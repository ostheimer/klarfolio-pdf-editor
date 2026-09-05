import AppKit
import PDFKit
import SwiftUI

struct PDFCanvasView: NSViewRepresentable {
    @ObservedObject var store: PDFDocumentStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = AnnotationEditingPDFView()
        pdfView.editingStore = store
        pdfView.delegate = context.coordinator
        pdfView.registerForDraggedTypes([.fileURL])
        store.attach(pdfView: pdfView)
        context.coordinator.installNotifications(for: pdfView)
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== store.document {
            pdfView.document = store.document
            pdfView.autoScales = true
        }

        if pdfView.displayMode != store.layoutMode.pdfDisplayMode {
            pdfView.displayMode = store.layoutMode.pdfDisplayMode
            pdfView.autoScales = true
        }

        if store.workspaceMode == .reading,
           let fieldEditor = pdfView.window?.firstResponder as? NSTextView,
           fieldEditor.isFieldEditor {
            pdfView.window?.makeFirstResponder(pdfView)
        }
    }

    final class Coordinator: NSObject, PDFViewDelegate {
        private weak var store: PDFDocumentStore?
        private var observers: [NSObjectProtocol] = []

        init(store: PDFDocumentStore) {
            self.store = store
        }

        deinit {
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func installNotifications(for pdfView: PDFView) {
            let center = NotificationCenter.default

            observers.append(
                center.addObserver(
                    forName: .PDFViewPageChanged,
                    object: pdfView,
                    queue: .main
                ) { [weak self, weak pdfView] _ in
                    Task { @MainActor in
                        self?.store?.syncFromPDFView(pdfView)
                    }
                }
            )

            observers.append(
                center.addObserver(
                    forName: .PDFViewScaleChanged,
                    object: pdfView,
                    queue: .main
                ) { [weak self, weak pdfView] _ in
                    Task { @MainActor in
                        self?.store?.syncFromPDFView(pdfView)
                    }
                }
            )
        }
    }
}

@MainActor
final class AnnotationEditingPDFView: PDFView, NSMenuItemValidation {
    weak var editingStore: PDFDocumentStore?

    private weak var draggedAnnotation: PDFAnnotation?
    private weak var draggedPage: PDFPage?
    private var dragStartPoint = CGPoint.zero
    private var dragStartBounds = CGRect.zero

    override var acceptsFirstResponder: Bool {
        true
    }

