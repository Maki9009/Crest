import SwiftUI

/// The inks a capture can be marked up in, from Crest's house palette.
struct BrowserCaptureMarkupColor: Hashable, Sendable {
    // MARK: - Static Variables

    static let coral = BrowserCaptureMarkupColor(name: "coral", title: "Coral", color: CrestBrandPalette.coral)
    static let butter = BrowserCaptureMarkupColor(name: "butter", title: "Butter", color: CrestBrandPalette.butter)
    static let sky = BrowserCaptureMarkupColor(name: "sky", title: "Sky", color: CrestBrandPalette.sky)
    static let sage = BrowserCaptureMarkupColor(name: "sage", title: "Sage", color: CrestBrandPalette.sage)
    static let ink = BrowserCaptureMarkupColor(name: "ink", title: "Ink", color: CrestBrandPalette.ink)
    static let paper = BrowserCaptureMarkupColor(name: "paper", title: "Paper", color: CrestBrandPalette.paper)
    static let all = [coral, butter, sky, sage, ink, paper]

    // MARK: - Variables

    let name: String
    let title: LocalizedStringResource
    let color: Color

    // MARK: - Initializers

    private init(name: String, title: LocalizedStringResource, color: Color) {
        self.name = name
        self.title = title
        self.color = color
    }
}

// MARK: - Hashable

extension BrowserCaptureMarkupColor {
    static func == (lhs: BrowserCaptureMarkupColor, rhs: BrowserCaptureMarkupColor) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
