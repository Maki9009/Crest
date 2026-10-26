import SwiftUI

/// The thin bar above the page that holds the page controls when the person
/// keeps them out of the sidebar: the sidebar, back, forward and reload
/// controls at its leading end, the site's name in the middle with a button
/// that copies the page's link, and the site controls at its trailing end.
/// Clicking the name opens the command bar, as the sidebar's field does. The
/// bar is the top of the page's card and can take the colour across the top
/// of the page, so it reads as part of the site. On a page in developer mode
/// the bar is the developer toolbar, its full address and tools in place of
/// the site's name, so the page keeps one bar rather than two.
struct BrowserTopBar: View {
    /// Where the bar sits: at the top of the page's card, or on the window's
    /// frame above cards shown side by side.
    enum Placement {
        case inCard
        case aboveCards
    }

    // MARK: - Static Variables

    private static let controlSize = CGSize(width: 26, height: 26)
    private static let linkControlSize = CGSize(width: 22, height: 22)
    private static let controlSpacing: CGFloat = 2
    private static let symbolFont = Font.system(size: 14, weight: .medium)
    private static let addressFont = Font.system(size: 13, weight: .semibold)
    private static let linkSymbolFont = Font.system(size: 12, weight: .semibold)
    private static let addressSpacing: CGFloat = 4
    private static let horizontalPadding: CGFloat = 6
    /// How far the centered address keeps from each end, so it never runs
    /// under the controls there.
    private static let addressInset: CGFloat = 136
    /// How long the address says the link was copied.
    private static let copiedDuration: Duration = .milliseconds(1400)
    /// The relative luminance under which a page's colour carries light
    /// controls.
    private static let darkTintLuminance = 0.55
    /// How strongly the hairline between the bar and the page shows, over the
    /// bar's own colour.
    private static let separatorOpacity = 0.12

    // MARK: - Variables

