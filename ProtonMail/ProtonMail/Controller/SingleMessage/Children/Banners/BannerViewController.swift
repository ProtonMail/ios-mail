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

import PMUIFoundations

protocol BannerViewControllerDelegate: class {
    func loadRemoteContent()
    func loadEmbeddedImage()
    func handleMessageExpired()
    func hideBannerController()
    func showBannerController()
}

class BannerViewController: UIViewController {

    enum BannerType: Int {
        case remoteContent
        case expiration
        case spam
        case error
        case unsubscribe

        var order: Int {
            rawValue
        }
    }

    let viewModel: BannerViewModel
    weak var delegate: BannerViewControllerDelegate?

    private(set) lazy var customView = UIView()
    private(set) var containerView: UIStackView?
    private(set) lazy var remoteContentBanner = RemoteContentBannerView()
    private(set) lazy var embeddedImageBanner = EmbeddedImageBannerView()
    private(set) lazy var errorBanner = ErrorBannerView()
    private(set) lazy var expirationBanner = ExpirationBannerView()
    private(set) lazy var remoteAndEmbeddedContentBanner = RemoteAndEmbeddedBannerView()
    private(set) lazy var unsubscribeBanner = UnsubscribeBanner()
    private(set) lazy var spamBanner = SpamBannerView()

    private(set) var displayedBanners: [BannerType: UIView] = [:] {
        didSet {
            displayedBanners.isEmpty ? delegate?.hideBannerController() : delegate?.showBannerController()
        }
    }

    init(viewModel: BannerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        self.viewModel.updateExpirationTime = { [weak self] offset in
            self?.expirationBanner.updateTitleWith(offset: offset)
        }

        self.viewModel.messageExpired = { [weak self] in
            self?.delegate?.handleMessageExpired()
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupContainerView()

        if viewModel.expirationTime != .distantFuture {
            self.showExpirationBanner()
        }
        handleUnsubscribeBanner()
        handleSpamBanner()
        setUpMessageObservation()
    }

    func hideBanner(type: BannerType) {
        if let view = displayedBanners[type] {
            view.removeFromSuperview()
            displayedBanners.removeValue(forKey: type)
        }
    }

    func showContentBanner(remoteContent: Bool, embeddedImage: Bool) {
        if displayedBanners[.remoteContent]?.subviews.first as? RemoteAndEmbeddedBannerView != nil {
            return
        } else if remoteContent && embeddedImage {
            showRemoteAndEmbeddedContentBanner()
        } else if remoteContent {
            showRemoteContentBanner()
        } else if embeddedImage {
            showEmbeddedImageBanner()
        }
    }

    func showErrorBanner(error: NSError) {
        errorBanner.setErrorTitle(error.localizedDescription)
        addBannerView(type: .error, shouldAddContainer: true, bannerView: errorBanner)
    }

    private func handleSpamBanner() {
        let isSpamBannerPresenter = displayedBanners.contains(where: { $0.key == .spam })
        isSpamBannerPresenter ? hideBanner(type: .spam) : ()
        guard let spamType = viewModel.spamType else { return }
        showSpamBanner(spamType: spamType)
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
        }
    }

    private func handleUnsubscribeBanner() {
        let isUnsubscribeBannerDisplayed = displayedBanners.contains(where: { $0.key == .unsubscribe })
        if isUnsubscribeBannerDisplayed && !viewModel.canUnsubscribe {
            hideBanner(type: .unsubscribe)
        }
        guard viewModel.canUnsubscribe && !isUnsubscribeBannerDisplayed else { return }
        showUnsubscribeBanner()
    }

    private func setupContainerView() {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        customView.addSubview(stackView)

        [
            stackView.topAnchor.constraint(equalTo: customView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: customView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: customView.trailingAnchor)
        ].activate()
        containerView = stackView
    }

