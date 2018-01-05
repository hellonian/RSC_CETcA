//
//  GalleryControlImageView.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GalleryDropView.h"

@protocol GalleryControlImageViewDelegate <NSObject>

- (void) galleryControlImageViewDeleteDropView:(UIView *)view;

@end

@interface GalleryControlImageView : UIImageView

@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, weak) id<GalleryControlImageViewDelegate> delegate;

- (void)addDropViewInCenter:(GalleryDropView *)view;
- (void)deleteDropView:(UIView *)view;

@end
