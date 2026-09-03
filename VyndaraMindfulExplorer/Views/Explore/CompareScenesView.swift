import SwiftUI

struct CompareScenesView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var left: SceneCard?
    @State private var right: SceneCard?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("One character. One memory.")
                    .font(.custom("Georgia", size: 24))
                    .foregroundColor(.white)
                Text("Pick two frames and read them as a single scene.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .top, spacing: 10) {
                    slot(left, label: "A")
                    slot(right, label: "B")
                }

                if let left, let right {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shared prompt")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.accent)
                        Text("What if \(left.title.lowercased()) and \(right.title.lowercased()) belong to the same person?")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text(store.prompt(for: left.imageName)?.prompt ?? left.seedPrompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(store.prompt(for: right.imageName)?.prompt ?? right.seedPrompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        NeonButton(title: "Add pairing to chronicle", icon: "link") {
                            let note = "Paired with \(right.title): \(store.prompt(for: right.imageName)?.prompt ?? right.seedPrompt)"
                            store.addEntry(from: left, note: note)
                            CaptureHaptics.capture()
                        }
                    }
                    .padding(12)
                    .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 12))
                }

                Text("Library")
                    .font(.headline)
                    .foregroundColor(.white)
                ForEach(store.allScenes) { card in
                    Button {
                        if left?.id == card.id {
                            left = nil
                        } else if right?.id == card.id {
                            right = nil
                        } else if left == nil {
                            left = card
                        } else {
                            right = card
                        }
                        store.markViewed(card.id)
                    } label: {
                        HStack(spacing: 10) {
                            SceneArtwork(card: card)
                                .frame(width: 72, height: 52)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.title).foregroundColor(.white)
                                Text(badge(for: card)).font(.caption).foregroundColor(AppTheme.accent)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(AppTheme.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgDesk")
        .navigationTitle("Compare")
    }

    private func badge(for card: SceneCard) -> String {
        if left?.id == card.id { return "Frame A" }
        if right?.id == card.id { return "Frame B" }
        return card.tags.first ?? "scene"
    }

    private func slot(_ card: SceneCard?, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frame \(label)")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.accent)
            if let card {
                SceneArtwork(card: card)
                    .frame(height: 140)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(card.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .frame(height: 140)
                    .overlay {
                        Text("Tap a scene")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
