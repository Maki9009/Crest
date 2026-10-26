import SwiftUI

/// The shown Space's downloads, live, in the popover the switcher's downloads
/// button opens: what runs now and how it is going, and what ended, newest
/// first. It reads the same core records as the sidebar's Downloads list and
/// asks the same coordinator to act on them, so both always agree.
struct BrowserDownloadsPopover: View {
    // MARK: - Static Variables

    private static let width: CGFloat = 360
    private static let maximumListHeight: CGFloat = 420
    private static let headerButtonSize = CGSize(width: 26, height: 26)

    // MARK: - Variables

    let control: BrowserSpaceSwitcherDownloadsControl

    @State private var listHeight: CGFloat = 0

    // MARK: - Actions - Drawing

    var body: some View {
        let items = control.items
        VStack(spacing: 0) {
            header(items)
            if items.isEmpty {
                emptyState
            } else {
                list(items)
            }
        }
        .frame(width: Self.width)
    }

    private func header(_ items: [DownloadState]) -> some View {
        let summary = BrowserDownloadsSummary(items: items)
        return HStack(spacing: CrestSpacing.small) {
            VStack(alignment: .leading, spacing: CrestSpacing.extraExtraSmall) {
                Text("Downloads")
                    .font(.headline)
                if summary.liveCount > 0 {
                    Text(verbatim: summary.caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if items.contains(where: { !$0.phase.isLive }) {
                Button("Clear") { clearEnded(items) }
                    .buttonStyle(.crestTertiary)
                    .help("Remove finished, failed and canceled downloads from the list")
            }

            Button("Show All Downloads", systemImage: "list.bullet") {
                control.setPresented(false)
                control.showAll()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(CrestChromeButtonStyle(controlSize: Self.headerButtonSize))
            .help("Show All Downloads")
        }
        .padding(.horizontal, CrestSpacing.medium)
        .padding(.top, CrestSpacing.medium)
        .padding(.bottom, CrestSpacing.small)
    }

    private func list(_ items: [DownloadState]) -> some View {
        ScrollView {
            LazyVStack(spacing: CrestSpacing.extraExtraSmall) {
                ForEach(items) { download in
                    BrowserDownloadsPopoverRow(
                        download: download,
                        destinations: control.actions.downloadDestinations,
                        perform: perform
                    )
                }
            }
            .padding(.horizontal, CrestSpacing.extraSmall)
            .padding(.bottom, CrestSpacing.extraSmall)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                listHeight = height
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: min(max(listHeight, 1), Self.maximumListHeight))
    }

    private var emptyState: some View {
        VStack(spacing: CrestSpacing.small) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No Downloads")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CrestSpacing.extraExtraLarge)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions - Downloads

    private func perform(_ action: BrowserUtilityDownloadAction) {
        guard let assignment = control.assignment else { return }
        control.actions.performDownloadAction(action, assignment)
    }

    /// Removes every download that ended from the list, leaving its file.
    private func clearEnded(_ items: [DownloadState]) {
        for item in items where !item.phase.isLive {
            perform(.clear(item.id))
        }
    }
}
