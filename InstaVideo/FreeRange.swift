//
//  FreeRange.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 8/30/15.
//  Copyright (c) 2015 Aphelion. All rights reserved.
//

import UIKit
import QuartzCore

class FreeRange: UIControl {

    //Metrics for minimum and maximum amounts
//    var minimumValue = 0.0
//    var maximumValue = 100.0
    var minimumValue = -4.0
    var maximumValue = 105.0

    //Starting positions for thumbs
    var lowerValue = 0.0
    var upperValue = 100.0

    //Minimum distance between the two thumbs
    var minDistance = 0.0

    var lowerBounds = 0.0
    var upperBounds = 100.0

    var trackMask : CGRect!
    var track : UIImageView!

    var lowerThumb : ThumbView!
    var upperThumb : ThumbView!

    var thumbWidth: CGFloat!
    var thumbHeight: CGFloat!

    var previousLocation = CGPoint()

    var background : Background!

//    override var frame: CGRect {
//        didSet {
//            updateLayerFrames()
////            self.background.frame = self.frame
//        }
//    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        //Default background for Revealed track
        self.background = Background(frame: CGRectMake(0, 0, self.frame.width, self.frame.height / 2))
        self.background.freeRange = self
        self.background.alpha = 0.3
        self.addSubview(self.background)

        //Default ratio for Freestyle slider
        self.thumbHeight = self.background.frame.height * 1.75
        self.thumbWidth = self.background.frame.width * (1/14)

        self.backgroundColor = UIColor.clearColor()

        self.track = UIImageView(frame: self.background.frame)
        self.addSubview(track)
        self.bringSubviewToFront(track)

        self.lowerThumb = ThumbView(frame: CGRectMake(0, 0, thumbWidth, thumbHeight))
        self.lowerThumb.freeRange = self
        self.addSubview(lowerThumb)
        self.bringSubviewToFront(lowerThumb)

        upperThumb = ThumbView(frame: CGRectMake(0, 0, thumbWidth, thumbHeight))
        upperThumb.freeRange = self
        self.addSubview(upperThumb)
        self.bringSubviewToFront(upperThumb)

        updateLayerFrames()

    }

    required init(coder: NSCoder) {
        super.init(coder: coder)!
    }

    func maskTrack() {
        let maskLayer = CAShapeLayer()
        let path : CGPathRef = CGPathCreateWithRect(self.trackMask, nil)
        maskLayer.path = path
        self.track.layer.mask = maskLayer
    }

    func updateLayerFrames(){

        let lowerThumbCenter = CGFloat(positionForValue(lowerValue))
        let upperThumbCenter = CGFloat(positionForValue(upperValue))

        self.trackMask = CGRectMake(lowerThumbCenter, 0, upperThumbCenter - lowerThumbCenter, self.bounds.height)
        maskTrack()

        lowerThumb.frame = CGRectMake((lowerThumbCenter - thumbWidth / 2.0), 0.0, thumbWidth, thumbHeight)

        upperThumb.frame = CGRectMake((upperThumbCenter - thumbWidth / 2.0), 0.0, thumbWidth, thumbHeight)

    }

    func positionForValue(value: Double) -> Double {
        return Double(bounds.width - thumbWidth) * (value - minimumValue) /
            (maximumValue - minimumValue) + Double(thumbWidth / 2.0)
    }

    override func beginTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) -> Bool {

        previousLocation = touch!.locationInView(self)

        // Hit test the thumb layers
        if lowerThumb.frame.contains(previousLocation) {
            lowerThumb.highlighted = true
        } else if upperThumb.frame.contains(previousLocation) {
            upperThumb.highlighted = true
        }

        return lowerThumb.highlighted || upperThumb.highlighted
    }

    //Keeps the updated upper/lower values within range
    func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        return min(max(value, lowerValue), upperValue)
    }

    override func continueTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) -> Bool {
        let location = touch!.locationInView(self)

        // 1. Determine by how much the user has dragged
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - thumbWidth)

        previousLocation = location

        if deltaValue > 1.0 || deltaValue < -1.0 {

        // 2. Update the values
        if lowerThumb.highlighted {
            //lowerValue
            lowerValue += deltaValue
            lowerValue = boundValue(lowerValue, toLowerValue: lowerBounds, upperValue: upperValue - minDistance)
        } else if upperThumb.highlighted {
            upperValue += deltaValue
            upperValue = boundValue(upperValue, toLowerValue: lowerValue + minDistance, upperValue: upperBounds)
        }
            // 3. Update the UI
            updateLayerFrames()

            sendActionsForControlEvents(.ValueChanged)

        }

        return true
    }

    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        lowerThumb.highlighted = false
        upperThumb.highlighted = false
    }
    
}

internal class Background : UIView {

    var overlay : UIView?
    var overlayAlpha : CGFloat = 0.3
    var overlayColor : UIColor? = nil {
        didSet {
            self.overlay = UIView(frame: self.frame)
            self.overlay!.backgroundColor = self.overlayColor
            self.overlay!.alpha = self.overlayAlpha
        }
    }

    var imageView : UIImageView!
    var image : UIImage! {
        didSet {
            self.imageView.image = self.image
        }
    }

    weak var freeRange : FreeRange?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.imageView = UIImageView(frame: self.frame)
        self.image = UIImage()
        self.addSubview(imageView)
        self.bringSubviewToFront(imageView)

        self.userInteractionEnabled = false
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

}

internal class ThumbView: UIView {

    var highlighted = false

    var imageView : UIImageView!
    var image : UIImage! {
        didSet {
            self.imageView.image = self.image
        }
    }
    var highlightedImage : UIImageView!

    weak var freeRange: FreeRange?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.imageView = UIImageView(frame: self.frame)
        self.addSubview(imageView)
        self.bringSubviewToFront(imageView)
        self.userInteractionEnabled = false
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
