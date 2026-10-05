function CT_TongTienHoaDon(order) {
    let tongtienhoadon = 0
    order.forEach((hd) => {
        if (hd.Is_KhuyenMai === 1) {
            tongtienhoadon += 0
        } else {
            tongtienhoadon += hd.SoLuong * hd.GiaBan_CuaHang
        }
        //Tính tiền Topping
        hd.ThuocTinh?.forEach((tt) => {
            tongtienhoadon += tt.SoLuong * tt.GiaBan_CuaHang
        })
    })
    return tongtienhoadon
}
function CT_TongZEN(order) {
    let tongzen = 0
    order.forEach((hd) => {
        if (hd.Is_ThanhToanZen === 1 && hd.Is_KhuyenMai === 0) {
            tongzen += hd.SoLuong * hd.GiaBan_CuaHang + (hd.TienVAT_CuaHang_SanPham ?? 0)
            //Tính tiền Topping
            hd.ThuocTinh?.forEach((tt) => {
                if (tt.Is_ThanhToanZen === 1) {
                    tongzen += tt.SoLuong * tt.GiaBan_CuaHang + (tt.TienVAT_CuaHang_SanPham ?? 0)
                } else {
                    tongzen += 0
                }
            })
        } else {
            //Tính tiền Topping
            hd.ThuocTinh?.forEach((tt) => {
                if (tt.Is_ThanhToanZen === 1) {
                    tongzen += tt.SoLuong * tt.GiaBan_CuaHang + (tt.TienVAT_CuaHang_SanPham ?? 0)
                } else {
                    tongzen += 0
                }
            })
        }
    })
    return tongzen
}
function CT_KhachPhaiTra(TongTienHoaDon, TongVAT, TongZEN, GiaoHang_Phi) {
    let khachphaitra = 0
    khachphaitra = TongTienHoaDon + TongVAT - TongZEN + parseInt(GiaoHang_Phi ?? 0)
    return khachphaitra
}
function CT_TongTienHinhThucThanhToan(KhachTra_TienMat = 0, KhachTra_CK = 0, KhachTra_SPF = 0, KhachTra_GRAB = 0, KhachTra_XSM = 0, KhachTra_HT1 = 0, KhachTra_HT2 = 0, KhachTra_HT3 = 0) {
    let tongtienhinhthucthanhtoan = 0
    tongtienhinhthucthanhtoan = parseInt(KhachTra_TienMat) + parseInt(KhachTra_CK) + parseInt(KhachTra_SPF) + parseInt(KhachTra_GRAB) + parseInt(KhachTra_XSM) + parseInt(KhachTra_HT1) + parseInt(KhachTra_HT2) + parseInt(KhachTra_HT3)
    return tongtienhinhthucthanhtoan
}
function CT_TraLai(TongTienHinhThucThanhToan, KhachPhaiTra) {
    let tralai = 0
    tralai = parseInt(TongTienHinhThucThanhToan) - parseInt(KhachPhaiTra)
    return tralai
}
function CT_TienVAT(TienVAT_CuaHang_SanPham, PhanTramVAT, ThanhTien) {
    let tienvat = 0
    tienvat = ThanhTien * (PhanTramVAT / 100)
    if (tienvat <= 0) {
        tienvat = TienVAT_CuaHang_SanPham
    }
    return tienvat
}
function CT_TongVAT(order) {
    let tongvat = 0
    order.forEach((item) => {
        tongvat += item.TienVAT_CuaHang_SanPham ?? 0
        item.ThuocTinh.forEach((itemTT) => {
            if (itemTT.SoLuong > 0 && itemTT.TienVAT_CuaHang_SanPham > 0) {
                tongvat += itemTT.TienVAT_CuaHang_SanPham ?? 0
            }
        })
    })
    return tongvat
}

function checkNhomSanPhamIDSumBanh(NhomSanPhamID) {
    const arrIdBanh = [48, 49, 54, 55, 57, 58, 59, 60, 62, 63, 64, 65, 67, 68, 69]
    return arrIdBanh.indexOf(NhomSanPhamID) >= 0
}

