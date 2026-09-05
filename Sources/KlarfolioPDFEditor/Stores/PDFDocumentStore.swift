import AppKit
import CryptoKit
import PDFKit
import UniformTypeIdentifiers

@MainActor
final class PDFDocumentStore: ObservableObject {
    static let workspaceModeDefaultsKey = "at.ostheimer.klarfoliopdf.workspaceMode"
    static let readingPositionDefaultsPrefix = "at.ostheimer.klarfoliopdf.readingPosition."
    static let pageBookmarksDefaultsPrefix = "at.ostheimer.klarfoliopdf.pageBookmarks."

    enum UnsavedChangesDecision {
        case save
        case discard
        case cancel
    }

    private let preferences: UserDefaults
    private let unsavedChangesDecisionProvider: ((PDFDocumentStore) -> UnsavedChangesDecision)?
    private let saveChangesHandler: ((PDFDocumentStore) -> Bool)?
    private let passwordProvider: ((URL, Bool) -> String?)?
    private var formAnnotations: [String: PDFAnnotation] = [:]
    private var activeReadingDocumentIdentifier: String?
    private var isRestoringReadingState = false

    @Published private(set) var workspaceMode: PDFWorkspaceMode {
        didSet {
            preferences.set(workspaceMode.rawValue, forKey: Self.workspaceModeDefaultsKey)
        }
    }
    @Published var document: PDFDocument? {
        didSet { protection = document.map(PDFDocumentProtection.init(document:)) ?? PDFDocumentProtection() }
    }
    @Published private(set) var protection = PDFDocumentProtection()
    @Published var fileURL: URL?
    @Published var currentPageIndex = 0 {
        didSet {
            persistCurrentReadingPosition()
        }
    }
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
    @Published private(set) var documentOutline: [PDFOutlineItem] = []
    @Published private(set) var pageBookmarks: [PDFPageBookmark] = []
    @Published private(set) var formFields: [PDFFormField] = []
    @Published private(set) var selectedAnnotation: PDFAnnotation?
    @Published private(set) var selectedAnnotationPageIndex: Int?
    @Published var selectedAnnotationText = ""
    @Published var linkTargetMode: PDFLinkTargetMode = .website
    @Published var linkURLString = "https://"
    @Published var linkDestinationPage = 1
    @Published var extractionStartPage = 1
    @Published var extractionEndPage = 1

    weak var pdfView: PDFView?
    private var isOpeningDocument = false

    func canPerform(_ operation: PDFOperation) -> Bool {
        if operation != .save && operation != .copy && operation != .print,
           workspaceMode != .editing { return false }
        guard let document else { return operation == .assemblePages && workspaceMode == .editing }
        return !document.isLocked && protection.allows(operation)
    }

    func fileDropAction(for urls: [URL]) -> PDFFileDropAction? {
        let action = PDFFileDropAction.resolve(urls, workspaceMode: workspaceMode)
        if case .importImages = action, !canPerform(.assemblePages) { return nil }
        return action
    }

    @discardableResult
    func requirePermission(_ operation: PDFOperation) -> Bool {
        guard canPerform(operation) else {
            statusMessage = protection.readOnlyReason
                ?? (workspaceMode == .reading && operation != .save && operation != .copy && operation != .print
                    ? "Diese Aktion benötigt den Bearbeitungsmodus."
                    : "Die PDF-Berechtigungen erlauben diese Aktion nicht.")
            return false
        }
        return true
    }

    func canEditAnnotation(_ annotation: PDFAnnotation, on page: PDFPage) -> Bool {
        canPerform(.annotate) && page.document === document
            && page.annotations.contains(where: { $0 === annotation })
            && !annotation.hasSubtype(.widget) && !annotation.hasSubtype(.popup)
    }

    /// The view must never mutate bounds before this central check.
    @discardableResult
    func moveAnnotation(_ annotation: PDFAnnotation, on page: PDFPage, to bounds: CGRect) -> Bool {
        guard canEditAnnotation(annotation, on: page), annotation === selectedAnnotation,
              bounds.origin.x.isFinite, bounds.origin.y.isFinite else { return false }
        let constrained = constrainedAnnotationBounds(bounds, on: page)
        guard constrained != annotation.bounds else { return false }
        annotation.bounds = constrained
        annotation.modificationDate = Date()
        pdfView?.annotationsChanged(on: page)
        markChanged("Anmerkung verschoben")
        return true
    }

    init(
        preferences: UserDefaults = .standard,
        unsavedChangesDecisionProvider: ((PDFDocumentStore) -> UnsavedChangesDecision)? = nil,
        saveChangesHandler: ((PDFDocumentStore) -> Bool)? = nil,
        passwordProvider: ((URL, Bool) -> String?)? = nil
    ) {
        self.preferences = preferences
        self.unsavedChangesDecisionProvider = unsavedChangesDecisionProvider
        self.saveChangesHandler = saveChangesHandler
        self.passwordProvider = passwordProvider
        workspaceMode = .reading
    }

    func setWorkspaceMode(_ mode: PDFWorkspaceMode) {
        guard workspaceMode != mode else {
            return
        }

        workspaceMode = mode

        if mode == .reading {
            clearAnnotationSelection()
            selectedTool = .select
        }
    }

    func toggleWorkspaceMode() {
        setWorkspaceMode(workspaceMode == .reading ? .editing : .reading)
    }

    var hasDocument: Bool {
        document != nil
    }

    var pageCount: Int {
        document?.pageCount ?? 0
    }

    var isCurrentPageBookmarked: Bool {
        pageBookmarks.contains { $0.pageIndex == currentPageIndex }
    }

    var documentTitle: String {
        PDFUtilities.displayName(for: fileURL)
    }

