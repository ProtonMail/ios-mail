//
//  OnboardViewController.swift
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
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import UIKit

extension OnboardViewController {
    enum OnboardingType {
        case newUser, update
    }
}

final class OnboardViewController: UIViewController, UIScrollViewDelegate {
    private let pageWidth: CGFloat = UIScreen.main.bounds.size.width
    private(set) lazy var customView = OnboardView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13, *) {
            return .darkContent
        }
        return .lightContent
    }

    private let onboardingList: [Onboarding]

    init(type: OnboardingType) {
        switch type {
        case .newUser:
            self.onboardingList = [.page1, .page2, .page3]
        case .update:
            self.onboardingList = [.updateIntro1, .updateIntro2, .updateIntro3]
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        customView.scrollView.delegate = self
        setupView()
        addOnboardViews()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = ((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
        let page = Int(floor(offset))
        customView.pageControl.currentPage = page

        updateView(at: page)
    }

    private func setupView() {
        customView.skipButton.addTarget(self,
                                        action: #selector(self.dismissView),
                                        for: .touchUpInside)
        customView.nextButton.addTarget(self,
                                        action: #selector(self.handleNextButtonAction),
                                        for: .touchUpInside)
    }

    private func updateView(at page: Int) {
        let isLastPage = page == onboardingList.endIndex - 1
        customView.skipButton.isHidden = isLastPage ? true : false

        let title = isLastPage ? LocalString._get_started_title : LocalString._next_btn_title
        customView.nextButton.setTitle(title, for: .normal)
    }

    private func scrollToNextPageIfCan() {
        let currentPage = customView.pageControl.currentPage
        guard currentPage != onboardingList.endIndex - 1 else {
            return
        }

        UIView.animate(withDuration: 0.3) {
            let page = currentPage + 1
            self.customView.scrollView
                .contentOffset = CGPoint(x: Int(self.pageWidth) * page,
                                         y: 0)
        }
    }

    private func addOnboardViews() {
        var previousView: UIView?
        for (index, page) in onboardingList.enumerated() {
            let view = NewOnboardView(frame: .zero)
            view.config(page)
            customView.scrollView.addSubview(view)

            let leadingTarget = previousView?.trailingAnchor ?? customView.scrollView.contentLayoutGuide.leadingAnchor
            var constraints = [
                view.topAnchor.constraint(equalTo: customView.scrollView.contentLayoutGuide.topAnchor),
                view.bottomAnchor.constraint(equalTo: customView.scrollView.contentLayoutGuide.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: leadingTarget),
                view.widthAnchor.constraint(equalToConstant: pageWidth),
                view.heightAnchor.constraint(equalTo: customView.scrollView.heightAnchor)
            ]
            if index == (onboardingList.endIndex - 1) {
                constraints.append(view.trailingAnchor.constraint(equalTo: customView.scrollView.trailingAnchor))
            }
            constraints.activate()
            previousView = view
        }

        let count = onboardingList.count
        customView.pageControl.numberOfPages = count
        customView.pageControl.currentPage = 0
        updateView(at: 0)
    }

    @objc
    private func handleNextButtonAction() {
        let isLastPage = customView.pageControl.currentPage == onboardingList.endIndex - 1
        if isLastPage {
            dismissView()
        } else {
            scrollToNextPageIfCan()
        }
    }

    @objc
    private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
