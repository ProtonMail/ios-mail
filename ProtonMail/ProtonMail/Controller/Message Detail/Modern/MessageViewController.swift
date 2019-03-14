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
            let head = MessageHeaderViewModel(parentViewModel: standalone)
            let body = MessageBodyViewModel(parentViewModel: standalone, remoteContentMode: self.viewModel.remoteContentMode)
            return (head, body)
        }
        self.viewModel.subscribe(toUpdatesOf: childViewModels)
        self.coordinator.createChildControllers(with: childViewModels)
    }
    
    @objc func mock() {
        fatalError("Implement me!")
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

        switch indexPath.row {
        case 0: self.coordinator.embedHeader(index: indexPath.section, onto: cell.contentView)
        case 1: self.coordinator.embedBody(index: indexPath.section, onto: cell.contentView)
        default: cell.backgroundColor = .yellow
        }
        
        return cell
    }
}

extension MessageViewController: MessageBodyScrollingDelegate {
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
        let body = standalone.observe(\.heightOfBody) { [weak self] _, _ in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
        self.standalonesObservation.append(body)
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
