import UIKit

extension UIViewController {

    public func embed(_ childController: UIViewController, inside view: UIView) {
        addChild(childController)
        view.addSubview(childController.view)

        [
            childController.view.topAnchor.constraint(equalTo: view.topAnchor),
            childController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ].activate()

        childController.didMove(toParent: self)
    }

    public func unembed(_ childController: UIViewController) {
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }

}
