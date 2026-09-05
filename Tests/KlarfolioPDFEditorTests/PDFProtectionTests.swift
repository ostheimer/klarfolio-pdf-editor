import AppKit
import KlarfolioPDFTestFixtures
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("PDF-Dokumentrechte")
struct PDFProtectionTests {
    @Test("Passwörter werden nicht in Preferences abgelegt; Eigentümerzugang hebt die Speichergrenze nicht auf")
    @MainActor
    func ownerUnlockDoesNotPersistPassword() throws {
        let name = "KlarfolioPasswordTests.\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: name))
        defer { preferences.removePersistentDomain(forName: name) }
        let store = PDFDocumentStore(preferences: preferences, passwordProvider: { _, _ in "klarfolio-test-owner" })
        #expect(store.loadDocument(from: PDFTestFixture.password.url))
        store.setWorkspaceMode(.editing)
        #expect(!store.canPerform(.save) && !store.canPerform(.annotate))
        let values = String(describing: preferences.persistentDomain(forName: name))
        #expect(!values.contains("klarfolio-test-owner") && !values.contains("klarfolio-test-open"))
    }

    @Test("Fehlgeschlagenes Speichern verhindert auch nach Passwortöffnung den Dokumentwechsel")
    @MainActor
    func failedSaveAfterUnlockPreservesDocument() {
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in .save },
                                     saveChangesHandler: { _ in false },
                                     passwordProvider: { _, _ in "klarfolio-test-open" })
        store.createBlankDocument()
        store.setWorkspaceMode(.editing)
        let original = store.document
        #expect(!store.loadDocument(from: PDFTestFixture.password.url))
        #expect(store.document === original && store.isDirty && store.workspaceMode == .editing)
    }

    @Test("Falsches Passwort erlaubt einen neuen Versuch und öffnet Reader-First")
    @MainActor
    func retryThenUnlock() throws {
        var retries: [Bool] = []
        let store = PDFDocumentStore(passwordProvider: { _, retry in
            retries.append(retry)
            return retry ? "klarfolio-test-open" : "wrong"
        })
        store.setWorkspaceMode(.editing)
        #expect(store.loadDocument(from: PDFTestFixture.password.url))
        #expect(retries == [false, true])
        #expect(store.document?.isLocked == false)
        #expect(store.document?.isEncrypted == true)
        #expect(store.pageCount == 3)
        #expect(store.workspaceMode == .reading)
        #expect(store.protection.readOnlyReason?.contains("Verschlüsseltes") == true)
        #expect(!store.statusMessage.contains("klarfolio-test-open"))
    }

    @Test("Falsches Passwort und Abbrechen bewahren Auswahl, Revision, Modus und Dirty-State")
    @MainActor
    func retryThenCancelKeepsSelection() throws {
        var tries = 0
        let store = PDFDocumentStore(passwordProvider: { _, _ in
            tries += 1
            return tries == 1 ? "wrong" : nil
        })
        store.createBlankDocument()
        store.setWorkspaceMode(.editing)
        store.addNoteAnnotation()
        let original = store.document
        let selected = store.selectedAnnotation
        let revision = store.revision
        #expect(!store.loadDocument(from: PDFTestFixture.password.url))
        #expect(store.document === original)
        #expect(store.selectedAnnotation === selected)
        #expect(store.revision == revision)
        #expect(store.isDirty)
        #expect(store.workspaceMode == .editing)
    }

    @Test("Erfolgreiches Entsperren respektiert danach Abbrechen im Dirty-Guard")
    @MainActor
    func unlockThenCancelReplacement() {
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in .cancel },
                                     passwordProvider: { _, _ in "klarfolio-test-open" })
        store.createBlankDocument()
        store.setWorkspaceMode(.editing)
        let original = store.document
        #expect(!store.loadDocument(from: PDFTestFixture.password.url))
        #expect(store.document === original)
        #expect(store.isDirty)
        #expect(store.workspaceMode == .editing)
    }

    @Test("Reentrante Passwortdialog-Rückmeldung ersetzt kein inzwischen gewechseltes Dokument")
    @MainActor
    func staleUnlockIsRejected() {
        var store: PDFDocumentStore!
        store = PDFDocumentStore(passwordProvider: { _, _ in
            store.document = PDFUtilities.blankDocument()
            return "klarfolio-test-open"
        })
        #expect(!store.loadDocument(from: PDFTestFixture.password.url))
        #expect(store.pageCount == 1)
        #expect(store.fileURL == nil)
    }

    @Test("Echte Signatur und negative Kontrollen werden strukturell unterschieden", arguments: [PDFTestFixture.signed, .emptySignature, .signaturePlaceholder, .interactiveForm])
    @MainActor
    func signatureControls(fixture: PDFTestFixture) throws {
        let store = PDFDocumentStore()
        #expect(store.loadDocument(from: fixture.url))
        #expect(store.protection.signature == (fixture == .signed ? .present : .none))
        store.setWorkspaceMode(.editing)
        #expect(store.canPerform(.annotate) == (fixture != .signed))
        #expect(store.canPerform(.save) == (fixture != .signed))
        #expect(!store.formFields.isEmpty)
    }

    @Test("Fehlerhafte Signaturstruktur bleibt konservativ schreibgeschützt")
    func malformedSignature() throws {
        let original = try Data(contentsOf: PDFTestFixture.signed.url)
        var data = original
        let marker = try #require(data.range(of: Data("/ByteRange".utf8)))
        data.replaceSubrange(marker, with: Data("/BadRange ".utf8))
        let document = try #require(PDFDocument(data: data))
        #expect(PDFDocumentProtection(document: document).signature == .uncertain)
        #expect(!PDFDocumentProtection(document: document).allows(.save))
    }

    @Test("PDFKit meldet Formular-, Kommentar- und Seitenrechte getrennt")
    func empiricalPermissionBits() throws {
        let form = PDFDocumentProtection(document: try #require(PDFDocument(url: PDFTestFixture.formOnly.url)))
        let comment = PDFDocumentProtection(document: try #require(PDFDocument(url: PDFTestFixture.commentOnly.url)))
        let assembly = PDFDocumentProtection(document: try #require(PDFDocument(url: PDFTestFixture.assemblyOnly.url)))
        #expect(form.allowsForms && !form.allowsAnnotations && !form.allowsAssembly)
        #expect(comment.allowsForms && comment.allowsAnnotations && !comment.allowsAssembly)
        #expect(assembly.allowsAssembly && !assembly.allowsForms && !assembly.allowsAnnotations)
        for protection in [form, comment, assembly] {
            #expect(!protection.allowsCopy && !protection.allowsPrint)
            #expect(!protection.allows(.save))
        }
    }

    @Test("Die Operationsmatrix trennt Rechte unabhängig von der konservativen Verschlüsselungsgrenze")
    func operationMatrix() {
        var policy = PDFDocumentProtection()
        policy.allowsForms = false
        policy.allowsAnnotations = false
        policy.allowsAssembly = false
        policy.allowsChanges = false
        policy.allowsCopy = false
        policy.allowsPrint = false
        #expect(PDFOperation.allCases.allSatisfy { !policy.allows($0) })
        policy.allowsForms = true
        #expect(policy.allows(.fillForms) && policy.allows(.save))
        #expect(!policy.allows(.annotate) && !policy.allows(.cropPage))
        policy.allowsAssembly = true
        #expect(policy.allows(.assemblePages) && !policy.allows(.exportPages))
        policy.allowsCopy = true
        #expect(policy.allows(.copy) && policy.allows(.exportPages))
        policy.isEncrypted = true
        #expect(policy.allows(.copy) && !policy.allows(.exportPages) && !policy.allows(.save))
    }

    @Test("Alle geschützten Mutations-, Formular-, Export- und Drop-Pfade erhalten die Quelle", arguments: [PDFTestFixture.restricted, .formOnly, .assemblyOnly, .commentOnly, .signed])
    @MainActor
    func protectedEntryPoints(fixture: PDFTestFixture) throws {
        let source = try Data(contentsOf: fixture.url)
        let store = PDFDocumentStore()
        #expect(store.loadDocument(from: fixture.url))
        store.setWorkspaceMode(.editing)
        let page = try #require(store.currentPage)
        let revision = store.revision
        let annotationCount = page.annotations.count
        let crop = page.bounds(for: .cropBox)
        let fieldValues = store.formFields.map(\.textValue)
        for field in store.formFields {
            #expect(!store.updateFormTextField(field.id, value: "Verboten"))
            #expect(!store.updateFormCheckbox(field.id, isOn: false))
        }
        for annotation in page.annotations {
            store.selectAnnotation(annotation, on: page)
            store.selectedAnnotationText = "Verboten"
            store.applySelectedAnnotationEdits()
            store.moveSelectedAnnotationBy(x: 12, y: 12)
            store.removeSelectedAnnotation()
            #expect(!store.moveAnnotation(annotation, on: page, to: annotation.bounds.offsetBy(dx: 10, dy: 0)))
        }
        store.addBlankPage(); store.deleteCurrentPage(); store.moveCurrentPage(by: 1)
        store.rotateCurrentPage(clockwise: true)
        store.addFreeTextAnnotation(); store.addNoteAnnotation(); store.addSignaturePlaceholder()
        store.addStamp(text: "Verboten"); store.addLinkAnnotation(); store.addMarkupAnnotation(.highlight)
        store.removeLastAnnotationOnCurrentPage()
        #expect(store.beginPageCrop() == nil)
        #expect(store.mergeDocuments(from: [PDFTestFixture.mergeTwoPages.url]) == 0)
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        #expect(!store.writePages(in: 0...0, to: output))
        #expect(!store.writeSplitDocument(afterPageAt: 0, firstPartURL: output, secondPartURL: output))
        #expect(!FileManager.default.fileExists(atPath: output.path))
        #expect(!store.saveDocumentAs()) // must return before opening a native panel
        let image = URL(fileURLWithPath: "/synthetic.png")
        #expect(store.fileDropAction(for: [image]) == nil)
        #expect(store.importImages(from: [image]) == 0)
        #expect(store.fileDropAction(for: [PDFTestFixture.password.url]) == .openPDF(PDFTestFixture.password.url))
        #expect(store.pageCount == 3 && store.revision == revision && !store.isDirty)
        #expect(page.rotation == 0 && page.bounds(for: .cropBox) == crop)
        #expect(page.annotations.count == annotationCount)
        #expect(store.formFields.map(\.textValue) == fieldValues)
        #expect(try Data(contentsOf: fixture.url) == source)
    }

    @Test("Geschützte Importquellen verursachen keinen teilweisen Merge", arguments: [PDFTestFixture.password, .restricted, .signed])
    @MainActor
    func protectedMergeSources(fixture: PDFTestFixture) {
        let store = PDFDocumentStore()
        store.createBlankDocument()
        store.setWorkspaceMode(.editing)
        let revision = store.revision
        #expect(store.mergeDocuments(from: [PDFTestFixture.mergeTwoPages.url, fixture.url]) == 0)
        #expect(store.pageCount == 1 && store.revision == revision)
        #expect(store.mergeDocuments(from: [PDFTestFixture.mergeTwoPages.url]) == 2)
        #expect(store.pageCount == 3)
    }

    @Test("Widget, fremde Annotation und verspäteter Drag umgehen den Store nicht")
    @MainActor
    func annotationIdentityAndMode() throws {
        let store = PDFDocumentStore()
        store.loadDocument(from: PDFTestFixture.interactiveForm.url)
        store.setWorkspaceMode(.editing)
        let page = try #require(store.currentPage)
        let widget = try #require(page.annotations.first { $0.hasSubtype(.widget) })
        store.selectAnnotation(widget)
        #expect(store.selectedAnnotation == nil)
        store.removeSelectedAnnotation()
        #expect(page.annotations.contains { $0 === widget })
        let note = try #require(page.annotations.first { $0.hasSubtype(.text) })
        store.selectAnnotation(note)
        let original = note.bounds
        store.setWorkspaceMode(.reading)
        #expect(!store.moveAnnotation(note, on: page, to: original.offsetBy(dx: 20, dy: 20)))
        #expect(note.bounds == original && !store.isDirty)
        store.setWorkspaceMode(.editing)
        store.loadDocument(from: PDFTestFixture.searchableThreePages.url)
        store.setWorkspaceMode(.editing)
        #expect(!store.moveAnnotation(note, on: page, to: original.offsetBy(dx: 20, dy: 20)))
    }

    @Test("PDFView blockiert direkte Copy-, Print- und Reset-Aktionen bei fehlendem Recht")
    @MainActor
    func nativeActions() throws {
        let store = PDFDocumentStore()
        store.loadDocument(from: PDFTestFixture.restricted.url)
        let view = AnnotationEditingPDFView()
        view.editingStore = store
        store.attach(pdfView: view)
        let page = try #require(store.currentPage)
        view.currentSelection = page.selection(for: page.bounds(for: .cropBox))
        let changeCount = NSPasteboard.general.changeCount
        view.copy(nil)
        #expect(NSPasteboard.general.changeCount == changeCount)
        #expect(!view.validateMenuItem(NSMenuItem(title: "Kopieren", action: #selector(view.copy(_:)), keyEquivalent: "c")))
        #expect(!view.validateMenuItem(NSMenuItem(title: "Drucken", action: #selector(view.printView(_:)), keyEquivalent: "p")))
        view.printView(nil)
        view.print(with: NSPrintInfo(), autoRotate: true)
        view.print(with: NSPrintInfo(), autoRotate: true, pageScaling: .pageScaleNone)
        view.perform(PDFActionResetForm())
        #expect(!store.isDirty)
    }

    @Test("Ein gewöhnliches dirty PDF kann auch nach Wechsel zum Lesen gespeichert werden")
    @MainActor
    func readerCanSavePriorEdits() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        try Data(contentsOf: PDFTestFixture.interactiveForm.url).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = PDFDocumentStore()
        store.loadDocument(from: url)
        store.setWorkspaceMode(.editing)
        store.addNoteAnnotation()
        store.setWorkspaceMode(.reading)
        #expect(store.isDirty && store.canPerform(.save))
        #expect(store.saveDocument())
        #expect(!store.isDirty)
    }

    @Test("Abgebrochene Passwortöffnung erhält dirty Dokument und Bearbeitungsmodus")
    @MainActor
    func cancelledPasswordPreservesDirtyDocument() throws {
        var discardPrompts = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            discardPrompts += 1
            return .discard
        }, passwordProvider: { _, _ in nil })
        store.createBlankDocument()
        store.setWorkspaceMode(.editing)
        let original = store.document
        #expect(!store.loadDocument(from: PDFTestFixture.password.url))
        #expect(store.document === original)
        #expect(store.isDirty)
        #expect(store.workspaceMode == .editing)
        #expect(discardPrompts == 0)
    }

    @Test("Signierte und verschlüsselte Dateien werden auch ohne Änderungen nicht neu gespeichert", arguments: [PDFTestFixture.signed, .restricted])
    @MainActor
    func noProtectedRewrite(fixture: PDFTestFixture) throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        let data = try Data(contentsOf: fixture.url)
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = PDFDocumentStore()
        #expect(store.loadDocument(from: url))
        #expect(!store.saveDocument())
        #expect(try Data(contentsOf: url) == data)
    }

    @Test("Direkte Store-Aufrufe ändern im Lesemodus keine Seiten oder Annotationen")
    @MainActor
    func readerDirectMutations() throws {
        let store = PDFDocumentStore()
        #expect(store.loadDocument(from: PDFTestFixture.interactiveForm.url))
        let page = try #require(store.currentPage)
        let annotations = page.annotations.count
        store.addBlankPage()
        store.rotateCurrentPage(clockwise: true)
        store.addNoteAnnotation()
        #expect(store.pageCount == 1)
        #expect(page.rotation == 0)
        #expect(page.annotations.count == annotations)
        #expect(!store.isDirty)
    }

    @Test("Geschützte und signierte Dokumente verhindern direkt aufgerufene Änderungen", arguments: [PDFTestFixture.restricted, .signed])
    @MainActor
    func protectedDirectMutations(fixture: PDFTestFixture) throws {
        let store = PDFDocumentStore()
        #expect(store.loadDocument(from: fixture.url))
        store.setWorkspaceMode(.editing)
        let page = try #require(store.currentPage)
        let count = store.pageCount
        let annotations = page.annotations.count
        store.rotateCurrentPage(clockwise: true)
        store.addNoteAnnotation()
        store.addBlankPage()
        #expect(store.pageCount == count)
        #expect(page.rotation == 0)
        #expect(page.annotations.count == annotations)
        #expect(!store.isDirty)
        #expect(store.documentByCopyingPages(in: 0...0) == nil)
    }
}
