function loadLocalStorage() {
    const JSONLocal = localStorage.getItem('JSON_PRINT_PDF_QD_LAP_HD')
    if (JSONLocal) {
        const parseJSON = JSON.parse(JSONLocal)
        vueData.HocVienInfo = parseJSON
        if (vueData.HocVienInfo.NganhID && vueData.HocVienInfo.LopID) {
            let isValidInt = !isNaN(parseInt(vueData.HocVienInfo.LopID.substring(0, 2), 10))
            let lopIDValue = isValidInt ? parseInt(vueData.HocVienInfo.LopID.substring(0, 2), 10) : null
            // Các lớp có ID niên khóa từ 23 trở xuống là đồ án, ngược lại là luận văn
            if (
                (vueData.HocVienInfo.NganhID === 106 && (vueData.HocVienInfo.LopID === '23CP911' || vueData.HocVienInfo.LopID === '23CP912' || vueData.HocVienInfo.LopID === '23CP913')) ||
                (vueData.HocVienInfo.NganhID === 102 && isValidInt && lopIDValue <= 23)
            ) {
                vueData.CheckLopDoAn = true
            }
        }
    }
}
function InQuyetDinhDanhGiaLuanVanThacSi(data) {
    const HoiDong_Header = data.data[0][0]
    const HoiDong_ThanhVenList = data.data[1]
    let tableRows = []
    // Thêm dòng tiêu đề (ToTrinh_Header)
    tableRows.push([
        { text: 'STT', style: { bold: true }, alignment: 'center' },
        { text: 'Họ và tên \nHọc vị, học hàm', style: { bold: true }, alignment: 'center' },
        { text: 'Cơ quan công tác', style: { bold: true }, alignment: 'center' },
        { text: 'Chức trách \ntrong Hội đồng', style: { bold: true }, alignment: 'center' },
    ])
    // Sử dụng vòng lặp để them danh sách ẩn phẩm
    for (let i = 0; i < HoiDong_ThanhVenList.length; i++) {
        let thanhvien = HoiDong_ThanhVenList[i]
        tableRows.push([
            { text: ['\n', `${String(thanhvien.STT).padStart(2, '0')}`, '\n'], alignment: 'center' },
            { text: ['\n', `${thanhvien.HocViHocHam}. ${thanhvien.HoTenGiangVien}`, '\n'], alignment: 'left' },
            { text: ['\n', `${thanhvien.CoQuanCongTac} `, '\n'], alignment: 'left' },
            { text: ['\n', `${thanhvien.ChucTrach} `, '\n'], alignment: 'left' },
        ])
    }
    // Tạo table object với dòng dữ liệu được tạo ra
    let tableDSThanhVen = {
        widths: [30, 150, 200, 80],
        body: tableRows,
        heights: 40,
    }
    let rowTongThanhVien = []
    rowTongThanhVien.push([
        { text: `Hội đồng gồm ${String(HoiDong_Header.SLTVHD_So).padStart(2, '0')} (${HoiDong_Header.SLTVHD_Chu}) thành viên.`, alignment: 'left', colSpan: 4 },
        {},
        {},
        {},
    ])
    let tableTongThanhVien = {
        widths: [30, 150, 200, 70],
        body: rowTongThanhVien,
    }
    // Khởi tạo File PDF
    vueData.dataPDF = {
        pageSize: 'A4',
        pageOrientation: 'portrait',
        defaultStyle: {
            alignment: 'justify',
            font: 'TimesNewRoman',
        },
        pageMargins: [
            50, //60
            60,
            40,
            60,
        ],
        content: [
            {
                style: 'header',
                layout: 'noBorders',
                table: {
                    widths: [220, '*'],
                    body: [
                        [
                            { text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', style: {} },
                            { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', style: { bold: true } },
                        ],
                        [
                            { text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', style: { bold: true } },
                            { text: 'Độc lập - Tự do - Hạnh phúc', style: { bold: true } },
                        ],
                        [
                            {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0,
                                        y1: -1,
                                        x2: 100,
                                        y2: -1,
                                        lineWidth: 1,
                                    },
                                ],
                            },
                            {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0,
                                        y1: -1,
                                        x2: 150,
                                        y2: -1,
                                        lineWidth: 1,
                                    },
                                ],
                            },
                        ],
                        [
                            { text: `Số: ${HoiDong_Header.Decision_SoQD}`, style: { italics: true, margin: [0, 50, 0, 50] } },
                            {
                                text: `Đồng Nai, ngày ${HoiDong_Header.Decision_NgayQD} tháng ${HoiDong_Header.Decision_ThangQD} năm ${HoiDong_Header.Decision_NamQD}`,
                                style: { italics: true, margin: [0, 50, 0, 50] },
                            },
                        ],
                    ],
                },
            },
            {
                text: 'QUYẾT ĐỊNH',
                alignment: 'center',
                fontSize: 14,
                font: 'TimesNewRoman',
                bold: true,
                margin: [0, 20, 0, 0],
            },
            {
                text: `Về việc thành lập Hội đồng đánhh giá ${vueData.CheckLopDoAn ? 'đồ án tốt nghiệp' : 'luận văn'} thạc sĩ`,
                alignment: 'center',
                fontSize: 13,
                font: 'TimesNewRoman',
                bold: true,
                margin: [0, 0, 0, 5],
            },
            {
                columns: [
                    { width: '*', text: '' },
                    {
                        width: 'auto',
                        canvas: [
                            {
                                type: 'line',
                                x1: 0,
                                y1: 0,
                                x2: 150,
                                y2: 0,
                                lineWidth: 1,
                            },
                        ],
                    },
                    { width: '*', text: '' },
                ],
            },
            {
                text: 'HIỆU TRƯỞNG TRƯỜNG ĐẠI HỌC LẠC HỒNG',
                alignment: 'center',
                fontSize: 14,
                font: 'TimesNewRoman',
                bold: true,
                margin: [0, 20, 0, 20],
            },
            ,
            {
                text: '\t\t\tCăn cứ Quyết định số 790/TTg ngày 24/9/1997 của Thủ tướng Chính phủ về việc thành lập Trường Đại học dân lập Lạc Hồng;',
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: '\t\t\tCăn cứ Quyết định số 1801/QĐ-TTg ngày 22/10/2015 của Thủ tướng Chính phủ về việc chuyển đổi loại hình của Trường Đại học dân lập Lạc Hồng;',
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: '\t\t\tCăn cứ Quy chế tổ chức và hoạt động của Trường Đại học Lạc Hồng;',
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: '\t\t\tCăn cứ Quyết định số 05/QĐ-ĐHLH.K2 ngày 08/6/2021 của Hội nghị nhà đầu tư về việc công nhận chức vụ Hiệu trưởng Trường Đại học tư thục Lạc Hồng nhiệm kỳ 2020-2025;',
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: '\t\tCăn cứ Quyết định số 787/QĐ-ĐHLH ngày 28/12/2021 về việc ban hành Quy chế tuyển sinh và đào tạo trình độ thạc sĩ của Hiệu trưởng trường Đại học Lạc Hồng;',
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: '\t\t\tCăn cứ chức năng và quyền hạn của Hiệu trưởng Trường Đại học Lạc Hồng;',
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: '\t\t\tTheo đề nghị của Trưởng Khoa Sau đại học.',
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: 'QUYẾT ĐỊNH',
                alignment: 'center',
                fontSize: 14,
                font: 'TimesNewRoman',
                bold: true,
                margin: [0, 5, 0, 20],
            },
            {
                text: [
                    { text: '\t\t\tĐiều 1. ', bold: true },
                    `Thành lập Hội đồng đánh giá ${vueData.CheckLopDoAn ? 'đồ án tốt nghiệp' : 'luận văn'} thạc sĩ về đề tài "`,
                    { text: `${HoiDong_Header.DeTai}`, bold: true },
                    `" của học viên `,
                    { text: `${HoiDong_Header.HoSV} ${HoiDong_Header.TenSV}`, bold: true },
                ],
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: [{ text: '\t\t\tNgành: ' }, { text: `${HoiDong_Header.TenNganh}`, bold: true }, { text: '; Mã số: ' }, { text: `${HoiDong_Header.MaNganh}`, bold: true }],
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: [{ text: '\t\t\tDanh sách thành viên Hội đồng kèm theo Quyết định này.' }],
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: [
                    { text: '\t\t\tĐiều 2. ', bold: true },
                    `Hội đồng đánh giá ${vueData.CheckLopDoAn ? 'đồ án tốt nghiệp' : 'luận văn'} thạc sĩ có nhiệm vụ: Tổ chức buổi đánh giá ${vueData.CheckLopDoAn ? 'đồ án tốt nghiệp' : 'luận văn'} thạc sĩ cho học viên theo các Quy định hiện hành và tự giải thể sau khi hoàn thành nhiệm vụ.`,
                ],
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: [{ text: '\t\t\tĐiều 3. ', bold: true }, 'Các thành viên Hội đồng, Trưởng khoa Sau đại học và học viên có trách nhiệm thi hành Quyết định này kể từ ngày ký./.'],
                alignment: 'justify',
                fontSize: 13,
                font: 'TimesNewRoman',
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 20],
            },
            {
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [
                            { text: 'Nơi nhận:', style: { italics: true, bold: true, alignment: 'left' } },
                            { text: 'HIỆU TRƯỞNG', style: { bold: true, alignment: 'center' } },
                        ],
                        [
                            {
                                text: `- Như Điều 3;\n - Lưu: VT, K.SĐH, (${HoiDong_Header.Decision_NguoiTao}).`,
                                style: { alignment: 'left' },
                            },
                            { text: '\n\n\n\n\n\n\nLâm Thành Hiển', style: { bold: true, alignment: 'center' } },
                        ],
                    ],
                },
            },
            { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'portrait', margin: [20, 20, 10, 10] },
            {
                style: 'header',
                layout: 'noBorders',
                // margin: [0, 0, 20, 5],
                table: {
                    widths: [215, '*'],
                    body: [
                        [
                            { text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', style: {} },
                            { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', style: { bold: true } },
                        ],
                        [
                            { text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', style: { bold: true } },
                            { text: 'Độc lập - Tự do - Hạnh phúc', style: { bold: true } },
                        ],
                        [
                            {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0,
                                        y1: -1,
                                        x2: 100,
                                        y2: -1,
                                        lineWidth: 1,
                                    },
                                ],
                            },
                            {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0,
                                        y1: -1,
                                        x2: 150,
                                        y2: -1,
                                        lineWidth: 1,
                                    },
                                ],
                            },
                        ],
                    ],
                },
            },
            {
                text: `\nDANH SÁCH HỘI ĐỒNG ĐÁNH GIÁ ${vueData.CheckLopDoAn ? 'ĐỒ ÁN TỐT NGHIỆP' : 'LUẬN VĂN'} THẠC SĨ`,
                alignment: 'center',
                fontSize: 14,
                font: 'TimesNewRoman',
                bold: true,
                margin: [20, 0, 20, 5],
            },
            {
                text: `NGÀNH: ${HoiDong_Header.TenNganh.toUpperCase()}`,
                alignment: 'center',
                fontSize: 13,
                font: 'TimesNewRoman',
                bold: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: `của học viên: ${HoiDong_Header.HoSV} ${HoiDong_Header.TenSV}`,
                alignment: 'center',
                fontSize: 13,
                font: 'TimesNewRoman',
                bold: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: `(Ban hành kèm theo Quyết định số ${HoiDong_Header.Decision_SoQD} ,\n ngày ${HoiDong_Header.Decision_NgayQD} tháng ${HoiDong_Header.Decision_ThangQD} năm ${HoiDong_Header.Decision_NamQD} của Hiệu trưởng Trường Đại học Lạc Hồng)`,
                alignment: 'center',
                fontSize: 13,
                font: 'TimesNewRoman',
                italics: true,
                margin: [0, 0, 20, 20],
            },
            {
                columns: [
                    { width: '*', text: '' },
                    {
                        width: 'auto',
                        table: tableDSThanhVen,
                    },
                    { width: '*', text: '' },
                ],
            },
            {
                columns: [
                    { width: '*', text: '' },
                    {
                        width: 'auto',
                        layout: 'noBorders',
                        table: tableTongThanhVien,
                    },
                    { width: '*', text: '' },
                ],
            },
            {
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [
                            { text: '', style: { italics: true, bold: true, alignment: 'left' } },
                            { text: 'HIỆU TRƯỞNG', style: { bold: true, alignment: 'center' } },
                        ],
                        [
                            {
                                text: '',
                                style: { alignment: 'left' },
                            },
                            { text: '\n\n\n\n\n\n\nLâm Thành Hiển', style: { bold: true, alignment: 'center' } },
                        ],
                    ],
                },
            },
        ],
        styles: {
            header: {
                fontSize: 12,
                font: 'TimesNewRoman',
                alignment: 'center',
            },
            bigger: {
                fontSize: 15,
                italics: true,
            },
        },
    }
}