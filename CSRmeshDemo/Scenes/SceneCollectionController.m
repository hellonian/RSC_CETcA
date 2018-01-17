//
//  SceneCollectionController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/26.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SceneCollectionController.h"
#import "LightSceneBringer.h"
#import "SceneIconsViewController.h"
#import "ConfiguredDeviceListController.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import <MBProgressHUD.h>
#import "SceneCell.h"
#import <CSRmesh/PowerModelApi.h>
#import <CSRmesh/LightModelApi.h>

@interface SceneCollectionController ()<MBProgressHUDDelegate>

@end

@implementation SceneCollectionController

static NSString * const sceneListKey = @"com.actec.bluetooth.sceneListKey";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadSceneProfile];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self endEdit];
    
}

#pragma mark - Load Profile

- (void)loadSceneProfile {
    [self.itemCluster removeAllObjects];
    
    NSArray *data = [self readSceneProfileData];
    
    for (NSData *sceneData in data) {
        LightSceneBringer *sceneProfile = [LightSceneBringer unArchiveData:sceneData];
        [self.itemCluster addObject:sceneProfile];
    }
    
    if (self.itemCluster.count>0) {
        [self updateCollectionView];
    }
}

- (nullable NSArray*)readSceneProfileData {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSArray *list = [center arrayForKey:sceneListKey];
    if (!list) {
        return nil;
    }
    NSMutableArray *dataSet = [[NSMutableArray alloc]init];
    
    for (NSString *key in list) {
        NSLog(@"= = = = = %@",key);
        [dataSet addObject:[center objectForKey:key]];
    }
    
    return dataSet;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = [self dataIndexOfCellAtIndexPath:indexPath];
    LightSceneBringer *profile = [self.itemCluster objectAtIndex:index];
    [self specialActionForDefaultScene:profile];
    
    //control
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [profile.groupMember enumerateKeysAndObjectsUsingBlock:^(NSNumber *deviceId,NSDictionary *dic,BOOL *stop){
            NSString *shortName = dic[@"shortName"];
            NSNumber *powerState = dic[@"powerState"];
            NSNumber *brightness = dic[@"brightness"];
            if (![powerState boolValue]) {
                [[PowerModelApi sharedInstance] setPowerState:deviceId state:@(0) success:nil failure:nil];
            }else {
                [[PowerModelApi sharedInstance] setPowerState:deviceId state:@(1) success:nil failure:nil];
                if ([shortName isEqualToString:@"D350BT"]) {
                    [[LightModelApi sharedInstance] setLevel:deviceId level:brightness success:nil failure:nil];
                }
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[LightModelApi sharedInstance] getState:deviceId success:nil failure:nil];
            });
        }];
    });
}

- (void)specialActionForDefaultScene:(LightSceneBringer*)profile {
    NSString *pName = profile.profileName;
    
    if ([pName isEqualToString:@"Home"] || [pName isEqualToString:@"Away"]) {
        if (profile.groupMember.count==0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"No light in this scene,do you want to add light now?" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

                ConfiguredDeviceListController *list = [[ConfiguredDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
                [list prepareEditingCurrentSceneProfile:profile.profileName sceneMemberInfo:profile.groupMember isNewAdd:NO image:profile.sceneImage];
                [self.navigationController pushViewController:list animated:YES];
                
            }];
            [alert addAction:cancel];
            [alert addAction:confirm];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

//remove scene
- (void)specialFlowLayoutCollectionViewSuperCell:(UICollectionViewCell *)cell didClickOnDeleteButton:(UIButton *)sender {
    SceneCell *sceneCell = (SceneCell*)cell;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Are you sure to remove this scene?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSInteger index = [self dataIndexOfCellAtIndexPath:sceneCell.myIndexpath];
        [self.itemCluster removeObjectAtIndex:index];
        
        [self removeSceneProfile:sceneCell.sceneName];
        [self updateCollectionView];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self beginEdit];
        });
        
        
    }];
    [alert addAction:cancel];
    [alert addAction:confirm];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)removeSceneProfile:(NSString*)pName {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSArray *list = [center arrayForKey:sceneListKey];
    
    if (list) {
        NSMutableArray *updateList = [NSMutableArray arrayWithArray:list];
        [updateList removeObject:pName];
        [center setObject:updateList forKey:sceneListKey];
        
        [center removeObjectForKey:pName];
    }
}

