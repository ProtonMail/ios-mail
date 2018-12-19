//
//  DKPhotoBaseImagePreviewVC.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 15/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

#if canImport(FLAnimatedImage)
import FLAnimatedImage
#elseif canImport(SDWebImage)
import SDWebImage
#endif

open class DKPhotoBaseImagePreviewVC: DKPhotoBasePreviewVC {

    // MARK: - QR Code
    
    private func detectStringFromImage() -> String? {
        guard let contentView = self.contentView as? DKPhotoImageView else { return nil }
        
        guard let targetImage = contentView.image ?? contentView.animatedImage?.posterImage else {
            return nil
        }
        
        if let result = self.detectStringFromCIImage(image: CIImage(image: targetImage)!) {
            return result
        } else {
            return nil
        }
    }
    
    private func detectStringFromCIImage(image: CIImage) -> String? {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [
            CIDetectorAccuracy : CIDetectorAccuracyHigh
            ])
        
        if let detector = detector {
            let features = detector.features(in: image)
            if let feature = features.first as? CIQRCodeFeature {
                return feature.messageString
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func previewQRCode(with result: String) {
        if let URL = URL(string: result), let _ = URL.scheme, let _ = URL.host {
            let resultVC = DKPhotoWebVC()
            resultVC.urlString = result
            self.navigationController?.pushViewController(resultVC, animated: true)
        } else {
            let resultVC = DKPhotoQRCodeResultVC(result: result)
            self.navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    // MARK: - Save Image
    
    private func saveImageToAlbum() {
        guard let contentView = self.contentView as? DKPhotoImageView else { return }
        
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async(execute: {
                switch status {
                case .authorized:
                    if let animatedImage = contentView.animatedImage {
                        ALAssetsLibrary().writeImageData(toSavedPhotosAlbum: animatedImage.data, metadata: nil, completionBlock: { (newURL, error) in
                            self.showImageSaveResult(with: error)
                        })
                    } else if let imageURL = self.item.imageURL, imageURL.isFileURL, let data = try? Data(contentsOf: imageURL) {
                        ALAssetsLibrary().writeImageData(toSavedPhotosAlbum: data, metadata: [:], completionBlock: { (newURL, error) in
                            self.showImageSaveResult(with: error)
                        })
                    } else if let image = contentView.image {
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                case .restricted:
                    fallthrough
                case .denied:
                    self.showTips(DKPhotoGalleryResource.localizedStringWithKey("preview.image.saveImage.permission.error"))
                default:
                    break
                }
            })
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        self.showImageSaveResult(with: error)
    }
    
    func showImageSaveResult(with error: Error?) {
        if let error = error {
            self.showTips(error.localizedDescription)
        } else {
            self.showTips(DKPhotoGalleryResource.localizedStringWithKey("preview.image.saveImage.result.success"))
        }
    }
    
    // MARK: - DKPhotoBasePreviewDataSource
    
    override public func createContentView() -> UIView {
        let contentView = DKPhotoImageView()
        return contentView
    }
        
    override public func updateContentView(with content: Any) {
        guard let contentView = self.contentView as? DKPhotoImageView else { return }
        
        if let data = content as? Data {
            let imageFormat = NSData.sd_imageFormat(forImageData: data)
            if imageFormat == .GIF {
                contentView.animatedImage = FLAnimatedImage(gifData: data)
            } else {
                contentView.image = UIImage(data: data)
            }
        } else if let image = content as? UIImage {
            contentView.image = image
        } else {
            assertionFailure()
        }
    }
    
    public override func snapshotImage() -> UIImage? {
        if let contentView = self.contentView as? DKPhotoImageView {
            if let image = contentView.image {
                return image
            } else if contentView.animatedImage != nil {
                return contentView.currentFrame
            } else {
                return self.item.thumbnail
            }
        } else {
            return self.item.thumbnail
        }
    }
    
    public override func showError() {
        if self.item.thumbnail != nil { return }
        
        guard let contentView = self.contentView as? DKPhotoImageView else { return }
        
        contentView.image = DKPhotoGalleryResource.downloadFailedImage()
        contentView.contentMode = .center
    }
    
    public override func hidesError() {
        contentView.contentMode = .scaleAspectFit
    }
    
    override public func contentSize() -> CGSize {
        guard let contentView = self.contentView as? DKPhotoImageView else { return CGSize.zero }
        
        if let image = contentView.image {
            return image.size
        } else if let animatedImage = contentView.animatedImage {
            return animatedImage.size
        } else {
            return CGSize.zero
        }
    }
    
    @available(iOS 9.0, *)
    public override func defaultPreviewActions() -> [UIPreviewActionItem] {
        let saveActionItem = UIPreviewAction(title: DKPhotoGalleryResource.localizedStringWithKey("preview.3DTouch.saveImage.title"),
                                             style: .default) { (action, previewViewController) in
                                                self.saveImageToAlbum()
        }
        
        return [saveActionItem]
    }
    
    public override func defaultLongPressActions() -> [UIAlertAction] {
        var actions = [UIAlertAction]()
        
        if let QRCodeResult = self.detectStringFromImage() {
            let detectQRCodeAction = UIAlertAction(title: DKPhotoGalleryResource.localizedStringWithKey("preview.image.extractQRCode.title"),
                                                   style: .default,
                                                   handler: { [weak self] (action) in
                                                    self?.previewQRCode(with: QRCodeResult)
            })
            actions.append(detectQRCodeAction)
        }
        
        let saveImageAction = UIAlertAction(title: DKPhotoGalleryResource.localizedStringWithKey("preview.image.longPress.saveImage.title"),
                                            style: .default) { [weak self] (action) in
                                                self?.saveImageToAlbum()
        }
        actions.append(saveImageAction)
        
        return actions
        
    }
}
