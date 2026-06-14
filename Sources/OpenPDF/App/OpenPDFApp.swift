import AppKit
import SwiftUI

@main
struct OpenPDFApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PDFDocumentStore()

    var body: some Scene {
        WindowGroup("OpenPDF", id: "main") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1120, minHeight: 720)
        }
        .commands {
            OpenPDFCommands(store: store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

struct OpenPDFCommands: Commands {
    @ObservedObject var store: PDFDocumentStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Neues PDF") {
                store.createBlankDocument()
            }
            .keyboardShortcut("n")

            Button("Öffnen …") {
                store.openDocument()
            }
            .keyboardShortcut("o")
        }

        CommandGroup(replacing: .saveItem) {
            Button("Speichern") {
                store.saveDocument()
            }
            .keyboardShortcut("s")
            .disabled(!store.hasDocument)

            Button("Sichern unter …") {
                store.saveDocumentAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(!store.hasDocument)
        }

        CommandMenu("PDF") {
            Button("Leere Seite einfügen") {
                store.addBlankPage()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!store.hasDocument)

            Button("Bilder als Seiten einfügen …") {
                store.importImagesAsPages()
            }

            Button("PDF zusammenführen …") {
                store.mergePDFs()
            }

            Divider()

            Button("Auswahl hervorheben") {
                store.addMarkupAnnotation(.highlight)
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            .disabled(!store.hasDocument)

            Button("Textfeld einfügen") {
                store.addFreeTextAnnotation()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .disabled(!store.hasDocument)

            Button("Notiz einfügen") {
                store.addNoteAnnotation()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .disabled(!store.hasDocument)

            Divider()

            Button("Vergrößern") {
                store.zoomIn()
            }
            .keyboardShortcut("+")
            .disabled(!store.hasDocument)

            Button("Verkleinern") {
                store.zoomOut()
            }
            .keyboardShortcut("-")
            .disabled(!store.hasDocument)

            Button("An Fenster anpassen") {
                store.fitToWindow()
            }
            .keyboardShortcut("0")
            .disabled(!store.hasDocument)
        }
    }
}
