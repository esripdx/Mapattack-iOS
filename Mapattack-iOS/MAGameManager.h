//
//  MAGameManager.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/19/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import "MAUdpConnection.h"

@class MAUdpConnection;
@class AFHTTPSessionManager;

@protocol MAGameStateManagerDelegate
- (void)coin:(NSString *)identifier didChangeState:(BOOL)claimable;
- (void)player:(NSString *)identifier didMoveToLocation:(CLLocation *)location;
- (void)team:(int)teamNumber didReceivePoints:(int)points;
- (void)gameDidStart;
- (void)gameDidEnd;
@end

@interface MAGameManager : NSObject <CLLocationManagerDelegate, MAUdpConnectionDelegate>
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic, readonly) MAUdpConnection *udpConnection;
@property (strong, nonatomic, readonly) AFHTTPSessionManager *tcpConnection;

+ (MAGameManager *)sharedManager;

- (void)registerDeviceWithCompletionBlock:(void (^)(NSError *))completion;
- (void)startGame:(NSString *)gameId;

@end