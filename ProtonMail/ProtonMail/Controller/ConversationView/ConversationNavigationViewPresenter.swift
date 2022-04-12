import UIKit

class ConversationNavigationViewPresenter {

    func present(viewType: NavigationViewType, in navigationItem: UINavigationItem) {
        let newTitleView = viewType.titleView
        switch navigationItem.titleView {
        case .some(let view) where view is ConversationNavigationDetailView && viewType.isSimple:
            hide(titleView: view, duration: 0.25) { [weak self] in
                self?.present(titleView: newTitleView, in: navigationItem, duration: 0.25)
            }
        case .some(let view) where view is ConversationNavigationSimpleView && viewType.isDetailed:
            hide(titleView: view, duration: 0.25) { [weak self] in
                self?.present(titleView: newTitleView, in: navigationItem, duration: 0.25)
            }
        case .none:
            present(titleView: newTitleView, in: navigationItem, duration: 0.25)
        default:
            break
        }
    }

    private func present(titleView: UIView, in navigationItem: UINavigationItem, duration: Double) {
        titleView.subviews.forEach { $0.alpha = 0 }
        navigationItem.titleView = titleView
        UIView.animate(withDuration: duration) {
            titleView.subviews.forEach { $0.alpha = 1 }
        }
    }

    private func hide(titleView: UIView, duration: Double, completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: duration,
            animations: {
                titleView.subviews.forEach { $0.alpha = 0 }
            }, completion: { _ in
                completion()
            }
        )
    }

}

extension NavigationViewType {

    var titleView: UIView {
        switch self {
        case let .simple(subject):
            let titleView = ConversationNavigationSimpleView()
            titleView.titleLabel.attributedText = subject
            return titleView
        case let .detailed(subject, numberOfMessages):
            let titleView = ConversationNavigationDetailView()
            titleView.topLabel.attributedText = numberOfMessages
            titleView.bottomLabel.attributedText = subject
            return titleView
        }
    }

}
