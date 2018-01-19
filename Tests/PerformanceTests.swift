//
//  PerformanceTests.swift
//  Concorde
//
//  Created by Boris Bügling on 11/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import Concorde
import XCTest

func decompressImage(_ data: Data) {
    if let image = UIImage(data: data) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        image.draw(at: CGPoint.zero)
        UIGraphicsEndImageContext()
    } else {
        XCTFail("Could not load image")
    }
}

class PerformanceTests: XCTestCase {
    var progressiveData = Data()

    override func setUp() {
        let path = Bundle(for: type(of: self)).path(forResource: "progressive", ofType: "jpg")
        progressiveData = try! Data(contentsOf: URL(fileURLWithPath: path!))
    }

    func testPerformanceIsComparableToImageIO() {
        self.measure {
            //decompressImage(self.progressiveData)

            let decoder = CCBufferedImageDecoder(data: self.progressiveData)
            decoder.decompress()
            let decodedImage = decoder.toImage()

            UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
            decodedImage.draw(at: CGPoint.zero)
            UIGraphicsEndImageContext()

            XCTAssertNotNil(decodedImage, "")
        }
    }
}
