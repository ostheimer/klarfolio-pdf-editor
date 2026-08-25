import AppKit
import KlarfolioPDFTestFixtures
import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("Dokumentsicherheit")
struct DocumentSafetyTests {
    @Test("Unveränderte Dokumente benötigen keine Sicherheitsabfrage")
    @MainActor
    func cleanDocumentsSkipUnsavedChangesConfirmation() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let sourceURL = try makePDF(in: temporaryDirectory, named: "Original.pdf")
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .cancel
        })

        #expect(store.confirmDiscardingUnsavedChanges())
        #expect(store.loadDocument(from: sourceURL))
        #expect(!store.isDirty)
        #expect(store.confirmDiscardingUnsavedChanges())
        #expect(store.createBlankDocument())
        #expect(confirmationCount == 0)
    }

    @Test("Abbrechen verhindert das Erstellen eines neuen Dokuments")
    @MainActor
    func cancellingNewDocumentPreservesUnsavedChanges() throws {
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .cancel
        })
        #expect(store.createBlankDocument())
        store.addFreeTextAnnotation(text: "Diese Änderung muss erhalten bleiben")

        let originalDocument = try #require(store.document)
        let originalAnnotation = try #require(store.selectedAnnotation)
        let originalRevision = store.revision
        let originalStatus = store.statusMessage

        #expect(!store.createBlankDocument())
        #expect(store.document === originalDocument)
        #expect(store.selectedAnnotation === originalAnnotation)
        #expect(store.pageCount == 1)
        #expect(store.isDirty)
        #expect(store.revision == originalRevision)
        #expect(store.statusMessage == originalStatus)
        #expect(confirmationCount == 1)
    }

    @Test("Abbrechen verhindert das Öffnen eines anderen PDFs")
    @MainActor
    func cancellingOpenDocumentPreservesUnsavedChanges() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let replacementURL = try makePDF(in: temporaryDirectory, named: "Anderes Dokument.pdf")
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in .cancel })
        #expect(store.createBlankDocument())
        store.addBlankPage()

        let originalDocument = try #require(store.document)
        let originalRevision = store.revision
        let originalStatus = store.statusMessage

        #expect(!store.loadDocument(from: replacementURL))
        #expect(store.document === originalDocument)
        #expect(store.fileURL == nil)
        #expect(store.pageCount == 2)
        #expect(store.currentPageIndex == 1)
        #expect(store.isDirty)
        #expect(store.revision == originalRevision)
        #expect(store.statusMessage == originalStatus)
    }

    @Test("Verwerfen ermöglicht das Erstellen eines neuen Dokuments")
    @MainActor
    func discardingUnsavedChangesAllowsNewDocument() throws {
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .discard
        })
        #expect(store.createBlankDocument())
        store.addFreeTextAnnotation(text: "Darf verworfen werden")
        let originalDocument = try #require(store.document)

        #expect(store.createBlankDocument())
        #expect(store.document !== originalDocument)
        #expect(store.pageCount == 1)
        #expect(store.currentPage?.annotations.isEmpty == true)
        #expect(store.fileURL == nil)
        #expect(store.isDirty)
        #expect(store.statusMessage == "Neues PDF erstellt")
        #expect(confirmationCount == 1)
    }

    @Test("Verwerfen ermöglicht das Öffnen eines anderen PDFs")
    @MainActor
    func discardingUnsavedChangesAllowsOpeningAnotherDocument() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let replacementURL = try makePDF(in: temporaryDirectory, named: "Ersatz.pdf")
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in .discard })
        #expect(store.createBlankDocument())
        store.addBlankPage()

        #expect(store.loadDocument(from: replacementURL))
        #expect(store.fileURL == replacementURL)
        #expect(store.pageCount == 1)
        #expect(!store.isDirty)
        #expect(store.statusMessage == "Ersatz.pdf geöffnet")
    }

    @Test("Speichern schreibt Änderungen vor dem Dokumentwechsel tatsächlich auf die Festplatte")
    @MainActor
    func savingBeforeReplacementWritesChangesToDisk() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let originalURL = try makePDF(in: temporaryDirectory, named: "Original.pdf")
        let replacementURL = try makePDF(in: temporaryDirectory, named: "Ersatz.pdf")
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .save
        })
        #expect(store.loadDocument(from: originalURL))
        store.addBlankPage()

        #expect(store.isDirty)
        #expect(PDFDocument(url: originalURL)?.pageCount == 1)
        #expect(store.loadDocument(from: replacementURL))
        #expect(PDFDocument(url: originalURL)?.pageCount == 2)
        #expect(store.fileURL == replacementURL)
        #expect(store.pageCount == 1)
        #expect(!store.isDirty)
        #expect(confirmationCount == 1)
    }

    @Test("Formularänderungen werden vor einem Dokumentwechsel vollständig gespeichert")
    @MainActor
    func savingBeforeReplacementPersistsTextAndCheckboxValues() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let sourceURL = temporaryDirectory.appendingPathComponent("Ausgefülltes Formular.pdf")
        let replacementURL = try makePDF(in: temporaryDirectory, named: "Nächstes Dokument.pdf")
        try FileManager.default.copyItem(at: PDFTestFixture.interactiveForm.url, to: sourceURL)

        let suiteName = "at.ostheimer.klarfoliopdf.DocumentSafety.\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        var confirmationCount = 0
        let store = PDFDocumentStore(preferences: preferences, unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .save
        })
        store.setWorkspaceMode(.editing)
        #expect(store.loadDocument(from: sourceURL))

        let textField = try #require(store.formFields.first { $0.name == "KlarfolioName" })
        let checkbox = try #require(store.formFields.first { $0.name == "KlarfolioConsent" })
        #expect(store.updateFormTextField(textField.id, value: "Vor dem Wechsel gesichert"))
        #expect(store.updateFormCheckbox(checkbox.id, isOn: false))

        let unsavedDocument = try #require(PDFDocument(url: sourceURL))
        #expect(unsavedDocument.page(at: 0)?.annotations.first {
            $0.fieldName == "KlarfolioName"
        }?.widgetStringValue == "Andreas Test")

        #expect(store.loadDocument(from: replacementURL))

        let savedDocument = try #require(PDFDocument(url: sourceURL))
        let savedPage = try #require(savedDocument.page(at: 0))
        #expect(savedPage.annotations.first {
            $0.fieldName == "KlarfolioName"
        }?.widgetStringValue == "Vor dem Wechsel gesichert")
        #expect(savedPage.annotations.first {
            $0.fieldName == "KlarfolioConsent"
        }?.buttonWidgetState == .offState)
        #expect(store.fileURL == replacementURL)
        #expect(store.formFields.isEmpty)
        #expect(!store.isDirty)
        #expect(confirmationCount == 1)
    }

    @Test("Abbrechen schützt ungespeicherte Formularwerte auch im Lesemodus")
    @MainActor
    func cancellingClosePreservesUnsavedFormsAfterSwitchingToReadingMode() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let sourceURL = temporaryDirectory.appendingPathComponent("Geschütztes Formular.pdf")
        try FileManager.default.copyItem(at: PDFTestFixture.interactiveForm.url, to: sourceURL)

        let suiteName = "at.ostheimer.klarfoliopdf.DocumentSafety.\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        var confirmationCount = 0
        let store = PDFDocumentStore(preferences: preferences, unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .cancel
        })
        store.setWorkspaceMode(.editing)
        #expect(store.loadDocument(from: sourceURL))

        let textField = try #require(store.formFields.first { $0.name == "KlarfolioName" })
        #expect(store.updateFormTextField(textField.id, value: "Noch nicht gespeichert"))
        store.setWorkspaceMode(.reading)

        let delegate = AppDelegate()
        delegate.register(documentStore: store)

        #expect(!delegate.shouldCloseDocumentWindow())
        #expect(store.workspaceMode == .reading)
        #expect(store.isDirty)
        #expect(store.formFields.first { $0.id == textField.id }?.textValue == "Noch nicht gespeichert")
        #expect(PDFDocument(url: sourceURL)?.page(at: 0)?.annotations.first {
            $0.fieldName == "KlarfolioName"
        }?.widgetStringValue == "Andreas Test")
        #expect(confirmationCount == 1)
    }

    @Test("Fehlgeschlagenes Speichern schützt Formularwerte vor Finder-Dokumentwechsel")
    @MainActor
    func failedFormSaveBlocksExternalDocumentReplacement() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let sourceURL = temporaryDirectory.appendingPathComponent("Ungesichertes Formular.pdf")
        let replacementURL = try makePDF(in: temporaryDirectory, named: "Finder-Ersatz.pdf")
        try FileManager.default.copyItem(at: PDFTestFixture.interactiveForm.url, to: sourceURL)

        let suiteName = "at.ostheimer.klarfoliopdf.DocumentSafety.\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        var saveAttemptCount = 0
        let store = PDFDocumentStore(
            preferences: preferences,
            unsavedChangesDecisionProvider: { _ in .save },
            saveChangesHandler: { _ in
                saveAttemptCount += 1
                return false
            }
        )
        store.setWorkspaceMode(.editing)
        #expect(store.loadDocument(from: sourceURL))

        let checkbox = try #require(store.formFields.first { $0.name == "KlarfolioConsent" })
        #expect(store.updateFormCheckbox(checkbox.id, isOn: false))

        let delegate = AppDelegate()
        delegate.register(documentStore: store)

        #expect(!delegate.openExternalDocumentURLs([replacementURL]))
        #expect(store.fileURL == sourceURL)
        #expect(store.isDirty)
        #expect(store.formFields.first { $0.id == checkbox.id }?.isChecked == false)
        #expect(PDFDocument(url: sourceURL)?.page(at: 0)?.annotations.first {
            $0.fieldName == "KlarfolioConsent"
        }?.buttonWidgetState == .onState)
        #expect(saveAttemptCount == 1)
    }

    @Test("Abgebrochenes oder fehlgeschlagenes Speichern verhindert den Dokumentwechsel")
    @MainActor
    func failedSavePreventsDocumentReplacement() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let replacementURL = try makePDF(in: temporaryDirectory, named: "Ersatz.pdf")
        var saveAttemptCount = 0
        let store = PDFDocumentStore(
            unsavedChangesDecisionProvider: { _ in .save },
            saveChangesHandler: { _ in
                saveAttemptCount += 1
                return false
            }
        )
        #expect(store.createBlankDocument())
        store.addBlankPage()
        let originalDocument = try #require(store.document)

        #expect(!store.loadDocument(from: replacementURL))
        #expect(store.document === originalDocument)
        #expect(store.fileURL == nil)
        #expect(store.pageCount == 2)
        #expect(store.isDirty)
        #expect(saveAttemptCount == 1)
    }

    @Test("Ein angeblich erfolgreiches Speichern mit verbleibenden Änderungen wird zurückgewiesen")
    @MainActor
    func saveMustAlsoClearDirtyStateBeforeReplacement() throws {
        let store = PDFDocumentStore(
            unsavedChangesDecisionProvider: { _ in .save },
            saveChangesHandler: { _ in true }
        )
        #expect(store.createBlankDocument())
        let originalDocument = try #require(store.document)

        #expect(!store.confirmDiscardingUnsavedChanges())
        #expect(store.document === originalDocument)
        #expect(store.isDirty)
    }

    @Test("Erfolgreiches Speichern erlaubt das sichere Schließen eines Dokuments")
    @MainActor
    func successfulInjectedSaveAllowsLifecycleConfirmation() {
        let store = PDFDocumentStore(
            unsavedChangesDecisionProvider: { _ in .save },
            saveChangesHandler: { store in
                store.isDirty = false
                return true
            }
        )
        #expect(store.createBlankDocument())

        #expect(store.confirmDiscardingUnsavedChanges())
        #expect(!store.isDirty)
    }

    @Test("Das Schließen eines Fensters respektiert eine abgebrochene Sicherheitsabfrage")
    @MainActor
    func applicationDelegateRejectsWindowCloseWhenUserCancels() {
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .cancel
        })
        #expect(store.createBlankDocument())
        let delegate = AppDelegate()
        delegate.register(documentStore: store)

        #expect(!delegate.shouldCloseDocumentWindow())
        #expect(store.hasDocument)
        #expect(store.isDirty)
        #expect(confirmationCount == 1)
    }

    @Test("Das Schließen eines Fensters erlaubt ausdrücklich verworfene Änderungen")
    @MainActor
    func applicationDelegateAllowsWindowCloseWhenUserDiscardsChanges() {
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .discard
        })
        #expect(store.createBlankDocument())
        let delegate = AppDelegate()
        delegate.register(documentStore: store)

        #expect(delegate.shouldCloseDocumentWindow())
        #expect(confirmationCount == 1)
    }

    @Test("Das Schließen eines Fensters wird bei fehlgeschlagenem Speichern verhindert")
    @MainActor
    func applicationDelegateRejectsWindowCloseWhenSavingFails() {
        var saveAttemptCount = 0
        let store = PDFDocumentStore(
            unsavedChangesDecisionProvider: { _ in .save },
            saveChangesHandler: { _ in
                saveAttemptCount += 1
                return false
            }
        )
        #expect(store.createBlankDocument())
        let delegate = AppDelegate()
        delegate.register(documentStore: store)

        #expect(!delegate.shouldCloseDocumentWindow())
        #expect(store.isDirty)
        #expect(saveAttemptCount == 1)
    }

    @Test("Ein unverändertes Dokument darf ohne Sicherheitsabfrage geschlossen werden")
    @MainActor
    func applicationDelegateAllowsCleanDocumentWindowToClose() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let sourceURL = try makePDF(in: temporaryDirectory, named: "Unverändert.pdf")
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .cancel
        })
        #expect(store.loadDocument(from: sourceURL))
        let delegate = AppDelegate()
        delegate.register(documentStore: store)

        #expect(delegate.shouldCloseDocumentWindow())
        #expect(confirmationCount == 0)
    }

    @Test("Finder-Dateien vor dem App-Start werden genau einmal nachgereicht")
    @MainActor
    func queuedExternalDocumentOpensExactlyOnceAfterRegistration() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let firstURL = try makePDF(in: temporaryDirectory, named: "Erstes Finder-Dokument.pdf")
        let ignoredURL = try makePDF(in: temporaryDirectory, named: "Weiteres Finder-Dokument.pdf")
        let delegate = AppDelegate()
        let store = PDFDocumentStore()

        #expect(!delegate.openExternalDocumentURLs([firstURL]))
        #expect(!delegate.openExternalDocumentURLs([ignoredURL]))
        #expect(!store.hasDocument)

        delegate.register(documentStore: store)
        let loadedDocument = try #require(store.document)

        #expect(store.fileURL == firstURL)
        #expect(store.pageCount == 1)
        #expect(!store.isDirty)

        delegate.register(documentStore: store)
        #expect(store.document === loadedDocument)
        #expect(store.fileURL == firstURL)
    }

    @Test("Doppelte Finder-Zustellung fragt nach Abbrechen nicht erneut")
    @MainActor
    func duplicateExternalOpenAfterCancellationShowsOnlyOneConfirmation() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let replacementURL = try makePDF(in: temporaryDirectory, named: "Doppelt zugestellt.pdf")
        let equivalentURL = URL(
            fileURLWithPath: temporaryDirectory.path + "/./" + replacementURL.lastPathComponent
        )
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .cancel
        })
        #expect(store.createBlankDocument())
        let originalDocument = try #require(store.document)
        let delegate = AppDelegate()
        delegate.register(documentStore: store)

        #expect(!delegate.openExternalDocumentURLs([replacementURL]))
        #expect(!delegate.openExternalDocumentURLs([equivalentURL]))
        #expect(confirmationCount == 1)
        #expect(store.document === originalDocument)
        #expect(store.fileURL == nil)
        #expect(store.isDirty)
    }

    @Test("Reentrante Finder-Zustellungen können keinen zweiten Dialog öffnen")
    @MainActor
    func reentrantExternalOpenCannotPresentAnotherConfirmation() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let replacementURL = try makePDF(in: temporaryDirectory, named: "Reentrant.pdf")
        let delegate = AppDelegate()
        var confirmationCount = 0
        var reentrantResult: Bool?
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            reentrantResult = delegate.openExternalDocumentURLs([replacementURL])
            return .cancel
        })
        #expect(store.createBlankDocument())
        let originalDocument = try #require(store.document)
        delegate.register(documentStore: store)

        #expect(!delegate.openExternalDocumentURLs([replacementURL]))
        #expect(reentrantResult == false)
        #expect(confirmationCount == 1)
        #expect(store.document === originalDocument)
        #expect(store.isDirty)
    }

    @Test("Externe Öffnungen ignorieren entfernte und fachfremde Dateien")
    @MainActor
    func externalOpenRejectsRemoteURLsAndUnsupportedTypes() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let imageURL = try makeImage(in: temporaryDirectory, named: "Kein Dokument.png")
        let remoteURL = try #require(URL(string: "https://example.invalid/Dokument.pdf"))
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .discard
        })
        #expect(store.createBlankDocument())
        let originalDocument = try #require(store.document)
        let delegate = AppDelegate()
        delegate.register(documentStore: store)

        #expect(!delegate.openExternalDocumentURLs([remoteURL, imageURL]))
        #expect(!delegate.openExternalDocumentURLs([]))
        #expect(confirmationCount == 0)
        #expect(store.document === originalDocument)
        #expect(store.isDirty)
    }

    @Test("Ungültige PDFs lösen keine unnötige Verwerfungsabfrage aus")
    @MainActor
    func invalidReplacementDoesNotAskToDiscardUnsavedChanges() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let invalidURL = temporaryDirectory.appendingPathComponent("Defekt.pdf")
        try Data("Das ist keine PDF-Datei".utf8).write(to: invalidURL)
        var confirmationCount = 0
        let store = PDFDocumentStore(unsavedChangesDecisionProvider: { _ in
            confirmationCount += 1
            return .discard
        })
        #expect(store.createBlankDocument())
        store.addBlankPage()
        let originalDocument = try #require(store.document)

        #expect(!store.loadDocument(from: invalidURL))
        #expect(store.document === originalDocument)
        #expect(store.pageCount == 2)
        #expect(store.isDirty)
        #expect(store.statusMessage == "Die Datei konnte nicht geöffnet werden.")
        #expect(confirmationCount == 0)
    }

    @Test("Speichern ohne geöffnetes Dokument meldet keinen Erfolg")
    @MainActor
    func savingWithoutDocumentFailsSafely() {
        let store = PDFDocumentStore()

        #expect(!store.saveDocument())
        #expect(!store.saveDocumentAs())
        #expect(!store.hasDocument)
    }

    @Test("Bilder werden ohne Dialog als neue PDF-Seiten übernommen")
    @MainActor
    func importingImagesAppendsPagesWithoutOpeningAPanel() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let firstImageURL = try makeImage(in: temporaryDirectory, named: "Erstes Bild.png")
        let secondImageURL = try makeImage(in: temporaryDirectory, named: "Zweites Bild.png")
        let store = PDFDocumentStore()
        #expect(store.createBlankDocument())

        #expect(store.importImages(from: [firstImageURL, secondImageURL]) == 2)
        #expect(store.pageCount == 3)
        #expect(store.currentPageIndex == 1)
        #expect(store.isDirty)
        #expect(store.statusMessage == "2 Bildseiten eingefügt")
    }

    @Test("Bildimport kann ohne bestehendes PDF ein neues Dokument aufbauen")
    @MainActor
    func importingImageCreatesDocumentWhenNeeded() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let imageURL = try makeImage(in: temporaryDirectory, named: "Einzelbild.png")
        let store = PDFDocumentStore()

        #expect(store.importImages(from: [imageURL]) == 1)
        #expect(store.pageCount == 1)
        #expect(store.currentPageIndex == 0)
        #expect(store.isDirty)
        #expect(store.statusMessage == "1 Bildseiten eingefügt")
    }

    @Test("Leere und unlesbare Bildlisten verändern bestehende Seiten nicht")
    @MainActor
    func emptyAndInvalidImageImportsDoNotAddPages() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let invalidImageURL = temporaryDirectory.appendingPathComponent("Defekt.png")
        try Data("kein Bild".utf8).write(to: invalidImageURL)
        let store = PDFDocumentStore()

        #expect(store.importImages(from: []) == 0)
        #expect(!store.hasDocument)

        #expect(store.createBlankDocument())
        #expect(store.importImages(from: [invalidImageURL]) == 0)
        #expect(store.pageCount == 1)
        #expect(store.statusMessage == "Keine lesbaren Bilder gefunden.")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlarfolioDocumentSafetyTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makePDF(in directory: URL, named name: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        let document = PDFUtilities.blankDocument()
        try #require(document.write(to: url))
        return url
    }

    private func makeImage(in directory: URL, named name: String) throws -> URL {
        let bitmap = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: 24,
                pixelsHigh: 18,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        )
        bitmap.setColor(NSColor(deviceRed: 0.2, green: 0.4, blue: 0.8, alpha: 1), atX: 0, y: 0)
        let imageData = try #require(bitmap.representation(using: .png, properties: [:]))
        let url = directory.appendingPathComponent(name)
        try imageData.write(to: url)
        return url
    }
}
