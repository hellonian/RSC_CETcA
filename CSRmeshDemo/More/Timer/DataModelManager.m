//
//  DataModelManager.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/6.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "DataModelManager.h"
#import <CSRmesh/DataModelApi.h>
#import "TimeSchedule.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"

@interface DataModelManager ()<DataModelApiDelegate>
{
    TimeSchedule *_schedule;
    NSInteger primordial;
}

@property (nonatomic,strong) DataModelApi *manager;
@property (nonatomic,strong) NSMutableDictionary *deviceKeyDic;


@end

@implementation DataModelManager

NSString * const kTimerProfile = @"com.actec.bluetooth.timerProfile";

static DataModelManager *manager = nil;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DataModelManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _manager = [DataModelApi sharedInstance];
        [_manager addDelegate:self];
    }
    return self;
}

- (void)sendCmdData:(NSString *)hexStrCmd  toDeviceId:(NSNumber *)deviceId {
    
    [_manager sendData:deviceId data:[self dataForHexString:hexStrCmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

//添加闹钟
- (void)addAlarmForDevice:(NSNumber *)deviceId alarmIndex:(NSInteger)index fireDate:(NSDate *)fireDate fireTime:(NSDate *)fireTime repeat:(NSString *)repeat eveType:(NSString *)alarnActionType level:(NSInteger)level {
    
    NSString *indexStr = [self stringWithHexNumber:index];
    
    NSString *YMdString = [self YMdStringForDate:fireDate];
    NSString *hmsString = [self hmsStringForDate:fireTime];
    
    NSString *levelString = [self stringWithHexNumber:level];
    
    NSString *repeatNumberStr = [self toDecimalSystemWithBinarySystem:repeat];
    
    NSString *repeatString = [self stringWithHexNumber:[repeatNumberStr integerValue]];
    
    NSString *cmd = [NSString stringWithFormat:@"8310%@01%@%@%@%@%@0000000000",indexStr,YMdString,hmsString,repeatString,alarnActionType,levelString];
    
    _schedule = [self analyzeTimeScheduleData:[NSString stringWithFormat:@"%@01%@%@%@%@%@0000000000",indexStr,YMdString,hmsString,repeatString,alarnActionType,levelString] forLight:deviceId];
    
    [self sendCmdData:cmd toDeviceId:deviceId];
}

//读取单灯闹钟列表
- (void)ReadAlarmMessageByDeviceId:(NSNumber *)deviceId {
    [self sendCmdData:@"820100" toDeviceId:deviceId];
}

//同步设备时间
- (void)setDeviceTime:(NSNumber *)deviceId {
    NSDate *current = [NSDate date];
    NSString *dateString = [self hexStringForDate:current];
    
    NSString *cmd = [NSString stringWithFormat:@"8006%@",dateString];

    [self sendCmdData:cmd toDeviceId:deviceId];
}

//读取设备时间
- (void)readDeviceTime:(NSNumber *)deviceId {
    [self sendCmdData:@"810100" toDeviceId:deviceId];
}

//关闭和开启闹钟
- (void)enAlarmForDevice:(NSNumber *)deviceId stata:(BOOL)state index:(NSInteger)index {
    NSString *stataString = [NSString stringWithFormat:@"0%d",state];
    NSString *indexString = [self stringWithHexNumber:index];
    NSString *cmd = [NSString stringWithFormat:@"8402%@%@",indexString,stataString];
    [self sendCmdData:cmd toDeviceId:deviceId];
}

//删除设备闹钟
- (void)deleteAlarmForDevice:(NSNumber *)deviceId index:(NSInteger)index {
    NSString *indexString = [self stringWithHexNumber:index];
    NSString *cmd = [NSString stringWithFormat:@"8501%@",indexString];
    [self sendCmdData:cmd toDeviceId:deviceId];
}


#pragma mark - DataModelApiDelegate

- (void)didSendData:(NSNumber *)deviceId data:(NSData *)data meshRequestId:(NSNumber *)meshRequestId {
    NSLog(@"didSendData : %@",data);
}

- (void)didReceiveBlockData:(NSNumber *)destinationDeviceId sourceDeviceId:(NSNumber *)sourceDeviceId data:(NSData *)data {
    NSLog(@"didReceiveBlockData: %@ ----- %@ +++++ %@",data,destinationDeviceId,sourceDeviceId);
    
    NSString *dataStr = [self hexStringForData:data];
    
    //获取到设备时间
    if ([dataStr hasPrefix:@"a1"]) {
        
//        NSString *dateStrInData = [dataStr substringWithRange:NSMakeRange(4, 12)];
//
//        NSDate *deviceTime = [self dateForString:dateStrInData];///////////
    }
    
    //添加闹钟回调
    if ([dataStr hasPrefix:@"a3"]) {
        NSString *suffixStr = [dataStr substringWithRange:NSMakeRange(6, 2)];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addAlarmCall" object:nil userInfo:@{@"addAlarmCall":suffixStr}];
        if ([suffixStr boolValue]&&self.delegate&&[self.delegate respondsToSelector:@selector(addAlarmSuccessCall:)]) {
            [self.delegate addAlarmSuccessCall:_schedule];
        }
    }
    
    //删除闹钟回调
    if ([dataStr hasPrefix:@"a5"]) {
        NSString *suffixStr = [dataStr substringWithRange:NSMakeRange(6, 2)];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteAlarmCall" object:nil userInfo:@{@"deleteAlarmCall":suffixStr}];
    }
    
    //关闭或开启闹钟回调
    if ([dataStr hasPrefix:@"a4"]) {
        
    }
    
    //实物按钮动作反馈
    if ([dataStr hasPrefix:@"87"]) {
        NSInteger seq = [[dataStr substringWithRange:NSMakeRange(4, 2)] integerValue];
        if (seq && seq < primordial) {
            return;
        }
        primordial = seq;
        NSString *state = [dataStr substringWithRange:NSMakeRange(6, 2)];
        NSInteger level = [self numberWithHexString:[dataStr substringWithRange:NSMakeRange(8, 2)]];
        NSNumber *levelNum = [NSNumber numberWithInteger:level];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"physicalButtonActionCall" object:self userInfo:@{@"powerState":state,@"level":levelNum,@"deviceId":sourceDeviceId}];
    }
    
    //遥控器设置反馈
    if ([dataStr hasPrefix:@"b0"]) {
        NSString *suffixStr = [dataStr substringWithRange:NSMakeRange(6, 2)];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"settingRemoteCall" object:nil userInfo:@{@"settingRemoteCall":suffixStr}];
    }
    
    //获取固件版本
    if ([dataStr hasPrefix:@"a8"]) {
        NSString *firmwareVersion = [dataStr substringWithRange:NSMakeRange(16, 2)];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"getFirmwareVersion" object:nil userInfo:@{@"getFirmwareVersion":@([self numberWithHexString:firmwareVersion]),@"deviceId":sourceDeviceId}];
    }
    
}

