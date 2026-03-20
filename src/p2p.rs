use std::sync::Arc;

use anyhow::Result;
use futures_lite::StreamExt;
use iroh::{Endpoint, endpoint::presets, protocol::Router};
use iroh_blobs::{ALPN as BLOBS_ALPN, BlobsProtocol, store::mem::MemStore};
use iroh_docs::{ALPN as DOCS_ALPN, DocTicket, engine::LiveEvent, protocol::Docs, store::Query};
use iroh_gossip::{ALPN as GOSSIP_ALPN, net::Gossip};
use tokio::sync::Mutex;

// The fixed key used to store the password store blob inside the doc.
const PASSWORDS_KEY: &[u8] = b"passwords";

// Represents the current sync state.
#[derive(Debug, Clone)]
pub enum SyncState {
	/// Not syncing.
	Idle,
	/// Sharing passwords; ticket can be handed to the other peer.
	Sharing { ticket: String },
	/// Awaiting ticket input for receiving.
	ReceiveInput { input: String },
	/// Currently receiving / syncing passwords.
	Receiving,
	/// Sync completed successfully.
	Completed { message: String },
	/// Sync failed.
	Error { message: String },
}

impl Default for SyncState {
	fn default() -> Self {
		Self::Idle
	}
}

/// All live handles needed to keep the node running.
struct NodeHandles {
	router: Router,
	docs: Docs,
	blobs: MemStore,
}

/// P2P sync handler backed by iroh-docs.
///
/// The sender creates a document, writes the password payload as an entry,
/// and hands off a `DocTicket` (read capability + node address) to the
/// receiver. The receiver imports the ticket and waits for the entry to
/// arrive via the docs live-sync protocol.
pub struct P2PSync {
	endpoint: Endpoint,
	handles: Option<NodeHandles>,
}

impl P2PSync {
	/// Spin up an iroh endpoint with the full docs/blobs/gossip stack.
	pub async fn new() -> Result<Self> {
		let endpoint = Endpoint::bind().await?;

		let blobs = MemStore::default();
		let gossip = Gossip::builder().spawn(endpoint.clone());
		let docs = Docs::memory().spawn(endpoint.clone(), (*blobs).clone(), gossip.clone()).await?;

		let router = Router::builder(endpoint.clone())
			.accept(BLOBS_ALPN, BlobsProtocol::new(&blobs, None))
			.accept(GOSSIP_ALPN, gossip)
			.accept(DOCS_ALPN, docs.clone())
			.spawn();

		Ok(Self { endpoint, handles: Some(NodeHandles { router, docs, blobs }) })
	}

	fn docs(&self) -> Result<&Docs> {
		self.handles.as_ref().map(|h| &h.docs).ok_or_else(|| anyhow::anyhow!("node not running"))
	}

	/// Write `data` into a new document and return a `DocTicket` string
	/// that grants read access plus the current node's address.
	///
	/// The ticket encodes both the namespace capability and the peer address,
	/// so the receiver can connect and pull the entry automatically.
	pub async fn share_data(&self, data: Vec<u8>) -> Result<String> {
		let api = self.docs()?.client();

		// Create a fresh document (generates a new NamespaceSecret).
		let doc = api.create().await?;

		// Use the default author for this node.
		let author = api.author_default().await?;

		// Write the password payload as a single entry under PASSWORDS_KEY.
		doc.set_bytes(author, PASSWORDS_KEY.to_vec(), data).await?;

		// Generate a read-only ticket so the receiver cannot write back.
		let ticket = doc
			.share(
				iroh_docs::api::protocol::ShareMode::Read,
				iroh_docs::api::protocol::AddrInfoOptions::RelayAndAddresses,
			)
			.await?;

		Ok(ticket.to_string())
	}

	/// Import a `DocTicket` string, join the document, wait for the entry,
	/// and return the raw password store bytes.
	pub async fn receive_data(&self, ticket_str: &str) -> Result<Vec<u8>> {
		let ticket: DocTicket = ticket_str.parse()?;
		let api = self.docs()?.client();

		// Import ticket and subscribe to live events so we can wait for the
		// entry to arrive without polling.
		let (doc, mut events) = api.import_and_subscribe(ticket).await?;

		// Wait until we see the entry we care about sync in.
		loop {
			match events.next().await {
				Some(Ok(LiveEvent::InsertRemote { entry, .. })) => {
					if entry.key() == PASSWORDS_KEY {
						break;
					}
				}
				// Also handle the case where the entry is already present
				// locally (e.g. re-import).
				Some(Ok(LiveEvent::InsertLocal { entry })) => {
					if entry.key() == PASSWORDS_KEY {
						break;
					}
				}
				Some(Ok(_)) => continue,
				Some(Err(e)) => return Err(e.into()),
				None => anyhow::bail!("event stream ended before entry arrived"),
			}
		}

		// Fetch the entry and read its content bytes via iroh-blobs.
		let entry = doc
			.get_one(Query::single_latest_per_key().key_exact(PASSWORDS_KEY))
			.await?
			.ok_or_else(|| anyhow::anyhow!("entry missing after sync"))?;

		let content = doc.read_to_bytes(&entry).await?;
		Ok(content.to_vec())
	}

	/// Gracefully shut down the router and close the endpoint.
	pub async fn shutdown(mut self) -> Result<()> {
		if let Some(handles) = self.handles.take() {
			handles.router.shutdown().await?;
		}
		Ok(())
	}
}

/// Async-safe wrapper for `P2PSync`.
pub struct P2PSyncHandle {
	inner: Arc<Mutex<Option<P2PSync>>>,
}

impl P2PSyncHandle {
	pub fn new() -> Self {
		Self { inner: Arc::new(Mutex::new(None)) }
	}

	/// Initialise a new P2P session (boots the full iroh stack).
	pub async fn init(&self) -> Result<()> {
		let mut guard = self.inner.lock().await;
		*guard = Some(P2PSync::new().await?);
		Ok(())
	}

	/// Share serialised password store bytes; returns a `DocTicket` string.
	pub async fn share(&self, data: Vec<u8>) -> Result<String> {
		let guard = self.inner.lock().await;
		match guard.as_ref() {
			Some(sync) => sync.share_data(data).await,
			None => anyhow::bail!("P2P sync not initialised"),
		}
	}

	/// Receive password store bytes from a `DocTicket` string.
	pub async fn receive(&self, ticket: &str) -> Result<Vec<u8>> {
		let mut guard = self.inner.lock().await;
		if guard.is_none() {
			*guard = Some(P2PSync::new().await?);
		}
		guard
			.as_ref()
			.ok_or_else(|| anyhow::anyhow!("P2P sync not initialised"))?
			.receive_data(ticket)
			.await
	}

	/// Shut down and clean up.
	pub async fn shutdown(&self) -> Result<()> {
		let mut guard = self.inner.lock().await;
		if let Some(sync) = guard.take() {
			sync.shutdown().await?;
		}
		Ok(())
	}

	/// Returns `true` if a session is currently active.
	pub async fn is_active(&self) -> bool {
		self.inner.lock().await.is_some()
	}
}

impl Default for P2PSyncHandle {
	fn default() -> Self {
		Self::new()
	}
}
