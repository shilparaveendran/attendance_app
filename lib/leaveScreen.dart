import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  _LeaveScreenState createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_startDate == null || _endDate == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('leave_requests').add({
      'userId': user.uid,
      'reason': _reasonController.text,
      'startDate': Timestamp.fromDate(_startDate!),
      'endDate': Timestamp.fromDate(_endDate!),
      'status': 'pending',
    });

    setState(() {
      _isSubmitting = false;
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Leave request submitted!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Request Leave"),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today, color: Colors.black),
                    label: Text(
                      _startDate != null
                          ? DateFormat('dd-MM-yyyy').format(_startDate!)
                          : "Start Date",
                      style: const TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[100],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today, color: Colors.black),
                    label: Text(
                      _endDate != null
                          ? DateFormat('dd-MM-yyyy').format(_endDate!)
                          : "End Date",
                      style: const TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[100],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Leave Reason",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter reason",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : Center(
              child: ElevatedButton(
                onPressed: _submitLeaveRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[200],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.0),
                  child: Text("Submit Request", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
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
                    return const Center(child: Text("No leave requests found."));
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
                                  "To: ${DateFormat('dd-MM-yyyy').format(request['endDate'].toDate())}"),
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
