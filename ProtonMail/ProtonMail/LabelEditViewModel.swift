//
//  LabelEditViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


public class LabelEditViewModel {
    
    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (code : Int, errorMessage : String) -> Void
    
    let colors : [String] = ["#7272a7","#cf5858", "#c26cc7", "#7569d1", "#69a9d1", "#5ec7b7", "#72bb75", "#c3d261", "#e6c04c", "#e6984c", "#8989ac", "#cf7e7e", "#c793ca", "#9b94d1", "#a8c4d5", "#97c9c1", "#9db99f", "#c6cd97", "#e7d292", "#dfb286"]
    
    public init() {
        
    }
    
    func getColorCount() -> Int {
        return colors.count
    }
    
    func getColor(index : Int) -> String {
        return colors[index]
    }

    public func getTitle() -> String {
        fatalError("This method must be overridden")
    }
    
    public func getSelectedIndex() -> NSIndexPath {
        let count = UInt32(colors.count)
        let rand = Int(arc4random_uniform(count))
        return NSIndexPath(forRow: rand, inSection: 0)
    }
    
    public func getPlaceHolder() -> String {
        fatalError("This method must be overridden")
    }
    
    public func getRightButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    public func createLabel (name : String, color : String, error:ErrorBlock,  complete: OkBlock)  {
        fatalError("This method must be overridden")
    }
//
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
