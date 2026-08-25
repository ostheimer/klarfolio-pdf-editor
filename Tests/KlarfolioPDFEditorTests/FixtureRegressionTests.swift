import Foundation
import KlarfolioPDFTestFixtures
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("Versionierte PDF-Testdateien")
struct FixtureRegressionTests {
    @Test("Alle dokumentierten Testdateien werden im Ressourcen-Bundle bereitgestellt")
    func everyDocumentedFixtureIsBundled() throws {
        #expect(PDFTestFixture.allCases.count == 4)

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
        let store = PDFDocumentStore()

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
        let document = try #require(PDFDocument(url: PDFTestFixture.interactiveForm.url))
        let page = try #require(document.page(at: 0))
        let textField = try #require(page.annotations.first { $0.fieldName == "KlarfolioName" })
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlarfolioFixtureTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        textField.widgetStringValue = "Gespeicherter Testwert"
        let outputURL = temporaryDirectory.appendingPathComponent("Ausgefüllt.pdf")

        #expect(document.write(to: outputURL))

        let reloadedDocument = try #require(PDFDocument(url: outputURL))
        let reloadedPage = try #require(reloadedDocument.page(at: 0))
        let reloadedTextField = try #require(
            reloadedPage.annotations.first { $0.fieldName == "KlarfolioName" }
        )

        #expect(reloadedTextField.widgetStringValue == "Gespeicherter Testwert")
        #expect(reloadedPage.annotations.contains { $0.hasSubtype(.text) })
    }

    @Test("Die ungültige PDF-Fixture wird ohne Verlust des offenen Dokuments abgewiesen")
    @MainActor
    func invalidFixtureCannotReplaceTheOpenDocument() throws {
        let store = PDFDocumentStore()
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
        let store = PDFDocumentStore()
        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))

        let extracted = try #require(store.documentByCopyingPages(in: 1...2))

        #expect(extracted.pageCount == 2)
        #expect(extracted.page(at: 0)?.string?.contains("Testseite 2") == true)
        #expect(extracted.page(at: 1)?.string?.contains("Testseite 3") == true)
        #expect(store.pageCount == 3)
        #expect(!store.isDirty)
    }
}
