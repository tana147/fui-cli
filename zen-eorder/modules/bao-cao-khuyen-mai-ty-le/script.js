function renderDieuKien(item) {
    switch (item.LoaiChuongTrinh) {
        case 1:
            return `Hóa đơn từ ${item.DieuKien_HoaDonTu.toLocaleString("en-us")}→${item.DieuKien_HoaDonDen.toLocaleString("en-us")}`
        case 2:
            return `Quay số trúng thưởng`
        case 3:
            return `Đổi ${item.DiemLaTra} điểm lá trà ZEN`
        default:
            return ""
    }
}
function renderKhuyenMai(item) {
    switch (item.LoaiChuongTrinh) {
        case 1:
            return `Tặng voucher món ${item.KhuyenMai_MaSanPham} - ${item.KhuyenMai_TenSanPham}`
        case 2:
            return `Trúng voucher ${item.KhuyenMai_MaSanPham} - ${item.KhuyenMai_TenSanPham}`
        case 3:
            return `Đổi voucher món ${item.KhuyenMai_MaSanPham} - ${item.KhuyenMai_TenSanPham}`
        default:
            return ""
    }
}