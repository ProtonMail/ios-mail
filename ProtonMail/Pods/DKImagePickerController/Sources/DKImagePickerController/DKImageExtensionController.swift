//
//  DKImageExtensionController.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 16/12/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import Foundation

public class DKImageExtensionContext {
    
    public internal(set) weak var imagePickerController: DKImagePickerController!
    public internal(set) var groupDetailVC: DKAssetGroupDetailVC?
    
}

////////////////////////////////////////////////////////////////////////

@objc
public enum DKImageExtensionType: Int {
    case gallery, camera, inlineCamera, photoEditor
}

public protocol DKImageExtensionProtocol {
    
    /// Starts the extension.
    func perform(with extraInfo: [AnyHashable: Any])
    
    /// Completes the extension.
    func finish()
}

/// This is the base class for all extensions.
@objc
open class DKImageBaseExtension: NSObject, DKImageExtensionProtocol {
    
    public let context: DKImageExtensionContext
    
    required public init(context: DKImageExtensionContext) {
        self.context = context
    }
    
    open func perform(with extraInfo: [AnyHashable : Any]) {
        fatalError("This method must be overridden.")
    }
    
    open func finish() {
        fatalError("This method must be overridden.")
    }
    
    internal class func extensionType() -> DKImageExtensionType {
        fatalError("This method must be overridden.")
    }
    
    @objc internal class func registerAsDefaultExtension() {
        DKImageExtensionController.registerDefaultExtension(extensionClass: self, for: self.extensionType())
    }
    
}

/// A placeholder object used to represent no any action for the certain ExtensionType.
@objc
open class DKImageExtensionNone: DKImageBaseExtension {}

/// The class handles the loading of extensions.
@objcMembers
open class DKImageExtensionController: NSObject {
    
    fileprivate static var defaultExtensions = [DKImageExtensionType : DKImageBaseExtension.Type]()
    fileprivate static var extensions = [DKImageExtensionType : DKImageBaseExtension.Type]()
    
    private var blacklist = Set<DKImageExtensionType>()
    private var cache = [DKImageExtensionType : DKImageBaseExtension]()
    
    private static let checkDefaultExtensions: Void = {
        let defaultClasses = [
            "DKImagePickerController.DKImageExtensionGallery",
            "DKImagePickerController.DKImageExtensionCamera",
            "DKImagePickerController.DKImageExtensionInlineCamera",
            "DKImagePickerController.DKImageExtensionPhotoCropper",
        ]
        
        for defaultClass in defaultClasses {
            if let defaultClass = NSClassFromString(defaultClass) {
                if let defaultClass = (defaultClass as AnyObject) as? NSObjectProtocol {
                    if defaultClass.responds(to: #selector(DKImageBaseExtension.registerAsDefaultExtension)) {
                        defaultClass.perform(#selector(DKImageBaseExtension.registerAsDefaultExtension))
                    }
                }
            }
        }
    }()
    
    private weak var imagePickerController: DKImagePickerController!
    
    init(imagePickerController: DKImagePickerController) {
        self.imagePickerController = imagePickerController
    }
    
    public func perform(extensionType: DKImageExtensionType, with extraInfo: [AnyHashable : Any]) {
        DKImageExtensionController.checkDefaultExtensions
        
        if let extensionClass = self.fetchExtensionClass(extensionType) {
            var e = self.cache[extensionType]
            if e == nil {
                e = extensionClass.init(context: self.createContext())
                self.cache[extensionType] = e
            }
            
            e?.perform(with: extraInfo)
        } else {
            // If the .camera extension is not found, then register it first using:
            // DKImageExtensionController.registerExtension(extensionClass: DKImageExtensionCamera.self, for: .camera)
            debugPrint("No DKImageExtension found: \(extensionType)")
        }
    }
    
    public func finish(extensionType: DKImageExtensionType) {
        if let e = self.cache[extensionType] {
            e.finish()
        }
    }
    
    public func enable(extensionType: DKImageExtensionType) {
        self.blacklist.remove(extensionType)
    }
    
    public func disable(extensionType: DKImageExtensionType) {
        self.blacklist.insert(extensionType)
    }

    public func isExtensionTypeAvailable(_ extensionType: DKImageExtensionType) -> Bool {
        return !self.blacklist.contains(extensionType) && self.fetchExtensionClass(extensionType) != nil
    }
    
    /// Registers an extension for the specified type.
    public class func registerExtension(extensionClass: DKImageBaseExtension.Type, for type: DKImageExtensionType) {
        DKImageExtensionController.extensions[type] = extensionClass
    }
    
    public class func unregisterExtension(for type: DKImageExtensionType) {
        DKImageExtensionController.extensions[type] = nil
    }
    
    private func createContext() -> DKImageExtensionContext {
        let context = DKImageExtensionContext()
        context.groupDetailVC = self.imagePickerController.topViewController as? DKAssetGroupDetailVC
        context.imagePickerController = self.imagePickerController
        
        return context
    }
    
    private func fetchExtensionClass(_ extensionType: DKImageExtensionType) -> DKImageBaseExtension.Type? {
        if let extensionClass = DKImageExtensionController.extensions[extensionType] ??
            DKImageExtensionController.defaultExtensions[extensionType] {
            return extensionClass is DKImageExtensionNone.Type ? nil : extensionClass
        } else {
            return nil
        }
    }
    
    internal class func registerDefaultExtension(extensionClass: DKImageBaseExtension.Type, for type: DKImageExtensionType) {
        DKImageExtensionController.defaultExtensions[type] = extensionClass
    }

}
