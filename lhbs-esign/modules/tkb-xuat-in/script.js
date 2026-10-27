function tkbAutoSelectRun() {
    if (!vueData.selectedRunID && vueData.dsRunKhaThi.length > 0) {
        vueData.selectedRunID = vueData.dsRunKhaThi[0].RunID;
    }
}
function tkbAutoSelectDoiTuong() {
    var ds = vueData.filterLoai === 'Lop' ? vueData.dsLop : (vueData.filterLoai === 'GV' ? vueData.dsGV : vueData.dsPhong);
    var key = vueData.filterLoai === 'Lop' ? 'MaLop' : (vueData.filterLoai === 'GV' ? 'MaGV' : 'MaPhong');
    if (ds.length > 0 && !ds.some(function (d) { return d[key] === vueData.filterMa; })) {
        vueData.filterMa = ds[0][key];
    } else if (ds.length === 0) {
        vueData.filterMa = '';
        vueData.dsLich = [];
    } else {
        CALL(vueData.fetchLich);
    }
}
function tkbFilterDsLich() {
    var key = vueData.filterLoai === 'Lop' ? 'MaLop' : (vueData.filterLoai === 'GV' ? 'MaGV' : 'MaPhong');
    vueData.dsLich = vueData.dsLichRaw.filter(function (r) { return r[key] === vueData.filterMa; });
}
function tkbXuatExcel() {
    var buoiLabel = { Sang: 'Sáng', Chieu: 'Chiều' };
    var data = vueData.dsLich.map(function (r) {
        return {
            'Thứ': r.Thu,
            'Buổi': buoiLabel[r.Buoi] || r.Buoi,
            'Tiết': r.Tiet,
            'Lớp': r.MaLop,
            'Môn': r.MaMon,
            'Tên môn': r.TenMon,
            'Mã GV': r.MaGV,
            'Giáo viên': r.TenGV,
            'Phòng': r.MaPhong
        };
    });
    var ten = vueData.filterLoai === 'Lop' ? 'Lop_' : (vueData.filterLoai === 'GV' ? 'GV_' : 'Phong_');
    jsonToExcel({
        data: data,
        filename: 'TKB_' + ten + (vueData.filterMa || '') + '.xlsx',
        worksheet: 'TKB'
    });
}