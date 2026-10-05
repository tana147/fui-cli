function autoLogOut() {
    ajaxCALL("/Security/SignOut", { SignOutAll: false })
    setCookie("awt", "", -1, "." + getDomainWithoutSubdomain(location.href))
    vueData.user = { UserID: null }
}
function InFileKetCa(data) {
    const CT_KetCa = data.DTKetCa[0][0]
    const DS_NhomSanPham = data.DTKetCa[1]
    const DS_SanPham = data.DTKetCa[2]
    const CT_Tong = data.DTKetCa[3][0]
    const DS_ChuaThanhToan = data.DTKetCa[4]
    const DS_HoaDonHuy = data.DTKetCa[5]
    const CT_KiemDem = data.DTKetCa[6][0]
    const DS_MonHuy = data.DTKetCa[7]
    //Xử lý danh sách sản phẩm
    let tableSanPham = []
    let tableSanPham_Sum = 0
    tableSanPham.push([{ text: "Chi tiết món (Bakery)", colSpan: 5, style: "tableHeader", alignment: "center" }, {}, {}, {}, {}])
    tableSanPham.push([
        { text: "Tên sản phẩm", style: "tableSubHeader", alignment: "center" },
        { text: "Đơn vị", style: "tableSubHeader", alignment: "center" },
        { text: "Số lượng", style: "tableSubHeader", alignment: "right" },
        { text: "Đơn giá", style: "tableSubHeader", alignment: "right" },
        { text: "Doanh thu", style: "tableSubHeader", alignment: "right" },
    ])
    DS_SanPham.forEach((item) => {
        tableSanPham_Sum += item.ThanhTien
        tableSanPham.push([
            { text: item.TenSanPham, alignment: "center", style: "tableBody" },
            { text: item.TenDonViTinh, alignment: "center", style: "tableBody" },
            { text: item.SoLuong, alignment: "right", style: "tableBody" },
            { text: item.DonGia.toLocaleString("vi-vn"), alignment: "right", style: "tableBody" },
            { text: item.ThanhTien.toLocaleString("vi-vn"), alignment: "right", style: "tableBody" },
        ])
    })
    tableSanPham.push([{ text: "Tổng", colSpan: 4, style: "tableFooter", alignment: "center" }, {}, {}, {}, { text: tableSanPham_Sum.toLocaleString("vi-vn"), style: "tableFooter", alignment: "right" }])
    //Xử lý danh sách chi tiết kiểm đếm
    const menhGiaTien = [500000, 200000, 100000, 50000, 20000, 10000, 5000, 2000, 1000, 500]
    let tableKiemDem = []
    tableKiemDem.push([{ text: "Chi tiết kiểm đếm", colSpan: 3, style: "tableHeader", alignment: "center" }, {}, {}])
    tableKiemDem.push([
        { text: "Mệnh giá", style: "tableSubHeader", alignment: "center" },
        { text: "Số lượng", style: "tableSubHeader", alignment: "center" },
        { text: "Thành tiền", style: "tableSubHeader", alignment: "right" },
    ])
    menhGiaTien.forEach((item) => {
        tableKiemDem.push([
            { text: item.toLocaleString("vi-vn"), alignment: "center", style: "tableBody" },
            { text: CT_KiemDem[`To_` + item], alignment: "center", style: "tableBody" },
            { text: CT_KiemDem[`Tong_` + item].toLocaleString("vi-vn"), alignment: "right", style: "tableBody" },
        ])
    })
    tableKiemDem.push([{ text: "Tổng tiền (B)", colSpan: 2, style: "tableFooter", alignment: "center" }, {}, { text: CT_KiemDem.TongCong.toLocaleString("vi-vn"), style: "tableFooter", alignment: "right" }])
    //Xử lý danh sách doanh thu theo nhóm sản phẩm
    let tableNhomSanPham = []
    let tableNhomSanPham_Sum = 0
    tableNhomSanPham.push([{ text: "Doanh thu theo nhóm (Bao gồm ZEN)", colSpan: 2, style: "tableHeader", alignment: "center" }, {}])
    DS_NhomSanPham.forEach((item) => {
        tableNhomSanPham_Sum += item.ThanhTien
        tableNhomSanPham.push([
            { text: item.TenNhomSanPham, alignment: "center", style: "tableBody" },
            { text: item.ThanhTien.toLocaleString("vi-vn"), alignment: "center", style: "tableBody" },
        ])
    })
    tableNhomSanPham.push([
        { text: "Tổng", alignment: "center", style: "tableFooter" },
        { text: tableNhomSanPham_Sum.toLocaleString("vi-vn"), alignment: "center", style: "tableFooter" },
    ])
    //Xử lý danh sách hóa đơn chưa thanh toán
    let tableHoaDonChuaThanhToan = []
    let tableHoaDonChuaThanhToan_Sum = 0
    tableHoaDonChuaThanhToan.push([{ text: "Hóa đơn chưa thanh toán", colSpan: 3, style: "tableHeader", alignment: "center" }, {}, {}])
    tableHoaDonChuaThanhToan.push([
        { text: "TK Order", alignment: "center", style: "tableSubHeader" },
        { text: "SL đơn", alignment: "center", style: "tableSubHeader" },
        { text: "Tổng tiền", alignment: "center", style: "tableSubHeader" },
    ])
    DS_ChuaThanhToan.forEach((item) => {
        tableHoaDonChuaThanhToan_Sum += item.TongTien
        tableHoaDonChuaThanhToan.push([
            { text: item.NhanVienThemMoi, alignment: "center", style: "tableBody" },
            { text: item.SoLuongDon, alignment: "center", style: "tableBody" },
            { text: item.TongTien.toLocaleString("vi-vn"), alignment: "center", style: "tableBody" },
        ])
    })
    tableHoaDonChuaThanhToan.push([{ text: "Tổng", colSpan: 2, style: "tableFooter", alignment: "center" }, {}, { text: tableHoaDonChuaThanhToan_Sum.toLocaleString("vi-vn"), style: "tableFooter", alignment: "center" }])
    //Xử lý danh sách hóa đơn hủy
    let tableHoaDonHuy = []
    let tableHoaDonHuy_Sum = 0
    tableHoaDonHuy.push([{ text: "Hóa đơn hủy", style: "tableHeader", colSpan: 3, alignment: "center" }, {}, {}])
    tableHoaDonHuy.push([
        { text: "Mã hóa đơn", style: "tableSubHeader", alignment: "center" },
        { text: "Tổng tiền", style: "tableSubHeader", alignment: "center" },
        { text: "Ghi chú", style: "tableSubHeader", alignment: "center" },
    ])
    DS_HoaDonHuy.forEach((item) => {
        tableHoaDonHuy_Sum += item.TienPhaiTra
        tableHoaDonHuy.push([
            { text: item.MaHoaDon, style: "tableBody", alignment: "center" },
            { text: item.TienPhaiTra.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
            { text: item.GhiChu, style: "tableBody", alignment: "center" },
        ])
    })
    tableHoaDonHuy.push([{ text: "Tổng", colSpan: 2, style: "tableFooter", alignment: "center" }, {}, { text: tableHoaDonHuy_Sum.toLocaleString("vi-vn"), style: "tableFooter", alignment: "center" }])
    //Xử lý danh sách món hủy
    let tableMonHuy = []
    tableMonHuy.push([{ text: "Món hủy", style: "tableHeader", colSpan: 4, alignment: "center" }])
    tableMonHuy.push([
        { text: "Mã hóa đơn", style: "tableSubHeader", alignment: "center" },
        { text: "Tên món", style: "tableSubHeader", alignment: "center" },
        { text: "Trạng thái", style: "tableSubHeader", alignment: "center" },
        { text: "Ghi chú", style: "tableSubHeader", alignment: "center" },
    ])
    DS_MonHuy.forEach((item) => {
        tableMonHuy.push([
            { text: item.MaHoaDon, style: "tableBody", alignment: "center" },
            { text: item.TenHienThi, style: "tableBody", alignment: "center" },
            { text: item.TrangThaiMon, style: "tableBody", alignment: "center" },
            { text: item.GhiChu, style: "tableBody", alignment: "center" },
        ])
    })
    tableMonHuy.push([{ text: "Tổng", colSpan: 3, style: "tableFooter", alignment: "center" }, {}, {}, { text: DS_MonHuy.length + " món", style: "tableFooter", alignment: "center" }])
    // Khởi tạo File PDF
    vueData.dataPDF = {
        pageSize: "A4",
        pageOrientation: "portrait",
        pageMargins: [10, 10],
        content: [
            { text: `PHIẾU KẾT CA ${CT_KetCa.TenCuaHang}`, alignment: "center", style: { bold: true, fontSize: 12 } },
            {
                layout: "noBorders",
                margin: [0, 5],
                table: {
                    widths: ["*", "*"],
                    body: [
                        [
                            { text: `Đóng ca làm việc: Ngày ${CT_KetCa.NgayKetCa} ${CT_KetCa.GioKetCa}`, alignment: "center" },
                            { text: `Nhân viên kết ca: ${CT_KetCa.NhanVienKetCa}`, alignment: "center" },
                        ],
                    ],
                },
            },
            {
                layout: "noBorders",
                table: {
                    widths: ["*", "*"],
                    body: [
                        [
                            {
                                style: "tableStyle",
                                table: {
                                    widths: ["*", "*"],
                                    heights: ["*", 32, 32, 32, 32, 32, "*"],
                                    body: [
                                        [{ text: "Tổng thu thực", colSpan: 2, style: "tableHeader", alignment: "center" }, {}],
                                        [
                                            { text: "\nTiền mặt (A)", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_TienMat.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "\nChuyển khoản", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_CK.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "\nQuẹt thẻ", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_QuetThe.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "\nShopeeFood", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_SPF.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "\nXanh SM", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_XSM.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "\nGrab", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_GRAB.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "\nHT1", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_HT1.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "\nHT2", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_HT2.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "\nHT3", style: "tableBody", alignment: "center" },
                                            { text: "\n" + CT_Tong.KhachTra_HT3.toLocaleString("vi-vn"), style: "tableBody", alignment: "center" },
                                        ],
                                        [
                                            { text: "Tổng", style: "tableFooter", alignment: "center" },
                                            { text: CT_Tong.TongDoanhThu.toLocaleString("vi-vn"), style: "tableFooter", alignment: "center" },
                                        ],
                                    ],
                                },
                            },
                            {
                                style: "tableStyle",
                                table: {
                                    widths: ["*", "*", "*"],
                                    body: tableKiemDem,
                                },
                            },
                        ],
                    ],
                },
            },
            {
                layout: "noBorders",
                margin: [0, 10],
                table: {
                    widths: ["*", "*"],
                    body: [
                        [
                            {
                                style: "tableStyle",
                                table: {
                                    widths: ["*", "*"],
                                    body: [
                                        [
                                            { text: "Tổng ZEN đã dùng", style: "tableSubHeader", alignment: "center" },
                                            { text: CT_Tong.KhachTra_Zen.toLocaleString("vi-vn"), style: "tableSubHeader", alignment: "center" },
                                        ],
                                    ],
                                },
                            },
                            {
                                style: "tableStyle",
                                table: {
                                    widths: ["*", "*"],
                                    body: [
                                        [
                                            { text: "Chênh lệch (B - A)", style: "tableSubHeader", alignment: "center" },
                                            { text: (CT_KiemDem.TongCong - CT_Tong.KhachTra_TienMat).toLocaleString("vi-vn"), style: "tableSubHeader", alignment: "center" },
                                        ],
                                    ],
                                },
                            },
                        ],
                    ],
                },
            },
            {
                margin: [0, 5],
                style: "tableStyle",
                table: {
                    widths: ["*"],
                    body: [[{ text: `Ghi chú: ${CT_KetCa.GhiChu}` }]],
                },
            },
            {
                layout: "noBorders",
                table: {
                    style: "tableExample",
                    widths: ["*", "*"],
                    body: [
                        [
                            {
                                style: "tableStyle",
                                table: {
                                    widths: ["*", "*"],
                                    body: tableNhomSanPham,
                                },
                            },
                            {
                                style: "tableStyle",
                                table: {
                                    widths: ["*", "*", "*"],
                                    body: tableHoaDonChuaThanhToan,
                                },
                            },
                        ],
                    ],
                },
            },
            {
                style: "tableStyle",
                margin: [0, 10],
                table: {
                    widths: ["*", "*", 250],
                    body: tableHoaDonHuy,
                },
            },
            {
                style: "tableStyle",
                margin: [0, 10],
                table: {
                    widths: ["*", "*", "*", "*"],
                    body: tableMonHuy,
                },
            },
            {
                style: "tableStyle",
                margin: [0, 10],
                table: {
                    widths: [250, "*", "*", "*", "*"],
                    body: tableSanPham,
                },
            },
        ],
        styles: {
            tableStyle: {
                fontSize: 10,
            },
            tableHeader: {
                bold: true,
                color: "#ffffff",
                fillColor: "#4caf50",
                fontSize: 12,
            },
            tableSubHeader: {
                bold: true,
                fillColor: "#b6e9b8",
                fontSize: 10,
            },
            tableBody: {
                //fillColor: '#f1f7f1',
                fontSize: 10,
            },
            tableFooter: {
                bold: true,
                fillColor: "#b6e9b8",
                fontSize: 10,
            },
        },
        defaultStyle: {
            alignment: "justify",
        },
    }
    //Generator PDF
    const pdfDocGenerator = pdfMake.createPdf(vueData.dataPDF)
    //Download file PDF
    if (vueData.IsDownload === "1") {
        pdfDocGenerator.download(`${CT_KetCa.TenCuaHang}_${CT_KetCa.NhanVienKetCa}_${CT_KetCa.NgayKetCa}_${CT_KetCa.GioKetCa}`)
    }
    //View PDF in iframe
    pdfDocGenerator.getDataUrl((dataUrl) => {
        const targetElement = document.querySelector("#iframeContainer")
        const iframe = document.createElement("iframe")
        iframe.src = dataUrl
        targetElement.appendChild(iframe)
    })
}