import AppKit
import SwiftUI

/// A captured part of a page and the marks the person draws over it before
/// copying, saving or sharing it.
@MainActor
@Observable
final class BrowserCaptureMarkup: Identifiable {
    // MARK: - Types

    struct Stroke: Equatable {
        let tool: BrowserCaptureMarkupTool
        let color: BrowserCaptureMarkupColor
        /// Points as fractions of the capture's width and height, so a stroke
        /// lands in the same place however large the preview shows it.
        var points: [CGPoint]
    }

    // MARK: - Variables

    let id = UUID()
    let image: NSImage
    /// How many of the image's units make one of the page's points, so marks
    /// keep their weight however the engine sized the image it captured.
    let pointScale: CGFloat
    private(set) var strokes: [Stroke] = []
    private(set) var drawing: Stroke?
    var tool = BrowserCaptureMarkupTool.pen
    var color = BrowserCaptureMarkupColor.coral

    var hasMarks: Bool { !strokes.isEmpty }

    // MARK: - Initializers

    init(image: NSImage, pointScale: CGFloat) {
        self.image = image
        self.pointScale = pointScale
    }

    // MARK: - Actions - Drawing

    /// Extends the stroke under way to `point`, a fraction of the capture's
    /// size, or starts one there.
    func draw(to point: CGPoint) {
        if drawing == nil {
            drawing = Stroke(tool: tool, color: color, points: [point])
        } else {
            drawing?.points.append(point)
        }
    }

    func finishStroke() {
        guard let drawing else { return }
        strokes.append(drawing)
        self.drawing = nil
    }

    func undo() {
        _ = strokes.popLast()
    }

    func clear() {
        strokes.removeAll()
    }

    // MARK: - Actions - Rendering

    /// The path `stroke` takes over a capture drawn at `size`.
    static func path(of stroke: Stroke, in size: CGSize) -> Path {
        var path = Path()
        guard let first = stroke.points.first else { return path }
        path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
        for point in stroke.points.dropFirst() {
            path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
        }
        if stroke.points.count == 1 {
            path.addLine(to: CGPoint(x: first.x * size.width + 0.1, y: first.y * size.height))
        }
        return path
    }

    /// The capture with every finished stroke drawn into it, at the capture's
    /// own resolution.
    func rendered() -> NSImage {
        guard hasMarks else { return image }
        let size = image.size
        let marks = strokes
        let image = image
        let pointScale = pointScale
        let renderer = ImageRenderer(
            content: ZStack {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                Canvas { context, size in
                    for stroke in marks {
                        stroke.tool.draw(
                            Self.path(of: stroke, in: size), color: stroke.color.color, scale: pointScale,
                            in: &context)
                    }
                }
                .frame(width: size.width, height: size.height)
            }
        )
        renderer.scale = image.representations.first.map { CGFloat($0.pixelsWide) / max(size.width, 1) } ?? 1
        return renderer.nsImage ?? image
    }

    /// The marked-up capture as PNG data, or nil when it cannot be encoded.
    func pngData() -> Data? {
        let image = rendered()
        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
