//
//  MACoinAnnotationView.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 10/7/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <MapKit/MapKit.h>

@class MACoin;

@interface MACoinAnnotationView : MKAnnotationView
@property (strong, nonatomic) MACoin *coin;

@end
