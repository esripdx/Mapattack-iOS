//
//  MAGameStateManager.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/19/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "MAGameStateManager.h"
#import "GeoHash.h"

@implementation MAGameStateManager

+ (MAGameStateManager *)sharedManager {
    static MAGameStateManager *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveDictionary:(NSDictionary *)dictionary {

}

- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveArray:(NSArray *)array {

}

- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;

    self.udpConnection = [MAUdpConnection connectionWithDelegate:self];

    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [locations enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        NSString *locationHash = [GeoHash hashForLatitude:location.coordinate.latitude
                                                longitude:location.coordinate.longitude
                                                   length:9];
        NSDictionary *update = @{
                @"location": locationHash,
                @"timestamp": @(location.timestamp.timeIntervalSince1970),
                @"accuracy": @(location.horizontalAccuracy),
                @"speed": @(location.speed),
                @"bearing": @(location.course)
        };
        [self.udpConnection sendDictionary:update];
    }];
}

- (void)startGame:(NSString *)gameId {
    DDLogVerbose(@"Starting game: %@", gameId);
    [self.locationManager startUpdatingLocation];
    [self.udpConnection connect];
}

@end
