//
//  ModernMessageViewController.swift
//  ProtonMail - Created on 06/03/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit

class MessageViewController: UITableViewController, ViewModelProtocol, ProtonMailViewControllerProtocol {
    
    // base protocols
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    @IBOutlet weak var menuButton: UIBarButtonItem!
    func configureNavigationBar() {
        ProtonMailViewController.configureNavigationBar(self)
    }
    
    // legacy
    
    @IBOutlet var backButton: UIBarButtonItem!
    
    // new code
    
    fileprivate var viewModel: MessageViewModel!
    private var coordinator: MessageViewCoordinator!
    private var threadObservation: NSKeyValueObservation!
    private var standalonesObservation: [NSKeyValueObservation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
        NotificationCenter.default.addObserver(self, selector: #selector(scrollToTop), name: .touchStatusBar, object: nil)

        // table view
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 85
        self.tableView.bounces = false
        
        // navigation bar buttons
        var rightButtons: [UIBarButtonItem] = []
        rightButtons.append(.init(image: UIImage(named: "top_more"), style: .plain, target: self, action: #selector(mock)))
        rightButtons.append(.init(image: UIImage(named: "top_trash"), style: .plain, target: self, action: #selector(mock)))
        rightButtons.append(.init(image: UIImage(named: "top_folder"), style: .plain, target: self, action: #selector(mock)))
        rightButtons.append(.init(image: UIImage(named: "top_label"), style: .plain, target: self, action: #selector(mock)))
        rightButtons.append(.init(image: UIImage(named: "top_unread"), style: .plain, target: self, action: #selector(mock)))
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let childViewModels = self.viewModel.thread.map { standalone -> MessageViewCoordinator.ChildViewModelPack in
            let message = self.viewModel.message(for: standalone)!
            let head = MessageHeaderViewModel(parentViewModel: standalone, message: message)
            let attachments = MessageAttachmentsViewModel(parentViewModel: standalone)
            let body = MessageBodyViewModel(parentViewModel: standalone)
            return (head, body, attachments)
        }
        self.viewModel.subscribe(toUpdatesOf: childViewModels)
        self.coordinator.createChildControllers(with: childViewModels)
    }
    
    @objc func mock() {
        fatalError("Implement me!")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MessageViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.thread.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.thread[section].divisionsCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)

        switch self.viewModel.thread[indexPath.section].divisions[indexPath.row] {
        case .header: self.coordinator.embedHeader(index: indexPath.section, onto: cell.contentView)
        case .attachments: self.coordinator.embedAttachments(index: indexPath.section, onto: cell.contentView)
        case .body: self.coordinator.embedBody(index: indexPath.section, onto: cell.contentView)
        case .remoteContent:
            guard let newCell = self.tableView.dequeueReusableCell(withIdentifier: "ShowImageCell", for: indexPath) as? ShowImageCell else {
                assert(false, "Failed to dequeue ShowImageCell")
                cell.backgroundColor = .magenta
                return cell
            }
            newCell.showImageView.delegate = self
            return newCell
        }
        
        return cell
    }
}

extension MessageViewController: ShowImageViewDelegate {
    func showImage() { // TODO: this should tell us which cell was tapped to let per-message switch in conversation mode
        self.viewModel.thread.forEach { $0.remoteContentMode = .allowed }
    }
}

extension MessageViewController: MessageBodyScrollingDelegate {
    @objc func scrollToTop() {
        guard self.presentedViewController == nil, self.navigationController?.topViewController == self else { return }
        self.tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: true)
    }
    
    func propogate(scrolling delta: CGPoint) {
         let yOffset = self.tableView.contentOffset.y + delta.y
         
         if yOffset < 0 { // not too high
             self.tableView.setContentOffset(.zero, animated: false)
         } else if case let maxOffset = self.tableView.contentSize.height - self.tableView.frame.size.height,
            yOffset > maxOffset  // not too low
         {
            self.tableView.setContentOffset(.init(x: 0, y: maxOffset), animated: false)
         } else {
             self.tableView.contentOffset = .init(x: 0, y: yOffset)
         }
    }
}

extension MessageViewController {
    func set(viewModel: MessageViewModel) {
        self.viewModel = viewModel
        
        viewModel.thread.forEach(self.subscribeToStandalone)
        self.subscribeToThread()
        
        viewModel.messages.forEach { message in
            message.fetchDetailIfNeeded() { _, _, _, error in
                guard error == nil else {
                    viewModel.errorWhileReloading(message: message, error: error!)
                    return
                }
                viewModel.reload(message: message)
            }
        }
    }
    
    private func subscribeToThread() {
        self.threadObservation = self.viewModel.observe(\.thread) { [weak self] viewModel, change in
            guard let self = self else { return }
            self.standalonesObservation = []
            viewModel.thread.forEach(self.subscribeToStandalone)
        }
    }
    
    private func subscribeToStandalone(_ standalone: Standalone) {
        let head = standalone.observe(\.heightOfHeader) { [weak self] _, _ in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
        self.standalonesObservation.append(head)
        
        let attachments = standalone.observe(\.heightOfAttachments) { [weak self] standalone, _ in
            guard let section = self?.viewModel.thread.firstIndex(of: standalone) else { return}
            let indexPath = IndexPath(row: Standalone.Divisions.attachments.rawValue, section: section)
            self?.tableView.reloadRows(at: [indexPath], with: .fade)
        }
        self.standalonesObservation.append(attachments)
        
        let body = standalone.observe(\.heightOfBody) { [weak self] _, _ in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
        self.standalonesObservation.append(body)
        
        let divisions = standalone.observe(\.divisionsCount, options: [.new, .old]) { [weak self] standalone, change in
            guard let old = change.oldValue, let new = change.newValue, old != new else { return }
            if let index = self?.viewModel.thread.firstIndex(of: standalone) {
                self?.tableView.reloadSections(IndexSet(integer: index), with: .fade)
            }
        }
        self.standalonesObservation.append(divisions)
    }
}

extension MessageViewController: CoordinatedNew {
    typealias coordinatorType = MessageViewCoordinator
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    func set(coordinator: MessageViewController.coordinatorType) {
        self.coordinator = coordinator
    }
}
