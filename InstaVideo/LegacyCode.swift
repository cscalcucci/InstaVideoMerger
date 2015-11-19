//
//  LegacyCode.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 11/18/15.
//  Copyright © 2015 Aphelion. All rights reserved.
//

import Foundation



//    func createClip(url: NSURL) {
//
//        let clip = Clip(url: url)
//
//        self.clipArray.append(clip)
//        self.merge()
//        createButtonScroller()
//    }

//Adds a clip to the VC, takes a BOOL to determine recordCamera/addLibrary
//    func addClip(record: Bool) {
//        let picker = UIImagePickerController()
//        picker.delegate = self
//        picker.allowsEditing = true
//        picker.mediaTypes = [kUTTypeMovie]
//
//        if record {
//            picker.sourceType = .Camera
//        } else {
//            picker.sourceType = .PhotoLibrary
//        }
//
//        self.presentViewController(picker, animated: true, completion: nil)
//    }
//
//    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
//
//        self.dismissViewControllerAnimated(true, completion: {})
//
//        //Preparing the path for the clip
//        let tempImage = info[UIImagePickerControllerMediaURL] as! NSURL!
//        let pathString = tempImage.relativePath
//        let assetUrl =  NSURL.fileURLWithPath(pathString!)
//
//        self.createClip(assetUrl!)
//
//        //Saves video to Camera Roll
////        UISaveVideoAtPathToSavedPhotosAlbum(pathString, self, nil, nil)
//
//    }
//
//    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
//        self.dismissViewControllerAnimated(true, completion: {})
//    }

//    func clipTapped(sender: UIButton) {
//        self.selectedClip = self.clipArray[sender.tag]
//
//        performSegueWithIdentifier("editSegue", sender: nil)
//    }

//    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "editSegue" {
//            let destinationVC : EditScreen = segue.destinationViewController as! EditScreen
//            destinationVC.selectedClip = self.selectedClip
//        }
//    }

//    func mergeClip() {
//        print("================= Merging =================\n")
//
//        var composition = AVMutableComposition()
//        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
//        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
//        var insertTime = kCMTimeZero
//
//        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideo)
////        var instructions : [AnyObject] = []
//
//        for clip in clipArray {
//
//            //Video Track
//            trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, clip.asset.duration), ofTrack: clip.videoTrack, atTime: insertTime, error: nil)
//
//            //Transformation
//            let transform : CGAffineTransform = clip.videoTrack!.preferredTransform
//            layerInstruction.setTransform(transform, atTime: insertTime)
//
//            //Audio Track
//            if (audioSet == false) {
//                trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, clip.asset.duration), ofTrack: clip.audioTrack, atTime: insertTime, error: nil)
//            }
//
//            insertTime = CMTimeAdd(insertTime, clip.asset.duration)
//        }
//
//
//        //Audio Track
//        if (audioSet == true) {
//            trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, insertTime), ofTrack: self.audio.audioTrack, atTime: kCMTimeZero, error: nil)
//        }
//
//        //Code to use a text instead of an image for watermark
//        //        CATextLayer *titleLayer = [CATextLayer layer];
//        //        titleLayer.string = @"Text goes here";
//        //        titleLayer.font = @"Helvetica";
//        //        titleLayer.fontSize = videoSize.height / 6;
//        //        //?? titleLayer.shadowOpacity = 0.5;
//        //        titleLayer.alignmentMode = kCAAlignmentCenter;
//        //        titleLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height / 6); //You may need to adjust this for proper display
//
//        let watermarkLayer = CALayer.new()
//        watermarkLayer.contents = self.watermark.CGImage
//        watermarkLayer.frame = CGRectMake(5, 5, 57, 57)
//        watermarkLayer.opacity = 0.65
//
//        let videoSize = trackVideo.naturalSize
//        let parentLayer = CALayer.new()
//        let videoLayer = CALayer.new()
//        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
//        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
//        parentLayer.addSublayer(videoLayer)
//        parentLayer.addSublayer(watermarkLayer)
////        parentLayer.addSublayer(titleLayer) //ONLY IF WE ADDED TEXT
//
//        let videoComp = AVMutableVideoComposition.new()
//        videoComp.renderSize = videoSize
//        videoComp.frameDuration = CMTimeMake(1, 30)
//        //        videoComp.frameDuration = CMTimeMake(1, trackVideo.naturalTimeScale);
//        videoComp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
//
//        let videoTrack = composition.tracksWithMediaType(AVMediaTypeVideo)
//        let instruction = AVMutableVideoCompositionInstruction.new()
//        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration)
//
//        instruction.layerInstructions = [layerInstruction]
//        videoComp.instructions = [instruction]
//
//        //Exporting
//        exportComposition(composition, video: videoComp)
//
//    }
//
//    func exportComposition(composition: AVMutableComposition, video: AVMutableVideoComposition?) {
//
//        var exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
//        exporter.videoComposition = video
//
//        exporter.outputURL = getPath()
//        exporter.outputFileType = AVFileTypeQuickTimeMovie //AVFileTypeQuickTimeMovie
//        exporter.exportAsynchronouslyWithCompletionHandler({
//            switch exporter.status{
//            case  AVAssetExportSessionStatus.Failed:
//                println("================= Export Failed \(exporter.error) =================")
//            case AVAssetExportSessionStatus.Cancelled:
//                println("================= Export Cancelled \(exporter.error) =================")
//            default:
//                println("================= Complete =================")
//                self.exportDidFinish(exporter)
//            }
//        })
//    }
//
//    func exportDidFinish(session: AVAssetExportSession) {
//        print("================= Finishing Export =================\n")
//        self.finalClip = Clip(url: session.outputURL)
//        self.player.path = "\(session.outputURL)"
//    }
//
//    func getPath() -> NSURL? {
//        let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
//        let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
//        if let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true) {
//            if paths.count > 0 {
//                if let dirPath = paths[0] as? String {
//                    let writePath = dirPath.stringByAppendingPathComponent("movie.mp4")
//                    let url : NSURL! = NSURL.fileURLWithPath(writePath)
//                    removeFile(url)
//                    return url
//                }
//            }
//        }
//        return nil
//    }
//
//    func removeFile(url: NSURL) {
//        let filePath : String! = url.path
//        let manager : NSFileManager = NSFileManager()
//        if manager.fileExistsAtPath(filePath) {
//
//            do {
//                try manager.removeItemAtPath(filePath)
//            } catch {
//                print("================= Remove File \(filePath) failed with error \(error) =================")
//            }
//
//        }
//    }