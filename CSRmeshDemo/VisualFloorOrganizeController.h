//
//  VisualFloorOrganizeController.h
//  BluetoothTest
//
//  Created by hua on 9/1/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VisualControlContentView.h"
#import "Floor.h"
#import "ImageDropButton.h"

typedef void(^VisualFloorOrganizeHandle)(VisualControlContentView *panel);

@interface VisualFloorOrganizeController : UIViewController

@property (nonatomic,strong) VisualControlContentView *content;
@property (nonatomic,strong) NSLayoutConstraint *bottomLayout;
@property (nonatomic,strong) Floor *floorDelegate;
@property (nonatomic,assign) CGFloat photoGeometry;
@property (nonatomic,assign) BOOL isEdit;

@property (nonatomic,copy) VisualFloorOrganizeHandle handle;

- (void)setOrganizingHandle:(VisualFloorOrganizeHandle)handle;
- (void)openDeviceList;
- (void)stepOn:(NSInteger)step;
- (void)connectLightToImageButton;
- (void)fixPositionOfRepresentation;

- (void)layoutView;
- (void)openCamera;
- (void)addVisualControlData:(NSData*)data withIndex:(nonnull NSString *)index;

@end
