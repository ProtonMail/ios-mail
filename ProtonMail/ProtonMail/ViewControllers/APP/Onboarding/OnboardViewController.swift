//
//  OnboardViewController.swift
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import UIKit

final class OnboardViewController: UIViewController, UIScrollViewDelegate {
    var onViewDidDisappear: (@MainActor () -> Void)?

    private var pageWidth: CGFloat {
        UIScreen.main.bounds.size.width
    }
    private var viewDidRotate = false
    private(set) lazy var customView = OnboardView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
            return .darkContent
    }

    private let onboardingList: [Onboarding] = [.page2, .page1, .page3]
    private let isPaidUser: Bool

    init(isPaidUser: Bool) {
        self.isPaidUser = isPaidUser
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
        customView.pageControl.addTarget(self, action: #selector(pageControllerIsChange), for: .valueChanged)
        setupView()
        addOnboardViews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        onViewDidDisappear?()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        viewDidRotate = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard viewDidRotate else { return }
        viewDidRotate = false
        scrollTo(page: customView.pageControl.currentPage)
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
        let isLastPage = page == customView.pageControl.numberOfPages - 1
        customView.skipButton.isHidden = isLastPage ? true : false

        let title = isLastPage ? LocalString._get_started_title : LocalString._next_btn_title
        customView.nextButton.setTitle(title, for: .normal)
    }

    private func scrollToNextPageIfCan() {
        let currentPage = customView.pageControl.currentPage
        guard currentPage != onboardingList.endIndex - 1 else {
            return
        }
        scrollTo(page: currentPage + 1)
    }

    private func scrollTo(page: Int) {
        UIView.animate(withDuration: 0.3) {
            self.customView.scrollView
                .contentOffset = CGPoint(x: Int(self.pageWidth) * page, y: 0)
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
                view.widthAnchor.constraint(equalTo: customView.scrollView.widthAnchor),
                view.heightAnchor.constraint(equalTo: customView.scrollView.heightAnchor)
            ]
            if index == (onboardingList.endIndex - 1) {
                constraints.append(view.trailingAnchor.constraint(equalTo: customView.scrollView.trailingAnchor))
            }
            constraints.activate()
            previousView = view
        }

        let count = onboardingList.count
        customView.pageControl.numberOfPages = isPaidUser ? count : count + 1
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
    private func pageControllerIsChange() {
        let newValue = customView.pageControl.currentPage
        scrollTo(page: newValue)
    }

    @objc
    private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
