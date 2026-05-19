import SwiftCrossUI

// MARK: - Detail

struct DetailView: View {
    let name: String
    let item: FfiItem

    @Environment(PasswordStoreViewModel.self) var vm
    @State var showPassword = false
    @State var showHistory = false

    var initial: String { String(name.prefix(1)).uppercased() }

    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    AvatarView(letter: initial, size: 72)
                        .padding(.top, 16)
                    Text(name)
                        .font(.title)
                        .emphasized()
                        .padding(.top, 4)
                    HStack {
                        Text(item.displayName)
                            .foregroundColor(.gray)
                            .font(.caption)
                        Spacer()
                        Button(showHistory ? "Hide History" : "History") {
                            showHistory.toggle()
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.bottom, 12)

                Divider()

                switch item {
                case .onlineAccount(let a):
                    OnlineAccountDetail(name: name, account: a, showPassword: $showPassword)
                case .socialSecurity(let s):
                    SsnDetail(ssn: s)
                }

                if showHistory {
                    Divider().padding(.top, 8)
                    HistoryPanel(name: name)
                        .environment(vm)
                }

                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 480)
    }
}

struct OnlineAccountDetail: View {
    let name: String
    let account: FfiOnlineAccount
    @Binding var showPassword: Bool

    @Environment(PasswordStoreViewModel.self) var vm
    @State var editing = false
    @State var draft = FfiOnlineAccount.empty()

    var body: some View {
        VStack {
            if editing {
                EditOnlineAccountView(name: name, draft: $draft, editing: $editing)
                    .environment(vm)
            } else {
                if let v = account.username { FieldRow(label: "Username", value: v) }
                if let v = account.email { FieldRow(label: "Email", value: v) }
                if let v = account.phone { FieldRow(label: "Phone", value: v) }
                if let v = account.hostWebsite { FieldRow(label: "Website", value: v) }
                if let pages = account.loginPages, !pages.isEmpty {
                    FieldRow(label: "Login Pages", value: pages.joined(separator: "\n"))
                }
                if let v = account.password {
                    PasswordRow(password: v, showPassword: $showPassword)
                }
                if let providers = account.signInWith, !providers.isEmpty {
                    FieldRow(label: "Sign In With", value: providers.joined(separator: ", "))
                }
                if let v = account.status { FieldRow(label: "Status", value: v) }
                if let tfa = account.twoFactorEnabled {
                    FieldRow(label: "2FA", value: tfa ? "Enabled" : "Disabled")
                }
                if let questions = account.securityQuestions, !questions.isEmpty {
                    SecurityQuestionsRow(questions: questions)
                }
                if let items = account.associatedItems, !items.isEmpty {
                    FieldRow(label: "Associated", value: items.joined(separator: ", "))
                }
                if let v = account.dateCreated { FieldRow(label: "Created", value: v) }
                if let v = account.notes { NotesRow(notes: v) }

                Button("Edit") {
                    draft = account
                    editing = true
                }
                .padding(.top, 8)
            }
        }
    }
}

struct EditOnlineAccountView: View {
    let name: String
    @Binding var draft: FfiOnlineAccount
    @Binding var editing: Bool

    @Environment(PasswordStoreViewModel.self) var vm
    @State var username = ""
    @State var password = ""
    @State var email = ""
    @State var phone = ""
    @State var website = ""
    @State var notes = ""

    var body: some View {
        VStack {
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
                Button("Cancel") { editing = false }
                Spacer()
                Button("Save") {
                    let updated = FfiOnlineAccount(
                        username: username.isEmpty ? nil : username,
                        password: password.isEmpty ? nil : password,
                        email: email.isEmpty ? nil : email,
                        phone: phone.isEmpty ? nil : phone,
                        signInWith: draft.signInWith,
                        status: draft.status,
                        hostWebsite: website.isEmpty ? nil : website,
                        loginPages: draft.loginPages,
                        securityQuestions: draft.securityQuestions,
                        twoFactorEnabled: draft.twoFactorEnabled,
                        associatedItems: draft.associatedItems,
                        dateCreated: draft.dateCreated,
                        notes: notes.isEmpty ? nil : notes
                    )
                    vm.update(name: name, item: .onlineAccount(account: updated))
                    editing = false
                }
            }
            .padding(.top, 8)
        }
        .onAppear {
            username = draft.username ?? ""
            password = draft.password ?? ""
            email = draft.email ?? ""
            phone = draft.phone ?? ""
            website = draft.hostWebsite ?? ""
            notes = draft.notes ?? ""
        }
    }
}

struct SsnDetail: View {
    let ssn: FfiSocialSecurity

    var body: some View {
        VStack {
            FieldRow(label: "Number", value: ssn.accountNumber)
            if let v = ssn.legalName { FieldRow(label: "Name", value: v) }
            if let v = ssn.countryOfIssue { FieldRow(label: "Country", value: v) }
            if let v = ssn.issuanceDate { FieldRow(label: "Issued", value: v) }
            if let v = ssn.notes { NotesRow(notes: v) }
        }
    }
}
