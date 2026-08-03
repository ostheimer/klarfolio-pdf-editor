import PDFKit
import SwiftUI

struct PDFCanvasView: NSViewRepresentable {
    @ObservedObject var store: PDFDocumentStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
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
