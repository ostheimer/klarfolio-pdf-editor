# Manueller Funktions-QA-Katalog

Dieser Katalog ist die Freigabegrundlage für eine sandboxed Release-App. Er ergänzt die automatisierten Build-, Test-, Shell- und Plist-Prüfungen in [`macos-ci.yml`](../../.github/workflows/macos-ci.yml); er ersetzt keine App-Store-Review.

## Durchführung und Evidenz

Teste einen **release-signierten** Build auf einem Mac mit macOS 14 oder neuer. Die Testperson hält pro Fall fest: Test-ID, Build/Bundle-ID, macOS-Version, Datum, Ergebnis (`PASS`, `FAIL` oder `BLOCKED`), tatsächliches Ergebnis und einen Evidenzverweis. Ein `PASS` ohne passende Evidenz gilt nicht als abgeschlossen.

Für Fälle, die Seitenleiste, Inspektor, Suche oder Statuszeile voraussetzen, zunächst über `Bearbeiten` in den Bearbeitungsmodus wechseln. Jeder App-Start und jedes erfolgreiche Öffnen einer vorhandenen PDF beginnen wieder im Lesemodus; nach jedem Dokumentwechsel ist Bearbeitung daher bei Bedarf erneut ausdrücklich zu aktivieren. Den reduzierten Standardzustand, sämtliche Öffnungspfade, die Umschaltung, die sicheren lokalen Installer und die Reader-Navigation prüfen QA-44 bis QA-46 sowie QA-66 bis QA-86 gesondert.

Zulässige Evidenz sind ein Screenshot oder eine kurze Bildschirmaufnahme mit sichtbarem erwarteten Zustand (`QA-<ID>-<kurzname>.png` bzw. `.mov`), eine gespeicherte Ausgabedatei mit SHA-256 plus Wiederöffnungsnachweis oder ein präziser Fehlerdialog bzw. Statuszeilentext bei einem Negativfall. Kritisch sind Datenverlust, unbeabsichtigtes Überschreiben, Absturz, Startfehler und fehlerhafte Signatur-/Sandbox-Prüfung; dafür ist eine Bildschirmaufnahme erforderlich.

Verwende vor dem Test die synthetischen, lizenzfreien Dateien aus [`TestFixtures/`](../../TestFixtures/README.md) und ergänze nur die benötigten Bild- beziehungsweise Ausgabe-Fixtures:

- `fixture-text-3-pages.pdf`: drei Seiten mit eindeutigem Text, darunter mindestens zwei Vorkommen von `Klarfolio-Testwort` und ein mehrzeiliger Satz.
- `fixture-merge-2-pages.pdf`: zwei sichtbar anders gestaltete Seiten.
- `fixture-outline-4-pages.pdf`: vier Seiten mit verschachtelten Kapitelzielen einschließlich eines Unterkapitels.
- `fixture-form.pdf`: vorausgefülltes Textfeld, aktivierte Checkbox und vorhandene Notizanmerkung.
- `fixture-invalid.pdf`: bewusst ungültige Datei mit PDF-Endung.
- `fixture-image.png`, `fixture-image.jpg` sowie eine nicht lesbare bzw. als Bild umbenannte Textdatei.
- Einen beschreibbaren Testordner außerhalb des Repositorys.

## Freigabekriterien

- Jeder kritische oder hohe Fall besteht auf dem finalen Build.
- Kein offener `FAIL` ist als Release-Ausnahme akzeptiert. `BLOCKED` braucht eine dokumentierte Ursache und eine Entscheidung der Release-Verantwortlichen.
- Gespeicherte Stichproben lassen sich nach einem vollständigen App-Neustart erneut öffnen; Seitenzahl und die jeweils geprüfte Änderung bleiben erhalten.
- Der Umfang entspricht der veröffentlichten Featureübersicht und den Store-Metadaten.

