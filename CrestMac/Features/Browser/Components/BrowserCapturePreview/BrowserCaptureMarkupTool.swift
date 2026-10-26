import SwiftUI

/// What a stroke over a capture draws with: a pen's solid line, or a
/// highlighter's broad translucent one.
struct BrowserCaptureMarkupTool: Hashable, Sendable {
    // MARK: - Static Variables

    static let pen = BrowserCaptureMarkupTool(
        name: "pen", title: "Pen", systemImage: "pencil.tip", lineWidth: 4, opacity: 1)
    static let highlighter = BrowserCaptureMarkupTool(
        name: "highlighter", title: "Highlighter", systemImage: "highlighter", lineWidth: 18, opacity: 0.4)
    static let all = [pen, highlighter]

    // MARK: - Variables

    let name: String
    let title: LocalizedStringResource
    let systemImage: String
    /// The line's width in the capture's own points.
    let lineWidth: CGFloat
    let opacity: Double

    // MARK: - Initializers

    private init(name: String, title: LocalizedStringResource, systemImage: String, lineWidth: CGFloat, opacity: Double)
    {
        self.name = name
        self.title = title
        self.systemImage = systemImage
        self.lineWidth = lineWidth
        self.opacity = opacity
    }

    // MARK: - Actions - Drawing

    /// Strokes `path` in `color`, scaled from the capture's points by `scale`.
    func draw(_ path: Path, color: Color, scale: CGFloat = 1, in context: inout GraphicsContext) {
        context.stroke(
            path,
            with: .color(color.opacity(opacity)),
            style: StrokeStyle(lineWidth: lineWidth * scale, lineCap: .round, lineJoin: .round)
        )
    }
}

// MARK: - Hashable

extension BrowserCaptureMarkupTool {
    static func == (lhs: BrowserCaptureMarkupTool, rhs: BrowserCaptureMarkupTool) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
