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

@interface MAGameManager()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) MAUdpConnection *udpConnection;
@property (strong, nonatomic) AFHTTPSessionManager *tcpConnection;
@property (copy, nonatomic) void (^listGamesCompletionBlock)(NSArray *games, NSError *error);
@property (strong, nonatomic) NSString *joinedGameId;
@property (strong, nonatomic) NSString *joinedGameName;

@end

@implementation MAGameManager {
    NSString *_accessToken;
    BOOL _listingGames;
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

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;

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

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!self.accessToken) {
        DDLogError(@"Tried to update locations without an access token!");
        return;
    }

    static BOOL waitingForList;
    if (_listingGames) {
        [self.locationManager stopUpdatingLocation];
        if (!waitingForList) {
            waitingForList = YES;
            DDLogVerbose(@"Fetching nearby games: %@", self.locationManager.location);
            [self.tcpConnection POST:@"/games"
                          parameters:@{
                                  @"access_token": self.accessToken,
                                  @"latitude": @(self.locationManager.location.coordinate.latitude),
                                  @"longitude": @(self.locationManager.location.coordinate.longitude)
                          }
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 NSArray *games = responseObject[@"games"];

                                 DDLogVerbose(@"Found %d game%@ nearby", games.count, games.count == 1 ? @"" : @"s");
                                 for (NSDictionary *game in games) {
                                     DDLogVerbose(@"got game: %@", game);
                                 }

                                 if (self.listGamesCompletionBlock != nil) {
                                     self.listGamesCompletionBlock(games, nil);
                                 }
                                 waitingForList = NO;
                                 _listingGames = NO;
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 DDLogError(@"Failed to retrieve nearby games: %@", [error debugDescription]);
                                 if (self.listGamesCompletionBlock != nil) {
                                     self.listGamesCompletionBlock(nil, error);
                                 }
                                 waitingForList = NO;
                                 _listingGames = NO;
                             }];
        }
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

- (void)fetchNearbyGamesWithCompletionBlock:(void (^)(NSArray *games, NSError *))completion {
    if (!self.accessToken) {
        DDLogError(@"Tried to get nearby games without an access token!");
        // TODO: Send user back to launch view with an alert telling them to try logging in again.
        return;
    }

    _listingGames = YES;
    self.listGamesCompletionBlock = completion;
    DDLogVerbose(@"Getting user's location for game list...");
    [self.locationManager startUpdatingLocation];
}

- (void)joinGame:(NSDictionary *)game {
    NSString *gameId = game[@"id"];
    NSString *gameName = game[@"name"];
    DDLogVerbose(@"Joining game: %@", gameId);
    [self.tcpConnection POST:@"/game/join"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"game_id": gameId
                  }
                     success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error joining game: %@", errorJson);
                             return;
                         }

                         // TODO: Currently the response from the server contains only the game_id on successful join. I think this should be
                         // returning team number, or just a success code, the game_id is what we sent in.
                         self.joinedGameId = gameId;
                         self.joinedGameName = gameName;
                         [self.locationManager startUpdatingLocation];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error joining game: %@", [error debugDescription]);
                     }];
}

- (void)syncGameState {
    [self.tcpConnection GET:@"/game/state"
                 parameters:@{}
                    success:^(NSURLSessionDataTask *task, id responseObject) {
                        NSDictionary *errorJson = responseObject[@"error"];
                        if (errorJson != nil) {
                            DDLogError(@"Error syncing game state: %@", errorJson);
                            return;
                        }

                        NSArray *players = responseObject[@"players"];
                        DDLogVerbose(@"Received state sync for %d players", players.count);
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
    NSString *accessToken = [defaults objectForKey:kAccessTokenKey];
    NSString *name = [defaults objectForKey:kUserNameKey];
    NSData *avatar = [defaults dataForKey:kAvatarKey];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
            @"name": name,
            @"avatar": [avatar base64EncodedStringWithOptions:0]
    }];
    [params setObject:accessToken forKey:@"access_token"];

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

@end
