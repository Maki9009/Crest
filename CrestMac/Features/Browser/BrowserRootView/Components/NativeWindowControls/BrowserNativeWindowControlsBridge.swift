import SwiftUI

struct BrowserNativeWindowControlsBridge: NSViewRepresentable {
    let isVisible: Bool
    var sidebarOnRight = false
    var sidebarWidth: CGFloat = BrowserChromeLayout.sidebarIdealWidth
    var cornerStyle = BrowserWindowCornerStyle.current
    var buttonCenterY: CGFloat?
    var floatingInset: CGFloat = 0

    func makeNSView(context: Context) -> BrowserNativeWindowControlsHostView {
        let view = BrowserNativeWindowControlsHostView()
        view.sidebarOnRight = sidebarOnRight
        view.sidebarWidth = sidebarWidth
        view.cornerStyle = cornerStyle
        view.buttonCenterY = buttonCenterY
        view.floatingInset = floatingInset
        view.isVisible = isVisible
        return view
    }

    func updateNSView(
        _ nsView: BrowserNativeWindowControlsHostView,
        context: Context
    ) {
        nsView.sidebarWidth = sidebarWidth
        nsView.cornerStyle = cornerStyle
        nsView.buttonCenterY = buttonCenterY
        nsView.floatingInset = floatingInset
        if nsView.isVisible != isVisible {
            // The sidebar slides onto or off the window in this update's
            // animation, and the controls ride with it on the same curve
            // rather than showing before it arrives or going before it leaves.
            let ride = nsView.beginSlidingWindowControls(visible: isVisible)
            context.animate {
                nsView.slideWindowControls()
            } completion: {
                nsView.finishSlidingWindowControls(ride)
            }
        }
        guard nsView.sidebarOnRight != sidebarOnRight else {
            nsView.applyBrowserChrome()
            return
        }
        // The sidebar crosses the window in this update's animation, and the
        // controls go with it on the same curve.
        context.animate {
            nsView.moveWindowControls(sidebarOnRight: sidebarOnRight)
        } completion: {
            nsView.finishMovingWindowControls()
        }
    }

    static func dismantleNSView(
        _ nsView: BrowserNativeWindowControlsHostView,
        coordinator: Void
    ) {
        nsView.restoreWindowChrome()
    }
}
