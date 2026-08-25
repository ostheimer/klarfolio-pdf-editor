import Foundation
import KlarfolioPDFTestFixtures
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("Versionierte PDF-Testdateien")
struct FixtureRegressionTests {
    private func isolatedPreferences() throws -> (preferences: UserDefaults, suiteName: String) {
        let suiteName = "KlarfolioFixtureRegressionTests.\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        preferences.removePersistentDomain(forName: suiteName)
        return (preferences, suiteName)
    }

    @Test("Alle dokumentierten Testdateien werden im Ressourcen-Bundle bereitgestellt")
    func everyDocumentedFixtureIsBundled() throws {
        #expect(PDFTestFixture.allCases.count == 5)

        for fixture in PDFTestFixture.allCases {
            let resourceValues = try fixture.url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])

            #expect(resourceValues.isRegularFile == true)
            #expect((resourceValues.fileSize ?? 0) > 0)
            #expect(fixture.url.lastPathComponent == "\(fixture.rawValue).pdf")
        }
    }

    @Test("Die dreiseitige Fixture enthält genau zwei seitenübergreifende Suchtreffer")
    @MainActor
    func searchableFixtureCoversOpeningNavigationAndSearch() throws {
        let (preferences, suiteName) = try isolatedPreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)

        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))
        #expect(store.pageCount == 3)
        #expect(store.currentPageIndex == 0)
        #expect(store.documentTitle == "fixture-text-3-pages.pdf")
        #expect(!store.isDirty)

        store.searchText = "Klarfolio-Testwort"
        store.runSearch()

        #expect(store.searchResultCount == 2)
        #expect(store.statusMessage == "2 Treffer")
        #expect(store.document?.page(at: 0)?.string?.contains("mehreren") == true)
        #expect(store.document?.page(at: 2)?.string?.contains("Klarfolio-Testwort") == true)

        store.goToPage(2)
        #expect(store.currentPageIndex == 2)
    }

    @Test("Die Outline-Fixture enthält vier Seiten und verschachtelte echte Kapitelziele")
    func outlinedFixtureContainsNestedRealPageDestinations() throws {
        let document = try #require(PDFDocument(url: PDFTestFixture.outlinedFourPages.url))
        let outlineRoot = try #require(document.outlineRoot)
        let introduction = try #require(outlineRoot.child(at: 0))
        let chapterOne = try #require(outlineRoot.child(at: 1))
        let section = try #require(chapterOne.child(at: 0))
        let chapterTwo = try #require(outlineRoot.child(at: 2))

        #expect(document.pageCount == 4)
        #expect(introduction.label == "Einleitung")
        #expect(chapterOne.label == "Kapitel 1")
        #expect(section.label == "Abschnitt 1.1")
        #expect(chapterTwo.label == "Kapitel 2")
        #expect(document.index(for: try #require(introduction.destination?.page)) == 0)
        #expect(document.index(for: try #require(chapterOne.destination?.page)) == 1)
        #expect(document.index(for: try #require(section.destination?.page)) == 2)
        #expect(document.index(for: try #require(chapterTwo.destination?.page)) == 3)
    }

    @Test("Die Zusammenführen-Fixture hat zwei unterscheidbare Seiten in stabiler Reihenfolge")
    func mergeFixtureHasTwoDistinctOrderedPages() throws {
        let document = try #require(PDFDocument(url: PDFTestFixture.mergeTwoPages.url))
        let firstPage = try #require(document.page(at: 0))
        let secondPage = try #require(document.page(at: 1))

        #expect(document.pageCount == 2)
        #expect(firstPage.string?.contains("Seite 1") == true)
        #expect(firstPage.string?.contains("Blaue Testseite") == true)
        #expect(secondPage.string?.contains("Seite 2") == true)
        #expect(secondPage.string?.contains("Mintfarbene Testseite") == true)
        #expect(firstPage.bounds(for: .mediaBox) == secondPage.bounds(for: .mediaBox))
    }

    @Test("Die Formularfixture enthält ein Textfeld, eine Checkbox und eine vorhandene Notiz")
    func formFixtureContainsRealWidgetsAndAnnotation() throws {
        let document = try #require(PDFDocument(url: PDFTestFixture.interactiveForm.url))
        let page = try #require(document.page(at: 0))
        let textField = try #require(page.annotations.first { $0.fieldName == "KlarfolioName" })
        let checkbox = try #require(page.annotations.first { $0.fieldName == "KlarfolioConsent" })
        let note = try #require(page.annotations.first { $0.hasSubtype(.text) })

        #expect(document.pageCount == 1)
        #expect(page.annotations.count == 3)
        #expect(textField.hasSubtype(.widget))
        #expect(textField.widgetFieldType == .text)
        #expect(textField.widgetStringValue == "Andreas Test")
        #expect(checkbox.hasSubtype(.widget))
        #expect(checkbox.widgetFieldType == .button)
        #expect(checkbox.widgetStringValue == "Yes")
        #expect(note.contents == "Klarfolio fixture annotation")
    }

    @Test("Formularwerte bleiben nach dem Schreiben und erneuten Öffnen erhalten")
    func formFixtureValuesRoundTripThroughPDFKit() throws {
        let sourceURL = PDFTestFixture.interactiveForm.url
        let originalFixtureData = try Data(contentsOf: sourceURL)
        let document = try #require(PDFDocument(url: sourceURL))
        let page = try #require(document.page(at: 0))
        let textField = try #require(page.annotations.first { $0.fieldName == "KlarfolioName" })
        let checkbox = try #require(page.annotations.first { $0.fieldName == "KlarfolioConsent" })
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlarfolioFixtureTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        textField.widgetStringValue = "Geprüfter Formularwert – Größe 42"
        checkbox.buttonWidgetState = .offState
        let outputURL = temporaryDirectory.appendingPathComponent("Ausgefüllt.pdf")

        #expect(document.write(to: outputURL))

        let reloadedDocument = try #require(PDFDocument(url: outputURL))
        let reloadedPage = try #require(reloadedDocument.page(at: 0))
        let reloadedTextField = try #require(
            reloadedPage.annotations.first { $0.fieldName == "KlarfolioName" }
        )
        let reloadedCheckbox = try #require(
            reloadedPage.annotations.first { $0.fieldName == "KlarfolioConsent" }
        )

        #expect(reloadedTextField.widgetStringValue == "Geprüfter Formularwert – Größe 42")
        #expect(reloadedCheckbox.buttonWidgetState == .offState)
        #expect(reloadedPage.annotations.contains { $0.hasSubtype(.text) })
        #expect(try Data(contentsOf: sourceURL) == originalFixtureData)
    }

    @Test("Die Checkbox der Formularfixture kann aus- und wieder eingeschaltet gespeichert werden")
    func formFixtureCheckboxRoundTripsBothStates() throws {
        let document = try #require(PDFDocument(url: PDFTestFixture.interactiveForm.url))
        let page = try #require(document.page(at: 0))
        let checkbox = try #require(page.annotations.first { $0.fieldName == "KlarfolioConsent" })
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlarfolioCheckboxTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        checkbox.buttonWidgetState = .offState
        let uncheckedURL = temporaryDirectory.appendingPathComponent("Nicht angekreuzt.pdf")
        #expect(document.write(to: uncheckedURL))

        let uncheckedDocument = try #require(PDFDocument(url: uncheckedURL))
        let uncheckedPage = try #require(uncheckedDocument.page(at: 0))
        let uncheckedCheckbox = try #require(
            uncheckedPage.annotations.first { $0.fieldName == "KlarfolioConsent" }
        )
        #expect(uncheckedCheckbox.buttonWidgetState == .offState)

        uncheckedCheckbox.buttonWidgetState = .onState
        let recheckedURL = temporaryDirectory.appendingPathComponent("Wieder angekreuzt.pdf")
        #expect(uncheckedDocument.write(to: recheckedURL))

        let recheckedDocument = try #require(PDFDocument(url: recheckedURL))
        let recheckedPage = try #require(recheckedDocument.page(at: 0))
        let recheckedCheckbox = try #require(
            recheckedPage.annotations.first { $0.fieldName == "KlarfolioConsent" }
        )

        #expect(recheckedCheckbox.buttonWidgetState == .onState)
        #expect(recheckedPage.annotations.first { $0.fieldName == "KlarfolioName" }?.widgetStringValue == "Andreas Test")
        #expect(recheckedPage.annotations.contains { $0.hasSubtype(.text) })
    }

    @Test("Die ungültige PDF-Fixture wird ohne Verlust des offenen Dokuments abgewiesen")
    @MainActor
    func invalidFixtureCannotReplaceTheOpenDocument() throws {
        let (preferences, suiteName) = try isolatedPreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))
        let previousDocument = try #require(store.document)
        let previousURL = store.fileURL

        #expect(PDFDocument(url: PDFTestFixture.invalidDocument.url) == nil)
        #expect(!store.loadDocument(from: PDFTestFixture.invalidDocument.url))
        #expect(store.document === previousDocument)
        #expect(store.fileURL == previousURL)
        #expect(store.pageCount == 3)
        #expect(store.statusMessage == "Die Datei konnte nicht geöffnet werden.")
    }

    @Test("Extraktion aus der Textfixture erhält den Inhalt und verändert die Quelle nicht")
    @MainActor
    func fixtureExtractionPreservesSourceAndPageContent() throws {
        let (preferences, suiteName) = try isolatedPreferences()
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))

        let extracted = try #require(store.documentByCopyingPages(in: 1...2))

        #expect(extracted.pageCount == 2)
        #expect(extracted.page(at: 0)?.string?.contains("Testseite 2") == true)
        #expect(extracted.page(at: 1)?.string?.contains("Testseite 3") == true)
        #expect(store.pageCount == 3)
        #expect(!store.isDirty)
    }
}
