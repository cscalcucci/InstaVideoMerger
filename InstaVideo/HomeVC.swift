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

class HomeVC: UIViewController, UIScrollViewDelegate {

@IBOutlet weak var playBtn: UIImageView!
@IBOutlet weak var audioLabel: UILabel!
@IBOutlet weak var cinema: UIView!
@IBOutlet weak var clipScroll: UIScrollView!
@IBOutlet weak var clipView: UIView!
@IBOutlet var collectionOfButtons: [UIButton]!

    //Misc Properties
    var clipScroller : UIScrollView!

    var audioSet : Bool!

    var watermark : UIImage!
    var player : Player!

    var audioAsset : AVAsset?

    var clipArray : [AVAsset] = [] {
        didSet {
            self.createButtonScroller()
            self.merge()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.audioLabel.text = ""

        self.watermark = UIImage(named: "DoneBtn")

//        let attributes = [
//            NSForegroundColorAttributeName: UIColor.whiteColor(),
//            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!
//        ]

        let navString = NSMutableAttributedString(string: "INSTAVIDEOMERGE", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!])

        navString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 196/255, green: 225/255, blue: 2/255, alpha: 1.0), range: NSRange(location:5,length:5))

        let navLabel = UILabel()
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
            case 1: addClip(); break //Add Clip
            case 2: addClip(); break //Record Clip
            case 3: addAudio(); break //Add Audio
            case 4: break //Watermark
            case 5: performSegueWithIdentifier("upgradeSegue", sender: nil); break //Upgrades
            case 6: finishVideo(); break //Finished
        default: break
        }
    }

    func addClip() {
        if savedPhotosAvailable() {
            startMediaBrowserFromViewController(self, usingDelegate: self)
        }
    }

    func recordClip() {
    }

    func finishVideo() {
        switch self.clipArray.count {
        case 0 : finishError()
        default : finishSheet()
        }
    }

    func createImage(asset: AVAsset) -> UIImage {

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

    //Adds clips to a scroll view
    func createButtonScroller() {

        var maxX: CGFloat = 0

        for (var i = 0; i < self.clipArray.count; i++) {

            let x = CGFloat(i)

            let clip = self.clipArray[i]
            let thumbnail = createImage(clip)

            let clipFrame = CGRectMake((x * 120) + (x * 30) + 5, (clipScroll.bounds.size.height - 80) / 2, 120, 80)

            let clipBtn = UIButton(frame: clipFrame)
                clipBtn.setTitle("", forState: .Normal)
                clipBtn.tag = i
                clipBtn.setBackgroundImage(thumbnail, forState: .Normal)
                clipBtn.addTarget(self, action: "clipTapped:", forControlEvents: .TouchUpInside)

            clipScroll.addSubview(clipBtn)

            maxX = CGRectGetMaxX(clipFrame)
        }
        
        clipScroll.contentSize = CGSizeMake(maxX, clipScroll.frame.height)
    }

    func clipTapped(sender: UIButton) {

        let clip = self.clipArray[sender.tag]

        let player = AVPlayer(playerItem: AVPlayerItem(asset: clip))
        let playerController = AVPlayerViewController()

        playerController.player = player
        self.addChildViewController(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        
        player.play()
    }

    func addAudio() {

        let picker = MPMediaPickerController(mediaTypes: MPMediaType.AnyAudio)
            picker.delegate = self
            picker.showsCloudItems = false
            picker.allowsPickingMultipleItems = false

        self.presentViewController(picker, animated: true, completion: nil)
    }


    //New
    func savedPhotosAvailable() -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) == false {
            let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            return false
        }
        return true
    }

    func startMediaBrowserFromViewController(viewController: UIViewController!, usingDelegate delegate : protocol<UINavigationControllerDelegate, UIImagePickerControllerDelegate>) -> Bool {

        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) == false {
            return false
        }

        let mediaUI = UIImagePickerController()
            mediaUI.sourceType = .SavedPhotosAlbum
            mediaUI.mediaTypes = [kUTTypeMovie as NSString as String]
            mediaUI.allowsEditing = true
            mediaUI.delegate = delegate

        presentViewController(mediaUI, animated: true, completion: nil)

        return true
    }

    //Handles the pausing/playing of the clip
    func playClip(sender: UITapGestureRecognizer) {

        switch (player.playbackState.description) {
            case "Playing":
                player.pause()
                self.playBtn.hidden = false
                print("================ Paused Player =============")
                break
            case "Paused":
                player.playFromCurrentTime()
                self.playBtn.hidden = true
                print("================ Playing From Current =============")
                break
            case "Stopped":
                player.playFromBeginning()
                self.playBtn.hidden = true
                print("================ Playing From Beginning =============")
                break
            default : break
            }
    }

    func merge() {
//        activitySpinner.startAnimating()

        let mixComposition = AVMutableComposition()

        let track = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        let trackAudio = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

        var insertTime = kCMTimeZero
        var instructions : [AVMutableVideoCompositionLayerInstruction] = []
        var videoSize = CGSize()

        // Creating Tracks from Clips
        for (var i = 0; i < (clipArray.count); i++) {

            let clip = clipArray[i]

            print("CLIP COUNT IS \(clipArray.count) and I is \(i)")

            do {
                try track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, clip.duration),
                    ofTrack: clip.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: insertTime)

                //Audio Track
                if (audioAsset == nil) {

                    try trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, clip.duration),
                        ofTrack: clip.tracksWithMediaType(AVMediaTypeAudio)[0],
                        atTime: insertTime)
                }

                let instruction = videoCompositionInstructionForTrack(track, asset: clip)
                instructions.append(instruction)

            } catch _ {
                print("error")
            }

            insertTime = CMTimeAdd(insertTime, clip.duration)

            if i == 0 {
                videoSize = track.naturalSize
            }

        }

        // Setting the Audio track if user selected custom audio
        if let loadedAudioAsset = audioAsset {

            let audioTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)

            do {
                try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, insertTime),
                    ofTrack: loadedAudioAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                    atTime: kCMTimeZero)
            } catch _ {

            }
        }

                //Code to use a text instead of an image for watermark
                //        CATextLayer *titleLayer = [CATextLayer layer];
                //        titleLayer.string = @"Text goes here";
                //        titleLayer.font = @"Helvetica";
                //        titleLayer.fontSize = videoSize.height / 6;
                //        //?? titleLayer.shadowOpacity = 0.5;
                //        titleLayer.alignmentMode = kCAAlignmentCenter;
                //        titleLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height / 6); //You may need to adjust this for proper display


        let watermarkLayer = CALayer()
            watermarkLayer.contents = self.watermark.CGImage
            watermarkLayer.frame = CGRectMake(5, 5, 57, 57)
            watermarkLayer.opacity = 0.65

        let videoLayer = CALayer()
            videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)

        let parentLayer = CALayer()
            parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(watermarkLayer)
            //parentLayer.addSublayer(titleLayer) //ONLY IF WE ADDED TEXT

        let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, insertTime)
            mainInstruction.layerInstructions = instructions

        let mainComposition = AVMutableVideoComposition()
            mainComposition.instructions = [mainInstruction]
            mainComposition.frameDuration = CMTimeMake(1, 30)
            mainComposition.renderSize = videoSize
            mainComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
          //mainComposition.renderSize = CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)

        // Creating the Exporter
        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter!.outputURL = getPath()
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
        exporter!.shouldOptimizeForNetworkUse = true
        exporter!.videoComposition = mainComposition

        // Performing the Export
        exporter!.exportAsynchronouslyWithCompletionHandler() {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in

                switch exporter!.status{
                    case  AVAssetExportSessionStatus.Failed:
                        print("================= Export Failed \(exporter!.error) =================")
                    case AVAssetExportSessionStatus.Cancelled:
                        print("================= Export Cancelled \(exporter!.error) =================")
                    default:
                        print("================= Complete =================")
                        self.exportDidFinish(exporter!)
                }
            })
        }
    }

    //Legacy code commented out that instantly saves the video
    func exportDidFinish(session: AVAssetExportSession) {

        if session.status == AVAssetExportSessionStatus.Completed {

            self.player.setUrl(session.outputURL!)

//            let outputURL = session.outputURL
//            let outputString = outputURL!.relativePath
//
//            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputString!)) {
//
//                print("Test")
//
//                UISaveVideoAtPathToSavedPhotosAlbum(outputString!, self,
//                    "image:didFinishSavingWithError:contextInfo:", nil)
//            } else {
//
//                print("Cannot Save to Camera Roll")
//            }

        }

//        activitySpinner.stopAnimating()
    }

    func getPath() -> NSURL? {

        let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .ShortStyle

        let date = dateFormatter.stringFromDate(NSDate())
        let writePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("movie-\(date).mov")

        removeFile(writePath)

        return writePath
    }
    
    func removeFile(url: NSURL) {
        let filePath : String! = url.path
        let manager : NSFileManager = NSFileManager()

        if manager.fileExistsAtPath(filePath) {
    
            do {
                try manager.removeItemAtPath(filePath)
            } catch {
                print("================= Remove File \(filePath) failed with error \(error) =================")
            }
        }
    }

    func image(image: UIImage, didFinishSavingWithError
        error: NSErrorPointer, contextInfo:UnsafePointer<Void>) {

            var title = ""
            var message = ""

            if error != nil {
                title = "Error"
                message = "Failed to save video"
            } else {
                title = "Success"
                message = "Video saved"
            }

            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
    }

    //Disabled while I figure out wtf is going wrong
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {

        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
//        let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]

//        let transform = assetTrack.preferredTransform
        //        let assetInfo = orientationFromTransform(transform)
        //
        //        var scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.width
        //
        //        if assetInfo.isPortrait {
        //            scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.height
        //            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
        //            instruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor),
        //                atTime: kCMTimeZero)
        //        } else {
        //            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
        //            var concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor), CGAffineTransformMakeTranslation(0, UIScreen.mainScreen().bounds.width / 2))
        //            if assetInfo.orientation == .Down {
        //                let fixUpsideDown = CGAffineTransformMakeRotation(CGFloat(M_PI))
        //                let windowBounds = UIScreen.mainScreen().bounds
        //                let yFix = assetTrack.naturalSize.height + windowBounds.height
        //                let centerFix = CGAffineTransformMakeTranslation(assetTrack.naturalSize.width, yFix)
        //                concat = CGAffineTransformConcat(CGAffineTransformConcat(fixUpsideDown, centerFix), scaleFactor)
        //            }
        //            instruction.setTransform(concat, atTime: kCMTimeZero)
        //        }

        return instruction
    }

    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {

        var assetOrientation = UIImageOrientation.Up
        var isPortrait = false

        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
        }
        return (assetOrientation, isPortrait)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        let backItem = UIBarButtonItem()
            backItem.title = "Back"

        navigationItem.backBarButtonItem = backItem
    }


    //Will change boilerplate with data from edited videos
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

    func finishError() {

        let finishAlert = UIAlertController(title: "Error",
                                          message: "You must add a video before finishing!",
                                   preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "OK",
                                         style: .Cancel) { (action) in
            // ...
        }

        finishAlert.addAction(cancelAction)

        self.presentViewController(finishAlert, animated: true, completion: nil)

    }

    func destroyAlert() {

        let destroyAlert = UIAlertController(title: "Start Over",
                                           message: "Erase video and start over?",
                                    preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .Cancel) { (action) in
            // ...
        }

        let confirmAction = UIAlertAction(title: "Confirm",
                                          style: .Destructive) { (action) in
            // ...
        }

        destroyAlert.addAction(cancelAction)
        destroyAlert.addAction(confirmAction)

        self.presentViewController(destroyAlert, animated: true, completion: nil)

    }

    func finishSheet() {

        let finishSheet = UIAlertController(title: nil,
                                          message: nil,
                                   preferredStyle: .ActionSheet)

        let deleteAction = UIAlertAction(title: "Start Over", style: .Destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            self.destroyAlert()
            print("Start Over")
        })

        let galleryAction = UIAlertAction(title: "Save to Gallery", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("File Saved")
        })

        let facebookAction = UIAlertAction(title: "Post to Facebook", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Posted to Facebook")
        })

        let instagramAction = UIAlertAction(title: "Post to Instagram", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Posted to Instagram")
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })

        finishSheet.addAction(galleryAction)
        finishSheet.addAction(facebookAction)
        finishSheet.addAction(instagramAction)
        finishSheet.addAction(deleteAction)
        finishSheet.addAction(cancelAction)
        
        self.presentViewController(finishSheet, animated: true, completion: nil)
        
    }

    //Legacy code for custom audio information

