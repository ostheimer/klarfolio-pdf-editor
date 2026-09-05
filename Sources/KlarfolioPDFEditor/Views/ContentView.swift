import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PDFDocumentStore
    @State private var isSidebarVisible = true
    @State private var isReadingNavigationPresented = false

    var body: some View {
        HSplitView {
            if store.workspaceMode == .editing, isSidebarVisible {
                SidebarView(store: store)
                    .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
                    .accessibilityIdentifier("documentSidebar")
            }

            EditorShellView(store: store)
        }
        .accessibilityIdentifier("mainDocumentWindow")
        .navigationTitle(store.documentTitle)
        .background(DocumentWindowObserver(store: store))
        .onChange(of: store.workspaceMode) { _, mode in
            if mode == .editing {
                isSidebarVisible = true
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                if store.workspaceMode == .editing {
                    Button {
                        isSidebarVisible.toggle()
                    } label: {
                        Label(
                            isSidebarVisible ? "Seitenleiste ausblenden" : "Seitenleiste einblenden",
                            systemImage: "sidebar.leading"
                        )
                    }
                    .help(isSidebarVisible ? "Seitenleiste ausblenden" : "Seitenleiste einblenden")

                    Button {
                        store.createBlankDocument()
                    } label: {
                        Label("Neues PDF", systemImage: "doc.badge.plus")
                    }
                    .accessibilityIdentifier("toolbarNewDocument")
                    .help("Neues PDF")
                }

                Button {
                    store.openDocument()
                } label: {
                    Label("Öffnen", systemImage: "folder")
                }
                .accessibilityIdentifier("toolbarOpenDocument")
                .help("PDF öffnen")

                if store.workspaceMode == .editing {
                    Button {
                        store.saveDocument()
                    } label: {
                        Label("Speichern", systemImage: "square.and.arrow.down")
                    }
                    .disabled(!store.canPerform(.save))
                    .accessibilityIdentifier("toolbarSaveDocument")
                    .help("Speichern")
                }
            }

            if store.workspaceMode == .editing {
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
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if store.workspaceMode == .editing {
                    SearchField(store: store)
                }

                if store.hasDocument {
                    Button {
                        isReadingNavigationPresented.toggle()
                    } label: {
                        Label("Inhalt & Lesezeichen", systemImage: "list.bullet.rectangle.portrait")
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("readerNavigationToggle")
                    .accessibilityLabel("Inhalt & Lesezeichen")
                    .help("Inhalt & Lesezeichen")
                    .popover(
                        isPresented: $isReadingNavigationPresented,
                        arrowEdge: .bottom
                    ) {
                        ReadingNavigationView(store: store)
                    }
                }

                if store.workspaceMode == .reading, store.isDirty {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Ungespeicherte Änderungen")
                        .accessibilityIdentifier("documentEditedIndicator")
                        .help("Dieses PDF enthält ungespeicherte Änderungen.")
                }

                Button {
                    store.toggleWorkspaceMode()
                } label: {
                    Label(
                        store.workspaceMode == .reading ? "Bearbeiten" : "Lesen",
                        systemImage: store.workspaceMode == .reading ? "pencil" : "book"
                    )
                }
                .accessibilityIdentifier("workspaceModeToggle")
                .help(
                    store.workspaceMode == .reading
                        ? "Bearbeitungsmodus einblenden"
                        : "Lesemodus aktivieren"
                )
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
                    .accessibilityIdentifier("pdfDocumentCanvas")

                if !store.hasDocument {
                    EmptyDocumentView(store: store)
                }
            }

            if store.workspaceMode == .editing {
                Divider()

                InspectorView(store: store)
                    .frame(minWidth: 276, idealWidth: 304, maxWidth: 340)
                    .accessibilityIdentifier("documentInspector")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if store.workspaceMode == .editing {
                StatusBarView(store: store)
                    .accessibilityIdentifier("documentStatusBar")
            }
        }
        .safeAreaInset(edge: .top) {
            if store.hasDocument, let reason = store.protection.readOnlyReason {
                Label(reason, systemImage: "lock.fill")
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.regularMaterial)
                    .accessibilityIdentifier("documentProtection.reason")
            }
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

                Text(
                    store.workspaceMode == .reading
                        ? "PDF öffnen oder ein neues Dokument erstellen."
                        : "PDF öffnen, neu erstellen oder aus Bildern zusammensetzen."
                )
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    store.openDocument()
                } label: {
                    Label("Öffnen", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("emptyOpenDocument")

                Button {
                    if store.createBlankDocument() {
                        store.setWorkspaceMode(.editing)
                    }
                } label: {
                    Label("Neues PDF", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("emptyCreateDocument")

                if store.workspaceMode == .editing {
                    Button {
                        store.importImagesAsPages()
                    } label: {
                        Label("Bilder einfügen", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("emptyImportImages")
                }
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
                    .accessibilityIdentifier("documentSaveState")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

private struct DocumentWindowObserver: NSViewRepresentable {
    @ObservedObject var store: PDFDocumentStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeNSView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.windowDidChange = { [weak coordinator = context.coordinator] window in
            coordinator?.observe(window)
        }
        return view
    }

    func updateNSView(_ view: ObserverView, context: Context) {
        context.coordinator.store = store
        context.coordinator.observe(view.window)
        context.coordinator.synchronizeDocumentState()
    }

    final class ObserverView: NSView {
        var windowDidChange: ((NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            windowDidChange?(window)
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        weak var store: PDFDocumentStore?
        private weak var observedWindow: NSWindow?
        private weak var previousDelegate: (any NSWindowDelegate)?

        init(store: PDFDocumentStore) {
            self.store = store
        }

        @MainActor
        func observe(_ window: NSWindow?) {
            guard let window else {
                return
            }

            if observedWindow !== window || window.delegate !== self {
                if let observedWindow, observedWindow.delegate === self {
                    observedWindow.delegate = previousDelegate
                }

                observedWindow = window
                previousDelegate = window.delegate
                window.delegate = self
            }

            synchronizeDocumentState()
        }

        @MainActor
        func synchronizeDocumentState() {
            guard let observedWindow, let store else {
                return
            }

            observedWindow.isDocumentEdited = store.isDirty
            observedWindow.representedURL = store.fileURL
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            if let previousDelegate,
               previousDelegate.responds(to: #selector(NSWindowDelegate.windowShouldClose(_:))),
               previousDelegate.windowShouldClose?(sender) == false {
                return false
            }

            if let appDelegate = NSApp.delegate as? AppDelegate {
                return appDelegate.shouldCloseDocumentWindow()
            }

            return store?.confirmDiscardingUnsavedChanges() ?? true
        }

        override func responds(to selector: Selector!) -> Bool {
            super.responds(to: selector) || previousDelegate?.responds(to: selector) == true
        }

        override func forwardingTarget(for selector: Selector!) -> Any? {
            if previousDelegate?.responds(to: selector) == true {
                return previousDelegate
            }

            return super.forwardingTarget(for: selector)
        }
    }
}