## Build, Installation und grundlegende Bedienung

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-01 | Kritisch | Finales `.pkg` installieren; App über Finder starten. | Installation und Start gelingen ohne Absturz. Hauptfenster zeigt Öffnen/Neues PDF und keine vorherige Testdatei. | Startaufnahme + `pkgutil --check-signature` |
| QA-02 | Kritisch | Signatur und Sandbox des installierten Bundles prüfen. | `codesign --verify --strict --verbose=2` endet erfolgreich; Entitlements enthalten nur App Sandbox und user-selected-read-write. | Terminalausgabe |
| QA-03 | Hoch | App beenden und erneut starten. | Die App beendet bzw. startet sauber; nach Schließen des letzten Fensters bleibt sie erwartungsgemäß aktiv oder kann über das Menü beendet werden. | Aufnahme |
| QA-04 | Hoch | Eine PDF per Finder mit „Öffnen mit Klarfolio PDF Editor“ öffnen. | Die gewählte PDF wird im vorhandenen App-Fenster ausschließlich im Lesemodus angezeigt; Seitenleiste und Inspektor bleiben ausgeblendet. | Screenshot |
| QA-05 | Mittel | **Neues PDF** wählen. | Ein einseitiges, ungespeichertes Dokument entsteht und die ausdrücklich angeforderte Bearbeitungsoberfläche ist sichtbar; Status zeigt „Ungespeichert“. | Screenshot |
| QA-06 | Mittel | Einen Datei- oder Speicherdialog abbrechen. | Dokument, Dirty-State und bisheriger Lese- oder Bearbeitungsmodus ändern sich nicht; kein Absturz. | Aufnahme vor/nach |

## Öffnen, Speichern und Wiederherstellen

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-07 | Kritisch | `fixture-text-3-pages.pdf` über **Öffnen** laden; anschließend ausdrücklich `Bearbeiten` wählen. | Die PDF erscheint zuerst ohne Bearbeitungsoberfläche im Lesemodus; erst nach `Bearbeiten` sind Dokumentname, drei Miniaturen, Seite 1/3 und der Öffnen-Status sichtbar. | Aufnahme + Screenshot |
| QA-08 | Hoch | Ungültige bzw. nicht lesbare PDF auswählen, soweit der Dialog dies zulässt. | Status „Die Datei konnte nicht geöffnet werden.“ oder Auswahl wird verhindert; vorheriges Dokument bleibt nutzbar. | Aufnahme/Status |
| QA-09 | Kritisch | In geöffneter Fixture Änderung vornehmen, **Speichern**, App beenden und Datei erneut öffnen. | Änderung bleibt erhalten; Status wechselt auf „Gespeichert“. | Vorher/Nachher + Dateihash |
| QA-10 | Kritisch | **Sichern unter** mit neuem Namen verwenden. | Neue Datei existiert im gewählten Ordner; Quelle wird nicht überschrieben; App arbeitet anschließend mit der neuen Datei. | Finder-Screenshot + beide Hashes |
| QA-11 | Hoch | Neues Dokument erstellen und **Speichern** wählen. | Speicherdialog erscheint; bestätigte Datei ist eine erneut öffnungsfähige PDF. | Screenshot + Wiederöffnung |
| QA-12 | Mittel | Speichern/Sichern unter abbrechen. | Kein neuer Eintrag und kein Überschreiben; Dokument bleibt „Ungespeichert“. | Screenshot |

## Lesen, Navigation und Suche

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-13 | Hoch | Alle drei Seiten über Miniaturen sowie Vorherige/Nächste Seite anwählen. | Aktuelle Seitenanzeige und sichtbare Seite stimmen bei jedem Wechsel überein; Grenzschalter sind deaktiviert. | Aufnahme |
| QA-14 | Mittel | Im Bereich **Dokument** Fortlaufend, Einzelseite und Doppelseite wählen. | Die PDF-Anzeige wechselt in jedes gewählte Layout und bleibt bedienbar. | Drei Screenshots |
| QA-15 | Mittel | Vergrößern, Verkleinern und An Fenster anpassen verwenden. | Zoomanzeige reagiert; Anpassen zeigt das Dokument ohne abgeschnittene Bedienung. | Aufnahme |
| QA-16 | Hoch | Nach `Klarfolio-Testwort` suchen und Enter drücken. | Treffer sind hervorgehoben, Zähler zeigt mindestens 2 und die erste Fundstelle wird angezeigt. | Screenshot |
| QA-17 | Mittel | Nach nicht vorhandenem Begriff suchen, dann Suche löschen. | Status meldet „Keine Treffer“; danach sind Zähler und Hervorhebungen zurückgesetzt. | Screenshot |

