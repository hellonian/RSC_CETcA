//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRMainViewController.h"
#import "CSRMenuSlidingSegue.h"
#import "CSRMenuViewController.h"
#import "CSRAppStateManager.h"
#import "CSRmeshSettings.h"
#import "CSRUtilities.h"

#import "CSRmeshStyleKit.h"
#import "CSRBluetoothLE.h"
#import <QuartzCore/QuartzCore.h>

@interface CSRMainViewController () <CSRBluetoothLEDelegate>

@property (nonatomic) NSMutableArray *rightButtonsArray;
@property (nonatomic) NSMutableArray *leftButtonsArray;
@property (assign, nonatomic) BOOL isCoverViewShowing;

@end

@implementation CSRMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set Initial flags for navigation items
    self.showNavMenuButton = YES;
    self.showNavSearchButton = YES;
    self.showNavCustomBackButton = NO;
    
    [self adjustNavigationControllerAppearance];
    if (!_isCoverViewShowing) {
        [self setupCoverView];
    }
    
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_isModal) {
        
        [self hideCoverView];
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showCoverView)
                                                 name:kCSRMenuShowedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideCoverView)
                                                 name:kCSRMenuHiddenNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(restartAutomaticBridgeConnection)
                                                 name:@"BridgeDisconnectedNotification"
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:kCSRMenuShowedNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:kCSRMenuHiddenNotification];
    
    [[NSNotificationCenter defaultCenter] removeObserver:@"BridgeDisconnectedNotification"];
}

- (void)viewDidLayoutSubviews
{
    _coverView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)dealloc
{
    self.view = nil;
}

#pragma mark - Cover view methods

- (void)setupCoverView
{
    _coverView = [UIView new];
    _coverView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    _coverView.backgroundColor = [UIColor blackColor];
    _coverView.alpha = 0.5;
    _coverView.hidden = YES;
    
    [self.view addSubview:_coverView];
    [self.view sendSubviewToBack:_coverView];
}

- (void)showCoverView
{
    _coverView.hidden = NO;
    [self.view bringSubviewToFront:_coverView];
    [UIView animateWithDuration:0.5
                     animations:^(void) {
                         _coverView.alpha = 0.6;
                         _navMenuButton.tintColor = [UIColor lightGrayColor];
                         _navMenuButton.enabled = NO;
    }
                     completion:^(BOOL finished){
                         self.view.userInteractionEnabled = NO;
                         _isCoverViewShowing = YES;
                     }];
}

- (void)hideCoverView
{
    if (_coverView.hidden) {
        _coverView.hidden = NO;
    }
    
        [UIView animateWithDuration:0.5
                         animations:^(void) {
                             _coverView.alpha = 0.0;
                             _navMenuButton.tintColor = [UIColor blueColor];
                             _navMenuButton.enabled = YES;
                         }
                         completion:^(BOOL finished){
                             _coverView.hidden = YES;
                             [self.view sendSubviewToBack:_coverView];
                             self.view.userInteractionEnabled = YES;
                             _isCoverViewShowing = NO;
                         }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue isKindOfClass:[CSRMenuSlidingSegue class]]) {
        [self showCoverView];

    }
}

#pragma mark - Navigation Controller methods

- (void)adjustNavigationControllerAppearance
{
    _rightButtonsArray = [NSMutableArray array];
    _leftButtonsArray = [NSMutableArray array];
    
    if (self.showNavSearchButton) {
        
        _navSearchButton.image = [CSRmeshStyleKit imageOfSearch];
        _navSearchButton.action = @selector(showSearch:);
        
    }
    
    if ([_rightButtonsArray count] > 0) {
        self.navigationItem.rightBarButtonItems = _rightButtonsArray;
    }
    
    
    [self.navigationItem setHidesBackButton:YES];
    self.navigationItem.backBarButtonItem = nil;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0],
                                 NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    [self.navigationController.navigationBar setTitleTextAttributes: attributes];

}

- (void)addCustomBackButtonItem:(UIBarButtonItem *)customBackButton
{
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = customBackButton;
    
    self.navigationItem.leftBarButtonItems = nil;
    
    if (customBackButton) {
        self.navigationItem.leftBarButtonItems = @[customBackButton];
    }
    
    self.navigationController.navigationItem.backBarButtonItem = nil;
    self.navigationController.navigationItem.backBarButtonItem = customBackButton;
}

#pragma mark - Navigation Bar items methods

- (IBAction)showSearch:(id)sender
{
    
}

- (IBAction)showMenu:(id)sender
{
}

- (void)setNavigationBarTitle:(NSString *)string
{
    NSUInteger rightButtonsCount = 0;
    
    if (_rightButtonsArray && [_rightButtonsArray count] > 0) {
        rightButtonsCount = [_rightButtonsArray count];
    }
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., 0., self.navigationController.navigationBar.frame.size.width - 22. - (rightButtonsCount * 22.), 44)];
    titleLabel.numberOfLines = 0;
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    
//    titleLabel.layer.borderColor = [[UIColor redColor] CGColor];
//    titleLabel.layer.borderWidth = 1.0;
    
    if (self.navigationItem.title) {
        titleLabel.text = self.navigationItem.title;
    } else {
        titleLabel.text = string;
    }
    
//    NSLog(@"titleLabel.frame: %@", NSStringFromCGRect(titleLabel.frame));
    
    self.navigationItem.titleView = titleLabel;
}

#pragma mark - BLE Delegate methods

- (void)discoveredBridge
{
//    NSLog(@"discovered bridges");
}

- (void)didConnectBridge:(CBPeripheral *)peripheral
{
    //TODO: this is hardcoded value, please replace it with appropriate action
    
}

#pragma mark - BLE scanning restart

- (void)restartAutomaticBridgeConnection
{
    [[CSRBluetoothLE sharedInstance] startScan];
}

@end
