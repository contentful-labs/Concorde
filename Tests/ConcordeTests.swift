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
            var path = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "non-progressive", ofType: "jpg")!)

            do {
                try nonProgressiveData = Data(contentsOf: path)

                path = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "progressive", ofType: "jpg")!)
                try progressiveData = Data(contentsOf: path)

                path = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "crash", ofType: "jpg")!)
                try crashData = Data(contentsOf: path)
            }
            catch {
                XCTFail("Unable to get data for \(path)")
            }

        }

        it("can decode non-progressive JPEGs") {
            let decoder = CCBufferedImageDecoder(data: nonProgressiveData)
            decoder?.decompress()

            let view = UIImageView(image: decoder?.toImage())
            expect(decoder?.isLoadingProgressiveJPEG).to(beFalse())
            expect(view).to(haveValidSnapshot())
        }

        it("can decode progressive JPEGs") {
            let decoder = CCBufferedImageDecoder(data: progressiveData)
            decoder?.decompress()

            let view = UIImageView(image: decoder?.toImage())
            expect(decoder?.isLoadingProgressiveJPEG).to(beTrue())
            expect(view).to(haveValidSnapshot())
        }

        it("can decode partial progressive JPEGs") {
            let partialData = progressiveData.subdata(in: 0..<7000)
            let decoder = CCBufferedImageDecoder(data: partialData)
            decoder?.decompress()

            let view = UIImageView(image: decoder?.toImage())
            expect(view).to(haveValidSnapshot())
        }

        it("is resilient against errors in the data to decode") {
            let partialData = progressiveData.subdata(in: 0..<32768)
            let decoder = CCBufferedImageDecoder(data: partialData)
            decoder?.decompress()
        }

        it("is resilient against calling decode() many times") {
            let decoder = CCBufferedImageDecoder(data: nonProgressiveData)

            for _ in 0...5 {
                decoder?.decompress()
            }

            let view = UIImageView(image: decoder?.toImage())
            expect(view).to(haveValidSnapshot())
        }

        it("is resilient against not calling decode() at all") {
            let decoder = CCBufferedImageDecoder(data: nonProgressiveData)

            expect(decoder?.toImage()).to(beNil())
        }

        it("is resilient against decoding nil") {
            let decoder = CCBufferedImageDecoder(data: nil)
            decoder?.decompress()

            expect(decoder?.toImage()).to(beNil())
        }

        it("is resilient against crashing with non-progressive images") {
            let decoder = CCBufferedImageDecoder(data: crashData)
            decoder?.decompress()

            expect(decoder?.toImage()).toNot(beNil())
        }

        it("can be used in IB") {
            let imageView = CCBufferedImageView(coder: NSKeyedUnarchiver(forReadingWith: Data()))

            expect(imageView).toNot(beNil())
        }
    }
}
