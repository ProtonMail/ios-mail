import ProtonCore_UIFoundations
import UIKit

class ConversationViewController: UIViewController, UITableViewDataSource, UIScrollViewDelegate, UITableViewDelegate {

    private let viewModel: ConversationViewModel
    private let conversationNavigationViewPresenter = ConversationNavigationViewPresenter()
    private let conversationMessageCellPresenter = ConversationMessageCellPresenter()

    private lazy var starBarButton = UIBarButtonItem.plain(target: self, action: #selector(starButtonTapped))

    private(set) lazy var customView = ConversationView()

    init(viewModel: ConversationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()
        navigationItem.rightBarButtonItem = starBarButton
        starButtonSetUp(starred: false)
        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
        customView.separator.isHidden = true

        viewModel.reloadTableView = { [weak self] in
            self?.customView.tableView.reloadData()
        }

        viewModel.fetchConversationDetails()
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
