//
//  MCSwipeCompletionBlockBox.swift
//  ProtonMail
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
