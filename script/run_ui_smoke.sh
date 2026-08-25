#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    "usage: $0 --app /absolute/path/to/Klarfolio.app [--require-ui|--allow-headless]" \
    "" \
    "Launches the app and verifies the real macOS accessibility tree:" \
    "  - the initial reduced reading mode" \
    "  - opening the versioned three-page PDF fixture" \
    "  - showing and hiding sidebar, inspector, and status bar" \
    "  - dirty-state visibility and protection for New, Close, and Quit" \
    "  - restoring editing mode after an application restart" \
    "" \
    "--require-ui fails when no graphical session or accessibility access exists." \
    "--allow-headless reports an explicit skipped UI check in that situation."
}

app_bundle=""
allow_headless=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      if [[ $# -lt 2 ]]; then
        usage >&2
        exit 2
      fi
      app_bundle="$2"
      shift 2
      ;;
    --require-ui)
      allow_headless=0
      shift
      ;;
    --allow-headless)
      allow_headless=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'error: unsupported argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$app_bundle" ]]; then
  printf 'error: --app is required\n' >&2
  usage >&2
  exit 2
fi

if [[ ! -d "$app_bundle" || ! -f "$app_bundle/Contents/Info.plist" ]]; then
  printf 'error: expected a macOS app bundle at %s\n' "$app_bundle" >&2
  exit 2
fi

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
pdf_fixture="$root_directory/TestFixtures/fixture-text-3-pages.pdf"

if [[ ! -f "$pdf_fixture" ]]; then
  printf 'error: missing versioned UI-smoke fixture at %s\n' "$pdf_fixture" >&2
  exit 1
fi

read -r -d '' smoke_program <<'SWIFT' || true
import AppKit
import ApplicationServices
import Foundation

struct SmokeFailure: Error, CustomStringConvertible {
    let description: String
}

let appURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fixtureURL = URL(fileURLWithPath: CommandLine.arguments[2])
let unavailableExitCode: Int32 = 77

func unavailable(_ message: String) -> Never {
    FileHandle.standardError.write(Data("UI smoke unavailable: \(message)\n".utf8))
    exit(unavailableExitCode)
}

func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
        return nil
    }

    return value
}

func childElements(_ element: AXUIElement, attribute name: String = kAXChildrenAttribute) -> [AXUIElement] {
    guard let values = attribute(element, name) as? [Any] else {
        return []
    }

    return values.map { unsafeDowncast($0 as AnyObject, to: AXUIElement.self) }
}

func snapshot(for application: NSRunningApplication) -> [AXUIElement] {
    let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
    var queue = childElements(applicationElement, attribute: kAXWindowsAttribute)
    var result: [AXUIElement] = []
    var currentIndex = 0

    while currentIndex < queue.count, result.count < 4_000 {
        let element = queue[currentIndex]
        currentIndex += 1
        result.append(element)
        queue.append(contentsOf: childElements(element))
    }

    return result
}

func identifier(of element: AXUIElement) -> String? {
    attribute(element, kAXIdentifierAttribute) as? String
}

func element(named expectedIdentifier: String, in application: NSRunningApplication) -> AXUIElement? {
    snapshot(for: application).first { identifier(of: $0) == expectedIdentifier }
}

func visibleText(of element: AXUIElement) -> String {
    [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute, kAXHelpAttribute]
        .compactMap { attribute(element, $0) as? String }
        .joined(separator: " ")
}

func button(titled expectedTitle: String, in application: NSRunningApplication) -> AXUIElement? {
    snapshot(for: application).first { item in
        attribute(item, kAXRoleAttribute) as? String == kAXButtonRole
            && visibleText(of: item)
                .split(separator: " ")
                .joined(separator: " ")
                .hasPrefix(expectedTitle)
    }
}

func pauseBriefly() {
    RunLoop.current.run(until: Date().addingTimeInterval(0.12))
}

func awaitCondition(
    _ description: String,
    timeout: TimeInterval = 18,
    condition: () -> Bool
) throws {
    let deadline = Date().addingTimeInterval(timeout)

    repeat {
        if condition() {
            return
        }
        pauseBriefly()
    } while Date() < deadline

    throw SmokeFailure(description: "timed out waiting for \(description)")
}

func check(_ condition: Bool, _ description: String) throws {
    if !condition {
        throw SmokeFailure(description: description)
    }
}

func awaitOpen(
    _ action: (@escaping (NSRunningApplication?, Error?) -> Void) -> Void
) throws -> NSRunningApplication {
    var result: Result<NSRunningApplication, Error>?

    action { application, error in
        if let error {
            result = .failure(error)
        } else if let application {
            result = .success(application)
        } else {
            result = .failure(SmokeFailure(description: "macOS did not return a launched application"))
        }
    }

    try awaitCondition("the macOS application-launch callback") {
        result != nil
    }

    return try result!.get()
}

func launch() throws -> NSRunningApplication {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false
    configuration.createsNewApplicationInstance = true

    return try awaitOpen { completion in
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration, completionHandler: completion)
    }
}

