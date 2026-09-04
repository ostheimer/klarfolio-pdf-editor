import PDFKit
import SwiftUI

struct PageCropSheet: View {
    @ObservedObject var store: PDFDocumentStore
    let session: PDFCropSession
    @Environment(\.dismiss) private var dismiss
    @State private var selection: CGRect
    @State private var dragOrigin: CGRect?
    @State private var errorMessage: String?
    private let preview: NSImage

    init(store: PDFDocumentStore, session: PDFCropSession) {
        self.store = store
        self.session = session
        let crop = session.geometry.isValid(session.originalCrop) ? session.originalCrop : session.geometry.mediaBox
        _selection = State(initialValue: session.geometry.displayRect(for: crop))
        // Render the entire MediaBox, including previously hidden content. No live
        // PDFView or editable widgets are exposed in this draft preview.
        preview = session.page.thumbnail(of: CGSize(width: 1000, height: 1000), for: .mediaBox)
    }

    private var crop: CGRect { session.geometry.cropRect(for: selection) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seite \(session.pageIndex + 1) zuschneiden")
                .font(.title2.bold())
            Text("Zuschneiden blendet Inhalte nur aus. Es entfernt keine Inhalte und ist keine sichere Schwärzung.")
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("pageCrop.warning")
            Text("Ziehe einen Rahmen auf der Seite oder passe seine Ecken und Ränder an. Die Auswahl bleibt mindestens etwa 12,7 mm breit und hoch; bei kleineren Seiten bleibt die volle Größe erhalten.")
                .font(.caption).foregroundStyle(.secondary)
            cropPreview
                .frame(height: 340)
            HStack {
                marginControl("Links", edge: 0)
                marginControl("Oben", edge: 1)
                marginControl("Rechts", edge: 2)
                marginControl("Unten", edge: 3)
            }
            Text("Sichtbarer Bereich: \(millimeters(selection.width)) × \(millimeters(selection.height)) mm")
                .accessibilityIdentifier("pageCrop.size")
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
            HStack {
                Button("Auf Seitengröße zurücksetzen") {
                    if store.resetPageCrop(session: session) || session.originalCrop == session.geometry.mediaBox {
                        dismiss()
                    } else { errorMessage = "Die Seite wurde inzwischen geändert. Öffne den Zuschnitt erneut." }
                }
                .disabled(session.originalCrop == session.geometry.mediaBox)
                .accessibilityIdentifier("pageCrop.reset")
                Spacer()
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("pageCrop.cancel")
                Button("Anwenden") {
                    if store.applyPageCrop(crop, session: session) || crop == session.originalCrop {
                        dismiss()
                    } else { errorMessage = "Der Zuschnitt ist nicht mehr gültig. Öffne ihn erneut." }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!session.geometry.isValid(crop))
                .accessibilityIdentifier("pageCrop.apply")
            }
        }
        .padding(20)
        .frame(width: 650)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pageCrop.sheet")
        .onChange(of: store.workspaceMode) { _, mode in
            if mode != .editing { dismiss() }
        }
        .onChange(of: store.currentPageIndex) { _, _ in dismiss() }
        .onChange(of: store.document.map(ObjectIdentifier.init)) { _, _ in dismiss() }
    }

    private var cropPreview: some View {
        GeometryReader { available in
            let size = session.geometry.displaySize
            let scale = min(available.size.width / size.width, available.size.height / size.height)
            let width = size.width * scale
            let height = size.height * scale
            ZStack(alignment: .topLeading) {
                Image(nsImage: preview).resizable().frame(width: width, height: height)
                Path { path in
                    path.addRect(CGRect(x: 0, y: 0, width: width, height: height))
                    path.addRect(CGRect(x: selection.minX * scale, y: selection.minY * scale,
                                        width: selection.width * scale, height: selection.height * scale))
                }
                .fill(.black.opacity(0.45), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)
                Rectangle().stroke(.blue, lineWidth: 3)
                    .frame(width: selection.width * scale, height: selection.height * scale)
                    .offset(x: selection.minX * scale, y: selection.minY * scale)
                    .allowsHitTesting(false)
                ForEach(0..<4) { corner in
                    let point = cornerPoint(corner, in: selection)
                    Circle().fill(.white).overlay(Circle().stroke(.blue, lineWidth: 3))
                        .frame(width: 16, height: 16)
                        .position(x: point.x * scale, y: point.y * scale)
                        .gesture(DragGesture(coordinateSpace: .named("cropPreview"))
                            .onChanged { value in
                                if dragOrigin == nil { dragOrigin = selection }
                                let anchor = cornerPoint(3 - corner, in: dragOrigin ?? selection)
                                selection = session.geometry.selection(from: anchor,
                                    to: CGPoint(x: value.location.x / scale, y: value.location.y / scale))
                            }
                            .onEnded { _ in dragOrigin = nil })
                }
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .coordinateSpace(name: "cropPreview")
            .gesture(DragGesture(coordinateSpace: .named("cropPreview"))
                .onChanged { value in
                    selection = session.geometry.selection(
                        from: CGPoint(x: value.startLocation.x / scale, y: value.startLocation.y / scale),
                        to: CGPoint(x: value.location.x / scale, y: value.location.y / scale))
                })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Seitenvorschau mit Zuschneiderahmen. Verwende die Randregler zum Anpassen.")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cornerPoint(_ corner: Int, in rect: CGRect) -> CGPoint {
        CGPoint(x: corner % 2 == 0 ? rect.minX : rect.maxX, y: corner < 2 ? rect.minY : rect.maxY)
    }

    private func margin(_ edge: Int) -> CGFloat {
        switch edge {
        case 0: return selection.minX
        case 1: return selection.minY
        case 2: return session.geometry.displaySize.width - selection.maxX
        default: return session.geometry.displaySize.height - selection.maxY
        }
    }

    private func adjusted(_ edge: Int, by delta: CGFloat) -> CGRect {
        var result = selection
        switch edge {
        case 0: result.origin.x += delta; result.size.width -= delta
        case 1: result.origin.y += delta; result.size.height -= delta
        case 2: result.size.width -= delta
        default: result.size.height -= delta
        }
        return result
    }

    private func marginControl(_ title: String, edge: Int) -> some View {
        VStack {
            Text("\(title): \(millimeters(margin(edge))) mm").font(.caption)
            HStack {
                ForEach([-2, 2], id: \.self) { delta in
                    let points = CGFloat(delta) * PDFCropGeometry.pointsPerMillimeter
                    Button(delta < 0 ? "−" : "+") { selection = adjusted(edge, by: points) }
                        .accessibilityLabel("Rand \(title) um 2 mm \(delta < 0 ? "verkleinern" : "vergrößern")")
                        .accessibilityIdentifier("pageCrop.margin.\(edge).\(delta < 0 ? "decrease" : "increase")")
                        .disabled(!session.geometry.isValid(session.geometry.cropRect(for: adjusted(edge, by: points))))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func millimeters(_ points: CGFloat) -> String {
        Double(points / PDFCropGeometry.pointsPerMillimeter).formatted(.number.precision(.fractionLength(1)))
    }
}
