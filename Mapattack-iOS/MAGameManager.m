//
//  MAGameManager.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/19/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "GeoHash.h"
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
        _accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kAccessTokenKey];
    }
    return _accessToken;
}

#pragma mark - MAUdpConnectionDelegate methods

- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveArray:(NSArray *)array {
    DDLogVerbose(@"Received udp array: %@", array);
}

- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveDictionary:(NSDictionary *)dictionary {
    DDLogVerbose(@"Received udp dictionary: %@", dictionary);
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!self.accessToken) {
        DDLogError(@"Tried to update locations without an access token!");
        return;
    }

    if (manager == self.gameListLocationManager) {
        DDLogVerbose(@"Fetching nearby games: %@", self.gameListLocationManager.location);
        [self.tcpConnection POST:@"/board/list"
                      parameters:@{
                              @"access_token": self.accessToken,
                              @"latitude": @(self.gameListLocationManager.location.coordinate.latitude),
                              @"longitude": @(self.gameListLocationManager.location.coordinate.longitude)
                      }
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
        return;
    }

    [locations enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        NSString *locationHash = [GeoHash hashForLatitude:location.coordinate.latitude
                                                longitude:location.coordinate.longitude
                                                   length:9];
        NSDictionary *update = @{
                @"location": locationHash,
                @"timestamp": @(location.timestamp.timeIntervalSince1970),
                @"accuracy": @(location.horizontalAccuracy),
                @"speed": @(location.speed),
                @"bearing": @(location.course),
                @"access_token": self.accessToken
        };
        [self.udpConnection sendDictionary:update];
    }];
}

# pragma mark - Game Mechanics

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

- (void)joinGame:(NSDictionary *)game completion:(void (^)(NSError *error, NSDictionary *response))completion {
    [self registerForPushToken];
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
                         self.joinedGameId = gameId;
                         self.joinedTeamColor = responseObject[@"team"];
                         if (completion != nil) {
                             completion(error, responseObject);
                         }

                         // TODO: Figure out what exactly should happen here? Check if game is active, start location updates if so, what do if not?
                         // [self.locationManager startUpdatingLocation];
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
                         if (completion != nil) {
                             completion(error, responseObject);
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error creating game: %@", [error debugDescription]);
                         if (completion != nil) {
                             completion(error, nil);
                         }
                     }];
}

- (void)startGame:(NSDictionary *)game {
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
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error starting game: %@", [error debugDescription]);
                     }];
}

- (void)syncGameState {
    [self.tcpConnection POST:@"/game/state"
                  parameters:@{}
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error syncing game state: %@", errorJson);
                             return;
                         }

                         NSArray *players = responseObject[@"players"];
                         DDLogVerbose(@"Received state sync for %lu players", (unsigned long)players.count);
                         for (NSDictionary *player in players) {
                             DDLogVerbose(@"%@", player);
                             if ([self.delegate respondsToSelector:@selector(player:didMoveToLocation:)]) {
                                 // TODO: I'm guessing at what these keys are.
                                 [self.delegate player:player[@"id"]
                                     didMoveToLocation:[[CLLocation alloc] initWithLatitude:[player[@"latitude"] floatValue]
                                                                                  longitude:[player[@"longitude"] floatValue]]];
                             }
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error syncing game state: %@", [error debugDescription]);

                         // TODO: Tell the user about this in some way? Maybe just keep track how many times we fail a sync
                         // and notify the user after missing so many.
                     }];
}

- (void)registerDeviceWithCompletionBlock:(void (^)(NSError *))completion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [defaults stringForKey:kUserNameKey];
    NSString *avatar = [[[defaults dataForKey:kAvatarKey] base64EncodedStringWithOptions:0] urlEncode];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"name": userName,
        @"avatar": avatar
    }];
    [params setValue:self.accessToken forKey:kAccessTokenKey];

    [self.tcpConnection POST:@"/device/register"
                  parameters:params
                     success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                         [defaults setValue:responseObject[@"device_id"] forKey:kDeviceIdKey];
                         [defaults setValue:responseObject[@"access_token"] forKey:kAccessTokenKey];
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
    [defs setObject:pushToken forKey:kPushTokenKey];
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

@end
