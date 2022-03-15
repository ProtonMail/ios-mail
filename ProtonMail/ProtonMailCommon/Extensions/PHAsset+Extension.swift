//
//  PHAssert+Extension.swift
//  ProtonMail - Created on 11/29/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation

import Photos

@available(*, deprecated)
extension PHAsset {
    var originalFilename: String? {

        var fname: String?

        let resources = PHAssetResource.assetResources(for: self)
        if let resource = resources.first {
            fname = resource.originalFilename
        }

        if fname == nil {
            // this is an undocumented workaround that works as of iOS 9.1
            fname = self.value(forKey: "filename") as? String
        }

        return fname
    }
}
