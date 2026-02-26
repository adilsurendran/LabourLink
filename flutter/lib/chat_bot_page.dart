import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({Key? key}) : super(key: key);

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);
  final Color _bgColor = const Color(0xFFF8FAFF);

  // 🔐 Replace with your OpenRouter API key
  final String apiKey =
      "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";

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.isEmpty || isLoading) return;

    setState(() {
      messages.add({"role": "user", "content": userMessage});
      isLoading = true;
    });

    _controller.clear();
    scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": messages
              .map((m) => {"role": m["role"], "content": m["content"]})
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String botReply = data["choices"][0]["message"]["content"];

        setState(() {
          messages.add({"role": "assistant", "content": botReply});
        });
      } else {
        setState(() {
          messages.add({
            "role": "assistant",
            "content":
                "I'm having trouble connecting right now. Please try again later.",
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "assistant",
          "content": "Something went wrong. Please check your connection.",
        });
      });
    }

    setState(() {
      isLoading = false;
    });

    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget buildMessage(Map<String, String> message, int index) {
    bool isUser = message["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child:
          Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUser ? null : Colors.white,
                  gradient: isUser
                      ? LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 0),
                    bottomRight: Radius.circular(isUser ? 0 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message["content"] ?? "",
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),
              )
              .animate()
              .fade(duration: 400.ms)
              .slideX(begin: isUser ? 0.2 : -0.2, end: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          "LabourLink AI",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: messages.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return buildMessage(messages[index], index);
              },
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Typing",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade().scale(alignment: Alignment.bottomLeft),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _primaryColor.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !isLoading,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: "Type your message...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
                  onTap: isLoading
                      ? null
                      : () => sendMessage(_controller.text.trim()),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isLoading
                          ? null
                          : LinearGradient(
                              colors: [_primaryColor, _secondaryColor],
                            ),
                      color: isLoading ? Colors.grey.shade300 : null,
                      shape: BoxShape.circle,
                      boxShadow: isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
                .animate(target: isLoading ? 0 : 1)
                .scale(duration: 200.ms, begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }
}
