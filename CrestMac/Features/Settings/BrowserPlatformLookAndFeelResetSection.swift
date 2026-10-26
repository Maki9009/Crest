import SwiftUI

/// The desktop's Reset All: the shared choices, plus Space page motion and the
/// Dock icon.
struct BrowserPlatformLookAndFeelResetSection: View {
    @AppStorage(SpacePageMotionPreference.key)
    private var animatesSpacePages = SpacePageMotionPreference.defaultValue
    @AppStorage(SidebarFullscreenRevealPreference.key, store: BrowserChromeAppearancePreference.defaults)
    private var revealsSidebarInFullscreen = SidebarFullscreenRevealPreference.defaultValue
    @AppStorage(BrowserWindowCornerStyle.key, store: BrowserChromeAppearancePreference.defaults)
    private var windowCornerStyleName = BrowserWindowCornerStyle.standard.name
    @AppStorage(BrowserSidebarMotionSpeed.key, store: BrowserChromeAppearancePreference.defaults)
    private var sidebarRate = BrowserSidebarMotionSpeed.standard.rate
    @AppStorage(BrowserAddressBarPlacement.key, store: BrowserChromeAppearancePreference.defaults)
    private var addressBarPlacementName = BrowserAddressBarPlacement.standard.name
    @AppStorage(BrowserAddressBarPlacement.matchesPageKey, store: BrowserChromeAppearancePreference.defaults)
    private var topBarMatchesPage = true

    var body: some View {
        BrowserLookAndFeelResetFooter {
            animatesSpacePages = SpacePageMotionPreference.defaultValue
            BrowserDeviceAppearanceStore.shared.sidebarRevealWidth = SidebarRevealWidthPreference.defaultValue
            revealsSidebarInFullscreen = SidebarFullscreenRevealPreference.defaultValue
            windowCornerStyleName = BrowserWindowCornerStyle.standard.name
            sidebarRate = BrowserSidebarMotionSpeed.standard.rate
            addressBarPlacementName = BrowserAddressBarPlacement.standard.name
            topBarMatchesPage = true
            _ = BrowserMacDockTile.shared.select("")
        }
    }
}
