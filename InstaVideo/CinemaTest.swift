//
//  CinemaTest.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 8/21/15.
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

public class Cinema: UIView {

    var playbackState: PlaybackState!
    var bufferingState: BufferingState!

    var filepath: String!

    var asset: AVAsset! //Private


    private var player: AVPlayer! {
        get {
            return (self.layer as! AVPlayerLayer).player
        }
        set {
            (self.layer as! AVPlayerLayer).player = newValue
        }
    }

    private var playerLayer: AVPlayerLayer! {
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

    // MARK: Init
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

    public func restart() {
        self.player.seekToTime(kCMTimeZero)
        self.play()
    }

    public func play() {
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


}
