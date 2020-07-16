//
//  EmbeddingViewController.swift
//  ProtonMail - Created on 11/04/2019.
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
        self.contentOffsetToPerserve = self.tableView?.contentOffset ?? .zero
    }
    
    @objc internal func restoreOffset() {
        self.tableView?.setContentOffset(self.contentOffsetToPerserve, animated: false)
    }
}

