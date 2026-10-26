using CrestCore.Application;

namespace CrestCore.Contracts;

/// The system asks for memory back at `Level`. The core unloads pages nobody
/// sees, off screen longest first, as many as the device's platform gives
/// back at that level. A page a window shows, one running media (playing,
/// capturing, or holding a Picture in Picture window, even paused), one
/// whose tab keeps its page loaded or an agent uses, and a Quick Window's or
/// Peek's page all stay.
public sealed record ReportMemoryPressure(MemoryPressureLevel Level) : PageIntent {
    #region Actions - Pages

    /// Unloads the pages memory pressure may take back, those `Pages.Unloadable`
    /// names, off screen longest first.
    internal override void Apply(Pages pages, PageTurn turn) {
        pages.Stamp(pages.Clock.Now, turn.Issue);
        var candidates = pages.Unloadable();
        foreach (var page in candidates.Take(pages.Device.Platform.ReleaseLimit(Level, candidates.Count))) pages.Unload(page, turn);
    }

    #endregion
}
