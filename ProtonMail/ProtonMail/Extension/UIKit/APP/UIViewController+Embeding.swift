import UIKit

extension UIViewController {

    func embed(_ childController: UIViewController, inside targetView: UIView) {
        addChild(childController)

        if let controllerView = childController.view {
            targetView.addSubview(controllerView)

            [
                controllerView.topAnchor.constraint(equalTo: targetView.topAnchor),
                controllerView.leadingAnchor.constraint(equalTo: targetView.leadingAnchor),
                controllerView.trailingAnchor.constraint(equalTo: targetView.trailingAnchor),
                controllerView.bottomAnchor.constraint(equalTo: targetView.bottomAnchor)
            ].activate()
        }

        childController.didMove(toParent: self)
    }

    func unembed(_ childController: UIViewController) {
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }

}
