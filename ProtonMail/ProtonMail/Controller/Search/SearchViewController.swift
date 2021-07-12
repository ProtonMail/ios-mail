//
//  SearchViewController.swift
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

import UIKit
import CoreData
import ProtonCore_UIFoundations

class SearchViewController: ProtonMailViewController, ComposeSaveHintProtocol {
    
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noResultLabel: UILabel!
    
    // MARK: - Private Constants
    fileprivate let kAnimationDuration: TimeInterval = 0.3
    fileprivate let kSegueToMessageDetailController: String = "toMessageDetailViewController"
    
    internal var user: UserManager!
    private let serialQueue = DispatchQueue(label: "com.protonamil.messageTapped")
    private var messageTapped = false
    
    lazy var replacingEmails: [Email] = { [unowned self] in
        return user.contactService.allEmails()
    }()
    
    // TODO: need better UI solution for this progress bar
    private lazy var progressBar: UIProgressView = {
        let bar = UIProgressView()
        bar.trackTintColor = .black
        bar.progressTintColor = .white
        bar.progressViewStyle = .bar
        
        let label = UILabel.init(font: UIFont.italicSystemFont(ofSize: UIFont.smallSystemFontSize), text: "Indexing local messages", textColor: .gray)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(label)
        bar.topAnchor.constraint(equalTo: label.topAnchor).isActive = true
        bar.leadingAnchor.constraint(equalTo: label.leadingAnchor).isActive = true
        bar.trailingAnchor.constraint(equalTo: label.trailingAnchor).isActive = true
        
        return bar
    }()
    private let localObjectIndexing: Progress = Progress(totalUnitCount: 1)
    private var localObjectsIndexingObserver: NSKeyValueObservation? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.progressBar.isHidden = (self?.localObjectsIndexingObserver == nil)
            }
        }
    }
    
    // MARK: - Private attributes
    typealias LocalObjectsIndexRow = Dictionary<String, Any>
    private var dbContents: Array<LocalObjectsIndexRow> = []
    fileprivate var searchResult: [Message] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate var currentPage = 0;

    fileprivate var query: String = ""

    private let cellPresenter = NewMailboxMessageCellPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        searchBar.textField.addTarget(self, action: #selector(textHasChanged), for: .editingChanged)
        searchBar.clearButton.addTarget(self, action: #selector(clearAction), for: .touchUpInside)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.noSeparatorsBelowFooter()
        self.tableView.register(NewMailboxMessageCell.self, forCellReuseIdentifier: NewMailboxMessageCell.defaultID())
        self.tableView.contentInsetAdjustmentBehavior = .automatic
        self.tableView.estimatedRowHeight = 100
        self.tableView.backgroundColor = .clear
        
        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = false;
        self.navigationController?.navigationBar.isTranslucent = false;
        
        self.progressBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.progressBar)
        self.progressBar.topAnchor.constraint(equalTo: self.tableView.topAnchor).isActive = true
        self.progressBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.progressBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.progressBar.heightAnchor.constraint(equalToConstant: UIFont.smallSystemFontSize).isActive = true
        
        self.indexLocalObjects {
            if self.searchResult.isEmpty, !self.query.isEmpty {
                self.fetchLocalObjects()
            }
        }

        navigationBarView.addSubview(searchBar)
        [
            searchBar.topAnchor.constraint(equalTo: navigationBarView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: navigationBarView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: navigationBarView.trailingAnchor, constant: -16),
            searchBar.bottomAnchor.constraint(equalTo: navigationBarView.bottomAnchor)
        ].activate()

        searchBar.textField.delegate = self
        searchBar.textField.becomeFirstResponder()

        activityIndicator.color = UIColorManager.BrandNorm
        activityIndicator.isHidden = true
    }

    let searchBar = SearchBarView()
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        self.localObjectIndexing.cancel() // switches off indexing of Messages in local db
    }
    
    // my selector that was defined above
    @objc func willEnterForeground() {
        self.dismiss(animated: false, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchResult = self.searchResult.filter{ $0.managedObjectContext != nil }
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.textField.resignFirstResponder()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func configureNavigationBar() {
        super.configureNavigationBar()
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;//.Blue_475F77
    }
    
    func indexLocalObjects(_ completion: @escaping ()->Void) {
        let context = CoreDataService.shared.operationContext
        var count = 0
        context.performAndWait {
            do {
                let overallCountRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: Message.Attributes.entityName)
                overallCountRequest.resultType = .countResultType
                overallCountRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, self.user.userinfo.userId)
                let result = try context.fetch(overallCountRequest)
                count = (result.first as? Int) ?? 1
            } catch let error {
                PMLog.D(" performFetch error: \(error)")
                assert(false, "Failed to fetch message dicts")
            }
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, self.user.userinfo.userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
        fetchRequest.resultType = .dictionaryResultType

        let objectId = NSExpressionDescription()
        objectId.name = "objectID"
        objectId.expression = NSExpression.expressionForEvaluatedObject()
        objectId.expressionResultType = NSAttributeType.objectIDAttributeType
        
        fetchRequest.propertiesToFetch = [objectId,
                                          Message.Attributes.title,
                                          Message.Attributes.sender,
                                          Message.Attributes.toList]
        let async = NSAsynchronousFetchRequest(fetchRequest: fetchRequest, completionBlock: { [weak self] result in
            self?.dbContents = result.finalResult as? Array<LocalObjectsIndexRow> ?? []
            self?.localObjectsIndexingObserver = nil
            completion()
        })
        
        context.perform {
            self.localObjectIndexing.becomeCurrent(withPendingUnitCount: 1)
            guard let indexRaw = try? context.execute(async),
                let index = indexRaw as? NSPersistentStoreAsynchronousResult else
            {
                self.localObjectIndexing.resignCurrent()
                return
            }
            
            self.localObjectIndexing.resignCurrent()
            self.localObjectsIndexingObserver = index.progress?.observe(\Progress.completedUnitCount, options: NSKeyValueObservingOptions.new, changeHandler: { [weak self] (progress, change) in
                DispatchQueue.main.async {
                    let completionRate = Float(progress.completedUnitCount) / Float(count)
                    self?.progressBar.setProgress(completionRate, animated: true)
                }
            })
        }
    }
    
    func fetchLocalObjects() {
        // TODO: this filter can be better. Can we lowercase and glue together all the strings via NSExpression during fetch?
        let messageIds: [NSManagedObjectID] = self.dbContents.compactMap {
            if let title = $0["title"] as? String,
                let _ = title.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive])
            {
                return $0["objectID"] as? NSManagedObjectID
            }
            if let senderName = $0["senderName"]  as? String,
                let _ = senderName.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive])
            {
                return $0["objectID"] as? NSManagedObjectID
            }
            if let sender = $0["sender"]  as? String,
                let _ = sender.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive])
            {
                return $0["objectID"] as? NSManagedObjectID
            }
            if let toList = $0["toList"]  as? String,
                let _ = toList.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive])
            {
                return $0["objectID"] as? NSManagedObjectID
            }
            return nil
        }
        
        let context = CoreDataService.shared.mainContext
        context.performAndWait {
            let messages = messageIds.compactMap { oldId -> Message? in
                let uri = oldId.uriRepresentation() // cuz contexts have different persistent store coordinators
                guard let newId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                    return nil
                }
                return context.object(with: newId) as? Message
            }
            self.searchResult = messages
            if self.currentPage == 0 && self.searchResult.count == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showHideNoresult()
                }
            }
        }
    }
    
    func showHideNoresult(){
        noResultLabel.isHidden = false
        if self.searchResult.count > 0 {
            noResultLabel.isHidden = true
        }
    }
    
    func fetchRemoteObjects(_ query: String,
                            page: Int? = nil)
    {
        let pageToLoad = page ?? 0
//        if query.count < 3 {  //query.preg_match("^[A-Za-z0-9_]+$") && 
//            self.searchResult = []
//            self.currentPage = 0
//            return
//        }
        noResultLabel.isHidden = true
        showActivityIndicator()
        
        let service = user.messageService
        service.search(query, page: pageToLoad) { (messageBoxes, error) -> Void in
            DispatchQueue.main.async { [weak self] in
                self?.hideActivityIndicator()
            }

            guard error == nil, let messages = messageBoxes else {
                PMLog.D(" search error: \(String(describing: error))")

                if pageToLoad == 0 {
                    self.fetchLocalObjects()
                }
                return
            }
            self.currentPage = pageToLoad
            guard !messages.isEmpty else {
                if pageToLoad == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.showHideNoresult()
                    }
                    self.searchResult = []
                }
                return
            }

            let context = CoreDataService.shared.mainContext
            context.perform {
                let mainQueueMessages = messages.compactMap { context.object(with: $0.objectID) as? Message }
                if pageToLoad > 0 {
                    self.searchResult.append(contentsOf: mainQueueMessages)
                } else {
                    self.searchResult = mainQueueMessages
                }
            }
        }
    }
    
    func initiateFetchIfCloseToBottom(_ indexPath: IndexPath) {
        if (self.searchResult.count - 1) <= indexPath.row {
            self.fetchRemoteObjects(query, page: self.currentPage + 1)
        }
    }

    private func showActivityIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    private func hideActivityIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func updateTapped(status: Bool) {
        serialQueue.sync {
            self.messageTapped = status
        }
    }
    
    private func getTapped() -> Bool {
        serialQueue.sync {
            let ret = self.messageTapped
            if ret == false {
                self.messageTapped = true
            }
            return ret
        }
    }

    @objc
    private func textHasChanged() {
        searchBar.clearButton.isHidden = searchBar.textField.text?.isEmpty == true
    }

    @objc
    private func clearAction() {
        searchBar.textField.text = nil
        searchBar.textField.sendActions(for: .editingChanged)
    }

    @IBAction func tapAction(_ sender: AnyObject) {
        searchBar.textField.resignFirstResponder()
    }

    // MARK: - Button Actions
    
    @objc
    private func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Prepare for segue
    
    private func prepareForDraft(_ message: Message) {
        self.updateTapped(status: true)
        let service = self.user.messageService
        service.ForcefetchDetailForMessage(message) { [weak self] (_, _, msg, error) in
            guard let _self = self else {
                self?.updateTapped(status: false)
                return
            }
            guard error == nil else {
                let alert = LocalString._unable_to_edit_offline.alertController()
                alert.addOKAction()
                _self.present(alert, animated: true, completion: nil)
                _self.tableView.indexPathsForSelectedRows?.forEach {
                    _self.tableView.deselectRow(at: $0, animated: true)
                }
                _self.updateTapped(status: false)
                return
            }
            _self.updateTapped(status: false)
            _self.showComposer(message: message)
        }
    }
    
    private func showComposer(message: Message) {
        let viewModel = ContainableComposeViewModel(msg: message,
                                                    action: .openDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataService: CoreDataService.shared)
        if let navigationController = self.navigationController {
            let composerVM = ComposeContainerViewModel(editorViewModel: viewModel,
                                                      uiDelegate: nil)
            let coordinator = ComposeContainerViewCoordinator(nav: navigationController,
                                                              viewModel: composerVM,
                                                              services: ServiceFactory.default)
            coordinator.start()
        }
    }
}

