import SwiftUI

struct SprintView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let card: SceneCard
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var minutes: Int?
    @State private var remaining = 0
    @State private var draft = ""
    @State private var running = false
    @State private var ended = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Button("Close") { finish() }
                        .foregroundColor(.secondary)
                    Spacer()
                    if minutes != nil {
                        Text(clock)
                            .font(.custom("Georgia", size: 28))
                            .foregroundColor(ended ? AppTheme.accent : .white)
                            .monospacedDigit()
                    }
                }
                SceneArtwork(card: card)
                    .frame(height: minutes == nil ? 180 : 110)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(card.title)
                    .font(.custom("Georgia", size: 22))
                    .foregroundColor(.white)
                Text(store.prompt(for: card.imageName)?.prompt ?? card.seedPrompt)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if minutes == nil {
                    Text("Writing sprint")
                        .font(.headline)
                        .foregroundColor(AppTheme.accent)
                    HStack(spacing: 10) {
                        ForEach([10, 15, 25], id: \.self) { value in
                            Button("\(value) min") { start(value) }
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    TextEditor(text: $draft)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.white)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                    if ended {
                        Text("Time. Save what you wrote.")
                            .font(.headline)
                            .foregroundColor(AppTheme.accent)
                    }
                    NeonButton(title: "Save prompt", icon: "pencil.circle") { savePrompt() }
                    NeonButton(title: "Send to chronicle", icon: "plus.rectangle.on.folder") {
                        savePrompt()
                        store.addEntry(from: card, note: draft)
                        CaptureHaptics.capture()
                        finish()
                    }
                }
            }
            .padding(18)
        }
        .preferredColorScheme(.dark)
        .dismissKeyboardOnTap()
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            store.markViewed(card.id)
            draft = store.prompt(for: card.imageName)?.prompt ?? ""
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onReceive(ticker) { _ in
            guard running, remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 {
                running = false
                ended = true
                CaptureHaptics.capture()
            }
        }
    }

    private var clock: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func start(_ value: Int) {
        minutes = value
        remaining = value * 60
        running = true
        ended = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func savePrompt() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let item = PhotoPrompt(
            id: store.prompt(for: card.imageName)?.id ?? UUID(),
            imageName: card.imageName,
            caption: card.title,
            prompt: text,
            updatedAt: Date(),
            history: store.prompt(for: card.imageName)?.history ?? []
        )
        store.upsertPrompt(item)
        CaptureHaptics.capture()
    }

    private func finish() {
        UIApplication.shared.isIdleTimerDisabled = false
        dismiss()
    }
}
