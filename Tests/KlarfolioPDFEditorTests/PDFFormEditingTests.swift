import Foundation
import KlarfolioPDFTestFixtures
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("Sichere PDF-Formularbearbeitung")
struct PDFFormEditingTests {
    @Test("Vorhandene Textfelder und Checkboxen werden vollständig erkannt")
    @MainActor
    func existingSupportedFormFieldsAreDiscovered() throws {
        let store = PDFDocumentStore()

        #expect(store.loadDocument(from: PDFTestFixture.interactiveForm.url))
        #expect(store.formFields.count == 2)

        let textField = try #require(store.formFields.first { $0.name == "KlarfolioName" })
        let checkbox = try #require(store.formFields.first { $0.name == "KlarfolioConsent" })

        #expect(textField.kind == .text)
        #expect(textField.title == "KlarfolioName")
        #expect(textField.pageIndex == 0)
        #expect(textField.textValue == "Andreas Test")
        #expect(!textField.isReadOnly)
        #expect(textField.maximumLength == 0)
        #expect(checkbox.kind == .checkbox)
        #expect(checkbox.pageIndex == 0)
        #expect(checkbox.isChecked)
        #expect(!checkbox.isReadOnly)
        #expect(!store.isDirty)
    }

    @Test("Der Lesemodus blockiert Text- und Checkboxänderungen im Store")
    @MainActor
    func readingModeRejectsAllFormMutations() throws {
        let store = try makeFormStore()
        let textField = try formField(named: "KlarfolioName", in: store)
        let checkbox = try formField(named: "KlarfolioConsent", in: store)
        let originalRevision = store.revision
        let originalStatus = store.statusMessage

        #expect(store.workspaceMode == .reading)
        #expect(!store.updateFormTextField(textField.id, value: "Unerlaubte Änderung"))
        #expect(!store.updateFormCheckbox(checkbox.id, isOn: false))
        #expect(store.formFields.first { $0.id == textField.id }?.textValue == "Andreas Test")
        #expect(store.formFields.first { $0.id == checkbox.id }?.isChecked == true)
        #expect(store.revision == originalRevision)
        #expect(store.statusMessage == originalStatus)
        #expect(!store.isDirty)
    }

    @Test("Eine Texteingabe aktualisiert Widget, Feldmodell, Status und Dirty-State")
    @MainActor
    func editingTextUpdatesDocumentAndDirtyState() throws {
        let store = try makeFormStore(mode: .editing)
        let field = try formField(named: "KlarfolioName", in: store)
        let initialRevision = store.revision

        #expect(store.updateFormTextField(field.id, value: "Geprüfter Wert mit Größe"))
        #expect(store.formFields.first { $0.id == field.id }?.textValue == "Geprüfter Wert mit Größe")
        #expect(try annotation(named: "KlarfolioName", in: store).widgetStringValue == "Geprüfter Wert mit Größe")
        #expect(store.isDirty)
        #expect(store.revision == initialRevision + 1)
        #expect(store.statusMessage == "Formularfeld „KlarfolioName“ aktualisiert")
    }

    @Test("Checkboxänderungen aktualisieren PDFKit und markieren das Dokument")
    @MainActor
    func editingCheckboxUpdatesPDFKitAndDirtyState() throws {
        let store = try makeFormStore(mode: .editing)
        let field = try formField(named: "KlarfolioConsent", in: store)
        let initialRevision = store.revision

        #expect(store.updateFormCheckbox(field.id, isOn: false))
        #expect(store.formFields.first { $0.id == field.id }?.isChecked == false)
        #expect(try annotation(named: "KlarfolioConsent", in: store).buttonWidgetState == .offState)
        #expect(store.isDirty)
        #expect(store.revision == initialRevision + 1)
        #expect(store.statusMessage == "Checkbox „KlarfolioConsent“ aktualisiert")
    }

    @Test("Identische Text- und Checkboxwerte erzeugen keinen falschen Dirty-State")
    @MainActor
    func identicalFormValuesAreSafeNoOperations() throws {
        let store = try makeFormStore(mode: .editing)
        let textField = try formField(named: "KlarfolioName", in: store)
        let checkbox = try formField(named: "KlarfolioConsent", in: store)
        let initialRevision = store.revision
        let initialStatus = store.statusMessage

        #expect(!store.updateFormTextField(textField.id, value: "Andreas Test"))
        #expect(!store.updateFormCheckbox(checkbox.id, isOn: true))
        #expect(!store.isDirty)
        #expect(store.revision == initialRevision)
        #expect(store.statusMessage == initialStatus)
    }

