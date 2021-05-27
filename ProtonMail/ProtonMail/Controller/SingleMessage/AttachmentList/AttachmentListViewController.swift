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
import ProtonCore_UIFoundations
import QuickLook
import UIKit

class AttachmentListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let viewModel: AttachmentListViewModel
    let tableView: UITableView = UITableView(frame: .zero)
    let bannerContainer: UIView = UIView()
    private var bannerHeightConstraint: NSLayoutConstraint?
    private var isInternetBannerPresented = false

    // Used in Quick Look dataSource
    private var tempClearFileURL: URL?
    private var currentNetworkStatus: NetworkStatus = .NotReachable

    init(viewModel: AttachmentListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        setUpSubviews()
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(AttachmentListTableViewCell.self)
        tableView.sectionHeaderHeight = 52.0
        tableView.rowHeight = 72.0

        var titleToAdd = "\(viewModel.attachmentCount) "
        titleToAdd += viewModel.attachmentCount > 1 ?
            LocalString._attachments_list_title :
            LocalString._one_attachment_list_title
        title = titleToAdd

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged(_:)),
                                               name: NSNotification.Name.reachabilityChanged,
                                               object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateInterface(reachability: sharedInternetReachability)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.attachmentSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.attachmentSections[section] {
        case .normal:
            return viewModel.normalAttachments.count
        case .inline:
            return viewModel.inlineAttachments.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

            if currentNetworkStatus == .NotReachable && !attachment.isDownloaded {
                cellToConfig.selectionStyle = .none
            } else {
                cellToConfig.selectionStyle = .default
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionItem = viewModel.attachmentSections[section]
        return PMHeaderView(title: sectionItem.actionTitle,
                            fontSize: 15,
                            titleColor: UIColorManager.TextWeak,
                            titleLeft: 16,
                            titleBottom: 8,
                            background: UIColorManager.BackgroundNorm)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.selectionStyle == UITableViewCell.SelectionStyle.none {
            return nil
        } else {
            return indexPath
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
            DispatchQueue.main.async {
                let alert = error.localizedDescription.alertController()
                alert.addOKAction()
                self?.present(alert, animated: true, completion: nil)
            }
        }

        viewModel.open(attachmentInfo: attachment, failed: errorClosure) { [weak self] url in
            DispatchQueue.main.async {
                self?.openQuickLook(clearfileURL: url,
                                    fileName: attachment.fileName.clear,
                                    type: attachment.mimeType)
            }
        }
    }
}

private extension AttachmentListViewController {
    private func setUpSubviews() {
        bannerContainer.backgroundColor = UIColorManager.BackgroundNorm
        tableView.backgroundColor = UIColorManager.BackgroundNorm

        let stackView = UIStackView(arrangedSubviews: [bannerContainer, tableView])
        stackView.distribution = .fill
        stackView.axis = .vertical

        view.addSubview(stackView)

        let bannerHeightConstraint = bannerContainer.heightAnchor.constraint(equalToConstant: 0)
        bannerHeightConstraint.isActive = true

        [
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ].activate()
        self.bannerHeightConstraint = bannerHeightConstraint
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

// MARK: - Handle Network status changed
private extension AttachmentListViewController {
    private func showInternetConnectionBanner() {
        guard isInternetBannerPresented == false else { return }
        let banner = MailBannerView()
        bannerContainer.addSubview(banner)

        banner.label.attributedText = LocalString._banner_no_internet_connection
            .apply(style: FontManager.body3RegularTextInverted)

        [
            banner.bottomAnchor.constraint(equalTo: bannerContainer.bottomAnchor),
            banner.leadingAnchor.constraint(equalTo: bannerContainer.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: bannerContainer.trailingAnchor),
            banner.topAnchor.constraint(equalTo: bannerContainer.topAnchor)
        ].activate()

        bannerHeightConstraint?.isActive = false

        view.layoutIfNeeded()

        isInternetBannerPresented = true
    }

    private func hideInternetConnectionBanner() {
        guard isInternetBannerPresented else { return }
        UIView.animate(withDuration: 0.25,
                       animations: { [weak self] in
                        self?.bannerHeightConstraint?.isActive = true
                       },
                       completion: { [weak self] _ in
                        self?.bannerContainer.subviews.forEach { $0.removeFromSuperview() }
                        self?.isInternetBannerPresented = false
                       })
    }

    private func updateInterface(reachability: Reachability) {
        let netStatus = reachability.currentReachabilityStatus()
        currentNetworkStatus = netStatus
        switch netStatus {
        case .NotReachable:
            showInternetConnectionBanner()
        case .ReachableViaWWAN:
            hideInternetConnectionBanner()
        case .ReachableViaWiFi:
            hideInternetConnectionBanner()
        default:
            break
        }
        tableView.reloadData()
    }

    @objc
    private func reachabilityChanged(_ note: Notification) {
        if let currentReachability = note.object as? Reachability {
            self.updateInterface(reachability: currentReachability)
        }
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
