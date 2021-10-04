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

private struct AttachInfo {
    let objectID: String
    let name: String
    let size: Int
    let mimeType: String
    var attachmentID: String
    var isUploaded: Bool {
        attachmentID != "0" && attachmentID != .empty
    }

    init(attachment: Attachment) {
        self.objectID = attachment.objectID.uriRepresentation().absoluteString
        self.name = attachment.fileName
        self.size = attachment.fileSize.intValue
        self.mimeType = attachment.mimeType
        self.attachmentID = attachment.attachmentID
    }
}

private extension Collection where Element == AttachInfo {
    var areUploaded: Bool {
        allSatisfy { $0.isUploaded }
    }
}

final class ComposerAttachmentVC: UIViewController {

    private var tableView: UITableView?
    private let coreDataService: CoreDataService
    @objc dynamic private(set) var tableHeight: CGFloat = 0

    var isUploading: ((Bool) -> Void)?

    private var datas: [AttachInfo] = []
    private weak var delegate: ComposerAttachmentVCDelegate?
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private var height: NSLayoutConstraint?
    private let cellHeight: CGFloat = 52
    var attachmentCount: Int { self.datas.count }

    init(attachments: [Attachment],
         coreDataService: CoreDataService,
         delegate: ComposerAttachmentVCDelegate?) {
        self.coreDataService = coreDataService
        super.init(nibName: nil, bundle: nil)
        attachments.forEach { att in
            if att.objectID.isTemporaryID {
                att.managedObjectContext?.performAndWait {
                    try? att.managedObjectContext?.obtainPermanentIDs(for: [att])
                }
            }
        }
        self.datas = attachments.map { AttachInfo(attachment: $0) }
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
        self.isUploading?(!datas.areUploaded)

        navigationController?.presentationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView?.reloadData()
    }

    func refreshAttachmentsLoadingState() {
        guard !datas.areUploaded else { return }
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
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(self.attachmentUploadFailed(noti:)),
                         name: .attachmentUploadFailed,
                         object: nil)
    }

    func removeNotificationObserver() {
        // swiftlint:disable:next notification_center_detachment
        NotificationCenter.default.removeObserver(self)
    }

    func getSize(completeHandler: ((Int) -> Void)?) {
        self.queue.addOperation { [weak self] in
            let array = self?.datas ?? []
            let size = array.reduce(into: 0) {
                $0 += $1.size
            }
            completeHandler?(size)
        }
    }

    func add(attachments: [Attachment], completeHandler: (() -> Void)? = nil) {
        self.queue.addOperation { [weak self] in
            guard let self = self else { return }
            let existedID = self.datas.map { $0.objectID }
            let attachments = attachments
                .filter { !existedID.contains($0.objectID.uriRepresentation().absoluteString) && !$0.isSoftDeleted }

            // swiftlint:disable:next todo
            // FIXME: insert function for better UX
            // the insert function could break in the concurrency
            self.datas += attachments.map { AttachInfo(attachment: $0) }
            completeHandler?()
            DispatchQueue.main.async {
                self.tableView?.reloadData()
                self.updateTableViewHeight()
                self.isUploading?(!self.datas.areUploaded)
            }
        }
    }

    func delete(objectID: String) {
        self.queue.addOperation { [weak self] in
            guard let self = self,
                  let index = self.datas.firstIndex(where: { $0.objectID == objectID })
            else { return }
            self.datas.remove(at: index)

            DispatchQueue.main.async {
                self.tableView?.reloadData()
                self.updateTableViewHeight()
                self.isUploading?(!self.datas.areUploaded)
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
        self.queue.addOperation { [weak self] in
            guard let self = self,
                  let objectID = noti.userInfo?["objectID"] as? String,
                  let attachmentID = noti.userInfo?["attachmentID"] as? String,
                  let index = self.datas
                    .firstIndex(where: { $0.objectID == objectID }) else {
                return
            }
            self.datas[index].attachmentID = attachmentID
            DispatchQueue.main.async {
                self.tableView?.reloadData()
                self.tableView?.endUpdates()
                self.isUploading?(!self.datas.areUploaded)
            }
        }
    }

    @objc
    func attachmentUploadFailed(noti: Notification) {
        guard let code = noti.userInfo?["code"] as? Int else { return }
        let uploadingData = self.datas.filter { !$0.isUploaded }
        DispatchQueue.main.async {
            let names = uploadingData.map { $0.name }.joined(separator: "\n")
            let message = "\(LocalString._attachment_upload_failed_body)\n \(names)"
            let title = code == 422 ? LocalString._storage_exceeded: LocalString._attachment_upload_failed_title
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }

        // The message queue is a sequence operation
        // One of the tasks failed, the rest one will be deleted too
        // So if one attachment upload failed, the rest of the attachments won't be uploaded
        let objectIDs = uploadingData.map { $0.objectID }
        let context = self.coreDataService.mainContext
        self.coreDataService.enqueue(context: context, block: { [weak self] context in
            for objectID in objectIDs {
                guard let self = self,
                      let managedObjectID = self.coreDataService.managedObjectIDForURIRepresentation(objectID),
                      let managedObject = try? context.existingObject(with: managedObjectID),
                      let attachment = managedObject as? Attachment else {
                    self?.delete(objectID: objectID)
                    continue
                }
                self.delete(objectID: objectID)
                DispatchQueue.main.async {
                    self.delegate?.delete(attachment: attachment)
                }
            }
        })
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
                as? ComposerAttachmentCellTableViewCell else {
            return ComposerAttachmentCellTableViewCell()
        }

        let row = indexPath.row
        let data = self.datas[row]
        cell.config(objectID: data.objectID,
                    name: data.name,
                    size: data.size,
                    mime: data.mimeType,
                    isUploading: !data.isUploaded,
                    delegate: self)
        return cell
    }

    func clickDeleteButton(for objectID: String) {
        guard let data = self.datas.first(where: { $0.objectID == objectID }) else {
            return
        }

        let message = LocalString._remove_attachment_warning
        let alert = UIAlertController(title: data.name, message: message, preferredStyle: .alert)
        let remove = UIAlertAction(title: LocalString._general_remove_button, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            let context = self.coreDataService.mainContext
            self.coreDataService.enqueue(context: context, block: { [weak self] context in
                guard let self = self,
                      let managedObjectID = self.coreDataService.managedObjectIDForURIRepresentation(objectID),
                      let managedObject = try? context.existingObject(with: managedObjectID),
                      let attachment = managedObject as? Attachment else {
                    self?.delete(objectID: objectID)
                    return
                }
                self.delete(objectID: objectID)
                DispatchQueue.main.async {
                    self.delegate?.delete(attachment: attachment)
                }
            })
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .default, handler: nil)
        [cancel, remove].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }
}

extension ComposerAttachmentVC: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        tableView?.reloadData()
    }

}
