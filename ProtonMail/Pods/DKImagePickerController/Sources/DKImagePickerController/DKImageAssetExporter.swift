//
//  DKImageAssetExporter.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/11/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import Foundation
import Photos

/// Purge disk on system UIApplicationWillTerminate notifications.
public class DKImageAssetDiskPurger {
    
    static let sharedInstance = DKImageAssetDiskPurger()
    
    private var directories = Set<URL>()
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(removeFiles), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func add(directory: URL) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        self.directories.insert(directory)
    }
    
    public func clear() {
        self.removeFiles()
    }
    
    // MARK: - Private
    
    @objc private func removeFiles() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let manager = FileManager.default
        for directory in self.directories {
            try? manager.removeItem(at: directory)
        }
    }
}

/////////////////////////////////////////////////////////////////////////////

// The Error that describes the failure can be obtained from the error property of DKAsset.
@objc
public enum DKImageAssetExporterError: Int {
    case cancelled, exportFailed
}

@objc
public enum DKImageExportPresent: Int {
    case
    compatible, // A preset for converting HEIF formatted images to JPEG.
    current     // A preset for passing image data as-is to the client.
}

public typealias DKImageAssetExportRequestID = Int32
public let DKImageAssetExportInvalidRequestID: DKImageAssetExportRequestID = 0

public let DKImageAssetExporterDomain = "DKImageAssetExporterDomain"

// Result's handler info dictionary keys
public let DKImageAssetExportResultRequestIDKey = "DKImageExportResultRequestIDKey" // key (DKImageAssetExportRequestID)
public let DKImageAssetExportResultCancelledKey = "DKImageExportCancelledKey" // key (Bool): result is not available because the request was cancelled

@objc
public protocol DKImageAssetExporterObserver {
    
    @objc optional func exporterWillBeginExporting(exporter: DKImageAssetExporter, asset: DKAsset)
    
    /// The progress can be obtained from the DKAsset.
    @objc optional func exporterDidUpdateProgress(exporter: DKImageAssetExporter, asset: DKAsset)
    
    /// When the asset's error is not nil, it indicates that an error occurred while exporting.
    @objc optional func exporterDidEndExporting(exporter: DKImageAssetExporter, asset: DKAsset)
}

/*
 Configuration options for a DKImageAssetExporter. When an exporter is created,
 a copy of the configuration object is made - you cannot modify the configuration
 of an exporter after it has been created.
 */
@objc
public class DKImageAssetExporterConfiguration: NSObject, NSCopying {
    
    @objc public var imageExportPreset = DKImageExportPresent.compatible
    
    /// videoExportPreset can be used to specify the transcoding quality for videos (via a AVAssetExportPreset* string).
    @objc public var videoExportPreset = AVAssetExportPresetHighestQuality
    
    #if swift(>=4.0)
    @objc public var avOutputFileType = AVFileType.mov
    #else
    @objc public var avOutputFileType = AVFileTypeQuickTimeMovie
    #endif
    
    @objc public var exportDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("DKImageAssetExporter")

    @objc public var compressionQuality = CGFloat(0.9)
    
    public required override init() {
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = type(of: self).init()
        copy.imageExportPreset = self.imageExportPreset
        copy.videoExportPreset = self.videoExportPreset
        copy.avOutputFileType = self.avOutputFileType
        copy.exportDirectory = self.exportDirectory
        copy.compressionQuality = self.compressionQuality
        
        return copy
    }
}

/*
 A DKImageAssetExporter object exports DKAsset(PHAsset) from album (or iCloud) to the app's tmp directory(by default).
 It automatically deletes the exported directories when it receives a UIApplicationWillTerminate notification.
 */
@objc
open class DKImageAssetExporter: DKImageBaseManager {
    
    @objc static public let sharedInstance = DKImageAssetExporter(configuration: DKImageAssetExporterConfiguration())

    private let configuration: DKImageAssetExporterConfiguration
    
    private var exportQueue: OperationQueue = {
        let exportQueue = OperationQueue()
        exportQueue.name = "DKImageAssetExporter_ExportQueue"
        exportQueue.maxConcurrentOperationCount = 1
        return exportQueue
    }()
    
