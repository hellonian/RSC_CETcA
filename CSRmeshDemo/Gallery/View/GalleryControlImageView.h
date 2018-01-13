//
//  GalleryControlImageView.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GalleryDropView.h"
#import "DropEntity.h"

@protocol GalleryControlImageViewDelegate <NSObject>

@optional
- (void) galleryControlImageViewDeleteDropView:(UIView *)view;
- (void) galleryControlImageViewDeleteAction:(id)sender;
- (void) galleryControlImageViewAdjustLocation:(id)sender oldRect:(CGRect)oldRect;
- (void) galleryControlImageViewPresentDetailViewAction:(id)sender;

@end

@interface GalleryControlImageView : UIImageView

@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, weak) id<GalleryControlImageViewDelegate> delegate;
@property (nonatomic, strong) NSNumber *galleryId;
@property (nonatomic, strong) NSMutableArray *drops;
@property (nonatomic, strong) UIButton *deleteButton;

- (void)addDropViewInCenter:(GalleryDropView *)view;
- (void)deleteDropView:(UIView *)view;
- (void)addDropViewInRightLocation:(DropEntity *)drop;
- (void)adjustDropViewInRightLocation;
- (void)addPanGestureRecognizer;
- (void)removePanGestureRecognizer;

@end