## Seitenorganisation

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-18 | Hoch | Auf Seite 1 eine **Leere Seite** einfügen. | Seitenzahl steigt um 1; neue Seite folgt direkt auf die aktuelle und wird angezeigt. | Vorher/Nachher |
| QA-19 | Hoch | PNG und JPG über **Bilder** importieren. | Pro lesbarem Bild entsteht am Ende eine Seite; Seitenzahl steigt um 2. | Screenshot + Wiederöffnung |
| QA-20 | Mittel | Unlesbare/umbenannte Bilddatei allein importieren. | Keine Seite wird hinzugefügt; Status meldet „Keine lesbaren Bilder gefunden.“ | Screenshot |
| QA-21 | Hoch | `fixture-merge-2-pages.pdf` zusammenführen. | Zwei Seiten werden am Ende eingefügt und die erste davon wird angezeigt. | Vorher/Nachher |
| QA-22 | Hoch | Eine Seite links und rechts drehen, speichern und erneut öffnen. | Ausrichtung ändert sich je 90 Grad und bleibt erhalten. | Aufnahme + Wiederöffnung |
| QA-23 | Hoch | Eine mittlere Seite mit ausgewähltem internen Link nach oben und nach unten verschieben. | Reihenfolge/Miniaturen ändern sich korrekt; aktuelle Seite bleibt die verschobene und die im Link-Editor gezeigte Zielseitenzahl folgt dem unveränderten Zielobjekt. | Aufnahme |
| QA-24 | Hoch | Zielseite eines internen Links löschen, speichern und erneut öffnen. | Seitenzahl sinkt um 1; richtige Nachbarseite wird aktiv; auf die gelöschte Seite gerichtete Links sind entfernt und werden nach Wiederöffnung nicht auf eine andere Seite umgedeutet. | Vorher/Nachher + Wiederöffnung |
| QA-25 | Mittel | Bei einseitigem Dokument **Aktuelle Seite löschen** auslösen bzw. prüfen. | Aktion ist deaktiviert; letzte Seite kann nicht entfernt werden. | Screenshot |
| QA-26 | Hoch | Einen gültigen Bereich, etwa Seite 2 bis 3, mit Weblink sowie internen Links zu einer enthaltenen und einer ausgeschlossenen Seite extrahieren. | Neue PDF enthält genau die gewählten Seiten; Weblink und internes Ziel im Bereich funktionieren nach Wiederöffnung, der bereichsüberschreitende Link fehlt; Name/Quell-PDF und deren Dirty-State bleiben unverändert. | Ausgabedatei + Hash + Wiederöffnung |
| QA-27 | Mittel | Ungültigen Bereich eingeben, etwa Von 3/Bis 2 oder außerhalb der Seitenzahl. | Keine Ausgabedatei; Status meldet „Bitte einen gültigen Seitenbereich wählen.“ | Screenshot |
| QA-28 | Hoch | Ein mindestens dreiseitiges Dokument mit internen Links innerhalb und zwischen den Teilen nach Seite 1 teilen; zusätzlich einen Schreibfehler für den zweiten Zielpfad simulieren. | Im Erfolgsfall entstehen beide PDFs mit korrekter Seitenzahl/Reihenfolge; interne Links innerhalb eines Teils funktionieren nach Wiederöffnung, teilübergreifende fehlen. Im Fehlerfall bleibt eine vorhandene erste Zieldatei unverändert und es entsteht keine halbe Ausgabe. Original und Dirty-State ändern sich nicht. | Finder-Screenshot + beide Hashes + Wiederöffnungen |