    @Test("Ungültige Feldkennungen und vertauschte Feldtypen werden zurückgewiesen")
    @MainActor
    func invalidIdentifiersAndMismatchedFieldTypesAreRejected() throws {
        let store = try makeFormStore(mode: .editing)
        let textField = try formField(named: "KlarfolioName", in: store)
        let checkbox = try formField(named: "KlarfolioConsent", in: store)

        #expect(!store.updateFormTextField("nicht-vorhanden", value: "Nein"))
        #expect(!store.updateFormCheckbox("nicht-vorhanden", isOn: true))
        #expect(!store.updateFormTextField(checkbox.id, value: "Falscher Typ"))
        #expect(!store.updateFormCheckbox(textField.id, isOn: false))
        #expect(!store.isDirty)
        #expect(try annotation(named: "KlarfolioName", in: store).widgetStringValue == "Andreas Test")
        #expect(try annotation(named: "KlarfolioConsent", in: store).buttonWidgetState == .onState)
    }

    @Test("Schreibgeschützte Textfelder und Checkboxen bleiben unveränderbar")
    @MainActor
    func readOnlyFormFieldsRemainImmutable() throws {
        let store = try makeFormStore(mode: .editing)
        let page = try #require(store.document?.page(at: 0))
        for annotation in page.annotations where annotation.hasSubtype(.widget) {
            annotation.isReadOnly = true
        }
        store.rotateCurrentPage(clockwise: true)
        store.isDirty = false

        let textField = try formField(named: "KlarfolioName", in: store)
        let checkbox = try formField(named: "KlarfolioConsent", in: store)

        #expect(textField.isReadOnly)
        #expect(checkbox.isReadOnly)
        #expect(!store.updateFormTextField(textField.id, value: "Nicht erlaubt"))
        #expect(!store.updateFormCheckbox(checkbox.id, isOn: false))
        #expect(!store.isDirty)
    }

    @Test("Nachträglich gesetzter Widget-Schreibschutz kann den Store nicht umgehen")
    @MainActor
    func dynamicallyLockedWidgetCannotBypassStoreValidation() throws {
        let store = try makeFormStore(mode: .editing)
        let field = try formField(named: "KlarfolioName", in: store)
        let widget = try annotation(named: "KlarfolioName", in: store)
        widget.isReadOnly = true

        #expect(!store.updateFormTextField(field.id, value: "Nicht erlaubt"))
        #expect(widget.widgetStringValue == "Andreas Test")
        #expect(!store.isDirty)
    }

    @Test("Die hinterlegte maximale Formulartextlänge wird eingehalten")
    @MainActor
    func configuredMaximumLengthIsEnforced() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let fixtureURL = try makeCustomizedFixture(in: temporaryDirectory) { document in
            let page = try #require(document.page(at: 0))
            let widget = try #require(page.annotations.first { $0.fieldName == "KlarfolioName" })
            widget.maximumLength = 5
            widget.widgetStringValue = "Alt"
        }

        let store = try makeFormStore(url: fixtureURL, mode: .editing)
        let field = try formField(named: "KlarfolioName", in: store)

