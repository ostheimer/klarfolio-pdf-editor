# Interne Architektur

Diese Datei beschreibt die aktuelle technische Struktur von OpenPDF.

## Projektform

OpenPDF ist eine SwiftPM-basierte macOS-App.

- Paketdatei: `Package.swift`
- App-Einstieg: `Sources/OpenPDF/App/OpenPDFApp.swift`
- Build- und Startskript: `script/build_and_run.sh`
- Codex-Run-Action: `.codex/environments/environment.toml`

Das Run-Skript baut das SwiftPM-Executable, legt ein lokales `.app`-Bundle unter `dist/OpenPDF.app` an und startet es mit `open -n`.

## Architekturprinzipien

- SwiftUI besitzt die Fensterstruktur, Werkzeugleisten, Seitenleiste und Inspektoren.
- PDFKit besitzt die PDF-Anzeige, PDF-Dokumente, Seiten und Annotationen.
- Die AppKit-Brücke bleibt auf `PDFCanvasView` begrenzt.
- `PDFDocumentStore` ist die zentrale Main-Actor-Quelle für Dokumentzustand, Auswahl, Statusmeldungen und PDF-Aktionen.
- Sichtbare deutsche Texte verwenden echte Umlaute.

## Wichtige Komponenten

| Datei | Verantwortung |
| --- | --- |
| `OpenPDFApp.swift` | App-Einstieg, Menübefehle, Aktivierung als reguläre macOS-App. |
| `ContentView.swift` | Hauptlayout, Toolbar, Suchfeld, Statusleiste und leerer Startzustand. |
| `SidebarView.swift` | Seitenminiaturen, Seitenauswahl und Dokumentübersicht. |
| `InspectorView.swift` | Werkzeug-, Anmerkungs-, Seiten- und Dokumentaktionen. |
| `PDFCanvasView.swift` | `NSViewRepresentable` für `PDFView` plus PDFKit-Benachrichtigungen. |
| `PDFDocumentStore.swift` | Öffnen, Speichern, Seitenaktionen, Suche, Zoom und Annotationen. |
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
- Textfelder, Stempel und Signaturfelder sind Annotationen, keine direkte Bearbeitung des ursprünglichen PDF-Content-Streams.
- Schwärzung muss später als echte Entfernung oder sichere Redaction implementiert werden. Eine überdeckende schwarze Fläche wäre fachlich unsicher.
- OCR, Office-Konvertierung und KI-Funktionen benötigen zusätzliche Frameworks oder Dienste.
- Formularfelder können mit PDFKit gelesen und teilweise ausgefüllt werden, aber die App hat dafür noch keine eigene UI.

## Nächste sinnvolle technische Schritte

1. Tests für `PDFDocumentStore` mit temporären PDFs und Bildseiten.
2. Drag-and-drop für PDF- und Bildimport.
3. Annotation-Auswahl, Verschieben und Bearbeiten vorhandener Annotationen.
4. Link-Annotationen und Lesezeichen/Outlines.
5. Sichere Redaction-Implementierung mit Validierung, dass Inhalte wirklich entfernt sind.
6. Export- und OCR-Strategie evaluieren.