## Anmerkungen

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-29 | Hoch | Farbe und Schriftgröße setzen; **Textfeld** einfügen. | Sichtbares Textfeld in gewählter Farbe/Größe; Status „Textfeld eingefügt“. | Screenshot + Wiederöffnung |
| QA-30 | Mittel | **Notiz** einfügen. | Sichtbares Notizsymbol in gewählter Farbe; Status bestätigt die Anmerkung. | Screenshot |
| QA-31 | Hoch | Text auswählen und Marker, Unterstreichen, Durchstreichen anwenden. | Auf der Auswahl erscheinen passende Anmerkungen in gewählter Farbe und bleiben nach Speichern. | Vorher/Nachher + Wiederöffnung |
| QA-32 | Mittel | Ohne Textauswahl Marker, Unterstreichen und Durchstreichen anwenden. | Keine leere Anmerkung; Status fordert zur Textmarkierung auf. | Screenshot |
| QA-33 | Mittel | Die drei Stempelvarianten einzeln einfügen. | „Genehmigt“, „Entwurf“ und „Vertraulich“ sind sichtbar und unterscheidbar. | Screenshot |
| QA-34 | Hoch | **Signaturfeld** einfügen und speichern. | Visueller Platzhalter „Unterschrift“ erscheint und bleibt; keine kryptografische Signatur wird behauptet. | Screenshot + Wiederöffnung |
| QA-35 | Hoch | Textfeld und danach eine Notiz einfügen, dann **Letzte Anmerkung löschen** wählen. | Die sichtbare Notiz einschließlich einer von PDFKit erzeugten Popup-Begleitanmerkung verschwindet; das Textfeld bleibt. | Vorher/Nachher-Aufnahme |
| QA-36 | Hoch | Werkzeug **Auswahl** aktivieren und eine vorhandene Text-, Notiz- oder Stempelanmerkung anklicken. | Blauer Rahmen und Bereich „Ausgewählte Anmerkung“ erscheinen mit richtiger Seite/Typ; Widget-Anmerkungen sind nicht auswählbar. | Aufnahme |
| QA-37 | Hoch | Gewählte Anmerkung per Drag und Pfeiltasten verschieben, danach Inhalt/Farbe/Schriftgröße ändern und anwenden. | Position bleibt innerhalb der Seite; Änderung und neue Position bleiben nach Speichern/Wiederöffnung erhalten. Größe und Seite ändern sich nicht durch Drag. | Aufnahme + Wiederöffnung |
| QA-38 | Hoch | Einen Web-Link ohne Schema und einen Link zu einer Dokumentseite anlegen, beide auswählen und Ziel prüfen; danach gewählten Link löschen. | Webziel wird als `https://` gespeichert, Seitenlink springt zur Zielseite; Löschen entfernt nur die gewählte Anmerkung. | Screenshot + Wiederöffnung |
| QA-39 | Mittel | Leere, fehlerhafte oder nicht unterstützte Webadresse eingeben und Link anlegen. | Keine Link-Anmerkung wird hinzugefügt; Status meldet „Bitte eine gültige Webadresse eingeben.“ | Screenshot |

## Release-, Datenschutz- und Inhaltsgrenzen

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-40 | Kritisch | Installiertes Bundle mit `codesign -d --entitlements :-` prüfen. | App Sandbox und nur benutzergewählter Lese-/Schreibzugriff; keine breiten Ordner-Entitlements. | Terminalausgabe |
| QA-41 | Hoch | App ohne Netzverbindung starten, lokale PDF öffnen, bearbeiten und speichern. | Kernfunktionen arbeiten offline; keine Anmeldung oder Kontoeinrichtung. | Aufnahme |
| QA-42 | Hoch | Store-Text und Nutzerhandbuch gegen Build abgleichen. | Keine fehlende Funktion wird beworben: keine Textobjektbearbeitung, OCR, Schwärzung, Passwortschutz, digitale Signatur, Komprimierung, Office-Export oder KI. | Abgezeichnete Checkliste |
| QA-43 | Kritisch | Öffentlichen Support- und Datenschutzlink auf finalem Store-Listing sowie `Hilfe > Datenschutz …` in der App prüfen. | Beide öffentlichen Links sind erreichbar, nennen die finale verantwortliche Stelle; der App-Hinweis ist erreichbar und entspricht `privacy.md`. | URL-Test + Screenshots |

QA-43 bleibt bis zur Store-Einreichung ein offenes Release-Gate: Der App-Hinweis ist implementiert, aber Betreiberkontakt und öffentliche Support-/Datenschutz-URLs müssen noch ergänzt und gemeinsam mit dem finalen Build geprüft werden.

## Lese- und Bearbeitungsmodus

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-44 | Hoch | App ohne zuvor gespeicherten Arbeitsmodus starten und eine PDF öffnen. | App-Start und geöffnete PDF erscheinen im Lesemodus: PDF und `Öffnen`/`Bearbeiten` sind sichtbar; Seitenleiste, Inspektor, Suchfeld, Seiten-/Zoom-Toolbar und Statusleiste fehlen. | Screenshot |
| QA-45 | Hoch | Mit `Bearbeiten`, `Lesen`, dem Menü `Darstellung` und `⌘⇧E` zwischen beiden Modi wechseln. | Jede Umschaltmöglichkeit funktioniert; im Bearbeitungsmodus stehen Seitenleiste, Anmerkungswerkzeuge, Suche, Navigation, Zoom und Status vollständig bereit. | Aufnahme |
| QA-46 | Hoch | Bearbeitungsmodus aktivieren, App neu starten; im Lesemodus eine vorhandene Anmerkung anklicken, ziehen und Löschen/Pfeiltasten drücken. | Der Neustart beginnt trotz vorheriger Bearbeitung wieder im Lesemodus; vorhandene Anmerkungen werden nicht ausgewählt, verschoben oder gelöscht und das Dokument bleibt unverändert. | Aufnahme + Vorher/Nachher |

