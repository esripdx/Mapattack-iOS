//
//  MAGamesListViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 10/8/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAGamesListViewController.h"
#import "MBProgressHUD.h"
#import "MAGameManager.h"
#import "MAAppDelegate.h"
#import "MAGameListCell.h"
#import "MACoinAnnotationView.h"
#import "MAGameViewController.h"
#import "MABorderSetter.h"
#import "MACoin.h"
#import "MABoard.h"

@interface MAGamesListViewController () {
    NSInteger _selectedIndex;
    NSInteger _selectedSection;
}
@property (strong, nonatomic) NSArray *currentGames;
@property (strong, nonatomic) NSArray *nearbyBoards;
@property (strong, nonatomic) NSMutableDictionary *coinCache;

@end

@implementation MAGamesListViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.coinCache = [NSMutableDictionary new];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];

    self.tableView.sectionHeaderHeight = kMACellHeight-3;
    // Move the section header up to the tippy-top of the tableview, accounting for the push down that the
    // navigation controller is doing to account for the status bar
    self.tableView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = MA_COLOR_CREAM;
    self.view.backgroundColor = MA_COLOR_BODYBLUE;

    self.toolbarItems = [MAAppDelegate appDelegate].toolbarItems;
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.tintColor = MA_COLOR_WHITE;
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.translucent = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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

- (BOOL)isActiveSection:(NSInteger)section {
    return section == 0;
}

- (UITableViewHeaderFooterView *)makeHeaderWithText:(NSString *)text andBackgroundColor:(UIColor *)bgColor andTextColor:(UIColor *)textColor {
    NSInteger x = 42;
    NSInteger y = 0;
    NSInteger width = kMATableWidth;
    NSInteger height = kMACellHeight;

    CGRect viewFrame = CGRectMake(x, y, width, height);
    UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithFrame:viewFrame];
    view.contentView.backgroundColor = bgColor;
    [MABorderSetter setBottomBorderForView:view withColor:textColor];

    CGRect labelFrame = CGRectMake(x, y, width, height);

    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.font = MA_FONT_MENSCH_HEADER;
    label.text = text;
    label.textColor = textColor;

    [view addSubview:label];

    return view;
}

- (void)beginMonitoringNearbyBoards {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    hud.square = NO;
    hud.labelText = @"Searching...";

    [self fetchBoards:hud];
}

