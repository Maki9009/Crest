import SwiftUI

/// Copies the address of the page the field shows, as Copy Page Link does,
/// and turns into a checkmark for a moment to say so.
struct BrowserAddressCopyLinkButton: View {
    /// How long the checkmark shows after a copy.
    private static let copiedDuration: Duration = .milliseconds(1400)

    let page: BrowserPage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Counts copies, so each one restarts the time the checkmark shows for.
    @State private var copyCount = 0
    @State private var showsCopied = false

    var body: some View {
        Button {
            guard page.copyPageLink() else { return }
            withAnimation(animation) { showsCopied = true }
            copyCount += 1
        } label: {
            Image(systemName: showsCopied ? "checkmark" : "link")
                .font(.system(size: BrowserTabTrailingControlMetrics.pointer.glyphSize, weight: .medium))
                .contentTransition(.symbolEffect(.replace))
                .frame(
                    width: BrowserSiteControlMetrics.triggerSize.width,
                    height: BrowserSiteControlMetrics.triggerSize.height
                )
                .contentShape(.rect)
        }
        .buttonStyle(CrestChromeButtonStyle(controlSize: BrowserSiteControlMetrics.triggerSize))
        .foregroundStyle(.secondary)
        .help(Text("Copy Link"))
        .accessibilityLabel(showsCopied ? Text("Link Copied") : Text("Copy Link"))
        .task(id: copyCount) {
            guard showsCopied else { return }
            try? await Task.sleep(for: Self.copiedDuration)
            guard !Task.isCancelled else { return }
            withAnimation(animation) { showsCopied = false }
        }
    }

    private var animation: Animation? {
        CrestMotion.contentState.unlessReducingMotion(reduceMotion)
    }
}
