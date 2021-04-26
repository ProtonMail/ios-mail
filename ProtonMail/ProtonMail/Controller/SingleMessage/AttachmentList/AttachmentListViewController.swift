//
//  AttachmentListViewController.swift
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

import PassKit
import PMUIFoundations
import QuickLook
import UIKit

class AttachmentListViewController: UITableViewController {
    let viewModel: AttachmentListViewModel

    // Used in Quick Look dataSource
    private var tempClearFileURL: URL?

    init(viewModel: AttachmentListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        tableView.register(AttachmentListTableViewCell.self)
        tableView.sectionHeaderHeight = 52.0
        tableView.rowHeight = 72.0

        var titleToAdd = "\(viewModel.attachmentCount) "
        titleToAdd += viewModel.attachmentCount > 1 ?
            LocalString._attachments_list_title :
            LocalString._one_attachment_list_title
        title = titleToAdd
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.attachmentSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.attachmentSections[section] {
        case .normal:
            return viewModel.normalAttachments.count
        case .inline:
            return viewModel.inlineAttachments.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AttachmentListTableViewCell.CellID, for: indexPath)
        if let cellToConfig = cell as? AttachmentListTableViewCell {
            let attachment: AttachmentInfo
            let sectionItem = viewModel.attachmentSections[indexPath.section]
            switch sectionItem {
            case .inline:
                attachment = viewModel.inlineAttachments[indexPath.row]
            case .normal:
                attachment = viewModel.normalAttachments[indexPath.row]
            }

            let byteCountFormatter = ByteCountFormatter()
            let sizeString = "\(byteCountFormatter.string(fromByteCount: Int64(attachment.size)))"

            cellToConfig.configure(mimeType: attachment.mimeType,
                                   fileName: attachment.fileName,
                                   fileSize: sizeString)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionItem = viewModel.attachmentSections[section]
        return PMHeaderView(title: sectionItem.actionTitle,
                            fontSize: 15,
                            titleColor: UIColorManager.TextWeak,
                            titleLeft: 16,
                            titleBottom: 8,
                            background: UIColorManager.BackgroundNorm)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionItem = viewModel.attachmentSections[indexPath.section]
        var attachment: AttachmentInfo
        switch sectionItem {
        case .inline:
            attachment = viewModel.inlineAttachments[indexPath.row]
        case .normal:
            attachment = viewModel.normalAttachments[indexPath.row]
        }

        let errorClosure: (NSError) -> Void = { [weak self] error in
            let alert = error.localizedDescription.alertController()
            alert.addOKAction()
            self?.present(alert, animated: true, completion: nil)
        }

        viewModel.open(attachmentInfo: attachment, failed: errorClosure) { [weak self] url in
            DispatchQueue.main.async {
                self?.openQuickLook(clearfileURL: url,
                                    fileName: attachment.fileName.clear,
                                    type: attachment.mimeType)
            }
        }
    }

    func openQuickLook(clearfileURL: URL, fileName: String, type: String) {
        self.tempClearFileURL = clearfileURL

        if (type == "application/vnd.apple.pkpass" || fileName.contains(check: ".pkpass") == true),
            let pkfile = try? Data(contentsOf: clearfileURL),
            let pass = try? PKPass(data: pkfile),
            let viewController = PKAddPassesViewController(pass: pass),
            // as of iOS 12.0 SDK, PKAddPassesViewController will not be initialized on iPads without any warning 🤯
            (viewController as UIViewController?) != nil {
            self.present(viewController, animated: true, completion: nil)
            return
        }

        let previewQL = QuickViewViewController()
        previewQL.dataSource = self
        previewQL.delegate = self
        self.present(previewQL, animated: true, completion: nil)
    }
}

extension AttachmentListViewController: QLPreviewControllerDataSource, QLPreviewControllerDelegate {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.tempClearFileURL != nil ? 1 : 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if let url = self.tempClearFileURL {
            return url as QLPreviewItem
        } else {
            fatalError("Should not reach here")
        }
    }

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        guard let url = self.tempClearFileURL else {
            return
        }
        try? FileManager.default.removeItem(at: url)
        self.tempClearFileURL = nil
    }
}
