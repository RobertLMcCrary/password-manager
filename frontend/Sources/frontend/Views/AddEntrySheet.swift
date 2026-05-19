import SwiftCrossUI

// MARK: - Add entry sheet

struct AddEntrySheet: View {
    @Binding var isPresented: Bool

    @Environment(PasswordStoreViewModel.self) var vm
    @State var name = ""
    @State var username = ""
    @State var password = ""
    @State var email = ""
    @State var phone = ""
    @State var website = ""
    @State var notes = ""

    var body: some View {
        VStack {
            Text("Add Entry").font(.title).padding(.bottom)

            HStack {
                Text("Name").frame(width: 90)
                TextField("entry-name", text: $name)
            }
            HStack {
                Text("Username").frame(width: 90)
                TextField("", text: $username)
            }
            HStack {
                Text("Password").frame(width: 90)
                TextField("", text: $password)
            }
            HStack {
                Text("Email").frame(width: 90)
                TextField("", text: $email)
            }
            HStack {
                Text("Phone").frame(width: 90)
                TextField("+1 555 000 0000", text: $phone)
            }
            HStack {
                Text("Website").frame(width: 90)
                TextField("https://…", text: $website)
            }
            HStack {
                Text("Notes").frame(width: 90)
                TextField("", text: $notes)
            }

            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button("Add") {
                    guard !name.isEmpty else { return }
                    let account = FfiOnlineAccount(
                        username: username.isEmpty ? nil : username,
                        password: password.isEmpty ? nil : password,
                        email: email.isEmpty ? nil : email,
                        phone: phone.isEmpty ? nil : phone,
                        signInWith: nil,
                        status: "Active",
                        hostWebsite: website.isEmpty ? nil : website,
                        loginPages: nil,
                        securityQuestions: nil,
                        twoFactorEnabled: nil,
                        associatedItems: nil,
                        dateCreated: nil,
                        notes: notes.isEmpty ? nil : notes
                    )
                    vm.add(name: name, item: .onlineAccount(account: account))
                    isPresented = false
                }
                .disabled(name.isEmpty)
            }
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 420)
    }
}