//    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
//
//        var tmpItem = mediaItemCollection.items[0] as? MPMediaItem
//        let item : MPMediaItem! = tmpItem!
//        //Makes sure the item is local and not iCloud
//        var strCloud = item.valueForProperty(MPMediaItemPropertyIsCloudItem) as! NSNumber.BooleanLiteralType
//
//        //            print("\(strCloud)=================================\n")
//
//        if tmpItem != nil && !strCloud  {
//
//            //Finding path to make the asset
//            if let itemUrl = item.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL {
//                print("================ URL is \(itemUrl) =================\n")
//                self.audio = Audio(url: itemUrl)
//                self.audioSet = true
//                print("================ Title is \((item!.valueForProperty(MPMediaItemPropertyTitle) as? String)!) =================\n")
//                audio.title = (item!.valueForProperty(MPMediaItemPropertyTitle) as? String)!
//                print("================ Artist is \((item!.valueForProperty(MPMediaItemPropertyArtist) as? String)!) =================\n")
//                audio.artist = (item!.valueForProperty(MPMediaItemPropertyArtist) as? String)!
//                self.audioLabel.text = "\(audio.title) by \(audio.artist)"
//                mediaPicker.dismissViewControllerAnimated(true, completion: nil)
//                //                    mergeClip()
//
//            } else {
//                //Error notifying that the song isn't local
//                let alert = UIAlertController(title: "Error", message: "Not Valid Audio", preferredStyle: .Alert)
//                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in self.addAudio()}
//                alert.addAction(cancelAction)
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
//
//            //Trawling metadata
//            //                let itemTitle = item!.valueForProperty(MPMediaItemPropertyTitle) as? String
//            //                let itemArtist = item!.valueForProperty(MPMediaItemPropertyArtist) as? String
//            //                let itemArtwork = item!.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork
//            //                print("Media Title \(itemTitle)\n Media Artist \(itemArtist) \n Media Artwork \(itemArtwork)")
//
//        } else {
//            //Error notifying that the song isn't local
//            let alert = UIAlertController(title: "Error", message: "Not Valid Audio", preferredStyle: .Alert)
//            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in self.addAudio()}
//            alert.addAction(cancelAction)
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
//    }
//
//    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController!) {
//        self.dismissViewControllerAnimated(true, completion: {})
//    }
}

