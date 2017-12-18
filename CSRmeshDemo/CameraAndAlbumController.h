//
//  CameraAndAlbumController.h
//  BluetoothTest
//
//  Created by hua on 6/14/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CameraAndAlbumCompletionHandler)(UIImage *fetchImage);

@protocol CameraAndAlbumControllerDelegate <NSObject>
@optional
- (void)cameraAndAlbumControllerDidPickImage:(UIImage*)image;
@end

@interface CameraAndAlbumController : UICollectionViewController
@property (nonatomic,weak) id<CameraAndAlbumControllerDelegate> delegate;

- (void)setCompletionHandler:(CameraAndAlbumCompletionHandler)handler;
@end
