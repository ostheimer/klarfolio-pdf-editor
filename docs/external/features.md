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
| Seite löschen | Umgesetzt | Löscht die aktuelle Seite, wenn mindestens eine weitere Seite bleibt. |
| Seiten extrahieren | Nicht umgesetzt | Export einzelner Seiten ist noch nicht vorhanden. |
| Seiten zuschneiden | Nicht umgesetzt | Crop-Werkzeuge fehlen aktuell. |

## Bearbeitung des PDF-Inhalts

| Feature | Status | Beschreibung |
| --- | --- | --- |
| Vorhandenen Text ändern | Nicht umgesetzt | PDFKit bietet dafür keine vollständige High-Level-Editorfunktion. |
| Bilder im PDF ändern | Nicht umgesetzt | Bildobjekt-Bearbeitung ist nicht implementiert. |
| Links hinzufügen | Nicht umgesetzt | Link-Annotationen sind technisch möglich, aber noch nicht in der UI. |
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
