import Foundation

extension NSUserActivity {

    static func messageDetailsActivity(messageId: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "Handoff.Message")
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = false
        activity.isEligibleForPublicIndexing = false
        if #available(iOS 12.0, *) {
            activity.isEligibleForPrediction = false
        }

        let deeplink = DeepLink(String(describing: MenuViewController.self))
        deeplink.append(.init(name: String(describing: MailboxViewController.self), value: Message.Location.inbox))
        deeplink.append(.init(name: String(describing: SingleMessageViewController.self), value: messageId))

        if let deeplinkData = try? JSONEncoder().encode(deeplink) {
            activity.addUserInfoEntries(from: ["deeplink": deeplinkData])
        }

        return activity
    }

}
