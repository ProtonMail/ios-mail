//
//  PagingManager.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class PagingManager {
    struct Constant {
        static let minPage = 1
    }
    
    private(set) var isMorePages = true
    private(set) var nextPage = Constant.minPage
    
    func reset() {
        isMorePages = true
        nextPage = Constant.minPage
    }
    
    func resultCount(count: Int) {
        if count != 0 {
            nextPage++
        } else {
            isMorePages = false
        }
    }
}
