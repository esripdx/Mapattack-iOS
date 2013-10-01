//
//  MAGameManager.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/19/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MAGameManager.h"
#import "NSString+UrlEncoding.h"
#import "NSData+Conversion.h"
#import "MAApiConnection.h"

@interface MAGameManager()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocationManager *gameListLocationManager;
@property (strong, nonatomic) MAUdpConnection *udpConnection;
@property (strong, nonatomic) AFHTTPSessionManager *tcpConnection;
@property (copy, nonatomic, readwrite) NSDictionary *joinedGameBoard;
@property (copy, nonatomic, readwrite) NSDictionary *lastBoardStateDict;
@property (strong, nonatomic) NSTimer *syncTimer;

@end

@implementation MAGameManager {
    NSString *_accessToken;
    BOOL _pushTokenRegistered;
    MAApiConnection *_api;
}

+ (MAGameManager *)sharedManager {
    static MAGameManager *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _pushTokenRegistered = NO;

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;

    self.gameListLocationManager = [[CLLocationManager alloc] init];
    self.gameListLocationManager.delegate = self;
    self.gameListLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.gameListLocationManager.distanceFilter = 50;

    self.udpConnection = [[MAUdpConnection alloc] initWithDelegate:self];
    
    _api = [MAApiConnection new];
    [self registerGameStartAndEndHandlers];

    return self;
}

#pragma mark - Device registration

- (void)registerDeviceWithCompletionBlock:(void (^)(NSError *))completion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [defaults stringForKey:kMADefaultsUserNameKey];
    NSString *avatar = [[[defaults dataForKey:kMADefaultsAvatarKey] base64EncodedStringWithOptions:0] urlEncode];
    MAApiSuccessHandler deviceRegisterSuccess = ^(NSDictionary *response) {
        NSString *dk = response[kMAApiDeviceIdKey];
        NSString *at = response[kMAApiAccessTokenKey];
        DDLogVerbose(@"Device (%@) registered with token: %@.", dk, at);
        [defaults setValue:dk forKey:kMADefaultsDeviceIdKey];
        [defaults setValue:at forKey:kMADefaultsAccessTokenKey];
        [defaults synchronize];
        if (completion != nil) {
            completion(nil);
        }
    };
    [_api postToPath:kMAApiDeviceRegisterPath
              params:@{ kMAApiNameKey: userName, kMAApiAvatarKey: avatar }
             success:deviceRegisterSuccess
               error:^(NSError *error) {
                   if (completion != nil) {
                       completion(error);
                   }
               }];
}

#pragma mark - Board monitoring

- (void)beginMonitoringNearbyBoardsWithBlock:(void (^)(NSArray *games, NSError *))completion {
    MAApiSuccessHandler boardListSuccess = ^(NSDictionary *response) {
        NSArray *boards = response[@"boards"];
        DDLogVerbose(@"Found %lu board%@ nearby", (unsigned long)boards.count, boards.count == 1 ? @"" : @"s");
        for (NSDictionary *game in boards) {
            DDLogVerbose(@"got game: %@", game);
        }
        if (completion != nil) {
            completion(boards, nil);
        }
    };
    MAApiErrorHandler boardListError = ^(NSError *error) {
        DDLogError(@"Error joining game: %@", [error debugDescription]);
        if (completion != nil) {
            completion(nil, error);
        }
    };
    [_api registerSuccessHandler:boardListSuccess forPath:kMAApiBoardListPath];
    [_api registerErrorHandler:boardListError forPath:kMAApiBoardListPath];
    DDLogVerbose(@"Getting user's location for game list...");
    [self.gameListLocationManager startUpdatingLocation];
}

- (void)stopMonitoringNearbyGames {
    DDLogVerbose(@"Stopping game list location updates.");
    [self.gameListLocationManager stopUpdatingLocation];
}

- (void)postLocationBoardList {
    DDLogVerbose(@"Fetching nearby games: %@", self.gameListLocationManager.location);
    [_api postToPath:kMAApiBoardListPath
              params:@{ @"latitude": @(self.gameListLocationManager.location.coordinate.latitude),
                        @"longitude": @(self.gameListLocationManager.location.coordinate.longitude) }];
}

#pragma mark - Game creating/joining

- (NSString *)joinedGameId {
    return (NSString *)_joinedGameBoard[kMAApiGameKey][kMAApiGameIdKey];
}

