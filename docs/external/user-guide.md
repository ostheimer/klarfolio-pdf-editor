# Klarfolio PDF Editor Nutzerhandbuch

Klarfolio PDF Editor ist eine kostenlose, native macOS-App zum Lesen, Erstellen und Bearbeiten von PDF-Dateien. Beim ersten Start zeigt sie einen ablenkungsarmen Lesemodus; die vollständige Bearbeitungsoberfläche lässt sich jederzeit einblenden.

## Starten

```bash
./script/build_and_run.sh
```

In der Codex-App ist zusätzlich eine lokale `Run`-Aktion eingerichtet.

Für eine dauerhaft lokal installierte Entwicklungs-App im persönlichen Programme-Ordner:

```bash
./script/install_local_dev.sh
```

## Lese- und Bearbeitungsmodus

Beim ersten Start ist der **Lesemodus** aktiv. Er zeigt das PDF ohne Seitenleiste, rechten Werkzeugbereich, untere Statusleiste oder erweiterte Toolbar; sichtbar bleiben die wesentlichen Aktionen zum Öffnen und zum Wechsel in die Bearbeitung. Vorhandene PDF-Anmerkungen lassen sich im Lesemodus nicht versehentlich verschieben oder löschen; schreibende PDF-Menübefehle und ihre Tastenkürzel bleiben ebenfalls gesperrt.

- `Bearbeiten` oben rechts blendet links die Seitenleiste, rechts die Werkzeuge und unten die Statusleiste ein. Zusätzlich erscheinen Seitensteuerung, Zoom und Suchfeld in der Toolbar.
- `Lesen` blendet diese Bedienelemente wieder aus und beendet eine vorhandene Anmerkungsauswahl, ohne das Dokument zu verändern.
- Das Menü `Darstellung` enthält dieselbe Umschaltung; das Tastenkürzel lautet `⌘⇧E`.
- Die App merkt sich den zuletzt gewählten Modus und stellt ihn nach einem Neustart wieder her.

## PDF öffnen oder erstellen

- `Öffnen` lädt eine vorhandene PDF-Datei.
- Eine einzelne PDF kann in beiden Modi direkt aus dem Finder auf die Dokumentansicht gezogen werden.
- `Neues PDF` erstellt ein leeres Dokument mit einer Standardseite.
- `Speichern` schreibt Änderungen in die aktuelle Datei.
- `Sichern unter` speichert das Dokument an einem neuen Ort.

Ungespeicherte Änderungen werden im Bearbeitungsmodus unten in der Statusleiste und in beiden Modi über die native macOS-Fensterkennzeichnung angezeigt. `Öffnen` bleibt auch im Lesemodus direkt erreichbar; weitere Dateiaktionen sind zusätzlich über das macOS-Menü verfügbar.

## Ungespeicherte Änderungen schützen

Wenn das aktuelle Dokument noch nicht gesicherte Änderungen enthält, fragt Klarfolio vor einem neuen Dokument, dem Öffnen einer anderen PDF, dem Öffnen über den Finder, dem Schließen des Fensters oder dem Beenden der App nach:

- `Speichern` sichert das aktuelle Dokument und führt die gewünschte Aktion erst nach erfolgreichem Schreiben aus.
- `Verwerfen` verwirft die offenen Änderungen und führt die gewünschte Aktion aus.
- `Abbrechen` erhält das aktuelle Dokument unverändert und bricht die gewünschte Aktion ab.

Bei einem neuen Dokument ohne Dateinamen öffnet `Speichern` zunächst `Sichern unter`. Wird dieser Dialog abgebrochen oder schlägt das Schreiben fehl, bleiben Dokument und Fenster geöffnet.

## Lesen und Navigieren

- Im Lesemodus kannst du das PDF direkt scrollen und lesen.
- Im Bearbeitungsmodus zeigt die linke Seitenleiste Miniaturen aller Seiten.
- Ein Klick auf eine Miniatur springt zur jeweiligen Seite.
- Die Werkzeugleiste zeigt die aktuelle Seite, die Gesamtzahl der Seiten und den Zoom.
- `Vergrößern`, `Verkleinern` und `An Fenster anpassen` steuern die Ansicht.
- Im Dokumentbereich der Seitenleiste kann zwischen fortlaufender Ansicht, Einzelseite und Doppelseite gewechselt werden.