func openFixture() throws {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false

    _ = try awaitOpen { completion in
        NSWorkspace.shared.open(
            [fixtureURL],
            withApplicationAt: appURL,
            configuration: configuration,
            completionHandler: completion
        )
    }
}

func expectReadingMode(in application: NSRunningApplication) throws {
    try awaitCondition("the reading-mode toolbar") {
        guard let toggle = element(named: "workspaceModeToggle", in: application) else {
            return false
        }

        return visibleText(of: toggle).contains("Bearbeiten")
            && element(named: "toolbarOpenDocument", in: application) != nil
    }

    let identifiers = Set(snapshot(for: application).compactMap(identifier))
    try check(!identifiers.contains("documentSidebar"), "reading mode unexpectedly exposes the sidebar")
    try check(!identifiers.contains("documentInspector"), "reading mode unexpectedly exposes the inspector")
    try check(!identifiers.contains("documentStatusBar"), "reading mode unexpectedly exposes the status bar")
    print("PASS reading mode hides editing surfaces")
}

func expectEditingMode(in application: NSRunningApplication) throws {
    try awaitCondition("the complete editing-mode surface") {
        guard let toggle = element(named: "workspaceModeToggle", in: application) else {
            return false
        }

        let identifiers = Set(snapshot(for: application).compactMap(identifier))
        return visibleText(of: toggle).contains("Lesen")
            && identifiers.contains("documentSidebar")
            && identifiers.contains("documentInspector")
            && identifiers.contains("documentStatusBar")
    }

    print("PASS editing mode exposes sidebar, inspector, and status bar")

    if ProcessInfo.processInfo.environment["KLARFOLIO_UI_SMOKE_DEBUG"] == "1" {
        for item in snapshot(for: application) {
            print("AX \(identifier(of: item) ?? "-"): \(visibleText(of: item))")
        }
    }
}

func pressWorkspaceToggle(in application: NSRunningApplication) throws {
    guard let toggle = element(named: "workspaceModeToggle", in: application) else {
        throw SmokeFailure(description: "the workspace-mode toolbar button is missing")
    }

    let result = AXUIElementPerformAction(toggle, kAXPressAction as CFString)
    try check(result == .success, "the workspace-mode button rejected the accessibility press")
}

func press(_ element: AXUIElement, description: String) throws {
    let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
    try check(result == .success, "\(description) rejected the accessibility press")
}

func pressButton(titled title: String, in application: NSRunningApplication) throws {
    guard let control = button(titled: title, in: application) else {
        throw SmokeFailure(description: "the button named \(title) is missing")
    }

    try press(control, description: "the \(title) button")
}

func pressCommandShortcut(
    keyCode: CGKeyCode,
    description: String,
    in application: NSRunningApplication
) throws {
    try check(
        application.activate(options: [.activateAllWindows]),
        "the \(description) target application could not be activated"
    )
    try awaitCondition("the \(description) target application to become active", timeout: 5) {
        application.isActive
    }

    guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
          let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
        throw SmokeFailure(description: "the \(description) keyboard shortcut could not be constructed")
    }

    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand
    keyDown.postToPid(application.processIdentifier)
    keyUp.postToPid(application.processIdentifier)
}

func expectUnsavedChangesAlert(in application: NSRunningApplication) throws {
    try awaitCondition("the Save / Discard / Cancel confirmation alert") {
        element(named: "documentSafety.save", in: application) != nil
            && element(named: "documentSafety.discard", in: application) != nil
            && element(named: "documentSafety.cancel", in: application) != nil
    }
}

func pressSafetyAction(_ identifier: String, in application: NSRunningApplication) throws {
    guard let action = element(named: identifier, in: application) else {
        throw SmokeFailure(description: "the document-safety action \(identifier) is missing")
    }

    try press(action, description: "the document-safety action \(identifier)")
}

func cancelAndExpectOriginalDocument(in application: NSRunningApplication) throws {
    try pressSafetyAction("documentSafety.cancel", in: application)
    try awaitCondition("Cancel to preserve the dirty original PDF") {
        !application.isTerminated
            && element(named: "documentSafety.discard", in: application) == nil
            && snapshot(for: application).contains {
                visibleText(of: $0).contains(fixtureURL.lastPathComponent)
            }
            && snapshot(for: application).contains {
                visibleText(of: $0) == "Ungespeichert"
            }
    }
}

func terminate(_ application: NSRunningApplication) throws {
    try check(application.terminate(), "the app rejected the clean termination request")
    try awaitCondition("the application to terminate cleanly") {
        application.isTerminated
    }
}

guard CGSessionCopyCurrentDictionary() != nil else {
    unavailable("no graphical macOS login session")
}

guard AXIsProcessTrusted() else {
    unavailable("the executing process has no macOS Accessibility permission")
}

