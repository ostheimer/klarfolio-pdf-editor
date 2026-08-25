# Interne Architektur

Diese Datei beschreibt die aktuelle technische Struktur von Klarfolio PDF Editor.

## Projektform

Klarfolio PDF Editor ist eine SwiftPM-basierte macOS-App.

- Paketdatei: `Package.swift`
- App-Einstieg: `Sources/KlarfolioPDFEditor/App/KlarfolioPDFEditorApp.swift`
- Build- und Startskript: `script/build_and_run.sh`
- Codex-Run-Action: `.codex/environments/environment.toml`

Das Run-Skript baut das SwiftPM-Executable, legt ein lokales `.app`-Bundle unter `dist/Klarfolio PDF Editor.app` an und startet es mit `open -n`.

## Architekturprinzipien

- SwiftUI besitzt die Fensterstruktur, Werkzeugleisten, Seitenleiste und Inspektoren.
- PDFKit besitzt die PDF-Anzeige, PDF-Dokumente, Seiten und Annotationen.
- AppKit-Brücken bleiben auf `PDFCanvasView` und die kleine native Fensteranbindung für Dokumentkennzeichnung und Schließschutz begrenzt.
- `PDFDocumentStore` ist die zentrale Main-Actor-Quelle für Dokumentzustand, Auswahl, Statusmeldungen, Arbeitsmodus und PDF-Aktionen.
- Der Arbeitsmodus startet ohne gespeicherte Einstellung im Lesemodus und wird ausschließlich lokal in `UserDefaults` persistiert; für Tests können isolierte Preference-Suites injiziert werden.
- Ein zentraler Dokumentwechsel-Guard bewertet `isDirty`, fragt `Speichern`/`Verwerfen`/`Abbrechen` ab und setzt Aktionen nur nach tatsächlichem Speichererfolg fort; Dialog- und Speicherentscheidungen sind für Regressionstests injizierbar.
- Der Lesemodus ist auch auf Menü-, Tastenkürzel- und Fensterzustandsebene schreibgeschützt; `NSWindow.isDocumentEdited` bleibt unabhängig von der ausgeblendeten Statusleiste aktuell.
- `NSSupportsAutomaticTermination` und `NSSupportsSuddenTermination` sind ausdrücklich deaktiviert, damit macOS offene PDF-Änderungen nicht durch ein unangekündigtes Prozessende am Schließschutz vorbei verwirft.
- Sichtbare deutsche Texte verwenden echte Umlaute.

## Wichtige Komponenten

| Datei | Verantwortung |
| --- | --- |
| `KlarfolioPDFEditorApp.swift` | App-Einstieg, schreibgeschützte Menübefehle im Lesemodus, Moduswechsel per `⌘⇧E`, sichere Beendigungsentscheidung, modusabhängige Mindestfenstergröße und Aktivierung als reguläre macOS-App. |
| `ContentView.swift` | Hauptlayout mit reduziertem Lesemodus bzw. vollständigem Bearbeitungsmodus, bedingter Toolbar, Suchfeld, Statusleiste, nativem Edited-Kennzeichen, Schließschutz und leerem Startzustand. |
| `SidebarView.swift` | Seitenminiaturen, Seitenauswahl und Dokumentübersicht. |
| `InspectorView.swift` | Werkzeug-, Anmerkungs-, Seiten- und Dokumentaktionen. |
| `PDFCanvasView.swift` | `NSViewRepresentable` für `PDFView`, PDFKit-Benachrichtigungen, native Dateidrops und Anmerkungsinteraktionen ausschließlich im Bearbeitungsmodus. |
| `PrivacyNoticeView.swift` | Direkt in der App erreichbare Zusammenfassung der lokalen Datenverarbeitung. |
| `PDFDocumentStore.swift` | Persistierter Lese-/Bearbeitungsmodus, zentraler Schutz ungespeicherter Änderungen, erfolgsbasierte Speicheraktionen, Öffnen, Seitenaktionen einschließlich Extrahieren/Teilen, Suche, Zoom, Link- und andere Annotationen. |
| `PDFModels.swift` | UI-Enums für Arbeitsmodus, Seitenleistenbereiche, Werkzeuge, Farben und Layouts. |
| `PDFUtilities.swift` | Hilfsfunktionen für leere Seiten, Anzeigegrößen und Dateinamen. |
| `PDFFileDrop.swift` | Reine, testbare Klassifikation lokaler PDF- und Bild-Drops einschließlich Lese-/Bearbeitungsmodus und Ablehnung mehrdeutiger Eingaben. |
| `TestFixtures/` | Synthetische, versionierte und lizenzfreie Referenz-PDFs mit dokumentierter Herkunft und erwartetem Verhalten. |
| `script/run_ui_smoke.sh` | Reproduzierbarer macOS-Smoke für zentrale App- und Oberflächenabläufe. |

