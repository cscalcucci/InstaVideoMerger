//
//  Cinema.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 8/20/15.
//  Copyright (c) 2015 Aphelion. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreGraphics

enum PlaybackState: Int, Printable {
    case Stopped = 0, Playing, Paused, Failed

    var description: String {
        get {
            switch self {
            case Stopped: return "Stopped"
            case Playing: return "Playing"
            case Failed: return "Failed"
            case Paused: return "Paused"
            }
        }
    }
}

enum BufferingState: Int, Printable {
    case Unknown = 0
    case Ready
    case Delayed

    var description: String {
        get {
            switch self {
            case Unknown: return "Unknown"
            case Ready: return "Ready"
            case Delayed: return "Delayed"
            }
        }
    }
}

//public protocol CinemaDelegate {
//    func playerReady(player: Cinema)
//    func playerPlaybackStateDidChange(player: Cinema)
//    func playerBufferingStateDidChange(player: Cinema)
//    func playerPlaybackWillStartFromBeginning(player: Cinema)
//    func playerPlaybackDidEnd(player: Cinema)
//}

// KVO contexts
var PlayerObserverContext = 0 //private
var PlayerItemObserverContext = 0 //private
var PlayerLayerObserverContext = 0 //private

// KVO player keys
let PlayerTracksKey = "tracks" //private
let PlayerPlayableKey = "playable" //private
let PlayerDurationKey = "duration" //private
let PlayerRateKey = "rate" //private

// KVO player item keys
let PlayerStatusKey = "status" //private
let PlayerEmptyBufferKey = "playbackBufferEmpty" //private
let PlayerKeepUp = "playbackLikelyToKeepUp" //private

// KVO player layer keys
let PlayerReadyForDisplay = "readyForDisplay" //private


public class Cinema: UIView {

//    public var delegate: CinemaDelegate!

    var filepath: String!
    var path: String! {
        get {
            return filepath
        }
        set {
            // Make sure everything is reset beforehand
            if(self.playbackState == .Playing){
                self.pause()
            }

            self.setupPlayerItem(nil)

            filepath = newValue
            var remoteUrl: NSURL? = NSURL(string: newValue)
            if remoteUrl != nil && remoteUrl?.scheme != nil {
                if let asset = AVURLAsset(URL: remoteUrl, options: .None) {
                    self.setupAsset(asset)
                }
            } else {
                var localURL: NSURL? = NSURL(fileURLWithPath: newValue)
                if let asset = AVURLAsset(URL: localURL, options: .None) {
                    self.setupAsset(asset)
                }
            }
        }
    }

    var muted: Bool! {
        get {
            return self.player.muted
        }
        set {
            self.player.muted = newValue
        }
    }


    var playbackLoops: Bool! {
        get {
            return (self.player.actionAtItemEnd == .None) as Bool
        }
        set {
            if newValue.boolValue {
                self.player.actionAtItemEnd = .None
            } else {
                self.player.actionAtItemEnd = .Pause
            }
        }
    }

    var playbackFreezesAtEnd: Bool!
    var playbackState: PlaybackState!
    var bufferingState: BufferingState!

    var maximumDuration: NSTimeInterval! {
        get {
            if let playerItem = self.playerItem {
                return CMTimeGetSeconds(playerItem.duration)
            } else {
                return CMTimeGetSeconds(kCMTimeIndefinite)
            }
        }
    }

    var asset: AVAsset! //Private
    var playerItem: AVPlayerItem? //Private
//    var player: AVPlayer! //Private

    //View Properties
    var player: AVPlayer! {
        get {
            return (self.layer as! AVPlayerLayer).player
        }
        set {
            (self.layer as! AVPlayerLayer).player = newValue
        }
    }

    var playerLayer: AVPlayerLayer! {
        get {
            return self.layer as! AVPlayerLayer
        }
    }

    public var fillMode: String! {
        get {
            return (self.layer as! AVPlayerLayer).videoGravity
        }
        set {
            (self.layer as! AVPlayerLayer).videoGravity = newValue
        }
    }

