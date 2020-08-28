//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRGaiaGattCommand.h"

#define GAIA_GATT_COMMAND_ACK_MASK               0x8000
#define GAIA_GATT_COMMAND_MASK                   0x7FFF

@implementation CSRGaiaGattCommand

- (NSUInteger)length {
    return [self.command length];
}

- (NSData *)getPacket {
    return self.command;
}

- (NSInteger)getPayloadLength {
    return [self.command length] - GAIA_GATT_HEADER_SIZE;
}

- (void)setCommandId:(GaiaCommandType)type {
    if (self.command) {
        unsigned char *header = (unsigned char *)[self.command bytes];
        
        header[GAIA_GATT_HEADER_OFFSET_COMMAND_ID] = (type >> 8) & 0xFF;
        header[GAIA_GATT_HEADER_OFFSET_COMMAND_ID + 1] = type & 0xFF;
        self.command_id = type;
    }
}

- (GaiaCommandType)getCommandId {
    // take off potential ACK bit (0x8000)
    return self.command_id & GAIA_GATT_COMMAND_MASK;
}

- (void)setVendorId:(uint16_t)vendor {
    if (self.command) {
        unsigned char *header = (unsigned char *)[self.command bytes];
        
        header[GAIA_GATT_HEADER_OFFSET_VENDOR_ID] = (vendor >> 8) & 0xFF;
        header[GAIA_GATT_HEADER_OFFSET_VENDOR_ID + 1] = vendor & 0xFF;
        self.vendor_id = vendor;
    }
}

- (uint16_t)getVendorId {
    return self.vendor_id;
}

- (void)addPayload:(NSData *)payload {
    [self.command appendData:payload];
}

- (NSData *)getPayload {
    NSInteger payload_length = [self getPayloadLength];
    
    if (!payload_length) {
        return nil;
    }
    
    NSRange payload_range = {GAIA_GATT_HEADER_OFFSET_PAYLOAD, payload_length};
    
    return [self.command subdataWithRange:payload_range];
}

- (BOOL)isAcknowledgement {
    return (self.command_id & GAIA_GATT_COMMAND_ACK_MASK) != 0;
}

- (BOOL)isControl {
    GaiaCommandType cmd = [self getCommandId];

    if (cmd >= GaiaCommand_Volume && cmd < GaiaCommand_GetAPIVersion) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isConfiguration {
    GaiaCommandType cmd = [self getCommandId];
    
    if (cmd >= GaiaCommand_SetLEDConfiguration && cmd < GaiaCommand_Volume) {
        return YES;
    }
    
    return NO;
}

- (GaiaCommandStatus)status {
    if (self.command && ([self getPayloadLength] >= 1)) {
        unsigned char *header = (unsigned char *)[self.command bytes];
        
        return (GaiaCommandStatus)header[GAIA_GATT_HEADER_OFFSET_PAYLOAD];
    }
    
    return GaiaStatus_NoStatusAvailable;
}

- (GaiaCommandUpdate)updateStatus {
    if (self.command && ([self getPayloadLength] >= 1)) {
        unsigned char *header = (unsigned char *)[self.command bytes];
        
        return (GaiaCommandUpdate)header[GAIA_GATT_HEADER_OFFSET_PAYLOAD + 1];
    }
    
    return GaiaUpdate_Unknown;
}

- (GaiaCommandUpdateResponse)updateResponse {
    if (self.command && ([self getPayloadLength] >= 1)) {
        unsigned char *header = (unsigned char *)[self.command bytes];
        
        return (GaiaCommandUpdateResponse)header[GAIA_GATT_HEADER_OFFSET_PAYLOAD];
    }
    
    return GaiaUpdateResponse_Success;
}

// get event type from notification
- (GaiaEvent)event {
    // if we have a command, it is an event notification and there is a payload
    // to look at
    if (   self.command
        && ([self getCommandId] == GaiaCommand_EventNotification)
        && ([self getPayloadLength] >= 1)) {
        unsigned char *header = (unsigned char *)[self.command bytes];
        
        return (GaiaEvent)header[GAIA_GATT_HEADER_OFFSET_PAYLOAD];
    }
    
    return GaiaEvent_UnknownEvent;
}

- (id)init {
    return [self initWithNSData:nil];
}

- (id)initWithNSData:(NSData *)data {
    if ([data length] < GAIA_GATT_HEADER_SIZE)
        return nil;
    
    if (self = [super init]) {
        // copy the data into this object instance
        self.command = [data copy];
        
        unsigned char *header = (unsigned char *)[self.command bytes];
        
        self.command_id |= (header[GAIA_GATT_HEADER_OFFSET_COMMAND_ID] << 8);
        self.command_id |= header[GAIA_GATT_HEADER_OFFSET_COMMAND_ID + 1];
        self.vendor_id |= (header[GAIA_GATT_HEADER_OFFSET_VENDOR_ID] << 8);
        self.vendor_id |= header[GAIA_GATT_HEADER_OFFSET_VENDOR_ID + 1];
    }
    
    return self;
}

- (id)initWithLength:(NSInteger)length {
    if (length < GAIA_GATT_HEADER_SIZE)
        return nil;
    
    if (self = [super init]) {
        self.command = [[NSMutableData alloc] initWithLength:length];
        
        if (!self.command) {
            return nil;
        }
    }
    
    return self;
}

@end
