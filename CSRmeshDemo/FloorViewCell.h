//
//  FloorViewCell.h
//  BluetoothTest
//
//  Created by hua on 9/2/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceModel.h"

@protocol FloorViewCellDelegate <NSObject>
@optional
- (void)floorViewCellDidClickOnLight:(NSNumber *)deviceId;
- (void)floorViewCellSendBrightnessControlTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin toLight:(NSNumber *)deviceId controlState:(UIGestureRecognizerState)state;
- (void)floorViewCellSendDeleteActionFromIndexPath:(NSIndexPath*)indexPath;
- (void)floorViewCellRecognizerDidTranslationInLocation:(CGPoint)touchAt recognizerState:(UIGestureRecognizerState)state;
- (void)floorViewCellDidClickOnNoneLightRectWithIndexPath:(NSIndexPath*)indexPath;
@end

@interface FloorViewCell : UICollectionViewCell
@property (nonatomic,weak) id<FloorViewCellDelegate> delegate;
@property (nonatomic,strong) NSIndexPath *myIndexPath;
@property (nonatomic,copy) NSString *floorIndex;

- (void)addVisualControlPanel:(UIView*)panel withFixBounds:(CGRect)bounds;
- (void)showDeleteButton:(BOOL)show;
- (void)updateLightPresentationWithMeshStatus:(DeviceModel *)deviceModel;
- (UIView*)visualContentView;
@end
