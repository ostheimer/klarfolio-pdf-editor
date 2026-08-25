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
private final class AnnotationEditingPDFView: PDFView {
    weak var editingStore: PDFDocumentStore?

    private weak var draggedAnnotation: PDFAnnotation?
    private weak var draggedPage: PDFPage?
    private var dragStartPoint = CGPoint.zero
    private var dragStartBounds = CGRect.zero

    override var acceptsFirstResponder: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        guard let editingStore,
              editingStore.workspaceMode == .editing,
              editingStore.selectedTool == .select else {
            super.mouseDown(with: event)
            return
        }

        window?.makeFirstResponder(self)
        let viewPoint = convert(event.locationInWindow, from: nil)
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
              editingStore.workspaceMode == .editing,
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

        annotation.bounds = constrainedBounds
        annotationsChanged(on: page)
        needsDisplay = true
        autoscroll(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if let editingStore,
           editingStore.workspaceMode == .editing,
           let annotation = draggedAnnotation,
           let page = draggedPage {
            editingStore.annotationMoveDidFinish(
                annotation,
                on: page,
                from: dragStartBounds
            )
        } else {
            super.mouseUp(with: event)
        }

        draggedAnnotation = nil
        draggedPage = nil
    }

    override func keyDown(with event: NSEvent) {
        guard let editingStore,
              editingStore.workspaceMode == .editing,
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
}
