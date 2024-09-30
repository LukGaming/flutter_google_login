import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sso_test/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/user.birthday.read', // Scope for accessing the birthday
      'https://www.googleapis.com/auth/user.phonenumbers.read',
      'https://www.googleapis.com/auth/user.addresses.read',
      'https://www.googleapis.com/auth/user.gender.read',
    ],
  );

  UserProfile? _userProfile;

  void _signInWithGoogle() async {
    try {
      final googleSSO = await _googleSignIn.signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleSSO?.authentication;

      if (googleAuth != null) {
        final userProfile = await getUserProfile(googleAuth.accessToken!);
        _userProfile = userProfile;
        setState(() {});
      }
    } catch (e) {
      print("SSO error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SSO"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text("login com google"),
            ),
            const SizedBox(height: 20),
            _userProfile != null
                ? UserProfileDisplay(userProfile: _userProfile!)
                : const Text(
                    "faça login com google para mostrar as informações do usuário"),
          ],
        ),
      ),
    );
  }
}

// Exibe as informações do usuário após o login
class UserProfileDisplay extends StatelessWidget {
  final UserProfile userProfile;

  const UserProfileDisplay({Key? key, required this.userProfile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name: ${userProfile.displayName ?? "N/A"}'),
        Text('Email: ${userProfile.email ?? "N/A"}'),
        Text('Phone Number: ${userProfile.phoneNumber ?? "N/A"}'),
        Text('Birthday: ${userProfile.birthday ?? "N/A"}'),
        Text('Address: ${userProfile.address ?? "N/A"}'),
        Text('Gender: ${userProfile.gender ?? "N/A"}'),
        userProfile.photoUrl != null
            ? Image.network(userProfile.photoUrl!)
            : const SizedBox.shrink(),
      ],
    );
  }
}

// Função que busca o perfil completo do usuário
Future<UserProfile?> getUserProfile(String accessToken) async {
  final response = await http.get(
    Uri.parse(
        'https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,phoneNumbers,birthdays,addresses,genders,photos'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic>? names = data['names'];
    final List<dynamic>? emails = data['emailAddresses'];
    final List<dynamic>? phoneNumbers = data['phoneNumbers'];
    final List<dynamic>? birthdays = data['birthdays'];
    final List<dynamic>? addresses = data['addresses'];
    final List<dynamic>? genders = data['genders'];
    final List<dynamic>? photos = data['photos'];

    return UserProfile(
      displayName:
          names != null && names.isNotEmpty ? names[0]['displayName'] : null,
      email: emails != null && emails.isNotEmpty ? emails[0]['value'] : null,
      phoneNumber: phoneNumbers != null && phoneNumbers.isNotEmpty
          ? phoneNumbers[0]['value']
          : null,
      birthday: birthdays != null && birthdays.isNotEmpty
          ? "${birthdays[0]['date']['day']}/${birthdays[0]['date']['month']}/${birthdays[0]['date']['year']}"
          : null,
      address: addresses != null && addresses.isNotEmpty
          ? addresses[0]['formattedValue']
          : null,
      gender: genders != null && genders.isNotEmpty
          ? genders[0]['formattedValue']
          : null,
      photoUrl: photos != null && photos.isNotEmpty ? photos[0]['url'] : null,
    );
  } else {
    print('Failed to fetch user profile: ${response.statusCode}');
    return null;
  }
}

class UserProfile {
  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final String? birthday;
  final String? address;
  final String? gender;
  final String? photoUrl;

  UserProfile({
    this.displayName,
    this.email,
    this.phoneNumber,
    this.birthday,
    this.address,
    this.gender,
    this.photoUrl,
  });
}
