import UIKit

extension UIViewController {

    func embed(_ childController: UIViewController, inside targetView: UIView) {
        embed(childController) { controllerView in
            targetView.addSubview(controllerView)

            [
                controllerView.topAnchor.constraint(equalTo: targetView.topAnchor),
                controllerView.leadingAnchor.constraint(equalTo: targetView.leadingAnchor),
                controllerView.trailingAnchor.constraint(equalTo: targetView.trailingAnchor),
                controllerView.bottomAnchor.constraint(equalTo: targetView.bottomAnchor),
            ].activate()
        }
    }

    func embed(_ childController: UIViewController, using embeddingMethod: (UIView) -> Void) {
        addChild(childController)
        embeddingMethod(childController.view)
        childController.didMove(toParent: self)
    }

    func unembed(_ childController: UIViewController) {
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }

}
