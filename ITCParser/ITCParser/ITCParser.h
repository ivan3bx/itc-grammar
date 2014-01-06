//
//  ITCParser.h
//  albums
//
//  Created by Ivan Moscoso on 9/7/13.
//  Copyright (c) 2013 ivan3bx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITCParser : NSObject

@property(readonly, nonatomic) NSString *fileType;
@property(readonly, nonatomic) NSString *library;
@property(readonly, nonatomic) NSString *trackID;
@property(readonly, nonatomic) NSString *method;
@property(readonly, nonatomic) NSString *format;
@property(readonly, nonatomic) NSArray *images;


/*
 * Init with a given file path
 */
-(id)initWith:(NSString *)path;
-(id)initWithURL:(NSURL *)url;

@end
