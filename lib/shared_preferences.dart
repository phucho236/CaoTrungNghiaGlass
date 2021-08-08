import 'package:shared_preferences/shared_preferences.dart';

class ConfigHTTP {
  ConfigHTTP({this.prefs});
  final SharedPreferences? prefs;
  String keyConfigHTTP = " keyConfigHTTP";
  void setBaseAPI(String api) async {
    await prefs!.setString(keyConfigHTTP, api);
  }

  Future getBaseAPI() async {
    return prefs!.getString(keyConfigHTTP) ?? "";
  }
}
