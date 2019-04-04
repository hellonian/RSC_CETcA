//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CBPeripheral+Info.h"
#import <objc/runtime.h>
#import "NSMutableArray+Queue.h"

static void * queuePropertyKey;

NSString const *localNamePropertyKey = @"localNamePropertyKey";
NSString const *uuidStringPropertyKey = @"uuidStringPropertyKey";
NSString const *rssiPropertyKey = @"rssiPropertyKey";
NSString const *startOfDiscoveryPropertyKey = @"startOfDiscovery";
NSString const *isBridgeServicePropertyKey = @"isBridgeService";


@implementation CBPeripheral (Info)

@dynamic localName, uuidString, rssi, startOfDiscovery, discoveryState, isBridgeService, queue;

    //=========================================================================
    // Getter and Setter for localName
-(NSString *) localName {
    return objc_getAssociatedObject(self, &localNamePropertyKey);
}

-(void) setLocalName:(NSString *)localName {
    objc_setAssociatedObject(self, &localNamePropertyKey, localName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString *) uuidString {
    return objc_getAssociatedObject(self, &uuidStringPropertyKey);
}

-(void) setUuidString:(NSString *)uuidString {
    objc_setAssociatedObject(self, &uuidStringPropertyKey, uuidString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

    //=========================================================================
    // Getter and Setter for RSSI
-(NSNumber *) rssi {
    return objc_getAssociatedObject(self, &rssiPropertyKey);
}

-(void) setRssi:(NSNumber *)rssi {
    
    objc_setAssociatedObject(self, &rssiPropertyKey, rssi, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

    //=========================================================================
    // Getter and Setter for start of discovery
-(NSDate *) startOfDiscovery {
    return objc_getAssociatedObject(self, &startOfDiscoveryPropertyKey);
}

-(void) setStartOfDiscovery:(NSDate *)startOfDiscovery {
    objc_setAssociatedObject(self, &startOfDiscoveryPropertyKey, startOfDiscovery, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


    //=========================================================================
    // Getter and Setter for start of discovery
-(NSNumber *) isBridgeService {
    return objc_getAssociatedObject(self, &isBridgeServicePropertyKey);
}

-(void) setIsBridgeService:(NSNumber *) isBridgeService {
    objc_setAssociatedObject(self, &isBridgeServicePropertyKey, isBridgeService, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


//=========================================================================
// Getter and Setter for queue property
- (NSMutableArray *)queue {
    return objc_getAssociatedObject(self, queuePropertyKey);
}

- (void)setQueue:(NSMutableArray *)queue {
    objc_setAssociatedObject(self, queuePropertyKey, queue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



//=========================================================================
// Save the callback object, PCM, in the Queue for this peripheral
-(void) saveCallBack :(id) pcm {
    @synchronized(self) {
        if (self.queue==nil) {
            self.queue = [[NSMutableArray alloc]init];
        }
        
        [self.queue enqueue:pcm];
    }
}

-(id) getCallBack {
    @synchronized(self) {
        id pcm = [self.queue dequeue];
        return (pcm);
    }
}


-(void) deleteQueue {
    @synchronized(self) {
        self.queue = nil;
    }
}



@end
