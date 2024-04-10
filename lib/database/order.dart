import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tratour/globalVar.dart';
import 'package:http/http.dart' as http;

class Order {
  GlobalVar globalVar = GlobalVar.instance;

  Future<bool> addOrderToDatabase(
    String user_id,
    String pickup_id,
    String waste_types,
    String user_coordinate,
    String sweeper_coordinate,
    String address,
    String cost,
    String payment_method,
    String formattedDate,
    String initial_status,
    BuildContext context,
  ) async {
    try {
      String url = 'https://tratour.000webhostapp.com/createOrder.php';

      Map<String, dynamic> newOrderData = {
        'user_id': user_id,
        'pickup_id': pickup_id,
        'waste_types': waste_types,
        'user_coordinate': user_coordinate,
        'sweeper_coordinate': sweeper_coordinate,
        'address': address,
        'cost': cost,
        'payment_method': payment_method,
        'created_at': formattedDate,
        'updated_at': formattedDate,
        'status': initial_status,
      };

      String body = json.encode(newOrderData);

      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Data sent: $body');
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        print('New order added successfully.');
        GlobalVar globalVar = GlobalVar.instance;
        globalVar.currentOrderData = newOrderData;

        String newOrderId = responseData['id'].toString();
        globalVar.currentOrderData['id'] = newOrderId;

        
        print('New order ID: $newOrderId');

        /* 
        ); */

        /*  bool isSweeperOrderFound = false;
        while (!isSweeperOrderFound) {
          isSweeperOrderFound =
              await checkSweeperOrder(globalVar.currentOrderData['id']);
          if (isSweeperOrderFound) {
            print('Sweeper order found.');
          } else {
            print('Failed to find sweeper order. Retrying...');
            await Future.delayed(
                Duration(seconds: 5)); // Delay 5 detik sebelum mencoba lagi
          }
        } */

        // Return true to indicate success
        return true;
      } else {
        print('Failed to create order: ${response.body}');
        print('Response Message: ${responseData['message']}');

        // Return false to indicate failure
        return false;
      }
    } catch (e) {
      // Tangani kesalahan yang terjadi selama proses HTTP request
      print('Error adding order: $e');
      // Lakukan sesuatu jika terjadi kesalahan

      // Return false to indicate failure
      return false;
    }
  }

  Future<bool> checkSweeperOrder(String order_id) async {
    String url = 'https://tratour.000webhostapp.com/checkSweeper.php';

    try {
      // Melakukan HTTP POST request dengan body order_id
      final response =
          await http.post(Uri.parse(url), body: {'order_id': order_id});
      Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // Berhasil mendapatkan respon dari server
        print('Sweeper order found');
        String pickupId = responseData['data']['pickup_id'];
        print('pickup_id: $pickupId');

        //   await findSweeperFromDB(pickupId);

        bool foundSweeper = await findSweeperFromDB(pickupId);

        if (foundSweeper) {
          print('Sweeper berhasil ditemukan!');
          return true; // Return true jika berhasil menemukan sweeper order
        } else {
          print('Gagal menemukan sweeper.');
          return false;
        }
      } else {
        // Gagal mendapatkan data sweeper atau respon dari server
        print('Gagal mendapatkan data sweeper: ${response.statusCode}');
        return false; // Return false jika gagal menemukan sweeper order
      }
    } catch (e) {
      // Terjadi kesalahan saat melakukan permintaan HTTP
      print('Error Find: $e');
      return false; // Return false jika terjadi kesalahan
    }
  }

  Future<bool> findSweeperFromDB(String pickup_id) async {
    String url = 'https://tratour.000webhostapp.com/findSweeper.php';

    try {
      // Melakukan HTTP POST request dengan body pickup_id
      final response =
          await http.post(Uri.parse(url), body: {'pickup_id': pickup_id});

      if (response.statusCode == 200) {
        // Berhasil mendapatkan respon dari server
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          // Jika status success, simpan data pickup ke dalam variabel globalVar
          globalVar.currentPickUpData = responseData['data_pickup'];
          globalVar.currentSweeperData = responseData['user_data'];

          print('pickup_data: ${globalVar.currentPickUpData}');
          print('sweeper_data: ${globalVar.currentSweeperData}');
          return true; // Jika berhasil, kembalikan true
        } else {
          // Jika status bukan success, cetak pesan error dari server
          print('Gagal mendapatkan data sweeper: ${responseData['message']}');
          return false; // Jika gagal, kembalikan false
        }
      } else {
        // Gagal mendapatkan respon dari server
        print('Gagal mendapatkan data sweeper: ${response.statusCode}');
        return false; // Jika gagal, kembalikan false
      }
    } catch (e) {
      // Terjadi kesalahan saat melakukan permintaan HTTP
      print('Error Find: $e');
      return false; // Jika terjadi kesalahan, kembalikan false
    }
  }

  Future<bool> cancelOrderFromDB(String order_id, String status_change) async {
    String url = 'https://tratour.000webhostapp.com/updateStatusOrder.php';

    try {
      // Melakukan HTTP POST request dengan body pickup_id dan status_change
      final response = await http.post(Uri.parse(url), body: {
        'order_id': order_id,
        'status_change': status_change,
      });

      print('order_id: $order_id');
      print('status_change: $status_change');

      if (response.statusCode == 200) {
        // Berhasil mendapatkan respon dari server
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          print('Pesanan berhasil dibatalkan');
          return true; // return true jika pesanan berhasil dibatalkan
        } else {
          // Jika status bukan success, cetak pesan error dari server
          print('Gagal membatalkan pesanan: ${responseData['message']}');
          return false; // return false jika gagal membatalkan pesanan
        }
      } else {
        // Gagal mendapatkan respon dari server
        print('Gagal membatalkan pesanan: ${response.statusCode}');
        return false; // return false jika gagal membatalkan pesanan
      }
    } catch (e) {
      // Terjadi kesalahan saat melakukan permintaan HTTP
      print('Error Cancelling Order: $e');
      return false; // return false jika terjadi kesalahan saat melakukan permintaan HTTP
    }
  }
}
