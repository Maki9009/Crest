import SwiftUI

/// A capture at `size` with the marks over it, which a drag draws on with
/// the markup's current tool and color.
struct BrowserCaptureMarkupCanvas: View {
    let markup: BrowserCaptureMarkup
    let size: CGSize

    var body: some View {
        let scale = size.width > 0 ? size.width / markup.image.size.width * markup.pointScale : 1
        Image(nsImage: markup.image)
            .resizable()
            .frame(width: size.width, height: size.height)
            .overlay {
                Canvas { context, size in
                    for stroke in markup.strokes + [markup.drawing].compactMap(\.self) {
                        stroke.tool.draw(
                            BrowserCaptureMarkup.path(of: stroke, in: size), color: stroke.color.color, scale: scale,
                            in: &context)
                    }
                }
                .allowsHitTesting(false)
            }
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        guard size.width > 0, size.height > 0 else { return }
                        markup.draw(
                            to: CGPoint(
                                x: min(max(value.location.x / size.width, 0), 1),
                                y: min(max(value.location.y / size.height, 0), 1)
                            )
                        )
                    }
                    .onEnded { _ in markup.finishStroke() }
            )
            .pointerStyle(.rectSelection)
            .accessibilityLabel("Capture")
            .accessibilityHint("Drag to draw on the capture")
    }
}
