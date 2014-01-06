//
//  ITCParser.m
//  albums
//
//  Created by Ivan Moscoso on 9/7/13.
//  Copyright (c) 2013 ivan3bx. All rights reserved.
//

#import "ITCParser.h"
#import <AppKit/AppKit.h>

@interface ITCParser() {
    NSMutableArray *_images;
    NSURL *_fileURL;
}

@property(nonatomic) NSString *library;
@property(nonatomic) NSString *trackID;

@end


@implementation ITCParser

- (id)initWith:(NSString *)path
{
    self = [super init];
    if (self) {
        if ([[[NSFileManager alloc] init] fileExistsAtPath:path]) {
            _fileURL = [NSURL URLWithString:path];
        } else {
            [NSException raise:@"File does not exist"
                        format:@"[path:%@]", path];
        }
        [self processFile];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        if ([[[NSFileManager alloc] init] fileExistsAtPath:url.path]) {
            _fileURL = url;
        } else {
            [NSException raise:@"File does not exist"
                        format:@"[path:%@]", url.path];
        }
        [self processFile];
    }
    return self;
}

-(NSMutableArray *)images
{
    if (!_images) {
        _images = [[NSMutableArray alloc] init];
    }
    return _images;
}

-(NSString *)library
{
    return [_library uppercaseString];
}

-(NSString *)trackID
{
    return [_trackID uppercaseString];
}

-(void)processFile
{
    @autoreleasepool {
        NSError *error;
        NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL:_fileURL error:&error];
        NSAssert(file, @"Expected file to be non-null");
        
        //
        // File type
        //
        [self processITCH:file];
        
        BOOL shouldContinue = YES;
        while (shouldContinue) {
            shouldContinue = [self processITEM:file];
        }
    }
}

-(void)processITCH:(NSFileHandle *)file
{
    uint32_t frameSize = [self convertToInt:[file readDataOfLength:4]];
    
    NSData *data = [file readDataOfLength:4];
    _fileType = [[NSString alloc] initWithBytes:data.bytes
                                         length:data.length
                                       encoding:NSUTF8StringEncoding];

    [file seekToFileOffset:frameSize];
}

-(BOOL)processITEM:(NSFileHandle *)file
{
    
    //
    // Frame Size
    //
    NSData *frameSizeData = [file readDataOfLength:4];
    if (frameSizeData.length == 0) {
        return NO;
    }
    
    //
    // Compute frame size & data size
    //
    uint32_t frameSize = [self convertToInt:frameSizeData];
    uint32_t dataSize = frameSize - 208; // (frameSize - size + type + iTunes_9 preamble)
    
    //
    // Frame type
    //
    NSString *frameType = [self convertToString:[file readDataOfLength:4]];
    if (![frameType isEqualToString:@"item"]) {
        NSLog(@"Frame type is not 'item'.  Skipping.");
        return NO;
    }
    
    //
    // Preamble
    //
    unsigned long long startingPoint = file.offsetInFile;
    [file seekToFileOffset:startingPoint + 20]; // image_offset_with_preamble
    
    //
    // Track metadata
    //
    _library = [self convertToHex:[file readDataOfLength:8]];
    _trackID = [self convertToHex:[file readDataOfLength:8]];
    _method  = [self convertToString:[file readDataOfLength:4]];
    _format  = [self convertToString:[file readDataOfLength:4]];
    
    //
    // Skip (undefined)
    //
    [file seekToFileOffset:file.offsetInFile + 4];
    
    //
    // Image dimensions
    //
    uint32_t width  = [self convertToInt:[file readDataOfLength:4]];
    uint32_t height = [self convertToInt:[file readDataOfLength:4]];
    
    //
    // Skip to start of image data
    //
    [file seekToFileOffset:startingPoint + 200]; // constant (ITUNES_9 + beyond)
    
    //
    // Image data
    //
    NSData *data = [file readDataOfLength:dataSize];
    
    // Write file by nsimage
    if (width > 0 && height > 0) {
        
        NSString *fileName = [NSString stringWithFormat:@"image_%@_%ux%u.png", _fileURL.lastPathComponent, width, height];
        
        if ([_format isEqualToString:@"ARGb"]) {
            CGImageRef cgImage = CGImageRetain([self createImageRefWithData:data width:width height:height]);
            [self writeCGImage:cgImage toFile:fileName];
            CGImageRelease(cgImage);
        } else {
            [data writeToFile:fileName atomically:NO];
        }
        return YES;
    } else {
        NSLog(@"Warning: File %@ had image with dimensions [%u,%u]", _fileURL.path, width,height);
        return NO;
    }
}

-(void)writeCGImage:(CGImageRef)image toFile:(NSString *)path
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
    
    CFRelease(destination);
}

-(CGImageRef)createImageRefWithData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height
{
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              data.bytes,
                                                              width*height*4,
                                                              NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width,
                                        height,
                                        8,
                                        32,
                                        4*width,
                                        colorSpaceRef,
                                        bitmapInfo,
                                        provider, NULL, NO, renderingIntent);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CFAutorelease(imageRef);
    return imageRef;
}


-(NSString *)convertToString:(NSData *)data
{
    return [[NSString alloc] initWithBytes:data.bytes
                                    length:data.length
                                  encoding:NSUTF8StringEncoding];
}

/*
 * Unpacks an unsigned integer, handling big endian conversion
 */
-(uint32_t)convertToInt:(NSData *)data
{
    uint32_t result;
    [data getBytes:&result length:4];
    return CFSwapInt32BigToHost(result);
}

-(uint64_t)convertToLong:(NSData *)data
{
    uint64_t result;
    [data getBytes:&result length:8];
    return CFSwapInt64BigToHost(result);
}

-(NSString *)convertToHex:(NSData *)data
{
    NSMutableString *bytes = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < [data length]; i++) {
        unsigned char byte;
        [data getBytes:&byte range:NSMakeRange(i, 1)];
        [bytes appendFormat:@"%02x", byte];
    }
    return bytes;
}

-(NSString *)description
{
    NSMutableString *output = [[NSMutableString alloc] init];
    [output appendFormat:@"ITC File: %@\n", _fileURL.lastPathComponent];
    [output appendFormat:@"%12s: %-16s\n", "File type", [self.fileType UTF8String]];
    [output appendFormat:@"%12s: %-16s\n", "Format", [self.format UTF8String]];
    [output appendFormat:@"%12s: %-16s\n", "Library ID", [self.library UTF8String]];
    [output appendFormat:@"%12s: %-16s\n", "Track ID", [self.trackID UTF8String]];
    [output appendFormat:@"%12s: %-16s\n", "Method", [self.method UTF8String]];
    [output appendFormat:@"%12s: %-16u\n", "Image Count", (unsigned int)self.images.count];
    
    [self.images enumerateObjectsUsingBlock:^(NSData *obj, NSUInteger idx, BOOL *stop) {
        [output appendFormat:@"%12s%01u: %8lu bytes\n", "Image #:", (unsigned int)idx+1, (unsigned long)obj.length];
    }];
    return output;
}

@end

