# Klarfolio PDF Editor Featureübersicht

Diese Datei dokumentiert den aktuellen Funktionsumfang aus Nutzersicht.

## Dokumentverwaltung

| Feature | Status | Beschreibung |
| --- | --- | --- |
| PDF öffnen | Umgesetzt | Öffnet lokale PDF-Dateien über den macOS-Dateidialog. |
| Neues PDF | Umgesetzt | Erstellt ein neues PDF mit einer leeren Seite. |
| Speichern | Umgesetzt | Speichert Änderungen in die aktuelle Datei. |
| Sichern unter | Umgesetzt | Speichert das PDF an einem neuen Speicherort. |
| Ungespeichert-Status | Umgesetzt | Zeigt in der Statusleiste, ob Änderungen vorhanden sind. |

## Lesen und Ansicht

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Native PDF-Anzeige | Umgesetzt | Darstellung über PDFKit. |
| Ablenkungsarmer Lesemodus | Umgesetzt | Standardansicht ohne Seitenleiste, Werkzeugbereich, Statusleiste und erweiterte Toolbar; PDF-Anmerkungen können dabei nicht versehentlich verschoben oder gelöscht werden. |
| Umschaltbarer Bearbeitungsmodus | Umgesetzt | `Bearbeiten`, das Menü `Darstellung` oder `⌘⇧E` blenden Seitenleiste, Werkzeuge, Suche, Navigation und Zoom ein; der letzte Modus bleibt nach einem Neustart erhalten. |
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

## Seitenorganisation

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Leere Seite einfügen | Umgesetzt | Fügt eine neue Seite nach der aktuellen Seite ein. |
| Bilder als Seiten | Umgesetzt | Importiert Bilddateien als PDF-Seiten. |
| PDF zusammenführen | Umgesetzt | Hängt Seiten aus anderen PDFs an. |
| Seite drehen | Umgesetzt | Dreht die aktuelle Seite nach links oder rechts. |
| Seite verschieben | Umgesetzt | Verschiebt die aktuelle Seite nach oben oder unten. |
| Seite löschen | Umgesetzt | Löscht die aktuelle Seite, wenn mindestens eine weitere Seite bleibt, und entfernt interne Links mit diesem Ziel. |
| Seiten extrahieren | Umgesetzt | Speichert einen frei gewählten Seitenbereich als neue PDF, ohne das geöffnete Dokument zu verändern; interne Links werden auf enthaltene Zielseiten umgebogen oder bei externem Bereichsziel entfernt. |
| Dokument teilen | Umgesetzt | Schreibt zwei vorab vorbereitete neue PDFs nach der aktuellen Seite in einen ausgewählten Zielordner und behandelt interne Links je Ausgabeteil wie beim Extrahieren. |
| Seiten zuschneiden | Nicht umgesetzt | Crop-Werkzeuge fehlen aktuell. |

## Bearbeitung des PDF-Inhalts

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Vorhandenen Text ändern | Nicht umgesetzt | PDFKit bietet dafür keine vollständige High-Level-Editorfunktion. |
| Bilder im PDF ändern | Nicht umgesetzt | Bildobjekt-Bearbeitung ist nicht implementiert. |
| Links hinzufügen | Umgesetzt | Links können zu einer Webadresse oder zu einer Seite des geöffneten Dokuments führen. |
| Kopf-/Fußzeilen | Nicht umgesetzt | Noch nicht geplant. |
| Inhaltsverzeichnis/Lesezeichen | Nicht umgesetzt | Noch nicht geplant. |

## Sicherheit, Export und Automatisierung

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Passwortschutz | Nicht umgesetzt | Noch keine Verschlüsselungs- oder Berechtigungsverwaltung. |
| Schwärzung/Zensieren | Nicht umgesetzt | Muss echte Inhalt Entfernung leisten, nicht nur Überdecken. |
| Komprimierung | Nicht umgesetzt | Noch keine Optimierung von Bildqualität oder Objektstruktur. |
| Office-/Bildexport | Nicht umgesetzt | Export nach Word, Excel, PowerPoint, TXT, JPG oder PNG fehlt. |
| OCR | Nicht umgesetzt | Texterkennung für Scans fehlt. |
| KI-Zusammenfassung | Nicht umgesetzt | Keine AI-Funktionen im aktuellen Stand. |
