import AppKit
import PDFKit

enum PDFUtilities {
    static let defaultPageSize = CGSize(width: 612, height: 792)

    static func blankPage(size: CGSize = defaultPageSize) -> PDFPage? {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return PDFPage(image: image)
    }

    static func blankDocument() -> PDFDocument {
        let document = PDFDocument()
        if let page = blankPage() {
            document.insert(page, at: 0)
        }
        return document
    }

    static func pageSizeLabel(for page: PDFPage?) -> String {
        guard let page else {
            return "Keine Seite"
        }

        let bounds = page.bounds(for: .cropBox)
        let widthMillimeters = bounds.width * 0.352778
        let heightMillimeters = bounds.height * 0.352778
        return "\(Int(widthMillimeters.rounded())) x \(Int(heightMillimeters.rounded())) mm"
    }

    static func displayName(for url: URL?) -> String {
        url?.lastPathComponent ?? "Unbenannt.pdf"
    }
}
