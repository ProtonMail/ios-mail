//
//  LabelEditViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


class LabelEditViewModel {
    
    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (_ code : Int, _ errorMessage : String) -> Void
    
    let colors : [String] = ["#7272a7","#cf5858", "#c26cc7", "#7569d1", "#69a9d1", "#5ec7b7", "#72bb75", "#c3d261", "#e6c04c", "#e6984c", "#8989ac", "#cf7e7e", "#c793ca", "#9b94d1", "#a8c4d5", "#97c9c1", "#9db99f", "#c6cd97", "#e7d292", "#dfb286"]
    
    public init() {
        
    }
    
    func colorCount() -> Int {
        return colors.count
    }
    
    func color(at index : Int) -> String {
        return colors[index]
    }

    func title() -> String {
        fatalError("This method must be overridden")
    }
    
    func seletedIndex() -> IndexPath {
        let count = UInt32(colors.count)
        let rand = Int(arc4random_uniform(count))
        return IndexPath(row: rand, section: 0)
    }
    
    func name() -> String {
        return ""
    }
    
    func placeHolder() -> String {
        fatalError("This method must be overridden")
    }
    
    func rightButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    func apply(withName name : String, color : String, error:@escaping ErrorBlock, complete:@escaping OkBlock) {
        fatalError("This method must be overridden")
    }

    
//    public func apply (archiveMessage : Bool) {
//        fatalError("This method must be overridden")
//    }
//    
//    public func cancel () {
//        fatalError("This method must be overridden")
//    }

//    
//    public func getLabelMessage(label : Label!) -> LabelMessageModel! {
//        fatalError("This method must be overridden")
//    }

//    
//    public func showArchiveOption() -> Bool {
//        fatalError("This method must be overridden")
//    }
//    
//    public func getApplyButtonText() -> String {
//        fatalError("This method must be overridden")
//    }
//    
//    public func getCancelButtonText() -> String {
//        fatalError("This method must be overridden")
//    }
//    
//    public func fetchController() -> NSFetchedResultsController? {
//        fatalError("This method must be overridden")
//    }
}
