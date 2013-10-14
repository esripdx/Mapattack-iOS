//
//  MAGameListCell.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/24/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MABoard;

@interface MAGameListCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *playersLabel;
@property (strong, nonatomic) IBOutlet UILabel *gameNameLabel;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *cellView;

@property (strong, nonatomic) UIButton *startButton;

@property (strong, nonatomic) MABoard *board;

- (void)styleAsActiveBoard;
- (void)styleAsInactiveBoard;

@end
