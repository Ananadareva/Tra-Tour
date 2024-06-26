// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:tratour/database/order.dart';
import 'package:tratour/globalVar.dart';
import 'package:tratour/pages/user/orderProcess.dart';
import 'package:url_launcher/url_launcher.dart';

class PickLocationPage extends StatefulWidget {
  PickLocationPage({Key? key}) : super(key: key);

  @override
  _PickLocationPageState createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  late final TextEditingController _addressOrderController;
  final TextEditingController _controllerPaymentMethod =
      TextEditingController();
  final String initial_status = 'Open';
  final String initial_cost = '';
  final String initial_pickup_id = '';
  final String initial_sweeper_coordinate = '';

  @override
  void initState() {
    super.initState();
    final globalVar = Provider.of<GlobalVar>(context, listen: false);
    _addressOrderController =
        TextEditingController(text: globalVar.userLoginData['address'] ?? '');
  }

  @override
  void dispose() {
    _addressOrderController.dispose();
    _controllerPaymentMethod.dispose();
   // super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalVar globalVar = Provider.of<GlobalVar>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalVar.mainColor,
        title: Text(
          'Pilih Lokasi Penjemputan',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
       
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${globalVar.userLocation}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _getCurrentPosition(context);
                  setState(() {});
                },
                child: Text('Gunakan Lokasimu'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: globalVar.userLocation.isEmpty
                    ? null
                    : () {
                        _openGoogleMaps(context);
                      },
                child: const Text('Periksa Lokasi'),
              ),
              SizedBox(height: 20),
              Text(
                "Alamat Anda",
                style: TextStyle(fontSize: 18),
              ),
              _entyAddress(_addressOrderController),
              SizedBox(height: 20),
              Text(
                "Metode Pembayaran",
                style: TextStyle(fontSize: 18),
              ),
              _entryPaymenMethod(_controllerPaymentMethod),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: Provider.of<GlobalVar>(context)
                            .userLocation
                            .isEmpty ||
                        _controllerPaymentMethod.text.isEmpty
                    ? null
                    : () async {
                        setState(() {
                          globalVar.isLoading = true;
                        });

                        showLoadingScreen(context);
                        Order order = Order();

                        DateTime now = DateTime.now();
                        String formattedDate =
                            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

                        bool success = await order.addOrderToDatabase(
                          globalVar.userLoginData['id'],
                          initial_pickup_id,
                          globalVar.selectedTrashIndexes.join(','),
                          globalVar.userLocation,
                          initial_sweeper_coordinate,
                          _addressOrderController.text,
                          initial_cost,
                          _controllerPaymentMethod.text,
                          formattedDate,
                          initial_status,
                          context,
                        );

                        if (success) {
                          bool isOrderFound = false;
                          String order_id = globalVar.currentOrderData['id'];

                          while (!isOrderFound) {
                            try {
                              isOrderFound =
                                  await order.checkPickUpOrder(order_id);

                              if (isOrderFound) {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderProcess(),
                                  ),
                                );
                                break;
                              } else {
                                print(
                                    'Order tidak ditemukan, melakukan percobaan kembali...');
                                await Future.delayed(Duration(seconds: 5));
                              }
                            } catch (e) {
                              print(
                                  'Terjadi kesalahan saat memeriksa order: $e');
                              break;
                            }
                          }
                        } else {
                          globalVar.isLoading == true
                              ? setState(() {
                                  globalVar.isLoading = false;
                                })
                              : Navigator.of(context).pop();

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Gagal Membuat Pesanan'),
                              content: Text(
                                  'Terjadi kesalahan saat menambahkan pesanan, periksa koneksi internet.'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                child: const Text('Buat Pesanan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryPaymenMethod(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(
            color: Colors.white,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        width: MediaQuery.of(context).size.width -
            50, // Menyesuaikan lebar container
        child: DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                controller.text = newValue;
              });
            }
          },
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Container(
                color: Colors.white,
                child: Text(
                  'Pilih Metode Pembayaran:',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: '1',
              child: Text('Tunai'),
            ),
          ],
          decoration: InputDecoration(
            hintText: 'Pilih Metode Pembayaran',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _entyAddress(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(
            color: Colors.white,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 20),
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(10),
              border: OutlineInputBorder(),
              labelText: 'Alamat',
            ),
            onChanged: (value) {
              // Tidak perlu menyimpan data alamat di sini
            },
          ),
        ),
      ),
    );
  }

  void showLoadingScreen(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Mencegah menutup dialog dengan mengetuk di luar dialog
      builder: (BuildContext context) {
        return LoadingScreen();
      },
    );
  }
}

void showLoadingScreen(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible:
        false, // Mencegah menutup dialog dengan mengetuk di luar dialog
    builder: (BuildContext context) {
      return LoadingScreen();
    },
  );
}

Future<bool> _handlePermission(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("GPS Nonaktif"),
          content: Text("Aktifkan GPS pada perangkat Anda untuk melanjutkan."),
          actions: <Widget>[
            TextButton(
              child: Text("Tutup"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return false;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      Provider.of<GlobalVar>(context, listen: false).userLocation =
          'Izin akses lokasi ditolak.';
      return false;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    Provider.of<GlobalVar>(context, listen: false).userLocation =
        'Izin akses lokasi ditolak selamanya.';
    return false;
  }

  return true;
}

Future<void> _getCurrentPosition(BuildContext context) async {
  bool hasPermission = await _handlePermission(context);

  if (!hasPermission) {
    return;
  }

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double latitude = position.latitude;
    double longitude = position.longitude;

    Provider.of<GlobalVar>(context, listen: false).userLocation =
        '$latitude,$longitude'; // Simpan hanya latitude dan longitude
    print(
        'location:  ${Provider.of<GlobalVar>(context, listen: false).userLocation}');
  } catch (e) {
    Provider.of<GlobalVar>(context, listen: false).userLocation = 'Error: $e';
  }
}

Future<void> _openGoogleMaps(BuildContext context) async {
  String userLocation =
      Provider.of<GlobalVar>(context, listen: false).userLocation;
  List<String> coordinates = userLocation.split(',');
  double latitude = 0.0;
  double longitude = 0.0;

  if (coordinates.length >= 2) {
    latitude = double.parse(coordinates[0]);
    longitude = double.parse(coordinates[1]);
  }

  final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

  if (await launchUrl(googleMapsUrl)) {
    await launchUrl(googleMapsUrl);
  } else {
    throw 'Tidak dapat membuka Google Maps';
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gambar logo
            Image.asset(
              'assets/images/findingSweeperLlogo.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20), // Spasi antara logo dan animasi loading
            // Animasi loading
            LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.orange, // Warna animasi
              size: 75, // Ukuran animasi
            ),
          ],
        ),
      ),
    );
  }
}
