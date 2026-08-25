struct PDFOutlineItem: Identifiable, Equatable {
    let id: String
    let title: String
    let pageIndex: Int?
    let children: [PDFOutlineItem]
}

struct PDFPageBookmark: Identifiable, Codable, Equatable {
    let id: String
    let pageIndex: Int
    let title: String
}
