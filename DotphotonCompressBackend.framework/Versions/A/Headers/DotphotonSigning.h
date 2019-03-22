//
//  DotphotonSigning.h
//  DotphotonCompress
//
//  Created by Christoph Clausen on 20.08.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

#ifndef DotphotonSigning_h
#define DotphotonSigning_h

@interface DotphotonSigning : NSObject {
    NSString *s1;
    NSString *s2;
    NSString *s3;
}

+ (DotphotonSigning *) shared;
- (NSData *) createSignatureForData:(NSData *)data;
- (NSData *) restore:(NSURL *)url;
@end

#endif /* DotphotonSigning_h */
