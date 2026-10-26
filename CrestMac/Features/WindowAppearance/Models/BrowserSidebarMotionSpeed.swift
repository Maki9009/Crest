import SwiftUI

/// How quickly the sidebar slides in, slides away, floats and docks: a rate
/// over Crest's own pacing, whose top end moves it without animating.
struct BrowserSidebarMotionSpeed: Hashable, Sendable {
    // MARK: - Static Variables

    static let key = "crest.appearance.sidebar-rate"
    static let range: ClosedRange<Double> = 1...5
    static let step = 0.25
    static let standard = BrowserSidebarMotionSpeed(rate: 1)

    /// Names the rate as the slider shows it, with its top end as Instant.
    static let readout = CrestSettingSliderReadout { rate in
        rate >= range.upperBound
            ? String(localized: "Instant")
            : rate.formatted(.number.precision(.fractionLength(0...2))) + "×"
    }

    /// The speed the person chose, or the standard one.
    @MainActor static var current: BrowserSidebarMotionSpeed {
        BrowserSidebarMotionSpeed(rate: BrowserChromeAppearancePreference.defaults.object(forKey: key) as? Double)
    }

    // MARK: - Variables

    /// How many times faster than Crest's own pacing the sidebar moves.
    let rate: Double

    /// Whether the sidebar moves without animating.
    var isInstant: Bool { rate >= Self.range.upperBound }

    // MARK: - Initializers

    /// The speed at `rate`, kept within the range; the standard one without.
    init(rate: Double?) {
        self.rate = min(max(rate ?? Self.range.lowerBound, Self.range.lowerBound), Self.range.upperBound)
    }

    // MARK: - Actions - Pacing

    /// `animation` at this speed, or nil when the sidebar does not animate.
    func animation(_ animation: Animation) -> Animation? {
        isInstant ? nil : animation.speed(rate)
    }

    /// How long a sidebar step that takes `duration` at Crest's own pacing
    /// takes at this speed.
    func duration(_ duration: Duration) -> Duration {
        isInstant ? .zero : duration / rate
    }
}