do {
    guard let bundle = Bundle(url: appURL), let bundleIdentifier = bundle.bundleIdentifier else {
        throw SmokeFailure(description: "the app bundle has no readable bundle identifier")
    }

    guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty else {
        throw SmokeFailure(
            description: "the app is already running; close it or use a dedicated UI-smoke bundle identifier"
        )
    }

    let originalFixtureData = try Data(contentsOf: fixtureURL)
    var activeApplication: NSRunningApplication?
    defer {
        if let activeApplication, !activeApplication.isTerminated {
            _ = activeApplication.terminate()

            let cleanupDeadline = Date().addingTimeInterval(5)
            while !activeApplication.isTerminated, Date() < cleanupDeadline {
                if let discard = element(named: "documentSafety.discard", in: activeApplication) {
                    _ = AXUIElementPerformAction(discard, kAXPressAction as CFString)
                }
                pauseBriefly()
            }

            if !activeApplication.isTerminated {
                _ = activeApplication.forceTerminate()
            }
        }
    }

    var application = try launch()
    activeApplication = application
    try awaitCondition("the workspace-mode toolbar button") {
        element(named: "workspaceModeToggle", in: application) != nil
    }
    guard let initialToggle = element(named: "workspaceModeToggle", in: application) else {
        throw SmokeFailure(description: "the initial workspace-mode button disappeared")
    }
    let originalModeWasEditing = visibleText(of: initialToggle).contains("Lesen")

    if originalModeWasEditing {
        try pressWorkspaceToggle(in: application)
    }
    try expectReadingMode(in: application)

    try openFixture()
    try awaitCondition("the three-page PDF fixture to appear in the window title") {
        snapshot(for: application).contains {
            visibleText(of: $0).contains(fixtureURL.lastPathComponent)
        }
    }
    try expectReadingMode(in: application)
    print("PASS versioned three-page PDF opens in reading mode")

    try pressWorkspaceToggle(in: application)
    try expectEditingMode(in: application)

    try pressButton(titled: "Textfeld", in: application)
    try awaitCondition("the annotation to mark the PDF as unsaved") {
        snapshot(for: application).contains { visibleText(of: $0) == "Ungespeichert" }
    }
    print("PASS annotation changes mark the open PDF as unsaved")

    try pressWorkspaceToggle(in: application)
    try expectReadingMode(in: application)
    try awaitCondition("the visible reading-mode dirty indicator") {
        element(named: "documentEditedIndicator", in: application) != nil
    }
    print("PASS reading mode keeps unsaved changes visibly marked")

    try pressWorkspaceToggle(in: application)
    try expectEditingMode(in: application)

    try pressCommandShortcut(keyCode: 13, description: "Command-W", in: application)
    try expectUnsavedChangesAlert(in: application)
    try cancelAndExpectOriginalDocument(in: application)
    print("PASS Command-W warns before closing and Cancel preserves the dirty PDF")

    try pressCommandShortcut(keyCode: 12, description: "Command-Q", in: application)
    try expectUnsavedChangesAlert(in: application)
    try cancelAndExpectOriginalDocument(in: application)
    print("PASS Command-Q warns before quitting and Cancel keeps the application open")

    try pressCommandShortcut(keyCode: 45, description: "Command-N", in: application)
    try expectUnsavedChangesAlert(in: application)
    try cancelAndExpectOriginalDocument(in: application)
    print("PASS Command-N warns before document loss and Cancel preserves the dirty PDF")

    try openFixture()
    try expectUnsavedChangesAlert(in: application)
    try pressSafetyAction("documentSafety.discard", in: application)
    try awaitCondition("Discard to reopen the unchanged source PDF") {
        element(named: "documentSafety.discard", in: application) == nil
            && snapshot(for: application).contains {
                visibleText(of: $0) == "Gespeichert"
            }
    }
    try check(
        try Data(contentsOf: fixtureURL) == originalFixtureData,
        "the UI smoke unexpectedly modified the versioned source fixture"
    )
    print("PASS explicitly discarding changes reopens the original PDF without modifying it")

    try terminate(application)
    activeApplication = nil

    application = try launch()
    activeApplication = application
    try expectEditingMode(in: application)
    print("PASS editing mode persists after a clean app restart")

    try pressWorkspaceToggle(in: application)
    try expectReadingMode(in: application)
    print("PASS switching back to reading mode restores the reduced interface")

    if originalModeWasEditing {
        try pressWorkspaceToggle(in: application)
        try expectEditingMode(in: application)
        print("PASS the pre-existing editing-mode preference was restored")
    }

    try terminate(application)
    activeApplication = nil
    print("UI smoke passed.")
} catch {
    FileHandle.standardError.write(Data("UI smoke failed: \(error)\n".utf8))
    exit(1)
}
SWIFT

if swift -e "$smoke_program" "$app_bundle" "$pdf_fixture"; then
  exit 0
else
  smoke_status=$?
fi

if [[ "$smoke_status" -eq 77 && "$allow_headless" -eq 1 ]]; then
  printf '%s\n' \
    "::warning::UI smoke skipped: no graphical macOS session or Accessibility permission." \
    "Fixture regression tests still run, but no accessibility interaction was claimed."
  exit 0
fi

exit "$smoke_status"
