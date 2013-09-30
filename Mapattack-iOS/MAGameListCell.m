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
        // Initialization code
    }
    return self;
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
        [[MAGameManager sharedManager] fetchBoardStateForBoard:self.board[@"board_id"]
                                                    completion:^(NSDictionary *board, NSArray *coins, NSError *error) {
                                                        if (error == nil) {
                                                            for (NSDictionary *coin in coins) {
                                                                MACoinAnnotation *annotation = [[MACoinAnnotation alloc] initWithDictionary:coin];
                                                                [self.mapView addAnnotation:annotation];
                                                            }
                                                        }
                                                    }];
        MKCoordinateRegion region = [[MAGameManager sharedManager] regionForBoard:self.board];
        [self.mapView setRegion:region animated:NO];
    }
}

@end