- (NSString *)joinedGameName {
    return (NSString *)_joinedGameBoard[kMAApiNameKey];
}

- (NSString *)joinedTeamColor {
    return (NSString *)_joinedGameBoard[kMAApiGameKey][kMAApiTeamKey];
}

- (void)joinGameOnBoard:(NSDictionary *)board completion:(void (^)(NSError *error, NSDictionary *response))completion {
    [self registerForPushToken];
    
    DDLogVerbose(@"Joining game: %@", board[kMAApiGameKey][kMAApiGameIdKey]);
    
    MAApiSuccessHandler gameJoinSuccess = ^(NSDictionary *response) {
        DDLogVerbose(@"game/join response: %@", response);
        self.joinedGameBoard = board;
        if (completion != nil) {
            completion(nil, response);
        }
        if (board[kMAApiGameKey][kMAApiActiveKey]) {
            [self.locationManager startUpdatingLocation];
        }
        [self startPollingGameState];
        
    };
    MAApiErrorHandler gameJoinError = ^(NSError *error) {
        DDLogError(@"Error joining game: %@", [error debugDescription]);
        if (completion != nil) {
            completion(error, nil);
        }
    };
    [_api postToPath:kMAApiGameJoinPath
              params:@{ kMAApiGameIdKey: board[kMAApiGameKey][kMAApiGameIdKey]}
             success:gameJoinSuccess
               error:gameJoinError];
}

- (void)createGameForBoard:(NSDictionary *)board completion:(void (^)(NSError *error, NSDictionary *response))completion {
    [self registerForPushToken];
    
    DDLogVerbose(@"Creating game for board: %@", board[kMAApiBoardIdKey]);
    
    MAApiSuccessHandler gameCreateSuccess = ^(NSDictionary *response) {
        DDLogVerbose(@"game/create response: %@", response);
        self.joinedGameBoard = board;
        if (completion != nil) {
            completion(nil, response);
        }
    };
    MAApiErrorHandler gameCreateError = ^(NSError *error) {
        DDLogError(@"Error creating game: %@", [error debugDescription]);
        if (completion != nil) {
            completion(error, nil);
        }
    };
    
    [_api postToPath:kMAApiGameCreatePath
              params:@{ kMAApiBoardIdKey: board[kMAApiBoardIdKey] }
             success:gameCreateSuccess
               error:gameCreateError];
}

#pragma mark - Game state/controls

- (void)registerGameStartAndEndHandlers {
    
    [_api registerSuccessHandler:^(NSDictionary *response) {
        [self.locationManager startUpdatingLocation];
        [self startPollingGameState];
        if ([self.delegate respondsToSelector:@selector(gameDidStart)]) {
            [self.delegate gameDidStart];
        }
    } forPath:kMAApiGameStartPath];
    
    [_api registerSuccessHandler:^(NSDictionary *response) {
        [self.locationManager stopUpdatingLocation];
        [self stopPollingGameState];
        if ([self.delegate respondsToSelector:@selector(gameDidEnd)]) {
            [self.delegate gameDidEnd];
        }
    } forPath:kMAApiGameEndPath];
    
}

- (void)startGame {
    [_api postToPath:kMAApiGameStartPath params:@{ kMAApiGameIdKey: self.joinedGameId }];
}

- (void)endGame {
    [_api postToPath:kMAApiGameEndPath params:@{ kMAApiGameIdKey: self.joinedGameId }];
}

- (void)fetchBoardStateForBoardId:(NSString *)boardId
                       completion:(void (^)(NSDictionary *board, NSArray *coins, NSError *error))completion {
    
    DDLogVerbose(@"fetching board state for board: %@", boardId);
    
    MAApiSuccessHandler boardStateSuccess = ^(NSDictionary *response) {
        self.lastBoardStateDict = response;
        DDLogVerbose(@"board state response: %@", response);
        if (completion != nil) {
            completion(response[@"board"], response[@"coins"], nil);
        }
    };
    
    [_api postToPath:kMAApiBoardStatePath
              params:@{ kMAApiBoardIdKey: boardId }
             success:boardStateSuccess];
}

- (void)startPollingGameState {
    [self registerGameStateSuccessHandler];
    [self syncGameState];
    DDLogVerbose(@"starting game state polling timer every %d seconds", kMAGameStatePollingInterval);
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:kMAGameStatePollingInterval
                                                      target:self
                                                    selector:@selector(syncGameState)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)stopPollingGameState {
    DDLogVerbose(@"invalidating game state polling timer");
    [self.syncTimer invalidate];
}

