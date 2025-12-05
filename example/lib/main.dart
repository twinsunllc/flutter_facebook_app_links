import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_facebook_app_links/flutter_facebook_app_links.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _deepLinkStatus = 'Waiting for deep link...';
  String _consentStatus = 'Not initialized';
  String _trackingStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    requestTrackingConsent();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterFacebookAppLinks.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    // Get deferred deep link
    await initDeepLink();
  }

  Future<void> requestTrackingConsent() async {
    try {
      // iOS: Request ATT permission first
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.requestTrackingAuthorization();
        final trackingEnabled = status == TrackingStatus.authorized;

        setState(() {
          _trackingStatus = 'ATT Status: ${status.toString().split('.').last}';
        });

        // Step 2: Set advertiser tracking based on ATT result
        await FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(trackingEnabled);

        // Step 3: Initialize Facebook SDK
        await FlutterFacebookAppLinks.consentProvided();
      } else {
        // Android: No ATT - just enable tracking and provide consent
        await FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(true);
        await FlutterFacebookAppLinks.consentProvided();
      }

      setState(() {
        _consentStatus = 'Facebook SDK initialized with consent';
      });
    } catch (e) {
      setState(() {
        _consentStatus = 'Error during consent flow: $e';
        _trackingStatus = 'Error: $e';
      });
    }
  }

  Future<void> initDeepLink() async {
    try {
      // Initialize Facebook Deep Links
      final deepLinkData = await FlutterFacebookAppLinks.initFBLinks();

      if (deepLinkData != null) {
        final deeplink = deepLinkData['deeplink'];
        final promoCode = deepLinkData['promotionalCode'];
        setState(() {
          _deepLinkStatus = 'Deep link received:\n'
              'URL: ${deeplink ?? 'null'}\n'
              'Promo Code: ${promoCode ?? 'null'}';
        });
      } else {
        setState(() {
          _deepLinkStatus = 'No deferred deep link available';
        });
      }

      // Also get the direct deep link URL
      final directLink = await FlutterFacebookAppLinks.getDeepLink();
      if (directLink.isNotEmpty && directLink != 'null') {
        setState(() {
          _deepLinkStatus += '\nDirect link: $directLink';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _deepLinkStatus = 'Error getting deep link: ${e.message}';
      });
    }
  }

  Future<void> testTrackingToggle() async {
    // This demonstrates changing tracking status after initial consent
    try {
      // Disable tracking
      await FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(false);
      setState(() {
        _trackingStatus = 'Tracking DISABLED (demo)';
      });

      await Future.delayed(Duration(seconds: 2));

      // Re-enable tracking
      await FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(true);
      setState(() {
        _trackingStatus = 'Tracking ENABLED (demo)';
      });
    } catch (e) {
      setState(() {
        _trackingStatus = 'Error toggling tracking: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Facebook App Links Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Platform: $_platformVersion\n',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  'Facebook Consent Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_consentStatus),
                SizedBox(height: 20),
                Text(
                  'Tracking Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_trackingStatus),
                SizedBox(height: 20),
                Text(
                  'Deep Link Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_deepLinkStatus),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: requestTrackingConsent,
                  child: Text('Request ATT & Initialize Facebook'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: testTrackingToggle,
                  child: Text('Test Tracking Toggle (Demo)'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: initDeepLink,
                  child: Text('Refresh Deep Link Data'),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Usage Notes:\n'
                    '• On iOS: Button triggers ATT permission → sets advertiser tracking → initializes SDK\n'
                    '• On Android: Button enables tracking → initializes SDK\n'
                    '• Deep link data may take a few seconds to load\n'
                    '• Toggle button demonstrates changing tracking status after initialization',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
