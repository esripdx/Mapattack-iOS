//
//  MACoin.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 10/7/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class CLLocation;

@interface MACoin : NSObject <MKAnnotation>

@property (strong, nonatomic) NSString *coinId;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSString *team;
@property (assign, nonatomic) NSInteger value;

+ (instancetype)coinWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;

- (NSString *)description;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToCoin:(MACoin *)coin;

- (NSUInteger)hash;

- (UIImage *)image;
@end
