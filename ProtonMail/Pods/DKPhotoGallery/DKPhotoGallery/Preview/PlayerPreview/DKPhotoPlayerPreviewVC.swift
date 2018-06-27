//
//  DKPhotoPlayerPreviewVC.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 15/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit
import AVKit
import Photos

open class DKPhotoPlayerPreviewVC: DKPhotoBasePreviewVC {

    public var closeBlock: (() -> Void)?
    
    public var autoHidesControlView = true
    
    public var tapToToggleControlView = true
    
    public var beginPlayBlock: (() -> Void)?
    
    public var isControlHidden: Bool = true {
        willSet {
            guard let playerView  = self.playerView else { return }
            
            playerView.isControlHidden = newValue
        }
    }

    private var playerView: DKPlayerView?
    
    deinit {
        self.playerView?.stop()
    }
    
    open override func photoPreviewWillAppear() {
        super.photoPreviewWillAppear()
        
        self.playerView?.isControlHidden = true
    }
    
    open override func photoPreviewWillDisappear() {
        super.photoPreviewWillDisappear()
        
        self.playerView?.pause()
        self.playerView?.playButton.isHidden = false
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        self.playerView?.reset()
    }
    
    // MARK: - DKPhotoBasePreviewDataSource
    
    open override func createContentView() -> UIView {
        self.playerView = DKPlayerView(controlParentView: self.view)
        return self.playerView!
    }
    
    open override func contentSize() -> CGSize {
        return self.view.bounds.size
    }
    
    open override func fetchContent(withProgressBlock progressBlock: @escaping ((Float) -> Void), completeBlock: @escaping ((Any?, Error?) -> Void)) {
        if let videoURL = self.item.videoURL {
            completeBlock(videoURL, nil)
        } else if let asset = self.item.asset {
            let identifier = asset.localIdentifier
            
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { (progress, error, stop, info) in
                if progress > 0 {
                    progressBlock(Float(progress))
                }
            }

            PHImageManager.default().requestAVAsset(forVideo: asset,
                                                    options: options,
                                                    resultHandler: { [weak self] (avAsset, _, _) in
                                                        DispatchQueue.main.async {
                                                            if let asset = self?.item.asset, asset.localIdentifier == identifier {
                                                                completeBlock(avAsset, nil)
                                                            } else {
                                                                let error = NSError(domain: Bundle.main.bundleIdentifier!, code: -1, userInfo: [
                                                                    NSLocalizedDescriptionKey : DKPhotoGalleryResource.localizedStringWithKey("preview.player.fetch.error")
                                                                    ])
                                                                completeBlock(nil, error)
                                                            }
                                                        }
            })
        } else {
            assertionFailure()
        }
    }
    
    open override func updateContentView(with content: Any) {
        self.playerView?.closeBlock = self.closeBlock
        self.playerView?.autoHidesControlView = self.autoHidesControlView
        self.playerView?.tapToToggleControlView = self.tapToToggleControlView
        self.playerView?.beginPlayBlock = self.beginPlayBlock
        self.playerView?.isControlHidden = self.isControlHidden
        
        if let asset = content as? AVAsset {
            self.playerView?.asset = asset
        } else if let contentURL = content as? URL {
            self.playerView?.url = contentURL
        }
    }
    
    open override func enableZoom() -> Bool {
        return false
    }
    
    public override func enableIndicatorView() -> Bool {
        return false
    }
    
    open override var previewType: DKPhotoPreviewType {
        get { return .video }
    }

}