    private let semaphore = DispatchSemaphore(value: 0)
    
    private var operations = [DKImageAssetExportRequestID : Operation]()
    private weak var currentAVExportSession: AVAssetExportSession?
    private var currentAssetInRequesting: DKAsset?
    
    @objc public init(configuration: DKImageAssetExporterConfiguration) {
        self.configuration = configuration.copy() as! DKImageAssetExporterConfiguration
        
        super.init()
        
        DKImageAssetDiskPurger.sharedInstance.add(directory: self.configuration.exportDirectory)
    }
    
    /// This method starts an asynchronous export operation of a batch of asset.
    @discardableResult
    @objc public func exportAssetsAsynchronously(assets: [DKAsset], completion: ((_ info: [AnyHashable : Any]) -> Void)?) -> DKImageAssetExportRequestID {
        guard assets.count > 0 else {
            completion?([
                DKImageAssetExportResultRequestIDKey : DKImageAssetExportInvalidRequestID,
                DKImageAssetExportResultCancelledKey : false
                ])
            return DKImageAssetExportInvalidRequestID
        }
        
        let requestID = self.getSeed()
        
        let operation = BlockOperation {
            guard let operation = self.operations[requestID] else {
                return
            }
            
            operation.completionBlock = nil
            
            var exportedCount = 0
            
            let exportCompletionBlock: (DKAsset, Error?) -> Void = { asset, error in
                exportedCount += 1
                
                defer {
                    self.notify(with: #selector(DKImageAssetExporterObserver.exporterDidEndExporting(exporter:asset:)), object: self, objectTwo: asset)
                    
                    if exportedCount == assets.count {
                        self.operations[requestID] = nil
                        self.semaphore.signal()
                        
                        DispatchQueue.main.async {
                            completion?([
                                DKImageAssetExportResultRequestIDKey : requestID,
                                DKImageAssetExportResultCancelledKey : operation.isCancelled
                                ])
                        }
                    }
                }
                
                if let error = error as NSError? {
                    asset.error = error
                    
                    asset.localTemporaryPath = nil
                } else {
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: asset.localTemporaryPath!.path)
                        asset.fileSize = (attributes[FileAttributeKey.size] as! NSNumber).uintValue
                    } catch let error as NSError {
                        asset.error = error
                        
                        asset.localTemporaryPath = nil
                    }
                }
            }
            
            for i in 0..<assets.count {
                let asset = assets[i]
                
                asset.progress = 0.0
                self.notify(with: #selector(DKImageAssetExporterObserver.exporterWillBeginExporting(exporter:asset:)), object: self, objectTwo: asset)
                
                if operation.isCancelled {
                    exportCompletionBlock(asset, self.makeCancelledError())
                    continue
                }
                
                asset.localTemporaryPath = self.generateTemporaryPath(with: asset)
                asset.error = nil
                
                if let localTemporaryPath = asset.localTemporaryPath,
                    let subpaths = try? FileManager.default.contentsOfDirectory(at: localTemporaryPath,
                                                                                includingPropertiesForKeys: [],
                                                                                options: .skipsHiddenFiles),
                    subpaths.count > 0 {
                    asset.localTemporaryPath = subpaths[0]
                    asset.fileName = subpaths[0].lastPathComponent
                    exportCompletionBlock(asset, nil)
                    continue
                }
                
                self.exportAsset(with: asset, requestID: requestID, progress: { progress in
                    asset.progress = progress
                    
                    self.notify(with: #selector(DKImageAssetExporterObserver.exporterDidUpdateProgress(exporter:asset:)), object: self, objectTwo: asset)
                }, completion: { error in
                    exportCompletionBlock(asset, error)
                })
            }
            
            self.semaphore.wait()
        }
        
        operation.completionBlock = { [weak operation] in
            if let operation = operation {
                if operation.isCancelled { // Not yet executing.
                    for asset in assets {
                        asset.error = self.makeCancelledError()
                        self.notify(with: #selector(DKImageAssetExporterObserver.exporterDidEndExporting(exporter:asset:)), object: self, objectTwo: asset)
                    }
                    
                    DispatchQueue.main.async {
                        completion?([
                            DKImageAssetExportResultRequestIDKey : requestID,
                            DKImageAssetExportResultCancelledKey : true
                            ])
                    }
                } else {
                    self.operations[requestID] = nil
                }
            }
        }
        
        self.operations[requestID] = operation
        self.exportQueue.addOperation(operation)
        
        return requestID
    }
    
    @objc public func cancel(requestID: DKImageAssetExportRequestID) {
        if let operation = self.operations[requestID] {
            if operation.isExecuting {
                self.currentAVExportSession?.cancelExport()
            }
            operation.cancel()
            self.operations[requestID] = nil
        }
    }
    
    @objc public func cancelAll() {
        self.operations.removeAll()
        self.exportQueue.cancelAllOperations()
        self.currentAssetInRequesting?.cancelRequests()
        self.currentAVExportSession?.cancelExport()
    }
    
    // MARK: - RequestID
    
    static private var seed: DKImageAssetExportRequestID = 0
    private func getSeed() -> DKImageAssetExportRequestID {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        DKImageAssetExporter.seed += 1
        return DKImageAssetExporter.seed
    }
    
    // MARK: - Private
    
    private func makeCancelledError() -> Error {
        return NSError(domain: DKImageAssetExporterDomain,
                       code: DKImageAssetExporterError.cancelled.rawValue,
                       userInfo: [NSLocalizedDescriptionKey : "The operation was cancelled."])
    }
    
    private func isHEIC(with imageData: Data) -> Bool {
        if imageData.count >= 12, let firstByte = imageData.first, firstByte == 0 {
            let subdata = imageData.subdata(in: 4..<12)
            let str = String(data: subdata, encoding: .ascii)
            return str == "ftypheic" || str == "ftypheix" || str == "ftyphevc" || str == "ftyphevx"
        } else {
            return false
        }
    }
    
    private func imageToJPEG(with imageData: Data) -> Data? {
        if #available(iOS 10.0, *), let ciImage = CIImage(data: imageData), let colorSpace = ciImage.colorSpace {
            return CIContext().jpegRepresentation(
                of: ciImage,
                colorSpace: colorSpace,
                options: [
                    CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String) : configuration.compressionQuality
                ]
            )
        } else if let image = UIImage(data: imageData) {
            return image.jpegData(compressionQuality: configuration.compressionQuality)
        } else {
            return nil
        }
    }
    
