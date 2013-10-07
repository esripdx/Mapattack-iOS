//
//  MAGamesListViewController.m
//  Mapattack-iOS
//
//  Created by poeks on 10/4/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAGamesListViewController.h"
#import "MBProgressHUD.h"
#import "MAGameManager.h"
#import "MAAppDelegate.h"
#import "MAGameListCell.h"
#import "MACoinAnnotation.h"
#import "MAGameViewController.h"
#import "MABorderSetter.h"

@interface MAGamesListViewController () {
    NSInteger _selectedIndex;
    UITableView *_selectedTable;
}
@property (strong, nonatomic) NSArray *currentGames;
@property (strong, nonatomic) NSArray *nearbyBoards;

@end

@implementation MAGamesListViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self.currentGamesTableView setDelegate:self];
    [self.currentGamesTableView setDataSource:self];
    [self.nearbyBoardsTableView setDelegate:self];
    [self.nearbyBoardsTableView setDataSource:self];
    
    self.view.backgroundColor = MA_COLOR_CREAM;
    self.currentGamesTableView.backgroundColor = [UIColor clearColor];
    self.nearbyBoardsTableView.backgroundColor = [UIColor clearColor];
    self.toolbarItems = [MAAppDelegate appDelegate].toolbarItems;
    
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.tintColor = MA_COLOR_WHITE;
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.translucent = YES;
    
    [self updateHeaderStyle];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = NO;
    
    _selectedIndex = -1;
    [self beginMonitoringNearbyBoards];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MAGameManager sharedManager] stopMonitoringNearbyGames];
}

- (void)updateHeaderStyle
{
    //self.currentGamesLabel.bounds = CGRectMake(140, 30, self.currentGamesTableView.bounds.size.width, self.currentGamesTableView.bounds.size.height);
    self.currentGamesLabel.font = MA_FONT_MENSCH_HEADER;
    self.currentGamesLabel.textColor = MA_COLOR_WHITE;
    self.currentGamesLabel.backgroundColor = MA_COLOR_BODYBLUE;
    [MABorderSetter setBottomBorderForView:self.currentGamesLabel withColor:MA_COLOR_WHITE];

    self.nearbyBoardsLabel.font = MA_FONT_MENSCH_HEADER;
    self.nearbyBoardsLabel.textColor = MA_COLOR_RED;
    [MABorderSetter setBottomBorderForView:self.nearbyBoardsLabel withColor:MA_COLOR_RED];

}

- (void)beginMonitoringNearbyBoards {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    hud.square = NO;
    hud.labelText = @"Searching...";
    
    [[MAGameManager sharedManager] beginMonitoringNearbyBoardsWithBlock:^(NSArray *boards, NSError *error) {
        if (error == nil) {
            [self separateBoards:boards];
            
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
            
        }

        [hud hide:YES];
    }];
}

-(void)separateBoards:(NSArray *)boards
{
    NSMutableArray *active = [NSMutableArray array];
    NSMutableArray *inactive = [NSMutableArray array];
    for (NSDictionary *board in boards) {
        if (board[@"game"][@"active"] && [board[@"game"][@"active"] intValue] > 0) {
            [active addObject:board];
        } else {
            [inactive addObject:board];
        }
    }
 
    self.currentGames = active;
    self.nearbyBoards = inactive;
    
    [self.currentGamesTableView reloadData];
    [self.nearbyBoardsTableView reloadData];
    
}

- (void)joinGame:(id)sender {
    if (_selectedIndex >= 0 && _selectedIndex) { // No longer applicable < self.nearbyBoards.count) {
        [[MAGameManager sharedManager] stopMonitoringNearbyGames];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.dimBackground = YES;
        hud.square = NO;
        NSDictionary *board;
        if (_selectedTable == self.currentGamesTableView) {
            board = self.currentGames[_selectedIndex];
        } else {
            board = self.nearbyBoards[_selectedIndex];
        }

        NSDictionary *game = board[@"game"];
        if (game != nil) {
            hud.labelText = @"Joining...";
            [[MAGameManager sharedManager] joinGameOnBoard:board completion:^(NSError *error, NSDictionary *response) {
                [hud hide:YES];
                if (!error) {
                    // show start button only if the game is inactive or there are no other players in the game.
                    BOOL showStartButton = !([game[@"active"] boolValue] || [game[@"blue_team"] integerValue] > 0 || [game[@"red_team"] integerValue] > 0);
                    if ([response[@"team"] isEqualToString:@"blue"]) {
                        [self showGameViewControllerWithStartButton:showStartButton color:MA_COLOR_BLUE];
                    } else {
                        [self showGameViewControllerWithStartButton:showStartButton color:MA_COLOR_RED];
                    }
                } else {
                    DDLogError(@"Error joining game: %@", [error debugDescription]);
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to join %@", board[@"name"]]
                                               delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }];
        } else {
            hud.labelText = @"Creating...";
            [[MAGameManager sharedManager] createGameForBoard:board completion:^(NSError *error, NSDictionary *response) {
                [hud hide:YES];
                if (!error) {
                    if ([response[@"team"] isEqualToString:@"blue"]) {
                        [self showGameViewControllerWithStartButton:YES color:MA_COLOR_BLUE];
                    } else {
                        [self showGameViewControllerWithStartButton:YES color:MA_COLOR_RED];
                    }
                } else {
                    DDLogError(@"Error creating game: %@", [error debugDescription]);
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to create %@", board[@"name"]]
                                               delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }];
        }
    } else {
        // TODO: I don't know how they'd get here but should probably do something about it? Maybe?
    }
}

// TODO: Need this?
- (void)showGameViewControllerWithStartButton:(BOOL)created color:(UIColor *)color {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    MAGameViewController *gvc = (MAGameViewController *)[sb instantiateViewControllerWithIdentifier:@"gameViewController"];
    gvc.createdGame = created;
    gvc.view.tintColor = color;
    [self.navigationController pushViewController:gvc animated:YES];
}

#pragma mark - UITableViewDelegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.currentGamesTableView) {
        return [self.currentGames count];
    } else {
        return [self.nearbyBoards count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAGameListCell *cell = (MAGameListCell *)[tableView dequeueReusableCellWithIdentifier:@"gameCell" forIndexPath:indexPath];
    
    NSDictionary *board;
    if (tableView == self.currentGamesTableView) {
        board = self.currentGames[(NSUInteger)indexPath.row];
    } else {
        board = self.nearbyBoards[(NSUInteger)indexPath.row];
        [cell.startButton setTitle:@"CREATE" forState:UIControlStateNormal];
        [cell.startButton addTarget:tableView action:@selector(startGame) forControlEvents:UIControlEventTouchUpInside];
    }
    [cell populateBoardWithDictionary:board];
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != _selectedIndex) {
        _selectedIndex = indexPath.row;
    } else {
        _selectedIndex = -1;
    }
    _selectedTable = tableView;
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // these cause the tableview to animate the cell expanding to show the map
    [tableView beginUpdates];
    [tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _selectedIndex) {
        return kCellExpandedHeight;
    } else {
        return kCellHeight;
    }
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MACoinAnnotation class]]) {
        MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"coinAnnotation"];
        MACoinAnnotation *coinAnnotation = (MACoinAnnotation *)annotation;
        pin.image = coinAnnotation.image;
        return pin;
    }
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:(MKTileOverlay *)overlay];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self beginMonitoringNearbyBoards];
}

@end
