//
//  CCBufferedImageDecoder.h
//  Concorde
//
//  Created by Boris Bügling on 10/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CCDecodingStatus) {
    CCDecodingStatusFailed,
    CCDecodingStatusFinished,
    CCDecodingStatusNextIteration,
};

@interface CCBufferedImageDecoder : NSObject

-(CCDecodingStatus)decompress;
-(instancetype)initWithData:(NSData*)data;
-(UIImage*)toImage;

@end
