class RegisterRequest {
  final String maDangNhap;
  final String hoTen;
  final String email;
  final String dienThoai;
  final String ngaySinh;
  final String gioiTinh;
  final String diaChi;
  final String password;
  final int maLoai;

  RegisterRequest({
    required this.maDangNhap,
    required this.hoTen,
    required this.email,
    required this.dienThoai,
    required this.ngaySinh,
    required this.gioiTinh,
    required this.diaChi,
    required this.password,
    required this.maLoai,
  });

  Map<String, dynamic> toJson() {
    return {
      'ma_dang_nhap': maDangNhap,
      'ho_ten': hoTen,
      'email': email,
      'dien_thoai': dienThoai,
      'ngay_sinh': ngaySinh,
      'gioi_tinh': gioiTinh,
      'dia_chi': diaChi,
      'password': password,
      'ma_loai': maLoai,
    };
  }
}




















