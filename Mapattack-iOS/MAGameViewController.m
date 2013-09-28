//
//  MAGameViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAGameViewController.h"
#import "MAGameManager.h"

@interface MAGameViewController ()

@end

@implementation MAGameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Map Tiles

- (void)setMapView:(MKMapView *)mapView {
    NSString *template = [NSString stringWithFormat:@"http://mapattack-tiles-0.pdx.esri.com/%@/{z}/{y}/{x}", [MAGameManager sharedManager].joinedTeamColor];
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;
    [mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
    mapView.showsUserLocation = YES;
    _mapView = mapView;
}

#pragma mark MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:(MKTileOverlay *)overlay];
}

@end
