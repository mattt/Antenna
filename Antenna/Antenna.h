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
 
 */
@interface Antenna : NSObject

/**
 
 */
@property (readonly, nonatomic, strong) NSArray *channels;

/**
 
 */
@property (readonly, nonatomic, strong) NSMutableDictionary *defaultPayload;

/**
 
 */
@property (nonatomic, strong) NSNotificationCenter *notificationCenter;

/**
 
 */
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

/**
 
 */
+ (instancetype)sharedLogger;

///======================
/// @name Adding Channels
///======================

/**
 
 */
- (void)addChannelWithFilePath:(NSString *)path;

/**

 */
- (void)addChannelWithOutputStream:(NSOutputStream *)outputStream;

/**
 
 */
- (void)addChannelWithURL:(NSURL *)URL
                   method:(NSString *)method;

/**
 
 */
#ifdef _COREDATADEFINES_H
- (void)addChannelWithEntity:(NSEntityDescription *)entity
            messageAttribute:(NSAttributeDescription *)messageAttribute
          timestampAttribute:(NSAttributeDescription *)timestampAttribute
      inManagedObjectContext:(NSManagedObjectContext *)context;
#endif

/**
 
 */
- (void)addChannel:(id <AntennaChannel>)channel;

/**
 
 */
- (void)removeChannel:(id <AntennaChannel>)channel;

///==============
/// @name Logging
///==============

/**

 */
- (void)log:(id)messageOrPayload;

///===========================
/// @name Notification Logging
///===========================

/**
 
 */
- (void)startLoggingApplicationLifecycleNotifications;

/**
 
 */
- (void)startLoggingNotificationName:(NSString *)name;

/**

 */
- (void)startLoggingNotificationName:(NSString *)name
                              object:(id)object;

/**
 
 */
- (void)startLoggingNotificationName:(NSString *)name
                              object:(id)object
        constructingPayLoadFromBlock:(NSDictionary * (^)(NSNotification *notification))block;

/**
 
 */
- (void)stopLoggingNotificationName:(NSString *)name;

/**
 
 */
- (void)stopLoggingAllNotifications;


@end

#pragma mark -

@protocol AntennaChannel <NSObject>

/**
 
 */
- (void)log:(NSDictionary *)payload;

@end