## Dokumentenschutz und schreibgeschütztes Lesen

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-47 | Kritisch | Ungespeichertes Dokument erstellen oder bearbeiten; anschließend `Neues PDF` wählen und nacheinander `Abbrechen`, `Verwerfen` sowie `Speichern` prüfen. | `Abbrechen` erhält das alte Dokument; `Verwerfen` öffnet das neue; `Speichern` öffnet das neue erst nach erfolgreicher Sicherung des bisherigen Dokuments. | Bildschirmaufnahme + Wiederöffnung |
| QA-48 | Kritisch | Geändertes Dokument per `Öffnen` und anschließend über den Finder durch eine andere PDF ersetzen. | Beide Einstiegspfade fragen vor dem Dokumentwechsel; ein Abbruch verändert weder Seiten, Anmerkungen, Dateinamen, Dirty-State noch Arbeitsmodus. Erfolgreiche Wechsel zeigen die neue PDF im Lesemodus. | Bildschirmaufnahme + Vorher/Nachher |
| QA-49 | Kritisch | Fenster mit offenen Änderungen über die rote Ampel und `⌘W` schließen; die App anschließend mit `⌘Q` beenden und jeweils `Abbrechen`, `Verwerfen` sowie `Speichern` prüfen. | Abbrechen hält das Fenster beziehungsweise die App offen; Speichern beendet erst nach erfolgreicher Sicherung; Verwerfen beendet bewusst ohne Speicherung. Automatische und abrupte macOS-Terminierung sind im App-Bundle deaktiviert. | Bildschirmaufnahme + Wiederöffnung + `Info.plist` |
| QA-50 | Kritisch | Bei einem neuen, ungespeicherten Dokument in der Sicherheitsabfrage `Speichern` wählen, anschließend `Sichern unter` abbrechen oder einen Schreibfehler provozieren. | Die angeforderte Folgeaktion wird nicht ausgeführt; ursprüngliches Dokument, offenes Fenster und Dirty-State bleiben erhalten. | Bildschirmaufnahme + Fehlerzustand |
| QA-51 | Hoch | Im Lesemodus PDF-Menü öffnen und `⌘⇧P`, `⌘⇧H`, `⌘⇧T`, `⌘⇧M` sowie `⌘⇧L` ausprobieren. | Alle schreibenden Menüaktionen sind deaktiviert und sämtliche Tastenkürzel verändern weder Seitenzahl noch Annotationen. | Bildschirmaufnahme + Vorher/Nachher |
| QA-52 | Hoch | Geändertes Dokument aus dem Bearbeitungsmodus in den Lesemodus schalten. | Das native macOS-Fenster kennzeichnet weiterhin offene Änderungen, obwohl die Statusleiste ausgeblendet bleibt. | Screenshot |
| QA-53 | Hoch | Versionierte synthetische PDF-Fixtures und den automatisierten macOS-UI-Smoke ausführen. | Fixture-Herkunft und Erwartungen sind nachvollziehbar; zentrale Reader-, Bearbeitungs- und Sicherheitsabläufe bestehen ohne benutzereigene Dokumente. | Terminalausgabe + CI-Lauf |

## PDF- und Bild-Drops

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-54 | Hoch | Einzelne PDF im Lese- und Bearbeitungsmodus aus dem Finder auf die Dokumentansicht ziehen; zusätzlich mit ungespeichertem Ausgangsdokument wiederholen. | Die PDF kann aus beiden Modi geöffnet werden, erscheint nach Erfolg aber immer im Lesemodus; vorhandene offene Änderungen lösen zuvor dieselbe Speichern-/Verwerfen-/Abbrechen-Abfrage aus. | Bildschirmaufnahme + Vorher/Nachher |
| QA-55 | Hoch | Im Bearbeitungsmodus eine PNG-Datei und anschließend mehrere PNG/JPG-Dateien auf das geöffnete PDF ziehen. | Jede lesbare Bilddatei wird als neue Seite angehängt, Seitenzahl und Dirty-Kennzeichnung stimmen. | Bildschirmaufnahme + Wiederöffnung |
| QA-56 | Hoch | Im Lesemodus Bilder sowie in beiden Modi mehrere PDFs, gemischte PDF-/Bild-Drops und unbekannte Dateitypen auf das Dokument ziehen. | Nicht unterstützte oder schreibende Drops werden abgelehnt; aktives PDF, Seitenzahl, Annotationen und Dirty-State bleiben unverändert. | Bildschirmaufnahme + Vorher/Nachher |

