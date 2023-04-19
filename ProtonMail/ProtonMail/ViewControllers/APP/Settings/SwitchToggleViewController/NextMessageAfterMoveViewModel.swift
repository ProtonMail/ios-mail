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
import ProtonCore_Services
import enum ProtonCore_Utilities.Either

final class NextMessageAfterMoveViewModel: SwitchToggleVMProtocol, SwitchToggleVMOutput {


    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }
    let title = L11n.NextMsgAfterMove.settingTitle
    let sectionNumber = 1
    let rowNumber = 1
    let headerTopPadding: CGFloat = 8.0
    let footerTopPadding: CGFloat = 8.0
    private var nextMessageAfterMoveStatusProvider: NextMessageAfterMoveStatusProvider
    private let apiService: APIService

    init(
        _ nextMessageAfterMoveStatusProvider: NextMessageAfterMoveStatusProvider,
        apiService: APIService
    ) {
        self.nextMessageAfterMoveStatusProvider = nextMessageAfterMoveStatusProvider
        self.apiService = apiService
    }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        (L11n.NextMsgAfterMove.rowTitle,
         nextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMove)
    }

    func sectionHeader(of section: Int) -> String? {
        nil
    }

    func sectionFooter(of section: Int) -> Either<String, NSAttributedString>? {
        .left(L11n.NextMsgAfterMove.rowFooterTitle)
    }
}

extension NextMessageAfterMoveViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        let request = UpdateNextMessageOnMoveRequest(isEnable: newStatus)
        apiService.perform(
            request: request,
            response: VoidResponse()
        ) { [weak self] _, response in
            if let error = response.error?.toNSError {
                completion(error)
            } else {
                self?.nextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMove = newStatus
                completion(nil)
            }
        }
    }
}
