import Foundation

/// Where the window keeps the page's address and its back, forward and
/// reload controls: at the top of the sidebar, or in a thin bar above the
/// page.
struct BrowserAddressBarPlacement: Hashable, Sendable {
    // MARK: - Static Variables

    static let key = "crest.appearance.address-bar-placement"
    /// Whether the top bar takes the colour across the top of the page.
    static let matchesPageKey = "crest.appearance.top-bar-matches-page"
    /// How far the page's content sits below the window's top edge with the
    /// top bar on: the page's frame above the bar, then the bar itself, at
    /// the top of the page's card. The sidebar's tabs start level with it.
    static let topBarBandHeight: CGFloat = 40
    static let sidebar = BrowserAddressBarPlacement(name: "sidebar", title: "Sidebar", showsTopBar: false)
    static let topBar = BrowserAddressBarPlacement(name: "top-bar", title: "Top Bar", showsTopBar: true)
    static let all = [sidebar, topBar]
    static let standard = sidebar

    /// The placement the person chose, or the standard one.
    @MainActor static var current: BrowserAddressBarPlacement {
        named(BrowserChromeAppearancePreference.defaults.string(forKey: key)) ?? standard
    }

    // MARK: - Variables

    /// The persisted spelling.
    let name: String
    let title: LocalizedStringResource
    /// Whether the address and its controls sit in a bar above the page
    /// rather than at the top of the sidebar.
    let showsTopBar: Bool

    // MARK: - Initializers

    private init(name: String, title: LocalizedStringResource, showsTopBar: Bool) {
        self.name = name
        self.title = title
        self.showsTopBar = showsTopBar
    }

    // MARK: - Actions - Layout

    /// The height of the top bar inside the page's card, under a frame
    /// `frameWidth` wide.
    static func topBarHeight(frameWidth: CGFloat) -> CGFloat {
        topBarBandHeight - frameWidth
    }

    /// How far below the window's top edge the centers of its close, minimize
    /// and zoom buttons sit, level with the top bar's controls, or nil where
    /// the window's corner style seats them.
    func windowControlsCenterY(frameWidth: CGFloat) -> CGFloat? {
        showsTopBar ? frameWidth + Self.topBarHeight(frameWidth: frameWidth) / 2 : nil
    }

    // MARK: - Actions - Lookup

    static func named(_ name: String?) -> BrowserAddressBarPlacement? {
        all.first { $0.name == name }
    }
}

// MARK: - Hashable

extension BrowserAddressBarPlacement {
    static func == (lhs: BrowserAddressBarPlacement, rhs: BrowserAddressBarPlacement) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
