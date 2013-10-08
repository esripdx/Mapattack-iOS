//
//  MACoin.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 10/7/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "MACoin.h"

@implementation MACoin
+ (instancetype)coinWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.coinId = dictionary[kMAApiCoinIdKey];
        self.team = dictionary[kMAApiTeamKey];
        self.value = [dictionary[kMAApiPointsKey] integerValue];

        NSNumber *latitude = dictionary[kMAApiLatitudeKey];
        NSNumber *longitude = dictionary[kMAApiLongitudeKey];
        NSNumber *timestamp = dictionary[kMAApiTimestampKey];
        if (latitude && longitude) {
            if (timestamp) {
                self.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([latitude floatValue], [longitude floatValue])
                                                              altitude:0 horizontalAccuracy:0 verticalAccuracy:0
                                                             timestamp:[NSDate dateWithTimeIntervalSince1970:[timestamp integerValue]]];
            } else {
                self.location = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
            }
        }
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    [dictionary setValue:self.coinId forKey:kMAApiCoinIdKey];
    [dictionary setValue:self.team forKey:kMAApiTeamKey];
    [dictionary setValue:@(self.value) forKey:kMAApiPointsKey];
    [dictionary setValue:@(self.location.coordinate.latitude) forKey:kMAApiLatitudeKey];
    [dictionary setValue:@(self.location.coordinate.longitude) forKey:kMAApiLongitudeKey];
    [dictionary setValue:@(self.location.timestamp.timeIntervalSince1970) forKey:kMAApiTimestampKey];

    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.coinId=%@", self.coinId];
    [description appendFormat:@", self.location=%@", self.location];
    [description appendFormat:@", self.team=%@", self.team];
    [description appendFormat:@", self.value=%i", self.value];
    [description appendString:@">"];
    return description;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    if (!other || ![[other class] isEqual:[self class]]) {
        return NO;
    }

    return [self isEqualToCoin:other];
}

- (BOOL)isEqualToCoin:(MACoin *)coin {
    if (self == coin) {
        return YES;
    }
    if (coin == nil) {
        return NO;
    }
    if (self.coinId == coin.coinId || [self.coinId isEqualToString:coin.coinId]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return [self.coinId hash];
}

- (CLLocationCoordinate2D)coordinate {
    return self.location.coordinate;
}

- (UIImage *)image {
    NSString *imageName = [NSString stringWithFormat:@"coin%@%d", self.team, self.value];
    imageName = [imageName stringByReplacingOccurrencesOfString:@"<null>" withString:@""];
    UIImage *image = [UIImage imageNamed:imageName];
    return [UIImage imageWithCGImage:image.CGImage scale:2.0f orientation:UIImageOrientationUp];
}

@end
