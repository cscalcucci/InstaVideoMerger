//
//  UpgradesVC.swift
//  InstaVideo
//
//  Created by Christopher Scalcucci on 8/25/15.
//  Copyright (c) 2015 Aphelion. All rights reserved.
//

import UIKit
import Foundation

class UpgradesVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        let attributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!
        ]

        let navString = NSMutableAttributedString(string: "UPGRADES", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!])

        let navLabel = UILabel()
        navLabel.attributedText = navString
        navLabel.sizeToFit()
        self.navigationItem.titleView = navLabel

        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.translucent = true
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell : UpgradeCell = tableView.dequeueReusableCellWithIdentifier("upgradeCell") as! UpgradeCell

        cell.title.textColor = UIColor(red: 145/255, green: 18/255, blue: 79/255, alpha: 1.0)
        cell.priceBtn.setTitleColor(UIColor(red: 145/255, green: 18/255, blue: 79/255, alpha: 1.0), forState: .Normal)
        cell.background.backgroundColor = UIColor(red: 232/255, green: 232/255, blue: 232/255, alpha: 1.0)

        switch indexPath.row {
            case 0:
                print("=================Creating First Cell=================\n")
                print("=================Creating First Cell=================\n")
                print("=================Creating First Cell=================\n")
                cell.title.text = "ALL UPGRADES COMBO"
                cell.content.text = "Add Music + Unlimted Clips + Remove Watermark. Save 40%!"
                cell.priceBtn.setTitle("$2.99", forState: .Normal)
                cell.title.textColor = UIColor(red: 67/255, green: 36/255, blue: 98/255, alpha: 1.0)
                cell.priceBtn.setTitleColor(UIColor(red: 67/255, green: 36/255, blue: 98/255, alpha: 1.0), forState: .Normal)
                cell.background.backgroundColor = UIColor(red: 240/255, green: 232/255, blue: 206/255, alpha: 1.0)
                break
            case 1:
                cell.title.text = "Add Music From Library"
                cell.content.text = "Add music from your library as background music for your video."
                cell.priceBtn.setTitle("$1.99", forState: .Normal)
                break
            case 2:
                cell.title.text = "Unlimited Clips"
                cell.content.text = "Add as many clips as you want to your video."
                cell.priceBtn.setTitle("$1.99", forState: .Normal)
                break
            case 3:
                cell.title.text = "Remove/Replace Watermark"
                cell.content.text = "Remove the 'Insta Video Merge' watermark, or replace with your own."
                cell.priceBtn.setTitle("$0.99", forState: .Normal)
                break
            default: break
        }

        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //
    }

}

class UpgradeCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var priceBtn: UIButton!
    @IBOutlet weak var background: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
