# Klarfolio PDF Editor Nutzerhandbuch

Klarfolio PDF Editor ist eine kostenlose, native macOS-App zum Lesen, Erstellen und Bearbeiten von PDF-Dateien. Bei jedem Start und beim Öffnen jeder vorhandenen PDF zeigt sie zuerst einen ablenkungsarmen Lesemodus; die vollständige Bearbeitungsoberfläche lässt sich bei Bedarf ausdrücklich einblenden.

## Passwortgeschützte und signierte PDFs

Beim Öffnen eines gesperrten PDFs fragt Klarfolio das Passwort verdeckt ab. Eine falsche Eingabe erlaubt einen weiteren Versuch. `Abbrechen` erhält das bisherige Dokument einschließlich ungespeicherter Änderungen und Arbeitsmodus. Das Passwort wird weder dauerhaft gespeichert noch protokolliert. Nach erfolgreichem Entsperren erscheint die Datei zunächst im Lesemodus.

Verschlüsselte PDFs bleiben derzeit schreibgeschützt, auch wenn einzelne PDF-Rechte Bearbeitung erlauben: Der geprüfte Speicherpfad kann den vorhandenen Passwortschutz nicht zuverlässig erhalten. Ein sichtbarer Hinweis erklärt diese Grenze. Speichern, Sichern unter, Formulare, Anmerkungen, Seitenänderungen und PDF-Export sind dann deaktiviert; solche Quellen können auch nicht zusammengeführt werden. Suche, Navigation und lokale Lesezeichen bleiben verfügbar. Kopieren und native Druckaktionen beachten die jeweiligen PDF-Rechte.

PDFs mit vorhandener digitaler Signatur bleiben ebenfalls schreibgeschützt, damit das Original nicht umgeschrieben wird. **Klarfolio prüft die Gültigkeit oder Vertrauenswürdigkeit dieser Signatur nicht.** Ein leeres Signaturfeld oder ein sichtbarer Unterschriftsplatzhalter ist keine digitale Signatur und löst diese Sperre nicht aus. Wenn sich die Signaturstruktur nicht sicher einordnen lässt, bleibt das Dokument vorsorglich schreibgeschützt.

## Starten

```bash
./script/build_and_run.sh
```

In der Codex-App ist zusätzlich eine lokale `Run`-Aktion eingerichtet.

Für eine dauerhaft lokal installierte Entwicklungs-App im persönlichen Programme-Ordner:

```bash
./script/install_local_dev.sh
```

Falls die Entwicklungs-App bereits läuft, schließe sie vor einer Aktualisierung regulär. Das Installationsskript beendet weder die Entwicklungs-App noch andere installierte Klarfolio-Varianten zwangsweise.

## Lese- und Bearbeitungsmodus

Bei jedem Start und nach jedem erfolgreichen Öffnen einer vorhandenen PDF ist der **Lesemodus** aktiv. Das gilt auch dann, wenn die App zuvor im Bearbeitungsmodus beendet wurde. Der Lesemodus zeigt das PDF ohne Seitenleiste, rechten Werkzeugbereich, untere Statusleiste oder erweiterte Toolbar; sichtbar bleiben die wesentlichen Aktionen zum Öffnen, zur kompakten Reader-Navigation und zum Wechsel in die Bearbeitung. Die Navigationsansicht erscheint ausschließlich nach ausdrücklicher Auswahl. Vorhandene PDF-Anmerkungen lassen sich im Lesemodus nicht versehentlich verschieben oder löschen; schreibende PDF-Menübefehle und ihre Tastenkürzel bleiben ebenfalls gesperrt.

- `Bearbeiten` oben rechts blendet links die Seitenleiste, rechts die Werkzeuge und unten die Statusleiste ein. Zusätzlich erscheinen Seitensteuerung, Zoom und Suchfeld in der Toolbar.
- `Lesen` blendet diese Bedienelemente wieder aus und beendet eine vorhandene Anmerkungsauswahl, ohne das Dokument zu verändern.
- Das Menü `Darstellung` enthält dieselbe Umschaltung; das Tastenkürzel lautet `⌘⇧E`.
- Ein App-Neustart und das erfolgreiche Öffnen einer anderen vorhandenen PDF beginnen bewusst wieder im Lesemodus; Bearbeitung erfordert jedes Mal eine ausdrückliche Auswahl.

## PDF öffnen oder erstellen

- `Öffnen` lädt eine vorhandene PDF-Datei und zeigt sie zunächst im Lesemodus.
- Das Öffnen über den Finder oder `Öffnen mit` zeigt die ausgewählte PDF ebenfalls zuerst im Lesemodus.
- Eine einzelne PDF kann in beiden Modi direkt aus dem Finder auf die Dokumentansicht gezogen werden; nach erfolgreichem Öffnen erscheint auch sie im Lesemodus.
- `Neues PDF` erstellt bewusst ein leeres Dokument mit einer Standardseite und darf direkt die Bearbeitungsoberfläche öffnen.
- `Speichern` schreibt Änderungen in die aktuelle Datei.
- `Sichern unter` speichert das Dokument an einem neuen Ort.