extension HomeVC: UIImagePickerControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        dismissViewControllerAnimated(true, completion: nil)

        if mediaType == kUTTypeMovie {

            let avAsset = AVAsset(URL: info[UIImagePickerControllerMediaURL] as! NSURL)
            let message = "Video Successfully Loaded"

            //            if loadingAssetOne {
            //                message = "Video one loaded"
            //                firstAsset = avAsset
            //            } else {
            //                message = "Video two loaded"
            //                secondAsset = avAsset
            //            }

            self.clipArray.append(avAsset)

            let alert = UIAlertController(title: "Asset Loaded", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }

}

extension HomeVC: UINavigationControllerDelegate {

}

extension HomeVC: MPMediaPickerControllerDelegate {

    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {

        let selectedSongs = mediaItemCollection.items

        if selectedSongs.count > 0 {
            let song = selectedSongs[0]
            if let url = song.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL {
                audioAsset = AVAsset(URL: url)
                dismissViewControllerAnimated(true, completion: nil)
                let alert = UIAlertController(title: "Asset Loaded", message: "Audio Loaded", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
                presentViewController(alert, animated: true, completion: nil)
            } else {
                dismissViewControllerAnimated(true, completion: nil)
                let alert = UIAlertController(title: "Asset Not Available", message: "Audio Not Loaded", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
                presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}




