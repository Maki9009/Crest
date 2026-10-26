import SwiftUI

/// The markup tools and the ways out of a capture preview: copy, save, share
/// or close.
struct BrowserCapturePreviewToolbar: View {
    let page: BrowserPage
    @Bindable var markup: BrowserCaptureMarkup

    var body: some View {
        HStack(spacing: BrowserDeveloperToolbarMetrics.itemSpacing) {
            ForEach(BrowserCaptureMarkupTool.all, id: \.self) { tool in
                BrowserDeveloperToolbarButton(
                    label: LocalizedStringKey(String(localized: tool.title)),
                    systemImage: tool.systemImage,
                    isActive: markup.tool == tool,
                    action: { markup.tool = tool }
                )
            }

            BrowserDeveloperToolbarDivider()

            ForEach(BrowserCaptureMarkupColor.all, id: \.self) { color in
                BrowserCaptureMarkupSwatch(color: color, isSelected: markup.color == color) {
                    markup.color = color
                }
            }

            BrowserDeveloperToolbarDivider()

            BrowserDeveloperToolbarButton(
                label: "Undo", systemImage: "arrow.uturn.backward", action: markup.undo
            )
            .disabled(!markup.hasMarks)
            BrowserDeveloperToolbarButton(label: "Clear", systemImage: "trash", action: markup.clear)
                .disabled(!markup.hasMarks)

            BrowserDeveloperToolbarDivider()

            BrowserDeveloperToolbarButton(
                label: "Copy", systemImage: "doc.on.doc", action: page.copyCapturePreview
            )
            BrowserDeveloperToolbarButton(
                label: "Save", systemImage: "square.and.arrow.down", action: page.saveCapturePreview
            )
            ShareLink(
                item: BrowserCaptureShareItem(markup: markup),
                preview: SharePreview("Page Capture", image: Image(nsImage: markup.image))
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(
                        width: BrowserDeveloperToolbarMetrics.buttonSize,
                        height: BrowserDeveloperToolbarMetrics.buttonSize
                    )
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Share")

            BrowserDeveloperToolbarDivider()

            BrowserDeveloperToolbarButton(
                label: "Close", systemImage: "xmark", action: page.closeCapturePreview
            )
        }
        .padding(.horizontal, 8)
        .frame(height: 42)
        .background { CrestSurfaceLayer(shape: Capsule()) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Capture tools")
    }
}

/// One ink to mark a capture up in.
private struct BrowserCaptureMarkupSwatch: View {
    let color: BrowserCaptureMarkupColor
    let isSelected: Bool
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.color)
                .frame(width: 16, height: 16)
                .overlay { Circle().strokeBorder(CrestColor.subtleBorder, lineWidth: 1) }
                .padding(3)
                .overlay {
                    if isSelected { Circle().strokeBorder(.primary, lineWidth: 2) }
                }
                .frame(width: 26, height: BrowserDeveloperToolbarMetrics.buttonSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(color.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help(Text(color.title))
    }
}

/// The marked-up capture as something to share, drawn only once the person
/// shares it rather than every time the toolbar updates.
private struct BrowserCaptureShareItem: Transferable {
    let markup: BrowserCaptureMarkup

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = await item.markup.pngData() else { throw BrowserDeveloperCaptureError.encodingFailed }
            return data
        }
    }
}
