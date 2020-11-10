//
//  SelectionListModel.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/11/3.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SelectionListModel : NSObject

@property (nonatomic, assign)NSInteger value;
@property (nonatomic, strong)NSString *name;
@property (nonatomic, assign)BOOL selected;

@end

NS_ASSUME_NONNULL_END
