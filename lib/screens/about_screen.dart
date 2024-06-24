import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import './overview_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;


class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appName = "";
  String _packageName = "";
  String _version = "";
  String _buildNumber = "";

  @override
  void initState() {
    super.initState();
    _getPackageInfo();
  }

  Future<void> _getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appName = packageInfo.appName;
      _packageName = packageInfo.packageName;
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OverviewScreen()),
          );
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
              title: const Text('About'),
              // The leading widget is on the left side of the app bar
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip:
                        MaterialLocalizations.of(context).openAppDrawerTooltip,
                  );
                },
              ),
            ),
            drawer: const AppDrawer(),
            body: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("Author: Markus J.T. de Ruijter")),
                        Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                                "App version: $_version $_buildNumber")),
                        Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                                "Platform: ${Platform.operatingSystem.toString()}")),
                      ],
                    )))));
  }
}
