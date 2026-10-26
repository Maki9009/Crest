import Foundation

extension ResumeEngineDownload {
    @MainActor func perform(on binding: WebKitEngineBinding) {
        binding.downloads.resume(downloadID)
    }
}
