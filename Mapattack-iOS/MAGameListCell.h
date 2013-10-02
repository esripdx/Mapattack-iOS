//
//  MAGameListCell.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/24/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MAGameListCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *bluePlayersLabel;
@property (strong, nonatomic) IBOutlet UILabel *redPlayersLabel;
@property (strong, nonatomic) IBOutlet UILabel *gameNameLabel;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *cellView;

@property (copy, nonatomic) NSDictionary *board;
@property (nonatomic) BOOL isActiveHeader;
@property (nonatomic) BOOL isInactiveHeader;

- (void)setActiveBoard:(BOOL)isHeader;
- (void)setInactiveBoard:(BOOL)isHeader;

@end
