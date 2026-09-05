# Lokale Entwicklung und Installation

Klarfolio kann auf demselben Mac als Entwicklungs-App genutzt und weiterentwickelt werden, ohne eine spätere App-Store-Installation zu überschreiben.

## Entwicklungs-App installieren

```bash
./script/install_local_dev.sh
```

Das Skript erstellt und startet standardmäßig:

- App: `~/Applications/Klarfolio PDF Editor Dev.app`
- Bundle-ID: `at.ostheimer.klarfoliopdf.debug`
- Konfiguration: `debug`
- Signatur: lokal/ad hoc

Die App wird beim erneuten Aufruf gezielt aktualisiert. Eine vorhandene App mit der normalen Bundle-ID `at.ostheimer.klarfoliopdf` bleibt unberührt. Deshalb können `Klarfolio PDF Editor Dev.app` und eine zusätzlich installierte `Klarfolio PDF Editor.app` auf demselben Mac unterschiedliche Entwicklungsstände zeigen.

Vor einem Update die laufende `Klarfolio PDF Editor Dev.app` regulär schließen und vorhandene Änderungen sichern. Der Installer prüft vor jedem Build ausschließlich den exakten Executable-Pfad dieser Entwicklungs-App. Läuft sie noch, bricht er mit einer eindeutigen Meldung ab, bevor das Bundle verändert wird. Er verwendet kein pauschales `pkill`, beendet keine normale Klarfolio-App und beendet keine isolierten UI-Test-Bundles. Nach dem Start wird ausschließlich derselbe Dev-Executable-Pfad geprüft.

Der beobachtete Screenshot mit einer sofort sichtbaren Bearbeitungsoberfläche zeigte die ältere normale lokale App, nicht die aktualisierte Entwicklungs-App. Bei der aktuellen Version beginnt jeder App-Start und jede erfolgreich per Finder, `Öffnen` oder PDF-Drop geladene vorhandene Datei im Lesemodus. Vor einer Fehlerdiagnose deshalb immer App-Name, absoluten Bundle-Pfad und Bundle-ID der tatsächlich gestarteten App prüfen.

Der Installationsordner kann bei Bedarf explizit überschrieben werden:

```bash
KLARFOLIO_LOCAL_APPLICATIONS_DIR="/vollständiger/pfad" ./script/install_local_dev.sh
```

## Vorhandene normale lokale App nur nach Herkunftsprüfung angleichen

Eine zusätzlich installierte `~/Applications/Klarfolio PDF Editor.app` darf nur aktualisiert werden, wenn sie bereits eine exakt identifizierte, lokal ad-hoc-signierte Entwicklungsinstallation ist. Eine App-Store-Version, eine Apple-/Developer-ID-signierte App, eine notarisiert verteilte App oder ein Bundle mit unbekannter Herkunft darf niemals durch diesen Vorgang überschrieben werden.

Vor dem Angleich müssen alle folgenden Bedingungen erfüllt sein:

1. Der Zielpfad lautet exakt `$HOME/Applications/Klarfolio PDF Editor.app`; das Bundle meldet exakt `at.ostheimer.klarfoliopdf`.
2. `codesign --verify --strict --verbose=2` bestätigt eine gültige Signatur, und `codesign -dv --verbose=4` weist ausdrücklich eine Ad-hoc-Signatur aus; ein Apple-/Developer-ID-Zertifikat oder Team-Identifier schließt den Vorgang aus.
3. Unter `Contents/_MASReceipt/receipt` existiert kein App-Store-Beleg.
4. Die normale Ziel-App wurde regulär geschlossen; es gibt keine ungespeicherten Nutzerdokumente. Die Entwicklungs-App muss nur für ein eigenes separates Dev-Update geschlossen werden.
5. Vor dem Ersetzen wurde eine eigenständige vollständige Backup-Kopie mit `ditto` erstellt und aufbewahrt.

Beispiel für die vorgelagerte, auf genau dieses Bundle begrenzte Prüfung und Sicherung:

```bash
normal_app_bundle="$HOME/Applications/Klarfolio PDF Editor.app"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
  "$normal_app_bundle/Contents/Info.plist"
codesign --verify --strict --verbose=2 "$normal_app_bundle"
codesign -dv --verbose=4 "$normal_app_bundle"
test ! -e "$normal_app_bundle/Contents/_MASReceipt/receipt"
normal_app_backup_directory="$(mktemp -d "$HOME/Applications/Klarfolio PDF Editor Backup.XXXXXXXX")"
ditto "$normal_app_bundle" "$normal_app_backup_directory/Klarfolio PDF Editor.app"
```

Erst wenn Bundle-ID, Herkunft, Ad-hoc-Signatur, fehlender App-Store-Beleg, geschlossene App und vollständiges Backup tatsächlich geprüft wurden, darf die bereits vorhandene lokale Normal-App so auf denselben Repository-Stand gebracht werden:

```bash
APP_NAME="Klarfolio PDF Editor" \
BUNDLE_ID="at.ostheimer.klarfoliopdf" \
./script/build_app_bundle.sh \
  --configuration debug \
  --output "$HOME/Applications/Klarfolio PDF Editor.app" \
  --sign-identity -
```

Das ist ausschließlich ein lokaler Abgleich einer vorher verifizierten Ad-hoc-Installation. Es ändert weder die Standardzuordnung für PDF-Dateien noch App-Store-, Release- oder Veröffentlichungseinstellungen. Bei jeder unklaren Herkunft bleibt die normale App unangetastet und stattdessen wird ausschließlich `install_local_dev.sh` verwendet.

## Direkt aus dem Repository arbeiten

