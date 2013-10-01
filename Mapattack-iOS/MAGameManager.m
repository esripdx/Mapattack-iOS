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

@interface MAGameManager()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocationManager *gameListLocationManager;
@property (strong, nonatomic) MAUdpConnection *udpConnection;
@property (strong, nonatomic) AFHTTPSessionManager *tcpConnection;
@property (copy, nonatomic) void (^listGamesCompletionBlock)(NSArray *games, NSError *error);
@property (strong, nonatomic) NSString *joinedGameId;
@property (strong, nonatomic) NSString *joinedGameName;
@property (strong, nonatomic) NSString *joinedTeamColor;
@property (copy, nonatomic, readwrite) NSDictionary *joinedGameBoard;
@property (copy, nonatomic, readwrite) NSDictionary *lastBoardStateDict;
@property (strong, nonatomic) NSTimer *syncTimer;

@end

@implementation MAGameManager {
    NSString *_accessToken;
    BOOL _pushTokenRegistered;
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

    self.tcpConnection = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:kMapAttackURL]];
    self.tcpConnection.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.tcpConnection.responseSerializer = [AFJSONResponseSerializer serializer];

    return self;
}

- (NSString *)accessToken {
    if (!_accessToken) {
        _accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsAccessTokenKey];
    }
    return _accessToken;
}

#pragma mark - Device registration

- (void)registerDeviceWithCompletionBlock:(void (^)(NSError *))completion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [defaults stringForKey:kMADefaultsUserNameKey];
    NSString *avatar = [[[defaults dataForKey:kMADefaultsAvatarKey] base64EncodedStringWithOptions:0] urlEncode];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"name": userName,
        @"avatar": avatar
    }];
    [params setValue:self.accessToken forKey:@"access_token"];

    [self.tcpConnection POST:@"/device/register"
                  parameters:params
                     success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                         [defaults setValue:responseObject[@"device_id"] forKey:kMADefaultsDeviceIdKey];
                         [defaults setValue:responseObject[@"access_token"] forKey:kMADefaultsAccessTokenKey];
                         [defaults synchronize];
                         
                         DDLogVerbose(@"Device (%@) registered with token: %@.", responseObject[@"device_id"], responseObject[@"access_token"]);
                         if (completion != nil) {
                             completion(nil);
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error registering device: %@", [error debugDescription]);
                         if (completion != nil) {
                             completion(error);
                         }
                     }];
}

#pragma mark - Board monitoring

- (void)beginMonitoringNearbyBoardsWithBlock:(void (^)(NSArray *games, NSError *))completion {
    if (!self.accessToken) {
        DDLogError(@"Tried to get nearby games without an access token!");
        // TODO: Send user back to launch view with an alert telling them to try logging in again.
        return;
    }

    self.listGamesCompletionBlock = completion;
    DDLogVerbose(@"Getting user's location for game list...");
    [self.gameListLocationManager startUpdatingLocation];
}

- (void)stopMonitoringNearbyGames {
    DDLogVerbose(@"Stopping game list location updates.");
    [self.gameListLocationManager stopUpdatingLocation];
    self.listGamesCompletionBlock = nil;
}

- (void)gameListLocationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    DDLogVerbose(@"Fetching nearby games: %@", manager.location);
    if (!self.accessToken) {
        DDLogError(@"Tried to update location for nearby games without an access token!");
        return;
    }
    
    NSDictionary *params = @{
        @"access_token": self.accessToken,
        @"latitude": @(manager.location.coordinate.latitude),
        @"longitude": @(manager.location.coordinate.longitude)
    };
    
    [self.tcpConnection POST:@"/board/list"
                  parameters:params
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         NSArray *boards = responseObject[@"boards"];
                         DDLogVerbose(@"Found %lu board%@ nearby", (unsigned long)boards.count, boards.count == 1 ? @"" : @"s");
                         for (NSDictionary *game in boards) {
                             DDLogVerbose(@"got game: %@", game);
                         }
                         
                         if (self.listGamesCompletionBlock != nil) {
                             self.listGamesCompletionBlock(boards, nil);
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Failed to retrieve nearby games: %@", [error debugDescription]);
                         if (self.listGamesCompletionBlock != nil) {
                             self.listGamesCompletionBlock(nil, error);
                         }
                     }];
}

#pragma mark - Game creating/joining

- (void)joinGameOnBoard:(NSDictionary *)board completion:(void (^)(NSError *error, NSDictionary *response))completion {
    [self registerForPushToken];
    NSDictionary *game = board[@"game"];
    NSString *gameId = game[@"game_id"];
    DDLogVerbose(@"Joining game: %@", gameId);
    [self.tcpConnection POST:@"/game/join"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"game_id": gameId
                  }
                     success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         NSError *error = nil;
                         if (errorJson != nil) {
                             DDLogError(@"Error creating game: %@", errorJson);
                             error = [NSError errorWithDomain:@"com.esri.portland.mapattack" code:400 userInfo:errorJson];
                         }
                         DDLogVerbose(@"game/join response: %@", responseObject);
                         self.joinedGameBoard = board;
                         self.joinedGameName = board[@"name"];
                         self.joinedGameId = gameId;
                         self.joinedTeamColor = responseObject[@"team"];
                         if (completion != nil) {
                             completion(error, responseObject);
                         }
                         if (game[@"active"]) {
                             [self.locationManager startUpdatingLocation];
                         }
                         [self startPollingGameState];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error joining game: %@", [error debugDescription]);
                         if (completion != nil) {
                             completion(error, nil);
                         }
                     }];
}

