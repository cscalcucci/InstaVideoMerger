//
//  HomeVC.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 8/14/15.
//  Copyright (c) 2015 Aphelion. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import MediaPlayer
import AVKit

class HomeVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, MPMediaPickerControllerDelegate {

@IBOutlet weak var playBtn: UIImageView!
@IBOutlet weak var audioLabel: UILabel!
@IBOutlet weak var cinema: UIView!
@IBOutlet weak var clipScroll: UIScrollView!
@IBOutlet weak var clipView: UIView!
@IBOutlet var collectionOfButtons: [UIButton]!

    //Misc Properties
    var clipAmt = 0
    var clipScroller : UIScrollView!

    var clipArray : [Clip] = []
    var finalClip : Clip!
    var selectedClip : Clip!
    var audio : Audio!
    var audioSet : Bool!

    var watermark : UIImage!

    var player : Player!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.audioLabel.text = ""

        self.watermark = UIImage(named: "DoneBtn")

        var attributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!
        ]

        var navString = NSMutableAttributedString(string: "INSTAVIDEOMERGE", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!])

        navString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 196/255, green: 225/255, blue: 2/255, alpha: 1.0), range: NSRange(location:5,length:5))

        var navLabel = UILabel()
        navLabel.attributedText = navString
        navLabel.sizeToFit()
        self.navigationItem.titleView = navLabel

        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.translucent = true

