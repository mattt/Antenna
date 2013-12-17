// Antenna.m
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

#import "Antenna.h"

#import "AFURLRequestSerialization.h"

#import <CoreData/CoreData.h>

static NSString * AntennaLogLineFromPayload(NSDictionary *payload) {
    NSMutableArray *mutableComponents = [NSMutableArray arrayWithCapacity:[payload count]];
    [payload enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        [mutableComponents addObject:[NSString stringWithFormat:@"\"%@\"=\"%@\"", key, obj]];
    }];

    return [mutableComponents componentsJoinedByString:@" "];
}

@interface AntennaStreamChannel : NSObject <AntennaChannel>
- (id)initWithOutputStream:(NSOutputStream *)outputStream;
@end

@interface AntennaHTTPChannel : NSObject <AntennaChannel>
- (id)initWithURL:(NSURL *)url
           method:(NSString *)method
requestSerializer:(AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer;
@end

#ifdef _COREDATADEFINES_H
@interface AntennaCoreDataChannel : NSObject <AntennaChannel>
- (id)initWithEntity:(NSEntityDescription *)entity
    messageAttribute:(NSAttributeDescription *)messageAttribute
  timestampAttribute:(NSAttributeDescription *)timestampAttribute
inManagedObjectContext:(NSManagedObjectContext *)context;
@end
#endif

#pragma mark -

@interface Antenna ()
@property (readwrite, nonatomic, strong) NSArray *channels;
@property (readwrite, nonatomic, strong) NSMutableDictionary *defaultPayload;
@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation Antenna

+ (instancetype)sharedLogger {
    static id _sharedAntenna = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedAntenna = [[self alloc] init];
    });

    return _sharedAntenna;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.channels = [NSArray array];

    self.defaultPayload = [NSMutableDictionary dictionary];

    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        [self.defaultPayload setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"uuid"];
    }
    [self.defaultPayload setValue:[[NSLocale currentLocale] localeIdentifier] forKey:@"locale"];

    self.notificationCenter = [NSNotificationCenter defaultCenter];
    self.operationQueue = [[NSOperationQueue alloc] init];

    return self;
}

#pragma mark -

- (void)addChannelWithFilePath:(NSString *)path {
    [self addChannelWithOutputStream:[NSOutputStream outputStreamToFileAtPath:path append:YES]];
}

- (void)addChannelWithOutputStream:(NSOutputStream *)outputStream {
    AntennaStreamChannel *channel = [[AntennaStreamChannel alloc] initWithOutputStream:outputStream];
    [self addChannel:channel];
}

- (void)addChannelWithURL:(NSURL *)URL
                   method:(NSString *)method
{
    AntennaHTTPChannel *channel = [[AntennaHTTPChannel alloc] initWithURL:URL method:method requestSerializer:[AFHTTPRequestSerializer serializer]];
    [self addChannel:channel];
}

#ifdef _COREDATADEFINES_H
- (void)addChannelWithEntity:(NSEntityDescription *)entity
            messageAttribute:(NSAttributeDescription *)messageAttribute
          timestampAttribute:(NSAttributeDescription *)timestampAttribute
      inManagedObjectContext:(NSManagedObjectContext *)context
{
    AntennaCoreDataChannel *channel = [[AntennaCoreDataChannel alloc] initWithEntity:entity messageAttribute:messageAttribute timestampAttribute:timestampAttribute inManagedObjectContext:context];
    [self addChannel:channel];
}
#endif

- (void)addChannel:(id <AntennaChannel>)channel {
    self.channels = [self.channels arrayByAddingObject:channel];
}

- (void)removeChannel:(id <AntennaChannel>)channel {
    NSMutableArray *mutableChannels = [NSMutableArray arrayWithArray:self.channels];
    if ([channel respondsToSelector:@selector(prepareForRemoval)]) {
        [channel prepareForRemoval];
    }
    [mutableChannels removeObject:channel];
    self.channels = [NSArray arrayWithArray:mutableChannels];
}

- (void)removeAllChannels {
    [self.channels enumerateObjectsUsingBlock:^(id channel, __unused NSUInteger idx, __unused BOOL *stop) {
        if ([channel respondsToSelector:@selector(prepareForRemoval)]) {
            [channel prepareForRemoval];
        }
    }];

    self.channels = [NSArray array];
}

#pragma mark -

- (void)log:(id)messageOrPayload {
    NSMutableDictionary *mutablePayload = nil;
    if ([messageOrPayload isKindOfClass:[NSDictionary class]]) {
        mutablePayload = [messageOrPayload mutableCopy];
    } else if (messageOrPayload) {
        mutablePayload = [NSMutableDictionary dictionaryWithObject:messageOrPayload forKey:@"message"];
    }

    [self.defaultPayload enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if (obj && ![mutablePayload valueForKey:key]) {
            [mutablePayload setObject:obj forKey:key];
        }
    }];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-selector-match"
    [self.channels enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id channel, __unused NSUInteger idx, __unused BOOL *stop) {
        [channel log:mutablePayload];
    }];
#pragma clang diagnostic pop
}

