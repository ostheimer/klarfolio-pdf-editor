import CryptoKit
import Foundation
import KlarfolioPDFTestFixtures
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("Sichere PDF-Lesenavigation")
struct PDFReadingNavigationTests {
    @Test("Vorhandene PDF-Gliederungen bleiben verschachtelt und zeigen auf echte Dokumentseiten")
    @MainActor
    func existingOutlineRetainsHierarchyAndRealPageDestinations() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)

        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))

        #expect(store.documentOutline.map(\.title) == ["Einleitung", "Kapitel 1", "Kapitel 2"])
        #expect(store.documentOutline.map(\.pageIndex) == [0, 1, 3])
        let nestedItem = try #require(store.documentOutline[1].children.first)
        #expect(nestedItem.title == "Abschnitt 1.1")
        #expect(nestedItem.pageIndex == 2)
        #expect(nestedItem.id != store.documentOutline[1].id)
        #expect(!store.isDirty)
        #expect(store.workspaceMode == .reading)
    }

    @Test("PDFs ohne Inhaltsverzeichnis erzeugen keine künstlichen Gliederungseinträge")
    @MainActor
    func documentWithoutOutlineHasNoSyntheticEntries() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)

        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))
        #expect(store.documentOutline.isEmpty)
    }

    @Test("Container und lokale Sprungaktionen werden sicher von externen Outline-Aktionen getrennt")
    @MainActor
    func outlineContainersAndExternalActionsRemainSafe() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let documentURL = try makeOutlineActionDocument(in: temporaryDirectory)
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)

        #expect(store.loadDocument(from: documentURL))

        let container = try #require(store.documentOutline.first)
        #expect(container.title == "Abschnitte")
        #expect(container.pageIndex == nil)
        #expect(container.children.first?.title == "Lokaler Abschnitt")
        #expect(container.children.first?.pageIndex == 2)
        let externalItem = try #require(store.documentOutline.last)
        #expect(externalItem.title == "Externer Verweis")
        #expect(externalItem.pageIndex == nil)

        store.goToOutline(externalItem)
        #expect(store.currentPageIndex == 0)

        store.goToOutline(try #require(container.children.first))
        #expect(store.currentPageIndex == 2)
        #expect(!store.isDirty)
    }

    @Test("Gliederungsnavigation verändert weder PDF noch Bearbeitungsstatus")
    @MainActor
    func outlineNavigationNeverChangesTheDocument() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        let originalDocument = try #require(store.document)
        let originalRevision = store.revision
        let originalStatus = store.statusMessage

        let nestedItem = try #require(store.documentOutline[1].children.first)
        store.goToOutline(nestedItem)

        #expect(store.currentPageIndex == 2)
        #expect(store.document === originalDocument)
        #expect(store.revision == originalRevision)
        #expect(store.statusMessage == originalStatus)
        #expect(store.workspaceMode == .reading)
        #expect(!store.isDirty)

        store.goToOutline(PDFOutlineItem(id: "container", title: "Container", pageIndex: nil, children: []))
        store.goToOutline(PDFOutlineItem(id: "invalid", title: "Ungültig", pageIndex: 99, children: []))
        #expect(store.currentPageIndex == 2)
    }

    @Test("Lokale Seitenlesezeichen verändern weder PDF-Datei noch Dokumentzustand")
    @MainActor
    func pageBookmarksAreLocalAndNeverModifyThePDF() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let documentURL = PDFTestFixture.outlinedFourPages.url
        let originalData = try Data(contentsOf: documentURL)
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: documentURL))
        store.goToPage(2)
        let originalDocument = try #require(store.document)
        let originalRevision = store.revision
        let originalStatus = store.statusMessage

        store.toggleBookmarkForCurrentPage()

        #expect(store.pageBookmarks == [PDFPageBookmark(id: "page-2", pageIndex: 2, title: "Seite 3")])
        #expect(store.isCurrentPageBookmarked)
        #expect(store.document === originalDocument)
        #expect(store.revision == originalRevision)
        #expect(store.statusMessage == originalStatus)
        #expect(store.workspaceMode == .reading)
        #expect(!store.isDirty)
        #expect(try Data(contentsOf: documentURL) == originalData)
    }

    @Test("Lesezeichen lassen Formularfelder und vorhandene Anmerkungen unverändert")
    @MainActor
    func bookmarksPreserveFormsAndAnnotations() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.interactiveForm.url))
        let originalFields = store.formFields
        let originalAnnotations = try #require(store.currentPage?.annotations)

        store.toggleBookmarkForCurrentPage()

        #expect(store.pageBookmarks.first?.title == "Seite 1")
        #expect(store.formFields == originalFields)
        #expect(store.currentPage?.annotations.count == originalAnnotations.count)
        #expect(store.formFields.first { $0.name == "KlarfolioName" }?.textValue == "Andreas Test")
        #expect(store.formFields.first { $0.name == "KlarfolioConsent" }?.isChecked == true)
        #expect(!store.isDirty)
    }

    @Test("Lesezeichen werden nach Seiten sortiert und durch erneutes Setzen wieder entfernt")
    @MainActor
    func bookmarksStaySortedAndToggleWithoutDuplicates() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))

        store.goToPage(3)
        store.toggleBookmarkForCurrentPage()
        store.goToPage(0)
        store.toggleBookmarkForCurrentPage()
        store.goToPage(2)
        store.toggleBookmarkForCurrentPage()

        #expect(store.pageBookmarks.map(\.pageIndex) == [0, 2, 3])
        #expect(store.pageBookmarks.map(\.title) == ["Seite 1", "Seite 3", "Seite 4"])
        #expect(store.isCurrentPageBookmarked)

        store.toggleBookmarkForCurrentPage()

        #expect(store.pageBookmarks.map(\.pageIndex) == [0, 3])
        #expect(!store.isCurrentPageBookmarked)
        #expect(!store.isDirty)
    }

    @Test("Lesezeichen springen nur zu existierenden IDs und lassen sich einzeln löschen")
    @MainActor
    func bookmarksNavigateAndRemoveByIdentifier() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        store.goToPage(2)
        store.toggleBookmarkForCurrentPage()
        store.goToPage(0)

        store.goToBookmark("missing")
        #expect(store.currentPageIndex == 0)

        store.goToBookmark("page-2")
        #expect(store.currentPageIndex == 2)

        store.removeBookmark("missing")
        #expect(store.pageBookmarks.count == 1)

        store.removeBookmark("page-2")
        #expect(store.pageBookmarks.isEmpty)
        #expect(!store.isCurrentPageBookmarked)
        #expect(!store.isDirty)
    }

    @Test("Leseposition und Seitenlesezeichen überstehen einen vollständigen Neustart")
    @MainActor
    func readingPositionAndBookmarksSurviveStoreRestart() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let firstStore = PDFDocumentStore(preferences: preferences)
        #expect(firstStore.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        firstStore.goToPage(2)
        firstStore.toggleBookmarkForCurrentPage()
        firstStore.goToPage(3)
        firstStore.setWorkspaceMode(.editing)

        let restartedStore = PDFDocumentStore(preferences: preferences)
        #expect(restartedStore.workspaceMode == .reading)
        #expect(restartedStore.loadDocument(from: PDFTestFixture.outlinedFourPages.url))

        #expect(restartedStore.currentPageIndex == 3)
        #expect(restartedStore.pageBookmarks == [PDFPageBookmark(id: "page-2", pageIndex: 2, title: "Seite 3")])
        #expect(restartedStore.workspaceMode == .reading)
        #expect(!restartedStore.isDirty)
    }

    @Test("Dokumente mit gleichem Inhalt behalten getrennte Lesepositionen und Lesezeichen")
    @MainActor
    func readingStateIsStrictlySeparatedByDocumentPath() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let firstURL = try copyFixture(
            PDFTestFixture.outlinedFourPages.url,
            into: temporaryDirectory,
            named: "Erstes.pdf"
        )
        let secondURL = try copyFixture(
            PDFTestFixture.outlinedFourPages.url,
            into: temporaryDirectory,
            named: "Zweites.pdf"
        )
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)

        #expect(store.loadDocument(from: firstURL))
        store.goToPage(2)
        store.toggleBookmarkForCurrentPage()

        #expect(store.loadDocument(from: secondURL))
        #expect(store.currentPageIndex == 0)
        #expect(store.pageBookmarks.isEmpty)
        store.goToPage(1)
        store.toggleBookmarkForCurrentPage()

        #expect(store.loadDocument(from: firstURL))
        #expect(store.currentPageIndex == 2)
        #expect(store.pageBookmarks.map(\.pageIndex) == [2])

        #expect(store.loadDocument(from: secondURL))
        #expect(store.currentPageIndex == 1)
        #expect(store.pageBookmarks.map(\.pageIndex) == [1])
    }

    @Test("Normalisierte Pfade und symbolische Verweise teilen dieselbe Dokumentidentität")
    @MainActor
    func normalizedPathsAndSymlinksShareDocumentIdentity() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let documentURL = try copyFixture(
            PDFTestFixture.outlinedFourPages.url,
            into: temporaryDirectory,
            named: "Original.pdf"
        )
        let symbolicLinkURL = temporaryDirectory.appendingPathComponent("Verweis.pdf")
        try FileManager.default.createSymbolicLink(at: symbolicLinkURL, withDestinationURL: documentURL)
        let dottedURL = URL(
            fileURLWithPath: temporaryDirectory.path + "/./" + documentURL.lastPathComponent
        )
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let firstStore = PDFDocumentStore(preferences: preferences)

        #expect(firstStore.loadDocument(from: dottedURL))
        firstStore.goToPage(2)
        firstStore.toggleBookmarkForCurrentPage()

        let reopenedStore = PDFDocumentStore(preferences: preferences)
        #expect(reopenedStore.loadDocument(from: symbolicLinkURL))
        #expect(reopenedStore.currentPageIndex == 2)
        #expect(reopenedStore.pageBookmarks.map(\.pageIndex) == [2])
    }

    @Test("UserDefaults enthalten ausschließlich SHA-256-Dokumentidentitäten und harmlose Seitendaten")
    @MainActor
    func persistenceNeverContainsRawPathsOrDocumentContents() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let sensitiveFileName = "Vertraulicher Mandant 4711.pdf"
        let documentURL = try copyFixture(
            PDFTestFixture.outlinedFourPages.url,
            into: temporaryDirectory,
            named: sensitiveFileName
        )
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: documentURL))
        store.goToPage(2)
        store.toggleBookmarkForCurrentPage()

        let domain = try #require(preferences.persistentDomain(forName: suiteName))
        let expectedHash = documentHash(for: documentURL)
        #expect(domain.keys.sorted() == [
            PDFDocumentStore.pageBookmarksDefaultsPrefix + expectedHash,
            PDFDocumentStore.readingPositionDefaultsPrefix + expectedHash
        ].sorted())

        for key in domain.keys {
            #expect(!key.contains(documentURL.path))
            #expect(!key.contains(sensitiveFileName))
            let hash = try #require(key.split(separator: ".").last)
            #expect(hash.count == 64)
            #expect(hash.allSatisfy { "0123456789abcdef".contains($0) })
        }

        let bookmarkData = try #require(
            preferences.data(forKey: PDFDocumentStore.pageBookmarksDefaultsPrefix + expectedHash)
        )
        let encodedBookmarks = try #require(String(data: bookmarkData, encoding: .utf8))
        #expect(!encodedBookmarks.contains(documentURL.path))
        #expect(!encodedBookmarks.contains(sensitiveFileName))
        #expect(!encodedBookmarks.contains("Kapitel"))
        #expect(encodedBookmarks.contains("Seite 3"))
        #expect(
            preferences.integer(forKey: PDFDocumentStore.readingPositionDefaultsPrefix + expectedHash) == 2
        )
    }

    @Test("Neue ungespeicherte Dokumente erzeugen weder dauerhafte Lesepositionen noch Lesezeichen")
    @MainActor
    func unsavedDocumentsNeverPersistReadingState() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)

        #expect(store.createBlankDocument())
        store.addBlankPage()
        store.goToPage(1)
        store.toggleBookmarkForCurrentPage()

        #expect(store.currentPageIndex == 1)
        #expect(store.pageBookmarks.isEmpty)
        #expect(!store.isCurrentPageBookmarked)
        #expect(store.isDirty)
        #expect(preferences.persistentDomain(forName: suiteName)?.isEmpty != false)
    }

    @Test("Ungültige gespeicherte Lesepositionen werden auf vorhandene Seiten begrenzt")
    @MainActor
    func invalidStoredReadingPositionsAreClamped() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let documentURL = PDFTestFixture.outlinedFourPages.url
        let positionKey = PDFDocumentStore.readingPositionDefaultsPrefix + documentHash(for: documentURL)
        preferences.set(999, forKey: positionKey)

        let lastPageStore = PDFDocumentStore(preferences: preferences)
        #expect(lastPageStore.loadDocument(from: documentURL))
        #expect(lastPageStore.currentPageIndex == 3)
        #expect(preferences.integer(forKey: positionKey) == 3)

        preferences.set(-42, forKey: positionKey)
        let firstPageStore = PDFDocumentStore(preferences: preferences)
        #expect(firstPageStore.loadDocument(from: documentURL))
        #expect(firstPageStore.currentPageIndex == 0)
        #expect(preferences.integer(forKey: positionKey) == 0)
    }

    @Test("Ungültige, doppelte und beschädigte gespeicherte Lesezeichen werden verworfen")
    @MainActor
    func invalidAndCorruptedBookmarksAreDiscardedSafely() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let documentURL = PDFTestFixture.outlinedFourPages.url
        let bookmarksKey = PDFDocumentStore.pageBookmarksDefaultsPrefix + documentHash(for: documentURL)
        let unsafeBookmarks = [
            PDFPageBookmark(id: "page-3", pageIndex: 3, title: "Seite 4"),
            PDFPageBookmark(id: "negative", pageIndex: -1, title: "Ungültig"),
            PDFPageBookmark(id: "outside", pageIndex: 4, title: "Ungültig"),
            PDFPageBookmark(id: "duplicate", pageIndex: 3, title: "Duplikat"),
            PDFPageBookmark(id: "", pageIndex: 1, title: "Fehlende ID"),
            PDFPageBookmark(id: "page-0", pageIndex: 0, title: "Seite 1")
        ]
        preferences.set(try JSONEncoder().encode(unsafeBookmarks), forKey: bookmarksKey)

        let normalizedStore = PDFDocumentStore(preferences: preferences)
        #expect(normalizedStore.loadDocument(from: documentURL))
        #expect(normalizedStore.pageBookmarks.map(\.pageIndex) == [0, 3])
        let normalizedData = try #require(preferences.data(forKey: bookmarksKey))
        #expect(try JSONDecoder().decode([PDFPageBookmark].self, from: normalizedData).count == 2)

        preferences.set(Data("kein gültiges JSON".utf8), forKey: bookmarksKey)
        let corruptedStore = PDFDocumentStore(preferences: preferences)
        #expect(corruptedStore.loadDocument(from: documentURL))
        #expect(corruptedStore.pageBookmarks.isEmpty)
        #expect(preferences.object(forKey: bookmarksKey) == nil)
    }

    @Test("Geänderte Seitenzahlen begrenzen Positionen und entfernen veraltete Lesezeichen")
    @MainActor
    func changedPageCountsClampPositionsAndDiscardMissingBookmarks() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let documentURL = try copyFixture(
            PDFTestFixture.outlinedFourPages.url,
            into: temporaryDirectory,
            named: "Geändert.pdf"
        )
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let originalStore = PDFDocumentStore(preferences: preferences)
        #expect(originalStore.loadDocument(from: documentURL))
        originalStore.goToPage(3)
        originalStore.toggleBookmarkForCurrentPage()

        let replacementDocument = PDFDocument()
        replacementDocument.insert(try #require(PDFUtilities.blankPage()), at: 0)
        replacementDocument.insert(try #require(PDFUtilities.blankPage()), at: 1)
        #expect(replacementDocument.write(to: documentURL))

        let reopenedStore = PDFDocumentStore(preferences: preferences)
        #expect(reopenedStore.loadDocument(from: documentURL))
        #expect(reopenedStore.pageCount == 2)
        #expect(reopenedStore.currentPageIndex == 1)
        #expect(reopenedStore.pageBookmarks.isEmpty)
    }

    @Test("Dokumentwechsel tauscht Gliederung, Lesezeichen und Leseposition vollständig aus")
    @MainActor
    func documentReplacementRefreshesAllReaderNavigationState() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        store.goToPage(2)
        store.toggleBookmarkForCurrentPage()

        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))

        #expect(store.currentPageIndex == 0)
        #expect(store.documentOutline.isEmpty)
        #expect(store.pageBookmarks.isEmpty)
        #expect(!store.isCurrentPageBookmarked)
        #expect(store.workspaceMode == .reading)
        #expect(!store.isDirty)

        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        #expect(store.currentPageIndex == 2)
        #expect(store.documentOutline.count == 3)
        #expect(store.pageBookmarks.map(\.pageIndex) == [2])
    }

    @Test("Ungültige Dateien verändern bestehende Lesepositionen und Lesezeichen nicht")
    @MainActor
    func invalidReplacementPreservesExistingReaderNavigation() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        store.goToPage(2)
        store.toggleBookmarkForCurrentPage()
        store.setWorkspaceMode(.editing)
        let previousOutline = store.documentOutline
        let previousBookmarks = store.pageBookmarks
        let previousDocument = try #require(store.document)

        #expect(!store.loadDocument(from: PDFTestFixture.invalidDocument.url))

        #expect(store.document === previousDocument)
        #expect(store.documentOutline == previousOutline)
        #expect(store.pageBookmarks == previousBookmarks)
        #expect(store.currentPageIndex == 2)
        #expect(store.workspaceMode == .editing)
    }

    @Test("Abgebrochene Dokumentwechsel behalten Lesezeichen und gespeicherte Zielpositionen")
    @MainActor
    func cancelledReplacementPreservesCurrentAndTargetReadingState() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let targetURL = PDFTestFixture.searchableThreePages.url
        let targetPositionKey = PDFDocumentStore.readingPositionDefaultsPrefix + documentHash(for: targetURL)
        preferences.set(2, forKey: targetPositionKey)
        let store = PDFDocumentStore(
            preferences: preferences,
            unsavedChangesDecisionProvider: { _ in .cancel }
        )
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        store.goToPage(2)
        store.toggleBookmarkForCurrentPage()
        store.setWorkspaceMode(.editing)
        store.addBlankPage()
        let previousDocument = try #require(store.document)
        let previousPage = store.currentPageIndex
        let previousBookmarks = store.pageBookmarks

        #expect(!store.loadDocument(from: targetURL))

        #expect(store.document === previousDocument)
        #expect(store.currentPageIndex == previousPage)
        #expect(store.pageBookmarks == previousBookmarks)
        #expect(store.workspaceMode == .editing)
        #expect(store.isDirty)
        #expect(preferences.integer(forKey: targetPositionKey) == 2)
    }

    @Test("PDFView-Seitenwechsel werden gespeichert und beim erneuten Anfügen wiederhergestellt")
    @MainActor
    func pdfViewNavigationSynchronizesAndPreservesRestoredPosition() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let documentURL = PDFTestFixture.outlinedFourPages.url
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: documentURL))
        let view = PDFView()
        store.attach(pdfView: view)
        let targetPage = try #require(store.document?.page(at: 3))

        view.go(to: targetPage)
        store.syncFromPDFView(view)

        #expect(store.currentPageIndex == 3)
        let positionKey = PDFDocumentStore.readingPositionDefaultsPrefix + documentHash(for: documentURL)
        #expect(preferences.integer(forKey: positionKey) == 3)

        let reopenedStore = PDFDocumentStore(preferences: preferences)
        #expect(reopenedStore.loadDocument(from: documentURL))
        #expect(reopenedStore.currentPageIndex == 3)
        let reopenedView = PDFView()
        reopenedStore.attach(pdfView: reopenedView)

        #expect(reopenedStore.currentPageIndex == 3)
        #expect(reopenedView.currentPage === reopenedStore.document?.page(at: 3))
    }

    @Test("Ein angehängtes PDFView stellt die Gliederungsseite nach mehrfachem Dokumentwechsel wieder her")
    @MainActor
    func attachedPDFViewRestoresOutlinePositionAcrossDocumentSwitches() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        let view = PDFView()
        store.attach(pdfView: view)

        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        let nestedItem = try #require(store.documentOutline[1].children.first)
        store.goToOutline(nestedItem)
        #expect(store.currentPageIndex == 2)
        #expect(view.currentPage === store.document?.page(at: 2))

        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))
        #expect(store.currentPageIndex == 0)

        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        #expect(store.currentPageIndex == 2)
        #expect(view.currentPage === store.document?.page(at: 2))
        #expect(store.workspaceMode == .reading)
    }

    @Test("Verspätete Seitenmeldungen ersetzter PDFViews überschreiben die Leseposition nicht")
    @MainActor
    func stalePDFViewCallbacksCannotOverwriteActiveReadingPosition() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let documentURL = PDFTestFixture.outlinedFourPages.url
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: documentURL))
        let staleView = PDFView()
        store.attach(pdfView: staleView)
        store.goToPage(2)

        let activeView = PDFView()
        store.attach(pdfView: activeView)
        #expect(activeView.currentPage === store.document?.page(at: 2))

        staleView.go(to: try #require(store.document?.page(at: 0)))
        store.syncFromPDFView(staleView)

        let positionKey = PDFDocumentStore.readingPositionDefaultsPrefix + documentHash(for: documentURL)
        #expect(store.currentPageIndex == 2)
        #expect(preferences.integer(forKey: positionKey) == 2)
        #expect(activeView.currentPage === store.document?.page(at: 2))
    }

    @Test("Gelöschte letzte Seiten entfernen ungültig gewordene lokale Lesezeichen")
    @MainActor
    func deletingBookmarkedLastPageRemovesOutOfBoundsBookmarks() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        store.goToPage(3)
        store.toggleBookmarkForCurrentPage()

        store.deleteCurrentPage()

        #expect(store.pageCount == 3)
        #expect(store.currentPageIndex == 2)
        #expect(store.pageBookmarks.isEmpty)
    }

    @Test("Kapitelziele folgen verschobenen Dokumentseiten")
    @MainActor
    func outlineDestinationsFollowMovedDocumentPages() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))
        store.goToPage(1)

        store.moveCurrentPage(by: 2)

        #expect(store.documentOutline.map(\.pageIndex) == [0, 3, 2])
        #expect(store.documentOutline[1].children.first?.pageIndex == 1)

        store.goToOutline(try #require(store.documentOutline[1].children.first))
        #expect(store.currentPageIndex == 1)
    }

    @Test("Kapitelziele bleiben nach eingefügten und gelöschten Seiten korrekt")
    @MainActor
    func outlineDestinationsFollowInsertedAndDeletedPages() throws {
        let (suiteName, preferences) = try makePreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.outlinedFourPages.url))

        store.addBlankPage()

        #expect(store.documentOutline.map(\.pageIndex) == [0, 2, 4])
        #expect(store.documentOutline[1].children.first?.pageIndex == 3)

        store.goToPage(1)
        store.deleteCurrentPage()

        #expect(store.documentOutline.map(\.pageIndex) == [0, 1, 3])
        #expect(store.documentOutline[1].children.first?.pageIndex == 2)
    }

    private func makePreferences() throws -> (String, UserDefaults) {
        let suiteName = "at.ostheimer.klarfoliopdf.ReadingNavigationTests.\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        preferences.removePersistentDomain(forName: suiteName)
        return (suiteName, preferences)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlarfolioReadingNavigationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func copyFixture(_ fixtureURL: URL, into directory: URL, named fileName: String) throws -> URL {
        let destinationURL = directory.appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: fixtureURL, to: destinationURL)
        return destinationURL
    }

    private func documentHash(for url: URL) -> String {
        let normalizedPath = url.standardizedFileURL.resolvingSymlinksInPath().path
        return SHA256.hash(data: Data(normalizedPath.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    @MainActor
    private func makeOutlineActionDocument(in directory: URL) throws -> URL {
        let document = PDFDocument()
        for index in 0..<3 {
            document.insert(try #require(PDFUtilities.blankPage()), at: index)
        }

        let rootOutline = PDFOutline()
        let sectionContainer = PDFOutline()
        sectionContainer.label = "Abschnitte"
        let localOutline = PDFOutline()
        localOutline.label = "Lokaler Abschnitt"
        localOutline.action = PDFActionGoTo(
            destination: PDFDestination(page: try #require(document.page(at: 2)), at: .zero)
        )
        sectionContainer.insertChild(localOutline, at: 0)
        rootOutline.insertChild(sectionContainer, at: 0)

        let externalOutline = PDFOutline()
        externalOutline.label = "Externer Verweis"
        externalOutline.action = PDFActionURL(url: try #require(URL(string: "https://example.invalid")))
        rootOutline.insertChild(externalOutline, at: 1)
        document.outlineRoot = rootOutline

        let documentURL = directory.appendingPathComponent("Outline-Aktionen.pdf")
        try #require(document.write(to: documentURL))
        return documentURL
    }
}
