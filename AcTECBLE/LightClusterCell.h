//
//  LightClusterCell.h
//  BluetoothAcTEC
//
//  Created by hua on 10/8/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "SpecialFlowLayoutCollectionViewSuperCell.h"
#import "DynamicIconView.h"

@interface LightClusterCell : SpecialFlowLayoutCollectionViewSuperCell
@property (nonatomic,strong) NSNumber *deviceID;
@property (nonatomic,strong) NSArray *groupMember;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,strong) NSNumber *groupId;
@property (nonatomic,assign) BOOL isAlloc;
@property (nonatomic,assign) BOOL isGroup;
@property (weak, nonatomic) IBOutlet DynamicIconView *groupView;
@property (weak, nonatomic) IBOutlet UIImageView *lightPresentation;

@property (assign, nonatomic) BOOL ignoreUpdate;

@property (nonatomic,assign) BOOL isDimmer;

- (void)setRoundCorner:(CGFloat)radius;
- (void)showGroupDismissButton:(BOOL)show;
- (void)updateBrightnessPercentage:(CGFloat)percentage;
- (void)updateBrightness:(CGFloat)percentage;
- (BOOL)isGroupOrganizingSelected;
- (void)showOfflineUI;
- (void)removeOfflineUI;

- (void)updateBrightness:(CGFloat)percentage animated:(BOOL)animated;

@end