Für den üblichen Entwicklungszyklus:

```bash
./script/build_and_run.sh --verify
```

Weitere Modi:

```bash
./script/build_and_run.sh --debug
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
```

Der lokale Repository-Build liegt unter `dist/Klarfolio PDF Editor.app` und verwendet ebenfalls die Debug-Bundle-ID.

Auch `build_and_run.sh` aktualisiert niemals eine laufende Ziel-App: Vor dem Build prüft es ausschließlich den exakten Pfad `dist/Klarfolio PDF Editor.app/Contents/MacOS/KlarfolioPDFEditor` und bricht ab, falls dieses Repository-Bundle noch geöffnet ist. Das Bundle zuvor regulär schließen; eine installierte Entwicklungs-App, eine normale lokale App und isolierte UI-Smokes werden nicht beendet. `--verify` kontrolliert nach dem Start ebenfalls ausschließlich den Repository-Executable-Pfad.

## Tests

Der Schutz-Slice (#22) ergänzt acht kleine verschlüsselte, rechtebeschränkte und tatsächlich signierte Fixtures mit negativen Kontrollen. Passwortöffnung, operationsbezogene Store-/PDFView-Grenzen, Import/Export und Signaturintegrität werden automatisiert geprüft; der echte AX-Lauf ergänzt Passwortabbruch mit dirty Dokument, sichtbaren Schreibschutz und deaktivierte Aktionen. Nachweise und reproduzierbarer PDFKit-Versuch: [Schutz-QA](protected-pdf-qa.md). Die folgenden Crop-Zahlen beschreiben die unveränderte Ausgangsbasis.

Der Crop-Slice (#20) ergänzt eine sechste synthetische Fixture, 15 gezielte Regressionstests und einen erweiterten echten Accessibility-Lauf. Aktuelle Basis: 128 Tests in acht Suites und 82 erfolgreiche UI-Prüfungen am isolierten Bundle. Einzelheiten und die PDFKit-Koordinatennormalisierung sind im [Crop-QA-Protokoll](crop-qa.md) dokumentiert.

Unter vollständigem Xcode 16 oder neuer:

```bash
swift test --parallel
```

Die Suite umfasst Store-, Dokumentenschutz-, Reader-Navigations-, Formular-, Drag-and-drop- und Fixture-Regressionen. Synthetische, lizenzfreie Referenzdateien liegen unter `TestFixtures/`; ihre Herkunft und erwarteten Inhalte sind in `TestFixtures/README.md` dokumentiert. `fixture-form.pdf` enthält ein vorausgefülltes Textfeld, eine aktivierte Checkbox und eine vorhandene Notizanmerkung. `fixture-outline-4-pages.pdf` enthält vier Seiten mit verschachteltem PDF-Inhaltsverzeichnis. Tests prüfen unter anderem Outline-Zielseiten nach strukturellen Seitenänderungen, isolierte lokale Lesezeichen/Leseposition, verspätete Rückmeldungen ersetzter PDF-Ansichten, Feld-Erkennung, Bearbeitungsgrenzen, Dirty-State und tatsächliches Speichern/Wiederöffnen.

Für einen tatsächlichen macOS-Oberflächentest mit Bedienungshilfen-Zugriff die zu prüfende App zunächst regulär schließen und danach ausführen:

```bash
./script/run_ui_smoke.sh \
  --app "$HOME/Applications/Klarfolio PDF Editor Dev.app" \
  --require-ui
```

Der Smoke verwendet ausschließlich synthetische Projekt-Fixtures beziehungsweise temporäre Fixture-Kopien und prüft die echte Accessibility-Oberfläche einschließlich Outline-Navigation, persönlicher Lesezeichen, wiederhergestellter Leseposition und tatsächlicher Formularänderungen. Ein App-Neustart und jedes erfolgreiche Öffnen einer vorhandenen PDF müssen dabei wieder im Lesemodus beginnen; Bearbeitung wird immer ausdrücklich aktiviert. Die versionierten Original-Fixtures und benutzereigene Dokumente bleiben unangetastet. CI darf mit `--allow-headless` nur dann ausdrücklich als übersprungen kennzeichnen, wenn keine grafische Sitzung oder keine Bedienungshilfen-Berechtigung vorhanden ist; ein solcher Skip ist kein bestandener UI-Test.

Wenn nur die Command Line Tools aktiv sind und Swift das Modul `Testing` nicht findet, kann der bereits validierte lokale Fallback verwendet werden:

```bash
swift test --disable-sandbox \
  -Xswiftc -F/Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath \
  -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath \
  -Xlinker /Library/Developer/CommandLineTools/Library/Developer/usr/lib
```

## Trennung der Builds

| Build | Bundle-ID | Zweck |
| --- | --- | --- |
| Lokale Entwicklungs-App | `at.ostheimer.klarfoliopdf.debug` | Tägliche Nutzung und Entwicklung; `install_local_dev.sh` aktualisiert ausschließlich diesen Build. |
| Vorhandene normale lokale Ad-hoc-App | `at.ostheimer.klarfoliopdf` | Nur nach eindeutiger Herkunftsprüfung, Backup und ausdrücklichem lokalem Abgleich. |
| Release/App Store | `at.ostheimer.klarfoliopdf` | Echt signierte Veröffentlichung; darf niemals durch einen lokalen Ad-hoc-Build ersetzt werden. |

Eine lokale ad-hoc-Signatur ist nur für Entwicklung und persönliche Nutzung gedacht. Sie ersetzt keine Apple-Distribution-Signatur, Notarisierung oder App-Store-Prüfung.
