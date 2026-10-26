import SwiftUI

/// The window's address and navigation stay in place while Space contents move
/// underneath. Their native field and popover identities belong to this leaf.
struct SidebarChrome: View {
    let context: BrowserSidebarContext
    let pages: BrowserPagePool
    let address: Binding<String>
    let isAddressEditing: Binding<Bool>
    let addressFocusRequest: Int
    let activateAddress: () -> Void
    let submitAddress: () -> Void
    let commandSurfaceNamespace: Namespace.ID
    let commandPaletteHandoff: BrowserCommandPaletteHandoff

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(BrowserAddressBarPlacement.key, store: BrowserChromeAppearancePreference.defaults)
    private var addressBarPlacementName = BrowserAddressBarPlacement.standard.name

    var body: some View {
        if let space = selectedSpace {
            let isLocked = context.spaceAccess.isLocked(space)

            VStack(spacing: 0) {
                if showsTopBar {
                    // The top bar holds the controls; the strip stays as the
                    // title bar beside the window's buttons, on the bar's row,
                    // so the tabs start level with the page.
                    Color.clear
                        .frame(height: BrowserAddressBarPlacement.topBarBandHeight)
                        .background { BrowserWindowTitleBarSurface() }
                } else {
                    navigationControls
                }

                if context.utilityPresentation.surface == nil, !showsTopBar {
                    SpaceSidebarAddressBand(
                        space: space,
                        offersSiteControls: !context.browser.isDeleting(space.id),
                        selectedTabID: context.browser.selectedTabID(in: space.id),
                        pages: pages,
                        capabilities: context.capabilities,
                        address: address,
                        isAddressEditing: isAddressEditing,
                        addressFocusRequest: addressFocusRequest,
                        activateAddress: activateAddress,
                        submitAddress: submitAddress,
                        commandSurfaceNamespace: commandSurfaceNamespace,
                        commandPaletteHandoff: commandPaletteHandoff,
                        siteControlPresentationChanged: {
                            context.utilityPresentation.setSiteControlPresented($0)
                        },
                        siteControlContextMenuPresentationChanged: {
                            context.utilityPresentation.setSiteControlContextMenuPresented($0)
                        }
                    )
                }
            }
            .modifier(SpaceColorScheme(branding: space.settings.look))
            .modifier(SpaceForegroundBlend(spaces: context.availableSpaces, selectedSpaceID: space.id))
            .blur(radius: isLocked ? BrowserSidebarMetrics.lockedSpaceBlurRadius : 0)
            .redacted(reason: isLocked ? .placeholder : [])
            .allowsHitTesting(!isLocked)
            .accessibilityHidden(isLocked)
        }
    }

    private var navigationControls: some View {
        BrowserSidebarNavigationControls(
            port: BrowserSidebarNavigationPort(
                pages: pages, browser: context.browser, showHistory: context.chromeActions.presentHistory),
            capabilities: context.capabilities
        )
        .contentTransition(.opacity)
        .background {
            // Only the empty navigation-strip background acts as the
            // title bar. Controls and tab gestures keep their input.
            BrowserWindowTitleBarSurface()
        }
        // Another tab's history shows at once, as every browser switches
        // tabs; a fade on each switch redraws the strip every frame.
        .animation(nil, value: pages.activeTabID)
        .animation(
            SpacePagerSettlement.standardAnimation.unlessReducingMotion(reduceMotion),
            value: [pages.canGoBack, pages.canGoForward, pages.activePage?.live.isLoading == true]
        )
    }

    private var showsTopBar: Bool {
        (BrowserAddressBarPlacement.named(addressBarPlacementName) ?? .standard).showsTopBar
    }

    /// The Space the window shows, unless it is being deleted.
    private var selectedSpace: SpaceModel? {
        context.browser.shownSpace
    }
}
