//
//  ConcordeTests.swift
//  ConcordeTests
//
//  Created by Boris Bügling on 09/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import Concorde
import XCTest

class ConcordeTests: XCTestCase {
    var nonProgressiveData = NSData()

    override func setUp() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("non-progressive", ofType: "jpg")
        nonProgressiveData = NSData(contentsOfFile: path!)!
    }

    func testNonProgressive() {
        let decoder = CCBufferedImageDecoder(data: nonProgressiveData)

        for i in 0...5 {
            decoder.decompress()
        }

        let data = UIImagePNGRepresentation(decoder.toImage())
        data.writeToFile("output.png", atomically: true)
    }
}
