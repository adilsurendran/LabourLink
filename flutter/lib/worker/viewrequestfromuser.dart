import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class WorkerRequestPage extends StatefulWidget {
  const WorkerRequestPage({super.key});

  @override
  State<WorkerRequestPage> createState() => _WorkerRequestPageState();
}

class _WorkerRequestPageState extends State<WorkerRequestPage> {
  final Dio dio = Dio();

  List requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final response = await dio.get(
        "$baseurl/api/worker/getrequest/$ProfileId",
      );

      setState(() {
        requests = response.data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateStatus(String requestId, String status) async {
    try {
      await dio.put(
        "$baseurl/api/worker/update-status/$requestId",
        data: {"status": status},
      );

      fetchRequests();
    } catch (e) {
      print(e);
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "User Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(child: Text("No Requests Found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request["userId"]?["name"] ?? "User",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("Date: ${request["date"]}"),
                          Text("Time: ${request["startTime"]}"),
                          Text("Job Type: ${request["jobType"]}"),
                          Text("Place: ${request["place"]}"),
                          const SizedBox(height: 8),
                          if (request["description"] != null)
                            Text("Description: ${request["description"]}"),
                          const SizedBox(height: 12),

                          // STATUS OR BUTTONS
                          if (request["status"] == "pending")
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () {
                                      updateStatus(
                                        request["_id"],
                                        "accepted",
                                      );
                                    },
                                    child: const Text("Accept"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      updateStatus(
                                        request["_id"],
                                        "rejected",
                                      );
                                    },
                                    child: const Text("Reject"),
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(
                                        request["status"])
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                request["status"],
                                style: TextStyle(
                                  color: getStatusColor(
                                      request["status"]),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}