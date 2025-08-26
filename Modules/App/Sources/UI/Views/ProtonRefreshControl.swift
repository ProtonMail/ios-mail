// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Combine
import Foundation
import InboxCoreUI
import Lottie
import UIKit

/// This class is assigned to the underlying UICollectionView of the SwiftUI List.
final class ProtonRefreshControl: UIRefreshControl, ObservableObject {
    private let spinnerAnimation = LottieAnimationView.protonSpinner
    private let spinnerSize: CGFloat = 28
    private var isAnimating = false
    private let onRefresh: () async -> Void

    private let listPullOffset: AnyPublisher<CGFloat, Never>
    private var cancellables: Set<AnyCancellable> = .init()

    init(listPullOffset: AnyPublisher<CGFloat, Never>, onRefresh: @escaping () async -> Void) {
        self.listPullOffset = listPullOffset
        self.onRefresh = onRefresh
        super.init()
        setUpView()
        setUpLayout()
        setUpBindings()
        setUpBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpView() {
        spinnerAnimation.loopMode = .loop
        addSubview(spinnerAnimation)
        addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    private func setUpLayout() {
        spinnerAnimation.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinnerAnimation.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinnerAnimation.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinnerAnimation.heightAnchor.constraint(equalToConstant: spinnerSize),
            spinnerAnimation.widthAnchor.constraint(equalTo: spinnerAnimation.heightAnchor),
        ])
    }

    private func setUpBindings() {
        listPullOffset
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.updateSpinnerProgressAndAlpha(withOffset: value)
            }
            .store(in: &cancellables)
    }

    override func beginRefreshing() {
        super.beginRefreshing()
        isAnimating = true
        spinnerAnimation.currentProgress = 0
        spinnerAnimation.play()
    }

    override func endRefreshing() {
        super.endRefreshing()
        spinnerAnimation.pause()
        isAnimating = false
    }

    @objc private func refreshData() {
        Task {
            beginRefreshing()
            await onRefresh()
            endRefreshing()
        }
    }

    func updateSpinnerProgressAndAlpha(withOffset offset: CGFloat) {
        guard !isAnimating else { return }
        let maxPullOffset: CGFloat = 150
        let progress = min(offset / maxPullOffset, 1)
        spinnerAnimation.alpha = 2 * progress
        spinnerAnimation.currentProgress = progress / 4
    }
}
