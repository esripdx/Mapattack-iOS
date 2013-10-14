//
//  MAToolbarView.m
//  Mapattack-iOS
//
//  Created by poeks on 10/14/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAToolbarView.h"
#import "MAAppDelegate.h"
#import "MAConstants.h"

@interface MAToolbarView ()
{
    NSInteger _previousXPos;
    NSInteger _spacing;
    NSInteger _totalWidth;
}

@property (nonatomic, strong) NSMutableArray *buttons;

@end

@implementation MAToolbarView

- (id)initWithFrame:(CGRect)frame
{
    if (self) {
        self = [super initWithFrame:frame];
        self.buttons = [[NSMutableArray alloc] init];
        _totalWidth = 320;
        _previousXPos = 0;
        _spacing = 20;
        [self addToolbarItems];
    }
    
    return self;
}

- (void)addButtonWithTitle:(NSString *)title andTarget:(id)target andMethod:(SEL)method
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIFont *lovebit = [UIFont fontWithName:@"M41_LOVEBIT" size:18.0f];
    button.titleLabel.font = lovebit;

    // Do stuff when clickethed
    [button addTarget:target
               action:method
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:MA_COLOR_WHITE forState:UIControlStateNormal];
    
    // Spacing and crap
    // TODO this could be a bit less janky
    NSInteger width = _spacing + ([title length]*14);
    NSInteger xPos = 0;
    if ([self.buttons count] > 0) {
        xPos = _previousXPos;
    } else {
        xPos = 10;
    }
    NSInteger yPos = 3;
    NSInteger height = kMAToolbarHeight;
    button.frame = CGRectMake(xPos, yPos, width, height);
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    //button.contentEdgeInsets =  UIEdgeInsetsMake(0, 6.0, 0 ,0);
    
    // add it to view and keep track of values
    [self.buttons addObject:button];
    [self addSubview:button];
    
    _previousXPos = width + _previousXPos + _spacing;
    
}

- (void)setAvatarImage
{
    NSData *avatarData = [[NSUserDefaults standardUserDefaults] dataForKey:kMADefaultsAvatarKey];
    if (!avatarData) {
        // No custom avatar found, use the selected default avatar.
        NSNumber *defaultAvatarIndex = [[NSUserDefaults standardUserDefaults] valueForKey:kMADefaultsDefaultAvatarSelectedKey];
        NSString *imageName = MA_DEFAULT_AVATARS[[defaultAvatarIndex unsignedIntegerValue]];
        UIImage *avatarImage = [UIImage imageNamed:imageName];
        avatarData = UIImageJPEGRepresentation(avatarImage, 1.0f);
    }
    
    // looks kinda weird
    UIImage *avatarImage = [UIImage imageWithData:avatarData];
    CGFloat avatarPadding = 2;
    CGFloat avatarHeight = kMAToolbarHeight-10;
    if (avatarImage.size.height > avatarHeight) {
        UIGraphicsBeginImageContext(CGSizeMake(avatarHeight, avatarHeight));
        [avatarImage drawInRect:CGRectMake(0.0, avatarPadding, avatarHeight, avatarHeight-6)];
        avatarImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    [self.buttons[2] setTitle:nil];
    [self.buttons[2] setImage:avatarImage forState:UIControlStateNormal];
    
}

- (void)addToolbarItems {
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsUserNameKey];
    MAAppDelegate *appDelegate = (MAAppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *nav = (UINavigationController *)appDelegate.window.rootViewController;
    
    [self addButtonWithTitle:@"<" andTarget:nav andMethod:@selector(popViewControllerAnimated:)];
    [self addButtonWithTitle:username andTarget:nil andMethod:nil];
    [self addButtonWithTitle:@"  " andTarget:nil andMethod:nil];
    [self addButtonWithTitle:@"00" andTarget:nil andMethod:nil];
    [self addButtonWithTitle:@"?" andTarget:self andMethod:@selector(segueHalp:)];
    
    // TODO fix this to actually work
    [self setAvatarImage];

}

- (IBAction)segueHalp:(id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *halpController = [sb instantiateViewControllerWithIdentifier:@"Help"];
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    [navigationController pushViewController:halpController animated:YES];
}

- (IBAction)segueScoreboard:(id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *scoreboardController = [sb instantiateViewControllerWithIdentifier:@"Scoreboard"];
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    [navigationController pushViewController:scoreboardController animated:YES];
}

+ (void)addToView:(UIView *)view
{
    MAToolbarView *tb = [[MAToolbarView alloc] initWithFrame:[self frameForToolbar]];
    tb.backgroundColor = MA_COLOR_DARKGRAY;
    tb.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [view addSubview:tb];
}

+ (CGRect)frameForToolbar
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
    
    CGFloat idk = 145/screenScale;
    CGFloat x = 0;
    CGFloat y = (screenSize.height)/2-idk;
    CGFloat width = 320;
    
    DDLogInfo(@"ypos %f %f", y, screenSize.height);

    return CGRectMake(x, y, width, kMAToolbarHeight);
}

@end
