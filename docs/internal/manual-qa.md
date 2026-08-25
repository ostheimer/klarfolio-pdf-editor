# Manueller Funktions-QA-Katalog

Dieser Katalog ist die Freigabegrundlage für eine sandboxed Release-App. Er ergänzt die automatisierten Build-, Test-, Shell- und Plist-Prüfungen in [`macos-ci.yml`](../../.github/workflows/macos-ci.yml); er ersetzt keine App-Store-Review.

## Durchführung und Evidenz

Teste einen **release-signierten** Build auf einem Mac mit macOS 14 oder neuer. Die Testperson hält pro Fall fest: Test-ID, Build/Bundle-ID, macOS-Version, Datum, Ergebnis (`PASS`, `FAIL` oder `BLOCKED`), tatsächliches Ergebnis und einen Evidenzverweis. Ein `PASS` ohne passende Evidenz gilt nicht als abgeschlossen.

Für Fälle, die Seitenleiste, Inspektor, Suche oder Statuszeile voraussetzen, zunächst über `Bearbeiten` in den Bearbeitungsmodus wechseln. Den reduzierten Standardzustand und die Umschaltung prüfen QA-44 bis QA-46 gesondert.

Zulässige Evidenz sind ein Screenshot oder eine kurze Bildschirmaufnahme mit sichtbarem erwarteten Zustand (`QA-<ID>-<kurzname>.png` bzw. `.mov`), eine gespeicherte Ausgabedatei mit SHA-256 plus Wiederöffnungsnachweis oder ein präziser Fehlerdialog bzw. Statuszeilentext bei einem Negativfall. Kritisch sind Datenverlust, unbeabsichtigtes Überschreiben, Absturz, Startfehler und fehlerhafte Signatur-/Sandbox-Prüfung; dafür ist eine Bildschirmaufnahme erforderlich.

Lege vor dem Test folgende nicht vertrauliche Dateien an:

- `fixture-text-3-pages.pdf`: drei Seiten mit eindeutigem Text, darunter mindestens zwei Vorkommen von `Klarfolio-Testwort` und ein mehrzeiliger Satz.
- `fixture-merge-2-pages.pdf`: zwei sichtbar anders gestaltete Seiten.
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
| QA-04 | Hoch | Eine PDF per Finder mit „Öffnen mit Klarfolio PDF Editor“ öffnen. | Die gewählte PDF wird im vorhandenen App-Fenster angezeigt. | Screenshot |
| QA-05 | Mittel | **Neues PDF** wählen. | Ein einseitiges, ungespeichertes Dokument entsteht; Status zeigt „Ungespeichert“. | Screenshot |
| QA-06 | Mittel | Einen Datei- oder Speicherdialog abbrechen. | Dokument und Bearbeitungszustand ändern sich nicht; kein Absturz. | Aufnahme vor/nach |

## Öffnen, Speichern und Wiederherstellen

| ID | Prio | Aktion | Pass-Kriterium | Evidenz |
| --- | --- | --- | --- | --- |
| QA-07 | Kritisch | `fixture-text-3-pages.pdf` über **Öffnen** laden. | Dokumentname, drei Miniaturen und Seite 1/3 sind sichtbar; Status bestätigt das Öffnen. | Screenshot |
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
| QA-44 | Hoch | App ohne zuvor gespeicherten Arbeitsmodus starten und eine PDF öffnen. | Standardmäßig erscheint der Lesemodus: PDF und `Öffnen`/`Bearbeiten` sind sichtbar; Seitenleiste, Inspektor, Suchfeld, Seiten-/Zoom-Toolbar und Statusleiste fehlen. | Screenshot |
| QA-45 | Hoch | Mit `Bearbeiten`, `Lesen`, dem Menü `Darstellung` und `⌘⇧E` zwischen beiden Modi wechseln. | Jede Umschaltmöglichkeit funktioniert; im Bearbeitungsmodus stehen Seitenleiste, Anmerkungswerkzeuge, Suche, Navigation, Zoom und Status vollständig bereit. | Aufnahme |
| QA-46 | Hoch | Modus wechseln, App neu starten; im Lesemodus eine vorhandene Anmerkung anklicken, ziehen und Löschen/Pfeiltasten drücken. | Der zuletzt gewählte Modus bleibt erhalten; vorhandene Anmerkungen werden im Lesemodus nicht ausgewählt, verschoben oder gelöscht und das Dokument bleibt unverändert. | Aufnahme + Vorher/Nachher |
