import AppKit

/// How round a browser window's corners are. macOS sizes a window's corners
/// by its toolbar's style, so each choice is the style Crest gives the empty
/// toolbar behind its chrome. Pages keep their corners concentric with
/// whichever the window has.
struct BrowserWindowCornerStyle: Hashable, Sendable {
    // MARK: - Static Variables

    static let key = "crest.appearance.window-corners"
    static let rounded = BrowserWindowCornerStyle(
        name: "rounded", title: "Rounded", toolbarStyle: .unified, windowControlsOffset: .zero)
    static let compact = BrowserWindowCornerStyle(
        name: "compact", title: "Compact", toolbarStyle: .unifiedCompact,
        windowControlsOffset: CGSize(width: 7, height: 6))
    /// The tightest corners macOS gives a window, from a toolbar that sits
    /// under the title rather than beside it. Crest's toolbar is empty, so
    /// only the corners and the window's buttons change.
    static let sharp = BrowserWindowCornerStyle(
        name: "sharp", title: "Sharp", toolbarStyle: .expanded, windowControlsOffset: CGSize(width: 10, height: 10))
    static let all = [rounded, compact, sharp]
    static let standard = rounded

    /// The style the person chose, or the standard one.
    @MainActor static var current: BrowserWindowCornerStyle {
        named(BrowserChromeAppearancePreference.defaults.string(forKey: key)) ?? standard
    }

    // MARK: - Variables

    /// The persisted spelling.
    let name: String
    let title: LocalizedStringResource
    let toolbarStyle: NSWindow.ToolbarStyle
    /// How far right and down the window's buttons move from where this
    /// style seats them, so they sit where the rounded style does, inside
    /// the sidebar's top corner, however tight the window's corners are.
    let windowControlsOffset: CGSize

    // MARK: - Initializers

    private init(
        name: String, title: LocalizedStringResource, toolbarStyle: NSWindow.ToolbarStyle,
        windowControlsOffset: CGSize
    ) {
        self.name = name
        self.title = title
        self.toolbarStyle = toolbarStyle
        self.windowControlsOffset = windowControlsOffset
    }

    // MARK: - Actions - Lookup

    static func named(_ name: String?) -> BrowserWindowCornerStyle? {
        all.first { $0.name == name }
    }
}

// MARK: - Hashable

extension BrowserWindowCornerStyle {
    static func == (lhs: BrowserWindowCornerStyle, rhs: BrowserWindowCornerStyle) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
