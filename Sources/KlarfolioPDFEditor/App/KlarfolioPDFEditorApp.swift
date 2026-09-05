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
                .frame(
                    minWidth: store.workspaceMode == .reading ? 680 : 1120,
                    minHeight: store.workspaceMode == .reading ? 520 : 720
                )
                .onAppear {
                    appDelegate.register(documentStore: store)
                }
                .onOpenURL { url in
                    appDelegate.openExternalDocumentURLs([url])
                }
        }
        .commands {
            KlarfolioPDFEditorCommands(store: store)
        }

        Window("Datenschutz", id: "privacy") {
            PrivacyNoticeView()
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private weak var documentStore: PDFDocumentStore?
    private var terminationWasApproved = false
    private var pendingOpenURL: URL?
    private var activelyOpeningURL: URL?
    private var mostRecentExternalOpen: (url: URL, completedAt: Date)?
    private let duplicateExternalOpenInterval: TimeInterval = 0.5

    func register(documentStore: PDFDocumentStore) {
        self.documentStore = documentStore

        if let pendingOpenURL {
            self.pendingOpenURL = nil
            openExternalDocumentURLs([pendingOpenURL])
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard shouldCloseDocumentWindow() else {
            return .terminateCancel
        }

        terminationWasApproved = true
        return .terminateNow
    }

    func shouldCloseDocumentWindow() -> Bool {
        terminationWasApproved || documentStore?.confirmDiscardingUnsavedChanges() ?? true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        openExternalDocumentURLs([URL(fileURLWithPath: filename)])
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        openExternalDocumentURLs(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        openExternalDocumentURLs(urls)
    }

    @discardableResult
    func openExternalDocumentURLs(_ urls: [URL]) -> Bool {
        guard let url = urls.first(where: {
            $0.isFileURL && $0.pathExtension.lowercased() == "pdf"
        }) else {
            return false
        }

        guard let documentStore else {
            if pendingOpenURL == nil {
                pendingOpenURL = url
            }
            return false
        }

        let normalizedURL = url.standardizedFileURL
        guard activelyOpeningURL != normalizedURL else {
            return false
        }

        if let mostRecentExternalOpen,
           mostRecentExternalOpen.url == normalizedURL,
           Date().timeIntervalSince(mostRecentExternalOpen.completedAt) < duplicateExternalOpenInterval {
            return false
        }

        activelyOpeningURL = normalizedURL
        defer {
            activelyOpeningURL = nil
            mostRecentExternalOpen = (normalizedURL, Date())
        }

        return documentStore.loadDocument(from: url)
    }
}

struct KlarfolioPDFEditorCommands: Commands {
    @ObservedObject var store: PDFDocumentStore
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Neues PDF") {
                if store.createBlankDocument() {
                    store.setWorkspaceMode(.editing)
                }
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
            .disabled(!store.canPerform(.save))

            Button("Sichern unter …") {
                store.saveDocumentAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(!store.canPerform(.save))
        }

        CommandGroup(after: .saveItem) {
            Button("Fenster schließen") {
                (NSApp.keyWindow ?? NSApp.mainWindow)?.performClose(nil)
            }
            .keyboardShortcut("w")
            .accessibilityIdentifier("closeDocumentWindow")
        }

        CommandGroup(after: .toolbar) {
            Button(
                store.workspaceMode == .reading
                    ? "Bearbeitungsmodus einblenden"
                    : "Lesemodus aktivieren"
            ) {
                store.toggleWorkspaceMode()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }

        CommandMenu("PDF") {
            Button("Leere Seite einfügen") {
                store.addBlankPage()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!store.canPerform(.assemblePages))

            Button("Bilder als Seiten einfügen …") {
                store.importImagesAsPages()
            }
            .disabled(!store.canPerform(.assemblePages))

            Button("PDF zusammenführen …") {
                store.mergePDFs()
            }
            .disabled(!store.canPerform(.assemblePages))

            Button("Seiten extrahieren …") {
                store.extractPages()
            }
            .disabled(!store.canPerform(.exportPages))

            Button("Nach aktueller Seite teilen …") {
                store.splitDocumentAfterCurrentPage()
            }
            .disabled(
                !store.canPerform(.exportPages)
                    || store.pageCount < 2
                    || store.currentPageIndex >= store.pageCount - 1
            )

            Divider()

            Button("Auswahl hervorheben") {
                store.addMarkupAnnotation(.highlight)
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            .disabled(!store.canPerform(.annotate))

            Button("Textfeld einfügen") {
                store.addFreeTextAnnotation()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .disabled(!store.canPerform(.annotate))

            Button("Notiz einfügen") {
                store.addNoteAnnotation()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .disabled(!store.canPerform(.annotate))

            Button("Link einfügen") {
                store.addLinkAnnotation()
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .disabled(!store.canPerform(.annotate))

            Button("Ausgewählte Anmerkung löschen") {
                store.removeSelectedAnnotation()
            }
            .disabled(!store.hasSelectedAnnotation || !store.canPerform(.annotate))

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

        CommandGroup(after: .help) {
            Button("Datenschutz …") {
                openWindow(id: "privacy")
            }
        }
    }
}
