//
//  AssetModel.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 11/17/15.
//  Copyright © 2015 Aphelion. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import MediaPlayer
import AVKit

struct Audio {

    var csURL : NSURL
    var asset : AVAsset
    var audioTrack : AVAssetTrack?
    var duration : CMTime
    var title : String = ""
    var artist : String = ""

    init(url: NSURL) {
        csURL = url
        asset = AVAsset(URL: url)
        duration = asset.duration

        var audios = self.asset.tracksWithMediaType(AVMediaTypeAudio)

        if audios.count > 0 {
            self.audioTrack = audios[0]
        }

    }
}

struct Clip {

    var csURL : NSURL
    var asset : AVAsset
    var videoTrack : AVAssetTrack?
    var audioTrack : AVAssetTrack?
    var orientation : String = ""
    var thumbnail : UIImage!
    var duration: CMTime = CMTimeMakeWithSeconds(0, 0) {
        didSet {
            //            durationSet = true
        }
    }

    init(url: NSURL) {
        csURL = url
        asset = AVAsset(URL: url)
        thumbnail = createImage(asset)
        orientation = detectOrientation(asset)
        duration = asset.duration

        var tracks = self.asset.tracksWithMediaType(AVMediaTypeVideo)
        var audios = self.asset.tracksWithMediaType(AVMediaTypeAudio)

        if tracks.count > 0 {
            videoTrack = tracks[0]
            audioTrack = audios[0]
        }
    }

    private func createImage(asset: AVAsset) -> UIImage {

        var img = UIImage(named: "")
        let imageGenerator = AVAssetImageGenerator(asset: asset);
        let time = CMTimeMakeWithSeconds(1.0, 1)

        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImg = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            img = UIImage(CGImage: cgImg)

        } catch {
            print(error)
        }
        return img!
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
        } else {
            print("================= Asset Orientation: Square ================= \n")
            orientation = "Square"
        }
        
        return orientation
    }
    
}
