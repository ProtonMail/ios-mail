//
//  WindowsCoordinator.swift
//  Proton Mail - Created on 12/11/2018.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Combine
import LifetimeTracker
import ProtonCoreDataModel
import ProtonCoreKeymaker
import ProtonCoreUIFoundations
import ProtonMailAnalytics
import SafariServices

final class WindowsCoordinator {
    typealias Dependencies = MenuCoordinator.Dependencies
    & LockCoordinator.Dependencies
    & HasKeychain
    & HasLaunchService
    & HasAppAccessResolver
    & HasNotificationCenter

    private lazy var snapshot = Snapshot()

    private var deepLink: DeepLink?

    private(set) var appWindow: UIWindow! = UIWindow(
        root: PlaceholderViewController(color: .red),
        scene: nil
    ) {
        didSet {
            guard appWindow == nil else { return }
            if let oldAppWindow = oldValue {
                oldAppWindow.rootViewController?.dismiss(animated: false)
                if oldAppWindow.rootViewController is PMSideMenuController {
                    oldAppWindow.rootViewController = nil
                }
            }
            menuCoordinator = nil
        }
    }

    private(set) var lockWindow: UIWindow?
    private var menuCoordinator: MenuCoordinator?

    private(set) var currentWindow: UIWindow? {
        didSet {
            switch dependencies.userDefaults[.darkModeStatus] {
            case .followSystem:
                self.currentWindow?.overrideUserInterfaceStyle = .unspecified
            case .forceOn:
                self.currentWindow?.overrideUserInterfaceStyle = .dark
            case .forceOff:
                self.currentWindow?.overrideUserInterfaceStyle = .light
            }
            self.currentWindow?.makeKeyAndVisible()
        }
    }

    enum Destination {
        enum SignInDestination: String { case form, mailboxPassword }
        case lockWindow, appWindow, signInWindow(SignInDestination)
    }

    var scene: UIScene? {
        didSet {
                assert(scene is UIWindowScene, "Scene should be of type UIWindowScene")
        }
    }
    private let dependencies: Dependencies
    private let showPlaceHolderViewOnly: Bool
    private var cancellables = Set<AnyCancellable>()

    init(
        dependencies: Dependencies,
        showPlaceHolderViewOnly: Bool = ProcessInfo.isRunningUnitTests
    ) {
        self.showPlaceHolderViewOnly = showPlaceHolderViewOnly
        self.dependencies = dependencies
        setupNotifications()
        trackLifetime()
    }

    func start(launchedByNotification: Bool = false, completion: (() -> Void)? = nil) {
        let placeholder = UIWindow(root: PlaceholderViewController(color: .white), scene: self.scene)
        self.currentWindow = placeholder

        if showPlaceHolderViewOnly {
            // While running the unit test, call this to generate the main key.
            _ = dependencies.keyMaker.mainKeyExists()
            return
        }

        start(completion: completion)
    }

    private func start(completion: (() -> Void)?) {
        Task {
            await startLaunch()
            evaluateAccessAtLaunch()
            subscribeToDeniedAccess()
            completion?()
        }
    }

    private func startLaunch() async {
        do {
            try dependencies.launchService.start()
        } catch {
            await showCoreDataSetUpFailAlert(error: error)
            fatalError("Core Data set up failed")
        }
    }

