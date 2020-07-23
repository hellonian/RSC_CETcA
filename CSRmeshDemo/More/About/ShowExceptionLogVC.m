//
//  ShowExceptionLogVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/7/22.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "ShowExceptionLogVC.h"

@interface ShowExceptionLogVC ()
@property (weak, nonatomic) IBOutlet UITextView *txtView;

@end

@implementation ShowExceptionLogVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIButton *btn = [[UIButton alloc] init];
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    if (_path) {
        _txtView.text = [[NSString alloc] initWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)back {
    [self.navigationController popoverPresentationController];
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
