//
//  MAPlayer.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 10/4/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class CLLocation;
@class MAPlayer;

@protocol MAPlayerDelegate <NSObject>
@optional
- (void)didUpdateAvatar:(UIImage *)avatar;
@end

@interface MAPlayer : NSObject <MKAnnotation>

@property (weak, nonatomic) id <MAPlayerDelegate>delegate;
@property (strong, nonatomic) NSString *playerId;
@property (strong, nonatomic) NSString *playerName;
@property (strong, nonatomic) NSString *team;
@property (nonatomic) NSInteger score;
@property (strong, nonatomic) CLLocation *location;
@property (nonatomic, readonly) BOOL isSelf;

+ (instancetype)playerWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
- (UIImage *)mapAvatar;

- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToPlayer:(MAPlayer *)player;
- (NSUInteger)hash;

- (NSString *)description;

@end
