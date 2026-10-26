import AppKit

/// A transparent view that reports where the pointer is over a region capture
/// overlay, from AppKit.
///
/// SwiftUI's continuous hover stops reporting when the view behind it is a
/// live web view. `NSTrackingArea` follows the pointer at the window level
/// instead, while `hitTest` leaves presses to the overlay's own gesture.
@MainActor
final class BrowserRegionCapturePointerTrackingView: NSView {
    var onPointerChange: @MainActor (CGPoint?) -> Void

    private var trackingArea: NSTrackingArea?

    init(onPointerChange: @escaping @MainActor (CGPoint?) -> Void) {
        self.onPointerChange = onPointerChange
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportRestingPointer()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: .zero,
            options: [
                .mouseEnteredAndExited,
                .mouseMoved,
                .activeAlways,
                .inVisibleRect,
            ],
            owner: self
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        onPointerChange(convert(event.locationInWindow, from: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        onPointerChange(convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        // The tracking area is rebuilt as the overlay lays out, which can
        // report an exit for a pointer that never left.
        let location = convert(event.locationInWindow, from: nil)
        guard !bounds.contains(location) else { return }
        onPointerChange(nil)
    }

    /// Frames the element under a pointer that was already over the page
    /// when capture began, without waiting for it to move. It looks once the
    /// overlay has been laid out, since the view joins its window unsized.
    private func reportRestingPointer() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            let location = self.convert(window.mouseLocationOutsideOfEventStream, from: nil)
            guard self.bounds.contains(location) else { return }
            self.onPointerChange(location)
        }
    }
}
