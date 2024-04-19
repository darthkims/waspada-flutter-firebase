import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fypppp/casesaround.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/profile.dart';
import 'package:fypppp/settings.dart';
import 'package:fypppp/sos.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fypppp/reportcase.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatelessWidget {
  const Home({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waspada',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  late MapController mapController;
  LatLng _currentLocation = LatLng(2.194552187594141, 102.25283674118499); // Default location
  int currentPageIndex = 0; // Index of the currently selected item

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getLocation();
  }

  Future<void> _getLocation() async {
    // Check if location permission is granted
    var status = await Permission.location.request();

    if (status.isGranted) {
      // Location permission granted, proceed to get the current position
      if (mounted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          mapController.move(_currentLocation, 19.0);
          print("$_currentLocation");
        });
      }
    } else {
      // Location permission denied or restricted, handle accordingly
      // You may show a dialog or message to the user explaining why location permission is necessary
      // and guide them to grant permission from device settings.
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      // _selectedIndex = index;
      switch (index) {
        case 0:
        // Handle Home navigation (already on Home page)
          break;
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Circles()));
          break;
        case 2:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => CasesAround()));
          break;
        case 3:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProfilePage())); // Assuming Profile page
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/darthkims/clulut7s900q401r2fbvm05ta/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiZGFydGhraW1zIiwiYSI6ImNscWppYWEzNzFram8ya21temU5cDdmN3kifQ.AhgO7e5wWPUR1KCKHiqBwg',
                userAgentPackageName: 'com.example.app',
                additionalOptions: {
                  'accessToken' : 'pk.eyJ1IjoiZGFydGhraW1zIiwiYSI6ImNscWppYWEzNzFram8ya21temU5cDdmN3kifQ.AhgO7e5wWPUR1KCKHiqBwg',
                  'id' : 'mapbox.cluluqvrw00ut01r56i0e1sre'
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    child: Icon(Icons.navigation_outlined, size: 50,),
                  ),
                ],
              ),

            ],
          ),
          Positioned(
            bottom: 36.0,
            right: 16.0,
            child: SizedBox(
              height: 60.0, // Adjust height and width as needed
              width: 60.0,
              child: FittedBox(
                child: FloatingActionButton(
                  heroTag: UniqueKey(),
                  onPressed: _getLocation,
                  tooltip: 'Locate Me',
                  child: Icon(Icons.my_location),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120.0,
            right: 16.0,
            child: SizedBox(
              height: 60.0, // Adjust height and width as needed
              width: 60.0,
              child: FittedBox(
                child: SpeedDial(
                  animatedIcon: AnimatedIcons.menu_close,
                  overlayColor: Colors.black,
                  overlayOpacity: 0.5,
                  spaceBetweenChildren: 5,
                  spacing: 5,
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.settings),
                      backgroundColor: Colors.blue,
                      label: 'Settings',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Settings()));                  },
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.notifications),
                      backgroundColor: Colors.green,
                      label: 'Notifications',
                      onTap: () {
                        // Handle Option 1 tap
                      },
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.flag),
                      backgroundColor: Colors.orangeAccent,
                      label: 'Report Case',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReportCase()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: SizedBox(
        width: 90,
        height: 90,
        child: FloatingActionButton(
          heroTag: UniqueKey(),
          backgroundColor: Colors.red,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SOSPage()));
          },
          child: Icon(Icons.sos, size: 70, color: Colors.white,),
          shape: CircleBorder(),

        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                    : const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)

          ),
        ),
        child: NavigationBar(
          height: 75,
          backgroundColor: Colors.blue,
          onDestinationSelected: _onItemTapped, // Use _onItemTapped for selection
          indicatorColor: Colors.white,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: ImageIcon(
                AssetImage('assets/images/appicon.png'), size: 30, // Replace with your image path
              ),
              icon: ImageIcon(
                AssetImage('assets/images/appicon.png',), size: 30, color: Colors.white, // Replace with your image path
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.diversity_1_outlined, size: 30,),
              icon: Icon(Icons.diversity_1, color: Colors.white, size: 30,),
              label: 'Circles', // Empty label for a cleaner look (optional)
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.settings_input_antenna_outlined, size: 30,),
              icon: Icon(Icons.settings_input_antenna, color: Colors.white, size: 30,),
              label: 'Cases Around',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.account_circle_outlined, size: 30,),
              icon: Icon(Icons.account_circle, color: Colors.white, size: 30,),
              label: 'Profile', // Empty label for a cleaner look (optional)
            ),
            ],
          ),
      ),
    );
  }
}
