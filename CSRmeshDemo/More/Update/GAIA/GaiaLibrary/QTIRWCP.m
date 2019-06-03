//
// Copyright 2017 Qualcomm Technologies International, Ltd.
//

#import "QTIRWCP.h"
#import "QTIRWCPSegment.h"
#import "CSRBluetoothLE.h"
#import "CSRGaia.h"

#define GATT_MTU						(20)

// Timeout periods
#define RWCP_SYN_TIMEOUT_MS				(500)
#define RWCP_RST_TIMEOUT_MS				(500)
#define RWCP_DATA_TIMEOUT_MS_NORMAL		(100)
#define RWCP_DATA_TIMEOUT_MS_MAX		(500)

// RWCP protocol definitions
#define RWCP_MAX_SEQUENCE				(63)
#define RWCP_SEQUENCE_SPACE_SIZE		(RWCP_MAX_SEQUENCE + 1)
#define RWCP_HEADER_SIZE				(1)
#define RWCP_DATA_PAYLOAD_LEN			(GATT_MTU - RWCP_HEADER_SIZE)
#define RWCP_HEADER_MASK_SEQ_NUMBER		(0x3F)
#define RWCP_HEADER_MASK_OPCODE			(0xC0)
#define RWCP_HEADER_OPCODE_DATA			(0 << 6)
#define RWCP_HEADER_OPCODE_DATA_ACK		(0 << 6)
#define RWCP_HEADER_OPCODE_SYN			(1 << 6)
#define RWCP_HEADER_OPCODE_SYN_ACK		(1 << 6)
#define RWCP_HEADER_OPCODE_RST			(2 << 6)
#define RWCP_HEADER_OPCODE_RST_ACK		(2 << 6)
#define RWCP_HEADER_OPCODE_GAP			(3 << 6)
#define RWCP_CWIN_MAX					(15)			// Maximum size of congestion window. i.e. maximum number of outstanding segments
#define RWCP_CWIN_ADJUSTMENT_THRESHOLD	(32)			// The number of successful acknowledgements before congestion window expansion is considered.

@interface QTIRWCP () <CSRBluetoothLEDelegate>

@property (nonatomic) CBPeripheral *connectedPeripheral;
@property (nonatomic) CBService *service;
@property (nonatomic) CBCharacteristic *dataCharacteristic;
@property (nonatomic) NSData *fileData;
@property (nonatomic) NSMutableArray *recentSegments;
@property (nonatomic) NSMutableArray *bufferedData;

@property (nonatomic) QTIRWCPState state;
@property (nonatomic) uint8_t cwin;
@property (nonatomic) uint8_t credit;
@property (nonatomic) uint16_t data_timeout;
@property (nonatomic) uint16_t next_send_segment_position;
@property (nonatomic) uint16_t send_sequence;
@property (nonatomic) uint8_t good_ack_count;
@property (nonatomic) Boolean timeout_is_set;
@property (nonatomic) Boolean rwcp_failed;
@property (nonatomic) Boolean gap_backoff;

@property (nonatomic) Boolean lastSegmentSent;
@property (nonatomic) NSUInteger progress;

@end

@implementation QTIRWCP

+ (QTIRWCP *)sharedInstance {
    static dispatch_once_t pred;
    static QTIRWCP *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[QTIRWCP alloc] init];
    });
    
    return shared;
}

- (void)commonInit {
    _state = QTIRWCPState_Listen;
    _send_sequence = 1;
    _timeout_is_set = false;
    _rwcp_failed = false;
    // Clear buffer
    _recentSegments = [NSMutableArray array];
    _dataBuffer = [NSMutableArray array];
    _next_send_segment_position = 0;
    _lastSegmentSent = false;
    _lastByteSent = false;
    _progress = 0;
}

- (void)connectPeripheral:(CBPeripheral *)peripheral
       dataCharacteristic:(CBCharacteristic *)characteristic {
    self.connectedPeripheral = peripheral;
    
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];

    self.dataCharacteristic = characteristic;
    
    if (self.dataCharacteristic) {
        [[CSRBluetoothLE sharedInstance]
         listenFor:UUID_GAIA_SERVICE
         characteristic:UUID_GAIA_DATA_ENDPOINT];
    }

    [self commonInit];
}

