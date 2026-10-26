import Foundation

extension PauseEngineDownload {
    @MainActor func perform(on binding: WebKitEngineBinding) {
        binding.downloads.pause(downloadID)
    }
}
