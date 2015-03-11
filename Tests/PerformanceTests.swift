//
//  PerformanceTests.swift
//  Concorde
//
//  Created by Boris Bügling on 11/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import Concorde
import XCTest

func decompressImage(data: NSData) {
    if let image = UIImage(data: data) {
        UIGraphicsBeginImageContext(CGSizeMake(1, 1))
        image.drawAtPoint(CGPointZero)
        UIGraphicsEndImageContext()
    } else {
        XCTFail("Could not load image")
    }
}

class PerformanceTests: XCTestCase {
    var progressiveData = NSData()

    override func setUp() {
        var path = NSBundle(forClass: self.dynamicType).pathForResource("progressive", ofType: "jpg")
        progressiveData = NSData(contentsOfFile: path!)!
    }

    func testPerformanceIsComparableToImageIO() {
        self.measureBlock {
            //decompressImage(self.progressiveData)

            let decoder = CCBufferedImageDecoder(data: self.progressiveData)
            decoder.decompress()
            let decodedImage = decoder.toImage()

            UIGraphicsBeginImageContext(CGSizeMake(1, 1))
            decodedImage.drawAtPoint(CGPointZero)
            UIGraphicsEndImageContext()

            XCTAssertNotNil(decodedImage, "")
        }
    }
}
