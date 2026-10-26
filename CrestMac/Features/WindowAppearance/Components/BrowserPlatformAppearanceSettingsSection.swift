import SwiftUI

/// The shared Window group, plus the window choices only the desktop has:
/// light or dark, how round the window's corners are, whether the address sits
/// in the sidebar or a top bar, how far dark dims Space
/// colors, Space page motion, how quickly the sidebar moves, the sidebar hover
/// area and whether it stays live over a page in full screen.
struct BrowserPlatformAppearanceSettingsSection: View {
    var space: BrowserSpaceAppearance?
    var showsPreview = false

    @AppStorage(SpacePageMotionPreference.key)
    private var animatesSpacePages = SpacePageMotionPreference.defaultValue
    @Bindable private var appearance = BrowserDeviceAppearanceStore.shared
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
        let mode = CrestSettingValue($appearance.mode, default: BrowserLookAndFeelDefaults.appearanceMode)
        let dimming = CrestSettingValue(
            $appearance.darkSpaceDimming, default: BrowserLookAndFeelDefaults.darkSpaceDimming)

        let motion = CrestSettingValue($animatesSpacePages, default: SpacePageMotionPreference.defaultValue)
        let corners = CrestSettingValue($windowCornerStyleName, default: BrowserWindowCornerStyle.standard.name)
        let addressBar = CrestSettingValue(
            $addressBarPlacementName, default: BrowserAddressBarPlacement.standard.name)
        let matchesPage = CrestSettingValue($topBarMatchesPage, default: true)

        let sidebarSpeed = CrestSettingValue($sidebarRate, default: BrowserSidebarMotionSpeed.standard.rate)
        let revealWidth = CrestSettingValue(
            $appearance.sidebarRevealWidth, default: SidebarRevealWidthPreference.defaultValue)
        let fullscreenReveal = CrestSettingValue(
            $revealsSidebarInFullscreen, default: SidebarFullscreenRevealPreference.defaultValue)

        return BrowserWindowAppearanceGroup(
            space: space,
            showsPreview: showsPreview,
            extraSettings: [
                mode.resettable("Appearance"),
                corners.resettable("Window corners"),
                addressBar.resettable("Address bar"),
                matchesPage.resettable("Match top bar to page"),
                dimming.resettable("Dim Space colors in dark"),
                motion.resettable("Animate pages when switching Spaces"),
                sidebarSpeed.resettable("Sidebar speed"),
                revealWidth.resettable("Sidebar hover area"),
                fullscreenReveal.resettable("Show sidebar on hover in full screen"),
            ]
        ) {
            CrestSettingRow("Appearance", setting: mode.resettable("Appearance")) {
                Picker("Appearance", selection: mode.binding) {
                    ForEach(BrowserAppearanceMode.all, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("appearance-mode")
            }

            CrestSettingRow("Window corners", setting: corners.resettable("Window corners")) {
                Picker("Window corners", selection: corners.binding) {
                    ForEach(BrowserWindowCornerStyle.all, id: \.self) { style in
                        Text(style.title).tag(style.name)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("window-corner-style")
            }

            CrestSettingRow("Address bar", setting: addressBar.resettable("Address bar")) {
                Picker("Address bar", selection: addressBar.binding) {
                    ForEach(BrowserAddressBarPlacement.all, id: \.self) { placement in
                        Text(placement.title).tag(placement.name)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("address-bar-placement")
            }

            if BrowserAddressBarPlacement.named(addressBarPlacementName)?.showsTopBar == true {
                CrestSettingRow(
                    "Match top bar to page", setting: matchesPage.resettable("Match top bar to page")
                ) {
                    Toggle("Match top bar to page", isOn: matchesPage.binding)
                        .labelsHidden()
                        .accessibilityIdentifier("top-bar-matches-page")
                }
            }

            CrestSettingSlider(
                "Dim Space colors in dark",
                value: dimming,
                readout: .percent(zero: "Off", full: "Full"),
                identifier: "dark-space-dimming"
            )

            CrestSettingRow(
                "Animate pages when switching Spaces",
                setting: motion.resettable("Animate pages when switching Spaces")
            ) {
                Toggle("Animate pages when switching Spaces", isOn: motion.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("animate-space-pages")
            }

            CrestSettingSlider(
                "Sidebar speed",
                value: sidebarSpeed,
                range: BrowserSidebarMotionSpeed.range,
                step: BrowserSidebarMotionSpeed.step,
                readout: BrowserSidebarMotionSpeed.readout,
                identifier: "sidebar-speed"
            )

            CrestSettingSlider(
                "Sidebar hover area",
                value: revealWidth,
                range: SidebarRevealWidthPreference.range,
                readout: .points,
                identifier: "sidebar-reveal-width",
                onEditingChanged: { _ in SidebarRevealWidthPreview.shared.adjusted() }
            )
            .onChange(of: appearance.sidebarRevealWidth) { SidebarRevealWidthPreview.shared.adjusted() }

            CrestSettingRow(
                "Show sidebar on hover in full screen",
                setting: fullscreenReveal.resettable("Show sidebar on hover in full screen")
            ) {
                Toggle("Show sidebar on hover in full screen", isOn: fullscreenReveal.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("sidebar-fullscreen-reveal")
            }
        }
    }
}
