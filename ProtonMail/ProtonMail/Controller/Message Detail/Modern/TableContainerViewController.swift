//
//  EmbeddingViewController.swift
//  ProtonMail - Created on 11/04/2019.
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

protocol ScrollableContainer: class {
    func propogate(scrolling: CGPoint, boundsTouchedHandler: ()->Void)
    var scroller: UIScrollView { get }
    
    func saveOffset()
    func restoreOffset()
}

class TableContainerViewController<ViewModel: TableContainerViewModel, Coordinator: TableContainerViewCoordinator>: UIViewController, ProtonMailViewControllerProtocol, UITableViewDelegate, UITableViewDataSource, ScrollableContainer, CoordinatedNew, ViewModelProtocol, BannerPresenting
{

    @IBOutlet weak var tableView: UITableView!
    
    // base protocols
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    @IBOutlet weak var menuButton: UIBarButtonItem!
    func configureNavigationBar() {
        ProtonMailViewController.configureNavigationBar(self)
    }
    
    // legacy
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    
    // new code
    
    private(set) var viewModel: ViewModel!
    private(set) var coordinator: Coordinator!
    private var contentOffsetToPerserve: CGPoint = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
        
        // table view
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmbedCell")
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 85
        self.tableView.bounces = false
        self.tableView.separatorInset = .zero
        
        // events
        NotificationCenter.default.addObserver(self, selector: #selector(scrollToTop), name: .touchStatusBar, object: nil)
        
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(restoreOffset), name: UIWindowScene.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(saveOffset), name: UIWindowScene.didEnterBackgroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(restoreOffset), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(saveOffset), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // --
    
    @objc func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfSections
    }
    
    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows(in: section)
    }
    
    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "EmbedCell", for: indexPath)
        self.coordinator.embedChild(indexPath: indexPath, onto: cell)
        return cell
    }

    // --
    
    @objc func scrollToTop() {
        guard self.presentedViewController == nil, self.navigationController?.topViewController == self else { return }
        self.tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: true)
    }
    
    func propogate(scrolling delta: CGPoint, boundsTouchedHandler: ()->Void) {
        UIView.animate(withDuration: 0.001) { // hackish way to show scrolling indicators on tableView
            self.tableView.flashScrollIndicators()
        }
        let maxOffset = self.tableView.contentSize.height - self.tableView.frame.size.height
        guard maxOffset > 0 else { return }
        
        let yOffset = self.tableView.contentOffset.y + delta.y
        
        if yOffset < 0 { // not too high
            self.tableView.setContentOffset(.zero, animated: false)
            boundsTouchedHandler()
        } else if yOffset > maxOffset { // not too low
            self.tableView.setContentOffset(.init(x: 0, y: maxOffset), animated: false)
            boundsTouchedHandler()
        } else {
            self.tableView.contentOffset = .init(x: 0, y: yOffset)
        }
    }
    
    var scroller: UIScrollView {
        return self.tableView
    }

    // --
    
    typealias coordinatorType = Coordinator
    typealias viewModelType = ViewModel
    
    func set(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    func set(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    // --
    
    @objc func presentBanner(_ sender: BannerRequester) {
        guard let banner = sender.errorBannerToPresent() else {
            return
        }
        self.view.addSubview(banner)
        banner.drop(on: self.view, from: .top)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

// iPads think tableView is resized when app is backgrounded and reloads it's data
// by some mysterious reason if MessageBodyViewController cell occupies whole screen at that moment, tableView will scroll to bottom. So we perserve contentOffset with help of these methods

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.saveOffset()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // scrolling happens after traits collection change, so we have to run restore async
        DispatchQueue.main.async {
            self.restoreOffset()
        }
    }
    
    @objc internal func saveOffset() {
        self.contentOffsetToPerserve = self.tableView.contentOffset
    }
    
    @objc internal func restoreOffset() {
        self.tableView.setContentOffset(self.contentOffsetToPerserve, animated: false)
    }
}

