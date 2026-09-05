# Reproduzierbare PDF-Testdateien

## Schutz-Fixtures (#22)

`script/generate_protection_fixtures.py` erzeugt acht kleine dreiseitige Ableitungen der unveränderten Formular- und Merge-Fixtures. Die Formularpositionen sind für diese Ableitungen entzerrt. Abhängigkeiten: Python mit `pypdf==6.10.0`, `cryptography==50.0.1` sowie OpenSSL. Aufruf: `python3 script/generate_protection_fixtures.py`. Erzeugung ist semantisch reproduzierbar; zufällige AES-IVs und ein neu erzeugter, ausschließlich flüchtiger RSA-Schlüssel führen bewusst zu anderen Bytes. Im Repository stehen nur die fertigen Referenz-PDFs, keine privaten Schlüssel.

| Datei | Schutz und Kontrolle |
| --- | --- |
| `fixture-password.pdf` | AES-128; Benutzerpasswort `klarfolio-test-open`, alle PDF-Rechte. |
| `fixture-restricted.pdf` | AES-128, leeres Öffnungspasswort; keine Änderungs-, Kopier- oder Druckrechte. |
| `fixture-form-only.pdf` | AES-128, leeres Öffnungspasswort; ausschließlich Formulareingabe. |
| `fixture-assembly-only.pdf` | AES-128, leeres Öffnungspasswort; ausschließlich Seitenverwaltung. |
| `fixture-comment-only.pdf` | AES-128, leeres Öffnungspasswort; Kommentare einschließlich Formulareingabe. |
| `fixture-signed.pdf` | Tatsächliche detached CMS-Signatur (RSA-2048/SHA-256), korrektes ByteRange/Contents; synthetisches selbstsigniertes Testzertifikat mit CN `Klarfolio Synthetic Test Only`, ohne Vertrauensbehauptung. |
| `fixture-empty-signature.pdf` | Echtes `/FT /Sig`-Widget ohne `/V`: noch keine Signatur. |
| `fixture-signature-placeholder.pdf` | Sichtbare FreeText-Unterschrift einschließlich wörtlichem `/Type /Sig /ByteRange [0 1 2 3]`: keine digitale Signatur. |

Alle verschlüsselten Fixtures nutzen das öffentlich dokumentierte synthetische Eigentümerpasswort `klarfolio-test-owner`. Diese Strings sind ausschließlich Testmaterial, keine Nutzergeheimnisse. Der Generator prüft die CMS-Integrität über `openssl cms -verify -binary -noverify`; `-noverify` überspringt die Vertrauenskette. Die Swift-Suite prüft zusätzlich die versionierte Signatur und eine absichtlich veränderte, dann ungültige Nutzlast. Produktionscode erzeugt oder validiert keine Signaturen.

`swift script/probe_pdf_protection.swift TestFixtures` reproduziert getrennt vom Store den beobachteten PDFKit-Speicherbefund. Ausgaben liegen ausschließlich in einem automatisch entfernten temporären Verzeichnis. Die Original-Fixtures werden weder durch Tests noch UI-Smoke überschrieben. Details: [Schutz-QA](../docs/internal/protected-pdf-qa.md).

## Ursprüngliche Fixtures

Alle Dateien in diesem Verzeichnis wurden ausschließlich für Klarfolio synthetisch erstellt. Sie enthalten keine personenbezogenen Echtdaten, Kundeninhalte, fremden Dokumente, eingebetteten Schriftdateien oder lizenzpflichtigen Medien. Der Name „Andreas Test“ ist ein frei erzeugter Platzhalter.

Die ursprünglichen sechs PDFs sind bewusst kleine, unkomprimierte und vollständig versionierte ASCII-Dateien. Die acht Schutz-Fixtures aus #22 enthalten zusätzlich binäre Verschlüsselungs- beziehungsweise Signaturdaten. Dadurch bleiben Inhalte, PDF-Objekte und Cross-Reference-Tabellen im Repository nachvollziehbar und Änderungen ergeben lesbare Diffs. Die festen PDF-Cross-Reference-Einträge benötigen abschließende Füllzeichen; `.gitattributes` nimmt ausschließlich diese Test-PDFs deshalb von Git-Whitespace-Prüfungen aus.

| Datei | Erwarteter Inhalt | Abgedeckte Fälle |
| --- | --- | --- |
| `fixture-text-3-pages.pdf` | Drei A4-Seiten, durchsuchbarer Text, genau zwei Vorkommen von `Klarfolio-Testwort` und mehrzeiliger Inhalt. | Öffnen, Miniaturen, Seitennavigation, Volltextsuche, Extraktion und Teilen. |
| `fixture-outline-4-pages.pdf` | Vier A4-Seiten mit echten PDFKit-Outlines: `Einleitung` (Seite 1), `Kapitel 1` (Seite 2) mit verschachteltem `Abschnitt 1.1` (Seite 3) und `Kapitel 2` (Seite 4). | Reader-Navigation, verschachtelte Kapitelziele, Lesezeichen und Wiederherstellung der zuletzt gelesenen Seite. |
| `fixture-merge-2-pages.pdf` | Zwei A4-Seiten mit unterscheidbaren blauen beziehungsweise grünen Inhaltsbereichen. | Zusammenführen, Seitenreihenfolge und visuelle Wiedererkennung. |
| `fixture-form.pdf` | Eine A4-Seite, ein vorausgefülltes Textfeld, eine aktivierte Checkbox und eine vorhandene Notizanmerkung. | AcroForm-Erkennung, kontrollierte Text-/Checkboxbearbeitung, Widgetschutz, Dirty-Tracking, Speichern/Wiederöffnen und vorhandene Anmerkungen. |
| `fixture-invalid.pdf` | Bewusst ungültiger Text mit PDF-Dateiendung. | Ablehnung beschädigter beziehungsweise falsch bezeichneter Dateien ohne Dokumentverlust. |
| `fixture-crop-4-pages.pdf` | Vier synthetische Seiten mit MediaBox `[-40 75 360 675]` (400 × 600 pt), Drehungen 0/90/180/270, roten/blauen Eckmarken und drei Textzeilen. Helvetica ist als PDF-Basisschrift referenziert, nicht eingebettet. | Echte versetzte Ursprünge, gedrehte Vorschau, aktuelle Seite, wiederholter Zuschnitt, Mindestgröße, Save/Reopen, Rücksetzen und Wiederherstellung aller Textzeilen. |

Swift Package Manager kopiert die Dateien in ein separates Testressourcen-Bundle. Die Regressionstests laden sie über `PDFTestFixture`; die Originaldateien können zusätzlich direkt für den manuellen QA-Katalog verwendet werden.

Die Oberflächenprüfung lässt sich gegen ein gebautes App-Bundle mit `./script/run_ui_smoke.sh --app "/Pfad/Klarfolio PDF Editor.app" --require-ui` ausführen. Veränderte Formularwerte werden ausschließlich an einer temporären Kopie von `fixture-form.pdf` geprüft; das versionierte Original bleibt unverändert. Eine grafische Sitzung und erteilter macOS-Bedienungshilfen-Zugriff werden vorausgesetzt; `--allow-headless` kennzeichnet fehlende Voraussetzungen ausdrücklich als übersprungen.
