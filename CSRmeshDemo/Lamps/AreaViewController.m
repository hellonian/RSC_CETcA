//
//  AreaViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/26.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "AreaViewController.h"
#import "DeviceModel.h"
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"

@interface AreaViewController ()

@end

@implementation AreaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *renameItem = [[UIBarButtonItem alloc] initWithTitle:@"Rename" style:UIBarButtonItemStylePlain target:self action:@selector(renameGroupProfileName)];
    self.navigationItem.rightBarButtonItem = renameItem;
}

- (void)queryPrimaryMeshNode {
    [self.itemCluster removeAllObjects];
    
    [self.areaMembers enumerateObjectsUsingBlock:^(DeviceModel *device, NSUInteger idx, BOOL * _Nonnull stop) {
        device.isForGroup = NO;
        [self.itemCluster addObject:device];
    }];
    [self updateCollectionView];
}

- (void)renameGroupProfileName {
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:@"Rename" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *renameTextField = renameAlert.textFields.firstObject;
        if (![renameTextField.text isEqualToString:self.navigationItem.title] && renameTextField.text.length != 0) {
            self.navigationItem.title = renameTextField.text;
            NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
            [areaMutableArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[CSRAreaEntity class]]) {
                    CSRAreaEntity *areaEntity = (CSRAreaEntity *)obj;
                    if ([areaEntity.areaID isEqualToNumber:self.areaId]) {
                        areaEntity.areaName = renameTextField.text;
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        if (self.block) {
                            self.block();
                        }
                        *stop = YES;
                    }
                }
            }];
            
        }
    }];
    [renameAlert addAction:cancel];
    [renameAlert addAction:confirm];
    
    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter a new group name";
    }];
    [self presentViewController:renameAlert animated:YES completion:nil];
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
