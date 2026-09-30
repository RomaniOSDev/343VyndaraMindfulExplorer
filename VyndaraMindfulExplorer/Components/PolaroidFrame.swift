import SwiftUI

struct SplitFrameView: View {
    @EnvironmentObject private var store: AppDataStore
    var frameA: FrameShot?
    var frameB: FrameShot?
    var height: CGFloat = 168

    var body: some View {
        HStack(spacing: 8) {
            slot(frameA, label: "A")
            slot(frameB, label: "B")
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private func slot(_ frame: FrameShot?, label: String) -> some View {
        ZStack(alignment: .topLeading) {
            if let frame {
                FrameArtwork(frame: frame)
            } else {
                AppTheme.surface.opacity(0.7)
                Text("Frame \(label)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.accent.opacity(0.92), in: Capsule())
                .padding(8)
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.primary.opacity(0.35), lineWidth: 1)
        )
    }
}

struct BeatChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.accent)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct NeonButton: View {
    let title: String
    let icon: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.neon)
                    .shadow(color: AppTheme.primary.opacity(0.45), radius: 8, y: 4)
            )
            .opacity(enabled ? 1 : 0.4)
        }
        .disabled(!enabled)
        .buttonStyle(FilmPressStyle())
        .frame(minHeight: 44)
    }
}
