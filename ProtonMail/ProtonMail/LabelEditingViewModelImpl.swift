//
//  LabelEditingViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


// label editing
final public class LabelEditingViewModelImple : LabelEditViewModel {
    var currentLabel : Label
    
    required public init(label : Label) {
        self.currentLabel = label
    }
    
    override public func title() -> String {
        return NSLocalizedString("Edit Label", comment: "Title")
    }
    
    override public func placeHolder() -> String {
        return NSLocalizedString("Label Name", comment: "place holder")
    }
    
    override public func rightButtonText() -> String {
        return NSLocalizedString("Update", comment: "top right action text")
    }
    
    override public func name() -> String {
        return currentLabel.name
    }
    
    override public func seletedIndex() -> IndexPath {
        let currentColor = currentLabel.color
        if let index = colors.index(of: currentColor) {
            return IndexPath(row: index, section: 0)
        } else {
            return super.seletedIndex()
        }
    }
    
    override public func apply(withName name: String, color: String, error: @escaping LabelEditViewModel.ErrorBlock, complete: @escaping LabelEditViewModel.OkBlock) {
        let api = UpdateLabelRequest<CreateLabelRequestResponse>(id: currentLabel.labelID, name: name, color: color)
        api.call { (task, response, hasError) -> Void in
            if hasError {
                error(response?.code ?? 1000, response?.errorMessage ?? "");
            } else {
                self.currentLabel.name = name
                self.currentLabel.color = color
                if let context = self.currentLabel.managedObjectContext {
                    context.perform() {
                        let _ = context.saveUpstreamIfNeeded()
                    }
                }
                complete()
            }
        }
        
    }
}
