enum NavigationViewType: Equatable {
    case simple(numberOfMessages: NSAttributedString)
    case detailed(subject: NSAttributedString, numberOfMessages: NSAttributedString)
}

extension NavigationViewType {

    var isSimple: Bool {
        guard case .simple = self else { return false }
        return true
    }

    var isDetailed: Bool {
        guard case .detailed = self else { return false }
        return true
    }

}