function checkNhomSanPhamIDSumNuoc(NhomSanPhamID) {
    const arrIdNuoc = [44, 61, 90]
    return arrIdNuoc.indexOf(NhomSanPhamID) >= 0
}

function checkNhomSanPhamIDSumNuocSizeL(NhomSanPhamID) {
    const arrIdNuoc = [90]
    return arrIdNuoc.indexOf(NhomSanPhamID) >= 0
}

function checkNhomSanPhamIDSumTopping(NhomSanPhamID) {
    const arrIdTopping = [45, 50, 51, 53, 56]
    return arrIdTopping.indexOf(NhomSanPhamID) >= 0
}

function checkNhomSanPhamIDSumKhuyenMai(NhomSanPhamID) {
    const arrIdKhuyenMai = [87]
    return arrIdKhuyenMai.indexOf(NhomSanPhamID) >= 0
}

function checkLoaiPhanHieuCuaHang(chid, dsch) {
    const DSCuaHangCurrent = dsch.find((item) => item.CuaHangID === chid)
    let loaiphanhieuid = DSCuaHangCurrent?.LoaiPhanHieuID
    if (loaiphanhieuid) {
        vueData.LoaiPhanHieuID = loaiphanhieuid
        vueData.TenCuaHang = DSCuaHangCurrent?.TenCuaHang
        if (DSCuaHangCurrent?.LoaiPhanHieuID === 2) {
            return true
        }
    }
    return false
}

function CT_SoLuongOrder(order) {
    const countObj = {
        Nuoc: 0,
        NuocSizeL: 0,
        Topping: 0,
        Banh: 0,
        KhuyenMai: 0
    };
    if (order?.length === 0) {
        return countObj;
    }
    order.forEach((itemSP) => {
        //Bỏ qua món huỷ: 6: Thu ngân huỷ; 7: Bếp huỷ
        if (itemSP?.TrangThai >= 6) return;
        //Đến số lượng món
        if (checkNhomSanPhamIDSumBanh(itemSP.NhomSanPhamID)) countObj.Banh += itemSP.SoLuong;
        if (checkNhomSanPhamIDSumNuoc(itemSP.NhomSanPhamID)) countObj.Nuoc += itemSP.SoLuong;
        if (checkNhomSanPhamIDSumNuocSizeL(itemSP.NhomSanPhamID)) countObj.NuocSizeL += itemSP.SoLuong;
        if (checkNhomSanPhamIDSumTopping(itemSP.NhomSanPhamID)) countObj.Topping += itemSP.SoLuong;
        //Đếm số lượng topping
        itemSP.ThuocTinh.forEach((itemTT) => {
            if (itemTT.SoLuong > 0 && checkNhomSanPhamIDSumTopping(itemTT.NhomSanPhamID)) {
                countObj.Topping += itemTT.SoLuong;
            }
        });
        /** [START] 10:30 09-06-2026: CHƯƠNG TRÌNH TẶNG Vịt Ngầu - TEA_KM_VITNGAU (09/06/2026) */
        // Kiểm tra điều kiện tặng món: Tự động thêm món khuyến mãi vào danh sách order
        const nuocSizeL = Number(countObj.NuocSizeL) || 0
        const topping = Number(countObj.Topping) || 0
        const banh = Number(countObj.Banh) || 0
        // Điều kiện: 1 Nước Size L + 1 Topping + 1 Bánh = 1 Vịt Ngầu - TEA_KM_VITNGAU (09/06/2026)
        countObj.KhuyenMai = Math.min(Math.floor(nuocSizeL / 1), Math.floor(topping / 1), Math.floor(banh / 1))
    });
    console.log("Calculate", countObj);
    return countObj;
}

const roundSoLuong = (SoLuong) => {
    let soluong = 0
    if (SoLuong) {
        soluong = parseFloat(SoLuong.toFixed(2))
    }
    return soluong
}
