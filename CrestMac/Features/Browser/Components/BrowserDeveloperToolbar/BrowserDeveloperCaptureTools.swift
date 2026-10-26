import SwiftUI

struct BrowserDeveloperCaptureControls: View {
    let page: BrowserPage
    @Binding var showsCaptureOptions: Bool

    var body: some View {
        HStack(spacing: BrowserDeveloperToolbarMetrics.itemSpacing) {
            BrowserDeveloperToolbarButton(
                label: "Capture Window",
                systemImage: "rectangle.inset.filled",
                isActive: showsCaptureOptions,
                action: { showsCaptureOptions.toggle() }
            )
            .disabled(!page.pageEngine.registration.supports(.fullPageCapture))
            .popover(isPresented: $showsCaptureOptions, arrowEdge: .top) {
                BrowserDeveloperCaptureOptions(page: page)
            }

            BrowserDeveloperToolbarButton(
                label: "Capture",
                systemImage: "camera",
                isActive: page.isRegionCapturePresented,
                action: page.beginRegionCapture
            )
            .disabled(!page.pageEngine.registration.supports(.viewportCapture))
        }
    }
}

struct BrowserRegionCaptureOverlay: View {
    /// The shortest side a region capture may have.
    private static let minimumSelectionLength: CGFloat = 12
    /// How far a press may move and still count as a click on the element
    /// under the pointer rather than the start of a drag.
    private static let clickSlop: CGFloat = 4
    private static let highlightCornerRadius: CGFloat = 6

