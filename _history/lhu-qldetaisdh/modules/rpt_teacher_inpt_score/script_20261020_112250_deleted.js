function InPhieuDiem(data) {
    let tableRows = []
    tableRows.push([
        { text: 'Tiêu chí đánh giá', style: { bold: true, fontSize: 13 }, marginTop: 5, marginBottom: 5 },
        { text: 'Điểm tối đa', style: { bold: true, fontSize: 13 }, marginTop: 5, marginBottom: 5 },
        { text: 'Điểm đánh giá', style: { bold: true, fontSize: 13 }, marginTop: 5, marginBottom: 5 },
    ])
    tableRows.push([
        {
            text: [
                "Bài báo, công trình khoa học",
                { text: '\u00B9', fontSize: 15, marginBottom: 28 } // Unicode cho số mũ 1
            ],
            alignment: "left",
            // fontSize: 15,
            style: 'tableCustom'
        },
        { text: `1,0`, style: 'tableCustom', },
        { text: `1.0`, style: 'tableCustom', },
    ]);
    tableRows.push([
        {
            text: [
                "Trích nguồn tham khảo",
                { text: '\u00B2', fontSize: 15, marginBottom: 28 } // Unicode cho số mũ 1
            ],
            alignment: "left",
            style: 'tableCustom'
        },
        { text: `1,0`, style: 'tableCustom', },
        { text: ``, style: 'tableCustom', },
    ]);
    tableRows.push([
        { text: `Hình thức, kết cấu luận văn`, alignment: "left", style: 'tableCustom', },
        { text: `1,0`, style: 'tableCustom', },
        { text: ``, style: 'tableCustom', },
    ]);
    tableRows.push([
        { text: `Nội dung và kết quả nghiên cứu`, alignment: "left", style: 'tableCustom' },
        { text: `5,0`, style: 'tableCustom', },
        { text: ``, style: 'tableCustom', },
    ]);
    tableRows.push([
        { text: `Năng lực của học viên (trình bày và trả lời)`, alignment: "left", style: 'tableCustom' },
        { text: `2,0`, style: 'tableCustom', },
        { text: ``, style: 'tableCustom', },
    ]);
    tableRows.push([
        { text: `Điểm tổng cộng (lẻ đến 0.5)`, bold: true, alignment: "right", style: 'tableCustom' },
        { text: `10`, bold: true, style: 'tableCustom', },
        { text: ``, style: 'tableCustom', },
    ]);
    let tableDanhGia = {
        widths: [250, 70, 90],
        body: tableRows
    }
    vueData.dataPDF = {
        "pageSize": { width: 595, height: 842 },
        "pageOrientation": "portrait",
        "defaultStyle": {
            "alignment": "justify",
            "font": "TimesNewRoman"
        },
        "pageMargins": [
            70, //left, top, right, bottom
            20,
            15,
            10
        ],
        "content": [
            {
                text: 'PHIẾU ĐÁNH GIÁ LUẬN VĂN THẠC SĨ',
                alignment: "center",
                fontSize: 16,
                font: "TimesNewRoman",
                bold: true,
                marginTop: 20,
            },
            {
                text: `NGÀNH TÀI CHÍNH - NGÂN HÀNG`,
                alignment: "center",
                fontSize: 16,
                font: "TimesNewRoman",
                bold: true,
            },
            {
                text: [
                    { text: "Hội đồng chấm luận văn được thành lập theo Quyết định số" },
                    { text: ` 611/QĐ-ĐHLH` }, //
                    { text: ` ngày 05/7/2023` }, //
                    { text: " đã họp tại Trường Đại học Lạc Hồng ngày" },
                    { text: ` 12/7/2023` }, //
                    { text: " để đánh giá luận văn thạc sĩ" },
                    { text: ` Tài chính - Ngân hàng` } //
                ],
                alignment: "left",
                font: "TimesNewRoman",
                marginTop: 30,
                lineHeight: 1.5,
                style: 'mediumTxt',
            },
            {
                text: [
                    { text: "Học viên:" },
                    { text: ` Lưu Ngọc Anh`, bold: true },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: [
                    { text: "Với luận văn:" },
                    { text: ` Các yếu tố ảnh hưởng đến quyết định gửi tiền của khách hàng doanh nghiệp tại Ngân hàng Thương mại cổ phần Ngoại thương Việt Nam chi nhánh Biên Hòa`, bold: true },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: "Ý KIẾN ĐÁNH GIÁ",
                alignment: "center",
                fontSize: 15,
                font: "TimesNewRoman",
                // lineHeight: 1.5,
                marginTop: 20,
                bold: true
            },
            {
                text: "(Cho điểm vào ô trống, tối đa là một số lẻ)",
                alignment: "center",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                // lineHeight: 1.5,
                italics: true,
                marginBottom: 20
            },
            {
                style: 'header',
                table: tableDanhGia,
                alignment: "center",
                marginLeft: 33,
            },
            {
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: '', "style": { italics: true, bold: true, alignment: "left" } }, { text: '\n\nTHÀNH VIÊN HỘI ĐỒNG', "style": { bold: true, alignment: "center", fontSize: 14 } }],
                        [{
                            text: '', "style": { alignment: "left" }
                        }, { text: '(Ký tên)', "style": { alignment: "center", bold: true, fontSize: 14, italics: true } }],
                        [{
                            text: '', "style": { alignment: "left" }
                        }, { text: '\n\n\n\nHọ và tên: Lữ Phi Nga', "style": { bold: true, alignment: "center", fontSize: 14 } }],
                    ]
                }
            },
            {
                canvas: [
                    {
                        type: 'line',
                        x1: 0, y1: 0,
                        x2: 160, y2: 0,
                        lineWidth: 1
                    }
                ],
                alignment: "left",
                marginBottom: 10,
                marginTop: 10,
            },
            {
                text: [
                    { text: '\u00B9', fontSize: 15, marginBottom: 28 },
                    { text: 'Công trình khoa học bao gồm: bài báo trình bày hoặc được in ấn trong các hội nghị, hội thảo khoa học từ cấp cơ sở trở lên liên quan đến luận văn; bài báo được in ấn trong các tạp chí khoa học chuyên ngành; tài liệu, sách được xuất bản liên quan đến nội dung khoa học của luận văn ' },
                    { text: '(tất cả phải có giấy phép xuất bản)', bold: true }
                ],
                style: ['quote', 'small']
            },
            {
                text: [
                    { text: '\u00B2', fontSize: 15, marginBottom: 28 },
                    { text: 'Trích dẫn đúng nguồn tài liệu tham khảo và tài liệu tham khảo phải có tính mới' }
                ],
                style: ['quote', 'small'],
                marginTop: 10,
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
            },
            quote: {
                italics: true,
            },
            small: {
                fontSize: 12
            },
            mediumTxt: {
                fontSize: 14,
            },
            tableCustom: {
                fontSize: 13,
                // lineHeight: 1.5,
                marginTop: 5,
                marginBottom: 5
            },
            alignTableTxt: {
                marginTop: 10,
                marginBottom: 10,
            },
            tableHeader: {
                bold: true,
                fontSize: 14,
            },
        }
    }
}