## Vorhandene PDF-Formulare sicher ausfüllen

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-57 | Hoch | Eine beschreibbare Kopie von `fixture-form.pdf` öffnen und zwischen Lese- und Bearbeitungsmodus wechseln. | Im Lesemodus ist der Formularbereich ausgeblendet; im Bearbeitungsmodus erscheinen das vorausgefüllte Textfeld und die aktivierte Checkbox unter `Formularfelder`. Das reine Öffnen markiert das Dokument nicht als geändert. | Bildschirmaufnahme + Screenshot |
| QA-58 | Kritisch | Im Bearbeitungsmodus den vorhandenen Text ändern und die Checkbox deaktivieren; anschließend speichern, die App vollständig beenden und die PDF neu öffnen. | Beide tatsächlichen Änderungen setzen Status und native Änderungskennzeichnung; nach Speichern und Neustart bleiben der neue Text und der Checkboxzustand erhalten. | Bildschirmaufnahme + Ausgabedatei + Wiederöffnung |
| QA-59 | Kritisch | Nach einer Formularänderung jeweils `Öffnen`, `⌘W` und `⌘Q` auslösen; Sicherheitsdialog mit `Abbrechen`, `Verwerfen` und `Speichern` prüfen. | Der bestehende Dokumentschutz behandelt Formularänderungen identisch zu anderen Änderungen; Abbrechen erhält den Wert, Verwerfen verwirft bewusst und Speichern schützt den Wert vor der Folgeaktion. | Bildschirmaufnahme + Wiederöffnung |
| QA-60 | Hoch | Formular-PDF im Lesemodus öffnen und Textfeld beziehungsweise Checkbox direkt auf der PDF anklicken; anschließend in den Bearbeitungsmodus wechseln und dort die direkte Widget-Interaktion wiederholen. | PDFKit-Widgets lassen sich in keinem Modus direkt verändern; unterstützte Änderungen erfolgen ausschließlich über den kontrollierten Formularbereich und erzeugen keinen unerkannten Dirty-State. | Bildschirmaufnahme + Vorher/Nachher |
| QA-61 | Hoch | Schreibgeschütztes Formularfeld beziehungsweise identischen Feldwert prüfen; zusätzlich eine PDF ohne unterstützte Formularfelder öffnen. | Schreibgeschützte Felder sind nicht änderbar, identische Werte erzeugen keinen falschen Änderungsstatus und ohne unterstützte Felder erscheint kein Formularbereich. | Screenshot + Statusvergleich |
| QA-62 | Hoch | Den echten macOS-UI-Smoke mit `--require-ui` gegen die lokal gebaute App ausführen. | Die reale Accessibility-Automation bearbeitet ein Textfeld und eine Checkbox an einer temporären Fixture-Kopie und bestätigt Dokumentschutz, Speicherung sowie Wiederöffnung, ohne Original-Fixtures oder Nutzerdokumente zu verändern. | Terminalausgabe + gespeicherte Testdatei |
| QA-63 | Hoch | Ein Formularfeld mit hinterlegter maximaler Textlänge sowie mehrfach vorkommende Feldnamen auf unterschiedlichen Seiten prüfen. | Zeichenlimits werden eingehalten; jede Formularzeile ist stabil ihrem tatsächlichen PDF-Feld und ihrer Seite zugeordnet. | Screenshot + Wiederöffnung |
| QA-64 | Hoch | Eine PDF mit formularzurücksetzender Aktion auf einer Link-Anmerkung in beiden Modi öffnen und den Link anklicken. | Die Reset-Aktion bleibt blockiert; vorhandene Formularwerte und Dirty-State verändern sich nicht außerhalb des sicheren Formularbereichs. | Bildschirmaufnahme + Vorher/Nachher |
| QA-65 | Hoch | Eine PDF mit Passwort-, Radio- oder anderen nicht unterstützten Formularfeldern in beiden Modi öffnen. | Nicht unterstützte Felder erscheinen nicht im Formularbereich; Passwortwerte werden niemals als lesbarer Text dargestellt und direkte PDFKit-Widget-Eingaben bleiben gesperrt. | Screenshot + Vorher/Nachher |

