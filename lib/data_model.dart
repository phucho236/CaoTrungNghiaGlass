class DataModel {
  DataModel({
    this.maSp,
    this.soLuong,
    this.dai,
    this.rong,
    this.sku,
    this.maDh,
    this.tenKh,
    this.chungLoaiKinh,
    this.dangGiaCong,
    this.ngayDatHang,
  });

  String? maSp;
  int? soLuong;
  int? dai;
  int? rong;
  String? sku;
  String? maDh;
  String? tenKh;
  String? chungLoaiKinh;
  String? dangGiaCong;
  String? ngayDatHang;

  factory DataModel.fromJson(Map<String, dynamic> json) => DataModel(
        maSp: json["ma_sp"],
        soLuong: json["so_luong"],
        dai: json["dai"],
        rong: json["rong"],
        sku: json["sku"],
        maDh: json["ma_dh"],
        tenKh: json["ten_kh"],
        chungLoaiKinh: json["chung_loai_kinh"],
        dangGiaCong: json["dang_gia_cong"],
        ngayDatHang: json["ngay_dat_hang"],
      );

  Map<String, dynamic> toJson() => {
        "ma_sp": maSp,
        "so_luong": soLuong,
        "dai": dai,
        "rong": rong,
        "sku": sku,
        "ma_dh": maDh,
        "ten_kh": tenKh,
        "chung_loai_kinh": chungLoaiKinh,
        "dang_gia_cong": dangGiaCong,
        "ngay_dat_hang": ngayDatHang,
      };
}
