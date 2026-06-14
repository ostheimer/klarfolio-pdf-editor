# OpenPDF Nutzerhandbuch

OpenPDF ist eine native macOS-App zum Lesen, Erstellen und Bearbeiten von PDF-Dateien. Die Oberfläche besteht aus einer Seitenleiste links, der PDF-Ansicht in der Mitte und einem Werkzeugbereich rechts.

## Starten

```bash
./script/build_and_run.sh
```

In der Codex-App ist zusätzlich eine lokale `Run`-Aktion eingerichtet.

## PDF öffnen oder erstellen

- `Öffnen` lädt eine vorhandene PDF-Datei.
- `Neues PDF` erstellt ein leeres Dokument mit einer Standardseite.
- `Speichern` schreibt Änderungen in die aktuelle Datei.
- `Sichern unter` speichert das Dokument an einem neuen Ort.

Ungespeicherte Änderungen werden unten in der Statusleiste angezeigt.

## Lesen und Navigieren

- Die linke Seitenleiste zeigt Miniaturen aller Seiten.
- Ein Klick auf eine Miniatur springt zur jeweiligen Seite.
- Die Werkzeugleiste zeigt die aktuelle Seite, die Gesamtzahl der Seiten und den Zoom.
- `Vergrößern`, `Verkleinern` und `An Fenster anpassen` steuern die Ansicht.
- Im Dokumentbereich der Seitenleiste kann zwischen fortlaufender Ansicht, Einzelseite und Doppelseite gewechselt werden.

## Suchen

Das Suchfeld in der Werkzeugleiste sucht im geöffneten PDF.

- Treffer werden im Dokument hervorgehoben.
- Die Trefferzahl wird neben dem Suchfeld angezeigt.
- Das Löschsymbol setzt die Suche zurück.

Hinweis: Gescannte PDFs ohne eingebetteten Text benötigen OCR, bevor sie zuverlässig durchsucht werden können. OCR ist aktuell noch nicht implementiert.

## Seiten bearbeiten

Im rechten Werkzeugbereich stehen Seitenaktionen bereit:

- `Leere Seite` fügt nach der aktuellen Seite eine neue leere Seite ein.
- `Bilder` importiert Bilddateien als neue PDF-Seiten.
- `Links drehen` und `Rechts drehen` drehen die aktuelle Seite.
- `Nach oben` und `Nach unten` verschieben die aktuelle Seite.
- `PDF zusammenführen` hängt Seiten aus anderen PDFs an.
- `Aktuelle Seite löschen` entfernt die aktuelle Seite, solange das Dokument mehr als eine Seite enthält.

## Anmerkungen

OpenPDF unterstützt einfache PDF-Anmerkungen:

- `Textfeld` fügt frei platzierbaren Text in der Seitenmitte ein.
- `Notiz` fügt eine PDF-Notiz hinzu.
- `Marker` hebt zuvor markierten Text hervor.
- `Unterstreichen` unterstreicht zuvor markierten Text.
- `Durchstreichen` streicht zuvor markierten Text.
- `Signaturfeld` fügt einen Platzhalter für eine Unterschrift ein.
- `Stempel einfügen` erstellt Stempel wie `Genehmigt`, `Entwurf` oder `Vertraulich`.
- `Letzte Anmerkung löschen` entfernt die zuletzt angelegte Anmerkung der aktuellen Seite.

Farbe und Schriftgröße werden im Werkzeugbereich eingestellt. Für Marker, Unterstreichung und Durchstreichung muss zuerst Text im PDF markiert werden.

## Grenzen des aktuellen MVP

OpenPDF bearbeitet derzeit keine vorhandenen PDF-Textobjekte direkt. Textfelder sind Anmerkungen, keine Änderungen am ursprünglichen PDF-Inhalt. Ebenso fehlen aktuell OCR, Schwärzung, Passwortschutz, Komprimierung, Formularfeld-Bearbeitung, Office-Export und KI-gestützte Zusammenfassungen.
