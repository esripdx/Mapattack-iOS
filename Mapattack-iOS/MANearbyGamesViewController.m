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
#import "MAUserToolbar.h"

@interface MANearbyGamesViewController () {
    NSInteger _selectedIndex;
}
@property (strong, nonatomic) NSArray *nearbyBoards;

@end

@implementation MANearbyGamesViewController

- (void)back
{
    NSLog(@"Testing back functionality");
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = NO;
    MAUserToolbar *toolbar = [[MAUserToolbar alloc] initWithUsername:@"This" andTarget:self];
    self.toolbarItems = toolbar.items;
    _selectedIndex = -1;

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    hud.square = NO;
    hud.labelText = @"Searching...";

    [[MAGameManager sharedManager] beginMonitoringNearbyBoardsWithBlock:^(NSArray *boards, NSError *error) {
        if (error == nil) {
            self.nearbyBoards = boards;
            if (boards.count == 0) {
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

            self.nearbyBoards = [NSArray array];
        }
        [self.tableView reloadData];
        [hud hide:YES];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MAGameManager sharedManager] stopMonitoringNearbyGames];
}


- (IBAction)joinGame:(id)sender {
    if (_selectedIndex >= 0 && _selectedIndex < self.nearbyBoards.count) {
        NSDictionary *board = self.nearbyBoards[(NSUInteger)_selectedIndex];
        NSDictionary *game = board[@"game"];
        if (game != nil) {
            if (game[@"is_active"]) {
                [[MAGameManager sharedManager] joinGame:game];
            } else {
                // TODO: Not sure what happens here. Join the game and go to an intermediary screen with a start button?
            }
        } else {
            [[MAGameManager sharedManager] createGameForBoard:board completion:nil];
            // TODO: completion block that does the things. I'm not exactly sure where the game is supposed to go from here,
            // to an intermediary screen with a start button?
        }
    } else {
        // TODO: I don't know how they'd get here but should probably do something about it? Maybe?
    }
}

#pragma mark - UITableViewDelegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.nearbyBoards.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAGameListCell *cell = (MAGameListCell *)[tableView dequeueReusableCellWithIdentifier:@"gameCell" forIndexPath:indexPath];

    NSDictionary *board = self.nearbyBoards[(NSUInteger)indexPath.row];
    cell.gameNameLabel.text = board[@"name"];
    NSDictionary *game = board[@"game"];
    if (game != nil) {
        cell.bluePlayersLabel.text = [game[@"blue_team"] stringValue];
        cell.redPlayersLabel.text = [game[@"red_team"] stringValue];
    } else {
        cell.bluePlayersLabel.text = @"0";
        cell.redPlayersLabel.text = @"0";
    }

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != _selectedIndex) {
        _selectedIndex = indexPath.row;
        MAGameListCell *cell = (MAGameListCell *)[tableView cellForRowAtIndexPath:indexPath];
        NSDictionary *board = self.nearbyBoards[(NSUInteger)indexPath.row];
        cell.board = board;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // these cause the tableview to animate the cell expanding to show the map
    [tableView beginUpdates];
    [tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _selectedIndex) {
        return 326;
    } else {
        return 44;
    }
}

#pragma mark MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:(MKTileOverlay *)overlay];
}

@end
