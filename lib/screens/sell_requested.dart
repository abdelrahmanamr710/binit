import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_homescreen.dart';
import 'package:binit/models/user_model.dart'; // Import UserModel

class SellDone extends StatefulWidget {
  final String userName;
  final UserModel? user;

  const SellDone({super.key, required this.userName, required this.user});
@override
SellDoneState createState() => SellDoneState();
}

class SellDoneState extends State<SellDone> {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 59),
                          height: 524,
                          width: double.infinity,
                          child: Image.asset(
                            "assets/png/SellDone.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 58, left: 37, right: 37),
                          width: double.infinity,
                          child: const Text(
                            "Sell Request \nSent",
                            style: TextStyle(
                              color: Color(0xFF035956),
                              fontSize: 35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 69, left: 37, right: 37),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BinOwnerHomeScreen(
                                    userName: widget.userName,  // Pass the userName
                                    user: widget.user,        // Pass the user object
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Ink(
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
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  "Return To Homepage",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