    override public class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }

    // MARK: object lifecycle

    convenience init() {
        self.init(frame: CGRectZero)
        self.playerLayer.backgroundColor = UIColor.blackColor().CGColor!
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.playerLayer.backgroundColor = UIColor.blackColor().CGColor!
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: Public Functions

    public func playFromBeginning() {
//        self.delegate?.playerPlaybackWillStartFromBeginning(self)
        self.player.seekToTime(kCMTimeZero)
        self.playFromCurrentTime()
    }

    public func playFromCurrentTime() {
        self.playbackState = .Playing
//        self.delegate?.playerPlaybackStateDidChange(self)
        self.player.play()
    }

    public func pause() {
        if self.playbackState != .Playing {
            return
        }

        self.player.pause()
        self.playbackState = .Paused
//        self.delegate?.playerPlaybackStateDidChange(self)
    }

    public func stop() {
        if self.playbackState == .Stopped {
            return
        }

        self.player.pause()
        self.playbackState = .Stopped
//        self.delegate?.playerPlaybackStateDidChange(self)
//        self.delegate?.playerPlaybackDidEnd(self)
    }

    // MARK: Private Setup

    private func setupAsset(asset: AVAsset) {
        if self.playbackState == .Playing {
            self.pause()
        }

        self.bufferingState = .Unknown
//        self.delegate?.playerBufferingStateDidChange(self)

        self.asset = asset
        if let updatedAsset = self.asset {
            self.setupPlayerItem(nil)
        }

        let keys: [String] = [PlayerTracksKey, PlayerPlayableKey, PlayerDurationKey]

        self.asset.loadValuesAsynchronouslyForKeys(keys, completionHandler: { () -> Void in
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in

                for key in keys {
                    var error: NSError?
                    let status = self.asset.statusOfValueForKey(key, error:&error)
                    if status == .Failed {
                        self.playbackState = .Failed
//                        self.delegate?.playerPlaybackStateDidChange(self)
                        return
                    }
                }

                if self.asset.playable.boolValue == false {
                    self.playbackState = .Failed
//                    self.delegate?.playerPlaybackStateDidChange(self)
                    return
                }

                let playerItem: AVPlayerItem = AVPlayerItem(asset:self.asset)
                self.setupPlayerItem(playerItem)

            })
        })
    }

    private func setupPlayerItem(playerItem: AVPlayerItem?) {
        if self.playerItem != nil {
            self.playerItem?.removeObserver(self, forKeyPath: PlayerEmptyBufferKey, context: &PlayerItemObserverContext)
            self.playerItem?.removeObserver(self, forKeyPath: PlayerKeepUp, context: &PlayerItemObserverContext)
            self.playerItem?.removeObserver(self, forKeyPath: PlayerStatusKey, context: &PlayerItemObserverContext)

            NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemFailedToPlayToEndTimeNotification, object: self.playerItem)
        }

        self.playerItem = playerItem

        if self.playerItem != nil {
            self.playerItem?.addObserver(self, forKeyPath: PlayerEmptyBufferKey, options: (NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old), context: &PlayerItemObserverContext)
            self.playerItem?.addObserver(self, forKeyPath: PlayerKeepUp, options: (NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old), context: &PlayerItemObserverContext)
            self.playerItem?.addObserver(self, forKeyPath: PlayerStatusKey, options: (NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old), context: &PlayerItemObserverContext)

            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemFailedToPlayToEndTime:", name: AVPlayerItemFailedToPlayToEndTimeNotification, object: self.playerItem)
        }

        self.player.replaceCurrentItemWithPlayerItem(self.playerItem)
        
        if self.playbackLoops.boolValue == true {
            self.player.actionAtItemEnd = .None
        } else {
            self.player.actionAtItemEnd = .Pause
        }
    }

    // MARK: NSNotifications

    public func playerItemDidPlayToEndTime(aNotification: NSNotification) {
        if self.playbackLoops.boolValue == true || self.playbackFreezesAtEnd.boolValue == true {
            self.player.seekToTime(kCMTimeZero)
        }

        if self.playbackLoops.boolValue == false {
            self.stop()
        }
    }

    public func playerItemFailedToPlayToEndTime(aNotification: NSNotification) {
        self.playbackState = .Failed
//        self.delegate?.playerPlaybackStateDidChange(self)
    }

    public func applicationWillResignActive(aNotification: NSNotification) {
        if self.playbackState == .Playing {
            self.pause()
        }
    }

    public func applicationDidEnterBackground(aNotification: NSNotification) {
        if self.playbackState == .Playing {
            self.pause()
        }
    }

    // MARK: KVO

    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {

        switch (keyPath, context) {
        case (PlayerRateKey, &PlayerObserverContext):
            true
        case (PlayerStatusKey, &PlayerItemObserverContext):
            true
        case (PlayerKeepUp, &PlayerItemObserverContext):
            if let item = self.playerItem {
                self.bufferingState = .Ready
//                self.delegate?.playerBufferingStateDidChange(self)

                if item.playbackLikelyToKeepUp && self.playbackState == .Playing {
                    self.playFromCurrentTime()
                }
            }

            let status = (change[NSKeyValueChangeNewKey] as! NSNumber).integerValue as AVPlayerStatus.RawValue

            switch (status) {
            case AVPlayerStatus.ReadyToPlay.rawValue:
                self.playerLayer.player = self.player
                self.playerLayer.hidden = false
            case AVPlayerStatus.Failed.rawValue:
                self.playbackState = PlaybackState.Failed
//                self.delegate?.playerPlaybackStateDidChange(self)
            default:
                true
            }
        case (PlayerEmptyBufferKey, &PlayerItemObserverContext):
            if let item = self.playerItem {
                if item.playbackBufferEmpty {
                    self.bufferingState = .Delayed
//                    self.delegate?.playerBufferingStateDidChange(self)
                }
            }

            let status = (change[NSKeyValueChangeNewKey] as! NSNumber).integerValue as AVPlayerStatus.RawValue

            switch (status) {
            case AVPlayerStatus.ReadyToPlay.rawValue:
                self.playerLayer.player = self.player
                self.playerLayer.hidden = false
            case AVPlayerStatus.Failed.rawValue:
                self.playbackState = PlaybackState.Failed
//                self.delegate?.playerPlaybackStateDidChange(self)
            default:
                true
            }
        case (PlayerReadyForDisplay, &PlayerLayerObserverContext):
            if self.playerLayer.readyForDisplay {
//                self.delegate?.playerReady(self)
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)

        }

    }
}


