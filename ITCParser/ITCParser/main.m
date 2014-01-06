//
//  main.m
//  ITCParser
//
//  Created by Ivan Moscoso on 1/4/14.
//  Copyright (c) 2014 3bx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITCParser.h"

#define PrintOut(aString) [aString writeToFile:@"/dev/stdout" atomically:NO encoding:NSUTF8StringEncoding error:nil]

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSURL *musicDirectoryURL = [[fileManager URLsForDirectory:NSMusicDirectory inDomains:NSUserDomainMask] firstObject];
        NSURL *artworkDirectory = [musicDirectoryURL URLByAppendingPathComponent:@"iTunes/Album Artwork"];

        NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtURL:artworkDirectory
                                                 includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                                               errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                                   NSLog(@"Experienced error with URL: %@, error:%@", url, error);
                                                                   return YES;
                                                               }];
        
        BOOL foundOne = NO;
        for (NSURL *theURL in dirEnumerator) {
            if ([@"itc" isEqualToString:theURL.pathExtension] && !foundOne) {
                ITCParser *parser = [[ITCParser alloc] initWithURL:theURL];
//                foundOne = YES;
                if (parser == nil) {
                    NSLog(@"Parser was nil");
                }
            }
        }
        
    }
    return 0;
}

