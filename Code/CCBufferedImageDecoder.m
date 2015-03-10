//
//  CCBufferedImageDecoder.m
//  Concorde
//
//  Created by Boris Bügling on 10/03/15.
//  Copyright (c) 2015 Contentful GmbH. All rights reserved.
//

#import <stdio.h>
#import "jpeglib.h"

#import "CCBufferedImageDecoder.h"

@interface CCBufferedImageDecoder ()

@property (nonatomic) NSData* data;
@property (nonatomic) BOOL done;
@property (nonatomic) NSMutableData* outputData;

@end

#pragma mark -

@implementation CCBufferedImageDecoder {
    struct jpeg_error_mgr jerr;
    struct jpeg_decompress_struct info;
    JSAMPROW samples;
}

#pragma mark -

-(instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

-(instancetype)initWithData:(NSData*)data {
    self = [super init];
    if (self) {
        self.data = data;

        [self initializeDecompression];
        [self startDecompression];
    }
    return self;
}

#pragma mark -

-(void)initializeDecompression {
    memset(&self->info, 0, sizeof(struct jpeg_decompress_struct));
    self->info.err = jpeg_std_error(&jerr);

    jpeg_create_decompress(&self->info);
    jpeg_mem_src(&self->info, (unsigned char *)self.data.bytes, self.data.length);
}

-(BOOL)startDecompression {
    if (jpeg_read_header(&self->info, TRUE) == JPEG_SUSPENDED) {
        return NO;
    }

    switch (self->info.jpeg_color_space) {
        case JCS_GRAYSCALE:
        case JCS_RGB:
        case JCS_YCbCr:
            self->info.out_color_space = JCS_RGB;
            break;
        case JCS_CMYK:
        case JCS_YCCK:
            self->info.out_color_space = JCS_CMYK;
            break;
        default:
            return NO;
    }

    self->info.buffered_image = TRUE;
    self->info.dct_method = JDCT_ISLOW;
    self->info.dither_mode = JDITHER_FS;
    self->info.do_fancy_upsampling = TRUE;
    self->info.enable_2pass_quant = FALSE;
    self->info.do_block_smoothing = TRUE;

    jpeg_calc_output_dimensions(&self->info);

    self.outputData = [NSMutableData dataWithLength:self->info.output_width * self->info.output_height * 4];
    self->samples = *(*self->info.mem->alloc_sarray)((j_common_ptr) &self->info, JPOOL_IMAGE, self->info.output_width * 4, 1);

    if (!jpeg_start_decompress(&self->info))
        return NO;

    return YES;
}

-(CCDecodingStatus)decompress {
    if (self.done) {
        return CCDecodingStatusFinished;
    }

    int status;
    do {
        status = jpeg_consume_input(&self->info);
    } while ((status != JPEG_SUSPENDED) && (status != JPEG_REACHED_EOI));

    if (!self->info.output_scanline) {
        int scan = self->info.input_scan_number;

        if (!self->info.output_scan_number && (scan > 1) && (status != JPEG_REACHED_EOI))
            --scan;

        if (!jpeg_start_output(&self->info, scan))
            return CCDecodingStatusFailed;
    }

    if (self->info.output_scanline == 0xffffff)
        self->info.output_scanline = 0;

    if (![self outputScanLines]) {
        if (!self->info.output_scanline)
            // Didn't manage to read any lines - flag so we
            // don't call jpeg_start_output() multiple times for
            // the same scan.
            self->info.output_scanline = 0xffffff;
        return CCDecodingStatusFailed;
    }

    if (self->info.output_scanline == self->info.output_height) {
        if (!jpeg_finish_output(&self->info))
            return CCDecodingStatusFailed;

        if (jpeg_input_complete(&self->info) && (self->info.input_scan_number == self->info.output_scan_number)) {
            self.done = YES;
            [self finishDecompression];
            return CCDecodingStatusFinished;
        }

        self->info.output_scanline = 0;
    }

    return CCDecodingStatusNextIteration;
}

-(BOOL)outputScanLines {
    NSCAssert(self->info.out_color_space == JCS_RGB, @"Only RGB is supported for now.");

    int width = self->info.output_width;

    while (self->info.output_scanline < self->info.output_height) {
        int destY = self->info.output_scanline;

        if (jpeg_read_scanlines(&self->info, &self->samples, 1) != 1)
            return NO;

        JSAMPROW buffer = self.outputData.mutableBytes + (destY * width * 4);
        for (int x = 0; x < width; ++x) {
            memcpy(buffer + (x * 4), samples + (x * 3), 3);
            buffer[x * 4 + 3] = (JSAMPLE)0xFF;
        }
    }

    return YES;
}

-(void)finishDecompression {
    jpeg_finish_decompress(&self->info);
    jpeg_destroy_decompress(&self->info);
}

-(UIImage*)toImage {
    if (!self->info.output_scanline) {
        return nil;
    }

    CGFloat width = self->info.output_width;
    CGFloat height = self->info.output_height;

    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              self.outputData.mutableBytes,
                                                              bufferLength,
                                                              NULL);

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if (!colorSpaceRef) {
        CGDataProviderRelease(provider);
        return nil;
    }

    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;

    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,
                                    NULL,
                                    YES,
                                    renderingIntent);

    uint32_t* pixels = (uint32_t*)malloc(bufferLength);

    if (!pixels) {
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }

    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);

    if (!context) {
        free(pixels);
    }

    UIImage *image = nil;

    if (context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        CGImageRef imageRef = CGBitmapContextCreateImage(context);

        image = [UIImage imageWithCGImage:imageRef];

        CGImageRelease(imageRef);
        CGContextRelease(context);
    }

    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);

    return image;
}


/* 
FIXME: Add support for CYMK, similar to this snippet from WebKit source

template <J_COLOR_SPACE colorSpace>
void setPixel(ImageFrame& buffer, ImageFrame::PixelData* currentAddress, JSAMPARRAY samples, int column)
{
    JSAMPLE* jsample = *samples + column * (colorSpace == JCS_RGB ? 3 : 4);

    switch (colorSpace) {
        case JCS_RGB:
            buffer.setRGBA(currentAddress, jsample[0], jsample[1], jsample[2], 0xFF);
            break;
        case JCS_CMYK:
            // Source is 'Inverted CMYK', output is RGB.
            // See: http://www.easyrgb.com/math.php?MATH=M12#text12
            // Or: http://www.ilkeratalay.com/colorspacesfaq.php#rgb
            // From CMYK to CMY:
            // X =   X    * (1 -   K   ) +   K  [for X = C, M, or Y]
            // Thus, from Inverted CMYK to CMY is:
            // X = (1-iX) * (1 - (1-iK)) + (1-iK) => 1 - iX*iK
            // From CMY (0..1) to RGB (0..1):
            // R = 1 - C => 1 - (1 - iC*iK) => iC*iK  [G and B similar]
            unsigned k = jsample[3];
            buffer.setRGBA(currentAddress, jsample[0] * k / 255, jsample[1] * k / 255, jsample[2] * k / 255, 0xFF);
            break;
    }
}
*/

@end
