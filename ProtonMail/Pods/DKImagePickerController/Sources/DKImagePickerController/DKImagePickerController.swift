//
//  DKImagePickerController.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 14-10-2.
//  Copyright (c) 2014年 ZhangAo. All rights reserved.
//

import UIKit
import Photos

/**
 - AllPhotos: Get all photos assets in the assets group.
 - AllVideos: Get all video assets in the assets group.
 - AllAssets: Get all assets in the group.
 */
@objc
public enum DKImagePickerControllerAssetType : Int {
    case allPhotos, allVideos, allAssets
}

@objc
public enum DKImagePickerControllerSourceType : Int {
    case camera, photo, both
}

@objc
public enum DKImagePickerControllerExportStatus: Int {
    case none, exporting
}

////////////////////////////////////////////////////////////////////////

@objc
public protocol DKImagePickerControllerAware {
    weak var imagePickerController: DKImagePickerController! { get set }
    
    func reload()
}

////////////////////////////////////////////////////////////////////////

@objc
internal protocol DKImagePickerControllerObserver {
    
    @objc optional func imagePickerControllerDidSelect(assets: [DKAsset])
    
    @objc optional func imagePickerControllerDidDeselect(assets: [DKAsset])
    
}

////////////////////////////////////////////////////////////////////////

@objc
open class DKUINavigationController: UINavigationController {}

@objc
open class DKImagePickerController: DKUINavigationController, DKImageBaseManagerObserver, UIAdaptivePresentationControllerDelegate {
    
    /// Use UIDelegate to Customize the picker UI.
    @objc public var UIDelegate: DKImagePickerControllerBaseUIDelegate! {
        willSet {
            newValue?.imagePickerController = self
        }
    }
    
    /// false to prevent dismissal of the picker when the presentation controller will dismiss in response to user action.
    @available(iOS 13.0, *)
    @objc public var shouldDismissViaUserAction: Bool {
        return false
    }

    /// Forces deselect of previous selected image. allowSwipeToSelect will be ignored.
    @objc public var singleSelect = false
    
    /// Auto close picker on single select
    @objc public var autoCloseOnSingleSelect = true
    
    /// The maximum count of assets which the user will be able to select, a value of 0 means no limit.
    @objc public var maxSelectableCount = 0
    
    /// Photos will be tagged with the location where they are taken.
    /// If true, your Info.plist should include the "Privacy - Location XXX" tag.
    open var containsGPSInMetadata = false
    
    /// Set the defaultAssetGroup to specify which album is the default asset group.
    public var defaultAssetGroup: PHAssetCollectionSubtype?
    
    /// Allow swipe to select images.
    @objc public var allowSwipeToSelect: Bool = false
    
    /// Allow select all
    @objc public var allowSelectAll: Bool = false
    
    /// A Bool value indicating whether the inline mode is enabled.
    @objc public var inline: Bool = false
    
    /// The type of picker interface to be displayed by the controller.
    @objc public var assetType: DKImagePickerControllerAssetType = .allAssets
    
    /// If sourceType is Camera will cause the assetType & maxSelectableCount & allowMultipleTypes to be ignored.
    @objc public var sourceType: DKImagePickerControllerSourceType = .both
    
    /// A Bool value indicating whether to allow the picker to select photos and videos at the same time.
    @objc public var allowMultipleTypes = true
    
    /// A Bool value indicating whether to allow the picker auto-rotate the screen.
    @objc public var allowsLandscape = false
    
    /// Set the showsEmptyAlbums to specify whether or not the empty albums is shown in the picker.
    @objc public var showsEmptyAlbums = true
    
    /// A Bool value indicating whether to allow the picker shows the cancel button.
    @objc public var showsCancelButton = false
    
    /// Limits the maximum number of objects displayed on the UI, a value of 0 means no limit.  Defaults to 0.
    @objc public var fetchLimit = 0
    
    /// The block is executed when the user presses the cancel button.
    @objc public var didCancel: (() -> Void)?
    
    /// The block is executed when the user presses the select button.
    @objc public var didSelectAssets: ((_ assets: [DKAsset]) -> Void)?
    
    /// The block is executed when the number of the selected assets is changed.
    @objc public var selectedChanged: (() -> Void)?

    /// Colors applied to the permission view when access needs to be granted by the user
    @objc public var permissionViewColors = DKPermissionViewColors()
    
