//
//  MACoinAnnotation.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/28/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MACoinAnnotation.h"

@interface MACoinAnnotation ()

@property (strong, nonatomic, readwrite) NSString *identifier;

@end

@implementation MACoinAnnotation

- (id)initWithIdentifier:(NSString *)identifier coordinate:(CLLocationCoordinate2D)coordinate pointValue:(NSInteger)points team:(NSString *)team {

    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.identifier = identifier;
    self.coordinate = coordinate;
    self.pointValue = points;
    self.team = team;

    return self;
}


- (UIImage *)image {
    NSString *imageName = [NSString stringWithFormat:@"coin%@%d", self.team, self.pointValue];
    imageName = [imageName stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    UIImage *image = [UIImage imageNamed:imageName];
    return [UIImage imageWithCGImage:image.CGImage scale:2.0f orientation:UIImageOrientationUp];
}

@end
