//
//  MAGameViewController.h
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MAGameViewController : UIViewController <MKMapViewDelegate, MAGameManagerDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIView *blueScoreContainer;
@property (strong, nonatomic) IBOutlet UIView *redScoreContainer;
@property (strong, nonatomic) IBOutlet UILabel *blueScoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *redScoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *gameNameLabel;
@property (nonatomic) BOOL createdGame;

@end