- (void)syncGameState {
    DDLogVerbose(@"syncing game state");
    [_api postToPath:kMAApiGameStatePath params:@{ kMAApiGameIdKey: self.joinedGameId }];
    // TODO: if it errors, tell the user about it in some way? Maybe just keep track how many times we fail a sync
}

- (void)sendLocationsViaUdp:(NSArray *)locations {
    if (!_api.accessToken) {
        DDLogError(@"Tried to send locations via UDP without an access token!");
        return;
    }
    [locations enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        NSDictionary *update = @{
            @"latitude": @(location.coordinate.latitude),
            @"longitude": @(location.coordinate.longitude),
            @"timestamp": @(location.timestamp.timeIntervalSince1970),
            @"accuracy": @(location.horizontalAccuracy),
            @"speed": @(location.speed),
            @"bearing": @(location.course),
            @"access_token": _api.accessToken
        };
        [self.udpConnection sendDictionary:update];
    }];
}

#pragma mark - State handlers

- (void)registerGameStateSuccessHandler {
    MAApiSuccessHandler gameStateSuccess = ^(NSDictionary *response) {
        [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqualToString:@"players"]) {
                DDLogVerbose(@"about to iterate players...");
                if ([self.delegate respondsToSelector:@selector(team:addPlayerWithIdentifier:name:score:location:)]) {
                    DDLogVerbose(@"iterating players...");
                    for (NSDictionary *player in obj) {
                        NSString *teamColor = player[@"team"];
                        NSString *playerId = player[@"device_id"];
                        NSNumber *score = player[@"score"];
                        NSNumber *latitude = player[@"latitude"];
                        NSNumber *longitude = player[@"longitude"];
                        CLLocation *playerLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                                                longitude:[longitude doubleValue]];
                        DDLogVerbose(@"adding player %@ - %@ (%@) at %@,%@", playerId, player[@"name"], score, latitude, longitude);
                        [self.delegate team:teamColor addPlayerWithIdentifier:playerId
                                       name:player[@"name"]
                                      score:[score integerValue]
                                   location:playerLocation];
                    }
                }
            } else if ([key isEqualToString:@"coins"]) {
                DDLogVerbose(@"about to iterate coins...");
                if ([self.delegate respondsToSelector:@selector(team:addCoinWithIdentifier:location:points:)]) {
                    DDLogVerbose(@"iterating coins...");
                    for (NSDictionary *coin in obj) {
                        NSString *teamColor = coin[@"team"];
                        NSString *coinId = coin[@"coin_id"];
                        NSNumber *points = coin[@"value"];
                        NSNumber *latitude = coin[@"latitude"];
                        NSNumber *longitude = coin[@"longitude"];
                        CLLocation *coinLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                                              longitude:[longitude doubleValue]];
                        DDLogVerbose(@"adding coin %@ (%@) at %@,%@", coinId, points, latitude, longitude);
                        [self.delegate team:teamColor addCoinWithIdentifier:coinId location:coinLocation points:[points integerValue]];
                    }
                }
            } else if ([key isEqualToString:@"game"]) {
                DDLogVerbose(@"about to set scores...");
                if ([self.delegate respondsToSelector:@selector(team:setScore:)]){
                    DDLogVerbose(@"setting scores...");
                    [self.delegate team:@"red" setScore:[(NSNumber *)obj[@"teams"][@"red"][@"score"] integerValue]];
                    [self.delegate team:@"blue" setScore:[(NSNumber *)obj[@"teams"][@"blue"][@"score"] integerValue]];
                }
            }
        }];
    };
    [_api registerSuccessHandler:gameStateSuccess forPath:kMAApiGameStatePath];
}

