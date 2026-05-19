import Foundation
import SwiftCrossUI

// MARK: - Field rows

struct FieldRow: View {
    let label: String
    let value: String

    @State private var copied = false
    @State private var hovered = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
                .font(.caption)
                .frame(width: 100)
            Text(value)
                .onHover { hovered = $0 }
                .foregroundColor(hovered ? .blue : .gray)
                .onTapGesture {
                    copyToClipboard(value)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                        copied = false
                    }
                }
                .onChange(of: value) {
                    copied = false
                }

            if hovered {
                Text("Click to Copy")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if copied {
                Text("Copied!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            Spacer()

        }
        .padding(.vertical, 6)
    }
}

struct PasswordRow: View {
    let password: String
    @Binding var showPassword: Bool
    @State private var copied = false
    @State private var hovered = false

    var body: some View {
        HStack {
            Text("Password")
                .foregroundColor(.gray)
                .font(.caption)
                .frame(width: 100)
            Text(showPassword ? password : String(repeating: "•", count: 16))
                .onHover {
                    hovering in
                    showPassword = hovering
                    hovered = true
                }
                .onTapGesture {
                    copyToClipboard(password)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                        copied = false
                    }
                }
                .onChange(of: password) {
                    copied = false
                }
            if hovered {
                Text("Click to Copy")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if copied {
                Text("Copied!")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct SecurityQuestionsRow: View {
    let questions: [FfiSecurityQuestion]

    var body: some View {
        VStack {
            HStack {
                Text("Security Q&A")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .frame(width: 100)
                Spacer()
            }
            ForEach(questions, id: \.question) { q in
                VStack {
                    HStack {
                        Text(q.question).font(.caption)
                        Spacer()
                    }
                    HStack {
                        Text(q.answer)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        /*
                        Button("Copy") { copyToClipboard(q.answer) }
                            .foregroundColor(.gray)
                        */
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.vertical, 6)
    }
}

struct NotesRow: View {
    let notes: String

    var body: some View {
        VStack {
            HStack {
                Text("Notes")
                    .foregroundColor(.gray)
                    .font(.caption)
                Spacer()
            }
            HStack {
                Text(notes)
                Spacer()
            }
            .padding(8)
        }
        .padding(.vertical, 6)
    }
}
