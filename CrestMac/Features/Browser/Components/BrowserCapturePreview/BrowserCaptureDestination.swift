import Foundation

/// Where a page capture goes once it is taken: into a preview to mark up and
/// then copy, save or share, or straight to the clipboard.
struct BrowserCaptureDestination: Hashable, Sendable {
    // MARK: - Static Variables

    static let key = "crest.capture.destination"
    static let preview = BrowserCaptureDestination(name: "preview", title: "Open Preview", opensPreview: true)
    static let clipboard = BrowserCaptureDestination(name: "clipboard", title: "Copy to Clipboard", opensPreview: false)
    static let all = [preview, clipboard]
    static let standard = preview

    /// The destination the person chose, or the standard one.
    @MainActor static var current: BrowserCaptureDestination {
        named(BrowserChromeAppearancePreference.defaults.string(forKey: key)) ?? standard
    }

    // MARK: - Variables

    /// The persisted spelling.
    let name: String
    let title: LocalizedStringResource
    let opensPreview: Bool

    // MARK: - Initializers

    private init(name: String, title: LocalizedStringResource, opensPreview: Bool) {
        self.name = name
        self.title = title
        self.opensPreview = opensPreview
    }

    // MARK: - Actions - Lookup

    static func named(_ name: String?) -> BrowserCaptureDestination? {
        all.first { $0.name == name }
    }
}

// MARK: - Hashable

extension BrowserCaptureDestination {
    static func == (lhs: BrowserCaptureDestination, rhs: BrowserCaptureDestination) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
