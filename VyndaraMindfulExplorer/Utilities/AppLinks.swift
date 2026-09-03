import UIKit

enum AppLinks: String {
    case privacy = "https://vyndaramindful343explorer.site/privacy/448"
    case terms = "https://vyndaramindful343explorer.site/terms/448"

    var url: URL? { URL(string: rawValue) }
}
