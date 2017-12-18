//
//  SceneCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/27.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SceneCell.h"
#import "LightDot.h"
#import "LightSceneBringer.h"
#import "UIImage+Darkness.h"

@interface SceneCell ()
@property (weak, nonatomic) IBOutlet LightDot *controlCircle;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *banner;
@property (nonatomic,strong) NSMutableArray *lightDot;
@property (nonatomic,assign) BOOL allowEdit;
@end

@implementation SceneCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.allowEdit = YES;
    self.sceneMember = [[NSMutableDictionary alloc] init];
    self.lightDot = [[NSMutableArray alloc] init];
}

- (void)configureCellWithInfo:(id)info adjustSize:(CGSize)size {
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    self.deleteButton.hidden = YES;
    self.controlCircle.layer.cornerRadius = size.width*0.5;
    self.controlCircle.layer.masksToBounds = YES;
    
    UIColor *color0 = [UIColor colorWithRed:219/255.0 green:112/255.0 blue:147/255.0 alpha:1];
    UIColor *color1 = [UIColor colorWithRed:199/255.0 green:12/255.0 blue:133/255.0 alpha:1];
    UIColor *color2 = [UIColor colorWithRed:153/255.0 green:50/255.0 blue:204/255.0 alpha:1];
    UIColor *color3 = [UIColor colorWithRed:147/255.0 green:112/255.0 blue:219/255.0 alpha:1];
    UIColor *color4 = [UIColor colorWithRed:65/255.0 green:105/255.0 blue:225/255.0 alpha:1];
    UIColor *color5 = [UIColor colorWithRed:70/255.0 green:130/255.0 blue:180/255.0 alpha:1];
    UIColor *color6 = [UIColor colorWithRed:95/255.0 green:158/255.0 blue:160/255.0 alpha:1];
    UIColor *color7 = [UIColor colorWithRed:60/255.0 green:179/255.0 blue:113/255.0 alpha:1];
    UIColor *color8 = [UIColor colorWithRed:189/255.0 green:183/255.0 blue:107/255.0 alpha:1];
    UIColor *color9 = [UIColor colorWithRed:218/255.0 green:165/255.0 blue:0/255.0 alpha:1];
    UIColor *color10 = [UIColor colorWithRed:188/255.0 green:143/255.0 blue:143/255.0 alpha:1];
    UIColor *color11 = [UIColor colorWithRed:0/255.0 green:139/255.0 blue:139/255.0 alpha:1];
    UIColor *color12 = [UIColor colorWithRed:139/255.0 green:0/255.0 blue:0/255.0 alpha:1];
    UIColor *color13 = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:139/255.0 alpha:1];
    UIColor *color14 = [UIColor colorWithRed:122/255.0 green:139/255.0 blue:139/255.0 alpha:1];
    UIColor *color15 = [UIColor colorWithRed:0/255.0 green:104/255.0 blue:139/255.0 alpha:1];
    UIColor *color16 = [UIColor colorWithRed:74/255.0 green:112/255.0 blue:139/255.0 alpha:1];
    
    NSArray *colors = @[color0,color1,color2,color3,color4,color5,color6,color7,color8,color9,color10,color11,color12,color13,color14,color15,color16];
    NSInteger rIndex = arc4random()%17;
    self.controlCircle.backgroundColor = colors[rIndex];
    self.controlCircle.highlightColor = self.controlCircle.backgroundColor;
    self.sceneView.layer.cornerRadius = size.width*0.5*0.5;
    
    if ([info isKindOfClass:[LightSceneBringer class]]) {
        LightSceneBringer *sceneProfile = info;
        
        NSString *pName = sceneProfile.profileName;
        self.sceneName = pName;
        self.allowEdit = (![pName isEqualToString:@"Home"] && ![pName isEqualToString:@"Away"]);
        if (self.allowEdit) {
            [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTap3:)]];
        }else {
            [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTap:)]];
        }

        self.imageNum = sceneProfile.sceneImage;
        self.sceneView.image = [UIImage imageNamed:[NSString stringWithFormat:@"scence%ld",sceneProfile.sceneImage-800]];
        self.banner.text = sceneProfile.profileName;
        
        [self.sceneMember removeAllObjects];
        [self.sceneMember addEntriesFromDictionary:sceneProfile.groupMember];
        [self updateLightDot];
    }
    
}
- (void)longTap:(UILongPressGestureRecognizer *)longRecognizer {
    if (longRecognizer.state == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        UIMenuItem *edit = [[UIMenuItem alloc]initWithTitle:@"Edit Scene" action:@selector(editSceneProfile)];
        UIMenuController *menu=[UIMenuController sharedMenuController];
        [menu setMenuItems:@[edit]];
        [menu setTargetRect:self.bounds inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
}
- (void)longTap3:(UILongPressGestureRecognizer *)longRecognizer {
    if (longRecognizer.state == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        UIMenuItem *edit = [[UIMenuItem alloc]initWithTitle:@"Edit Scene" action:@selector(editSceneProfile)];
        UIMenuItem *icon = [[UIMenuItem alloc]initWithTitle:@"Change Icon" action:@selector(changeSceneIcon)];
        UIMenuItem *rename = [[UIMenuItem alloc]initWithTitle:@"Rename" action:@selector(renameSceneProfile)];
        UIMenuController *menu=[UIMenuController sharedMenuController];
        [menu setMenuItems:@[edit,icon,rename]];
        [menu setTargetRect:self.bounds inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
}

- (IBAction)clickOnDeleteButton:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(specialFlowLayoutCollectionViewSuperCell:didClickOnDeleteButton:)]) {
        [self.delegate specialFlowLayoutCollectionViewSuperCell:self didClickOnDeleteButton:sender];
    }
}

- (void)updateLightDot {
    //the cell's size is explicit
    if (self.lightDot.count>0) {
        for (LightDot *dot in self.lightDot) {
            [dot removeFromSuperview];
        }
    }
    
    NSInteger total = self.sceneMember.count;
    
    if (total>0) {
        CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)-4);
        CGFloat width = self.bounds.size.width/10.0;
        CGFloat radius = self.bounds.size.width/2;
        double startAngle = (total%2==0) ? (M_PI_2 - M_PI_2/6 - (total/2-1)*M_PI_2/3) : (M_PI_2 - (total-1)*M_PI_2/6);
        
        for (NSInteger index=0; index<total; index++) {
            LightDot *dot = [[LightDot alloc] initWithFrame:CGRectMake(0, 0, width, width)];
            dot.backgroundColor = [UIColor whiteColor];
            dot.layer.masksToBounds = YES;
            dot.layer.cornerRadius = width*0.5;
            [dot.layer setBorderWidth:1];
            [dot.layer setBorderColor:[UIColor darkGrayColor].CGColor];
            dot.lightMAC = self.sceneMember.allKeys[index];
            dot.center = CGPointMake(center.x+radius*cos(startAngle+index*M_PI_2/3), center.y-radius*sin(startAngle+index*M_PI_2/3));
            
            [self.lightDot addObject:dot];
            [self addSubview:dot];
        }
    }
}

- (void)changeControlCircleColor:(UIColor*)color {
    self.controlCircle.backgroundColor = color;
    self.controlCircle.highlightColor = color;
}

- (void)showDeleteButton:(BOOL)show {
    if (self.allowEdit) {
        self.deleteButton.hidden = !show;
    }
    else {
        self.deleteButton.hidden = YES;
    }
}

- (void)editSceneProfile {
    [self requireRespondingToAction:@"Edit"];
}

- (void)changeSceneIcon {
    [self requireRespondingToAction:@"Icon"];
}

- (void)renameSceneProfile {
    [self requireRespondingToAction:@"Rename"];
}

- (void)requireRespondingToAction:(NSString*)actionName {
    if (self.delegate && [self.delegate respondsToSelector:@selector(specialFlowLayoutCollectionViewSuperCell:requireMenuAction:)]) {
        [self.delegate specialFlowLayoutCollectionViewSuperCell:self requireMenuAction:actionName];
    }
}


-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(editSceneProfile)||action == @selector(changeSceneIcon)||action == @selector(renameSceneProfile)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}
-(BOOL)canBecomeFirstResponder {
    return YES;
}


@end
