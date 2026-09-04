# Lokale Crop-Abnahme (#20)

## Umfang und Ergebnisse

- Ausgangspunkt: `d3251ee`, 113 Tests in sieben Suites, 50 echte Accessibility-Prüfungen.
- Neue Basis: 128 Tests in acht Suites, davon 15 gezielte Crop-Tests. Vier parametrisierte Tests führen die Drehungen 0/90/180/270 jeweils separat aus.
- Debug- und Release-Build erfolgreich; vollständige Suite, Website-Validator, JavaScript-Syntax, alle Shell-Skripte, Entitlements/Bundle-Plist und `git diff --check` erfolgreich.
- 82 echte macOS-Accessibility-Prüfungen mit `--require-ui` am lokal ad-hoc-signierten isolierten Bundle `/tmp/Klarfolio Crop QA.app`, Bundle-ID `at.ostheimer.klarfoliopdf.cropqa`. Darunter 16 explizite Crop-Szenarien (vier je Drehung) sowie die ergänzenden Reader-/Edit-Modusprüfungen. Die übrigen Formular-, Reader-, Outline-, Bookmark- und Dokumentenschutzfälle laufen weiter mit.
- Zusätzlich sichtbare Prüfung der MediaBox-Vorschau auf allen vier gedrehten Seiten; neuer Rahmen und Eckgriff wurden per echter Mausgeste bedient. Die Eckmarken, Außenabdunklung und Randmaße entsprechen der sichtbaren Orientierung. Entwürfe wurden abgebrochen; Originaldateien blieben unverändert.
- Randmaße und sichtbare Größe erscheinen benutzerfreundlich in Millimetern mit einer Nachkommastelle; Randregler verwenden 2-mm-Schritte. Der AX-Smoke prüft die sichtbaren Millimeterwerte und die dazugehörige gespeicherte PDF-Geometrie unabhängig (Toleranz 0,001 pt für die PDFKit-Serialisierung).
- CI prüft weiterhin macOS 15 / Xcode 16.4 und macOS 26 / Xcode 26.6. Fehlende grafische Sitzung/Accessibility wird ausdrücklich als Skip protokolliert und zählt nicht zu den 82 lokalen Prüfungen. Verbindliche Run- und Merge-Referenzen werden im PR sowie in #3/#8/#20 festgehalten.
- Die beiden installierten Nutzer-Apps werden erst nach Merge und nach erneuter Pfad-/Bundle-/Signatur-/Receipt-/Prozess-/Dirty-State-Prüfung aktualisiert. Ihr tatsächlicher Abschluss oder ein externer Restschritt wird ebenfalls in den GitHub-Nachweisen festgehalten.

## Rot-/Grün-Nachweise und PDFKit-Verhalten

Die normale automatische PR-Review erkannte eine verschobene Gegenecke beim Erreichen der Mindestgröße. Reproduzierende Tests sichern nun alle vier Eckgriffe bei Unterschreiten, Erreichen und Überschreiten des Ankers sowie beide äußeren Seitengrenzen ab. Der konkrete Fall Anker 300 / Zeiger 290 ergab zunächst 290…326 statt 264…300. Die Korrektur klemmt den gezogenen Eckgriff auf derselben Seite im Mindestabstand; der gegenüberliegende Anker bleibt fest. Die Tests wurden zuerst rot und danach grün ausgeführt. Randregler und Store-Validierung bleiben unverändert.

Die Umstellung auf 2-mm-Schritte reproduzierte einen echten Rotationsfehler: wiederholte Gleitkomma-Subtraktion lieferte bei 90/270 Grad einen Außenüberstand von ungefähr `1e-13` pt und deaktivierte einen zulässigen Randregler. Derselbe parametrisierte Geometrietest war zunächst für 90/270 Grad rot und nach der Korrektur für alle vier Drehungen grün. Die Vorschau→PDF-Konvertierung fängt ausschließlich Rundungsabweichungen unter `1e-9` pt an MediaBox-Kanten ab; die öffentliche Store-Validierung bleibt strikt. Zusätzlich werden minimale Gesten mit gebrochenen Koordinaten geprüft.

Der erste gezielte Testlauf schlug unter anderem für eine negative MediaBox-Rohbreite fehl: `CGRect.width` standardisiert das Vorzeichen. Die Validierung prüft nun `size.width/height`; derselbe Test ist grün. Die erste empirische Vorschauprüfung nahm fälschlich einen geflippten PDFView an und wurde durch den tatsächlichen Vergleich mit `PDFView.isFlipped == false` und der oberen Kante korrigiert. Feste erwartete PDF↔Vorschau-Rechtecke und der unabhängige PDFView-Vergleich bestehen für alle vier Drehungen und den Ursprung `(-40, 75)`; `bounds(for:)` liefert bei Drehungen unverändert ungedrehte Boxen.

Die anfänglich auf identische absolute Box-Ursprünge gerichtete Save/Reopen-Prüfung schlug mit der echten Crop-Fixture fehl: Der vorhandene PDFKit-Writer normalisiert `[-40 75 360 675]` zu `[0 0 400 600]`. Die mit der PM abgestimmte Invariante ist die gleiche Größe und der gleiche relative sichtbare Ausschnitt, nicht dieselbe absolute Ursprungszahl. Die Tests prüfen Rotation, aktuelle/andere Seiten, Formularwerte, Anmerkungen, Links, Outlines, lokale Lesedaten und nach Rücksetzen/Speichern/Wiederöffnen den vollständigen ursprünglichen Text. Ein eigener PDF-Writer wurde nicht eingeführt.

Der erste echte AX-Lauf erkannte das geöffnete Sheet nicht zuverlässig, weil dessen Kennung an alle Kind-Controls vererbt wurde. Eine explizite Accessibility-Containergrenze erhält nun die individuellen Control-Kennungen. Derselbe erweiterte Smoke besteht vollständig.

Der erste macOS-15-CI-Smoke scheiterte am exakten Textvergleich nach Rücksetzen. Der Diagnose-Lauf belegte ausschließlich zwei führende Leerzeichen sowie einen zusätzlichen abschließenden Zeilenumbruch mit Leerzeichen beim Original; die gespeicherte Kopie enthielt sämtliche Wörter unverändert. Der Smoke normalisiert daher Unicode-Whitespace und vergleicht die vollständigen, nicht leeren Tokenfolgen in identischer Reihenfolge. Fehlender, zusätzlicher oder veränderter Text bleibt ein Fehler. Der bytegenaue Vergleich der versionierten Original-Fixtures bleibt unverändert.

## Reproduktion

```bash
swift build -c debug
swift build -c release
swift test --parallel
APP_NAME="Klarfolio Crop QA" BUNDLE_ID="at.ostheimer.klarfoliopdf.cropqa" \
  ./script/build_app_bundle.sh --configuration debug \
  --output "/tmp/Klarfolio Crop QA.app" --sign-identity -
./script/run_ui_smoke.sh --app "/tmp/Klarfolio Crop QA.app" --require-ui
```

Vor einem erneuten Bundle-Build muss ausschließlich dieses isolierte Test-Bundle regulär geschlossen sein. Die Testdateien werden privat kopiert; keine Nutzerdokumente werden geschrieben. Die bestehenden Versions-Fixtures bleiben unverändert. Datenschutz, Veröffentlichung, App Store, Windows und systemweite PDF-Zuordnungen gehören nicht zu diesem Slice. Zuschneiden ist Ausblenden, keine sichere Schwärzung.
