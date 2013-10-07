//
//  MAPlayer.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 10/4/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "MAPlayer.h"

@interface MAPlayer () {
    AFHTTPSessionManager *_imageFetcher;
    UIImage *_mapAvatar;
}

@end

@implementation MAPlayer

+ (instancetype)playerWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.playerId = dictionary[kMAApiDeviceIdKey];
        self.playerName = dictionary[kMAApiNameKey];
        self.score = [dictionary[kMAApiScoreKey] integerValue];
        self.team = dictionary[kMAApiTeamKey];

        NSNumber *latitude = dictionary[kMAApiLatitudeKey];
        NSNumber *longitude = dictionary[kMAApiLongitudeKey];
        if (latitude && longitude) {
            NSNumber *timestamp = dictionary[kMAApiTimestampKey];
            NSNumber *speed = dictionary[kMAApiSpeedKey];
            NSNumber *bearing = dictionary[kMAApiBearingKey];
            NSNumber *accuracy = dictionary[kMAApiAccuracyKey];
            self.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue])
                                                          altitude:0
                                                horizontalAccuracy:[accuracy doubleValue] verticalAccuracy:[accuracy doubleValue]
                                                            course:[bearing doubleValue] // TODO: I'm not sure this is correct... we're not really using it yet anyway
                                                             speed:[speed doubleValue]
                                                         timestamp:[NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]]];
        }

        _isSelf = [self.playerId isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsDeviceIdKey]];
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"Player {playerId: %@, playerName: %@, score: %d, team: %@, location: %@}",
                                      self.playerId, self.playerName, self.score, self.team, self.location];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    [dictionary setValue:self.playerId forKey:kMAApiDeviceIdKey];
    [dictionary setValue:self.playerName forKey:kMAApiNameKey];
    [dictionary setValue:@(self.score) forKey:kMAApiScoreKey];
    [dictionary setValue:self.team forKey:kMAApiTeamKey];
    [dictionary setValue:@(self.location.coordinate.latitude) forKey:kMAApiLatitudeKey];
    [dictionary setValue:@(self.location.coordinate.longitude) forKey:kMAApiLongitudeKey];
    [dictionary setValue:@(self.location.timestamp.timeIntervalSince1970) forKey:kMAApiTimestampKey];
    [dictionary setValue:@(self.location.speed) forKey:kMAApiSpeedKey];
    [dictionary setValue:@(self.location.course) forKey:kMAApiBearingKey]; // TODO: I'm not sure this is correct... we're not really using it yet anyway
    [dictionary setValue:@(self.location.horizontalAccuracy) forKey:kMAApiAccuracyKey];

    return dictionary;
}

- (UIImage *)mapAvatar {
    if (!_mapAvatar) {
        // Grab a random default avatar while we load the one from the server
        NSArray *defaultAvatars = MA_DEFAULT_AVATARS;
        NSString *imageName = defaultAvatars[(NSUInteger)rand()%(defaultAvatars.count-1)];
        UIImage *icon = [UIImage imageNamed:imageName];
        UIGraphicsBeginImageContext(CGSizeMake(kMAAvatarIconSize, kMAAvatarIconSize));
        [icon drawInRect:CGRectMake(0.0, 0.0, kMAAvatarIconSize, kMAAvatarIconSize)];
        _mapAvatar = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        [self fetchMapAvatar];
    }
    return _mapAvatar;
}

#pragma mark - MKAnnotation
- (CLLocationCoordinate2D)coordinate {
    return self.location.coordinate;
}

- (void)fetchMapAvatar {
    if (!_imageFetcher) {
        _imageFetcher = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:kMapAttackWebHostname]];
        _imageFetcher.requestSerializer = [AFHTTPRequestSerializer serializer];
        _imageFetcher.responseSerializer = [AFImageResponseSerializer serializer];
    }

    [_imageFetcher GET:[NSString stringWithFormat:kMAApiMapAvatarPathTemplate, self.playerId, self.team, self.playerName]
            parameters:nil
               success:^(NSURLSessionDataTask *task, UIImage *avatar) {
                   DDLogVerbose(@"Fetched avatar of size: %fx%f for player: %@", avatar.size.width, avatar.size.height, self);
                   _mapAvatar = avatar;
                   if ([self.delegate respondsToSelector:@selector(didUpdateAvatar:)]) {
                       [self.delegate didUpdateAvatar:avatar];
                   }
               }
               failure:^(NSURLSessionDataTask *task, NSError *error) {
                   DDLogError(@"Error fetching avatar for player: %@\n%@", self, error);
               }];

}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    if (!other || ![[other class] isEqual:[self class]]) {
        return NO;
    }

    return [self isEqualToPlayer:other];
}

- (BOOL)isEqualToPlayer:(MAPlayer *)player {
    if (self == player) {
        return YES;
    }
    if (player == nil) {
        return NO;
    }
    if (self.playerId == player.playerId || [self.playerId isEqualToString:player.playerId]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return [self.playerId hash];
}

@end
