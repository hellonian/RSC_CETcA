//
//  ZHViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/23.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "ZHViewController.h"
#import "MySQLDatabaseTool.h"
#import "CSRParseAndLoad.h"
#import "CSRUtilities.h"
#import "PureLayout.h"

@interface ZHViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UIButton *signInBtn;
@property (weak, nonatomic) IBOutlet UIButton *signUpBtn;

@end

@implementation ZHViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_nameTF setValue:[UIFont boldSystemFontOfSize:15] forKeyPath:@"_placeholderLabel.font"];
    [_passwordTF setValue:[UIFont boldSystemFontOfSize:15] forKeyPath:@"_placeholderLabel.font"];
    
    _nameTF.delegate = self;
    _passwordTF.delegate = self;
    
    if (self.shareDirection == ShareOut) {
        _signUpBtn.hidden = NO;
        [_signInBtn setTitle:@"Sign In / Upload Data" forState:UIControlStateNormal];
        [_signUpBtn setTitle:@"Sign Up / Upload Data" forState:UIControlStateNormal];
    }else {
        _signUpBtn.hidden = YES;
        [_signInBtn setTitle:@"Sign In / Download Data" forState:UIControlStateNormal];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMessage:) name:@"showMessage" object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showMessage" object:nil];
}

- (NSString *)getJsonString {
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    if (jsonData) {
        NSString *jsonString = [CSRUtilities stringFromData:jsonData];
        return jsonString;
    }
    return nil;
}

- (IBAction)sighIn:(UIButton *)sender {
    
    if (_nameTF.text.length > 0 && _passwordTF.text.length > 0) {
        
        MySQLDatabaseTool *tool = [[MySQLDatabaseTool alloc] init];
        if (self.shareDirection == ShareOut) {
            
            NSString *data = [self getJsonString];
            
            [tool singInWithName:_nameTF.text passsword:_passwordTF.text data:data];
            
            
        }else {
            if (self.handle) {
                self.handle(_nameTF.text,_passwordTF.text);
            }
        }
        
        
        [tool endConnect];
        
    }
}

- (IBAction)signUp:(UIButton *)sender {
    if (_nameTF.text.length > 0 && _passwordTF.text.length > 0) {
        
        MySQLDatabaseTool *tool = [[MySQLDatabaseTool alloc] init];
        NSString *data = [self getJsonString];
        [tool singUpWithName:_nameTF.text password:_passwordTF.text data:data];
        [tool endConnect];
        
    }
}

#pragma mark - 提示框

- (void)showMessage:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSString *message = dic[@"message"];
    [self showAlert:message];
}

- (void)showAlert:(NSString *)string {
    UIAlertController *aler = [UIAlertController alertControllerWithTitle:nil message:string preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [aler addAction:cancel];
    
    [self presentViewController:aler animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate methods


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}


@end
