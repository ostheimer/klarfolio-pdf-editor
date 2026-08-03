import AppKit
import SwiftUI

@main
struct KlarfolioPDFEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PDFDocumentStore()

    var body: some Scene {
        WindowGroup("Klarfolio PDF Editor", id: "main") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1120, minHeight: 720)
                .onAppear {
                    openExternalDocumentURLs(AppDelegate.consumePendingOpenURLs())
                }
                .onReceive(NotificationCenter.default.publisher(for: .klarfolioOpenDocumentURLs)) { notification in
                    guard let urls = notification.userInfo?[AppDelegate.openURLsUserInfoKey] as? [URL] else {
                        return
                    }
                    openExternalDocumentURLs(urls)
                }
                .onOpenURL { url in
                    openExternalDocumentURLs([url])
                }
        }
        .commands {
            KlarfolioPDFEditorCommands(store: store)
        }
    }

    private func openExternalDocumentURLs(_ urls: [URL]) {
        guard let url = urls.first(where: { $0.pathExtension.lowercased() == "pdf" }) else {
            return
        }

        store.loadDocument(from: url)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let openURLsUserInfoKey = "urls"
    private static var pendingOpenURLs: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        enqueueOpenFiles([filename])
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        enqueueOpenURLs(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        enqueueOpenURLs(urls)
    }

    static func consumePendingOpenURLs() -> [URL] {
        let urls = pendingOpenURLs
        pendingOpenURLs.removeAll()
        return urls
    }

    private func enqueueOpenFiles(_ filenames: [String]) {
        enqueueOpenURLs(filenames.map { URL(fileURLWithPath: $0) })
    }

    private func enqueueOpenURLs(_ urls: [URL]) {
        Self.pendingOpenURLs.append(contentsOf: urls)
        NotificationCenter.default.post(
            name: .klarfolioOpenDocumentURLs,
            object: nil,
            userInfo: [Self.openURLsUserInfoKey: urls]
        )
    }
}

extension Notification.Name {
    static let klarfolioOpenDocumentURLs = Notification.Name("KlarfolioPDFEditorOpenDocumentURLs")
}

struct KlarfolioPDFEditorCommands: Commands {
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