- (void)fetchBoards:(MBProgressHUD *)hud {
    __weak MAGamesListViewController *weakSelf = self;
    [[MAGameManager sharedManager] beginMonitoringNearbyBoardsWithBlock:^(NSArray *boards, NSError *error) {
        if (error == nil) {
            [weakSelf separateBoards:boards];

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

        if (hud) {
            [hud hide:YES];
        }

        weakSelf.tableView.hidden = NO;
    }];
}

-(void)separateBoards:(NSArray *)boards {
    NSMutableArray *active = [NSMutableArray array];
    NSMutableArray *inactive = [NSMutableArray array];
    for (MABoard *board in boards) {
        if (board.game.isActive) {
            [active addObject:board];
        } else {
            [inactive addObject:board];
        }
    }

    self.currentGames = active;
    self.nearbyBoards = inactive;

    [self.tableView reloadData];
}

- (MABoard *)boardForIndexPath:(NSIndexPath *)indexPath {
    MABoard *board;
    if ([self isActiveSection:indexPath.section]) {
        board = self.currentGames[(NSUInteger)indexPath.row];
    } else {
        board = self.nearbyBoards[(NSUInteger)indexPath.row];
    }
    return board;
}

- (void)joinGame:(id)sender {
    if (_selectedIndex >= 0) {
        [[MAGameManager sharedManager] stopMonitoringNearbyGames];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.dimBackground = YES;
        hud.square = NO;
        MABoard *board = [self boardForIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:_selectedSection]];

        if (board.game != nil) {
            hud.labelText = @"Joining...";
            [[MAGameManager sharedManager] joinGameOnBoard:board completion:^(NSString *joinedTeam, NSError *error) {
                [hud hide:YES];
                if (!error) {
                    // show start button only if the game is inactive or there are no other players in the game.
                    BOOL showStartButton = !(board.game.isActive || board.game.blueTeamPlayers > 0 || board.game.redTeamPlayers > 0);
                    if ([joinedTeam isEqualToString:@"blue"]) {
                        [self showGameViewControllerWithStartButton:showStartButton color:MA_COLOR_BLUE];
                    } else {
                        [self showGameViewControllerWithStartButton:showStartButton color:MA_COLOR_RED];
                    }
                } else {
                    DDLogError(@"Error joining game: %@", [error debugDescription]);
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to join %@", board.name]
                                               delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }];
        } else {
            hud.labelText = @"Creating...";
            [[MAGameManager sharedManager] createGameForBoard:board completion:^(NSString *joinedTeam, NSError *error) {
                [hud hide:YES];
                if (!error) {
                    if ([joinedTeam isEqualToString:@"blue"]) {
                        [self showGameViewControllerWithStartButton:YES color:MA_COLOR_BLUE];
                    } else {
                        [self showGameViewControllerWithStartButton:YES color:MA_COLOR_RED];
                    }
                } else {
                    DDLogError(@"Error creating game: %@", [error debugDescription]);
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to create %@", board.name]
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

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // don't bounce on scrolling up, only down.
    if (scrollView.contentOffset.y < 0) {
        scrollView.contentOffset = CGPointMake(0, 0);
    }
}

#pragma mark - UITableViewDelegate/Datasource
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section

{
    if ([self isActiveSection:section]) {
        return [self makeHeaderWithText:@"CURRENT GAMES" andBackgroundColor:MA_COLOR_BODYBLUE andTextColor:MA_COLOR_WHITE];
    } else {
        return [self makeHeaderWithText:@"NEARBY BOARDS" andBackgroundColor:MA_COLOR_CREAM andTextColor:MA_COLOR_RED];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isActiveSection:section]) {
        return [self.currentGames count];
    } else {
        return [self.nearbyBoards count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAGameListCell *cell = (MAGameListCell *)[tableView dequeueReusableCellWithIdentifier:@"gameListCell" forIndexPath:indexPath];

    MABoard *board = [self boardForIndexPath:indexPath];
    [cell setBoard:board withMapDelegate:self annotations:self.coinCache[board.game.gameId]];

    // DDLogVerbose(@"dequeued cell for %@", cell.board);
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != _selectedIndex || indexPath.section != _selectedSection) {
        _selectedIndex = indexPath.row;
        _selectedSection = indexPath.section;
        __weak MAGameListCell *cell = (MAGameListCell *)[tableView cellForRowAtIndexPath:indexPath];
        __weak MAGamesListViewController *weakSelf = self;
        if (cell.board.game.gameId) {
            if (!self.coinCache[cell.board.game.gameId]) {
                [[MAGameManager sharedManager] fetchGameStateForGameId:cell.board.game.gameId
                                                            completion:^(NSArray *coins, NSError *error) {
                                                                if (error == nil) {
                                                                    weakSelf.coinCache[cell.board.game.gameId] = coins;
                                                                    [cell.mapView addAnnotations:coins];
                                                                    DDLogVerbose(@"Added %d annotations for %@", coins.count, cell.board);
                                                                } else {
                                                                    DDLogError(@"Error fetching game state: %@", [error localizedDescription]);
                                                                }
                                                            }];
            } else {
                [cell.mapView removeAnnotations:cell.mapView.annotations];
                [cell.mapView addAnnotations:self.coinCache[cell.board.game.gameId]];
            }
        } else {
            if (!self.coinCache[cell.board.boardId]) {
                [[MAGameManager sharedManager] fetchBoardStateForBoardId:cell.board.boardId
                                                              completion:^(MABoard *board, NSArray *coins, NSError *error) {
                                                                  if (error == nil) {
                                                                      weakSelf.coinCache[cell.board.boardId] = coins;
                                                                      [cell.mapView addAnnotations:coins];
                                                                      DDLogVerbose(@"Added %d annotations for %@", coins.count, cell.board);
                                                                  } else {
                                                                      DDLogError(@"Error fetching board state: %@", [error localizedDescription]);
                                                                  }
                                                              }];
            } else {
                [cell.mapView removeAnnotations:cell.mapView.annotations];
                [cell.mapView addAnnotations:self.coinCache[cell.board.boardId]];
            }
        }
    } else {
        _selectedIndex = -1;
        _selectedSection = -1;
    }

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // these cause the tableview to animate the cell expanding to show the map
    [tableView beginUpdates];
    [tableView endUpdates];
    NSInteger scrollTo = indexPath.row;
    NSIndexPath *path = [NSIndexPath indexPathForItem:scrollTo inSection:indexPath.section];
    [self.tableView scrollToRowAtIndexPath:path
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _selectedIndex && indexPath.section == _selectedSection) {
        return kMACellExpandedHeight;
    } else {
        return kMACellHeight;
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
