//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import <UIKit/UIKit.h>

@interface CSRMainTableViewController : UITableViewController

@property (nonatomic) UIView *coverView;
@property (nonatomic) IBOutlet UIBarButtonItem *navMenuButton;
@property (nonatomic) UIBarButtonItem *navCloudButton;
@property (nonatomic) UIBarButtonItem *navSearchButton;

@property (assign, nonatomic) BOOL showNavMenuButton;
@property (assign, nonatomic) BOOL showNavSearchButton;
@property (assign, nonatomic) BOOL applyGlobalTintColor;

- (void)adjustNavigationControllerAppearance;
- (void)setNavigationBarTitle:(NSString *)string;
- (void)showCoverView;
- (void)hideCoverView;

@end