// MARK: - UITableViewDataSource

extension SearchViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.searchResult.isEmpty ? 0 : 1
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResult.count
    }
    
    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let mailboxCell = tableView.dequeueReusableCell(
                withIdentifier: NewMailboxMessageCell.defaultID(),
                for: indexPath
        ) as? NewMailboxMessageCell else {
            assert(false)
            return UITableViewCell()
        }
        
        let message = self.searchResult[indexPath.row]
        let customFolderLabels = user.labelService.getAllLabels(
            of: .folder,
            context: CoreDataService.shared.mainContext
        )
        let viewModel = buildViewModel(
            message: message,
            customFolderLabels: customFolderLabels,
            weekStart: user.userInfo.weekStartValue
        )
        cellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)
        return mailboxCell
    }
    
    @objc func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.zeroMargin()
        self.initiateFetchIfCloseToBottom(indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}


// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.getTapped() {
            // Fetching other draft data
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        // open messages in MessaveContainerViewController
        let message = self.searchResult[indexPath.row]
        guard message.contains(label: .draft) else {
            self.updateTapped(status: false)
            guard let navigationController = navigationController else { return }
            let coordinator = SingleMessageCoordinator(
                navigationController: navigationController,
                labelId: "",
                message: message,
                user: user
            )
            coordinator.start()
            return
        }
        self.prepareForDraft(message)
    }

}


// MARK: - UITextFieldDelegate

extension SearchViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        query = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard self.query.count > 0 else {
            return true
        }
        self.fetchRemoteObjects(self.query)
        return true
    }
}
