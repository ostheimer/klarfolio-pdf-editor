import AppKit
import PDFKit
import UniformTypeIdentifiers

@MainActor
final class PDFDocumentStore: ObservableObject {
    @Published var document: PDFDocument?
    @Published var fileURL: URL?
    @Published var currentPageIndex = 0
    @Published var selectedTool: PDFInteractionTool = .select
    @Published var sidebarPanel: SidebarPanel = .pages
    @Published var annotationColor: AnnotationSwatch = .yellow
    @Published var fontSize = 16.0
    @Published var layoutMode: PageLayoutMode = .singleContinuous
    @Published var searchText = ""
    @Published var searchResultCount = 0
    @Published var zoomPercent = 100
    @Published var isDirty = false
    @Published var statusMessage = "Bereit"
    @Published var revision = 0

    weak var pdfView: PDFView?

    var hasDocument: Bool {
        document != nil
    }

    var pageCount: Int {
        document?.pageCount ?? 0
    }

    var documentTitle: String {
        PDFUtilities.displayName(for: fileURL)
    }

    var currentPage: PDFPage? {
        if let page = pdfView?.currentPage {
            return page
        }

        guard let document, currentPageIndex >= 0, currentPageIndex < document.pageCount else {
            return nil
        }

        return document.page(at: currentPageIndex)
    }

    var currentPageSizeLabel: String {
        PDFUtilities.pageSizeLabel(for: currentPage)
    }

    func attach(pdfView: PDFView) {
        self.pdfView = pdfView
        configure(pdfView)
        pdfView.document = document
        syncFromPDFView(pdfView)
    }

    func configure(_ pdfView: PDFView) {
        pdfView.autoScales = true
        pdfView.displayMode = layoutMode.pdfDisplayMode
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.enableDataDetectors = true
        pdfView.backgroundColor = .windowBackgroundColor
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "PDF-Datei öffnen"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        loadDocument(from: url)
    }

    func loadDocument(from url: URL) {
        guard let pdfDocument = PDFDocument(url: url) else {
            statusMessage = "Die Datei konnte nicht geöffnet werden."
            return
        }

        setDocument(pdfDocument, url: url, dirty: false)
        statusMessage = "\(url.lastPathComponent) geöffnet"
    }

    func createBlankDocument() {
        setDocument(PDFUtilities.blankDocument(), url: nil, dirty: true)
        statusMessage = "Neues PDF erstellt"
    }

    func saveDocument() {
        guard let document else {
            return
        }

        if let fileURL {
            if document.write(to: fileURL) {
                isDirty = false
                statusMessage = "\(fileURL.lastPathComponent) gespeichert"
            } else {
                statusMessage = "Das PDF konnte nicht gespeichert werden."
            }
            return
        }

        saveDocumentAs()
    }

    func saveDocumentAs() {
        guard let document else {
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = documentTitle
        panel.message = "PDF sichern"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        if document.write(to: url) {
            fileURL = url
            isDirty = false
            statusMessage = "\(url.lastPathComponent) gespeichert"
        } else {
            statusMessage = "Das PDF konnte nicht gespeichert werden."
        }
    }

    func addBlankPage() {
        ensureDocument()
        guard let document, let page = PDFUtilities.blankPage() else {
            return
        }

        let insertionIndex = min(currentPageIndex + 1, document.pageCount)
        document.insert(page, at: insertionIndex)
        markChanged("Leere Seite eingefügt")
        goToPage(insertionIndex)
    }

    func importImagesAsPages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Bilder als PDF-Seiten einfügen"

        guard panel.runModal() == .OK, !panel.urls.isEmpty else {
            return
        }

        ensureDocument()
        guard let document else {
            return
        }

        let firstInsertedIndex = document.pageCount
        var inserted = 0

        for url in panel.urls {
            guard let image = NSImage(contentsOf: url), let page = PDFPage(image: image) else {
                continue
            }

            document.insert(page, at: document.pageCount)
            inserted += 1
        }

        if inserted > 0 {
            markChanged("\(inserted) Bildseiten eingefügt")
            goToPage(firstInsertedIndex)
        } else {
            statusMessage = "Keine lesbaren Bilder gefunden."
        }
    }

    func mergePDFs() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "PDFs zusammenführen"

        guard panel.runModal() == .OK, !panel.urls.isEmpty else {
            return
        }

        ensureDocument()
        guard let document else {
            return
        }

        let firstInsertedIndex = document.pageCount
        var inserted = 0

