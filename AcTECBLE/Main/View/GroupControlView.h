//
//  GroupControlView.h
//  AcTECBLE
//
//  Created by AcTEC on 2019/3/2.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ColorSlider.h"
#import "ColorSquare.h"
#import <AVFoundation/AVFoundation.h>
#import "SoundListenTool.h"


@interface GroupControlView : UIView <ColorSliderDelegate,ColorSquareDelegate,SoundListenToolDelegate>
{
    BOOL musicBehavior;
}
@property (nonatomic, strong) UILabel *threeColorTempTitleLabel, *colorTempTitleLabel, *colorTempLabel, *rgbTitleLabel, *colorLabel, *colorSatTitleLabel, *colorSatLabel, *musicTitleLabel;
@property (nonatomic, strong) UIButton *threeColorTempChangeBtn, *threeColorTempResetBtn, *musicBtn;
@property (nonatomic, strong) UIImageView *colorTempIconImageView, *rgbIconImageView, *colorSatIconImageView, *musicImageView;
@property (nonatomic, strong) UISlider *colorTempSlider, *colorSatSlider;
@property (nonatomic, strong) ColorSlider *colorSlider;
@property (nonatomic, strong) ColorSquare *colorSquare;
@property (nonatomic, strong) NSNumber *groupID;

- (id)initWithFrame:(CGRect)frame threeColorTemperature:(BOOL)threeColorTemp colorTemperature:(BOOL)colorTemp RGB:(BOOL)rgb;

@end