- (void)didReceiveStreamData:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber data:(NSData *)data {
    NSLog(@"didReceiveStreamData: %@ +++++ %@ ----- %@",data,deviceId,streamNumber);
    
    NSMutableDictionary *deviceDic;
    if ([self.deviceKeyDic objectForKey:deviceId]) {
        deviceDic = [self.deviceKeyDic objectForKey:deviceId];
        if (![deviceDic objectForKey:streamNumber]) {
            [deviceDic setObject:data forKey:streamNumber];
        }
    }else{
        deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:data forKey:streamNumber];
    }
    [self.deviceKeyDic setObject:deviceDic forKey:deviceId];
}

- (void)didReceiveStreamDataEnd:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber {
    NSLog(@"didReceiveStreamDataEnd: %@ ~~~~~ %@",deviceId,streamNumber);
    
    NSMutableDictionary *dic = [self.deviceKeyDic objectForKey:deviceId];
    NSArray *ary = [dic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSData *data = [dic objectForKey:ary[0]];
    NSString *firstStr = [self hexStringForData:data];
    
    if ([firstStr hasPrefix:@"a2"]) {
        NSString *string = @"actec";
        for (NSNumber *key in ary) {
            NSData *preData = [dic objectForKey:key];
            string = [NSString stringWithFormat:@"%@%@",string,[self hexStringForData:preData]];
        }
        NSInteger num = [self numberWithHexString:[firstStr substringWithRange:NSMakeRange(4, 2)]];
        NSMutableArray *timersArray = [[NSMutableArray alloc] init];
        for (NSInteger i=0; i<num; i++) {
            NSString *perStr = [string substringWithRange:NSMakeRange(i*32+11, 32)];////
            TimeSchedule *schedule = [self analyzeTimeScheduleData:perStr forLight:deviceId];
            [timersArray addObject:schedule];
        }
        if ([timersArray count] > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kTimerProfile object:nil userInfo:@{kTimerProfile:timersArray,@"deviceId":deviceId}];
        }
    }
    
    [self.deviceKeyDic removeObjectForKey:deviceId];
}

