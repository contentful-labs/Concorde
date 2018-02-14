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
/** The scan that is currently decoding **/
@property (nonatomic) int currentScan;

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
-(instancetype _Nullable)initWithData:(NSData* _Nullable)data;

/**
 *  Convert the result RGB data to an image instance.
 *
 *  @return An image instance for use in Cocoa.
 */
#if TARGET_OS_IPHONE
-(UIImage* _Nullable)toImage;
#else
-(NSImage* _Nullable)toImage;
#endif

/**
 *  Convert the result RGB data to an image instance, only if the current scan being processed
 *  is greater than the scan provided. Use currentScan to get the scan being processed after decompressing.
 *
 *  Using this method will result in the image loading by every full-frame pass, rather than line by line.
 *  It will guarantee you will always show a full-frame image rather than a partially downloaded image.
 *
 *  @param scan The last scan processed
 *
 *  @return An image instance for use in Cocoa.
 */
#if TARGET_OS_IPHONE
-(UIImage* _Nullable)toImageWithScan:(int)scan;
#else
-(NSImage* _Nullable)toImageWithScan:(int)scan;
#endif

@end
