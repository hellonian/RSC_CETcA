//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRMainTableViewController.h"
#import "CSRMenuSlidingSegue.h"
#import "CSRAppStateManager.h"
#import "CSRmeshStyleKit.h"

@interface CSRMainTableViewController ()

@property (nonatomic) NSMutableArray *rightButtonsArray;
@property (nonatomic) NSMutableArray *leftButtonsArray;

@end

@implementation CSRMainTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set Initial flags for navigation items
    self.showNavMenuButton = YES;
    self.showNavSearchButton = YES;
    self.applyGlobalTintColor = YES;
    
    [self adjustNavigationControllerAppearance];
    
    [self setupCoverView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hideCoverView];
}

- (void)viewDidLayoutSubviews
{
    _coverView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)dealloc
{
    self.tableView = nil;
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
                     }];
}

- (void)hideCoverView
{
    if (_coverView.hidden) {
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
                         }];
    }
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
        _navSearchButton = [[UIBarButtonItem alloc] initWithTitle:@""
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(showSearch:)];
        
        _navSearchButton.image = [CSRmeshStyleKit imageOfSearch];
        _navSearchButton.width = 10.f;
        
        [_rightButtonsArray addObject:_navSearchButton];
        
    }
    
    self.navigationItem.rightBarButtonItems = _rightButtonsArray;
    
    if (self.applyGlobalTintColor) {
        
        //Change navigation bar color
        self.navigationController.navigationBar.barTintColor = [CSRAppStateManager sharedInstance].globalTintColor;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    }
    
    [self.navigationItem setHidesBackButton:YES];
    self.navigationItem.backBarButtonItem = nil;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0],
                                 NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    [self.navigationController.navigationBar setTitleTextAttributes: attributes];
    
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
    
    if (self.navigationItem.title) {
        titleLabel.text = self.navigationItem.title;
    } else {
        titleLabel.text = string;
    }
    
    self.navigationItem.titleView = titleLabel;
}

@end
