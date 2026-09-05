import PDFKit

enum PDFOperation: CaseIterable {
    case fillForms, annotate, assemblePages, cropPage, exportPages, save, copy, print
}

/// Independent of workspace mode: the same source rules also apply to imports.
struct PDFDocumentProtection {
    enum SignatureState { case none, present, uncertain }
    var isLocked = false
    var isEncrypted = false
    var signature: SignatureState = .none
    var allowsForms = true
    var allowsAnnotations = true
    var allowsAssembly = true
    var allowsChanges = true
    var allowsCopy = true
    var allowsPrint = true

    init() {}

    init(document: PDFDocument) {
        isLocked = document.isLocked
        isEncrypted = document.isEncrypted
        signature = Self.signatureState(in: document)
        allowsForms = document.allowsFormFieldEntry || document.allowsCommenting
        allowsAnnotations = document.allowsCommenting
        allowsAssembly = document.allowsDocumentAssembly
        allowsChanges = document.allowsDocumentChanges
        allowsCopy = document.allowsCopying
        allowsPrint = document.allowsPrinting
    }

    var readOnlyReason: String? {
        if isLocked { return "Dieses PDF ist gesperrt. Öffne es mit dem zugehörigen Passwort." }
        if signature == .present {
            return "Digital signiertes PDF: schreibgeschützt, damit die Signatur erhalten bleibt. Die Gültigkeit der Signatur wurde nicht geprüft."
        }
        if signature == .uncertain {
            return "Der Signaturstatus konnte nicht sicher bestimmt werden. Dieses PDF bleibt zum Schutz des Originals schreibgeschützt."
        }
        if isEncrypted {
            return "Verschlüsseltes PDF: schreibgeschützt. Klarfolio kann Passwortschutz und Berechtigungen beim Speichern derzeit nicht zuverlässig erhalten."
        }
        return nil
    }

    func allows(_ operation: PDFOperation) -> Bool {
        guard !isLocked else { return false }
        switch operation {
        case .copy: return allowsCopy
        case .print: return allowsPrint
        default: break
        }
        guard readOnlyReason == nil else { return false }
        switch operation {
        case .fillForms: return allowsForms
        case .annotate: return allowsAnnotations
        case .assemblePages: return allowsAssembly
        case .cropPage: return allowsChanges
        case .exportPages: return allowsCopy
        case .save: return allowsForms || allowsAnnotations || allowsAssembly || allowsChanges
        case .copy, .print: return false // handled above
        }
    }

    /// Structural detection only. Never regex-search content streams, validate
    /// certificates, or rewrite the document to inspect its signature fields.
    static func signatureState(in document: PDFDocument) -> SignatureState {
        guard !document.isLocked else { return .uncertain }
        // New in-memory PDFs have no source catalog and cannot contain an
        // existing byte-range signature. File-backed parse failures fail closed.
        guard let ref = document.documentRef, let catalog = ref.catalog else {
            return document.documentURL == nil ? .none : .uncertain
        }
        var visited = Set<CGPDFDictionaryRef>()
        var budget = 10_000
        var result: SignatureState = .none
        func dictionary(_ parent: CGPDFDictionaryRef, _ key: String) -> CGPDFDictionaryRef? {
            var value: CGPDFDictionaryRef?
            CGPDFDictionaryGetDictionary(parent, key, &value)
            return value
        }
        func name(_ parent: CGPDFDictionaryRef, _ key: String) -> String? {
            var value: UnsafePointer<CChar>?
            guard CGPDFDictionaryGetName(parent, key, &value), let value else { return nil }
            return String(cString: value)
        }
        func inspectSignature(_ value: CGPDFDictionaryRef) {
            var contents: CGPDFStringRef?
            var range: CGPDFArrayRef?
            if CGPDFDictionaryGetString(value, "Contents", &contents), let contents,
               CGPDFStringGetLength(contents) > 0,
               CGPDFDictionaryGetArray(value, "ByteRange", &range), let range,
               CGPDFArrayGetCount(range) == 4 {
                var offsets = [CGPDFInteger](repeating: 0, count: 4)
                let validRange = (0..<4).allSatisfy { CGPDFArrayGetInteger(range, $0, &offsets[$0]) }
                if validRange, offsets[0] == 0, offsets[1] > 0,
                   offsets[2] > offsets[1], offsets[3] > 0 {
                    result = .present
                } else if result != .present { result = .uncertain }
            } else if result != .present {
                result = .uncertain
            }
        }
        func visit(_ field: CGPDFDictionaryRef, inheritedType: String?, depth: Int) {
            guard result != .present else { return }
            guard budget > 0, depth < 64 else { result = .uncertain; return }
            budget -= 1
            guard visited.insert(field).inserted else { return }
            var type = name(field, "FT") ?? inheritedType
            var ancestor = dictionary(field, "Parent")
            var ancestors = Set<CGPDFDictionaryRef>()
            while type == nil, let parent = ancestor, ancestors.count < 64,
                  ancestors.insert(parent).inserted {
                type = name(parent, "FT")
                ancestor = dictionary(parent, "Parent")
            }
            if let value = dictionary(field, "V"), type == "Sig" || name(value, "Type") == "Sig" {
                inspectSignature(value)
            } else if type == "Sig" {
                var value: CGPDFObjectRef?
                if CGPDFDictionaryGetObject(field, "V", &value), let value,
                   CGPDFObjectGetType(value) != .null { result = .uncertain }
            }
            if let parent = dictionary(field, "Parent") {
                visit(parent, inheritedType: type, depth: depth + 1)
            }
            var kids: CGPDFArrayRef?
            if CGPDFDictionaryGetArray(field, "Kids", &kids), let kids {
                for index in 0..<min(CGPDFArrayGetCount(kids), 10_001) {
                    var child: CGPDFDictionaryRef?
                    if CGPDFArrayGetDictionary(kids, index, &child), let child {
                        visit(child, inheritedType: type, depth: depth + 1)
                    }
                }
            }
        }
        if let permissions = dictionary(catalog, "Perms"), let signature = dictionary(permissions, "DocMDP") {
            inspectSignature(signature)
        }
        if let form = dictionary(catalog, "AcroForm") {
            var fields: CGPDFArrayRef?
            if CGPDFDictionaryGetArray(form, "Fields", &fields), let fields {
                for index in 0..<min(CGPDFArrayGetCount(fields), 10_001) {
                    var field: CGPDFDictionaryRef?
                    if CGPDFArrayGetDictionary(fields, index, &field), let field {
                        visit(field, inheritedType: nil, depth: 0)
                    }
                }
            }
        }
        // Include orphan widgets and inherited field values, not just AcroForm.
        for pageIndex in 0..<document.pageCount {
            guard let page = ref.page(at: pageIndex + 1), let pageDictionary = page.dictionary else { continue }
            var annotations: CGPDFArrayRef?
            if CGPDFDictionaryGetArray(pageDictionary, "Annots", &annotations), let annotations {
                for index in 0..<min(CGPDFArrayGetCount(annotations), 10_001) {
                    var annotation: CGPDFDictionaryRef?
                    if CGPDFArrayGetDictionary(annotations, index, &annotation), let annotation {
                        visit(annotation, inheritedType: nil, depth: 0)
                    }
                }
            }
        }
        return result
    }
}
