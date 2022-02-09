//
//  MenuViewModel.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import CoreData
import PromiseKit
import ProtonCore_AccountSwitcher
import ProtonCore_DataModel
import UIKit

final class MenuViewModel: NSObject {
    private let usersManager: UsersManager
    private let userStatusInQueueProvider: UserStatusInQueueProtocol
    private let coreDataContextProvider: CoreDataContextProviderProtocol
    
    private var labelDataService: LabelsDataService? {
        guard let labelService = self.currentUser?.labelService else {
            return nil
        }
        
        return labelService
    }
    private var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    /// To observe the unread number change for message mode label
    private var labelUpdateFetcher: NSFetchedResultsController<NSFetchRequestResult>?
    /// To observe the unread number change for conversation mode label
    private var conversationCountFetcher: NSFetchedResultsController<NSFetchRequestResult>?
    private weak var delegate: MenuUIProtocol?
    var currentUser: UserManager? {
        return self.usersManager.firstUser
    }
    var secondUser: UserManager? {
        return self.usersManager.user(at: 1)
    }
    private(set) var menuWidth: CGFloat!
    
    private var rawData = [MenuLabel]()
    private(set) var sections: [MenuSection]
    private(set) var feedbackItems: [MenuLabel]
    private let inboxItems: [MenuLabel]
    private(set) var folderItems: [MenuLabel] = []
    private var labelItems: [MenuLabel] = []
    private var moreItems: [MenuLabel]
    /// When BE has issue, BE will disable subcription functionality
    private var subscriptionAvailable = true

    var isInAppFeedbackEnable: Bool {
        usersManager.firstUser?.inAppFeedbackStateService.isEnable ?? false
    }

    var reloadClosure: (() -> Void)?
    
