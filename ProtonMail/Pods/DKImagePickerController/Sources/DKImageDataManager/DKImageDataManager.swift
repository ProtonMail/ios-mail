//
//  DKImageDataManager.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/11/29.
//  Copyright © 2015年 ZhangAo. All rights reserved.
//

import Photos

public typealias DKImageRequestID = Int32
public let DKImageInvalidRequestID: DKImageRequestID = 0

public func getImageDataManager() -> DKImageDataManager {
	return DKImageDataManager.sharedInstance
}

public class DKImageDataManager {
	
	public class func checkPhotoPermission(_ handler: @escaping (_ granted: Bool) -> Void) {
		func hasPhotoPermission() -> Bool {
			return PHPhotoLibrary.authorizationStatus() == .authorized
		}
		
		func needsToRequestPhotoPermission() -> Bool {
			return PHPhotoLibrary.authorizationStatus() == .notDetermined
		}
		
		hasPhotoPermission() ? handler(true) : (needsToRequestPhotoPermission() ?
			PHPhotoLibrary.requestAuthorization({ status in
				DispatchQueue.main.async(execute: { () in
					hasPhotoPermission() ? handler(true) : handler(false)
				})
			}) : handler(false))
	}
	
	static let sharedInstance = DKImageDataManager()
	
    private let manager = PHCachingImageManager()
	
	private lazy var imageRequestOptions: PHImageRequestOptions = {
		let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
		
		return options
	}()
	
	private lazy var videoRequestOptions: PHVideoRequestOptions = {
		let options = PHVideoRequestOptions()
		options.deliveryMode = .mediumQualityFormat
        options.isNetworkAccessAllowed = true
		
		return options
	}()
    
    @discardableResult
    public func fetchImage(for asset: DKAsset,
                           size: CGSize,
                           options: PHImageRequestOptions? = nil,
                           contentMode: PHImageContentMode = .aspectFill,
                           completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) -> DKImageRequestID {
        return self.fetchImage(for: asset,
                               size: size,
                               options: options,
                               contentMode: contentMode,
                               oldRequestID: nil,
                               completeBlock: completeBlock)
    }
    
    @discardableResult
    private func fetchImage(for asset: DKAsset,
                            size: CGSize,
                            options: PHImageRequestOptions?,
                            contentMode: PHImageContentMode,
                            oldRequestID: DKImageRequestID?,
                            completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) -> DKImageRequestID {
        let requestID = oldRequestID ?? self.getSeed()
        
        guard let originalAsset = asset.originalAsset else {
            assertionFailure("Expect originalAsset")
            completeBlock(nil, nil)
            return requestID
        }
        
        let requestOptions = options ?? self.imageRequestOptions
        let imageRequestID = self.manager.requestImage(
            for: originalAsset,
            targetSize: size,
            contentMode: contentMode,
            options: requestOptions,
            resultHandler: { image, info in
                self.update(requestID: requestID, with: info)
                
                if let info = info, let isCancelled = info[PHImageCancelledKey] as? NSNumber, isCancelled.boolValue {
                    completeBlock(image, info)
                    return
                }
                
                if let isInCloud = info?[PHImageResultIsInCloudKey] as AnyObject?,
                    image == nil,
                    isInCloud.boolValue,
                    !requestOptions.isNetworkAccessAllowed {
                    if self.cancelledRequestIDs.contains(requestID) {
                        self.cancelledRequestIDs.remove(requestID)
                        completeBlock(nil, [PHImageCancelledKey : NSNumber(value: 1)])
                        return
                    }
                    
                    guard let requestCloudOptions = requestOptions.copy() as? PHImageRequestOptions else {
                        assertionFailure("Expect PHImageRequestOptions")
                        completeBlock(nil, nil)
                        return
                    }
                    
                    requestCloudOptions.isNetworkAccessAllowed = true
                    
                    self.fetchImage(for: asset,
                                    size: size,
                                    options: requestCloudOptions,
                                    contentMode: contentMode,
                                    oldRequestID: requestID,
                                    completeBlock: completeBlock)
                } else {
                    completeBlock(image, info)
                }
        })
        
        self.update(requestID: requestID, with: imageRequestID, old: oldRequestID)
        return requestID
    }
    
