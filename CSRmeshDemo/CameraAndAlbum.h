//
//  CameraAndAlbum.h
//  CWGJIOSSDK
//
//  Created by hua on 16/4/22.
//  Copyright © 2016年 hua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^ImagePickerHandler)(UIImage *fetchImage);

@interface CameraAndAlbum : UIImagePickerController

- (instancetype)initCamera;
- (instancetype)initAlbum;

- (void)setPickerHandler:(ImagePickerHandler)handler;
- (void)performPickerHandlerWithImage:(UIImage*)image;
@end
