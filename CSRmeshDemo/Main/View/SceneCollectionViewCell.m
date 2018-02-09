//
//  SceneCollectionViewCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SceneCollectionViewCell.h"
#import "SceneEntity.h"
#import "CSRDeviceEntity.h"

@interface SceneCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (nonatomic,strong) NSArray *iconArray;


@end

@implementation SceneCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _iconArray = @[@"home", @"sleep", @"party", @"TV", @"reading", @"away", @"getup", @"dining", @"custom"];
}


- (void)configureCellWithiInfo:(id)info withCellIndexPath:(NSIndexPath *)indexPath{
    
    if ([info isKindOfClass:[SceneEntity class]]) {
        SceneEntity *sceneEntity = (SceneEntity *)info;
        
        NSString *iconString = self.iconArray[[sceneEntity.iconID integerValue]];
        self.iconView.image = [UIImage imageNamed:[NSString stringWithFormat:@"Scene_%@_gray",iconString]];
        self.iconView.highlightedImage = [UIImage imageNamed:[NSString stringWithFormat:@"Scene_%@_orange",iconString]];
        self.nameLabel.text = sceneEntity.sceneName;
        self.nameLabel.highlightedTextColor = DARKORAGE;
        self.sceneId = sceneEntity.sceneID;
        if ([sceneEntity.sceneID isEqualToNumber:@0] || [sceneEntity.sceneID isEqualToNumber:@1]) {
            [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(defaultCelllongTap:)]];
        }else {
            [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(customCelllongTap:)]];
        }
        
        return;
    }  
}

- (void)defaultCelllongTap:(UILongPressGestureRecognizer *)longRecognizer {
    if (longRecognizer.state == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        UIMenuController *menu=[UIMenuController sharedMenuController];
        UIMenuItem *edit = [[UIMenuItem alloc]initWithTitle:@"Edit Scene" action:@selector(editSceneProfile)];
        [menu setMenuItems:@[edit]];
        [menu setTargetRect:self.bounds inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
}

- (void)customCelllongTap:(UILongPressGestureRecognizer *)longRecognizer {
    if (longRecognizer.state == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        UIMenuController *menu=[UIMenuController sharedMenuController];
        UIMenuItem *edit = [[UIMenuItem alloc]initWithTitle:@"Edit Scene" action:@selector(editSceneProfile)];
        UIMenuItem *icon = [[UIMenuItem alloc]initWithTitle:@"Change Icon" action:@selector(changeSceneIcon)];
        UIMenuItem *rename = [[UIMenuItem alloc]initWithTitle:@"Rename" action:@selector(renameSceneProfile)];
        [menu setMenuItems:@[edit,icon,rename]];
        [menu setTargetRect:self.bounds inView:self];
        [menu setMenuVisible:YES animated:YES];
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
