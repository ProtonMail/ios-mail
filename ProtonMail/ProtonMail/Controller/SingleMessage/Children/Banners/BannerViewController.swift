//
//  BannerViewController.swift
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

protocol BannerViewControllerDelegate: AnyObject {
    func loadRemoteContent()
    func loadEmbeddedImage()
    func handleMessageExpired()
    func hideBannerController()
    func showBannerController()
}

class BannerViewController: UIViewController {

    let viewModel: BannerViewModel
    weak var delegate: BannerViewControllerDelegate?

    private(set) lazy var customView = UIView()
    private(set) var containerView: UIStackView?
    private(set) var remoteContentBanner: CompactBannerView?
    private(set) var embeddedImageBanner: CompactBannerView?
    private(set) var errorBanner: CompactBannerView?
    private(set) var expirationBanner: CompactBannerView?
    private(set) var unsubscribeBanner: CompactBannerView?
    private(set) lazy var spamBanner = SpamBannerView()
    private(set) var autoReplyBanner: CompactBannerView?
    private(set) var receiptBanner: CompactBannerView?
    private(set) var decryptionErrorBanner: CompactBannerView?

    private(set) var displayedBanners: [BannerType: UIView] = [:] {
        didSet {
            displayedBanners.isEmpty ? delegate?.hideBannerController() : delegate?.showBannerController()
        }
    }

    init(viewModel: BannerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        self.viewModel.updateExpirationTime = { [weak self] offset in
            let newTitle = BannerViewModel.calculateExpirationTitle(of: offset)
            self?.expirationBanner?.updateTitleText(newTitle: newTitle)
        }

        self.viewModel.messageExpired = { [weak self] in
            self?.delegate?.handleMessageExpired()
        }
    }

    required init?(coder: NSCoder) { nil }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupContainerView()

        let bannersBeforeUpdate = displayedBanners

        if viewModel.expirationTime != .distantFuture {
            self.showExpirationBanner()
        }
        handleUnsubscribeBanner()
        handleSpamBanner()
        handleAutoReplyBanner()
        setUpMessageObservation()
        handleReceiptBanner()

