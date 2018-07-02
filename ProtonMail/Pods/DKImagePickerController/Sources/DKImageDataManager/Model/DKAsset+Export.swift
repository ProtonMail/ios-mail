//
//  DKAsset+Export.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 17/11/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import Foundation

/**
 The following properties only available after exporting to local.
 */
@objc
extension DKAsset {
    
    /// The exported file will be placed in this location.
    /// All exported files can be automatically cleaned by the DKImageAssetDiskPurger when appropriate.
    @objc public var localTemporaryPath: URL? {
        
        get { return getAssociatedObject(key: &ExportKeys.localTemporaryPath) as? URL }
        set { setAssociatedObject(key: &ExportKeys.localTemporaryPath, value: newValue) }
    }
    
    @objc public var fileName: String? {
        
        get { return getAssociatedObject(key: &ExportKeys.fileName) as? String }
        set { setAssociatedObject(key: &ExportKeys.fileName, value: newValue) }
    }
    
    /// Indicates the file's size in bytes.
    @objc public var fileSize: UInt {
        
        get { return (getAssociatedObject(key: &ExportKeys.fileSize) as? UInt) ?? 0 }
        set { setAssociatedObject(key: &ExportKeys.fileSize, value: newValue) }
    }
        
    /// If you export an asset whose data is not on the local device, and you have enabled downloading with the isNetworkAccessAllowed property, the progress indicates the progress of the download. A value of 0.0 indicates that the download has just started, and a value of 1.0 indicates the download is complete.
    @objc public var progress: Double {
        
        get { return (getAssociatedObject(key: &ExportKeys.progress) as? Double) ?? 0.0 }
        set { setAssociatedObject(key: &ExportKeys.progress, value: newValue) }
    }
    
    /// Describes the error that occurred if the export has failed or been cancelled.
    @objc public var error: Error? {
        
        get { return getAssociatedObject(key: &ExportKeys.error) as? Error }
        set { setAssociatedObject(key: &ExportKeys.error, value: newValue) }
    }
    
    // MARK: - Private
    
    private struct ExportKeys {
        static fileprivate var localTemporaryPath: UInt8 = 0
        static fileprivate var fileName: UInt8 = 0
        static fileprivate var fileSize: UInt8 = 0
        static fileprivate var progress: UInt8 = 0
        static fileprivate var error: UInt8 = 0
    }
    
    internal func setAssociatedObject(key: UnsafePointer<UInt8>, value: Any?, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN) {
        objc_setAssociatedObject(self, key, value, policy)
    }
    
    internal func getAssociatedObject(key: UnsafePointer<UInt8>) -> Any? {
        return objc_getAssociatedObject(self, key)
    }
    
}
