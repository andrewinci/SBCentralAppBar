#import "RFCommComunication.h"

@implementation RFCommComunication
@synthesize mRFCOMMChannel;
@synthesize mBluetoothDevice;
@synthesize delegate;
#if 0
#pragma mark -
#pragma mark Methods to interact with the window
#endif

- (void)closeConnecton
{
    [self closeRFCOMMConnectionOnChannel:mRFCOMMChannel];
}

-(BOOL)send:(NSString*)message{
    NSData* data = [self dataWithString:message];
    [mRFCOMMChannel writeSync:(void*)data.bytes length:data.length];
    return true;
}

- (NSData *)dataWithString:(NSString *)string{
    //string = [string stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    
    //NSCharacterSet *notAllowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefABCDEF1234567890"] invertedSet];
    //string = [[string componentsSeparatedByCharactersInSet:notAllowedCharacters] componentsJoinedByString:@""];
    
    const char *cString = [string cStringUsingEncoding:NSASCIIStringEncoding];
    const char *idx = cString;
    unsigned char result[[string length] / 2];
    size_t count = 0;
    
    for(count = 0; count < sizeof(result)/sizeof(result[0]); count++)
    {
        sscanf(idx, "%2hhx", &result[count]);
        idx += 2 * sizeof(char);
    }
    
    return [[NSData alloc] initWithBytes:result length:sizeof(result)];
}
- (void)openConnection
{
    if ( [self openSerialPortProfile] )
    {
        // if openSerialPortProfile is successful the connection is open or at
        // least in the process of opening. So we disable the "Open" button. The
        // button will be re-enabled if the open process fails or when the
        // connection is closed.
    }
}


// =============================
// == BLUETOOTH SPECIFIC CODE ==
// =============================

#if 0
#pragma mark -
#pragma mark Methods to handle the Baseband and RFCOMM connection
#endif

- (BOOL)openSerialPortProfile
{
    IOBluetoothDeviceSelectorController	*deviceSelector;
    //IOBluetoothSDPUUID					*sppServiceUUID;
    NSArray								*deviceArray;
    
    deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
    if ( [deviceSelector runModal] != kIOBluetoothUISuccess )
    {
        NSLog( @"User has cancelled the device selection.\n" );
    }
    deviceArray = [deviceSelector getResults];
    IOBluetoothDevice *device = [deviceArray objectAtIndex:0];
    NSArray *deviceServices=[device services];
    IOBluetoothSDPServiceRecord *sppServiceRecord=[deviceServices objectAtIndex:6];
    
    
    
    // To connect we need a device to connect and an RFCOMM channel ID to open on the device:
    UInt8	rfcommChannelID;
    if ( [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess )
    {
        NSLog( @"Error - no spp service in selected device.  ***This should never happen an spp service must have an rfcomm channel id.***\n" );
        return FALSE;
    }
    IOBluetoothRFCOMMChannel *mmRFCOMMChannel=mRFCOMMChannel;
    // Open asyncronously the rfcomm channel when all the open sequence is completed my implementation of "rfcommChannelOpenComplete:" will be called.
    if ( ( [device openRFCOMMChannelAsync:&mmRFCOMMChannel withChannelID:rfcommChannelID delegate:self] != kIOReturnSuccess ) && ( mmRFCOMMChannel != nil ) )
    {
        // Something went bad (looking at the error codes I can also say what, but for the moment let's not dwell on
        // those details). If the device connection is left open close it and return an error:
        NSLog( @"Error - open sequence failed.***\n" );
        
        [self closeDeviceConnectionOnDevice:device];
        
        return FALSE;
    }
    
    // So far a lot of stuff went well, so we can assume that the device is a good one and that rfcomm channel open process is going
    // well. So we keep track of the device and we (MUST) retain the RFCOMM channel:
    mBluetoothDevice = device;
    mRFCOMMChannel=mmRFCOMMChannel;
    return TRUE;
}

- (void)closeRFCOMMConnectionOnChannel:(IOBluetoothRFCOMMChannel*)channel
{
    if ( mRFCOMMChannel == channel )
    {
        [mRFCOMMChannel closeChannel];
    }
}

- (void)closeDeviceConnectionOnDevice:(IOBluetoothDevice*)device
{
    if ( mBluetoothDevice == device )
    {
        IOReturn error = [mBluetoothDevice closeConnection];
        if ( error != kIOReturnSuccess )
        {
            // I failed to close the connection, maybe the device is busy, no problem, as soon as the device is no more busy it will close the connetion itself.
            NSLog(@"Error - failed to close the device connection with error %08x.\n", (unsigned int)error);
        }
        
        //[mBluetoothDevice release];
        mBluetoothDevice = nil;
    }
    
    // Re-enable the open button so the user can restart the sequence:
    // Since we are closed also disables the close button:

}

#if 0
#pragma mark -
#pragma mark These are methods that are called when "things" happen on the
#pragma mark bluetooth connection, read along and it will all be clearer:
#endif

// Called by the RFCOMM channel on us once the baseband and rfcomm connection is completed:
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error
{
    // If it failed to open the channel call our close routine and from there the code will
    // perform all the necessary cleanup:
    if ( error != kIOReturnSuccess )
    {
        NSLog(@"Error - failed to open the RFCOMM channel with error %08x.\n", (unsigned int)error);
        [self rfcommChannelClosed:rfcommChannel];
        return;
    }
    
    // Now that the channel is successfully open we enable the close button:
    
    // The RFCOMM channel is now completly open so it is possible to send and receive data
    // ... add the code that begin the send data ... for example to reset a modem:
    [rfcommChannel writeSync:"ATZ\n" length:4];
}

// Called by the RFCOMM channel on us when new data is received from the channel:
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    NSMutableString *result=[[NSMutableString alloc] init];
    unsigned char *dataAsBytes = (unsigned char *)dataPointer;
    
    while ( dataLength-- )
    {
        [result appendString:[NSString stringWithFormat:@"%02x ", *dataAsBytes]];
        //[self addThisByteToTheLogs:*dataAsBytes];
        dataAsBytes++;
    }
    NSString *toReturn=result;
    //return
    if([delegate respondsToSelector:@selector(receivedMessage:)])
    {
        //send the delegate function with the amount entered by the user
        [delegate receivedMessage:toReturn];
    }
}

// Called by the RFCOMM channel on us when something happens and the connection is lost:
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
    // wait a second and close the device connection as well:
    [self performSelector:@selector(closeDeviceConnectionOnDevice:) withObject:mBluetoothDevice afterDelay:1.0];
}
@end

