//
// Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "CSRDatabaseManager.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"
#import "CSRmeshSettings.h"
#import "CSRMesh/TimeModelApi.h"
#import "LightClusterViewController.h"
#import "GalleryViewController.h"
#import "MoreViewController.h"
#import "SceneCollectionController.h"
#import "LightSceneBringer.h"

#import "MainViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

static NSString *kLoadDefaultSceneProfile = @"com.actec.kLoadDefaultSceneProfile";
static NSString * const sceneListKey = @"com.actec.bluetooth.sceneListKey";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
//    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    // Set the global cloud host URL
    if ([CSRUtilities getValueFromDefaultsForKey:kCSRGlobalCloudHost]) {
        
        [CSRAppStateManager sharedInstance].globalCloudHost = [CSRUtilities getValueFromDefaultsForKey:kCSRGlobalCloudHost];
        
    } else {
        
        [CSRAppStateManager sharedInstance].globalCloudHost = kCloudServerUrl;
        
    }
    
    // Check if there is a place in DB
    [[CSRAppStateManager sharedInstance] createDefaultPlace];

    // Setup current place to be available from the start
    [[CSRAppStateManager sharedInstance] setupPlace];
    
    [[CSRAppStateManager sharedInstance] switchConnectionForSelectedBearerType:CSRSelectedBearerType_Bluetooth];
    
    // Check for externally passed URL - place import
    if (launchOptions[@"UIApplicationLaunchOptionsURLKey"])
    {
        [self application:application openURL:launchOptions[@"UIApplicationLaunchOptionsURLKey"] options:launchOptions];
    }
    
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    bgView.image = [UIImage imageNamed:@"backgroundImage"];
    [self.window addSubview:bgView];
    
    [[UINavigationBar appearance] setTintColor:DARKORAGE];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1]}];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1]];
    
    
    self.mainTabBarController = [[MainTabBarController alloc] init];
    
//    LightClusterViewController *lampsVC = [[LightClusterViewController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
    MainViewController *mainVC = [[MainViewController alloc] init];
    UINavigationController *mainNav = [[UINavigationController alloc] initWithRootViewController:mainVC];
    
//    SceneCollectionController *sceneVC = [[SceneCollectionController alloc] initWithItemPerSection:3 cellIdentifier:@"SceneCell"];
    
    GalleryViewController *galleryVC = [[GalleryViewController alloc] init];
    UINavigationController *galleryNav = [[UINavigationController alloc] initWithRootViewController:galleryVC];
    
    MoreViewController *moreVC = [[MoreViewController alloc] init];
    
    NSArray *vcs = @[mainNav,galleryNav,moreVC];
    self.mainTabBarController.viewControllers = vcs;
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.mainTabBarController];
    self.window.rootViewController = self.mainTabBarController;
    
//    [self loadDefaultSceneProfile];
    
//    NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
//    if (url != nil && [url isFileURL]) {
//        _urlImageFile = url;
//    }
    
    return YES;
}

- (void)loadDefaultSceneProfile {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    BOOL loaded = [center boolForKey:kLoadDefaultSceneProfile];
    
    if (!loaded) {
        LightSceneBringer *atHome = [[LightSceneBringer alloc]init];
        atHome.profileName = @"Home";
        atHome.sceneImage = 800;
        [self addNewSceneProfile:[atHome archive] profileName:@"Home"];
        
        LightSceneBringer *leaveHome = [[LightSceneBringer alloc]init];
        leaveHome.profileName = @"Away";
        leaveHome.sceneImage = 801;
        [self addNewSceneProfile:[leaveHome archive] profileName:@"Away"];
        
        [center setBool:YES forKey:kLoadDefaultSceneProfile];
    }
}

- (void)addNewSceneProfile:(NSData*)profileData profileName:(NSString*)pName {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSArray *list = [center arrayForKey:sceneListKey];
    NSMutableArray *updatedList = [[NSMutableArray alloc]init];
    
    if (list) {
        [updatedList addObjectsFromArray:list];
    }
    
    if (![updatedList containsObject:pName]) {
        [updatedList addObject:pName];
        [center setObject:updatedList forKey:sceneListKey];
    }
    
    [center setObject:profileData forKey:pName];
    [center synchronize];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if (self.window) {
        if (url) {
            NSString *fileNameStr = [url lastPathComponent];
            NSString *doc = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/localFile"] stringByAppendingPathComponent:fileNameStr];
            
            NSData *data = [NSData dataWithContentsOfURL:url];
            [data writeToFile:doc atomically:YES];
            
            if (url != nil && [url isFileURL]) {
                _urlImageFile = url;
            }
        }
    }
    return YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Broadcast time
//    [self broadcastTime];
    
}

//- (void)applicationDidEnterBackground:(UIApplication *)application
//{
//    
//}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
//    [[CSRDatabaseManager sharedInstance] saveContext];
    [[CSRAppStateManager sharedInstance] connectivityCheck];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
//    [[CSRConnectionManager sharedInstance] shutDown];
//    [[CSRDatabaseManager sharedInstance] saveContext];
}

/*
- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    
    if (url != nil && [url isFileURL]) {
        _managePlacesViewController = [[CSRManagePlacesViewController alloc] init];
        [_managePlacesViewController setImportedURL:url];
        _passingURL = url;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRImportPlaceDataNotification
                                                        object:self
                                                      userInfo:nil];
    return YES;
}

#define SecondsPerHour  3600

-(void)broadcastTime {
    
    // Compute timezone, BST -> GMT=1 | Delhi=+5.5
    
    [[TimeModelApi sharedInstance] broadcastTimeWithCurrentTime:@([[NSDate date] timeIntervalSince1970] * 1000)
                                                       timeZone:@(([[NSTimeZone localTimeZone] secondsFromGMT]) / SecondsPerHour)
                                                     masterFlag:@1];
    
}
*/

@end
