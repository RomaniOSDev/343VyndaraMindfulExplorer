import SwiftUI

struct BeatsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var beats = SceneBeats()
    @State private var showSprint = false

    var body: some View {
        ZStack {
            Color.clear
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SplitFrameView(frameA: store.draft.frameA, frameB: store.draft.frameB, height: 140)
                    Text("Five beats")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("\(beats.filledCount) of 5 — every field is required before the sprint.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    beatField("Who is watching", hint: "A night clerk. A child on the stairs. Nobody yet.", text: $beats.watcher)
                    beatField("What they want", hint: "To be seen. To miss the last boat. To keep a secret dry.", text: $beats.want)
                    beatField("What stands in the way", hint: "A locked door. Weather. The other person in frame B.", text: $beats.obstacle)
                    beatField("The turn from A to B", hint: "What changes between the two pictures — not what stays.", text: $beats.turn)
                    beatField("Last line spoken", hint: "One sentence someone says, or refuses to say.", text: $beats.lastLine)

                    NeonButton(title: "Lock a sprint", icon: "lock.fill", enabled: beats.isComplete) {
                        store.updateBeats(beats)
                        showSprint = true
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .clearScrollBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackdrop()
        .dismissKeyboardOnTap()
        .navigationTitle("Beats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { beats = store.draft.beats }
        .onChange(of: beats) { newValue in
            store.updateBeats(newValue)
        }
        .fullScreenCover(isPresented: $showSprint) {
            LockedSprintView().environmentObject(store)
        }
    }

    private func beatField(_ title: String, hint: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.accent)
            TextField(hint, text: text, axis: .vertical)
                .lineLimit(2...5)
                .foregroundColor(.white)
                .padding(12)
                .background(AppTheme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

struct SceneCardDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let sceneId: UUID
    @State private var confirmDelete = false

    private var scene: WrittenScene? { store.cards.first { $0.id == sceneId } }

    var body: some View {
        ZStack {
            Color.clear
            if let scene {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SplitFrameView(frameA: scene.frameA, frameB: scene.frameB, height: 170)
                        Text(scene.pairingTitle)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        Text("\(scene.minutes)-minute draft  ·  \(scene.finishedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(scene.beats.lines, id: \.label) { line in
                            BeatChip(label: line.label, value: line.value)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Locked draft")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.accent)
                            Text(scene.draft)
                                .font(.body)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Button("Delete this scene", role: .destructive) { confirmDelete = true }
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .clearScrollBackground()
            } else {
                Text("Scene is gone.")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackdrop()
        .navigationTitle("Scene card")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this scene card?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                store.deleteCard(sceneId)
                dismiss()
            }
            Button("Keep", role: .cancel) { }
        }
    }
}
