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

@property (weak, nonatomic) IBOutlet UILabel *playersLabel;
@property (weak, nonatomic) IBOutlet UILabel *gameNameLabel;
@property (weak, nonatomic) IBOutlet UIView *cellView;

@property (weak, nonatomic) MKMapView *mapView;
@property (weak, nonatomic) UIButton *joinButton;
@property (strong, nonatomic) MABoard *board;

- (void)styleAsActiveBoard;
- (void)styleAsInactiveBoard;

@end
