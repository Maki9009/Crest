import SwiftUI

/// The part of a page someone just captured, shown over the page to mark up
/// and then copy, save or share. Escape or a click outside closes it.
struct BrowserCapturePreview: View {
    // MARK: - Static Variables

    /// How much of the page the capture may fill.
    private static let maximumFill: CGFloat = 0.84
    private static let toolbarAllowance: CGFloat = 64
    /// How far past its own size a small capture may grow to fill the
    /// preview, before its pixels would show.
    private static let maximumEnlargement: CGFloat = 2
    /// How dark the page goes behind the capture, so the capture stands out.
    private static let backdropOpacity = 0.62
    private static let outlineWidth: CGFloat = 3

    // MARK: - Variables

    let page: BrowserPage
    let markup: BrowserCaptureMarkup
    /// The color of the page's Space, which the capture's outline takes
    /// unless the person chose another.
    var spaceAccent: Color?

    @AppStorage(BrowserCaptureOutline.key, store: BrowserChromeAppearancePreference.defaults)
    private var outlineName = BrowserCaptureOutline.standard.name
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var appeared = false

    var body: some View {
        GeometryReader { proxy in
            let size = displaySize(in: proxy.size)
            ZStack {
                Rectangle()
                    .fill(.black.opacity(Self.backdropOpacity))
                    .contentShape(.rect)
                    .onTapGesture(perform: page.closeCapturePreview)
                    .accessibilityHidden(true)
                VStack(spacing: 14) {
                    BrowserCaptureMarkupCanvas(markup: markup, size: size)
                        .clipShape(.rect(cornerRadius: CrestRadius.compact, style: .continuous))
                        .padding(Self.outlineWidth)
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: CrestRadius.compact + Self.outlineWidth, style: .continuous
                            )
                            .strokeBorder(outlineColor, lineWidth: Self.outlineWidth)
                        }
                        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
                    BrowserCapturePreviewToolbar(page: page, markup: markup)
                }
                .scaleEffect(appeared ? 1 : 0.94)
                .opacity(appeared ? 1 : 0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear {
            isFocused = true
            withAnimation(CrestMotion.floatingPane.unlessReducingMotion(reduceMotion)) { appeared = true }
        }
        .onExitCommand(perform: page.closeCapturePreview)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Page capture")
        .accessibilityIdentifier("page-capture-preview")
    }

    private var outlineColor: Color {
        (BrowserCaptureOutline.named(outlineName) ?? .standard).color(spaceAccent: spaceAccent)
    }

    /// The capture at the size that fills the preview, with room for the
    /// toolbar beneath it: shrunk to fit, or grown so a small capture is
    /// easy to see and draw on.
    private func displaySize(in bounds: CGSize) -> CGSize {
        let natural = CGSize(
            width: markup.image.size.width / markup.pointScale,
            height: markup.image.size.height / markup.pointScale
        )
        guard natural.width > 0, natural.height > 0 else { return .zero }
        let available = CGSize(
            width: bounds.width * Self.maximumFill,
            height: max(bounds.height * Self.maximumFill - Self.toolbarAllowance, 1)
        )
        let scale = min(
            Self.maximumEnlargement, available.width / natural.width, available.height / natural.height)
        return CGSize(width: natural.width * scale, height: natural.height * scale)
    }
}
