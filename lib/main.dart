import 'dart:io';
import 'package:caotrungnghiaglass/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MaterialApp(home: MyHome()));

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QRViewExample();
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late ConfigHTTP configHTTP;
  var flash = false.obs;
  var isLoading = false.obs;
  String baseAPI = "http://113.176.95.141:3000/check/product/";
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    configHTTP = ConfigHTTP(prefs: await SharedPreferences.getInstance());
    var baseAPITmp = await configHTTP.getBaseAPI();
    if (baseAPITmp != "") {
      baseAPI = baseAPITmp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height / 2,
              child: Stack(
                children: [
                  _buildQrView(context, (id) async {
                    // lấy mẵ sản phẩm call chổ này
                    isLoading.value = true;
                    var uriResponse = await http.get(
                      Uri.parse(baseAPI + id),
                    );
                    isLoading.value = false;
                  }),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await controller?.flipCamera();
                          },
                          icon: Icon(
                            Icons.flip_camera_android,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await controller?.toggleFlash();
                            flash.value = await controller!.getFlashStatus() ?? false;
                          },
                          icon: Obx(
                            () => flash.value
                                ? Icon(
                                    Icons.flash_on,
                                    color: Colors.white,
                                  )
                                : Icon(
                                    Icons.flash_off,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            _showMyDialog(context);
                          },
                          icon: Icon(
                            Icons.settings,
                            color: Colors.white,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
                flex: 1,
                child: Obx(
                  () => isLoading.value
                      ? Center(child: CircularProgressIndicator())
                      : result == null
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Item(
                                      nameField: "Mã SP: ",
                                    ),
                                    Item(
                                      nameField: "sku: ",
                                    ),
                                    Item(
                                      nameField: "Số Lượng: ",
                                    ),
                                    Item(
                                      nameField: "Kich thước: ",
                                    ),
                                    Item(
                                      nameField: "Mã Đơn Hàng: ",
                                    ),
                                    Item(
                                      nameField: "Chủng Loại: ",
                                    ),
                                    Item(
                                      nameField: "Dạng Gia Công: ",
                                    ),
                                    Item(
                                      nameField: "Dạng Gia Công: ",
                                    ),
                                    Item(
                                      nameField: "Dạng Gia Công: ",
                                    ),
                                  ],
                                ),
                              ))
                          : Center(
                              child: Text('Scan a code'),
                            ),
                ))
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context, Function(String) callApi) {
    var scanArea =
        (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 150.0 : 300.0;

    void _onQRViewCreated(QRViewController controller) {
      setState(() {
        this.controller = controller;
      });
      controller.scannedDataStream.listen(
        (scanData) {
          callApi(scanData.code);
        },
      );
    }

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _showMyDialog(context) async {
    TextEditingController textApiController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom Base API'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: textApiController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'http://113.176.95.141:3000/check/product/',
                      labelText: 'BaseApi',
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cance'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset'),
              onPressed: () async {
                configHTTP.setBaseAPI("");
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  configHTTP.setBaseAPI(textApiController.text.trim());
                  baseAPI = textApiController.text.trim();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class Item extends StatelessWidget {
  const Item({
    this.data = "adsfas dfghjj jjjjjjjj jjjj jjjjj jjjj jjj jjjjj jjjjjjj jj jjjjjjj jj",
    required this.nameField,
    Key? key,
  }) : super(key: key);
  final String data;
  final String nameField;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    nameField,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                data,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5, top: 5),
          child: Container(
            height: 1,
            color: Colors.grey,
            width: double.infinity,
          ),
        )
      ],
    );
  }
}