//edit
- (void)specialFlowLayoutCollectionViewSuperCell:(UICollectionViewCell *)cell requireMenuAction:(NSString *)actionName {
    SceneCell *sceneCell = (SceneCell*)cell;
    
    if ([actionName isEqualToString:@"Edit"]) {
        ConfiguredDeviceListController *list = [[ConfiguredDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
        [list prepareEditingCurrentSceneProfile:sceneCell.sceneName sceneMemberInfo:sceneCell.sceneMember isNewAdd:NO image:sceneCell.imageNum];
        [self.navigationController pushViewController:list animated:YES];
        return;
    }
    
    if ([actionName isEqualToString:@"Icon"]) {
        [self changeIconForCellAtIndexPath:sceneCell.myIndexpath withCell:cell];
        return;
    }
    
    if ([actionName isEqualToString:@"Rename"]) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Rename" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *renameTextField = alert.textFields.firstObject;
            if (renameTextField.text.length != 0){
                BOOL exist = [self checkSceneName:renameTextField.text];
                if (exist) {
                     [self showTextHud:@"Scene name conflict!"];
                }
            }
            
            NSInteger index = [self dataIndexOfCellAtIndexPath:sceneCell.myIndexpath];
            LightSceneBringer *profile = self.itemCluster[index];
            NSString *oldName = profile.profileName;
            profile.profileName = renameTextField.text;
            
            [self removeSceneProfile:oldName];
            [self addNewSceneProfile:[profile archive] profileName:renameTextField.text];
            [self.lightPanel reloadItemsAtIndexPaths:@[sceneCell.myIndexpath]];
        }];
        [alert addAction:cancel];
        [alert addAction:confirm];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Enter a new name for scene";
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
}

- (BOOL)checkSceneName:(NSString*)newName {
    NSArray *sceneList = [[NSUserDefaults standardUserDefaults] arrayForKey:sceneListKey];
    __block BOOL isExist = NO;
    if ([sceneList count]==0) {
        return NO;
    }
    
    [sceneList enumerateObjectsUsingBlock:^(NSString *profileName,NSUInteger idx, BOOL *stop){
        if ([profileName isEqualToString:newName]) {
            isExist = YES;
            *stop = YES;
        }
    }];
    
    return isExist;
    
}



- (void)changeIconForCellAtIndexPath:(NSIndexPath*)indexPath withCell:(UICollectionViewCell *)cell{
    SceneIconsViewController *svc = [[SceneIconsViewController alloc] init];
    NSInteger index = [self dataIndexOfCellAtIndexPath:indexPath];
    LightSceneBringer *profile = self.itemCluster[index];
    svc.title = profile.profileName;
    svc.click = ^(NSInteger tag){
        profile.sceneImage = tag;
        
        [self addNewSceneProfile:[profile archive] profileName:profile.profileName];

        [self.lightPanel reloadItemsAtIndexPaths:@[indexPath]];

    };

    UINavigationController *iconNav = [[UINavigationController alloc] initWithRootViewController:svc];
    iconNav.modalPresentationStyle = UIModalPresentationPopover;

    [self presentViewController:iconNav animated:YES completion:nil];

    UIPopoverPresentationController *popover = iconNav.popoverPresentationController;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popover.sourceRect = cell.bounds;
    popover.sourceView = cell;

}

- (void)addNewSceneProfile:(NSData*)profileData profileName:(NSString*)pName {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSArray *list = [center arrayForKey:sceneListKey];
    NSMutableArray *updatedList = [[NSMutableArray alloc]init];
    
    if (list) {
        [updatedList addObjectsFromArray:list];
    }
    
    if (![updatedList containsObject:pName]) {
        [updatedList addObject:pName];
        [center setObject:updatedList forKey:sceneListKey];
    }
    
    [center setObject:profileData forKey:pName];
    [center synchronize];
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.label.numberOfLines = 0;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:1.5f];
}
@end
