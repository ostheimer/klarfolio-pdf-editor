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
- Die AppKit-Brücke bleibt auf `PDFCanvasView` begrenzt.
- `PDFDocumentStore` ist die zentrale Main-Actor-Quelle für Dokumentzustand, Auswahl, Statusmeldungen und PDF-Aktionen.
- Sichtbare deutsche Texte verwenden echte Umlaute.

## Wichtige Komponenten

| Datei | Verantwortung |
| --- | --- |
| `KlarfolioPDFEditorApp.swift` | App-Einstieg, Menübefehle, Aktivierung als reguläre macOS-App. |
| `ContentView.swift` | Hauptlayout, Toolbar, Suchfeld, Statusleiste und leerer Startzustand. |
| `SidebarView.swift` | Seitenminiaturen, Seitenauswahl und Dokumentübersicht. |
| `InspectorView.swift` | Werkzeug-, Anmerkungs-, Seiten- und Dokumentaktionen. |
| `PDFCanvasView.swift` | `NSViewRepresentable` für `PDFView` plus PDFKit-Benachrichtigungen. |
| `PrivacyNoticeView.swift` | Direkt in der App erreichbare Zusammenfassung der lokalen Datenverarbeitung. |
| `PDFDocumentStore.swift` | Öffnen, Speichern, Seitenaktionen einschließlich Extrahieren/Teilen, Suche, Zoom, Link- und andere Annotationen; interne Linkziele werden beim Teil-Export auf kopierte Seiten umgebogen oder entfernt. |
| `PDFModels.swift` | UI-Enums für Seitenleistenbereiche, Werkzeuge, Farben und Layouts. |
| `PDFUtilities.swift` | Hilfsfunktionen für leere Seiten, Anzeigegrößen und Dateinamen. |

## Datenfluss

1. SwiftUI-Views rufen Aktionen am `PDFDocumentStore` auf.
2. Der Store verändert `PDFDocument`, `PDFPage` oder `PDFAnnotation`.
3. `PDFCanvasView` synchronisiert das SwiftUI-Modell mit `PDFView`.
4. `PDFView` sendet Seiten- und Zoomänderungen über PDFKit-Benachrichtigungen zurück an den Store.
5. Der Store veröffentlicht Status, Seitenindex, Zoom und Dirty-State an die Oberfläche.

## Aktuelle technische Grenzen

- PDFKit ist stark für Anzeige, Annotationen und Seitenorganisation, aber kein vollständiger Inhaltseditor für bestehende Text- und Bildobjekte.
- Textfelder, Stempel und Signaturfelder sind Annotationen, keine direkte Bearbeitung des ursprünglichen PDF-Content-Streams. Automatisch erzeugte PDFKit-Popup-Begleitanmerkungen werden nicht als eigenständige Nutzeranmerkungen ausgewählt oder gelöscht.
- Beim Löschen von Seiten werden interne Links zu dieser Zielseite entfernt. Extraktion und Teilen remappen interne Ziele innerhalb des Ausgabeteils und entfernen bereichsüberschreitende Links; beide Split-Ausgaben werden vor dem Ersetzen vorhandener Zieldateien vorbereitet.
- Schwärzung muss später als echte Entfernung oder sichere Redaction implementiert werden. Eine überdeckende schwarze Fläche wäre fachlich unsicher.
- OCR, Office-Konvertierung und KI-Funktionen benötigen zusätzliche Frameworks oder Dienste.
- Formularfelder können mit PDFKit gelesen und teilweise ausgefüllt werden, aber die App hat dafür noch keine eigene UI.

## Nächste sinnvolle technische Schritte

1. Die vorhandenen `PDFDocumentStore`-Tests unter vollständigem Xcode in CI ausführen und um reale Fixture-PDFs sowie UI-Automation ergänzen.
2. Drag-and-drop für PDF- und Bildimport.
3. Lesezeichen/Outlines und erweiterte Linkverwaltung.
4. Sichere Redaction-Implementierung mit Validierung, dass Inhalte wirklich entfernt sind.
5. Export- und OCR-Strategie evaluieren.
