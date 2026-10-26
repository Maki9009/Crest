import SwiftUI

/// How Capture Page looks and where what it takes goes.
struct BrowserPageCaptureSettingsSection: View {
    @AppStorage(BrowserCaptureOutline.key, store: BrowserChromeAppearancePreference.defaults)
    private var outlineName = BrowserCaptureOutline.standard.name
    @AppStorage(BrowserCaptureDestination.key, store: BrowserChromeAppearancePreference.defaults)
    private var destinationName = BrowserCaptureDestination.standard.name

    var body: some View {
        Section("Capture Page") {
            Picker("Outline", selection: $outlineName) {
                ForEach(BrowserCaptureOutline.all, id: \.self) { outline in
                    Text(outline.title).tag(outline.name)
                }
            }
            .accessibilityIdentifier("capture-outline")

            Picker("After capturing", selection: $destinationName) {
                ForEach(BrowserCaptureDestination.all, id: \.self) { destination in
                    Text(destination.title).tag(destination.name)
                }
            }
            .accessibilityIdentifier("capture-destination")
        }
    }
}
