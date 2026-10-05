/**1: Chờ xử lý, 2: Chờ thanh toán, 3: Đã thanh toán, 4: Hoàn tất, 5: Đã hủy, 6: Đã thanh toán một phần, 7: Đã trả hàng, 8: Đặt trước, 9: Tiếp nhận đơn hàng */
const EnumHoaDon = {
    ChoXyLy: 1,
    ChoThanhToan: 2,
    DaThanhToan: 3,
    HoanTat: 4,
    DaHuy: 5,
    DaThanhToanMotPhan: 6,
    DaTraHang: 7,
    DatTruoc: 8,
    TiepNhanDonHang: 9,
}
const EnumChiTietHoaDon = {}
/** 0: Giá trị mặc định  1: In tạm tính, 2: In hóa đơn */
const EnumLoaiIn = {
    InMacDinh: 0,
    InTamTinh: 1,
    InHoaDon: 2,
}
/** Nhà hàng: 2*/
const EnumLoaiPhanHieu = {
    NhaHang: 2,
}
const EnumHinhThucThanhToan = {
    KhachTra_TienMat: "1",
    KhachTra_CK: "2",
    KhachTra_SPF: "3",
    KhachTra_XSM: "7",
    KhachTra_GRAB: "6",
    KhachTra_QT: "4",
    KhachTra_HT1: "8",
    KhachTra_HT2: "9",
    KhachTra_HT3: "10",
}
/** 0: Giá trị mặc định 1: Dùng tại cửa hàng; 2: Mang về; 3: Giao hàng */
const EnumLoaiDonHang = {
    LoaiDonHangMacDinh: 0,
    DungTaiCuaHang: 1,
    MangVe: 2,
    GiaoHang: 3,
}
/** 0: uncheck 1: check */
const EnumCheckZEN = {
    UnCheck: 0,
    Check: 1,
}
function pushRouterPos(hdid) {
    vueData.hdid = hdid
    const url = new URL(location)
    url.searchParams.set("hdid", hdid)
    history.pushState({}, "", url)
}
function deleteRouterHDIDPos() {
    const url = new URL(location)
    url.searchParams.delete("hdid")
    history.pushState({}, "", url)
}
function initHoaDon() {
    let ldh = vueData.HoaDon.BanID > 0 || vueData.LoaiPhanHieuID !== 2 ? 1 : 2
    vueData.HoaDon = {
        ...vueData.HoaDon,
        HoaDonID: parseInt(vueData.hdid ?? 0),
        LoaiDonHang: ldh,
    }
    if (vueData.HoaDon.HoaDonID && vueData.HoaDon.HoaDonID > 0) {
        loadHoaDon(parseInt(vueData.HoaDon.BanID ?? 0), parseInt(vueData.HoaDon.HoaDonID ?? 0))
    }
}
const checkTrangThaiButtonFooter = (TrangThai) => {
    switch (TrangThai) {
        case EnumHoaDon.DaThanhToan:
            return true
        case EnumHoaDon.HoanTat:
            return true
        case EnumHoaDon.DaHuy:
            return true
        default:
            return false
    }
}
function sortOrder(arr) {
    arr.sort((a, b) => {
        const orderMap = {
            Nuoc: 1,
            Topping: 2,
            Banh: 3,
        }
        const getNhomSanPhamOrder = (item) => {
            if (checkNhomSanPhamIDSumNuoc(item.NhomSanPhamID)) {
                return orderMap.Nuoc
            } else if (checkNhomSanPhamIDSumTopping(item.NhomSanPhamID)) {
                return orderMap.Topping
            } else if (checkNhomSanPhamIDSumBanh(item.NhomSanPhamID)) {
                return orderMap.Banh
            } else {
                // Nếu không thuộc bất kỳ nhóm nào, đặt ở cuối
                return Infinity
            }
        }
        const orderA = getNhomSanPhamOrder(a)
        const orderB = getNhomSanPhamOrder(b)
        return orderA - orderB
    })
    return arr
}
function loadHoaDon(banid, hoadonid) {
    return new Promise((resolve, reject) => {
        const params = { BanID: banid, HoaDonID: hoadonid }
        ajaxCALL("/eorder/HoaDon_Select_ByBanId", params, (res) => {
            if (res.data) {
                const resBan = res.data[0][0] ?? {
                    BanID: 0,
                    LauID: vueData.HoaDon.LauID ?? 0,
                    KhuID: vueData.HoaDon.KhuID ?? 0,
                }
                const resHoaDon = res.data[1][0] ?? {}
                const resChiTietHoaDon = res.data[2] ?? []
                let resDefaultHoaDon
                const productJsonData = []
                //Nếu bàn đó chưa có hóa đơn thì load thêm món mặc định
                if (res.data[3] && res.data[3].length > 0) {
                    resDefaultHoaDon = res.data[3] ?? []
                    resDefaultHoaDon.forEach((item, index) => {
                        productJsonData.push({
                            ...item,
                            SoThuTu: index,
                            Is_ThanhToanZen: 0,
                            TongTienMon: 0,
                            Is_KhuyenMai: 0,
                            ThuocTinh: [],
                        })
                    })
                }
                const productFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 1)
                const toppingFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 0)
                //Lặp danh sách sản phẩm
                productFilter.forEach((item, index) => {
                    //Tìm topping của sản phẩm
                    const topping = toppingFilter.filter((topping) => topping.SanPhamGUID === item.SanPhamGUID)
                    let toppingMerge = []
                    //Merge với chi tiết liên kết nếu sản phẩm có NhomLienKetID > 0
                    if (item.NhomLienKetID > 0) {
                        const toppingOfProduct = vueData.DSChiTietLienKet.filter((link) => link.NhomLienKetID === item.NhomLienKetID)
                        toppingMerge = toppingOfProduct.map((link) => {
                            const indexTopping = topping.findIndex((find) => find.NhomLienKetChiTietID === link.NhomLienKetChiTietID)
                            if (indexTopping >= 0) {
                                topping[indexTopping].SoLuongThucTe = topping[indexTopping].SoLuong / item.SoLuong
                                return topping[indexTopping]
                            } else {
                                return {
                                    HoaDonChiTietID: 0,
                                    HoaDonID: item.HoaDonID,
                                    SanPhamID: link.SanPhamID,
                                    SanPhamGUID: item.SanPhamGUID,
                                    OrderGUID: item.OrderGUID,
                                    NhomLienKetID: link.NhomLienKetID ?? 0,
                                    NhomLienKetChiTiet_ParentID: link.NhomLienKetChiTiet_ParentID,
                                    NhomLienKetChiTietID: link.NhomLienKetChiTietID,
                                    DoiMon_SanPhamID: 0,
                                    TenHienThi: link.TenHienThi,
                                    TenNoiBo: link.TenNoiBo,
                                    SoLuong: 0,
                                    SoLuongThucTe: 0,
                                    SoLuongToiDa: link.SoLuongToiDa ?? 0,
                                    DonGia: item.DonGia,
                                    TienVAT: link.TienVAT ?? 0,
                                    TienVAT_CuaHang_SanPham: link.TienVAT_CuaHang_SanPham ?? 0,
                                    PhanTramVAT: link.PhanTramVAT ?? 0,
                                    GiaBan_CuaHang: link.GiaBan_CuaHang,
                                    ThanhTien: 0,
                                    DonViTinhID: "",
                                    ThuTu: link.ThuTu,
                                    GhiChu: "",
                                    TenMayIn: "",
                                    TrangThai: item.TrangThai,
                                    TenTrangThai: "",
                                    TinhTrang: 0,
                                    Is_MangVe: item.Is_MangVe,
                                    Is_SanPham: 0,
                                    Is_ThuocTinh: 1,
                                    Is_ThanhToanZen: link.Is_ThanhToanZen ?? 0,
                                }
                            }
                        })
                    }
                    const product = {
                        ...item,
                        SoThuTu: index + 1,
                        TongTienMon: 0,
                        ThuocTinh: toppingMerge,
                    }
                    productJsonData.push(product)
                })
                const dataJson = {
                    ...resHoaDon,
                    ...resBan,
                    ChiTietHoaDon: productJsonData,
                }
                vueData.HoaDon = dataJson
                resolve()
            }
        })
    })
}
function getLauByCuaHangID() {
    return new Promise((resolve, reject) => {
        const params = { CuaHangID: vueData.CuaHangID }
        ajaxCALL("/eorder/Lau_Select_ByCuaHangId", params, (res) => {
            if (res.data) {
                resolve(res.data)
            }
        })
    })
}
function getKhuByLauID(lauid) {
    return new Promise((resolve, reject) => {
        const params = { LauID: lauid }
        ajaxCALL("/eorder/Khu_Select_ByLauId", params, (res) => {
            if (res.data) {
                resolve(res.data)
            }
        })
    })
}
async function getBanByKhuID(khuid) {
    return new Promise((resolve, reject) => {
        const params = { KhuID: khuid }
        ajaxCALL("/eorder/Ban_Select_TrangThai_ByKhuId", params, (res) => {
            if (res.data) {
                resolve(res.data)
            }
        })
    })
}
function getTable() {
    if (vueData.HoaDon.KhuID) {
        const params = { KhuID: vueData.HoaDon.KhuID }
        ajaxCALL("/eorder/Ban_Select_TrangThai_ByKhuId", params, (res) => {
            if (res.data) {
                vueData.DSBan = res.data
            }
        })
    }
}
function getHinhThucThanhToan(KhachTra_TienMat = 0, KhachTra_CK = 0, KhachTra_SPF = 0, KhachTra_GRAB = 0, KhachTra_QT = 0, KhachTra_XSM = 0, KhachTra_HT1 = 0, KhachTra_HT2 = 0, KhachTra_HT3 = 0) {
    let hinhThucThanhToan = []
    if (KhachTra_TienMat > 0) {
        hinhThucThanhToan.push("1")
    }
    if (KhachTra_CK > 0) {
        hinhThucThanhToan.push("2")
    }
    if (KhachTra_SPF > 0) {
        hinhThucThanhToan.push("3")
    }
    if (KhachTra_GRAB > 0) {
        hinhThucThanhToan.push("6")
    }
    if (KhachTra_QT > 0) {
        hinhThucThanhToan.push("4")
    }
    if (KhachTra_XSM > 0) {
        hinhThucThanhToan.push("7")
    }
    if (KhachTra_HT1 > 0) {
        hinhThucThanhToan.push("8")
    }
    if (KhachTra_HT2 > 0) {
        hinhThucThanhToan.push("9")
    }
    if (KhachTra_HT3 > 0) {
        hinhThucThanhToan.push("10")
    }
    return hinhThucThanhToan
}
