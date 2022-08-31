import ProtonCore_UIFoundations

extension ConversationViewController {
    func handleActionSheetAction(_ action: MessageViewActionSheetAction, message: MessageEntity, body: String?) {
        switch action {
        case .reply, .replyAll, .forward:
            handleOpenComposerAction(action, message: message)
        case .labelAs:
            showLabelAsActionSheet(dataSource: .message(message))
        case .moveTo:
            showMoveToActionSheet(dataSource: .message(message))
        case .print:
            if let controller = contentController(for: message) {
                controller.presentPrintController()
            }
        case .saveAsPDF:
            if let controller = contentController(for: message) {
                controller.exportPDF()
            }
        case .viewHeaders, .viewHTML:
            handleOpenViewAction(action, message: message)
        case .dismiss:
            let actionSheet = navigationController?.view.subviews.compactMap { $0 as? PMActionSheet }.first
            actionSheet?.dismiss(animated: true)
        case .delete:
            showDeleteAlert(deleteHandler: { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, message: message) { [weak self] shouldDismissView in
                    guard shouldDismissView else { return }
                    self?.navigationController?.popViewController(animated: true)
                }
            })
        case .reportPhishing:
            showPhishingAlert { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, message: message, body: body) { _ in }
            }
        default:
            viewModel.handleActionSheetAction(action, message: message) { [weak self] shouldDismissView in
                guard shouldDismissView else { return }
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func handleOpenComposerAction(_ action: MessageViewActionSheetAction, message: MessageEntity) {
        switch action {
        case .reply:
            coordinator.handle(navigationAction: .reply(message: message))
        case .replyAll:
            coordinator.handle(navigationAction: .replyAll(message: message))
        case .forward:
            coordinator.handle(navigationAction: .forward(message: message))
        default:
            return
        }
    }

    private func handleOpenViewAction(_ action: MessageViewActionSheetAction, message: MessageEntity) {
        switch action {
        case .viewHeaders:
            if let url = viewModel.getMessageHeaderUrl(message: message) {
                coordinator.handle(navigationAction: .viewHeaders(url: url))
            }
        case .viewHTML:
            if let url = viewModel.getMessageBodyUrl(message: message) {
                coordinator.handle(navigationAction: .viewHTML(url: url))
            }
        default:
            return
        }
    }
}

extension ConversationViewController {

    private func showDeleteAlert(deleteHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: LocalString._warning,
                                      message: LocalString._messages_will_be_removed_irreversibly,
                                      preferredStyle: .alert)
        let yes = UIAlertAction(title: LocalString._general_delete_action, style: .destructive, handler: deleteHandler)
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel)
        [yes, cancel].forEach(alert.addAction)

        self.present(alert, animated: true, completion: nil)
    }

    private func showPhishingAlert(reportHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: LocalString._confirm_phishing_report,
                                      message: LocalString._reporting_a_message_as_a_phishing_,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: { _ in }))
        alert.addAction(.init(title: LocalString._general_confirm_action, style: .default, handler: reportHandler))
        self.present(alert, animated: true, completion: nil)
    }

}

private extension UIViewController {

    func contentController(for message: MessageEntity) -> SingleMessageContentViewController? {
        recursiveChildren
            .compactMap { $0 as? SingleMessageContentViewController }
            .first(where: { message.messageID == $0.viewModel.message.messageID })
    }

    private var recursiveChildren: [UIViewController] {
        children + children.flatMap(\.recursiveChildren)
    }

}
