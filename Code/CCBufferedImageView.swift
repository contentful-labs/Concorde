//
//  CCBufferedImageView.swift
//  Concorde
//
//  Created by Boris Bügling on 11/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import UIKit

/// A subclass of UIImageView which displays a JPEG progressively while it is downloaded
public class CCBufferedImageView : UIImageView, NSURLConnectionDataDelegate {
    private weak var connection: NSURLConnection?
    private let defaultContentLength = 5 * 1024 * 1024
    private var data: NSMutableData?
    private let queue = dispatch_queue_create("com.contentful.Concorde", DISPATCH_QUEUE_SERIAL)

    /// Optional handler which is called after an image has been successfully downloaded
    public var loadedHandler: (() -> ())?

    deinit {
        connection?.cancel()
    }

    /// Initialize a new image view with the given frame
    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.grayColor()
    }

    /// Initialize a new image view and start loading a JPEG from the given URL
    public init(URL: NSURL) {
        super.init(image: nil)

        backgroundColor = UIColor.grayColor()
        load(URL)
    }

    /// Required initializer, not implemented
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Load a JPEG from the given URL
    public func load(URL: NSURL) {
        connection?.cancel()
        connection = NSURLConnection(request: NSURLRequest(URL: URL), delegate: self)
    }

    // MARK: NSURLConnectionDataDelegate

    /// see NSURLConnectionDataDelegate
    public func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        NSLog("Error: %@", error)
    }

    /// see NSURLConnectionDataDelegate
    public func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.data?.appendData(data)

        dispatch_sync(queue) {
            let decoder = CCBufferedImageDecoder(data: self.data)
            decoder.decompress()
            let decodedImage = decoder.toImage()

            dispatch_async(dispatch_get_main_queue()) {
                self.image = decodedImage
            }
        }
    }

    /// see NSURLConnectionDataDelegate
    public func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        var contentLength = Int(response.expectedContentLength)
        if contentLength < 0 {
            contentLength = defaultContentLength
        }

        data = NSMutableData(capacity: contentLength)
    }

    /// see NSURLConnectionDataDelegate
    public func connectionDidFinishLoading(connection: NSURLConnection) {
        data = nil

        if let loadedHandler = loadedHandler {
            loadedHandler()
        }
    }
}
