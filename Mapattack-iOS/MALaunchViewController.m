//
//  MALaunchViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AFNetworking/AFNetworking.h>
#import "MALaunchViewController.h"
#import "MAGameManager.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface MALaunchViewController () {
    BOOL _isUserNameSet;
    BOOL _isAvatarSet;
}

@end

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
    NSString *userName = [defaults objectForKey:kUserNameKey];
    if (userName) {
        self.userNameField.text = userName;
        _isUserNameSet = YES;
    }

    NSData *avatarData = [defaults dataForKey:kAvatarKey];
    if (avatarData) {
        [self.capturedAvatarImage setImage:[UIImage imageWithData:avatarData]];
        _isAvatarSet = YES;
    }
    
    self.capturedAvatarImage.layer.borderColor = MA_COLOR_RED.CGColor;
    self.capturedAvatarImage.layer.borderWidth = 1.0f;

    [self updateEnterButton];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;

    if (!_isAvatarSet) {
        [self startCapture];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)updateEnterButton {
    self.enterButton.enabled = (_isUserNameSet && _isAvatarSet);
}

- (void)startCapture {
    [self updateEnterButton];
    self.videoCaptureSession = [AVCaptureSession new];
    self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset352x288;

    self.videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoCaptureSession];
    self.videoLayer.frame = CGRectMake(0.0, 0.0, kMAAvatarSize, kMAAvatarSize);
    self.videoLayer.bounds = CGRectMake(48.0, 16.0, 288.0, 352.0);
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
    [[NSUserDefaults standardUserDefaults] setObject:self.userNameField.text forKey:kUserNameKey];
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

    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                           CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                                                           if (exifAttachments) {
                                                               // Do something with the attachments.
                                                           }
                                                           else {
                                                           }
                                                           
                                                           UIImage *image = [[UIImage alloc] initWithData:[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer]];
                                                           image = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([image CGImage], CGRectMake(48.0, 16.0, kMAAvatarSize, kMAAvatarSize)) scale:0.0 orientation:image.imageOrientation];
                                                           self.capturedAvatarImage.image = image;
                                                           [[NSUserDefaults standardUserDefaults] setObject:UIImageJPEGRepresentation(image, 1.0f)
                                                                                                     forKey:kAvatarKey];
                                                           [[NSUserDefaults standardUserDefaults] synchronize];
                                                           _isAvatarSet = YES;

                                                           [self endCapture];
                                                       }];
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
    [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:kAvatarKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _isAvatarSet = YES;
    
    [self updateEnterButton];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end