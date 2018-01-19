//
//  CCBufferedImageView.swift
//  Concorde
//
//  Created by Boris Bügling on 11/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import UIKit

/// A subclass of UIImageView which displays a JPEG progressively while it is downloaded
open class CCBufferedImageView : UIImageView, NSURLConnectionDataDelegate {
    fileprivate weak var connection: NSURLConnection?
    fileprivate let defaultContentLength = 5 * 1024 * 1024
    fileprivate var data: Data?
    fileprivate let queue = DispatchQueue(label: "com.contentful.Concorde", attributes: [])

    /// Optional handler which is called after an image has been successfully downloaded
    open var loadedHandler: (() -> ())?

    deinit {
        connection?.cancel()
    }

    /// Initialize a new image view with the given frame
    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.gray
    }

    /// Initialize a new image view and start loading a JPEG from the given URL
    public init(URL: Foundation.URL) {
        super.init(image: nil)

        backgroundColor = UIColor.gray
        load(URL)
    }

    /// Required initializer, not implemented
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.gray
    }

    /// Load a JPEG from the given URL
    open func load(_ URL: Foundation.URL) {
        connection?.cancel()
        connection = NSURLConnection(request: URLRequest(url: URL), delegate: self)
    }

    // MARK: NSURLConnectionDataDelegate

    /// see NSURLConnectionDataDelegate
    open func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        NSLog("Error: \(error)")
    }

    /// see NSURLConnectionDataDelegate
    open func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.data?.append(data)

        queue.sync {
            let decoder = CCBufferedImageDecoder(data: self.data! as Data)
            decoder?.decompress()
            
            guard let decodedImage = decoder?.toImage() else {
                return
            }
            
            UIGraphicsBeginImageContext(CGSize(width: 1,height: 1))
            let context = UIGraphicsGetCurrentContext()
            context?.draw(decodedImage.cgImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            UIGraphicsEndImageContext()

            DispatchQueue.main.async {
                self.image = decodedImage
            }
        }
    }

    /// see NSURLConnectionDataDelegate
    open func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        var contentLength = Int(response.expectedContentLength)
        if contentLength < 0 {
            contentLength = defaultContentLength
        }

        data = Data(capacity: contentLength)
    }

    /// see NSURLConnectionDataDelegate
    open func connectionDidFinishLoading(_ connection: NSURLConnection) {
        data = nil

        if let loadedHandler = loadedHandler {
            loadedHandler()
        }
    }
}
