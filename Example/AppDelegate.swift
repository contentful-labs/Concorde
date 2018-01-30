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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = UIColor.white
        self.window!.rootViewController = UIViewController()
        self.window!.makeKeyAndVisible()

        let nonProgressiveImageView = CCBufferedImageView(frame: self.window!.bounds)
        nonProgressiveImageView.frame.size.width /= 2
        self.window!.rootViewController!.view.addSubview(nonProgressiveImageView)

        if let url = URL(string: "http://pooyak.com/p/progjpeg/jpegload.cgi?o=0") {
            nonProgressiveImageView.load(url)
        }

        let progressiveImageView = CCBufferedImageView(frame: self.window!.bounds)
        progressiveImageView.frame.origin.x = nonProgressiveImageView.frame.maxX
        progressiveImageView.frame.size.width /= 2
        self.window!.rootViewController!.view.addSubview(progressiveImageView)

        if let url = URL(string: "http://www.pooyak.com/p/progjpeg/jpegload.cgi?o=1") {
            progressiveImageView.load(url)
        }

        return true
    }
}
