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


@IBOutlet weak var playerView: UIView!
@IBOutlet weak var clipScroll: UIScrollView!
@IBOutlet weak var clipView: UIView!
@IBOutlet weak var movieView: Cinema!
@IBOutlet var collectionOfButtons: [UIButton]!

    //Misc Properties
    var clipAmt = 0
    var clipScroller : UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        createButtons()

        let tap = UITapGestureRecognizer(target: self, action: Selector("playClip:"))
        movieView.addGestureRecognizer(tap)

    }

//    override func viewDidLayoutSubviews() {
//        playerLayer = AVPlayerLayer(player: player)
//        playerLayer.frame = movieView.bounds
//        movieView.layer.addSublayer(playerLayer)
//    }

    //Rounding buttons and setting attributes
    func createButtons() {
        for btn in collectionOfButtons {
            btn.removeFromSuperview()
            btn.setTitle("", forState: .Normal)
            btn.frame = CGRectMake(btn.frame.width, btn.frame.height, 65, 65)
            btn.layer.cornerRadius = 0.5 * btn.frame.width
            btn.backgroundColor = .redColor()
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
            case 5: break //Upgrades
            case 6: didFinish(); break //Finished
        default: break
        }
    }

    func didFinish() {
//        let cinema = Cinema()
//        cinema.frame = self.view.bounds
//        cinema.path = "movie.mp4"
//        self.view.addSubview(cinema)
    }

    //Adds clips to a scroll view
    func createButtonScroller() {

        var maxX: CGFloat = 0
        var i : CGFloat = 0

        for clip in movieView.clipArray {

            let clip = movieView.clipArray[Int(i)]

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

//            var tmpItem = mediaItemCollection.items[0] as? MPMediaItem
//            let item : MPMediaItem! = tmpItem!
//            //Makes sure the item is local and not iCloud
//            var strCloud = item.valueForProperty(MPMediaItemPropertyIsCloudItem) as! NSNumber.BooleanLiteralType
//
////            print("\(strCloud)=================================\n")
//
//            if tmpItem != nil && !strCloud  {
//
//                    //Finding path to make the asset
//                if let itemUrl = item.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL {
//                    print("================ URL is \(itemUrl) =================\n")
////                    self.audio = Audio(url: itemUrl)
//                    print("================ Title is \((item!.valueForProperty(MPMediaItemPropertyTitle) as? String)!) =================\n")
//                    audio.title = (item!.valueForProperty(MPMediaItemPropertyTitle) as? String)!
//                    print("================ Artist is \((item!.valueForProperty(MPMediaItemPropertyArtist) as? String)!) =================\n")
//                    audio.artist = (item!.valueForProperty(MPMediaItemPropertyArtist) as? String)!
//                    mediaPicker.dismissViewControllerAnimated(true, completion: nil)
//
//                } else {
//                        //Error notifying that the song isn't local
//                    let alert = UIAlertController(title: "Error", message: "Not Valid Audio", preferredStyle: .Alert)
//                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in self.addAudio()}
//                    alert.addAction(cancelAction)
//                    self.presentViewController(alert, animated: true, completion: nil)
//                }
//
//                //Trawling metadata
////                let itemTitle = item!.valueForProperty(MPMediaItemPropertyTitle) as? String
////                let itemArtist = item!.valueForProperty(MPMediaItemPropertyArtist) as? String
////                let itemArtwork = item!.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork
////                print("Media Title \(itemTitle)\n Media Artist \(itemArtist) \n Media Artwork \(itemArtwork)")
//
//            } else {
//                //Error notifying that the song isn't local
//                let alert = UIAlertController(title: "Error", message: "Not Valid Audio", preferredStyle: .Alert)
//                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in self.addAudio()}
//                    alert.addAction(cancelAction)
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
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

//        movieView.createClip(assetUrl!)

        //Saves video to Camera Roll
//        UISaveVideoAtPathToSavedPhotosAlbum(pathString, self, nil, nil)

    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: {})
    }

    func clipTapped(sender: UIButton) {
//        let clip = movieView.clipArray[sender.tag]

        let avPlayer : AVPlayerViewController = AVPlayerViewController.new()
        avPlayer.player = AVPlayer(playerItem: AVPlayerItem(asset: clip.asset))
        presentViewController(avPlayer, animated: true, completion: nil)
    }

    //Handles the pausing/playing of the clip
    func playClip(sender: UITapGestureRecognizer) {

        switch (movieView.playbackState.description) {
            case "Playing": movieView.pause(); break;
            case "Paused": movieView.playFromCurrentTime(); break;
            case "Stopped": movieView.playFromBeginning(); break;
            default : break
        }
    }
}