    @discardableResult
    public func fetchImageData(for asset: DKAsset, options: PHImageRequestOptions? = nil, completeBlock: @escaping (_ data: Data?, _ info: [AnyHashable: Any]?) -> Void) -> DKImageRequestID {
        return self.fetchImageData(for: asset, options: options, oldRequestID: nil, completeBlock: completeBlock)
    }
    
    @discardableResult
    private func fetchImageData(for asset: DKAsset,
                                options: PHImageRequestOptions?,
                                oldRequestID: DKImageRequestID?,
                                completeBlock: @escaping (_ data: Data?, _ info: [AnyHashable: Any]?) -> Void)
        -> DKImageRequestID
    {
        let requestID = oldRequestID ?? self.getSeed()

        guard let originalAsset = asset.originalAsset else {
            assertionFailure("Expect originalAsset")
            completeBlock(nil, nil)
            return requestID
        }

        let requestOptions = options ?? self.imageRequestOptions
        let imageRequestID = self.manager.requestImageData(
            for: originalAsset,
            options: requestOptions) { (data, dataUTI, orientation, info) in
                self.update(requestID: requestID, with: info)

                if let info = info, let isCancelled = info[PHImageCancelledKey] as? NSNumber, isCancelled.boolValue {
                    completeBlock(data, info)
                    return
                }

                if let isInCloud = info?[PHImageResultIsInCloudKey] as AnyObject?,
                    data == nil,
                    isInCloud.boolValue,
                    !requestOptions.isNetworkAccessAllowed
                {
                    if self.cancelledRequestIDs.contains(requestID) {
                        self.cancelledRequestIDs.remove(requestID)
                        completeBlock(nil, [PHImageCancelledKey : NSNumber(value: 1)])
                        return
                    }

                    guard let requestCloudOptions = requestOptions.copy() as? PHImageRequestOptions else {
                        assertionFailure("Expect PHImageRequestOptions")
                        completeBlock(nil, nil)
                        return
                    }

                    requestCloudOptions.isNetworkAccessAllowed = true

                    self.fetchImageData(for: asset, options: requestCloudOptions, oldRequestID: requestID, completeBlock: completeBlock)
                } else {
                    completeBlock(data, info)
                }
        }
        
        self.update(requestID: requestID, with: imageRequestID, old: oldRequestID)
        return requestID
    }
	
    @discardableResult
    public func fetchAVAsset(for asset: DKAsset, options: PHVideoRequestOptions? = nil, completeBlock: @escaping (_ avAsset: AVAsset?, _ info: [AnyHashable: Any]?) -> Void) -> DKImageRequestID {
        return self.fetchAVAsset(for: asset, options: options, oldRequestID: nil, completeBlock: completeBlock)
    }
    
