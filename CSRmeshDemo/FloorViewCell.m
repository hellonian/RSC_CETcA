//
//  FloorViewCell.m
//  BluetoothTest
//
//  Created by hua on 9/2/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "FloorViewCell.h"
#import "VisualControlContentView.h"
#import "PureLayout.h"

@interface FloorViewCell ()<VisualControlContentViewDelegate>
@property (nonatomic,strong) VisualControlContentView *gallery;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *anchorView;
@end

@implementation FloorViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.deleteButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.deleteButton];
    [self.deleteButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:0.16];
    [self.deleteButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.anchorView];
    [self.deleteButton autoAlignAxis:ALAxisVertical toSameAxisOfView:self.anchorView];
}

- (void)addVisualControlPanel:(UIView *)panel withFixBounds:(CGRect)bounds {
    if ([panel isKindOfClass:[VisualControlContentView class]]) {
        VisualControlContentView *control = (VisualControlContentView*)panel;
        self.floorIndex = control.visualControlIndex;
        
        _gallery = [control copy];
        _gallery.bounds = bounds;
        _gallery.delegate = self;
        [_gallery disableEdit];
        
        [self.contentView addSubview:_gallery];
        [self updateConstraints];
    }
}

- (UIView*)visualContentView {
    return self.gallery;
}

- (void)showDeleteButton:(BOOL)show {
    self.deleteButton.hidden = !show;
    [self.contentView bringSubviewToFront:self.deleteButton];
}

- (void)updateLightPresentationWithMeshStatus:(DeviceModel *)deviceModel {
    [self.gallery updateLightPresentationWithMeshStatus:deviceModel];
}

- (IBAction)onDeleteButtonClick:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(floorViewCellSendDeleteActionFromIndexPath:)]) {
        [self.delegate floorViewCellSendDeleteActionFromIndexPath:self.myIndexPath];
    }
}

#pragma mark - VisualControlContentView Delegate

- (void)visualControlContentViewDidClickOnLight:(NSNumber *)deviceId {
    if (self.delegate && [self.delegate respondsToSelector:@selector(floorViewCellDidClickOnLight:)]) {
        [self.delegate floorViewCellDidClickOnLight:deviceId];
    }
}

- (void)visualControlContentViewSendBrightnessControlTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin toLight:(NSNumber *)deviceId controlState:(UIGestureRecognizerState)state {
    if (self.delegate && [self.delegate respondsToSelector:@selector(floorViewCellSendBrightnessControlTouching:referencePoint:toLight:controlState:)]) {
        [self.delegate floorViewCellSendBrightnessControlTouching:touchAt referencePoint:origin toLight:deviceId controlState:state];
    }
}

- (void)visualControlContentViewRecognizerDidTranslationInLocation:(CGPoint)touchAt recognizerState:(UIGestureRecognizerState)state {
    if (self.delegate && [self.delegate respondsToSelector:@selector(floorViewCellRecognizerDidTranslationInLocation:recognizerState:)]) {
        [self.delegate floorViewCellRecognizerDidTranslationInLocation:touchAt recognizerState:state];
    }
}

- (void)visualControlContentViewDidClickOnNoneLightRect {
    if (self.delegate && [self.delegate respondsToSelector:@selector(floorViewCellDidClickOnNoneLightRectWithIndexPath:)]) {
        [self.delegate floorViewCellDidClickOnNoneLightRectWithIndexPath:self.myIndexPath];
    }
}

#pragma mark - AutoLayout

- (void)updateConstraints {
    [super updateConstraints];
    [self.gallery autoPinEdgesToSuperviewEdges];
    [self.gallery adjustLightRepresentationPosition];
}

@end
