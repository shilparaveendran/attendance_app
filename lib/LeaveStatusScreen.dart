import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LeaveStatusScreen extends StatefulWidget {
  const LeaveStatusScreen({super.key});

  @override
  _LeaveStatusScreenState createState() => _LeaveStatusScreenState();
}

class _LeaveStatusScreenState extends State<LeaveStatusScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Leave Status"),
        backgroundColor: Colors.purple[50],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Your Leave Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('leave_requests')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey, size: 80),
                          SizedBox(height: 20),
                          Text(
                            "No leave requests found.",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var request = snapshot.data!.docs[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text("Reason: ${request['reason']}"),
                          subtitle: Text(
                            "From: ${DateFormat('dd-MM-yyyy').format(request['startDate'].toDate())} "
                                "To: ${DateFormat('dd-MM-yyyy').format(request['endDate'].toDate())}",
                          ),
                          trailing: Icon(
                            request['status'] == 'approved'
                                ? Icons.check_circle
                                : request['status'] == 'rejected'
                                ? Icons.cancel
                                : Icons.hourglass_top,
                            color: request['status'] == 'approved'
                                ? Colors.green
                                : request['status'] == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
