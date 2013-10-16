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

@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UIButton *enterButton;
@property (weak, nonatomic) IBOutlet UIButton *captureAvatarButton;
@property (weak, nonatomic) IBOutlet UIButton *pickFromRollButton;
@property (weak, nonatomic) IBOutlet UIButton *prevAvatarButton;
@property (weak, nonatomic) IBOutlet UIButton *nextAvatarButton;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureSession *videoCaptureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoLayer;

- (IBAction)captureNow;
- (IBAction)enterLobby;
- (IBAction)pickFromCameraRoll;

@end