- (void)didDisconnectFromPeripheral:(CBPeripheral *)peripheral {
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
    self.connectedPeripheral = nil;
    self.service = nil;
    self.dataCharacteristic = nil;
    
    [self commonInit];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didMakeProgress:)]) {
        [self.delegate didMakeProgress:_progress];
        [self.delegate didUpdateStatus:@"Disconnected. Waiting for reconnection..."];
    }
}

- (void)setTimer:(NSTimeInterval)value {
    _timeout_is_set = true;
    [NSTimer scheduledTimerWithTimeInterval:value
                                     target:self
                                   selector:@selector(timeout)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)setPayload:(NSData *)data {
    if ([self sessionIdle]) [self startSession];
    
    uint8_t availableBuffers = [self rwcpAvailableBuffers];
    
    NSLog(@"New payload. Available buffers: %d", availableBuffers);
    
    if (availableBuffers) {
        QTIRWCPSegment *seg = [[QTIRWCPSegment alloc]
                               initWithLength:data.length
                               sequence:_send_sequence
                               data:data];
        
        NSLog(@"RWCP Data SEQ 0x%02X queued.", _send_sequence);
        
        [_recentSegments addObject:seg];
        _send_sequence = (_send_sequence + 1) % RWCP_SEQUENCE_SPACE_SIZE;
        
        if (   _state == QTIRWCPState_Established
            && _credit
            && [self rwcpUnsentSegments]) {
            [self setTimer:_data_timeout];
            [self sendRWCPData:false];
        }
    }
}

- (uint8_t)availablePayloadBuffer {
    return [self rwcpAvailableBuffers];
}

- (void)abort {
    _timeout_is_set = false;

    [self commonInit];
}

// -------------------------------------------------------------------------------------------------
- (void)chracteristicChanged:(CBCharacteristic *)characteristic {
    if ([characteristic isEqual:self.dataCharacteristic]) {
        NSLog(@"Incoming data: %@", characteristic.value);
        [self processIncomingResponse:characteristic.value];
        
        while ([self rwcpAvailableBuffers] && _dataBuffer.count > 0) {
            NSLog(@"Backfilling...");
            NSData * data = [_dataBuffer firstObject];

            [_recentSegments addObject:[[QTIRWCPSegment alloc]
                                        initWithLength:data.length
                                        sequence:_send_sequence
                                        data:data]];
            
            [_dataBuffer removeObjectAtIndex:0];
            
            if (_lastByteSent && _dataBuffer.count == 0) {
                _lastSegmentSent = true;
            }
            
            NSLog(@"RWCP Data SEQ 0x%02X queued.", _send_sequence);
            
            _send_sequence = (_send_sequence + 1) % RWCP_SEQUENCE_SPACE_SIZE;
            
            if (   _state == QTIRWCPState_Established
                && _credit
                && [self rwcpUnsentSegments]) {
                [self setTimer:_data_timeout];
                [self sendRWCPData:false];
            }
        }
    }
}

- (void)send:(NSData *)data {
    NSLog(@"Outgoing packet: %@", data);
    [self.connectedPeripheral
     writeValue:data
     forCharacteristic:self.dataCharacteristic
     type:CBCharacteristicWriteWithoutResponse];
}

- (NSString *)getRWCPFlagString:(uint8_t)header {
    switch (header & RWCP_HEADER_MASK_OPCODE) {
        case RWCP_HEADER_OPCODE_DATA_ACK:
            return @"DATA/ACK";
        case RWCP_HEADER_OPCODE_SYN_ACK:
            return @"SYN/SYN+ACK";
        case RWCP_HEADER_OPCODE_RST_ACK:
            return @"RES/RES+ACK";
        case RWCP_HEADER_OPCODE_GAP:
            return @"GAP";
        default:
            return nil;
    }
}

- (uint8_t)rwcpUnsentSegments {
    return (_recentSegments.count > _next_send_segment_position) ?
           (_recentSegments.count - _next_send_segment_position) : 0;
}

- (uint8_t)rwcpAvailableBuffers {
    return RWCP_CWIN_MAX - _recentSegments.count;
}

- (uint8_t)rwcpOutstandingSegments {
    return _recentSegments.count - [self rwcpUnsentSegments];
}

- (void)processIncomingResponse:(NSData *)data {
    uint8_t header = 0;
    uint8_t received_seq = 0;
    uint8_t opcode = 0;
    
    if (data.length == 0) return;
    
    [data getBytes:&header range:NSMakeRange(0, 1)];

    opcode = header & RWCP_HEADER_MASK_OPCODE;
    received_seq = header & RWCP_HEADER_MASK_SEQ_NUMBER;
    
    switch (_state) {
        case QTIRWCPState_Listen:
            NSLog(@"Received unexpected RWCP header 0x%02x(%@) in LISTEN state.", header, [self getRWCPFlagString:header]);
            break;
        case QTIRWCPState_SynSent: {
            switch (opcode) {
                case RWCP_HEADER_OPCODE_SYN_ACK: {
                    NSLog(@"Received RWCP SYN+ACK SEQ 0x%02x, RWCP establised.", header & RWCP_HEADER_MASK_SEQ_NUMBER);
                    
                    _timeout_is_set = false;
                    _state = QTIRWCPState_Established;
                    
                    if ([self rwcpUnsentSegments]) {
                        NSLog(@"Begin sending RWCP data.");
                        [self setTimer:_data_timeout];
                        [self sendRWCPData:false];
                    }
                    
                    [self.delegate didUpdateStatus:@""];
                    break;
                }
                case RWCP_HEADER_OPCODE_RST_ACK:
                    NSLog(@"Received RWCP RST+ACK SEQ 0x%02x in SYN_SENT state, ignoring.", header & RWCP_HEADER_MASK_SEQ_NUMBER);
                    break;
                default:
                    NSLog(@"Received unexpected RWCP header 0x%02x(%@) in SYN_SENT state. Upgrade failed.", header, [self getRWCPFlagString:header]);
                    [self terminateSession:true];
                    break;
            }
            break;
        }
        case QTIRWCPState_Established: {
            switch (opcode) {
                case RWCP_HEADER_OPCODE_DATA_ACK:
                    _timeout_is_set = false;
                    _data_timeout = RWCP_DATA_TIMEOUT_MS_NORMAL;
                    [self handleAck:received_seq];
                    break;
                case RWCP_HEADER_OPCODE_SYN_ACK:
                    NSLog(@"SYN+ACK (SEQ 0x%02X) received in Established state, re-sending first data packets", received_seq);
                    _next_send_segment_position = 0;
                    _cwin = RWCP_CWIN_MAX;
                    _credit = _cwin;
                    
                    [self setTimer:_data_timeout];
                    [self sendRWCPData:false];
                    break;
                case RWCP_HEADER_OPCODE_RST:
                    NSLog(@"RST (SEQ 0x%02X) received in Established state, State -> Listen. Upgrade failed", received_seq);
                    [self terminateSession:true];
                    break;
                case RWCP_HEADER_OPCODE_GAP:
                    _timeout_is_set = false;
                    _data_timeout = RWCP_DATA_TIMEOUT_MS_NORMAL;
                    
                    [self handleGap:received_seq];
                    break;
                default:
                    NSLog(@"Received unexpected RWCP header 0x%02X(%@) in ESTABLISHED state.", header, [self getRWCPFlagString:header]);
                    break;
            }
            break;
        }
        case QTIRWCPState_Closing: {
            NSLog(@"Received RWCP %@ SEQ 0x%02X.", [self getRWCPFlagString:header], header & RWCP_HEADER_MASK_SEQ_NUMBER);
            
            switch (opcode) {
                case RWCP_HEADER_OPCODE_DATA_ACK:
                    [self setTimer:_data_timeout];
                    break;
                case RWCP_HEADER_OPCODE_RST_ACK:
                    _timeout_is_set = false; // Ignore previous timers.
                    NSLog(@"RWCP State Closing -> Listen.");
                    [self terminateSession:false];
                    
                    if ([self rwcpUnsentSegments]) {
                        [self startSession];
                    }
                    break;
                default:
                    NSLog(@"Unrecognised RWCP header flags. Upgrade failed.");
                    [self terminateSession:true];
                    break;
            }
            break;
        }
        default:
            NSLog(@"Unknown RWCP state %ld", (long)_state);
            [self terminateSession:true];
            break;
    }
}

// -------------------------------------------------------------------------------------------------
- (void)startSession {
    _state = QTIRWCPState_SynSent;
    _timeout_is_set = true;
    _cwin = RWCP_CWIN_MAX;
    _credit = _cwin;
    _data_timeout = RWCP_DATA_TIMEOUT_MS_NORMAL;
    
    [self setTimer:_data_timeout];
    [self writePayload:0 flags:RWCP_HEADER_OPCODE_RST length:0 data:nil];
    [self writePayload:0 flags:RWCP_HEADER_OPCODE_SYN length:0 data:nil];
}

- (void)terminateSession:(Boolean)failed {
    _state = QTIRWCPState_Listen;
    _rwcp_failed = failed;
    
    if (failed) {
        _send_sequence = 1;
        [_recentSegments removeAllObjects];
        _next_send_segment_position = 0;
    }
}

- (Boolean)sessionIdle {
    return _state == QTIRWCPState_Listen;
}

- (void)sendRWCPData:(Boolean)resend {
    NSLog(@"GAIA RWCP Send Data");
    
    if (resend && [self rwcpOutstandingSegments]) {
        QTIRWCPSegment *seg = _recentSegments.firstObject;
        NSLog(@"Re-sending RWCP data SEQ 0x%02X.", seg.sequence);
        
        [self writePayload:seg.sequence
                     flags:RWCP_HEADER_OPCODE_DATA
                    length:seg.length
                      data:seg.data];
    }
    
    if ([self rwcpUnsentSegments]) {
        QTIRWCPSegment *seg = _recentSegments[_next_send_segment_position];

        if (_credit) _credit--;
        
        NSLog(@"Sending RWCP data SEQ 0x%02X Credit left: %d.", seg.sequence, _credit);
        
        _next_send_segment_position++;

        [self writePayload:seg.sequence
                     flags:RWCP_HEADER_OPCODE_DATA
                    length:seg.length
                      data:seg.data];
    } else {
        NSLog(@"No data in RWCP buffer.");
    }
}

- (void)advanceAckSeq:(uint8_t)ack_sequence {
    Boolean seq_valid = false;
    uint8_t seq_diff = 0;
    uint8_t outstandingSegments = [self rwcpOutstandingSegments];
    
    if (outstandingSegments) {
        uint8_t seg_len = 0;
        
        for (uint8_t i = 0; i < outstandingSegments && !seq_valid; i++) {
            QTIRWCPSegment *seg = _recentSegments[i];
            
            if (seg.sequence == ack_sequence) {
                seq_valid = true;
                seq_diff = i + 1;
                seg_len = seg.length;
            }
        }
        
        if (seq_valid) {
            _good_ack_count = _good_ack_count + seq_diff;
            [_recentSegments removeObjectsInRange:NSMakeRange(0, seq_diff)];
            _next_send_segment_position -= seq_diff;
            _credit = _credit + seq_diff;
            
            NSLog(@"ACK 0x%02X. Advancing ACK by %d, outstanding %d", ack_sequence, seq_diff, [self rwcpOutstandingSegments]);
            
            if (_good_ack_count >= RWCP_CWIN_ADJUSTMENT_THRESHOLD) {
                _good_ack_count = 0;
                
                if (_cwin < RWCP_CWIN_MAX) {
                    _cwin++;
                    NSLog(@"CWIN %d -> %d", _cwin - 1, _cwin);
                    
                    if (_credit < _cwin) _credit++;
                }
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(didMakeProgress:)]) {
                _progress += seg_len - 8;
                [self.delegate didMakeProgress:_progress];
            }
        } else {
            QTIRWCPSegment *seg = _recentSegments[0];
            NSLog(@"Invalid ACK (SEQ 0x%02X Next exp SEQ 0x%02X, send SEQ 0x%02X", ack_sequence, seg.sequence, _send_sequence);
        }
    }
}

