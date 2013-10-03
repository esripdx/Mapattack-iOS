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
@property (strong, nonatomic) NSString *joinedTeamColor;
@property (copy, nonatomic, readwrite) NSDictionary *joinedGameBoard;
@property (copy, nonatomic, readwrite) NSDictionary *lastBoardStateDict;
@property (strong, nonatomic) NSTimer *syncTimer;

@end

@implementation MAGameManager {
    BOOL _pushTokenRegistered;
    MAApiConnection *_api;
    AFHTTPSessionManager *_imageFetcher;
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
    self.locationManager.distanceFilter = kMARealTimeDistanceFilter;

    self.gameListLocationManager = [[CLLocationManager alloc] init];
    self.gameListLocationManager.delegate = self;
    self.gameListLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.gameListLocationManager.distanceFilter = kMAGameListDistanceFilter;

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
              params:@{ kMAApiLatitudeKey: @(self.gameListLocationManager.location.coordinate.latitude),
                        kMAApiLongitudeKey: @(self.gameListLocationManager.location.coordinate.longitude) }];
}

#pragma mark - Game creating/joining

- (NSString *)joinedGameId {
    return (NSString *)_joinedGameBoard[kMAApiGameKey][kMAApiGameIdKey];
}

- (NSString *)joinedGameName {
    return (NSString *)_joinedGameBoard[kMAApiNameKey];
}

- (void)joinGameOnBoard:(NSDictionary *)board completion:(void (^)(NSError *error, NSDictionary *response))completion {
    [self registerForPushToken];
    
    DDLogVerbose(@"Joining game: %@", board[kMAApiGameKey][kMAApiGameIdKey]);
    
    MAApiSuccessHandler gameJoinSuccess = ^(NSDictionary *response) {
        DDLogVerbose(@"game/join response: %@", response);
        self.joinedGameBoard = board;
        self.joinedTeamColor = response[kMAApiTeamKey];
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
        self.joinedTeamColor = response[kMAApiTeamKey];
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
            completion(response[kMAApiBoardKey], response[kMAApiCoinsKey], nil);
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
            kMAApiLatitudeKey: @(location.coordinate.latitude),
            kMAApiLongitudeKey: @(location.coordinate.longitude),
            kMAApiTimestampKey: @(location.timestamp.timeIntervalSince1970),
            kMAApiAccuracyKey: @(location.horizontalAccuracy),
            kMAApiSpeedKey: @(location.speed),
            kMAApiBearingKey: @(location.course),
            kMAApiAccessTokenKey: _api.accessToken
        };
        [self.udpConnection sendDictionary:update];
    }];
}

#pragma mark - TCP State handlers

- (void)registerGameStateSuccessHandler {
    MAApiSuccessHandler gameStateSuccess = ^(NSDictionary *response) {
        [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqualToString:kMAApiPlayersKey]) {
                [self handlePlayersUpdate:obj];
            } else if ([key isEqualToString:kMAApiCoinsKey]) {
                [self handleCoinsUpdate:obj];
            } else if ([key isEqualToString:kMAApiGameKey]) {
                [self handleGameUpdate:obj];
            }
        }];
    };
    [_api registerSuccessHandler:gameStateSuccess forPath:kMAApiGameStatePath];
}

- (void)handlePlayersUpdate:(NSArray *)playersUpdate {
    DDLogVerbose(@"about to iterate players...");
    if ([self.delegate respondsToSelector:@selector(team:addPlayerWithIdentifier:name:score:location:)]) {
        
        DDLogVerbose(@"iterating players...");
        for (NSDictionary *player in playersUpdate) {
            
            NSString *teamColor = player[kMAApiTeamKey];
            NSString *playerId = player[kMAApiDeviceIdKey];
            NSNumber *score = player[kMAApiScoreKey];
            NSNumber *latitude = player[kMAApiLatitudeKey];
            NSNumber *longitude = player[kMAApiLongitudeKey];
            CLLocation *playerLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                                    longitude:[longitude doubleValue]];
            
            DDLogVerbose(@"adding player %@ - %@ (%@) at %@,%@", playerId, player[kMAApiNameKey], score, latitude, longitude);
            [self.delegate team:teamColor addPlayerWithIdentifier:playerId
                           name:player[kMAApiNameKey]
                          score:[score integerValue]
                       location:playerLocation];
        }
    }
}

- (void)handleCoinsUpdate:(NSArray *)coinsUpdate {
    DDLogVerbose(@"about to iterate coins...");
    if ([self.delegate respondsToSelector:@selector(team:addCoinWithIdentifier:location:points:)]) {
        
        DDLogVerbose(@"iterating coins...");
        for (NSDictionary *coin in coinsUpdate) {
            
            NSString *teamColor = coin[kMAApiTeamKey];
            NSString *coinId = coin[kMAApiCoinIdKey];
            NSNumber *points = coin[kMAApiPointsKey];
            NSNumber *latitude = coin[kMAApiLatitudeKey];
            NSNumber *longitude = coin[kMAApiLongitudeKey];
            CLLocation *coinLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                                  longitude:[longitude doubleValue]];
            DDLogVerbose(@"adding coin %@ (%@) at %@,%@", coinId, points, latitude, longitude);
            [self.delegate team:teamColor addCoinWithIdentifier:coinId
                       location:coinLocation
                         points:[points integerValue]];
        }
    }
}