        for url in panel.urls {
            guard let source = PDFDocument(url: url) else {
                continue
            }

            for pageIndex in 0..<source.pageCount {
                guard let page = source.page(at: pageIndex) else {
                    continue
                }

                document.insert(page, at: document.pageCount)
                inserted += 1
            }
        }

        if inserted > 0 {
            markChanged("\(inserted) Seiten zusammengeführt")
            goToPage(firstInsertedIndex)
        } else {
            statusMessage = "Keine PDF-Seiten gefunden."
        }
    }

    func deleteCurrentPage() {
        guard let document, document.pageCount > 1 else {
            statusMessage = "Die letzte Seite kann nicht gelöscht werden."
            return
        }

        let deleteIndex = min(max(currentPageIndex, 0), document.pageCount - 1)
        document.removePage(at: deleteIndex)
        let nextIndex = min(deleteIndex, document.pageCount - 1)
        markChanged("Seite \(deleteIndex + 1) gelöscht")
        goToPage(nextIndex)
    }

    func rotateCurrentPage(clockwise: Bool) {
        guard let page = currentPage else {
            return
        }

        let delta = clockwise ? 90 : -90
        let rotation = (page.rotation + delta + 360) % 360
        page.rotation = rotation
        markChanged("Seite gedreht")
    }

    func moveCurrentPage(by offset: Int) {
        guard let document, let page = currentPage else {
            return
        }

        let oldIndex = document.index(for: page)
        let newIndex = oldIndex + offset
        guard oldIndex >= 0, newIndex >= 0, newIndex < document.pageCount else {
            return
        }

        document.removePage(at: oldIndex)
        document.insert(page, at: newIndex)
        markChanged("Seite verschoben")
        goToPage(newIndex)
    }

    func goToPage(_ index: Int) {
        guard let document, index >= 0, index < document.pageCount else {
            return
        }

        currentPageIndex = index
        if let page = document.page(at: index) {
            pdfView?.go(to: page)
        }
    }

    func goToPreviousPage() {
        goToPage(currentPageIndex - 1)
    }

    func goToNextPage() {
        goToPage(currentPageIndex + 1)
    }

    func zoomIn() {
        pdfView?.zoomIn(nil)
        syncFromPDFView(pdfView)
    }

    func zoomOut() {
        pdfView?.zoomOut(nil)
        syncFromPDFView(pdfView)
    }

    func fitToWindow() {
        guard let pdfView else {
            return
        }

        pdfView.autoScales = true
        syncFromPDFView(pdfView)
        statusMessage = "Ansicht angepasst"
    }

    func applyLayoutMode() {
        guard let pdfView else {
            return
        }

        pdfView.displayMode = layoutMode.pdfDisplayMode
        pdfView.autoScales = true
        syncFromPDFView(pdfView)
    }

    func runSearch() {
        guard let document else {
            return
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            clearSearch()
            return
        }

        let selections = document.findString(query, withOptions: [.caseInsensitive])
        searchResultCount = selections.count
        pdfView?.highlightedSelections = selections

        if let first = selections.first {
            pdfView?.setCurrentSelection(first, animate: true)
            pdfView?.go(to: first)
            syncFromPDFView(pdfView)
            statusMessage = "\(selections.count) Treffer"
        } else {
            statusMessage = "Keine Treffer"
        }
    }

    func clearSearch() {
        searchResultCount = 0
        pdfView?.highlightedSelections = nil
        statusMessage = "Suche zurückgesetzt"
    }

    func addFreeTextAnnotation(text: String = "Text") {
        guard let page = currentPage else {
            return
        }

        let annotation = PDFAnnotation(
            bounds: defaultAnnotationBounds(on: page, width: 220, height: 56),
            forType: .freeText,
            withProperties: nil
        )
        annotation.contents = text
        annotation.font = .systemFont(ofSize: fontSize)
        annotation.fontColor = annotationColor.nsColor
        annotation.color = .clear
        annotation.border = border(lineWidth: 0)
        page.addAnnotation(annotation)
        selectedTool = .text
        markChanged("Textfeld eingefügt")
    }

    func addNoteAnnotation() {
        guard let page = currentPage else {
            return
        }

        let annotation = PDFAnnotation(
            bounds: defaultAnnotationBounds(on: page, width: 32, height: 32),
            forType: .text,
            withProperties: nil
        )
        annotation.contents = "Notiz"
        annotation.color = annotationColor.nsColor
        page.addAnnotation(annotation)
        selectedTool = .note
        markChanged("Notiz eingefügt")
    }

    func addMarkupAnnotation(_ kind: MarkupAnnotationKind) {
        guard let pdfView, let selection = pdfView.currentSelection else {
            statusMessage = kind.fallbackStatus
            return
        }

        let lineSelections = selection.selectionsByLine()
        guard !lineSelections.isEmpty else {
            statusMessage = kind.fallbackStatus
            return
        }

        var count = 0
        for lineSelection in lineSelections {
            for page in lineSelection.pages {
                let bounds = lineSelection.bounds(for: page).insetBy(dx: -1, dy: -1)
                guard !bounds.isEmpty else {
                    continue
                }

                let annotation = PDFAnnotation(bounds: bounds, forType: kind.pdfSubtype, withProperties: nil)
                annotation.color = annotationColor.nsColor.withAlphaComponent(kind == .highlight ? 0.45 : 0.85)
                page.addAnnotation(annotation)
                count += 1
            }
        }

        if count > 0 {
            selectedTool = .highlight
            markChanged("Anmerkung hinzugefügt")
        } else {
            statusMessage = kind.fallbackStatus
        }
    }

    func addStamp(text: String) {
        guard let page = currentPage else {
            return
        }

        let annotation = PDFAnnotation(
            bounds: defaultAnnotationBounds(on: page, width: 168, height: 44),
            forType: .freeText,
            withProperties: nil
        )
        annotation.contents = text
        annotation.font = .boldSystemFont(ofSize: 15)
        annotation.fontColor = annotationColor.nsColor
        annotation.color = annotationColor.nsColor.withAlphaComponent(0.12)
        annotation.border = border(lineWidth: 1.5)
        page.addAnnotation(annotation)
        selectedTool = .stamp
        markChanged("Stempel eingefügt")
    }

    func addSignaturePlaceholder() {
        guard let page = currentPage else {
            return
        }

        let annotation = PDFAnnotation(
            bounds: defaultAnnotationBounds(on: page, width: 240, height: 72),
            forType: .freeText,
            withProperties: nil
        )
        annotation.contents = "Unterschrift"
        annotation.font = .systemFont(ofSize: 22, weight: .light)
        annotation.fontColor = annotationColor.nsColor
        annotation.color = .clear
        annotation.border = border(lineWidth: 1)
        page.addAnnotation(annotation)
        selectedTool = .sign
        markChanged("Signaturfeld eingefügt")
    }

    func removeLastAnnotationOnCurrentPage() {
        guard let page = currentPage, let annotation = page.annotations.last else {
            statusMessage = "Keine Anmerkung auf dieser Seite."
            return
        }

        page.removeAnnotation(annotation)
        markChanged("Anmerkung entfernt")
    }

    func thumbnail(for pageIndex: Int, size: CGSize) -> NSImage? {
        document?.page(at: pageIndex)?.thumbnail(of: size, for: .cropBox)
    }

    func syncFromPDFView(_ view: PDFView?) {
        guard let view else {
            return
        }

        if let page = view.currentPage, let document {
            let index = document.index(for: page)
            if index >= 0 {
                currentPageIndex = index
            }
        }

        zoomPercent = Int((view.scaleFactor * 100).rounded())
    }

    private func setDocument(_ document: PDFDocument, url: URL?, dirty: Bool) {
        self.document = document
        self.fileURL = url
        self.isDirty = dirty
        self.currentPageIndex = 0
        self.searchText = ""
        self.searchResultCount = 0
        self.revision += 1
        pdfView?.document = document
        pdfView?.highlightedSelections = nil
        pdfView?.autoScales = true
        goToPage(0)
        syncFromPDFView(pdfView)
    }

    private func ensureDocument() {
        if document == nil {
            setDocument(PDFDocument(), url: nil, dirty: true)
        }
    }

    private func markChanged(_ message: String) {
        isDirty = true
        revision += 1
        statusMessage = message
        pdfView?.needsDisplay = true
        syncFromPDFView(pdfView)
    }

    private func defaultAnnotationBounds(on page: PDFPage, width: CGFloat, height: CGFloat) -> CGRect {
        let pageBounds = page.bounds(for: .cropBox)
        let x = pageBounds.midX - width / 2
        let y = pageBounds.midY - height / 2
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func border(lineWidth: CGFloat) -> PDFBorder {
        let border = PDFBorder()
        border.lineWidth = lineWidth
        border.style = .solid
        return border
    }
}
