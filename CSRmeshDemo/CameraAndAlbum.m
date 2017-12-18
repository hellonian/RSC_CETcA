//
//  CameraAndAlbum.m
//  CWGJIOSSDK
//
//  Created by hua on 16/4/22.
//  Copyright © 2016年 hua. All rights reserved.
//

#import "CameraAndAlbum.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface CameraAndAlbum ()
@property (nonatomic,copy)ImagePickerHandler pickerHandler;
@end

@implementation CameraAndAlbum

- (instancetype)initCamera {
    self = [super init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        self.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.allowsEditing = YES;
        self.mediaTypes = @[(NSString *)kUTTypeImage];
    }
    return self;
}

- (instancetype)initAlbum {
    self = [super init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    return self;
}

- (void)setPickerHandler:(ImagePickerHandler)handler {
    _pickerHandler = handler;
}

- (void)performPickerHandlerWithImage:(UIImage*)image {
    if (self.pickerHandler) {
        self.pickerHandler(image);
    }
}

@end
