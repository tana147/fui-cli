function InBienBan(data) {
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
                text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                marginTop: 20,
            },
            {
                text: 'Độc lập - Tự do - Hạnh phúc',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
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
                alignment: "center",
                marginBottom: 10,
                marginTop: 5,
            },
            {
                text: 'BIÊN BẢN CUỘC HỌP HỘI ĐỒNG CHẤM LUẬN VĂN THẠC SĨ',
                alignment: "center",
                fontSize: 16,
                font: "TimesNewRoman",
                bold: true,
                marginTop: 20,
                lineHeight: 1.5,
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
                    { text: "của học viên:" },
                    { text: ` Lưu Ngọc Anh`, bold: true },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                marginTop: 20,
            },
            {
                text: [
                    { text: "về luận văn:" },
                    { text: ` Các yếu tố ảnh hưởng đến quyết định gửi tiền của khách hàng doanh nghiệp tại Ngân hàng Thương mại cổ phần Ngoại thương Việt Nam chi nhánh Biên Hòa`, bold: true },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `tại Trường Đại học Lạc Hồng`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: [
                    { text: `Vào ngày` },
                    { text: ` 17`, bold: true },
                    { text: ` tháng` },
                    { text: ` 05`, bold: true },
                    { text: ` năm` },
                    { text: ` 2024`, bold: true }
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: [
                    { text: 'Hội đồng chấm luận văn được thành lập theo Quyết định số' },
                    { text: ` 611/QĐ-ĐHLH` },
                    { text: ' ngày' },
                    { text: ` 05/7/2023` },
                    { text: ' của Hiệu trưởng Trường Đại học Lạc Hồng đã nghe học viên' },
                    { text: ` Lưu Ngọc Anh` },
                    { text: ' trình bày tóm tắt nội dung luận văn để nhận học vị Thạc sĩ ' },
                    { text: ` Tài chính – Ngân hàng.` },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `Một số ý kiến trao đổi của hội đồng:`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                margin: [0, 10, 0, 10]
            },
            {
                text: `Sau khi nghe tác giả trả lời và người dướng dẫn khoa học nhận xét luận văn. Hội đồng họp riêng và thông qua kết luận, Hội đồng bầu Ban kiểm phiếu gồm`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                style: 'header',
                layout: 'noBorders',
                lineHeight: 1.5,
                margin: [30, 0, 0, 0],
                table: {
                    widths: [300, 120],
                    body: [
                        [{ text: `1) PGS.TS. Đỗ Quang Dương`, "style": { fontSize: 14, alignment: "left", bold: true} }, { text: `Trưởng ban`, "style": { fontSize: 14, alignment: "left" } }],
                    ]
                }
            },
            {
                style: 'header',
                layout: 'noBorders',
                lineHeight: 1.5,
                margin: [30, 0, 0, 0],
                table: {
                    widths: [300, 120],
                    body: [
                        [{ text: `2) PGS.TS. Huỳnh Văn Hóa`, "style": { fontSize: 14, alignment: "left", bold: true} }, { text: `Ủy viên`, "style": { fontSize: 14, alignment: "left" } }],
                    ]
                }
            },
            {
                style: 'header',
                layout: 'noBorders',
                lineHeight: 1.5,
                margin: [30, 0, 0, 0],
                table: {
                    widths: [300, 120],
                    body: [
                        [{ text: `3) PGS.TS. Nguyễn Thanh Lâm`, "style": { fontSize: 14, alignment: "left", bold: true} }, { text: `Ủy viên`, "style": { fontSize: 14, alignment: "left" } }],
                    ]
                }
            },
            {
                text: `Căn cứ vào kết quả bỏ phiếu của Hội đồng chấm luận văn là:`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: [
                    { text: `- Số thành viên Hội đồng tham gia bỏ phiếu:` },
                    { text: ` 3`, bold: true }
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                margin: [30, 0, 0, 0]
            },
            {
                text: [
                    { text: `- Tổng số điểm chấm luận văn của Hội đồng:` },
                    { text: ` 10`, bold: true }
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                margin: [30, 0, 0, 0]
            },
            {
                text: [
                    { text: `- Điểm bình quân:` },
                    { text: ` 10`, bold: true }
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                margin: [30, 0, 0, 0]
            },
            {
                text: `Hội đồng kết luận:`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                margin: [38, 0, 0, 0]
            },
            {
                text: [
                    { text: `1) Bản luận văn của học viên` },
                    { text: ` Lưu Ngọc Anh`, bold: true },
                    { text: ` đáp ứng yêu cầu của luận văn Thạc sĩ` },
                    { text: ` TÀI CHÍNH - NGÂN HÀNG`, bold: true },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `Một số khuyến cáo của hội đồng như sau (nếu có):`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                margin: [15, 0, 0, 0]
            },
            {
                text: `Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                margin: [0, 10, 0, 10],
                lineHeight: 1.5,
            },
            {
                text: [
                    { text: `2) Đề nghị công nhận học vị Thạc sĩ` },
                    { text: ` TÀI CHÍNH - NGÂN HÀNG`, bold: true },
                    { text: ` cho học viên` },
                    { text: `  Lưu Ngọc Anh`, bold: true },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: [
                    { text: `3) Đề nghị cho phép học viên` },
                    { text: ` Lưu Ngọc Anh`, bold: true },
                    { text: ` được chuyển tiếp nghiên cứu sinh` },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                style: 'header',
                layout: 'noBorders',
                marginLeft: 10,
                table: {
                    widths: [207.5, 307.5],
                    body: [
                        [{ text: 'THƯ KÝ HỘI ĐÒNG', "style": { fontSize: 14, bold: true, alignment: "center", } }, { text: 'CHỦ TỊCH HỘI ĐỒNG', "style": { bold: true, fontSize: 14, alignment: "center" } }],
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
        }
    }
}