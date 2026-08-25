import AppKit
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("PDFDocumentStore")
struct PDFDocumentStoreTests {
    @Test("Leere Dokumente verwenden die erwartete Seitengröße")
    func blankDocumentUsesDefaultPageSize() throws {
        let document = PDFUtilities.blankDocument()

        #expect(document.pageCount == 1)
        let page = try #require(document.page(at: 0))
        let bounds = page.bounds(for: .mediaBox)
        #expect(abs(bounds.width - PDFUtilities.defaultPageSize.width) < 0.5)
        #expect(abs(bounds.height - PDFUtilities.defaultPageSize.height) < 0.5)
        #expect(PDFUtilities.pageSizeLabel(for: page) == "216 x 279 mm")
        #expect(PDFUtilities.pageSizeLabel(for: nil) == "Keine Seite")
    }

    @Test("Die App startet ohne gespeicherte Einstellung im Lesemodus")
    @MainActor
    func freshWorkspaceDefaultsToReadingMode() throws {
        let suiteName = "KlarfolioWorkspaceModeTests-\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }

        let store = PDFDocumentStore(preferences: preferences)

        #expect(store.workspaceMode == .reading)
        #expect(preferences.string(forKey: PDFDocumentStore.workspaceModeDefaultsKey) == nil)
    }

    @Test("Der Arbeitsmodus wird umgeschaltet und nach einem Neustart wiederhergestellt")
    @MainActor
    func workspaceModePersistsAcrossStoreInstances() throws {
        let suiteName = "KlarfolioWorkspaceModeTests-\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }

        let firstStore = PDFDocumentStore(preferences: preferences)
        firstStore.toggleWorkspaceMode()

        #expect(firstStore.workspaceMode == .editing)
        #expect(
            preferences.string(forKey: PDFDocumentStore.workspaceModeDefaultsKey)
                == PDFWorkspaceMode.editing.rawValue
        )

        let restoredStore = PDFDocumentStore(preferences: preferences)
        #expect(restoredStore.workspaceMode == .editing)

        restoredStore.toggleWorkspaceMode()