    private func generateAuxiliaryPath(with url: URL) -> (auxiliaryDirectory: URL, auxiliaryFilePath: URL) {
        let parentDirectory = url.deletingLastPathComponent()
        let auxiliaryDirectory = parentDirectory.appendingPathComponent(".tmp")
        let auxiliaryFilePath = auxiliaryDirectory.appendingPathComponent(url.lastPathComponent)

        return (auxiliaryDirectory, auxiliaryFilePath)
    }
    
    private func generateTemporaryPath(with asset: DKAsset) -> URL {
        let localIdentifier = asset.localIdentifier.data(using: .utf8)?.base64EncodedString() ?? "\(Date.timeIntervalSinceReferenceDate)"
        var directoryName = localIdentifier
        
        if let originalAsset = asset.originalAsset {
            if let modificationDate = originalAsset.modificationDate {
                directoryName = directoryName + "/" + String(modificationDate.timeIntervalSinceReferenceDate)
            }
            
            if asset.type == .photo {
                directoryName = directoryName + "/" + String(self.configuration.imageExportPreset.rawValue)
            } else {
                #if swift(>=4.0)
                directoryName = directoryName + "/" + self.configuration.videoExportPreset + self.configuration.avOutputFileType.rawValue
                #else
                directoryName = directoryName + "/" + self.configuration.videoExportPreset + self.configuration.avOutputFileType
                #endif
            }
        }
        
        let directory = self.configuration.exportDirectory.appendingPathComponent(directoryName)
        
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return directory
    }
    
    static let ioQueue = DispatchQueue(label: "DKPhotoImagePreviewVC.ioQueue")

