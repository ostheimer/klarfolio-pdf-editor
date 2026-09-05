import Foundation
import KlarfolioPDFTestFixtures
import PDFKit
import Testing

@Suite("Synthetische CMS-Signaturintegrität")
struct PDFSignatureIntegrityTests {
    @Test("Die versionierte Signatur ist kryptografisch korrekt; geänderte Nutzdaten scheitern")
    func actualDetachedCMSSignature() throws {
        let data = try Data(contentsOf: PDFTestFixture.signed.url)
        let document = try #require(PDFDocument(data: data)?.documentRef)
        let catalog = try #require(document.catalog)
        var form: CGPDFDictionaryRef?
        #expect(CGPDFDictionaryGetDictionary(catalog, "AcroForm", &form))
        var fields: CGPDFArrayRef?
        #expect(CGPDFDictionaryGetArray(try #require(form), "Fields", &fields))
        let fieldArray = try #require(fields)
        var signature: CGPDFDictionaryRef?
        for index in 0..<CGPDFArrayGetCount(fieldArray) {
            var field: CGPDFDictionaryRef?
            if CGPDFArrayGetDictionary(fieldArray, index, &field), let field {
                var value: CGPDFDictionaryRef?
                if CGPDFDictionaryGetDictionary(field, "V", &value) { signature = value }
            }
        }
        let signatureDictionary = try #require(signature)
        var range: CGPDFArrayRef?
        var contents: CGPDFStringRef?
        #expect(CGPDFDictionaryGetArray(signatureDictionary, "ByteRange", &range))
        #expect(CGPDFDictionaryGetString(signatureDictionary, "Contents", &contents))
        let byteRange = try #require(range)
        var values = [CGPDFInteger](repeating: 0, count: 4)
        for index in 0..<4 { #expect(CGPDFArrayGetInteger(byteRange, index, &values[index])) }
        #expect(values[0] == 0 && values[2] + values[3] == data.count)
        let encoded = try #require(contents)
        let bytes = try #require(CGPDFStringGetBytePtr(encoded))
        let signatureData = Data(bytes: bytes, count: CGPDFStringGetLength(encoded))
        var signedContent = data[0..<values[1]] + data[values[2]..<data.count]
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let signatureURL = directory.appendingPathComponent("signature.der")
        let contentURL = directory.appendingPathComponent("content.bin")
        try signatureData.write(to: signatureURL)
        func verify() throws -> Int32 {
            try signedContent.write(to: contentURL)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
            process.arguments = ["cms", "-verify", "-binary", "-inform", "DER", "-in", signatureURL.path,
                                 "-content", contentURL.path, "-noverify", "-out", "/dev/null"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        }
        // Integrity verification deliberately excludes certificate trust.
        #expect(try verify() == 0)
        signedContent[10] ^= 1
        #expect(try verify() != 0)
    }
}