        #expect(restoredStore.workspaceMode == .reading)
        #expect(PDFDocumentStore(preferences: preferences).workspaceMode == .reading)
    }

    @Test("Ungültige gespeicherte Arbeitsmodi fallen auf den Lesemodus zurück")
    @MainActor
    func invalidPersistedWorkspaceModeFallsBackToReading() throws {
        let suiteName = "KlarfolioWorkspaceModeTests-\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        preferences.set("unsupported-mode", forKey: PDFDocumentStore.workspaceModeDefaultsKey)

        let store = PDFDocumentStore(preferences: preferences)

        #expect(store.workspaceMode == .reading)
    }

    @Test("Der Lesemodus beendet die Anmerkungsauswahl ohne das Dokument zu verändern")
    @MainActor
    func enteringReadingModeClearsSelectionWithoutChangingDocument() throws {
        let suiteName = "KlarfolioWorkspaceModeTests-\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        store.setWorkspaceMode(.editing)
        store.createBlankDocument()
        store.addFreeTextAnnotation(text: "Bleibt unverändert")

        let document = try #require(store.document)
        let annotation = try #require(store.selectedAnnotation)
        let revision = store.revision
        let statusMessage = store.statusMessage
        let wasDirty = store.isDirty
        store.selectedTool = .text

        store.setWorkspaceMode(.reading)

        #expect(store.workspaceMode == .reading)
        #expect(store.document === document)
        #expect(store.currentPage?.annotations.contains { $0 === annotation } == true)
        #expect(!store.hasSelectedAnnotation)
        #expect(store.selectedTool == .select)
        #expect(store.revision == revision)
        #expect(store.statusMessage == statusMessage)
        #expect(store.isDirty == wasDirty)
    }

    @Test("Ein neues Dokument setzt den Dokumentzustand zurück")
    @MainActor
    func creatingBlankDocumentResetsDocumentState() {
        let store = PDFDocumentStore()
        store.searchText = "vorher"
        store.searchResultCount = 3
        let originalRevision = store.revision

        store.createBlankDocument()

        #expect(store.pageCount == 1)
        #expect(store.currentPageIndex == 0)
        #expect(store.fileURL == nil)
        #expect(store.isDirty)
        #expect(store.searchText == "")
        #expect(store.searchResultCount == 0)
        #expect(store.statusMessage == "Neues PDF erstellt")
        #expect(store.revision > originalRevision)
    }

    @Test("Seitenoperationen erhalten ein benutzbares Dokument")
    @MainActor
    func pageOperationsPreserveAUsableDocument() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        store.addBlankPage()

        #expect(store.pageCount == 3)
        #expect(store.currentPageIndex == 2)

        let movedPage = try #require(store.currentPage)
        store.moveCurrentPage(by: -2)

        #expect(store.currentPageIndex == 0)
        #expect(store.document?.page(at: 0) === movedPage)

        store.rotateCurrentPage(clockwise: true)
        #expect(movedPage.rotation == 90)
        store.rotateCurrentPage(clockwise: false)
        #expect(movedPage.rotation == 0)

        store.deleteCurrentPage()
        #expect(store.pageCount == 2)
        #expect(store.currentPageIndex == 0)
        #expect(store.isDirty)
    }

    @Test("Die letzte Seite kann nicht gelöscht werden")
    @MainActor
    func lastPageCannotBeDeleted() {
        let store = PDFDocumentStore()
        store.createBlankDocument()

        store.deleteCurrentPage()

        #expect(store.pageCount == 1)
        #expect(store.statusMessage == "Die letzte Seite kann nicht gelöscht werden.")
    }

    @Test("Anmerkungen können hinzugefügt und wieder entfernt werden")
    @MainActor
    func annotationLifecycle() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.fontSize = 19
        store.annotationColor = .blue

        store.addFreeTextAnnotation(text: "Prüftext")

        let page = try #require(store.currentPage)
        let freeText = try #require(store.selectedAnnotation)
        #expect(freeText.contents == "Prüftext")
        #expect(freeText.hasSubtype(.freeText))

        store.addNoteAnnotation()
        let note = try #require(store.selectedAnnotation)
        #expect(note.contents == "Notiz")
        #expect(note.hasSubtype(.text))
        #expect(page.annotations.filter { !$0.hasSubtype(.popup) }.count == 2)

        store.removeLastAnnotationOnCurrentPage()
        #expect(page.annotations.contains { $0 === freeText })
        #expect(!page.annotations.contains { $0 === note })
        #expect(!page.annotations.contains { $0.hasSubtype(.popup) })
        #expect(store.statusMessage == "Anmerkung entfernt")
    }

    @Test("Gültige PDFs werden geladen und ungültige abgewiesen")
    @MainActor
    func loadingValidAndInvalidPDFs() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlarfolioPDFEditorTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let validURL = temporaryDirectory.appendingPathComponent("Beispiel.pdf")
        #expect(PDFUtilities.blankDocument().write(to: validURL))

        let store = PDFDocumentStore()
        store.loadDocument(from: validURL)

        #expect(store.pageCount == 1)
        #expect(store.fileURL == validURL)
        #expect(!store.isDirty)
        #expect(store.documentTitle == "Beispiel.pdf")
        #expect(store.statusMessage == "Beispiel.pdf geöffnet")

        let invalidURL = temporaryDirectory.appendingPathComponent("Defekt.pdf")
        try Data("kein PDF".utf8).write(to: invalidURL)
        let originalDocument = store.document
        store.loadDocument(from: invalidURL)

        #expect(store.document === originalDocument)
        #expect(store.statusMessage == "Die Datei konnte nicht geöffnet werden.")
    }

    @Test("Ungültige Seitennavigation verändert die Auswahl nicht")
    @MainActor
    func invalidPageNavigationKeepsCurrentPage() {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        #expect(store.currentPageIndex == 1)

        store.goToPage(-1)
        store.goToPage(2)

        #expect(store.currentPageIndex == 1)
    }

    @Test("Seitenbereiche werden kopiert und extrahiert, ohne das Original zu verändern")
    @MainActor
    func copyingAndExtractingPagesPreservesOriginalDocument() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        store.addBlankPage()
        store.isDirty = false

        let copiedDocument = try #require(store.documentByCopyingPages(in: 1...2))
        #expect(copiedDocument.pageCount == 2)
        #expect(store.pageCount == 3)

        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let extractedURL = temporaryDirectory.appendingPathComponent("Extrahiert.pdf")

        #expect(store.writePages(in: 1...2, to: extractedURL))
        #expect(PDFDocument(url: extractedURL)?.pageCount == 2)
        #expect(store.pageCount == 3)
        #expect(!store.isDirty)
        #expect(store.statusMessage == "2 Seiten nach Extrahiert.pdf extrahiert")

        #expect(store.documentByCopyingPages(in: 0...3) == nil)
        #expect(!store.writePages(in: 0...3, to: extractedURL))
        #expect(store.statusMessage == "Bitte einen gültigen Seitenbereich wählen.")
    }

    @Test("Dokumentteilung schreibt zwei gültige PDFs und weist ungültige Teilungen ab")
    @MainActor
    func splittingDocumentWritesExpectedParts() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        store.addBlankPage()
        store.isDirty = false

        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let firstURL = temporaryDirectory.appendingPathComponent("Teil-1.pdf")
        let secondURL = temporaryDirectory.appendingPathComponent("Teil-2.pdf")

        #expect(
            store.writeSplitDocument(
                afterPageAt: 0,
                firstPartURL: firstURL,
                secondPartURL: secondURL
            )
        )
        #expect(PDFDocument(url: firstURL)?.pageCount == 1)
        #expect(PDFDocument(url: secondURL)?.pageCount == 2)
        #expect(store.pageCount == 3)
        #expect(!store.isDirty)
        #expect(store.statusMessage == "Dokument nach Seite 1 in zwei PDFs geteilt")

        #expect(
            !store.writeSplitDocument(
                afterPageAt: 2,
                firstPartURL: firstURL,
                secondPartURL: secondURL
            )
        )
        #expect(store.statusMessage == "Bitte eine Teilung vor der letzten Seite wählen.")

        #expect(
            !store.writeSplitDocument(
                afterPageAt: 0,
                firstPartURL: firstURL,
                secondPartURL: firstURL
            )
        )
        #expect(store.statusMessage == "Für beide Teile werden unterschiedliche Dateinamen benötigt.")

        let originalFirstPartData = try Data(contentsOf: firstURL)
        let unavailableSecondURL = temporaryDirectory
            .appendingPathComponent("Fehlender-Ordner", isDirectory: true)
            .appendingPathComponent("Teil-2.pdf")
        #expect(
            !store.writeSplitDocument(
                afterPageAt: 0,
                firstPartURL: firstURL,
                secondPartURL: unavailableSecondURL
            )
        )
        let unchangedFirstPartData = try Data(contentsOf: firstURL)
        #expect(unchangedFirstPartData == originalFirstPartData)
        #expect(store.statusMessage == "Das Dokument konnte nicht vollständig geteilt werden.")
    }

    @Test("Ausgewählte Anmerkungen können bearbeitet, begrenzt verschoben und gelöscht werden")
    @MainActor
    func selectedAnnotationLifecycle() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addFreeTextAnnotation(text: "Vorher")

        let annotation = try #require(store.selectedAnnotation)
        let page = try #require(store.currentPage)
        #expect(annotation === page.annotations.first)
        #expect(store.selectedAnnotationPageIndex == 0)
        #expect(store.selectedAnnotationText == "Vorher")
        #expect(store.hasSelectedAnnotation)
        #expect(annotation.hasSubtype(.freeText))

        let revisionBeforeEdit = store.revision
        store.selectedAnnotationText = "Nachher"
        store.fontSize = 20
        store.annotationColor = .red
        store.applySelectedAnnotationEdits()

        #expect(annotation.contents == "Nachher")
        #expect(annotation.font?.pointSize == 20)
        #expect(store.revision > revisionBeforeEdit)
        #expect(store.isDirty)

        let originalBounds = annotation.bounds
        store.moveSelectedAnnotationBy(x: 12, y: 8)
        #expect(annotation.bounds != originalBounds)

        store.moveSelectedAnnotationBy(x: -10_000, y: -10_000)
        #expect(page.bounds(for: .cropBox).contains(annotation.bounds))

        store.removeSelectedAnnotation()
        #expect(page.annotations.isEmpty)
        #expect(!store.hasSelectedAnnotation)
        #expect(store.selectedAnnotationPageIndex == nil)
        #expect(store.selectedAnnotationText.isEmpty)
    }

    @Test("Web- und Dokumentlinks werden validiert und korrekt angelegt")
    @MainActor
    func linkAnnotationsUseValidatedTargets() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        store.goToPage(0)

        store.linkTargetMode = .website
        store.linkURLString = "example.com"
        store.addLinkAnnotation()

        let webLink = try #require(store.selectedAnnotation)
        #expect(webLink.hasSubtype(.link))
        #expect(webLink.url?.absoluteString == "https://example.com")
        #expect(webLink.destination == nil)

        store.linkTargetMode = .page
        store.linkDestinationPage = 2
        store.addLinkAnnotation()

        let pageLink = try #require(store.selectedAnnotation)
        #expect(pageLink.hasSubtype(.link))
        #expect(pageLink.url == nil)
        #expect(pageLink.destination?.page === store.document?.page(at: 1))

        let copiedDocument = try #require(store.documentByCopyingPages(in: 0...1))
        let copiedPageLink = try #require(
            copiedDocument.page(at: 0)?.annotations.first(where: { $0.destination != nil })
        )
        #expect(copiedPageLink.destination?.page === copiedDocument.page(at: 1))

        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let copiedURL = temporaryDirectory.appendingPathComponent("Links-kopiert.pdf")
        #expect(copiedDocument.write(to: copiedURL))
        let reloadedCopy = try #require(PDFDocument(url: copiedURL))
        let reloadedPageLink = try #require(
            reloadedCopy.page(at: 0)?.annotations.first(where: { $0.destination != nil })
        )
        #expect(reloadedPageLink.destination?.page === reloadedCopy.page(at: 1))

        let singlePageCopy = try #require(store.documentByCopyingPages(in: 0...0))
        #expect(singlePageCopy.page(at: 0)?.annotations.count == 1)
        #expect(singlePageCopy.page(at: 0)?.annotations.first?.url?.absoluteString == "https://example.com")

        let annotationCount = try #require(store.currentPage).annotations.count
        store.linkTargetMode = .website
        store.linkURLString = "https://"
        store.addLinkAnnotation()

        #expect(store.currentPage?.annotations.count == annotationCount)
        #expect(store.statusMessage == "Bitte eine gültige Webadresse eingeben.")
    }

    @Test("Geteilte PDFs erhalten nur gültige, auf ihren Teil umgebogene Links")
    @MainActor
    func splitDocumentsPersistValidLinkTargets() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        store.addBlankPage()
        let source = try #require(store.document)
        let page0 = try #require(source.page(at: 0))
        let page1 = try #require(source.page(at: 1))
        let page2 = try #require(source.page(at: 2))

        func addInternalLink(from sourcePage: PDFPage, to targetPage: PDFPage) {
            let annotation = PDFAnnotation(
                bounds: CGRect(x: 20, y: 20, width: 100, height: 24),
                forType: .link,
                withProperties: nil
            )
            annotation.destination = PDFDestination(page: targetPage, at: .zero)
            sourcePage.addAnnotation(annotation)
        }

        addInternalLink(from: page0, to: page2)
        addInternalLink(from: page1, to: page2)
        let webLink = PDFAnnotation(
            bounds: CGRect(x: 20, y: 50, width: 100, height: 24),
            forType: .link,
            withProperties: nil
        )
        webLink.url = URL(string: "https://example.com")
        page0.addAnnotation(webLink)

        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let firstURL = temporaryDirectory.appendingPathComponent("Teil-1.pdf")
        let secondURL = temporaryDirectory.appendingPathComponent("Teil-2.pdf")
        #expect(
            store.writeSplitDocument(
                afterPageAt: 0,
                firstPartURL: firstURL,
                secondPartURL: secondURL
            )
        )

        let firstPart = try #require(PDFDocument(url: firstURL))
        let secondPart = try #require(PDFDocument(url: secondURL))
        let firstAnnotations = try #require(firstPart.page(at: 0)).annotations
        #expect(firstAnnotations.allSatisfy { $0.destination == nil })
        #expect(firstAnnotations.contains { $0.url?.absoluteString == "https://example.com" })

        let secondPartLink = try #require(
            secondPart.page(at: 0)?.annotations.first(where: { $0.destination != nil })
        )
        #expect(secondPartLink.destination?.page === secondPart.page(at: 1))
    }

    @Test("Annotation-Auswahl bleibt nach Seitenänderungen auf die richtige Seite bezogen")
    @MainActor
    func annotationSelectionTracksStructuralPageChanges() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        store.addBlankPage()
        store.addFreeTextAnnotation(text: "Seite 3")
        let annotation = try #require(store.selectedAnnotation)
        #expect(store.selectedAnnotationPageIndex == 2)

        store.goToPage(0)
        store.deleteCurrentPage()

        #expect(store.selectedAnnotation === annotation)
        #expect(store.selectedAnnotationPageIndex == 1)

        store.goToPage(0)
        store.moveCurrentPage(by: 1)

        #expect(store.selectedAnnotation === annotation)
        #expect(store.selectedAnnotationPageIndex == 0)
    }

    @Test("Anmerkungsauswahl synchronisiert die aktuelle PDFView-Seite")
    @MainActor
    func selectingAnnotationSynchronizesPDFViewPage() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        let firstPage = try #require(store.document?.page(at: 0))
        let secondPage = try #require(store.document?.page(at: 1))
        let annotation = PDFAnnotation(
            bounds: CGRect(x: 20, y: 20, width: 80, height: 30),
            forType: .freeText,
            withProperties: nil
        )
        secondPage.addAnnotation(annotation)

        let pdfView = PDFView()
        store.attach(pdfView: pdfView)
        pdfView.go(to: firstPage)
        store.syncFromPDFView(pdfView)
        #expect(store.currentPageIndex == 0)

        store.selectAnnotation(annotation, on: secondPage)

        #expect(store.currentPageIndex == 1)
        #expect(pdfView.currentPage === secondPage)
        #expect(store.currentPage === secondPage)
    }

    @Test("Ausgewählte Seitenlinks folgen verschobenen Zielseiten")
    @MainActor
    func selectedInternalLinkTracksPageMoves() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        store.goToPage(0)
        store.linkTargetMode = .page
        store.linkDestinationPage = 2
        store.addLinkAnnotation()

        let link = try #require(store.selectedAnnotation)
        let targetPage = try #require(link.destination?.page)
        #expect(store.selectedAnnotationPageIndex == 0)
        #expect(store.linkDestinationPage == 2)

        store.moveCurrentPage(by: 1)

        #expect(store.selectedAnnotation === link)
        #expect(store.selectedAnnotationPageIndex == 1)
        #expect(store.document?.page(at: 0) === targetPage)
        #expect(store.linkDestinationPage == 1)

        store.applySelectedAnnotationEdits()
        #expect(link.destination?.page === targetPage)
    }

    @Test("Beim Löschen einer Zielseite werden darauf gerichtete interne Links entfernt")
    @MainActor
    func deletingTargetPageRemovesInternalLinks() throws {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.addBlankPage()
        store.goToPage(0)
        store.linkTargetMode = .page
        store.linkDestinationPage = 2
        store.addLinkAnnotation()
        #expect(store.hasSelectedAnnotation)

        store.goToPage(1)
        store.deleteCurrentPage()

        #expect(store.pageCount == 1)
        #expect(store.document?.page(at: 0)?.annotations.allSatisfy { !$0.hasSubtype(.link) } == true)
        #expect(!store.hasSelectedAnnotation)

        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let outputURL = temporaryDirectory.appendingPathComponent("Ohne-verwaisten-Link.pdf")
        #expect(store.document?.write(to: outputURL) == true)
        #expect(PDFDocument(url: outputURL)?.page(at: 0)?.annotations.allSatisfy { !$0.hasSubtype(.link) } == true)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlarfolioPDFEditorTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
