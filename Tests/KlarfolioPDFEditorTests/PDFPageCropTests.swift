import AppKit
import KlarfolioPDFTestFixtures
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("PDF-Seitenzuschnitt")
struct PDFPageCropTests {
    let media = CGRect(x: -40, y: 75, width: 400, height: 600)

    @Test("Gedrehte versetzte PDF-Boxen entsprechen festen visuellen Koordinaten", arguments: [0, 90, 180, 270])
    func rotatedCoordinates(rotation: Int) throws {
        let geometry = try #require(PDFCropGeometry(mediaBox: media, rotation: rotation))
        let crop = CGRect(x: -20, y: 105, width: 100, height: 200)
        let expected: [Int: CGRect] = [
            0: CGRect(x: 20, y: 370, width: 100, height: 200),
            90: CGRect(x: 30, y: 20, width: 200, height: 100),
            180: CGRect(x: 280, y: 30, width: 100, height: 200),
            270: CGRect(x: 370, y: 280, width: 200, height: 100)
        ]
        #expect(geometry.displayRect(for: crop) == expected[rotation])
        #expect(geometry.cropRect(for: try #require(expected[rotation])) == crop)
        #expect(geometry.displayRect(for: media) == CGRect(origin: .zero, size: geometry.displaySize))
        let inset = PDFCropGeometry.pointsPerMillimeter * 2
        var mmSelection = CGRect(origin: .zero, size: geometry.displaySize)
        for _ in 0..<2 {
            mmSelection.origin.x += inset
            mmSelection.size.width -= inset
            #expect(geometry.isValid(geometry.cropRect(for: mmSelection)))
        }
        mmSelection.origin.y += inset
        mmSelection.size.height -= inset
        #expect(geometry.isValid(geometry.cropRect(for: mmSelection)))
    }

    @Test("Vorschaugeometrie stimmt mit PDFKit überein", arguments: [0, 90, 180, 270])
    @MainActor
    func matchesPDFKit(rotation: Int) throws {
        let page = try #require(PDFUtilities.blankPage())
        page.setBounds(media, for: .mediaBox)
        page.setBounds(media, for: .cropBox)
        page.rotation = rotation
        let document = PDFDocument(); document.insert(page, at: 0)
        let view = PDFView(frame: CGRect(x: 0, y: 0, width: 800, height: 800))
        view.displayMode = .singlePage; view.displayBox = .mediaBox
        view.document = document; view.scaleFactor = 1; view.layoutDocumentView()
        let bounds = view.convert(media, from: page)
        let candidate = CGRect(x: -20, y: 105, width: 100, height: 200)
        let actual = view.convert(candidate, from: page)
        let geometry = try #require(PDFCropGeometry(mediaBox: media, rotation: rotation))
        let expected = geometry.displayRect(for: candidate)
        #expect(abs(actual.minX - bounds.minX - expected.minX) < 0.01)
        // Empirically PDFView is unflipped. SwiftUI preview is top-left based.
        #expect(!view.isFlipped)
        #expect(page.bounds(for: .mediaBox) == media)
        #expect(abs(bounds.maxY - actual.maxY - expected.minY) < 0.01)
        #expect(abs(actual.width - expected.width) < 0.01)
        #expect(abs(actual.height - expected.height) < 0.01)
    }

    @Test("Ungültige MediaBox und nicht unterstützte Drehungen werden abgewiesen")
    func invalidMedia() {
        for box in [CGRect.zero, CGRect(x: 0, y: 0, width: -1, height: 50),
                    CGRect(x: CGFloat.infinity, y: 0, width: 50, height: 50),
                    CGRect(x: 0, y: 0, width: CGFloat.nan, height: 50)] {
            #expect(PDFCropGeometry(mediaBox: box, rotation: 0) == nil)
        }
        #expect(PDFCropGeometry(mediaBox: media, rotation: 45) == nil)
        #expect(PDFCropGeometry(mediaBox: media, rotation: -90)?.rotation == 270)
    }