    let page: BrowserPage
    /// The color of the page's Space, which the outline wears unless the
    /// person chose another.
    var spaceAccent: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(BrowserCaptureOutline.key, store: BrowserChromeAppearancePreference.defaults)
    private var outlineName = BrowserCaptureOutline.standard.name
    @State private var dragStart: CGPoint?
    @State private var dragEnd: CGPoint?
    @State private var targetElement: CGRect?
    /// Where the pointer was when `targetElement` was found.
    @State private var targetPointer: CGPoint?
    @State private var pendingPointer: CGPoint?
    @State private var isPointerInside = false
    @State private var isFindingElement = false
    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let bounds = proxy.frame(in: .local)
            let highlight = highlightRect(in: bounds)
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(.black.opacity(0.38))
                    .mask {
                        Rectangle()
                            .overlay(alignment: .topLeading) {
                                if let highlight {
                                    RoundedRectangle(cornerRadius: Self.highlightCornerRadius, style: .continuous)
                                        .frame(width: highlight.width, height: highlight.height)
                                        .offset(x: highlight.minX, y: highlight.minY)
                                        .blendMode(.destinationOut)
                                }
                            }
                            .compositingGroup()
                    }
                if let highlight {
                    RoundedRectangle(cornerRadius: Self.highlightCornerRadius, style: .continuous)
                        .strokeBorder(
                            (BrowserCaptureOutline.named(outlineName) ?? .standard).color(spaceAccent: spaceAccent),
                            style: isDragging
                                ? StrokeStyle(lineWidth: 2, dash: [6, 4])
                                : StrokeStyle(lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.45), radius: 6)
                        .frame(width: highlight.width, height: highlight.height)
                        .offset(x: highlight.minX, y: highlight.minY)
                }
            }
            .animation(
                isDragging ? nil : CrestMotion.captureTarget.unlessReducingMotion(reduceMotion),
                value: highlight
            )
            .contentShape(.rect)
            .gesture(captureGesture(in: bounds))
            .background {
                BrowserRegionCapturePointerTracker(onPointerChange: pointerMoved)
            }
            .overlay(alignment: .bottom) {
                BrowserRegionCaptureInstruction()
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onExitCommand(perform: page.cancelRegionCapture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page capture selection")
        .accessibilityHint("Click an element or drag a rectangle to capture that part of the page")
        .accessibilityIdentifier("developer-region-capture")
    }

    /// Whether the press under way has moved far enough to be a drag.
    private var isDragging: Bool {
        guard let dragStart, let dragEnd else { return false }
        return hypot(dragEnd.x - dragStart.x, dragEnd.y - dragStart.y) > Self.clickSlop
    }

    /// What the overlay frames: the rectangle being dragged, or else the
    /// element a click would capture.
    private func highlightRect(in bounds: CGRect) -> CGRect? {
        if isDragging { return selectionRect(in: bounds) }
        return targetElement.map { $0.intersection(bounds) }.flatMap { $0.isNull || $0.isEmpty ? nil : $0 }
    }

    private func captureGesture(in bounds: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = value.startLocation
                }
                dragEnd = value.location
            }
            .onEnded { value in
                let start = dragStart ?? value.startLocation
                let dragged = isDragging
                dragStart = nil
                dragEnd = nil
                // A drag too short to select a rectangle is still a click.
                if dragged, let rect = Self.captureRect(from: start, to: value.location, in: bounds) {
                    page.captureRegion(rect)
                } else {
                    captureElement(at: value.location, in: bounds)
                }
            }
    }

    /// Captures the element under `location`. The framed one is used only when
    /// it was found for this spot; otherwise the page is asked again, so a
    /// click never takes the element the pointer just left.
    private func captureElement(at location: CGPoint, in bounds: CGRect) {
        if !isFindingElement, let targetPointer,
            hypot(targetPointer.x - location.x, targetPointer.y - location.y) <= Self.clickSlop,
            let element = highlightRect(in: bounds)
        {
            page.captureRegion(element)
            return
        }
        Task { @MainActor in
            guard let element = await page.regionCaptureElement(at: location)?.intersection(bounds),
                !element.isNull, !element.isEmpty
            else { return }
            page.captureRegion(element)
        }
    }

    private func pointerMoved(to location: CGPoint?) {
        guard let location else {
            isPointerInside = false
            targetElement = nil
            targetPointer = nil
            return
        }
        isPointerInside = true
        findElement(at: location)
    }

    /// Asks the page for the element under `location`. Only one lookup runs
    /// at a time; the pointer's latest position is looked up next, so a fast
    /// pointer never queues stale work.
    private func findElement(at location: CGPoint) {
        pendingPointer = location
        guard !isFindingElement else { return }
        isFindingElement = true
        Task { @MainActor in
            while let pointer = pendingPointer {
                pendingPointer = nil
                let element = await page.regionCaptureElement(at: pointer)
                if isPointerInside {
                    targetElement = element
                    targetPointer = pointer
                }
            }
            isFindingElement = false
        }
    }

    private func selectionRect(in bounds: CGRect) -> CGRect? {
        guard let dragStart, let dragEnd else { return nil }
        return Self.captureRect(
            from: dragStart,
            to: dragEnd,
            in: bounds
        )
    }

    /// The region a drag from `start` to `end` selects, clipped to `bounds`,
    /// or nil when it is too small to be a deliberate selection.
    private static func captureRect(
        from start: CGPoint,
        to end: CGPoint,
        in bounds: CGRect
    ) -> CGRect? {
        let proposed = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        let clipped = proposed.intersection(bounds)
        guard !clipped.isNull,
            clipped.width >= minimumSelectionLength,
            clipped.height >= minimumSelectionLength
        else {
            return nil
        }
        return clipped
    }
}

private struct BrowserDeveloperCaptureOptions: View {
    let page: BrowserPage

    var body: some View {
        VStack(spacing: 12) {
            BrowserDeveloperCapturePreview()
            Button(
                "Capture in Portrait Mode",
                systemImage: "rectangle.portrait.on.rectangle.portrait"
            ) {
                page.savePortraitCapture()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            Button(
                "Copy Full Page Capture",
                systemImage: "doc.on.clipboard"
            ) {
                page.copyFullPageCapture()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(width: 260)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Capture Window")
    }
}

private struct BrowserDeveloperCapturePreview: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.indigo, .purple, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 112)
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.black.opacity(0.72))
                    .padding(22)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
            }
            .accessibilityHidden(true)
    }
}

private struct BrowserRegionCaptureInstruction: View {
    var body: some View {
        Label(
            "Click an element or drag to capture part of this page",
            systemImage: "camera.viewfinder"
        )
        .font(.callout.weight(.semibold))
        .padding(.horizontal, 18)
        .frame(height: 42)
        .background { CrestSurfaceLayer(shape: Capsule()) }
        .padding(.bottom, 28)
        .allowsHitTesting(false)
    }
}
