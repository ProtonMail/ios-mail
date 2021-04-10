import PMUIFoundations
import UIKit

class SingleMessageViewController: UIViewController {

    private(set) lazy var customView = SingleMessageView()

    private let viewModel: SingleMessageViewModel
    private lazy var starBarButton = UIBarButtonItem(
        image: nil,
        style: .plain,
        target: self,
        action: #selector(starButtonTapped)
    )

    init(viewModel: SingleMessageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = starBarButton
        starButtonSetUp(starred: viewModel.starred)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.markReadIfNeeded()
        viewModel.userActivity.becomeCurrent()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        viewModel.userActivity.invalidate()
    }

    private func starButtonSetUp(starred: Bool) {
        starBarButton.image = starred ?
            Asset.messageDeatilsStarActive.image : Asset.messageDetailsStarInactive.image
        starBarButton.tintColor = starred ? UIColorManager.NotificationWarning : UIColorManager.IconWeak
    }

    @objc
    private func starButtonTapped() {
        viewModel.starTapped()
        starButtonSetUp(starred: viewModel.starred)
    }

    required init?(coder: NSCoder) {
        nil
    }

}

extension SingleMessageViewController: Deeplinkable {

    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(
            name: String(describing: SingleMessageViewController.self),
            value: viewModel.message.messageID
        )
    }

}
