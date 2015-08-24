//
//  CinemaPlay.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 8/21/15.
//  Copyright (c) 2015 Aphelion. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreGraphics


public class Cinema: UIView {


    // KVO contexts
    private var PlayerObserverContext = 0
    private var PlayerItemObserverContext = 0
    private var PlayerLayerObserverContext = 0

    // KVO player keys
    private let PlayerTracksKey = "tracks"
    private let PlayerPlayableKey = "playable"
    private let PlayerDurationKey = "duration"
    private let PlayerRateKey = "rate"

    // KVO player item keys
    private let PlayerStatusKey = "status"
    private let PlayerEmptyBufferKey = "playbackBufferEmpty"
    private let PlayerKeepUp = "playbackLikelyToKeepUp"

    // KVO player layer keys
    private let PlayerReadyForDisplay = "readyForDisplay"

//    var player: AVPlayer!
//    var playerLayer: AVPlayerLayer!
    var playerItem: AVPlayerItem!
    var asset: AVAsset!

    internal var playbackState: PlaybackState!
    internal var bufferingState: BufferingState!
//    public var fillMode: String!

    public var playbackFreezesAtEnd: Bool!
    public var playbackLoops: Bool!
    public var muted: Bool!

    var clipArray : [Clip] = []

    var finalClip : Clip! {
        didSet {
            setupAsset(self.finalClip.asset)
        }
    }

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

    var fillMode: String! {
        get {
            return (self.layer as! AVPlayerLayer).videoGravity
        }
        set {
            (self.layer as! AVPlayerLayer).videoGravity = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.player = AVPlayer()
        self.playerLayer.backgroundColor = UIColor.blackColor().CGColor!
        self.player.addObserver(self, forKeyPath: PlayerRateKey, options: (NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old) , context: &PlayerObserverContext)

        self.muted = false
        self.playbackLoops = false
        self.playbackFreezesAtEnd = false

        self.player.actionAtItemEnd = .Pause
        self.playbackState = .Stopped
        self.bufferingState = .Unknown

        self.loadCinema()

//        self.playerLayer.backgroundColor = UIColor.blackColor().CGColor!
    }

    deinit {
        self.player = nil

        NSNotificationCenter.defaultCenter().removeObserver(self)

        self.layer.removeObserver(self, forKeyPath: PlayerReadyForDisplay, context: &PlayerLayerObserverContext)
        self.player.removeObserver(self, forKeyPath: PlayerRateKey, context: &PlayerObserverContext)

        self.player.pause()
        self.setupPlayerItem(nil)
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }

    private func loadCinema() {
        self.fillMode = AVLayerVideoGravityResizeAspect
        self.playerLayer.hidden = true
        self.layer.addObserver(self, forKeyPath: PlayerReadyForDisplay, options: (NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old), context: &PlayerLayerObserverContext)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())
    }



    // MARK: methods
    public func createClip(url: NSURL) {
        let clip = Clip(url: url)

        self.clipArray.append(clip)
        self.mergeClip()
        //        self.finalClip = clip
    }

    public func playFromBeginning() {
        self.player.seekToTime(kCMTimeZero)
        self.playFromCurrentTime()
    }

    public func playFromCurrentTime() {
        self.playbackState = .Playing
        self.player.play()
    }

    public func pause() {
        if self.playbackState != .Playing {
            return
        }

        self.player.pause()
        self.playbackState = .Paused
    }

    public func stop() {
        if self.playbackState == .Stopped {
            return
        }

        self.player.pause()
        self.playbackState = .Stopped
    }

    //Private Functionality
    private func mergeClip() {
        print("================= Merging =================\n")

        var composition = AVMutableComposition()
        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        var insertTime = kCMTimeZero

        for clip in clipArray {
            
            //Video Track
            trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, clip.asset.duration), ofTrack: clip.videoTrack, atTime: insertTime, error: nil)