    @MainActor
    private func showCoreDataSetUpFailAlert(error: Error) async {
        await withCheckedContinuation { continuation in
            let title: String
            let message: String
            if error.isSqlLiteDiskFull {
                title = L10n.Error.core_data_setup_insufficient_disk_title
                message = L10n.Error.core_data_setup_insufficient_disk_messsage
            } else {
                title = LocalString._general_error_alert_title
                message = String(format: L10n.Error.core_data_setup_generic_messsage, error.localizedDescription)
            }

            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalString._general_ok_action, style: .default) { _ in
                continuation.resume()
            })
            currentWindow?.topmostViewController()?.present(alert, animated: true)
        }
    }

    private func evaluateAccessAtLaunch() {
        let appAccessAtLaunch = dependencies.appAccessResolver.evaluateAppAccessAtLaunch()
        SystemLogger.log(message: appAccessAtLaunch.localizedDescription, category: .appLock)
        switch appAccessAtLaunch {
        case .accessGranted:
            handleAppAccessGrantedAtLaunch()
        case .accessDenied(let reason):
            handleAppAccessDenied(deniedAccess: reason)
        }
    }

    private func subscribeToDeniedAccess() {
        dependencies
            .appAccessResolver
            .deniedAccessPublisher
            .sink { reason in
                SystemLogger.log(message: reason.localizedDescription, category: .appLock)
                self.handleAppAccessDenied(deniedAccess: reason)
            }
            .store(in: &cancellables)
    }

    private func handleAppAccessGrantedAtLaunch() {
        go(dest: .appWindow)
    }

    private func handleAppAccessDenied(deniedAccess: DeniedAccessReason) {
        switch deniedAccess {
        case .lockProtectionRequired:
            lock()
        case .noAuthenticatedAccountFound:
            go(dest: .signInWindow(.form))
        }
    }

    func go(dest: Destination) {
        DispatchQueue.main.async { // cuz
            switch dest {
            case .signInWindow(let signInDestination):
                // do not recreate coordinator in case it's already displayed with right configuration
                if let signInVC = self.currentWindow?.rootViewController as? SignInCoordinator.VC,
                   signInVC.coordinator.startingPoint == signInDestination {
                    signInVC.coordinator.start()
                    return
                }
                self.lockWindow = nil
                self.appWindow = nil
                // TODO: refactor SignInCoordinatorEnvironment init
                let signInEnvironment = SignInCoordinatorEnvironment.live(
                    dependencies: self.dependencies
                )
                let coordinator: SignInCoordinator = .loginFlowForFirstAccount(
                    startingPoint: signInDestination, environment: signInEnvironment
                ) { [weak self] flowResult in
                    switch flowResult {
                    case .succeeded:
                        self?.go(dest: .appWindow)
                        delay(1) {
                            // Waiting for init of Menu coordinate to receive the notification
                            self?.dependencies.notificationCenter.post(name: .switchView, object: nil)
                        }
                    case .userWantsToGoToTroubleshooting:
                        self?.currentWindow?.rootViewController?.present(
                            doh: BackendConfiguration.shared.doh,
                            modalPresentationStyle: .fullScreen,
                            onDismiss: { [weak self] in
                                // restart the process after user returns from troubleshooting
                                self?.go(dest: .signInWindow(signInDestination))
                            }
                        )
                    case .alreadyLoggedIn, .loggedInFreeAccountsLimitReached, .errored:
                        // not sure what else I can do here instead of restarting the process
                        self?.go(dest: .signInWindow(.form))
                    case .dismissed:
                        assertionFailure("this should never happen as the loginFlowForFirstAccount is not dismissable")
                        self?.go(dest: .signInWindow(.form))
                    }
                }
                let newWindow = UIWindow(root: coordinator.actualViewController, scene: self.scene)
                self.navigate(from: self.currentWindow, to: newWindow, animated: false) {
                    coordinator.start()
                }

            case .lockWindow:
                if let topVC = self.appWindow?.topmostViewController() {
                    topVC.view.becomeFirstResponder()
                    topVC.view.endEditing(true)
                }
                guard self.lockWindow == nil else {
                    guard let lockVC = self.currentWindow?.rootViewController as? LockCoordinator.VC,
                          lockVC.coordinator.startedOrScheduledForAStart == false
                    else {
                        return
                    }
                    lockVC.coordinator.start()
                    return
                }

                let coordinator = LockCoordinator(
                    dependencies: self.dependencies,
                    finishLockFlow: { [weak self] flowResult in
                        switch flowResult {
                        case .mailbox:
                            self?.go(dest: .appWindow)
                        case .mailboxPassword:
                            self?.go(dest: .signInWindow(.mailboxPassword))
                        case .signIn:
                            self?.go(dest: .signInWindow(.form))
                        case .signOut:
                            NotificationCenter.default.post(name: .didSignOutLastAccount, object: nil)
                        }
                    }
                )
                let lock = UIWindow(root: coordinator.actualViewController, scene: self.scene)
                self.lockWindow?.rootViewController?.presentedViewController?.dismiss(animated: false)
                self.lockWindow = lock
                coordinator.startedOrScheduledForAStart = true
                self.navigate(from: self.currentWindow, to: lock, animated: false) { [weak coordinator] in
                    if UIApplication.shared.applicationState != .background {
                        coordinator?.start()
                    } else {
                        coordinator?.startedOrScheduledForAStart = false
                    }
                }

            case .appWindow:
                self.lockWindow = nil
                if self.appWindow == nil || self.appWindow.rootViewController is PlaceholderViewController {
                    let root = PMSideMenuController()
                    let menuWidth = MenuViewController.calcProperMenuWidth()
                    let coordinator = MenuCoordinator(
                        dependencies: self.dependencies,
                        sideMenu: root,
                        menuWidth: menuWidth
                    )
                    coordinator.delegate = self
                    self.menuCoordinator = coordinator
                    coordinator.start()
                    self.appWindow = UIWindow(root: root, scene: self.scene)
                }
                if self.appWindow.windowScene == nil {
                    self.appWindow.windowScene = self.scene as? UIWindowScene
                }
                if self.navigate(from: self.currentWindow, to: self.appWindow, animated: true), let deeplink = self.deepLink {
                    self.handleDeepLinkIfNeeded(deeplink)
                }
            }
        }
    }

    @discardableResult
    private func navigate(from source: UIWindow?, to destination: UIWindow, animated: Bool, completion: (() -> Void)? = nil) -> Bool {
        guard source != destination else {
            return false
        }

        let effectView = UIVisualEffectView(frame: UIScreen.main.bounds)
        source?.addSubview(effectView)
        destination.alpha = 0.0

        UIView.animate(withDuration: animated ? 0.5 : 0.0, animations: {
            effectView.effect = UIBlurEffect(style: .dark)
            destination.alpha = 1.0
        }, completion: { _ in
            _ = source
            _ = destination
            effectView.removeFromSuperview()

            // ensure proper view(Will|Did)(Appear|Disappear) callbacks are called
            let topSource = source?.topmostViewController()
            let topDestination = destination.topmostViewController()

            topSource?.beginAppearanceTransition(false, animated: false)
            topDestination?.loadViewIfNeeded()
            topDestination?.beginAppearanceTransition(true, animated: false)

            topSource?.endAppearanceTransition()
            topDestination?.endAppearanceTransition()

            completion?()
        })
        self.currentWindow = destination
        return true
    }

    private func setupNotifications() {
        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(unlock),
            name: .didUnlock,
            object: nil
        )
        dependencies.notificationCenter.addObserver(
            forName: .didRevoke,
            object: nil,
            queue: .main
        ) { [weak self] noti in
            if let uid = noti.userInfo?["uid"] as? String {
                self?.didReceiveTokenRevoke(uid: uid)
            }
        }

        dependencies.notificationCenter.addObserver(
            forName: .switchView,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            SystemLogger.log(
                message: "Notification observer: start handle view switching",
                category: .notificationDebug
            )
            // trigger the menu to follow the deeplink or show inbox
            self?.handleSwitchViewDeepLinkIfNeeded(notification.object as? DeepLink)
        }

        dependencies.notificationCenter.addObserver(
            forName: .scheduledMessageSucceed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let tuple = notification.object as? (MessageID, Date, UserID) else { return }
            self?.showScheduledSendSucceedBanner(
                messageID: tuple.0,
                deliveryTime: tuple.1,
                userID: tuple.2
            )
        }

        dependencies.notificationCenter.addObserver(
            forName: .showScheduleSendUnavailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showScheduledSendUnavailableAlert()
        }

        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(messageSendFailAddressValidationIncorrect),
            name: .messageSendFailAddressValidationIncorrect,
            object: nil
        )

        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(updateUserInterfaceStyle),
            name: .shouldUpdateUserInterfaceStyle,
            object: nil
        )
    }
}

