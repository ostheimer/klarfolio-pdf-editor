import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PDFDocumentStore
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            EditorShellView(store: store)
        }
        .navigationTitle(store.documentTitle)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    store.createBlankDocument()
                } label: {
                    Label("Neues PDF", systemImage: "doc.badge.plus")
                }
                .help("Neues PDF")

                Button {
                    store.openDocument()
                } label: {
                    Label("Öffnen", systemImage: "folder")
                }
                .help("PDF öffnen")

                Button {
                    store.saveDocument()
                } label: {
                    Label("Speichern", systemImage: "square.and.arrow.down")
                }
                .disabled(!store.hasDocument)
                .help("Speichern")
            }

            ToolbarItemGroup {
                Button {
                    store.goToPreviousPage()
                } label: {
                    Label("Vorherige Seite", systemImage: "chevron.up")
                }
                .disabled(store.currentPageIndex <= 0)
                .help("Vorherige Seite")

                Text("\(min(store.currentPageIndex + 1, max(store.pageCount, 1))) / \(max(store.pageCount, 1))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 64)

                Button {
                    store.goToNextPage()
                } label: {
                    Label("Nächste Seite", systemImage: "chevron.down")
                }
                .disabled(store.currentPageIndex >= store.pageCount - 1)
                .help("Nächste Seite")
            }

            ToolbarItemGroup {
                Button {
                    store.zoomOut()
                } label: {
                    Label("Verkleinern", systemImage: "minus.magnifyingglass")
                }
                .disabled(!store.hasDocument)
                .help("Verkleinern")

                Text("\(store.zoomPercent)%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 52)

                Button {
                    store.zoomIn()
                } label: {
                    Label("Vergrößern", systemImage: "plus.magnifyingglass")
                }
                .disabled(!store.hasDocument)
                .help("Vergrößern")

                Button {
                    store.fitToWindow()
                } label: {
                    Label("Anpassen", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
                }
                .disabled(!store.hasDocument)
                .help("An Fenster anpassen")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                SearchField(store: store)
            }
        }
    }
}

private struct EditorShellView: View {
    @ObservedObject var store: PDFDocumentStore

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                PDFCanvasView(store: store)
                    .ignoresSafeArea(.container, edges: .bottom)

                if !store.hasDocument {
                    EmptyDocumentView(store: store)
                }
            }

            Divider()

            InspectorView(store: store)
                .frame(minWidth: 276, idealWidth: 304, maxWidth: 340)
        }
        .safeAreaInset(edge: .bottom) {
            StatusBarView(store: store)
        }
    }
}

private struct EmptyDocumentView: View {
    @ObservedObject var store: PDFDocumentStore

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("Klarfolio PDF Editor")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("PDF öffnen, neu erstellen oder aus Bildern zusammensetzen.")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    store.openDocument()
                } label: {
                    Label("Öffnen", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    store.createBlankDocument()
                } label: {
                    Label("Neues PDF", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.bordered)

                Button {
                    store.importImagesAsPages()
                } label: {
                    Label("Bilder einfügen", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
    }
}

private struct SearchField: View {
    @ObservedObject var store: PDFDocumentStore

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Suchen", text: $store.searchText)
                .textFieldStyle(.plain)
                .frame(width: 180)
                .onSubmit {
                    store.runSearch()
                }

            if store.searchResultCount > 0 {
                Text("\(store.searchResultCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Button {
                store.runSearch()
            } label: {
                Label("Suchen", systemImage: "return")
            }
            .buttonStyle(.plain)
            .disabled(store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Suchen")

            Button {
                store.searchText = ""
                store.clearSearch()
            } label: {
                Label("Suche löschen", systemImage: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .disabled(store.searchText.isEmpty && store.searchResultCount == 0)
            .help("Suche löschen")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatusBarView: View {
    @ObservedObject var store: PDFDocumentStore

    var body: some View {
        HStack(spacing: 12) {
            Text(store.statusMessage)
                .lineLimit(1)

            Spacer()

            if store.hasDocument {
                Text(store.currentPageSizeLabel)
                Text(store.isDirty ? "Ungespeichert" : "Gespeichert")
                    .foregroundStyle(store.isDirty ? .orange : .secondary)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
