import SwiftCrossUI

/*
TODO
- [x] click to copy on all fields
- [x] hover -> "click to copy" for all fields
- [ ] open website in browser
- [ ] more sorting
*/

// MARK: - Root

enum SortOrder {
    case nameAscending, nameDescending
}

struct ContentView: View {
    @Environment(PasswordStoreViewModel.self) var vm
    @State var showAddSheet = false
    @State var showShareSheet = false
    @State var receiveTicket = ""
    @State var searchText = ""
    @State var sortOrder: SortOrder = .nameAscending

    var filteredEntries: [String] {
        let sorted =
            sortOrder == .nameAscending
            ? vm.entries.sorted()
            : vm.entries.sorted().reversed()
        guard !searchText.isEmpty else { return Array(sorted) }
        return sorted.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationSplitView(
            sidebar: {
                VStack {
                    TextField("Search…", text: $searchText)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)

                    if filteredEntries.isEmpty {
                        VStack {
                            Spacer()
                            Text(searchText.isEmpty ? "No entries" : "No results")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        List(filteredEntries, id: \.self, selection: vm.$selectedEntry) {
                            name in
                            EntryRow(name: name, subtitle: vm.subtitles[name] ?? "")
                        }
                        .onChange(of: vm.selectedEntry) {
                            if let name = vm.selectedEntry { vm.select(name) }
                        }
                    }

                    Button(sortOrder == .nameAscending ? "A-Z" : "Z-A") {
                        sortOrder =
                            sortOrder == .nameAscending ? .nameDescending : .nameAscending
                    }
                    .foregroundColor(.gray)

                    Divider()

                    HStack {
                        Button("+") { showAddSheet = true }
                            .foregroundColor(.blue)
                        Button("Delete") {
                            if let name = vm.selectedEntry { vm.remove(name: name) }
                        }
                        .foregroundColor(.red)
                        .disabled(vm.selectedEntry == nil)
                        Spacer()
                        Button("Share") {
                            vm.share()
                            showShareSheet = true
                        }
                    }
                    .padding(8)
                }
                .padding(8)
            },
            detail: {
                if let item = vm.selectedItem, let name = vm.selectedEntry {
                    DetailView(name: name, item: item)
                } else {
                    VStack {
                        Spacer()
                        Text("Select an entry")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        )
        .sheet(isPresented: $showAddSheet) {
            AddEntrySheet(isPresented: $showAddSheet)
                .environment(vm)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(receiveTicket: $receiveTicket, isPresented: $showShareSheet)
                .environment(vm)
        }
        .alert(vm.$errorMessage) {
            Button("OK") { vm.errorMessage = nil }
        }
    }
}
