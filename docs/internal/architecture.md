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
- Jeder neu initialisierte Store startet ausdrücklich im Lesemodus, auch wenn `UserDefaults` aus einer früheren Sitzung noch `editing` enthält. Moduswechsel werden weiterhin ausschließlich lokal abgelegt; sie dürfen weder einen App-Neustart noch das erfolgreiche Öffnen einer vorhandenen PDF in die Bearbeitung zwingen. Für Tests können isolierte Preference-Suites injiziert werden.
- Eine erfolgreich geladene vorhandene PDF setzt den Arbeitsmodus erst nach bestandenem Dokumentwechsel-Guard und erfolgreichem PDF-Laden auf `reading`; ein abgebrochener Guard oder eine ungültige Datei lässt Dokument, Dirty-State und bisherigen Arbeitsmodus unverändert.
- PDF-Outlines werden rekursiv aus der vorhandenen PDFKit-Dokumenthierarchie gelesen und nach strukturellen Seitenänderungen neu aufgelöst; Kapitelansprünge und persönliche Seiten-Lesezeichen sind reine Reader-Aktionen und verändern weder PDF-Inhalte noch den Dirty-State.
- Leseposition und persönliche Lesezeichen liegen ausschließlich in injizierbaren lokalen `UserDefaults`; die dokumentbezogenen Schlüssel verwenden `SHA256` des standardisierten, symlinkaufgelösten Dateipfads statt lesbarer Pfade. Namenlos neu erzeugte PDFs erhalten keine dauerhafte Dokumenthistorie.
- Seitenrückmeldungen einer bereits ersetzten `PDFView` werden verworfen, damit verspätete SwiftUI-/PDFKit-Benachrichtigungen weder die aktuelle Ansicht noch eine gespeicherte Leseposition überschreiben.
- Ein zentraler Dokumentwechsel-Guard bewertet `isDirty`, fragt `Speichern`/`Verwerfen`/`Abbrechen` ab und setzt Aktionen nur nach tatsächlichem Speichererfolg fort; Dialog- und Speicherentscheidungen sind für Regressionstests injizierbar.
- Vorhandene PDF-Textfelder und Checkboxen werden im Store als überprüfbare Feldmodelle erfasst; Passwort-, Radio- und andere nicht unterstützte Felder bleiben ausgeschlossen. Jede zulässige Änderung läuft ausschließlich im Bearbeitungsmodus über zentrale Store-Aktionen mit Dirty-Tracking, Statusmeldung und regulärer PDF-Speicherung.
- Der Lesemodus ist auch auf Menü-, Tastenkürzel- und Fensterzustandsebene schreibgeschützt; `NSWindow.isDocumentEdited` bleibt unabhängig von der ausgeblendeten Statusleiste aktuell.
- `NSSupportsAutomaticTermination` und `NSSupportsSuddenTermination` sind ausdrücklich deaktiviert, damit macOS offene PDF-Änderungen nicht durch ein unangekündigtes Prozessende am Schließschutz vorbei verwirft.
- Sichtbare deutsche Texte verwenden echte Umlaute.

## Wichtige Komponenten

| Datei | Verantwortung |
| --- | --- |
| `KlarfolioPDFEditorApp.swift` | App-Einstieg, schreibgeschützte Menübefehle im Lesemodus, Moduswechsel per `⌘⇧E`, sichere Beendigungsentscheidung, modusabhängige Mindestfenstergröße und Aktivierung als reguläre macOS-App. |
| `ContentView.swift` | Hauptlayout mit reduziertem Lesemodus bzw. vollständigem Bearbeitungsmodus, bedingter Toolbar, Suchfeld, Statusleiste, nativem Edited-Kennzeichen, Schließschutz und leerem Startzustand. |
| `ReadingNavigationView.swift` | Kompakte, ausdrücklich geöffnete Reader-Navigation mit aktueller Seite, verschachteltem PDF-Inhaltsverzeichnis und persönlichen lokalen Seiten-Lesezeichen. |
| `SidebarView.swift` | Seitenminiaturen, Seitenauswahl und Dokumentübersicht. |
| `InspectorView.swift` | Werkzeug-, Anmerkungs-, Seiten- und Dokumentaktionen sowie die sichere Oberfläche für vorhandene PDF-Textfelder und Checkboxen. |
| `PDFCanvasView.swift` | `NSViewRepresentable` für `PDFView`, PDFKit-Benachrichtigungen, native Dateidrops und Anmerkungsinteraktionen ausschließlich im Bearbeitungsmodus. |
| `PrivacyNoticeView.swift` | Direkt in der App erreichbare Zusammenfassung der lokalen Datenverarbeitung. |
| `PDFDocumentStore.swift` | Deterministischer Lesemodus, vorhandene PDF-Outlines, lokal dokumentgetrennte Lesezeichen/Leseposition, expliziter Bearbeitungswechsel, zentraler Dokumentenschutz, nachvollziehbare Formularbearbeitung, erfolgsbasierte Speicherung, Seitenaktionen, Suche, Zoom und Annotationen. |
| `PDFModels.swift` | UI-Enums für Arbeitsmodus, Seitenleistenbereiche, Werkzeuge, Farben und Layouts. |
| `PDFFormModels.swift` | Stabile, überprüfbare Modelle vorhandener PDF-Textfelder und Checkboxen mit Feldidentität, Seite, Wert, Schreibschutz und Zeichenlimit. |
| `PDFReadingNavigationModels.swift` | Verschachtelte PDF-Outline-Einträge und lokal serialisierbare persönliche Seiten-Lesezeichen. |
| `PDFUtilities.swift` | Hilfsfunktionen für leere Seiten, Anzeigegrößen und Dateinamen. |
| `PDFFileDrop.swift` | Reine, testbare Klassifikation lokaler PDF- und Bild-Drops einschließlich Lese-/Bearbeitungsmodus und Ablehnung mehrdeutiger Eingaben. |
| `TestFixtures/` | Synthetische, versionierte und lizenzfreie Referenz-PDFs mit dokumentierter Herkunft und erwartetem Verhalten. |
| `script/install_local_dev.sh` | Aktualisiert ausschließlich die Entwicklungs-App, verweigert den Build bei laufendem exakt identifiziertem Dev-Prozess und beendet niemals andere App-Varianten oder isolierte UI-Smokes. |
| `script/build_and_run.sh` | Baut ausschließlich das Repository-Bundle unter `dist/`, blockiert bei dessen laufendem exakt identifiziertem Prozess und prüft mit `--verify` ausschließlich diesen Executable-Pfad; installierte Apps und UI-Smokes bleiben unberührt. |
| `script/run_ui_smoke.sh` | Reproduzierbarer macOS-Smoke für zentrale App-, Dokumentenschutz-, Formular- und Oberflächenabläufe. |

