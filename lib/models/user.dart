class User {
  final int maNguoiDung;
  final String username;
  final String loaiNguoiDung;
  final String hoTen;

  User({
    required this.maNguoiDung,
    required this.username,
    required this.loaiNguoiDung,
    required this.hoTen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      maNguoiDung: json['ma_nguoi_dung'] ?? json['maNguoiDung'] ?? 0,
      username: json['username'] ?? '',
      loaiNguoiDung: json['loai_nguoi_dung'] ?? json['loaiNguoiDung'] ?? '',
      hoTen: json['ho_ten'] ?? json['hoTen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_nguoi_dung': maNguoiDung,
      'username': username,
      'loai_nguoi_dung': loaiNguoiDung,
      'ho_ten': hoTen,
    };
  }
}




