// MARK: DeepLink methods
extension WindowsCoordinator {
    func followDeepLink(_ deepLink: DeepLink) {
        self.deepLink = deepLink
        _ = deepLink.popFirst
        self.start()
    }

    func followDeepDeepLinkIfNeeded(_ deepLink: DeepLink) {
        followDeepLink(deepLink)
    }

    private func handleDeepLinkIfNeeded(_ deepLink: DeepLink) {
        self.appWindow.enumerateViewControllerHierarchy { controller, stop in
            if let _ = controller as? MenuViewController,
               let coordinator = self.menuCoordinator {
                coordinator.follow(deepLink)
                stop = true
            }
        }
    }

    private func shouldOpenURL(deepLink: DeepLink?) -> URL? {
        guard let headNode = deepLink?.head else { return nil }

        if headNode.name == .toWebSupportForm {
            return URL(string: .webSupportFormLink)
        }
        if headNode.name == .toWebBrowser {
            guard let urlString = headNode.value else {
                return nil
            }
            return URL(string: urlString)
        }
        return nil
    }

    private func handleWebUrl(url: URL) {
        let linkOpener = dependencies.keychain[.browser]
        let url = linkOpener.deeplink(to: url)

        if linkOpener == .inAppSafari {
            presentInAppSafari(url: url)
        } else {
            openUrl(url)
        }
    }

