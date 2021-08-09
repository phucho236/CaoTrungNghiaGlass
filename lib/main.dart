import 'dart:convert';
import 'dart:io';
import 'package:caotrungnghiaglass/data_model.dart';
import 'package:caotrungnghiaglass/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  Rx<DataModel?> dataModel = Rx<DataModel?>(null);
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late ConfigHTTP configHTTP;
  var flash = false.obs;
  var isLoading = false.obs;
  var firstRun = true.obs;
  String baseAPI = "http://123.16.55.174:3000/check/product/";
  String idTmp = "";
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
                  _buildQrView(
                    context,
                    (id) async {
                      // lấy mẵ sản phẩm call chổ này

                      if (id != idTmp) {
                        idTmp = id;
                        try {
                          firstRun.value = false;
                          isLoading.value = true;

                          http.Response uriResponse = await http.get(
                            Uri.parse(baseAPI + id),
                          );
                          isLoading.value = false;
                          print(uriResponse.body);
                          dataModel.value = DataModel.fromJson(jsonDecode(uriResponse.body));
                        } catch (e) {
                          dataModel.value = null;
                        }
                      }
                    },
                  ),
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
                () => firstRun.value
                    ? Center(
                        child: Text('Quét mã QR'),
                      )
                    : isLoading.value
                        ? Center(child: CircularProgressIndicator())
                        : dataModel.value != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8, left: 15, right: 15),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Item(
                                        nameField: "Mã SP: ",
                                        data: dataModel.value!.maSp!,
                                      ),
                                      Item(
                                        nameField: "Tên Khách Hàng: ",
                                        data: dataModel.value!.tenKh.toString(),
                                      ),
                                      Item(
                                        nameField: "SKU: ",
                                        data: dataModel.value!.sku!,
                                      ),
                                      Item(
                                        nameField: "Số Lượng: ",
                                        data: dataModel.value!.soLuong.toString(),
                                      ),
                                      Item(
                                        nameField: "Kich thước: ",
                                        data: "${dataModel.value!.dai.toString()}x${dataModel.value!.rong.toString()}",
                                      ),
                                      Item(
                                        nameField: "Mã Đơn Hàng: ",
                                        data: dataModel.value!.maDh.toString(),
                                      ),
                                      Item(
                                        nameField: "Chủng Loại: ",
                                        data: dataModel.value!.chungLoaiKinh.toString(),
                                      ),
                                      Item(
                                        nameField: "Dạng Gia Công: ",
                                        data: dataModel.value!.dangGiaCong.toString(),
                                      ),
                                      Item(
                                        nameField: "Ngày Đặt Hàng: ",
                                        data: dataModel.value!.ngayDatHang!,
                                        paddingBottom: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Center(
                                child: Text('Không tìm thấy dữ liệu'),
                              ),
              ),
            ),
            Text("Cao Trung Nghĩa"),
            Text("Ứng dụng nhận diện sản phẩm"),
            SizedBox(
              height: 5,
            )
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
    this.data = "",
    this.paddingBottom = 5,
    required this.nameField,
    Key? key,
  }) : super(key: key);
  final String data;
  final String nameField;
  final double paddingBottom;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameField,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                data,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(bottom: paddingBottom, top: 5),
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
