//
//  CCBufferedImageView.swift
//  Concorde
//
//  Created by Boris Bügling on 16/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

import ContentfulDeliveryAPI

// Make "private" methods from the CDA's `UIImageView` category known to Swift code.
extension UIImageView {
    func cda_handleCachingForAsset(asset: CDAAsset!) {
        fatalError("should never be called")
    }

    func cda_setImageWithAsset(asset: CDAAsset!, URL: NSURL!, size: CGSize, placeholderImage: UIImage!) {
        fatalError("should never be called")
    }
}

extension CCBufferedImageView {
    func cda_fetchImageWithAsset(asset: CDAAsset!, URL: NSURL!, placeholderImage: UIImage!) {
        if let placeholderImage = placeholderImage {
            image = placeholderImage
        }

        if let URL = URL {
            loadedHandler = {
                self.cda_handleCachingForAsset(asset)
            }

            load(URL)
        }
    }

    public override func cda_setImageWithAsset(asset: CDAAsset!, size: CGSize, placeholderImage: UIImage!) {
        if let asset = asset {
            let URL = asset.imageURLWithSize(size, quality: 0.75, format: CDAImageFormat.JPEG, fit: CDAFitType.Default, focus: nil, radius: CDARadiusNone, background: nil, progressive: true)

            cda_setImageWithAsset(asset, URL: URL, size: size, placeholderImage: placeholderImage)
        }
    }
}
