
function InToTrinh(data) {
    const ToTrinh_Header = data.data[0][0]
    const ToTrinh_AnPhamList = data.data[1]
    let tableRows = [];
    // Thêm dòng tiêu đề (ToTrinh_Header)
    tableRows.push([
        { text: 'STT', style: { bold: true } },
        { text: 'Tên tác giả', style: { bold: true } },
        { text: 'TGLH/TTG', style: { bold: true } },
        { text: 'Đơn vị', style: { bold: true } },
        { text: 'Tên bài báo', style: { bold: true } },
        { text: 'Năm đăng', style: { bold: true } },
        { text: 'Nơi đăng', style: { bold: true } },
        { text: 'Hoàn phí đăng', style: { bold: true } },
        { text: 'Khen thưởng', style: { bold: true } },
        { text: 'Khen thưởng sau hoàn phí', style: { bold: true } },
        { text: 'Ghi chú', style: { bold: true } },
    ]);
    // Sử dụng vòng lặp để them danh sách ẩn phẩm
    for (let i = 0; i < ToTrinh_AnPhamList.length; i++) {
        let anpham = ToTrinh_AnPhamList[i];
        tableRows.push([
            { text: `${String(anpham.STT).padStart(2, '0')}` },
            { text: `${anpham.TacGia}` },
            { text: `${anpham.TenNhanVienDaiDien} ` },
            { text: `${anpham.DonViDaiDien} ` },
            { text: `${anpham.TenAnPham} ` },
            { text: `${anpham.NamDangBai} ` },
            { text: `${anpham.NoiDangBai} ` },
            { text: `${anpham.HoanPhiDang} `, style: { alignment: "right" } },
            { text: `${anpham.SoTienKhenThuong} `, style: {alignment: "right" } },
            { text: `... `, style: { alignment: "right" }},
            { text: `... ` }
        ]);
    }
    tableRows.push([
        { text: `Tổng tiền ${ToTrinh_Header.TongTienKhenThuong}`, style: {alignment:"center", bold:true}, colSpan: 7},
        {},
        {},
        {},
        {},
        {},
        {},
        { text: '-', style: { bold: true } },
        { text: '-', style: { bold: true } },
        { text: '-', style: { bold: true } },
        { text: '', style: { bold: true } },
    ]);
    tableRows.push([
        { text: `Só tiền bằng chữ: ${ToTrinh_Header.TongTienKhenThuong_BangChu}`, style: { alignment: "center", italics: true }, colSpan: 11 },
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
    ]);
    // Tạo table object với dòng dữ liệu được tạo ra
    let tableDSAnPham = {
        widths: [30, 100, 100, 100, 110, 30, 30, 60, 50, 50, 30],
        body: tableRows
    };
    // Khởi tạo File PDF
    vueData.dataPDF = {
        "pageSize": "A4",
        "pageOrientation": "portrait",
        "defaultStyle": {
            "alignment": "justify",
            "font": "TimesNewRoman"
        },
        "pageMargins": [
            20,
            20,
            10,
            10
        ],
        "content": [
            {
                style: 'ToTrinh_Header',
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', "style": {} }, { text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', "style": { bold: true } }],
                        [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { bold: true } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true } }],
                        [{
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: 0,
                                    x2: 100, y2: 0,
                                    lineWidth: 1
                                }
                            ]
                        }, {
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: 0,
                                    x2: 100, y2: 0,
                                    lineWidth: 1
                                }
                            ]
                        }],
                        [{ text: `Số: ${ToTrinh_Header.SoQD}`, "style": { italics: true, margin: [0, 50, 0, 50] } }
                            , { text: `Đồng Nai, ngày ${ToTrinh_Header.Ngay} tháng ${ToTrinh_Header.Thang} năm ${ToTrinh_Header.Nam}`, "style": { italics: true, margin: [0, 50, 0, 50] } }],
                    ]
                }
            },
            {
                text: 'QUYẾT ĐỊNH',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 20, 0, 20]
            },
            {
                text: 'Về việc hỗ trợ kinh phí và khen thưởng tác giả có ấn phẩm khoa học',
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: 'được công bố trên các tạp chí, kỷ yếu hội thảo, nhà xuất bản ',
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: `khoa học năm ${ToTrinh_Header.NamHocKhenThuong} đợt ${ToTrinh_Header.DotKhenThuong}`,
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 0, 0, 5]
            }, {
                text: 'HIỆU TRƯỞNG TRƯỜNG ĐẠI HỌC LẠC HỒNG',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 20, 0, 20]
            },
            , {
                text: '\t\t\tCăn cứ Quyết định số 790/TTg ngày 24/9/1997 của Thủ tướng Chính phủ về việc thành lập Trường Đại học dân lập Lạc Hồng;',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5],
            },
            {
                text: '\t\t\tCăn cứ Quyết định số 1801/QĐ-TTg ngày 22/10/2015 của Thủ tướng Chính phủ về việc chuyển đổi loại hình của Trường Đại học dân lập Lạc Hồng;',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: '\t\t\tCăn cứ Quy chế tổ chức và hoạt động của Trường Đại học Lạc Hồng;',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: '\t\t\tCăn cứ Quyết định số 05/QĐ-ĐHLH.K2 ngày 08/6/2021 của Hội nghị nhà đầu tư về việc công nhận chức vụ Hiệu trưởng Trường Đại học tư thục Lạc Hồng nhiệm kỳ 2020-2025;',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: '\t\t\tCăn cứ Quyết định số 879/QĐ-ĐHLH ngày 24/10/2018 của Hiệu trưởng Trường Đại học Lạc Hồng về việc ban hành Quy định hỗ trợ kinh phí và khen thưởng tác giả có ấn phẩm khoa học được công bố trên các tạp chí, kỷ yếu hội thảo, nhà xuất bản khoa học;',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: '\t\t\tCăn cứ Quyết định số 171/QĐ-ĐHLH ngày 17/4/2020 của Hiệu trưởng Trường Đại học Lạc Hồng về việc sửa đổi bổ sung một số điều của Quy định hỗ trợ kinh phí và khen thưởng tác giả có ấn phẩm khoa học được công bố trên các tạp chí, kỷ yếu hội thảo, nhà xuất bản khoa học ban hành kèm theo Quyết định số 879/QĐ-ĐHLH ngày 24/10/2018 của Hiệu trưởng Trường Đại học Lạc Hồng;',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: '\t\t\tCăn cứ chức năng và quyền hạn của Hiệu trưởng Trường Đại học Lạc Hồng;',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: '\t\t\tTheo đề nghị của Giám đốc Trung tâm Nghiên cứu Khoa học và Ứng dụng.',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: 'QUYẾT ĐỊNH',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 5, 0, 5]
            },
            {
                text: [
                    { text: '\t\t\tĐiều 1. ', bold: true },
                    `Nay hỗ trợ và khen thưởng cho cán bộ, giảng viên và nhân viên Trường Đại học Lạc Hồng là tác giả của 16 (mười sáu) bài báo được đăng trên tạp chí, kỷ yếu hội thảo khoa học chuyên ngành trong nước và quốc tế (danh sách kèm theo).`
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: [
                    { text: '\t\t\tĐiều 2. ', bold: true },
                    'Kinh phí hỗ trợ và khen thưởng được trích từ nguồn kinh phí hoạt động khoa học công nghệ của Trung tâm Nghiên cứu khoa học và Ứng dụng. Phòng Tài chính chịu trách nhiệm cấp phát kinh phí.'
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: [
                    { text: '\t\t\tĐiều 3. ', bold: true },
                    'Quyết định này có hiệu lực từ ngày ký.'
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: [
                    { text: '\t\t\tĐiều 4. ', bold: true },
                    'Giám đốc Trung tâm Nghiên cứu Khoa học và Ứng dụng, Trưởng phòng Tài chính, Thủ trưởng các đơn vị có liên quan và các cá nhân có tên ở Điều 1 chịu trách nhiệm thi hành Quyết định này./.'
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 20]
            },
            {
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: 'Nơi nhận:', "style": { italics: true, bold: true, alignment: "left" } }, { text: 'HIỆU TRƯỞNG', "style": { bold: true, alignment: "center" } }],
                        [{
                            text: `- Như Điều 3;\n - Lưu: VT, TT.NCKH&ƯD, (388).`, "style": { alignment: "left" }
                        }, { text: '\n\n\n\n\n\n\nLâm Thành Hiển', "style": { bold: true, alignment: "center" } }],
                    ]
                }
            },
            { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'landscape', margin: [0, 0, 0, 8] },
            {
                style: 'ToTrinh_Header',
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', "style": {} }, { text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', "style": { bold: true } }],
                        [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { bold: true } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true } }],
                        [{
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: 0,
                                    x2: 100, y2: 0,
                                    lineWidth: 1
                                }
                            ]
                        }, {
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: 0,
                                    x2: 100, y2: 0,
                                    lineWidth: 1
                                }
                            ]
                        }]
                    ]
                }
            },
            {
                text: `DANH SÁCH KHEN THƯỞNG CÁC ẤN PHẨM KHOA HỌC VÀ CÔNG NGHỆ NĂM ${ToTrinh_Header.NamHocKhenThuong} - ĐỢT ${ToTrinh_Header.DotKhenThuong}`,
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 20, 0, 20]
            },
            {
                text: `(Ban hành kèm theo Quyết định số ${ToTrinh_Header.SoQD} ngày ${ToTrinh_Header.Ngay} tháng ${ToTrinh_Header.Thang} năm ${ToTrinh_Header.Nam} của Hiệu trưởng Trường Đại học Lạc Hồng)`,
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                margin: [0, 0, 0, 5]
            },
            {
                style: 'ToTrinh_Header',
                table: tableDSAnPham
            },
            {
                text: `Danh sách có ${ToTrinh_Header.SLAnPham_BangSo} (${ToTrinh_Header.SLAnPham_BangChu}) bài báo./.`,
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 20]
            },
            {
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: '', "style": { italics: true, bold: true, alignment: "left" } }, { text: 'HIỆU TRƯỞNG', "style": { bold: true, alignment: "center" } }],
                        [{
                            text: '', "style": { alignment: "left" }
                        }, { text: '\n\n\n\n\n\n\nLâm Thành Hiển', "style": { bold: true, alignment: "center" } }],
                    ]
                }
            },
        ],
        styles: {
            ToTrinh_Header: {
                fontSize: 12,
                font: "TimesNewRoman",
                alignment: "center"
            },
            bigger: {
                fontSize: 15,
                italics: true
            }
        }
    }
}