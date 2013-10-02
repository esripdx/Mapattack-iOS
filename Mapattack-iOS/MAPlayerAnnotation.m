//
//  MAPlayerAnnotation.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/28/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAPlayerAnnotation.h"

@interface MAPlayerAnnotation ()

@property (strong, nonatomic, readwrite) NSString *team;
@property (strong, nonatomic, readwrite) NSString *playerName;
@property (strong, nonatomic, readwrite) NSString *identifier;

@end

@implementation MAPlayerAnnotation

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name score:(NSInteger)score location:(CLLocation *)location team:(NSString *)color {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.identifier = identifier;
    self.playerName = name;
    self.score = score;
    self.location = location;
    self.team = color;
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return self.location.coordinate;
}

@end
