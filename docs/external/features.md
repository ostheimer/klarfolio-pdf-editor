# Klarfolio PDF Editor Featureübersicht

Diese Datei dokumentiert den aktuellen Funktionsumfang aus Nutzersicht.

## Dokumentverwaltung

| Feature | Status | Beschreibung |
| --- | --- | --- |
| PDF öffnen | Umgesetzt | Öffnet lokale PDF-Dateien über den macOS-Dateidialog oder Finder immer zunächst im schreibgeschützten Lesemodus. |
| PDF per Drag-and-drop öffnen | Umgesetzt | Öffnet eine einzelne lokale PDF durch Ziehen auf die Dokumentansicht ebenfalls im Lesemodus; ungespeicherte Änderungen bleiben durch dieselbe Sicherheitsabfrage geschützt. |
| Neues PDF | Umgesetzt | Erstellt ein neues PDF mit einer leeren Seite und darf als ausdrückliche Erstellaktion unmittelbar in den Bearbeitungsmodus wechseln. |
| Speichern | Umgesetzt | Speichert Änderungen in die aktuelle Datei. |
| Sichern unter | Umgesetzt | Speichert das PDF an einem neuen Speicherort. |
| Sicherer Dokumentwechsel | Umgesetzt | Fragt vor Neu, Öffnen, Finder-Öffnen, Fensterschließen und App-Beenden nach `Speichern`, `Verwerfen` oder `Abbrechen`, falls ungespeicherte Änderungen vorliegen; abgebrochene und ungültige Öffnungen erhalten Dokument und Arbeitsmodus. |
| Ungespeichert-Status | Umgesetzt | Kennzeichnet das macOS-Fenster bei offenen Änderungen; im Bearbeitungsmodus erscheint zusätzlich die Statusleiste. |

## Lesen und Ansicht

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Native PDF-Anzeige | Umgesetzt | Darstellung über PDFKit. |
| Ablenkungsarmer Lesemodus | Umgesetzt | Jeder App-Start und jedes erfolgreiche Öffnen einer vorhandenen PDF beginnen in der schreibgeschützten Ansicht ohne Seitenleiste, Werkzeugbereich, Statusleiste und erweiterte Toolbar; schreibende Werkzeuge, Menüaktionen und Tastenkürzel sind deaktiviert. |
| Umschaltbarer Bearbeitungsmodus | Umgesetzt | `Bearbeiten`, das Menü `Darstellung` oder `⌘⇧E` blenden Seitenleiste, Werkzeuge, Suche, Navigation und Zoom ausdrücklich ein; ein Neustart oder eine neu geöffnete vorhandene PDF kehrt zuverlässig in den Lesemodus zurück. |
| PDF-Inhaltsverzeichnis | Umgesetzt | Zeigt vorhandene verschachtelte PDF-Kapitel über eine kompakte, ausdrücklich geöffnete Reader-Navigation und springt zur tatsächlichen Zielseite. |
| Persönliche Seiten-Lesezeichen | Umgesetzt | Merkt und verwaltet Seiten-Lesezeichen dokumentbezogen und ausschließlich lokal, ohne PDF-Inhalte oder Dirty-State zu verändern. |
| Gemerkte Leseposition | Umgesetzt | Öffnet eine bekannte PDF wieder auf der zuletzt gelesenen gültigen Seite, weiterhin immer im schreibgeschützten Lesemodus. |
| Seitenminiaturen | Umgesetzt | Seitenleiste mit Miniaturansichten und direkter Seitenauswahl. |
| Fortlaufende Ansicht | Umgesetzt | Standardansicht für längere Dokumente. |
| Einzelseitenansicht | Umgesetzt | Alternative Darstellung pro Seite. |
| Doppelseitenansicht | Umgesetzt | Zwei-Seiten-Layout über PDFKit. |
| Zoom | Umgesetzt | Vergrößern, Verkleinern und Anpassen an das Fenster. |
| Nacht-/Sepia-Lesemodus | Nicht umgesetzt | Für spätere Leseeinstellungen vorgesehen. |

## Suche

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Textsuche | Umgesetzt | Sucht Text im PDF und hebt Treffer hervor. |
| Trefferanzahl | Umgesetzt | Zeigt die Anzahl der Suchtreffer. |
| Suche in gescannten PDFs | Nicht umgesetzt | Erfordert OCR. |
| Suche über mehrere PDFs | Nicht umgesetzt | Aktuell nur im geöffneten Dokument. |

## Anmerkungen

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Textfeld | Umgesetzt | Fügt ein FreeText-Annotationselement ein. |
| Notiz | Umgesetzt | Fügt eine PDF-Notiz ein. |
| Hervorheben | Umgesetzt | Hebt zuvor selektierten Text farbig hervor. |
| Unterstreichen | Umgesetzt | Unterstreicht zuvor selektierten Text. |
| Durchstreichen | Umgesetzt | Streicht zuvor selektierten Text. |
| Stempel | Umgesetzt | Erstellt einfache Textstempel. |
| Signaturfeld | Teilweise umgesetzt | Fügt einen visuellen Platzhalter ein, aber keine kryptografische Signatur. |
| Bestehende Anmerkung bearbeiten | Umgesetzt | Nicht-Widget-Anmerkungen können ausgewählt, verschoben, bearbeitet und gelöscht werden. |
| Link hinzufügen | Umgesetzt | Erzeugt Link-Anmerkungen zu einer Webadresse oder einer Seite im selben Dokument. |
| Freihandzeichnen | Nicht umgesetzt | Für spätere Zeichenwerkzeuge vorgesehen. |
| Formen | Nicht umgesetzt | Rechteck, Linie, Pfeil und Polygon fehlen noch. |
| Audio-Kommentare | Nicht umgesetzt | Nicht Teil des aktuellen MVP. |

