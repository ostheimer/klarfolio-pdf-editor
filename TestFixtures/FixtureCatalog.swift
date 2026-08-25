import Foundation

public enum PDFTestFixture: String, CaseIterable, Sendable {
    case searchableThreePages = "fixture-text-3-pages"
    case mergeTwoPages = "fixture-merge-2-pages"
    case interactiveForm = "fixture-form"
    case invalidDocument = "fixture-invalid"

    public var url: URL {
        guard let resourceURL = Bundle.module.url(forResource: rawValue, withExtension: "pdf") else {
            preconditionFailure("Missing bundled PDF fixture: \(rawValue).pdf")
        }

        return resourceURL
    }
}
