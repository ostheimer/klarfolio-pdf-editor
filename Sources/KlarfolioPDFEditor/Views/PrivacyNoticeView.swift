import SwiftUI

struct PrivacyNoticeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Datenschutz", systemImage: "hand.raised")
                    .font(.largeTitle.bold())

                Text("Klarfolio PDF Editor verarbeitet die von dir ausgewählten PDF- und Bilddateien lokal auf deinem Mac.")
                    .font(.title3)

                privacySection(
                    title: "Dokumente",
                    text: "Die App öffnet und speichert nur Dateien und Speicherorte, die du über die macOS-Dateiauswahl, den Finder oder „Öffnen mit“ freigibst. Dokumentinhalte werden nach dem aktuellen Funktionsumfang nicht an den Anbieter oder an Dritte übertragen."
                )

                privacySection(
                    title: "Konten und Analyse",
                    text: "Die App benötigt kein Benutzerkonto und enthält keine Cloud-Synchronisierung, Werbung, Analyse, Telemetrie oder eingebundene Drittanbieter-SDKs für diese Zwecke."
                )

                privacySection(
                    title: "Deine Kontrolle",
                    text: "Gespeicherte Dateien verbleiben in den von dir gewählten Ordnern. Du kannst sie jederzeit im Finder verwalten oder löschen."
                )

                Divider()

                Text("Vor einer öffentlichen Veröffentlichung werden die verantwortliche Stelle, der Datenschutzkontakt und die endgültige öffentliche Datenschutz-URL ergänzt.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 620, height: 560)
    }

    private func privacySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}
