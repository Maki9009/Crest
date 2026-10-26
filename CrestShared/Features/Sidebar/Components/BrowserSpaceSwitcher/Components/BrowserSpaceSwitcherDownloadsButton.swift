import SwiftUI

/// The switcher's window-edge accessory: the shown Space's downloads at a
/// glance. While files download it rings with their progress together and
/// counts them; once they end, it counts the ones nobody has looked at yet,
/// in red when one needs attention. Its tooltip sums them up and a click opens
/// the popover that lists them.
struct BrowserSpaceSwitcherDownloadsButton: View {
    // MARK: - Types

    /// What decides that the downloads have been seen: whether their popover
    /// shows, and which of them nobody has looked at yet.
    private struct AcknowledgementKey: Equatable {
        let isPresented: Bool
        let unacknowledgedIDs: [UUID]

        init(isPresented: Bool, items: [DownloadState]) {
            self.isPresented = isPresented
            unacknowledgedIDs = items.filter { !$0.isAcknowledged }.map(\.id)
        }
    }

    // MARK: - Static Variables

    private static let ringDiameter: CGFloat = 20
    private static let ringLineWidth: CGFloat = 2
    /// How much of the ring an unknown size shows, turning.
    private static let indeterminateArc: CGFloat = 0.25

    // MARK: - Variables

    let control: BrowserSpaceSwitcherDownloadsControl

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if os(macOS)
        @Environment(BrowserMacDownloadFeedbackState.self) private var downloadFeedback:
            BrowserMacDownloadFeedbackState?
    #endif

    // MARK: - Actions - Drawing

    var body: some View {
        let items = control.items
        let summary = BrowserDownloadsSummary(items: items)
        Button {
            control.setPresented(!control.isPresented)
        } label: {
            glyph(summary)
                .frame(
                    width: BrowserSpaceSwitcherLayout.utilityButtonSize,
                    height: BrowserSpaceSwitcherLayout.utilityButtonSize
                )
                .overlay(alignment: .topTrailing) { badge(summary) }
        }
        .buttonStyle(
            CrestChromeButtonStyle(
                controlSize: CGSize(
                    width: BrowserSpaceSwitcherLayout.utilityButtonSize,
                    height: BrowserSpaceSwitcherLayout.utilityButtonSize
                )
            )
        )
        .help(summary.help)
        .accessibilityLabel("Downloads")
        .accessibilityValue(summary.help)
        .accessibilityIdentifier("downloads-button")
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            control.recordFrame(frame)
        }
        .popover(isPresented: presentation, arrowEdge: .top) {
            BrowserDownloadsPopover(control: control)
        }
        .task(id: AcknowledgementKey(isPresented: control.isPresented, items: items)) {
            // What the popover shows is no longer news. The button decides,
            // since a closed popover's view can outlive it with a stale state.
            guard control.isPresented else { return }
            control.acknowledge()
        }
        .onChange(of: control.assignment) {
            // The list belongs to the Space it opened over.
            if control.isPresented { control.setPresented(false) }
        }
        .onDisappear {
            if control.isPresented { control.setPresented(false) }
        }
    }

    private var presentation: Binding<Bool> {
        Binding(get: { control.isPresented }, set: control.setPresented)
    }

    @ViewBuilder
    private func glyph(_ summary: BrowserDownloadsSummary) -> some View {
        if summary.liveCount > 0 {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: Self.ringLineWidth)
                ring(summary)
                Image(systemName: summary.isPaused ? "pause.fill" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .frame(width: Self.ringDiameter, height: Self.ringDiameter)
        } else {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: BrowserChromeSymbolLabel.defaultPointSize + 2, weight: .regular))
                .symbolEffect(.bounce, value: reduceMotion ? nil : arrivalCount)
        }
    }

    @ViewBuilder
    private func ring(_ summary: BrowserDownloadsSummary) -> some View {
        let tint = summary.isPaused ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary)
        if let progress = summary.progress {
            Circle()
                .trim(from: 0, to: max(progress, 0.02))
                .stroke(tint, style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(CrestMotion.loadingProgress.unlessReducingMotion(reduceMotion), value: progress)
        } else {
            BrowserDownloadsIndeterminateRing(
                arc: Self.indeterminateArc, lineWidth: Self.ringLineWidth, tint: tint,
                turns: !reduceMotion && !summary.isPaused)
        }
    }

    @ViewBuilder
    private func badge(_ summary: BrowserDownloadsSummary) -> some View {
        let count = summary.liveCount > 1 ? summary.liveCount : summary.newCount
        if count > 0 {
            BrowserUtilityNotificationBadge(
                count: count,
                tint: summary.needsAttention ? .red : control.tint,
                progress: nil
            )
            .offset(
                x: BrowserUtilitySwitcherLayout.notificationBadgeOffset,
                y: -BrowserUtilitySwitcherLayout.notificationBadgeOffset
            )
            .allowsHitTesting(false)
        }
    }

    /// Counts the downloads that flew here from a page, so the arrow bounces
    /// as each one lands.
    private var arrivalCount: Int {
        #if os(macOS)
            return downloadFeedback?.arrivalCount ?? 0
        #else
            return 0
        #endif
    }
}

/// A quarter of a ring turning, for downloads whose size is not known yet.
private struct BrowserDownloadsIndeterminateRing: View {
    let arc: CGFloat
    let lineWidth: CGFloat
    let tint: AnyShapeStyle
    let turns: Bool

    @State private var angle: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: arc)
            .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(angle - 90))
            .onAppear { spin(turns) }
            .onChange(of: turns) { spin(turns) }
    }

    private func spin(_ turns: Bool) {
        guard turns else {
            angle = 0
            return
        }
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            angle = 360
        }
    }
}
