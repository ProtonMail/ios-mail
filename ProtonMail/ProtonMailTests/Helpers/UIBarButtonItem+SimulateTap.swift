import UIKit

extension UIBarButtonItem { // MG: - Remove and used a function from Core

    func simulateTap() {
        if let action = action {
            _ = target?.perform(action, with: self)
        }
    }

}
