import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // for utf8.encode

class HashCollisionTesting extends StatefulWidget {
  const HashCollisionTesting({super.key});

  @override
  _HashCollisionTestingState createState() => _HashCollisionTestingState();
}

class _HashCollisionTestingState extends State<HashCollisionTesting> {
  List<String> inputs = [
    "aB3@cD1#",
    "Zx9!Kp2*",
    "Qw4&Er7%",
    "Tg6^Uh8(",
    "Ij0*Yl9)",
    "Mn3&Pq1\$",
    "Wx2@St5#",
    "Zv7!Lu4*",
    "Aa9&Xr6%",
    "Cc5^Vf8(",
    "Gg0*Bd9)",
    "Hh3&Pj1\$",
    "Jj2@Km5#",
    "Kk7!Ln4*",
    "Ll9&Op6%",
    "Mm5^Qr8(",
    "Nn0*St9)",
    "Oo3&Uv1\$",
    "Pp2@Wx5#",
    "Qq7!Yz4*",
    "Rr9&Ab6%",
    "Ss5^Cd8(",
    "Tt0*Ef9)",
    "Uu3&Gh1\$",
    "Vv2@Ij5#",
    "Ww7!Kl4*",
    "Xx9&Mn6%",
    "Yy5^Op8(",
    "Zz0*Qr9)",
    "aA3&St1\$",
    "bB2@Uv5#",
    "cC7!Wx4*",
    "dD9&Yz6%",
    "eE5^Ab8(",
    "fF0*Cd9)",
    "gG3&Ef1\$",
    "hH2@Gh5#",
    "iI7!Ij4*",
    "jJ9&Kl6%",
    "kK5^Mn8(",
    "lL0*Op9)",
    "mM3&Qr1\$",
    "nN2@St5#",
    "oO7!Uv4*",
    "pP9&Wx6%",
    "qQ5^Yz8(",
    "rR0*Ab9)",
    "sS3&Cd1\$",
    "tT2@Ef5#",
    "uU7!Gh4*",
    "vV9&Ij6%",
    "wW5^Kl8(",
    "xX0*Mn9)",
    "yY3&Op1\$",
    "zZ2@Qr5#",
    "A1a!St4*",
    "B2b#Uv6%",
    "C3c@Wx8(",
    "D4d\$Yz9)",
    "E5e%Ab1\$",
    "F6f^Cd3#",
    "G7g&Ef5*",
    "H8h*Gh7%",
    "I9i^Ij9(",
    "J0j@Kl1)",
    "K1k#Mn3\$",
    "L2l@Op5#",
    "M3m!Qr7*",
    "N4n&St9%",
    "O5o*Uv1(",
    "P6p^Wx3)",
    "Q7q@Yz5\$",
    "R8r#Ab7#",
    "S9s!Cd9*",
    "T0t\$Ef2%",
    "U1u%Gh4(",
    "V2v^Ij6)",
    "W3w&Kl8\$",
    "X4x*Mn0#",
    "Y5y@Op2*",
    "Z6z!Qr4%",
    "a7A^St6(",
    "b8B*Uv8)",
    "c9C@Wx0\$",
    "d0D#Yz2#",
    "e1E!Ab4*",
    "f2F\$Cd6%",
    "g3G%Ef8(",
    "h4H^Gh0)",
    "i5I&Ij2\$",
    "j6J*Kl4#",
    "k7K@Mn6*",
    "l8L!Op8%",
    "m9M^Qr0(",
    "n0N*St2)",
    "o1O@Uv4\$",
    "p2P#Wx6#",
    "q3Q!Yz8*",
    "r4R\$Ab0%",
    "s5S%Cd2("
  ];


  Map<String, String> hashMap = {};
  String result = '';
  int index = 0;

  @override
  void initState() {
    super.initState();
    performHashCollisionTesting();
  }

  void performHashCollisionTesting() {
    for (var input in inputs) {
      index++;
      String hash = generateSha256(input);
      print("String: $input. Hash: $hash");
      if (hashMap.containsKey(hash)) {
        setState(() {
          result += 'Collision detected: ${hashMap[hash]} and $input produce the same hash: $hash\n';
        });
      } else {
        hashMap[hash] = input;
      }
    }
    if (result.isEmpty) {
      print("No collisions for $index strings");
      setState(() {
        result = 'No collisions detected.';
      });
    }
  }

  String generateSha256(String input) {
    var bytes = utf8.encode(input); // data being hashed
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hash Collision Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(result),
        ),
      ),
    );
  }
}
