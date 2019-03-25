//
//  MessageHeaderView.swift
//  ProtonMail - Created on 07/03/2019.
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

class MessageHeaderViewController: UIViewController {
    private var coordinator: MessageHeaderViewCoordinator!
    private(set) var viewModel: MessageHeaderViewModel!
    @IBOutlet weak var emailHeaderView: EmailHeaderView!
    private var height: NSLayoutConstraint!
    private var headerViewFrameObservation: NSKeyValueObservation!
    private var viewModelObservation: NSKeyValueObservation!
    
    override func viewDidLoad() {
        self.emailHeaderView.makeConstraints()
        self.emailHeaderView.isShowingDetail = false
        self.emailHeaderView.backgroundColor = .white
        self.emailHeaderView.viewDelegate = self
        self.emailHeaderView.inject(recepientDelegate: self)
        self.emailHeaderView.inject(delegate: self)
        
        self.height = self.view.heightAnchor.constraint(equalToConstant: 0.1)
        self.height.priority = .init(999.0) // for correct UITableViewCell autosizing
        self.height.isActive = true
        
        self.headerViewFrameObservation = self.emailHeaderView.observe(\.frame) { [weak self] headerView, change in
            guard self?.viewModel.contentsHeight != headerView.frame.size.height else {
                return
            }
            self?.height.constant = headerView.frame.size.height - 8
            self?.viewModel.contentsHeight = headerView.frame.size.height - 8
        }
        
        self.viewModelObservation = self.viewModel.observe(\.headerData) { [weak self] viewModel, _ in
            self?.updateHeaderData(viewModel.headerData)
        }
        self.updateHeaderData(viewModel.headerData)
    }
    
    func updateHeaderData(_ headerData: HeaderData) {
        self.emailHeaderView.updateHeaderData(headerData)
        self.emailHeaderView.updateHeaderLayout()
        self.emailHeaderView.updateShowImageConstraints()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.coordinator.prepare(for: segue, sender: sender)
    }
}

extension MessageHeaderViewController: EmailHeaderViewProtocol {
    func updateSize() {
        // unnecessary cuz done by self.observation
    }
}

extension MessageHeaderViewController: ViewModelProtocol {
    func set(viewModel: MessageHeaderViewModel) {
        self.viewModel = viewModel
    }
}

extension MessageHeaderViewController: CoordinatedNew {
    func set(coordinator: MessageHeaderViewCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
}


extension MessageHeaderViewController: RecipientViewDelegate {
    func recipientView(at cell: RecipientCell, arrowClicked arrow: UIButton, model: ContactPickerModelProtocol) {
        self.coordinator.recipientView(at: cell, arrowClicked: arrow, model: model)
    }
    
    func recipientView(at cell: RecipientCell, lockClicked lock: UIButton, model: ContactPickerModelProtocol) {
        self.coordinator.recipientView(at: cell, lockClicked: lock, model: model)
    }
    
    func recipientView(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.viewModel.recipientView(lockCheck: model, progress: progress, complete: complete)
    }
}

extension MessageHeaderViewController: EmailHeaderActionsProtocol {
    func quickLook(attachment tempfile: URL, keyPackage: Data, fileName: String, type: String) {
        fatalError("Stub until emailHeaderView rewrite")
    }
    
    func quickLook(file: URL, fileName: String, type: String) {
        fatalError("Stub until emailHeaderView rewrite")
    }
    
    func star(changed isStarred: Bool) {
        self.viewModel.star(isStarred)
    }
    
    func downloadFailed(error: NSError) {
        fatalError("Stub until emailHeaderView rewrite")
    }
    
    func showImage() {
        fatalError("Stub until emailHeaderView rewrite")
    }
}
