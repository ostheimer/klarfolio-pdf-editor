struct PDFFormField: Identifiable, Equatable {
    enum Kind: Equatable {
        case text
        case checkbox
    }

    let id: String
    let name: String
    let title: String
    let pageIndex: Int
    let kind: Kind
    let textValue: String
    let isChecked: Bool
    let isReadOnly: Bool
    let maximumLength: Int
}