    /// A Bool value indicating whether to allow the picker to auto-export the selected assets to the specified directory when done is called.
    /// picker will creating a default exporter if exportsWhenCompleted is true and the exporter is nil.
    @objc public var exportsWhenCompleted = false
    
    @objc public var exporter: DKImageAssetExporter?
    
    /// Indicates the status of the exporter.
    @objc public private(set) var exportStatus = DKImagePickerControllerExportStatus.none {
        willSet {
            if self.exportStatus != newValue {
                self.willChangeValue(forKey: #keyPath(DKImagePickerController.exportStatus))
            }
        }
        
        didSet {
            if self.exportStatus != oldValue {
                self.didChangeValue(forKey: #keyPath(DKImagePickerController.exportStatus))
                
                self.exportStatusChanged?(self.exportStatus)
            }
        }
    }
    
    /// The block is executed when the exportStatus is changed.
    @objc public var exportStatusChanged: ((DKImagePickerControllerExportStatus) -> Void)?
    
    /// The object that acts as the data source of the picker.
    @objc public private(set) lazy var groupDataManager: DKImageGroupDataManager = {
        let configuration = DKImageGroupDataManagerConfiguration()
        configuration.assetFetchOptions = self.createDefaultAssetFetchOptions()
        configuration.fetchLimit = self.fetchLimit
        
        return DKImageGroupDataManager(configuration: configuration)
    }()
    
    private var isInlineCamera: Bool { return self.sourceType == .camera }
    
    public private(set) var selectedAssetIdentifiers = [String]() // DKAsset.localIdentifier
    private var assets = [String : DKAsset]() // DKAsset.localIdentifier : DKAsset
    
    public lazy var extensionController: DKImageExtensionController! = {
        return DKImageExtensionController(imagePickerController: self)
    }()
    
    internal var proxyObserver = DKImageBaseManager()
    
    private weak var rootVC: (UIViewController & DKImagePickerControllerAware)?
    
    public convenience init(groupDataManager: DKImageGroupDataManager? = nil) {
        self.init(nibName: nil, bundle: nil)
        
        if let groupDataManager = groupDataManager {
            self.groupDataManager = groupDataManager            
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        self.groupDataManager.invalidate()
    }
    
    private lazy var doSetupOnce: () -> Void = {
        if self.UIDelegate == nil {
            self.UIDelegate = DKImagePickerControllerBaseUIDelegate()
        }
        
        if self.exportsWhenCompleted && self.exporter == nil {
            self.exporter = DKImageAssetExporter.sharedInstance
        }
        
        if self.inline || self.isInlineCamera {
            self.isNavigationBarHidden = true
        } else {
            self.isNavigationBarHidden = false
        }
        
        if !self.isInlineCamera {
            let rootVC = self.makeRootVC()
            rootVC.imagePickerController = self
            self.rootVC = rootVC
            
            self.UIDelegate.prepareLayout(self, vc: rootVC)
            self.updateCancelButtonForVC(rootVC)
            self.setViewControllers([rootVC], animated: false)
        }
        
        if self.selectedAssetIdentifiers.count > 0 {
            self.UIDelegate.imagePickerController(self, didSelectAssets: self.selectedAssets)
        }
        
        if self.preferredContentSize.equalTo(CGSize.zero) {
            self.preferredContentSize = CGSize(width: 680, height: 600)
        }
        
        self.rootVC?.navigationItem.hidesBackButton = true
        
        return {}
    }()
    
    private var needShowInlineCamera = true
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.doSetupOnce()
        
        if #available(iOS 13, *), self.presentingViewController != nil, self.presentationController?.delegate == nil {
            self.presentationController?.delegate = self
        }
        
        if self.needShowInlineCamera && self.isInlineCamera {
            self.needShowInlineCamera = false
            self.showCamera()
        }
    }
    
    @objc open func makeRootVC() -> UIViewController & DKImagePickerControllerAware {
      return DKAssetGroupDetailVC()
    }
    
    @objc open func presentCamera() {
        self.showCamera()
    }
    
    @objc open override func present(_ viewControllerToPresent: UIViewController,
                                     animated flag: Bool = true,
                                     completion: (() -> Swift.Void)? = nil) {
        var targetVC: UIViewController = self
        if self.inline {
            targetVC = UIApplication.shared.keyWindow!.rootViewController!
        }
        
        while let presentedViewController = targetVC.presentedViewController {
            targetVC = presentedViewController
        }
        
        if targetVC == self {
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        } else {
            targetVC.present(viewControllerToPresent, animated: flag, completion: completion)
        }
    }
    
    @objc open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if self.inline {
            UIApplication.shared.keyWindow!.rootViewController!.dismiss(animated: true,
                                                                        completion: completion)
        } else {
            super.dismiss(animated: true, completion: completion)
        }
    }
    
