//
//  DotphotonDNGWrapper.h
//  DotphotonConvert
//
//  Created by Christoph Clausen on 05.06.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CompressionResult){
    success = 0,
    cannotOpen,
    pixelBufferFailure,
    cannotSave
};

@interface DotphotonDNGWrapper : NSObject
- (void) setGain:(double[4]) gain;
- (void) setBlackLevel:(double[4]) blackLevel;
- (void) setNoise:(double[4]) noise;
- (int) lookupTableSize:(NSString *)inputPath;
- (enum CompressionResult) compressFile:(NSString *)inputPath outputPath:(NSString *)outputPath;
@end