- (void)handleUdpDictionary:(NSDictionary *)dictionary {
    NSArray *keys = [dictionary allKeys];
    if ([keys containsObject:@"coin_id"]) {
        DDLogVerbose(@"got coin update");
        NSString *teamColor = dictionary[@"team"];
        NSString *coinId = dictionary[@"coin_id"];
        NSNumber *redScore = dictionary[@"red_score"];
        NSNumber *blueScore = dictionary[@"blue_score"];
        if ([self.delegate respondsToSelector:@selector(coin:wasClaimedByTeam:)]) {
            DDLogVerbose(@"setting coinId %@ claimed by %@", coinId, teamColor);
            [self.delegate coin:coinId wasClaimedByTeam:teamColor];
        }
        if ([self.delegate respondsToSelector:@selector(team:setScore:)]) {
            DDLogVerbose(@"setting team red score to %@", redScore);
            [self.delegate team:@"red" setScore:[redScore integerValue]];
            DDLogVerbose(@"setting team blue score to %@", blueScore);
            [self.delegate team:@"blue" setScore:[blueScore integerValue]];
        }
    } else if ([keys containsObject:@"device_id"]) {
        DDLogVerbose(@"got device update");
        NSString *playerId = dictionary[@"device_id"];
        NSNumber *latitude = dictionary[@"latitude"];
        NSNumber *longitude = dictionary[@"longitude"];
        CLLocation *playerLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                                longitude:[longitude doubleValue]];
        if ([self.delegate respondsToSelector:@selector(player:didMoveToLocation:)]) {
            DDLogVerbose(@"setting playerId %@ to location %@", playerId, playerLocation);
            [self.delegate player:playerId didMoveToLocation:playerLocation];
        }
    } else if ([keys containsObject:@"board_id"]) {
        DDLogVerbose(@"got board update");
        NSNumber *redScore = dictionary[@"red_score"];
        NSNumber *blueScore = dictionary[@"blue_score"];
        if ([self.delegate respondsToSelector:@selector(team:setScore:)]) {
            DDLogVerbose(@"setting team red score to %@", redScore);
            [self.delegate team:@"red" setScore:[redScore integerValue]];
            DDLogVerbose(@"setting team blue score to %@", blueScore);
            [self.delegate team:@"blue" setScore:[blueScore integerValue]];
        }
    }
}

#pragma mark - T0t3s p0t3z

- (void)registerForPushToken {
    if (!_pushTokenRegistered) {
        DDLogVerbose(@"registering for push token");
        UIRemoteNotificationType poteType = (UIRemoteNotificationTypeBadge |
                                             UIRemoteNotificationTypeSound |
                                             UIRemoteNotificationTypeAlert);
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:poteType];
    }
}

- (void)registerPushToken:(NSData *)pushToken {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:pushToken forKey:kMADefaultsPushTokenKey];
    [defs synchronize];

    NSString *poteKey;
    switch ((int)kPushTokenType) {
        case MAPushTokenTypeSandbox:
            poteKey = @"apns_sandbox_token";
            break;
        case MAPushTokenTypeProduction:
            poteKey = @"apns_prod_token";
            break;
    }
    if (pushToken) {
        [_api postToPath:kMAApiDeviceRegisterPushPath
                  params:@{ poteKey: [pushToken hexadecimalString] }
                 success:^(NSDictionary *response) { _pushTokenRegistered = YES; }];
    } else {
        DDLogError(@"no push token data!");
    }
}

#pragma mark - Helpers

- (MKCoordinateRegion)regionForJoinedBoard {
    return [self regionForBoard:self.joinedGameBoard];
}

- (MKCoordinateRegion)regionForBoard:(NSDictionary *)board {
    NSArray *bbox = board[@"bbox"];
    double lng1 = [bbox[0] doubleValue];
    double lat1 = [bbox[1] doubleValue];
    double lng2 = [bbox[2] doubleValue];
    double lat2 = [bbox[3] doubleValue];

    MKCoordinateSpan span;
    span.latitudeDelta = fabs(lat2 - lat1);
    span.longitudeDelta = fabs(lng2 - lng1);

    CLLocationCoordinate2D center;
    center.latitude = fmax(lat1, lat2) - (span.latitudeDelta/2.0);
    center.longitude = fmax(lng1, lng2) - (span.longitudeDelta/2.0);

    MKCoordinateRegion region;
    region.span = span;
    region.center = center;
    return region;
}

#pragma mark - MAUdpConnectionDelegate methods

- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveArray:(NSArray *)array {
//    DDLogVerbose(@"Received udp array: %@", array);
}

- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveDictionary:(NSDictionary *)dictionary {
//    DDLogVerbose(@"Received udp dictionary: %@", dictionary);
    [self handleUdpDictionary:dictionary];
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (manager == self.gameListLocationManager) {
        [self postLocationBoardList];
    } else if (manager == self.locationManager) {
        [self sendLocationsViaUdp:locations];
    }
}

@end