//
//  MessageAttachmentsViewController.swift
//  ProtonMail - Created on 15/03/2019.
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
    

import Foundation

class MessageAttachmentsViewController: UIViewController {
    private var coordinator: MessageAttachmentsCoordinator!
    private var viewModel: MessageAttachmentsViewModel!
    private var height: NSLayoutConstraint! // do we need this shit?
    private var headerViewFrameObservation: NSKeyValueObservation!
    private var attachmentsObservation: NSKeyValueObservation!
    private var isExpanded: Bool = false

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.tableView.register(UINib(nibName: String(describing: ExpirationWarningHeaderCell.self), bundle: nil),
                                forHeaderFooterViewReuseIdentifier: String(describing: ExpirationWarningHeaderCell.self))
        
        self.tableView.register(UINib(nibName: String(describing: AttachmentTableViewCell.self), bundle: nil),
                                      forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
        
        self.height = self.view.heightAnchor.constraint(equalToConstant: 0.1)
        self.height.priority = .init(999.0) // for correct UITableViewCell autosizing
        self.height.isActive = true
        
        self.headerViewFrameObservation = self.tableView.observe(\.contentSize) { [weak self] tableView, change in
            guard self?.viewModel.contentsHeight != tableView.contentSize.height else {
                return
            }
            self?.updateHeight()
        }
        
        self.attachmentsObservation = self.viewModel.observe(\.attachments) { [weak self] viewModel, _ in
            self?.tableView.reloadData()
        }
    }
    
    private func updateHeight() {
        self.height.constant = tableView.contentSize.height
        self.viewModel.contentsHeight = tableView.contentSize.height
    }
}

extension MessageAttachmentsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.attachments.isEmpty ? 0 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.isExpanded ? self.viewModel.attachments.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AttachmentTableViewCell.self), for: indexPath)
        if let cell = cell as? AttachmentTableViewCell {
            let attachment = self.viewModel.attachments[indexPath.row]
            cell.setFilename(attachment.fileName, fileSize: attachment.size)
            cell.configAttachmentIcon(attachment.mimeType)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: ExpirationWarningHeaderCell.self)) as? ExpirationWarningHeaderCell
        
        cell?.isUserInteractionEnabled = true
        cell?.contentView.isUserInteractionEnabled = true
        
        let count = self.viewModel.attachments.count
        cell?.ConfigHeader(title: "\(count) Attachments", section: section, expend: self.isExpanded)
        cell?.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath) as? AttachmentTableViewCell
        
        // TODO: this will break if tableView will be reloaded while downoading
        let attachment = self.viewModel.attachments[indexPath.row]
        let pregressUpdate: (Float)->Void = { [weak cell, weak attachment] progress in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    guard cell?.filename == attachment?.fileName else {
                        return // cell was reused since then
                    }
                    cell?.progressView.alpha = 1.0
                    cell?.progressView.isHidden = progress >= 1.0
                    cell?.progressView.progress = progress
                }
            }
        }

        self.viewModel.open(attachment, pregressUpdate, self.coordinator.error) { cleartextURL in
            self.coordinator.quickLook(clearfileURL: cleartextURL,
                                       fileName: attachment.fileName.clear,
                                       type: attachment.mimeType)
        }
    }
}

extension MessageAttachmentsViewController: ExpirationWarningHeaderCellDelegate {
    func clicked(at section: Int, expend: Bool) {
        self.isExpanded = expend
        self.tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
}

extension MessageAttachmentsViewController: EmailHeaderViewProtocol {
    func updateSize() {
        // unnecessary cuz done by self.observation
    }
}

extension MessageAttachmentsViewController: ViewModelProtocol {
    func set(viewModel: MessageAttachmentsViewModel) {
        self.viewModel = viewModel
    }
}

extension MessageAttachmentsViewController: CoordinatedNew {
    func set(coordinator: MessageAttachmentsCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
}
