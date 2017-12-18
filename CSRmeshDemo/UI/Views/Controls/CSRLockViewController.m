//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRLockViewController.h"
#import "CSRmeshStyleKit.h"

@interface CSRLockViewController ()

@end

@implementation CSRLockViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [_lockButton setImage:[CSRmeshStyleKit imageOfLock_on] forState:UIControlStateNormal];
    [_lockButton setImage:[CSRmeshStyleKit imageOfLock_off] forState:UIControlStateSelected];
    [_lockButton addTarget:self action:@selector(stayPressed:) forControlEvents:UIControlEventTouchDown];
}

-(void)stayPressed:(UIButton *) sender {
    if (sender.selected == YES) {
        sender.selected = NO;
    }else{
        sender.selected = YES;
    }
}

@end
