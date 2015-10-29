//
//  SELAppDelegate.m
//  menuapp
//
//  Created by dpcc on 2014/04/08.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELAppDelegate.h"
#import "SELSettingDataManager.h"
#import "SELMenuDataManager.h"
#import "AFNetworkActivityLogger.h"

@implementation SELAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSLog(@"%@", [paths description]);

    // キャッシュをオフ
//    [[ NSURLCache sharedURLCache ] setDiskCapacity : 0 ];
//    [[ NSURLCache sharedURLCache ] setMemoryCapacity : 0 ];
    
    /*
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
     */
    
    // ユーザーデータを取得
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    SELUserData* userData = [settingDataManager GetUserData];
    
    if (!userData) {
        // ユーザーデータが空の場合 -> demodataを読み込む
        SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
        [menuDataManager CreateDemoData];
        
        // Setting.json -> NSUserDefaultにセットする
        SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
        [settingDataManager UpdateSettingData];
        
        // demomenuメッセージの表示
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"POPUP_TITLE_DEMO", nil)
                              message:NSLocalizedString(@"POPUP_MESSAGE_DEMO", nil)
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        
        // tablenameを設定する
        [settingDataManager SetTableName:@"TABLE-1"];
    }
    
    // AppVersionの設定
    NSString *strVersion;
    strVersion = [NSString stringWithFormat:@"%@(%@)",[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]];
    [[NSUserDefaults standardUserDefaults] setObject:strVersion forKey:@"applicationVersion"];

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
    // アプリ起動時にメニュー自動更新
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    id automaticUpdate = [userDefaults objectForKey:@"automaticUpdate"];
    if (automaticUpdate != nil && [automaticUpdate boolValue]) {
        // アプリ起動時にメニュー自動更新
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        id linkSystem = [userDefaults objectForKey:@"linkSystem"];
        
        switch ([linkSystem intValue]) {
            case 0: // プリンタ連携時
            case 2: // スマレジ連携時
            {
                NSLog(@"メニュー自動更新");
                SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
                [menuDataManager Update];
                break;
            }
            default:
                break;
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