    let model: BrowserRootModel
    let space: SpaceModel
    let placement: Placement

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.displayScale) private var displayScale
    @AppStorage(BrowserAddressBarPlacement.matchesPageKey, store: BrowserChromeAppearancePreference.defaults)
    private var matchesPage = true
    /// Counts link copies, so each one restarts the time the copied state
    /// shows for.
    @State private var copyCount = 0
    @State private var showsCopied = false

    var body: some View {
        ZStack {
            if let page = developerPage(in: space) {
                HStack(spacing: Self.controlSpacing) {
                    navigationControls
                    BrowserDeveloperToolbarDivider()
                    BrowserDeveloperToolbarContent(
                        page: page, browser: model.browser, pages: model.pages,
                        permissionCenter: model.pages.permissionCenter
                    )
                    // A new page in developer mode starts its own address.
                    .id(ObjectIdentifier(page))
                    siteControlButton(in: space)
                }
            } else {
                HStack(spacing: Self.controlSpacing) {
                    navigationControls
                    Spacer(minLength: 0)
                    siteControlButton(in: space)
                }

                address(in: space)
                    .padding(.horizontal, Self.addressInset)
            }
        }
        .padding(.horizontal, Self.horizontalPadding)
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        // Above cards, the frame's top edge is part of the bar, so its
        // controls stay level with the window's buttons.
        .padding(.top, placement == .aboveCards ? frameWidth : 0)
        .background { background(in: space) }
        .animation(CrestMotion.palette.unlessReducingMotion(reduceMotion), value: tint(in: space))
        .task(id: copyCount) { await showCopied() }
        .task(id: topColorReading(in: space)) {
            guard matchesPage, let page = displayedPage(in: space) else { return }
            await page.refreshTopColor()
        }
        .modifier(colorScheme(in: space))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Address Bar"))
    }

    private var navigationControls: some View {
        HStack(spacing: Self.controlSpacing) {
            Button {
                model.toggleSidebar(reduceMotion: reduceMotion)
            } label: {
                Label(sidebarToggleTitle, systemImage: "sidebar.left")
            }
            .help(Text(sidebarToggleTitle))

            Button(action: port.goBack) {
                Label("Back", systemImage: "arrow.left")
            }
            .disabled(!port.canGoBack())
            .help(Text("Back"))
            .modifier(
                BrowserPlatformNavigationHistoryMenuModifier(
                    items: port.backHistory,
                    emptyTitle: BrowserSidebarNavigationControl.back.emptyHistoryTitle,
                    choose: port.goBackToHistoryItem,
                    showFullHistory: port.showHistory
                )
            )

            Button(action: port.goForward) {
                Label("Forward", systemImage: "arrow.right")
            }
            .disabled(!port.canGoForward())
            .help(Text("Forward"))
            .modifier(
                BrowserPlatformNavigationHistoryMenuModifier(
                    items: port.forwardHistory,
                    emptyTitle: BrowserSidebarNavigationControl.forward.emptyHistoryTitle,
                    choose: port.goForwardToHistoryItem,
                    showFullHistory: port.showHistory
                )
            )

            Button(action: port.reloadOrStop) {
                Label(reloadTitle, systemImage: port.isLoading() ? "xmark" : "arrow.clockwise")
            }
            .disabled(!port.hasActivePage())
            .help(Text(reloadTitle))
        }
        .font(Self.symbolFont)
        .labelStyle(.iconOnly)
        .buttonStyle(CrestChromeButtonStyle(controlSize: Self.controlSize))
        .foregroundStyle(.secondary)
        // Another tab's history shows at once, as the sidebar's strip does.
        .animation(nil, value: model.pages.activeTabID)
    }

    @ViewBuilder
    private func siteControlButton(in space: SpaceModel) -> some View {
        if let siteControl = siteControl(in: space) {
            BrowserSiteControlButton(configuration: siteControl)
        }
    }

    /// The site's name, with the page's link button before it and, on a page
    /// that is not secure, a warning that opens its certificate.
    private func address(in space: SpaceModel) -> some View {
        HStack(spacing: Self.addressSpacing) {
            if let page = displayedPage(in: space), page.live.displayURL != nil {
                if !page.live.security.isSecure {
                    BrowserAddressSecurityButton(page: page, isSecure: false)
                }
                Button {
                    guard page.copyPageLink() else { return }
                    withAnimation(CrestMotion.contentState.unlessReducingMotion(reduceMotion)) { showsCopied = true }
                    copyCount += 1
                } label: {
                    Image(systemName: showsCopied ? "checkmark" : "link")
                        .font(Self.linkSymbolFont)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(CrestChromeButtonStyle(controlSize: Self.linkControlSize))
                .foregroundStyle(.secondary)
                .help(Text("Copy Link"))
                .accessibilityLabel(Text("Copy Link"))
            }

            Button {
                model.chrome.openLocation(model.address)
            } label: {
                addressLabel(in: space)
                    .font(Self.addressFont)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .help(Text("Search or enter website"))
            .accessibilityHint(Text("Opens the command bar"))
        }
    }

    @ViewBuilder
    private func addressLabel(in space: SpaceModel) -> some View {
        if showsCopied {
            Text("Copied")
                .foregroundStyle(.primary)
                .transition(addressTransition)
        } else if let name = siteName(in: space) {
            Text(verbatim: name)
                .foregroundStyle(.primary)
                .transition(addressTransition)
        } else {
            Text("Search or enter website")
                .foregroundStyle(.tertiary)
        }
    }

    /// The page's colour or the card's own, with a soft hairline above the
    /// page; over the Start Page the Space shows through. The window moves
    /// from any of it the controls leave free.
    private func background(in space: SpaceModel) -> some View {
        let showsPage = displayedPage(in: space)?.live.displayURL != nil
        return ZStack {
            if developerPage(in: space) != nil {
                BrowserDeveloperToolbarBackground(isOpaque: reduceTransparency)
            } else if let tint = tint(in: space) {
                Color(nsColor: tint)
            } else if placement == .inCard, showsPage {
                Rectangle().fill(.background)
            }
            BrowserWindowTitleBarSurface()
        }
        .overlay(alignment: .bottom) {
            if placement == .inCard, showsPage {
                Rectangle()
                    .fill(Color.primary.opacity(Self.separatorOpacity))
                    .frame(height: 1 / displayScale)
                    .allowsHitTesting(false)
            }
        }
    }

    /// The page's colour the bar takes: the one the site declares, or the
    /// one across its top. Nil where the bar keeps the Space's.
    private func tint(in space: SpaceModel) -> NSColor? {
        guard matchesPage, developerPage(in: space) == nil, let page = displayedPage(in: space),
            page.live.displayURL != nil
        else { return nil }
        return page.themeColor ?? page.topColor
    }

    /// Light controls on a dark page colour and dark ones on a light one, or
    /// the Space's own scheme.
    private func colorScheme(in space: SpaceModel) -> BrowserTopBarColorScheme {
        BrowserTopBarColorScheme(
            branding: space.settings.look,
            tintScheme: tint(in: space)?.usingColorSpace(.sRGB).map { color in
                let luminance =
                    0.2126 * color.redComponent + 0.7152 * color.greenComponent + 0.0722 * color.blueComponent
                return luminance < Self.darkTintLuminance ? .dark : .light
            })
    }

    /// Changes whenever the shown page may have a new colour across its top.
    private func topColorReading(in space: SpaceModel) -> [AnyHashable] {
        let page = displayedPage(in: space)
        return [matchesPage, page.map(ObjectIdentifier.init), page?.completedNavigationCount, page?.live.displayURL]
    }

    /// The height of the bar under the window's frame.
    private var barHeight: CGFloat {
        BrowserAddressBarPlacement.topBarHeight(frameWidth: frameWidth)
    }

    private var frameWidth: CGFloat {
        BrowserChromeAppearance.device(windowCornerRadius: nil).frameWidth
    }

    private var addressTransition: AnyTransition {
        reduceMotion ? .opacity : .push(from: .bottom)
    }

    private var sidebarToggleTitle: LocalizedStringKey {
        model.sidebarPresentation.reservesSidebarWidth ? "Hide Sidebar" : "Show Sidebar"
    }

    private var reloadTitle: LocalizedStringKey {
        port.isLoading() ? "Stop" : "Reload"
    }

    private var port: BrowserSidebarNavigationPort {
        BrowserSidebarNavigationPort(
            pages: model.pages, browser: model.browser, showHistory: { model.chrome.presentUtility(.history) })
    }

    // MARK: - Actions - Copy

    /// Goes back to the site's name a moment after the link was copied.
    private func showCopied() async {
        guard showsCopied else { return }
        try? await Task.sleep(for: Self.copiedDuration)
        guard !Task.isCancelled else { return }
        withAnimation(CrestMotion.contentState.unlessReducingMotion(reduceMotion)) { showsCopied = false }
    }

    // MARK: - Actions - Page

    private func displayedPage(in space: SpaceModel) -> BrowserPage? {
        guard let tabID = model.browser.selectedTabID(in: space.id) else { return nil }
        return model.pages.activePage(
            matching: BrowserTabRuntimeAssignment(tabID: tabID, spaceID: space.id, profileID: space.profileID))
    }

    /// The shown page when it is in developer mode and the bar holds its
    /// developer toolbar; cards side by side keep a toolbar each.
    private func developerPage(in space: SpaceModel) -> BrowserPage? {
        guard placement == .inCard, let page = displayedPage(in: space), page.isDeveloperModeEnabled else {
            return nil
        }
        return page
    }

    /// The host the page shows, without a leading "www.", or its whole
    /// address when it has no host.
    private func siteName(in space: SpaceModel) -> String? {
        guard let url = displayedPage(in: space)?.live.displayURL else { return nil }
        guard let host = url.host(), !host.isEmpty else { return url.absoluteString }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private func siteControl(in space: SpaceModel) -> BrowserSiteControlConfiguration? {
        guard !model.browser.isDeleting(space.id), let page = displayedPage(in: space),
            page.live.displayURL != nil
        else { return nil }
        return BrowserSiteControlConfiguration(
            page: page,
            space: space,
            selectedTabID: model.browser.selectedTabID(in: space.id),
            permissionCenter: model.pages.permissionCenter,
            presentationChanged: { model.chrome.utilityPresentation.setSiteControlPresented($0) },
            contextMenuPresentationChanged: {
                model.chrome.utilityPresentation.setSiteControlContextMenuPresented($0)
            }
        )
    }
}

/// The colour scheme of the top bar's controls: the one its page colour
/// needs, or the Space's.
private struct BrowserTopBarColorScheme: ViewModifier {
    let branding: SpaceBranding?
    let tintScheme: ColorScheme?

    func body(content: Content) -> some View {
        if let tintScheme {
            content.environment(\.colorScheme, tintScheme)
        } else {
            content.modifier(SpaceColorScheme(branding: branding))
        }
    }
}

extension EnvironmentValues {
    /// Whether the top bar above the page's card holds the page's developer
    /// toolbar, so the page shows no bar of its own for it.
    @Entry var browserTopBarHostsDeveloperToolbar = false
}
