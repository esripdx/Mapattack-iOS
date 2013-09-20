//
//  MALaunchViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MALaunchViewController.h"

static NSString * const kDeviceIdKey = @"com.esri.portland.mapattack.deviceId";
static NSString * const kUserNameKey = @"com.esri.portland.mapattack.userName";
static NSString * const kAvatarKey = @"com.esri.portland.mapattack.avatar";

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

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [defaults objectForKey:kUserNameKey];
    if (userName) {
        self.userNameField.text = userName;
        _isUserNameSet = YES;
    }

    NSData *avatarData = [defaults dataForKey:kAvatarKey];
    if (avatarData) {
        [self.avatarButton setImage:[UIImage imageWithData:avatarData]forState:UIControlStateNormal];
        _isAvatarSet = YES;
    }

    [self updateEnterButton];
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

- (IBAction)chooseAvatarClicked:(id)sender {
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.delegate = self;

    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [self.avatarButton setImage:image forState:UIControlStateNormal];

    // TODO: This is bad, mmmmmkay. Should probably store the file on disk and handle loading that file if it's there
    // or a default image if not. Should refactor to that method when we have a default image to load in the failure
    // case. Until then... I'm in ur defaults storin' all my blobs.
    [[NSUserDefaults standardUserDefaults] setObject:UIImagePNGRepresentation(image) forKey:kAvatarKey];
    _isAvatarSet = YES;

    [self dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerController = nil;
}

@end
