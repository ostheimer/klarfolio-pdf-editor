import PDFKit

/// A draft retains identity and original geometry so a stale sheet cannot edit
/// a replacement document, another page, or a page changed while it was open.
struct PDFCropSession: Identifiable {
    let id = UUID()
    let document: PDFDocument
    let page: PDFPage
    let pageIndex: Int
    let geometry: PDFCropGeometry
    let originalCrop: CGRect
    let originalRotation: Int
}
