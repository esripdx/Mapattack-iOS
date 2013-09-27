//
//  NSString+UrlEncoding.m
//  Mapattack-iOS
//
//  Created by kenichi nakamura on 9/27/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "NSString+UrlEncoding.h"

// http://stackoverflow.com/questions/8088473/url-encode-an-nsstring
//
@implementation NSString (UrlEncoding)

- (NSString *)urlEncode {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[self UTF8String];
    int sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

@end