        guard bannersBeforeUpdate.sortedBanners != displayedBanners.sortedBanners else { return }
        viewModel.recalculateCellHeight?(false)
        view.alpha = 0
        delay(0.5) {
            self.view.alpha = 1
        }
    }

    func hideBanner(type: BannerType) {
        if let view = displayedBanners[type] {
            view.removeFromSuperview()
            displayedBanners.removeValue(forKey: type)
        }
        viewModel.recalculateCellHeight?(false)
    }

    private func handleSpamBanner() {
        let isSpamBannerPresenter = displayedBanners.contains(where: { $0.key == .spam })
        let isSpam = viewModel.message.spam != nil
        if isSpamBannerPresenter && isSpam == false {
            hideBanner(type: .spam)
        } else if let spamType = viewModel.spamType, isSpamBannerPresenter == false {
            showSpamBanner(spamType: spamType)
        }
    }

    private func showSpamBanner(spamType: SpamType) {
        spamBanner.infoTextView.attributedText = spamType.text
        spamBanner.iconImageView.image = spamType.icon
        spamBanner.button.setAttributedTitle(spamType.buttonTitle, for: .normal)
        spamBanner.button.isHidden = spamType.buttonTitle == nil
        spamBanner.button.addTarget(self, action: #selector(markAsLegitimate), for: .touchUpInside)
        addBannerView(type: .spam, shouldAddContainer: true, bannerView: spamBanner)
    }

    private func setUpMessageObservation() {
        viewModel.reloadBanners = { [weak self] in
            self?.handleUnsubscribeBanner()
            self?.handleSpamBanner()
            self?.handleAutoReplyBanner()
        }
    }

    private func handleReceiptBanner() {
        let isPresented = displayedBanners.contains(where: { $0.key == .sendReceipt })
        guard !isPresented, viewModel.shouldShowReceiptBanner else { return }
        showReceiptBanner()
    }

    private func handleUnsubscribeBanner() {
        let isUnsubscribeBannerDisplayed = displayedBanners.contains(where: { $0.key == .unsubscribe })
        if isUnsubscribeBannerDisplayed && !viewModel.canUnsubscribe {
            hideBanner(type: .unsubscribe)
        }
        guard viewModel.canUnsubscribe && !isUnsubscribeBannerDisplayed else { return }
        showUnsubscribeBanner()
    }

    private func handleAutoReplyBanner() {
        let isAutoReplyBannerDisplayed = displayedBanners.contains(where: { $0.key == .autoReply })
        if !isAutoReplyBannerDisplayed && viewModel.isAutoReply {
            showAutoReplyBanner()
        }
    }

    private func showAutoReplyBanner() {
        let banner = CompactBannerView(appearance: .normal,
                                       title: LocalString._autoreply_compact_banner_description,
                                       icon: Asset.lightbulb.image,
                                       action: nil)
        autoReplyBanner = banner
        addBannerView(type: .autoReply, shouldAddContainer: true, bannerView: banner)
    }

    private func setupContainerView() {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        customView.addSubview(stackView)

        [
            stackView.topAnchor.constraint(equalTo: customView.topAnchor, constant: 4.0),
            stackView.bottomAnchor.constraint(equalTo: customView.bottomAnchor, constant: -4.0),
            stackView.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: customView.trailingAnchor)
        ].activate()
        containerView = stackView
    }

    private func showRemoteContentBanner() {
        let banner = CompactBannerView(appearance: .normal,
                                       title: LocalString._banner_remote_content_new_title,
                                       icon: Asset.mailRemoteContentIcon.image,
                                       action: { [weak self] in
            self?.loadRemoteContent()
        })
        remoteContentBanner = banner
        addBannerView(type: .remoteContent, shouldAddContainer: true, bannerView: banner)
    }

    private func showEmbeddedImageBanner() {
        let banner = CompactBannerView(appearance: .normal,
                                       title: LocalString._banner_embedded_image_new_title,
                                       icon: Asset.mailRemoteContentIcon.image) { [weak self] in
            self?.loadEmbeddedImages()
        }
        embeddedImageBanner = banner
        addBannerView(type: .embeddedContent, shouldAddContainer: true, bannerView: banner)
    }

    private func showExpirationBanner() {
        let title = BannerViewModel.calculateExpirationTitle(of: viewModel.getExpirationOffset())
        let banner = CompactBannerView(appearance: .expiration,
                                       title: title,
                                       icon: Asset.mailHourglass.image,
                                       action: nil)
        expirationBanner = banner
        addBannerView(type: .expiration, shouldAddContainer: true, bannerView: banner)
    }

    private func showUnsubscribeBanner() {
        let banner = CompactBannerView(appearance: .normal,
                                       title: LocalString._unsubscribe_compact_banner_description,
                                       icon: Asset.unsubscribe.image) { [weak self] in
            self?.viewModel.unsubscribe()
        }
        unsubscribeBanner = banner
        addBannerView(type: .unsubscribe, shouldAddContainer: true, bannerView: banner)
    }

    private func showReceiptBanner() {
        let banner: CompactBannerView
        if viewModel.hasSentReceipt {
            banner = CompactBannerView(appearance: .normal,
                                       title: LocalString._receipt_sent,
                                       icon: Asset.icBell.image,
                                       action: nil)
        } else {
            banner = CompactBannerView(appearance: .normal,
                                       title: LocalString._banner_title_send_read_receipt,
                                       icon: Asset.icBell.image) { [weak self] in
                self?.sendReceipt()
            }
        }
        receiptBanner = banner
        addBannerView(type: .sendReceipt, shouldAddContainer: true, bannerView: banner)
    }

    private func addBannerView(type: BannerType, shouldAddContainer: Bool, bannerView: UIView) {
        guard let containerView = self.containerView, displayedBanners[type] == nil else { return }
        var viewToAdd = bannerView
        if shouldAddContainer {
            let bannerContainerView = UIView()
            bannerContainerView.addSubview(bannerView)
            [
                bannerView.topAnchor.constraint(equalTo: bannerContainerView.topAnchor, constant: 4),
                bannerView.leadingAnchor.constraint(equalTo: bannerContainerView.leadingAnchor, constant: 8),
                bannerView.trailingAnchor.constraint(equalTo: bannerContainerView.trailingAnchor, constant: -8),
                bannerView.bottomAnchor.constraint(equalTo: bannerContainerView.bottomAnchor, constant: -4)
            ].activate()
            viewToAdd = bannerContainerView
        }
        let indexToInsert = findIndexToInsert(type)
        containerView.insertWithFadeInAnimation(subview: viewToAdd, at: indexToInsert)
        displayedBanners[type] = viewToAdd
    }

    private func findIndexToInsert(_ typeToInsert: BannerType) -> Int {
        guard let containerView = self.containerView else { return 0 }

        var indexToInsert = containerView.arrangedSubviews.count
        for (index, view) in containerView.arrangedSubviews.enumerated() {
            if let type = displayedBanners.first(where: { _, value -> Bool in
                return value == view
            }) {
                if type.key.order > typeToInsert.order {
                    indexToInsert = index
                }
            }
        }
        return indexToInsert
    }

    @objc
    private func loadRemoteContent() {
        delegate?.loadRemoteContent()
        self.hideBanner(type: .remoteContent)
        viewModel.resetLoadedHeight?()
    }

    @objc
    private func loadEmbeddedImages() {
        delegate?.loadEmbeddedImage()
        self.hideBanner(type: .embeddedContent)
        viewModel.resetLoadedHeight?()
    }

    @objc
    private func markAsLegitimate() {
        viewModel.markAsLegitimate()
        hideBanner(type: .spam)
    }

    @objc
    private func sendReceipt() {
        guard self.isOnline else {
            LocalString._no_internet_connection.alertToast(withTitle: true, view: self.view, preventCopies: true)
            return
        }
        viewModel.sendReceipt()
        self.receiptBanner?.updateTitleText(newTitle: LocalString._receipt_sent)
        self.receiptBanner?.disableTapGesture()
    }
}

