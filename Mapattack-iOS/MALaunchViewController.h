//
//  MALaunchViewController.h
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MALaunchViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UITextField *userNameField;
@property (strong, nonatomic) IBOutlet UIButton *avatarButton;
@property (strong, nonatomic) IBOutlet UIButton *enterButton;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;

- (IBAction)chooseAvatarClicked:(id)sender;

@end
