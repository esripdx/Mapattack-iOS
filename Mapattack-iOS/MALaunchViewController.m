//
//  MALaunchViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import "MALaunchViewController.h"
#import "MAGameManager.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface MALaunchViewController () {
    BOOL _isUserNameSet;
    BOOL _isAvatarSet;
}

@property (strong, nonatomic) IBOutlet UIView *avatarContainer;
@property (strong, nonatomic) IBOutlet UIView *avatarButtonsContainer;

@end

static NSUInteger const kMAMaxUsernameLength = 3;
static float const kMAAvatarSize = 256.0f;

@implementation MALaunchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.enterButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.enterButton.titleLabel.minimumScaleFactor = 0.42;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [defaults objectForKey:kMADefaultsUserNameKey];
    if (userName) {
        self.userNameField.text = userName;
        _isUserNameSet = YES;
    }

    NSData *avatarData = [defaults dataForKey:kMADefaultsAvatarKey];
    if (avatarData) {
        [self.capturedAvatarImage setImage:[UIImage imageWithData:avatarData]];
        _isAvatarSet = YES;
    }

    self.view.backgroundColor = MA_COLOR_CREAM;

    self.avatarContainer.layer.borderColor = MA_COLOR_RED.CGColor;
    self.avatarContainer.layer.borderWidth = 2.0f;
    self.avatarContainer.backgroundColor = [UIColor clearColor];

    self.avatarButtonsContainer.layer.borderColor = MA_COLOR_RED.CGColor;
    self.avatarButtonsContainer.layer.borderWidth = 1.0f;
    self.avatarButtonsContainer.backgroundColor = [UIColor clearColor];

    UIFont *lovebit = [UIFont fontWithName:@"M41_LOVEBIT" size:26.0f];
    self.prevAvatarButton.titleLabel.font = lovebit;
    self.prevAvatarButton.contentEdgeInsets = UIEdgeInsetsMake(8.0, 3.0, 0, 0);
    self.prevAvatarButton.layer.borderColor = MA_COLOR_RED.CGColor;
    self.prevAvatarButton.layer.borderWidth = 2.0f;
    self.prevAvatarButton.backgroundColor = [UIColor clearColor];

    self.nextAvatarButton.titleLabel.font = lovebit;
    self.nextAvatarButton.contentEdgeInsets = UIEdgeInsetsMake(8.0, 4.0, 0, 0);
    self.nextAvatarButton.layer.borderColor = MA_COLOR_RED.CGColor;
    self.nextAvatarButton.layer.borderWidth = 2.0f;
    self.nextAvatarButton.backgroundColor = [UIColor clearColor];

    self.captureAvatarButton.layer.borderColor = MA_COLOR_RED.CGColor;
    self.captureAvatarButton.layer.borderWidth = 2.0f;

    self.pickFromRollButton.layer.borderColor = MA_COLOR_RED.CGColor;
    self.pickFromRollButton.layer.borderWidth = 2.0f;

    self.userNameField.font = lovebit;
    self.userNameField.textColor = MA_COLOR_RED;
    self.userNameField.layer.borderColor = MA_COLOR_RED.CGColor;
    self.userNameField.layer.borderWidth = 2.0f;
    self.userNameField.backgroundColor = MA_COLOR_WHITE;

    self.enterButton.titleLabel.font = lovebit;
    self.enterButton.tintColor = MA_COLOR_BLUE;
    self.enterButton.layer.borderColor = MA_COLOR_BLUE.CGColor;
    self.enterButton.layer.borderWidth = 2.0f;
    self.enterButton.contentEdgeInsets = UIEdgeInsetsMake(8.0, 0, 0, 0);

    [self updateEnterButton];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;

    if (!_isAvatarSet) {
        [self startCapture];
    }

    self.navigationController.toolbarHidden = YES;

    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)updateEnterButton {
    self.enterButton.enabled = (_isUserNameSet && _isAvatarSet);
    if (self.enterButton.enabled) {
        self.enterButton.backgroundColor = MA_COLOR_BLUE;
        self.enterButton.tintColor = MA_COLOR_WHITE;
    } else {
        self.enterButton.backgroundColor = [UIColor clearColor];
        self.enterButton.tintColor = MA_COLOR_BLUE;
    }
}

