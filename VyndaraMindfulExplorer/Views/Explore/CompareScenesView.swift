import SwiftUI
import PhotosUI

struct PairFramesView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var pickedItem: PhotosPickerItem?

    private let columns = [
        GridItem(.flexible(minimum: 0), spacing: 10),
        GridItem(.flexible(minimum: 0), spacing: 10)
    ]

    var body: some View {
        ZStack {
            Color.clear
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Choose A and B")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("The scene lives in the gap between the two frames.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    SplitFrameView(frameA: store.draft.frameA, frameB: store.draft.frameB, height: 160)

                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        Label("Add a frame from Photos", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(store.allFrames) { frame in
                            Button { store.toggleFrame(frame) } label: {
                                ZStack(alignment: .bottomLeading) {
                                    FrameArtwork(frame: frame)
                                    LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                                    HStack(spacing: 6) {
                                        Text(frame.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        Spacer(minLength: 4)
                                        if let mark = badge(for: frame) {
                                            Text(mark)
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(AppTheme.accent, in: Capsule())
                                        }
                                    }
                                    .padding(8)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(badge(for: frame) != nil ? AppTheme.accent : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }

                    NavigationLink(value: WorkshopRoute.beats) {
                        HStack {
                            Image(systemName: "text.justify.left")
                            Text("Write the five beats").font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.neon)
                        )
                        .opacity(store.draft.hasPair ? 1 : 0.4)
                    }
                    .disabled(!store.draft.hasPair)
                    .frame(minHeight: 44)
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
        .navigationTitle("Pair")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickedItem) { newItem in
            guard let newItem else { return }
            Task {
                if let picked = try? await newItem.loadTransferable(type: PickedImageData.self),
                   let shot = store.addCustomFrame(imageData: picked.data) {
                    store.toggleFrame(shot)
                }
                pickedItem = nil
            }
        }
    }

    private func badge(for frame: FrameShot) -> String? {
        if store.draft.frameA?.id == frame.id { return "A" }
        if store.draft.frameB?.id == frame.id { return "B" }
        return nil
    }
}
