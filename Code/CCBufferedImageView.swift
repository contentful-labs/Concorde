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
    private let queue = DispatchQueue(label: "com.contentful.Concorde")

    /// Optional handler which is called after an image has been successfully downloaded
    public var loadedHandler: (() -> ())?

    deinit {
        connection?.cancel()
    }

    /// Initialize a new image view with the given frame
    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.gray
    }

    /// Initialize a new image view and start loading a JPEG from the given URL
    public init(URL: URL) {
        super.init(image: nil)

        backgroundColor = .gray
        load(URL: URL)
    }

    /// Required initializer, not implemented
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = .gray
    }

    /// Load a JPEG from the given URL
    public func load(URL: URL) {
        connection?.cancel()
        connection = NSURLConnection(request: NSURLRequest(url: URL as URL) as URLRequest, delegate: self)
    }

    // MARK: NSURLConnectionDataDelegate

    /// see NSURLConnectionDataDelegate
    public func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        NSLog("Error: %@", error)
    }

    /// see NSURLConnectionDataDelegate
    public func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.data?.append(data as Data)

        queue.sync() {
            let decoder = CCBufferedImageDecoder(data: self.data as Data?)
            decoder?.decompress()
            
            guard let decodedImage = decoder?.toImage() else {
                return
            }
            
            UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
            let context = UIGraphicsGetCurrentContext()

            context?.draw(decodedImage.cgImage!,
                          in: CGRect(x: 0, y: 0, width: 1, height: 1))

            UIGraphicsEndImageContext()

            DispatchQueue.main.async {
                self.image = decodedImage
            }
        }
    }

    /// see NSURLConnectionDataDelegate
    public func connection(connection: NSURLConnection, didReceiveResponse response: URLResponse) {
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