## Lesemodus bei jedem Start, Dokumentwechsel und lokaler Installation

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-66 | Kritisch | Bearbeitungsmodus ausdrücklich aktivieren, App vollständig beenden und mit zuvor gespeicherter `editing`-Einstellung neu starten. | Das neue App-Fenster beginnt ohne Ausnahme im Lesemodus; Seitenleiste, Inspektor und Statusleiste bleiben ausgeblendet. | Bildschirmaufnahme + Vorher/Nachher |
| QA-67 | Hoch | Im Bearbeitungsmodus eine vorhandene PDF über `Öffnen` und anschließend eine weitere über Finder/`Öffnen mit` laden. | Jeder erfolgreiche Einstiegspfad zeigt das neu geöffnete Dokument unmittelbar im Lesemodus; Bearbeitungswerkzeuge erscheinen erst nach ausdrücklichem `Bearbeiten`. | Bildschirmaufnahme |
| QA-68 | Hoch | Im Bearbeitungsmodus eine einzelne gültige PDF per Drag-and-drop auf die Dokumentansicht ziehen. | Die neue PDF erscheint nach erfolgreichem Laden im Lesemodus; bisherige Anmerkungsauswahl und Bearbeitungswerkzeuge sind zurückgesetzt. | Bildschirmaufnahme + Screenshot |
| QA-69 | Kritisch | Ein geändertes Dokument im Bearbeitungsmodus per Öffnen/Finder/PDF-Drop ersetzen und die Sicherheitsabfrage jeweils mit `Abbrechen` schließen. | Ursprüngliches Dokument, Dateipfad, Dirty-State, Auswahl und Bearbeitungsmodus bleiben vollständig erhalten. | Bildschirmaufnahme + Vorher/Nachher |
| QA-70 | Hoch | Im Bearbeitungsmodus einen Öffnen-Dialog abbrechen beziehungsweise `fixture-invalid.pdf` auswählen oder droppen. | Der fehlgeschlagene Öffnungsversuch verändert weder das bestehende Dokument noch seinen Arbeitsmodus oder Dirty-State. | Bildschirmaufnahme + Vorher/Nachher |
| QA-71 | Hoch | Aus dem Lesemodus ausdrücklich `Neues PDF` wählen; danach eine vorhandene PDF öffnen. | Das neue leere Dokument darf unmittelbar im Bearbeitungsmodus erscheinen; die anschließend geöffnete vorhandene PDF beginnt wieder im Lesemodus. | Bildschirmaufnahme |
| QA-72 | Hoch | Parallel vorhandene `Klarfolio PDF Editor Dev.app` und `Klarfolio PDF Editor.app` anhand von Pfad, Bundle-ID und Signatur vergleichen. | Abweichende lokale Entwicklungsstände werden eindeutig erkannt; die Entwicklungsinstallation wird nicht mit einer älteren normalen lokalen App verwechselt. | Terminalausgabe + beide App-Informationen |
| QA-73 | Kritisch | Vor dem optionalen Abgleich einer normalen lokalen App exakten Zielpfad, Bundle-ID, Ad-hoc-Signatur, fehlenden App-Store-Beleg, geschlossenen Zustand und vollständiges Backup prüfen. | Ausschließlich eine vorhandene verifizierte lokale Ad-hoc-App darf ersetzt werden; echt signierte, notarisiert verteilte und App-Store-Apps bleiben ebenso unverändert wie die PDF-Standardzuordnung. | Terminalausgabe + Backup-Nachweis + Signaturprüfung |
| QA-74 | Kritisch | `install_local_dev.sh` beziehungsweise `build_and_run.sh --verify` zunächst bei ihrer jeweils laufenden Ziel-App und anschließend nach deren regulärem Schließen bei gleichzeitig laufenden anderen App-Varianten oder isolierten UI-Test-Bundles ausführen. | Beide Skripte prüfen ausschließlich ihren jeweiligen Dev- beziehungsweise `dist/`-Executable-Pfad, brechen bei laufender Ziel-App vor dem Build eindeutig ab und verifizieren danach nur denselben Pfad. Andere App-Varianten und isolierte Tests bleiben unbeendet und unberührt. | Terminalausgabe + Prozessliste vor/nach |