    @objc open func dismissCamera() {
        self.extensionController.finish(extensionType: self.isInlineCamera ? .inlineCamera : .camera)
    }
    
    @objc open func dismiss() {
        self.cancelCurrentExportRequestIfNeeded()
        
        self.presentingViewController?.dismiss(animated: true, completion: {
            self.didCancel?()
            
            if self.isInlineCamera {
                self.needShowInlineCamera = true
            }
        })
    }
    
    private var exportRequestID = DKImageAssetExportInvalidRequestID
    @objc open func done() {
        self.cancelCurrentExportRequestIfNeeded()
        
        let completeBlock: ([DKAsset]) -> Void = { assets in
            self.exportStatus = .none
            
            self.didSelectAssets?(assets)
            
            if self.isInlineCamera {
                self.needShowInlineCamera = true
            }
        }
        
        let exportBlock = {
            let assets = self.selectedAssets
            if let exporter = self.exporter {
                self.exportRequestID = exporter.exportAssetsAsynchronously(assets: assets) { [weak self] info in
                    if let strongSelf = self {
                        let requestID = info[DKImageAssetExportResultRequestIDKey] as! DKImageAssetExportRequestID
                        if strongSelf.exportRequestID == requestID {
                            strongSelf.exportRequestID = DKImageAssetExportInvalidRequestID
                            completeBlock(assets)
                        }
                    }
                }
                
                self.exportStatus = .exporting
            } else {
                completeBlock(assets)
            }
        }
        
        if self.inline {
            exportBlock()
        } else {
            self.presentingViewController?.dismiss(animated: true, completion: {
                exportBlock()
            })
        }
    }
    
    /// Reload this picker with a new DKImageGroupDataManager.
    @objc open func reload(with dataManager: DKImageGroupDataManager) {
        self.groupDataManager = dataManager
        if let rootVC = self.rootVC {
            rootVC.reload()
        }
    }
    
    private func cancelCurrentExportRequestIfNeeded() {
        if self.exportRequestID != DKImageAssetExportInvalidRequestID {
            self.exporter?.cancel(requestID: self.exportRequestID)
            self.exportStatus = .none
        }
    }
    
    private func updateCancelButtonForVC(_ vc: UIViewController) {
        if self.showsCancelButton {
            self.UIDelegate.imagePickerController(self, showsCancelButtonForVC: vc)
        } else {
            self.UIDelegate.imagePickerController(self, hidesCancelButtonForVC: vc)
        }
    }
    
    private func createDefaultAssetFetchOptions() -> PHFetchOptions {
        let createImagePredicate = { () -> NSPredicate in
            let imagePredicate = NSPredicate(format: "mediaType == %d",
                                             PHAssetMediaType.image.rawValue)
            
            return imagePredicate
        }
        
        let createVideoPredicate = { () -> NSPredicate in
            let videoPredicate = NSPredicate(format: "mediaType == %d",
                                             PHAssetMediaType.video.rawValue)
            
            return videoPredicate
        }
        
        var predicate: NSPredicate?
        switch self.assetType {
        case .allAssets:
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates:
                [createImagePredicate(), createVideoPredicate()]
            )
        case .allPhotos:
            predicate = createImagePredicate()
        case .allVideos:
            predicate = createVideoPredicate()
        }
        
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = predicate
        