- (void)startCapture {
    [self updateEnterButton];
    self.videoCaptureSession = [AVCaptureSession new];
    self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset352x288;

    self.videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoCaptureSession];
    self.videoLayer.frame = CGRectMake(0.0, 0.0, kMAAvatarSize, kMAAvatarSize);
    self.videoLayer.bounds = CGRectMake((352.0 - kMAAvatarSize)/2, (288.0 - kMAAvatarSize)/2, 288.0, 352.0);
    [self.capturedAvatarImage.layer addSublayer:self.videoLayer];

    self.stillImageOutput = [AVCaptureStillImageOutput new];
    [self.stillImageOutput setOutputSettings:@{AVVideoCodecKey: AVVideoCodecJPEG}];
    [self.videoCaptureSession addOutput:self.stillImageOutput];

    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == AVCaptureDevicePositionFront) {
            NSError *error = nil;
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            if (!input) {
                DDLogError(@"ERROR: trying to open camera: %@", error);
                [[[UIAlertView alloc] initWithTitle:@"ERROR!"
                                           message:[NSString stringWithFormat:@"Error openin camera: %@", [error localizedDescription]]
                                          delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil] show];
                break;
            }

            [self.videoCaptureSession addInput:input];

            [self.videoCaptureSession startRunning];
            break;
        }
    }

    if (self.videoCaptureSession.inputs.count < 1) {
        self.videoCaptureSession = nil;
        self.stillImageOutput = nil;
    }
}

- (void)endCapture {
    if (self.videoCaptureSession) {
        [self.videoCaptureSession stopRunning];
        self.videoCaptureSession = nil;
        self.stillImageOutput = nil;
        [self.videoLayer removeFromSuperlayer];
        [self updateEnterButton];
    }
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:NO];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [[NSUserDefaults standardUserDefaults] setObject:self.userNameField.text forKey:kMADefaultsUserNameKey];
    _isUserNameSet = ![self.userNameField.text isEqualToString:@""];

    [self updateEnterButton];
    [self.userNameField resignFirstResponder];
}

#pragma mark - IBActions

- (IBAction)captureNow {
    if (!self.videoCaptureSession) {
        _isAvatarSet = NO;
        [self updateEnterButton];
        [self startCapture];
        return;
    }
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                videoConnection.videoMirrored = YES;
                break;
            }
        }
        if (videoConnection) {break;}
    }
    
    void (^captureStillCompletionHandler)(CMSampleBufferRef, NSError *) = ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        /*
        CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        
        if (exifAttachments) {
            // Do something with the attachments.
        }
        else {
        }
        */
        
        CGRect captureRect = CGRectMake((352.0 - kMAAvatarSize)/2,
                                        (288.0 - kMAAvatarSize)/2,
                                        self.capturedAvatarImage.frame.size.width,
                                        self.capturedAvatarImage.frame.size.height);
        UIImage *image = [[UIImage alloc] initWithData:[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer]];
        image = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([image CGImage], captureRect)
                                    scale:0.0
                              orientation:image.imageOrientation];
        self.capturedAvatarImage.image = image;
        [[NSUserDefaults standardUserDefaults] setObject:UIImageJPEGRepresentation(image, 1.0f)
                                                  forKey:kMADefaultsAvatarKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _isAvatarSet = YES;
        
        [self endCapture];
    };
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler:captureStillCompletionHandler];
}

- (IBAction)enterLobby {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    hud.square = NO;
    hud.labelText = @"Registering...";

    [[MAGameManager sharedManager] registerDeviceWithCompletionBlock:^(NSError *error) {
        if (error != nil) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Error registering device with server" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            [self performSegueWithIdentifier:@"device-registered" sender:self];
        }

        [hud hide:YES];
    }];
}

- (IBAction)pickFromCameraRoll {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        [self endCapture];
        UIImagePickerController *picker = [UIImagePickerController new];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    DDLogVerbose(@"didFinishPickingMediaWithInfo: %@", info);
    
    UIImage *editedImage = (UIImage *) info[UIImagePickerControllerEditedImage];
    
    UIGraphicsBeginImageContext(CGSizeMake(kMAAvatarSize, kMAAvatarSize));
    [editedImage drawInRect:CGRectMake(0.0, 0.0, kMAAvatarSize, kMAAvatarSize)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.capturedAvatarImage.image = resizedImage;
    
    DDLogVerbose(@"setting imageData in defaults...");
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 1.0f);
    [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:kMADefaultsAvatarKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _isAvatarSet = YES;
    
    [self updateEnterButton];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Keyboard methods

- (IBAction)dismissKeyboard:(id)sender {
    [self.userNameField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return textField.text.length + string.length <= kMAMaxUsernameLength;
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    [self moveViewForKeyboardHeight:kbSize.height];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [self moveViewForKeyboardHeight:-kbSize.height];
}

- (void)moveViewForKeyboardHeight:(CGFloat)height {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.5];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-height,
            self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
}

@end