## Datenfluss

1. SwiftUI-Views rufen Aktionen am `PDFDocumentStore` auf.
2. Der Store verändert `PDFDocument`, `PDFPage` oder `PDFAnnotation`.
3. `PDFCanvasView` synchronisiert das SwiftUI-Modell mit `PDFView`.
4. `PDFView` sendet Seiten- und Zoomänderungen über PDFKit-Benachrichtigungen zurück an den Store.
5. Der Store veröffentlicht Status, Seitenindex, Zoom und Dirty-State an die Oberfläche.
6. Der Arbeitsmodus steuert Seitenleistensichtbarkeit, Inspektor, Toolbar und Statusleiste; bei jedem App-Start und erfolgreichen Öffnen einer vorhandenen PDF gilt der Lesemodus. Beim Wechsel in den Lesemodus werden Anmerkungsauswahl und Bearbeitungswerkzeug zurückgesetzt, ohne das Dokument zu verändern.
7. Bevor ein dirty Dokument ersetzt, ein Fenster geschlossen oder die App beendet wird, entscheidet derselbe Store-Guard zwischen Speichern, Verwerfen und Abbrechen; fehlgeschlagene oder abgebrochene Speicherung blockiert den Folgeschritt und erhält den bisherigen Arbeitsmodus.
8. Finder-Drops auf `PDFView` werden über `UTType` klassifiziert: einzelne PDFs öffnen in beiden Modi über den Dokumentwechsel-Guard und erscheinen nach erfolgreichem Laden im Lesemodus; Bilddateien importiert ausschließlich der Bearbeitungsmodus. Das ausdrückliche Erstellen eines neuen PDFs darf dagegen unmittelbar in die Bearbeitung wechseln.
9. Nach dem Dokumentwechsel erfasst der Store unterstützte Formular-Widgets; Text- und Checkboxänderungen aus dem SwiftUI-Inspektor prüfen Bearbeitungsmodus, Feldtyp, Schreibschutz und tatsächliche Wertänderung, bevor sie PDFKit und Dirty-State aktualisieren.
10. Direkte PDFKit-Widget-Eingaben sowie formularzurücksetzende Link-Aktionen bleiben in beiden Arbeitsmodi blockiert, damit keine Änderung den zentralen Dokumentenschutz umgehen kann.
11. Bei einem vorhandenen Datei-PDF liest der Store die Outline-Hierarchie und zugehörige lokale Lesezeichen, begrenzt ungültige gespeicherte Seiten und stellt die letzte gültige Leseposition wieder her. Die Reader-Navigation ruft nur sichere Seitenwechsel und lokale Bookmark-Aktionen auf.
12. PDFView-Seitenänderungen aktualisieren die Leseposition unter `at.ostheimer.klarfoliopdf.readingPosition.<sha256>`; persönliche Lesezeichen liegen separat unter `at.ostheimer.klarfoliopdf.pageBookmarks.<sha256>`. Weder Schlüssel noch Werte enthalten Klartext-Dateipfade oder PDF-Inhalte.

## Aktuelle technische Grenzen

### Zuschnitt der aktuellen Seite (#20)

