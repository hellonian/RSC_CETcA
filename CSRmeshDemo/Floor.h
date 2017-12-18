//
//  Floor.h
//  BluetoothAcTEC
//
//  Created by hua on 10/19/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Floor : NSObject <NSCoding>
@property (nonatomic,strong) UIImage *floorImage;
@property (nonatomic,strong) NSMutableArray *light;
@property (nonatomic,assign) CGSize layoutSize;
@property (nonatomic,copy) NSString *floorIndex;

-(NSData *)archive;
+(Floor *)unArchiveData:(NSData *)data;

@end