        #expect(field.maximumLength == 5)
        #expect(store.updateFormTextField(field.id, value: "Äpfel und Birnen"))
        #expect(store.formFields.first { $0.id == field.id }?.textValue == "Äpfel")
        #expect(try annotation(named: "KlarfolioName", in: store).widgetStringValue == "Äpfel")
    }

    @Test("Ein auf den bestehenden Wert gekürzter Text erzeugt keine Änderung")
    @MainActor
    func truncationToExistingValueIsNotMarkedDirty() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let fixtureURL = try makeCustomizedFixture(in: temporaryDirectory) { document in
            let page = try #require(document.page(at: 0))
            let widget = try #require(page.annotations.first { $0.fieldName == "KlarfolioName" })
            widget.maximumLength = 3
            widget.widgetStringValue = "ABC"
        }

        let store = try makeFormStore(url: fixtureURL, mode: .editing)
        let field = try formField(named: "KlarfolioName", in: store)

        #expect(!store.updateFormTextField(field.id, value: "ABCDE"))
        #expect(!store.isDirty)
        #expect(field.textValue == "ABC")
    }

    @Test("Passwortfelder werden nie im Klartext in Formularmodelle übernommen")
    @MainActor
    func passwordWidgetsAreNeverExposed() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let fixtureURL = try makeCustomizedFixture(in: temporaryDirectory) { document in
            let page = try #require(document.page(at: 0))
            let widget = try #require(page.annotations.first { $0.fieldName == "KlarfolioName" })
            widget.widgetStringValue = "Geheimes Testkennwort"
            #expect(widget.setValue(NSNumber(value: 1 << 13), forAnnotationKey: .widgetFieldFlags))
            #expect(widget.isPasswordField)
        }

        let store = try makeFormStore(url: fixtureURL, mode: .editing)

        #expect(!store.formFields.contains { $0.name == "KlarfolioName" })
        #expect(!store.formFields.contains { $0.textValue.contains("Geheimes Testkennwort") })
        #expect(store.formFields.count == 1)
        #expect(store.formFields.first?.kind == .checkbox)
    }

    @Test("Radiobuttons werden nicht als eigenständige Checkboxen angeboten")
    @MainActor
    func radioButtonWidgetsAreNotTreatedAsCheckboxes() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let fixtureURL = try makeCustomizedFixture(in: temporaryDirectory) { document in
            let page = try #require(document.page(at: 0))
            let widget = try #require(page.annotations.first { $0.fieldName == "KlarfolioConsent" })
            widget.widgetControlType = .radioButtonControl
        }

        let store = try makeFormStore(url: fixtureURL, mode: .editing)

        #expect(!store.formFields.contains { $0.name == "KlarfolioConsent" })
        #expect(store.formFields.count == 1)
        #expect(store.formFields.first?.kind == .text)
    }

    @Test("Push-Buttons werden nicht als Formular-Checkboxen angeboten")
    @MainActor
    func pushButtonsAreNotTreatedAsCheckboxes() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let fixtureURL = try makeCustomizedFixture(in: temporaryDirectory) { document in
            let page = try #require(document.page(at: 0))
            let widget = try #require(page.annotations.first { $0.fieldName == "KlarfolioConsent" })
            widget.widgetControlType = .pushButtonControl
        }

        let store = try makeFormStore(url: fixtureURL, mode: .editing)

        #expect(!store.formFields.contains { $0.name == "KlarfolioConsent" })
        #expect(store.formFields.count == 1)
    }

    @Test("Auswahlfelder werden nicht als unterstützte Formulartextfelder angeboten")
    @MainActor
    func choiceWidgetsAreExcludedFromSupportedFields() throws {
        let store = try makeFormStore(mode: .editing)
        let widget = try annotation(named: "KlarfolioName", in: store)
        widget.widgetFieldType = .choice
        store.rotateCurrentPage(clockwise: true)

        #expect(!store.formFields.contains { $0.name == "KlarfolioName" })
        #expect(store.formFields.count == 1)
        #expect(store.formFields.first?.kind == .checkbox)
    }

    @Test("Text- und Checkboxwerte überstehen Speichern und erneutes Öffnen")
    @MainActor
    func textAndCheckboxValuesPersistAfterSaving() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let sourceData = try Data(contentsOf: PDFTestFixture.interactiveForm.url)
        let writableURL = temporaryDirectory.appendingPathComponent("Ausgefülltes Formular.pdf")
        try FileManager.default.copyItem(at: PDFTestFixture.interactiveForm.url, to: writableURL)
        let store = try makeFormStore(url: writableURL, mode: .editing)
        let textField = try formField(named: "KlarfolioName", in: store)
        let checkbox = try formField(named: "KlarfolioConsent", in: store)

        #expect(store.updateFormTextField(textField.id, value: "Gespeicherter Wert – Größe 42"))
        #expect(store.updateFormCheckbox(checkbox.id, isOn: false))
        #expect(store.isDirty)
        #expect(store.saveDocument())
        #expect(!store.isDirty)

        let reloaded = PDFDocumentStore()
        #expect(reloaded.loadDocument(from: writableURL))
        #expect(try formField(named: "KlarfolioName", in: reloaded).textValue == "Gespeicherter Wert – Größe 42")
        #expect(try formField(named: "KlarfolioConsent", in: reloaded).isChecked == false)
        #expect(reloaded.document?.page(at: 0)?.annotations.contains { $0.hasSubtype(.text) } == true)
        #expect(try Data(contentsOf: PDFTestFixture.interactiveForm.url) == sourceData)
    }

    @Test("Beide Checkboxzustände bleiben nach wiederholtem Speichern erhalten")
    @MainActor
    func checkboxPersistsBothOffAndOnStates() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let writableURL = temporaryDirectory.appendingPathComponent("Checkbox.pdf")
        try FileManager.default.copyItem(at: PDFTestFixture.interactiveForm.url, to: writableURL)
        let store = try makeFormStore(url: writableURL, mode: .editing)
        let field = try formField(named: "KlarfolioConsent", in: store)

        #expect(store.updateFormCheckbox(field.id, isOn: false))
        #expect(store.saveDocument())
        let uncheckedDocument = try #require(PDFDocument(url: writableURL))
        #expect(uncheckedDocument.page(at: 0)?.annotations.first {
            $0.fieldName == "KlarfolioConsent"
        }?.buttonWidgetState == .offState)

        #expect(store.updateFormCheckbox(field.id, isOn: true))
        #expect(store.saveDocument())
        let checkedDocument = try #require(PDFDocument(url: writableURL))
        #expect(checkedDocument.page(at: 0)?.annotations.first {
            $0.fieldName == "KlarfolioConsent"
        }?.buttonWidgetState == .onState)
    }

    @Test("Dokumentwechsel entfernt veraltete Formularfelder vollständig")
    @MainActor
    func replacingTheDocumentRefreshesFormFields() throws {
        let store = try makeFormStore()
        let previousField = try formField(named: "KlarfolioName", in: store)

        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))
        #expect(store.formFields.isEmpty)

        store.setWorkspaceMode(.editing)
        #expect(!store.updateFormTextField(previousField.id, value: "Veraltetes Feld"))
        #expect(!store.isDirty)
    }

    @Test("Abbrechen schützt ein ungespeichertes Formular vor Dokumentwechsel")
    @MainActor
    func cancellationPreservesDirtyFormValues() throws {
        let store = try makeFormStore(mode: .editing, unsavedChangesDecisionProvider: { _ in .cancel })
        let field = try formField(named: "KlarfolioName", in: store)
        #expect(store.updateFormTextField(field.id, value: "Nicht verwerfen"))

        #expect(!store.loadDocument(from: PDFTestFixture.searchableThreePages.url))
        #expect(store.fileURL == PDFTestFixture.interactiveForm.url)
        #expect(try formField(named: "KlarfolioName", in: store).textValue == "Nicht verwerfen")
        #expect(store.isDirty)
    }

    @Test("Speichern vor dem Dokumentwechsel sichert ausgefüllte Formularwerte")
    @MainActor
    func replacementWarningSavesPendingFormValues() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let writableURL = temporaryDirectory.appendingPathComponent("Vor Wechsel speichern.pdf")
        try FileManager.default.copyItem(at: PDFTestFixture.interactiveForm.url, to: writableURL)
        let store = try makeFormStore(
            url: writableURL,
            mode: .editing,
            unsavedChangesDecisionProvider: { _ in .save }
        )
        let field = try formField(named: "KlarfolioName", in: store)
        #expect(store.updateFormTextField(field.id, value: "Vor dem Wechsel gesichert"))

        #expect(store.loadDocument(from: PDFTestFixture.searchableThreePages.url))
        #expect(store.formFields.isEmpty)
        #expect(!store.isDirty)

        let savedDocument = try #require(PDFDocument(url: writableURL))
        #expect(savedDocument.page(at: 0)?.annotations.first {
            $0.fieldName == "KlarfolioName"
        }?.widgetStringValue == "Vor dem Wechsel gesichert")
    }

    @Test("Mehrfach vorkommende Feldnamen besitzen getrennte stabile Identitäten")
    @MainActor
    func duplicateFieldNamesHaveDistinctIdentitiesAndPages() throws {
        let store = try makeFormStore(mode: .editing)
        try addDuplicateTextFieldPage(to: store)
        let duplicatedFields = store.formFields.filter { $0.name == "KlarfolioName" }

        #expect(duplicatedFields.count == 2)
        #expect(Set(duplicatedFields.map(\.id)).count == 2)
        #expect(Set(duplicatedFields.map(\.pageIndex)) == [0, 1])

        let secondField = try #require(duplicatedFields.first { $0.pageIndex == 1 })
        store.goToFormField(secondField.id)
        #expect(store.currentPageIndex == 1)
    }

    @Test("Seitenverschiebungen und Löschungen aktualisieren Formularzuordnungen")
    @MainActor
    func pageMovesAndDeletionRefreshFormFieldLocations() throws {
        let store = try makeFormStore(mode: .editing)
        store.addBlankPage()
        store.goToPage(0)
        store.moveCurrentPage(by: 1)

        #expect(try formField(named: "KlarfolioName", in: store).pageIndex == 1)
        #expect(try formField(named: "KlarfolioConsent", in: store).pageIndex == 1)

        store.goToPage(0)
        store.deleteCurrentPage()
        #expect(try formField(named: "KlarfolioName", in: store).pageIndex == 0)
        #expect(try formField(named: "KlarfolioConsent", in: store).pageIndex == 0)
    }

    @Test("Wechsel in den Lesemodus schützt bereits geänderte Formularwerte")
    @MainActor
    func switchingToReadingRetainsDirtyValueButRejectsFurtherChanges() throws {
        let store = try makeFormStore(mode: .editing)
        let field = try formField(named: "KlarfolioName", in: store)
        #expect(store.updateFormTextField(field.id, value: "Bereits geändert"))

        store.setWorkspaceMode(.reading)

        #expect(!store.updateFormTextField(field.id, value: "Unerlaubter Nachtrag"))
        #expect(try formField(named: "KlarfolioName", in: store).textValue == "Bereits geändert")
        #expect(store.isDirty)
    }

    @MainActor
    private func makeFormStore(
        url: URL = PDFTestFixture.interactiveForm.url,
        mode: PDFWorkspaceMode = .reading,
        unsavedChangesDecisionProvider: ((PDFDocumentStore) -> PDFDocumentStore.UnsavedChangesDecision)? = nil
    ) throws -> PDFDocumentStore {
        let suiteName = "KlarfolioPDFFormEditingTests-\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        preferences.removePersistentDomain(forName: suiteName)
        let store = PDFDocumentStore(
            preferences: preferences,
            unsavedChangesDecisionProvider: unsavedChangesDecisionProvider
        )
        #expect(store.loadDocument(from: url))
        store.setWorkspaceMode(mode)
        return store
    }

    @MainActor
    private func formField(named name: String, in store: PDFDocumentStore) throws -> PDFFormField {
        try #require(store.formFields.first { $0.name == name })
    }

    @MainActor
    private func annotation(named name: String, in store: PDFDocumentStore) throws -> PDFAnnotation {
        try #require(store.document?.page(at: 0)?.annotations.first { $0.fieldName == name })
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlarfolioFormEditingTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeCustomizedFixture(
        in directory: URL,
        customize: (PDFDocument) throws -> Void
    ) throws -> URL {
        let document = try #require(PDFDocument(url: PDFTestFixture.interactiveForm.url))
        try customize(document)
        let outputURL = directory.appendingPathComponent("Angepasstes Formular.pdf")
        #expect(document.write(to: outputURL))
        return outputURL
    }

    @MainActor
    private func addDuplicateTextFieldPage(
        to store: PDFDocumentStore,
        named name: String = "KlarfolioName"
    ) throws {
        store.addBlankPage()
        let page = try #require(store.currentPage)
        let field = PDFAnnotation(
            bounds: CGRect(x: 72, y: 620, width: 220, height: 30),
            forType: .widget,
            withProperties: nil
        )
        field.widgetFieldType = .text
        field.fieldName = name
        field.widgetStringValue = "Wert auf der zweiten Seite"
        page.addAnnotation(field)
        store.rotateCurrentPage(clockwise: true)
    }
}