`PDFCropGeometry` rechnet zwischen ungedrehten PDF-Koordinaten (Ursprung unten links, einschließlich versetzter MediaBox) und gedrehten Vorschaukoordinaten (oben links). Ein empirischer Test gegen `PDFView.convert` prüft 0/90/180/270 Grad: `PDFPage.bounds(for:)` bleibt ungedreht; `PDFView.isFlipped` ist false. Die SwiftUI-Vorschau benötigt deshalb die explizite Umrechnung. Rohbreiten/-höhen werden über `CGRect.size` geprüft, weil `CGRect.width/height` negative Werte standardisieren können. Nicht endliche, negative, zu kleine und außerhalb liegende Store-Eingaben werden ohne Mutation abgewiesen. Nur Gesten werden auf gültige Grenzen begrenzt.

`PDFCropSession` hält Dokument- und Seitenidentität, Seitenindex und ursprüngliche Boxen/Rotation. `PageCropSheet` hält den Rahmen ausschließlich als lokalen Entwurf; seine MediaBox-Miniatur ist kein bearbeitbarer PDFView. `canBeginPageCrop` ist eine Prüfung ohne Session-Erzeugung. Anwenden/Rücksetzen prüfen erneut Bearbeitungsmodus, Dokumentberechtigung, aktuelle Seite und unveränderte Ausgangsgeometrie. Nur die CropBox der aktuellen Seite wird gesetzt. Identische Werte bleiben ohne Dirty-State. Der bestehende Änderungs-/Speicherpfad aktualisiert Revision, Status, Miniatur und Größenanzeige; PDFKit berechnet das Seitenlayout neu. Es gibt keine zusätzlichen Crop-Menüs oder globalen Kürzel.

Der vorhandene `PDFDocument.write`-Pfad normalisiert beim Export versetzte MediaBox-Ursprünge: beispielsweise wird `[-40 75 360 675]` zu `[0 0 400 600]`, und CropBox sowie Inhalte werden entsprechend verschoben. Es wird keine unveränderte absolute Ursprungskoordinate nach Save/Reopen garantiert. Die Tests sichern Seitengröße, relativen sichtbaren Ausschnitt, Rotation, Formularwerte, Anmerkungen, interne Ziele und nach Rücksetzen/Speichern/Wiederöffnen den vollständigen Fixture-Text ab. Persönliche Lesezeichen und Leseposition laufen unverändert über die bestehende lokale Speicherung. Ein eigener PDF-Writer ist ausdrücklich außerhalb dieses Slices.

Zuschneiden ist ausschließlich Ausblenden über Seitenboxen, keine sichere Schwärzung oder Inhaltsentfernung. Datenverarbeitung und Datenschutz ändern sich dadurch nicht.

### Weitere Grenzen

- PDFKit ist stark für Anzeige, Annotationen und Seitenorganisation, aber kein vollständiger Inhaltseditor für bestehende Text- und Bildobjekte.
- Textfelder, Stempel und Signaturfelder sind Annotationen, keine direkte Bearbeitung des ursprünglichen PDF-Content-Streams. Automatisch erzeugte PDFKit-Popup-Begleitanmerkungen werden nicht als eigenständige Nutzeranmerkungen ausgewählt oder gelöscht.
- Beim Löschen von Seiten werden interne Links zu dieser Zielseite entfernt. Extraktion und Teilen remappen interne Ziele innerhalb des Ausgabeteils und entfernen bereichsüberschreitende Links; beide Split-Ausgaben werden vor dem Ersetzen vorhandener Zieldateien vorbereitet.
- Schwärzung muss später als echte Entfernung oder sichere Redaction implementiert werden. Eine überdeckende schwarze Fläche wäre fachlich unsicher.
- OCR, Office-Konvertierung und KI-Funktionen benötigen zusätzliche Frameworks oder Dienste.
- Direkte Eingaben in PDFKit-Formular-Widgets bleiben blockiert; unterstützte vorhandene Textfelder und Checkboxen werden ausschließlich über den kontrollierten Store-/Inspektorpfad geändert. Formular-Reset-Aktionen bleiben gesperrt, solange ihr Effekt nicht vollständig nachvollziehbar ist. Neue Formularfelder und kryptografische Signaturen werden nicht erzeugt.

## Nächste sinnvolle technische Schritte

1. Den vorhandenen Fixture- und UI-Smoke-Grundstock gezielt um große, verschlüsselte, signierte und formularreiche PDFs erweitern.
2. Die vorhandene Drag-and-drop-Basis um nachvollziehbare Nutzerhinweise und bei Bedarf weitere lokale Importformate ergänzen.
3. Die vorhandene Reader-Navigation bei tatsächlichem Bedarf um erweiterte Linkverwaltung, weitere Leseeinstellungen und zusätzliche PDF-Formularfeldtypen ergänzen.
4. Sichere Redaction erst mit Validierung implementieren, dass Inhalte wirklich entfernt sind.
5. Export-, OCR-, Autosave- und Wiederherstellungsstrategie nur bei tatsächlichem lokalem Bedarf evaluieren.
