import AppKit

/// What Crest reads from the document itself, on whichever engine shows it:
/// the colour across its top.
extension BrowserPage {
    // MARK: - Static Variables

    private static let readingTimeout: Duration = .seconds(2)
    /// The first solid background behind the middle of the page's top edge,
    /// or the page's own, as `[red, green, blue]` from 0 to 255.
    private static let topColorScript = """
        const solid = (value) => {
            const parts = value && value.match(/[\\d.]+/g);
            return parts && parts.length >= 3 && (parts.length < 4 || Number(parts[3]) >= 0.5)
                ? parts.slice(0, 3).map(Number) : null;
        };
        const behind = (element) => {
            for (; element; element = element.parentElement) {
                const color = solid(getComputedStyle(element).backgroundColor);
                if (color) return color;
            }
            return null;
        };
        return behind(document.elementFromPoint(innerWidth / 2, 1)) ?? behind(document.body)
            ?? solid(getComputedStyle(document.documentElement).backgroundColor);
        """

    // MARK: - Actions - Reading

    /// Reads the colour across the top of the page into `topColor`, keeping
    /// the last one where the page doesn't answer.
    func refreshTopColor() async {
        guard let components = await evaluated(Self.topColorScript, as: [Double].self), components.count == 3 else {
            return
        }
        topColor = NSColor(
            srgbRed: components[0] / 255, green: components[1] / 255, blue: components[2] / 255, alpha: 1)
    }

    private func evaluated<Value: Decodable>(_ source: String, as type: Value.Type) async -> Value? {
        guard let result = await enginePage.evaluate(source, in: .agent, timeout: Self.readingTimeout),
            result.error == nil, let json = result.json
        else { return nil }
        return try? JSONDecoder().decode(Value.self, from: Data(json.utf8))
    }
}
