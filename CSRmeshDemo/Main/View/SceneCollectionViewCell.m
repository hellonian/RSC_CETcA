//
//  SceneCollectionViewCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "SceneCollectionViewCell.h"
#import "SceneEntity.h"
#import "CSRDeviceEntity.h"
#import "CSRConstants.h"

@interface SceneCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
//@property (nonatomic,strong) NSArray *iconArray;
@property(nonatomic, strong) NSString *sceneName;


@end

@implementation SceneCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
//    _iconArray = @[@"home", @"sleep", @"party", @"TV", @"reading", @"away", @"getup", @"dining", @"custom"];
}


- (void)configureCellWithiInfo:(id)info withCellIndexPath:(NSIndexPath *)indexPath{
    
    if ([info isKindOfClass:[SceneEntity class]]) {
        SceneEntity *sceneEntity = (SceneEntity *)info;
        
        NSString *iconString = kSceneIcons[[sceneEntity.iconID integerValue]];
        self.iconView.image = [UIImage imageNamed:[NSString stringWithFormat:@"Scene_%@_gray",iconString]];
        self.iconView.highlightedImage = [UIImage imageNamed:[NSString stringWithFormat:@"Scene_%@_orange",iconString]];
        if ([sceneEntity.sceneName isEqualToString:@"Home"] || [sceneEntity.sceneName isEqualToString:@"Away"] || [sceneEntity.sceneName isEqualToString:@"Scene1"] || [sceneEntity.sceneName isEqualToString:@"Scene2"] || [sceneEntity.sceneName isEqualToString:@"Scene3"] || [sceneEntity.sceneName isEqualToString:@"Scene4"]) {
            self.nameLabel.text = AcTECLocalizedStringFromTable(sceneEntity.sceneName, @"Localizable");
        }else {
            self.nameLabel.text = sceneEntity.sceneName;
        }
        
        self.nameLabel.highlightedTextColor = DARKORAGE;
        self.sceneId = sceneEntity.sceneID;
        self.sceneName = sceneEntity.sceneName;
        [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sceneCellLongTap:)]];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sceneCellTap:)]];
        
        return;
    }  
}

- (void)sceneCellLongTap:(UILongPressGestureRecognizer *)longRecognizer {
    if (longRecognizer.state == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        UIMenuController *menu=[UIMenuController sharedMenuController];
        UIMenuItem *edit = [[UIMenuItem alloc]initWithTitle:AcTECLocalizedStringFromTable(@"EditScene", @"Localizable") action:@selector(editSceneProfile)];
        UIMenuItem *icon = [[UIMenuItem alloc]initWithTitle:AcTECLocalizedStringFromTable(@"ChangeIcon", @"Localizable") action:@selector(changeSceneIcon)];
        UIMenuItem *rename = [[UIMenuItem alloc]initWithTitle:AcTECLocalizedStringFromTable(@"Rename", @"Localizable") action:@selector(renameSceneProfile)];
        if ([self.sceneId isEqualToNumber:@0] || [self.sceneId isEqualToNumber:@1]) {
            [menu setMenuItems:@[edit]];
        }else {
            [menu setMenuItems:@[edit,icon,rename]];
        }
        [menu setTargetRect:self.bounds inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
}

- (void)sceneCellTap:(UITapGestureRecognizer *)tapRecognizer {
    if (tapRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateSceneCellTapAction:)]) {
            [self.superCellDelegate superCollectionViewCellDelegateSceneCellTapAction:self.sceneId];
        }
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(editSceneProfile) || action == @selector(changeSceneIcon) || action == @selector(renameSceneProfile)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)editSceneProfile {
    [self menuAction:@"Edit"];
}

- (void)changeSceneIcon {
    [self menuAction:@"Icon"];
}

- (void)renameSceneProfile {
    [self menuAction:@"Rename"];
}

- (void)menuAction:(NSString *)actionName {
    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateSceneMenuAction:actionName:)]) {
        [self.superCellDelegate superCollectionViewCellDelegateSceneMenuAction:self.sceneId actionName:actionName];
    }
}

@end
