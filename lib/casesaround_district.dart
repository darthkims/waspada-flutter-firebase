import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/navbar.dart';
import 'package:fypppp/profile.dart';
import 'package:fypppp/sos.dart';

class CasesAroundDistrict extends StatefulWidget {
  const CasesAroundDistrict({super.key});

  @override
  State<CasesAroundDistrict> createState() => _CasesAroundDistrictState();
}

class _CasesAroundDistrictState extends State<CasesAroundDistrict> {
  int currentPageIndex = 3;
  Map<String, int> melakaTengahCityCounts = {};
  Map<String, int> jasinCityCounts = {};
  Map<String, int> alorGajahCityCounts = {};
  int melakaTengahCount = 0;
  int jasinCount = 0;
  int alorGajahCount = 0;
  Color cityTitle = Colors.redAccent;
  Color totalCases = Colors.black;
  Color containerCity = Colors.white;

  void onItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1,
                  Animation<double> animation2) {
                return const Home();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
        case 1:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1,
                  Animation<double> animation2) {
                return const SOSPage();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
        case 2:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1,
                  Animation<double> animation2) {
                return const Circles();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
        case 3:
          break;
        case 4:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1,
                  Animation<double> animation2) {
                return const ProfilePage();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
      }
    });
  }

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

  final List<String> melakaTengahCities = [
    'Alai', 'Ayer Molek', 'Bachang', 'Balai Panjang', 'Bandar Melaka', 'Batu Berendam', 'Bertam',
    'Bukit Baru', 'Bukit Katil', 'Bukit Lintang', 'Bukit Piatu', 'Bukit Rambai', 'Cheng', 'Duyong',
    'Kandang', 'Klebang Besar', 'Klebang Kecil', 'Krubong', 'Padang Temu', 'Paya Rumput', 'Peringgit',
    'Pernu', 'Semabok', 'Sungai Udang', 'Tangga Batu', 'Tanjung Kling', 'Tanjong Minyak', 'Telok Mas',
    'Ujong Pasir', 'Hang Tuah Jaya', 'Kota Melaka', 'Pantai Kundor', 'Klebang', 'Pengkalan Batu',
    'Ayer Keroh', 'Kesidang', 'Kota Laksamana', 'Bandar Hilir', 'Malacca City'
  ];


  final List<String> jasinCities = [
    'Air Panas', 'Ayer Molek', 'Bemban', 'Batang Melaka', 'Bukit Senggeh', 'Chabau', 'Chinchin',
    'Chohong', 'Jasin', 'Jus', 'Kesang', 'Merlimau', 'Nyalas', 'Rim', 'Sebatu', 'Selandar',
    'Sempang', 'Semujok', 'Serkam', 'Sungai Rambai', 'Tedong', 'Umbai', 'Asahan'
  ];


  final List<String> alorGajahCities = [
    'Ayer Paabas', 'Ayer Limau', 'Belimbing', 'Beringin', 'Brisu',
    'Durian Tunggal', 'Gadek', 'Kelemak', 'Kemuning', 'Kuala Linggi',
    'Kuala Sungai Baru', 'Lendu', 'Machap', 'Machap Jaya', 'Masjid Tanah',
    'Melaka Pindah', 'Melekek', 'Padang Sebang', 'Parit Melana', 'Pegoh',
    'Pulau Sebang', 'Ramuan Cina Besar', 'Ramuan Cina Kecil', 'Rembia',
    'Sungai Baru Hilir', 'Sungai Baru Tengah', 'Sungai Baru Ulu', 'Sungai Buluh',
    'Sungai Petai', 'Sungai Siput', 'Taboh Naning', 'Tanjung Bidara',
    'Tanjung Rimau', 'Tebong', 'Alor Gajah'
  ];

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('reports').get();

    // Get today's date and date 3 days ago
    DateTime now = DateTime.now();
    DateTime threeDaysAgo = now.subtract(const Duration(days: 300));

    Map<String, int> tempMelakaTengahCityCounts = {};
    Map<String, int> tempJasinCityCounts = {};
    Map<String, int> tempAlorGajahCityCounts = {};

    for (var doc in snapshot.docs) {
      String city = doc['city'];
      Timestamp timestamp = doc['timeStamp'];
      DateTime date = timestamp.toDate();

      // Only consider reports from the last 3 days
      if (date.isAfter(threeDaysAgo)) {
        if (melakaTengahCities.contains(city)) {
          if (!tempMelakaTengahCityCounts.containsKey(city)) {
            tempMelakaTengahCityCounts[city] = 0;
          }
          tempMelakaTengahCityCounts[city] = tempMelakaTengahCityCounts[city]! + 1;
        }

        if (jasinCities.any((item) => city.contains(item))) {
          if (!tempJasinCityCounts.containsKey(city)) {
            tempJasinCityCounts[city] = 0;
          }
          tempJasinCityCounts[city] = tempJasinCityCounts[city]! + 1;
        }

        if (alorGajahCities.contains(city)) {
          if (!tempAlorGajahCityCounts.containsKey(city)) {
            tempAlorGajahCityCounts[city] = 0;
          }
          tempAlorGajahCityCounts[city] = tempAlorGajahCityCounts[city]! + 1;
        }
      }
    }

    setState(() {
      melakaTengahCityCounts = tempMelakaTengahCityCounts;
      jasinCityCounts = tempJasinCityCounts;
      alorGajahCityCounts = tempAlorGajahCityCounts;
    });

    // Print all values for debugging
    print('Melaka Tengah City-wise Case Counts in Last 3 Days:');
    melakaTengahCityCounts.forEach((city, count) {
      melakaTengahCount+=count;
      print('City: $city, Cases: $count');
    });
    print('Total Melaka Tengah cases: $melakaTengahCount');

    print('Jasin City-wise Case Counts in Last 3 Days:');
    jasinCityCounts.forEach((city, count) {
      jasinCount+=count;
      print('City: $city, Cases: $count');
    });
    print('Total Jasin cases: $jasinCount');

    print('Alor Gajah City-wise Case Counts in Last 3 Days:');
    alorGajahCityCounts.forEach((city, count) {
      alorGajahCount+=count;
      print('City: $city, Cases: $count');
    });
    print('Total Alor Gajah cases: $alorGajahCount');
  }

  BarChart buildBarChart(Map<String, int> cityCounts, String title) {
    final cityNames = cityCounts.keys.toList();
    final caseCounts = cityCounts.values.toList();

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black, width: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= cityNames.length) {
                  return const SizedBox(); // Return an empty widget if index is out of range
                }
                final city = cityNames[index];
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    city,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: cityCounts.entries.map((entry) {
          final index = cityCounts.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Colors.redAccent,
                width: 20,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          );
        }).toList(),
        alignment: BarChartAlignment.spaceEvenly,
        maxY: caseCounts.isNotEmpty
            ? caseCounts.reduce((a, b) => a > b ? a : b).toDouble() + 3
            : 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F3F2),
      appBar: AppBar(
        title: const Text('Cases Around',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false,
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                ),
                onPressed: () {
                  _showHelpDialog(context);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.airline_seat_recline_extra_sharp,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CasesAroundDistrict()));
                },
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('reports').get(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else{
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        // Enable horizontal scrolling
                        child: Row(
                          children: [
                            // Chart for Melaka Tengah
                            Container(
                              margin: const EdgeInsets.all(10),
                              padding:
                                  const EdgeInsets.only(top: 10, right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: 200,
                                width: 300, // Adjust width as needed
                                child: buildBarChart(melakaTengahCityCounts,
                                    'Melaka Tengah Cases'),
                              ),
                            ),
                            // Chart for Jasin
                            Container(
                              margin: const EdgeInsets.all(10),
                              padding:
                                  const EdgeInsets.only(top: 10, right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: 200,
                                width: 300, // Adjust width as needed
                                child: buildBarChart(
                                    jasinCityCounts, 'Jasin Cases'),
                              ),
                            ),
                            // Chart for Alor Gajah
                            Container(
                              margin: const EdgeInsets.all(10),
                              padding:
                                  const EdgeInsets.only(top: 10, right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: 200,
                                width: 300, // Adjust width as needed
                                child: buildBarChart(
                                    alorGajahCityCounts, 'Alor Gajah Cases'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 100,
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: containerCity,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                // bottom: 45,
                                right: 0,
                                child: Image.asset(
                                  "assets/images/afamosa.png",
                                  width: 120,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Melaka Tengah',
                                    style: TextStyle(
                                        fontSize: 25,
                                        color: cityTitle,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Total Cases: $melakaTengahCount',
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: totalCases,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 100,
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: containerCity,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                // bottom: 45,
                                right: 0,
                                child: Image.asset(
                                  "assets/images/tengkolok.png",
                                  width: 120,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jasin',
                                    style: TextStyle(
                                        fontSize: 25,
                                        color: cityTitle,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Total Cases: $jasinCount',
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: totalCases,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 100,
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: containerCity,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: 0,
                                child: Image.asset(
                                  "assets/images/keris.png",
                                  width: 100,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alor Gajah',
                                    style: TextStyle(
                                        fontSize: 25,
                                        color: cityTitle,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Total Cases: $alorGajahCount',
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: totalCases,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
      ),
        bottomNavigationBar: CustomNavigationBar(currentPageIndex: currentPageIndex, onItemTapped: onItemTapped)
    );
  }

}