    @Test("Mindestgröße, Boxgrenzen und endliche Eingaben werden geprüft")
    func validation() throws {
        let geometry = try #require(PDFCropGeometry(mediaBox: media, rotation: 0))
        #expect(geometry.isValid(CGRect(x: -40, y: 75, width: 36, height: 36)))
        // Even smaller deviations than the conversion snap threshold remain
        // invalid when supplied directly, rather than produced by the preview.
        #expect(!geometry.isValid(CGRect(x: media.minX - 1e-10, y: 75, width: 100, height: 100)))
        #expect(!geometry.isValid(CGRect(x: -40, y: 75, width: media.width + 1e-10, height: 100)))
        for crop in [CGRect(x: -40, y: 75, width: 35.99, height: 36),
                     CGRect(x: -41, y: 75, width: 100, height: 100),
                     CGRect(x: 350, y: 75, width: 36, height: 36),
                     CGRect(x: 0, y: 670, width: 36, height: 36),
                     CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 50),
                     CGRect(x: CGFloat.nan, y: 75, width: 100, height: 100)] {
            #expect(!geometry.isValid(crop))
        }
    }

    @Test("Kleine Seiten können vollständig zurückgesetzt werden")
    func tinyMedia() throws {
        let small = CGRect(x: 7, y: 8, width: 20, height: 25)
        let geometry = try #require(PDFCropGeometry(mediaBox: small, rotation: 90))
        #expect(geometry.isValid(small))
        #expect(geometry.cropRect(for: geometry.selection(from: .zero, to: .zero)) == small)
    }

    @Test("Ziehen bleibt in der MediaBox und wahrt die Mindestgröße", arguments: [0, 90, 180, 270])
    func clampedGestures(rotation: Int) throws {
        let geometry = try #require(PDFCropGeometry(mediaBox: media, rotation: rotation))
        for start in [CGPoint.zero, CGPoint(x: -500, y: -500), CGPoint(x: 800, y: 900),
                      CGPoint(x: 11.33858267716536, y: 5.66929133858268)] {
            for end in [start, CGPoint(x: 200, y: 300), CGPoint(x: 900, y: 900)] {
                #expect(geometry.isValid(geometry.cropRect(for: geometry.selection(from: start, to: end))))
            }
        }
    }

    @Test("Lesemodus und fehlendes Dokument sperren Zuschnitt und Rücksetzen")
    @MainActor
    func readingGuard() throws {
        let store = PDFDocumentStore()
        store.setWorkspaceMode(.editing)
        #expect(store.beginPageCrop() == nil)
        #expect(store.loadDocument(from: PDFTestFixture.interactiveForm.url))
        #expect(store.beginPageCrop() == nil)
        store.setWorkspaceMode(.editing)
        let session = try #require(store.beginPageCrop())
        store.setWorkspaceMode(.reading)
        #expect(!store.applyPageCrop(session.originalCrop.insetBy(dx: 36, dy: 36), session: session))
        #expect(!store.resetPageCrop(session: session))
        #expect(!store.isDirty)
    }

    @Test("Öffnen und Verwerfen eines Entwurfs bleiben ohne Mutation")
    @MainActor
    func cancelDraft() throws {
        let store = try makeStore()
        let page = try #require(store.currentPage)
        let before = page.bounds(for: .cropBox), text = page.string
        let revision = store.revision
        _ = try #require(store.beginPageCrop())
        #expect(page.bounds(for: .cropBox) == before)
        #expect(page.string == text)
        #expect(!store.isDirty)
        #expect(store.revision == revision)
        store.isDirty = true
        _ = store.beginPageCrop()
        #expect(store.isDirty)
    }

    @Test("Nur aktuelle CropBox, Dirty-State, Revision und Größenanzeige ändern sich")
    @MainActor
    func appliesOnlyCurrentPage() throws {
        let store = try makeStore()
        store.goToPage(1)
        let session = try #require(store.beginPageCrop())
        let first = try #require(store.document?.page(at: 0)).bounds(for: .cropBox)
        let revision = store.revision
        let label = store.currentPageSizeLabel
        let crop = session.originalCrop.insetBy(dx: 36, dy: 48)
        #expect(store.applyPageCrop(crop, session: session))
        #expect(store.currentPage === session.page)
        #expect(session.page.bounds(for: .cropBox) == crop)
        #expect(session.page.bounds(for: .mediaBox) == session.geometry.mediaBox)
        #expect(store.document?.page(at: 0)?.bounds(for: .cropBox) == first)
        #expect(store.currentPageSizeLabel != label)
        #expect(store.revision == revision + 1)
        #expect(store.isDirty)
    }

    @Test("Ungültige Eingaben und identische Boxen ändern weder PDF noch Status")
    @MainActor
    func invalidStoreInput() throws {
        let store = try makeStore()
        let session = try #require(store.beginPageCrop())
        let revision = store.revision, status = store.statusMessage
        for crop in [CGRect.zero, CGRect(x: CGFloat.infinity, y: 0, width: 50, height: 50),
                     session.originalCrop.insetBy(dx: -1, dy: -1), session.originalCrop,
                     session.originalCrop.offsetBy(dx: -1e-10, dy: 0),
                     CGRect(x: 0, y: 0, width: 2, height: 2)] {
            #expect(!store.applyPageCrop(crop, session: session))
        }
        #expect(!store.resetPageCrop(session: session))
        #expect(!store.isDirty)
        #expect(store.revision == revision)
        #expect(store.statusMessage == status)
    }

    @Test("PDFView-Layout und Miniatur folgen der neuen CropBox")
    @MainActor
    func viewAndThumbnailRefresh() throws {
        let store = try makeStore()
        let view = PDFView(frame: CGRect(x: 0, y: 0, width: 700, height: 700))
        store.attach(pdfView: view)
        store.goToPage(1)
        let session = try #require(store.beginPageCrop())
        let crop = session.originalCrop.insetBy(dx: 100, dy: 40)
        let before = try #require(store.thumbnail(for: 1, size: CGSize(width: 200, height: 200)))
        #expect(store.applyPageCrop(crop, session: session))
        #expect(view.currentPage === session.page)
        #expect(store.currentPageIndex == 1)
        #expect(view.displayBox == .cropBox)
        let after = try #require(store.thumbnail(for: 1, size: CGSize(width: 200, height: 200)))
        #expect(abs(after.size.width / after.size.height - crop.width / crop.height) < 0.02)
        #expect(after.size != before.size)
    }

    @Test("Veraltete Entwürfe nach Seitenwechsel, Rotation oder Ersatz werden abgewiesen")
    @MainActor
    func staleSession() throws {
        let store = try makeStore()
        let session = try #require(store.beginPageCrop())
        let crop = session.originalCrop.insetBy(dx: 40, dy: 40)
        store.goToPage(1)
        #expect(!store.applyPageCrop(crop, session: session))
        store.goToPage(0)
        session.page.rotation = 90
        #expect(!store.applyPageCrop(crop, session: session))
        session.page.rotation = 0
        session.page.setBounds(crop, for: .cropBox)
        #expect(!store.resetPageCrop(session: session))
        #expect(store.loadDocument(from: PDFTestFixture.interactiveForm.url))
        store.setWorkspaceMode(.editing)
        #expect(!store.applyPageCrop(crop, session: session))
        #expect(!store.isDirty)
    }

    @Test("Wiederholter Zuschnitt und Rücksetzen erhalten versetzte Boxen beim Speichern", arguments: [0, 90, 180, 270])
    @MainActor
    func saveReopen(rotation: Int) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = PDFTestFixture.croppedGeometryFourPages.url
        let original = try Data(contentsOf: source)
        let url = directory.appendingPathComponent("crop.pdf")
        try FileManager.default.copyItem(at: source, to: url)
        let store = try makeStore(url: url)
        store.goToPage(rotation / 90)
        let page = try #require(store.currentPage)
        #expect(page.bounds(for: .mediaBox) == media)
        #expect(page.rotation == rotation)
        let session = try #require(store.beginPageCrop())
        let crop = media.insetBy(dx: 40, dy: 50)
        let text = page.string, annotationCount = page.annotations.count
        #expect(store.applyPageCrop(crop, session: session))
        let second = try #require(store.beginPageCrop())
        let smaller = crop.insetBy(dx: 10, dy: 10)
        #expect(store.applyPageCrop(smaller, session: second))
        #expect(store.saveDocument())
        #expect(!store.isDirty)
        #expect(store.loadDocument(from: url))
        #expect(store.workspaceMode == .reading)
        let reopened = try #require(store.currentPage)
        let savedMedia = reopened.bounds(for: .mediaBox)
        #expect(savedMedia.size == media.size)
        // PDFKit's existing writer normalizes non-zero MediaBox origins. The
        // visible rectangle must remain identical relative to the MediaBox.
        #expect(reopened.bounds(for: .cropBox) == smaller.offsetBy(
            dx: savedMedia.minX - media.minX, dy: savedMedia.minY - media.minY))
        #expect(reopened.rotation == rotation)
        #expect(reopened.annotations.count == annotationCount)
        store.setWorkspaceMode(.editing)
        #expect(store.resetPageCrop(session: try #require(store.beginPageCrop())))
        #expect(store.isDirty)
        #expect(store.saveDocument())
        #expect(store.loadDocument(from: url))
        #expect(store.currentPage?.bounds(for: .cropBox) == store.currentPage?.bounds(for: .mediaBox))
        #expect(store.currentPage?.string == text)
        #expect(try Data(contentsOf: source) == original)
    }

    @Test("Links, Outlines und persönliche Lesedaten bleiben beim Zuschnitt erhalten")
    @MainActor
    func navigationPreserved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("outline.pdf")
        try FileManager.default.copyItem(at: PDFTestFixture.outlinedFourPages.url, to: url)
        let store = try makeStore(url: url)
        store.goToPage(2)
        store.toggleBookmarkForCurrentPage()
        let outline = store.documentOutline
        let bookmarks = store.pageBookmarks
        let target = try #require(store.document?.page(at: 0))
        let link = PDFAnnotation(bounds: CGRect(x: 50, y: 50, width: 80, height: 40), forType: .link, withProperties: nil)
        link.destination = PDFDestination(page: target, at: CGPoint(x: 60, y: 70))
        let session = try #require(store.beginPageCrop())
        session.page.addAnnotation(link)
        #expect(store.applyPageCrop(session.originalCrop.insetBy(dx: 40, dy: 40), session: session))
        #expect(link.destination?.page === target)
        #expect(store.documentOutline == outline)
        #expect(store.pageBookmarks == bookmarks)
        #expect(store.currentPageIndex == 2)
        #expect(store.saveDocument())
        #expect(store.loadDocument(from: url))
        #expect(store.currentPageIndex == 2)
        #expect(store.pageBookmarks == bookmarks)
        #expect(store.documentOutline.map(\.pageIndex) == outline.map(\.pageIndex))
        let savedLink = try #require(store.currentPage?.annotations.first { $0.type == "Link" })
        #expect(savedLink.destination?.page === store.document?.page(at: 0))
    }

    @Test("Formularwerte und Anmerkungen überstehen Zuschnitt und Rücksetzen")
    @MainActor
    func formsPreserved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("form.pdf")
        let source = PDFTestFixture.interactiveForm.url
        let original = try Data(contentsOf: source)
        try FileManager.default.copyItem(at: source, to: url)
        let store = try makeStore(url: url)
        let field = try #require(store.formFields.first { $0.name == "KlarfolioName" })
        #expect(store.updateFormTextField(field.id, value: "Größe bleibt erhalten"))
        let session = try #require(store.beginPageCrop())
        let annotations = session.page.annotations.count
        #expect(store.applyPageCrop(session.originalCrop.insetBy(dx: 60, dy: 80), session: session))
        #expect(store.saveDocument())
        #expect(store.loadDocument(from: url))
        #expect(store.formFields.first { $0.name == "KlarfolioName" }?.textValue == "Größe bleibt erhalten")
        #expect(store.formFields.first { $0.name == "KlarfolioConsent" }?.isChecked == true)
        #expect(store.currentPage?.annotations.count == annotations)
        store.setWorkspaceMode(.editing)
        #expect(store.resetPageCrop(session: try #require(store.beginPageCrop())))
        #expect(store.saveDocument())
        #expect(store.loadDocument(from: url))
        #expect(store.formFields.first { $0.name == "KlarfolioName" }?.textValue == "Größe bleibt erhalten")
        #expect(store.currentPage?.annotations.contains { $0.contents == "Klarfolio fixture annotation" } == true)
        #expect(try Data(contentsOf: source) == original)
    }

    @MainActor
    private func makeStore(url: URL = PDFTestFixture.searchableThreePages.url) throws -> PDFDocumentStore {
        let suite = "KlarfolioCropTests.\(UUID().uuidString)"
        let preferences = try #require(CropTestPreferences(suite: suite))
        let store = PDFDocumentStore(preferences: preferences)
        #expect(store.loadDocument(from: url))
        store.setWorkspaceMode(.editing)
        return store
    }
}

private final class CropTestPreferences: UserDefaults, @unchecked Sendable {
    let suite: String
    init?(suite: String) {
        self.suite = suite
        super.init(suiteName: suite)
    }
    deinit { removePersistentDomain(forName: suite) }
}
