import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/casesaround.dart';


const Color theme = Colors.red;
const Color sectheme = Colors.white;

class CasesAroundSpecific extends StatefulWidget {
  final List<String> cities;
  final String cityName;

  const CasesAroundSpecific({super.key, required this.cities, required this.cityName});

  @override
  State<CasesAroundSpecific> createState() => _CasesAroundSpecificState();
}

class _CasesAroundSpecificState extends State<CasesAroundSpecific> {
  Set<String> uniqueCities = <String>{};
  Map<String, int> cityOccurrences = {};

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Help"),
          content: const Text(
            "Only cities with cases are listed.\n"
                "Green: 1-2 cases\n"
                "Yellow: 3-4 cases\n"
                "Red: 5 or more cases",
            style: TextStyle(fontSize: 15),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F2),
      appBar: AppBar(
        backgroundColor: theme,
        title: Text(
          widget.cityName,
          style: const TextStyle(color: sectheme, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: sectheme),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: sectheme,
                ),
                onPressed: () {
                  _showHelpDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 8, right: 8,),
        child: FutureBuilder(
          future: FirebaseFirestore.instance.collection('reports').get(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final reports = snapshot.data!.docs;
              // Clear set to avoid duplicates when rebuilding
              uniqueCities.clear();
              cityOccurrences.clear(); // Clear cityOccurrences map
              for (var report in reports) {
                // Preprocess city name before adding to set
                String cityName = report['city'];
                if (cityName.toLowerCase() == 'malacca') {
                  cityName = 'Malacca City'; // Treat 'Malacca' as 'Melaka'
                }
                if (cityName.toLowerCase() == 'melaka') {
                  cityName = 'Malacca City'; // Treat 'Malacca' as 'Melaka'
                }
                if (widget.cities.any((item) => cityName.contains(item))) { // Check if the city is in the list
                  uniqueCities.add(cityName);
                  // Update cityOccurrences map
                  if (cityOccurrences.containsKey(cityName)) {
                    cityOccurrences[cityName] = cityOccurrences[cityName]! + 1;
                  } else {
                    cityOccurrences[cityName] = 1;
                  }
                }
              }
              final cityList = uniqueCities.toList();
              // Add a blank city to the end if the city list has an odd number of elements
              if (cityList.length % 2 != 0) {
                cityList.add('');
              }
              return ListView.builder(
                itemCount: (cityList.length / 2).ceil(),
                // Calculate number of rows
                itemBuilder: (context, index) {
                  final int startIndex = index * 2;
                  final int endIndex = startIndex + 2;
                  final List<String> rowCities =
                  cityList.sublist(startIndex, endIndex);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: rowCities.map((cityName) {
                      final int cases = cityOccurrences[cityName] ?? 0;
                      final bool highCases = cases > 4;
                      final bool midCases = cases > 2;
                      Color color = highCases
                          ? const Color(0xffF88379)
                          : midCases
                          ? const Color(0xFFFFFAA0)
                          : const Color(0xFFF1E3C8);
                      Color style = highCases
                          ? Colors.white
                          : midCases
                          ? const Color(0xFF04234D)
                          : const Color(0xFF04234D);
                      String warning = highCases ? "assets/images/red_warning.png" : midCases ? "assets/images/yellow_warning.png" : "assets/images/green_warning.png";
                      return Expanded(
                        child: cityName.isNotEmpty
                            ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CityDetailsPage(
                                        cityName: cityName,
                                        color: color,
                                        style: style,
                                        totalCases: cityOccurrences[cityName]!
                                    )
                                ),
                              );
                            },
                            child: Container(
                              height: 120,
                              // Specify a fixed height for the container
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.8),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  children: [
                                    Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Image.asset(warning, width: 35,)
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cityName,
                                          style: TextStyle(
                                              color: highCases
                                                  ? Color(0xFF04234D)
                                                  : midCases
                                                  ? const Color(0xFF04234D)
                                                  : const Color(0xFF04234D),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "Cases: ${cityOccurrences[cityName] ?? 0}",
                                          // Display the number of occurrences
                                          style: TextStyle(
                                              color: highCases
                                                  ? Color(0xFF04234D)
                                                  : midCases
                                                  ? const Color(0xFF04234D)
                                                  : const Color(0xFF04234D),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ))
                            : Container(
                          height: 120,
                          // Specify a fixed height for the container
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: highCases
                                ? Colors.red
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child:
                          Image.asset("assets/images/icon_red.png"),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
