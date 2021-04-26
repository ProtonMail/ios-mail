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

protocol BannerViewControllerDelegate: class {
    func loadRemoteContent()
    func handleMessageExpired()
}

class BannerViewController: UIViewController {

    enum BannerType {
        case remoteContent
        case expiration

        var order: Int {
            switch self {
            case .remoteContent:
                return 1
            case .expiration:
                return 2
            }
        }
    }

    let viewModel: BannerViewModel
    weak var delegate: BannerViewControllerDelegate?

    private(set) lazy var customView = UIView()
    private(set) var containerView: UIStackView?
    private(set) lazy var remoteContentBanner = RemoteContentBannerView()
    private(set) lazy var expirationBanner = ExpirationBannerView()

    private(set) var displayedBanners: [BannerType: UIView] = [:]

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

    func hideBanner(type: BannerType) {
        if let view = displayedBanners[type] {
            view.removeFromSuperview()
            displayedBanners.removeValue(forKey: type)
        }
    }

    func showRemoteContentBanner() {
        guard let containerView = self.containerView else { return }

        remoteContentBanner.titleLabel.attributedText =
            LocalString._banner_remote_content_title.apply(style: FontManager.Caption)
        remoteContentBanner.loadContentButton.setAttributedTitle(
            LocalString._banner_load_remote_content.apply(style: FontManager.body3RegularNorm),
            for: .normal
        )

        let bannerConainterView = UIView()
        bannerConainterView.addSubview(remoteContentBanner)
        [
            remoteContentBanner.topAnchor.constraint(equalTo: bannerConainterView.topAnchor, constant: 12),
            remoteContentBanner.leadingAnchor.constraint(equalTo: bannerConainterView.leadingAnchor, constant: 12),
            remoteContentBanner.trailingAnchor.constraint(equalTo: bannerConainterView.trailingAnchor, constant: -12),
            remoteContentBanner.bottomAnchor.constraint(equalTo: bannerConainterView.bottomAnchor, constant: -12)
        ].activate()

        let indexToInsert = findIndexToInsert(.remoteContent)

        containerView.insertArrangedSubview(bannerConainterView, at: indexToInsert)
        displayedBanners[.remoteContent] = bannerConainterView

        remoteContentBanner.loadContentButton.addTarget(self,
                                                        action: #selector(self.loadRemoteContent),
                                                        for: .touchUpInside)
    }

    func showExpirationBanner() {
        guard let containerView = self.containerView else { return }
        let banner = self.expirationBanner
        banner.updateTitleWith(offset: viewModel.getExpirationOffset())
        let indexToInsert = findIndexToInsert(.expiration)
        containerView.insertArrangedSubview(banner, at: indexToInsert)
        displayedBanners[.expiration] = banner
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
    private func loadRemoteContent() {
        delegate?.loadRemoteContent()
        self.hideBanner(type: .remoteContent)
    }
}
