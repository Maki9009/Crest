import Foundation

/// How long a tab's page may go unseen before Memory Saver unloads it, or
/// never. An unloaded tab stays in the sidebar and reloads where it was when
/// shown again.
struct BrowserMemorySaver: Hashable, Sendable {
    // MARK: - Static Variables

    static let key = "crest.pages.memory-saver-minutes"
    /// How often the pages are looked over, which bounds how far past its
    /// limit a page can stay loaded.
    static let checkInterval: Duration = .seconds(60)
    static let off = BrowserMemorySaver(idleMinutes: nil, title: "Off")
    static let quarterHour = BrowserMemorySaver(idleMinutes: 15, title: "After 15 Minutes")
    static let halfHour = BrowserMemorySaver(idleMinutes: 30, title: "After 30 Minutes")
    static let hour = BrowserMemorySaver(idleMinutes: 60, title: "After 1 Hour")
    static let twoHours = BrowserMemorySaver(idleMinutes: 120, title: "After 2 Hours")
    static let all = [off, quarterHour, halfHour, hour, twoHours]
    static let standard = hour

    /// The choice the person made, or the standard one.
    @MainActor static var current: BrowserMemorySaver {
        (BrowserChromeAppearancePreference.defaults.object(forKey: key) as? Int).map(named) ?? standard
    }

    // MARK: - Variables

    /// The minutes a page may go unseen, or nil when pages stay loaded until
    /// memory runs short.
    let idleMinutes: Int?
    let title: LocalizedStringResource

    /// The persisted spelling: the minutes, or 0 for off.
    var storedMinutes: Int { idleMinutes ?? 0 }

    // MARK: - Initializers

    private init(idleMinutes: Int?, title: LocalizedStringResource) {
        self.idleMinutes = idleMinutes
        self.title = title
    }

    // MARK: - Actions - Lookup

    static func named(_ minutes: Int) -> BrowserMemorySaver {
        all.first { $0.storedMinutes == minutes } ?? standard
    }
}

// MARK: - Hashable

extension BrowserMemorySaver {
    static func == (lhs: BrowserMemorySaver, rhs: BrowserMemorySaver) -> Bool {
        lhs.idleMinutes == rhs.idleMinutes
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(idleMinutes)
    }
}
