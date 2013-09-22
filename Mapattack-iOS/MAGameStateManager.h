//
//  MAGameStateManager.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/19/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MAUdpConnection.h"

@class MAUdpConnection;

@protocol MAGameStateManagerDelegate
- (void)coin:(NSString *)identifier didChangeState:(BOOL)claimable;
- (void)player:(NSString *)identifier didMoveToLocation:(CLLocation *)location;
- (void)team:(int)teamNumber didReceivePoints:(int)points;
- (void)gameDidStart;
- (void)gameDidEnd;
@end

@interface MAGameStateManager : NSObject <CLLocationManagerDelegate, MAUdpConnectionDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) MAUdpConnection *udpConnection;

+ (MAGameStateManager *)sharedManager;

- (void)startGame:(NSString *)gameId;

@end
