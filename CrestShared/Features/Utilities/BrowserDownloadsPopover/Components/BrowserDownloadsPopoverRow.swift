import SwiftUI

/// One download in the downloads popover: its file's icon and name, a bar
/// while it runs, the bytes, rate and time left or how it ended, and the
/// controls its state allows. A finished file opens with a click, drags out as
/// itself, and offers the rest from its context menu.
struct BrowserDownloadsPopoverRow: View {
    // MARK: - Static Variables

    private static let iconSize: CGFloat = 32
    private static let actionSize = CGSize(width: 24, height: 24)

    // MARK: - Variables

    let download: DownloadState
    let destinations: [BrowserUtilityDownloadDestination]
    let perform: (BrowserUtilityDownloadAction) -> Void

    @State private var isHovering = false

    /// The finished file, while it still stands where it was saved.
    private var fileURL: URL? {
        guard download.phase.isComplete, let url = download.destinationURL, url.isFileURL,
            FileManager.default.fileExists(atPath: url.path)
        else { return nil }
        return url
    }

    private var isPaused: Bool {
        download.phase.isTransferring && download.telemetry.isPaused
    }

    /// Whether resuming takes up a download that failed rather than one the
    /// person paused.
    private var resumeRetries: Bool {
        download.canResume && !download.phase.isLive
    }

    // MARK: - Actions - Drawing

