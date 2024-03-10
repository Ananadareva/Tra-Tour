import 'dart:ui';

import 'package:flutter/material.dart';

class GlobalVar {
  // Buat instance static dari GlobalVar
  static final GlobalVar _instance = GlobalVar._internal();

  static const mainColor = Color.fromRGBO(29, 121, 72, 1.0);

  static const baseColor = Color.fromRGBO(240, 240, 240, 1.0);

// from login
  dynamic _userLoginData;

  var _userLoginPostsData;
  bool _isLogin = false;

  bool _isLoading = false;

  int _selectedIndex;

  // Getter setter
  int get selectedIndex => _selectedIndex;

  get mysql => null;
  set selectedIndex(int value) {
    _selectedIndex = value;
  }

  ////////////////////
  dynamic get userLoginData => _userLoginData;

  dynamic get userLoginPostsData => _userLoginPostsData;
  bool get isLogin => _isLogin;
  bool get isLoading => _isLoading;

  set userLoginData(dynamic value) {
    _userLoginData = value;
  }

  set userLoginPostsData(dynamic value) {
    _userLoginPostsData = value;
  }

  set isLogin(bool value) {
    _isLogin = value;
  }

  set isLoading(bool value) {
    _isLoading = value;
  }

  // Private constructor untuk Singleton
  GlobalVar._internal() : _selectedIndex = 0;

  // Getter untuk instance GlobalVar
  static GlobalVar get instance => _instance;
}
