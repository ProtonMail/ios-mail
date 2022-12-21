// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
@testable import ProtonMail
import ProtonCore_TestingToolkit

final class MockUndoActionManager: UndoActionManagerProtocol {

    @FuncStub(MockUndoActionManager.addUndoToken(_:undoActionType:)) var callAddUndoToken
    func addUndoToken(_ token: ProtonMail.UndoTokenData, undoActionType: ProtonMail.UndoAction?) {
        callAddUndoToken(token, undoActionType)
    }

    @FuncStub(MockUndoActionManager.addUndoTokens(_:undoActionType:)) var callAddUndoTokens
    func addUndoTokens(_ tokens: [String], undoActionType: ProtonMail.UndoAction?) {
        callAddUndoTokens(tokens, undoActionType)
    }

    @FuncStub(MockUndoActionManager.showUndoSendBanner(for:)) var callShowUndoSendBanner
    func showUndoSendBanner(for messageID: ProtonMail.MessageID) {
        callShowUndoSendBanner(messageID)
    }

    @FuncStub(MockUndoActionManager.register(handler:)) var callRegister
    func register(handler: ProtonMail.UndoActionHandlerBase) {
        callRegister(handler)
    }

    @FuncStub(MockUndoActionManager.requestUndoAction(undoTokens:completion:)) var callRequestUndoAction
    func requestUndoAction(undoTokens: [String], completion: ((Bool) -> Void)?) {
        callRequestUndoAction(undoTokens, completion)
    }

    func calculateUndoActionBy(labelID: ProtonMail.LabelID) -> ProtonMail.UndoAction? {
        return nil
    }

    @FuncStub(MockUndoActionManager.addTitleWithAction(title:action:)) var callAddTitleWithAction
    func addTitleWithAction(title: String, action: ProtonMail.UndoAction) {
        callAddTitleWithAction(title, action)
    }
}