    private func showRemoteContentBanner() {
        remoteContentBanner.loadContentButton.addTarget(self,
                                                        action: #selector(self.loadRemoteContent),
                                                        for: .touchUpInside)
        addBannerView(type: .remoteContent, shouldAddContainer: true, bannerView: remoteContentBanner)
    }

    private func showEmbeddedImageBanner() {
        embeddedImageBanner.loadContentButton.addTarget(self,
                                                        action: #selector(self.loadEmbeddedImages),
                                                        for: .touchUpInside)
        addBannerView(type: .remoteContent, shouldAddContainer: true, bannerView: embeddedImageBanner)
    }

    private func showRemoteAndEmbeddedContentBanner() {
        remoteAndEmbeddedContentBanner.loadImagesButton.addTarget(self,
                                                                  action: #selector(self.loadEmbeddedImageAndCheck),
                                                                  for: .touchUpInside)
        remoteAndEmbeddedContentBanner.loadContentButton.addTarget(self,
                                                                   action: #selector(self.loadRemoteContentAndCheck),
                                                                   for: .touchUpInside)
        addBannerView(type: .remoteContent, shouldAddContainer: true, bannerView: remoteAndEmbeddedContentBanner)
    }

    private func showExpirationBanner() {
        let banner = self.expirationBanner
        banner.updateTitleWith(offset: viewModel.getExpirationOffset())

        addBannerView(type: .expiration, shouldAddContainer: false, bannerView: banner)
    }

    private func showUnsubscribeBanner() {
        let banner = unsubscribeBanner
        banner.unsubscribeButton.addTarget(viewModel, action: #selector(viewModel.unsubscribe), for: .touchUpInside)
        addBannerView(type: .unsubscribe, shouldAddContainer: true, bannerView: banner)
    }

    private func addBannerView(type: BannerType, shouldAddContainer: Bool, bannerView: UIView) {
        guard let containerView = self.containerView else { return }
        var viewToAdd = bannerView
        if shouldAddContainer {
            let bannerConainterView = UIView()
            bannerConainterView.addSubview(bannerView)
            [
                bannerView.topAnchor.constraint(equalTo: bannerConainterView.topAnchor, constant: 12),
                bannerView.leadingAnchor.constraint(equalTo: bannerConainterView.leadingAnchor, constant: 12),
                bannerView.trailingAnchor.constraint(equalTo: bannerConainterView.trailingAnchor, constant: -12),
                bannerView.bottomAnchor.constraint(equalTo: bannerConainterView.bottomAnchor, constant: -12)
            ].activate()
            viewToAdd = bannerConainterView
        }
        let indexToInsert = findIndexToInsert(type)

        containerView.insertArrangedSubview(viewToAdd, at: indexToInsert)
        displayedBanners[type] = viewToAdd
    }

    private func findIndexToInsert(_ typeToInsert: BannerType) -> Int {
        guard let containerView = self.containerView else { return 0 }

        var indexToInsert = 0
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
    private func loadRemoteContentAndCheck() {
        delegate?.loadRemoteContent()
        remoteAndEmbeddedContentBanner.loadContentButton.isEnabled = false
        if remoteAndEmbeddedContentBanner.areBothButtonDisabled {
            self.hideBanner(type: .remoteContent)
        }
    }

    @objc
    private func loadEmbeddedImageAndCheck() {
        delegate?.loadEmbeddedImage()
        remoteAndEmbeddedContentBanner.loadImagesButton.isEnabled = false
        if remoteAndEmbeddedContentBanner.areBothButtonDisabled {
            self.hideBanner(type: .remoteContent)
        }
    }

    @objc
    private func loadRemoteContent() {
        delegate?.loadRemoteContent()
        self.hideBanner(type: .remoteContent)
    }

    @objc
    private func loadEmbeddedImages() {
        delegate?.loadEmbeddedImage()
        self.hideBanner(type: .remoteContent)
    }

    @objc
    private func markAsLegitimate() {
        viewModel.markAsLegitimate()
        hideBanner(type: .spam)
    }

}
