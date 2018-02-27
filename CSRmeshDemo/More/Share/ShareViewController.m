//
//  ShareViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/20.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "ShareViewController.h"
#import "PureLayout.h"
#import "QRCodeGenerateVC.h"
#import "QRCodeScanningVC.h"
#import "MySQLDatabaseTool.h"
#import "CSRUtilities.h"
#import "CSRPlaceEntity.h"
#import "CSRAppStateManager.h"
#import "CSRParseAndLoad.h"
#import "CSRDatabaseManager.h"
#import "ZHViewController.h"

@interface ShareViewController ()
{
    NSLayoutConstraint *constraint;
    ShareDirection currenShareDirection;
    UIView *bgView;
}

@property (strong, nonatomic) IBOutlet UIView *chooseView;
@property (nonatomic,strong) CSRPlaceEntity *placeEntity;

@end

@implementation ShareViewController

static NSString * const sceneListKey = @"com.actec.bluetooth.sceneListKey";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Share";
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting_back"] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
    [self.view addSubview:self.chooseView];
    constraint = [self.chooseView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view withOffset:100];
    [self.chooseView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.view];
    [self.chooseView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.view];
    [self.chooseView autoSetDimension:ALDimensionHeight toSize:150];
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)share:(UIButton *)sender {
    
    constraint.constant = -50;
    [UIView animateWithDuration:0.5 animations:^{
        [self.chooseView layoutIfNeeded];
    }];
    switch (sender.tag) {
        case 100:
            currenShareDirection = ShareOut;
            break;
        case 200:
            currenShareDirection = ShareIn;
            break;
        default:
            break;
    }
}
- (IBAction)QRShare:(UIButton *)sender {
    switch (currenShareDirection) {
        case ShareOut:
        {
            constraint.constant = 100;
            QRCodeGenerateVC *VC = [[QRCodeGenerateVC alloc] init];
            [self.navigationController pushViewController:VC animated:YES];
            break;
        }
        case ShareIn:
        {
            constraint.constant = 100;
            QRCodeScanningVC *scanVC = [[QRCodeScanningVC alloc] init];
            scanVC.handle = ^(NSString *uuid) {
                
                bgView = [[UIView alloc] init];
                bgView.backgroundColor = [UIColor whiteColor];
                bgView.alpha = 0.5;
                [self.view addSubview:bgView];
                [bgView autoPinEdgesToSuperviewEdges];
                UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                spinner.color = [UIColor blackColor];
                [bgView addSubview:spinner];
                [spinner autoCenterInSuperview];
                [spinner startAnimating];
                [self download:uuid];
                
                [self performSelector:@selector(stopSpinner:) withObject:spinner afterDelay:4];
                   
            };
            [self.navigationController pushViewController:scanVC animated:YES];
            break;
        }
        default:
            break;
    }
}

- (void)stopSpinner:(UIActivityIndicatorView *)spinner {
    [spinner stopAnimating];
    [bgView removeFromSuperview];
}

- (IBAction)ZHShare:(UIButton *)sender {
    switch (currenShareDirection) {
        case ShareOut:
        {
            constraint.constant = 100;
            ZHViewController *ZHVC = [[ZHViewController alloc] init];
            ZHVC.shareDirection = ShareOut;
            [self.navigationController pushViewController:ZHVC animated:YES];
            break;
        }
        case ShareIn:
        {
            constraint.constant = 100;
            ZHViewController *ZHVC = [[ZHViewController alloc] init];
            ZHVC.shareDirection = ShareIn;
            ZHVC.handle = ^(NSString *name,NSString *password) {
                
                MySQLDatabaseTool *tool = [[MySQLDatabaseTool alloc] init];
                NSArray *array = [tool signInWithName:name passWord:password];
                
                if (array.count > 0) {
                    NSDictionary *dic = array[0];
                    NSString *dataStr = dic[@"DATA"];
                    NSString *sceneList = dic[@"SCENELIST"];
                    
                    [self fixLampData:dataStr];
                    
                    NSArray *list = [sceneList componentsSeparatedByString:@"|"];
                    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
                    [center setObject:list forKey:sceneListKey];
                    for (NSString *sceneKey in list) {
                        NSData *sceneData = [tool seleteWithName:name password:password sceneKey:sceneKey];
                        [center setObject:sceneData forKey:sceneKey];
                    }
                    [center synchronize];
                }
                
                [tool endConnect];
                
                
                
            };
            [self.navigationController pushViewController:ZHVC animated:YES];
            break;
        }
        default:
            break;
    }
}

- (void)download:(NSString *)uuid {
    
    MySQLDatabaseTool *tool = [[MySQLDatabaseTool alloc] init];
    NSArray *array = [tool seleteWithUuid:uuid];
    
    if (array.count > 0) {
        
        NSDictionary *dic = array[0];
        NSString *dataStr = dic[@"DATA"];
        NSString *sceneList = dic[@"SCENELIST"];
        
        [self fixLampData:dataStr];
        
        NSArray *list = [sceneList componentsSeparatedByString:@"|"];
        NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
        [center setObject:list forKey:sceneListKey];
        for (NSString *sceneKey in list) {
            NSData *sceneData = [tool seletSceneDataWithUuid:uuid sceneKey:sceneKey];
            [center setObject:sceneData forKey:sceneKey];
        }
        [center synchronize];
        
        
    }
    
    
    [tool endConnect];
}

- (void)fixLampData: (NSString *)dataStr {
    NSData *data = [CSRUtilities authCodefromString:dataStr];
    
    _placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    
    [self checkForSettings];
    
    NSError *error = nil;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
    [[CSRAppStateManager sharedInstance] setupPlace];
    
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    [parseLoad deleteEntitiesInSelectedPlace];
    [parseLoad parseIncomingDictionary:jsonDictionary];
    
    [[MeshServiceApi sharedInstance] setNetworkPassPhrase:_placeEntity.passPhrase];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetData" object:self];
}

- (void)checkForSettings
{
    if (_placeEntity.settings) {
        
        _placeEntity.settings.retryInterval = @500;
        _placeEntity.settings.retryCount = @10;
        _placeEntity.settings.concurrentConnections = @1;
        _placeEntity.settings.listeningMode = @1;
        
    } else {
        
        CSRSettingsEntity *settings = [NSEntityDescription insertNewObjectForEntityForName:@"CSRSettingsEntity"
                                                                    inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
        settings.retryInterval = @500;
        settings.retryCount = @10;
        settings.concurrentConnections = @1;
        settings.listeningMode = @1;
        
        _placeEntity.settings = settings;
        
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    constraint.constant = 100;
    [UIView animateWithDuration:0.5 animations:^{
        [self.chooseView layoutIfNeeded];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
