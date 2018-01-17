//
//  SceneCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/27.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SpecialFlowLayoutCollectionViewSuperCell.h"

@interface SceneCell : SpecialFlowLayoutCollectionViewSuperCell

@property (nonatomic,copy) NSString *sceneName;
@property (nonatomic,strong) NSMutableDictionary *sceneMember;
@property (weak, nonatomic) IBOutlet UIImageView *sceneView;
@property (nonatomic,assign) NSInteger imageNum;

- (void)changeControlCircleColor:(UIColor*)color;

@end
