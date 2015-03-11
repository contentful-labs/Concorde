//
//  CCBufferedImageView.swift
//  Concorde
//
//  Created by Boris Bügling on 11/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import UIKit

public class CCBufferedImageView : UIImageView, NSURLConnectionDataDelegate {
    private let defaultContentLength = 5 * 1024 * 1024
    private var data: NSMutableData?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public init(URL: NSURL) {
        super.init()

        load(URL)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func load(URL: NSURL) {
        NSURLConnection(request: NSURLRequest(URL: URL), delegate: self)
    }

    // MARK: NSURLConnectionDataDelegate

    public func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        NSLog("Error: %@", error)
    }

    public func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.data?.appendData(data)

        let decoder = CCBufferedImageDecoder(data: self.data)
        decoder.decompress()
        image = decoder.toImage()
    }

    public func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        var contentLength = Int(response.expectedContentLength)
        if contentLength < 0 {
            contentLength = defaultContentLength
        }

        data = NSMutableData(capacity: contentLength)
    }

    public func connectionDidFinishLoading(connection: NSURLConnection) {
        data = nil
    }
}
