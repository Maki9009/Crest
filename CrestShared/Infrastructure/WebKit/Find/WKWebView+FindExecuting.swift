import WebKit

/// WebKit's public find reports only whether a match was found, never how
/// many. So the page's text is searched in an isolated script world instead:
/// it marks every match with the CSS Custom Highlight API, picks the current
/// one, scrolls it into view and answers with its place among them. Where the
/// script cannot run, such as in a PDF, WebKit's own find takes over without a
/// count.
extension WKWebView: BrowserFindExecuting {
    // MARK: - Static Variables

    /// Searches the document's visible text for `query`, keeping the matches
    /// between calls so a repeated query steps through them. Answers
    /// `{total, active}`, or null where the page has no highlight support.
    private static let findScript = """
        const state = globalThis.__crestFind ??= { key: null, caseSensitive: false, ranges: [], index: -1, sheet: null, all: null, active: null };
        // The two highlights stay registered and change in place: WebKit
        // repaints what leaves a highlight it keeps, but not always what a
        // replaced one covered, such as text in a sticky column.
        const clear = () => {
            state.all?.clear();
            state.active?.clear();
            state.key = null; state.ranges = []; state.index = -1;
        };
        if (!query) { clear(); return { total: 0, active: 0 }; }
        if (!(globalThis.CSS && CSS.highlights && globalThis.Highlight && document.body)) return null;
        if (!state.sheet) {
            state.sheet = new CSSStyleSheet();
            state.sheet.replaceSync(
                '::highlight(crest-find){background-color:rgba(255,214,10,.45)}' +
                '::highlight(crest-find-active){background-color:#ff9f0a;color:#000}');
        }
        if (!state.all) {
            state.all = new Highlight();
            state.active = new Highlight();
            state.active.priority = 1;
        }
        if (CSS.highlights.get('crest-find') !== state.all) CSS.highlights.set('crest-find', state.all);
        if (CSS.highlights.get('crest-find-active') !== state.active) CSS.highlights.set('crest-find-active', state.active);
        if (!document.adoptedStyleSheets.includes(state.sheet)) {
            document.adoptedStyleSheets = [...document.adoptedStyleSheets, state.sheet];
        }
        const key = caseSensitive ? query : query.toLowerCase();
        // Lowercasing that changes a string's length, as for "İ", would put
        // the ranges off the text they match, so WebKit's own find takes over.
        if (key.length !== query.length) { clear(); return null; }
        const fresh = state.key !== key || state.caseSensitive !== caseSensitive || !state.ranges.length || !state.ranges[0].startContainer.isConnected;
        if (fresh) {
            const ranges = [];
            const shown = new Map();
            const isShown = (element) => {
                if (!shown.has(element)) {
                    shown.set(element, element.checkVisibility ? element.checkVisibility({ visibilityProperty: true }) : true);
                }
                return shown.get(element);
            };
            const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
                acceptNode(node) {
                    const parent = node.parentElement;
                    if (!parent || /^(SCRIPT|STYLE|NOSCRIPT|TEMPLATE)$/.test(parent.tagName)) return NodeFilter.FILTER_REJECT;
                    return isShown(parent) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
                }
            });
            for (let node = walker.nextNode(); node && ranges.length < 2000; node = walker.nextNode()) {
                const text = caseSensitive ? node.data : node.data.toLowerCase();
                if (text.length !== node.data.length) { clear(); return null; }
                for (let at = text.indexOf(key); at >= 0 && ranges.length < 2000; at = text.indexOf(key, at + key.length)) {
                    const range = new Range();
                    range.setStart(node, at);
                    range.setEnd(node, Math.min(at + key.length, node.length));
                    ranges.push(range);
                }
            }
            state.key = key;
            state.caseSensitive = caseSensitive;
            state.ranges = ranges;
            // A new search starts at the first match on screen or below it.
            const below = ranges.findIndex((range) => range.getBoundingClientRect().bottom >= 0);
            state.index = below < 0 ? 0 : below;
            if (backwards && ranges.length) state.index = (state.index - 1 + ranges.length) % ranges.length;
        } else {
            state.index = (state.index + (backwards ? -1 : 1) + state.ranges.length) % state.ranges.length;
        }
        if (!state.ranges.length) { clear(); state.key = key; return { total: 0, active: 0 }; }
        const current = state.ranges[state.index];
        if (fresh) {
            state.all.clear();
            for (const range of state.ranges) state.all.add(range);
        }
        state.active.clear();
        state.active.add(current);
        const rect = current.getBoundingClientRect();
        if (rect.top < 0 || rect.bottom > innerHeight || rect.left < 0 || rect.right > innerWidth) {
            current.startContainer.parentElement?.scrollIntoView({ block: 'center', inline: 'nearest', behavior: 'instant' });
        }
        return { total: state.ranges.length, active: state.index + 1 };
        """

    // MARK: - Actions - Find

    func performFind(
        _ query: String,
        configuration: BrowserFindConfiguration,
        completion: @escaping @MainActor (BrowserFindResult) -> Void
    ) {
        callAsyncJavaScript(
            Self.findScript,
            arguments: [
                "query": query, "backwards": configuration.backwards, "caseSensitive": configuration.caseSensitive,
            ],
            in: nil,
            in: .defaultClient
        ) { [weak self] result in
            guard case .success(let value) = result, let counts = value as? [String: Any],
                let total = (counts["total"] as? NSNumber)?.intValue,
                let active = (counts["active"] as? NSNumber)?.intValue
            else {
                self?.performNativeFind(query, configuration: configuration, completion: completion)
                return
            }
            // The script reads only the main frame, so a query it cannot find
            // may still be in a subframe, which WebKit's own find searches.
            guard total > 0 || query.isEmpty else {
                self?.performNativeFind(query, configuration: configuration, completion: completion)
                return
            }
            completion(BrowserFindResult(matchCount: total, activeMatch: active))
        }
    }

    /// WebKit's own find, which selects the match but cannot count.
    private func performNativeFind(
        _ query: String,
        configuration: BrowserFindConfiguration,
        completion: @escaping @MainActor (BrowserFindResult) -> Void
    ) {
        let native = WKFindConfiguration()
        native.backwards = configuration.backwards
        native.caseSensitive = configuration.caseSensitive
        native.wraps = true
        find(query, configuration: native) { result in
            completion(BrowserFindResult(matchFound: result.matchFound))
        }
    }
}
