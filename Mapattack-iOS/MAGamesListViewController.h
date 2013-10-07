//
//  MAGamesListViewController.h
//  Mapattack-iOS
//
//  Created by poeks on 10/4/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MAGamesListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *currentGamesTableView;
@property (strong, nonatomic) IBOutlet UITableView *nearbyBoardsTableView;
@property (weak, nonatomic) IBOutlet UILabel *currentGamesLabel;
@property (weak, nonatomic) IBOutlet UILabel *nearbyBoardsLabel;

@end
