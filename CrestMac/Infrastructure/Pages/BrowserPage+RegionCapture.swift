import Foundation

extension BrowserPage {
    // MARK: - Types

    private struct CaptureElementBox: Decodable {
        let left: Double
        let top: Double
        let width: Double
        let height: Double
    }

    // MARK: - Static Variables

    /// How long a pointer lookup may take before the overlay gives up on it.
    private static let captureElementTimeout: Duration = .milliseconds(250)

    /// Finds the element under `x` and `y`, in CSS pixels from the visual
    /// viewport's top left, that a capture should frame: a figure with its
    /// caption, a picture, video, canvas, chart or embed, or otherwise the
    /// nearest block big enough to aim at. Answers the part of its box that
    /// shows, in the same space, or null when the pointer is over the
    /// page itself rather than one element of it.
    private static let captureElementScript = #"""
        const viewport = window.visualViewport;
        const scale = viewport ? viewport.scale : 1;
        const offsetX = viewport ? viewport.offsetLeft : 0;
        const offsetY = viewport ? viewport.offsetTop : 0;
        const width = viewport ? viewport.width : innerWidth;
        const height = viewport ? viewport.height : innerHeight;
        const clientX = offsetX + x / scale;
        const clientY = offsetY + y / scale;
        let element = document.elementFromPoint(clientX, clientY);
        while (element && element.shadowRoot) {
          const inner = element.shadowRoot.elementFromPoint(clientX, clientY);
          if (!inner || inner === element) break;
          element = inner;
        }
        if (!element) return null;
        const viewportArea = width * height;
        const covers = (box) => box.width * box.height >= viewportArea * 0.9;
        const media = element.closest("figure, picture, video, canvas, svg, iframe, embed, object, img");
        let target = media && media.tagName === "IMG" ? (media.closest("figure, picture") || media) : media;
        if (target && covers(target.getBoundingClientRect())) target = null;
        if (!target) {
          target = element;
          while (target.parentElement) {
            const box = target.getBoundingClientRect();
            const display = getComputedStyle(target).display;
            const aimable = box.width >= 48 && box.height >= 24 && !display.startsWith("inline")
              && display !== "contents" && display !== "table-row" && display !== "table-cell";
            if (aimable) break;
            const parentBox = target.parentElement.getBoundingClientRect();
            if (covers(parentBox)) break;
            target = target.parentElement;
          }
        }
        if (target === document.documentElement || target === document.body) return null;
        let box = target.getBoundingClientRect();
        if (target !== media) {
          // A block that wraps around a float reaches under it; frame what it holds.
          const range = document.createRange();
          range.selectNodeContents(target);
          const content = range.getBoundingClientRect();
          if (content.width >= 1 && content.height >= 1) {
            const left = Math.max(box.left, content.left), top = Math.max(box.top, content.top);
            const right = Math.min(box.right, content.right), bottom = Math.min(box.bottom, content.bottom);
            if (right > left && bottom > top) box = new DOMRect(left, top, right - left, bottom - top);
          }
        }
        // An ancestor that hides its overflow shows only part of the element.
        for (let clip = target.parentElement; clip && clip !== document.body; clip = clip.parentElement) {
          const style = getComputedStyle(clip);
          if (style.overflowX === "visible" && style.overflowY === "visible") continue;
          const bounds = clip.getBoundingClientRect();
          const left = Math.max(box.left, bounds.left), top = Math.max(box.top, bounds.top);
          const right = Math.min(box.right, bounds.right), bottom = Math.min(box.bottom, bounds.bottom);
          if (right - left < 1 || bottom - top < 1) return null;
          box = new DOMRect(left, top, right - left, bottom - top);
        }
        if (covers(box)) return null;
        const left = Math.max(box.left, offsetX);
        const top = Math.max(box.top, offsetY);
        const right = Math.min(box.right, offsetX + width);
        const bottom = Math.min(box.bottom, offsetY + height);
        if (right - left < 1 || bottom - top < 1) return null;
        return { left: (left - offsetX) * scale, top: (top - offsetY) * scale,
          width: (right - left) * scale, height: (bottom - top) * scale };
        """#

    // MARK: - Actions - Region Capture

    /// The frame of the element a capture at `point`, in the page view's
    /// points from its top left, would take, in the same space; or nil when
    /// no single element sits there or the page did not answer in time.
    func regionCaptureElement(at point: CGPoint) async -> CGRect? {
        let zoom = renderedPageZoom
        guard zoom > 0 else { return nil }
        let source =
            "const x = \(Double(point.x / zoom)), y = \(Double(point.y / zoom));\n"
            + Self.captureElementScript
        guard let evaluated = await enginePage.evaluate(source, in: .agent, timeout: Self.captureElementTimeout),
            evaluated.error == nil,
            let json = evaluated.json,
            let box = try? JSONDecoder().decode(CaptureElementBox.self, from: Data(json.utf8))
        else {
            return nil
        }
        return CGRect(x: box.left, y: box.top, width: box.width, height: box.height)
            .applying(CGAffineTransform(scaleX: zoom, y: zoom))
    }
}
