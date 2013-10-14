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
    NSInteger _buttonCount;
}
@end

@implementation MAToolbarView

- (id)initWithFrame:(CGRect)frame
{
    if (self) {
        self = [super initWithFrame:frame];
        _buttonCount = 0;
        [self addToolbarItems];
    }
    
    return self;
}

- (UIButton *)makeButtonWithTitle:(NSString *)title andTarget:(id)target andMethod:(SEL)method
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [button addTarget:target
               action:method
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:MA_COLOR_RED forState:UIControlStateNormal];
    
    NSInteger width = [title length];
    button.frame = CGRectMake(_buttonCount*width, kMAToolbarYPosition, width, kMAToolbarHeight);
    button.tintColor = MA_COLOR_WHITE;
    button.backgroundColor = MA_COLOR_CREAM;
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    _buttonCount = _buttonCount + 1;
    
    return button;
}

- (void)addToolbarItems {
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsUserNameKey];
    MAAppDelegate *appDelegate = (MAAppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *nav = (UINavigationController *)appDelegate.window.rootViewController;
    UIFont *lovebit = [UIFont fontWithName:@"M41_LOVEBIT" size:18.0f];
    
    UIButton *backButton = [self makeButtonWithTitle:@"<" andTarget:nav andMethod:@selector(popViewControllerAnimated:)];
    [self addSubview:backButton];
    
//    [UIButton alloc] initWithFrame:[backButtonFrame ]l
//                            initWithTitle:@"<"
//                                                                   style:UIBarButtonItemStylePlain
//                                                                  target:nav
//                                                                  action:@selector(popViewControllerAnimated:)];
    
    // TODO: UITextAttributeFont is deprecated, but way easier to use =P We'll want to fix this later.
//    NSDictionary *barButtonAppearanceDict = @{UITextAttributeFont: lovebit};
//    [backButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
//
    
    
    UIButton *usernameButton = [self makeButtonWithTitle:username andTarget:nil andMethod:nil];
    usernameButton.tintColor = MA_COLOR_WHITE;
    [self addSubview:usernameButton];
    
    //    [[UIBarButtonItem alloc] initWithTitle:username
//                                                                       style:UIBarButtonItemStylePlain
//                                                                      target:nil action:nil];
//    [usernameButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    
    //    NSData *avatarData = [[NSUserDefaults standardUserDefaults] dataForKey:kMADefaultsAvatarKey];
    //    UIBarButtonItem *avatarButton;
    //    if (avatarData) {
    //        UIImage *avatarImage = [UIImage imageWithData:avatarData];
    //        CGFloat avatarPadding = 4;
    //        CGFloat avatarHeight = nav.toolbar.frame.size.height - (avatarPadding/2.0f);
    //        if (avatarImage.size.height > avatarHeight) {
    //            UIGraphicsBeginImageContext(CGSizeMake(avatarHeight, avatarHeight));
    //            [avatarImage drawInRect:CGRectMake(0.0, avatarPadding, avatarHeight, avatarHeight)];
    //            avatarImage = UIGraphicsGetImageFromCurrentImageContext();
    //            UIGraphicsEndImageContext();
    //        }
    //        avatarButton = [[UIBarButtonItem alloc] initWithImage:avatarImage style:UIBarButtonItemStylePlain target:nil action:nil];
    //    }
    
    UIButton *scoreButton = [self makeButtonWithTitle:@"00" andTarget:nil andMethod:nil];
    scoreButton.tintColor = MA_COLOR_WHITE;
    [self addSubview:scoreButton];

    //    [[UIButton alloc] initWithTitle:@"00" style:UIBarButtonItemStylePlain target:nil action:nil];
//    [scoreButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    
    UIButton *helpButton = [self makeButtonWithTitle:@"?" andTarget:appDelegate andMethod:@selector(halp:)];
    helpButton.tintColor = MA_COLOR_WHITE;
    [self addSubview:helpButton];
    
    //    [[UIBarButtonItem alloc] initWithTitle:@"?"
//                                                                   style:UIBarButtonItemStylePlain
//                                                                  target:appDelegate
//                                                                  action:@selector(halp:)];
//    [helpButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];

    
}

+ (void)addToView:(UIView *)view
{
    MAToolbarView *tb = [[MAToolbarView alloc] initWithFrame:[self frameForToolbar]];
    tb.backgroundColor = MA_COLOR_BODYBLUE;
    tb.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [view addSubview:tb];
}

+ (CGRect)frameForToolbar
{
    CGFloat x = 0;
    CGFloat width = 320;

    return CGRectMake(x, 320, width, 300);
}

@end
