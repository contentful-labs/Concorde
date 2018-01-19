//
//  ConcordeTests.swift
//  ConcordeTests
//
//  Created by Boris Bügling on 09/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import Concorde
import Nimble
import Nimble_Snapshots
import Quick

class ConcordeTests: QuickSpec {
    override func spec() {
        var crashData = Data()
        var nonProgressiveData = Data()
        var progressiveData = Data()

        beforeEach {
            var path = NSBundle(forClass: type(of: self)).pathForResource("non-progressive", ofType: "jpg")
            nonProgressiveData = NSData(contentsOfFile: path!)!

            path = NSBundle(forClass: type(of: self)).pathForResource("progressive", ofType: "jpg")
            progressiveData = NSData(contentsOfFile: path!)!

            path = NSBundle(forClass: type(of: self)).pathForResource("crash", ofType: "jpg")
            crashData = NSData(contentsOfFile: path!)!
        }

        it("can decode non-progressive JPEGs") {
            let decoder = CCBufferedImageDecoder(data: nonProgressiveData)
            decoder.decompress()

            let view = UIImageView(image: decoder.toImage())
            expect(view).to(haveValidSnapshot())
        }

        it("can decode progressive JPEGs") {
            let decoder = CCBufferedImageDecoder(data: progressiveData)
            decoder.decompress()

            let view = UIImageView(image: decoder.toImage())
            expect(view).to(haveValidSnapshot())
        }

        it("can decode partial progressive JPEGs") {
            let partialData = progressiveData.subdataWithRange(NSMakeRange(0, 7000))
            let decoder = CCBufferedImageDecoder(data: partialData)
            decoder.decompress()

            let view = UIImageView(image: decoder.toImage())
            expect(view).to(haveValidSnapshot())
        }

        it("is resilient against errors in the data to decode") {
            let partialData = progressiveData.subdataWithRange(NSMakeRange(0, 32768))
            let decoder = CCBufferedImageDecoder(data: partialData)
            decoder.decompress()
        }

        it("is resilient against calling decode() many times") {
            let decoder = CCBufferedImageDecoder(data: nonProgressiveData)

            for _ in 0...5 {
                decoder.decompress()
            }

            let view = UIImageView(image: decoder.toImage())
            expect(view).to(haveValidSnapshot())
        }

        it("is resilient against not calling decode() at all") {
            let decoder = CCBufferedImageDecoder(data: nonProgressiveData)

            expect(decoder.toImage()).to(beNil())
        }

        it("is resilient against decoding nil") {
            let decoder = CCBufferedImageDecoder(data: nil)
            decoder.decompress()

            expect(decoder.toImage()).to(beNil())
        }

        it("is resilient against crashing with non-progressive images") {
            let decoder = CCBufferedImageDecoder(data: crashData)
            decoder.decompress()

            expect(decoder.toImage()).toNot(beNil())
        }

        it("can be used in IB") {
            let imageView = CCBufferedImageView(coder: NSKeyedUnarchiver(forReadingWithData: NSData()))

            expect(imageView).toNot(beNil())
        }
    }
}
