import Foundation

/// What a Space's downloads amount to at a glance: how many still run, how far
/// the running ones have come together, how fast and how soon they finish, and
/// how many ended ones nobody has looked at yet.
struct BrowserDownloadsSummary: Equatable {
    // MARK: - Variables

    /// The downloads that have not ended, paused ones included.
    let liveCount: Int

    /// The live downloads that are paused.
    let pausedCount: Int

    /// The ended downloads nobody has looked at yet.
    let newCount: Int

    /// Whether any download failed or waits on the person.
    let needsAttention: Bool

    /// The bytes the live downloads have together.
    let receivedBytes: Int64

    /// The bytes the live downloads come to together, or nil while any of
    /// them has not said how large it is.
    let totalBytes: Int64?

    /// How fast the running downloads arrive together, or nil while none
    /// measures a rate.
    let bytesPerSecond: Double?

    /// How long until the last running download finishes, or nil while none
    /// can tell.
    let estimatedTimeRemaining: TimeInterval?

    /// The one live download's name, when only one runs.
    let soleFilename: String?

    /// How far the live downloads have come together, or nil when there are
    /// none or their size is not known.
    var progress: Double? {
        guard liveCount > 0, let totalBytes, totalBytes > 0 else { return nil }
        return min(max(Double(receivedBytes) / Double(totalBytes), 0), 1)
    }

    /// Whether every live download is paused.
    var isPaused: Bool {
        liveCount > 0 && pausedCount == liveCount
    }

    // MARK: - Initializers

    init(items: [DownloadState]) {
        let live = items.filter(\.phase.isLive)
        let running = live.filter { $0.phase.isTransferring && !$0.telemetry.isPaused }
        let rates = running.compactMap(\.telemetry.bytesPerSecond)
        liveCount = live.count
        pausedCount = live.count(where: \.telemetry.isPaused)
        newCount = items.count(where: { !$0.isAcknowledged && !$0.phase.isLive })
        needsAttention = items.contains { $0.phase.needsAttention || $0.phase.awaitsDecision }
        receivedBytes = live.reduce(0) { $0 + $1.telemetry.bytesReceived }
        totalBytes =
            live.allSatisfy { $0.telemetry.totalBytes != nil }
            ? live.reduce(0) { $0 + ($1.telemetry.totalBytes ?? 0) } : nil
        bytesPerSecond = rates.isEmpty ? nil : rates.reduce(0, +)
        estimatedTimeRemaining = running.compactMap(\.telemetry.estimatedTimeRemaining).max()
        soleFilename = live.count == 1 ? live.first?.filename : nil
    }

    // MARK: - Actions - Describing

    /// What the downloads come to, as the button's tooltip says it.
    var help: String {
        guard liveCount > 0 else {
            if needsAttention { return String(localized: "A download needs attention") }
            if newCount == 1 { return String(localized: "New download") }
            if newCount > 1 { return String(localized: "\(newCount) new downloads") }
            return String(localized: "Downloads")
        }
        return [headline, transferDetail].compactMap(\.self).joined(separator: "\n")
    }

    /// The live downloads in one line, as the popover's header says it.
    var caption: String {
        [headline, transferDetail].compactMap(\.self).joined(separator: " · ")
    }

    /// What the live downloads are doing, in a few words.
    var headline: String {
        if isPaused {
            return liveCount == 1
                ? String(localized: "Download paused") : String(localized: "\(liveCount) downloads paused")
        }
        if let soleFilename { return String(localized: "Downloading “\(soleFilename)”") }
        return String(localized: "Downloading \(liveCount) files")
    }

    /// The bytes, rate and time left of the live downloads together, or nil
    /// before any of it is known.
    var transferDetail: String? {
        var parts: [String] = []
        let received = receivedBytes.formatted(.byteCount(style: .file))
        if let totalBytes {
            parts.append(String(localized: "\(received) of \(totalBytes.formatted(.byteCount(style: .file)))"))
        } else if receivedBytes > 0 {
            parts.append(received)
        }
        if let bytesPerSecond, !isPaused {
            parts.append(String(localized: "\(Int64(bytesPerSecond.rounded()).formatted(.byteCount(style: .file)))/s"))
        }
        if let estimatedTimeRemaining, !isPaused {
            parts.append(Self.timeLeft(estimatedTimeRemaining))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// How long remains, as a download row says it.
    static func timeLeft(_ seconds: TimeInterval) -> String {
        let duration = Duration.seconds(max(seconds, 1)).formatted(
            .units(allowed: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 2))
        return String(localized: "\(duration) left")
    }
}
