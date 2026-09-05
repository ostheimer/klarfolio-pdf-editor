# Geschützte PDFs – erster Mac-Slice (#22)

Basis: `514504c` (#20 / PR #21). Prüfung vom 5. September 2026 auf macOS 26.6.2 (25G83) mit Xcode 26.6 (17F113) / Swift 6.3.3. Keine Nutzerpasswörter, keine Nutzerzertifikate, keine Veröffentlichung.

## Befund und Entscheidung

Vier ausführbare Regressionstests mit sechs Fällen ergaben vor der Umsetzung **18 fehlgeschlagene Erwartungen**: direkte Seiten-/Annotationsaktionen mutierten im Reader, gesperrte PDFKit-Aktionen erzeugten fälschlich Dirty-State, geschützte Seiten konnten exportiert werden, signierte Dateien wurden verändert/neu gespeichert und eine abgebrochene Passwortöffnung ersetzte ein dirty Dokument. Dieselben Tests sind nach der Änderung grün.

`swift script/probe_pdf_protection.swift TestFixtures` prüft den bestehenden `PDFDocument.write(to:)`-Pfad unabhängig vom Store. Beobachtung auf dieser Plattform: Alle fünf AES-128-Fixtures lieferten beim Schreiben `true`; die Ausgaben waren verschlüsselt und gesperrt, ließen sich aber weder mit leerem Passwort noch den ursprünglichen synthetischen Benutzer-/Eigentümerpasswörtern öffnen. Dies ist ein Befund für den geprüften Speicherpfad und die geprüfte Plattform, keine universelle Aussage über PDFKit-Versionen. Deshalb gibt dieser Slice verschlüsselte Dokumente **ausschließlich zum Lesen** frei; auch Save As, Extraktion, Split und Nutzung als Merge-Quelle bleiben gesperrt. Es werden keine Passwörter zur späteren Neuverschlüsselung aufbewahrt.

PDFKit meldet `allowsDocumentChanges` auch bei reinen Formular-/Assembly-Rechten als wahr. Die spezifischen Eigenschaften unterscheiden Formular, Kommentar und Seitenverwaltung korrekt. Die konservative Verschlüsselungsgrenze verhindert, dass die breite Eigenschaft in diesem Slice Schreibrechte erweitert.

Primärreferenzen: Apples [PDFDocument-Rechte](https://developer.apple.com/documentation/pdfkit/pdfdocument/allowsdocumentassembly) beschreiben Assembly getrennt von Formularen und Kommentaren; der [CGPDF-Katalog](https://developer.apple.com/documentation/coregraphics/cgpdfdocument) und [typisierte Dictionary-Zugriffe](https://developer.apple.com/documentation/coregraphics/cgpdfdictionary) bilden die Grundlage der Strukturerkennung. Der tatsächlich verwendete Writer und seine Passwortoptionen wurden zusätzlich im installierten Apple-SDK-Header `PDFDocument.h` und empirisch geprüft.

## Zentrale Operationsmatrix

| Operation | PDF-Recht | Arbeitsmodus | Zusätzliche Grenze |
| --- | --- | --- | --- |
| Lesen, Suche, Navigation, lokale Lesezeichen | Erfolgreich entsperrt | Beide | Keine PDF-Mutation |
| Formularfelder | FormFieldEntry oder Commenting | Bearbeiten | Feldtyp, Identität und Feld-Schreibschutz |
| Annotationen einschließlich Drag/Tastatur | Commenting | Bearbeiten | Aktuelle Dokument-/Seitenidentität; keine Widgets/Popups |
| Seiten einfügen, importieren, löschen, drehen, verschieben | DocumentAssembly | Bearbeiten | Quelle und Ziel getrennt prüfen |
| Crop und Rücksetzen | DocumentChanges | Bearbeiten | Bestehender Crop-Session-/Geometrie-Guard |
| Extraktion, Split, Merge-Quelle | Copying | Bearbeiten für Zielaktion | Kein Umschreiben geschützter Quellen |
| Speichern und Sichern unter | Mindestens ein Änderungsrecht | Beide | Dirty Dokument bleibt auch nach Reader-Wechsel speicherbar |
| Kopieren | Copying | Beide | Bewachter PDFView-Einstieg; kein freier PDFKit-Exportkontext |
| Drucken | Printing | Beide | Beide PDFView-Print-Varianten und geerbter NSView-Druckbefehl bewacht |

Für **jede PDF-Mutation und jeden PDF-Neuschreibpfad** kommt zusätzlich dieselbe Sperre hinzu: verschlüsselt, gesperrt, vorhandene digitale Signatur oder unklarer Signaturstatus. Lesen/Kopieren/Drucken behaupten keine Signaturgültigkeit. Es gibt keine neue Druckoberfläche; die vorhandenen nativen Einstiegspunkte sind abgesichert.

## Öffnen und native Aktionen

Die neue Datei wird lokal geladen und über `NSSecureTextField` entsperrt, bevor der Guard für ungespeicherte Änderungen erscheint. Falsche Eingaben erlauben Wiederholung, Abbrechen erhält Dokument, Dirty-State, Modus und Auswahl. Passwörter stehen nur kurzzeitig im lokalen Aufruf und im anschließend geleerten sicheren Textfeld; sie werden nicht protokolliert, in Preferences geschrieben oder als Store-Zustand gehalten. Swift-/PDFKit-internes Speichermanagement erlaubt keine Zusage kryptografischer Speicherlöschung.

Reentrantes Öffnen und veraltete Dialogrückmeldungen werden gegen Dokumentidentität/Revision geprüft. Der View verschiebt Annotationen ausschließlich über den Store, niemals vor dessen Guard. Native Widgets und Reset-Aktionen bleiben blockiert; Formularänderungen laufen über den Inspektor. Das native Kontextmenü bietet nur bewachtes Kopieren, keine unkontrollierten Annotation-/Bildexportaktionen. Gewöhnliche lokale und Web-Links bleiben verfügbar; weitere native Action-Typen bleiben gesperrt.

## Signaturerkennung und Fixtures

Die App liest die geparste CGPDF-Struktur: AcroForm/Fields, Kids/Parent-Vererbung, Seiten-Widgets und Perms/DocMDP. Ein befülltes Signaturwörterbuch mit Contents und ByteRange wird konservativ geschützt. Leere Felder ohne Wert und bloß sichtbare `/Sig`-/`ByteRange`-Zeichenfolgen sind keine vorhandene Signatur. Fehlerhafte befüllte Signaturstrukturen bleiben schreibgeschützt. Traversierung ist gegen Zyklen und übermäßige Tiefe/Anzahl begrenzt. Dies ist **keine Zertifikats-, Vertrauenskette- oder Signaturvalidierung in der App**.

Die versionierte signed-Fixture enthält tatsächlich eine detached CMS-Signatur. Ein eigener Regressionstest prüft mit `/usr/bin/openssl cms -verify -binary -noverify` ihre Integrität und weist eine absichtlich manipulierte Nutzlast ab. `-noverify` überspringt die Zertifikats-Vertrauenskette, nicht die Signaturintegritätsprüfung. Herkunft, öffentliche Testpasswörter und reproduzierbarer Generator stehen in [TestFixtures/README.md](../../TestFixtures/README.md).

## Nachweise

Lokal bestanden: **151 Tests in elf Suites**, Debug- und Release-Build, **105 echte AX-Prüfungen** am isolierten ad-hoc-signierten Bundle `at.ostheimer.klarfoliopdf.qa22`, Shell-/Plist-/Website-/JavaScript-Prüfungen und `git diff --check`. Der abschließende Lauf verwendet die versionierten Fixture-Bytes; keine ursprüngliche Fixture wurde verändert. Die ergänzende CUA-Sichtprüfung bestätigt Passwort-Wiederholung, Reader-First, lesbare Formularpositionen und den sichtbaren Signaturhinweis. Ein direkter nativer AX-Schreibversuch auf das Passwort-Fixture-Formular wurde abgewiesen.

Der erweiterte AX-Harness prüft zusätzlich zum bisherigen Crop-/Reader-/Formularumfang sichere Passwortwiederholung/Abbruch, dirty Dokumentwechsel, Reader-First, sichtbare Schutzgründe, gesperrte Bedienfelder/Kürzel sowie unsigned Negativkontrollen und unveränderte Fixture-Bytes. Ein Headless-Skip ist kein UI-Pass. Zeitgebundene PR-/main-CI-URLs, PM-Review-Head und Installations-/Backup-Belege werden bei der Abnahme in [Issue #22](https://github.com/ostheimer/klarfolio-pdf-editor/issues/22) festgehalten. Die Installation folgt unverändert den exakten Herkunfts-, Prozess-, Dirty- und Backup-Prüfungen in [Lokale Entwicklung](local-development.md).

Zusätzliche Regressionen sichern interne Linkziele beim Merge mehrerer Quellen in ein vorhandenes Ziel einschließlich Save/Reopen und unveränderter Quellen ab. Der NSWindow-KeyView-Test enthält native PDFView-Nachfahren und belegt Tab/Shift-Tab zu legitimen externen Controls. Tatsächliche PDFView-Mouse-Events prüfen: Marker/Text verändern weder Werkzeug noch Annotationsbounds/Dirty-State, das Auswahlwerkzeug verschiebt weiterhin. Diese Fälle wurden zunächst rot reproduziert.
