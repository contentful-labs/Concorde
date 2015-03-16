/*
 * CCBufferedImageDecoder.m
 * Concorde
 *
 * Code is derived from WebKit's Source/WebCore/platform/image-decoders/jpeg/JPEGImageDecoder.cpp,
 * licensed under the following terms.
 *
 * Copyright (C) 2006 Apple Inc.
 *
 * Portions are Copyright (C) 2001-6 mozilla.org
 *
 * Other contributors:
 *   Stuart Parmenter <stuart@mozilla.com>
 *
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#import <stdio.h>
#import "jpeglib.h"
#include <setjmp.h>

#import "CCBufferedImageDecoder.h"

// Error handling code from libjpeg's example.c
struct my_error_mgr {
    struct jpeg_error_mgr pub;
    jmp_buf setjmp_buffer;
};

typedef struct my_error_mgr * my_error_ptr;

METHODDEF(void) my_error_exit (j_common_ptr cinfo) {
    my_error_ptr myerr = (my_error_ptr) cinfo->err;
    (*cinfo->err->output_message) (cinfo);
    longjmp(myerr->setjmp_buffer, 1);
}

METHODDEF(void) my_output_message(j_common_ptr cinfo) { }

#pragma mark -

@interface CCBufferedImageDecoder ()

@property (nonatomic) NSData* data;
@property (nonatomic) BOOL done;
@property (nonatomic) NSMutableData* outputData;

@end

#pragma mark -

@implementation CCBufferedImageDecoder {
    struct my_error_mgr jerr;
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

        if (self.data) {
            [self initializeDecompression];
            [self startDecompression];
        } else {
            self.done = YES;
        }
    }
    return self;
}

#pragma mark -

-(void)initializeDecompression {
    memset(&self->info, 0, sizeof(struct jpeg_decompress_struct));

    self->info.err = jpeg_std_error((struct jpeg_error_mgr *)&jerr);
    jerr.pub.error_exit = my_error_exit;
    jerr.pub.output_message = my_output_message;

    if (setjmp(jerr.setjmp_buffer)) {
        return;
    }

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

    if (setjmp(jerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&self->info);
        return CCDecodingStatusFailed;
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

#if TARGET_OS_IPHONE
-(UIImage*)toImage {
#else
-(NSImage*)toImage {
#endif
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

#if TARGET_OS_IPHONE
    UIImage *image = nil;
#else
    NSImage *image = nil;
#endif

    if (context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        CGImageRef imageRef = CGBitmapContextCreateImage(context);

#if TARGET_OS_IPHONE
        image = [UIImage imageWithCGImage:imageRef];
#else
        image = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(width, height)];
#endif

        CGImageRelease(imageRef);
        CGContextRelease(context);
    }

    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    free(pixels);

    return image;
}

@end
