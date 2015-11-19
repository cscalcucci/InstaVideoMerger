//
//  EditScreen.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 8/30/15.
//  Copyright (c) 2015 Aphelion. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import MediaPlayer
import AVKit

class EditScreen: UIViewController {

@IBOutlet weak var movieView: UIView!

@IBOutlet weak var playBtn: UIImageView!
@IBOutlet weak var editView: UIView!
@IBOutlet weak var startTime: UILabel!
@IBOutlet weak var endTime: UILabel!

@IBOutlet weak var clipLength: UILabel!
@IBOutlet weak var videoLength: UILabel!

    var freeRange : FreeRange!
    var selectedClip : Clip!
    var totalSeconds : Double!

    var player : Player!

    var upperValue : Int!
    var lowerValue : Int!

    override func viewDidLoad() {
        super.viewDidLoad()

        let attributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!
        ]

        let navString = NSMutableAttributedString(string: "EDIT CLIP", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!])

        let navLabel = UILabel()
        navLabel.attributedText = navString
        navLabel.sizeToFit()
        self.navigationItem.titleView = navLabel

        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.translucent = true

        //Tap Gesture Recognizer to trigger play/pause
        let tap = UITapGestureRecognizer(target: self, action: Selector("playClip:"))
        movieView.addGestureRecognizer(tap)
//
//        let movieBG = CALayer.new()
//        movieBG.backgroundColor = UIColor.blackColor().CGColor!
//        movieBG.frame = CGRectMake(movieView.frame.width / 2, movieView.frame.height / 2, movieView.frame.width - 10, movieView.frame.height - 10)
//        movieView.layer.insertSublayer(movieBG, atIndex: 0)

        //Setup FreeRange
        self.freeRange = FreeRange(frame: CGRectMake(0, 40, 380, 100))

        self.freeRange.background.image = UIImage(named: "SliderBG")
        self.freeRange.track.image = UIImage(named: "SliderBG")
        self.freeRange.lowerThumb.image = UIImage(named: "LeftSlider")
        self.freeRange.upperThumb.image = UIImage(named: "RightSlider")

        self.freeRange.center.x = self.view.center.x
        self.editView.addSubview(freeRange)
        self.editView.bringSubviewToFront(freeRange)

        self.upperValue = Int(self.freeRange.upperValue)
        self.lowerValue = Int(self.freeRange.lowerValue)

        self.freeRange.addTarget(self, action:"dispatchedValue" , forControlEvents: UIControlEvents.ValueChanged)

    }

    override func viewDidLayoutSubviews() {

        self.player = Player()
        self.player.view.frame = playBtn.frame
        self.playBtn.frame = self.movieView.bounds

        self.player.setUrl(self.selectedClip.csURL)

        self.addChildViewController(self.player)
//        self.movieView.addSubview(self.player.view)
        self.movieView.bringSubviewToFront(self.playBtn)
        self.player.didMoveToParentViewController(self)

        self.totalSeconds = CMTimeGetSeconds(self.selectedClip.duration)

        self.endTime.text = setTime(1)

    }

    func dispatchedValue() {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.rangeSliderValueChanged(self.freeRange)

        })
    }

    func rangeSliderValueChanged(rangeSlider: FreeRange) {

        if self.upperValue != Int(rangeSlider.upperValue) {


            print("======== Upper Value Changed ======== \n")
            self.upperValue = Int(rangeSlider.upperValue)

            dispatch_async(dispatch_get_main_queue(), {

                let update = self.setTime(Double(self.upperValue) / 100.0)

                self.endTime.text = update


                print("\(self.endTime.text)")
            })
        }

//        } else if self.lowerValue != Int(rangeSlider.lowerValue) {
//            print("======== Lower Value Changed ========")
//            self.lowerValue = Int(rangeSlider.lowerValue)
//            self.startTime.text = setTime(Double(self.lowerValue) / 100.0)
//
//        }

    }

    func setTime(multiplier: Double) -> String {

        totalSeconds = totalSeconds * multiplier

        let xHours : Int = Int(floor(totalSeconds / 3600))
        let xMinutes : Int = Int(floor(totalSeconds % 3600 / 60))
        let xSeconds : Int = Int(floor(totalSeconds % 3600 % 60))
        let xMiliseconds : Int = Int(roundToPlaces((((totalSeconds % 3600) % 60) / 1000), places: 2))

        let yHours : String = formatTime(xHours)
        let yMinutes : String = formatTime(xMinutes)
        let ySeconds : String = formatTime(xSeconds)
        let yMiliseconds : String = formatTime(xMiliseconds)

//        print("========== Hours: \(yHours) ========== \n")
//        print("========== Minutes: \(yMinutes) ======== \n")
//        print("========== Seconds: \(ySeconds) ======== \n")
//        print("========== Miliseconds: \(yMiliseconds) ==== \n")

        return "\(yMinutes):\(ySeconds).\(yMiliseconds)"
    }

    func formatTime(time: Int) -> String {

        var timeString : String = "\(time)"

        switch time {
            case 0...9 : timeString = "0\(time)"; break
            default : break
        }

        return timeString
    }

    func roundToPlaces(value:Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(value * divisor) / divisor
    }

    func playClip(sender: UITapGestureRecognizer) {

        self.playBtn.hidden = !self.playBtn.hidden

        switch (player.playbackState.description) {
        case "Playing":
            player.pause()
            print("================Playing============= \n")
            break
        case "Paused":
            player.playFromCurrentTime()
            print("================Paused============= \n")
            break
        case "Stopped":
            player.playFromBeginning()
            print("================Stopped============= \n")
            break
        default : break
        }
    }

    @IBAction func btnPressed(sender: UIButton) {

        switch sender.tag {
            case 0:
                self.performSegueWithIdentifier("unwindToRoot", sender: self);
                break
            case 1:
                self.performSegueWithIdentifier("unwindToRoot", sender: self);
                break
            default: break
        }
    }
}

