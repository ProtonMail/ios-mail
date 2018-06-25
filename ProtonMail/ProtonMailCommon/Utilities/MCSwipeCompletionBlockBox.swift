//
//  MCSwipeCompletionBlockBox.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 20/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import MCSwipeTableViewCell

/// Wrapper over MCSwipeCompletionBlock to allow usage with target+selector APIs from Swift rather than closures.
class MCSwipeCompletionBlockBox: NSObject {
    typealias Block = MCSwipeCompletionBlock
    private weak var cell: MCSwipeTableViewCell?
    private let block: Block //: ((MCSwipeTableViewCell, MCSwipeTableViewCellState, MCSwipeTableViewCellMode) -> Void)?
    
    /// Execute the underlaying block/closure
    @objc func execute(_ cell: MCSwipeTableViewCell,
                       _ state: MCSwipeTableViewCellState,
                       _ mode: MCSwipeTableViewCellMode)
    {
        if let cell = self.cell {
            self.block(cell, state, mode)
        }
    }
    
    init?(_ block: Block?, _ cell: MCSwipeTableViewCell) {
        guard let block = block else { return nil }
        self.cell = cell
        self.block = block
    }
}
