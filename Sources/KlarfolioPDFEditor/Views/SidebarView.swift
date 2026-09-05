import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: PDFDocumentStore

    private var pageSelection: Binding<Int?> {
        Binding<Int?> {
            store.hasDocument ? store.currentPageIndex : nil
        } set: { value in
            if let value {
                store.goToPage(value)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Bereich", selection: $store.sidebarPanel) {
                ForEach(SidebarPanel.allCases) { panel in
                    Label(panel.title, systemImage: panel.symbolName)
                        .tag(panel)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .top], 12)
            .padding(.bottom, 8)

            Divider()

            switch store.sidebarPanel {
            case .pages:
                pagesList
            case .document:
                documentSummary
            }
        }
    }

    private var pagesList: some View {
        List(selection: pageSelection) {
            if store.pageCount == 0 {
                Label("Keine Seiten", systemImage: "doc")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(0..<store.pageCount, id: \.self) { index in
                    PageThumbnailRow(store: store, pageIndex: index)
                        .tag(index)
                        .contextMenu {
                            Button("Seite drehen") {
                                store.goToPage(index)
                                store.rotateCurrentPage(clockwise: true)
                            }
                            .disabled(!store.canPerform(.assemblePages))

                            Button("Leere Seite danach") {
                                store.goToPage(index)
                                store.addBlankPage()
                            }
                            .disabled(!store.canPerform(.assemblePages))

                            Divider()

                            Button("Seite löschen", role: .destructive) {
                                store.goToPage(index)
                                store.deleteCurrentPage()
                            }
                            .disabled(store.pageCount <= 1 || !store.canPerform(.assemblePages))
                        }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var documentSummary: some View {
        List {
            Section("Datei") {
                LabeledContent("Name", value: store.documentTitle)
                LabeledContent("Seiten", value: "\(store.pageCount)")
                LabeledContent("Status", value: store.isDirty ? "Ungespeichert" : "Gespeichert")
                LabeledContent("Aktuelle Seite", value: store.currentPageSizeLabel)
            }

            Section("Ansicht") {
                Picker("Layout", selection: $store.layoutMode) {
                    ForEach(PageLayoutMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .onChange(of: store.layoutMode) {
                    store.applyLayoutMode()
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct PageThumbnailRow: View {
    @ObservedObject var store: PDFDocumentStore
    let pageIndex: Int

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
                .frame(width: 54, height: 72)
                .background(.background, in: RoundedRectangle(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.separator, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Seite \(pageIndex + 1)")
                    .lineLimit(1)

                Text(pageDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = store.thumbnail(for: pageIndex, size: CGSize(width: 108, height: 144)) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .padding(3)
        } else {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
        }
    }

    private var pageDescription: String {
        guard let page = store.document?.page(at: pageIndex) else {
            return "Keine Vorschau"
        }

        return PDFUtilities.pageSizeLabel(for: page)
    }
}