    private func openUrl(_ url: URL) {
        guard UIApplication.shared.canOpenURL(url) else {
            SystemLogger.log(message: "url can't be opened by the system: \(url.absoluteString)", isError: true)
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }

    private func presentInAppSafari(url: URL) {
        let safari = SFSafariViewController(url: url)
        DispatchQueue.main.async { [weak self] in
            self?.appWindow.topmostViewController()?.present(safari, animated: true)
        }
    }

    private func handleSwitchViewDeepLinkIfNeeded(_ deepLinkInNotification: DeepLink?) {
        deepLink = deepLinkInNotification ?? deepLink
        if let url = shouldOpenURL(deepLink: deepLink) {
            self.deepLink = nil
            handleWebUrl(url: url)
            return
        }
        guard appWindow != nil else {
            return
        }
        SystemLogger.log(
            message: "HandleSwitchViewDeepLinkIfNeeded: \(deepLink?.debugDescription ?? "no deep link")",
            category: .notificationDebug
        )

        self.appWindow.enumerateViewControllerHierarchy { controller, stop in
            if let _ = controller as? MenuViewController,
               let coordinator = self.menuCoordinator {
                coordinator.handleSwitchView(deepLink: self.deepLink)
                stop = true
                self.deepLink = nil
            }
        }
    }
}

// MARK: Actions
extension WindowsCoordinator {
    func willEnterForeground() {
        self.snapshot.remove()
    }

    func didEnterBackground() {
        if let vc = self.currentWindow?.topmostViewController(),
           !(vc is ComposeContainerViewController) {
            vc.view.endEditing(true)
        }
        if let window = self.currentWindow {
            self.snapshot.show(at: window)
        }
    }

    @objc
    private func lock() {
        guard dependencies.usersManager.hasUsers() else {
            go(dest: .signInWindow(.form))
            return
        }
        // The mainkey could be removed while changing the protection of the app. We should check
        // if the lock notification should be ignored by checking the `LockPreventor`
        let isLockSupressed = LockPreventor.shared.isLockSuppressed
        let showOnlyPlaceHolder = showPlaceHolderViewOnly
        guard !isLockSupressed && !showOnlyPlaceHolder else {
            let msg = "lock ignored: isLockSupressed=\(isLockSupressed) showOnlyPlaceHolder=\(showOnlyPlaceHolder)"
            SystemLogger.log(message: msg, category: .appLock)
            return
        }
        go(dest: .lockWindow)
    }

    @objc
    private func unlock() {
        self.lockWindow = nil

        guard dependencies.usersManager.hasUsers() else {
            go(dest: .signInWindow(.form))
            return
        }
        if dependencies.usersManager.count <= 0 {
            _ = dependencies.usersManager.clean()
            go(dest: .signInWindow(.form))
        } else {
            // To register again in case the registration on app launch didn't go through because the app was locked
            UNUserNotificationCenter.current().delegate = dependencies.pushService
            dependencies.pushService.registerIfAuthorized()
            self.go(dest: .appWindow)
        }
    }

    @objc
    private func didReceiveTokenRevoke(uid: String) {
        if let user = dependencies.usersManager.getUser(by: uid),
           !dependencies.usersManager.loggingOutUserIDs.contains(user.userID) {
            let shouldShowBadTokenAlert = dependencies.usersManager.count == 1

            Analytics.shared.sendEvent(
                .userKickedOut(reason: .apiAccessTokenInvalid),
                trace: Breadcrumbs.shared.trace(for: .randomLogout)
            )
            SystemLogger.log(message: "apiAccessTokenInvalid for uid:\(uid.redacted)", isError: true)

            dependencies.queueManager.unregisterHandler(for: user.userID, completion: nil)
            dependencies.usersManager.logout(user: user, shouldShowAccountSwitchAlert: true) { [weak self] in
                guard let self = self else { return }
                guard let appWindow = self.appWindow else {return}

                if self.dependencies.usersManager.hasUsers() {
                    appWindow.enumerateViewControllerHierarchy { controller, stop in
                        if let menu = controller as? MenuViewController {
                            // Work Around: trigger viewDidLoad of menu view controller
                            _ = menu.view
                            menu.navigateTo(label: MenuLabel(location: .inbox))
                        }
                    }
                }
                if shouldShowBadTokenAlert {
                    NSError.alertBadToken(in: appWindow)
                }

                let handler = LocalNotificationService(userID: user.userID)
                handler.showSessionRevokeNotification(email: user.defaultEmail)
            }
        }
    }

