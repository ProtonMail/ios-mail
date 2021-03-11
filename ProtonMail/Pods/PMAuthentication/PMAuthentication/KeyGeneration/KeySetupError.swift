//
//  KeySetupError.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 05.01.2021.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation

enum KeySetupError: Error {
    case keyGenerationFailed
    case keyRingGenerationFailed
    case randomTokenGenerationFailed
    case cantHashPassword
}