    init(usersManager: UsersManager,
         userStatusInQueueProvider: UserStatusInQueueProtocol,
         coreDataContextProvider: CoreDataContextProviderProtocol) {
        self.usersManager = usersManager
        self.userStatusInQueueProvider = userStatusInQueueProvider
        self.coreDataContextProvider = coreDataContextProvider
        
        var sections: [MenuSection] = [.inboxes, .folders, .labels, .more]
        let localIsInAppFeedbackEnable = usersManager.firstUser?.inAppFeedbackStateService.isEnable ?? false
        if localIsInAppFeedbackEnable {
            sections.insert(.feedback, at: 0)
            self.feedbackItems = [MenuLabel(location: .provideFeedback)]
        } else {
            self.feedbackItems = []
        }
        self.sections = sections
        self.inboxItems = Self.inboxItems()
        let defaultInfo = MoreItemsInfo(userIsMember: nil,
                                        subscriptionAvailable: subscriptionAvailable,
                                        isPinCodeEnabled: userCachedStatus.isPinCodeEnabled,
                                        isTouchIDEnabled: userCachedStatus.isTouchIDEnabled)
        self.moreItems = Self.moreItems(for: defaultInfo)
        super.init()

        usersManager.firstUser?.inAppFeedbackStateService.register(delegate: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: MenuVMProtocol
extension MenuViewModel: MenuVMProtocol {
    /// Initialize needed
    func set(delegate: MenuUIProtocol) {
        self.delegate = delegate
    }
    
    func set(menuWidth: CGFloat) {
        self.menuWidth = menuWidth
    }
    
    func userDataInit() {
        assert(self.delegate != nil,
               "delegate can't be nil, use set(delegate:) to setting")
        self.regesterNotification()
        self.fetchLabels()
        self.observeLabelUnreadUpdate()
        self.observeContextLabelUnreadUpdate()
        self.highlight(label: MenuLabel(location: .inbox))
    }
    
    var enableFolderColor: Bool {
        guard let user = self.currentUser else { return false }
        return user.userinfo.enableFolderColor == 1
    }
    
    func menuViewInit() {
        self.updatePrimaryUserView()
        self.updateMoreItems(shouldReload: false)
        _ = self.updateUnread().done {
            self.delegate?.updateMenu(section: nil)
        }
    }
    
    func getMenuItem(indexPath: IndexPath) -> MenuLabel? {
        let section = indexPath.section
        let row = indexPath.row
        
        switch self.sections[section] {
        case .feedback:
            return self.feedbackItems[row]
        case .inboxes:
            return self.inboxItems[row]
        case .folders:
            return self.folderItems.getFolderItem(by: indexPath)
        case .labels:
            return self.labelItems[safe:row]
        case .more:
            return self.moreItems[safe:row]
        default: return nil
        }
    }
    
    func numberOfRowsIn(section: Int) -> Int {
        switch self.sections[section] {
        case .feedback: return self.feedbackItems.count
        case .inboxes: return self.inboxItems.count
        case .folders:
            return self.folderItems.getNumberOfRows()
        case .labels: return self.labelItems.count
        case .more: return self.moreItems.count
        default: return 0
        }
    }
    
    func clickCollapsedArrow(labelID: String) {
        guard let idx = self.rawData.firstIndex(where: {$0.location.labelID == labelID}) else {
            return
        }
        self.rawData[idx].expanded = !self.rawData[idx].expanded
        self.handleMenuExpandEvent(label: self.rawData[idx])
    }
    
    func isCurrentUserHasQueuedMessage() -> Bool {
        guard let user = self.currentUser else {
            return false
        }
        return self.userStatusInQueueProvider.isAnyQueuedMessage(of: user.userinfo.userId)
    }
    
    func removeAllQueuedMessageOfCurrentUser() {
        guard let user = self.currentUser else {
            return
        }
        self.userStatusInQueueProvider.deleteAllQueuedMessage(of: user.userinfo.userId, completeHander: nil)
    }
    
    func signOut(userID: String, completion: (() -> Void)?) {
        guard let user = self.usersManager.getUser(byUserId: userID) else {
            completion?()
            return
        }
        self.usersManager.logout(user: user, shouldShowAccountSwitchAlert: false, completion: completion)
    }
    
    func removeDisconnectAccount(userID: String) {
        guard let user = self.usersManager.disconnectedUsers.first(where: {$0.userID == userID}) else {return}
        self.usersManager.removeDisconnectedUser(user)
    }
    
    /// Remove subscription item after get error response from `StorefrontCollectionViewController`
    func subscriptionUnavailable() {
        self.subscriptionAvailable = false
        self.updateMoreItems()
    }
    
    func highlight(label: MenuLabel) {
        let tmp = self.inboxItems + self.rawData + self.moreItems
        tmp.forEach({$0.isSelected = false})
        let item = tmp.first(where: {$0.location.labelID == label.location.labelID})
            
        item?.isSelected = true
        self.delegate?.updateMenu(section: nil)
    }
    
    func appVersion() -> String {
        var appVersion = "Unkonw Version"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = "\(version)"
        }
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = appVersion + " (\(build))"
        }
        return appVersion
    }
    
    func getAccountList() -> [AccountSwitcher.AccountData] {
        var list = self.usersManager.users.map {user -> AccountSwitcher.AccountData in
            let id = user.userInfo.userId
            let name = user.defaultDisplayName
            let mail = user.defaultEmail
            return AccountSwitcher.AccountData(userID: id, name: name, mail: mail, isSignin: true, unread: 0)
        }
        
        list += self.usersManager.disconnectedUsers.map {user -> AccountSwitcher.AccountData in
            return AccountSwitcher.AccountData(userID: user.userID, name: user.defaultDisplayName, mail: user.defaultEmail, isSignin: false, unread: 0)
        }
        return list
    }
    
    func getUnread(of userID: String) -> Promise<Int> {
        return Promise { [weak self] seal in
            guard let vm = self,
                  let user = vm.usersManager.getUser(byUserId: userID) else {return seal.fulfill(0) }
            let labelID = LabelLocation.inbox.toMessageLocation.rawValue
            _ = user.getUnReadCount(by: labelID).done { (unread) in
                seal.fulfill(unread)
            }
        }
    }
    
    func activateUser(id: String) {
        guard let user = self.usersManager.getUser(byUserId: id) else {
            return
        }
        self.usersManager.active(uid: user.auth.sessionID)
        self.userDataInit()
        self.menuViewInit()
        self.delegate?.navigateTo(label: MenuLabel(location: .inbox))
        let msg = String(format: LocalString._signed_in_as, user.defaultEmail)
        self.delegate?.showToast(message: msg)
    }
    
    func prepareLogin(userID: String) {
        if let user = self.usersManager.disconnectedUsers.first(where: {$0.userID == userID}) {
            let label = MenuLabel(id: LabelLocation.addAccount.labelID, name: user.defaultEmail, parentID: nil, path: "tmp", textColor: "", iconColor: "", type: -1, order: -1, notify: false)
            self.delegate?.navigateTo(label: label)
        } else {
            let label = MenuLabel(id: LabelLocation.addAccount.labelID, name: "", parentID: nil, path: "tmp", textColor: "", iconColor: "", type: -1, order: -1, notify: false)
            self.delegate?.navigateTo(label: label)
        }
    }
    
    func prepareLogin(mail: String) {
        let label = MenuLabel(id: LabelLocation.addAccount.labelID, name: mail, parentID: nil, path: "tmp", textColor: "", iconColor: "", type: -1, order: -1, notify: false)
        self.delegate?.navigateTo(label: label)
    }
    
    func getColor(of label: MenuLabel) -> UIColor {
        guard let user = self.currentUser else { return UIColor(hexColorCode: "#9CA0AA") }
        guard label.type == .folder else {
            return UIColor(hexColorCode: label.iconColor)
        }
        
        let enableColor = user.userinfo.enableFolderColor == 1
        let inherit = user.userinfo.inheritParentFolderColor == 1
        
        guard enableColor else { return UIColor(hexColorCode: "#9CA0AA") }
        if inherit {
            guard let parent = self.folderItems.getRootItem(of: label) else {
                return UIColor(hexColorCode: "#9CA0AA")
            }
            return UIColor(hexColorCode: parent.iconColor)
        } else {
            return UIColor(hexColorCode: label.iconColor)
        }
    }
    
    func allowToCreate(type: PMLabelType) -> Bool {
        guard let user = self.currentUser else { return false }
        // Only free user has limitation
        guard user.userinfo.subscribed == 0 else { return true }
        switch type {
        case .folder:
            return self.folderItems.getNumberOfRows() < 3
        case .label:
            return self.labelItems.getNumberOfRows() < 3
        default:
            return false
        }
    }
}

extension MenuViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == self.labelUpdateFetcher || controller == self.conversationCountFetcher {
            _ = self.updateUnread().done {
                self.delegate?.updateMenu(section: nil)
            }
            return
        }
        
