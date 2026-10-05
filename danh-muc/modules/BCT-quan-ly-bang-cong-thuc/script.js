/* ============================
   BORDER STYLE
===============================*/
function getAllBorderStyle() {
    return {
        top: { style: "thin", color: { rgb: "000000" } },
        bottom: { style: "thin", color: { rgb: "000000" } },
        left: { style: "thin", color: { rgb: "000000" } },
        right: { style: "thin", color: { rgb: "000000" } },
    }
}
/* ============================
   HELPER: apply style to every cell in a range
===============================*/
function applyStyleToRange(ws, start, end, style) {
    for (let rr = start.r; rr <= end.r; rr++) {
        for (let cc = start.c; cc <= end.c; cc++) {
            const cellRef = XLSX.utils.encode_cell({ r: rr, c: cc })
            if (!ws[cellRef]) ws[cellRef] = { t: "s", v: "" }
            ws[cellRef].s = { ...(ws[cellRef].s || {}), ...style }
        }
    }
}
/* ============================
   HELPER: sanitize filename
===============================*/
function sanitizeFileName(name) {
    return String(name || "CongThuc").replace(/[\\/:*?"<>|]/g, "-")
}
/* ============================
   HELPER: number safe
===============================*/
function toNum(x) {
    const n = Number(x)
    return Number.isFinite(n) ? n : 0
}
/* ============================
   KEY for JSON "Sau khi nấu"
   2   -> DinhLuong2
   0.5 -> DinhLuong0_5
===============================*/
function jsonKey(dinhLuong) {
    return `DinhLuong${String(dinhLuong).replace(".", "_")}`
}
/* ============================
   PAD ROW to colCount
===============================*/
function padRow(row, colCount) {
    const out = row.slice()
    while (out.length < colCount) out.push("")
    return out
}
/* ============================
   NORMALIZE qty columns (sort)
   Expect input: [{dinhLuong, key, title, w}, ...]
===============================*/
function normalizeQtyCols(cotDinhLuong) {
    const fallback = [{ dinhLuong: 1, key: "DinhLuongMotPhan", title: "Định lượng 1 phần", w: 18 }]
    const list = Array.isArray(cotDinhLuong) && cotDinhLuong.length ? cotDinhLuong : fallback
    // giữ đúng key do UI tạo; chỉ bổ sung dinhLuong nếu thiếu
    const out = list.map((x) => ({
        dinhLuong: x.dinhLuong ?? x.part ?? 1,
        key: x.key,
        title: x.title || `Định lượng ${x.dinhLuong ?? x.part ?? 1} phần`,
        w: x.w || 18,
    }))
    out.sort((a, b) => Number(a.dinhLuong) - Number(b.dinhLuong))
    // đảm bảo luôn có 1 phần
    if (!out.some((x) => Number(x.dinhLuong) === 1)) {
        out.unshift({ dinhLuong: 1, key: "DinhLuongMotPhan", title: "Định lượng 1 phần", w: 18 })
    }
    return out
}
/* ============================
   COL COUNT
   Cột: STT + Nhóm + Thành phần + Đơn vị + (N cột định lượng) + Ghi chú
===============================*/
function getColCount(qtyCols) {
    const nQty = (qtyCols || []).length || 1
    return 4 + nQty + 1
}
/* ============================
   COLUMN WIDTHS (dynamic)
===============================*/
function getColWidthsDynamic(qtyCols) {
    const nQty = (qtyCols || []).length || 1
    const widths = [
        { wch: 6 },   // STT
        { wch: 18 },  // Nhóm
        { wch: 34 },  // Thành phần
        { wch: 10 },  // Đơn vị
    ]
    for (let i = 0; i < nQty; i++) widths.push({ wch: 18 }) // mỗi cột định lượng
    widths.push({ wch: 22 }) // Ghi chú
    return widths
}
/* ============================
   BUILD HEADER INFO (dynamic columns)
===============================*/
function buildHeaderInfo(meta, colCount) {
    const lastCol = colCount - 1
    const r1 = Array(colCount).fill("")
    r1[0] = { v: meta.company || "", s: { font: { bold: true, sz: 13 } } }
    r1[lastCol] = { v: meta.khuVuc ? `${meta.khuVuc}` : "", s: { font: { bold: true, sz: 11 } } }
    const r2 = Array(colCount).fill("")
    r2[0] = { v: `Chi nhánh: ${meta.chiNhanh || ""}`, s: { font: { sz: 11 } } }
    const r3 = Array(colCount).fill("")
    r3[0] = { v: "CÔNG THỨC CHẾ BIẾN", s: { font: { bold: true, sz: 14 } } }
    const r4 = Array(colCount).fill("")
    r4[0] = { v: `Tên sản phẩm: ${meta.tenMon || ""}`, s: { font: { bold: true, sz: 12 } } }
    return [r1, r2, r3, r4]
}
/* ============================
   BUILD TABLE HEADER (1 row)
===============================*/
function buildTableHeader(qtyCols, colCount) {
    const row = [
        { v: "STT", s: { font: { bold: true } } },
        { v: "Nhóm thành phần", s: { font: { bold: true } } },
        { v: "Thành phần", s: { font: { bold: true } } },
        { v: "Đơn vị", s: { font: { bold: true } } },
    ]
    qtyCols.forEach((c) => {
        row.push({ v: c.title || `Định lượng ${c.dinhLuong} phần`, s: { font: { bold: true } } })
    })
    row.push({ v: "Ghi chú", s: { font: { bold: true } } })
    return [padRow(row, colCount)]
}
/* ============================
   BUILD DATA ROWS
===============================*/
function buildDataRows(detailRows, qtyCols, colCount) {
    return (detailRows || []).map((r, idx) => {
        const row = [
            r.STT ?? (idx + 1),
            r.TenNhomVatTu ?? "",
            r.TenThayThe || r.TenHangHoa || "",
            r.TenDonVi ?? "",
        ]
        qtyCols.forEach((c) => {
            row.push(r?.[c.key] ?? "")
        })
        row.push(r.GhiChu ?? "")
        return padRow(row, colCount)
    })
}
/* ============================
   READ JSON "Sau khi nấu"
   Accept: object or JSON string
===============================*/
function readSauKhiNauJson(raw) {
    if (!raw) return {}
    if (typeof raw === "object") return { ...raw }
    if (typeof raw === "string") {
        try { return JSON.parse(raw) || {} } catch (e) { return {} }
    }
    return {}
}
/* ============================
   FOOTER INFO
===============================*/
function buildFooterInfo(meta, colCount) {
    return [
        padRow([""], colCount),
        padRow([{ v: `Hạn sử dụng: ${meta.hanSuDung || ""} giờ` }], colCount),
        padRow([{ v: `Bảo quản: ${meta.baoQuan || ""}` }], colCount),
        padRow([{ v: `Thiết bị bảo quản: ${meta.thietBiBaoQuan || ""}` }], colCount),
    ]
}
/* ============================
   SIGNATURE BLOCK
===============================*/
function buildSignatureBlock(meta, colCount) {
    const diaDiem = meta?.diaDiem || "..."
    const date = dayjs()
    const chucDanhKy = meta?.chucDanhKy || "QUẢN LÝ BẾP"
    const rowEmpty = padRow([""], colCount)
    const startSign = Math.max(0, colCount - 3)
    const rowDate = Array(colCount).fill("")
    rowDate[startSign] = {
        v: `${diaDiem}, Ngày ${date.format("DD")}  tháng ${date.format("MM")}  năm ${date.format("YYYY")}`,
        s: { font: { italic: true, sz: 11 }, alignment: { horizontal: "center" } },
    }
    const rowRole = Array(colCount).fill("")
    rowRole[startSign] = {
        v: chucDanhKy,
        s: { font: { bold: true, sz: 12 }, alignment: { horizontal: "center" } },
    }
    return [rowEmpty, rowDate, rowRole, rowEmpty]
}
/* ============================
   MERGE “Nhóm thành phần” theo block (cột B = index 1)
===============================*/
function buildGroupMerges(detailRows, firstDataRowIndex) {
    const merges = []
    const rows = detailRows || []
    if (!rows.length) return merges
    let start = 0
    while (start < rows.length) {
        const g = rows[start].TenNhomVatTu
        let end = start
        while (end + 1 < rows.length && rows[end + 1].TenNhomVatTu === g) end++
        if (end > start) {
            merges.push({
                s: { r: firstDataRowIndex + start, c: 1 },
                e: { r: firstDataRowIndex + end, c: 1 },
            })
        }
        start = end + 1
    }
    return merges
}
function buildSummaryRowsFromUI(meta, qtyCols, colCount) {
    const {
        donViTDL,
        donViSauKhiNau,
        tongDLTheoCot = {},
        sauKhiNauJson = {},
        haoHutTheoCot = {},
        loaiNguyenLieu = "",
        // các field TP của bảng chi phí (có truyền thì dùng, không thì bỏ qua)
        giaBan = 0,
        tiLeSoVoiChiPhi = 0,
        // thêm context để phân biệt đang xuất bảng nào
        exportType = "CONG_THUC", // "CONG_THUC" | "CHI_PHI"
    } = meta || {}
    const isTP = String(loaiNguyenLieu).toUpperCase() === "TP"
    // Dòng 1: Tổng định lượng (luôn có)
    const rowTong = ["", "", { v: "Tổng định lượng", s: { font: { bold: true } } }, donViTDL || ""]
    qtyCols.forEach((c) => rowTong.push(toNum(tongDLTheoCot?.[c.key])))
    rowTong.push("")
    // Công thức: TP chỉ có Tổng định lượng
    if (exportType === "CONG_THUC" && isTP) {
        return [padRow(rowTong, colCount)]
    }
    // Chi phí: TP có Giá bán + Tỉ lệ (Tổng chi phí xử lý bên exportBangChiPhiExcel)
    if (exportType === "CHI_PHI" && isTP) {
        const rowGiaBan = ["", "", { v: "Giá bán", s: { font: { bold: true } } }, "VNĐ"]
        qtyCols.forEach((c, i) => rowGiaBan.push(i === 0 ? toNum(giaBan) : ""))
        rowGiaBan.push("")
        const rowTiLe = ["", "", { v: "Tỉ lệ so với chi phí", s: { font: { bold: true } } }, "%"]
        qtyCols.forEach((c, i) => rowTiLe.push(i === 0 ? `${toNum(tiLeSoVoiChiPhi)}%` : ""))
        rowTiLe.push("")
        return [padRow(rowTong, colCount), padRow(rowGiaBan, colCount), padRow(rowTiLe, colCount)]
    }
    // Mặc định (KHÔNG TP): Tổng + Sau khi nấu + Hao hụt
    const rowSau = ["", "", { v: "Sau khi nấu", s: { font: { bold: true } } }, donViSauKhiNau || ""]
    qtyCols.forEach((c) => rowSau.push(toNum(sauKhiNauJson?.[jsonKey(c.dinhLuong)])))
    rowSau.push("")
    const rowHao = ["", "", { v: "Hao hụt", s: { font: { bold: true } } }, "%"]
    qtyCols.forEach((c) => rowHao.push(`${toNum(haoHutTheoCot?.[c.key])}%`))
    rowHao.push("")
    return [padRow(rowTong, colCount), padRow(rowSau, colCount), padRow(rowHao, colCount)]
}
/* ============================
   EXPORT MAIN
===============================*/
function exportCongThucCheBienExcel(params) {
    if (typeof XLSX === "undefined") {
        throw new Error("XLSX chưa được load. Hãy nhúng CDN xlsx-js-style trước.")
    }
    const {
        // header
        company = "CÔNG TY TNHH MTV THƯƠNG MẠI DỊCH VỤ TÔ MINH",
        chiNhanh = "",
        khuVuc = "",
        tenMon = "",
        // table data
        detailRows = [],
        // dynamic qty cols from UI
        cotDinhLuong = [{ dinhLuong: 1, key: "DinhLuongMotPhan", title: "Định lượng 1 phần" }],
        // units
        donViTDL = "",
        donViSauKhiNau = "",
        // JSON Sau khi nấu
        // ex: { DinhLuong2: 3560, DinhLuong3: 7120 }
        DinhLuongCol_Json = {},
        // footer
        hanSuDung = "",
        baoQuan = "",
        thietBiBaoQuan = "",
        // output
        sheetName = "CongThuc",
        fileName,
        // signature
        diaDiem = "...",
        chucDanhKy = "QUẢN LÝ BẾP",
        tongDLTheoCot = {},
        sauKhiNauJson = {},
        haoHutTheoCot = {},
        loaiNguyenLieu = "",      // "TP" | "BTP" | ...
        giaBan = 0,               // giá bán món
        tiLeSoVoiChiPhi = 0,      // % (vd: 35)
    } = params || {}
    const qtyCols = normalizeQtyCols(cotDinhLuong)
    const colCount = getColCount(qtyCols)
    const endColIndex = colCount - 1
    const borderStyle = getAllBorderStyle()
    const workbook = XLSX.utils.book_new()
    // ===== build data =====
    const headerInfo = buildHeaderInfo({ company, chiNhanh, khuVuc, tenMon }, colCount)
    const tableHeader = buildTableHeader(qtyCols, colCount)
    const dataRows = buildDataRows(detailRows, qtyCols, colCount)
    const summaryRows = buildSummaryRowsFromUI(
        {
            donViTDL,
            donViSauKhiNau,
            tongDLTheoCot,
            sauKhiNauJson: sauKhiNauJson && Object.keys(sauKhiNauJson).length ? sauKhiNauJson : DinhLuongCol_Json,
            haoHutTheoCot,
            loaiNguyenLieu,
            giaBan,
            tiLeSoVoiChiPhi,
        },
        qtyCols,
        colCount
    )
    const footerInfo = buildFooterInfo({ hanSuDung, baoQuan, thietBiBaoQuan }, colCount)
    const signBlock = buildSignatureBlock({ diaDiem, chucDanhKy }, colCount)
    const sheetData = [
        ...headerInfo,
        ...tableHeader,
        ...dataRows,
        ...summaryRows,
        ...footerInfo,
        ...signBlock,
    ]
    const ws = XLSX.utils.aoa_to_sheet(sheetData)
    // ===== indexes =====
    const headerRows = headerInfo.length           // 4
    const tableHeaderRowIndex = headerRows         // 4
    const firstDataRowIndex = tableHeaderRowIndex + 1
    // ===== merges =====
    const merges = []
    // company: A1..(colCount-2)
    merges.push({ s: { r: 0, c: 0 }, e: { r: 0, c: Math.max(0, colCount - 2) } })
    // A2..last
    merges.push({ s: { r: 1, c: 0 }, e: { r: 1, c: endColIndex } })
    merges.push({ s: { r: 2, c: 0 }, e: { r: 2, c: endColIndex } })
    merges.push({ s: { r: 3, c: 0 }, e: { r: 3, c: endColIndex } })
    // group merges at col "Nhóm" index 1
    merges.push(...buildGroupMerges(detailRows, firstDataRowIndex))
    // footer merges (HSD/BQ/TBBQ lines)
    const footerStart = headerRows + tableHeader.length + dataRows.length + summaryRows.length
    merges.push({ s: { r: footerStart + 1, c: 0 }, e: { r: footerStart + 1, c: endColIndex } })
    merges.push({ s: { r: footerStart + 2, c: 0 }, e: { r: footerStart + 2, c: endColIndex } })
    merges.push({ s: { r: footerStart + 3, c: 0 }, e: { r: footerStart + 3, c: endColIndex } })
    // signature merges: from colCount-3 .. last on 2 lines
    const signStart = footerStart + footerInfo.length
    const startSign = Math.max(0, colCount - 3)
    merges.push({ s: { r: signStart + 1, c: startSign }, e: { r: signStart + 1, c: endColIndex } })
    merges.push({ s: { r: signStart + 2, c: startSign }, e: { r: signStart + 2, c: endColIndex } })
    ws["!merges"] = merges
    // ===== styles =====
    const baseCellStyle = {
        border: borderStyle,
        alignment: { horizontal: "center", vertical: "center", wrapText: true },
        font: { sz: 11 },
    }
    // apply style for table region (header + data + summary)
    const startRowForTable = tableHeaderRowIndex
    const endRowForTable = tableHeaderRowIndex + tableHeader.length + dataRows.length + summaryRows.length - 1
    applyStyleToRange(ws, { r: startRowForTable, c: 0 }, { r: endRowForTable, c: endColIndex }, baseCellStyle)
    // header table
    applyStyleToRange(ws, { r: tableHeaderRowIndex, c: 0 }, { r: tableHeaderRowIndex, c: endColIndex }, {
        ...baseCellStyle,
        font: { sz: 11, bold: true },
        fill: { fgColor: { rgb: "EDEDED" } },
    })
    // align left: "Thành phần"(c=2) and "Ghi chú"(c=endColIndex)
    for (let r = firstDataRowIndex; r < firstDataRowIndex + dataRows.length; r++) {
        applyStyleToRange(ws, { r, c: 2 }, { r, c: 2 }, { alignment: { horizontal: "left", vertical: "center", wrapText: true } })
        applyStyleToRange(ws, { r, c: endColIndex }, { r, c: endColIndex }, { alignment: { horizontal: "left", vertical: "center", wrapText: true } })
    }
    // summary row styles
    // summary row styles (dynamic theo summaryRows.length)
    const rowTong = firstDataRowIndex + dataRows.length
    applyStyleToRange(ws, { r: rowTong, c: 0 }, { r: rowTong, c: endColIndex }, {
        ...baseCellStyle,
        font: { sz: 11, bold: true },
    })
    if (summaryRows.length >= 2) {
        const rowSau = rowTong + 1
        applyStyleToRange(ws, { r: rowSau, c: 0 }, { r: rowSau, c: endColIndex }, {
            ...baseCellStyle,
            font: { sz: 11, bold: true },
        })
    }
    if (summaryRows.length >= 3) {
        const rowHao = rowTong + 2
        applyStyleToRange(ws, { r: rowHao, c: 0 }, { r: rowHao, c: endColIndex }, {
            ...baseCellStyle,
            font: { sz: 11, bold: true },
        })
        // make hao hụt percent cells red (qty columns are from c=4 to c=endColIndex-1)
        if (endColIndex - 1 >= 4) {
            applyStyleToRange(ws, { r: rowHao, c: 4 }, { r: rowHao, c: endColIndex - 1 }, {
                font: { sz: 11, bold: true, color: { rgb: "C00000" } },
            })
        }
    }
    // style title row "CÔNG THỨC CHẾ BIẾN"
    applyStyleToRange(ws, { r: 2, c: 0 }, { r: 2, c: endColIndex }, {
        alignment: { horizontal: "center", vertical: "center", wrapText: true },
        font: { bold: true, sz: 14 },
    })
    // ===== rows heights + cols widths =====
    ws["!rows"] = [
        { hpt: 24 }, // company
        { hpt: 18 }, // chi nhánh
        { hpt: 22 }, // title
        { hpt: 22 }, // ten mon
    ]
    ws["!cols"] = getColWidthsDynamic(qtyCols)
    // ===== write file =====
    XLSX.utils.book_append_sheet(workbook, ws, sheetName)
    const outName = fileName ? sanitizeFileName(fileName) : `CONG_THUC_${sanitizeFileName(tenMon)}.xlsx`
    XLSX.writeFile(workbook, outName)
}
function exportBangChiPhiExcel(params) {
    if (typeof XLSX === "undefined") {
        throw new Error("XLSX chưa được load. Hãy nhúng CDN xlsx-js-style trước.");
    }
    const {
        company = "",
        chiNhanh = "",
        khuVuc = "",
        tenMon = "",
        // UI columns
        tatCaCot = [],
        detailRows = [],
        cotDinhLuong = [],
        // units + tfoot UI
        donViTDL = "",
        donViSauKhiNau = "",
        sauKhiNauJson = {},
        tongDLTheoCot = {},
        haoHutTheoCot = {},
        tongChiPhiTheoCot = {},
        tongChiPhi = 0,
        loaiNguyenLieu = "",
        giaBan = 0,
        tiLeSoVoiChiPhi = 0,
        // footer giống exportCongThucCheBienExcel
        hanSuDung = "",
        baoQuan = "",
        thietBiBaoQuan = "",
        // signature giống exportCongThucCheBienExcel
        diaDiem = "...",
        chucDanhKy = "QUẢN LÝ BẾP",
        // output
        fileName = `BangChiPhi_${sanitizeFileName(tenMon)}.xlsx`,
        sheetName = "Bang Chi Phi",
        // (optional) nếu UI có cột nhóm để merge (vd: TenNhomNguyenLieu)
        groupFieldKey = "TenNhomNguyenLieu", // data field
        groupColKey = "TenTinhChat",         // column key trên UI để merge theo nhóm (tùy bạn)
    } = params || {};
    // Kiểm tra xem tatCaCot có cột GhiChu không
    const hasGhiChuCol = tatCaCot.some(c => c.key === "GhiChu");
    // Lọc bỏ cột action để tính colCount thực tế
    const validCols = tatCaCot.filter(c => c.key !== "act");
    // Tính colCount thực tế (bao gồm cả cột GhiChu nếu chưa có)
    const actualColCount = hasGhiChuCol ? validCols.length : validCols.length + 1;
    const colCount = actualColCount;
    const endCol = colCount - 1;
    const borderStyle = getAllBorderStyle();
    const findCol = (key) => validCols.findIndex(x => x.key === key);
    const mkEmpty = () => Array(colCount).fill("");
    // ===== HEADER giống bản chuẩn =====
    const headerInfo = buildHeaderInfo({ company, chiNhanh, khuVuc, tenMon }, colCount);
    // ===== TABLE HEADER (1 dòng) =====
    // Thêm cột "Ghi chú" cố định vào cuối (trước cột action nếu có)
    const headerRow = tatCaCot
        .filter(c => c.key !== "act") // Loại bỏ cột action
        .map(c => ({ v: c.title || "", s: { font: { bold: true } } }));
    // Kiểm tra xem đã có cột GhiChu chưa
    if (!hasGhiChuCol) {
        headerRow.push({ v: "Ghi chú", s: { font: { bold: true } } });
    }
    const tableHeader = [headerRow];
    // ===== BODY =====
    const bodyRows = (detailRows || []).map((r, idx) => {
        const row = tatCaCot
            .filter(c => c.key !== "act") // Loại bỏ cột action
            .map((c) => {
                if (c.key === "STT") return r.STT ?? (idx + 1);
                // XỬ LÝ CỘT NGUYÊN VẬT LIỆU
                if (c.key === "NguyenVatLieu") {
                    return r.TenThayThe || r.TenHangHoa || r.NguyenVatLieu || "";
                }
                // XỬ LÝ CỘT GHI CHÚ
                if (c.key === "GhiChu") {
                    return r.GhiChu ?? "";
                }
                if (c.key === "DonVi") {
                    return r.TenDonVi ?? "";
                }
                if (c.key === "Is_TinhDinhLuong") return r.Is_TinhDinhLuong ? "✓" : "";
                if (c.key === "GiaNguyenVatLieu" || c.key === "ChiPhiSuDung") return toNum(r[c.key]);
                if (c.isCotDinhLuong) return toNum(r[c.key]);
                return r[c.key] ?? "";
            });
        // Thêm cột Ghi chú cố định nếu UI không có
        if (!hasGhiChuCol) {
            row.push(r.GhiChu ?? "");
        }
        return row;
    });
    // ===== FOOTER UI (4 dòng) =====
    const colLabel = Math.max(0, findCol("GiaNguyenVatLieu"));
    const colDonVi = Math.max(0, findCol("DonVi"));
    const colCPSD = Math.max(0, findCol("ChiPhiSuDung"));
    const qtyKeys = (cotDinhLuong || []).map(x => x.key);
    const rowTongDL = mkEmpty();
    rowTongDL[colLabel] = { v: "Tổng định lượng", s: { font: { bold: true } } };
    rowTongDL[colDonVi] = donViTDL || "";
    qtyKeys.forEach((k) => {
        const idx = findCol(k);
        if (idx >= 0) rowTongDL[idx] = toNum(tongDLTheoCot[k]);
    });
    const isTP = String(loaiNguyenLieu).toUpperCase() === "TP";
    let rowSau = mkEmpty();
    let rowHao = mkEmpty();
    if (isTP) {
        // ===== TP: thay "Sau khi nấu" bằng "Giá bán" =====
        rowSau[colLabel] = { v: "Giá bán", s: { font: { bold: true } } };
        rowSau[colDonVi] = "VNĐ";
        // điền giá bán vào cột định lượng đầu tiên (để đẹp), các cột khác để trống
        let filled = false;
        qtyKeys.forEach((k) => {
            const idx = findCol(k);
            if (idx >= 0 && !filled) {
                rowSau[idx] = toNum(giaBan);
                filled = true;
            }
        });
        // ===== TP: thay "Hao hụt" bằng "Tỉ lệ so với chi phí" =====
        rowHao[colLabel] = { v: "Tỉ lệ so với chi phí", s: { font: { bold: true } } };
        rowHao[colDonVi] = "%";
        filled = false;
        qtyKeys.forEach((k) => {
            const idx = findCol(k);
            if (idx >= 0 && !filled) {
                rowHao[idx] = `${toNum(tiLeSoVoiChiPhi)}%`;
                filled = true;
            }
        });
    } else {
        // ===== BTP, NL: giữ logic cũ =====
        rowSau[colLabel] = { v: "Sau khi nấu", s: { font: { bold: true } } };
        rowSau[colDonVi] = donViSauKhiNau || "";
        qtyKeys.forEach((k) => {
            const col = (cotDinhLuong || []).find(x => x.key === k);
            const v = col ? toNum(sauKhiNauJson[jsonKey(col.dinhLuong)]) : 0;
            const idx = findCol(k);
            if (idx >= 0) rowSau[idx] = v;
        });
        rowHao[colLabel] = { v: "Hao hụt", s: { font: { bold: true } } };
        rowHao[colDonVi] = "%";
        qtyKeys.forEach((k) => {
            const idx = findCol(k);
            if (idx >= 0) rowHao[idx] = `${toNum(haoHutTheoCot[k])}%`;
        });
    }
    // ===== Dòng 4: Tổng chi phí (GIỮ NGUYÊN) =====
    const rowCost = mkEmpty();
    rowCost[colLabel] = { v: "Tổng chi phí", s: { font: { bold: true } } };
    rowCost[colDonVi] = "VNĐ";
    qtyKeys.forEach((k) => {
        const idx = findCol(k);
        if (idx >= 0) rowCost[idx] = toNum(tongChiPhiTheoCot[k]);
    });
    if (colCPSD >= 0) rowCost[colCPSD] = toNum(tongChiPhi);
    // ===== FOOTER giống bản chuẩn =====
    const footerInfo = buildFooterInfo({ hanSuDung, baoQuan, thietBiBaoQuan }, colCount);
    const signBlock = buildSignatureBlock({ diaDiem, chucDanhKy }, colCount);
    const forceColCount = (rows) => rows.map(r => padRow(r, colCount));
    // ===== SHEET DATA =====
    const sheetData = forceColCount([
        ...headerInfo,
        ...tableHeader,
        ...bodyRows,
        rowTongDL,
        rowSau,
        rowHao,
        rowCost,
        ...footerInfo,
        ...signBlock,
    ]);
    const ws = XLSX.utils.aoa_to_sheet(sheetData);
    // ===== INDEXES =====
    const headerRowsCount = headerInfo.length;            // 4
    const tableHeaderRowIndex = headerRowsCount;          // 4
    const firstDataRowIndex = tableHeaderRowIndex + 1;
    const footerUiStartRow = firstDataRowIndex + bodyRows.length; // rowTongDL
    const footerStdStartRow = footerUiStartRow + 4;       // sau 4 dòng footer UI
    const signStartRow = footerStdStartRow + footerInfo.length;
    // ===== MERGES giống bản chuẩn =====
    const merges = [];
    // company row: A1..(colCount-2)
    merges.push({ s: { r: 0, c: 0 }, e: { r: 0, c: Math.max(0, colCount - 2) } });
    merges.push({ s: { r: 1, c: 0 }, e: { r: 1, c: endCol } });
    merges.push({ s: { r: 2, c: 0 }, e: { r: 2, c: endCol } });
    merges.push({ s: { r: 3, c: 0 }, e: { r: 3, c: endCol } });
    // footer chuẩn: merge 3 dòng HSD/BQ/TBBQ (nằm trong footerInfo: [blank, HSD, BQ, TBBQ])
    // footerInfo index: 0 blank, 1 HSD, 2 BQ, 3 TBBQ
    merges.push({ s: { r: footerStdStartRow + 1, c: 0 }, e: { r: footerStdStartRow + 1, c: endCol } });
    merges.push({ s: { r: footerStdStartRow + 2, c: 0 }, e: { r: footerStdStartRow + 2, c: endCol } });
    merges.push({ s: { r: footerStdStartRow + 3, c: 0 }, e: { r: footerStdStartRow + 3, c: endCol } });
    // signature merges: from colCount-3 .. last on 2 lines (date + role)
    const startSign = Math.max(0, colCount - 3);
    merges.push({ s: { r: signStartRow + 1, c: startSign }, e: { r: signStartRow + 1, c: endCol } });
    merges.push({ s: { r: signStartRow + 2, c: startSign }, e: { r: signStartRow + 2, c: endCol } });
    // (optional) merge nhóm theo block nếu UI có cột nhóm
    const groupColIndex = findCol(groupColKey);
    if (groupColIndex >= 0 && detailRows && detailRows.length) {
        let start = 0;
        while (start < detailRows.length) {
            const g = detailRows[start]?.[groupFieldKey];
            let end = start;
            while (end + 1 < detailRows.length && detailRows[end + 1]?.[groupFieldKey] === g) end++;
            if (end > start) {
                merges.push({
                    s: { r: firstDataRowIndex + start, c: groupColIndex },
                    e: { r: firstDataRowIndex + end, c: groupColIndex },
                });
            }
            start = end + 1;
        }
    }
    ws["!merges"] = merges;
    // ===== STYLES giống bản chuẩn =====
    const baseCellStyle = {
        border: borderStyle,
        alignment: { horizontal: "center", vertical: "center", wrapText: true },
        font: { sz: 11 },
    };
    // Apply style vùng bảng: table header + body + 4 dòng footer UI
    const endRowTable = footerUiStartRow + 4 - 1;
    applyStyleToRange(ws, { r: tableHeaderRowIndex, c: 0 }, { r: endRowTable, c: endCol }, baseCellStyle);
    // ===== ALIGN LEFT: Nguyên vật liệu + Ghi chú (chỉ body rows) =====
    const colNguyenVatLieu = findCol("NguyenVatLieu");
    // Tìm cột GhiChu: nếu có trong tatCaCot thì dùng, nếu không thì là cột cuối
    let colGhiChu = findCol("GhiChu");
    if (colGhiChu < 0 && !hasGhiChuCol) {
        colGhiChu = colCount - 1; // Cột cuối cùng
    }
    for (let r = firstDataRowIndex; r < firstDataRowIndex + bodyRows.length; r++) {
        if (colNguyenVatLieu >= 0) {
            applyStyleToRange(ws, { r, c: colNguyenVatLieu }, { r, c: colNguyenVatLieu }, {
                alignment: { horizontal: "left", vertical: "center", wrapText: true },
            });
        }
        if (colGhiChu >= 0) {
            applyStyleToRange(ws, { r, c: colGhiChu }, { r, c: colGhiChu }, {
                alignment: { horizontal: "left", vertical: "center", wrapText: true },
            });
        }
    }
    // Header table
    applyStyleToRange(ws, { r: tableHeaderRowIndex, c: 0 }, { r: tableHeaderRowIndex, c: endCol }, {
        ...baseCellStyle,
        font: { sz: 11, bold: true },
        fill: { fgColor: { rgb: "EDEDED" } },
    });
    // Title row "CÔNG THỨC CHẾ BIẾN" ở headerInfo row index 2
    applyStyleToRange(ws, { r: 2, c: 0 }, { r: 2, c: endCol }, {
        alignment: { horizontal: "center", vertical: "center", wrapText: true },
        font: { bold: true, sz: 14 },
    });
    // Style 3 dòng summary UI giống bản chuẩn (Tổng/Sau/Hao) + thêm dòng Tổng chi phí
    const rTong = footerUiStartRow;
    const rSau = footerUiStartRow + 1;
    const rHao = footerUiStartRow + 2;
    const rCost = footerUiStartRow + 3;
    applyStyleToRange(ws, { r: rTong, c: 0 }, { r: rTong, c: endCol }, {
        ...baseCellStyle,
        font: { sz: 11, bold: true },
    });
    applyStyleToRange(ws, { r: rSau, c: 0 }, { r: rSau, c: endCol }, {
        ...baseCellStyle,
        font: { sz: 11, bold: true },
    });
    applyStyleToRange(ws, { r: rHao, c: 0 }, { r: rHao, c: endCol }, {
        ...baseCellStyle,
        font: { sz: 11, bold: true },
    });
    applyStyleToRange(ws, { r: rCost, c: 0 }, { r: rCost, c: endCol }, {
        ...baseCellStyle,
        font: { sz: 11, bold: true },
    });
    // make hao hụt percent cells red cho các cột định lượng (nếu có)
    qtyKeys.forEach((k) => {
        const idx = findCol(k);
        if (idx >= 0) {
            applyStyleToRange(ws, { r: rHao, c: idx }, { r: rHao, c: idx }, {
                font: { sz: 11, bold: true, color: { rgb: "C00000" } },
            });
        }
    });
    // ===== ROW HEIGHTS + COL WIDTHS giống bản chuẩn =====
    ws["!rows"] = [
        { hpt: 24 }, // company
        { hpt: 18 }, // chi nhánh
        { hpt: 22 }, // title
        { hpt: 22 }, // ten mon
    ];
    ws["!cols"] = tatCaCot.map(c => ({ wch: Math.max(8, Math.round((c.width || 80) / 6)) }));
    // ===== WRITE FILE =====
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, sheetName);
    XLSX.writeFile(wb, sanitizeFileName(fileName));
}
/**
 * Tạo và tải template Excel để import công thức
 */
function exportTemplateImportCongThuc() {
    if (typeof XLSX === 'undefined') {
        showToast.error('Thư viện XLSX chưa được tải!')
        return
    }
    // Dữ liệu mẫu
    const templateData = [
        // Header row
        [
            'Mã sản phẩm',
            'Tên Sản Phẩm',
            'Nơi sử dụng',
            'Khu vực chế biến',
            'Nhóm sản phẩm',
            'Nơi sản xuất',
            'Đơn vị ĐL',
            'Mã NL',
            'Tên Nguyên Liệu',
            'Đơn vị sử dụng',
            'Số Lượng SD',
            'Sau khi nấu'
        ],
        // Sample data - 5 nguyên liệu mẫu
        [
            'SCLX',
            'Xốt Socola Xanh Lamington_BTP',
            'Zen Bakery',
            'Nhóm Nhân bánh',
            'Bán thành phẩm',
            'Zen Bakery',
            'Gram',
            'B353',
            'Cotta Socola Xanh Compound (khối)',
            'Gram',
            50,
            190
        ],
        [
            'SCLX',
            'Xốt Socola Xanh Lamington_BTP',
            'Zen Bakery',
            'Nhóm Nhân bánh',
            'Bán thành phẩm',
            'Zen Bakery',
            'Gram',
            'B343',
            'Colatta Socola Trắng Compound (khối)',
            'Gram',
            100,
            190
        ],
        [
            'SCLX',
            'Xốt Socola Xanh Lamington_BTP',
            'Zen Bakery',
            'Nhóm Nhân bánh',
            'Bán thành phẩm',
            'Zen Bakery',
            'Gram',
            'B0216',
            'Rượu Dark Captain 750ml',
            'Gram',
            4,
            190
        ],
        [
            'SCLX',
            'Xốt Socola Xanh Lamington_BTP',
            'Zen Bakery',
            'Nhóm Nhân bánh',
            'Bán thành phẩm',
            'Zen Bakery',
            'Gram',
            'B505',
            'Bơ lạt PL790LTU-V Vivo 15Kg',
            'Gram',
            10,
            190
        ],
        [
            'SCLX',
            'Xốt Socola Xanh Lamington_BTP',
            'Zen Bakery',
            'Nhóm Nhân bánh',
            'Bán thành phẩm',
            'Zen Bakery',
            'Gram',
            'B0456',
            'Kem đánh bông Professional Avonmore 1L',
            'Gram',
            35,
            190
        ]
    ]
    // Tạo workbook và worksheet
    const wb = XLSX.utils.book_new()
    const ws = XLSX.utils.aoa_to_sheet(templateData)
    // Thiết lập độ rộng cột
    ws['!cols'] = [
        { wch: 18 }, // Mã sản phẩm
        { wch: 35 }, // Tên Sản Phẩm
        { wch: 15 }, // Nơi sử dụng
        { wch: 20 }, // Khu vực chế biến
        { wch: 18 }, // Nhóm sản phẩm
        { wch: 15 }, // Nơi sản xuất
        { wch: 12 }, // Đơn vị ĐL
        { wch: 12 }, // Mã NL
        { wch: 35 }, // Tên Nguyên Liệu
        { wch: 15 }, // Đơn vị sử dụng
        { wch: 12 },  // Số Lượng SD
        { wch: 15 }  // Sau khi nấu
    ]
    // Style cho header
    const range = XLSX.utils.decode_range(ws['!ref'])
    for (let C = range.s.c; C <= range.e.c; ++C) {
        const address = XLSX.utils.encode_col(C) + "1"
        if (!ws[address]) continue
        ws[address].s = {
            font: { bold: true, color: { rgb: "FFFFFF" }, sz: 11 },
            fill: { fgColor: { rgb: "4472C4" } },
            alignment: { horizontal: "center", vertical: "center", wrapText: true },
            border: {
                top: { style: 'thin', color: { rgb: "000000" } },
                bottom: { style: 'thin', color: { rgb: "000000" } },
                left: { style: 'thin', color: { rgb: "000000" } },
                right: { style: 'thin', color: { rgb: "000000" } }
            }
        }
    }
    // Thêm border cho tất cả cells
    for (let R = range.s.r; R <= range.e.r; ++R) {
        for (let C = range.s.c; C <= range.e.c; ++C) {
            const address = XLSX.utils.encode_cell({ r: R, c: C })
            if (!ws[address]) continue
            if (!ws[address].s) ws[address].s = {}
            ws[address].s.border = {
                top: { style: 'thin', color: { rgb: "D0D0D0" } },
                bottom: { style: 'thin', color: { rgb: "D0D0D0" } },
                left: { style: 'thin', color: { rgb: "D0D0D0" } },
                right: { style: 'thin', color: { rgb: "D0D0D0" } }
            }
        }
    }
    XLSX.utils.book_append_sheet(wb, ws, 'Template')
    const fileName = `Template_Import_CongThuc_${new Date().toISOString().slice(0, 10)}.xlsx`
    XLSX.writeFile(wb, fileName)
    showToast.success('Đã tải template thành công!')
}