- (void)handleAck:(uint8_t)ack_sequence {
    [self advanceAckSeq:ack_sequence];
    
    _gap_backoff = false;
    
    // If credit is not 0
    if (_credit && [self rwcpUnsentSegments] > 0) {
        [self setTimer:_data_timeout];
        [self sendRWCPData:false];
    } else {
        if (![self rwcpOutstandingSegments]) {
            NSLog(@"End of session, ACKs catched up. End of transfer, terminating RWCP session...");
            NSLog(@"Sending RST (SEQ 0x%02X)", _send_sequence);
            
            _state = QTIRWCPState_Closing;
            [self setTimer:_data_timeout];

            _send_sequence = 1;
            
            [self writePayload:_send_sequence
                         flags:RWCP_HEADER_OPCODE_RST
                        length:0
                          data:nil];
            
            if (_lastByteSent && _dataBuffer.count == 0) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didCompleteDataSend)]) {
                    _lastByteSent = false;
                    _lastSegmentSent = false;
                    [self.delegate didCompleteDataSend];
                }
            }
        }
    }
}

- (void)handleGap:(uint8_t)ack_sequence {
    if ([self rwcpOutstandingSegments]) {
        QTIRWCPSegment *seg = _recentSegments[0];
        
        // Check if GAP sequence number implies any lost ACKs
        if ((ack_sequence + 1) % RWCP_SEQUENCE_SPACE_SIZE != seg.sequence) {
            // Sequence number in GAP implies lost ACKs, advance outstanding sliding window
            NSLog(@"GAP with ACKs ahead");
            _gap_backoff = false;
            [self advanceAckSeq:ack_sequence];
        }
    }
    
    if (!_gap_backoff) {
        if (![self rwcpOutstandingSegments]) {
            NSLog(@"GAP server ACKs 0x%02X while no segments are outstanding. Upgrade failed", ack_sequence);
            
            [self terminateSession:true];
        }
        
        QTIRWCPSegment *seg = _recentSegments[_next_send_segment_position - 1];

        NSLog(@"GAP received, server ACKs 0x%02X, client sent 0x%02X.", ack_sequence, seg.sequence);
        NSLog(@"Rewinding %d packets and resend", [self rwcpOutstandingSegments]);
        NSLog(@"CWIN %d ->", _cwin);
        
        _cwin = ((_cwin - 1) / 2) + 1;
        
        if (_cwin > RWCP_CWIN_MAX) _cwin = 1;
        
        NSLog(@"CWIN %d", _cwin);
        _good_ack_count = 0;
        _credit = _cwin; // Reset credit
        _next_send_segment_position = 0;
        _gap_backoff = true;
        
        [self setTimer:_data_timeout];
        [self sendRWCPData:false];
    }
}