        let dbItems = (controller.fetchedObjects as? [Label]) ?? []
        self.handle(dbLabels: dbItems)
    }
}

// MARK: Data source
extension MenuViewModel {
    private func fetchLabels() {
        guard let service = self.labelDataService else {
            return
        }
        
        // The response of api will write into CoreData
        // And the change will trigger controllerDidChangeContent(_ :)
        defer {
            service.fetchV4Labels().cauterize()
        }
        
        self.fetchedLabels = service.fetchedResultsController(.all)
        self.fetchedLabels?.delegate = self
        guard let result = self.fetchedLabels else {return}
        do {
            try result.performFetch()
            guard let labels = result.fetchedObjects as? [Label] else {
                return
            }
            self.handle(dbLabels: labels)
        } catch {
        }
    }
    
    private func observeLabelUnreadUpdate() {
        guard let user = self.currentUser else {return}
        let moc = self.coreDataContextProvider.mainContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: LabelUpdate.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "(%K == %@)",
                                             LabelUpdate.Attributes.userID,
                                             user.userinfo.userId)
        let strComp = NSSortDescriptor(key: LabelUpdate.Attributes.labelID,
                                       ascending: true,
                                       selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [strComp]
        self.labelUpdateFetcher = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        self.labelUpdateFetcher?.delegate = self
        
        guard let fetcher = self.labelUpdateFetcher else {return}
        do {
            try fetcher.performFetch()
        } catch {
        }
    }
    
