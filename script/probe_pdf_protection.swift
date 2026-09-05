import Foundation
import PDFKit

// Run: swift script/probe_pdf_protection.swift TestFixtures
// Only public, synthetic fixture passwords are used; never pass user documents.
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: temporary) }
for name in ["password", "restricted", "form-only", "assembly-only", "comment-only", "signed"] {
    let document = PDFDocument(url: root.appendingPathComponent("fixture-\(name).pdf"))!
    print(name, "locked", document.isLocked, "encrypted", document.isEncrypted)
    if document.isLocked {
        print("wrong unlock", document.unlock(withPassword: "wrong"))
        print("correct unlock", document.unlock(withPassword: "klarfolio-test-open"))
    }
    print("copy/print/form/comment/assembly/change", document.allowsCopying, document.allowsPrinting,
          document.allowsFormFieldEntry, document.allowsCommenting, document.allowsDocumentAssembly,
          document.allowsDocumentChanges)
    document.page(at: 0)!.rotation = 90
    let output = temporary.appendingPathComponent(name + ".pdf")
    print("write", document.write(to: output))
    let reopened = PDFDocument(url: output)!
    print("reopened locked/encrypted", reopened.isLocked, reopened.isEncrypted)
    for candidate in ["", "klarfolio-test-open", "klarfolio-test-owner"] {
        print("reopen unlock empty/user/owner", candidate.isEmpty ? "empty" : (candidate.hasSuffix("open") ? "user" : "owner"),
              reopened.unlock(withPassword: candidate), reopened.permissionsStatus.rawValue)
    }
    print("reopened permissions", reopened.accessPermissions.rawValue, "original", document.accessPermissions.rawValue)
}
