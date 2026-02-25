// import 'dart:math';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
// import 'package:intl/intl.dart';
// import 'package:labourlink/user/homepage.dart';
// import 'package:labourlink/worker/Register_worker.dart';
// import 'package:labourlink/worker/homepage2.dart';

// class WorkerJobsPage extends StatefulWidget {
//   const WorkerJobsPage({super.key});

//   @override
//   State<WorkerJobsPage> createState() => _WorkerJobsPageState();
// }

// class _WorkerJobsPageState extends State<WorkerJobsPage> {

//   final Dio dio = Dio();

//   List jobs = [];
//   bool isLoading = true;

//   double workerLat = double.parse(latt);
//   double workerLng = double.parse(lngg);

//   @override
//   void initState() {
//     super.initState();
//     fetchJobs();
//   }

//   // ================= DISTANCE =================

//   double _calculateDistance(
//       double lat1, double lon1, double lat2, double lon2) {

//     const R = 6371;
//     double dLat = _deg2rad(lat2 - lat1);
//     double dLon = _deg2rad(lon2 - lon1);

//     double a =
//         sin(dLat / 2) * sin(dLat / 2) +
//         cos(_deg2rad(lat1)) *
//             cos(_deg2rad(lat2)) *
//             sin(dLon / 2) *
//             sin(dLon / 2);

//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));

//     return R * c;
//   }

//   double _deg2rad(double deg) {
//     return deg * (pi / 180);
//   }

//   double _parseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }

//   // ================= FETCH =================

//   Future<void> fetchJobs() async {
//     try {
//       final res =
//           await dio.get("$baseurl/api/worker/pending-jobs");
//           print(res.data);

//       List data = res.data["data"];

//       for (var job in data) {

//         double userLat =
//             _parseDouble(job["profileId"]?["location"]?["lat"]);

//         double userLng =
//             _parseDouble(job["profileId"]?["location"]?["lng"]);

//         job["distance"] =
//             _calculateDistance(
//                 workerLat,
//                 workerLng,
//                 userLat,
//                 userLng);
//       }

//       data.sort(
//           (a, b) =>
//               a["distance"]
//                   .compareTo(b["distance"]));

//       setState(() {
//         jobs = data;
//         isLoading = false;
//       });

//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }

//   // ================= UI =================

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: const Text("Nearby Jobs"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Stack(
//         children: [

//           // Gradient Background
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF4A00E0),
//                   Color(0xFF8E2DE2)
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),

//           Padding(
//             padding: const EdgeInsets.only(
//                 top: 100,
//                 left: 16,
//                 right: 16),
//             child: isLoading
//                 ? const Center(
//                     child:
//                         CircularProgressIndicator(
//                             color:
//                                 Colors.white),
//                   )
//                 : jobs.isEmpty
//                     ? const Center(
//                         child: Text(
//                           "No Nearby Jobs",
//                           style: TextStyle(
//                               color:
//                                   Colors.white,
//                               fontSize: 16),
//                         ),
//                       )
//                     : ListView.builder(
//                         itemCount: jobs.length,
//                         itemBuilder:
//                             (context, index) {

//                           final job =
//                               jobs[index];

//                           return Container(
//                             margin:
//                                 const EdgeInsets
//                                     .only(
//                                         bottom:
//                                             20),
//                             padding:
//                                 const EdgeInsets
//                                     .all(18),
//                             decoration:
//                                 BoxDecoration(
//                               color: Colors
//                                   .white
//                                   .withOpacity(
//                                       0.95),
//                               borderRadius:
//                                   BorderRadius
//                                       .circular(
//                                           20),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors
//                                       .black
//                                       .withOpacity(
//                                           0.2),
//                                   blurRadius:
//                                       15,
//                                   offset:
//                                       const Offset(
//                                           0,
//                                           8),
//                                 )
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment:
//                                   CrossAxisAlignment
//                                       .start,
//                               children: [

//                                 Text(
//                                   job["title"],
//                                   style:
//                                       const TextStyle(
//                                     fontSize:
//                                         18,
//                                     fontWeight:
//                                         FontWeight
//                                             .bold,
//                                   ),
//                                 ),

//                                 const SizedBox(
//                                     height:
//                                         8),

//                                 Text(job[
//                                     "description"]),

//                                 const SizedBox(
//                                     height:
//                                         8),

//                                 Text(
//                                     "👤 ${job["profileId"]?["name"] ?? ""}"),

//                                 const SizedBox(
//                                     height:
//                                         6),

//                                 Text(
//                                     "📍 ${job["profileId"]?["place"] ?? ""}"),

//                                 const SizedBox(
//                                     height:
//                                         6),

//                                 Text(
//                                   "📅 ${DateFormat('dd MMM yyyy').format(DateTime.parse(job["date"]))}",
//                                 ),

//                                 const SizedBox(
//                                     height:
//                                         6),

//                                 Text(
//                                   "📏 ${job["distance"].toStringAsFixed(2)} km away",
//                                   style:
//                                       const TextStyle(
//                                     fontWeight:
//                                         FontWeight
//                                             .bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';
import 'package:labourlink/worker/homepage2.dart';

