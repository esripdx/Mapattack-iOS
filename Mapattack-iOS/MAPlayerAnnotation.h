//
//  MAPlayerAnnotation.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/28/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MAPlayerAnnotation : MKPointAnnotation

- (id)initWithIdentifier:(NSString *)identifier
                    name:(NSString *)name
                   score:(NSInteger)score
                location:(CLLocation *)location
                    team:(NSString *)color;

@property (strong, nonatomic, readonly) NSString *team;
@property (strong, nonatomic, readonly) NSString *playerName;
@property (strong, nonatomic, readonly) NSString *identifier;
@property (assign, nonatomic) NSInteger score;
@property (strong, nonatomic) CLLocation *location;

@end
