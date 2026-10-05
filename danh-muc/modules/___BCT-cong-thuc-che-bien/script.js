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
    r1[0] = { v: meta.company || "", s: { font: { bold: true, sz: 13, color: { rgb: "1F4E79" } } } }
    r1[lastCol] = { v: meta.khuVuc ? `${meta.khuVuc}` : "", s: { font: { bold: true, sz: 11 } } }
    const r2 = Array(colCount).fill("")
    r2[0] = { v: `Chi nhánh: ${meta.chiNhanh || ""}`, s: { font: { sz: 11 } } }
    const r3 = Array(colCount).fill("")
    r3[0] = { v: "CÔNG THỨC CHẾ BIẾN", s: { font: { bold: true, sz: 14 } } }
    const r4 = Array(colCount).fill("")
    r4[0] = { v: `Tên sản phẩm: ${meta.tenMon || ""}`, s: { font: { bold: true, sz: 12, color: { rgb: "1F4E79" } } } }
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
            r.TenNhomNguyenLieu ?? "",
            r.TenHangHoa ?? "",
            r.DonVi ?? "",
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
   BUILD SUMMARY ROWS (3 rows)
   - Tổng: tự tính từ detailRows theo c.key
   - Sau khi nấu: lấy từ JSON user nhập (KHÔNG auto-calc)
   - Hao hụt: % = (tong - sau)/tong
===============================*/
function buildSummaryRows(meta, detailRows, qtyCols, colCount) {
    const tongByQty = qtyCols.map((c) => {
        return (detailRows || []).reduce((s, r) => s + toNum(r?.[c.key]), 0)
    })
    const sauJson = readSauKhiNauJson(meta.DinhLuongCol_Json)
    const sauByQty = qtyCols.map((c) => {
        const k = jsonKey(c.dinhLuong)
        return toNum(sauJson[k])
    })
    const haoByQty = qtyCols.map((c, i) => {
        const tong = toNum(tongByQty[i])
        const sau = toNum(sauByQty[i])
        return tong > 0 ? Math.round(((tong - sau) / tong) * 100) : 0
    })
    // Note: 2 cột đầu để canh theo layout bạn đang dùng: (STT, Nhóm)
    const rowTong = ["", "", { v: "Tổng định lượng", s: { font: { bold: true } } }, meta.donViTDL || ""]
    tongByQty.forEach((v) => rowTong.push(v))
    rowTong.push("")
    const rowSau = ["", "", { v: "Sau khi nấu", s: { font: { bold: true } } }, meta.donViSauKhiNau || ""]
    sauByQty.forEach((v) => rowSau.push(v))
    rowSau.push("")
    const rowHao = ["", "", { v: "Hao hụt", s: { font: { bold: true } } }, "%"]
    haoByQty.forEach((p) => rowHao.push(`${p}%`))
    rowHao.push("")
    return [padRow(rowTong, colCount), padRow(rowSau, colCount), padRow(rowHao, colCount)]
}
/* ============================
   FOOTER INFO
===============================*/
function buildFooterInfo(meta, colCount) {
    return [
        padRow([""], colCount),
        padRow([{ v: `Hạn sử dụng: ${meta.hanSuDung || ""}` }], colCount),
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
        const g = rows[start].TenNhomNguyenLieu
        let end = start
        while (end + 1 < rows.length && rows[end + 1].TenNhomNguyenLieu === g) end++
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
    const summaryRows = buildSummaryRows(
        { donViTDL, donViSauKhiNau, DinhLuongCol_Json },
        detailRows,
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
    const rowTong = firstDataRowIndex + dataRows.length
    const rowSau = rowTong + 1
    const rowHao = rowTong + 2
    applyStyleToRange(ws, { r: rowTong, c: 0 }, { r: rowTong, c: endColIndex }, {
        ...baseCellStyle,
        fill: { fgColor: { rgb: "F2F2F2" } },
        font: { sz: 11, bold: true },
    })
    applyStyleToRange(ws, { r: rowSau, c: 0 }, { r: rowSau, c: endColIndex }, {
        ...baseCellStyle,
        fill: { fgColor: { rgb: "FFF2CC" } },
        font: { sz: 11, bold: true },
    })
    applyStyleToRange(ws, { r: rowHao, c: 0 }, { r: rowHao, c: endColIndex }, {
        ...baseCellStyle,
        fill: { fgColor: { rgb: "FCE4D6" } },
        font: { sz: 11, bold: true },
    })
    // make hao hut percent cells red (qty columns are from c=4 to c=endColIndex-1)
    if (endColIndex - 1 >= 4) {
        applyStyleToRange(ws, { r: rowHao, c: 4 }, { r: rowHao, c: endColIndex - 1 }, {
            font: { sz: 11, bold: true, color: { rgb: "C00000" } },
        })
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