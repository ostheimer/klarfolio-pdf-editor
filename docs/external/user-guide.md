# Klarfolio PDF Editor Nutzerhandbuch

Klarfolio PDF Editor ist eine kostenlose, native macOS-App zum Lesen, Erstellen und Bearbeiten von PDF-Dateien. Die Oberfläche besteht aus einer Seitenleiste links, der PDF-Ansicht in der Mitte und einem Werkzeugbereich rechts.

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
- `Aktuelle Seite löschen` entfernt die aktuelle Seite, solange das Dokument mehr als eine Seite enthält. Interne Links, deren Ziel diese Seite war, werden ebenfalls entfernt, damit keine verwaisten Linkziele gespeichert werden.
- Unter `Seiten extrahieren` wählst du mit `Von` und `Bis` einen Bereich und sicherst ihn als neue PDF. Das geöffnete Dokument bleibt dabei unverändert.
- `Nach aktueller Seite teilen` legt im gewählten Zielordner zwei neue Dateien mit den Endungen `-Teil-1.pdf` und `-Teil-2.pdf` an. Beide Ausgaben werden zuerst vorbereitet, damit ein Fehler beim zweiten Teil keine einseitig überschriebene Ausgabe zurücklässt. Nach der letzten Seite ist die Aktion nicht verfügbar.
- Interne Seitenlinks werden beim Extrahieren und Teilen auf die Seiten des jeweiligen Ausgabedokuments umgebogen. Verweist ein Link auf eine Seite außerhalb dieses Ausgabeteils, wird er dort entfernt; Weblinks bleiben erhalten.

## Anmerkungen

Klarfolio PDF Editor unterstützt einfache PDF-Anmerkungen:

- `Textfeld` fügt frei platzierbaren Text in der Seitenmitte ein.
- `Notiz` fügt eine PDF-Notiz hinzu.
- `Marker` hebt zuvor markierten Text hervor.
- `Unterstreichen` unterstreicht zuvor markierten Text.
- `Durchstreichen` streicht zuvor markierten Text.
- `Signaturfeld` fügt einen Platzhalter für eine Unterschrift ein.
- `Stempel einfügen` erstellt Stempel wie `Genehmigt`, `Entwurf` oder `Vertraulich`.
- `Letzte Anmerkung löschen` entfernt die zuletzt angelegte Anmerkung der aktuellen Seite.
- Mit `Link-Bereich anlegen` verlinkst du markierten Text oder ohne Textauswahl einen Bereich in der Seitenmitte. Das Ziel kann eine Webadresse oder eine Seite im selben Dokument sein; bei einer Webadresse ergänzt die App bei Bedarf `https://`.
- Mit dem Werkzeug `Auswahl` kannst du eine vorhandene, nicht interaktive Anmerkung anklicken. Der blaue Rahmen zeigt die Auswahl. Ziehe sie, verwende die Pfeiltasten oder bearbeite Inhalt, Farbe und Schriftgröße im Bereich `Ausgewählte Anmerkung`; dort lässt sie sich auch löschen.

Farbe und Schriftgröße werden im Werkzeugbereich eingestellt. Für Marker, Unterstreichung und Durchstreichung muss zuerst Text im PDF markiert werden.

## Grenzen des aktuellen MVP

Klarfolio PDF Editor bearbeitet derzeit keine vorhandenen PDF-Textobjekte direkt. Textfelder sind Anmerkungen, keine Änderungen am ursprünglichen PDF-Inhalt. Ebenso fehlen aktuell OCR, Schwärzung, Passwortschutz, Komprimierung, Formularfeld-Bearbeitung, Office-Export und KI-gestützte Zusammenfassungen.

## Datenschutz

Die App verarbeitet die von dir ausgewählten Dokumente lokal auf deinem Mac. Der vollständige [Datenschutzhinweis](privacy.md) ist vor einer öffentlichen Veröffentlichung noch um die verantwortliche Stelle und eine öffentliche URL zu ergänzen.

Eine Zusammenfassung der aktuellen lokalen Datenverarbeitung ist jederzeit im App-Menü unter `Hilfe > Datenschutz …` erreichbar.
