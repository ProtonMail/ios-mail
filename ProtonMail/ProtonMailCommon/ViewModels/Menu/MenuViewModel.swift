//
//  MenuViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/20/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//
import Foundation
import CoreData

enum MenuViewError: Error {
    
}

enum MenuSection {
    case inboxes    //general inbox list
    case others      //other options contacts, settings, signout
    case labels      //label inbox
    case unknown    //do nothing by default
}

extension Mirror { // TODO: unused, consider removing
    
    private func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        
        // Properties of this instance:
        for attr in self.children {
            if let propertyName = attr.label {
                dict[propertyName] = attr.value
            }
        }
        
        // Add properties of superclass:
        if let parent = self.superclassMirror {
            for (propertyName, value) in parent.toDictionary() {
                dict[propertyName] = value
            }
        }
        
        return dict
    }
}

class MenuViewModel {
    
    init() { }
    
    //
    func setupMenu() {
        fatalError("This method must be overridden")
    }
    func setupLabels(delegate: NSFetchedResultsControllerDelegate?) {
        fatalError("This method must be overridden")
    }

    //
    func sectionCount() -> Int {
        fatalError("This method must be overridden")
    }
    func section(at: Int) -> MenuSection {
        fatalError("This method must be overridden")
    }
    func inboxesCount() -> Int {
        fatalError("This method must be overridden")
    }
    func othersCount() -> Int {
        fatalError("This method must be overridden")
    }
    func labelsCount() -> Int {
        fatalError("This method must be overridden")
    }
    func label(at : Int) -> Label? {
        fatalError("This method must be overridden")
    }
    func item(inboxes at: Int ) ->MenuItem {
        fatalError("This method must be overridden")
    }
    func item(others at: Int ) ->MenuItem {
        fatalError("This method must be overridden")
    }
    
    func find( section : MenuSection, item : MenuItem) -> IndexPath {
        fatalError("This method must be overridden")
    }
    
}