- (TimeSchedule *)analyzeTimeScheduleData:(NSString *)dataString forLight:(NSNumber *)deviceId {
    
    NSInteger index = [self numberWithHexString:[dataString substringWithRange:NSMakeRange(0, 2)]];
    BOOL state = [[dataString substringWithRange:NSMakeRange(2, 2)] boolValue];
    NSString *repeat = [self getBinaryByhex:[dataString substringWithRange:NSMakeRange(16, 2)]];
    NSString *eveType = [dataString substringWithRange:NSMakeRange(18, 2)];
    NSInteger level = [self numberWithHexString:[dataString substringWithRange:NSMakeRange(20, 2)]];
    
    NSString *dateStrInData = [dataString substringWithRange:NSMakeRange(4, 12)];
    NSDate *fireDate = [self dateForString:dateStrInData];
    
    CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceId];
    
    TimeSchedule *profile = [[TimeSchedule alloc]init];
    profile.deviceId = deviceId;
    profile.timerIndex = index;
    profile.level = level;
    profile.state = state;
    profile.eveType = eveType;
    profile.repeat = repeat;
    profile.fireDate = fireDate;
    profile.lightNickname = device.name;
    
    return profile;
}

- (NSDate *)dateForString:(NSString *)dateStrInData {
    NSInteger year = [self numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(0, 2)]] + 2000;
    NSInteger month = [self numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(2, 2)]];
    NSInteger day = [self numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(4, 2)]];
    NSInteger hour = [self numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(6, 2)]];
    NSInteger minute = [self numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(8, 2)]];
    NSInteger second = [self numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(10, 2)]];
    NSString *dateStr = [NSString stringWithFormat:@"%ld-%ld-%ld %ld:%ld:%ld",year,month,day,hour,minute,second];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [format dateFromString:dateStr];
    return date;
}

- (NSString *)YMdStringForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"YYYY:MM:dd";
    NSString *dateStr = [formatter stringFromDate:date];
    NSArray *YMdAry = [dateStr componentsSeparatedByString:@":"];
    
    NSString *year = [self stringWithHexNumber:[[YMdAry[0] substringWithRange:NSMakeRange(2, 2)] integerValue]];
    NSString *month = [self stringWithHexNumber:[YMdAry[1] integerValue]];
    NSString *day = [self stringWithHexNumber:[YMdAry[2] integerValue]];
    NSString *YMdString = [NSString stringWithFormat:@"%@%@%@",year,month,day];
    return YMdString;
}

- (NSString *)hmsStringForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"hh:mm:ss";
    NSString *dateStr = [formatter stringFromDate:date];
    NSArray *hmsAry = [dateStr componentsSeparatedByString:@":"];
    
    NSString *hour = [self stringWithHexNumber:[hmsAry[0] integerValue]];
    NSString *minute = [self stringWithHexNumber:[hmsAry[1] integerValue]];
    NSString *second = [self stringWithHexNumber:[hmsAry[2] integerValue]];
    NSString *hmsString = [NSString stringWithFormat:@"%@%@%@",hour,minute,second];
    return hmsString;
}

- (NSString *)hexStringForDate:(NSDate *)date {
    NSString *YMdString = [self YMdStringForDate:date];
    
    NSString *hmsString = [self hmsStringForDate:date];
    
    NSString *string = [NSString stringWithFormat:@"%@%@",YMdString,hmsString];
    return string;
}

#pragma mark - 数据类型转化

