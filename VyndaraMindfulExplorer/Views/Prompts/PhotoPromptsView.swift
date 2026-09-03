import SwiftUI
import PhotosUI

struct PhotoPromptsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var pickedItem: PhotosPickerItem?
    @State private var pendingImage: Data?
    @State private var customTitle = ""
    @State private var customSeed = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Label("Add scene from library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 10))
                }

                if store.photoPrompts.isEmpty && store.allScenes.isEmpty {
                    Text("No Prompts Yet")
                }
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(store.allScenes) { card in
                        NavigationLink(value: card) {
                            PolaroidFrame(tilt: card.id == "camera" ? -3 : 2) {
                                VStack(alignment: .leading, spacing: 8) {
                                    SceneArtwork(card: card)
                                        .frame(height: 110)
                                        .clipped()
                                    Text(preview(for: card))
                                        .font(.caption)
                                        .foregroundColor(.black.opacity(0.75))
                                        .lineLimit(2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .contextMenu {
                            if card.isCustom {
                                Button("Delete scene", role: .destructive) {
                                    store.deleteCustomScene(card.id)
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgDesk")
        .navigationTitle("Photo prompts")
        .onChange(of: pickedItem) { newItem in
            guard let newItem else { return }
            Task {
                if let picked = try? await newItem.loadTransferable(type: PickedImageData.self) {
                    pendingImage = picked.data
                    customTitle = ""
                    customSeed = ""
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { pendingImage != nil },
            set: { if !$0 { pendingImage = nil } }
        )) {
            NavigationStack {
                Form {
                    Section("New scene") {
                        TextField("Title", text: $customTitle)
                        TextField("Seed prompt", text: $customSeed, axis: .vertical)
                            .lineLimit(2...5)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
                .navigationTitle("From library")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { pendingImage = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { saveCustom() }
                    }
                }
            }
            .tint(AppTheme.accent)
            .preferredColorScheme(.dark)
            .dismissKeyboardOnTap()
        }
    }

    private func preview(for card: SceneCard) -> String {
        store.prompt(for: card.imageName)?.prompt ?? "No Prompts Yet"
    }

    private func saveCustom() {
        guard let pendingImage else { return }
        if let card = store.addCustomScene(imageData: pendingImage, title: customTitle, seed: customSeed) {
            store.markViewed(card.id)
            CaptureHaptics.capture()
        }
        self.pendingImage = nil
        pickedItem = nil
    }
}

struct PhotoPromptDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let card: SceneCard
    @State private var prompt = ""
    @State private var error: String?
    @State private var saved = false
    @State private var showSprint = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PolaroidFrame {
                    SceneArtwork(card: card)
                        .frame(height: 220)
                        .clipped()
                }
                Text(card.title)
                    .font(.custom("Georgia", size: 24))
                TextEditor(text: $prompt)
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                if let error { Text(error).font(.caption).foregroundColor(.red) }
                if saved {
                    Label("Saved", systemImage: "checkmark")
                        .foregroundColor(AppTheme.accent)
                }
                NeonButton(title: "Save prompt", icon: "pencil.circle") { save() }
                NeonButton(title: "Send to chronicle", icon: "plus.rectangle.on.folder") {
                    save()
                    store.addEntry(from: card)
                }
                .accessibilityIdentifier("send_to_chronicle")
                NeonButton(title: "Writing sprint", icon: "timer") { showSprint = true }

                if let history = store.prompt(for: card.imageName)?.history, !history.isEmpty {
                    Text("Earlier versions")
                        .font(.headline)
                    ForEach(history) { revision in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(revision.prompt)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(revision.savedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(AppTheme.accent)
                            Button("Restore this version") {
                                prompt = revision.prompt
                                store.restoreRevision(revision, for: card.imageName)
                                saved = true
                                CaptureHaptics.capture()
                            }
                            .frame(minHeight: 44)
                            .foregroundColor(AppTheme.accent)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                if card.isCustom {
                    Button("Delete custom scene", role: .destructive) {
                        store.deleteCustomScene(card.id)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .padding(18)
        }
        .scrollDismissesKeyboard(.immediately)
        .dismissKeyboardOnTap()
        .screenBackdrop("BgDesk")
        .navigationTitle("Caption")
        .fullScreenCover(isPresented: $showSprint) {
            SprintView(card: card).environmentObject(store)
        }
        .onAppear {
            prompt = store.prompt(for: card.imageName)?.prompt ?? card.seedPrompt
            store.markViewed(card.id)
        }
    }

    private func save() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            error = "Enter a prompt before saving."
            saved = false
            return
        }
        error = nil
        let item = PhotoPrompt(
            id: store.prompt(for: card.imageName)?.id ?? UUID(),
            imageName: card.imageName,
            caption: card.title,
            prompt: trimmed,
            updatedAt: Date(),
            history: store.prompt(for: card.imageName)?.history ?? []
        )
        store.upsertPrompt(item)
        saved = true
        CaptureHaptics.capture()
    }
}
