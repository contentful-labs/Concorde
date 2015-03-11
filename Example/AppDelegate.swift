//
//  AppDelegate.swift
//  Example
//
//  Created by Boris Bügling on 11/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import Concorde
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()
        self.window!.rootViewController = UIViewController()
        self.window!.makeKeyAndVisible()

        let nonProgressiveImageView = CCBufferedImageView(frame: self.window!.bounds)
        nonProgressiveImageView.backgroundColor = UIColor.redColor()
        nonProgressiveImageView.frame.size.width /= 2
        self.window!.rootViewController!.view.addSubview(nonProgressiveImageView)

        if let url = NSURL(string: "http://pooyak.com/p/progjpeg/jpegload.cgi?o=0") {
            nonProgressiveImageView.load(url)
        }

        let progressiveImageView = CCBufferedImageView(frame: self.window!.bounds)
        progressiveImageView.backgroundColor = UIColor.greenColor()
        progressiveImageView.frame.origin.x = nonProgressiveImageView.frame.maxX
        progressiveImageView.frame.size.width /= 2
        self.window!.rootViewController!.view.addSubview(progressiveImageView)

        if let url = NSURL(string: "http://www.pooyak.com/p/progjpeg/jpegload.cgi?o=1") {
            progressiveImageView.load(url)
        }

        return true
    }
}