## Suchen

Das Suchfeld in der Werkzeugleiste ist im Bearbeitungsmodus sichtbar und sucht im geöffneten PDF.

- Treffer werden im Dokument hervorgehoben.
- Die Trefferzahl wird neben dem Suchfeld angezeigt.
- Das Löschsymbol setzt die Suche zurück.

Hinweis: Gescannte PDFs ohne eingebetteten Text benötigen OCR, bevor sie zuverlässig durchsucht werden können. OCR ist aktuell noch nicht implementiert.

## Seiten bearbeiten

Im rechten Werkzeugbereich stehen Seitenaktionen bereit:

- `Leere Seite` fügt nach der aktuellen Seite eine neue leere Seite ein.
- `Bilder` importiert Bilddateien als neue PDF-Seiten.
- Im Bearbeitungsmodus kannst du eine oder mehrere PNG-, JPG- oder andere unterstützte Bilddateien direkt auf das PDF ziehen; sie werden als neue Seiten angehängt.
- `Links drehen` und `Rechts drehen` drehen die aktuelle Seite.
- `Nach oben` und `Nach unten` verschieben die aktuelle Seite.
- `PDF zusammenführen` hängt Seiten aus anderen PDFs an.
- `Aktuelle Seite löschen` entfernt die aktuelle Seite, solange das Dokument mehr als eine Seite enthält. Interne Links, deren Ziel diese Seite war, werden ebenfalls entfernt, damit keine verwaisten Linkziele gespeichert werden.
- Unter `Seiten extrahieren` wählst du mit `Von` und `Bis` einen Bereich und sicherst ihn als neue PDF. Das geöffnete Dokument bleibt dabei unverändert.
- `Nach aktueller Seite teilen` legt im gewählten Zielordner zwei neue Dateien mit den Endungen `-Teil-1.pdf` und `-Teil-2.pdf` an. Beide Ausgaben werden zuerst vorbereitet, damit ein Fehler beim zweiten Teil keine einseitig überschriebene Ausgabe zurücklässt. Nach der letzten Seite ist die Aktion nicht verfügbar.
- Interne Seitenlinks werden beim Extrahieren und Teilen auf die Seiten des jeweiligen Ausgabedokuments umgebogen. Verweist ein Link auf eine Seite außerhalb dieses Ausgabeteils, wird er dort entfernt; Weblinks bleiben erhalten.

Bild-Drops sind im Lesemodus bewusst deaktiviert. Gemischte PDF-/Bild-Drops, mehrere gleichzeitig gezogene PDFs und unbekannte Dateitypen werden zurückgewiesen, damit das aktive Dokument nicht versehentlich verändert oder mehrdeutig ersetzt wird.

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

Klarfolio PDF Editor bearbeitet derzeit keine vorhandenen PDF-Textobjekte direkt. Textfelder sind Anmerkungen, keine Änderungen am ursprünglichen PDF-Inhalt. Vorhandene PDF-Formularfelder werden angezeigt, bleiben aber bis zur Einführung einer verlässlichen Formular- und Speicherfunktion in beiden Arbeitsmodi schreibgeschützt. Ebenso fehlen aktuell OCR, Schwärzung, Passwortschutz, Komprimierung, Office-Export und KI-gestützte Zusammenfassungen.

## Datenschutz

Die App verarbeitet die von dir ausgewählten Dokumente lokal auf deinem Mac. Der vollständige [Datenschutzhinweis](privacy.md) ist vor einer öffentlichen Veröffentlichung noch um die verantwortliche Stelle und eine öffentliche URL zu ergänzen.

Eine Zusammenfassung der aktuellen lokalen Datenverarbeitung ist jederzeit im App-Menü unter `Hilfe > Datenschutz …` erreichbar.
