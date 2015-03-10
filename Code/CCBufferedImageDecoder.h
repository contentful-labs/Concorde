//
//  CCBufferedImageDecoder.h
//  Concorde
//
//  Created by Boris Bügling on 10/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

typedef NS_ENUM(NSInteger, CCDecodingStatus) {
    CCDecodingStatusFailed,
    CCDecodingStatusFinished,
    CCDecodingStatusNextIteration,
};

@interface CCBufferedImageDecoder : NSObject

-(CCDecodingStatus)decompress;
-(instancetype)initWithData:(NSData*)data;

#if TARGET_OS_IPHONE
-(UIImage*)toImage;
#else
-(NSImage*)toImage;
#endif

@end
