import SwiftUI

struct PolaroidFrame<Content: View>: View {
    var tilt: Double = 0
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 28)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: AppTheme.primary.opacity(0.28), radius: 10, y: 8)
            )
            .rotationEffect(.degrees(tilt))
    }
}

struct NeonButton: View {
    let title: String
    let icon: String
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
        }
        .buttonStyle(FilmPressStyle())
        .frame(minHeight: 44)
    }
}
