function GetDSNam() {
    const yearNow = moment().year()
    let dsYear = []
    for (let y = yearNow; y >= 2024; y--) {
        dsYear.push(y)
    }
    return dsYear
}
function handleColumnHinhThucThoiGian(HinhThucThoiGian) {
    let findIndexHeader = vueData.headers.findIndex(col => col.key && col.key == 'HinhThucThoiGian')
    if (findIndexHeader == -1) return
    vueData.headers[findIndexHeader].text = (vueData.DSHinhThucThoiGian.find(obj => obj.value == HinhThucThoiGian).text) ?? 'Hình thức thời gian'
}
function getBaoCaoAll(){
    const params = {
        PhanHieuID: vueData.PhanHieuID,
        KhuVucID: vueData.KhuVucID,
        Ngay: vueData.Ngay?? -1,
        TuNgay: vueData.TuNgay?? -1,
        DenNgay: vueData.DenNgay?? -1,
        HinhThucThanhToan: vueData.HinhThucThanhToan,
        TrangThaiMon: vueData.TrangThaiMon,
        HinhThucThoiGian: vueData.HinhThucThoiGian,
        Nam: vueData.Nam?? -1,
        TuNam: vueData.TuNam?? -1,
        DenNam: vueData.DenNam?? -1,
        Thang: vueData.Thang ?? -1
    }
    ajaxCALL('/eorder/BaoCao_HoaDon_ChiTiet_v2', params, (res) => {
        vueData.DSChiTietHoaDon = res.data
        handleColumnHinhThucThoiGian(vueData.HinhThucThoiGian)
    })
}