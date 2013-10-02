//
//  MAGameListCell.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/24/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MAGameListCell.h"
#import "MAGameManager.h"
#import "MACoinAnnotation.h"

@implementation MAGameListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (UIFont *)fontType
{
    return [UIFont fontWithName:@"karla" size:12.0f];
}

- (void)setActiveBoard:(BOOL)isHeader
{
    if (isHeader) {
        [self setActiveBoardHeader];
    }
    self.cellView.backgroundColor = MA_COLOR_BODYBLUE;
    self.bluePlayersLabel.textColor = MA_COLOR_WHITE;
    self.bluePlayersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_WHITE;
    self.gameNameLabel.font = [self fontType];
}

- (void)setActiveBoardHeader
{
    
}

- (void)setInactiveBoard:(BOOL)isHeader
{
    if (isHeader) {
        [self setInactiveBoardHeader];
    }
    self.cellView.backgroundColor = MA_COLOR_CREAM;
    self.bluePlayersLabel.textColor = MA_COLOR_RED;
    self.bluePlayersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_RED;
    self.gameNameLabel.font = [self fontType];
}

- (void)setInactiveBoardHeader
{
    
}


- (void)setMapView:(MKMapView *)mapView {
    NSString *template = @"http://mapattack-tiles-0.pdx.esri.com/dark/{z}/{y}/{x}";
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;
    [mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
    mapView.showsUserLocation = YES;
    _mapView = mapView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) {
        [[MAGameManager sharedManager] fetchBoardStateForBoardId:self.board[@"board_id"]
                                                      completion:^(NSDictionary *board, NSArray *coins, NSError *error) {
                                                          if (error == nil) {
                                                              for (NSDictionary *coin in coins) {
                                                                  CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([coin[@"latitude"] doubleValue], [coin[@"longitude"] doubleValue]);
                                                                  MACoinAnnotation *annotation = [[MACoinAnnotation alloc] initWithIdentifier:coin[@"coin_id"]
                                                                                                                                   coordinate:coord
                                                                                                                                   pointValue:[coin[@"value"] integerValue]
                                                                                                                                         team:coin[@"team"]];
                                                                  [self.mapView addAnnotation:annotation];
                                                              }
                                                          }
                                                      }];
        MKCoordinateRegion region = [[MAGameManager sharedManager] regionForBoard:self.board];
        [self.mapView setRegion:region animated:NO];
    }
}

@end
