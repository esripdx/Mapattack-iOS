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

@property (strong, nonatomic, readonly) MABoard *board;
- (void)setBoard:(MABoard *)board withMapDelegate:(id <MKMapViewDelegate>)delegate annotations:(NSArray *)annotations;

- (void)styleAsActiveBoard;
- (void)styleAsInactiveBoard;

@end