        return assetFetchOptions
    }
    
    private func didCancelCamera() {
        self.dismissCamera()
        if self.isInlineCamera {
            self.dismiss()
        }
    }
    
    private func showCamera() {
        let didCancel = { [unowned self] () in
            self.didCancelCamera()
        }
        
        let didFinishCapturingImage = { [weak self] (image: UIImage, metadata: [AnyHashable : Any]?) in
            if let strongSelf = self {
                let didFinishEditing: ((UIImage, [AnyHashable : Any]?) -> Void) = { (image, metadata) in
                    self?.processImageFromCamera(image, metadata)
                }
                
                if strongSelf.extensionController.isExtensionTypeAvailable(.photoEditor) {
                    var extraInfo: [AnyHashable : Any] = [
                        "image" : image,
                        "didFinishEditing" : didFinishEditing
                        ]
                    
                    if let metadata = metadata {
                        extraInfo["metadata"] = metadata
                    }
                    
                    strongSelf.extensionController.perform(extensionType: .photoEditor, with: extraInfo)
                } else {
                    didFinishEditing(image, metadata)
                }
            }
        }
        
        let didFinishCapturingVideo = { [unowned self] (videoURL: URL) in
            var newVideoIdentifier: String!
            PHPhotoLibrary.shared().performChanges({
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                newVideoIdentifier = assetRequest?.placeholderForCreatedAsset?.localIdentifier
            }) { (success, error) in
                DispatchQueue.main.async(execute: {
                    if success {
                        if let newAsset = PHAsset.fetchAssets(withLocalIdentifiers: [newVideoIdentifier],
                                                              options: nil).firstObject {
                            if !self.isInlineCamera || self.viewControllers.count == 0 {
                                self.dismissCamera()
                            }
                            self.select(asset: DKAsset(originalAsset: newAsset))
                        }
                    } else {
                        self.dismissCamera()
                    }
                })
            }
        }
        
        self.extensionController.perform(extensionType: isInlineCamera ? .inlineCamera : .camera, with: [
            "didFinishCapturingImage" : didFinishCapturingImage,
            "didFinishCapturingVideo" : didFinishCapturingVideo,
            "didCancel" : didCancel,
            "containsGPSInMetadata" : self.containsGPSInMetadata
            ])
    }
    
    private func triggerSelectedChangedIfNeeded() {
        if let selectedChanged = self.selectedChanged {
            selectedChanged()
        }
    }
    
    // MARK: - Capturing Image
    
    internal func processImageFromCamera(_ image: UIImage, _ metadata: [AnyHashable : Any]?) {
        self.saveImage(image, metadata) { asset in
            if !self.isInlineCamera {
                self.dismissCamera()
            }
            self.select(asset: asset)
        }
    }
    
    // MARK: - Save Image
    
    @objc open func saveImage(_ image: UIImage,
                              _ metadata: [AnyHashable : Any]?,
                              _ completeBlock: @escaping ((_ asset: DKAsset) -> Void)) {
        if let metadata = metadata {
            let imageData = image.jpegData(compressionQuality: 1)!
            
            if let imageDataWithMetadata = self.writeMetadata(metadata, into: imageData) {
                self.saveImageDataToAlbumForiOS9(imageDataWithMetadata, completeBlock)
            } else {
                self.saveImageDataToAlbumForiOS9(imageData, completeBlock)
            }
        } else {
            self.saveImageToAlbum(image, completeBlock)
        }
    }
    
    @objc open func saveImageToAlbum(_ image: UIImage, _ completeBlock: @escaping ((_ asset: DKAsset) -> Void)) {
        var newImageIdentifier: String!
        
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            newImageIdentifier = assetRequest.placeholderForCreatedAsset!.localIdentifier
        }) { (success, error) in
            DispatchQueue.main.async(execute: {
                if success, let newAsset = PHAsset.fetchAssets(withLocalIdentifiers: [newImageIdentifier], options: nil).firstObject {
                    completeBlock(DKAsset(originalAsset: newAsset))
                } else {
                    completeBlock(DKAsset(image: image))
                }
            })
        }
    }
    
    @objc open func saveImageDataToAlbumForiOS9(_ imageDataWithMetadata: Data, _ completeBlock: @escaping ((_ asset: DKAsset) -> Void)) {
        var newImageIdentifier: String = ""
        
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetCreationRequest.forAsset()
            assetRequest.addResource(with: .photo, data: imageDataWithMetadata, options: nil)
            newImageIdentifier = assetRequest.placeholderForCreatedAsset?.localIdentifier ?? ""
        }) { (success, error) in
            DispatchQueue.main.async(execute: {
                if newImageIdentifier.isEmpty, let img =  UIImage(data: imageDataWithMetadata) {
                    completeBlock(DKAsset(image: img))
                    return
                }
                if newImageIdentifier.isEmpty {
                    completeBlock(DKAsset(image: UIImage()))
                    return
                }

                if success, let newAsset = PHAsset.fetchAssets(withLocalIdentifiers: [newImageIdentifier], options: nil).firstObject {
                    completeBlock(DKAsset(originalAsset: newAsset))
                } else {
                    if let img =  UIImage(data: imageDataWithMetadata) {
                        completeBlock(DKAsset(image: img))
                    } else {
                        completeBlock(DKAsset(image: UIImage()))
                    }
                }
            })
        }
    }
    
    @objc open func writeMetadata(_ metadata: Dictionary<AnyHashable, Any>, into imageData: Data) -> Data? {
        let source = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let UTI = CGImageSourceGetType(source)!
        
        let newImageData = NSMutableData()
        if let destination = CGImageDestinationCreateWithData(newImageData, UTI, 1, nil) {
            CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
            if CGImageDestinationFinalize(destination) {
                return newImageData as Data
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: - Selection
        
    @objc open func select(asset: DKAsset) {
        self.select(assets: [asset])
    }
    
    @objc open func select(assets: [DKAsset]) {
        if self.singleSelect {
            self.deselectAll()
        }
        
        var insertedAssets = [DKAsset]()
        
        for asset in assets {
            if self.assets[asset.localIdentifier] != nil { continue }
            if !self.canSelect(asset: asset) { break }
            
            self.selectedAssetIdentifiers.append(asset.localIdentifier)
            self.assets[asset.localIdentifier] = asset
            
            insertedAssets.append(asset)
        }
        
        if insertedAssets.count > 0 {
            self.clearSelectedAssetsCache()
            
            if self.isInlineCamera || (self.singleSelect && self.autoCloseOnSingleSelect) {
                self.done()
            } else {
                self.triggerSelectedChangedIfNeeded()
                self.UIDelegate?.imagePickerController(self, didSelectAssets: insertedAssets)
            }
            
            self.notify(with: #selector(DKImagePickerControllerObserver.imagePickerControllerDidSelect(assets:)), object: insertedAssets as AnyObject)
        }
    }
    
    @objc open func handleSelectAll() {
        if let groupDetailVC = self.viewControllers.first as? DKAssetGroupDetailVC, let selectedGroupId = groupDetailVC.selectedGroupId {
            guard let group = self.groupDataManager.fetchGroup(with: selectedGroupId) else {
                assertionFailure("Expect group")
                return
            }
            
            var assets: [DKAsset] = []
            for index in 0 ..< group.totalCount {
                guard let asset = self.groupDataManager.fetchAsset(group, index: index) else {
                    assertionFailure("Expect asset")
                    continue
                }
                assets.append(asset)
            }
            
            if assets.count > 0 {
                self.select(assets: assets)
            }
        }
        self.UIDelegate.updateDoneButtonTitle(self.UIDelegate.doneButton!)
    }
    
    @objc open func deselect(asset: DKAsset) {
        removeSelection(asset: asset)
        
        self.notify(with: #selector(DKImagePickerControllerObserver.imagePickerControllerDidDeselect(assets:)), object: [asset] as AnyObject)
    }
    
    @objc open func removeSelection(asset: DKAsset) {
        if self.assets[asset.localIdentifier] == nil { return }
        
        self.selectedAssetIdentifiers.remove(at: self.selectedAssetIdentifiers.firstIndex(of: asset.localIdentifier)!)
        self.assets[asset.localIdentifier] = nil
        self.clearSelectedAssetsCache()
        
        self.triggerSelectedChangedIfNeeded()
        
        let deselectAssets = [asset]
        self.UIDelegate?.imagePickerController(self, didDeselectAssets: deselectAssets)
    }
    
    @objc open func deselectAll() {
        if self.selectedAssetIdentifiers.count > 0 {
            let assets = self.selectedAssets
            self.selectedAssetIdentifiers.removeAll()
            self.assets.removeAll()
            self.clearSelectedAssetsCache()
            
            self.triggerSelectedChangedIfNeeded()
            self.UIDelegate?.imagePickerController(self, didDeselectAssets: assets)
            
            self.notify(with: #selector(DKImagePickerControllerObserver.imagePickerControllerDidDeselect(assets:)), object: assets as AnyObject)
        }
    }
    
    @objc open func setSelectedAssets(assets: [DKAsset]) {
        if assets.count > 0 {
            self.deselectAll()
            self.select(assets: assets)
        } else {
            self.deselectAll()
        }
    }
    
    open func index(of asset: DKAsset) -> Int? {
        if self.contains(asset: asset) {
            return self.selectedAssetIdentifiers.firstIndex(of: asset.localIdentifier)
        } else {
            return nil
        }
    }
    
    @objc open func contains(asset: DKAsset) -> Bool {
        return self.assets[asset.localIdentifier] != nil
    }
  
    @objc open func scroll(to indexPath: IndexPath, animated: Bool = false) {
        if let groupDetailVC = self.viewControllers.first as? DKAssetGroupDetailVC {
            groupDetailVC.scroll(to: indexPath, animted: animated)
        }
    }
    
    @objc open func scrollToLastTappedIndexPath(animated: Bool = false) {
        if let groupDetailVC = self.viewControllers.first as? DKAssetGroupDetailVC {
            groupDetailVC.scrollToLastIndexPath(animated: animated)
        }
    }
    
    private var internalSelectedAssetsCache: [DKAsset]?
    @objc public var selectedAssets: [DKAsset] {
        get {
            if self.internalSelectedAssetsCache != nil {
                return self.internalSelectedAssetsCache!
            }
            
            var assets = [DKAsset]()
            for assetIdentifier in self.selectedAssetIdentifiers {
                assets.append(self.assets[assetIdentifier]!)
            }
            
            self.internalSelectedAssetsCache = assets

            return assets
        }
    }
    
    @objc open func canSelect(asset: DKAsset, showAlert: Bool = true) -> Bool {
        if let firstSelectedAsset = self.selectedAssets.first,
            self.allowMultipleTypes == false && firstSelectedAsset.type != asset.type {
            
            if showAlert {
                let alert = UIAlertController(title: DKImagePickerControllerResource.localizedStringWithKey("picker.select.photosOrVideos.error.title"),
                                              message: DKImagePickerControllerResource.localizedStringWithKey("picker.select.photosOrVideos.error.message"),
                                              preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: DKImagePickerControllerResource.localizedStringWithKey("picker.alert.ok"),
                                              style: .cancel))
                
                self.present(alert, animated: true){}
            }
            
            return false
        }
        
        if self.maxSelectableCount > 0 {
            let shouldSelect = self.selectedAssetIdentifiers.count < self.maxSelectableCount
            if !shouldSelect && showAlert && !self.UIDelegate.isMaxLimitAlertDisplayed {
                self.UIDelegate.imagePickerControllerDidReachMaxLimit(self)
            }
            
            return shouldSelect
        } else {
            return true
        }
    }
    
    private func clearSelectedAssetsCache() {
        self.internalSelectedAssetsCache = nil
    }
    
    // MARK: - DKImageBaseManagerObserver
    
    internal func add(observer object: AnyObject) {
        self.proxyObserver.add(observer: object)
    }
    
    internal func remove(observer object: AnyObject) {
        self.proxyObserver.remove(observer: object)
    }
    
    internal func notify(with selector: Selector, object: AnyObject?) {
        self.proxyObserver.notify(with: selector, object: object)
    }
    
    internal func notify(with selector: Selector, object: AnyObject?, objectTwo: AnyObject?) {
        self.proxyObserver.notify(with: selector, object: object, objectTwo: objectTwo)
    }
    
    // MARK: - Orientation
    
    @objc open override var shouldAutorotate : Bool {
        return self.allowsLandscape && !self.isInlineCamera ? true : false
    }
    
    @objc open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if self.allowsLandscape {
            return super.supportedInterfaceOrientations
        } else {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    @available(iOS 13.0, *)
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return self.shouldDismissViaUserAction
    }
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if self.isInlineCamera {
            self.didCancelCamera()
        } else {
            self.dismiss()
        }
    }
    
    // MARK: - Gallery
    
    open func showGallery(with presentationIndex: Int?,
                            presentingFromImageView: UIImageView?,
                            groupId: String) {
        var extraInfo: [AnyHashable : Any] = [
            "groupId" : groupId
        ]
        
        if let presentationIndex = presentationIndex {
            extraInfo["presentationIndex"] = presentationIndex
        }
        
        if let presentingFromImageView = presentingFromImageView {
            extraInfo["presentingFromImageView"] = presentingFromImageView
        }
        
        self.extensionController.perform(extensionType: .gallery, with: extraInfo)
    }
    
}
