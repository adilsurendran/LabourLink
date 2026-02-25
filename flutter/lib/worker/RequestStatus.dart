import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {

  final Dio dio = Dio();
  List requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ================= FETCH =================

  Future<void> fetchRequests() async {
    try {
      setState(() => isLoading = true);

      final res = await dio.get(
        "$baseurl/api/worker/worker-requests/$ProfileId",
      );

      setState(() {
        requests = res.data["data"];
        isLoading = false;
      });

    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ================= CANCEL =================

  Future<void> cancelRequest(String requestId) async {
    try {
      await dio.delete(
        "$baseurl/api/worker/cancel-request/$requestId",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request Cancelled"),
          backgroundColor: Colors.green,
        ),
      );

      fetchRequests();

    } on DioException catch (e) {
      String message = "Something went wrong";

      if (e.response != null) {
        message = e.response?.data["message"] ?? message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Job Requests"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A00E0),
                  Color(0xFF8E2DE2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
                top: 100,
                left: 16,
                right: 16),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white),
                  )
                : requests.isEmpty
                    ? const Center(
                        child: Text(
                          "No Requests Found",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: requests.length,
                        itemBuilder:
                            (context, index) {

                          final req = requests[index];
                          final work = req["workId"];
                          final status = req["status"];

                          Color statusColor;

                          switch (status) {
                            case "accepted":
                              statusColor = Colors.green;
                              break;
                            case "rejected":
                              statusColor = Colors.red;
                              break;
                            default:
                              statusColor = Colors.orange;
                          }

                          return Container(
                            margin:
                                const EdgeInsets.only(
                                    bottom: 20),
                            padding:
                                const EdgeInsets.all(20),
                            decoration:
                                BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                      20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.2),
                                  blurRadius: 15,
                                  offset:
                                      const Offset(
                                          0, 8),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Text(
                                      work?["title"] ??
                                          "",
                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                                  horizontal:
                                                      10,
                                                  vertical:
                                                      4),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            statusColor,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    20),
                                      ),
                                      child: Text(
                                        status,
                                        style:
                                            const TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                    height: 8),

                                Text(
                                    work?["description"] ??
                                        ""),

                                const SizedBox(
                                    height: 8),

                                Text(
                                  "📅 ${DateFormat('dd MMM yyyy').format(DateTime.parse(work["date"]))}",
                                ),

                                const SizedBox(
                                    height: 8),

                                Text(
                                  "👤 ${work?["profileId"]?["name"] ?? ""}",
                                ),

                                const SizedBox(
                                    height: 15),

                                if (status ==
                                    "pending")
                                  SizedBox(
                                    width: double
                                        .infinity,
                                    child:
                                        ElevatedButton(
                                      style:
                                          ElevatedButton
                                              .styleFrom(
                                        backgroundColor:
                                            Colors
                                                .red,
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  14),
                                        ),
                                      ),
                                      onPressed:
                                          () =>
                                              cancelRequest(
                                                  req["_id"]),
                                      child:
                                          const Text(
                                              "Cancel Request"),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}