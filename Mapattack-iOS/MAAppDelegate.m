//
//  MAAppDelegate.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAAppDelegate.h"
#import "MAHelpViewController.h"
#import "MAGameManager.h"

static const int MAFileLoggerRollingFrequency = 60*60*24;
static const int MAFileLoggerMaxFiles = 7;

@implementation MAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Override point for customization after application launch.
    
    // CocoaLumberjack logging
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDFileLogger *fileLogger = [DDFileLogger new];
    fileLogger.rollingFrequency = MAFileLoggerRollingFrequency;
    fileLogger.logFileManager.maximumNumberOfLogFiles = MAFileLoggerMaxFiles;
    [DDLog addLogger:fileLogger];

    self.window.tintColor = MA_COLOR_RED;

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -

+ (MAAppDelegate *)appDelegate
{
    return (MAAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (IBAction)halp:(id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *halpController = [sb instantiateViewControllerWithIdentifier:@"HalpController"];
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    [navigationController pushViewController:halpController animated:YES];
}

- (NSArray *)toolbarItems {
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsUserNameKey];
    MAAppDelegate *appDelegate = (MAAppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *nav = (UINavigationController *)appDelegate.window.rootViewController;
    UIFont *lovebit = [UIFont fontWithName:@"M41_LOVEBIT" size:18.0f];

    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"<"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nav
                                                                  action:@selector(popViewControllerAnimated:)];

    // TODO: UITextAttributeFont is deprecated, but way easier to use =P We'll want to fix this later.
    NSDictionary *barButtonAppearanceDict = @{UITextAttributeFont: lovebit};
    [backButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    backButton.tintColor = MA_COLOR_WHITE;

    UIBarButtonItem *usernameButton = [[UIBarButtonItem alloc] initWithTitle:username
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:nil action:nil];
    [usernameButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    usernameButton.tintColor = MA_COLOR_WHITE;

    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:appDelegate
                                                                  action:@selector(halp:)];
    [helpButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    helpButton.tintColor = MA_COLOR_WHITE;

    NSArray *toolbarItems = @[backButton, space, usernameButton, space, helpButton];

    return toolbarItems;
}

#pragma mark - Totes Potes

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    DDLogVerbose(@"did register for push token");
    [[MAGameManager sharedManager] registerPushToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    DDLogError(@"push registration failed: %@", [error debugDescription]);
}

@end