- (void)createGameForBoard:(NSDictionary *)board completion:(void (^)(NSError *error, NSDictionary *response))completion {
    [self registerForPushToken];
    NSString *boardId = board[@"board_id"];
    NSString *boardName = board[@"name"];
    DDLogVerbose(@"Creating game for board: %@", boardId);
    [self.tcpConnection POST:@"game/create"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"board_id": boardId
                  }
                     success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         NSError *error = nil;
                         if (errorJson != nil) {
                             DDLogError(@"Error creating game: %@", errorJson);
                             error = [NSError errorWithDomain:@"com.esri.portland.mapattack" code:400 userInfo:errorJson];
                         }
                         DDLogVerbose(@"game/create response: %@", responseObject);
                         self.joinedGameId = responseObject[@"game_id"];
                         self.joinedTeamColor = responseObject[@"team"];
                         self.joinedGameName = boardName;
                         self.joinedGameBoard = board;
                         if (completion != nil) {
                             completion(error, responseObject);
                         }
                         
                         // shouldn't this happen after game is started? -kn
                         // [self startPollingGameState];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error creating game: %@", [error debugDescription]);
                         if (completion != nil) {
                             completion(error, nil);
                         }
                     }];
}

#pragma mark - Game state/controls

- (void)startGame {
    [self.tcpConnection POST:@"game/start"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"game_id": self.joinedGameId
                  }
                     success:^(NSURLSessionTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error starting game: %@", errorJson);
                             return;
                         }

                         [self.locationManager startUpdatingLocation];
                         [self startPollingGameState];
                         if ([self.delegate respondsToSelector:@selector(gameDidStart)]) {
                             [self.delegate gameDidStart];
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error starting game: %@", [error debugDescription]);
                     }];
}

- (void)endGame {
    [self.tcpConnection POST:@"game/end"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"game_id": self.joinedGameId
                  }
                     success:^(NSURLSessionTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error ending game: %@", errorJson);
                             return;
                         }

                         [self.locationManager stopUpdatingLocation];
                         [self stopPollingGameState];
                         if ([self.delegate respondsToSelector:@selector(gameDidEnd)]) {
                             [self.delegate gameDidEnd];
                         }
                     }
                     failure:^(NSURLSessionTask *task, NSError *error) {
                         DDLogError(@"Error ending game: %@", [error debugDescription]);
                     }];
}

- (void)fetchBoardStateForBoard:(NSString *)boardId completion:(void (^)(NSDictionary *board, NSArray *coins, NSError *error))completion {
    DDLogVerbose(@"fetching board state for board: %@", boardId);
    [self.tcpConnection POST:@"/board/state"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"board_id": boardId
                  }
                     success:^(NSURLSessionTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         NSError *e;
                         if (errorJson != nil) {
                             DDLogError(@"Error retrieving board state: %@", errorJson);
                             e = [NSError errorWithDomain:@"com.esri.portland.mapattack" code:400 userInfo:errorJson];
                         } else {
                             self.lastBoardStateDict = responseObject;
                         }

                         DDLogVerbose(@"board state response: %@", responseObject);
                         if (completion != nil) {
                             completion(responseObject[@"board"], responseObject[@"coins"], e);
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *e) {
                         DDLogError(@"Error retrieving board state: %@", [e debugDescription]);
                         if (completion != nil) {
                             completion(nil, nil, e);
                         }
                     }];
}

- (void)startPollingGameState {
    DDLogVerbose(@"starting polling game state");
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(syncGameState) userInfo:nil repeats:YES];
}

- (void)stopPollingGameState {
    [self.syncTimer invalidate];
}

- (void)syncGameState {
    DDLogVerbose(@"syncing game state");
    [self.tcpConnection POST:@"/game/state"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"game_id": self.joinedGameId
                  }
                     success:^(NSURLSessionDataTask *task, id responseObject) {
//                         DDLogVerbose(@"received game/state response... %@", responseObject);
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error syncing game state: %@", errorJson);
                         } else {
                             [self handleGameStateResponse:responseObject];
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error syncing game state: %@", [error debugDescription]);

                         // TODO: Tell the user about this in some way? Maybe just keep track how many times we fail a sync
                         // and notify the user after missing so many.
                     }];
}

- (void)sendLocationsViaUdp:(NSArray *)locations {
    if (!self.accessToken) {
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
            @"access_token": self.accessToken
        };
        [self.udpConnection sendDictionary:update];
    }];
}

#pragma mark - State handlers

- (void)handleGameStateResponse:(NSDictionary *)response {
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
//        DDLogVerbose(@"got device update");
        NSString *playerId = dictionary[@"device_id"];
        NSNumber *latitude = dictionary[@"latitude"];
        NSNumber *longitude = dictionary[@"longitude"];
        CLLocation *playerLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                                longitude:[longitude doubleValue]];
        if ([self.delegate respondsToSelector:@selector(player:didMoveToLocation:)]) {
//            DDLogVerbose(@"setting playerId %@ to location %@", playerId, playerLocation);
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

    if (self.accessToken) {
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
            NSDictionary *params = @{
                @"access_token": self.accessToken,
                poteKey: [pushToken hexadecimalString]
            };
            [self.tcpConnection POST:@"/device/register_push"
                          parameters:params
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 _pushTokenRegistered = YES;
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 _pushTokenRegistered = NO;
                             }];

        } else {
            DDLogError(@"no push token data!");
        }
    } else {
        DDLogError(@"no access_token, can't post push token to server");
    }
}

#pragma mark - Helpers

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
        [self gameListLocationManager:manager didUpdateLocations:locations];
    } else if (manager == self.locationManager) {
        [self sendLocationsViaUdp:locations];
    }
}

@end