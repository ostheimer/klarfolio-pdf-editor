import PDFKit

enum PDFReaderInteractionPolicy {
    static func blocksFormInteraction(
        at point: CGPoint,
        on page: PDFPage,
        workspaceMode: PDFWorkspaceMode
    ) -> Bool {
        switch workspaceMode {
        case .reading, .editing:
            return page.annotations.contains { annotation in
                (annotation.hasSubtype(.widget) || annotation.action is PDFActionResetForm)
                    && annotation.shouldDisplay
                    && annotation.bounds.contains(point)
            }
        }
    }
}
