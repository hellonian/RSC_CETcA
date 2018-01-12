//
//  GalleryEditToolView.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/9.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GalleryEditToolViewDelegate <NSObject>

- (void)adjustControlImageSize:(NSInteger)row adjustHeight:(float)height;

@end

@interface GalleryEditToolView : UIView

@property (nonatomic,weak) id<GalleryEditToolViewDelegate> delegate;
@property (nonatomic,assign) float isLimitHeight;

@end
