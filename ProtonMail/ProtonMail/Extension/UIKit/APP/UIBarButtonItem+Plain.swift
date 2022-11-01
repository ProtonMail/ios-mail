import UIKit

extension UIBarButtonItem {

    static func plain(image: UIImage? = nil, target: Any?, action: Selector?) -> UIBarButtonItem {
        UIBarButtonItem(image: image, style: .plain, target: target, action: action)
    }

}
