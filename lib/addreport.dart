import 'dart:io';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class AddReport extends StatefulWidget {
  const AddReport({super.key});

  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  String? _selectedCaseType;
  Future<String?>? _locationFuture;
  String? _mediaType;
  String? _mediaName;
  File? _mediaFile;
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher(); // Instantiate FirestoreFetcher
  Future<String?> getCity(double latitude, double longitude) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    Placemark place = placemarks[0];
    return "${place.locality}";
  }


  @override
  void initState() {
    super.initState();
    _locationFuture = _getCurrentLocation() as Future<String?>?;
  }

  Future<String?> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationFuture = Future.value(
            "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}");
      });
      print("${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}");
    } catch (e) {
      print("Error getting location: $e");
    }
    return null;
  }

  Future<void> getLocationAndPrintCity() async {
    String? location = await _getCurrentLocation();
    if (location != null) {
      List<String> coordinates = location.split(', ');
      double latitude = double.parse(coordinates[0]);
      double longitude = double.parse(coordinates[1]);
      String? city = await getCity(latitude, longitude);
      if (city != null) {
        print("Current city: $city");
      } else {
        print("City not found for the given coordinates.");
      }
    } else {
      print("Failed to retrieve location");
    }
  }


  Future<void> pickMedia(BuildContext context, String type) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await (type == 'photo'
          ? picker.pickImage(source: ImageSource.gallery)
          : picker.pickVideo(source: ImageSource.gallery));
      if (pickedFile != null) {
        setState(() {
          _mediaName = pickedFile.path; // Update to full file path
          _mediaFile = File(pickedFile.path);
          _mediaType = type;
        });
        print('$type picked: ${pickedFile.path}');
        // You can handle the picked media here
      } else {
        print('No $type selected.');
      }
    } catch (e) {
      print('Error picking $type: $e');
    }
  }

  Future<void> captureMedia(String type) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await (type == 'photo'
          ? picker.pickImage(source: ImageSource.camera)
          : picker.pickVideo(source: ImageSource.camera));
      if (pickedFile != null) {
        setState(() {
          _mediaName = pickedFile.path; // Update to full file path
          _mediaFile = File(pickedFile.path);
          _mediaType = type;
        });
        print('$type captured: ${pickedFile.path}');
      } else {
        print('$type capture canceled');
      }
    } catch (e) {
      print('Error capturing $type: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> caseTypes = [
      'Select Case Type',
      'Robbery',
      'Sexual Harassment',
      'Kidnapping',
      'Car Theft',
      'Terrorism'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Add Report",
          style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
      iconTheme: IconThemeData(color: Colors.white), // Set the leading icon color to white
    ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text("Add Report", style: TextStyle(fontSize: 30)),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                borderRadius: BorderRadius.circular(30),
                value: _selectedCaseType ?? caseTypes[0], // Set the initial value
                items: caseTypes
                    .map((String type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  // Update the selected case type when user selects a case type
                  setState(() {
                    _selectedCaseType = value;
                  });
                  print('Selected case type: $value');
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  labelText: 'Case Type',
                ),
              ),
              SizedBox(height: 20),
              FutureBuilder<String?>(
                future: _locationFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return TextFormField(
                      key: UniqueKey(),
                      readOnly: true, // Set readOnly to true
                      initialValue: snapshot.data,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.my_location_rounded),
                          onPressed: _getCurrentLocation,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error getting location');
                  }
                  return TextFormField(
                    key: UniqueKey(),
                    initialValue: "Fetching location",
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                "Media:",
                style: TextStyle(),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.black),
                  color: Colors.grey[200],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_mediaName != null)
                              _mediaType == 'photo'
                                  ? Image.file(
                                File(_mediaName!), // Assuming _mediaName is the path to the image file
                                width: double.infinity,
                                height: 200, // Adjust the height as needed
                                fit: BoxFit.cover, // Ensure the image covers the container
                              )
                                  : _mediaType == 'video'
                                  ? Text('Video Preview unavailable')
                                  : Container() // Placeholder if the media type is neither photo nor video
                            else
                              Container(), // Placeholder if no media is selected
                            SizedBox(height: 8), // Adding some space between media preview and media name
                            Text(
                              _mediaType != null
                                  ? _mediaType == 'video'
                                  ? 'Video Name: ${_mediaName!.split('/').last}'
                                  : _mediaType == 'photo'
                                  ? 'Image Name: ${_mediaName!.split('/').last}'
                                  : '$_mediaType Name: $_mediaName'
                                  : 'No Media Selected',
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        if (_mediaType != null && _mediaName != null) {
                          setState(() {
                            _mediaType = null;
                            _mediaName = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Media deleted.'),
                              duration: Duration(seconds: 2), // Adjust the duration as needed
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No media selected.'),
                              duration: Duration(seconds: 2), // Adjust the duration as needed
                            ),
                          );
                        }
                      },
                    )

                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min, // Ensure the Column only occupies the space it needs
                            children: <Widget>[
                              SizedBox(height: 10,),
                              ListTile(
                                leading: Icon(
                                  Icons.photo,
                                  size: 36, // Adjust the size of the icon
                                ),
                                title: Text(
                                  'Upload Image',
                                  style: TextStyle(fontSize: 20), // Adjust the font size
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  pickMedia(context, 'photo');
                                },
                              ),
                              SizedBox(height: 10,),
                              ListTile(
                                leading: Icon(
                                  Icons.video_file_outlined,
                                  size: 36, // Adjust the size of the icon
                                ),
                                title: Text(
                                  'Upload Video',
                                  style: TextStyle(fontSize: 20), // Adjust the font size
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  pickMedia(context, 'video');
                                },
                              ),
                              SizedBox(height: 10,),
                              ListTile(
                                leading: Icon(
                                  Icons.camera_alt,
                                  size: 36, // Adjust the size of the icon
                                ),
                                title: Text(
                                  'Capture Image',
                                  style: TextStyle(fontSize: 20), // Adjust the font size
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  captureMedia('photo');
                                },
                              ),
                              SizedBox(height: 10,),
                              ListTile(
                                leading: Icon(
                                  Icons.videocam,
                                  size: 36, // Adjust the size of the icon
                                ),
                                title: Text(
                                  'Capture Video',
                                  style: TextStyle(fontSize: 20), // Adjust the font size
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  captureMedia('video');
                                },
                              ),
                              SizedBox(height: 10,),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.upload),
                    label: Text('Upload Evidence'),
                    style: ButtonStyle(shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50,),
              Container(
                width: 200, // Adjust the width as needed
                child: ElevatedButton(
                  onPressed: () async {
                    // Check if the case type is selected
                    if (_selectedCaseType != null) {
                      try {
                        // Retrieve the location asynchronously
                        String? location = await _locationFuture;
                        List<String> coordinates = location!.split(', ');
                        double latitude = double.parse(coordinates[0]);
                        double longitude = double.parse(coordinates[1]);
                        String? city = await getCity(latitude, longitude);
                        // Check if location is available
                        if (location != null) {
                          // Print the location
                          print('Uploading report with case type: $_selectedCaseType and location: $location and url $_mediaFile');
                          // Call the uploadReport method from FirestoreFetcher
                          await _firestoreFetcher.uploadReport(_selectedCaseType!, location, _mediaFile!, city!);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Report uploaded successfully!'),
                            ),
                          );
                        } else {
                          // Location is not available
                          print('Location is not available.');
                          // Show error message or take appropriate action
                        }
                      } catch (e) {
                        // Error occurred while getting location or uploading report
                        print('Error: $e');
                        // Show error message or take appropriate action
                      }
                    } else {
                      // Case type is not selected
                      print('Please select a case type.');
                      // Show error message or take appropriate action
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: Text(
                    "Upload Report",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}