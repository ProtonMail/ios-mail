import ProtonCore_UIFoundations
import UIKit

class ConversationViewController: UIViewController,
                                  UITableViewDataSource, UITableViewDelegate,
                                  UIScrollViewDelegate, ComposeSaveHintProtocol {

    private var actionBar: PMActionBar?
    let viewModel: ConversationViewModel
    private let conversationNavigationViewPresenter = ConversationNavigationViewPresenter()
    private let conversationMessageCellPresenter = ConversationMessageCellPresenter()

    private lazy var starBarButton = UIBarButtonItem.plain(target: self, action: #selector(starButtonTapped))

    private(set) lazy var customView = ConversationView()
    private lazy var actionSheetPresenter = MessageViewActionSheetPresenter()
    private let coordinator: ConversationCoordinator
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()

    init(coordinator: ConversationCoordinator,
         viewModel: ConversationViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyBackButtonTitleForNextView()
        setUpTableView()
        navigationItem.rightBarButtonItem = starBarButton
        starButtonSetUp(starred: false)
        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
        customView.separator.isHidden = true

        viewModel.reloadTableView = { [weak self] in
            self?.customView.tableView.reloadData()
        }

        viewModel.fetchConversationDetails()
        showActionBar()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataSource = viewModel.dataSource[indexPath.row]
        switch dataSource {
        case .header(let subject):
            let cell = tableView.dequeue(cellType: ConversationViewHeaderCell.self)
            let style = FontManager.MessageHeader.alignment(.center)
            cell.customView.titleLabel.attributedText = subject.apply(style: style)
            return cell
        case .message(let viewModel):
            switch viewModel.state {
            case .collapsed(let viewModel):
                let cell = tableView.dequeue(cellType: ConversationMessageCell.self)
                conversationMessageCellPresenter.present(model: viewModel.model, in: cell.customView)
                return cell
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cell = customView.tableView.visibleCells.compactMap({ $0 as? ConversationViewHeaderCell }).first {
            let headerLabelConvertedFrame = cell.convert(cell.customView.titleLabel.frame, to: customView.tableView)
            let shouldPresentDetailedNavigationTitle = scrollView.contentOffset.y >= headerLabelConvertedFrame.maxY
            shouldPresentDetailedNavigationTitle ? presentDetailedNavigationTitle() : presentSimpleNavigationTitle()

            let separatorConvertedFrame = cell.convert(cell.customView.separator.frame, to: customView.tableView)
            let shouldShowSeparator = customView.tableView.contentOffset.y >= separatorConvertedFrame.maxY
            customView.separator.isHidden = !shouldShowSeparator

            cell.customView.topSpace = scrollView.contentOffset.y < 0 ? scrollView.contentOffset.y : 0
        } else {
            presentDetailedNavigationTitle()
            customView.separator.isHidden = false
        }
    }

    private func presentDetailedNavigationTitle() {
        conversationNavigationViewPresenter.present(viewType: viewModel.detailedNavigationViewType, in: navigationItem)
    }

    private func presentSimpleNavigationTitle() {
        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
    }

    @objc
    private func starButtonTapped() {}

    private func starButtonSetUp(starred: Bool) {
        starBarButton.image = starred ?
            Asset.messageDeatilsStarActive.image : Asset.messageDetailsStarInactive.image
        starBarButton.tintColor = starred ? UIColorManager.NotificationWarning : UIColorManager.IconWeak
    }

    private func setUpTableView() {
        customView.tableView.dataSource = self
        customView.tableView.delegate = self
        customView.tableView.register(cellType: ConversationViewHeaderCell.self)
        customView.tableView.register(cellType: ConversationMessageCell.self)
    }

    required init?(coder: NSCoder) {
        nil
    }

}

// MARK: - Action Bar
private extension ConversationViewController {
    private func showActionBar() {
        guard self.actionBar == nil else {
            return
        }

        let actions = viewModel.getActionTypes()
        var actionBarItems: [PMActionBarItem] = []
        for (key, action) in actions.enumerated() {
            let actionHandler: (PMActionBarItem) -> Void = { [weak self] _ in
                switch action {
                case .more:
                    self?.moreButtonTapped()
                case .reply:
                    self?.coordinator.navigate(to: .reply)
                case .replyAll:
                    self?.coordinator.navigate(to: .replyAll)
                case .delete:
                    self?.showDeleteAlert(deleteHandler: { [weak self] _ in
                        self?.viewModel.handleActionBarAction(action)
                        self?.navigationController?.popViewController(animated: true)
                    })
                default:
                    self?.viewModel.handleActionBarAction(action)
                    self?.navigationController?.popViewController(animated: true)
                }
            }

            let actionBarItem: PMActionBarItem
            if key == actions.startIndex {
                actionBarItem = PMActionBarItem(icon: action.iconImage,
                                                text: action.name,
                                                handler: actionHandler)
            } else {
                actionBarItem = PMActionBarItem(icon: action.iconImage,
                                                backgroundColor: .clear,
                                                handler: actionHandler)
            }
            actionBarItems.append(actionBarItem)
        }
        let separator = PMActionBarItem(width: 1,
                                        verticalPadding: 6,
                                        color: UIColorManager.FloatyText)
        actionBarItems.insert(separator, at: 1)
        self.actionBar = PMActionBar(items: actionBarItems,
                                     backgroundColor: UIColorManager.FloatyBackground,
                                     floatingHeight: 42.0,
                                     width: .fit,
                                     height: 48.0)
        self.actionBar?.show(at: self)
    }

    private func showDeleteAlert(deleteHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: LocalString._warning,
                                      message: LocalString._messages_will_be_removed_irreversibly,
                                      preferredStyle: .alert)
        let yes = UIAlertAction(title: LocalString._general_delete_action, style: .destructive, handler: deleteHandler)
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel)
        [yes, cancel].forEach(alert.addAction)

        self.present(alert, animated: true, completion: nil)
    }

    private func moreButtonTapped() {
        guard let navigationVC = self.navigationController,
              let newestMessage = viewModel.dataSource.newestMessage else { return }
        let actionSheetViewModel = MessageViewActionSheetViewModel(title: newestMessage.subject,
                                                                   labelID: viewModel.labelId)
        actionSheetPresenter.present(on: navigationVC,
                                     viewModel: actionSheetViewModel) { [weak self] action in
            self?.handleActionSheetAction(action)
        }
    }
}

// MARK: - Action Sheet Actions
private extension ConversationViewController {
    func handleActionSheetAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .reply, .replyAll, .forward:
            handleOpenComposerAction(action)
        case .labelAs:
            showLabelAsActionSheet()
        case .moveTo:
            showMoveToActionSheet()
        case .print:
            #warning("TODO: (Mustapha) Handle message printing in conversation, without message only related VCs")
        case .viewHeaders, .viewHTML:
            handleOpenViewAction(action)
        case .dismiss:
            let actionSheet = navigationController?.view.subviews.compactMap { $0 as? PMActionSheet }.first
            actionSheet?.dismiss(animated: true)
        case .delete:
            showDeleteAlert(deleteHandler: { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            })
        case .reportPhishing:
            showPhishingAlert { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            }
        default:
            viewModel.handleActionSheetAction(action, completion: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
        }
    }

    private func handleOpenComposerAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .reply:
            coordinator.navigate(to: .reply)
        case .replyAll:
            coordinator.navigate(to: .replyAll)
        case .forward:
            coordinator.navigate(to: .forward)
        default:
            return
        }
    }

    private func handleOpenViewAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .viewHeaders:
            if let url = viewModel.getMessageHeaderUrl() {
                coordinator.navigate(to: .viewHeaders(url: url))
            }
        case .viewHTML:
            if let url = viewModel.getMessageBodyUrl() {
                coordinator.navigate(to: .viewHTML(url: url))
            }
        default:
            return
        }
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

