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
}

class BannerViewController: UIViewController {

    let viewModel: BannerViewModel
    weak var delegate: BannerViewControllerDelegate?

    private(set) lazy var customView = UIView()
    private(set) lazy var remoteContentBanner = RemoteContentBannerView()

    init(viewModel: BannerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func hideBanner() {
        view.subviews.forEach({ $0.removeFromSuperview() })
    }

    func showRemoteContentBanner() {
        customView.subviews.forEach({ $0.removeFromSuperview() })
        remoteContentBanner.titleLabel.attributedText =
            LocalString._banner_remote_content_title.apply(style: FontManager.Caption)
        remoteContentBanner.loadContentButton.setAttributedTitle(
            LocalString._banner_load_remote_content.apply(style: FontManager.body3RegularNorm),
            for: .normal
        )
        customView.addSubview(remoteContentBanner)

        [
            remoteContentBanner.topAnchor.constraint(equalTo: customView.topAnchor, constant: 12),
            remoteContentBanner.leadingAnchor.constraint(equalTo: customView.leadingAnchor, constant: 12),
            remoteContentBanner.trailingAnchor.constraint(equalTo: customView.trailingAnchor, constant: -12),
            remoteContentBanner.bottomAnchor.constraint(equalTo: customView.bottomAnchor, constant: -12)
        ].activate()
        remoteContentBanner.loadContentButton.addTarget(self,
                                                        action: #selector(self.loadRemoteContent),
                                                        for: .touchUpInside)
    }

    @objc
    func loadRemoteContent() {
        delegate?.loadRemoteContent()
        self.hideBanner()
    }
}
