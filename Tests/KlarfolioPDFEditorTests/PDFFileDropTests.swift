import Foundation
import Testing
@testable import KlarfolioPDFEditor

@Suite("PDF-Dateien und Bildseiten per Drag-and-drop")
struct PDFFileDropTests {
    @Test("Einzelne PDFs können im Lese- und Bearbeitungsmodus geöffnet werden")
    func singlePDFCanBeOpenedInBothWorkspaceModes() {
        let pdf = URL(fileURLWithPath: "/tmp/Klarfolio-Beispiel.PDF")

        #expect(PDFFileDropAction.resolve([pdf], workspaceMode: .reading) == .openPDF(pdf))
        #expect(PDFFileDropAction.resolve([pdf], workspaceMode: .editing) == .openPDF(pdf))
    }

    @Test("Unterstützte Bilder können im Bearbeitungsmodus gesammelt importiert werden")
    func supportedImagesCanBeImportedTogetherWhileEditing() {
        let images = [
            URL(fileURLWithPath: "/tmp/Klarfolio-Bild.png"),
            URL(fileURLWithPath: "/tmp/Klarfolio-Foto.JPG")
        ]

        #expect(PDFFileDropAction.resolve(images, workspaceMode: .editing) == .importImages(images))
    }

    @Test("Der Lesemodus weist schreibende Bild-Drops zurück")
    func readingModeRejectsImageImports() {
        let image = URL(fileURLWithPath: "/tmp/Klarfolio-Bild.png")

        #expect(PDFFileDropAction.resolve([image], workspaceMode: .reading) == nil)
    }

    @Test("Mehrere PDFs und gemischte Dateitypen werden nicht mehrdeutig verarbeitet")
    func ambiguousAndMixedDropsAreRejected() {
        let firstPDF = URL(fileURLWithPath: "/tmp/Erste.pdf")
        let secondPDF = URL(fileURLWithPath: "/tmp/Zweite.pdf")
        let image = URL(fileURLWithPath: "/tmp/Bild.png")

        #expect(PDFFileDropAction.resolve([firstPDF, secondPDF], workspaceMode: .editing) == nil)
        #expect(PDFFileDropAction.resolve([firstPDF, image], workspaceMode: .editing) == nil)
    }

    @Test("Leere, unbekannte und nicht lokale Drops werden abgelehnt")
    func unsupportedDropsAreRejected() throws {
        let textFile = URL(fileURLWithPath: "/tmp/Klarfolio.txt")
        let extensionlessFile = URL(fileURLWithPath: "/tmp/Klarfolio")
        let remoteFile = try #require(URL(string: "https://example.com/Klarfolio.pdf"))

        #expect(PDFFileDropAction.resolve([], workspaceMode: .editing) == nil)
        #expect(PDFFileDropAction.resolve([textFile], workspaceMode: .editing) == nil)
        #expect(PDFFileDropAction.resolve([extensionlessFile], workspaceMode: .editing) == nil)
        #expect(PDFFileDropAction.resolve([remoteFile], workspaceMode: .editing) == nil)
    }
}
