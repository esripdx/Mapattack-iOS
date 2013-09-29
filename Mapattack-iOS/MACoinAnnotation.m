//
//  MACoinAnnotation.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/28/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MACoinAnnotation.h"

@implementation MACoinAnnotation

- (id)initWithDictionary:(NSDictionary *)dict {

    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.coordinate = CLLocationCoordinate2DMake([dict[@"latitude"] doubleValue], [dict[@"longitude"] doubleValue]);
    self.pointValue = [dict[@"value"] integerValue];
    self.team = dict[@"team"];

    return self;
}


- (UIImage *)image {
    NSString *imageName = [NSString stringWithFormat:@"coin%@%d", self.team, self.pointValue];
    imageName = [imageName stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    return [UIImage imageNamed:imageName];
}

@end
