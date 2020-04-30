> This library is no longer being maintained.
> You can continue to use Antenna in your projects,
> but we recommend switching to the
> [unified logging system](https://developer.apple.com/documentation/os/logging)
> or another telemetry solution whenever you have the opportunity.

* * *

# Antenna

Visibility into how users interact with your app is invaluable.
This information can go a long way to inform user interaction design,
and improve business conversion rates.

Antenna provides this crucial level of visibility
in a way that captures majority usage information by default,
but also allows you to tune everything according to your app's particular needs.

Antenna asynchronously logs notifications to any number of
web services, files, or Core Data entities.
Each logging message comes with global state information,
including a unique identifier for the device,
along with any additional data from the notification itself.

When paired with [rack-http-logger](https://github.com/mattt/rack-http-logger),
iOS system events can be streamed directly into your web application logs
for integrated analysis.

## Usage

### AppDelegate.m

```objective-c
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [[Antenna sharedLogger] addChannelWithURL:[NSURL URLWithString:@"http://example.com"] method:@"LOG"];
  [[Antenna sharedLogger] startLoggingApplicationLifecycleNotifications];
  [[Antenna sharedLogger] startLoggingNotificationName:AntennaExampleNotification];

  // ...
}
```

## Contact

Mattt ([@mattt](https://twitter.com/mattt))

## License

Antenna is available under the MIT license. See the LICENSE file for more info.
