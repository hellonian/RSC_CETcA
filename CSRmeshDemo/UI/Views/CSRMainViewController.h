//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import <UIKit/UIKit.h>
#import "CSRConstants.h"

@interface CSRMainViewController : UIViewController

@property (nonatomic) UIView *coverView;
@property (nonatomic) IBOutlet UIBarButtonItem *navMenuButton;
@property (nonatomic) IBOutlet UIBarButtonItem *navSearchButton;
@property (nonatomic) UIBarButtonItem *navCustomBackButton;

@property (assign, nonatomic) BOOL showNavMenuButton;
@property (assign, nonatomic) BOOL showNavSearchButton;
@property (assign, nonatomic) BOOL showNavCustomBackButton;
@property (assign, nonatomic) BOOL isModal;

- (void)adjustNavigationControllerAppearance;
- (void)addCustomBackButtonItem:(UIBarButtonItem *)customBackButton;
- (void)setNavigationBarTitle:(NSString *)string;
- (void)showCoverView;
- (void)hideCoverView;


@end