    var currentPage: PDFPage? {
        if let page = pdfView?.currentPage, page.document === document {
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

    var hasSelectedAnnotation: Bool {
        selectedAnnotation != nil
    }

    var selectedAnnotationIsLink: Bool {
        guard let selectedAnnotation else {
            return false
        }

        return selectedAnnotation.hasSubtype(.link)
    }

    var selectedAnnotationTypeTitle: String {
        guard let annotation = selectedAnnotation, let type = annotation.type else {
            return "Keine Auswahl"
        }

        if annotation.hasSubtype(.freeText) { return "Textfeld" }
        if annotation.hasSubtype(.text) { return "Notiz" }
        if annotation.hasSubtype(.highlight) { return "Hervorhebung" }
        if annotation.hasSubtype(.underline) { return "Unterstreichung" }
        if annotation.hasSubtype(.strikeOut) { return "Durchstreichung" }
        if annotation.hasSubtype(.link) { return "Link" }
        if annotation.hasSubtype(.stamp) { return "Stempel" }
        if annotation.hasSubtype(.ink) { return "Zeichnung" }
        if annotation.hasSubtype(.square) { return "Rechteck" }
        if annotation.hasSubtype(.circle) { return "Ellipse" }
        return type
    }

    func attach(pdfView: PDFView) {
        self.pdfView = pdfView
        configure(pdfView)
        pdfView.document = document
        goToPage(currentPageIndex)
        syncFromPDFView(pdfView)
    }

    func configure(_ pdfView: PDFView) {
        pdfView.autoScales = true
        pdfView.displayMode = layoutMode.pdfDisplayMode
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        if #unavailable(macOS 15) {
            pdfView.enableDataDetectors = true
        }
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

    @discardableResult
    func loadDocument(from url: URL) -> Bool {
        guard !isOpeningDocument else { return false }
        isOpeningDocument = true
        defer { isOpeningDocument = false }
        let previousDocument = document
        let previousRevision = revision
        guard let pdfDocument = PDFDocument(url: url) else {
            statusMessage = "Die Datei konnte nicht geöffnet werden."
            return false
        }

        var retry = false
        while pdfDocument.isLocked {
            // The password lives only in this loop iteration and the secure
            // native input; never in Published state, preferences or logs.
            let enteredPassword: String?
            if let passwordProvider { enteredPassword = passwordProvider(url, retry) }
            else { enteredPassword = presentPasswordAlert(for: url, retry: retry) }
            guard let password = enteredPassword else {
                statusMessage = "Öffnen abgebrochen"
                return false
            }
            _ = pdfDocument.unlock(withPassword: password)
            retry = true
        }
        guard document === previousDocument, revision == previousRevision,
              pdfDocument.pageCount > 0 else { return false }

        guard confirmDiscardingUnsavedChanges() else {
            return false
        }

        guard document === previousDocument else { return false }
        setDocument(pdfDocument, url: url, dirty: false)
        setWorkspaceMode(.reading)
        statusMessage = "\(url.lastPathComponent) geöffnet"
        return true
    }

    private func presentPasswordAlert(for url: URL, retry: Bool) -> String? {
        let alert = NSAlert()
        alert.messageText = retry ? "Das Passwort ist nicht korrekt." : "Passwortgeschütztes PDF"
        alert.informativeText = "Gib das Passwort für „\(url.lastPathComponent)“ ein."
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 26))
        field.placeholderString = "Passwort"
        field.setAccessibilityIdentifier("documentPassword.input")
        alert.accessoryView = field
        alert.addButton(withTitle: "Öffnen")
        alert.addButton(withTitle: "Abbrechen")
        alert.buttons[0].setAccessibilityIdentifier("documentPassword.open")
        alert.buttons[1].setAccessibilityIdentifier("documentPassword.cancel")
        alert.buttons[1].keyEquivalent = "\u{1b}"
        alert.window.initialFirstResponder = field
        defer { field.stringValue = "" }
        return alert.runModal() == .alertFirstButtonReturn ? field.stringValue : nil
    }

    @discardableResult
    func createBlankDocument() -> Bool {
        guard confirmDiscardingUnsavedChanges() else {
            return false
        }

        setDocument(PDFUtilities.blankDocument(), url: nil, dirty: true)
        statusMessage = "Neues PDF erstellt"
        return true
    }

    @discardableResult
    func saveDocument() -> Bool {
        guard requirePermission(.save) else { return false }
        guard let document else {
            return false
        }

        if let fileURL {
            if document.write(to: fileURL) {
                isDirty = false
                statusMessage = "\(fileURL.lastPathComponent) gespeichert"
                return true
            } else {
                statusMessage = "Das PDF konnte nicht gespeichert werden."
                return false
            }
        }

        return saveDocumentAs()
    }

    @discardableResult
    func saveDocumentAs() -> Bool {
        guard requirePermission(.save) else { return false }
        guard let document else {
            return false
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = documentTitle
        panel.message = "PDF sichern"

        guard panel.runModal() == .OK, let url = panel.url else {
            return false
        }

        guard self.document === document, requirePermission(.save) else { return false }
        if document.write(to: url) {
            fileURL = url
            activateReadingState(for: url, document: document)
            persistCurrentReadingPosition()
            isDirty = false
            statusMessage = "\(url.lastPathComponent) gespeichert"
            return true
        } else {
            statusMessage = "Das PDF konnte nicht gespeichert werden."
            return false
        }
    }

    @discardableResult
    func confirmDiscardingUnsavedChanges() -> Bool {
        guard document != nil, isDirty else {
            return true
        }

        let decision = unsavedChangesDecisionProvider?(self) ?? presentUnsavedChangesAlert()

        switch decision {
        case .save:
            let didSave = saveChangesHandler?(self) ?? saveDocument()
            return didSave && !isDirty
        case .discard:
            return true
        case .cancel:
            return false
        }
    }

    private func presentUnsavedChangesAlert() -> UnsavedChangesDecision {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Möchtest du die Änderungen an „\(documentTitle)“ speichern?"
        alert.informativeText = "Wenn du die Änderungen nicht speicherst, gehen sie verloren."
        alert.addButton(withTitle: "Speichern")
        alert.addButton(withTitle: "Verwerfen")
        alert.addButton(withTitle: "Abbrechen")
        alert.buttons[0].setAccessibilityIdentifier("documentSafety.save")
        alert.buttons[1].setAccessibilityIdentifier("documentSafety.discard")
        alert.buttons[2].setAccessibilityIdentifier("documentSafety.cancel")
        alert.buttons[0].keyEquivalent = "\r"
        alert.buttons[2].keyEquivalent = "\u{1b}"

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .save
        case .alertSecondButtonReturn:
            return .discard
        default:
            return .cancel
        }
    }

    func addBlankPage() {
        guard requirePermission(.assemblePages) else { return }
        ensureDocument()
        guard let document, let page = PDFUtilities.blankPage() else {
            return
        }

        let insertionIndex = min(currentPageIndex + 1, document.pageCount)
        document.insert(page, at: insertionIndex)
        markChanged("Leere Seite eingefügt", refreshDocumentOutline: true)
        goToPage(insertionIndex)
    }

    func importImagesAsPages() {
        guard requirePermission(.assemblePages) else { return }
        let expectedDocument = document
        let expectedRevision = revision
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Bilder als PDF-Seiten einfügen"

        guard panel.runModal() == .OK, !panel.urls.isEmpty else {
            return
        }

        guard document === expectedDocument, revision == expectedRevision else { return }
        importImages(from: panel.urls)
    }

    @discardableResult
    func importImages(from urls: [URL]) -> Int {
        guard requirePermission(.assemblePages) else { return 0 }
        guard !urls.isEmpty else {
            return 0
        }

        ensureDocument()
        guard let document else {
            return 0
        }

        let firstInsertedIndex = document.pageCount
        var inserted = 0

        for url in urls {
            guard let image = NSImage(contentsOf: url), let page = PDFPage(image: image) else {
                continue
            }

            document.insert(page, at: document.pageCount)
            inserted += 1
        }

        if inserted > 0 {
            markChanged("\(inserted) Bildseiten eingefügt", refreshDocumentOutline: true)
            goToPage(firstInsertedIndex)
        } else {
            statusMessage = "Keine lesbaren Bilder gefunden."
        }

        return inserted
    }

    func mergePDFs() {
        guard requirePermission(.assemblePages) else { return }
        let expectedDocument = document
        let expectedRevision = revision
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "PDFs zusammenführen"

        guard panel.runModal() == .OK, !panel.urls.isEmpty else {
            return
        }

        guard document === expectedDocument, revision == expectedRevision else { return }
        _ = mergeDocuments(from: panel.urls)
    }

