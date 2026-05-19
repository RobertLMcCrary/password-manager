import SwiftCrossUI

// MARK: - History panel

struct HistoryPanel: View {
    let name: String
    @Environment(PasswordStoreViewModel.self) var vm
    @State var expandedHash: String? = nil

    var body: some View {
        let log = vm.logHistory(for: name)
        VStack {
            HStack {
                Text("History")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            if log.isEmpty {
                Text("No history recorded.").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(log, id: \.hash) { entry in
                    VStack {
                        HStack {
                            VStack {
                                HStack {
                                    Text(entry.message).font(.caption)
                                    Spacer()
                                }
                                HStack {
                                    Text(String(entry.hash.prefix(12)))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(entry.timestamp)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                            Button(expandedHash == entry.hash ? "Hide" : "Diff") {
                                expandedHash = expandedHash == entry.hash ? nil : entry.hash
                            }
                            Button("Revert") {
                                vm.revert(name: name, toHash: entry.hash)
                            }
                        }
                        .padding(.vertical, 2)

                        if expandedHash == entry.hash {
                            if let result = vm.diff(name: name, fromHash: entry.hash) {
                                DiffView(result: result)
                            } else {
                                Text("No diff available.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Diff view

struct DiffView: View {
    let result: DiffResult

    var body: some View {
        VStack {
            HStack {
                Text(result.label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            ForEach(result.lines, id: \.self) { line in
                DiffLineView(line: line)
            }
        }
        .padding(8)
    }
}

struct DiffLineView: View {
    let line: DiffLine

    var body: some View {
        HStack {
            switch line.op {
            case .insert:
                Text("+ \(line.content)")
                    .font(.caption)
                    .foregroundColor(.green)
            case .delete:
                Text("- \(line.content)")
                    .font(.caption)
                    .foregroundColor(.red)
            case .retain:
                Text("  \(line.content)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
}
