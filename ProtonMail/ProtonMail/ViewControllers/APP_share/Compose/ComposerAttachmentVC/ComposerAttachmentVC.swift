//
//  ComposerAttachmentVC.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import CoreData
import ProtonCoreServices
import ProtonCoreUIFoundations
import UIKit

protocol ComposerAttachmentVCDelegate: AnyObject {
    func composerAttachmentViewController(_ composerVC: ComposerAttachmentVC, didDelete attachment: AttachmentEntity)
    func uploadAttachmentFailed(composerVC: ComposerAttachmentVC)
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

    init(_ attachment: AttachmentEntity) {
        self.objectID = attachment.objectID.rawValue.uriRepresentation().absoluteString
        self.name = attachment.name
        self.size = attachment.fileSize.intValue
        self.mimeType = attachment.rawMimeType
        self.attachmentID = attachment.id.rawValue
    }
}

private extension Collection where Element == AttachInfo {
    var areUploaded: Bool {
        allSatisfy { $0.isUploaded }
    }
}

final class ComposerAttachmentVC: UIViewController {

    private var tableView: UITableView?
    private let contextProvider: CoreDataContextProviderProtocol
    @objc dynamic private(set) var tableHeight: CGFloat = 0
    private let attachInfoUpdateQueue = DispatchQueue(label: "AttachInfo update queue")
    var isUploading: ((Bool) -> Void)?

    // `datas` is mostly updated on `self.queue`, but is also used to populate the table view.
    // `sync` is needed instead of `async`, so that `self.queue` is paused for the duration of the access,
    // to avoid race conditions.
    private var _datas: [AttachInfo] = []
    private var datas: [AttachInfo] {
        get {
            attachInfoUpdateQueue.sync {
                return _datas
            }
        }
        set {
            attachInfoUpdateQueue.sync {
                _datas = newValue
            }
        }
    }

    private weak var delegate: ComposerAttachmentVCDelegate?
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private var height: NSLayoutConstraint?
    private let cellHeight: CGFloat = 52
    var attachmentCount: Int { self.datas.count }

    init(attachments: [AttachmentEntity],
         contextProvider: CoreDataContextProviderProtocol,
         delegate: ComposerAttachmentVCDelegate?) {
        self.contextProvider = contextProvider
        super.init(nibName: nil, bundle: nil)
        self.datas = attachments
            .filter({ $0.isInline == false })
            .map { AttachInfo($0) }
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

    func set(attachments: [AttachmentEntity], completeHandler: @escaping () -> Void) {
        let relevantAttachments = attachments
            .filter { !$0.isSoftDeleted &&
                $0.isInline == false
            }
        let attachmentInfos = relevantAttachments.map(AttachInfo.init)

        self.queue.addOperation { [weak self] in
            guard let self = self else { return }

            self.datas = attachmentInfos
            DispatchQueue.main.async {
                completeHandler()
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
        table.backgroundColor = ColorProvider.BackgroundNorm
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
    private func attachmentUploadFailed(noti: Notification) {
        guard
            let error = noti.userInfo?["error"] as? Error,
            let attachmentURI = noti.userInfo?["attachmentURI"] as? String
        else { return }
        let uploadingData = self.datas.filter { $0.objectID == attachmentURI }
        let isTooManyAttachments = error.responseCode == APIErrorCode.tooManyAttachments
        displayErrorAlert(isTooManyAttachments: isTooManyAttachments, uploadingData: uploadingData, error: error)
        SystemLogger.log(error: error, category: .draft)

        uploadingData.map { $0.objectID }.forEach(delete(objectID:))
        DispatchQueue.main.async {
            self.delegate?.uploadAttachmentFailed(composerVC: self)
        }
    }

    private func displayErrorAlert(isTooManyAttachments: Bool, uploadingData: [AttachInfo], error: Error) {
        DispatchQueue.main.async {
            let message: String
            if uploadingData.isEmpty {
                message = error.localizedDescription
            } else {
                let names = uploadingData.map { $0.name }.joined(separator: "\n")
                message = "\(LocalString._attachment_upload_failed_body) \(names)"
            }

            let title = isTooManyAttachments
            ? LocalString._storage_exceeded : LocalString._attachment_upload_failed_title

            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
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
        let row = indexPath.row
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
                as? ComposerAttachmentCellTableViewCell,
              let data = self.datas[safe: row] else {
            return ComposerAttachmentCellTableViewCell()
        }

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
            self?.delete(objectID: objectID)
            guard let strongSelf = self,
                  let managedObjectID = self?.contextProvider.managedObjectIDForURIRepresentation(objectID) else {
                return
            }
            if let attachment = self?.contextProvider.read(block: { context in
                if let attachment = try? context.existingObject(with: managedObjectID) as? Attachment {
                    return AttachmentEntity(attachment)
                } else {
                    return nil
                }
            }) {
                DispatchQueue.main.async {
                    self?.delegate?.composerAttachmentViewController(strongSelf, didDelete: attachment)
                }
            }
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
