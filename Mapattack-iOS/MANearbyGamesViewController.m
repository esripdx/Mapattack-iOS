//
//  MANearbyGamesViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import "MANearbyGamesViewController.h"
#import "MAGameManager.h"
#import "MAGameViewController.h"
#import "MAGameListCell.h"
#import "MAAppDelegate.h"
#import "MABoard.h"
#import "MACoin.h"
#import "MACoinAnnotationView.h"

@interface MANearbyGamesViewController () {
    NSInteger _selectedIndex;
}
@property (strong, nonatomic) NSArray *nearbyBoards;

@end

@implementation MANearbyGamesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    self.view.backgroundColor = MA_COLOR_CREAM;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.toolbarItems = [MAAppDelegate appDelegate].toolbarItems;

    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.tintColor = MA_COLOR_WHITE;
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.translucent = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = NO;

    _selectedIndex = -1;
    [self beginMonitoringNearbyBoards];
}

- (NSArray *)sortByActiveBoards:(NSArray *)boards
{
    NSArray *sortedArray;
    sortedArray = [boards sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        
        NSNumber *first = ([a[@"game"][@"active"]  isEqual: @1]) ? @1 : @0;
        NSNumber *second = ([b[@"game"][@"active"]  isEqual: @1]) ? @1 : @0;
        
        return [second compare:first];
        
    }];
    return sortedArray;
}

- (void)beginMonitoringNearbyBoards {

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    hud.square = NO;
    hud.labelText = @"Searching...";
    
    [[MAGameManager sharedManager] beginMonitoringNearbyBoardsWithBlock:^(NSArray *boards, NSError *error) {
        if (error == nil) {
            self.nearbyBoards = [self sortByActiveBoards:boards];
            // this is hiding a row :/ self.inActiveHeaderIndex = [self firstInactiveBoardIndex];
            
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

- (int)firstInactiveBoardIndex
{

    int inActiveHeaderIndex;
    BOOL foundFirstInactiveBoard = NO;
    for (int thisBoard = 0; thisBoard <= [self.nearbyBoards count]; thisBoard++) {
        if (!foundFirstInactiveBoard) {
            NSDictionary *board = self.nearbyBoards[thisBoard];
            if (thisBoard > 0) {
                NSDictionary *previousBoard = self.nearbyBoards[thisBoard-1];
                if (!board[@"game"][@"active"] && previousBoard[@"game"][@"active"]) {
                    foundFirstInactiveBoard = YES;
                    inActiveHeaderIndex = thisBoard;
                    self.inActiveHeaderIndex = inActiveHeaderIndex;
                }
            }
        }
    }

    return inActiveHeaderIndex;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MAGameManager sharedManager] stopMonitoringNearbyGames];
}

- (IBAction)joinGame:(id)sender {
    if (_selectedIndex >= 0 && _selectedIndex < self.nearbyBoards.count) {
        [[MAGameManager sharedManager] stopMonitoringNearbyGames];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.dimBackground = YES;
        hud.square = NO;
        NSDictionary *board = self.nearbyBoards[(NSUInteger)_selectedIndex];
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

- (void)showGameViewControllerWithStartButton:(BOOL)created color:(UIColor *)color {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    MAGameViewController *gvc = (MAGameViewController *)[sb instantiateViewControllerWithIdentifier:@"gameViewController"];
    gvc.createdGame = created;
    gvc.view.tintColor = color;
    [self.navigationController pushViewController:gvc animated:YES];
}

#pragma mark - UITableViewDelegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.nearbyBoards.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAGameListCell *cell = (MAGameListCell *)[tableView dequeueReusableCellWithIdentifier:@"gameCell" forIndexPath:indexPath];
    
    NSDictionary *board = self.nearbyBoards[(NSUInteger)indexPath.row];
    [cell populateBoardWithDictionary:board andIndex:self.currentBoardIndex andInactiveHeaderIndex:self.inActiveHeaderIndex andTableView:self.tableView];
    self.currentBoardIndex = self.currentBoardIndex + 1;
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != _selectedIndex) {
        _selectedIndex = indexPath.row;
    } else {
        _selectedIndex = -1;
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

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MACoin class]]) {
        return [[MACoinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"coinAnnotation"];
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