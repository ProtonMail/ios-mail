//
//  DKAsset+Fetch.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 30/11/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import Foundation
import UIKit
import Photos

public extension DKAsset {
    
    /**
     Fetch an image with the specific size.
     */
    @objc func fetchImage(with size: CGSize,
                          options: PHImageRequestOptions? = nil,
                          contentMode: PHImageContentMode = .aspectFit,
                          completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        if self.originalAsset != nil {
            self.add(requestID: getImageDataManager().fetchImage(for: self,
                                                                 size: size,
                                                                 options: options,
                                                                 contentMode: contentMode,
                                                                 completeBlock: completeBlock))
        } else {
            completeBlock(self.image, nil)
        }
    }
    
    /**
     Fetch an image with the current screen size.
     */
    @objc func fetchFullScreenImage(completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        if let (image, info) = self.fullScreenImage {
            completeBlock(image, info)
        } else if self.originalAsset == nil {
            completeBlock(self.image, nil)
        } else {
            let screenSize = UIScreen.main.bounds.size
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            
            self.add(requestID: getImageDataManager().fetchImage(for: self,
                                                                 size: screenSize.toPixel(),
                                                                 options: options,
                                                                 contentMode: .aspectFit) { [weak self] image, info in
                                                                    guard let strongSelf = self else { return }
                                                                    
                                                                    strongSelf.fullScreenImage = (image, info)
                                                                    completeBlock(image, info)
            })
        }
    }
    
    /**
     Fetch an image with the original size.
     */
    @objc func fetchOriginalImage(options: PHImageRequestOptions? = nil,
                                  completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        if self.originalAsset != nil {
            self.add(requestID: getImageDataManager().fetchImageData(for: self,
                                                                     options: options,
                                                                     completeBlock: { (data, info) in
                                                                        var image: UIImage?
                                                                        if let data = data {
                                                                            image = UIImage(data: data)
                                                                        }
                                                                        completeBlock(image, info)
            }))
        } else {
            completeBlock(self.image, nil)
        }
    }
    
    /**
     Fetch an image data with the original size.
     */
    @objc func fetchImageData(options: PHImageRequestOptions? = nil,
                              compressionQuality: CGFloat = 0.9,
                              completeBlock: @escaping (_ imageData: Data?, _ info: [AnyHashable: Any]?) -> Void) {
        if self.originalAsset != nil {
            self.add(requestID: getImageDataManager().fetchImageData(for: self,
                                                                     options: options,
                                                                     completeBlock: completeBlock))
        } else {
            if let image = self.image {
                if self.hasAlphaChannel(image: image) {
                    completeBlock(image.pngData(), nil)
                } else {
                    completeBlock(image.jpegData(compressionQuality: compressionQuality), nil)
                }
            } else {
                assert(false)
            }
        }
    }
    
    /**
     Fetch an AVAsset with a completeBlock and PHVideoRequestOptions.
     */
    @objc func fetchAVAsset(options: PHVideoRequestOptions? = nil,
                            completeBlock: @escaping (_ AVAsset: AVAsset?, _ info: [AnyHashable: Any]?) -> Void) {
        self.add(requestID: getImageDataManager().fetchAVAsset(for: self,
                                                               options: options,
                                                               completeBlock: completeBlock))
    }

    @objc func cancelRequests() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if let requestIDs = self.requestIDs {
            getImageDataManager().cancelRequests(requestIDs: requestIDs as! [DKImageRequestID])
            
            self.requestIDs?.removeAllObjects()
        }
    }
    
    // MARK: - Private
    
    private func hasAlphaChannel(image: UIImage) -> Bool {
        if let cgImage = image.cgImage {
            let alphaInfo = cgImage.alphaInfo
            return alphaInfo == .first
                || alphaInfo == .last
                || alphaInfo == .premultipliedFirst
                || alphaInfo == .premultipliedLast
        } else {
            return false
        }
    }
    
    private func add(requestID: DKImageRequestID) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        var requestIDs: NSMutableArray! = self.requestIDs
        if requestIDs == nil {
            requestIDs = NSMutableArray()
            self.requestIDs = requestIDs
        }
        
        requestIDs.add(requestID)
    }
    
    // MARK: - Attributes
    
    private struct FetchKeys {
        static fileprivate var requestIDs: UInt8 = 0
        static fileprivate var fullScreenImage: UInt8 = 0
    }
    
    private var requestIDs: NSMutableArray? {
        
        get { return getAssociatedObject(key: &FetchKeys.requestIDs) as? NSMutableArray }
        set { setAssociatedObject(key: &FetchKeys.requestIDs, value: newValue) }
    }

    private(set) var fullScreenImage: (image: UIImage?, info: [AnyHashable: Any]?)? {
        
        get { return getAssociatedObject(key: &FetchKeys.fullScreenImage) as? (image: UIImage?, info: [AnyHashable: Any]?) }
        set { setAssociatedObject(key: &FetchKeys.fullScreenImage, value: newValue) }
    }
    
}
