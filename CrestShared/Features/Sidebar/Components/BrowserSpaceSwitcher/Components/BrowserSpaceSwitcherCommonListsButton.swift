import SwiftUI

/// The switcher's page-side accessory: one control for the archive, history,
/// and downloads lists. It wears the symbol of the list it opens, which its
/// menu changes, and while a list is open it is the way back to the tabs.
struct BrowserSpaceSwitcherCommonListsButton: View {
    let isExpanded: Bool
    let surface: BrowserUtilitySurface
    let action: () -> Void
    let choose: (BrowserUtilitySurface) -> Void
    let recordFrame: (CGRect) -> Void

    var body: some View {
        Button(action: action) {
            if isExpanded {
                Label("Back to Tabs", systemImage: "xmark")
            } else {
                Label("Common Lists", systemImage: surface.systemImage)
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .frame(
            width: BrowserSpaceSwitcherLayout.utilityButtonSize,
            height: BrowserSpaceSwitcherLayout.utilityButtonSize
        )
        .contextMenu {
            Picker(selection: Binding(get: { surface }, set: choose)) {
                ForEach(BrowserUtilitySurface.all) { surface in
                    Label {
                        Text(surface.title)
                    } icon: {
                        Image(systemName: surface.systemImage)
                    }
                    .tag(surface)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        }
        .help(isExpanded ? "Back to Tabs" : "Archive, History, and Downloads")
        .accessibilityLabel(isExpanded ? Text("Back to Tabs") : Text(surface.title))
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityIdentifier("common-lists-button")
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            recordFrame(frame)
        }
    }
}

#if DEBUG
    #Preview("Expansion") {
        @Previewable @State var expanded = false
        @Previewable @State var surface = BrowserUtilitySurface.archive
        BrowserSpaceSwitcherCommonListsButton(
            isExpanded: expanded, surface: surface,
            action: { expanded.toggle() }, choose: { surface = $0 }, recordFrame: { _ in }
        ).padding()
    }
#endif
