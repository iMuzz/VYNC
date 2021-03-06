//
//  File.swift
//  VYNC
//
//  Created by Thomas Abend on 1/18/15.
//  Copyright (c) 2015 Thomas Abend. All rights reserved.
//
import UIKit
import CoreMedia
import CoreData
import MobileCoreServices
import AVKit
import AVFoundation

//let standin = "https://s3-us-west-2.amazonaws.com/telephono/IMG_0370.MOV"
let path = NSBundle.mainBundle().pathForResource("IMG_0370", ofType:"MOV")
let standin = NSURL.fileURLWithPath(path!) as NSURL!

class VyncListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {

    @IBOutlet var vyncTable: UITableView!
    var refreshControl:UIRefreshControl!
    
//    Setting this equal to a global variable that is an array of vyncs. This will later be replaced by a function return from a dB query.
    var vyncs = vyncList
    var videoPlayer : QueueLoopVideoPlayer?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib

        let color = UIColor(netHex:0x73A1FF)
        let font = [NSFontAttributeName: UIFont(name: "Egypt 22", size: 50)!, NSForegroundColorAttributeName: color]
        self.navigationController!.navigationBar.titleTextAttributes = font
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Camera, target: self, action: "showCam")
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
        
//        let leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "showCam")
//        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refersh")
        self.refreshControl.addTarget(self, action: "reloadVyncs", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl.layer.zPosition = -1
        self.vyncTable.addSubview(refreshControl)
        self.vyncTable.rowHeight = 70
        vyncTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vyncs.count
    }
    
    @IBAction func reloadVyncs() {
        self.refreshControl.beginRefreshing()
        println("reloading Vyncs")
        self.refreshControl.endRefreshing()
    }
    
    // Set the properties of cells
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("VyncCell", forIndexPath: indexPath) as VyncCell

        addGesturesToCell(cell)
       //        Set Title and Length Labels
        cell.titleLabel.text = vyncs[indexPath.row].title()
        cell.lengthLabel.text = vyncs[indexPath.row].size()
        
        // New vyncs get special color and gesture
        if vyncs[indexPath.row].waitingOnYou() {
            cell.statusLogo.textColor = UIColor(netHex:0xFFB5C9)
            cell.subTitle.text = "January 14 - Swipe to Reply"
        } else {
            cell.subTitle.text = "January 14 - Hold to Play"
//            cell.statusLogo.textColor = UIColor(netHex:0xD9FF85)
            cell.statusLogo.textColor = UIColor(netHex:0x7FF2FF)
        }
        
        // Unwatched vyncs get special background color
        if vyncs[indexPath.row].unwatched {
            let color = UIColor(netHex: 0xD3D3D3)
            cell.backgroundColor = color
        } else {
            cell.backgroundColor = UIColor.whiteColor()
        }

        return cell
    }
    
    func addGesturesToCell(cell:UITableViewCell){
        // long touch for playback
        let longTouch = UILongPressGestureRecognizer()
        longTouch.addTarget(self, action: "holdToPlayVideos:")
        cell.addGestureRecognizer(longTouch)
        
        let singleTap = UITapGestureRecognizer(target: self, action: "singleTapCell:")
        singleTap.numberOfTapsRequired = 1
        
        let doubleTap = UITapGestureRecognizer(target:self, action: "doubleTapCell:")
        doubleTap.numberOfTapsRequired = 2
        
        cell.addGestureRecognizer(singleTap)
        cell.addGestureRecognizer(doubleTap)
        singleTap.requireGestureRecognizerToFail(doubleTap)
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if vyncs[indexPath.row].waitingOnYou(){
            return true
        } else {
            return false
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let replyClosure = { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            self.reply(indexPath.row)
        }
        
        let reply = UITableViewRowAction(
            style: UITableViewRowActionStyle.Normal,
            title: "REPLY",
            handler: replyClosure
            )
        reply.backgroundColor = UIColor(netHex: 0xFFB5C9)
        return [reply]
    }
    
    
    @IBAction func holdToPlayVideos(sender: UILongPressGestureRecognizer) {

        if sender.state == .Began {
            let index = self.vyncTable.indexPathForRowAtPoint(sender.view!.center)?.row
            println("Playing Videos)")
            vyncs[index!].unwatched = false
            let urls = vyncs[index!].videoUrls()
            println(urls)
            
            self.videoPlayer = QueueLoopVideoPlayer()
            self.videoPlayer!.view.addGestureRecognizer(sender)
            self.videoPlayer!.videoList = urls + urls
            self.videoPlayer!.playVideos()
            self.presentViewController(self.videoPlayer!, animated: false, completion:nil)
        }
        if sender.state == .Ended {
            println("Dismissing PlayerLayer")
            self.videoPlayer?.stop()
            self.view.addGestureRecognizer(sender)
            self.vyncTable.reloadData()
            self.vyncTable.setNeedsDisplay()
        }
    }
    
    func singleTapCell(sender:UITapGestureRecognizer){
        println("single tapped")
        let indexPath = self.vyncTable.indexPathForRowAtPoint(sender.view!.center)?
        if let cell = vyncTable.cellForRowAtIndexPath(indexPath!) as? VyncCell {
            cell.selectCellAnimation()
        }

    }
    
    func doubleTapCell(sender:UITapGestureRecognizer){
        let indexPath:NSIndexPath = self.vyncTable.indexPathForRowAtPoint(sender.view!.center)!
        if let cell = vyncTable.cellForRowAtIndexPath(indexPath) as? VyncCell {
            if cell.isFlipped {
                let view = self.view.viewWithTag(19)
                cell.isFlipped = false
                UIView.transitionFromView(
                    view!,
                    toView: cell.contentView,
                    duration: 0.66,
                    options: UIViewAnimationOptions.TransitionFlipFromBottom,
                    completion: nil
                )
            } else {
                let viewHeight = Int(cell.frame.height)
                let viewWidth = Int(cell.frame.width)
                let view = UIView(frame:CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight))
                let label = UILabel()
                label.frame = view.frame
                
                let labelText = ", ".join(vyncs[indexPath.row].usersList())
                label.text = "Users on this Vync: \(labelText)"
                
                view.addSubview(label)
                view.tag = 19
                cell.isFlipped = true
                UIView.transitionFromView(
                    cell.contentView,
                    toView: view,
                    duration: 0.66,
                    options: UIViewAnimationOptions.TransitionFlipFromTop,
                    completion: {
                        finished in
                        //                    Auto flip back after 4 seconds
                        delay(4){
                            if cell.isFlipped {
                                self.doubleTapCell(sender)
                            }
                        }
                    }
                )
            }
        }
    }

    
    func reply(index:Int){
        println("showing Reply Camera")
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
        let camera = self.storyboard?.instantiateViewControllerWithIdentifier("Camera") as VyncCameraViewController
        camera.vync = vyncs[index]
        self.presentViewController(camera, animated: false, completion: nil)
    }

    @IBAction func showCam() {
        println("showing Camera")
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
        let camera = self.storyboard?.instantiateViewControllerWithIdentifier("Camera") as VyncCameraViewController

        self.presentViewController(camera, animated: false, completion: nil)
    }
    
   

}
