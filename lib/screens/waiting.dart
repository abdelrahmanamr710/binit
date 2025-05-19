import 'package:flutter/material.dart';
import 'package:binit/screens/recyclingCompany_homescreen.dart';

class Waiting extends StatefulWidget {
  final String? offerId;
  const Waiting({super.key, this.offerId});
  @override
  WaitingState createState() => WaitingState();
}

class WaitingState extends State<Waiting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: const Color(0xFFFFFFFF),
                  width: double.infinity,
                  height: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 37, right: 37),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 121, bottom: 76),
                            width: 188,
                            height: 246,
                            child: Image.asset(
                              "assets/png/waiting.png",
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 114, left: 6, right: 6),
                          width: double.infinity,
                          child: const Text(
                            "Customer is \nWaiting for You\nat Stated Time",
                            style: TextStyle(
                              color: Color(0xFF035956),
                              fontSize: 35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            // Explicitly pass back the offerId to trigger the slide-out animation
                            if (widget.offerId != null) {
                              Navigator.pop(context, widget.offerId);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: IntrinsicHeight(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  begin: Alignment(-1, -1),
                                  end: Alignment(-1, 1),
                                  colors: [
                                    Color(0xFF184D47),
                                    Color(0xFF184D47),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              margin: const EdgeInsets.only(bottom: 111),
                              width: double.infinity,
                              child: const Column(
                                children: [
                                  Text(
                                    "Return To Homepage",
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