    var body: some View {
        let fileURL = fileURL
        HStack(spacing: CrestSpacing.small) {
            if let fileURL, let open = destination(.open) {
                Button {
                    perform(.open(download.id, open))
                } label: {
                    label(fileURL: fileURL)
                }
                .buttonStyle(.plain)
                .browserDownloadFileDrag(download)
                .help("Open “\(download.filename)”")
            } else {
                label(fileURL: nil)
            }

            controls(fileURL: fileURL)
        }
        .padding(.leading, CrestSpacing.small)
        .padding(.trailing, CrestSpacing.extraSmall)
        .padding(.vertical, CrestSpacing.small)
        .crestHoverSurface(cornerRadius: CrestRadius.compact)
        .onHover { isHovering = $0 }
        .contextMenu { menu(fileURL: fileURL) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: download.filename))
        .accessibilityValue(Text(verbatim: status(fileURL: fileURL)))
        .accessibilityIdentifier(BrowserUtilityAccessibilityID.downloadRow(download.id))
    }

    private func label(fileURL: URL?) -> some View {
        HStack(spacing: CrestSpacing.small + CrestSpacing.extraExtraSmall) {
            BrowserDownloadsPopoverFileIcon(download: download, fileURL: fileURL)
                .frame(width: Self.iconSize, height: Self.iconSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: CrestSpacing.extraSmall) {
                Text(verbatim: download.filename)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(fileURL == nil && download.phase.isComplete ? .secondary : .primary)

                if download.phase.isTransferring {
                    progressBar
                }

                Text(verbatim: status(fileURL: fileURL))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(statusStyle)
                    .lineLimit(2)
                    .help(Text(verbatim: status(fileURL: fileURL)))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(.rect)
    }

    @ViewBuilder
    private var progressBar: some View {
        Group {
            if download.telemetry.totalBytes != nil {
                ProgressView(value: min(max(download.progress, 0), 1))
            } else {
                ProgressView()
            }
        }
        .progressViewStyle(.linear)
        .controlSize(.small)
        .tint(isPaused ? Color.secondary : Color.accentColor)
        .accessibilityHidden(true)
    }

    // MARK: - Actions - Controls

    @ViewBuilder
    private func controls(fileURL: URL?) -> some View {
        HStack(spacing: CrestSpacing.extraExtraSmall) {
            if download.canPause {
                control(DownloadRowAction.pause.title, symbol: DownloadRowAction.pause.symbol) {
                    perform(.pause(download.id))
                }
            } else if download.canResume {
                if resumeRetries {
                    control("Retry Download", symbol: "arrow.clockwise") { perform(.resume(download.id)) }
                } else {
                    control(DownloadRowAction.resume.title, symbol: DownloadRowAction.resume.symbol) {
                        perform(.resume(download.id))
                    }
                }
            } else if download.phase.canRetry {
                control(DownloadRowAction.retry.title, symbol: DownloadRowAction.retry.symbol) {
                    perform(.retry(download.id))
                }
            }

            if download.phase.isLive {
                control(DownloadRowAction.cancel.title, symbol: DownloadRowAction.cancel.symbol) {
                    perform(.cancel(download.id))
                }
            } else {
                if fileURL != nil, let reveal = destination(.revealInFinder) {
                    control(reveal.title, symbol: reveal.symbol) { perform(.open(download.id, reveal)) }
                }
                // Removing is there under the pointer, so ended rows stay calm.
                control("Remove from List", symbol: "xmark") { perform(.clear(download.id)) }
                    .opacity(isHovering ? 1 : 0)
                    .allowsHitTesting(isHovering)
                    .accessibilityHidden(!isHovering)
            }
        }
    }

    private func control(
        _ title: LocalizedStringResource, symbol: String, action: @escaping () -> Void
    ) -> some View {
        Button(String(localized: title), systemImage: symbol, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 12, weight: .semibold))
            .buttonStyle(CrestChromeButtonStyle(controlSize: Self.actionSize))
            .help(Text(title))
    }

    @ViewBuilder
    private func menu(fileURL: URL?) -> some View {
        if fileURL != nil {
            ForEach(destinations) { destination in
                Button(String(localized: destination.title), systemImage: destination.symbol) {
                    perform(.open(download.id, destination))
                }
            }
            Divider()
        }
        if download.canPause {
            Button(String(localized: DownloadRowAction.pause.title), systemImage: DownloadRowAction.pause.symbol) {
                perform(.pause(download.id))
            }
        }
        if download.canResume {
            Button(
                resumeRetries ? String(localized: "Retry Download") : String(localized: DownloadRowAction.resume.title),
                systemImage: resumeRetries ? "arrow.clockwise" : DownloadRowAction.resume.symbol
            ) {
                perform(.resume(download.id))
            }
        }
        if download.phase.canRetry {
            Button(String(localized: DownloadRowAction.retry.title), systemImage: DownloadRowAction.retry.symbol) {
                perform(.retry(download.id))
            }
        }
        if download.phase.isLive {
            Button(String(localized: DownloadRowAction.cancel.title), systemImage: DownloadRowAction.cancel.symbol) {
                perform(.cancel(download.id))
            }
        } else {
            Button("Remove from List", systemImage: "xmark") { perform(.clear(download.id)) }
        }
    }

    private func destination(_ wanted: BrowserUtilityDownloadDestination) -> BrowserUtilityDownloadDestination? {
        destinations.first { $0 == wanted }
    }

    // MARK: - Actions - Status

    /// Where the download stands, in one line: the bytes, rate and time left
    /// while it runs, its size and age once it finished, or why it stopped.
    private func status(fileURL: URL?) -> String {
        let telemetry = download.telemetry
        if download.phase.isTransferring {
            let received = telemetry.bytesReceived.formatted(.byteCount(style: .file))
            var parts = [
                telemetry.totalBytes.map {
                    String(localized: "\(received) of \($0.formatted(.byteCount(style: .file)))")
                } ?? received
            ]
            if isPaused {
                parts.insert(String(localized: "Paused"), at: 0)
            } else {
                if let rate = telemetry.bytesPerSecond {
                    parts.append(String(localized: "\(Int64(rate.rounded()).formatted(.byteCount(style: .file)))/s"))
                }
                if let remaining = telemetry.estimatedTimeRemaining {
                    parts.append(BrowserDownloadsSummary.timeLeft(remaining))
                }
            }
            return parts.joined(separator: " · ")
        }
        if download.phase.isComplete {
            guard fileURL != nil else { return String(localized: "Moved or deleted") }
            let size = (telemetry.totalBytes ?? telemetry.bytesReceived).formatted(.byteCount(style: .file))
            return "\(size) · \(download.createdAt.formatted(.relative(presentation: .named)))"
        }
        return BrowserDownloadRowPresentation.status(of: download).resolvedForSearch()
    }

    private var statusStyle: AnyShapeStyle {
        if download.phase.awaitsDecision { return AnyShapeStyle(Color.orange) }
        if download.phase.needsAttention { return AnyShapeStyle(Color.red) }
        return AnyShapeStyle(.secondary)
    }
}

/// The file's own icon once it is saved, as Finder shows it; otherwise the
/// download's state.
private struct BrowserDownloadsPopoverFileIcon: View {
    let download: DownloadState
    let fileURL: URL?

    var body: some View {
        #if os(macOS)
            if let fileURL {
                Image(nsImage: NSWorkspace.shared.icon(forFile: fileURL.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                statusIcon
            }
        #else
            statusIcon
        #endif
    }

    private var statusIcon: some View {
        BrowserDownloadStatusIcon(item: download)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.secondary)
    }
}
