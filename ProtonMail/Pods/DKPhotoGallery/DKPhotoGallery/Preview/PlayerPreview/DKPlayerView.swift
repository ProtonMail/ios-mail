//
//  DKPlayerView.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 28/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit
import AVFoundation

private var DKPlayerViewKVOContext = 0

private class DKPlayerControlView: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitTestingView = super.hitTest(point, with: event)
        return hitTestingView == self ? nil : hitTestingView
    }
    
}

open class DKPlayerView: UIView {
    
    public var url: URL? {
        
        willSet {
            if self.url == newValue && self.error == nil {
                return
            }
            
            if let newValue = newValue {
                DispatchQueue.global().async {
                    if newValue == self.url {
                        let asset = AVURLAsset(url: newValue)
                        
                        DispatchQueue.main.async {
                            if newValue == self.url {
                                self.asset = asset
                            }
                        }
                    }
                }
            } else {
                self.asset = nil
            }
        }
    }
    
    public var asset: AVAsset? {
        
        didSet {
            if self.asset == oldValue {
                return
            }
            
            if let oldAsset = oldValue {
                oldAsset.cancelLoading()
            }
            
            self.playerItem = nil
            
            if let newValue = self.asset {
                self.bufferingIndicator.startAnimating()
                newValue.loadValuesAsynchronously(forKeys: ["duration", "tracks"], completionHandler: {
                    if newValue == self.asset {
                        var error: NSError?
                        let loadStatus = newValue.statusOfValue(forKey: "duration", error: &error)
                        var item: AVPlayerItem?
                        if loadStatus == .loaded {
                            item = AVPlayerItem(asset: newValue)
                        } else if loadStatus == .failed {
                            self.error = error
                        }
                        
                        DispatchQueue.main.async {
                            if newValue == self.asset {
                                self.bufferingIndicator.stopAnimating()
                                
                                if let item = item {
                                    self.playerItem = item
                                } else if let error = self.error, self.autoPlayOrShowErrorOnce {
                                    self.showPlayError(error.localizedDescription)
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    public var playerItem: AVPlayerItem? {

        willSet {
            if self.playerItem == newValue {
                return
            }
            
            if let oldPlayerItem = self.playerItem {
                self.removeObservers(for: oldPlayerItem)
                self.player.pause()

                self.player.replaceCurrentItem(with: nil)
            }

            if let newPlayerItem = newValue {
                self.player.replaceCurrentItem(with: newPlayerItem)
                self.addObservers(for: newPlayerItem)
            }
        }
    }
 
    public var closeBlock: (() -> Void)? {
        willSet {
            self.closeButton.isHidden = newValue == nil
        }
    }
    
    public var beginPlayBlock: (() -> Void)?
    
    public var isControlHidden: Bool {
        get { return self.controlView.isHidden }
        
        set { self.controlView.isHidden = newValue }
    }
    
    public var isPlaying: Bool {
        get { return self.player.rate == 1.0 }
    }
    
    public var autoHidesControlView = true
    
    public var tapToToggleControlView = true {
        willSet {
            self.tapGesture.isEnabled = newValue
        }
    }
    
    public var isFinishedPlaying = false
    
    public let playButton = UIButton(type: .custom)
    
    private let closeButton = UIButton(type: .custom)
    private let playPauseButton = UIButton(type: .custom)
    private let timeSlider = UISlider()
    private let startTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private var tapGesture: UITapGestureRecognizer!
    private lazy var bufferingIndicator: UIActivityIndicatorView = {
        #if swift(>=4.2)
        return UIActivityIndicatorView(style: .gray)
        #else
        return UIActivityIndicatorView(activityIndicatorStyle: .gray)
        #endif
    }()
    
    private var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    private let player = AVPlayer()
    
    private var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        
        set {
            guard let _ = self.player.currentItem else { return }
            
            #if swift(>=4.2)
            let newTime = CMTimeMakeWithSeconds(Double(Int64(newValue)), preferredTimescale: 1)
            self.player.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            #else
            let newTime = CMTimeMakeWithSeconds(Double(Int64(newValue)), 1)
            self.player.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            #endif
        }
    }
    
    private let controlView = DKPlayerControlView()
    
    private var autoPlayOrShowErrorOnce = false
    
    private var _error: NSError?
    private var error: NSError? {
        get {
            return _error ?? self.player.currentItem?.error as NSError?
        }
        
        set {
            _error = newValue
        }
    }
    
    /*
     A formatter for individual date components used to provide an appropriate
     value for the `startTimeLabel` and `durationLabel`.
     */
    private let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    private var timeObserverToken: Any?
    
    open override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    convenience init() {
        self.init(frame: CGRect.zero, controlParentView: nil)
    }
    
    convenience init(controlParentView: UIView?) {
        self.init(frame: CGRect.zero, controlParentView: controlParentView)
    }
    
    private weak var controlParentView: UIView?
    public init(frame: CGRect, controlParentView: UIView?) {
        super.init(frame: frame)
        
        self.controlParentView = controlParentView
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupUI()
    }
    
    deinit {
        guard let currentItem = self.player.currentItem, currentItem.observationInfo != nil else { return }
        
        self.removeObservers(for: currentItem)
    }
    
    @objc public func playAndHidesControlView() {
        self.play()
        
        self.beginPlayBlock?()
        
        if self.autoHidesControlView {
            self.isControlHidden = true
        }
    }
    
    public func play() {
        guard !self.isPlaying else { return }
        
        if let error = self.error {
            if let avAsset = self.asset ?? self.playerItem?.asset, self.isTriableError(error) {
                self.autoPlayOrShowErrorOnce = true
                
                if let URLAsset = avAsset as? AVURLAsset {
                    self.asset = nil
                    self.url = URLAsset.url
                } else {
                    self.url = nil
                    self.asset = avAsset
                }
                self.error = nil
            } else {
                self.showPlayError(error.localizedDescription)
            }
            
            return
        }
        
        if let currentItem = self.playerItem {
            if currentItem.status == .readyToPlay {
                if self.isFinishedPlaying {
                    self.isFinishedPlaying = false
                    self.currentTime = 0.0
                }
                
                self.player.play()
                
                self.updateBufferingIndicatorStateIfNeeded()
            } else if currentItem.status == .unknown {
                self.player.play()
            }
        }
    }
    
    @objc public func pause() {
        guard let _ = self.player.currentItem, self.isPlaying else { return }
        
        self.player.pause()
    }
    
    public func stop() {
        self.asset?.cancelLoading()
        self.pause()
    }
    
    public func updateContextBackground(alpha: CGFloat) {
        self.playButton.alpha = alpha
        self.controlView.alpha = alpha
    }
    
    public func reset() {
        self.asset?.cancelLoading()
        
        self.url = nil
        self.asset = nil
        self.playerItem = nil
        self.error = nil
        
        self.autoPlayOrShowErrorOnce = false
        self.isFinishedPlaying = false
        self.bufferingIndicator.stopAnimating()
        
        self.playButton.isHidden = false
        
        self.playPauseButton.isEnabled = false
        self.timeSlider.isEnabled = false
        self.timeSlider.value = 0
        
        self.startTimeLabel.isEnabled = false
        self.startTimeLabel.text = "0:00"
        
        self.durationLabel.isEnabled = false
        self.durationLabel.text = "0:00"
    }
    
    // MARK: - Private
    
    private func setupUI() {
        self.playerLayer.player = self.player
        
        self.playButton.setImage(DKPhotoGalleryResource.videoPlayImage(), for: .normal)
        self.playButton.addTarget(self, action: #selector(playAndHidesControlView), for: .touchUpInside)
        self.addSubview(self.playButton)
        self.playButton.sizeToFit()
        self.playButton.center = self.center
        self.playButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        
        self.bufferingIndicator.hidesWhenStopped = true
        self.bufferingIndicator.isUserInteractionEnabled = false
        self.bufferingIndicator.center = self.center
        self.bufferingIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        self.addSubview(self.bufferingIndicator)
        
        self.closeButton.setImage(DKPhotoGalleryResource.closeVideoImage(), for: .normal)
        self.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        self.controlView.addSubview(self.closeButton)
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.closeButton.addConstraint(NSLayoutConstraint(item: self.closeButton,
                                                          attribute: .width,
                                                          relatedBy: .equal,
                                                          toItem: nil,
                                                          attribute: .notAnAttribute,
                                                          multiplier: 1,
                                                          constant: 40))
        self.closeButton.addConstraint(NSLayoutConstraint(item: self.closeButton,
                                                          attribute: .height,
                                                          relatedBy: .equal,
                                                          toItem: nil,
                                                          attribute: .notAnAttribute,
                                                          multiplier: 1,
                                                          constant: 40))
        self.controlView.addConstraint(NSLayoutConstraint(item: self.closeButton,
                                                          attribute: .top,
                                                          relatedBy: .equal,
                                                          toItem: self.controlView,
                                                          attribute: .top,
                                                          multiplier: 1,
                                                          constant: 25))
        self.controlView.addConstraint(NSLayoutConstraint(item: self.closeButton,
                                                          attribute: .left,
                                                          relatedBy: .equal,
                                                          toItem: self.controlView,
                                                          attribute: .left,
                                                          multiplier: 1,
                                                          constant: 15))
        
        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        self.controlView.addSubview(bottomView)
        
        self.playPauseButton.setImage(DKPhotoGalleryResource.videoToolbarPlayImage(), for: .normal)
        self.playPauseButton.setImage(DKPhotoGalleryResource.videoToolbarPauseImage(), for: .selected)
        self.playPauseButton.addTarget(self, action: #selector(playPauseButtonWasPressed), for: .touchUpInside)
        bottomView.addSubview(self.playPauseButton)
        self.playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        self.playPauseButton.addConstraint(NSLayoutConstraint(item: self.playPauseButton,
                                                              attribute: .width,
                                                              relatedBy: .equal,
                                                              toItem: nil,
                                                              attribute: .notAnAttribute,
                                                              multiplier: 1,
                                                              constant: 40))
        self.playPauseButton.addConstraint(NSLayoutConstraint(item: self.playPauseButton,
                                                              attribute: .height,
                                                              relatedBy: .equal,
                                                              toItem: nil,
                                                              attribute: .notAnAttribute,
                                                              multiplier: 1,
                                                              constant: 40))
        bottomView.addConstraint(NSLayoutConstraint(item: self.playPauseButton,
                                                    attribute: .left,
                                                    relatedBy: .equal,
                                                    toItem: bottomView,
                                                    attribute: .left,
                                                    multiplier: 1,
                                                    constant: 20))
        bottomView.addConstraint(NSLayoutConstraint(item: self.playPauseButton,
                                                    attribute: .top,
                                                    relatedBy: .equal,
                                                    toItem: bottomView,
                                                    attribute: .top,
                                                    multiplier: 1,
                                                    constant: 0))
        bottomView.addConstraint(NSLayoutConstraint(item: self.playPauseButton,
                                                    attribute: .bottom,
                                                    relatedBy: .equal,
                                                    toItem: bottomView,
                                                    attribute: .bottom,
                                                    multiplier: 1,
                                                    constant: 0))
        
        bottomView.addSubview(self.startTimeLabel)
        self.startTimeLabel.textColor = UIColor.white
        self.startTimeLabel.textAlignment = .right
        self.startTimeLabel.font = UIFont(name: "Helvetica Neue", size: 13)
        self.startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addConstraint(NSLayoutConstraint(item: self.startTimeLabel,
                                                    attribute: .left,
                                                    relatedBy: .equal,
                                                    toItem: self.playPauseButton,
                                                    attribute: .right,
                                                    multiplier: 1,
                                                    constant: 0))
        bottomView.addConstraint(NSLayoutConstraint(item: self.startTimeLabel,
                                                    attribute: .centerY,
                                                    relatedBy: .equal,
                                                    toItem: self.playPauseButton,
                                                    attribute: .centerY,
                                                    multiplier: 1,
                                                    constant: 0))
        
        bottomView.addSubview(self.timeSlider)
        self.timeSlider.addTarget(self, action: #selector(timeSliderDidChange(sender:event:)), for: .valueChanged)
        self.timeSlider.setThumbImage(DKPhotoGalleryResource.videoTimeSliderImage(), for: .normal)
        self.timeSlider.translatesAutoresizingMaskIntoConstraints = false
        self.timeSlider.addConstraint(NSLayoutConstraint(item: self.timeSlider,
                                                         attribute: .height,
                                                         relatedBy: .equal,
                                                         toItem: nil,
                                                         attribute: .notAnAttribute,
                                                         multiplier: 1,
                                                         constant: 40))
        bottomView.addConstraint(NSLayoutConstraint(item: self.timeSlider,
                                                    attribute: .left,
                                                    relatedBy: .equal,
                                                    toItem: self.startTimeLabel,
                                                    attribute: .right,
                                                    multiplier: 1,
                                                    constant: 15))
        bottomView.addConstraint(NSLayoutConstraint(item: self.timeSlider,
                                                    attribute: .centerY,
                                                    relatedBy: .equal,
                                                    toItem: self.playPauseButton,
                                                    attribute: .centerY,
                                                    multiplier: 1,
                                                    constant: 0))
        
        bottomView.addSubview(self.durationLabel)
        self.durationLabel.textColor = UIColor.white
        self.durationLabel.font = self.startTimeLabel.font
        self.durationLabel.translatesAutoresizingMaskIntoConstraints = false
        self.durationLabel.addConstraint(NSLayoutConstraint(item: self.durationLabel,
                                                            attribute: .width,
                                                            relatedBy: .equal,
                                                            toItem: nil,
                                                            attribute: .notAnAttribute,
                                                            multiplier: 1,
                                                            constant: 50))
        bottomView.addConstraint(NSLayoutConstraint(item: self.durationLabel,
                                                    attribute: .width,
                                                    relatedBy: .equal,
                                                    toItem: self.startTimeLabel,
                                                    attribute: .width,
                                                    multiplier: 1,
                                                    constant: 0))
        bottomView.addConstraint(NSLayoutConstraint(item: self.durationLabel,
                                                    attribute: .left,
                                                    relatedBy: .equal,
                                                    toItem: self.timeSlider,
                                                    attribute: .right,
                                                    multiplier: 1,
                                                    constant: 15))
        bottomView.addConstraint(NSLayoutConstraint(item: self.durationLabel,
                                                    attribute: .right,
                                                    relatedBy: .equal,
                                                    toItem: bottomView,
                                                    attribute: .right,
                                                    multiplier: 1,
                                                    constant: -10))
        bottomView.addConstraint(NSLayoutConstraint(item: self.durationLabel,
                                                    attribute: .centerY,
                                                    relatedBy: .equal,
                                                    toItem: self.startTimeLabel,
                                                    attribute: .centerY,
                                                    multiplier: 1,
                                                    constant: 0))
        
        self.controlView.addConstraint(NSLayoutConstraint(item: bottomView,
                                                    attribute: .left,
                                                    relatedBy: .equal,
                                                    toItem: self.controlView,
                                                    attribute: .left,
                                                    multiplier: 1,
                                                    constant: 0))
        self.controlView.addConstraint(NSLayoutConstraint(item: bottomView,
                                                          attribute: .right,
                                                          relatedBy: .equal,
                                                          toItem: self.controlView,
                                                          attribute: .right,
                                                          multiplier: 1,
                                                          constant: 0))
        self.controlView.addConstraint(NSLayoutConstraint(item: bottomView,
                                                          attribute: .bottom,
                                                          relatedBy: .equal,
                                                          toItem: self.controlView,
                                                          attribute: .bottom,
                                                          multiplier: 1,
                                                          constant: DKPhotoBasePreviewVC.isIphoneX() ? -34 : 0))
        
        if let controlParentView = self.controlParentView {
            controlParentView.addSubview(self.controlView)
        } else {
            self.addSubview(self.controlView)
        }
        
        self.controlView.frame = self.controlView.superview!.bounds
        self.controlView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let backgroundImageView = UIImageView(image: DKPhotoGalleryResource.videoPlayControlBackgroundImage())
        backgroundImageView.frame = self.controlView.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.controlView.insertSubview(backgroundImageView, at: 0)
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControlView(tapGesture:)))
        self.addGestureRecognizer(self.tapGesture)
        
        self.timeSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sliderTappedAction(tapGesture:))))
        
        self.controlView.isHidden = self.isControlHidden
    }
    
    @objc private func playPauseButtonWasPressed() {
        if !self.isPlaying {
            self.play()
        } else {
            self.pause()
        }
    }
    
    @objc private func timeSliderDidChange(sender: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                if self.isPlaying {
                    self.pause()
                }
            case .moved:
                self.currentTime = Double(self.timeSlider.value)
            case .ended,
                 .cancelled:
                self.play()
            default:
                break
            }
        } else {
            self.currentTime = Double(self.timeSlider.value)
            self.play()
        }
    }
    
    @objc private func sliderTappedAction(tapGesture: UITapGestureRecognizer) {
        if let slider = tapGesture.view as? UISlider {
            if slider.isHighlighted { return }
            
            let point = tapGesture.location(in: slider)
            let percentage = Float(point.x / slider.bounds.width)
            let delta = percentage * Float(slider.maximumValue - slider.minimumValue)
            let value = slider.minimumValue + delta
            slider.setValue(value, animated: true)
            slider.sendActions(for: .valueChanged)
        }
    }
    
    @objc private func toggleControlView(tapGesture: UITapGestureRecognizer) {
        self.isControlHidden = !self.isControlHidden
        
        self.startHidesControlTimerIfNeeded()
    }

    private var hidesControlViewTimer: Timer?
    private func startHidesControlTimerIfNeeded() {
        guard self.autoHidesControlView else { return }
        
        self.stopHidesControlTimer()
        if !self.isControlHidden && self.isPlaying {
            self.hidesControlViewTimer = Timer.scheduledTimer(timeInterval: 3.5,
                                                              target: self,
                                                              selector: #selector(hidesControlViewIfNeeded),
                                                              userInfo: nil,
                                                              repeats: false)
        }
    }
    
    private func stopHidesControlTimer() {
        guard self.autoHidesControlView else { return }
        
        self.hidesControlViewTimer?.invalidate()
        self.hidesControlViewTimer = nil
    }
    
    @objc private func hidesControlViewIfNeeded() {
        if self.isPlaying {
            self.isControlHidden = true
        }
    }
    
    @objc private func close() {
        if let closeBlock = self.closeBlock {
            closeBlock()
        }
    }
    
    private func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
    private func showPlayError(_ message: String) {
        self.makeSimpleToast(message)
    }
    
    private func isTriableError(_ error: NSError) -> Bool {
        let untriableCodes: Set<Int> = [
            URLError.badURL.rawValue,
            URLError.fileDoesNotExist.rawValue,
            URLError.unsupportedURL.rawValue,
        ]
        
        return !untriableCodes.contains(error.code)
    }
    
    private func updateBufferingIndicatorStateIfNeeded() {
        if self.isPlaying, let currentItem = self.player.currentItem {
            if currentItem.isPlaybackBufferEmpty {
                self.bufferingIndicator.startAnimating()
            } else if currentItem.isPlaybackLikelyToKeepUp {
                self.bufferingIndicator.stopAnimating()
            } else {
                self.bufferingIndicator.stopAnimating()
            }
        }
    }
    
    // MARK: - Observer
    
    private func addObservers(for playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), options: [.new, .initial], context: &DKPlayerViewKVOContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: &DKPlayerViewKVOContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: [.new, .initial], context: &DKPlayerViewKVOContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.new, .initial], context: &DKPlayerViewKVOContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new, .initial], context: &DKPlayerViewKVOContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let interval = CMTime(value: 1, timescale: 1)
        self.timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            
            let timeElapsed = Float(CMTimeGetSeconds(time))
            strongSelf.startTimeLabel.text = strongSelf.createTimeString(time: timeElapsed)
            
            if strongSelf.isPlaying {
                strongSelf.timeSlider.value = timeElapsed
                strongSelf.playButton.isHidden = true
            }
        })
    }
    
    private func removeObservers(for playerItem: AVPlayerItem) {
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), context: &DKPlayerViewKVOContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &DKPlayerViewKVOContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), context: &DKPlayerViewKVOContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), context: &DKPlayerViewKVOContext)
        self.player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: &DKPlayerViewKVOContext)
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserverToken = self.timeObserverToken {
            self.player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    @objc func itemDidPlayToEndTime(notification: Notification) {
        if (notification.object as? AVPlayerItem) == self.player.currentItem {
            self.isFinishedPlaying = true
            self.playButton.isHidden = false
        }
    }
    
    // Update our UI when player or `player.currentItem` changes.
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &DKPlayerViewKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.duration) {
            // Update timeSlider and enable/disable controls when duration > 0.0
            
            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            } else {
                #if swift(>=4.2)
                newDuration = CMTime.zero
                #else
                newDuration = kCMTimeZero
                #endif
            }
            
            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
            let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
            self.timeSlider.maximumValue = Float(newDurationSeconds)
            self.timeSlider.value = currentTime
            
            self.playPauseButton.isEnabled = hasValidDuration
            self.timeSlider.isEnabled = hasValidDuration
            
            self.startTimeLabel.isEnabled = hasValidDuration
            self.startTimeLabel.text = createTimeString(time: currentTime)
            
            self.durationLabel.isEnabled = hasValidDuration
            self.durationLabel.text = self.createTimeString(time: Float(newDurationSeconds))
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            guard let currentItem = object as? AVPlayerItem else { return }
            guard self.autoPlayOrShowErrorOnce else { return }
            
            // Display an error if status becomes `.Failed`.
            
            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            #if swift(>=4.2)
            let newStatus: AVPlayerItem.Status
            #else
            let newStatus: AVPlayerItemStatus
            #endif
            
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                #if swift(>=4.2)
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                #else
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
                #endif
            } else {
                newStatus = .unknown
            }
            
            if newStatus == .readyToPlay {
                self.play()
                
                self.autoPlayOrShowErrorOnce = false
            } else if newStatus == .failed {
                if let error = currentItem.error {
                    self.showPlayError(error.localizedDescription)
                } else {
                    self.showPlayError(DKPhotoGalleryResource.localizedStringWithKey("preview.player.error.unknown"))
                }
                
                self.autoPlayOrShowErrorOnce = false
            }
        } else if keyPath == #keyPath(AVPlayer.rate) {
            // Update UI status.
            let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue
            
            if newRate == 1.0 {
                self.startHidesControlTimerIfNeeded()
                self.playPauseButton.isSelected = true
            } else {
                self.stopHidesControlTimer()
                self.playPauseButton.isSelected = false
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            self.updateBufferingIndicatorStateIfNeeded()
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            self.updateBufferingIndicatorStateIfNeeded()
        }
    }

}
