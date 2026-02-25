import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class SendFeedbackPageofWorker extends StatefulWidget {


  const SendFeedbackPageofWorker({super.key});

  @override
  State<SendFeedbackPageofWorker> createState() =>
      _SendFeedbackPageofWorkerState();
}

class _SendFeedbackPageofWorkerState
    extends State<SendFeedbackPageofWorker> {

  final Dio dio = Dio();
  final TextEditingController controller =
      TextEditingController();

  bool isLoading = false;

  Future<void> sendFeedback() async {

    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feedback cannot be empty"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {

      Map<String, dynamic> data = {
        "feedback": controller.text.trim(),
        "workerId":ProfileId
      };

      await dio.post(
        "$baseurl/api/admin/send",
        data: data,
      );

      controller.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feedback Sent Successfully"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Send Feedback"),
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
                top: 120, left: 20, right: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius:
                    BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Your Feedback",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration:
                        InputDecoration(
                      hintText:
                          "Write your feedback here...",
                      filled: true,
                      fillColor:
                          Colors.grey[100],
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(12),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : sendFeedback,
                      style:
                          ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets
                                .symmetric(
                                    vertical: 14),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Submit Feedback",
                            ),
                    ),
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