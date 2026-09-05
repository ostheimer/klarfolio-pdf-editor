import Foundation

public enum PDFTestFixture: String, CaseIterable, Sendable {
    case searchableThreePages = "fixture-text-3-pages"
    case outlinedFourPages = "fixture-outline-4-pages"
    case croppedGeometryFourPages = "fixture-crop-4-pages"
    case mergeTwoPages = "fixture-merge-2-pages"
    case interactiveForm = "fixture-form"
    case invalidDocument = "fixture-invalid"
    case password = "fixture-password"
    case restricted = "fixture-restricted"
    case formOnly = "fixture-form-only"
    case assemblyOnly = "fixture-assembly-only"
    case commentOnly = "fixture-comment-only"
    case signed = "fixture-signed"
    case emptySignature = "fixture-empty-signature"
    case signaturePlaceholder = "fixture-signature-placeholder"

    public var url: URL {
        guard let resourceURL = Bundle.module.url(forResource: rawValue, withExtension: "pdf") else {
            preconditionFailure("Missing bundled PDF fixture: \(rawValue).pdf")
        }

        return resourceURL
    }
}