class WorkerJobsPage extends StatefulWidget {
  const WorkerJobsPage({super.key});

  @override
  State<WorkerJobsPage> createState() => _WorkerJobsPageState();
}

class _WorkerJobsPageState extends State<WorkerJobsPage> {

  final Dio dio = Dio();

  List jobs = [];
  bool isLoading = true;

  late double workerLat;
  late double workerLng;

  @override
  void initState() {
    super.initState();

    workerLat = _safeParse(latt);
    workerLng = _safeParse(lngg);

    fetchJobs();
  }

  // ================= SAFE PARSE =================

  double _safeParse(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ================= DISTANCE =================

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {

    const R = 6371;

    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  // ================= FETCH JOBS =================

  Future<void> fetchJobs() async {
    try {
      setState(() => isLoading = true);

      final res =
          await dio.get("$baseurl/api/worker/pending-jobs");

      List data = res.data["data"];

      for (var job in data) {

        double userLat =
            _safeParse(job["profileId"]?["location"]?["lat"]);

        double userLng =
            _safeParse(job["profileId"]?["location"]?["lng"]);

        job["distance"] =
            _calculateDistance(
                workerLat,
                workerLng,
                userLat,
                userLng);
      }

      data.sort((a, b) =>
          a["distance"].compareTo(b["distance"]));

      setState(() {
        jobs = data;
        isLoading = false;
      });

    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ================= REQUEST JOB =================
Future<void> requestJob(String workId) async {
  try {
    final res = await dio.post(
      "$baseurl/api/worker/request-job",
      data: {
        "workId": workId,
        "workerId": ProfileId,
      },
    );

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request submitted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      fetchJobs();
    }

  } on DioException catch (e) {

    String message = "Something went wrong";

    if (e.response != null) {
      final status = e.response?.statusCode;

      if (status == 400) {
        message = e.response?.data["message"] ?? "Invalid request";
      } 
      else if (status == 404) {
        message = "Job not found";
      } 
      else if (status == 500) {
        message = "Server error. Try again.";
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Unexpected error occurred"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Future<void> requestJob(String workId) async {
  //   try {
  //     await dio.post(
  //       "$baseurl/api/worker/request-job",
  //       data: {
  //         "workId": workId,
  //         "workerId": ProfileId,
  //       },
  //     );

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Request Sent Successfully"),
  //         backgroundColor: Colors.green,
  //       ),
  //     );

  //     fetchJobs();

  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Already Requested or Error"),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Nearby Jobs"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [

          // Gradient Background
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
                : RefreshIndicator(
                    onRefresh: fetchJobs,
                    child: jobs.isEmpty
                        ? const Center(
                            child: Text(
                              "No Nearby Jobs",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: jobs.length,
                            itemBuilder:
                                (context, index) {

                              final job =
                                  jobs[index];

                              return Container(
                                margin:
                                    const EdgeInsets
                                        .only(
                                            bottom:
                                                20),
                                padding:
                                    const EdgeInsets
                                        .all(20),
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .white
                                      .withOpacity(
                                          0.95),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withOpacity(
                                              0.2),
                                      blurRadius:
                                          15,
                                      offset:
                                          const Offset(
                                              0,
                                              8),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    Text(
                                      job["title"],
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            8),

                                    Text(job[
                                        "description"]),

                                    const SizedBox(
                                        height:
                                            10),

                                    Row(
                                      children: [
                                        const Icon(
                                            Icons
                                                .person,
                                            size:
                                                18),
                                        const SizedBox(
                                            width:
                                                6),
                                        Text(job[
                                                "profileId"]?[
                                            "name"] ??
                                            ""),
                                      ],
                                    ),

                                    const SizedBox(
                                        height:
                                            6),

                                    Row(
                                      children: [
                                        const Icon(
                                            Icons
                                                .location_on,
                                            size:
                                                18),
                                        const SizedBox(
                                            width:
                                                6),
                                        Text(job[
                                                "profileId"]?[
                                            "place"] ??
                                            ""),
                                      ],
                                    ),

                                    const SizedBox(
                                        height:
                                            6),

                                    Row(
                                      children: [
                                        const Icon(
                                            Icons
                                                .calendar_today,
                                            size:
                                                18),
                                        const SizedBox(
                                            width:
                                                6),
                                        Text(
                                          DateFormat(
                                                  'dd MMM yyyy')
                                              .format(
                                            DateTime
                                                .parse(
                                                    job["date"]),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                        height:
                                            8),

                                    Text(
                                      "📏 ${job["distance"].toStringAsFixed(2)} km away",
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            15),

                                    SizedBox(
                                      width:
                                          double
                                              .infinity,
                                      child:
                                          ElevatedButton(
                                        style:
                                            ElevatedButton
                                                .styleFrom(
                                          backgroundColor:
                                              Colors
                                                  .indigo,
                                                  foregroundColor: Colors.white,
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    14),
                                          ),
                                        ),
                                        onPressed:
                                            () =>
                                                requestJob(
                                                    job["_id"]),
                                        child:
                                            const Text(
                                                "Request Job"),
                                            
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}