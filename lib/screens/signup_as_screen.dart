import 'package:flutter/material.dart';
import 'package:binit/screens/login_screen.dart';
import 'package:flutter/services.dart';

class SignUpAs extends StatelessWidget {
  const SignUpAs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFFFFFFFF),
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 80, bottom: 52),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        "assets/png/leftcornergreen.png",
                      ),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 150, left: 20),
                        width: 500,
                        child: const Text(
                          "\nSign Up\n",
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontFamily: 'Roboto Flex',
                            fontSize: 70,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "as",
                          style: TextStyle(
                            color: Color(0xFF00917C),
                            fontSize: 50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 166,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/bin_owner_signup');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF184D47),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "Bin Owner",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 166,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/recycling_company_signup');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF184D47),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 19),
                          ),
                          child: const Text(
                            "Recycling Company",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15

                              ,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Already Have an Account? ",
                        style: TextStyle(
                          color: Color(0xFF141313),
                          fontSize: 15,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'login',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}