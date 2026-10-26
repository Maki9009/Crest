using CrestCore.Application;

namespace CrestCore.Contracts;

/// Memory Saver: unloads every page nobody has looked at for `IdleMinutes`,
/// whatever memory the device has left. The pages are the ones memory
/// pressure may take back (see `Pages.Unloadable`), so a page a window shows,
/// one running media, and one whose tab keeps its page loaded or an agent
/// uses all stay. Each tab brings its page back, where it was, when shown.
public sealed record UnloadIdlePages(int IdleMinutes) : PageIntent {
    #region Actions - Pages

    internal override void Apply(Pages pages, PageTurn turn) {
        if (IdleMinutes <= 0) return;
        var now = pages.Clock.Now;
        pages.Stamp(now, turn.Issue);
        var hiddenBefore = now - TimeSpan.FromMinutes(IdleMinutes);
        foreach (var page in pages.Unloadable().Where(page => page.HiddenSince <= hiddenBefore)) pages.Unload(page, turn);
    }

    #endregion
}
