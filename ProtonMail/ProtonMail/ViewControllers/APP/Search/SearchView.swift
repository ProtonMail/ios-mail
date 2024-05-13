// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreUIFoundations
import UIKit

final class SearchView: UIView {
    let stackView = SubviewFactory.stackView
    let searchBarContainer = UIView()
    let searchBar = SearchBarView()
    let tableView = SubviewFactory.tableView
    let toolBar = PMToolBarView()
    let activityIndicator = SubviewFactory.activityIndicator
    let progressView = SubviewFactory.progressBar
    let noResultImage = SubviewFactory.noResultImage
    let noResultLabel = SubviewFactory.noResultLabel
    let noResultSubLabel = SubviewFactory.noResultSubLabel

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setupLayout()
        searchBarContainer.backgroundColor = ColorProvider.BackgroundNorm
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(searchBarContainer)
        searchBarContainer.addSubview(searchBar)
        stackView.addArrangedSubview(tableView)
        stackView.addArrangedSubview(toolBar)
        addSubview(activityIndicator)
        addSubview(progressView)
        addSubview(noResultImage)
        addSubview(noResultLabel)
        addSubview(noResultSubLabel)
    }

    private func setupLayout() {
        [
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ].activate()
        [
            searchBarContainer.heightAnchor.constraint(equalToConstant: 44.0)
        ].activate()
        [
            searchBar.topAnchor.constraint(equalTo: searchBarContainer.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchBarContainer.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: searchBarContainer.trailingAnchor, constant: -16),
            searchBar.bottomAnchor.constraint(equalTo: searchBarContainer.bottomAnchor)
        ].activate()
        [
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: searchBarContainer.bottomAnchor, constant: 190)
        ].activate()

        [
            progressView.topAnchor.constraint(equalTo: tableView.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: UIFont.smallSystemFontSize)
        ].activate()

        [
            noResultImage.topAnchor.constraint(equalTo: searchBarContainer.bottomAnchor, constant: 135),
            noResultImage.heightAnchor.constraint(equalToConstant: 140),
            noResultImage.widthAnchor.constraint(equalToConstant: 140),
            noResultImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            noResultLabel.topAnchor.constraint(equalTo: noResultImage.bottomAnchor, constant: 8),
            noResultLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            noResultLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            noResultSubLabel.topAnchor.constraint(equalTo: noResultLabel.bottomAnchor, constant: 4),
            noResultSubLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            noResultSubLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ].activate()
    }

    func showNoResult() {
        noResultImage.isHidden = false
        noResultLabel.isHidden = false
        noResultSubLabel.isHidden = false
    }

    func hideNoResult() {
        noResultImage.isHidden = true
        noResultLabel.isHidden = true
        noResultSubLabel.isHidden = true
    }
}

private enum SubviewFactory {
    static var stackView: UIStackView {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        return view
    }

    static var tableView: UITableView {
        let view = UITableView(frame: .zero, style: .grouped)
        view.contentInsetAdjustmentBehavior = .automatic
        view.estimatedRowHeight = 100
        view.rowHeight = UITableView.automaticDimension
        view.estimatedSectionHeaderHeight = 100
        view.backgroundColor = .clear
        view.separatorColor = ColorProvider.SeparatorNorm
        return view
    }

    static var activityIndicator: UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = ColorProvider.BrandNorm
        view.isHidden = true
        view.hidesWhenStopped = true
        return view
    }

    // TODO: need better UI solution for this progress bar
    static var progressBar: UIProgressView {
        let bar = UIProgressView()
        bar.trackTintColor = .black
        bar.progressTintColor = .white
        bar.progressViewStyle = .bar

        let label = UILabel(
            font: UIFont.italicSystemFont(ofSize: UIFont.smallSystemFontSize),
            text: "Indexing local messages",
            textColor: .gray
        )

        label.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(label)
        bar.topAnchor.constraint(equalTo: label.topAnchor).isActive = true
        bar.leadingAnchor.constraint(equalTo: label.leadingAnchor).isActive = true
        bar.trailingAnchor.constraint(equalTo: label.trailingAnchor).isActive = true

        return bar
    }

    static var noResultImage: UIImageView {
        let view = UIImageView()
        view.image = Asset.searchNoResult.image
        view.contentMode = .scaleAspectFill
        view.isHidden = true
        return view
    }

    static var noResultLabel: UILabel {
        let view = UILabel()
        view.attributedText = L10n.Search.noResultsTitle.apply(style: .Headline.alignment(.center))
        view.isHidden = true
        return view
    }

    static var noResultSubLabel: UILabel {
        let view = UILabel()
        view.attributedText = L10n.Search.noResultSubTitle.apply(style: .DefaultWeak.alignment(.center))
        view.isHidden = true
        return view
    }
}
