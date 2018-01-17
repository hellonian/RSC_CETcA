//
//  LightClusterViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/11.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SpecialFlowLayoutCollectionController.h"

@protocol LightClusterControllerDelegate <NSObject>
@optional
- (void)lightClusterControllerUpdateNumberOfSelectedLight:(NSInteger)number;
@end

@interface LightClusterViewController : SpecialFlowLayoutCollectionController

@property (nonatomic,assign) BOOL allowGroupEdit;
@property (nonatomic,weak) id<LightClusterControllerDelegate> delegate;

//子类使用到的方法
- (void)disableSomeFeatureOfSuper;
- (void)onlyYou:(NSNumber *)deviceId;
- (void)actionWhenSelectCell:(UICollectionViewCell*)cell;
- (void)actionWhenCancelSelectCell:(UICollectionViewCell*)cell;
//- (void)updateReusedCell:(UICollectionViewCell*)cell;

- (void)beginGroupOrganizing;
- (void)endGroupOrganizing;
- (void)groupOrganizingFinalStep;

@end