    private func observeContextLabelUnreadUpdate() {
        guard let user = self.currentUser else {return}
        let moc = self.coreDataContextProvider.mainContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ConversationCount.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "(%K == %@)",
                                             ConversationCount.Attributes.userID,
                                             user.userinfo.userId)
        let strComp = NSSortDescriptor(key: ConversationCount.Attributes.labelID,
                                       ascending: true,
                                       selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [strComp]
        self.conversationCountFetcher = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        self.conversationCountFetcher?.delegate = self
        
        guard let fetcher = self.conversationCountFetcher else {return}
        do {
            try fetcher.performFetch()
        } catch {
        }
    }
    
    private func handle(dbLabels: [Label]) {
        let datas: [MenuLabel] = Array(labels: dbLabels, previousRawData: self.rawData)
        self.rawData = datas
        _ = self.updateUnread().done { [weak self] in
            self?.sortoutData(data: datas)
        }
    }
    
    private func sortoutData(data: [MenuLabel]) {
        (self.labelItems, self.folderItems) = data.sortoutData()
        self.appendAddItems()
        self.delegate?.updateMenu(section: nil)
    }
    
    private func appendAddItems() {
        if self.labelItems.isEmpty {
            let addLabel = MenuLabel(id: LabelLocation.addLabel.labelID, name: LocalString._labels_add_label_action, parentID: nil, path: "tmp", textColor: "#9CA0AA", iconColor: "#9CA0AA", type: 1, order: 9999, notify: false)
            self.labelItems.append(addLabel)
        }
        
        if self.folderItems.isEmpty {
            let addFolder = MenuLabel(id: LabelLocation.addFolder.labelID, name: LocalString._labels_add_folder_action, parentID: nil, path: "tmp", textColor: "#9CA0AA", iconColor: "#9CA0AA", type: 1, order: 9999, notify: false)
            self.folderItems.append(addFolder)
        }
    }
    
    private func updateMoreItems(shouldReload: Bool = true) {
        let moreItemsInfo = MoreItemsInfo(userIsMember: currentUser?.userinfo.isMember ?? false,
                                          subscriptionAvailable: self.subscriptionAvailable,
                                          isPinCodeEnabled: userCachedStatus.isPinCodeEnabled,
                                          isTouchIDEnabled: userCachedStatus.isTouchIDEnabled)
        let newMore = Self.moreItems(for: moreItemsInfo)
        if newMore.count != self.moreItems.count {
            self.moreItems = newMore
            if shouldReload {
                self.delegate?.updateMenu(section: 3)
            }
        }
    }
    
    // Get the tableview row of the given labelID
    private func getFolderItemRow(by labelID: String, source: [MenuLabel]) -> Int? {
        var num = 0
        // DFS
        var queue = source
        while queue.count > 0 {
            let label = queue.remove(at: 0)
            if label.location.labelID == labelID {
                return num
            }
            num += 1
            guard label.expanded else {continue}
            for sub in label.subLabels.reversed() {
                queue.insert(sub, at: 0)
            }
        }
        return nil
    }
    
    // Query unread number of labels
    private func getUnreadNumbers() -> Promise<Void> {
        return Promise<Void> { seal in
            let tmp = self.inboxItems + self.rawData
            let labels = tmp.map({ $0.location.labelID })

            self.labelDataService?.getUnreadCounts(by: labels, userID: nil).done({ labelUnreadDict in
                for item in tmp {
                    item.unread = labelUnreadDict[item.location.labelID] ?? 0
                }
                if let unreadOfInbox = labelUnreadDict[Message.Location.inbox.rawValue] {
                    UIApplication.setBadge(badge: unreadOfInbox)
                }
                seal.fulfill_()
            }).cauterize()
        }
    }
    
    private func aggregateUnreadNumbers() -> Promise<Void> {
        return Promise { seal in
            let arr = self.rawData.filter({$0.type == .folder}).reversed()
            // 0 is "add folder" label, skip
            for label in arr {
                guard label.subLabels.count > 0 else {
                    label.aggreateUnread = label.unread
                    continue
                }
                
                label.aggreateUnread = label.unread + label.subLabels.reduce(0, { (sum, label) -> Int in
                    return sum + label.aggreateUnread
                })
            }
            seal.fulfill_()
        }
    }
}

