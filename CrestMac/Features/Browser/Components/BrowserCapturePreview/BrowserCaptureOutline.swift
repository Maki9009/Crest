import SwiftUI

/// The color of the outline page capture draws around what it would take.
struct BrowserCaptureOutline: Hashable, Sendable {
    // MARK: - Static Variables

    static let key = "crest.capture.outline"
    static let spaceColor = BrowserCaptureOutline(name: "space", title: "Space Color", fixedColor: nil)
    static let white = BrowserCaptureOutline(name: "white", title: "White", fixedColor: CrestBrandPalette.paper)
    static let all = [spaceColor, white]
    static let standard = spaceColor

    // MARK: - Variables

    /// The persisted spelling.
    let name: String
    let title: LocalizedStringResource
    /// The outline's own color, or nil to take the page's Space color.
    let fixedColor: Color?

    // MARK: - Initializers

    private init(name: String, title: LocalizedStringResource, fixedColor: Color?) {
        self.name = name
        self.title = title
        self.fixedColor = fixedColor
    }

    // MARK: - Actions - Lookup

    static func named(_ name: String?) -> BrowserCaptureOutline? {
        all.first { $0.name == name }
    }

    /// The outline's color over a page whose Space wears `spaceAccent`.
    func color(spaceAccent: Color?) -> Color {
        fixedColor ?? spaceAccent ?? CrestBrandPalette.paper
    }
}

// MARK: - Hashable

extension BrowserCaptureOutline {
    static func == (lhs: BrowserCaptureOutline, rhs: BrowserCaptureOutline) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