## PDF-Inhaltsverzeichnis, persönliche Lesezeichen und Leseposition

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-75 | Hoch | `fixture-outline-4-pages.pdf` über Finder, Dialog und PDF-Drop öffnen. | Die PDF beginnt ohne Bearbeitungsoberfläche im Lesemodus; `Inhalt & Lesezeichen` erscheint als einzelne kompakte Navigationsschaltfläche und die Navigationsansicht bleibt bis zum Klick geschlossen. | Bildschirmaufnahme + Screenshot |
| QA-76 | Hoch | `Inhalt & Lesezeichen` öffnen und nacheinander `Einleitung`, `Kapitel 1`, `Abschnitt 1.1` sowie `Kapitel 2` wählen; anschließend an einer temporären PDF-Kopie im Bearbeitungsmodus Seiten einfügen, verschieben beziehungsweise löschen und die Kapitel erneut anspringen. | Die verschachtelte Kapitelhierarchie bleibt sichtbar; jeder Eintrag springt zunächst zur Zielseite 1, 2, 3 beziehungsweise 4 und nach strukturellen Änderungen weiterhin zur tatsächlich zugehörigen PDF-Seite. | Bildschirmaufnahme + Seitenanzeige |
| QA-77 | Mittel | Eine PDF ohne eingebettetes Inhaltsverzeichnis öffnen und die Reader-Navigation anzeigen. | Der verständliche Leerzustand erklärt das fehlende Inhaltsverzeichnis; Seiten-Lesezeichen und reguläre Dokumentanzeige bleiben verfügbar. | Screenshot |
| QA-78 | Kritisch | Auf zwei unterschiedlichen Seiten persönliche Lesezeichen anlegen und anschließend eines entfernen. | Lesezeichen lassen sich eindeutig hinzufügen, anspringen und entfernen; Dateihash, PDF-Anmerkungen, Formularwerte und Dirty-State bleiben unverändert. | Bildschirmaufnahme + SHA-256-Vergleich |
| QA-79 | Hoch | Für zwei unterschiedliche PDFs jeweils eine eigene Seite markieren und wechselweise erneut öffnen. | Beide Dokumente behalten ausschließlich ihre eigenen Lesezeichen und Lesepositionen; kein Eintrag erscheint irrtümlich im anderen PDF. | Bildschirmaufnahme + Vorher/Nachher |
| QA-80 | Hoch | In der vierseitigen Outline-Fixture Seite 4 auswählen, die App vollständig beenden und dieselbe PDF erneut öffnen. | Das Dokument öffnet wieder auf Seite 4, weiterhin im Lesemodus ohne Seitenleiste, Inspektor oder Bearbeitungswerkzeuge. | Bildschirmaufnahme + Seitenanzeige |
| QA-81 | Hoch | Eine zuvor gemerkte PDF durch eine kürzere Version ersetzen beziehungsweise eine inzwischen nicht vorhandene Bookmark-Zielseite öffnen. | Die Leseposition wird auf eine gültige Seite begrenzt; ungültige persönliche Lesezeichen werden verworfen und die App bleibt stabil. | Testdatei + Bildschirmaufnahme |
| QA-82 | Kritisch | Ein bearbeitetes Formular mit offener Reader-Navigation durch eine andere PDF ersetzen und die Sicherheitsabfrage abbrechen. | Dokument, Formularwerte, Leseposition, Lesezeichen und Bearbeitungsmodus bleiben vollständig erhalten; der vorhandene Dokumentschutz wird nicht umgangen. | Bildschirmaufnahme + Vorher/Nachher |
| QA-83 | Hoch | Lokale App-Einstellungen nach Navigation und Bookmark-Anlage inspizieren. | Persistenzschlüssel verwenden nur den `SHA256` des normalisierten Dokumentpfads; Werte enthalten ausschließlich Seitenindizes und persönliche Lesezeichen, keine Klartextpfade oder PDF-Inhalte. | Anonymisierte Terminalausgabe |
| QA-84 | Hoch | Eine neue PDF ohne Dateipfad erstellen und anschließend über `Sichern unter` erstmals sichern. | Ohne Dateipfad entsteht keine dauerhafte dokumentbezogene Historie; nach erfolgreicher Speicherung verwendet die Leseposition ausschließlich die neue gehashte Dokumentkennung. | Bildschirmaufnahme + lokale Einstellungsprüfung |
| QA-85 | Hoch | Den echten macOS-Accessibility-Smoke gegen ein isoliertes Test-Bundle mit allen fünf versionierten PDF-Fixtures ausführen. | Kapitelansprung, lokale Lesezeichen, wiederhergestellte Leseposition sowie sämtliche vorhandenen Formular- und Schutzfälle bestehen; Original-Fixtures und Nutzerdokumente bleiben unverändert. | Terminalausgabe + Fixture-Dateihashes |
| QA-86 | Hoch | In-App-Datenschutzhinweis, externen Datenschutzhinweis und Reader-Verhalten gemeinsam prüfen. | Beide Hinweise beschreiben ausschließlich lokal gespeicherte Leseposition/Lesezeichen, gehashte Dokumentkennungen und fehlende Cloud-Übertragung zutreffend. | Screenshots + abgezeichnete Checkliste |
