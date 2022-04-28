//
//  ContactTypeViewModel.swift
//  ProtonMail - Created on 5/4/17.
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

class ContactTypeViewModel {

    init() { }

    func getDefinedTypes() -> [ContactFieldType] {
        fatalError("This method must be overridden")
    }

    func getCustomType() -> ContactFieldType {
        fatalError("This method must be overridden")
    }

    func getPickedType() -> ContactFieldType {
        fatalError("This method must be overridden")
    }

    func getSectionType() -> ContactEditSectionType {
        fatalError("This method must be overridden")
    }

    func updateType(t: ContactFieldType) {
        fatalError("This method must be overridden")
    }

    func getSelectedIndexPath() -> IndexPath? {
        fatalError("This method must be overridden")
    }
}
