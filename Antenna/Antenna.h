// Antenna.h
// 
// Copyright (c) 2013 Mattt Thompson
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@protocol AntennaChannel;

/**
 Antenna objects asynchronously log notifications to subscribed channels, such as web services, files, or Core Data entities. Each logging message comes with global state information, including a unique identifier for the device, along with any additional data from the notification itself.
 */
@interface Antenna : NSObject

/**
 The currently active channels.
 */
@property (readonly, nonatomic, strong) NSArray *channels;

/**
 The default payload to include in each logged message.
 */
@property (readonly, nonatomic, strong) NSMutableDictionary *defaultPayload;

/**
 The notification center on which to observe notifications.
 */
@property (nonatomic, strong) NSNotificationCenter *notificationCenter;

/**
 The operation queoe onto which notifications are posted.
 */
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

/**
 The shared Antenna instance.
 */
+ (instancetype)sharedLogger;

///======================
/// @name Adding Channels
///======================

/**
 Adds a new channel that logs messages to a file at the specified path.
 */
- (void)addChannelWithFilePath:(NSString *)path;

/**
 Adds a new channel that logs messages to the specified output stream.
 */
- (void)addChannelWithOutputStream:(NSOutputStream *)outputStream;

/**
 Adds a new channel that logs to the specified URL with a given HTTP method.
 */
- (void)addChannelWithURL:(NSURL *)URL
                   method:(NSString *)method;

/**
 Adds a new channel that logs messages by inserting managed objects of a particular entity into a given managed object context using the specified attributes for the message and timestamp properties.
 
 @param entity The entity used to model log messages
 @param messageAttribute The attribute used to store the log message
 @param timestampAttribute The attribute used to store the log timestamp
 @param context The managed object context
 
 @warning Requires that Core Data is linked and imported in the target's precompiled header.
 */
#ifdef _COREDATADEFINES_H
- (void)addChannelWithEntity:(NSEntityDescription *)entity
            messageAttribute:(NSAttributeDescription *)messageAttribute
          timestampAttribute:(NSAttributeDescription *)timestampAttribute
      inManagedObjectContext:(NSManagedObjectContext *)context;
#endif

/**
 Adds the specified channel.
 
 @param channel The channel to add.
 */
- (void)addChannel:(id <AntennaChannel>)channel;

/**
 Removes the specified channel, if present.
 
 @param channel The channel to remove.
 */
- (void)removeChannel:(id <AntennaChannel>)channel;

/**
 Removes all channels.
 */
- (void)removeAllChannels;

///==============
/// @name Logging
///==============

/**
 Logs the specified message or payload to each channel.
 
 @param messageOrPayload An `NSString` or `NSDictionary` object to log.
 */
- (void)log:(id)messageOrPayload;

///===========================
/// @name Notification Logging
///===========================

/**
 Start listening for and logging UIApplicationDelegate application lifecycle notifications.
 */
- (void)startLoggingApplicationLifecycleNotifications;

/**
 Start listening for and logging notifications with the specified name.
 
 @param name The notification name.
 */
- (void)startLoggingNotificationName:(NSString *)name;

/**
 Start listening for and logging notifications with the specified name and object.
 
 @param name The notification name.
 @param object The notification object.
 */
- (void)startLoggingNotificationName:(NSString *)name
                              object:(id)object;

/**
 Start listening for and logging notifications with a name and object, constructing the payload for the log message from the notification using the specified block.

 @param name The notification name.
 @param object The notification object.
 @param block A block used to construct the payload to log from a given notification. The returns the payload and takes a single argument: the received notification to log.
 */
- (void)startLoggingNotificationName:(NSString *)name
                              object:(id)object
        constructingPayLoadFromBlock:(NSDictionary * (^)(NSNotification *notification))block;

/**
 Stop listening for and logging all notifications with the specified name.
 
 @param name The notification name.
 */
- (void)stopLoggingNotificationName:(NSString *)name;

/**
 Stop listening for and logging notifications with the specified name and object.

 @param name The notification name.
 @param object The notification object.
 */
- (void)stopLoggingNotificationName:(NSString *)name
                             object:(id)object;

/**
 Stop listening for and logging all notifications.
 */
- (void)stopLoggingAllNotifications;

@end

#pragma mark -

/**
 The AntennaChannel protocol defines the required methods for objects that can be added as channels by Antenna.
 */
@protocol AntennaChannel <NSObject>

@required

/**
 Log the specified payload.
 */
- (void)log:(NSDictionary *)payload;

@optional

/**
 Called before a channel is removed.
 
 @warning This method should never be called directly.
 */
- (void)prepareForRemoval;

@end