//十六进制字符串转二进制数据
- (NSData*)dataForHexString:(NSString*)hexString
{
    if (hexString == nil) {
        return nil;
    }
    const char* ch = [[hexString lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* data = [NSMutableData data];
    while (*ch) {
        if (*ch == ' ') {
            continue;
        }
        char byte = 0;
        if ('0' <= *ch && *ch <= '9') {
            byte = *ch - '0';
        }
        else if ('a' <= *ch && *ch <= 'f') {
            byte = *ch - 'a' + 10;
        }
        else if ('A' <= *ch && *ch <= 'F') {
            byte = *ch - 'A' + 10;
        }
        ch++;
        byte = byte << 4;
        if (*ch) {
            if ('0' <= *ch && *ch <= '9') {
                byte += *ch - '0';
            } else if ('a' <= *ch && *ch <= 'f') {
                byte += *ch - 'a' + 10;
            }
            else if('A' <= *ch && *ch <= 'F')
            {
                byte += *ch - 'A' + 10;
            }
            ch++;
        }
        [data appendBytes:&byte length:1];
    }
    return data;
}

//二进制数据转十六进制字符串
- (NSString *)hexStringForData: (NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

//十六进制字符串转十进制数据
- (NSInteger)numberWithHexString:(NSString *)hexString{
    
    const char *hexChar = [hexString cStringUsingEncoding:NSUTF8StringEncoding];
    
    int hexNumber;
    
    sscanf(hexChar, "%x", &hexNumber);
    
    return (NSInteger)hexNumber;
}

//十六进制字符串转二进制字符串
-(NSString *)getBinaryByhex:(NSString *)hex
{
    NSMutableDictionary  *hexDic = [[NSMutableDictionary alloc] init];
    
    hexDic = [[NSMutableDictionary alloc] initWithCapacity:16];
    
    [hexDic setObject:@"0000" forKey:@"0"];
    
    [hexDic setObject:@"0001" forKey:@"1"];
    
    [hexDic setObject:@"0010" forKey:@"2"];
    
    [hexDic setObject:@"0011" forKey:@"3"];
    
    [hexDic setObject:@"0100" forKey:@"4"];
    
    [hexDic setObject:@"0101" forKey:@"5"];
    
    [hexDic setObject:@"0110" forKey:@"6"];
    
    [hexDic setObject:@"0111" forKey:@"7"];
    
    [hexDic setObject:@"1000" forKey:@"8"];
    
    [hexDic setObject:@"1001" forKey:@"9"];
    
    [hexDic setObject:@"1010" forKey:@"a"];
    
    [hexDic setObject:@"1011" forKey:@"b"];
    
    [hexDic setObject:@"1100" forKey:@"c"];
    
    [hexDic setObject:@"1101" forKey:@"d"];
    
    [hexDic setObject:@"1110" forKey:@"e"];
    
    [hexDic setObject:@"1111" forKey:@"f"];
    
    NSString *binaryString=[[NSString alloc] init];
    
    for (int i=0; i<[hex length]; i++) {
        
        NSRange rage;
        
        rage.length = 1;
        
        rage.location = i;
        
        NSString *key = [hex substringWithRange:rage];
        
        binaryString = [NSString stringWithFormat:@"%@%@",binaryString,[NSString stringWithFormat:@"%@",[hexDic objectForKey:key]]];
        
    }
    
    return binaryString;
    
}

//十进制数转十六进制字符串
- (NSString *)stringWithHexNumber:(NSUInteger)hexNumber{
    
    char hexChar[6];
    sprintf(hexChar, "%x", (int)hexNumber);
    
    NSString *hexString = [NSString stringWithCString:hexChar encoding:NSUTF8StringEncoding];
    if (hexString.length == 1) {
        hexString = [NSString stringWithFormat:@"0%@",hexString];
    }
    return hexString;
}

//二进制字符串 转 十进制字符串
- (NSString *)toDecimalSystemWithBinarySystem:(NSString *)binary
{
    int ll = 0 ;
    int  temp = 0 ;
    for (int i = 0; i < binary.length; i ++)
    {
        temp = [[binary substringWithRange:NSMakeRange(i, 1)] intValue];
        temp = temp * powf(2, binary.length - i - 1);
        ll += temp;
    }
    
    NSString * result = [NSString stringWithFormat:@"%d",ll];
    
    return result;
}

- (NSMutableDictionary *)deviceKeyDic {
    if (!_deviceKeyDic) {
        _deviceKeyDic = [[NSMutableDictionary alloc] init];
    }
    return _deviceKeyDic;
}



@end