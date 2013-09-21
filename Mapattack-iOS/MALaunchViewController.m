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
#import <MBProgressHUD/MBProgressHUD.h>

static NSString * const kDeviceIdKey = @"com.esri.portland.mapattack.deviceId";
static NSString * const kUserNameKey = @"com.esri.portland.mapattack.userName";
static NSString * const kAvatarKey = @"com.esri.portland.mapattack.avatar";
static NSString * const kAccessTokenKey = @"com.esri.portland.mapattack.accessToken";

@interface MALaunchViewController () {
    BOOL _isUserNameSet;
    BOOL _isAvatarSet;
}

@end

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

- (void)updateEnterButton {
    self.enterButton.enabled = (_isUserNameSet && _isAvatarSet);
}

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

- (void)startCapture {
    [self updateEnterButton];
    self.videoCaptureSession = [[AVCaptureSession alloc] init];
    self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset640x480;

    self.videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoCaptureSession];

    self.videoLayer.frame = self.capturedAvatarImage.bounds;
    [self.capturedAvatarImage.layer addSublayer:self.videoLayer];

    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
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

                                                           NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                           UIImage *image = [[UIImage alloc] initWithData:imageData];

                                                           self.capturedAvatarImage.image = image;
                                                           [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:kAvatarKey];
                                                           [[NSUserDefaults standardUserDefaults] synchronize];
                                                           _isAvatarSet = YES;

                                                           [self.videoCaptureSession stopRunning];
                                                           self.videoCaptureSession = nil;
                                                           self.stillImageOutput = nil;
                                                           [self.videoLayer removeFromSuperlayer];
                                                           [self updateEnterButton];
                                                       }];
}

- (IBAction)enterLobby {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = [defaults objectForKey:kDeviceIdKey];
    NSString *name = [defaults objectForKey:kUserNameKey];
    NSData *avatar = [defaults dataForKey:kAvatarKey];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
            @"name": name,
            @"avatar": [avatar base64EncodedStringWithOptions:0]
    }];
    [params setValue:deviceId forKey:@"device_id"];

    // this should probably be done in the app delegate or something
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:@"http://192.168.10.22:8080"]];
    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    hud.color = self.view.tintColor;
    hud.square = NO;
    hud.labelText = @"Registering...";
    [sessionManager POST:@"/device/register"
              parameters:params
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     [defaults setValue:responseObject[@"device_id"] forKey:kDeviceIdKey];
                     [defaults setValue:responseObject[@"access_token"] forKey:kAccessTokenKey];
                     [self performSegueWithIdentifier:@"device-registered" sender:self];
                     DDLogVerbose(@"device registered.");
                     [hud hide:YES];
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error) {
                     DDLogError(@"Error registering device: %@", [error debugDescription]);
                     [hud hide:YES];
                     [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Error registering device with server" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                 }];

}

@end
