import SwiftUI

enum AppTheme {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")

    static var neon: LinearGradient {
        LinearGradient(colors: [primary, accent], startPoint: .leading, endPoint: .trailing)
    }

    static var slate: LinearGradient {
        LinearGradient(colors: [surface.opacity(0.95), background.opacity(0.9)], startPoint: .top, endPoint: .bottom)
    }
}

struct FilmPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .rotationEffect(.degrees(configuration.isPressed ? -1.2 : 0))
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
