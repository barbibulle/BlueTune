//
//  CocoaPlayerController.m
//  CocoaPlayer
//
//  Created by Gilles on 9/7/08.
//  Copyright 2008 Gilles Boccon-Gibod. All rights reserved.
//

#import "BtCocoaPlayerController.h"

@interface CocoaPlayerRecordList : NSObject 
{
    NSMutableArray* records;
}
-(int) numberOfRowsInTableView:(NSTableView *)aTableView;
-(id)        tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
@end


@implementation CocoaPlayerRecordList

-(id) init
{
    if ((self = [super init])) {
        records = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
    [records release];
    [super dealloc];
}

-(int) numberOfRowsInTableView: (NSTableView *)view
{
    return [records count];
}

-(id)             tableView: (NSTableView *)   view 
  objectValueForTableColumn: (NSTableColumn *) column 
                        row: (int)             rowIndex
{
    id record = [records objectAtIndex: rowIndex];
    id value = [record objectForKey: [column identifier]];    
    return value;
}

-(void) setProperty: (NSString*) name value: (NSString*) value
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setValue: name forKey: @"Name"];
    [dict setValue: value forKey: @"Value"];
    [records addObject: dict];
}

@end

@implementation CocoaPlayerController
-(id) init 
{
    if ((self = [super init])) {
        player = [[BLT_PlayerObject alloc] init];
        [player setDelegate: self];
        // TEMP
        [player setOutput: @"osxaq:0"];
    }
    return self;
}

-(void) awakeFromNib
{        
    // set the data source for the list views
    [playerPropertiesView setDataSource: [[CocoaPlayerRecordList alloc]init]];
    [playerStreamInfoView setDataSource: [[CocoaPlayerRecordList alloc]init]];
}

-(IBAction) play: (id) sender;
{
    [player play];
}

-(IBAction) stop: (id) sender;
{
    [player stop];
}

-(IBAction) pause: (id) sender;
{
    [player pause];
}

-(IBAction) setInput: (id) sender;
{
    [player stop];
    [player setInput: [playerInput stringValue]];
}

-(IBAction) seek: (id) sender;
{
    UInt64 position = [playerPosition floatValue] * 1000.0;
    UInt64 range    = [playerPosition maxValue] * 1000.0;
    [player seekToPosition: position range: range];
}

-(IBAction) setVolume: (id) sender;
{
    float volume = [playerVolume floatValue]/[playerVolume maxValue];
    [player setVolume: volume];
}

-(IBAction) chooseFile: (id) sender;
{
}

-(void) ackWasReceived: (BLT_Player_CommandId) command_id
{
    printf("ACK %d\n", command_id);
}

-(void) nackWasReceived: (BLT_Player_CommandId) command_id result: (BLT_Result) result
{
    printf("NACK %d, %d\n", command_id, result);
}

-(void) decoderStateDidChange: (BLT_Player_DecoderState) state
{
    switch (state) {
        case BLT_PLAYER_DECODER_STATE_EOS:
            [playerState setStringValue: @"[EOS]"]; break;
        case BLT_PLAYER_DECODER_STATE_STOPPED:
            [playerState setStringValue: @"[STOPPED]"]; break;
        case BLT_PLAYER_DECODER_STATE_PLAYING:
            [playerState setStringValue: @"[PLAYING]"]; break;
        case BLT_PLAYER_DECODER_STATE_PAUSED:
            [playerState setStringValue: @"[PAUSED]"]; break;
    }
}

-(void) streamTimecodeDidChange: (BLT_TimeCode) timecode
{
    NSString* timecode_string = [NSString stringWithFormat:@"%02d:%02d:%02d", timecode.h, timecode.m, timecode.s];
    [playerTimecode setStringValue: timecode_string];
}

-(void) streamPositionDidChange: (BLT_StreamPosition) position
{
    float where = (float)position.offset*100.0f/(float)position.range;
    [playerPosition setFloatValue: where];
}

-(void) streamInfoDidChange: (const BLT_StreamInfo*) info updateMask: (BLT_Mask) mask
{
    if (mask & BLT_STREAM_INFO_MASK_DATA_TYPE) {
        [[playerStreamInfoView dataSource] setProperty: @"Data Type" value: [NSString stringWithUTF8String: info->data_type]];
    }
    if (mask & BLT_STREAM_INFO_MASK_DURATION) {
        [[playerStreamInfoView dataSource] setProperty: @"Duration" value: [NSString stringWithFormat:@"%2f", (float)info->duration/1000.0f]];
    }
    if (mask & BLT_STREAM_INFO_MASK_NOMINAL_BITRATE) {
        [[playerStreamInfoView dataSource] setProperty: @"Nominal Bitrate" value: [NSString stringWithFormat:@"%d", info->nominal_bitrate]];
    }
    if (mask & BLT_STREAM_INFO_MASK_AVERAGE_BITRATE) {
        [[playerStreamInfoView dataSource] setProperty: @"Average Bitrate" value: [NSString stringWithFormat:@"%d", info->average_bitrate]];
    }
    if (mask & BLT_STREAM_INFO_MASK_INSTANT_BITRATE) {
        [[playerStreamInfoView dataSource] setProperty: @"Instant Bitrate" value: [NSString stringWithFormat:@"%d", info->instant_bitrate]];
    }
    if (mask & BLT_STREAM_INFO_MASK_SIZE) {
        [[playerStreamInfoView dataSource] setProperty: @"Size" value: [NSString stringWithFormat:@"%d", info->size]];
    }
    if (mask & BLT_STREAM_INFO_MASK_SAMPLE_RATE) {
        [[playerStreamInfoView dataSource] setProperty: @"Sample Rate" value: [NSString stringWithFormat:@"%d", info->sample_rate]];
    }
    if (mask & BLT_STREAM_INFO_MASK_CHANNEL_COUNT) {
        [[playerStreamInfoView dataSource] setProperty: @"Channels" value: [NSString stringWithFormat:@"%d", info->channel_count]];
    }
    if (mask & BLT_STREAM_INFO_MASK_FLAGS) {
        [[playerStreamInfoView dataSource] setProperty: @"Flags" value: [NSString stringWithFormat:@"%x", info->flags]];
    }
    [playerStreamInfoView reloadData];
}

-(void) propertyDidChange: (BLT_PropertyScope)        scope 
                   source: (const char*)              source 
                     name: (const char*)              name 
                    value: (const ATX_PropertyValue*) value
{
    if (name == NULL || value == NULL) return;
    
    NSString* value_string = nil;
    switch (value->type) {
        case ATX_PROPERTY_VALUE_TYPE_STRING:
            value_string = [NSString stringWithUTF8String: value->data.string];
            break;

        case ATX_PROPERTY_VALUE_TYPE_INTEGER:
            value_string = [NSString stringWithFormat:@"%d", value->data.string];
            break;
            
        default:
            value_string = @"";
    }
    if (value_string) {
        [[playerPropertiesView dataSource] setProperty: [NSString stringWithUTF8String: name] value: value_string];
    }
}

@end
