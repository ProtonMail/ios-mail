//
//  FolderEditingViewModelImpl .swift
//  ProtonMail - Created on 4/6/17.
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
// folder editing
final public class FolderEditingViewModelImple : LabelEditViewModel {
    var currentLabel : Label
    
    internal init(label: Label, apiService: APIService, labelService: LabelsDataService) {
        self.currentLabel = label
        super.init(apiService: apiService, labelService: labelService)
    }
    
    override public func title() -> String {
        return LocalString._labels_edit_folder_title
    }
    
    override public func placeHolder() -> String {
        return LocalString._labels_folder_name_text
    }
    
    override public func rightButtonText() -> String {
        return LocalString._general_update_action
    }
    
    override public func name() -> String {
        return currentLabel.name
    }
    
    override public func seletedIndex() -> IndexPath {
        let currentColor = currentLabel.color
        if let index = colors.firstIndex(of: currentColor) {
            return IndexPath(row: index, section: 0)
        } else {
            return super.seletedIndex()
        }
    }
    
    override public func apply(withName name: String, color: String, error: @escaping LabelEditViewModel.ErrorBlock, complete: @escaping LabelEditViewModel.OkBlock) {
        let api = UpdateLabelRequest(id: currentLabel.labelID, name: name, color: color)
        api.call(api: self.apiService) { (task, response, hasError) -> Void in
            if hasError {
                error(response?.code ?? 1000, response?.errorMessage ?? "");
            } else {
                self.currentLabel.name = name
                self.currentLabel.color = color
                if let context = self.currentLabel.managedObjectContext {
                    context.perform {
                        let _ = context.saveUpstreamIfNeeded()
                    }
                }
                complete()
            }
        }
    }
}
