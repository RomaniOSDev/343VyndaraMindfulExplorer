import SwiftUI

struct InspirationPreviewView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var note = ""
    @State private var selected: SceneCard?
    @State private var sprintCard: SceneCard?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ready scenes")
                    .font(.custom("Georgia", size: 26))
                NavigationLink {
                    CompareScenesView()
                } label: {
                    Label("Compare two scenes", systemImage: "rectangle.split.2x1")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 12)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                }
                if store.allScenes.isEmpty {
                    Label("No inspiration yet—tap Explore", systemImage: "magnifyingglass.circle")
                }
                ForEach(store.allScenes) { card in
                    sceneCard(card)
                }
            }
            .padding(18)
        }
        .scrollDismissesKeyboard(.immediately)
        .dismissKeyboardOnTap()
        .screenBackdrop("BgDesk")
        .navigationTitle("Explore")
        .fullScreenCover(item: $sprintCard) { card in
            SprintView(card: card).environmentObject(store)
        }
    }

    private func sceneCard(_ card: SceneCard) -> some View {
        let isSelected = selected?.id == card.id
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                select(card)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    SceneArtwork(card: card)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    HStack {
                        Text(card.title).font(.headline).foregroundColor(.white)
                        Spacer()
                        if isSelected {
                            Text("Selected")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                    Text(card.seedPrompt).font(.subheadline).foregroundColor(.secondary)
                    HStack {
                        ForEach(card.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.primary.opacity(0.25), in: Capsule())
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            if isSelected {
                TextField("Add a note to this scene", text: $note, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(10)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Button(store.favorites.contains(card.id) ? "Favorited" : "Favorite") {
                    store.toggleFavorite(card.id)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .frame(minHeight: 44)
                Button("Add to chronicle") {
                    if !isSelected { select(card) }
                    store.addEntry(from: card, note: note)
                    note = ""
                    CaptureHaptics.capture()
                }
                .frame(minHeight: 44)
            }
            .foregroundColor(AppTheme.accent)
            if isSelected {
                Button("Writing sprint") { sprintCard = card }
                    .frame(minHeight: 44)
                    .foregroundColor(AppTheme.accent)
            }
        }
        .padding(12)
        .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 2)
        )
    }

    private func select(_ card: SceneCard) {
        if selected?.id == card.id {
            selected = nil
            note = ""
        } else {
            selected = card
            note = ""
            store.markViewed(card.id)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
