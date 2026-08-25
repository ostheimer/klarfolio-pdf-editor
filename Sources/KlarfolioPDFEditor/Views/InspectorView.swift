import SwiftUI

struct InspectorView: View {
    @ObservedObject var store: PDFDocumentStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if store.workspaceMode == .editing, !store.formFields.isEmpty {
                    formSection
                    Divider()
                }

                toolSection
                annotationSection
                selectedAnnotationSection
                pageSection
                documentSection
            }
            .padding(16)
        }
        .background(.regularMaterial)
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Formularfelder")
                .font(.headline)

            Text("Fülle vorhandene Formularfelder sicher über diesen Bereich aus.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(store.formFields) { field in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(field.title)
                            .font(.subheadline.weight(.semibold))

                        Spacer(minLength: 4)

                        Button("Seite \(field.pageIndex + 1)") {
                            store.goToFormField(field.id)
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier(
                            accessibilityFormFieldIdentifier(for: field, prefix: "formFieldPage")
                        )
                    }

                    formControl(for: field)

                    if field.kind == .text, field.maximumLength > 0 {
                        Text("Maximal \(field.maximumLength) Zeichen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if field.isReadOnly {
                        Label("Schreibgeschützt", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("formFieldsSection")
    }

    @ViewBuilder
    private func formControl(for field: PDFFormField) -> some View {
        switch field.kind {
        case .text:
            TextField(
                "Text eingeben",
                text: Binding(
                    get: {
                        store.formFields.first { $0.id == field.id }?.textValue ?? ""
                    },
                    set: { value in
                        store.updateFormTextField(field.id, value: value)
                    }
                )
            )
            .textFieldStyle(.roundedBorder)
            .disabled(field.isReadOnly || store.workspaceMode != .editing)
            .accessibilityLabel(field.title)
            .accessibilityIdentifier(
                accessibilityFormFieldIdentifier(for: field, prefix: "formText")
            )

        case .checkbox:
            Toggle(
                "Ausgewählt",
                isOn: Binding(
                    get: {
                        store.formFields.first { $0.id == field.id }?.isChecked ?? false
                    },
                    set: { isOn in
                        store.updateFormCheckbox(field.id, isOn: isOn)
                    }
                )
            )
            .toggleStyle(.checkbox)
            .disabled(field.isReadOnly || store.workspaceMode != .editing)
            .accessibilityLabel(field.title)
            .accessibilityIdentifier(
                accessibilityFormFieldIdentifier(for: field, prefix: "formCheckbox")
            )
        }
    }

    private func accessibilityFormFieldIdentifier(
        for field: PDFFormField,
        prefix: String
    ) -> String {
        let baseIdentifier = "\(prefix).\(field.name)"
        guard store.formFields.filter({ $0.name == field.name }).count > 1 else {
            return baseIdentifier
        }

        let stableFieldIdentifier = field.id.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : "_"
        }.joined()

        return "\(baseIdentifier).\(field.pageIndex + 1).\(stableFieldIdentifier)"
    }

    private var toolSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Werkzeug")
                .font(.headline)

            Picker("Werkzeug", selection: $store.selectedTool) {
                ForEach(PDFInteractionTool.allCases) { tool in
                    Label(tool.title, systemImage: tool.symbolName)
                        .tag(tool)
                }
            }
            .pickerStyle(.menu)

            Picker("Farbe", selection: $store.annotationColor) {
                ForEach(AnnotationSwatch.allCases) { swatch in
                    Label(swatch.title, systemImage: "circle.fill")
                        .foregroundStyle(swatch.swiftUIColor)
                        .tag(swatch)
                }
            }
            .pickerStyle(.menu)

            Stepper(value: $store.fontSize, in: 9...36, step: 1) {
                Text("Schriftgröße \(Int(store.fontSize)) pt")
            }
        }
    }

    private var annotationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Anmerkungen")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    Button {
                        store.addFreeTextAnnotation()
                    } label: {
                        Label("Textfeld", systemImage: "textformat")
                    }

                    Button {
                        store.addNoteAnnotation()
                    } label: {
                        Label("Notiz", systemImage: "note.text")
                    }
                }

                GridRow {
                    Button {
                        store.addMarkupAnnotation(.highlight)
                    } label: {
                        Label("Marker", systemImage: "highlighter")
                    }

                    Button {
                        store.addMarkupAnnotation(.underline)
                    } label: {
                        Label("Unterstreichen", systemImage: "underline")
                    }
                }

                GridRow {
                    Button {
                        store.addMarkupAnnotation(.strikeOut)
                    } label: {
                        Label("Durchstreichen", systemImage: "strikethrough")
                    }

                    Button {
                        store.addSignaturePlaceholder()
                    } label: {
                        Label("Signaturfeld", systemImage: "signature")
                    }
                }
            }
            .buttonStyle(.bordered)
            .disabled(!store.hasDocument)

            Menu {
                Button("Genehmigt") {
                    store.addStamp(text: "Genehmigt")
                }

                Button("Entwurf") {
                    store.addStamp(text: "Entwurf")
                }

                Button("Vertraulich") {
                    store.addStamp(text: "Vertraulich")
                }
            } label: {
                Label("Stempel einfügen", systemImage: "seal")
            }
            .disabled(!store.hasDocument)

            Divider()

            Text("Link hinzufügen")
                .font(.subheadline.weight(.semibold))

            linkTargetControls

            Button {
                store.addLinkAnnotation()
            } label: {
                Label("Link-Bereich anlegen", systemImage: "link.badge.plus")
            }
            .disabled(!store.hasDocument)

            Text("Markierter Text wird verlinkt; ohne Textauswahl entsteht ein verschiebbarer Link-Bereich in der Seitenmitte.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                store.removeLastAnnotationOnCurrentPage()
            } label: {
                Label("Letzte Anmerkung löschen", systemImage: "trash")
            }
            .disabled(!store.hasDocument)
        }
    }

    @ViewBuilder
    private var selectedAnnotationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ausgewählte Anmerkung")
                .font(.headline)

            if store.hasSelectedAnnotation {
                LabeledContent("Typ", value: store.selectedAnnotationTypeTitle)
                if let pageIndex = store.selectedAnnotationPageIndex {
                    LabeledContent("Seite", value: "\(pageIndex + 1)")
                }

                TextField("Inhalt oder Kommentar", text: $store.selectedAnnotationText)
                    .textFieldStyle(.roundedBorder)

                if store.selectedAnnotationIsLink {
                    linkTargetControls
                }

                HStack(spacing: 6) {
                    Button {
                        store.moveSelectedAnnotationBy(x: -4, y: 0)
                    } label: {
                        Label("Nach links", systemImage: "arrow.left")
                    }

                    Button {
                        store.moveSelectedAnnotationBy(x: 0, y: -4)
                    } label: {
                        Label("Nach unten", systemImage: "arrow.down")
                    }

                    Button {
                        store.moveSelectedAnnotationBy(x: 0, y: 4)
                    } label: {
                        Label("Nach oben", systemImage: "arrow.up")
                    }

                    Button {
                        store.moveSelectedAnnotationBy(x: 4, y: 0)
                    } label: {
                        Label("Nach rechts", systemImage: "arrow.right")
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)

                HStack(spacing: 8) {
                    Button {
                        store.applySelectedAnnotationEdits()
                    } label: {
                        Label("Änderungen anwenden", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        store.removeSelectedAnnotation()
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            } else {
                Text("Werkzeug „Auswahl“ aktivieren und eine vorhandene Anmerkung anklicken. Danach kann sie gezogen, mit Pfeiltasten verschoben, bearbeitet oder gelöscht werden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var linkTargetControls: some View {
        Picker("Ziel", selection: $store.linkTargetMode) {
            ForEach(PDFLinkTargetMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)

        switch store.linkTargetMode {
        case .website:
            TextField("https://example.com", text: $store.linkURLString)
                .textFieldStyle(.roundedBorder)
        case .page:
            Stepper(
                "Zielseite \(store.linkDestinationPage)",
                value: $store.linkDestinationPage,
                in: 1...max(store.pageCount, 1)
            )
        }
    }

    private var pageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Seiten")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    Button {
                        store.addBlankPage()
                    } label: {
                        Label("Leere Seite", systemImage: "doc.badge.plus")
                    }

                    Button {
                        store.importImagesAsPages()
                    } label: {
                        Label("Bilder", systemImage: "photo.on.rectangle")
                    }
                }

                GridRow {
                    Button {
                        store.rotateCurrentPage(clockwise: false)
                    } label: {
                        Label("Links drehen", systemImage: "rotate.left")
                    }

                    Button {
                        store.rotateCurrentPage(clockwise: true)
                    } label: {
                        Label("Rechts drehen", systemImage: "rotate.right")
                    }
                }

                GridRow {
                    Button {
                        store.moveCurrentPage(by: -1)
                    } label: {
                        Label("Nach oben", systemImage: "arrow.up")
                    }
                    .disabled(store.currentPageIndex <= 0)

                    Button {
                        store.moveCurrentPage(by: 1)
                    } label: {
                        Label("Nach unten", systemImage: "arrow.down")
                    }
                    .disabled(store.currentPageIndex >= store.pageCount - 1)
                }
            }
            .buttonStyle(.bordered)

            Button {
                store.mergePDFs()
            } label: {
                Label("PDF zusammenführen", systemImage: "square.stack.3d.up")
            }

            Button(role: .destructive) {
                store.deleteCurrentPage()
            } label: {
                Label("Aktuelle Seite löschen", systemImage: "trash")
            }
            .disabled(store.pageCount <= 1)

            Divider()

            Text("Seiten extrahieren")
                .font(.subheadline.weight(.semibold))

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    TextField("Von", value: $store.extractionStartPage, format: .number)
                        .textFieldStyle(.roundedBorder)
                    TextField("Bis", value: $store.extractionEndPage, format: .number)
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Button("Aktuelle Seite") {
                        store.useCurrentPageForExtraction()
                    }

                    Button {
                        store.extractPages()
                    } label: {
                        Label("Extrahieren …", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .disabled(!store.hasDocument)

            Button {
                store.splitDocumentAfterCurrentPage()
            } label: {
                Label("Nach aktueller Seite teilen …", systemImage: "rectangle.split.2x1")
            }
            .disabled(store.pageCount < 2 || store.currentPageIndex >= store.pageCount - 1)
        }
    }

    private var documentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dokument")
                .font(.headline)

            LabeledContent("Name", value: store.documentTitle)
            LabeledContent("Seiten", value: "\(store.pageCount)")
            LabeledContent("Aktuelle Seite", value: "\(min(store.currentPageIndex + 1, max(store.pageCount, 1)))")

            HStack(spacing: 8) {
                Button {
                    store.saveDocument()
                } label: {
                    Label("Speichern", systemImage: "square.and.arrow.down")
                }
                .disabled(!store.hasDocument)

                Button {
                    store.saveDocumentAs()
                } label: {
                    Label("Sichern unter", systemImage: "square.and.arrow.down.on.square")
                }
                .disabled(!store.hasDocument)
            }
        }
    }
}
