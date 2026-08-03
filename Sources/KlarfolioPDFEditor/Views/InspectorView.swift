import SwiftUI

struct InspectorView: View {
    @ObservedObject var store: PDFDocumentStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                toolSection
                annotationSection
                pageSection
                documentSection
            }
            .padding(16)
        }
        .background(.regularMaterial)
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

            Button(role: .destructive) {
                store.removeLastAnnotationOnCurrentPage()
            } label: {
                Label("Letzte Anmerkung löschen", systemImage: "trash")
            }
            .disabled(!store.hasDocument)
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