    private func exportAsset(with asset: DKAsset, requestID: DKImageAssetExportRequestID, progress: @escaping (Double) -> Void, completion: @escaping (Error?) -> Void) {
        switch asset.type {
        case .photo:
            self.exportImage(with: asset, requestID: requestID, progress: progress, completion: completion)
        case .video:
            self.exportAVAsset(with: asset, requestID: requestID, progress: progress, completion: completion)
        }
    }
    
    private func exportImage(with asset: DKAsset, requestID: DKImageAssetExportRequestID, progress: @escaping (Double) -> Void, completion: @escaping (Error?) -> Void) {
        
        func write(data: Data, to url: URL) throws {
            let (auxiliaryDirectory, auxiliaryFilePath) = self.generateAuxiliaryPath(with: url)
            
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: auxiliaryDirectory, withIntermediateDirectories: true, attributes: nil)
            
            try data.write(to: auxiliaryFilePath, options: [.atomic])
            try fileManager.moveItem(at: auxiliaryFilePath, to: url)
            try fileManager.removeItem(at: auxiliaryDirectory)
        }
        
        if let originalAsset = asset.originalAsset {
            autoreleasepool {
                let options = PHImageRequestOptions()
                options.version = .current
                options.progressHandler = { (p, _, _, _) in
                    progress(p)
                }
                
                let semaphore = DispatchSemaphore(value: 0)
                
                asset.fetchImageData(options: options, compressionQuality: configuration.compressionQuality) { (data, info) in
                    self.currentAssetInRequesting = nil
                    semaphore.signal()
                    
                    DKImageAssetExporter.ioQueue.async {
                        if self.operations[requestID] == nil {
                            return completion(self.makeCancelledError())
                        }
                        
                        if var imageData = data {
                            if #available(iOS 9, *) {
                                var resource: PHAssetResource? = nil
                                for assetResource in PHAssetResource.assetResources(for: originalAsset) {
                                    if assetResource.type == .photo {
                                        resource = assetResource
                                        break
                                    }
                                }
                                if let resource = resource {
                                    asset.fileName = resource.originalFilename
                                }
                            }
                            
                            if asset.fileName == nil {
                                if let info = info, let fileURL = info["PHImageFileURLKey"] as? NSURL {
                                    asset.fileName = fileURL.lastPathComponent ?? "Image"
                                } else {
                                    asset.fileName = "Image.jpg"
                                }
                            }
                                                                                    
                            if self.configuration.imageExportPreset == .compatible && self.isHEIC(with: imageData) {
                                if let fileName = asset.fileName, let jpgData = self.imageToJPEG(with: imageData) {
                                    imageData = jpgData
                                    
                                    if fileName.uppercased().hasSuffix(".HEIC") {
                                        asset.fileName = fileName.dropLast(4) + "jpg"
                                    }
                                }
                            }
                            
                            asset.localTemporaryPath = asset.localTemporaryPath?.appendingPathComponent(asset.fileName!)
                            
                            if FileManager.default.fileExists(atPath: asset.localTemporaryPath!.path) {
                                return completion(nil)
                            }
                            
                            do {
                                try write(data: imageData, to: asset.localTemporaryPath!)
                                completion(nil)
                            } catch {
                                completion(error)
                            }
                        } else {
                            if let info = info, let isCancelled = info[PHImageCancelledKey] as? NSNumber, isCancelled.boolValue {
                                completion(self.makeCancelledError())
                            } else {
                                completion(NSError(domain: DKImageAssetExporterDomain,
                                                   code: DKImageAssetExporterError.exportFailed.rawValue,
                                                   userInfo: [NSLocalizedDescriptionKey : "Failed to fetch image data."]))
                            }
                        }
                    }
                }
                self.currentAssetInRequesting = asset
                
                semaphore.wait()
            }
        } else {
            let quality = configuration.compressionQuality
            DKImageAssetExporter.ioQueue.async {
                if self.operations[requestID] == nil {
                    return completion(self.makeCancelledError())
                }
                
                do {
                    try write(data: asset.image!.jpegData(compressionQuality: quality)!, to: asset.localTemporaryPath!)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    private func exportAVAsset(with asset: DKAsset, requestID: DKImageAssetExportRequestID, progress: @escaping (Double) -> Void, completion: @escaping (Error?) -> Void) {
        var isNotInLocal = false
        
        let options = PHVideoRequestOptions()
        options.deliveryMode = .mediumQualityFormat
        options.progressHandler = { (p, _, _, _) in
            isNotInLocal = true
            progress(p * 0.85)
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        asset.fetchAVAsset(options: options) { (avAsset, info) in
            self.currentAssetInRequesting = nil
            
            #if swift(>=4.0)
            let mediaTypeVideo = AVMediaType.video
            #else
            let mediaTypeVideo = AVMediaTypeVideo
            #endif
            
            if let avAsset = avAsset {
                if let avURLAsset = avAsset as? AVURLAsset {
                    asset.fileName = avURLAsset.url.lastPathComponent
                } else if let composition = avAsset as? AVComposition,
                    let sourceURL = composition.tracks(withMediaType: mediaTypeVideo).first?.segments.first?.sourceURL {
                    asset.fileName = sourceURL.lastPathComponent
                } else {
                    asset.fileName = "Video.mov"
                }
                
                asset.localTemporaryPath = asset.localTemporaryPath?.appendingPathComponent(asset.fileName!)
                
                semaphore.signal()
                
                DKImageAssetExporter.ioQueue.async {
                    if self.operations[requestID] == nil {
                        return completion(self.makeCancelledError())
                    }
                    
                    let group = DispatchGroup()
                    group.enter()
                    
                    if avAsset.isExportable, let exportSession = AVAssetExportSession(asset: avAsset, presetName: self.configuration.videoExportPreset) {
                        let (auxiliaryDirectory, auxiliaryFilePath) = self.generateAuxiliaryPath(with: asset.localTemporaryPath!)
                        
                        let fileManager = FileManager.default
                        if fileManager.fileExists(atPath: auxiliaryFilePath.path) {
                            try? fileManager.removeItem(at: auxiliaryFilePath)
                        }
                        
                        try? fileManager.createDirectory(at: auxiliaryDirectory,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
                        
                        exportSession.outputFileType = self.configuration.avOutputFileType
                        exportSession.outputURL = auxiliaryFilePath
                        exportSession.shouldOptimizeForNetworkUse = true
                        exportSession.directoryForTemporaryFiles = auxiliaryDirectory
                        exportSession.exportAsynchronously(completionHandler: {
                            defer {
                                try? fileManager.removeItem(at: auxiliaryDirectory)
                            }
                            
                            group.leave()
                            
                            switch (exportSession.status) {
                            case .completed:
                                try! fileManager.moveItem(at: auxiliaryFilePath, to: asset.localTemporaryPath!)
                                completion(nil)
                            case .cancelled:
                                completion(self.makeCancelledError())
                            case .failed:
                                completion(exportSession.error)
                            default:
                                assert(false)
                            }
                        })
                        
                        self.currentAVExportSession = exportSession
                        
                        self.waitForExportToFinish(exportSession: exportSession, group: group) { p in
                            progress(isNotInLocal ? min(0.85 + p * 0.15, 1.0) : p)
                        }
                    } else {
                        if let info = info, let isCancelled = info[PHImageCancelledKey] as? NSNumber, isCancelled.boolValue {
                            completion(self.makeCancelledError())
                        } else {
                            completion(NSError(domain: DKImageAssetExporterDomain,
                                               code: DKImageAssetExporterError.exportFailed.rawValue,
                                               userInfo: [NSLocalizedDescriptionKey : "Can't setup AVAssetExportSession."]))
                        }
                    }
                }
            } else {
                completion(NSError(domain: DKImageAssetExporterDomain,
                                   code: DKImageAssetExporterError.exportFailed.rawValue,
                                   userInfo: [NSLocalizedDescriptionKey : "Failed to fetch AVAsset."]))
            }
        }
        self.currentAssetInRequesting = asset
        
        semaphore.wait()
    }
    
    private func waitForExportToFinish(exportSession: AVAssetExportSession, group: DispatchGroup, progress: (Double) -> Void) {
        while exportSession.status == .waiting || exportSession.status == .exporting {
            
            let _ = group.wait(timeout: .now() + .milliseconds(500))
            
            if exportSession.status == .exporting {
                progress(Double(exportSession.progress))
            }
        }
    }
}
