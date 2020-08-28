//
//  DynamicIconView.h
//  BluetoothAcTEC
//
//  Created by hua on 10/13/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DynamicIconView : UICollectionView
@property (nonatomic,strong) NSMutableArray *itemCluster;
- (void)configureWithItemPerSection:(NSInteger)count cellIdentifier:(NSString*)identifier;
- (void)addLightWithAddress:(NSArray*)list;
@end