Ungespeicherte Änderungen werden im Bearbeitungsmodus unten in der Statusleiste und in beiden Modi über die native macOS-Fensterkennzeichnung angezeigt. `Öffnen` bleibt auch im Lesemodus direkt erreichbar; weitere Dateiaktionen sind zusätzlich über das macOS-Menü verfügbar. Wird ein Dateidialog oder eine Sicherheitsabfrage abgebrochen beziehungsweise eine ungültige PDF abgewiesen, bleiben das bisherige Dokument und der bisherige Lese- oder Bearbeitungsmodus unverändert.

## Ungespeicherte Änderungen schützen

Wenn das aktuelle Dokument noch nicht gesicherte Änderungen enthält, fragt Klarfolio vor einem neuen Dokument, dem Öffnen einer anderen PDF, dem Öffnen über den Finder, dem Schließen des Fensters oder dem Beenden der App nach. Das gilt ausdrücklich auch für ausgefüllte Textfelder und geänderte Checkboxen:

- `Speichern` sichert das aktuelle Dokument und führt die gewünschte Aktion erst nach erfolgreichem Schreiben aus.
- `Verwerfen` verwirft die offenen Änderungen und führt die gewünschte Aktion aus.
- `Abbrechen` erhält das aktuelle Dokument einschließlich Arbeitsmodus unverändert und bricht die gewünschte Aktion ab.

Bei einem neuen Dokument ohne Dateinamen öffnet `Speichern` zunächst `Sichern unter`. Wird dieser Dialog abgebrochen oder schlägt das Schreiben fehl, bleiben Dokument und Fenster geöffnet.

## Lesen und Navigieren

- Im Lesemodus kannst du das PDF direkt scrollen und lesen.
- `Inhalt & Lesezeichen` zeigt bei Bedarf die aktuelle Seite, vorhandene PDF-Kapitel und deine persönlichen Seiten-Lesezeichen.
- Im Bearbeitungsmodus zeigt die linke Seitenleiste Miniaturen aller Seiten.
- Ein Klick auf eine Miniatur springt zur jeweiligen Seite.
- Die Werkzeugleiste zeigt die aktuelle Seite, die Gesamtzahl der Seiten und den Zoom.
- `Vergrößern`, `Verkleinern` und `An Fenster anpassen` steuern die Ansicht.
- Im Dokumentbereich der Seitenleiste kann zwischen fortlaufender Ansicht, Einzelseite und Doppelseite gewechselt werden.

## Inhaltsverzeichnis, Lesezeichen und Leseposition

Sobald eine PDF geöffnet ist, kannst du ihre Reader-Navigation direkt über `Inhalt & Lesezeichen` in der oberen Werkzeugleiste öffnen. Die vollständige Bearbeitungsoberfläche wird dadurch nicht eingeblendet.

- `Inhaltsverzeichnis` zeigt vorhandene Kapitel und verschachtelte Unterkapitel des PDFs. Ein Klick springt zur jeweiligen Seite.
- Enthält eine PDF kein eigenes Inhaltsverzeichnis, bleibt das Dokument vollständig nutzbar; die Navigation zeigt einen verständlichen Hinweis.
- Über den Bereich `Meine Lesezeichen` merkst du die aktuelle Seite, springst zu bereits gemerkten Seiten und entfernst nicht mehr benötigte Einträge.
- Seiten-Lesezeichen sind persönliche lokale Einstellungen: Sie werden nicht in die PDF geschrieben und erzeugen keine ungespeicherten Dokumentänderungen.
- Beim erneuten Öffnen einer bereits bekannten PDF springt Klarfolio zur zuletzt gelesenen gültigen Seite und bleibt trotzdem im Lesemodus.
- Leseposition und Lesezeichen gelten jeweils nur für das zugehörige Dokument und bleiben auf deinem Mac; eine andere PDF erhält ihre eigene Navigation.

## Suchen

Das Suchfeld in der Werkzeugleiste ist im Bearbeitungsmodus sichtbar und sucht im geöffneten PDF.

- Treffer werden im Dokument hervorgehoben.
- Die Trefferzahl wird neben dem Suchfeld angezeigt.
- Das Löschsymbol setzt die Suche zurück.

Hinweis: Gescannte PDFs ohne eingebetteten Text benötigen OCR, bevor sie zuverlässig durchsucht werden können. OCR ist aktuell noch nicht implementiert.

## PDF-Formulare ausfüllen

Vorhandene PDF-Formulare können auf dem Mac sicher ausgefüllt werden:

1. Öffne die PDF und wechsle mit `Bearbeiten` in den Bearbeitungsmodus.
2. Enthält das Dokument unterstützte Formularfelder, erscheint rechts oben der Bereich `Formularfelder`.
3. Gib neue Werte in vorhandene Textfelder ein oder aktiviere beziehungsweise deaktiviere vorhandene Checkboxen.
4. Speichere das Dokument. Die neuen Formularwerte bleiben beim erneuten Öffnen erhalten.

Jede tatsächliche Änderung wird als ungespeichert gekennzeichnet und durch dieselbe Sicherheitsabfrage geschützt wie andere PDF-Bearbeitungen. Als schreibgeschützt markierte Formularfelder können nicht verändert werden; vorhandene Zeichenlimits werden berücksichtigt. Im Lesemodus ist die Formularoberfläche ausgeblendet; direkte Eingaben in PDF-Widgets und formularzurücksetzende Link-Aktionen bleiben ebenfalls gesperrt. Auch im Bearbeitungsmodus erfolgt die Änderung bewusst über `Formularfelder`, damit sie zuverlässig erkannt, angezeigt und gespeichert wird.

Die Funktion füllt bereits vorhandene Textfelder und Checkboxen aus. Passwortfelder werden bewusst nicht als lesbarer Text dargestellt. Die App erstellt keine neuen Formularfelder und bietet keine kryptografischen Signaturen an.

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

## Aktuelle Seite zuschneiden

1. Öffne dein PDF, aktiviere ausdrücklich `Bearbeiten` und wähle die gewünschte Seite.
2. Wähle im rechten Bereich `Seiten` die Aktion `Seite zuschneiden …`.
3. Die Vorschau zeigt die gesamte Seite, auch bereits ausgeblendete Bereiche. Ziehe einen neuen Rahmen auf oder passe seine vier Ecken an. Alternativ ändern die beschrifteten Plus-/Minus-Regler die Ränder in 2-mm-Schritten; sie sind auch per Tastatur und Bedienungshilfen erreichbar. Randmaße und sichtbare Größe erscheinen in Millimetern mit einer Nachkommastelle. Die Ränder beziehen sich auf die sichtbare Seitendrehung.
4. Der Rahmen bleibt innerhalb der Seite. Die Mindestgröße beträgt ungefähr 12,7 mm je Richtung; bei noch kleineren Originalseiten bleibt in dieser Richtung die volle Größe erhalten.
5. `Abbrechen` verwirft den Entwurf ohne Änderung. `Anwenden` ändert ausschließlich den sichtbaren Bereich der aktuellen Seite und markiert eine tatsächliche Änderung als ungespeichert. Vorschau, Miniatur und Größenanzeige aktualisieren sich.
6. Speichere regulär. Beim erneuten Öffnen bleibt der Ausschnitt erhalten und die App beginnt wieder im Lesemodus. Zum Wiederherstellen öffne das Sheet erneut und wähle `Auf Seitengröße zurücksetzen`; auch diese Änderung muss gespeichert werden.

**Zuschneiden blendet Inhalte nur aus. Es entfernt keine Inhalte und ist keine sichere Schwärzung.** Ausgeblendete Texte und andere PDF-Inhalte können weiterhin in der Datei vorhanden und zugänglich sein. Der Zuschnitt eignet sich nicht zum Entfernen vertraulicher Informationen. Stapelbearbeitung ist nicht enthalten.

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

Klarfolio PDF Editor bearbeitet derzeit keine vorhandenen PDF-Textobjekte direkt. Frei eingefügte Textfelder sind Anmerkungen, keine Änderungen am ursprünglichen PDF-Inhalt; vorhandene PDF-Formular-Textfelder und Checkboxen können dagegen über den eigenen Bereich `Formularfelder` ausgefüllt werden. Das Erstellen neuer Formularfelder sowie kryptografische Signaturen werden nicht unterstützt. Ebenso fehlen aktuell OCR, Schwärzung, das Einrichten oder Ändern von Passwortschutz, Komprimierung, Office-Export und KI-gestützte Zusammenfassungen.

## Datenschutz

Die App verarbeitet die von dir ausgewählten Dokumente lokal auf deinem Mac. Persönliche Seiten-Lesezeichen und die zuletzt gelesene Seite werden ausschließlich in lokalen App-Einstellungen gespeichert; Dokumentkennungen verwenden gehashte statt lesbarer Dateipfade. Der vollständige [Datenschutzhinweis](privacy.md) ist vor einer öffentlichen Veröffentlichung noch um die verantwortliche Stelle und eine öffentliche URL zu ergänzen.

Eine Zusammenfassung der aktuellen lokalen Datenverarbeitung ist jederzeit im App-Menü unter `Hilfe > Datenschutz …` erreichbar.
