//
//  ContactTypeViewModelImpl.swift
//  Proton Mail - Created on 5/4/17.
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation

class ContactTypeViewModelImpl: ContactTypeViewModel {
    var typeInterface: ContactEditTypeInterface
    init(t: ContactEditTypeInterface) {
        self.typeInterface = t
    }

    override func getPickedType() -> ContactFieldType {
        return typeInterface.getCurrentType()
    }

    override func getDefinedTypes() -> [ContactFieldType] {
        return typeInterface.types()
    }

    override func getCustomType() -> ContactFieldType {
        let type = typeInterface.getCurrentType()
        let types = getDefinedTypes()
        if let _ = types.firstIndex(where: { ( left ) -> Bool in return left.rawString == type.rawString }) {

        } else {
            return type
        }
        return .empty
    }

    override func getSectionType() -> ContactEditSectionType {
        return typeInterface.getSectionType()
    }

    override func updateType(t: ContactFieldType) {
        typeInterface.updateType(type: t)
    }

    override func getSelectedIndexPath() -> IndexPath? {
        if let index = getDefinedTypes().firstIndex(where: {$0.rawString == getPickedType().rawString}) {
            return IndexPath(row: index, section: 0)
        } else if !getCustomType().isEmpty {
            return IndexPath(row: 0, section: 1)
        } else {
            return nil
        }
    }
}