// iOS does not give you an event so...
- (void)onWrite {
    switch (_state) {
        case QTIRWCPState_SynSent:
            NSLog(@"Sent RWCP RST/SYN segments to device");
            _rwcp_failed = false;
            break;
        case QTIRWCPState_Established:
            if (_credit && [self rwcpUnsentSegments]) {
                [self setTimer:_data_timeout];
                [self sendRWCPData:false];
            }
            break;
        default:
            break;
    }
}

- (void)writePayload:(uint8_t)seq
               flags:(uint8_t)flags
              length:(size_t)length
                data:(NSData *)data {
    NSMutableData *payload = [[NSMutableData alloc] init];
    uint8_t header = (seq & RWCP_HEADER_MASK_SEQ_NUMBER) | (flags & ~(RWCP_HEADER_MASK_SEQ_NUMBER));

    [payload appendBytes:&header length:sizeof(uint8_t)];
    
    if (data) {
        [payload appendData:data];
    }
    
    [self send:payload];
    
    // iOS does not give you a callback for write without response.
    // Assume it worked and call onWrite.
    //[self onWrite];
}

- (void)timeout {
    if (_timeout_is_set) {
        _timeout_is_set = false;
        
        switch (_state) {
            case QTIRWCPState_SynSent:
                NSLog(@"SYN timeout, resending");
                
                [self setTimer:_data_timeout];
                [self writePayload:0 flags:RWCP_HEADER_OPCODE_SYN length:0 data:nil];
                break;
            case QTIRWCPState_Established:
                NSLog(@"ACK timeout, resending first unacknowledged DATA segment.");
                _data_timeout = _data_timeout * 2;
                
                if (_data_timeout > RWCP_DATA_TIMEOUT_MS_MAX) {
                    _data_timeout = RWCP_DATA_TIMEOUT_MS_MAX;
                }
                
                [self setTimer:_data_timeout];
                // resend previous data
                [self sendRWCPData:true];
                break;
            case QTIRWCPState_Closing:
                NSLog(@"RST timeout, resending RST segment.");
                NSLog(@"Sending RST (SEQ 0x%02X)", _send_sequence);
                
                [self setTimer:_data_timeout];
                [self writePayload:_send_sequence
                             flags:RWCP_HEADER_OPCODE_RST
                            length:0
                              data:nil];
                break;
            default:
                NSLog(@"Unexpected timer event");
                break;
        }
    }
}

@end
