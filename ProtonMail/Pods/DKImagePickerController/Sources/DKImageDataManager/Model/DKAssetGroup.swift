//
//  DKAssetGroup.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/12/13.
//  Copyright © 2015年 ZhangAo. All rights reserved.
//

import Photos

/// A representation of a Photos asset grouping, such as a moment, user-created album, or smart album.
public class DKAssetGroup: NSObject {
    public let groupId: String

    public var groupName: String?

    public var originalCollection: PHAssetCollection?
    public var fetchResult: PHFetchResult<PHAsset>?

    public var totalCount: Int {
        get {
            guard let fetchResult = fetchResult else { return 0 }

            if let displayCount = displayCount, displayCount > 0 {
                return min(displayCount, fetchResult.count)
            } else {
                return fetchResult.count
            }
        }
    }
    
    var displayCount: Int?

    init(groupId: String) {
        self.groupId = groupId
    }
}
