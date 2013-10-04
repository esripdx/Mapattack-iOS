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

@interface MAGamesListViewController () {
    NSInteger _selectedIndex;
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
