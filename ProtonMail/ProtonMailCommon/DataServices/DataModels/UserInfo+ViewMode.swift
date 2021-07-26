import ProtonCore_Common
import ProtonCore_DataModel

enum ViewMode: Int {
    case conversation = 0
    case singleMessage = 1
}

extension UserInfo {

    var viewMode: ViewMode {
        ViewMode(rawValue: groupingMode) ?? .conversation
    }

}
