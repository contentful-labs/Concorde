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

/** JPEG decoding status */
typedef NS_ENUM(NSInteger, CCDecodingStatus){
    /** Decoding failed */
    CCDecodingStatusFailed,
    /** Decoding completely finished */
    CCDecodingStatusFinished,
    /** Another decoding pass exists */
    CCDecodingStatusNextIteration,
};

/** Decoder for JPEG images */
@interface CCBufferedImageDecoder : NSObject

/** Indicates whether the JPEG being decoded is progressive **/
@property (nonatomic) BOOL isLoadingProgressiveJPEG;

/**
 *  Decompress the next pass in buffered mode.
 *
 *  @return Status of the decoding process.
 */
-(CCDecodingStatus)decompress;

/**
 *  Initialize decoder with image data.
 *
 *  @param data The image data to decode.
 *
 *  @return An initialized decoder instance.
 */
-(instancetype)initWithData:(NSData*)data;

/**
 *  Initialize decoder with image data.
 *
 *  @param data The image data to decode.
 *
 *  @param showFirstPass If set to YES, the first pass will appear while
 *  loading. The initial image frame will be grey, and the image will fill
 *  in the frame line-by-line as the first pass loads. If set to NO, the
 *  first pass will not appear until it is completed. The image frame will
 *  fill in the full frame after the first pass has completed.
 *
 *  @return An initialized decoder instance.
 */
-(instancetype)initWithData:(NSData*)data showFirstPass:(BOOL)showFirstPass;


/**
 *  Convert the result RGB data to an image instance.
 *
 *  @return An image instance for use in Cocoa.
 */
#if TARGET_OS_IPHONE
-(UIImage*)toImage;
#else
-(NSImage*)toImage;
#endif

@end
