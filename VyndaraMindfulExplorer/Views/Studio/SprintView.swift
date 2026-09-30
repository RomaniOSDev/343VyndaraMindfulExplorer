import SwiftUI

struct LockedSprintView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var minutes: Int?
    @State private var remaining = 0
    @State private var running = false
    @State private var unlocked = false
    @State private var draft = ""
    @State private var confirmClose = false

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            Color.clear
                .overlay {
                    Image("BgWorkshop")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.28)
                }
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 14) {
                HStack {
                    Button("Close") { confirmClose = true }
                        .foregroundColor(.secondary)
                        .frame(minHeight: 44)
                    Spacer()
                    if minutes != nil {
                        HStack(spacing: 6) {
                            Image(systemName: unlocked ? "lock.open.fill" : "lock.fill")
                            Text(clock)
                                .monospacedDigit()
                        }
                        .font(.title2.weight(.semibold))
                        .foregroundColor(unlocked ? AppTheme.accent : .white)
                    }
                }

                SplitFrameView(frameA: store.draft.frameA, frameB: store.draft.frameB, height: minutes == nil ? 130 : 88)

                if minutes == nil {
                    picker
                } else {
                    writingDesk
                }
            }
            .frame(maxWidth: .infinity)
            .padding(18)
        }
        .preferredColorScheme(.dark)
        .dismissKeyboardOnTap()
        .interactiveDismissDisabled(running)
        .alert("Leave without a scene card?", isPresented: $confirmClose) {
            Button("Leave", role: .destructive, action: close)
            Button("Stay", role: .cancel) { }
        } message: {
            Text(unlocked ? "The draft is unlocked but not saved yet." : "The sprint is still locked. Nothing will be saved.")
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onReceive(ticker) { _ in
            guard running, remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 {
                running = false
                unlocked = true
                CaptureHaptics.capture()
            }
        }
    }

    private var picker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lock a sprint")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            Text("You can type the whole time. Saving stays locked until the clock hits zero.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                ForEach([5, 8, 12], id: \.self) { value in
                    Button("\(value) min") { start(value) }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundColor(.white)
                }
            }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.draft.beats.lines, id: \.label) { line in
                        BeatChip(label: line.label, value: line.value)
                    }
                }
            }
            .clearScrollBackground()
        }
    }

    private var writingDesk: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(unlocked ? "Draft unlocked — save the scene card." : "Saving is locked until the clock ends.")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.accent)
            TextEditor(text: $draft)
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.surface.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            NeonButton(
                title: unlocked ? "Save scene card" : "Locked until \(clock)",
                icon: unlocked ? "square.and.arrow.down" : "lock.fill",
                enabled: unlocked && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                store.completeScene(draftText: draft, minutes: minutes ?? 0)
                close()
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
        unlocked = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func close() {
        UIApplication.shared.isIdleTimerDisabled = false
        dismiss()
    }
}
