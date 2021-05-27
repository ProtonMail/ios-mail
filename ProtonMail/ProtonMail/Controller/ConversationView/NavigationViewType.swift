enum NavigationViewType: Equatable {
    case simple(numberOfMessages: NSAttributedString)
    case detailed(subject: NSAttributedString, numberOfMessages: NSAttributedString)
}

extension NavigationViewType {

    var isSimple: Bool {
        guard case .simple(_) = self else { return false }
        return true
    }

    var isDetailed: Bool {
        guard case .detailed(_, _) = self else { return false }
        return true
    }

}
