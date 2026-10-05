function InNhanXet(data) {
    const today = new Date();
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
                text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                marginTop: 20,
            },
            {
                text: 'KHOA SAU ĐẠI HỌC',
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
                        x2: 150, y2: 0,
                        lineWidth: 1
                    }
                ],
                alignment: "center",
                marginBottom: 10,
                marginTop: 5,
            },
            {
                text: 'NHẬN XÉT LUẬN VĂN THẠC SĨ',
                alignment: "center",
                fontSize: 16,
                font: "TimesNewRoman",
                bold: true,
                marginTop: 10,
            },
            {
                text: `(Dùng cho người phản biện)`,
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                italics: true,
            },
            {
                text: [
                    { text: "Về đề tài:" },
                    { text: ` Xây dựng hệ thống hỏi đáp thông tin về du lịch của một tỉnh có quy mô nhỏ`, },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                marginTop: 30,
            },
            {
                text: [
                    { text: "Học viên:" },
                    { text: ` Nguyễn Văn Sáng`, },
                ],
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                style: 'header',
                layout: 'noBorders',
                lineHeight: 1.5,
                table: {
                    widths: [207.5, 207.5],
                    body: [
                        [{ text: `Ngành: Công nghệ thông tin`, "style": { fontSize: 14, alignment: "left", } }, { text: `Mã số: 8480201`, "style": { fontSize: 14, alignment: "right" } }],
                    ]
                }
            },
            {
                text: `Người phản biện: PGS.TS. Trần Văn Hoài`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `NỘI DUNG NHẬN XÉT`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                bold: true,
            },
            {
                text: `1) Phần kết thực hiện của đề tài có trùng với các công trình khoa học khác đã công bố hay không; nếu trùng, mức độ trùng lắp như thế nào.`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                bold: true
            },
            {
                text: `Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `2) Nhận xét và đánh giá cụ thẻ về luận văn`,
                alignment: "left",
                style: ['mediumTxt', 'headingSpacer'],
                font: "TimesNewRoman",
                bold: true,
                lineHeight: 1.5,
                // style: 'headingSpacer',
            },
            {
                text: `Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `3) Những đề nghị chỉnh sửa, bổ sung cả về hình thức và nội dung (nếu có)`,
                alignment: "left",
                style: ['mediumTxt', 'headingSpacer'],
                font: "TimesNewRoman",
                lineHeight: 1.5,
                bold: true,
            },
            {
                text: `Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `4) Câu hỏi dành cho học viên`,
                alignment: "left",
                style: ['mediumTxt', 'headingSpacer'],
                font: "TimesNewRoman",
                lineHeight: 1.5,
                bold: true,
            },
            {
                text: `Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
            },
            {
                text: `Kết luận:`,
                alignment: "left",
                style: ['mediumTxt', 'headingSpacer'],
                font: "TimesNewRoman",
                bold: true,
                lineHeight: 1.5,
            },
            {
                text: `• Đề tài có đáp ứng yêu cầu của một luận văn thạc sĩ ngành  CNTT  hay không:  đáp ứng`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                margin: [10, 0, 0, 0]
            },
            {
                text: `• Học viên có xứng đáng để nhận văn bằng thạc sĩ hay không:  xứng đáng`,
                alignment: "left",
                style: 'mediumTxt',
                font: "TimesNewRoman",
                lineHeight: 1.5,
                margin: [10, 0, 0, 10]
            },
            {
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: '', "style": { italics: true, bold: true, alignment: "left" } }, { text: `Đồng Nai, ngày ${today.getDate()} tháng ${today.getMonth() + 1} năm ${today.getFullYear()}`, "style": { alignment: "center", italics: true, fontSize: 14 } }],
                        [{
                            text: '', "style": { alignment: "left" }
                        }, { text: 'NGƯỜI NHẬN XÉT', "style": { alignment: "center", bold: true, fontSize: 14 } }],
                        [{
                            text: '', "style": { alignment: "left" }
                        }, { text: `\n\n\n\nLữ Phi Nga`, "style": { bold: true, alignment: "center", fontSize: 14 } }],
                    ]
                }
            },
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
            headingSpacer: {
                marginTop: 20,
            }
        }
    }
}