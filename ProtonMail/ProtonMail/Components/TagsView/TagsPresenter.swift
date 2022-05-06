//
//  TagsPresenter.swift
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
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class TagsPresenter {

    func presentTags(tags: [TagViewModel], in view: TagsView) {
        view.tagViews = tags.map { tagViewModel in
            tagViewModel.icon != nil ? tagIconViewView(tagViewModel) : tagView(tagViewModel)
        }
    }

    private func tagIconViewView(_ viewModel: TagViewModel) -> UIView {
        let view = TagIconView()

        view.tagLabel.attributedText = viewModel.title
        view.tagLabel.lineBreakMode = .byTruncatingTail
        view.imageView.image = viewModel.icon
        view.imageView.tintColor = ColorProvider.IconNorm
        view.backgroundColor = viewModel.color

        return view
    }

    private func tagView(_ viewModel: TagViewModel) -> UIView {
        let view = TagView()

        view.tagLabel.attributedText = viewModel.title
        view.tagLabel.lineBreakMode = .byTruncatingTail
        view.backgroundColor = viewModel.color

        return view
    }

}
