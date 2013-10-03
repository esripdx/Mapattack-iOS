//
//  MAGameManager.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/19/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <AFNetworking/AFNetworking.h>
#import "MAUdpConnection.h"

@class MAUdpConnection;
@class AFHTTPSessionManager;
@class MAGameManager;

@protocol MAGameManagerDelegate
- (void)coin:(NSString *)identifier wasClaimedByTeam:(NSString *)color;
- (void)player:(NSString *)identifier didMoveToLocation:(CLLocation *)location;
- (void)team:(NSString *)color didReceivePoints:(NSInteger)points;
- (void)team:(NSString *)color setScore:(NSInteger)score;

- (void)team:(NSString *)color addPlayerWithIdentifier:(NSString *)identifier
        name:(NSString *)name
       score:(NSInteger)score
    location:(CLLocation *)location;

// if `color` is `nil`, coin has not been claimed yet
//
- (void)team:(NSString *)color addCoinWithIdentifier:(NSString *)identifier
    location:(CLLocation *)location
      points:(NSInteger)points;

- (void)gameDidStart;
- (void)gameDidEnd;
- (void)didFetchIcon:(UIImage *)icon forPlayerId:(NSString *)playerId;
@end

@interface MAGameManager : NSObject <CLLocationManagerDelegate, MAUdpConnectionDelegate>
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic, readonly) MAUdpConnection *udpConnection;
@property (strong, nonatomic, readonly) NSString *joinedGameId;
@property (strong, nonatomic, readonly) NSString *joinedGameName;
@property (strong, nonatomic, readonly) NSString *joinedTeamColor;
@property (copy, nonatomic, readonly) NSDictionary *joinedGameBoard;
@property (copy, nonatomic, readonly) NSDictionary *lastBoardStateDict;
@property (assign, nonatomic, readonly) NSInteger redScore;
@property (assign, nonatomic, readonly) NSInteger blueScore;
@property (assign, nonatomic, readonly) NSInteger playerScore;
@property (weak, nonatomic) id <MAGameManagerDelegate, NSObject> delegate;

+ (MAGameManager *)sharedManager;

- (void)registerDeviceWithCompletionBlock:(void (^)(NSError *))completion;
- (void)registerPushToken:(NSData *)pushToken;
- (void)beginMonitoringNearbyBoardsWithBlock:(void (^)(NSArray *games, NSError *))completion;
- (void)stopMonitoringNearbyGames;

- (void)joinGameOnBoard:(NSDictionary *)board completion:(void (^)(NSError *error, NSDictionary *response))completion;
- (void)createGameForBoard:(NSDictionary *)board completion:(void (^)(NSError *error, NSDictionary *response))completion;
- (void)startGame;
- (void)endGame;
- (void)fetchBoardStateForBoardId:(NSString *)boardId completion:(void (^)(NSDictionary *board, NSArray *coins, NSError *error))completion;

- (void)startPollingGameState;
- (void)fetchIconForPlayerId:(NSString *)playerId;

- (MKCoordinateRegion)regionForJoinedBoard;
- (MKCoordinateRegion)regionForBoard:(NSDictionary *)board;

@end