extension ConversationViewController: LabelAsActionSheetPresentProtocol {
    var labelAsActionHandler: LabelAsActionSheetProtocol {
        return viewModel
    }

    func showLabelAsActionSheet() {
        let labels = labelAsActionHandler.getLabelMenuItems()
        let labelAsViewModel = LabelAsActionSheetViewModelConversations(menuLabels: labels,
                                                                        conversations: [viewModel.conversation])

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        self?.coordinator.pendingActionAfterDismissal = { [weak self] in
                            self?.showLabelAsActionSheet()
                        }
                        self?.coordinator.navigate(to: .addNewLabel)
                     },
                     selected: { [weak self] menuLabel, isOn in
                        self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isArchive, currentOptionsStatus  in
                        if let conversation = self?.viewModel.conversation {
                            self?.labelAsActionHandler
                                .handleLabelAsAction(conversations: [conversation],
                                                     shouldArchive: isArchive,
                                                     currentOptionsStatus: currentOptionsStatus)
                        }
                        self?.dismissActionSheet()
                        self?.navigationController?.popViewController(animated: true)
                     })
    }
}

extension ConversationViewController: MoveToActionSheetPresentProtocol {
    var moveToActionHandler: MoveToActionSheetProtocol {
        return viewModel
    }

    func showMoveToActionSheet() {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let moveToViewModel =
            MoveToActionSheetViewModelConversations(menuLabels: viewModel.getFolderMenuItems(),
                                                    conversations: [viewModel.conversation],
                                                    isEnableColor: isEnableColor,
                                                    isInherit: isInherit,
                                                    labelId: viewModel.labelId)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        self?.coordinator.pendingActionAfterDismissal = { [weak self] in
                            self?.showMoveToActionSheet()
                        }
                        self?.coordinator.navigate(to: .addNewFolder)
                     },
                     selected: { [weak self] menuLabel, isOn in
                        self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isHavingUnsavedChanges in
                        defer {
                            self?.dismissActionSheet()
                            self?.navigationController?.popViewController(animated: true)
                        }
                        guard isHavingUnsavedChanges, let conversation = self?.viewModel.conversation else {
                            return
                        }
                        self?.moveToActionHandler.handleMoveToAction(conversations: [conversation])
                     })
    }
}