## Datenfluss

1. SwiftUI-Views rufen Aktionen am `PDFDocumentStore` auf.
2. Der Store verändert `PDFDocument`, `PDFPage` oder `PDFAnnotation`.
3. `PDFCanvasView` synchronisiert das SwiftUI-Modell mit `PDFView`.
4. `PDFView` sendet Seiten- und Zoomänderungen über PDFKit-Benachrichtigungen zurück an den Store.
5. Der Store veröffentlicht Status, Seitenindex, Zoom und Dirty-State an die Oberfläche.
6. Der Arbeitsmodus steuert Seitenleistensichtbarkeit, Inspektor, Toolbar und Statusleiste; beim Wechsel in den Lesemodus werden Anmerkungsauswahl und Bearbeitungswerkzeug zurückgesetzt, ohne das Dokument zu verändern.
7. Bevor ein dirty Dokument ersetzt, ein Fenster geschlossen oder die App beendet wird, entscheidet derselbe Store-Guard zwischen Speichern, Verwerfen und Abbrechen; fehlgeschlagene oder abgebrochene Speicherung blockiert den Folgeschritt.
8. Finder-Drops auf `PDFView` werden über `UTType` klassifiziert: einzelne PDFs öffnen in beiden Modi über den Dokumentwechsel-Guard; Bilddateien importiert ausschließlich der Bearbeitungsmodus.

## Aktuelle technische Grenzen

- PDFKit ist stark für Anzeige, Annotationen und Seitenorganisation, aber kein vollständiger Inhaltseditor für bestehende Text- und Bildobjekte.
- Textfelder, Stempel und Signaturfelder sind Annotationen, keine direkte Bearbeitung des ursprünglichen PDF-Content-Streams. Automatisch erzeugte PDFKit-Popup-Begleitanmerkungen werden nicht als eigenständige Nutzeranmerkungen ausgewählt oder gelöscht.
- Beim Löschen von Seiten werden interne Links zu dieser Zielseite entfernt. Extraktion und Teilen remappen interne Ziele innerhalb des Ausgabeteils und entfernen bereichsüberschreitende Links; beide Split-Ausgaben werden vor dem Ersetzen vorhandener Zieldateien vorbereitet.
- Schwärzung muss später als echte Entfernung oder sichere Redaction implementiert werden. Eine überdeckende schwarze Fläche wäre fachlich unsicher.
- OCR, Office-Konvertierung und KI-Funktionen benötigen zusätzliche Frameworks oder Dienste.
- Formularfelder und formularzurücksetzende PDF-Aktionen werden bis zu einer zuverlässig Dirty-State-verfolgten Umsetzung in beiden Arbeitsmodi blockiert; andernfalls könnte PDFKit Dokumentinhalte ohne Speicherwarnung verändern.

## Nächste sinnvolle technische Schritte

1. Den vorhandenen Fixture- und UI-Smoke-Grundstock gezielt um große, verschlüsselte, signierte und formularreiche PDFs erweitern.
2. Die vorhandene Drag-and-drop-Basis um nachvollziehbare Nutzerhinweise und bei Bedarf weitere lokale Importformate ergänzen.
3. Vorhandene PDF-Formularfelder, Lesezeichen/Outlines, komfortable Reader-Navigation und erweiterte Linkverwaltung produktisieren.
4. Sichere Redaction erst mit Validierung implementieren, dass Inhalte wirklich entfernt sind.
5. Export-, OCR-, Autosave- und Wiederherstellungsstrategie nur bei tatsächlichem lokalem Bedarf evaluieren.
