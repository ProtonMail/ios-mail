//
//  MessageHeaderView.swift
//  ProtonMail - Created on 07/03/2019.
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

class MessageHeaderViewController: UIViewController {
    private var coordinator: MessageHeaderViewCoordinator!
    private(set) var viewModel: MessageHeaderViewModel!
    @IBOutlet weak var emailHeaderView: EmailHeaderView!
    private var height: NSLayoutConstraint!
    private var headerViewFrameObservation: NSKeyValueObservation!
    private var viewModelObservation: NSKeyValueObservation!
    
    deinit {
        self.headerViewFrameObservation = nil
        self.viewModelObservation = nil
    }
    
    override func viewDidLoad() {
        self.accessibilityElements = self.emailHeaderView.accessibilityElements
        
        self.setupHeaderView(self.emailHeaderView)
        
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
        
        self.viewModelObservation = self.viewModel.observe(\.headerData, options: [.initial]) { [weak self] viewModel, _ in
            guard let self = self else { return }
            self.updateHeaderData(viewModel.headerData, on: self.emailHeaderView)
        }
    }
    
    fileprivate func setupHeaderView(_ emailHeaderView: EmailHeaderView) {
        emailHeaderView.makeConstraints()
        emailHeaderView.isShowingDetail = false
        emailHeaderView.backgroundColor = .white
        emailHeaderView.viewDelegate = self
        emailHeaderView.inject(recepientDelegate: self)
        emailHeaderView.inject(delegate: self)
    }
    
    fileprivate func updateHeaderData(_ headerData: HeaderData, on emailHeaderView: EmailHeaderView) {
        emailHeaderView.updateHeaderData(headerData)
        emailHeaderView.updateHeaderLayout()
        emailHeaderView.updateShowImageConstraints()
        emailHeaderView.updateSpamScoreConstraints()
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
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        self.viewModel.star(isStarred)
    }
    
    func downloadFailed(error: NSError) {
        fatalError("Stub until emailHeaderView rewrite")
    }
    
    func showImage() {
        fatalError("Stub until emailHeaderView rewrite")
    }
}

extension MessageHeaderViewController: Printable {
    typealias Renderer = HeaderedPrintRenderer.CustomViewPrintRenderer
    
    func printPageRenderer() -> UIPrintPageRenderer {
        let newHeader = EmailHeaderView(frame: self.emailHeaderView.frame)
        self.setupHeaderView(newHeader)
        self.updateHeaderData(self.viewModel.headerData, on: newHeader)
        if self.emailHeaderView.isShowingDetail {
            newHeader.detailsButtonTapped()
        }
        
        return Renderer(newHeader)
    }
    
    func printingWillStart(renderer: UIPrintPageRenderer) {
        if let renderer = renderer as? Renderer,
            let newHeader = renderer.view as? EmailHeaderView
        {
            newHeader.prepareForPrinting(true)
            let minimalSize = newHeader.sizeThatFits(.init(width: 560, height: 300))
            newHeader.frame = .init(x: 18, y: 39, width: 560, height: minimalSize.height)
            newHeader.layoutIfNeeded()
            
            renderer.updateImage(in: newHeader.frame)
        }
    }
}
