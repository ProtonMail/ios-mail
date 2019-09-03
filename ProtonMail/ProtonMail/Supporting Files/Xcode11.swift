/*
 
 THIS FILE IS ONLY NEEDED TO LET XCODE 10 LINK PROJECT AGAINST IOS 13 SKD
 REMOVE IT WHEN FINALY MOVE TO XCODE 11
 DISABLE IT LOCALLY IF NEED TO WORK WITH XCODE 11
 
 DON'T FORGET TO REMOVE IT IN SEPTEMBER 2019
 
 */

import Foundation
import UserNotifications

protocol UIWindowSceneDelegate {}

class UISceneSession: Equatable, Hashable {
    static func == (lhs: UISceneSession, rhs: UISceneSession) -> Bool {
        return true
    }
    
    var userInfo: [AnyHashable: Any]?
    var stateRestorationActivity: NSUserActivity?
    var scene: UIScene?
    var role: Any?
    func hash(into hasher: inout Hasher) {
        // nothing
    }
}

class UISceneConfiguration {
    var delegateClass: AnyClass = NSObject.self
    init(name: Any, sessionRole: Any) { }
}

class UIScene {
    var session = UISceneSession()
    var userActivity: NSUserActivity?
    var activationState: State = .background
    var delegate: Any?
    enum State {
        case background
    }
    class ConnectionOptions {
        var userActivities: [NSUserActivity] = []
        var shortcutItem: UIApplicationShortcutItem?
        var handoffUserActivityType: String?
        
        @available(iOS 10.0, *)
        var notificationResponse: UNNotificationResponse? {
            return nil
        }
    }
}

class UIWindowScene: UIScene {
    static let willEnterForegroundNotification = NSNotification.Name.init("")
    static let didActivateNotification = NSNotification.Name.init("")
    static let didEnterBackgroundNotification = NSNotification.Name.init("")
    
    var title: String?
}

extension UIWindow {
    var windowScene: UIWindowScene? {
        get { return nil }
        set { /*nothing*/ }
    }
    
    convenience init(windowScene: UIWindowScene) {
        self.init()
    }
}

extension UIApplication {
    var openSessions: [UISceneSession] {
        return []
    }
    
    func requestSceneSessionDestruction(_ session: UISceneSession, options: Any?, handler: (NSError)->Void) {
        
    }
}
