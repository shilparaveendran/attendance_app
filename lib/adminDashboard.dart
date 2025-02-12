import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Admin Dashboard",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.purple[100], // Light Purple Color
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.purple,
            tabs: [
              Tab(text: "Attendance"),
              Tab(text: "Leave Requests"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EmployeeAttendanceTab(),
            LeaveRequestsTab(),
          ],
        ),
      ),
    );
  }
}

class EmployeeAttendanceTab extends StatelessWidget {
  const EmployeeAttendanceTab({super.key});

  Future<String> _getUserName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown';
  }

  Widget shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            color: Colors.white,
          ),
          title: Container(
            height: 15,
            width: 100,
            color: Colors.white,
          ),
          subtitle: Container(
            height: 15,
            width: 150,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => shimmerPlaceholder(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No attendance data available."));
          }
          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data();
              return FutureBuilder<String>(
                future: _getUserName(data['userId']),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return shimmerPlaceholder();
                  }
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(
                        "${userSnapshot.data} (ID: ${data['userId']})",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Checked in at: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(data['checkInTime'].toDate())}",
                      ),
                      trailing: Text(
                        data['location'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: data['location'] == "Office" ? Colors.green : Colors.red,
                        ),
                      ),
                      leading: const Icon(Icons.access_time, color: Colors.purple),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


class LeaveRequestsTab extends StatelessWidget {
  const LeaveRequestsTab({super.key});

  Future<String> _getUserName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown';
  }

  void updateLeaveStatus(String docId, String status) {
    FirebaseFirestore.instance.collection('leave_requests').doc(docId).update({
      'status': status,
    });
  }

  Widget shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            color: Colors.white,
          ),
          title: Container(
            height: 15,
            width: 100,
            color: Colors.white,
          ),
          subtitle: Container(
            height: 15,
            width: 150,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('leave_requests').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => shimmerPlaceholder(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No leave requests found."));
          }
          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data();
              return FutureBuilder<String>(
                future: _getUserName(data['userId']),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return shimmerPlaceholder();
                  }
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(
                        "${userSnapshot.data} (ID: ${data['userId']})",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Reason: ${data['reason']}"),
                          Text("From: ${data['startDate'].toDate()}"),
                          Text("To: ${data['endDate'].toDate()}"),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: data['status'] == 'pending'
                                  ? Colors.orange[100]
                                  : data['status'] == 'approved'
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data['status'].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: data['status'] == 'pending'
                                    ? Colors.orange[800]
                                    : data['status'] == 'approved'
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: data['status'] == 'pending'
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {
                              updateLeaveStatus(docs[index].id, 'approved');
                            },
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              updateLeaveStatus(docs[index].id, 'rejected');
                            },
                            tooltip: 'Reject',
                          ),
                        ],
                      )
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