// MARK: - Exposed Method
extension BannerViewController {
    func showContentBanner(remoteContent: Bool, embeddedImage: Bool) {
        let bannersBeforeUpdate = displayedBanners
        if displayedBanners[.remoteContent]?.subviews.first as? RemoteAndEmbeddedBannerView != nil {
            return
        } else if remoteContent && embeddedImage {
            showRemoteContentBanner()
            showEmbeddedImageBanner()
        } else if remoteContent {
            showRemoteContentBanner()
        } else if embeddedImage {
            showEmbeddedImageBanner()
        }

        guard bannersBeforeUpdate.sortedBanners != displayedBanners.sortedBanners else { return }
        viewModel.recalculateCellHeight?(false)
    }

    func showErrorBanner(error: NSError) {
        let banner = CompactBannerView(appearance: .alert,
                                       title: error.localizedDescription,
                                       icon: Asset.icExclamationCircleFilled.image,
                                       action: nil)
        errorBanner = banner
        addBannerView(type: .error, shouldAddContainer: true, bannerView: banner)
        viewModel.recalculateCellHeight?(false)
    }

    func showDecryptionBanner(action: @escaping () -> Void) {
        guard !displayedBanners.contains(where: { $0.key == .decryptionError }) else {
            return
        }
        let title = "\(LocalString._decryption_error): \(LocalString._decryption_of_this_message_failed)"
        let banner = CompactBannerView(appearance: .alert,
                                       title: title,
                                       icon: Asset.icExclamationCircleFilled.image,
                                       action: action)
        decryptionErrorBanner = banner
        addBannerView(type: .decryptionError,
                      shouldAddContainer: true,
                      bannerView: banner)
    }

    func hideDecryptionBanner() {
        guard displayedBanners.contains(where: { $0.key == .decryptionError }) else {
            return
        }
        hideBanner(type: .decryptionError)
    }
}

private extension Dictionary where Key == BannerType, Value == UIView {

    var sortedBanners: [Key] {
        keys.sorted(by: { $0.order > $1.order })
    }

}

private extension UIStackView {
    func insertWithFadeInAnimation(subview: UIView, at index: Int) {
        subview.alpha = 0.0
        insertArrangedSubview(subview, at: index)
        UIView.animate(withDuration: 0.15, delay: 0.2, options: .curveEaseInOut) {
            subview.alpha = 1.0
        }
    }
}