//        self.navigationController?.navigationBar.titleTextAttributes = attributes

        let tap = UITapGestureRecognizer(target: self, action: Selector("playClip:"))
        cinema.addGestureRecognizer(tap)

        self.audioSet = false

        createButtons()
    }

    override func viewDidLayoutSubviews() {

        self.player = Player()
        self.player.view.frame = self.cinema.bounds
        self.playBtn.frame = self.cinema.bounds

        self.addChildViewController(self.player)
        self.cinema.addSubview(self.player.view)
        self.cinema.bringSubviewToFront(self.playBtn)
        self.player.didMoveToParentViewController(self)
    }

    //Rounding buttons and setting attributes
    func createButtons() {
        for btn in collectionOfButtons {
            btn.removeFromSuperview()
            btn.frame = CGRectMake(btn.frame.width, btn.frame.height, 65, 65)
            btn.layer.cornerRadius = 0.5 * btn.frame.width
            btn.addTarget(self, action:"btnTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            view.addSubview(btn)
        }
    }

    //Single selector to handle all button taps based on tags in Storyboard
    func btnTapped(sender: UIButton) {
        switch sender.tag {
            case 0: break //+ & vidView
            case 1: addClip(false); break //Add Clip
            case 2: addClip(true); break //Record Clip
            case 3: addAudio(); break //Add Audio
            case 4: break //Watermark
            case 5: performSegueWithIdentifier("upgradeSegue", sender: nil); break //Upgrades
            case 6: finishVideo(); break //Finished
        default: break
        }
    }

    func finishVideo() {
        switch self.clipArray.count {
        case 0 : finishError()
        default : finishSheet()
        }
    }

    func finishError() {
        let finishAlert = UIAlertController(title: "Error", message: "You must add a video before finishing!", preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "OK", style: .Cancel) { (action) in
            // ...
        }

        finishAlert.addAction(cancelAction)

        self.presentViewController(finishAlert, animated: true, completion: nil)

    }

    func destroyAlert() {
        let destroyAlert = UIAlertController(title: "Start Over", message: "Erase video and start over?", preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // ...
        }

        let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive) { (action) in
            // ...
        }

        destroyAlert.addAction(cancelAction)
        destroyAlert.addAction(confirmAction)

        self.presentViewController(destroyAlert, animated: true, completion: nil)

    }

    func finishSheet() {
        let finishSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let deleteAction = UIAlertAction(title: "Start Over", style: .Destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            self.destroyAlert()
            println("Start Over")
        })

        let galleryAction = UIAlertAction(title: "Save to Gallery", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            println("File Saved")
        })

        let facebookAction = UIAlertAction(title: "Post to Facebook", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Posted to Facebook")
        })

        let instagramAction = UIAlertAction(title: "Post to Instagram", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Posted to Instagram")
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Cancelled")
        })

        finishSheet.addAction(galleryAction)
        finishSheet.addAction(facebookAction)
        finishSheet.addAction(instagramAction)
        finishSheet.addAction(deleteAction)
        finishSheet.addAction(cancelAction)

        self.presentViewController(finishSheet, animated: true, completion: nil)

    }

    func createClip(url: NSURL) {
        let clip = Clip(url: url)

        self.clipArray.append(clip)
        self.mergeClip()
        createButtonScroller()
    }

    //Adds clips to a scroll view
    func createButtonScroller() {

        var maxX: CGFloat = 0
        var i : CGFloat = 0

        for clip in self.clipArray {

            let clip = self.clipArray[Int(i)]

            var clipFrame = CGRectMake((i * 120) + (i * 30) + 5, (clipScroll.bounds.size.height - 80) / 2, 120, 80)

            let clipBtn = UIButton(frame: clipFrame)
            clipBtn.setTitle("", forState: .Normal)
            clipBtn.tag = (Int(i))
            clipBtn.setBackgroundImage(UIImage(CGImage: clip.thumbnail), forState: .Normal)
            clipBtn.addTarget(self, action: "clipTapped:", forControlEvents: .TouchUpInside)
            clipScroll.addSubview(clipBtn)

            maxX = CGRectGetMaxX(clipFrame)

            i++

        }
        clipScroll.contentSize = CGSizeMake(maxX, clipScroll.frame.height)
    }

    func addAudio() {
        let picker = MPMediaPickerController(mediaTypes: MPMediaType.AnyAudio)
        picker.delegate = self
        picker.showsCloudItems = false
        picker.allowsPickingMultipleItems = false
        [self .presentViewController(picker, animated: true, completion: nil)]
    }

    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {

            var tmpItem = mediaItemCollection.items[0] as? MPMediaItem
            let item : MPMediaItem! = tmpItem!
            //Makes sure the item is local and not iCloud
            var strCloud = item.valueForProperty(MPMediaItemPropertyIsCloudItem) as! NSNumber.BooleanLiteralType

//            print("\(strCloud)=================================\n")

            if tmpItem != nil && !strCloud  {

                    //Finding path to make the asset
                if let itemUrl = item.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL {
                    print("================ URL is \(itemUrl) =================\n")
                    self.audio = Audio(url: itemUrl)
                    self.audioSet = true
                    print("================ Title is \((item!.valueForProperty(MPMediaItemPropertyTitle) as? String)!) =================\n")
                    audio.title = (item!.valueForProperty(MPMediaItemPropertyTitle) as? String)!
                    print("================ Artist is \((item!.valueForProperty(MPMediaItemPropertyArtist) as? String)!) =================\n")
                    audio.artist = (item!.valueForProperty(MPMediaItemPropertyArtist) as? String)!
                    self.audioLabel.text = "\(audio.title) by \(audio.artist)"
                    mediaPicker.dismissViewControllerAnimated(true, completion: nil)
                    mergeClip()

                } else {
                        //Error notifying that the song isn't local
                    let alert = UIAlertController(title: "Error", message: "Not Valid Audio", preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in self.addAudio()}
                    alert.addAction(cancelAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                }

                //Trawling metadata
//                let itemTitle = item!.valueForProperty(MPMediaItemPropertyTitle) as? String
//                let itemArtist = item!.valueForProperty(MPMediaItemPropertyArtist) as? String
//                let itemArtwork = item!.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork
//                print("Media Title \(itemTitle)\n Media Artist \(itemArtist) \n Media Artwork \(itemArtwork)")

            } else {
                //Error notifying that the song isn't local
                let alert = UIAlertController(title: "Error", message: "Not Valid Audio", preferredStyle: .Alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in self.addAudio()}
                    alert.addAction(cancelAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
    }

    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController!) {
        self.dismissViewControllerAnimated(true, completion: {})
    }

    //Adds a clip to the VC, takes a BOOL to determine recordCamera/addLibrary
    func addClip(record: Bool) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.mediaTypes = [kUTTypeMovie]

        if record {
            picker.sourceType = .Camera
        } else {
            picker.sourceType = .PhotoLibrary
        }

        self.presentViewController(picker, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        self.dismissViewControllerAnimated(true, completion: {})

        //Preparing the path for the clip
        let tempImage = info[UIImagePickerControllerMediaURL] as! NSURL!
        let pathString = tempImage.relativePath
        let assetUrl =  NSURL.fileURLWithPath(pathString!)

        self.createClip(assetUrl!)

        //Saves video to Camera Roll
//        UISaveVideoAtPathToSavedPhotosAlbum(pathString, self, nil, nil)

    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: {})
    }

    func clipTapped(sender: UIButton) {
        self.selectedClip = self.clipArray[sender.tag]

        performSegueWithIdentifier("editSegue", sender: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editSegue" {
            let destinationVC : EditScreen = segue.destinationViewController as! EditScreen
            destinationVC.selectedClip = self.selectedClip
        }
    }

    //Handles the pausing/playing of the clip
    func playClip(sender: UITapGestureRecognizer) {
        if self.clipArray.count != 0 {
            self.playBtn.hidden = !self.playBtn.hidden
        }

        switch (player.playbackState.description) {
            case "Playing":
                player.pause()
                print("================Playing=============")
                break
            case "Paused":
                player.playFromCurrentTime()
                print("================Paused=============")
                break
            case "Stopped":
                player.playFromBeginning()
                print("================Stopped=============")
                break
            default : break
        }
    }

    func mergeClip() {
        print("================= Merging =================\n")

        var composition = AVMutableComposition()
        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        var insertTime = kCMTimeZero

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideo)
//        var instructions : [AnyObject] = []

        for clip in clipArray {

            //Video Track
            trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, clip.asset.duration), ofTrack: clip.videoTrack, atTime: insertTime, error: nil)

            //Transformation
            let transform : CGAffineTransform = clip.videoTrack!.preferredTransform
            layerInstruction.setTransform(transform, atTime: insertTime)

            //Audio Track
            if (audioSet == false) {
                trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, clip.asset.duration), ofTrack: clip.audioTrack, atTime: insertTime, error: nil)
            }

            insertTime = CMTimeAdd(insertTime, clip.asset.duration)
        }


        //Audio Track
        if (audioSet == true) {
            trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, insertTime), ofTrack: self.audio.audioTrack, atTime: kCMTimeZero, error: nil)
        }

        //Code to use a text instead of an image for watermark
        //        CATextLayer *titleLayer = [CATextLayer layer];
        //        titleLayer.string = @"Text goes here";
        //        titleLayer.font = @"Helvetica";
        //        titleLayer.fontSize = videoSize.height / 6;
        //        //?? titleLayer.shadowOpacity = 0.5;
        //        titleLayer.alignmentMode = kCAAlignmentCenter;
        //        titleLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height / 6); //You may need to adjust this for proper display

        let watermarkLayer = CALayer.new()
        watermarkLayer.contents = self.watermark.CGImage
        watermarkLayer.frame = CGRectMake(5, 5, 57, 57)
        watermarkLayer.opacity = 0.65

        let videoSize = trackVideo.naturalSize
        let parentLayer = CALayer.new()
        let videoLayer = CALayer.new()
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(watermarkLayer)
//        parentLayer.addSublayer(titleLayer) //ONLY IF WE ADDED TEXT

        let videoComp = AVMutableVideoComposition.new()
        videoComp.renderSize = videoSize
        videoComp.frameDuration = CMTimeMake(1, 30)
        //        videoComp.frameDuration = CMTimeMake(1, trackVideo.naturalTimeScale);
        videoComp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)

        let videoTrack = composition.tracksWithMediaType(AVMediaTypeVideo)
        let instruction = AVMutableVideoCompositionInstruction.new()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration)

        instruction.layerInstructions = [layerInstruction]
        videoComp.instructions = [instruction]

        //Exporting
        exportComposition(composition, video: videoComp)

    }

    func exportComposition(composition: AVMutableComposition, video: AVMutableVideoComposition?) {

        var exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter.videoComposition = video

        exporter.outputURL = getPath()
        exporter.outputFileType = AVFileTypeQuickTimeMovie //AVFileTypeQuickTimeMovie
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

    func exportDidFinish(session: AVAssetExportSession) {
        print("================= Finishing Export =================\n")
        self.finalClip = Clip(url: session.outputURL)
        self.player.path = "\(session.outputURL)"
    }

    func getPath() -> NSURL? {
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

    func removeFile(url: NSURL) {
        var filePath : String! = url.path
        var manager : NSFileManager = NSFileManager.new()
        if manager.fileExistsAtPath(filePath) {
            var error : NSErrorPointer = NSErrorPointer()
            if manager.removeItemAtPath(filePath, error: error) == false {
                print("================= Remove File \(filePath) failed with \(error) =================")
            }
        }
    }

    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {

//        if(segue.sourceViewController .isKindOfClass(ViewController2))
//        {
//            var view2:ViewController2 = segue.sourceViewController as ViewController2
//            let alert = UIAlertView()
//            alert.title = "UnwindSegue Data"
//            alert.message = view2.data
//            alert.addButtonWithTitle("Ok")
//            alert.show()
//        }
//        if(segue.sourceViewController .isKindOfClass(ViewController3))
//        {
//            var view3:ViewController3 = segue.sourceViewController as ViewController3
//            let alert = UIAlertView()
//            alert.title = "UnwindSegue Data"
//            alert.message = view3.data
//            alert.addButtonWithTitle("Ok")
//            alert.show()
//        }

    }

}

struct Audio {

    var csURL : NSURL
    var asset : AVAsset
    var audioTrack : AVAssetTrack?
    var duration : CMTime
    var title : String = ""
    var artist : String = ""

    init(url: NSURL) {
        csURL = url
        asset = AVAsset.assetWithURL(url) as! AVAsset
        duration = asset.duration

        var audios = self.asset.tracksWithMediaType(AVMediaTypeAudio)

        if audios.count > 0 {
            self.audioTrack = audios[0] as? AVAssetTrack
        }

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



