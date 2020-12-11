//
//  SonosSelectModel.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/11/2.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SelectModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SonosSelectModel : SelectModel

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger songNumber;
@property (nonatomic, assign) BOOL play;
@property (nonatomic, assign) NSInteger cycle;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) NSInteger voice;
@property (nonatomic, assign) BOOL channelState;
@property (nonatomic, assign) NSInteger source;
@property (nonatomic, assign) NSInteger dataValid;
@property (nonatomic, assign) BOOL selected;

@end

NS_ASSUME_NONNULL_END
