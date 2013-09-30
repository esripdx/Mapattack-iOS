//
//  MACoinAnnotation.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/28/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MACoinAnnotation : MKPointAnnotation

- (id)initWithIdentifier:(NSString *)identifier coordinate:(CLLocationCoordinate2D)coordinate pointValue:(NSInteger)points team:(NSString *)team;

@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic, readonly) UIImage *image;
@property (assign, nonatomic, readwrite) NSInteger pointValue;
@property (strong, nonatomic, readwrite) NSString *team;

@end