// MARK: Private functions
extension MenuViewModel {
    private func regesterNotification() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(primaryAccountLogout),
                         name: .didPrimaryAccountLogout,
                         object: nil)
    }
    
    @objc private func primaryAccountLogout() {
        guard self.usersManager.users.count > 0,
              let user = self.currentUser else {return}
        self.activateUser(id: user.userInfo.userId)
    }

    private func updatePrimaryUserView() {
        guard let user = self.currentUser else {
            // todo, error handle
            fatalError("Primary user is nil")
        }
        self.delegate?.update(email: user.defaultEmail)
        
        let name = user.defaultDisplayName.isEmpty ? user.defaultEmail: user.defaultDisplayName
        self.delegate?.update(displayName: name)
        self.delegate?.update(avatar: name.initials())
    }
    
    // Get the indexPaths should be Expanded / collapsed by the given label
    private func handleMenuExpandEvent(label: MenuLabel) {
        guard let row = self.getFolderItemRow(by: label.location.labelID, source: self.folderItems),
              let sectionOfFolder = sections.firstIndex(of: .folders) else {
            return
        }

        var num = 0
        var queue = label.subLabels
        while queue.count > 0 {
            let item = queue.remove(at: 0)
            num += 1
            guard item.expanded else { continue }
            item.subLabels.forEach { label in
                queue.insert(label, at: 0)
            }
        }
        guard num > 0 else { return }
        var arr = [IndexPath]()
        for idx in 1...num {
            arr.append(IndexPath(row: row + idx, section: sectionOfFolder))
        }
        
        let updateRow = IndexPath(row: row, section: sectionOfFolder)
        var insertRows: [IndexPath] = []
        var deleteRows: [IndexPath] = []
        if label.expanded {
            insertRows = arr
        } else {
            deleteRows = arr
        }
        
        self.delegate?.update(rows: [updateRow],
                              insertRows: insertRows,
                              deleteRows: deleteRows)
    }

    private func updateUnread() -> Promise<Void> {
        return self.getUnreadNumbers()
            .then { self.aggregateUnreadNumbers() }
    }
}

// MARK: MenuLabel options builder
extension MenuViewModel {
    struct MoreItemsInfo {
        var userIsMember: Bool?
        var subscriptionAvailable: Bool
        var isPinCodeEnabled: Bool
        var isTouchIDEnabled: Bool
    }

    static func inboxItems() -> [MenuLabel] {
        [MenuLabel(location: .inbox),
         MenuLabel(location: .draft),
         MenuLabel(location: .sent),
         MenuLabel(location: .starred),
         MenuLabel(location: .archive),
         MenuLabel(location: .spam),
         MenuLabel(location: .trash),
         MenuLabel(location: .allmail)]
    }

    static func moreItems(for info: MoreItemsInfo) -> [MenuLabel] {
        var newMore = [MenuLabel(location: .settings),
                       MenuLabel(location: .contacts),
                       MenuLabel(location: .bugs),
                       MenuLabel(location: .lockapp),
                       MenuLabel(location: .signout)]

        if info.userIsMember == false {
            newMore.insert(MenuLabel(location: .subscription), at: 0)
        }

        if info.subscriptionAvailable == false {
            newMore = newMore.filter { $0.location != .subscription }
        }
        
        if !info.isPinCodeEnabled, !info.isTouchIDEnabled {
            newMore = newMore.filter { $0.location != .lockapp }
        }

        return newMore
    }
}

extension MenuViewModel: InAppFeedbackStateServiceDelegate {
    func inAppFeedbackFeatureFlagHasChanged(enable: Bool) {
        if enable {
            sections.insert(.feedback, at: 0)
            feedbackItems = [MenuLabel(location: .provideFeedback)]
        } else {
            sections = sections.filter({ $0 != .feedback })
            feedbackItems = []
        }
        reloadClosure?()
    }
}
