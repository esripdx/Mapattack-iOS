//
//  MAHelpViewController.h
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MAHelpViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *creditsLabel;
@property (weak, nonatomic) IBOutlet UILabel *technologyLabel;
@property (weak, nonatomic) IBOutlet UILabel *historyLabel;
@property (weak, nonatomic) IBOutlet UITextView *creditsTextView;
@property (weak, nonatomic) IBOutlet UITextView *technologyTextView;
@property (weak, nonatomic) IBOutlet UITextView *historyTextView;

@end
