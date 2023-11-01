#import "ReservationPropWebViewController.h"
#import <Masonry.h>
#import <AXWebViewController.h>

@interface ReservationPropWebViewController ()

@property (nonatomic, strong) AXWebViewController *adWebVC;

@end

@implementation ReservationPropWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.adWebVC = [[AXWebViewController alloc] initWithAddress:self.serverUrl];
    self.adWebVC.showsToolBar = NO;
    self.adWebVC.showsBackgroundLabel = NO;
    self.adWebVC.enabledWebViewUIDelegate = YES;
    [self.view addSubview:self.adWebVC.view];
    
    [self.adWebVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
}

@end