            //Audio Track
            trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, clip.asset.duration), ofTrack: clip.audioTrack, atTime: insertTime, error: nil)

            insertTime = CMTimeAdd(insertTime, clip.asset.duration)
        }

        //Exporting
        exportComposition(composition)
    }

    private func exportComposition(composition: AVMutableComposition) {

        var exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter.outputURL = getPath()
        exporter.outputFileType = AVFileTypeMPEG4 //AVFileTypeQuickTimeMovie
        exporter.exportAsynchronouslyWithCompletionHandler({
            switch exporter.status{
            case  AVAssetExportSessionStatus.Failed:
                println("================= Export Failed \(exporter.error) =================")
            case AVAssetExportSessionStatus.Cancelled:
                println("================= Export Cancelled \(exporter.error) =================")
            default:
                println("================= Complete =================")
                self.exportDidFinish(exporter)
            }
        })
    }

    private func exportDidFinish(session: AVAssetExportSession) {
        print("================= Finishing Export =================\n")
        finalClip = Clip(url: session.outputURL)
    }

    // MARK: private setup

    private func setupAsset(asset: AVAsset) {
        //Pauses Cinema while loading a new asset
        if self.playbackState == .Playing {
            self.pause()
        }

        self.bufferingState = .Unknown
        self.asset = asset

        //If new asset is the same as old asset, no change occurs
        if let updatedAsset = self.asset {
            self.setupPlayerItem(nil)
        }

        let keys: [String] = [PlayerTracksKey, PlayerPlayableKey, PlayerDurationKey]

        //Sets up the observation pattern to determine when the asset can be played
        self.asset.loadValuesAsynchronouslyForKeys(keys, completionHandler: { () -> Void in
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in

                for key in keys {
                    var error: NSError?
                    let status = self.asset.statusOfValueForKey(key, error:&error)
                    if status == .Failed {
                        self.playbackState = .Failed
                        return
                    }
                }
                //Breaks & returns if the asset is not playable
                if self.asset.playable.boolValue == false {
                    self.playbackState = .Failed
                    return
                }

                //If the asset IS playable, we create a playerItem & move forward
                let playerItem: AVPlayerItem = AVPlayerItem(asset:self.asset)
                self.setupPlayerItem(playerItem)

            })
        })
    }

    private func setupPlayerItem(playerItem: AVPlayerItem?) {
        //If the playerItem is passed nil, we remove the observation pattern
        if self.playerItem != nil {
            self.playerItem?.removeObserver(self, forKeyPath: PlayerEmptyBufferKey, context: &PlayerItemObserverContext)
            self.playerItem?.removeObserver(self, forKeyPath: PlayerKeepUp, context: &PlayerItemObserverContext)
            self.playerItem?.removeObserver(self, forKeyPath: PlayerStatusKey, context: &PlayerItemObserverContext)

            NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemFailedToPlayToEndTimeNotification, object: self.playerItem)
        }

        self.playerItem = playerItem

        //Likewise, if the playerItem has a value, we add the observation pattern to it
        if self.playerItem != nil {
            self.playerItem?.addObserver(self, forKeyPath: PlayerEmptyBufferKey, options: (NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old), context: &PlayerItemObserverContext)
            self.playerItem?.addObserver(self, forKeyPath: PlayerKeepUp, options: (NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old), context: &PlayerItemObserverContext)
            self.playerItem?.addObserver(self, forKeyPath: PlayerStatusKey, options: (NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old), context: &PlayerItemObserverContext)

            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemFailedToPlayToEndTime:", name: AVPlayerItemFailedToPlayToEndTimeNotification, object: self.playerItem)
        }
        //Sets the new playerItem to Cinema
        self.player.replaceCurrentItemWithPlayerItem(self.playerItem)

        if self.playbackLoops.boolValue == true {
            self.player.actionAtItemEnd = .None
        } else {
            self.player.actionAtItemEnd = .Pause
        }
    }

    // MARK: NSNotifications
    public func playerItemDidPlayToEndTime(aNotification: NSNotification) {
        //Rewinds the player to 0 and plays again if settings are set to Loop
        if self.playbackLoops.boolValue == true || self.playbackFreezesAtEnd.boolValue == true {
            self.player.seekToTime(kCMTimeZero)
        }
        //Stops AVPlayer if the settings are configured to play only once
        if self.playbackLoops.boolValue == false {
            self.stop()
        }
    }

    public func playerItemFailedToPlayToEndTime(aNotification: NSNotification) {
        self.playbackState = .Failed
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
                    default:
                        true
                }

            case (PlayerEmptyBufferKey, &PlayerItemObserverContext):
                if let item = self.playerItem {
                    if item.playbackBufferEmpty {
                        self.bufferingState = .Delayed
                    }
                }

                let status = (change[NSKeyValueChangeNewKey] as! NSNumber).integerValue as AVPlayerStatus.RawValue

                switch (status) {
                case AVPlayerStatus.ReadyToPlay.rawValue:
                    self.playerLayer.player = self.player
                    self.playerLayer.hidden = false
                case AVPlayerStatus.Failed.rawValue:
                    self.playbackState = PlaybackState.Failed
                default:
                    true
                }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}

