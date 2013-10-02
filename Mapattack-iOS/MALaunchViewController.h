//
//  MALaunchViewController.h
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MALaunchViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UITextField *userNameField;
@property (strong, nonatomic) IBOutlet UIButton *enterButton;
@property (strong, nonatomic) IBOutlet UIButton *captureAvatarButton;
@property (strong, nonatomic) IBOutlet UIButton *pickFromRollButton;
@property (strong, nonatomic) IBOutlet UIButton *prevAvatarButton;
@property (strong, nonatomic) IBOutlet UIButton *nextAvatarButton;
@property (strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureSession *videoCaptureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoLayer;

- (IBAction)captureNow;
- (IBAction)enterLobby;
- (IBAction)pickFromCameraRoll;

@end
