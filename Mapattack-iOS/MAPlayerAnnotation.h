//
//  MAPlayerAnnotation.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/28/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MAPlayerAnnotation : MKPointAnnotation

@property (strong, nonatomic, readonly) UIImage *image;
@property (strong, nonatomic, readwrite) NSString *team;
@property (strong, nonatomic, readwrite) NSString *playerName;

@end