extension Cinema {
//    private var projector : Projector
    internal func getPath() -> NSURL? {
        let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
        let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
        if let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true) {
            if paths.count > 0 {
                if let dirPath = paths[0] as? String {
                    let writePath = dirPath.stringByAppendingPathComponent("movie.mp4")
                    let url : NSURL! = NSURL.fileURLWithPath(writePath)
                    removeFile(url)
                    return url
                }
            }
        }
        return nil
    }

    internal func removeFile(url: NSURL) {
        var filePath : String! = url.path
        var manager : NSFileManager = NSFileManager.new()
        if manager.fileExistsAtPath(filePath) {
            var error : NSErrorPointer = NSErrorPointer()
            if manager.removeItemAtPath(filePath, error: error) == false {
                print("================= Remove File \(filePath) failed with \(error) =================")
            }
        }
    }
}

internal enum PlaybackState: Int, Printable {
    case Stopped = 0, Playing, Paused, Failed

    internal var description: String {
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

internal enum BufferingState: Int, Printable {
    case Unknown = 0
    case Ready
    case Delayed

    internal var description: String {
        get {
            switch self {
            case Unknown: return "Unknown"
            case Ready: return "Ready"
            case Delayed: return "Delayed"
            }
        }
    }
}


struct Audio {

    var csURL : NSURL
    var asset : AVAsset
    var duration : CMTime
    var title : String = ""
    var artist : String = ""

    init(url: NSURL) {
        csURL = url
        asset = AVAsset.assetWithURL(url) as! AVAsset
        duration = asset.duration
    }

}

struct Clip {

    var csURL : NSURL
    var asset : AVAsset
    var videoTrack : AVAssetTrack?
    var audioTrack : AVAssetTrack?
    var orientation : String = ""
    var thumbnail : CGImage!
    var duration: CMTime = CMTimeMakeWithSeconds(0, 0) {
        didSet {
            //            durationSet = true
        }
    }

    init(url: NSURL) {
        csURL = url
        asset = AVAsset.assetWithURL(url) as! AVAsset
        thumbnail = createImage(asset)
        orientation = detectOrientation(asset)
        duration = asset.duration

        var tracks = self.asset.tracksWithMediaType(AVMediaTypeVideo)
        var audios = self.asset.tracksWithMediaType(AVMediaTypeAudio)

        if tracks.count > 0 {
            self.videoTrack = tracks[0] as? AVAssetTrack
            self.audioTrack = audios[0] as? AVAssetTrack
        }
    }

    private func createImage(asset: AVAsset) -> CGImage {
        let imageGenerator = AVAssetImageGenerator(asset: asset);
        let time = CMTimeMakeWithSeconds(1.0, 1)
        var actualTime : CMTime = CMTimeMake(0, 0)
        var error : NSError?
        imageGenerator.appliesPreferredTrackTransform = true
        return imageGenerator.copyCGImageAtTime(time, actualTime: &actualTime, error: &error)
    }

    private func detectOrientation(asset: AVAsset) -> String {
        let tracks : [AnyObject] = asset.tracksWithMediaType(AVMediaTypeVideo)
        let avTrack : AVAssetTrack = tracks[0] as! AVAssetTrack
        let avTrackSize = avTrack.naturalSize;
        var avTrackRect = CGRectMake(0.0, 0.0, avTrackSize.width, avTrackSize.height)
        avTrackRect = CGRectApplyAffineTransform(avTrackRect, avTrack.preferredTransform);

        var orientation : String = ""

        if (avTrackRect.height > avTrackRect.width) {
            print("================= Asset Orientation: Portrait ================= \n")
            orientation = "Portrait"
        }
        else if (avTrackRect.height < avTrackRect.width) {
            print("================= Asset Orientation: Landscape ================= \n")
            orientation = "Landscape"
        }
        else {
            print("================= Asset Orientation: Square ================= \n")
            orientation = "Square"
        }
        
        return orientation
    }
}


//        //Audio Track
//        if (audio != nil) {
//            var audioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
//            audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, totalTime), ofTrack: audio.asset.tracksWithMediaType(AVMediaTypeAudio)[0] as! AVAssetTrack, atTime: kCMTimeZero, error: nil)
//        }

//internal class Projector {
//
//    var playerLayer: AVPlayerLayer!
//
//    var player: AVPlayer!
//
//    public var playbackState: PlaybackState!
//    public var bufferingState: BufferingState!
//
//}
