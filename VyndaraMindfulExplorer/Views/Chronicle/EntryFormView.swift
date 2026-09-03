import SwiftUI

struct EntryFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    var existing: ChronicleEntry?
    @State private var title = ""
    @State private var prompt = ""
    @State private var icon = "lightbulb"
    @State private var theme = "memory"
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Annotation") {
                    TextField("Title", text: $title)
                    TextField("Prompt", text: $prompt, axis: .vertical)
                        .lineLimit(3...8)
                    Picker("Icon", selection: $icon) {
                        Text("Idea").tag("lightbulb")
                        Text("Lens").tag("camera")
                        Text("Night").tag("moon")
                        Text("Heat").tag("flame")
                    }
                    TextField("Theme", text: $theme)
                    if let error { Text(error).font(.caption).foregroundColor(.red) }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(AppTheme.background)
            .dismissKeyboardOnTap()
            .navigationTitle(existing == nil ? "New entry" : "Edit entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let existing {
                    title = existing.title
                    prompt = existing.prompts.first ?? ""
                    icon = existing.icon
                    theme = existing.theme
                }
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty || p.isEmpty {
            error = "Title and at least one prompt are required."
            return
        }
        let entry = ChronicleEntry(id: existing?.id ?? UUID(), title: t, prompts: [p], icon: icon, theme: theme)
        store.upsertEntry(entry)
        CaptureHaptics.capture()
        dismiss()
    }
}

struct EntryDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let entryId: UUID
    @State private var showEdit = false
    @State private var confirmDelete = false

    private var entry: ChronicleEntry? { store.entries.first { $0.id == entryId } }

    var body: some View {
        Group {
            if let entry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(entry.title)
                            .font(.custom("Georgia", size: 28))
                        Text(entry.theme.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.accent)
                        ForEach(entry.prompts, id: \.self) { line in
                            Text(line)
                                .font(.title3)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                        }
                        NeonButton(title: "Edit", icon: "pencil") { showEdit = true }
                        Button("Delete", role: .destructive) { confirmDelete = true }
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(18)
                }
                .screenBackdrop("BgDesk")
                .sheet(isPresented: $showEdit) {
                    EntryFormView(existing: entry).environmentObject(store)
                }
                .alert("Delete this annotation?", isPresented: $confirmDelete) {
                    Button("Delete", role: .destructive) { store.deleteEntry(entry.id) }
                    Button("Cancel", role: .cancel) { }
                }
            } else {
                Text("Entry unavailable.").screenBackdrop("BgDesk")
            }
        }
        .navigationTitle("Scene")
    }
}