    override func copy(_ sender: Any?) {
        guard document === editingStore?.document,
              editingStore?.requirePermission(.copy) == true else { return }
        super.copy(sender)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard document === editingStore?.document else { return false }
        if menuItem.action == #selector(copy(_:)) {
            return editingStore?.canPerform(.copy) == true && currentSelection != nil
        }
        if menuItem.action == #selector(printView(_:)) {
            return editingStore?.canPerform(.print) == true
        }
        return document != nil
    }

    override func printView(_ sender: Any?) {
        guard document === editingStore?.document,
              editingStore?.requirePermission(.print) == true else { return }
        print(with: NSPrintInfo.shared, autoRotate: true)
    }

    override func print(with printInfo: NSPrintInfo, autoRotate: Bool) {
        guard document === editingStore?.document,
              editingStore?.requirePermission(.print) == true else { return }
        super.print(with: printInfo, autoRotate: autoRotate)
    }

    override func print(with printInfo: NSPrintInfo, autoRotate: Bool, pageScaling scale: PDFPrintScalingMode) {
        guard document === editingStore?.document,
              editingStore?.requirePermission(.print) == true else { return }
        super.print(with: printInfo, autoRotate: autoRotate, pageScaling: scale)
    }

    override func perform(_ action: PDFAction) {
        // Native reset/JavaScript/named Print or remote-document actions can
        // otherwise bypass Store guards. Only ordinary navigation links run.
        guard action is PDFActionGoTo || action is PDFActionURL else { return }
        super.perform(action)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        // PDFKit's opaque context menu includes annotation editing and exporting
        // selections as images. Expose only the explicitly guarded copy action.
        let menu = NSMenu()
        let item = NSMenuItem(title: "Kopieren", action: #selector(copy(_:)), keyEquivalent: "")
        item.target = self
        item.isEnabled = editingStore?.canPerform(.copy) == true && currentSelection != nil
        menu.autoenablesItems = false
        menu.addItem(item)
        return menu
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        fileDropAction(for: sender) == nil ? [] : .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        fileDropAction(for: sender) == nil ? [] : .copy
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        fileDropAction(for: sender) != nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let editingStore, let action = fileDropAction(for: sender) else {
            return false
        }

        switch action {
        case let .openPDF(url):
            return editingStore.loadDocument(from: url)
        case let .importImages(urls):
            return editingStore.importImages(from: urls) > 0
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard let editingStore else {
            super.mouseDown(with: event)
            return
        }

        let viewPoint = convert(event.locationInWindow, from: nil)

        if let page = page(for: viewPoint, nearest: false),
           PDFReaderInteractionPolicy.blocksFormInteraction(
               at: convert(viewPoint, to: page),
               on: page,
               workspaceMode: editingStore.workspaceMode
           ) {
            window?.makeFirstResponder(self)
            return
        }

        if !editingStore.canPerform(.annotate) {
            if let page = page(for: viewPoint, nearest: false),
               let hit = annotation(at: convert(viewPoint, to: page), on: page),
               !hit.hasSubtype(.link) {
                window?.makeFirstResponder(self)
                return
            }
            super.mouseDown(with: event)
            return
        }

        window?.makeFirstResponder(self)
        guard let page = page(for: viewPoint, nearest: false) else {
            editingStore.clearAnnotationSelection()
            super.mouseDown(with: event)
            return
        }

        let pagePoint = convert(viewPoint, to: page)
        guard let annotation = annotation(at: pagePoint, on: page) else {
            editingStore.clearAnnotationSelection()
            super.mouseDown(with: event)
            return
        }

        editingStore.selectAnnotation(annotation, on: page)
        draggedAnnotation = annotation
        draggedPage = page
        let updatedViewPoint = convert(event.locationInWindow, from: nil)
        dragStartPoint = convert(updatedViewPoint, to: page)
        dragStartBounds = annotation.bounds
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let editingStore,
              editingStore.canPerform(.annotate),
              let annotation = draggedAnnotation,
              let page = draggedPage else {
            super.mouseDragged(with: event)
            return
        }

        let viewPoint = convert(event.locationInWindow, from: nil)
        let pagePoint = convert(viewPoint, to: page)
        let proposedBounds = dragStartBounds.offsetBy(
            dx: pagePoint.x - dragStartPoint.x,
            dy: pagePoint.y - dragStartPoint.y
        )
        let constrainedBounds = editingStore.constrainedAnnotationBounds(proposedBounds, on: page)
        guard constrainedBounds != annotation.bounds else {
            return
        }

        guard editingStore.moveAnnotation(annotation, on: page, to: constrainedBounds) else { return }
        needsDisplay = true
        autoscroll(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if draggedAnnotation == nil {
            super.mouseUp(with: event)
        }

        draggedAnnotation = nil
        draggedPage = nil
    }

    override func keyDown(with event: NSEvent) {
        // PDFKit tab navigation may focus native widget editors. Supported
        // forms are edited through the accessible, guarded inspector controls.
        if event.keyCode == 48 { return }
        guard let editingStore,
              editingStore.canPerform(.annotate),
              editingStore.hasSelectedAnnotation else {
            super.keyDown(with: event)
            return
        }

        let step: CGFloat = event.modifierFlags.contains(.shift) ? 10 : 2
        switch event.keyCode {
        case 51, 117:
            editingStore.removeSelectedAnnotation()
        case 53:
            editingStore.clearAnnotationSelection()
        case 123:
            editingStore.moveSelectedAnnotationBy(x: -step, y: 0)
        case 124:
            editingStore.moveSelectedAnnotationBy(x: step, y: 0)
        case 125:
            editingStore.moveSelectedAnnotationBy(x: 0, y: -step)
        case 126:
            editingStore.moveSelectedAnnotationBy(x: 0, y: step)
        default:
            super.keyDown(with: event)
        }
    }

    override func drawPagePost(_ page: PDFPage, to context: CGContext) {
        super.drawPagePost(page, to: context)

        guard editingStore?.workspaceMode == .editing,
              let annotation = editingStore?.selectedAnnotation,
              annotation.page === page else {
            return
        }

        let selectionBounds = convert(annotation.bounds, from: page).insetBy(dx: -3, dy: -3)
        context.saveGState()
        context.setStrokeColor(NSColor.controlAccentColor.cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [6, 3])
        context.stroke(selectionBounds)
        context.restoreGState()
    }

    private func annotation(at point: CGPoint, on page: PDFPage) -> PDFAnnotation? {
        page.annotations.reversed().first { annotation in
            annotation.shouldDisplay
                && !annotation.hasSubtype(.widget)
                && !annotation.hasSubtype(.popup)
                && annotation.bounds.insetBy(dx: -2, dy: -2).contains(point)
        }
    }

    private func fileDropAction(for draggingInfo: NSDraggingInfo) -> PDFFileDropAction? {
        guard let editingStore else {
            return nil
        }

        let urls = draggingInfo.draggingPasteboard
            .readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            )?
            .compactMap { ($0 as? NSURL).map { $0 as URL } } ?? []

        return editingStore.fileDropAction(for: urls)
    }
}
