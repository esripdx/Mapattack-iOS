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
@property (assign, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *cellView;

@property (weak, nonatomic) UIButton *startButton;

@property (strong, nonatomic, readonly) MABoard *board;
- (void)setBoard:(MABoard *)board withMapDelegate:(id <MKMapViewDelegate>)delegate annotations:(NSArray *)annotations;

- (void)styleAsActiveBoard;
- (void)styleAsInactiveBoard;

@end
