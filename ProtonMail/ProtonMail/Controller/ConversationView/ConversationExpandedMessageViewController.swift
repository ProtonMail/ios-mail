import UIKit

class ConversationExpandedMessageViewController: UIViewController {

    let viewModel: ConversationExpandedMessageViewModel
    private(set) lazy var customView = ConversationExpandedMessageView()
    private let singleMessageContentViewController: SingleMessageContentViewController

    init(viewModel: ConversationExpandedMessageViewModel,
         singleMessageContentViewController: SingleMessageContentViewController) {
        self.viewModel = viewModel
        self.singleMessageContentViewController = singleMessageContentViewController
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        embedChildren()
    }

    private func embedChildren() {
        embed(singleMessageContentViewController, inside: customView.contentContainer)
    }

    required init?(coder: NSCoder) {
        nil
    }

}
