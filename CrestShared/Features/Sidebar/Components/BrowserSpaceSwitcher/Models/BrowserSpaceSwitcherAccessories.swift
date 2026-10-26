import SwiftUI

/// The controls a shell asks the Space switcher to carry alongside its
/// Spaces.
///
/// Only an arrangement with room either side of its picker can carry any, so
/// each one is optional and the scrolling track ignores both.
struct BrowserSpaceSwitcherAccessories {
    var downloads: BrowserSpaceSwitcherDownloadsControl?
    var commonLists: BrowserSpaceSwitcherCommonLists?
}

/// The switcher's accessory at the window's edge: the shown Space's downloads
/// at a glance, and the popover that lists them.
///
/// It carries the download center rather than the records, so only the button
/// and its popover read them, and a download's progress redraws nothing else.
struct BrowserSpaceSwitcherDownloadsControl {
    let downloadCenter: BrowserDownloadCenter

    /// The shown Space, or nil while it is locked, which shows no downloads.
    let assignment: BrowserSpaceRuntimeAssignment?

    /// The Space's own accent, which the button wears unless something needs
    /// attention.
    let tint: Color
    let isPresented: Bool
    let setPresented: (Bool) -> Void
    let actions: BrowserUtilityListActions

    /// Opens the full, searchable Downloads list in the sidebar.
    let showAll: () -> Void

    /// Reports where the button ended up, so a starting download flies to it.
    let recordFrame: (CGRect) -> Void

    /// Everything the shown Space's profile has downloaded, newest first.
    @MainActor var items: [DownloadState] {
        guard let assignment else { return [] }
        return downloadCenter.items(for: assignment.profileID).sorted { $0.createdAt > $1.createdAt }
    }

    /// Marks the shown Space's downloads seen, as opening their list does.
    @MainActor func acknowledge() {
        guard let assignment else { return }
        downloadCenter.acknowledgeItems(for: assignment.profileID)
    }
}

/// The switcher's accessory on the page side: the archive, history, and
/// downloads lists.
struct BrowserSpaceSwitcherCommonLists {
    let isExpanded: Bool

    /// The list the button opens and wears the symbol of in the shown Space.
    let surface: BrowserUtilitySurface
    let toggle: () -> Void

    /// Makes another list the one the button opens in the shown Space.
    let choose: (BrowserUtilitySurface) -> Void

    /// Reports where the trigger ended up, so the lists can fan out from it.
    let recordTriggerFrame: (CGRect) -> Void
}
