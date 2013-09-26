NSString *const kMapAttackHostname = @"api.mapattack.org";

UIColor *_colorWithHexString(NSString *hex) {
    NSString *cleanString = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if ([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                                                 [cleanString substringWithRange:NSMakeRange(0, 1)], [cleanString substringWithRange:NSMakeRange(0, 1)],
                                                 [cleanString substringWithRange:NSMakeRange(1, 1)], [cleanString substringWithRange:NSMakeRange(1, 1)],
                                                 [cleanString substringWithRange:NSMakeRange(2, 1)], [cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if ([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }

    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];

    return [UIColor colorWithRed:((baseValue >> 24) & 0xFF)/255.0f
                           green:((baseValue >> 16) & 0xFF)/255.0f
                            blue:((baseValue >> 8) & 0xFF)/255.0f
                           alpha:((baseValue >> 0) & 0xFF)/255.0f];
}
