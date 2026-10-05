
function InQuyetDinhTienSi(data) {
    let tableRows = [];
    // Thêm dòng tiêu đề (header)
    tableRows.push([
        { text: 'STT', style: { bold: true } },
        { text: 'MSHV', style: { bold: true } },
        { text: 'Họ tên', style: { bold: true }, colSpan: 2 },
        {},
        { text: 'Ngày sinh', style: { bold: true } },
        { text: 'Nơi sinh', style: { bold: true } },
        { text: 'Tên đề tài', style: { bold: true } },
        { text: 'Giảng viên hướng dẫn', style: { bold: true } }
    ]);
    // Sử dụng vòng lặp thông thường để thêm dòng cho mỗi sinh viên
    for (let i = 0; i < data.Decision_StudentList.length; i++) {
        let student = data.Decision_StudentList[i];
        tableRows.push([
            { text: `${String(student.STT).padStart(2, '0')}` },
            { text: `${student.Student_ID}` },
            { text: `${student.Ho_SV} ` },
            { text: `${student.Ten_SV} ` },
            { text: `${student.Ngay_Sinh} ` },
            { text: `${student.Noi_Sinh} ` },
            { text: `${student.Thesis_Name} ` },
            { text: `${student.Thesises_Prof1} ` }
        ]);
    }
    // Tạo table object với dòng dữ liệu được tạo ra
    let tableDSHocVien = {
        widths: [30, 60, 100, 50, 60, 80, 170, 150],
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
                style: 'header',
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
                        [{ text: `Số: ${data.Decision_SoQD}`, "style": { italics: true, margin: [0, 50, 0, 50] } }
                            , { text: `Đồng Nai, ngày ${data.Decision_NgayQD} tháng ${data.Decision_ThangQD} năm ${data.Decision_NamQD}`, "style": { italics: true, margin: [0, 50, 0, 50] } }],
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
                text: 'Về việc giao đề tài luận án và người hướng dẫn khoa học',
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 0, 0, 5]
            },
            {
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
                text: '\t\t\tCăn cứ Quyết định số 386/QĐ-ĐHLH ngày 14/09/2021 của Hiệu trưởng Trường Đại học Lạc Hồng về việc ban hành Quy chế tuyển sinh và đào tạo trình độ tiến sĩ;',
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: `\t\t\tCăn cứ Quyết định số 861/QĐ-ĐHLH ngày 30/08/2023 của Hiệu trưởng Trường Đại học Lạc Hồng về việc công nhận nghiên cứu sinh ngành ${data.Decision_Nganh} khóa ${data.Decision_NienKhoa};`,
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
                text: '\t\t\tXét đề nghị của Trưởng Khoa Sau đại học.',
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
                margin: [0, 20, 0, 20]
            },
            {
                text: [
                    { text: '\t\t\tĐiều 1. ', bold: true },
                    `Công nhận nghiên cứu sinh ${data.Decision_StudentList[0].Ho_SV} ${data.Decision_StudentList[0].Ten_SV} sinh ngày ${data.Decision_StudentList[0].Ngay_Sinh} mã số: ${data.Decision_StudentList[0].Student_ID}, khóa ${data.Decision_NienKhoa}, niên khóa 2023-2026 tại trường Đại học Lạc Hồng với đề tài:`
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
             {
                text:`${data.Decision_StudentList[0].Thesis_Name}`,
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: [{ text: `Ngành: ` }, { text: `${data.Decision_Nganh }`, "style": { bold: true }},{ text: `\t\t\tMã số: ` }, { text: `${data.Decision_MaSo}`, "style": { bold: true }}],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text:`Người hướng dẫn khoa học:`,
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: `\t\t\t1.	${data.Decision_StudentList[0].Thesises_Prof1??'……………………'}- Trường ${data.Decision_StudentList[0].Thesises_ProfUni1??'……………'}; (Email: ${data.Decision_StudentList[0].Thesises_ProfEmail1??'       '}; Điện thoại:.  ${data.Decision_StudentList[0].Thesises_ProfPhone1??'                 '})`,
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: `\t\t\t2.	${data.Decision_StudentList[0].Thesises_Prof2??'……………………'}- Trường ${data.Decision_StudentList[0].Thesises_ProfUni2??'……………'}; (Email: ${data.Decision_StudentList[0].Thesises_ProfEmail2??'       '}; Điện thoại:.  ${data.Decision_StudentList[0].Thesises_ProfPhone2??'                 '})`,
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: [
                    { text: '\t\t\tĐiều 2. ', bold: true },
                    'Nghiên cứu sinh và người hướng dẫn có nhiệm vụ và được hưởng các quyền lợi theo Quy chế đào tạo trình độ tiến sĩ hiện hành.'
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
                    'Trưởng khoa Sau đại học, các đơn vị liên quan, người hướng dẫn khoa học và nghiên cứu sinh có tên trong Điều 1 chịu trách nhiệm thi hành Quyết định./.'
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
                            text: `- Như Điều 3;\n - Lưu: VT, K.SĐH, (${data.Decision_NguoiTao}).`, "style": { alignment: "left" }
                        }, { text: '\n\n\n\n\n\n\nLâm Thành Hiển', "style": { bold: true, alignment: "center" } }],
                    ]
                }
            }
        ],
        styles: {
            header: {
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