    @discardableResult
    func mergeDocuments(from urls: [URL]) -> Int {
        guard requirePermission(.assemblePages), !urls.isEmpty else { return 0 }
        // Prepare every source before changing the destination. Protected sources
        // are not rewritten as unprotected pages or partially imported.
        var pages: [PDFPage] = []
        var preparedSources: [PDFDocument] = []
        for url in urls {
            guard let source = PDFDocument(url: url),
                  PDFDocumentProtection(document: source).allows(.exportPages), source.pageCount > 0 else {
                statusMessage = "Zusammenführen abgebrochen: Eine Quelle ist geschützt oder nicht lesbar."
                return 0
            }
            let prepared = PDFDocument()
            var copiedPages: [(source: PDFPage, copy: PDFPage)] = []
            for index in 0..<source.pageCount {
                guard let original = source.page(at: index),
                      let copy = original.copy() as? PDFPage else { return 0 }
                prepared.insert(copy, at: prepared.pageCount)
                copiedPages.append((original, copy))
                pages.append(copy)
            }
            // Keep each original alive until its destinations refer to the
            // corresponding copied pages, never to another source or target page.
            remapInternalLinks(in: copiedPages, sourceDocument: source, sourceRange: 0...(source.pageCount - 1))
            preparedSources.append(prepared)
        }
        ensureDocument()
        guard let document else {
            return 0
        }

        let firstInsertedIndex = document.pageCount
        let inserted = pages.count
        withExtendedLifetime(preparedSources) {
            for page in pages { document.insert(page, at: document.pageCount) }
        }

        if inserted > 0 {
            markChanged("\(inserted) Seiten zusammengeführt", refreshDocumentOutline: true)
            goToPage(firstInsertedIndex)
        } else {
            statusMessage = "Keine PDF-Seiten gefunden."
        }
        return inserted
    }