    @discardableResult
    private func fetchAVAsset(for asset: DKAsset,
                              options: PHVideoRequestOptions?,
                              oldRequestID: DKImageRequestID?,
                              completeBlock: @escaping (_ avAsset: AVAsset?, _ info: [AnyHashable: Any]?) -> Void)
        -> DKImageRequestID
    {
        let requestID = oldRequestID ?? self.getSeed()

        guard let originalAsset = asset.originalAsset else {
            assertionFailure("Expect originalAsset")
            completeBlock(nil, nil)
            return requestID
        }

        let requestOptions = options ?? self.videoRequestOptions
        let imageRequestID = self.manager.requestAVAsset(
            forVideo: originalAsset,
            options: requestOptions) { avAsset, audioMix, info in
                self.update(requestID: requestID, with: info)

                if let info = info, let isCancelled = info[PHImageCancelledKey] as? NSNumber, isCancelled.boolValue {
                    completeBlock(avAsset, info)
                    return
                }

                if let isInCloud = info?[PHImageResultIsInCloudKey] as AnyObject?,
                    avAsset == nil,
                    isInCloud.boolValue,
                    !requestOptions.isNetworkAccessAllowed
                {
                    if self.cancelledRequestIDs.contains(requestID) {
                        self.cancelledRequestIDs.remove(requestID)
                        completeBlock(nil, [PHImageCancelledKey : NSNumber(value: 1)])
                        return
                    }

                    guard let requestCloudOptions = requestOptions.copy() as? PHVideoRequestOptions else {
                        assertionFailure("Expect PHImageRequestOptions")
                        completeBlock(nil, nil)
                        return
                    }

                    requestCloudOptions.isNetworkAccessAllowed = true

                    self.fetchAVAsset(for: asset, options: requestCloudOptions, oldRequestID: requestID, completeBlock: completeBlock)
                } else {
                    completeBlock(avAsset, info)
                }
        }
        
        self.update(requestID: requestID, with: imageRequestID, old: oldRequestID)
        return requestID
    }
    
    public func cancelRequest(requestID: DKImageRequestID) {
        self.cancelRequests(requestIDs: [requestID])
    }
    
    public func cancelRequests(requestIDs: [DKImageRequestID]) {
        self.executeOnMainThread {
            while self.cancelledRequestIDs.count > 100 {
                let _ = self.cancelledRequestIDs.popFirst()
            }
            
            for requestID in requestIDs {
                if let imageRequestID = self.requestIDs[requestID] {
                    self.manager.cancelImageRequest(imageRequestID)
                    self.cancelledRequestIDs.insert(requestID)
                }
                
                self.requestIDs[requestID] = nil
            }
        }
    }
    
    public func startCachingAssets(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) {
        self.manager.startCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: options)
    }
    
    public func stopCachingAssets(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) {
        self.manager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: options)
    }
    
    public func stopCachingForAllAssets() {
        self.manager.stopCachingImagesForAllAssets()
    }
    
    // MARK: - RequestID
    
    private var requestIDs = [DKImageRequestID : PHImageRequestID]()
    private var finishedRequestIDs = Set<DKImageRequestID>()
    private var cancelledRequestIDs = Set<DKImageRequestID>()
    
    private var seed: DKImageRequestID = 0
    private func getSeed() -> DKImageRequestID {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        seed += 1
        return seed
    }
    
    private func update(requestID: DKImageRequestID,
                        with imageRequestID: PHImageRequestID?,
                        old oldImageRequestID: DKImageRequestID?) {
        self.executeOnMainThread {
            if let imageRequestID = imageRequestID {
                if self.cancelledRequestIDs.contains(requestID) {
                    self.cancelledRequestIDs.remove(requestID)
                    self.manager.cancelImageRequest(imageRequestID)
                } else {
                    if self.finishedRequestIDs.contains(requestID) {
                        self.finishedRequestIDs.remove(requestID)
                    } else {
                        self.requestIDs[requestID] = imageRequestID
                    }
                }
            } else {
                self.requestIDs[requestID] = nil
            }
        }
    }
    
    private func update(requestID: DKImageRequestID, with info: [AnyHashable : Any]?) {
        guard let info = info else { return }
        
        if let isCancelled = info[PHImageCancelledKey] as? NSNumber, isCancelled.boolValue {
            self.executeOnMainThread {
                self.requestIDs[requestID] = nil
                self.cancelledRequestIDs.remove(requestID)
            }
        } else if let isDegraded = (info[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue {
            if !isDegraded { // No more callbacks for the requested image.
                self.executeOnMainThread {
                    if self.requestIDs[requestID] == nil {
                        self.finishedRequestIDs.insert(requestID)
                    } else {
                        self.requestIDs[requestID] = nil
                    }
                }
            }
        }
    }
    
    private func executeOnMainThread(block: @escaping (() -> Void)) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
