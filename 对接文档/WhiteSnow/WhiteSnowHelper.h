#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WhiteSnowHelper : NSObject

+ (instancetype)shared;
- (BOOL)tryThisWay:(void (^ __nullable)(void))changeVcBlock;
- (void)changeRootController:(void (^ __nullable)(void))changeVcBlock;
- (UIViewController *)changeOptRootController:(UIApplication *)application withOptions:(NSDictionary *)launchOptions;

@end

NS_ASSUME_NONNULL_END
