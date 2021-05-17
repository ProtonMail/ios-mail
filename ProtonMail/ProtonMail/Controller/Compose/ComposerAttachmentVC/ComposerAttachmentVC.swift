//
//  ComposerAttachmentVC.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

protocol ComposerAttachmentVCDelegate: AnyObject {
    func delete(attachment: Attachment)
}

final class ComposerAttachmentVC: UIViewController {

    private var tableView: UITableView?
    @objc dynamic
    private(set) var tableHeight: CGFloat = 0
    private(set) var datas: [Attachment] = []
    private weak var delegate: ComposerAttachmentVCDelegate?
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private var height: NSLayoutConstraint?
    private let cellHeight: CGFloat = 52

    init(attachments: [Attachment], delegate: ComposerAttachmentVCDelegate?) {
        super.init(nibName: nil, bundle: nil)
        attachments.forEach { att in
            if att.objectID.isTemporaryID {
                att.managedObjectContext?.performAndWait {
                    try? att.managedObjectContext?.obtainPermanentIDs(for: [att])
                }
            }
        }
        self.datas = attachments
        self.delegate = delegate
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView?.reloadData()
    }

    func addNotificationObserver() {
        self.removeNotificationObserver()
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(self.attachmentUploaded(noti:)),
                         name: .attachmentUploaded,
                         object: nil)
    }

    func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    func add(attachments: [Attachment], completeHandler: (()->())? = nil) {
        self.queue.addOperation {
            let existedID = self.datas
                .map { $0.objectID.uriRepresentation().absoluteString }
            let attachments = attachments
                .filter { !existedID.contains($0.objectID.uriRepresentation().absoluteString) }

            // FIXME: insert function for better UX
            // the insert function could break in the concurrency
            self.datas += attachments
            completeHandler?()
            DispatchQueue.main.async {
                self.tableView?.reloadData()
                self.updateTableViewHeight()
            }
        }
    }

    func delete(attachment: Attachment) {
        self.queue.addOperation {
            guard let index = self.datas.firstIndex(of: attachment) else {
                return
            }
            self.datas.remove(at: index)

            DispatchQueue.main.async {
                self.tableView?.beginUpdates()
                let path = IndexPath(row: index, section: 0)
                self.tableView?.deleteRows(at: [path], with: .automatic)
                self.tableView?.endUpdates()
                self.updateTableViewHeight()
            }
        }
    }
}

extension ComposerAttachmentVC {
    private func setup() {
        self.setupTableView()
    }

    private func setupTableView() {
        let table = UITableView()
        self.view.addSubview(table)

        [
            table.topAnchor.constraint(equalTo: self.view.topAnchor),
            table.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            table.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            table.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16)
        ].activate()

        self.updateTableViewHeight()
        self.height = table.heightAnchor.constraint(equalToConstant: self.tableHeight)
        self.height?.priority = UILayoutPriority(999)
        self.height?.isActive = true

        let nib = ComposerAttachmentCellTableViewCell.defaultNib()
        let cellID = ComposerAttachmentCellTableViewCell.defaultID()
        table.register(nib, forCellReuseIdentifier: cellID)
        table.tableFooterView = UIView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        self.tableView = table
    }

    private func updateTableViewHeight() {
        let newHeight = CGFloat(self.datas.count) * self.cellHeight
        self.height?.constant = newHeight
        self.tableHeight = newHeight
    }

    @objc
    private func attachmentUploaded(noti: Notification) {
        self.queue.addOperation {
            guard let objectID = noti.userInfo?["objectID"] as? String,
                  let attachmentID = noti.userInfo?["attachmentID"] as? String,
                  let index = self.datas.firstIndex(where: { $0.objectID.uriRepresentation().absoluteString == objectID }) else {
                return
            }
            self.datas[index].attachmentID = attachmentID
            DispatchQueue.main.async {
                self.tableView?.beginUpdates()
                let path = IndexPath(row: index, section: 0)
                self.tableView?.reloadRows(at: [path], with: .automatic)
                self.tableView?.endUpdates()
            }
        }
    }
}

extension ComposerAttachmentVC: UITableViewDataSource, UITableViewDelegate, ComposerAttachmentCellDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.cellHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = ComposerAttachmentCellTableViewCell.defaultID()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? ComposerAttachmentCellTableViewCell else {
            return ComposerAttachmentCellTableViewCell()
        }

        let row = indexPath.row
        let data = self.datas[row]
        let isUploading = data.attachmentID == "0"
        cell.config(objectID: data.objectID.uriRepresentation().absoluteString,
                    name: data.fileName,
                    size: data.fileSize.intValue,
                    mime: data.mimeType,
                    isUploading: isUploading,
                    delegate: self)
        return cell
    }

    func clickDeleteButton(for objectID: String) {
        guard let data = self.datas.first(where: { $0.objectID.uriRepresentation().absoluteString == objectID }) else {
            return
        }
        let message = LocalString._remove_attachment_warning
        let alert = UIAlertController(title: data.fileName, message: message, preferredStyle: .alert)
        let remove = UIAlertAction(title: LocalString._general_remove_button, style: .destructive) { _ in
            self.delete(attachment: data)
            self.delegate?.delete(attachment: data)
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .default, handler: nil)
        [cancel, remove].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }
}