- (void)handleGameUpdate:(NSDictionary *)gameUpdate {
    DDLogVerbose(@"about to set scores...");
    if ([self.delegate respondsToSelector:@selector(team:setScore:)]){
        DDLogVerbose(@"setting scores...");
        [self.delegate team:kMAApiRedKey
                   setScore:[(NSNumber *)gameUpdate[kMAApiTeamsKey][kMAApiRedKey][kMAApiScoreKey] integerValue]];
        [self.delegate team:kMAApiBlueKey
                   setScore:[(NSNumber *)gameUpdate[kMAApiTeamsKey][kMAApiBlueKey][kMAApiScoreKey] integerValue]];
    }
}

#pragma mark - UDP State handlers

- (void)handleUdpDictionary:(NSDictionary *)dictionary {
    NSArray *keys = [dictionary allKeys];
    if ([keys containsObject:kMAApiCoinIdKey]) {
        [self handleUdpCoinUpdate:dictionary];
    } else if ([keys containsObject:kMAApiDeviceIdKey]) {
        [self handleUdpPlayerUpdate:dictionary];
    } else if ([keys containsObject:kMAApiBoardIdKey]) {
        [self handleUdpBoardUpdate:dictionary];
    }
}

- (void)handleUdpCoinUpdate:(NSDictionary *)coinUpdate {
    DDLogVerbose(@"got coin update");
    NSString *teamColor = coinUpdate[kMAApiTeamKey];
    NSString *coinId = coinUpdate[kMAApiCoinIdKey];
    NSNumber *redScore = coinUpdate[kMAApiRedScoreKey];
    NSNumber *blueScore = coinUpdate[kMAApiBlueScoreKey];
    NSString *playerId = coinUpdate[kMAApiDeviceIdKey];
    NSNumber *playerScore = coinUpdate[kMAApiPlayerScoreKey];
    if ([self.delegate respondsToSelector:@selector(coin:wasClaimedByPlayerId:withScore:forTeam:)]) {
        DDLogVerbose(@"setting coinId %@ claimed by %@", coinId, teamColor);
        [self.delegate coin:coinId wasClaimedByPlayerId:playerId withScore:[playerScore integerValue] forTeam:teamColor];
    }
    if ([self.delegate respondsToSelector:@selector(team:setScore:)]) {
        DDLogVerbose(@"setting team red score to %@", redScore);
        [self.delegate team:kMAApiRedKey setScore:[redScore integerValue]];
        DDLogVerbose(@"setting team blue score to %@", blueScore);
        [self.delegate team:kMAApiBlueKey setScore:[blueScore integerValue]];
    }
}

- (void)handleUdpPlayerUpdate:(NSDictionary *)playerUpdate {
    DDLogVerbose(@"got device update");
    NSString *playerId = playerUpdate[kMAApiDeviceIdKey];
    NSNumber *latitude = playerUpdate[kMAApiLatitudeKey];
    NSNumber *longitude = playerUpdate[kMAApiLongitudeKey];
    CLLocation *playerLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                            longitude:[longitude doubleValue]];
    if ([self.delegate respondsToSelector:@selector(player:didMoveToLocation:)]) {
        DDLogVerbose(@"moving playerId %@ to %@,%@", playerId, latitude, longitude);
        [self.delegate player:playerId didMoveToLocation:playerLocation];
    }
}

- (void)handleUdpBoardUpdate:(NSDictionary *)boardUpdate {
    DDLogVerbose(@"got board update");
    NSNumber *redScore = boardUpdate[kMAApiRedScoreKey];
    NSNumber *blueScore = boardUpdate[kMAApiBlueScoreKey];
    if ([self.delegate respondsToSelector:@selector(team:setScore:)]) {
        DDLogVerbose(@"setting team red score to %@", redScore);
        [self.delegate team:kMAApiRedKey setScore:[redScore integerValue]];
        DDLogVerbose(@"setting team blue score to %@", blueScore);
        [self.delegate team:kMAApiBlueKey setScore:[blueScore integerValue]];
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
            poteKey = kMAApiApnsSandboxTokenKey;
            break;
        case MAPushTokenTypeProduction:
            poteKey = kMAApiApnsProductionTokenKey;
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
    NSArray *bbox = board[kMAApiBoundingBoxKey];
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

- (void)fetchIconForPlayerId:(NSString *)playerId {
    
    if (!_imageFetcher) {
        _imageFetcher = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:MAPATTACK_URL]];
        _imageFetcher.requestSerializer = [AFHTTPRequestSerializer serializer];
        _imageFetcher.responseSerializer = [AFImageResponseSerializer serializer];
    }
    
    [_imageFetcher GET:[NSString stringWithFormat:@"/user/%@.jpg", playerId] parameters:nil success:^(NSURLSessionDataTask *task, UIImage *avatar) {
        DDLogVerbose(@"user/%@.jpg response: %@", playerId, avatar);
        if ([self.delegate respondsToSelector:@selector(didFetchIcon:forPlayerId:)]) {
            if (avatar && avatar.size.height > 0 && avatar.size.width > 0) {
                [self.delegate didFetchIcon:avatar forPlayerId:playerId];
            } else {
                DDLogError(@"fetched avatar image is 0x0!");
            }
        }
    } failure:nil];
    
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