import SwiftCrossUI

// MARK: - Share / receive sheet

struct ShareSheet: View {
    @Binding var receiveTicket: String
    @Binding var isPresented: Bool

    @Environment(PasswordStoreViewModel.self) var vm

    var body: some View {
        VStack {
            Text("Share / Receive").font(.title).padding(.bottom)

            if let ticket = vm.shareTicket {
                VStack {
                    Text("Share ticket (send this to the receiver):").font(.caption)
                    Text(ticket)
                        .font(.caption)
                        .padding(8)
                    /*
                    Button("Copy ticket") { copyToClipboard(ticket) }
                    */
                }
                .padding(.bottom)
            }

            Divider()

            VStack {
                Text("Paste a ticket to receive:").font(.caption)
                TextField("ticket…", text: $receiveTicket)
                Button("Receive") {
                    vm.receive(ticket: receiveTicket)
                    isPresented = false
                }
                .disabled(receiveTicket.isEmpty)
            }

            Button("Close") { isPresented = false }
                .padding(.top)
        }
        .padding()
        .frame(minWidth: 480)
    }
}
