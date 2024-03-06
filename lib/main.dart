//import 'dart:convert';
import 'dart:io';

//import 'package:aplikasi_sampah/components/drawer.dart';
import 'package:aplikasi_sampah/firebase/auth.dart';
import 'package:aplikasi_sampah/globalVar.dart';
import 'package:aplikasi_sampah/login_register_page.dart';
import 'package:aplikasi_sampah/model/articles_model.dart';

import 'package:aplikasi_sampah/widget_tree.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
//import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:aplikasi_sampah/components/appBar.dart';
import 'package:aplikasi_sampah/components/ProfilePage.dart';

//import 'package:aplikasi_sampah/profile.dart';6
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalVar globalVar = GlobalVar.instance;

  Platform.isAndroid
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
              apiKey: 'AIzaSyBxDijkEkT9meAuvaAPUIcM9NLW0S46O7w',
              appId: '1:525346093175:android:e0136e9c61854d9f0dee72',
              messagingSenderId: '525346093175',
              projectId: 'tra-tour'))
      : await Firebase.initializeApp();

  print('isLoginkkk: ${globalVar.isLogin}');

  

  runApp(MyApp(globalVar: globalVar));
}

class MyApp extends StatelessWidget {
  final GlobalVar globalVar;
  const MyApp({Key? key, required this.globalVar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tra-tour',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WidgetTree(),
    );
  }
}

class HomePage extends StatefulWidget {
  final GlobalVar globalVar;
  HomePage({Key? key, required this.globalVar}) : super(key: key);

  final User? user = Auth().currentUser;

  @override
  State<HomePage> createState() => _HomeState(globalVar: globalVar);
}

class _HomeState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalVar globalVar;
  late final List<GlobalKey<NavigatorState>> navigatorKeys;
  late final List<AnimationController> destinationFaders;
  late final List<Widget> destinationViews;

  final List<Destination> allDestinations = [
    Destination(0, 'Beranda', Icons.home, Colors.blue),
    Destination(1, 'Pesanan', Icons.reorder, Colors.green),
    Destination(2, 'Tambah', Icons.add_circle, Colors.red),
    Destination(3, 'Sosial', Icons.groups, Colors.purple),
    Destination(4, 'Profile', Icons.person, Colors.grey),
    // Add more destinations as needed
  ];

  _HomeState({required this.globalVar});

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        
        String userEmail =
            user.email ?? ""; // Mengambil email pengguna, jika ada
        print("User email firebase: $userEmail");

        LoginPageState loginPageState = LoginPageState();

        // Panggil metode findUserDataFromDB dari objek LoginPageState
        loginPageState.findUserDataFromDB(userEmail);
      }
    });

    navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
      allDestinations.length,
      (int index) => GlobalKey(),
    ).toList();

    destinationFaders = List<AnimationController>.generate(
      allDestinations.length,
      (int index) => buildFaderController(),
    ).toList();
    destinationFaders[globalVar.selectedIndex].value = 1.0;

    final CurveTween tween = CurveTween(curve: Curves.fastOutSlowIn);
    destinationViews = allDestinations.map<Widget>(
      (Destination destination) {
        return FadeTransition(
          opacity: destinationFaders[destination.index].drive(tween),
          child: DestinationView(
            destination: destination,
            navigatorKey: navigatorKeys[destination.index],
          ),
        );
      },
    ).toList();
  }

  AnimationController buildFaderController() {
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    controller.addStatusListener(
      (AnimationStatus status) {
        if (status == AnimationStatus.dismissed) {
          setState(() {}); // Rebuild unselected destinations offstage.
        }
      },
    );
    return controller;
  }

  @override
  void dispose() {
    for (final AnimationController controller in destinationFaders) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPop: () {
        final NavigatorState navigator =
            navigatorKeys[globalVar.selectedIndex].currentState!;
        navigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Stack(
            fit: StackFit.expand,
            children: allDestinations.map(
              (Destination destination) {
                final int index = destination.index;
                final Widget view = destinationViews[index];
                if (index == globalVar.selectedIndex) {
                  destinationFaders[index].forward();
                  return Offstage(offstage: false, child: view);
                } else {
                  destinationFaders[index].reverse();
                  if (destinationFaders[index].isAnimating) {
                    return IgnorePointer(child: view);
                  }
                  return Offstage(child: view);
                }
              },
            ).toList(),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: globalVar.selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              globalVar.selectedIndex = index;
            });
          },
          destinations: allDestinations.map<NavigationDestination>(
            (Destination destination) {
              return NavigationDestination(
                icon: Icon(destination.icon, color: destination.color),
                label: destination.title,
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

class Destination {
  const Destination(this.index, this.title, this.icon, this.color);
  final int index;
  final String title;
  final IconData icon;
  final MaterialColor color;
}

class RootPage extends StatelessWidget {
  const RootPage({Key? key, required this.destination});

  final Destination destination;

  Widget _buildPage(BuildContext context) {
    // Return the appropriate widget based on the destination
    switch (destination.index) {
      case 0:
        return BerandaPage();
      case 1:
        return PesananPage();
      case 2:
        return TambahPage();
      case 3:
        return SosialPage();
      case 4:
        return ProfilePage();
      default:
        return SizedBox(); // Return an empty widget for unknown destinations
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: destination.index != 4 ? MyAppBar() : null,
      backgroundColor: destination.color[50],
      body: _buildPage(context), // Build the appropriate page
    );
  }
}

class BerandaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _getInfo();
    return Scaffold(
      body: ListView(
        children: [
          // Poin kamu
          _poinSection(),

          // Voucher
          _voucherSection(),

          // Artikel Pilihan1
          _artikelPilihan(),

          // Artikel Pilihan2
          _artikelPilihan(),
        ],
      ),
      //bottomNavigationBar: _bottomNavigationBar(),
    );
  }
}

class PesananPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Ini adalah halaman Pesanan'),
    );
  }
}

class SosialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Ini adalah halaman Siasal'),
    );
  }
}

class TambahPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Ini adalah halaman Tambah'),
    );
  }
}

class DestinationView extends StatefulWidget {
  const DestinationView({
    super.key,
    required this.destination,
    required this.navigatorKey,
  });

  final Destination destination;
  final Key navigatorKey;

  @override
  State<DestinationView> createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) {
            switch (settings.name) {
              case '/':
                return RootPage(destination: widget.destination);
              /* case '/list':
                return ListPage(destination: widget.destination);
              case '/text':
                return TextPage(destination: widget.destination); */
            }
            assert(false);
            return const SizedBox();
          },
        );
      },
    );
  }
}

List<ArticlesModel> articles = [];

void _getInfo() {
  articles = ArticlesModel.getArticles();
}

/* @override
Widget build(BuildContext context) {
  _getInfo();
  return Scaffold(
    appBar: MyAppBar(),
    body: ListView(
      children: [
        // Poin kamu
        _poinSection(),

        // Voucher
        _voucherSection(),

        // Artikel Pilihan1
        _artikelPilihan(),

        // Artikel Pilihan2
        _artikelPilihan(),
      ],
    ),
    //bottomNavigationBar: _bottomNavigationBar(),
  );
}
 */
Padding _artikelPilihan() {
  return Padding(
    padding: const EdgeInsets.all(15.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                "Artikel Pilihan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PTSans',
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
              ),
            ],
          ),
        ),
        Container(
          height: 185,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Container(
                width: 152,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                      child: Image.asset(
                        articles[index].articleImage,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            articles[index].title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'PTSans',
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 12,
                              ),
                              Text(
                                articles[index].date,
                                style: TextStyle(fontSize: 8),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            articles[index].description,
                            style: TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => SizedBox(width: 25),
            itemCount: articles.length,
          ),
        ),
      ],
    ),
  );
}

Padding _voucherSection() {
  return Padding(
    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
    child: Container(
      width: 320,
      height: 149,
      decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voucher',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PTSans',
                  ),
                ),
                Text(
                  'Total poin kamu dapat ditukarkan dengan voucher dibawah ini loh!',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'PTSans',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceAround, // Memberikan ruang sekitar setiap child
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.smartphone),
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10.0,
                          fontFamily: 'PTSans',
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Pulsa \n',
                          ),
                          TextSpan(
                            text: 'Prabayar',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.wifi),
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10.0,
                          fontFamily: 'PTSans',
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Paket\n',
                          ),
                          TextSpan(
                            text: 'Data',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.bolt),
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10.0,
                          fontFamily: 'PTSans',
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Voucher \n',
                          ),
                          TextSpan(
                            text: 'Listrik',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.arrow_right_alt),
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10.0,
                          fontFamily: 'PTSans',
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Voucher \n',
                          ),
                          TextSpan(
                            text: 'Lainnya',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Padding _poinSection() {
  GlobalVar globalVar = GlobalVar.instance;

  List<dynamic> userDataList = globalVar.userLoginData;

  // Get user data from the list

  String user_pointLogin = userDataList.isNotEmpty
      ? userDataList[0]['user_point'].toString() ?? 'ERROR CONNECTING TO DB'
      : '';

  return Padding(
    padding: const EdgeInsets.all(15.0),
    child: Container(
      width: 320,
      height: 70,
      decoration: const BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Poin Kamu',
              style: TextStyle(
                fontFamily: 'PTSans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'Total Poin Anda: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'PTSans',
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: user_pointLogin,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'PTSans',
                          ),
                        ),
                        TextSpan(
                          text: ' Poin',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'PTSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // child: Text(
                  //   '10000 Poin',
                  //   style: TextStyle(fontSize: 14),
                  // ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class NavigationBar extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  const NavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      items: destinations.map((destination) {
        return BottomNavigationBarItem(
          icon: destination.icon,
          label: destination.label,
        );
      }).toList(),
    );
  }
}
