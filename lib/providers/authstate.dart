import 'package:flutter/material.dart';

class AuthChangeState extends ChangeNotifier{
    bool isLogin;

    AuthChangeState({this.isLogin = true });

    void clickAuth(){
        isLogin = !isLogin;
        notifyListeners();
    }
}