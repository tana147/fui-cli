vueData.rules = {
    required: value => !!value || "Trường này là bắt buộc.",
        year: v =>
            /^\d{4}$/.test(v) && v >= 1900 && v <= 2100 || "Năm phải từ 1900 - 2100"
}
// ===================== LÝ LỊCH KHOA HỌC: dữ liệu, ma trận mẫu, bản in =====================
window.LLKH = (function () {
    const CHUA_CO = "Chưa có";
    const LY_DO = {
        noStore: "Chưa có nơi lưu (cần bổ sung)",
        hrmMigrating: "HRM đang chuyển đổi dữ liệu",
        noData: "Chưa có dữ liệu"
    };
    const API_HRM = "https://tapi.lhu.edu.vn/hrm/LLKH_HRM_BoSung_Select";
    const API_NCKH = "/HDKH_LLKH_NCKH_Select";
    function isEmpty(v) {
        if (v === null || v === undefined) return true;
        if (Array.isArray(v)) return v.length === 0;
        return String(v).trim() === "";
    }
    function show(v) { return isEmpty(v) ? CHUA_CO : v; }
    function year(d) { return isEmpty(d) ? "" : String(d).substring(0, 4); }
    function dmy(d) {
        if (isEmpty(d)) return "";
        const p = String(d).substring(0, 10).split("-");
        return p.length === 3 ? p[2] + "/" + p[1] + "/" + p[0] : d;
    }
    function my(d) {
        if (isEmpty(d)) return "";
        const p = String(d).substring(0, 10).split("-");
        return p.length >= 2 ? p[1] + "/" + p[0] : d;
    }
    function sets(res) {
        const data = res && res.data ? res.data : [];
        return Array.isArray(data[0]) || data.length === 0 ? data : [data];
    }
    function isDoi(link) { return !isEmpty(link) && /doi\.org\/|^10\.\d{4,}/i.test(link); }
    // Bậc của một dòng đào tạo HRM
    function bac(r) {
        const t = (r.TenTrinhDo || "").trim();
        if (/^GS/i.test(t)) return "GS";
        if (/^PGS/i.test(t)) return "PGS";
        if (t === "TS" || t === "TSKH") return "TS";
        if (t === "ThS" || t === "CKII") return "ThS";
        if (["Kỹ sư", "Cử nhân", "Dược sĩ"].indexOf(t) >= 0) return "DH";
        return "KHAC";
    }
    const TEN_BAC = { GS: "Giáo sư", PGS: "Phó giáo sư", TS: "Tiến sĩ", ThS: "Thạc sĩ", DH: "Đại học", KHAC: "Khác" };
    function normalize(hrmRes, nckhRes) {
        const h = sets(hrmRes), n = sets(nckhRes);
        const daoTaoAll = (h[1] || []).map(r => Object.assign({}, r, { Bac: bac(r), TenBac: TEN_BAC[bac(r)] }));
        const daoTao = daoTaoAll.filter(r => r.Bac !== "GS" && r.Bac !== "PGS");
        const hocHam = daoTaoAll.filter(r => r.Bac === "GS" || r.Bac === "PGS");
        const chungChi = h[2] || [];
        const keKhai = n[3] || [];
        const thiKHCN = n[4] || [];
        const caoNhat = daoTao.slice().sort((a, b) => (a.ThuBac || 99) - (b.ThuBac || 99))[0] || null;
        const loaiCC = re => chungChi.filter(c => re.test(c.TenLoaiChungChi || ""));
        return {
            nt: (h[0] || [])[0] || {},
            daoTao, hocHam, caoNhat, chungChi,
            ngoaiNgu: loaiCC(/ngoại ngữ/i),
            tinHoc: loaiCC(/tin học/i),
            triet: loaiCC(/triết/i),
            ppgd: loaiCC(/phương pháp giảng dạy|sư phạm/i),
            congTac: h[3] || [],
            giaDinh: h[4] || [],
            huongNC: ((n[0] || [])[0] || {}).HuongNghienCuuChinh || "",
            deTai: (n[1] || []).concat(keKhai.filter(k => k.Loai === "DE_TAI").map(k => ({
                Nguon: "Kê khai giờ NCKH (" + k.TrangThaiDuyet + ")", TenDeTai: k.Ten, Cap: k.CapDeTai,
                Nam: k.NamHoc, VaiTro: k.VaiTro
            }))),
            congTrinh: n[2] || [],
            sachKeKhai: keKhai.filter(k => k.Loai === "SACH"),
            shtt: thiKHCN.filter(t => t.LoaiKhenThuong !== 1),
            shttKeKhai: keKhai.filter(k => k.Loai === "SHTT"),
            cuocThi: thiKHCN.filter(t => t.LoaiKhenThuong === 1),
            duLieuCu: n[5] || []
        };
    }
    // ---------- Danh mục trường dùng để kiểm tra đủ/thiếu ----------
    // tab: coban | nckh ; why: lý do khi luôn thiếu
    const F = {
        hoTen: { label: "Họ và tên", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.HoTen },
        gioiTinh: { label: "Giới tính", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.GioiTinh },
        ngaySinh: { label: "Ngày sinh", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => dmy(d.nt.NgaySinh) },
        cccd: { label: "Số CCCD", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.CCCD },
        ngayCapCCCD: { label: "Ngày cấp CCCD", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => dmy(d.nt.NgayCapCCCD) },
        noiCapCCCD: { label: "Nơi cấp CCCD", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.NoiCapCCCD },
        noiSinh: { label: "Nơi sinh", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.NoiSinh },
        queQuan: { label: "Quê quán", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.QueQuan },
        danToc: { label: "Dân tộc", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.DanToc },
        quocTich: { label: "Quốc tịch", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.QuocTich },
        tonGiao: { label: "Tôn giáo", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.TonGiao },
        thuongTru: { label: "Địa chỉ thường trú", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.ThuongTru },
        chucVuDonVi: { label: "Chức vụ, đơn vị công tác", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.ChucVuPhongBan },
        dienThoai: { label: "Điện thoại di động", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.DienThoai },
        email: { label: "Email", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.Email },
        dtVP: { label: "Điện thoại văn phòng", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.DienThoaiVP },
        honNhan: { label: "Tình trạng hôn nhân", tab: "coban", muc: "I. Sơ lược lý lịch", get: d => d.nt.HonNhan },
        sucKhoe: { label: "Tình trạng sức khỏe", tab: "coban", muc: "I. Sơ lược lý lịch", get: () => null, why: LY_DO.noStore },
        hocVi: { label: "Học vị cao nhất", tab: "coban", muc: "II. Đào tạo", get: d => d.caoNhat ? d.caoNhat.TenTrinhDo : d.nt.TrinhDoCaoNhat },
        namNuocHocVi: { label: "Năm, nước nhận học vị", tab: "coban", muc: "II. Đào tạo", get: d => d.caoNhat && d.caoNhat.NgayCapBang && d.caoNhat.NuocDaoTao ? year(d.caoNhat.NgayCapBang) + ", " + d.caoNhat.NuocDaoTao : null },
        hocHam: { label: "Học hàm (GS/PGS), năm phong", tab: "coban", muc: "II. Đào tạo", get: d => d.hocHam.map(r => r.TenBac + " " + (r.TenChuyenNganh || "") + " (" + year(r.NgayCapBang) + ")").join("; ") },
        daoTao: { label: "Quá trình đào tạo", tab: "coban", muc: "II. Đào tạo", get: d => d.daoTao },
        namTotNghiep: { label: "Năm tốt nghiệp các bậc", tab: "coban", muc: "II. Đào tạo", get: d => d.daoTao.length && d.daoTao.every(r => r.NgayCapBang) ? "ok" : null },
        daoTaoThoiGian: { label: "Thời gian học (từ tháng năm)", tab: "coban", muc: "II. Đào tạo", get: () => null, why: LY_DO.noStore },
        luanVanLuanAn: { label: "Tên luận văn / luận án", tab: "coban", muc: "II. Đào tạo", get: () => null, why: LY_DO.noStore },
        luanAnTS: { label: "Tên đề tài luận án tiến sĩ", tab: "coban", muc: "II. Đào tạo", get: () => null, why: LY_DO.noStore },
        noiBaoVe: { label: "Nơi bảo vệ luận án tiến sĩ", tab: "coban", muc: "II. Đào tạo", get: d => (d.daoTao.find(r => r.Bac === "TS") || {}).TenTruongDH },
        namBatDauDay: { label: "Năm bắt đầu giảng dạy ĐH/ThS", tab: "coban", muc: "I. Sơ lược lý lịch", get: () => null, why: LY_DO.hrmMigrating },
        ngoaiNgu: { label: "Ngoại ngữ", tab: "coban", muc: "II. Đào tạo", get: d => d.ngoaiNgu },
        tinHoc: { label: "Tin học", tab: "coban", muc: "II. Đào tạo", get: d => d.tinHoc },
        triet: { label: "Chứng chỉ Triết học", tab: "coban", muc: "II. Đào tạo", get: d => d.triet },
        ppgd: { label: "Chứng chỉ PPGD đại học", tab: "coban", muc: "II. Đào tạo", get: d => d.ppgd },
        congTac: { label: "Quá trình công tác", tab: "coban", muc: "III. Công tác", get: d => d.congTac },
        khenThuong: { label: "Khen thưởng khác", tab: "coban", muc: "IV. Giải thưởng & khen thưởng", get: () => null, why: LY_DO.hrmMigrating },
        giaDinhChaMe: { label: "Cha, mẹ", tab: "coban", muc: "V. Gia đình", get: d => d.giaDinh.filter(g => g.TenLoaiQH === "Cha" || g.TenLoaiQH === "Mẹ") },
        nguoiBaoTin: { label: "Người báo tin", tab: "coban", muc: "V. Gia đình", get: () => null, why: LY_DO.noStore },
        huongNC: { label: "Hướng nghiên cứu chính", tab: "nckh", muc: "I. Hướng nghiên cứu", get: d => d.huongNC },
        deTai: { label: "Đề tài, dự án", tab: "nckh", muc: "II. Đề tài", get: d => d.deTai },
        baiBao: { label: "Bài báo, báo cáo khoa học", tab: "congtrinh", muc: "I. Bài báo, báo cáo, sách", get: d => d.congTrinh.filter(c => c.LoaiAnPhamID !== 6) },
        baiBaoDOI: { label: "DOI của bài báo WoS/Scopus/trong nước", tab: "congtrinh", muc: "I. Bài báo, báo cáo, sách", get: d => { const a = d.congTrinh.filter(c => c.LoaiAnPhamID !== 6); return a.length && a.every(c => isDoi(c.DuongDanBaiBao)) ? "ok" : null; } },
        baiBaoTapSoTrang: { label: "Tập, số, trang và tháng công bố", tab: "congtrinh", muc: "I. Bài báo, báo cáo, sách", get: () => null, why: LY_DO.noStore },
        baiBaoViTri: { label: "Tác giả thứ nhất / liên hệ / chủ biên", tab: "congtrinh", muc: "I. Bài báo, báo cáo, sách", get: () => null, why: LY_DO.noStore },
        sach: { label: "Sách, giáo trình", tab: "congtrinh", muc: "I. Bài báo, báo cáo, sách", get: d => d.congTrinh.filter(c => c.LoaiAnPhamID === 6).concat(d.sachKeKhai) },
        shtt: { label: "Sáng chế, giải pháp hữu ích", tab: "nckh", muc: "III. Sở hữu trí tuệ", get: d => d.shtt.concat(d.shttKeKhai) },
        cuocThi: { label: "Giải thưởng cuộc thi KH&CN", tab: "coban", muc: "IV. Giải thưởng & khen thưởng", get: d => d.cuocThi }
    };
    // ---------- Ma trận mẫu: req = bắt buộc (chặn in), opt = in nếu có ----------
    const MAU = [
        { ma: "GV", ten: "LLKH Giảng viên (MAU LLKH GV LHU-001)",
          req: ["hoTen", "gioiTinh", "cccd", "ngaySinh", "noiSinh", "queQuan", "danToc", "hocVi", "namNuocHocVi", "chucVuDonVi", "thuongTru", "dienThoai", "email", "daoTao", "namTotNghiep", "luanVanLuanAn", "ngoaiNgu", "tinHoc", "triet", "ppgd", "congTac"],
          opt: ["hocHam", "deTai", "baiBao", "sach", "shtt"] },
        { ma: "SDH", ten: "LLKH GV đào tạo tiến sĩ (Sau đại học)",
          req: ["hoTen", "ngaySinh", "gioiTinh", "quocTich", "cccd", "dienThoai", "email", "hocVi", "namNuocHocVi", "noiBaoVe", "luanAnTS", "namBatDauDay", "huongNC", "baiBao", "baiBaoDOI", "baiBaoTapSoTrang", "baiBaoViTri"],
          opt: ["hocHam", "sach", "shtt"] },
        { ma: "SYLL", ten: "Sơ yếu lý lịch (DHLH 2023)",
          req: ["hoTen", "ngaySinh", "gioiTinh", "noiSinh", "quocTich", "tonGiao", "thuongTru", "cccd", "ngayCapCCCD", "noiCapCCCD", "dienThoai", "email", "hocVi", "ngoaiNgu", "tinHoc", "honNhan", "sucKhoe", "nguoiBaoTin", "daoTao", "daoTaoThoiGian", "congTac", "giaDinhChaMe"],
          opt: [] },
        { ma: "LLKH", ten: "Lý lịch khoa học chung (5 năm gần nhất)",
          req: ["hoTen", "ngaySinh", "gioiTinh", "chucVuDonVi", "dienThoai", "email", "daoTao", "congTac", "ngoaiNgu", "tinHoc", "huongNC"],
          opt: ["hocHam", "dtVP", "deTai", "baiBao", "sach", "shtt", "cuocThi", "khenThuong"] }
    ];
    function kiemTra(ma, d) {
        const m = MAU.find(x => x.ma === ma) || MAU[0];
        const row = (key, batBuoc) => {
            const f = F[key], v = f.get(d), du = !isEmpty(v);
            return { key, label: f.label, tab: f.tab, muc: f.muc, batBuoc, du,
                giaTri: du ? (Array.isArray(v) ? v.length + " dòng" : (v === "ok" ? "Đủ" : v)) : (f.why || LY_DO.noData) };
        };
        const rows = m.req.map(k => row(k, true)).concat(m.opt.map(k => row(k, false)));
        const req = rows.filter(r => r.batBuoc);
        return { mau: m, rows, soDu: req.filter(r => r.du).length, tong: req.length, thieu: req.filter(r => !r.du) };
    }
    // =========================== BẢN IN (pdfmake) ===========================
    const S = {
        title: { fontSize: 14, bold: true, alignment: "center" },
        sub: { italics: true, alignment: "center" },
        h1: { fontSize: 12, bold: true, margin: [0, 10, 0, 4] },
        h2: { bold: true, margin: [0, 6, 0, 3] },
        th: { bold: true, alignment: "center", fontSize: 10 },
        td: { fontSize: 10 },
        missing: { italics: true, color: "#9e9e9e" }
    };
    function v(x) { return isEmpty(x) ? { text: CHUA_CO, style: "missing" } : { text: String(x) }; }
    function line(label, value) { return { text: [label + ": ", v(value)], margin: [0, 2, 0, 2] }; }
    function line2(l1, v1, l2, v2) {
        return { columns: [{ width: "55%", text: [l1 + ": ", v(v1)] }, { width: "45%", text: [l2 + ": ", v(v2)] }], margin: [0, 2, 0, 2] };
    }
    function table(heads, rows, widths) {
        const body = [heads.map(h => ({ text: h, style: "th" }))];
        if (!rows.length) body.push([{ text: CHUA_CO, style: "missing", colSpan: heads.length, alignment: "center" }].concat(heads.slice(1).map(() => ({}))));
        rows.forEach(r => body.push(r.map(c => (c && typeof c === "object") ? c : Object.assign(v(c), { style: isEmpty(c) ? "missing" : "td" }))));
        return { table: { headerRows: 1, widths: widths || heads.map(() => "*"), body }, margin: [0, 2, 0, 6] };
    }
    function headerBoGD() {
        return { columns: [
            { width: "45%", stack: [{ text: "BỘ GIÁO DỤC VÀ ĐÀO TẠO" }, { text: "TRƯỜNG ĐẠI HỌC LẠC HỒNG", bold: true }], alignment: "center", fontSize: 11 },
            { width: "55%", stack: [{ text: "CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM", bold: true }, { text: "Độc lập - Tự do - Hạnh phúc", bold: true }], alignment: "center", fontSize: 11 }
        ], margin: [0, 0, 0, 16] };
    }
    function camDoan(text) { return { text: text, margin: [0, 12, 0, 8], alignment: "justify" }; }
    function kyTen(trai, phai) {
        return { columns: [{ width: "50%", stack: trai, alignment: "center" }, { width: "50%", stack: phai, alignment: "center" }], margin: [0, 6, 0, 0] };
    }
    function namCT(c) { return c.NamDangBai; }
    function tg(c) { return c.Is_TacGiaChinh ? "Tác giả chính" : "Đồng tác giả"; }
    function thoiGianCT(c) { return my(c.NgayLamViec) + " – " + (c.NgayNghiViec ? my(c.NgayNghiViec) : "nay"); }
    function ccText(arr) { return arr.map(c => c.TenChungChi + (c.Diem ? " (" + c.Diem + ")" : "")).join("; "); }
    const CAM_DOAN_LLKH = "Tôi cam đoan và chịu trách nhiệm về tính chính xác, trung thực của nội dung bản lý lịch khoa học, nếu sai tôi xin chịu trách nhiệm trước pháp luật./.";
    const NGAY_KY = "Đồng Nai, ngày ...... tháng ...... năm ......";
    function docGV(d) {
        const nt = d.nt, by = b => d.daoTao.filter(r => r.Bac === b);
        const dh = by("DH"), ths = by("ThS")[0] || {}, ts = by("TS")[0] || {};
        const hh = d.hocHam[0];
        return [
            headerBoGD(),
            { text: "LÝ LỊCH KHOA HỌC", style: "title" }, { text: "(Dùng cho giảng viên)", style: "sub", margin: [0, 0, 0, 10] },
            { text: "I. LÝ LỊCH SƠ LƯỢC", style: "h1" },
            line2("Họ và tên", nt.HoTen, "Giới tính", nt.GioiTinh),
            line("Số CCCD/CC", nt.CCCD),
            line2("Ngày, tháng, năm sinh", dmy(nt.NgaySinh), "Nơi sinh", nt.NoiSinh),
            line2("Quê quán", nt.QueQuan, "Dân tộc", nt.DanToc),
            line2("Học vị cao nhất", F.hocVi.get(d), "Năm, nước nhận học vị", F.namNuocHocVi.get(d)),
            line2("Chức danh khoa học cao nhất", hh ? hh.TenBac : null, "Năm bổ nhiệm", hh ? year(hh.NgayCapBang) : null),
            line("Chức vụ, đơn vị công tác", nt.ChucVuPhongBan),
            line("Chỗ ở riêng hoặc địa chỉ liên lạc", nt.ThuongTru),
            line2("Điện thoại di động", nt.DienThoai, "Email", nt.Email),
            { text: "II. QUÁ TRÌNH ĐÀO TẠO", style: "h1" },
            { text: "1. Đại học", style: "h2" },
            line("Hệ đào tạo", (dh[0] || {}).TenLHDT), line("Nơi đào tạo", (dh[0] || {}).TenTruongDH), line("Ngành học", (dh[0] || {}).TenChuyenNganh),
            line2("Nước đào tạo", (dh[0] || {}).NuocDaoTao, "Năm tốt nghiệp", year((dh[0] || {}).NgayCapBang)),
            line2("Bằng đại học 2", (dh[1] || {}).TenChuyenNganh, "Năm tốt nghiệp", year((dh[1] || {}).NgayCapBang)),
            { text: "2. Sau đại học", style: "h2" },
            line2("- Thạc sĩ chuyên ngành", ths.TenChuyenNganh, "Năm cấp bằng", year(ths.NgayCapBang)),
            line("Nơi/cơ sở đào tạo", ths.TenTruongDH), line("Tên luận văn", null),
            line2("- Tiến sĩ chuyên ngành", ts.TenChuyenNganh, "Năm cấp bằng", year(ts.NgayCapBang)),
            line("Nơi/cơ sở đào tạo", ts.TenTruongDH), line("Tên luận án", null),
            { text: "3. Ngoại ngữ", style: "h2" },
            ...(d.ngoaiNgu.length ? d.ngoaiNgu.map((c, i) => line2((i + 1) + ". " + c.TenChungChi, null, "Mức độ sử dụng", c.Diem)) : [line("Ngoại ngữ", null)]),
            { text: "4. Các chứng chỉ khác", style: "h2" },
            line("- Triết học", ccText(d.triet)), line("- Phương pháp giảng dạy đại học", ccText(d.ppgd)),
            line("- Tin học", ccText(d.tinHoc)),
            line("- Khác", ccText(d.chungChi.filter(c => [d.ngoaiNgu, d.tinHoc, d.triet, d.ppgd].every(a => a.indexOf(c) < 0)))),
            { text: "III. QUÁ TRÌNH CÔNG TÁC CHUYÊN MÔN", style: "h1" },
            table(["Thời gian", "Nơi công tác", "Vị trí/công việc đảm nhiệm"], d.congTac.map(c => [thoiGianCT(c), "Trường Đại học Lạc Hồng – " + (c.TenPB || ""), c.TenChucVu]), ["22%", "43%", "35%"]),
            { text: "IV. QUÁ TRÌNH NGHIÊN CỨU KHOA HỌC", style: "h1" },
            { text: "1. Các đề tài nghiên cứu khoa học đã và đang tham gia", style: "h2" },
            table(["TT", "Tên đề tài nghiên cứu", "Năm bắt đầu/ hoàn thành", "Đề tài cấp", "Trách nhiệm"], d.deTai.map((t, i) => [i + 1, t.TenDeTai, t.ThoiGian || t.Nam, t.Cap, t.VaiTro]), [20, "*", 70, 70, 70]),
            { text: "2. Các công trình khoa học đã công bố", style: "h2" },
            table(["STT", "Tên công trình", "Năm công bố", "Tên tạp chí", "Điểm HĐGS", "Ghi chú (vị trí tác giả)"], F.baiBao.get(d).map((c, i) => [i + 1, c.TenAnPham, namCT(c), c.TenTapChi, c.DiemHoiDong, tg(c)]), [22, "*", 40, 110, 40, 65]),
            { text: "3. Các sách chuyên khảo, giáo trình đã công bố", style: "h2" },
            table(["STT", "Tên công trình", "Năm xuất bản", "Tên nhà xuất bản", "Điểm HĐGS", "Ghi chú"], F.sach.get(d).map((c, i) => [i + 1, c.TenAnPham || c.Ten, c.NamDangBai || c.ThoiGianPhatHanh, c.TenTapChi || c.NoiPhatHanh, c.DiemHoiDong, c.VaiTro || tg(c)]), [22, "*", 45, 110, 40, 60]),
            { text: "4. Bằng phát minh, sáng chế, giải pháp hữu ích", style: "h2" },
            table(["TT", "Tên bằng", "Số hiệu", "Năm cấp", "Nơi cấp", "Tác giả/ đồng tác giả", "Sản phẩm đề tài"], d.shtt.map((s, i) => [i + 1, s.TenCuocThi_CongTrinh, s.SoQuyetDinh_VanBang, year(s.NgayBanHanh), null, s.VaiTro, null]), [20, "*", 50, 35, 55, 60, 50]),
            camDoan(CAM_DOAN_LLKH),
            kyTen([{ text: "Xác nhận của Trường đại học", bold: true }, { text: "HIỆU TRƯỞNG", bold: true }],
                [{ text: NGAY_KY, italics: true }, { text: "Người khai ký tên", bold: true }, { text: "(Ghi rõ chức danh, học vị)", italics: true }, { text: "\n\n\n" + (nt.HoTen || ""), bold: true }])
        ];
    }
    function docSDH(d) {
        const nt = d.nt, gs = d.hocHam.find(r => r.Bac === "GS"), pgs = d.hocHam.find(r => r.Bac === "PGS");
        const ts = d.daoTao.find(r => r.Bac === "TS") || {};
        const nganh = d.caoNhat ? d.caoNhat.TenChuyenNganh : null;
        const bb = arr => arr.map((c, i) => [i + 1, c.TenAnPham, null, null, null, c.TenTapChi, null, c.NamDangBai, c.DiemHoiDong]);
        const H = ["TT", "Tên bài báo/báo cáo", "Chủ biên", "TG thứ nhất", "TG liên hệ", "Tên tạp chí, kỷ yếu", "Tập, số, trang", "Tháng, năm", "Điểm"];
        const W = [18, "*", 34, 34, 34, 80, 40, 38, 30];
        const wos = d.congTrinh.filter(c => c.LoaiAnPhamID === 15), scopus = d.congTrinh.filter(c => c.LoaiAnPhamID === 16);
        const trongNuoc = d.congTrinh.filter(c => c.LoaiAnPhamID === 3 || c.LoaiAnPhamID === 1);
        const sach = d.congTrinh.filter(c => c.LoaiAnPhamID === 6);
        return [
            headerBoGD(),
            { text: "LÝ LỊCH KHOA HỌC", style: "title" }, { text: "(Dành cho giảng viên tham gia đào tạo chương trình tiến sĩ)", style: "sub", margin: [0, 0, 0, 10] },
            { text: "I. THÔNG TIN CHUNG", style: "h1" },
            line2("Họ và tên", nt.HoTen, "Ngày sinh", dmy(nt.NgaySinh)),
            line2("Giới tính", nt.GioiTinh, "Quốc tịch", nt.QuocTich),
            line("Mã số CCCD", nt.CCCD),
            line2("Số điện thoại", nt.DienThoai, "Email", nt.Email),
            line("Cơ quan công tác hiện tại", "Trường Đại học Lạc Hồng"),
            line2("Học hàm Giáo sư ngành", gs ? gs.TenChuyenNganh : "", "Năm phong", gs ? year(gs.NgayCapBang) : ""),
            line2("Học hàm Phó giáo sư ngành", pgs ? pgs.TenChuyenNganh : "", "Năm phong", pgs ? year(pgs.NgayCapBang) : ""),
            line2("Học vị cao nhất", F.hocVi.get(d), "Năm cấp bằng", d.caoNhat ? year(d.caoNhat.NgayCapBang) : null),
            line("Nơi bảo vệ luận án tiến sĩ", ts.TenTruongDH),
            line("Tên đề tài luận án tiến sĩ", null),
            line("Năm giảng dạy trình độ đại học hoặc thạc sĩ: Từ năm", null),
            line("Hướng nghiên cứu chính hiện nay", d.huongNC),
            { text: "II. KẾT QUẢ NGHIÊN CỨU KHOA HỌC", style: "h1" },
            { text: "1. Báo cáo hội nghị khoa học, bài báo khoa học đã công bố trong các ấn phẩm thuộc danh mục Web of Science hoặc Scopus là tác giả chính", style: "h2" },
            { text: "I. Tạp chí/kỷ yếu thuộc danh mục Web of Science", italics: true }, table(H, bb(wos), W),
            { text: "II. Tạp chí/kỷ yếu thuộc danh mục SCOPUS", italics: true }, table(H, bb(scopus), W),
            { text: "2. Chương sách tham khảo do các nhà xuất bản quốc tế uy tín phát hành", style: "h2" },
            table(["TT", "Tên chương sách", "Chủ biên", "TG thứ nhất", "TG liên hệ", "Tên sách", "Nhà xuất bản", "Tháng, năm", "Điểm"], [], W),
            { text: "3. Bài báo đăng trên các tạp chí khoa học trong nước là tác giả chính", style: "h2" },
            table(H.concat(["Ngành/Lĩnh vực"]), trongNuoc.map((c, i) => bb([c])[0].map((x, j) => j === 0 ? i + 1 : x).concat([nganh])), [16, "*", 30, 30, 30, 70, 36, 34, 26, 44]),
            { text: "4. Sách chuyên khảo do các nhà xuất bản uy tín trong nước và quốc tế phát hành", style: "h2" },
            table(["TT", "Tên sách chuyên khảo", "Chủ biên", "TG thứ nhất", "TG liên hệ", "Nhà xuất bản", "Chỉ số ISBN", "Tháng, năm", "Điểm"],
                sach.map((c, i) => [i + 1, c.TenAnPham, null, null, null, c.TenTapChi, c.ISSN, c.NamDangBai, c.DiemHoiDong]), W),
            { text: "5. Sáng chế", style: "h2" },
            ...(d.shtt.length ? d.shtt.map(s => ({ text: "- " + s.TenCuocThi_CongTrinh + "; " + (s.SoQuyetDinh_VanBang || "") + "; " + year(s.NgayBanHanh), margin: [0, 2, 0, 2] })) : [v(null)]),
            camDoan(CAM_DOAN_LLKH),
            kyTen([], [{ text: NGAY_KY, italics: true }, { text: "Người khai ký tên", bold: true }, { text: "(Ghi rõ chức danh, học vị)", italics: true }, { text: "\n\n\n" + (nt.HoTen || ""), bold: true }])
        ];
    }
    function docSYLL(d) {
        const nt = d.nt, qh = t => d.giaDinh.filter(g => t.indexOf(g.TenLoaiQH) >= 0);
        const nguoi = (lbl, g) => [
            line2("Họ và tên " + lbl, g ? g.HoTen : null, "sinh năm", g ? (g.NgaySinh ? dmy(g.NgaySinh) : g.NamSinh) : null),
            line("Nghề nghiệp", g ? g.NgheNghiep : null), line("Nơi công tác", g ? g.NoiCongTac : null), line("Chỗ ở hiện nay", g ? g.ChoOHienNay : null)
        ];
        const bang = arr => table(["STT", "Mối quan hệ", "Họ và tên", "Năm sinh", "Nghề nghiệp", "Nơi công tác / học tập"], arr.map((g, i) => [i + 1, g.TenLoaiQH, g.HoTen, g.NamSinh || year(g.NgaySinh), g.NgheNghiep, g.NoiCongTac]), [22, 45, "*", 40, 70, 110]);
        return [
            { columns: [
                { width: 90, table: { widths: [80], heights: [100], body: [[{ text: "Ảnh 4x6", alignment: "center", margin: [0, 40, 0, 0], color: "#9e9e9e" }]] } },
                { width: "*", stack: [{ text: "CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM", bold: true }, { text: "Độc lập - Tự do - Hạnh phúc", bold: true }, { text: "\nSƠ YẾU LÝ LỊCH", style: "title" }], alignment: "center" }
            ], margin: [0, 0, 0, 12] },
            line2("Họ và tên", nt.HoTen, "sinh ngày", dmy(nt.NgaySinh)),
            line("Giới tính", nt.GioiTinh), line("Nơi sinh", nt.NoiSinh),
            line2("Quốc tịch", nt.QuocTich, "Tôn giáo", nt.TonGiao),
            line("Địa chỉ thường trú", nt.ThuongTru), line("Địa chỉ tạm trú (nếu có)", nt.TamTru || ""),
            line("CCCD số", nt.CCCD), line2("cấp ngày", dmy(nt.NgayCapCCCD), "tại", nt.NoiCapCCCD),
            line("Giấy phép lao động số", nt.GiayPhepLaoDong || ""),
            line2("có thời hạn từ ngày", nt.GiayPhepLaoDong ? dmy(nt.NgayCapGPLD) : "", "đến ngày", nt.GiayPhepLaoDong ? dmy(nt.NgayHetHanGPLD) : ""),
            line2("Số điện thoại", nt.DienThoai, "Email", nt.Email),
            line("Trình độ chuyên môn hoặc nghề nghiệp", F.hocVi.get(d)),
            line("Trình độ ngoại ngữ", ccText(d.ngoaiNgu)), line("Trình độ tin học", ccText(d.tinHoc)),
            line("Tình trạng hôn nhân", nt.HonNhan), line("Tình trạng sức khỏe hiện nay", null),
            { text: "Khi cần báo tin cho ai? ở đâu", margin: [0, 4, 0, 2] },
            table(["Mối quan hệ", "Họ và tên", "Số điện thoại", "Địa chỉ liên hệ"], [], [70, "*", 80, "*"]),
            { text: "QUÁ TRÌNH HỌC TẬP BẢN THÂN TỪ ĐẠI HỌC", style: "h1", alignment: "center" },
            table(["Từ tháng năm đến tháng năm", "Nơi đào tạo", "Chuyên ngành đào tạo", "Thành tích học tập"], d.daoTao.map(r => [r.NgayCapBang ? "... – " + my(r.NgayCapBang) : null, r.TenTruongDH, r.TenChuyenNganh, r.XepLoai]), [90, "*", "*", 90]),
            { text: "QUÁ TRÌNH CÔNG TÁC BẢN THÂN", style: "h1", alignment: "center" },
            table(["Từ tháng năm đến tháng năm", "Nơi công tác", "Công việc gì", "Chức vụ (nếu có)"], d.congTac.map(c => [thoiGianCT(c), "Trường Đại học Lạc Hồng – " + (c.TenPB || ""), null, c.TenChucVu]), [90, "*", "*", 90]),
            { text: "HOÀN CẢNH GIA ĐÌNH", style: "h1", alignment: "center" },
            ...nguoi("cha", qh(["Cha"])[0]), ...nguoi("mẹ", qh(["Mẹ"])[0]),
            { text: "HỌ VÀ TÊN ANH CHỊ EM RUỘT", style: "h2", alignment: "center" }, bang(qh(["Anh", "Chị", "Em"])),
            ...nguoi("chồng (vợ)", qh(["Vợ", "Chồng"])[0]),
            { text: "HỌ VÀ TÊN CÁC CON", style: "h2", alignment: "center" }, bang(qh(["Con"])),
            { text: "LỜI CAM ĐOAN", style: "h1", alignment: "center" },
            camDoan("Tôi xin cam đoan những lời khai trên là đúng sự thật, nếu sai tôi xin hoàn toàn chịu trách nhiệm./."),
            kyTen([{ text: "Xác nhận của cơ quan có thẩm quyền", bold: true }, { text: "Ngày ...... tháng ...... năm ......", italics: true }, { text: "(Ký và ghi rõ họ tên, đóng dấu)", italics: true }],
                [{ text: "Ngày ...... tháng ...... năm ......", italics: true }, { text: "Người khai", bold: true }, { text: "(Ký và ghi rõ họ tên)", italics: true }, { text: "\n\n\n" + (nt.HoTen || ""), bold: true }])
        ];
    }
    function docLLKH(d) {
        const nt = d.nt, tu = new Date().getFullYear() - 4;
        const gan = a => a.filter(x => !x.NamDangBai || x.NamDangBai >= tu);
        const quocTe = gan(d.congTrinh.filter(c => [2, 15, 16].indexOf(c.LoaiAnPhamID) >= 0));
        const trongNuoc = gan(d.congTrinh.filter(c => c.LoaiAnPhamID === 1 || c.LoaiAnPhamID === 3));
        const link = c => c.DuongDanBaiBao;
        const bbRows = arr => arr.map((c, i) => [i + 1, c.TenAnPham, c.TenTapChi, c.NamDangBai, link(c)]);
        const hh = d.hocHam[0];
        const info = (a, b) => [{ text: a, style: "td" }, Object.assign(v(b), { style: isEmpty(b) ? "missing" : "td" })];
        return [
            headerBoGD(),
            { text: "LÝ LỊCH KHOA HỌC", style: "title", margin: [0, 0, 0, 10] },
            { text: "1. Thông tin cá nhân", style: "h1" },
            { table: { widths: [130, "*", 90, "*"], body: [
                info("Họ và tên", nt.HoTen).concat(info("Ngày sinh", dmy(nt.NgaySinh))),
                info("Giới tính", nt.GioiTinh).concat([{ text: "", colSpan: 2 }, {}]),
                info("Chức danh khoa học", hh ? hh.TenBac : F.hocVi.get(d)).concat([{ text: "", colSpan: 2 }, {}]),
                info("Chức vụ", nt.ChucVuPhongBan).concat([{ text: "", colSpan: 2 }, {}]),
                [{ text: "Cơ quan công tác và địa chỉ: Trường Đại học Lạc Hồng\nĐịa chỉ: Số 10, đường Huỳnh Văn Nghệ, phường Trấn Biên, thành phố Đồng Nai.", colSpan: 4, style: "td" }, {}, {}, {}],
                info("Chỗ ở hiện nay", nt.TamTru || nt.ThuongTru).concat([{ text: "", colSpan: 2 }, {}]),
                info("Điện thoại VP", nt.DienThoaiVP).concat(info("Điện thoại di động", nt.DienThoai)),
                info("E-mail", nt.Email).concat([{ text: "", colSpan: 2 }, {}])
            ] }, margin: [0, 2, 0, 6] },
            { text: "2. Quá trình đào tạo (bao gồm các lớp đào tạo ngắn hạn)", style: "h1" },
            table(["Thời gian", "Tên cơ sở đào tạo", "Chuyên ngành", "Học vị"], d.daoTao.map(r => [year(r.NgayCapBang), r.TenTruongDH, r.TenChuyenNganh, r.TenTrinhDo]), [60, "*", "*", 60]),
            { text: "3. Quá trình công tác", style: "h1" },
            table(["Thời gian", "Cơ quan công tác và địa chỉ", "Chức vụ và công việc đảm nhận"], d.congTac.map(c => [thoiGianCT(c), "Trường Đại học Lạc Hồng – " + (c.TenPB || ""), c.TenChucVu]), [80, "*", "*"]),
            { text: "4. Ngoại ngữ và tin học", style: "h1" },
            line2("Ngoại ngữ 1", (d.ngoaiNgu[0] || {}).TenLoaiChungChi ? "Tiếng Anh" : null, "Trình độ", (d.ngoaiNgu[0] || {}).TenChungChi),
            line2("Tin học", d.tinHoc.length ? "Tin học" : null, "Trình độ", (d.tinHoc[0] || {}).TenChungChi),
            { text: "5. Những công trình nghiên cứu khoa học đã công bố (chỉ liệt kê những công trình 5 năm gần nhất)", style: "h1" },
            { text: "5.1. Đề tài/dự án nghiên cứu đã và đang tham gia thực hiện", style: "h2" },
            table(["Stt", "Tên đề tài/dự án", "Đề tài thuộc cấp", "Thời gian thực hiện", "Vai trò"], d.deTai.filter(t => !t.Nam || String(t.Nam).substring(0, 4) >= tu).map((t, i) => [i + 1, t.TenDeTai, t.Cap, t.ThoiGian || t.Nam, t.VaiTro]), [22, "*", 90, 70, 70]),
            { text: "5.2. Bài báo khoa học", style: "h2" },
            { text: "Tạp chí khoa học, hội thảo Quốc tế", italics: true },
            table(["Stt", "Tên bài báo", "Nhà xuất bản/Tên tạp chí", "Năm xuất bản", "Link Google Scholar/Link DOI"], bbRows(quocTe), [22, "*", 110, 45, 110]),
            { text: "Tạp chí khoa học, hội thảo trong nước", italics: true },
            table(["Stt", "Tên bài báo", "Nhà xuất bản/Tên tạp chí", "Năm xuất bản", "Link Google Scholar/Link DOI"], bbRows(trongNuoc), [22, "*", 110, 45, 110]),
            { text: "5.3. Sách chuyên khảo/chương sách/sách hoặc giáo trình", style: "h2" },
            table(["Stt", "Tên sách", "Nhà xuất bản/đơn vị xuất bản", "Năm xuất bản", "Link Google Scholar/Link DOI"], gan(F.sach.get(d)).map((c, i) => [i + 1, c.TenAnPham || c.Ten, c.TenTapChi || c.NoiPhatHanh, c.NamDangBai || c.ThoiGianPhatHanh, c.DuongDanBaiBao]), [22, "*", 110, 45, 110]),
            { text: "5.4. Phát minh, sáng chế", style: "h2" },
            table(["Stt", "Tên phát minh, sáng chế", "Số văn bằng", "Năm công bố", "Link minh chứng"], d.shtt.map((s, i) => [i + 1, s.TenCuocThi_CongTrinh, s.SoQuyetDinh_VanBang, year(s.NgayBanHanh), null]), [22, "*", 80, 55, 90]),
            { text: "5.5. Tham gia các cuộc thi khoa học và công nghệ", style: "h2" },
            table(["Stt", "Tên tác giả/nhóm tác giả", "Tên đề tài/giải pháp", "Đạt giải", "Tên cuộc thi/giải thưởng", "Số QĐ khen thưởng"], d.cuocThi.map((c, i) => [i + 1, c.NhomTacGia, c.TenCuocThi_CongTrinh, c.Giai, c.CapDo, c.SoQuyetDinh_VanBang]), [22, 90, "*", 50, 90, 60]),
            { text: "5.6. Các hình thức khen thưởng khác", style: "h2" },
            table(["Stt", "Hình thức, nội dung khen thưởng", "Cơ quan, đơn vị khen thưởng", "Số QĐ, ngày, tháng, năm"], [], [22, "*", 120, 100]),
            { text: "5.7. Hướng nghiên cứu chính 5 năm gần đây", style: "h2" }, v(d.huongNC),
            camDoan(CAM_DOAN_LLKH.replace("./.", ".")),
            kyTen([], [{ text: NGAY_KY, italics: true }, { text: "Người khai lý lịch", bold: true }, { text: "\n\n\n" + (nt.HoTen || ""), bold: true }])
        ];
    }
    const BUILD = { GV: docGV, SDH: docSDH, SYLL: docSYLL, LLKH: docLLKH };
    function docDefinition(ma, d) {
        return {
            pageSize: "A4", pageMargins: [50, 40, 40, 40],
            defaultStyle: { fontSize: 11, lineHeight: 1.15 },
            content: BUILD[ma](d), styles: S,
            footer: (p, n) => ({ text: p + "/" + n, alignment: "center", fontSize: 9, margin: [0, 10, 0, 0] })
        };
    }
    return { CHUA_CO, LY_DO, API_HRM, API_NCKH, MAU, F, isEmpty, show, year, dmy, my, isDoi, normalize, kiemTra, docDefinition };
})();