- (void)prepareForRemoval {
    [self stopLoggingAllNotifications];
}

#pragma mark -

- (void)startLoggingApplicationLifecycleNotifications {
    NSArray *names = [NSArray arrayWithObjects:UIApplicationDidFinishLaunchingNotification, UIApplicationDidEnterBackgroundNotification, UIApplicationDidBecomeActiveNotification, UIApplicationDidReceiveMemoryWarningNotification, nil];
    for (NSString *name in names) {
        [self startLoggingNotificationName:name];
    }
}

- (void)startLoggingNotificationName:(NSString *)name {
    [self startLoggingNotificationName:name object:nil];
}

- (void)startLoggingNotificationName:(NSString *)name
                              object:(id)object
{
    __weak __typeof(self)weakSelf = self;
    [self startLoggingNotificationName:name object:nil constructingPayLoadFromBlock:^NSDictionary *(NSNotification *notification) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;

        NSMutableDictionary *mutablePayload = [strongSelf.defaultPayload mutableCopy];
        if (notification.userInfo) {
            [notification.userInfo enumerateKeysAndObjectsUsingBlock:^(id key, __unused id obj, __unused BOOL *stop) {
                [mutablePayload setObject:object forKey:key];
            }];
        }
        [mutablePayload setObject:name forKey:@"notification"];

        return mutablePayload;
    }];
}

- (void)startLoggingNotificationName:(NSString *)name
                              object:(id)object
        constructingPayLoadFromBlock:(NSDictionary * (^)(NSNotification *notification))block
{
    __weak __typeof(self)weakSelf = self;
    [self.notificationCenter addObserverForName:name object:object queue:self.operationQueue usingBlock:^(NSNotification *notification) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        NSDictionary *payload = nil;
        if (block) {
            payload = block(notification);
        }

        [strongSelf log:payload];
    }];
}

- (void)stopLoggingNotificationName:(NSString *)name {
    [self.notificationCenter removeObserver:self name:name object:nil];
}

- (void)stopLoggingNotificationName:(NSString *)name
                             object:(id)object
{
    [self.notificationCenter removeObserver:self name:name object:object];
}

- (void)stopLoggingAllNotifications {
    [self.notificationCenter removeObserver:self];
}

@end

#pragma mark -

@interface AntennaStreamChannel ()
@property (readwrite, nonatomic, strong) NSOutputStream *outputStream;
@end

@implementation AntennaStreamChannel

- (id)initWithOutputStream:(NSOutputStream *)outputStream {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.outputStream = outputStream;
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream open];
    
    return self;
}

#pragma mark - AntennaChannel

- (void)log:(NSDictionary *)payload {
    NSData *data = [AntennaLogLineFromPayload(payload) dataUsingEncoding:NSUTF8StringEncoding];
    [self.outputStream write:[data bytes] maxLength:[data length]];
}

- (void)prepareForRemoval {
    [self.outputStream close];
}

@end

#pragma mark -

@interface AntennaHTTPChannel ()
@property (readwrite, nonatomic, strong) NSURL *URL;
@property (readwrite, nonatomic, copy) NSString *method;
@property (readwrite, nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;
@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation AntennaHTTPChannel

- (id)initWithURL:(NSURL *)url
           method:(NSString *)method
requestSerializer:(AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.method = method;
    self.URL = url;
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.requestSerializer = requestSerializer;

    return self;
}

#pragma mark - AntennaChannel

- (void)log:(NSDictionary *)payload {
    NSURLRequest *request = [self.requestSerializer requestWithMethod:self.method URLString:[self.URL absoluteString] parameters:payload];
    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:nil];
}

@end

#ifdef _COREDATADEFINES_H
@interface AntennaCoreDataChannel ()
@property (readwrite, nonatomic, strong) NSEntityDescription *entity;
@property (readwrite, nonatomic, strong) NSManagedObjectContext *context;
@property (readwrite, nonatomic, strong) NSAttributeDescription *messageAttribute;
@property (readwrite, nonatomic, strong) NSAttributeDescription *timestampAttribute;
@end

@implementation AntennaCoreDataChannel

- (id)initWithEntity:(NSEntityDescription *)entity
    messageAttribute:(NSAttributeDescription *)messageAttribute
  timestampAttribute:(NSAttributeDescription *)timestampAttribute
inManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.entity = entity;
    self.context = context;
    self.messageAttribute = messageAttribute;
    self.timestampAttribute = timestampAttribute;

    return self;
}

#pragma mark - AntennaChannel

- (void)log:(NSDictionary *)payload {
    [self.context performBlock:^{
        NSManagedObjectContext *entry = [NSEntityDescription insertNewObjectForEntityForName:self.entity.name inManagedObjectContext:self.context];
        [entry setValue:AntennaLogLineFromPayload(payload) forKey:self.messageAttribute.name];
        [entry setValue:[NSDate date] forKey:self.timestampAttribute.name];

        NSError *error = nil;
        if (![self.context save:&error]) {
            NSLog(@"Logging Error: %@", error);
        }
    }];
}

@end

#endif