    func extractPages() {
        guard requirePermission(.exportPages) else { return }
        let expectedRevision = revision
        guard let document else {
            return
        }

        let startIndex = extractionStartPage - 1
        let endIndex = extractionEndPage - 1
        guard startIndex >= 0,
              endIndex >= startIndex,
              endIndex < document.pageCount,
              let extractedDocument = documentByCopyingPages(in: startIndex...endIndex) else {
            statusMessage = "Bitte einen gültigen Seitenbereich wählen."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = exportName(
            suffix: startIndex == endIndex
                ? "Seite-\(startIndex + 1)"
                : "Seiten-\(startIndex + 1)-\(endIndex + 1)"
        )
        panel.message = "Ausgewählte Seiten als neues PDF sichern"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        guard self.document === document, revision == expectedRevision else { return }
        _ = writePages(in: startIndex...endIndex, to: url, preparedDocument: extractedDocument)
    }

    func useCurrentPageForExtraction() {
        let pageNumber = min(max(currentPageIndex + 1, 1), max(pageCount, 1))
        extractionStartPage = pageNumber
        extractionEndPage = pageNumber
    }

    func splitDocumentAfterCurrentPage() {
        guard requirePermission(.exportPages) else { return }
        let expectedRevision = revision
        guard let document, document.pageCount > 1 else {
            statusMessage = "Zum Teilen werden mindestens zwei Seiten benötigt."
            return
        }

        let splitIndex = min(max(currentPageIndex, 0), document.pageCount - 1)
        guard splitIndex < document.pageCount - 1,
              let firstPart = documentByCopyingPages(in: 0...splitIndex),
              let secondPart = documentByCopyingPages(in: (splitIndex + 1)...(document.pageCount - 1)) else {
            statusMessage = "Nach der letzten Seite kann das Dokument nicht geteilt werden."
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Auswählen"
        panel.message = "Zielordner für die beiden PDF-Teile auswählen"

        guard panel.runModal() == .OK, let directoryURL = panel.url else {
            return
        }

        let baseName = fileURL?.deletingPathExtension().lastPathComponent ?? "Dokument"
        let firstURL = directoryURL.appendingPathComponent("\(baseName)-Teil-1.pdf")
        let secondURL = directoryURL.appendingPathComponent("\(baseName)-Teil-2.pdf")

        guard confirmOverwriteIfNeeded([firstURL, secondURL]) else {
            statusMessage = "Teilen abgebrochen"
            return
        }

        guard self.document === document, revision == expectedRevision else { return }
        _ = writeSplitDocument(
            afterPageAt: splitIndex,
            firstPartURL: firstURL,
            secondPartURL: secondURL,
            preparedParts: (firstPart, secondPart)
        )
    }

    func documentByCopyingPages(in range: ClosedRange<Int>) -> PDFDocument? {
        guard requirePermission(.exportPages) else { return nil }
        guard let document,
              range.lowerBound >= 0,
              range.upperBound < document.pageCount else {
            return nil
        }

        let result = PDFDocument()
        var copiedPages: [(source: PDFPage, copy: PDFPage)] = []
        for pageIndex in range {
            guard let page = document.page(at: pageIndex),
                  let pageCopy = page.copy() as? PDFPage else {
                return nil
            }

            result.insert(pageCopy, at: result.pageCount)
            copiedPages.append((page, pageCopy))
        }

        remapInternalLinks(in: copiedPages, sourceDocument: document, sourceRange: range)
        return result.pageCount > 0 ? result : nil
    }

    @discardableResult
    func writePages(in range: ClosedRange<Int>, to url: URL) -> Bool {
        guard requirePermission(.exportPages) else { return false }
        guard let extractedDocument = documentByCopyingPages(in: range) else {
            statusMessage = "Bitte einen gültigen Seitenbereich wählen."
            return false
        }

        return writePages(in: range, to: url, preparedDocument: extractedDocument)
    }

    @discardableResult
    func writeSplitDocument(
        afterPageAt splitIndex: Int,
        firstPartURL: URL,
        secondPartURL: URL
    ) -> Bool {
        guard requirePermission(.exportPages) else { return false }
        guard let document,
              splitIndex >= 0,
              splitIndex < document.pageCount - 1,
              let firstPart = documentByCopyingPages(in: 0...splitIndex),
              let secondPart = documentByCopyingPages(in: (splitIndex + 1)...(document.pageCount - 1)) else {
            statusMessage = "Bitte eine Teilung vor der letzten Seite wählen."
            return false
        }

        return writeSplitDocument(
            afterPageAt: splitIndex,
            firstPartURL: firstPartURL,
            secondPartURL: secondPartURL,
            preparedParts: (firstPart, secondPart)
        )
    }

    func deleteCurrentPage() {
        guard requirePermission(.assemblePages) else { return }
        guard let document, document.pageCount > 1 else {
            statusMessage = "Die letzte Seite kann nicht gelöscht werden."
            return
        }

        let deleteIndex = min(max(currentPageIndex, 0), document.pageCount - 1)
        if selectedAnnotationPageIndex == deleteIndex {
            clearAnnotationSelection()
        }
        if let deletedPage = document.page(at: deleteIndex) {
            removeInternalLinks(targeting: deletedPage, in: document)
        }
        document.removePage(at: deleteIndex)
        let nextIndex = min(deleteIndex, document.pageCount - 1)
        markChanged("Seite \(deleteIndex + 1) gelöscht", refreshDocumentOutline: true)
        goToPage(nextIndex)
    }

    var canBeginPageCrop: Bool {
        guard canPerform(.cropPage), let document,
              let page = currentPage,
              pageIndex(of: page, in: document) != nil else { return false }
        return PDFCropGeometry(mediaBox: page.bounds(for: .mediaBox), rotation: page.rotation) != nil
    }

    func beginPageCrop() -> PDFCropSession? {
        guard requirePermission(.cropPage), let document,
              let page = currentPage,
              let index = pageIndex(of: page, in: document),
              let geometry = PDFCropGeometry(mediaBox: page.bounds(for: .mediaBox), rotation: page.rotation)
        else { return nil }
        return PDFCropSession(document: document, page: page, pageIndex: index, geometry: geometry,
                              originalCrop: page.bounds(for: .cropBox), originalRotation: page.rotation)
    }

    @discardableResult
    func applyPageCrop(_ crop: CGRect, session: PDFCropSession) -> Bool {
        guard requirePermission(.cropPage), let document, document === session.document,
              currentPage === session.page, document.page(at: session.pageIndex) === session.page,
              session.page.rotation == session.originalRotation,
              session.page.bounds(for: .mediaBox) == session.geometry.mediaBox,
              session.page.bounds(for: .cropBox) == session.originalCrop,
              session.geometry.isValid(crop), crop != session.originalCrop else { return false }
        session.page.setBounds(crop, for: .cropBox)
        // PDFKit must recalculate page layout after box changes; retain page identity,
        // annotations, outline destinations and the user's current page.
        pdfView?.layoutDocumentView()
        markChanged(crop == session.geometry.mediaBox ? "Seitengröße wiederhergestellt" : "Seite zugeschnitten")
        goToPage(session.pageIndex)
        return true
    }

    @discardableResult
    func resetPageCrop(session: PDFCropSession) -> Bool {
        applyPageCrop(session.geometry.mediaBox, session: session)
    }

    func rotateCurrentPage(clockwise: Bool) {
        guard requirePermission(.assemblePages) else { return }
        guard let page = currentPage else {
            return
        }

        let delta = clockwise ? 90 : -90
        let rotation = (page.rotation + delta + 360) % 360
        page.rotation = rotation
        markChanged("Seite gedreht")
    }

    func moveCurrentPage(by offset: Int) {
        guard requirePermission(.assemblePages) else { return }
        guard let document, let page = currentPage else {
            return
        }

        guard let oldIndex = pageIndex(of: page, in: document) else {
            return
        }
        let newIndex = oldIndex + offset
        guard document.pageCount > 0, (0..<document.pageCount).contains(newIndex) else {
            return
        }

        document.removePage(at: oldIndex)
        document.insert(page, at: newIndex)
        if selectedAnnotation?.page === page {
            selectedAnnotationPageIndex = newIndex
        }
        markChanged("Seite verschoben", refreshDocumentOutline: true)
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

    func toggleBookmarkForCurrentPage() {
        guard activeReadingDocumentIdentifier != nil,
              let document,
              (0..<document.pageCount).contains(currentPageIndex) else {
            return
        }

        if let existingBookmark = pageBookmarks.first(where: { $0.pageIndex == currentPageIndex }) {
            removeBookmark(existingBookmark.id)
            return
        }

        pageBookmarks.append(
            PDFPageBookmark(
                id: "page-\(currentPageIndex)",
                pageIndex: currentPageIndex,
                title: "Seite \(currentPageIndex + 1)"
            )
        )
        pageBookmarks.sort { $0.pageIndex < $1.pageIndex }
        persistPageBookmarks()
    }

    func removeBookmark(_ bookmarkID: String) {
        guard let bookmarkIndex = pageBookmarks.firstIndex(where: { $0.id == bookmarkID }) else {
            return
        }

        pageBookmarks.remove(at: bookmarkIndex)
        persistPageBookmarks()
    }

    func goToBookmark(_ bookmarkID: String) {
        guard let bookmark = pageBookmarks.first(where: { $0.id == bookmarkID }) else {
            return
        }

        goToPage(bookmark.pageIndex)
    }

    func goToOutline(_ item: PDFOutlineItem) {
        guard let pageIndex = item.pageIndex else {
            return
        }

        goToPage(pageIndex)
    }

    @discardableResult
    func updateFormTextField(_ fieldID: String, value: String) -> Bool {
        guard requirePermission(.fillForms) else { return false }
        guard workspaceMode == .editing,
              let field = formFields.first(where: { $0.id == fieldID }),
              field.kind == .text,
              !field.isReadOnly,
              let annotation = formAnnotations[fieldID],
              annotation.page?.document === document,
              annotation.hasSubtype(.widget),
              annotation.widgetFieldType == .text,
              !annotation.isPasswordField,
              !annotation.isReadOnly else {
            return false
        }

        let maximumLength = max(annotation.maximumLength, 0)
        let boundedValue = maximumLength > 0 ? String(value.prefix(maximumLength)) : value
        guard annotation.widgetStringValue ?? "" != boundedValue else {
            return false
        }

        annotation.widgetStringValue = boundedValue
        annotation.modificationDate = Date()
        if let page = annotation.page {
            pdfView?.annotationsChanged(on: page)
        }
        markChanged("Formularfeld „\(field.title)“ aktualisiert")
        return true
    }

    @discardableResult
    func updateFormCheckbox(_ fieldID: String, isOn: Bool) -> Bool {
        guard requirePermission(.fillForms) else { return false }
        guard workspaceMode == .editing,
              let field = formFields.first(where: { $0.id == fieldID }),
              field.kind == .checkbox,
              !field.isReadOnly,
              let annotation = formAnnotations[fieldID],
              annotation.page?.document === document,
              annotation.hasSubtype(.widget),
              annotation.widgetFieldType == .button,
              annotation.widgetControlType == .checkBoxControl,
              !annotation.isReadOnly else {
            return false
        }

        let requestedState: PDFWidgetCellState = isOn ? .onState : .offState
        guard annotation.buttonWidgetState != requestedState else {
            return false
        }

        annotation.buttonWidgetState = requestedState
        annotation.modificationDate = Date()
        if let page = annotation.page {
            pdfView?.annotationsChanged(on: page)
        }
        markChanged("Checkbox „\(field.title)“ aktualisiert")
        return true
    }

    func goToFormField(_ fieldID: String) {
        guard let annotation = formAnnotations[fieldID],
              let page = annotation.page,
              let document,
              let pageIndex = pageIndex(of: page, in: document) else {
            return
        }

        goToPage(pageIndex)
        pdfView?.go(to: annotation.bounds, on: page)
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

    func selectAnnotation(_ annotation: PDFAnnotation?, on page: PDFPage? = nil) {
        if let annotation {
            guard let page = page ?? annotation.page, canEditAnnotation(annotation, on: page) else { return }
        }
        selectedAnnotation = annotation

        guard let annotation else {
            selectedAnnotationPageIndex = nil
            selectedAnnotationText = ""
            pdfView?.needsDisplay = true
            return
        }

        let annotationPage = page ?? annotation.page
        if let annotationPage,
           let document,
           let pageIndex = pageIndex(of: annotationPage, in: document) {
            selectedAnnotationPageIndex = pageIndex
            goToPage(pageIndex)
        } else {
            selectedAnnotationPageIndex = nil
        }

        selectedAnnotationText = annotation.contents ?? ""
        loadStyle(from: annotation)
        loadLinkTarget(from: annotation)
        selectedTool = .select
        statusMessage = "\(selectedAnnotationTypeTitle) ausgewählt"
        pdfView?.needsDisplay = true
    }

    func clearAnnotationSelection() {
        selectAnnotation(nil)
    }

    func applySelectedAnnotationEdits() {
        guard let candidate = selectedAnnotation, let selectedPage = candidate.page,
              canEditAnnotation(candidate, on: selectedPage) else { return }
        guard let annotation = selectedAnnotation, let page = annotation.page else {
            statusMessage = "Keine Anmerkung ausgewählt."
            return
        }

        if selectedAnnotationIsLink, !applyLinkTarget(to: annotation) {
            return
        }

        if annotation.hasAppearanceStream && canRegenerateAppearance(for: annotation) {
            annotation.removeValue(forAnnotationKey: .appearanceDictionary)
            annotation.removeValue(forAnnotationKey: .appearanceState)
        }
        annotation.contents = selectedAnnotationText
        applyCurrentStyle(to: annotation)
        annotation.modificationDate = Date()
        pdfView?.annotationsChanged(on: page)
        markChanged("\(selectedAnnotationTypeTitle) aktualisiert")
    }

    func moveSelectedAnnotationBy(x: CGFloat, y: CGFloat) {
        guard let candidate = selectedAnnotation, let selectedPage = candidate.page,
              canEditAnnotation(candidate, on: selectedPage) else { return }
        guard let annotation = selectedAnnotation, let page = annotation.page else {
            statusMessage = "Keine Anmerkung ausgewählt."
            return
        }

        let originalBounds = annotation.bounds
        var movedBounds = originalBounds.offsetBy(dx: x, dy: y)
        movedBounds.origin = clampedAnnotationOrigin(for: movedBounds, on: page)
        guard movedBounds != originalBounds else {
            return
        }

        annotation.bounds = movedBounds
        annotation.modificationDate = Date()
        pdfView?.annotationsChanged(on: page)
        markChanged("Anmerkung verschoben")
    }

    func annotationMoveDidFinish(
        _ annotation: PDFAnnotation,
        on page: PDFPage,
        from originalBounds: CGRect
    ) {
        guard canEditAnnotation(annotation, on: page),
              annotation === selectedAnnotation, annotation.bounds != originalBounds else {
            return
        }

        annotation.modificationDate = Date()
        pdfView?.annotationsChanged(on: page)
        markChanged("Anmerkung verschoben")
    }

    func removeSelectedAnnotation() {
        guard let candidate = selectedAnnotation, let selectedPage = candidate.page,
              canEditAnnotation(candidate, on: selectedPage) else { return }
        guard let annotation = selectedAnnotation, let page = annotation.page else {
            statusMessage = "Keine Anmerkung ausgewählt."
            return
        }

        page.removeAnnotation(annotation)
        clearAnnotationSelection()
        pdfView?.annotationsChanged(on: page)
        markChanged("Anmerkung entfernt")
    }

    func addLinkAnnotation() {
        guard requirePermission(.annotate) else { return }
        guard currentPage != nil else {
            return
        }

        let locations = linkAnnotationLocations()
        guard !locations.isEmpty else {
            statusMessage = "Für den Link wurde keine gültige Position gefunden."
            return
        }

        var addedAnnotations: [(annotation: PDFAnnotation, page: PDFPage)] = []
        for location in locations {
            let annotation = PDFAnnotation(
                bounds: location.bounds,
                forType: .link,
                withProperties: nil
            )
            annotation.contents = linkTargetDescription
            annotation.color = NSColor.systemBlue
            annotation.border = border(lineWidth: 1)

            guard applyLinkTarget(to: annotation, reportErrors: addedAnnotations.isEmpty) else {
                continue
            }

            location.page.addAnnotation(annotation)
            addedAnnotations.append((annotation, location.page))
        }

        guard let first = addedAnnotations.first else {
            return
        }

        selectedTool = .link
        selectAnnotation(first.annotation, on: first.page)
        selectedTool = .link
        markChanged(
            addedAnnotations.count == 1
                ? "Link hinzugefügt"
                : "\(addedAnnotations.count) Link-Bereiche hinzugefügt"
        )
    }

    func addFreeTextAnnotation(text: String = "Text") {
        guard requirePermission(.annotate) else { return }
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
        selectAnnotation(annotation, on: page)
        selectedTool = .text
        markChanged("Textfeld eingefügt")
    }

    func addNoteAnnotation() {
        guard requirePermission(.annotate) else { return }
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
        selectAnnotation(annotation, on: page)
        selectedTool = .note
        markChanged("Notiz eingefügt")
    }

    func addMarkupAnnotation(_ kind: MarkupAnnotationKind) {
        guard requirePermission(.annotate) else { return }
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
                guard page.document === document else { continue }
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
        guard requirePermission(.annotate) else { return }
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
        selectAnnotation(annotation, on: page)
        selectedTool = .stamp
        markChanged("Stempel eingefügt")
    }

    func addSignaturePlaceholder() {
        guard requirePermission(.annotate) else { return }
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
        selectAnnotation(annotation, on: page)
        selectedTool = .sign
        markChanged("Signaturfeld eingefügt")
    }

    func removeLastAnnotationOnCurrentPage() {
        guard requirePermission(.annotate) else { return }
        guard let page = currentPage,
              let annotation = page.annotations.last(where: { !$0.hasSubtype(.popup) && !$0.hasSubtype(.widget) }) else {
            statusMessage = "Keine Anmerkung auf dieser Seite."
            return
        }

        page.removeAnnotation(annotation)
        if annotation === selectedAnnotation {
            clearAnnotationSelection()
        }
        markChanged("Anmerkung entfernt")
    }

    func thumbnail(for pageIndex: Int, size: CGSize) -> NSImage? {
        document?.page(at: pageIndex)?.thumbnail(of: size, for: .cropBox)
    }

    func syncFromPDFView(_ view: PDFView?) {
        guard let view, view === pdfView else {
            return
        }

        if let page = view.currentPage,
           let document,
           let index = pageIndex(of: page, in: document) {
            currentPageIndex = index
        }

        zoomPercent = Int((view.scaleFactor * 100).rounded())
    }

    func constrainedAnnotationBounds(_ proposedBounds: CGRect, on page: PDFPage) -> CGRect {
        var result = proposedBounds
        result.origin = clampedAnnotationOrigin(for: proposedBounds, on: page)
        return result
    }

    private func setDocument(_ document: PDFDocument, url: URL?, dirty: Bool) {
        isRestoringReadingState = true
        activeReadingDocumentIdentifier = nil
        selectedAnnotation = nil
        selectedAnnotationPageIndex = nil
        selectedAnnotationText = ""
        self.document = document
        self.fileURL = url
        self.isDirty = dirty
        self.currentPageIndex = 0
        self.searchText = ""
        self.searchResultCount = 0
        self.linkDestinationPage = 1
        self.extractionStartPage = 1
        self.extractionEndPage = 1
        self.documentOutline = readDocumentOutline(from: document)
        activateReadingState(for: url, document: document)
        let restoredPageIndex = restoredReadingPosition(in: document)
        refreshFormFields()
        self.revision += 1
        pdfView?.document = document
        pdfView?.highlightedSelections = nil
        pdfView?.autoScales = true
        goToPage(restoredPageIndex)
        syncFromPDFView(pdfView)
        isRestoringReadingState = false
        persistCurrentReadingPosition()
    }

    private func ensureDocument() {
        if document == nil {
            setDocument(PDFDocument(), url: nil, dirty: true)
        }
    }

    private func markChanged(_ message: String, refreshDocumentOutline: Bool = false) {
        refreshSelectedAnnotationLocation()
        refreshFormFields()
        discardInvalidPageBookmarks()
        if refreshDocumentOutline, let document {
            documentOutline = readDocumentOutline(from: document)
        }
        isDirty = true
        revision += 1
        statusMessage = message
        pdfView?.needsDisplay = true
        syncFromPDFView(pdfView)
    }

    private func activateReadingState(for url: URL?, document: PDFDocument) {
        guard let url,
              url.isFileURL,
              document.pageCount > 0 else {
            activeReadingDocumentIdentifier = nil
            pageBookmarks = []
            return
        }

        let normalizedPath = url.standardizedFileURL.resolvingSymlinksInPath().path
        let pathDigest = SHA256.hash(data: Data(normalizedPath.utf8))
        let identifier = pathDigest.map { String(format: "%02x", $0) }.joined()
        activeReadingDocumentIdentifier = identifier
        pageBookmarks = restoredPageBookmarks(for: identifier, pageCount: document.pageCount)
    }

    private func restoredReadingPosition(in document: PDFDocument) -> Int {
        guard document.pageCount > 0,
              let identifier = activeReadingDocumentIdentifier,
              let storedPageIndex = preferences.object(
                  forKey: Self.readingPositionDefaultsPrefix + identifier
              ) as? Int else {
            return 0
        }

        return min(max(storedPageIndex, 0), document.pageCount - 1)
    }

    private func persistCurrentReadingPosition() {
        guard !isRestoringReadingState,
              let identifier = activeReadingDocumentIdentifier,
              let document,
              (0..<document.pageCount).contains(currentPageIndex) else {
            return
        }

        preferences.set(currentPageIndex, forKey: Self.readingPositionDefaultsPrefix + identifier)
    }

    private func restoredPageBookmarks(for identifier: String, pageCount: Int) -> [PDFPageBookmark] {
        let defaultsKey = Self.pageBookmarksDefaultsPrefix + identifier
        guard let storedBookmarks = preferences.data(forKey: defaultsKey) else {
            return []
        }

        guard let decodedBookmarks = try? JSONDecoder().decode(
            [PDFPageBookmark].self,
            from: storedBookmarks
        ) else {
            preferences.removeObject(forKey: defaultsKey)
            return []
        }

        var bookmarkedPageIndices: Set<Int> = []
        let validBookmarks = decodedBookmarks.filter { bookmark in
            guard (0..<pageCount).contains(bookmark.pageIndex),
                  !bookmark.id.isEmpty,
                  !bookmarkedPageIndices.contains(bookmark.pageIndex) else {
                return false
            }

            bookmarkedPageIndices.insert(bookmark.pageIndex)
            return true
        }.sorted { $0.pageIndex < $1.pageIndex }

        if validBookmarks != decodedBookmarks {
            if validBookmarks.isEmpty {
                preferences.removeObject(forKey: defaultsKey)
            } else if let normalizedBookmarks = try? JSONEncoder().encode(validBookmarks) {
                preferences.set(normalizedBookmarks, forKey: defaultsKey)
            }
        }

        return validBookmarks
    }

    private func persistPageBookmarks() {
        guard let identifier = activeReadingDocumentIdentifier else {
            return
        }

        let defaultsKey = Self.pageBookmarksDefaultsPrefix + identifier
        guard !pageBookmarks.isEmpty else {
            preferences.removeObject(forKey: defaultsKey)
            return
        }

        guard let encodedBookmarks = try? JSONEncoder().encode(pageBookmarks) else {
            return
        }

        preferences.set(encodedBookmarks, forKey: defaultsKey)
    }

    private func discardInvalidPageBookmarks() {
        guard let document else {
            return
        }

        let validBookmarks = pageBookmarks.filter { (0..<document.pageCount).contains($0.pageIndex) }
        guard validBookmarks != pageBookmarks else {
            return
        }

        pageBookmarks = validBookmarks
        persistPageBookmarks()
    }

    private func readDocumentOutline(from document: PDFDocument) -> [PDFOutlineItem] {
        guard let outlineRoot = document.outlineRoot else {
            return []
        }

        var visitedOutlines: Set<ObjectIdentifier> = [ObjectIdentifier(outlineRoot)]
        var remainingItemBudget = 2_000

        func readChildren(of outline: PDFOutline, path: String, depth: Int) -> [PDFOutlineItem] {
            guard depth < 32, remainingItemBudget > 0 else {
                return []
            }

            var items: [PDFOutlineItem] = []

            for childIndex in 0..<outline.numberOfChildren {
                guard remainingItemBudget > 0 else {
                    break
                }

                guard let child = outline.child(at: childIndex),
                      visitedOutlines.insert(ObjectIdentifier(child)).inserted else {
                    continue
                }

                remainingItemBudget -= 1
                let childPath = "\(path).\(childIndex)"
                let destination = child.destination ?? (child.action as? PDFActionGoTo)?.destination
                let destinationPage = destination?.page
                let targetPageIndex = destinationPage.flatMap { pageIndex(of: $0, in: document) }
                let trimmedLabel = child.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                items.append(
                    PDFOutlineItem(
                        id: childPath,
                        title: trimmedLabel.isEmpty ? "Ohne Titel" : trimmedLabel,
                        pageIndex: targetPageIndex,
                        children: readChildren(of: child, path: childPath, depth: depth + 1)
                    )
                )
            }

            return items
        }

        return readChildren(of: outlineRoot, path: "outline", depth: 0)
    }

    private func refreshFormFields() {
        guard let document else {
            formAnnotations = [:]
            formFields = []
            return
        }

        var updatedAnnotations: [String: PDFAnnotation] = [:]
        var updatedFields: [PDFFormField] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else {
                continue
            }

            for (annotationIndex, annotation) in page.annotations.enumerated() {
                guard annotation.hasSubtype(.widget) else {
                    continue
                }

                let kind: PDFFormField.Kind
                switch annotation.widgetFieldType {
                case .text:
                    guard !annotation.isPasswordField else {
                        continue
                    }
                    kind = .text
                case .button:
                    guard annotation.widgetControlType == .checkBoxControl else {
                        continue
                    }
                    kind = .checkbox
                default:
                    continue
                }

                let declaredName = annotation.fieldName?.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = declaredName?.isEmpty == false
                    ? declaredName!
                    : "Feld \(updatedFields.count + 1)"
                let identifier = "\(pageIndex):\(annotationIndex):\(name)"
                let field = PDFFormField(
                    id: identifier,
                    name: name,
                    title: name,
                    pageIndex: pageIndex,
                    kind: kind,
                    textValue: kind == .text ? annotation.widgetStringValue ?? "" : "",
                    isChecked: kind == .checkbox && annotation.buttonWidgetState == .onState,
                    isReadOnly: annotation.isReadOnly,
                    maximumLength: kind == .text ? max(annotation.maximumLength, 0) : 0
                )
                updatedAnnotations[identifier] = annotation
                updatedFields.append(field)
            }
        }

        formAnnotations = updatedAnnotations
        formFields = updatedFields
    }

    private var linkTargetDescription: String {
        switch linkTargetMode {
        case .website:
            return linkURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        case .page:
            return "Seite \(linkDestinationPage)"
        }
    }

    private func linkAnnotationLocations() -> [(page: PDFPage, bounds: CGRect)] {
        if let selection = pdfView?.currentSelection {
            let locations = selection.selectionsByLine().flatMap { lineSelection in
                lineSelection.pages.compactMap { page -> (page: PDFPage, bounds: CGRect)? in
                    guard page.document === document else { return nil }
                    let bounds = lineSelection.bounds(for: page).insetBy(dx: -1.5, dy: -1.5)
                    return bounds.isEmpty ? nil : (page, bounds)
                }
            }

            if !locations.isEmpty {
                return locations
            }
        }

        guard let page = currentPage else {
            return []
        }

        return [(page, defaultAnnotationBounds(on: page, width: 240, height: 32))]
    }

    private func applyLinkTarget(to annotation: PDFAnnotation, reportErrors: Bool = true) -> Bool {
        switch linkTargetMode {
        case .website:
            guard let url = normalizedLinkURL(from: linkURLString) else {
                if reportErrors {
                    statusMessage = "Bitte eine gültige Webadresse eingeben."
                }
                return false
            }

            annotation.destination = nil
            annotation.url = url

        case .page:
            guard let document,
                  linkDestinationPage >= 1,
                  linkDestinationPage <= document.pageCount,
                  let targetPage = document.page(at: linkDestinationPage - 1) else {
                if reportErrors {
                    statusMessage = "Bitte eine gültige Zielseite wählen."
                }
                return false
            }

            let pageBounds = targetPage.bounds(for: .cropBox)
            annotation.url = nil
            annotation.destination = PDFDestination(
                page: targetPage,
                at: CGPoint(x: pageBounds.minX, y: pageBounds.maxY)
            )
        }

        return true
    }

    private func loadLinkTarget(from annotation: PDFAnnotation) {
        guard annotation.hasSubtype(.link) else {
            return
        }

        if let url = annotation.url {
            linkTargetMode = .website
            linkURLString = url.absoluteString
            return
        }

        linkTargetMode = .page
        if let targetPage = annotation.destination?.page,
           let document,
           let targetIndex = pageIndex(of: targetPage, in: document) {
            linkDestinationPage = targetIndex + 1
        } else {
            linkDestinationPage = min(max(currentPageIndex + 1, 1), max(pageCount, 1))
        }
    }

    private func loadStyle(from annotation: PDFAnnotation) {
        if let selectedFont = annotation.font {
            fontSize = Double(selectedFont.pointSize)
        }

        let selectedColor: NSColor?
        if annotation.hasSubtype(.freeText) {
            selectedColor = annotation.fontColor
        } else {
            selectedColor = annotation.color
        }

        guard let selectedColor,
              let rgbColor = selectedColor.usingColorSpace(.deviceRGB),
              let closestSwatch = AnnotationSwatch.allCases.min(by: { first, second in
                  colorDistance(from: first.nsColor, to: rgbColor)
                      < colorDistance(from: second.nsColor, to: rgbColor)
              }) else {
            return
        }

        annotationColor = closestSwatch
    }

    private func colorDistance(from first: NSColor, to second: NSColor) -> CGFloat {
        guard let firstRGB = first.usingColorSpace(.deviceRGB),
              let secondRGB = second.usingColorSpace(.deviceRGB) else {
            return .greatestFiniteMagnitude
        }

        let red = firstRGB.redComponent - secondRGB.redComponent
        let green = firstRGB.greenComponent - secondRGB.greenComponent
        let blue = firstRGB.blueComponent - secondRGB.blueComponent
        return red * red + green * green + blue * blue
    }

    private func normalizedLinkURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let candidate: String
        if trimmed.contains("://") || trimmed.lowercased().hasPrefix("mailto:") {
            candidate = trimmed
        } else {
            candidate = "https://\(trimmed)"
        }

        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              ["http", "https", "mailto"].contains(scheme) else {
            return nil
        }

        if scheme == "mailto" {
            guard !components.path.isEmpty else {
                return nil
            }
        } else {
            guard let host = components.host, !host.isEmpty else {
                return nil
            }
        }

        return components.url
    }

    private func applyCurrentStyle(to annotation: PDFAnnotation) {
        if annotation.hasSubtype(.freeText) {
            annotation.font = .systemFont(ofSize: fontSize)
            annotation.fontColor = annotationColor.nsColor
        } else if annotation.hasSubtype(.highlight) {
            annotation.color = annotationColor.nsColor.withAlphaComponent(0.45)
        } else if annotation.hasSubtype(.underline) || annotation.hasSubtype(.strikeOut) {
            annotation.color = annotationColor.nsColor.withAlphaComponent(0.85)
        } else if annotation.hasSubtype(.link) {
            annotation.color = NSColor.systemBlue
            annotation.border = border(lineWidth: 1)
        } else {
            annotation.color = annotationColor.nsColor
        }
    }

    private func canRegenerateAppearance(for annotation: PDFAnnotation) -> Bool {
        annotation.hasSubtype(.freeText)
            || annotation.hasSubtype(.text)
            || annotation.hasSubtype(.highlight)
            || annotation.hasSubtype(.underline)
            || annotation.hasSubtype(.strikeOut)
            || annotation.hasSubtype(.link)
            || annotation.hasSubtype(.ink)
            || annotation.hasSubtype(.line)
            || annotation.hasSubtype(.square)
            || annotation.hasSubtype(.circle)
    }

    private func refreshSelectedAnnotationLocation() {
        guard let annotation = selectedAnnotation else {
            selectedAnnotationPageIndex = nil
            return
        }

        guard let page = annotation.page,
              let document else {
            selectedAnnotation = nil
            selectedAnnotationPageIndex = nil
            selectedAnnotationText = ""
            return
        }

        guard let pageIndex = pageIndex(of: page, in: document) else {
            selectedAnnotation = nil
            selectedAnnotationPageIndex = nil
            selectedAnnotationText = ""
            return
        }

        selectedAnnotationPageIndex = pageIndex
        if annotation.hasSubtype(.link) {
            loadLinkTarget(from: annotation)
        }
    }

    private func remapInternalLinks(
        in copiedPages: [(source: PDFPage, copy: PDFPage)],
        sourceDocument: PDFDocument,
        sourceRange: ClosedRange<Int>
    ) {
        for pair in copiedPages {
            let sourceAnnotations = pair.source.annotations
            let copiedAnnotations = pair.copy.annotations

            for annotationIndex in copiedAnnotations.indices.reversed() {
                guard annotationIndex < sourceAnnotations.count else {
                    continue
                }

                let sourceAnnotation = sourceAnnotations[annotationIndex]
                let copiedAnnotation = copiedAnnotations[annotationIndex]
                guard sourceAnnotation.hasSubtype(.link),
                      sourceAnnotation.url == nil,
                      let sourceDestination = sourceAnnotation.destination,
                      let sourceTargetPage = sourceDestination.page else {
                    continue
                }

                guard let sourceTargetIndex = pageIndex(of: sourceTargetPage, in: sourceDocument),
                      sourceRange.contains(sourceTargetIndex) else {
                    pair.copy.removeAnnotation(copiedAnnotation)
                    continue
                }

                let copiedTargetIndex = sourceTargetIndex - sourceRange.lowerBound
                guard copiedPages.indices.contains(copiedTargetIndex) else {
                    pair.copy.removeAnnotation(copiedAnnotation)
                    continue
                }

                copiedAnnotation.url = nil
                copiedAnnotation.destination = PDFDestination(
                    page: copiedPages[copiedTargetIndex].copy,
                    at: sourceDestination.point
                )
            }
        }
    }

    private func removeInternalLinks(targeting targetPage: PDFPage, in document: PDFDocument) {
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else {
                continue
            }

            let linksToRemove = page.annotations.filter { annotation in
                annotation.hasSubtype(.link)
                    && annotation.url == nil
                    && annotation.destination?.page === targetPage
            }
            for annotation in linksToRemove {
                page.removeAnnotation(annotation)
            }
        }
    }

    private func clampedAnnotationOrigin(for bounds: CGRect, on page: PDFPage) -> CGPoint {
        let pageBounds = page.bounds(for: .cropBox)
        let x: CGFloat
        let y: CGFloat

        if bounds.width >= pageBounds.width {
            x = pageBounds.minX
        } else {
            x = min(max(bounds.minX, pageBounds.minX), pageBounds.maxX - bounds.width)
        }

        if bounds.height >= pageBounds.height {
            y = pageBounds.minY
        } else {
            y = min(max(bounds.minY, pageBounds.minY), pageBounds.maxY - bounds.height)
        }

        return CGPoint(x: x, y: y)
    }

    private func pageIndex(of page: PDFPage, in document: PDFDocument) -> Int? {
        let index = document.index(for: page)
        return (0..<document.pageCount).contains(index) ? index : nil
    }

    private func exportName(suffix: String) -> String {
        let baseName = fileURL?.deletingPathExtension().lastPathComponent ?? "Dokument"
        return "\(baseName)-\(suffix).pdf"
    }

    private func confirmOverwriteIfNeeded(_ urls: [URL]) -> Bool {
        let existingNames = urls
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map(\.lastPathComponent)
        guard !existingNames.isEmpty else {
            return true
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Vorhandene Dateien ersetzen?"
        alert.informativeText = existingNames.joined(separator: "\n")
        alert.addButton(withTitle: "Ersetzen")
        alert.addButton(withTitle: "Abbrechen")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func writePages(
        in range: ClosedRange<Int>,
        to url: URL,
        preparedDocument: PDFDocument
    ) -> Bool {
        guard requirePermission(.exportPages) else { return false }
        guard preparedDocument.write(to: url) else {
            statusMessage = "Die ausgewählten Seiten konnten nicht gesichert werden."
            return false
        }

        let unit = range.count == 1 ? "Seite" : "Seiten"
        statusMessage = "\(range.count) \(unit) nach \(url.lastPathComponent) extrahiert"
        return true
    }

    private func writeSplitDocument(
        afterPageAt splitIndex: Int,
        firstPartURL: URL,
        secondPartURL: URL,
        preparedParts: (first: PDFDocument, second: PDFDocument)
    ) -> Bool {
        guard requirePermission(.exportPages) else { return false }
        guard firstPartURL.standardizedFileURL != secondPartURL.standardizedFileURL else {
            statusMessage = "Für beide Teile werden unterschiedliche Dateinamen benötigt."
            return false
        }

        let fileManager = FileManager.default
        guard !isDirectory(at: firstPartURL, using: fileManager),
              !isDirectory(at: secondPartURL, using: fileManager) else {
            statusMessage = "Das Dokument konnte nicht vollständig geteilt werden."
            return false
        }

        let firstStagingURL = stagingURL(for: firstPartURL)
        let secondStagingURL = stagingURL(for: secondPartURL)
        defer {
            removeFileIfPresent(at: firstStagingURL, using: fileManager)
            removeFileIfPresent(at: secondStagingURL, using: fileManager)
        }

        guard preparedParts.first.write(to: firstStagingURL),
              preparedParts.second.write(to: secondStagingURL) else {
            statusMessage = "Das Dokument konnte nicht vollständig geteilt werden."
            return false
        }

        var installedOutputs: [InstalledOutput] = []
        do {
            installedOutputs.append(
                try installStagedOutput(
                    at: firstStagingURL,
                    destinationURL: firstPartURL,
                    using: fileManager
                )
            )
            installedOutputs.append(
                try installStagedOutput(
                    at: secondStagingURL,
                    destinationURL: secondPartURL,
                    using: fileManager
                )
            )
        } catch {
            for output in installedOutputs.reversed() {
                rollbackInstalledOutput(output, using: fileManager)
            }
            statusMessage = "Das Dokument konnte nicht vollständig geteilt werden."
            return false
        }

        for output in installedOutputs {
            if let backupURL = output.backupURL {
                removeFileIfPresent(at: backupURL, using: fileManager)
            }
        }

        statusMessage = "Dokument nach Seite \(splitIndex + 1) in zwei PDFs geteilt"
        return true
    }

    private struct InstalledOutput {
        let destinationURL: URL
        let backupURL: URL?
    }

    private func stagingURL(for destinationURL: URL) -> URL {
        destinationURL.deletingLastPathComponent().appendingPathComponent(
            ".\(destinationURL.lastPathComponent).klarfolio-\(UUID().uuidString).tmp.pdf"
        )
    }

    private func backupURL(for destinationURL: URL) -> URL {
        destinationURL.deletingLastPathComponent().appendingPathComponent(
            ".\(destinationURL.lastPathComponent).klarfolio-\(UUID().uuidString).backup"
        )
    }

    private func installStagedOutput(
        at stagingURL: URL,
        destinationURL: URL,
        using fileManager: FileManager
    ) throws -> InstalledOutput {
        let destinationExists = fileManager.fileExists(atPath: destinationURL.path)
        let existingBackupURL = destinationExists ? backupURL(for: destinationURL) : nil

        if let existingBackupURL {
            try fileManager.moveItem(at: destinationURL, to: existingBackupURL)
        }

        do {
            try fileManager.moveItem(at: stagingURL, to: destinationURL)
        } catch {
            if let existingBackupURL {
                try? fileManager.moveItem(at: existingBackupURL, to: destinationURL)
            }
            throw error
        }

        return InstalledOutput(
            destinationURL: destinationURL,
            backupURL: existingBackupURL
        )
    }

    private func rollbackInstalledOutput(
        _ output: InstalledOutput,
        using fileManager: FileManager
    ) {
        removeFileIfPresent(at: output.destinationURL, using: fileManager)
        if let backupURL = output.backupURL,
           fileManager.fileExists(atPath: backupURL.path) {
            try? fileManager.moveItem(at: backupURL, to: output.destinationURL)
        }
    }

    private func removeFileIfPresent(at url: URL, using fileManager: FileManager) {
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try? fileManager.removeItem(at: url)
    }

    private func isDirectory(at url: URL, using fileManager: FileManager) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            && isDirectory.boolValue
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
