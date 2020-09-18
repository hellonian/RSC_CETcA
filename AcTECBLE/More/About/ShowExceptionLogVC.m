//
//  ShowExceptionLogVC.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/7/22.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "ShowExceptionLogVC.h"

@interface ShowExceptionLogVC ()
@property (weak, nonatomic) IBOutlet UITextView *txtView;

@end

@implementation ShowExceptionLogVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (_path) {
        _txtView.text = _path;
    }
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
