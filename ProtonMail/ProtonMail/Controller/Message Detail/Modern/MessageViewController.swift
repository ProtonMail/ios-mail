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
    private var observations: [NSKeyValueObservation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())

        self.coordinator.addChildren(of: self)
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 85
        self.tableView.bounces = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let headerViewModel = MessageHeaderViewModel(headerData: self.viewModel.headerData())
        self.coordinator.updateHeader(viewModel: headerViewModel)
        self.viewModel.subscribe(toUpdatesOf: headerViewModel)
        
        let contents = WebContents(body: self.viewModel.htmlBody(), remoteContentMode: .lockdown)
        let bodyViewModel = MessageBodyViewModel(contents: contents)
        self.coordinator.updateBody(viewModel: bodyViewModel)
        self.viewModel.subscribe(toUpdatesOf: bodyViewModel)
    }
}

extension MessageViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        switch indexPath.section {
        case 0: self.coordinator.embedHeader(onto: cell.contentView)
        case 1: self.coordinator.embedBody(onto: cell.contentView)
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
        
        self.observations = [
            self.viewModel.observe(\.heightOfHeader, changeHandler: { [weak self] viewModel, change in
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            }),
            self.viewModel.observe(\.heightOfBody, changeHandler: { [weak self] viewModel, change in
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            })
        ]
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
