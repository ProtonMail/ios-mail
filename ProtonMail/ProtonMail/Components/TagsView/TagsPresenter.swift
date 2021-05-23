//
//  TagsPresenter.swift
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

class TagsPresenter {

    func presentTags(tags: [TagViewModel], in view: TagsView) {
        view.tagViews = tags.map { tagViewModel in
            let tagView = TagView()
            tagView.tagLabel.attributedText = tagViewModel.title
            tagView.tagLabel.lineBreakMode = .byTruncatingTail
            tagView.tagLabel.isHidden = tagViewModel.title?.string.isEmpty ?? true
            tagView.imageView.image = tagViewModel.icon
            tagView.imageView.isHidden = tagViewModel.icon == nil
            tagView.backgroundColor = tagViewModel.color
            return tagView
        }
    }

}
