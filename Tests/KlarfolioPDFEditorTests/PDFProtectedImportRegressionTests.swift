import AppKit
import KlarfolioPDFTestFixtures
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("Geschützter Import und Tastaturnavigation")
struct PDFProtectedImportRegressionTests {
    @Test("Nur das Auswahlwerkzeug verschiebt vorhandene Annotationen per PDFView-Drag", arguments: [PDFInteractionTool.highlight, .text, .select])
    @MainActor
    func annotationDragRequiresSelectionTool(tool: PDFInteractionTool) throws {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 900),
                              styleMask: [.titled], backing: .buffered, defer: false)
        let view = AnnotationEditingPDFView(frame: NSRect(x: 0, y: 0, width: 600, height: 850))
        window.contentView = view
        let store = PDFDocumentStore()
        store.loadDocument(from: PDFTestFixture.interactiveForm.url)
        store.setWorkspaceMode(.editing)
        store.selectedTool = tool
        view.editingStore = store
        store.attach(pdfView: view)
        view.scaleFactor = 1
        view.layoutDocumentView()
        let page = try #require(store.currentPage)
        let note = try #require(page.annotations.first { $0.hasSubtype(.text) })
        let original = note.bounds
        let start = view.convert(view.convert(CGPoint(x: original.midX, y: original.midY), from: page), to: nil)
        func event(_ type: NSEvent.EventType, point: CGPoint) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [], timestamp: 0,
                                           windowNumber: window.windowNumber, context: nil,
                                           eventNumber: 1, clickCount: 1, pressure: 1))
        }
        view.mouseDown(with: try event(.leftMouseDown, point: start))
        let end = CGPoint(x: start.x + 20, y: start.y - 20)
        view.mouseDragged(with: try event(.leftMouseDragged, point: end))
        view.mouseUp(with: try event(.leftMouseUp, point: end))
        #expect(store.selectedTool == tool)
        if tool == .select {
            #expect(note.bounds != original && store.isDirty)
        } else {
            #expect(note.bounds == original && !store.isDirty)
        }
    }

    @Test("Merge remappt interne Ziele mehrerer Quellen auf Kopien und erhält sie beim Speichern")
    @MainActor
    func mergePreservesInternalDestinations() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var urls: [URL] = []
        var originals: [Data] = []
        for index in 0..<2 {
            let source = try #require(PDFDocument(url: PDFTestFixture.mergeTwoPages.url))
            let page = try #require(source.page(at: 0))
            let target = try #require(source.page(at: 1))
            let link = PDFAnnotation(bounds: CGRect(x: 40, y: 40, width: 100, height: 30), forType: .link, withProperties: nil)
            link.action = PDFActionGoTo(destination: PDFDestination(page: target, at: CGPoint(x: 20, y: 60)))
            page.addAnnotation(link)
            let url = directory.appendingPathComponent("source-\(index).pdf")
            #expect(source.write(to: url))
            urls.append(url)
            originals.append(try Data(contentsOf: url))
        }
        let output = directory.appendingPathComponent("merged.pdf")
        try Data(contentsOf: PDFTestFixture.mergeTwoPages.url).write(to: output)
        let store = PDFDocumentStore()
        #expect(store.loadDocument(from: output))
        store.setWorkspaceMode(.editing)
        #expect(store.mergeDocuments(from: urls) == 4)
        func verify(_ document: PDFDocument) throws {
            #expect(document.pageCount == 6)
            for (from, to) in [(2, 3), (4, 5)] {
                let link = try #require(document.page(at: from)?.annotations.first { $0.hasSubtype(.link) })
                let target = try #require((link.action as? PDFActionGoTo)?.destination.page ?? link.destination?.page)
                #expect(target.document === document)
                #expect(document.index(for: target) == to)
            }
        }
        try verify(try #require(store.document))
        #expect(store.saveDocument())
        try verify(try #require(PDFDocument(url: output)))
        for (url, bytes) in zip(urls, originals) { #expect(try Data(contentsOf: url) == bytes) }
    }

    @Test("Tab und Umschalt-Tab verlassen PDFView zu legitimen KeyViews ohne Widgetfokus")
    @MainActor
    func tabMovesOutsidePDFView() throws {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                              styleMask: [.titled], backing: .buffered, defer: false)
        let content = try #require(window.contentView)
        let previous = NSTextField(frame: NSRect(x: 10, y: 460, width: 100, height: 24))
        let next = NSTextField(frame: NSRect(x: 300, y: 460, width: 100, height: 24))
        let view = AnnotationEditingPDFView(frame: NSRect(x: 0, y: 0, width: 600, height: 430))
        let store = PDFDocumentStore()
        store.loadDocument(from: PDFTestFixture.interactiveForm.url)
        view.editingStore = store
        store.attach(pdfView: view)
        content.addSubview(previous); content.addSubview(view); content.addSubview(next)
        let nativeBefore = NSTextField(frame: NSRect(x: 10, y: 10, width: 100, height: 24))
        let nativeAfter = NSTextField(frame: NSRect(x: 10, y: 40, width: 100, height: 24))
        view.addSubview(nativeBefore); view.addSubview(nativeAfter)
        window.autorecalculatesKeyViewLoop = false
        previous.nextKeyView = nativeBefore; nativeBefore.nextKeyView = view
        view.nextKeyView = nativeAfter; nativeAfter.nextKeyView = next; next.nextKeyView = previous
        #expect(window.makeFirstResponder(view))
        func tab(shift: Bool) throws -> NSEvent {
            try #require(NSEvent.keyEvent(with: .keyDown, location: .zero,
                                         modifierFlags: shift ? [.shift] : [], timestamp: 0,
                                         windowNumber: window.windowNumber, context: nil,
                                         characters: "\t", charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48))
        }
        view.keyDown(with: try tab(shift: false))
        #expect(window.firstResponder === next.currentEditor())
        #expect(window.firstResponder !== view)
        #expect(nativeAfter.currentEditor() == nil)
        #expect(window.makeFirstResponder(view))
        view.keyDown(with: try tab(shift: true))
        #expect(window.firstResponder === previous.currentEditor())
        #expect(window.firstResponder !== view)
        #expect(nativeBefore.currentEditor() == nil)
        #expect(!store.isDirty)
    }
}
