import SwiftUI

/// Adds the window server's pointer tracking to the region capture overlay
/// without taking presses away from its selection gesture.
struct BrowserRegionCapturePointerTracker: NSViewRepresentable {
    let onPointerChange: @MainActor (CGPoint?) -> Void

    func makeNSView(context: Context) -> BrowserRegionCapturePointerTrackingView {
        BrowserRegionCapturePointerTrackingView(onPointerChange: onPointerChange)
    }

    func updateNSView(_ nsView: BrowserRegionCapturePointerTrackingView, context: Context) {
        nsView.onPointerChange = onPointerChange
    }
}
