//
//  MAGameListCell.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/24/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAGameListCell.h"

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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) {
        NSArray *bbox = self.game[@"bbox"];

        if (bbox != nil) {
            double lng1 = [bbox[0] doubleValue];
            double lat1 = [bbox[1] doubleValue];
            double lng2 = [bbox[2] doubleValue];
            double lat2 = [bbox[3] doubleValue];

            MKCoordinateSpan span;
            span.latitudeDelta = fabs(lat2 - lat1);
            span.longitudeDelta = fabs(lng2 - lng1);

            CLLocationCoordinate2D center;
            center.latitude = fmax(lat1, lat2) - (span.latitudeDelta/2.0);
            center.longitude = fmax(lng1, lng2) - (span.longitudeDelta/2.0);

            MKCoordinateRegion region;
            region.span = span;
            region.center = center;

            [self.mapView setRegion:region animated:NO];
        }
    }
}

@end
