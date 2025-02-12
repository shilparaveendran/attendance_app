import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'LeaveStatusScreen.dart';
import 'leaveScreen.dart';


class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final String officeWiFiSSID = "Techlogica IT DT Solutions";
  final double officeLat = 37.4219983;
  final double officeLng = -122.084;
  final double geoFenceRadius = 100.0;
  bool _isCheckingIn = false;

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location permissions are permanently denied.');
      }
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _checkIn() async {
    setState(() => _isCheckingIn = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isCheckingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is required for check-in!")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isCheckingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied. Enable them in settings.")),
      );
      return;
    }

    String? wifiSSID;
    try {
      wifiSSID = await WifiInfo().getWifiName();
    } catch (e) {
      wifiSSID = null;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double currentLat = position.latitude;
    double currentLng = position.longitude;

    if (wifiSSID != officeWiFiSSID) {
      setState(() => _isCheckingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-in allowed only on office Wi-Fi!")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('attendance').add({
      'userId': user.uid,
      'checkInTime': Timestamp.now(),
      'location': 'Office',
      'latitude': currentLat,
      'longitude': currentLng
    });

    setState(() => _isCheckingIn = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Checked in at Office (Lat: $currentLat, Lng: $currentLng)")),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Employee Attendance", style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFEDE7F6), // Very light purple
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _isCheckingIn
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
              onTap: _checkIn,
              child: Card(
                color: Colors.purple[200],
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      "Check In",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Check-In History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('attendance')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 80),
                        const SizedBox(height: 20),
                        const Text(
                          "No check-ins found.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data();
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(
                            "Checked in at: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(data['checkInTime'].toDate())}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text("Location: ${data['location']}"),
                          leading: const Icon(Icons.access_time, color: Colors.purple),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveScreen()));
              },
              child: Card(
                color: Colors.purple[100],
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      "Request Leave",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveStatusScreen()));
              },
              child: Card(
                color: Colors.purple[300],
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      "View Leave Status",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
