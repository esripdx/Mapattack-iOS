//
//  MANearbyGamesViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MANearbyGamesViewController.h"
#import "MAGameManager.h"
#import "MAGameListCell.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface MANearbyGamesViewController () {
    NSInteger _selectedIndex;
}
@property (strong, nonatomic) NSArray *nearbyGames;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation MANearbyGamesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    _selectedIndex = -1;

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    hud.square = NO;
    hud.labelText = @"Searching...";

    [[MAGameManager sharedManager] fetchNearbyGamesWithCompletionBlock:^(NSArray *games, NSError *error) {
        if (error == nil) {
            self.nearbyGames = games;
            if (games.count == 0) {
                [[[UIAlertView alloc] initWithTitle:@"No Nearby Games"
                                            message:@"No games were found near your current location."
                                           delegate:nil
                                  cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:[NSString stringWithFormat:@"Failed to retreive nearby games with the following error: %@", [error localizedDescription]]
                                       delegate:nil
                              cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            // TODO: Should probably set ourselves as the delegate for the alert view and give a retry button.

            self.nearbyGames = [NSArray array];
        }
        [self.tableView reloadData];
        [hud hide:YES];
    }];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.nearbyGames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAGameListCell *cell = (MAGameListCell *)[tableView dequeueReusableCellWithIdentifier:@"gameCell" forIndexPath:indexPath];

    NSDictionary *game = self.nearbyGames[(NSUInteger)indexPath.row];
    cell.gameNameLabel.text = game[@"name"];
    NSNumber *bluePlayers = game[@"blue_team"];
    NSNumber *redPlayers = game[@"red_team"];

    if (bluePlayers == nil) {
        cell.bluePlayersLabel.text = @"0";
    } else {
        cell.bluePlayersLabel.text = [bluePlayers stringValue];
    }

    if (redPlayers == nil) {
        cell.redPlayersLabel.text = @"0";
    } else {
        cell.redPlayersLabel.text = [redPlayers stringValue];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != _selectedIndex) {
        MAGameListCell *cell = (MAGameListCell *)[tableView cellForRowAtIndexPath:indexPath];
        _selectedIndex = indexPath.row;
        NSDictionary *game = self.nearbyGames[(NSUInteger)indexPath.row];
        NSArray *bbox = game[@"bbox"];

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

            NSString *template = @"http://mapattack-tiles-0.pdx.esri.com/dark/{z}/{y}/{x}";
            MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
            overlay.canReplaceMapContent = YES;
            [cell.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
            cell.mapView.showsUserLocation = YES;
            [cell.mapView setRegion:region animated:NO];
        }
    }

    // these cause the tableview to animate the cell expanding to show the map
    [tableView beginUpdates];
    [tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _selectedIndex) {
        return 285;
    } else {
        return 44;
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:(MKTileOverlay *)overlay];
}
@end
