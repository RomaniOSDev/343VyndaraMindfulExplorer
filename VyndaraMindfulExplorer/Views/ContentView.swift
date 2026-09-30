import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    @State private var showSettings = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.clear
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                    Text("Two frames")
                            .font(.system(size: 34, weight: .bold, design: .default))
                            .foregroundColor(.white)
                        Text("Write one scene from a pair. Five beats, then a locked draft.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        NeonButton(title: "Pair two frames", icon: "rectangle.split.2x1") {
                            path.append(WorkshopRoute.pair)
                        }

                        if store.draft.hasPair {
                            continueDraft
                        }

                        if let latest = store.cards.first {
                            Text("Latest scene")
                                .font(.headline)
                                .foregroundColor(.white)
                            NavigationLink(value: latest) {
                                latestCard(latest)
                            }
                            .buttonStyle(.plain)
                        } else {
                            emptyState
                        }

                        if store.cards.count > 1 {
                            Text("Finished scenes")
                                .font(.headline)
                                .foregroundColor(.white)
                            ForEach(Array(store.cards.dropFirst())) { scene in
                                NavigationLink(value: scene) {
                                    sceneRow(scene)
                                }
                                .buttonStyle(.plain)
                            }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .navigationDestination(for: WorkshopRoute.self) { route in
                switch route {
                case .pair:
                    PairFramesView()
                case .beats:
                    BeatsView()
                }
            }
            .navigationDestination(for: WrittenScene.self) { scene in
                SceneCardDetailView(sceneId: scene.id)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(store)
            }
            .onChange(of: store.homeTick) { _ in
                path = NavigationPath()
            }
        }
        .background(Color.clear)
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
        .environmentObject(store)
    }

    private var continueDraft: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Open pairing")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.accent)
            SplitFrameView(frameA: store.draft.frameA, frameB: store.draft.frameB, height: 120)
            Text("\(store.draft.beats.filledCount) of 5 beats filled")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Button("Continue") {
                    path.append(WorkshopRoute.pair)
                    path.append(WorkshopRoute.beats)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(AppTheme.accent)
                Button("Discard") { store.discardDraft() }
                    .frame(minHeight: 44)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func latestCard(_ scene: WrittenScene) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SplitFrameView(frameA: scene.frameA, frameB: scene.frameB, height: 150)
            Text(scene.pairingTitle)
                .font(.headline)
                .foregroundColor(.white)
            Text(scene.beats.lastLine)
                .font(.system(.title3, design: .serif))
                .foregroundColor(AppTheme.accent)
                .italic()
        }
        .padding(12)
        .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sceneRow(_ scene: WrittenScene) -> some View {
        HStack(spacing: 12) {
            SplitFrameView(frameA: scene.frameA, frameB: scene.frameB, height: 56)
                .frame(width: 112, height: 56)
                .clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(scene.pairingTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(scene.beats.lastLine)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding(12)
        .background(AppTheme.surface.opacity(0.9), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No scene cards yet")
                .font(.headline)
                .foregroundColor(.white)
            Text("Pair two frames, fill the five beats, then write while the clock holds the save.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
