use std::{fs, path::Path};

fn main() {
	println!("cargo:rerun-if-changed=schemas/");

	let out_dir = std::env::var("OUT_DIR").expect("OUT_DIR not set");
	let dest = Path::new(&out_dir).join("models_generated.rs");

	// Merge all schemas from schemas/ into a root definition map.
	let mut defs: serde_json::Map<String, serde_json::Value> = serde_json::Map::new();

	for entry in fs::read_dir("schemas").expect("schemas/ directory not found") {
		let entry = entry.expect("failed to read schemas/");
		let path = entry.path();
		if path.extension().and_then(|e| e.to_str()) != Some("json") {
			continue;
		}
		let content = fs::read_to_string(&path)
			.unwrap_or_else(|e| panic!("failed to read {}: {}", path.display(), e));
		let schema: serde_json::Value = serde_json::from_str(&content)
			.unwrap_or_else(|e| panic!("invalid JSON in {}: {}", path.display(), e));
		let key = schema
			.get("title")
			.and_then(|v| v.as_str())
			.map(ToOwned::to_owned)
			.unwrap_or_else(|| path.file_stem().unwrap().to_string_lossy().into_owned());
		defs.insert(key, schema);
	}

	// Build a root schema wrapping all definitions.
	let refs: Vec<serde_json::Value> =
		defs.keys().map(|k| serde_json::json!({ "$ref": format!("#/$defs/{}", k) })).collect();
	let root = serde_json::json!({
			"$schema": "http://json-schema.org/draft-07/schema#",
			"$defs": defs,
			"oneOf": refs,
	});

	// Use typify's TypeSpaceSettings to register x-rust-type crate overrides.
	let mut settings = typify::TypeSpaceSettings::default();
	settings
		.with_crate("jiff", typify::CrateVers::Version("0.2.0".parse().unwrap()), None::<&String>)
		.with_crate("url", typify::CrateVers::Version("2.5.0".parse().unwrap()), None::<&String>)
		.with_crate(
			"email_address",
			typify::CrateVers::Version("0.2.9".parse().unwrap()),
			None::<&String>,
		)
		.with_crate(
			"phonenumber",
			typify::CrateVers::Version("0.3.7".parse().unwrap()),
			None::<&String>,
		)
		.with_crate("celes", typify::CrateVers::Version("2.6.0".parse().unwrap()), None::<&String>);

	let schema_json = serde_json::to_string(&root).unwrap();
	let schema: schemars::schema::RootSchema = serde_json::from_str(&schema_json).unwrap();

	let mut type_space = typify::TypeSpace::new(&settings);
	type_space.add_root_schema(schema).expect("typify: failed to add schema");

	let code = prettyplease::unparse(
		&syn::parse2(type_space.to_stream()).expect("typify: invalid token stream"),
	);

	fs::write(&dest, code).expect("failed to write generated model code");
}
