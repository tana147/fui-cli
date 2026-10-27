// Ham phu cho trang "TKB - Bang dieu khien" (gop tkb-theo-giaovien + tkb-theo-phong + khoa phong + chay nhanh).
// Goi tu EXE trong module.json (engine FUI chay JS that, thay duoc vueData/CALL) — KHONG goi trong bieu thuc template.
function tkbAutoSelectRun() {
    if (!vueData.selectedRunID && vueData.dsRunKhaThi.length > 0) {
        vueData.selectedRunID = vueData.dsRunKhaThi[0].RunID;
    }
}
function tkbAutoSelectGV() {
    if (vueData.dsGV.length > 0 && !vueData.dsGV.some(function (g) { return g.MaGV === vueData.filterGV; })) {
        vueData.filterGV = vueData.dsGV[0].MaGV;
    } else if (vueData.dsGV.length === 0) {
        vueData.filterGV = '';
        vueData.gvLich = [];
    } else {
        CALL(vueData.fetchGVLich);
    }
}
function tkbAutoSelectPhong() {
    if (vueData.dsPhong.length > 0 && !vueData.dsPhong.some(function (p) { return p.MaPhong === vueData.filterPhong; })) {
        vueData.filterPhong = vueData.dsPhong[0].MaPhong;
    } else if (vueData.dsPhong.length === 0) {
        vueData.filterPhong = '';
        vueData.phongLich = [];
    } else {
        CALL(vueData.fetchPhongLich);
    }
}
function tkbRefreshLich() {
    if (vueData.filterGV) CALL(vueData.fetchGVLich);
    if (vueData.filterPhong) CALL(vueData.fetchPhongLich);
    if (vueData.selectedRunID) {
        CALL(vueData.fetchToanTruong);
        CALL(vueData.fetchDinhMuc);
    }
}
function tkbHandleSuaTietResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        vueData.dlSua = false;
        tkbRefreshLich();
        if (vueData.selectedRunID) CALL(vueData.fetchThieu);
    }
}
function tkbHandleDoiTietResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    vueData.doiTietID1 = null;
    if (row.Success) tkbRefreshLich();
}
// ---- Chay nhanh: dong ho 5 giay goi lai spAPI_TkbChayNhanh (may trang thai o DB, moi lan goi ngan) ----
function tkbNhanhBatDongHo() {
    if (vueData._nhanhTimer) window.clearInterval(vueData._nhanhTimer);
    vueData.nhanhDangChay = true;
    vueData.nhanhBusy = false;
    vueData._nhanhTimer = window.setInterval(function () { vueData.nhanhTick = (vueData.nhanhTick || 0) + 1; }, 5000);
}
function tkbNhanhDungDongHo() {
    if (vueData._nhanhTimer) window.clearInterval(vueData._nhanhTimer);
    vueData._nhanhTimer = null;
    vueData.nhanhDangChay = false;
    vueData.nhanhBusy = false;
}
function tkbNhanhSauKhiGoi() {
    vueData.nhanhBusy = false;
    var st = vueData.nhanhState || {};
    if (st.TrangThai === 'Loi') {
        tkbNhanhDungDongHo();
        return;
    }
    if (st.TrangThai === 'HoanTat') {
        tkbNhanhDungDongHo();
        vueData.selectedRunID = st.RunID;
        CALL(vueData.fetchRunKhaThi);
        CALL(vueData.fetchThieu);
    }
}
// ---- Tab "Toan truong" + cua so lop / giao vien (2026-10-06) ----
// Moi thay doi (sua/doi/chuyen/go/khoa/ap dung goi y) goi tkbRefreshLich -> nap lai ca luoi toan truong,
// dinh muc, lich GV dang mo — de thay anh huong toan truong ngay.
function tkbLocLop() {
    var lop = vueData.lopChon;
    vueData.lopLich = lop ? vueData.dsToanTruong.filter(function (r) { return r.MaLop === lop && r.MaMon !== 'HOP'; }) : [];
    // GV day lop nay (lay tu dinh muc + lich thuc te) de ghim so sanh.
    var opts = {}, ds = [];
    (vueData.dsDinhMuc || []).forEach(function (d) {
        if (d.MaLop !== lop || !d.MaGV || d.MaGV === d.MaMon) return;
        if (!opts[d.MaGV]) { opts[d.MaGV] = { MaGV: d.MaGV, Ten: d.HoTen || d.MaGV, Mon: [] }; ds.push(opts[d.MaGV]); }
        if (opts[d.MaGV].Mon.indexOf(d.MaMon) < 0) opts[d.MaGV].Mon.push(d.MaMon);
    });
    vueData.lopGVOpts = ds.map(function (g) { return { MaGV: g.MaGV, Ten: g.Ten, Mon: g.Mon.join(', ') }; });
    tkbLocGVLop();
}
// Lich 2 GV dang ghim trong cua so lop + o danh dau: tren lich lop = o GV thu nhat ranh (khong day, khong hop,
// khong bao ban); tren lich GV = o lop dang xem con trong. Tinh tu du lieu toan truong da nap (khong goi server).
function tkbLocGVLop() {
    var gvs = vueData.lopGVs || [], all = vueData.dsToanTruong || [];
    var ten = function (g) {
        var o = (vueData.lopGVOpts || []).filter(function (x) { return x.MaGV === g; })[0];
        if (o) return o.Ten;
        var r = all.filter(function (x) { return x.MaGV === g && x.TenGV; })[0];
        return r ? r.TenGV : g;
    };
    vueData.lopGV1Lich = gvs[0] ? all.filter(function (r) { return r.MaGV === gvs[0]; }) : [];
    vueData.lopGV2Lich = gvs[1] ? all.filter(function (r) { return r.MaGV === gvs[1]; }) : [];
    vueData.lopGV1Ten = gvs[0] ? ten(gvs[0]) : '';
    vueData.lopGV2Ten = gvs[1] ? ten(gvs[1]) : '';
    var key = function (t, b, k) { return t + '|' + b + '|' + k; };
    var banGV = {}, banLop = {}, baoBan = {};
    vueData.lopGV1Lich.forEach(function (r) { banGV[key(r.Thu, r.Buoi, r.Tiet)] = true; });
    vueData.lopLich.forEach(function (r) { banLop[key(r.Thu, r.Buoi, r.Tiet)] = true; });
    (vueData.dsSapTayMeta || []).forEach(function (m) { if (m.Loai === 'BAN' && m.MaGV === gvs[0]) baoBan[key(m.Thu, m.Buoi, m.Tiet)] = true; });
    // Chi danh dau gio hoc that cua khoi (o ma it nhat 1 lop cung khoi co tiet) — bo Thu 7 / tiet 5 khoi khong hoc.
    var khoi = (/^(\d\d)[A-Za-z]/.exec(vueData.lopChon || '') || [])[1], hopLe = {};
    all.forEach(function (r) {
        if (r.MaMon !== 'HOP' && (!khoi || (r.MaLop || '').indexOf(khoi) === 0)) hopLe[key(r.Thu, r.Buoi, r.Tiet)] = true;
    });
    var markLop = [], markGV = [];
    (vueData.fixedThuCols || []).forEach(function (t) {
        (vueData.fixedSlots || []).forEach(function (s) {
            var k = key(t, s.Buoi, s.Tiet), o = { Thu: t, Buoi: s.Buoi, Tiet: s.Tiet };
            if (!hopLe[k]) return;
            if (gvs[0] && !banGV[k] && !baoBan[k]) markLop.push(o);
            if (!banLop[k]) markGV.push(o);
        });
    });
    vueData.lopMarkLop = markLop;
    vueData.lopMarkGV = markGV;
}
// Ghim GV: bam tiet/mon -> GV len vi tri thu nhat (giu 1 GV ghim truoc do); bam lai nut GV dang ghim -> bo ghim.
function tkbGhimGV() {
    var g = vueData.lopGhimGV;
    if (!g) return;
    var ds = (vueData.lopGVs || []).slice();
    var co = ds.indexOf(g) >= 0;
    if (co && vueData.lopGhimNguon === 'chip') ds = ds.filter(function (x) { return x !== g; });
    else ds = [g].concat(ds.filter(function (x) { return x !== g; })).slice(0, 2);
    vueData.lopGVs = ds;
    tkbLocGVLop();
}
function tkbMoLop() {
    vueData.lopGVs = [];
    tkbLocLop();
    vueData.dlLop = true;
}
function tkbMoGV() {
    var g = vueData.gvMo || {};
    if (!g.MaGV) return;
    vueData.gvXemTen = g.TenGV || g.MaGV;
    if (vueData.filterGV === g.MaGV) CALL(vueData.fetchGVLich);
    else vueData.filterGV = g.MaGV;
    vueData.dlGV = true;
}
function tkbSauThayDoi(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (!row.Success) return;
    tkbRefreshLich();
    if (vueData.selectedRunID) CALL(vueData.fetchThieu);
}
// ---- Sap tay kieu co vua (2026-10-06): tra ket qua spAPI_TkbSapTayThucHien ve cho luoi (kem seq de khop nuoc di) ----
function tkbSauSapTay() {
    var r = (vueData.sapTayResp && vueData.sapTayResp[0]) ? vueData.sapTayResp[0] : {};
    vueData.sapTayKQ = { Success: !!r.Success, Message: r.Message, NewID: r.NewID, NewIDs: r.NewIDs, seq: vueData.sapTaySeq };
    if (r.Success) {
        tkbRefreshLich();
        if (vueData.selectedRunID) CALL(vueData.fetchThieu);
    }
}
// ---- Xuat TKB ra file mau phan mem TKB cua truong (2026-10-09) ----
// spAPI_TkbXuatStk5 tra 1 dong {TenFile, Base64, ThongBao}; giai base64 thanh file roi tai ve trinh duyet.
function tkbTaiFileXuat(resp) {
    var r = (resp && resp[0]) ? resp[0] : {};
    if (!r.Base64) return;
    var bin = window.atob(r.Base64), n = bin.length, bytes = new Uint8Array(n);
    for (var i = 0; i < n; i++) bytes[i] = bin.charCodeAt(i);
    var blob = new Blob([bytes], { type: /\.xls$/i.test(r.TenFile || '') ? 'application/vnd.ms-excel' : 'application/octet-stream' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = r.TenFile || 'TKB';
    document.body.appendChild(a);
    a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
}