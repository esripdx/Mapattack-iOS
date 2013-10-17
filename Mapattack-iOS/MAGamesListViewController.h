//
//  MAGamesListViewController.h
//  Mapattack-iOS
//
//  Created by Jen on 10/8/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
@class MBProgressHUD;

@interface MAGamesListViewController : UIViewController <MKMapViewDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) MBProgressHUD *hud;

@end
