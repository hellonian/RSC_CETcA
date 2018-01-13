//
//  DropView.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryDropView : UIView

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,assign) BOOL isEditing;
@property (nonatomic,strong) NSNumber *dropId;
@property (nonatomic, retain) NSNumber * boundRatio;
@property (nonatomic, retain) NSNumber * centerXRatio;
@property (nonatomic, retain) NSNumber * centerYRatio;

@end