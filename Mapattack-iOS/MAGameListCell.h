//
//  MAGameListCell.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/24/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MABoard.h"

@interface MAGameListCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *bluePlayersLabel;
@property (strong, nonatomic) IBOutlet UILabel *redPlayersLabel;
@property (strong, nonatomic) IBOutlet UILabel *gameNameLabel;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *cellView;

@property (nonatomic) BOOL isActiveHeader;
@property (nonatomic) BOOL isInactiveHeader;
@property (nonatomic, retain) id parent;

@property (nonatomic, strong) MABoard *board;

- (void)setActiveBoard:(BOOL)isHeader;
- (void)setInactiveBoard:(BOOL)isHeader;
- (void)populateBoardWithDictionary:(NSDictionary *)board andIndex:(int)boardIndex andInactiveHeaderIndex:(int)inActiveHeaderIndex andTableView:(UITableView *)tableView;
- (void)populateBoardWithDictionary:(NSDictionary *)board;

@end
