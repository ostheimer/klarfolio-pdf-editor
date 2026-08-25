import Foundation
import UniformTypeIdentifiers

enum PDFFileDropAction: Equatable {
    case openPDF(URL)
    case importImages([URL])

    static func resolve(
        _ urls: [URL],
        workspaceMode: PDFWorkspaceMode
    ) -> PDFFileDropAction? {
        guard !urls.isEmpty, urls.allSatisfy(\.isFileURL) else {
            return nil
        }

        if urls.count == 1,
           let url = urls.first,
           fileType(for: url)?.conforms(to: .pdf) == true {
            return .openPDF(url)
        }

        guard workspaceMode == .editing,
              urls.allSatisfy({ fileType(for: $0)?.conforms(to: .image) == true }) else {
            return nil
        }

        return .importImages(urls)
    }

    private static func fileType(for url: URL) -> UTType? {
        guard !url.pathExtension.isEmpty else {
            return nil
        }

        return UTType(filenameExtension: url.pathExtension.lowercased())
    }
}