## PDF-Formulare

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Vorhandene Textfelder ausfüllen | Umgesetzt | Erkennt unterstützte PDF-Formularfelder und bietet ihre sichere Bearbeitung ausschließlich im Bereich `Formularfelder` des Bearbeitungsmodus an. |
| Checkboxen ändern | Umgesetzt | Schaltet vorhandene Formular-Checkboxen über denselben zentralen, nachvollziehbaren Bearbeitungspfad um. |
| Formularänderungen speichern | Umgesetzt | Kennzeichnet tatsächliche Änderungen als ungespeichert, schützt sie beim Dokumentwechsel und erhält Text- sowie Checkboxwerte nach dem erneuten Öffnen. |
| Schreibgeschützte Formularfelder | Umgesetzt | Respektiert als schreibgeschützt markierte PDF-Felder; im Lesemodus bleiben sämtliche Formular-Widgets unveränderbar. |
| Formularfelder erstellen | Nicht umgesetzt | Es werden ausschließlich bereits vorhandene, unterstützte Textfelder und Checkboxen ausgefüllt. |
| Passwort-Formularfelder | Nicht umgesetzt | Als Passwort markierte PDF-Felder werden nicht als lesbares Textfeld angezeigt. |
| Radio- und Auswahlfelder | Nicht umgesetzt | Weitere Formularfeldtypen werden erst bei konkretem lokalem Bedarf ergänzt. |
| Digitale Signaturen | Nicht umgesetzt | Kryptografische Signaturfelder und Zertifikatssignaturen sind nicht Teil der Formularfunktion. |

## Seitenorganisation

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Leere Seite einfügen | Umgesetzt | Fügt eine neue Seite nach der aktuellen Seite ein. |
| Bilder als Seiten | Umgesetzt | Importiert Bilddateien per Dateidialog oder Drag-and-drop als PDF-Seiten; Bild-Drops sind nur im Bearbeitungsmodus erlaubt. |
| PDF zusammenführen | Umgesetzt | Hängt Seiten aus anderen PDFs an. |
| Seite drehen | Umgesetzt | Dreht die aktuelle Seite nach links oder rechts. |
| Seite verschieben | Umgesetzt | Verschiebt die aktuelle Seite nach oben oder unten. |
| Seite löschen | Umgesetzt | Löscht die aktuelle Seite, wenn mindestens eine weitere Seite bleibt, und entfernt interne Links mit diesem Ziel. |
| Seiten extrahieren | Umgesetzt | Speichert einen frei gewählten Seitenbereich als neue PDF, ohne das geöffnete Dokument zu verändern; interne Links werden auf enthaltene Zielseiten umgebogen oder bei externem Bereichsziel entfernt. |
| Dokument teilen | Umgesetzt | Schreibt zwei vorab vorbereitete neue PDFs nach der aktuellen Seite in einen ausgewählten Zielordner und behandelt interne Links je Ausgabeteil wie beim Extrahieren. |
| Aktuelle Seite zuschneiden | Umgesetzt | Im Bearbeitungsmodus öffnet `Seite zuschneiden …` eine vollständige Seitenvorschau mit ziehbarem Rahmen und zugänglichen Randreglern. Ändert nur den sichtbaren Bereich der aktuellen Seite; blendet Inhalte aus, entfernt sie aber nicht und ist keine sichere Schwärzung. |
| Seitengröße wiederherstellen | Umgesetzt | `Auf Seitengröße zurücksetzen` stellt den sichtbaren Bereich auf die MediaBox zurück; tatsächliche Änderungen werden als ungespeichert markiert und lassen sich regulär speichern. |

## Bearbeitung des PDF-Inhalts

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Vorhandenen Text ändern | Nicht umgesetzt | PDFKit bietet dafür keine vollständige High-Level-Editorfunktion. |
| Bilder im PDF ändern | Nicht umgesetzt | Bildobjekt-Bearbeitung ist nicht implementiert. |
| Links hinzufügen | Umgesetzt | Links können zu einer Webadresse oder zu einer Seite des geöffneten Dokuments führen. |
| Kopf-/Fußzeilen | Nicht umgesetzt | Noch nicht geplant. |
| Inhaltsverzeichnis/Lesezeichen | Umgesetzt | Vorhandene PDF-Outlines werden schreibgeschützt angezeigt; persönliche Seiten-Lesezeichen verbleiben lokal und werden nicht in die PDF geschrieben. |

## Sicherheit, Export und Automatisierung

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Passwortschutz | Nicht umgesetzt | Noch keine Verschlüsselungs- oder Berechtigungsverwaltung. |
| Schwärzung/Zensieren | Nicht umgesetzt | Muss echte Inhalt Entfernung leisten, nicht nur Überdecken. |
| Komprimierung | Nicht umgesetzt | Noch keine Optimierung von Bildqualität oder Objektstruktur. |
| Office-/Bildexport | Nicht umgesetzt | Export nach Word, Excel, PowerPoint, TXT, JPG oder PNG fehlt. |
| OCR | Nicht umgesetzt | Texterkennung für Scans fehlt. |
| KI-Zusammenfassung | Nicht umgesetzt | Keine AI-Funktionen im aktuellen Stand. |