    @objc
    private func updateUserInterfaceStyle() {
        switch dependencies.userDefaults[.darkModeStatus] {
        case .followSystem:
            currentWindow?.overrideUserInterfaceStyle = .unspecified
        case .forceOff:
            currentWindow?.overrideUserInterfaceStyle = .light
        case .forceOn:
            currentWindow?.overrideUserInterfaceStyle = .dark
        }
    }
}

// MARK: Schedule message
extension WindowsCoordinator {

    private func showScheduledSendSucceedBanner(
        messageID: MessageID,
        deliveryTime: Date,
        userID: UserID
    ) {
        let topVC = self.currentWindow?.topmostViewController() ?? UIViewController()

        typealias Key = PMBanner.UserInfoKey
        PMBanner
            .getBanners(in: topVC)
            .filter {
                $0.userInfo?[Key.type.rawValue] as? String == Key.sending.rawValue &&
                $0.userInfo?[Key.messageID.rawValue] as? String == messageID.rawValue
            }
            .forEach { $0.dismiss(animated: false) }

        let timeTuple = PMDateFormatter.shared.titleForScheduledBanner(from: deliveryTime)
        let message = String(format: LocalString._edit_scheduled_button_message,
                             timeTuple.0,
                             timeTuple.1)
        let banner = PMBanner(message: message, style: PMBannerNewStyle.info)
        banner.addButton(text: LocalString._messages_undo_action) { banner in
            self.handleEditScheduleMessage(
                messageID: messageID,
                userID: userID
            ) {
                let deepLink = DeepLink(
                    String(describing: MailboxViewController.self),
                    sender: Message.Location.draft.rawValue
                )
                deepLink.append(
                    .init(name: MailboxCoordinator.Destination.composeScheduledMessage.rawValue,
                          value: messageID.rawValue,
                          states: ["originalScheduledTime": deliveryTime])
                )
                self.dependencies.notificationCenter.post(name: .switchView, object: deepLink)
            }
            banner.dismiss()
        }
        banner.show(at: .bottom, on: topVC)
    }

    private func showScheduledSendUnavailableAlert() {
        let title = LocalString._message_saved_to_draft
        let message = LocalString._schedule_send_unavailable_message
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addOKAction()

        let topVC = self.currentWindow?.topmostViewController() ?? UIViewController()
        topVC.present(alert, animated: true, completion: nil)
    }

    @objc private func messageSendFailAddressValidationIncorrect() {
        let title = LocalString._address_invalid_error_to_draft_action_title
        let toDraftAction = UIAlertAction(title: title, style: .default) { (_) in
            self.dependencies.notificationCenter.post(
                name: .switchView,
                object: DeepLink(
                    String(describing: MailboxViewController.self),
                    sender: Message.Location.draft.rawValue
                )
            )
        }
        UIAlertController.showOnTopmostVC(
            title: LocalString._address_invalid_error_sending_title,
            message: LocalString._address_invalid_error_sending,
            action: toDraftAction
        )
    }

    private func handleEditScheduleMessage(
        messageID: MessageID,
        userID: UserID,
        completion: @escaping () -> Void
    ) {
        let users = dependencies.usersManager
        let user = users.getUser(by: userID)
        user?.messageService.undoSend(
            of: messageID,
            completion: { result in
                guard result.error == nil else {
                    return
                }
                user?.eventsService.fetchEvents(
                    byLabel: Message.Location.allmail.labelID,
                    notificationMessageID: nil,
                    discardContactsMetadata: EventCheckRequest.isNoMetaDataForContactsEnabled,
                    completion: { _ in
                        completion()
                    })
            }
        )
    }
}

extension WindowsCoordinator: MenuCoordinatorDelegate {
    func lockTheScreen() {
        go(dest: .lockWindow)
    }
}

extension WindowsCoordinator: LifetimeTrackable {
    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}

private extension Error {

    var isSqlLiteDiskFull: Bool {
        (self as NSError).userInfo["NSSQLiteErrorDomain"] as? Int == 13
    }
}
