//backup hàm tách nhóm danh sách đề tài khi khác tên ngành
// const groupedData = {};
// // Duyệt qua từng đối tượng trong mảng
// data.DeTaiList.forEach(item => {
//     // Kiểm tra xem nhóm dựa trên TenNganh đã tồn tại chưa
//     if (!groupedData[item.TenNganh]) {
//         groupedData[item.TenNganh] = [];
//     }
//     // Thêm đối tượng vào nhóm tương ứng
//     groupedData[item.TenNganh].push(item);
// });
// // Chuyển đổi các nhóm thành mảng các mảng
// const resultArray = Object.values(groupedData);
function loadLocalStorage() {
    const JsonHocVienArr = localStorage.getItem('JSON_PRINT_PDF_DSHV')
    const JsonGiangVien = localStorage.getItem('JSON_PRINT_PDF_GiangVienInfo')
    if (JsonHocVienArr) {
        const parseJSON = JSON.parse(JsonHocVienArr)
        vueData.DeTaiList = parseJSON
        console.log('vueData.DeTaiList', vueData.DeTaiList)
    }
    if (JsonGiangVien) {
        const parseJSON = JSON.parse(JsonGiangVien)
        vueData.CoQuanCongTac = parseJSON.CoQuanCongTac
        vueData.GiangVienID = parseJSON.GiangVienID
        vueData.HocHamHocVi = parseJSON.HocHamHocVi
        vueData.HoTenGiangVien = parseJSON.HoTenGiangVien
        vueData.NganhGiangDay = parseJSON.NganhGiangDay
        vueData.NganhID = parseJSON.NganhID
    }
}
function generateTable(tableData) {
    let tableRows = []
    tableRows.push([
        { text: 'TT', style: { bold: true } },
        { text: 'LopID', style: { bold: true } },
        { text: 'Mã HV', style: { bold: true } },
        { text: 'Họ', style: { bold: true } },
        { text: 'Tên', style: { bold: true } },
        { text: 'Ngày sinh', style: { bold: true } },
        { text: 'Điện thoại', style: { bold: true } },
        { text: 'Email', style: { bold: true } },
        { text: 'Đề tài đăng ký', style: { bold: true } },
        { text: 'GVHD', style: { bold: true } },
    ]);
    for (let i = 0; i < tableData.length; i++) {
        let detai = tableData[i];
        tableRows.push([
            { text: `${i + 1}` },
            { text: `${detai.lopId}`, alignment: 'left' },
            { text: `${detai.studentid} `, alignment: 'left' },
            { text: `${detai.HoSV} `, alignment: 'left' },
            { text: `${detai.TenSV} `, alignment: 'left' },
            { text: `${detai.NgaySinh} `, alignment: 'left' },
            { text: `${detai.SoDienThoai} `, alignment: 'left' },
            { text: `${detai.Email} `, alignment: 'left' },
            { text: `${detai.TenDeTai} `, alignment: 'left' },
            { text: `${detai.GVHD_1} `, alignment: 'left' },
        ]);
    }
    return tableRows
}
function generateTable2GVHD(tableData) {
    let tableRows = []
    tableRows.push([
        { text: 'TT', style: { bold: true } },
        { text: 'LopID', style: { bold: true } },
        { text: 'Mã HV', style: { bold: true } },
        { text: 'Họ', style: { bold: true } },
        { text: 'Tên', style: { bold: true } },
        { text: 'Ngày sinh', style: { bold: true } },
        { text: 'Điện thoại', style: { bold: true } },
        { text: 'Email', style: { bold: true } },
        { text: 'Đề tài đăng ký', style: { bold: true } },
        { text: 'GVHD 1', style: { bold: true } },
        { text: 'GVHD 2', style: { bold: true } }
    ]);
    for (let i = 0; i < tableData.length; i++) {
        let detai = tableData[i];
        tableRows.push([
            { text: `${i + 1}` },
            { text: `${detai.lopId}`, alignment: 'left' },
            { text: `${detai.studentid} `, alignment: 'left' },
            { text: `${detai.HoSV} `, alignment: 'left' },
            { text: `${detai.TenSV} `, alignment: 'left' },
            { text: `${detai.NgaySinh} `, alignment: 'left' },
            { text: `${detai.SoDienThoai} `, alignment: 'left' },
            { text: `${detai.Email} `, alignment: 'left' },
            { text: `${detai.TenDeTai} `, alignment: 'left' },
            { text: `${detai.GVHD_1} `, alignment: 'left' },
            { text: `${detai.GVHD_2} `, alignment: 'left' },
        ]);
    }
    return tableRows
}
function upperCaseString(str) {
    return str.toUpperCase();
}
function InGiayMoi() {
    let tableRows = [];
    let ds2GVHD = [];
    //lọc khác tên ngành
    const groupedData = {};
    // Duyệt qua từng đối tượng trong mảng
    vueData.DeTaiList.forEach(item => {
        // Kiểm tra xem nhóm dựa trên TenNganh đã tồn tại chưa
        if (!groupedData[item.TenNganh]) {
            groupedData[item.TenNganh] = {};
        }
        // Kiểm tra xem nhóm con dựa trên NienKhoa đã tồn tại chưa
        if (!groupedData[item.TenNganh][item.NienKhoa]) {
            groupedData[item.TenNganh][item.NienKhoa] = [];
        }
        // Thêm đối tượng vào nhóm tương ứng
        groupedData[item.TenNganh][item.NienKhoa].push(item);
    });
    // Chuyển đổi các nhóm thành mảng các mảng
    const resultArray = Object.values(groupedData)
        .flatMap(tenNganhGroup => Object.values(tenNganhGroup));
    // Kiểm tra kết quả
    console.log("result arr", resultArray);
    // Tạo một Set để lưu trữ các cặp giá trị duy nhất của NienKhoa và TenNganh
    const uniqueEntries = new Set();
    // Lọc các phần tử không trùng nhau dựa trên NienKhoa và TenNganh
    const filteredData = vueData.DeTaiList.filter(entry => {
        const key = `${entry.NienKhoa}-${entry.TenNganh}`;
        if (uniqueEntries.has(key)) {
            return false; // Bỏ qua nếu đã tồn tại
        }
        uniqueEntries.add(key); // Thêm vào Set nếu không trùng
        return true;
    });
    console.log("filteredData", filteredData)
    const today = new Date();
    let arrNganh = filteredData.map(item => {
        let example = {
            stack: [
                {
                    style: 'header',
                    layout: 'noBorders',
                    table: {
                        widths: [207.5, 307.5],
                        body: [
                            [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { fontSize: 12, bold: false, alignment: "center", } }, { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', "style": { bold: true, fontSize: 12, alignment: "center" } }],
                            [{ text: 'KHOA SAU ĐẠI HỌC', "style": { bold: true, fontSize: 12, alignment: "center" } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true, fontSize: 12, alignment: "center" } }],
                            [
                                {
                                    canvas: [
                                        {
                                            type: 'line',
                                            x1: 0, y1: 0,
                                            x2: 60, y2: 0,
                                            lineWidth: 1
                                        }
                                    ],
                                    alignment: "center"
                                }, {
                                    canvas: [
                                        {
                                            type: 'line',
                                            x1: 0, y1: 0,
                                            x2: 150, y2: 0,
                                            lineWidth: 1
                                        }
                                    ],
                                    alignment: "center"
                                }
                            ],
                            [{}, { text: `\nĐồng Nai, ngày ${today.getDate()} tháng ${today.getMonth() + 1} năm ${today.getFullYear()}`, "style": { italics: true, fontSize: 12, bold: false, alignment: "center" } }],
                        ]
                    }
                },
                {
                    text: 'GIẤY MỜI',
                    alignment: "center",
                    fontSize: 25,
                    font: "TimesNewRoman",
                    bold: true,
                    marginTop: 23
                    // margin: [0, 20, 0, 20]
                },
                {
                    text: 'HƯỚNG DẪN LUẬN VĂN THẠC SĨ',
                    alignment: "center",
                    fontSize: 19,
                    font: "TimesNewRoman",
                    bold: true,
                    marginBottom: 26
                    // margin: [0, 20, 0, 20]
                },
                {
                    text: 'Khoa Sau đại học Trường Đại học Lạc Hồng trân trọng kính mời:',
                    alignment: "center",
                    fontSize: 15,
                    font: "TimesNewRoman",
                    bold: true,
                },
                {
                    text: `${vueData.HocHamHocVi}${vueData.HoTenGiangVien}`,
                    alignment: "center",
                    fontSize: 15,
                    font: "TimesNewRoman",
                    bold: true,
                    marginTop: 10,
                    marginBottom: 30
                },
                {
                    text: [
                        { text: "Tham gia hướng dẫn luận văn thạc sĩ " },
                        { text: `${item.TenNganh}` },
                        { text: ` cho học viên khóa ${item.NienKhoa.slice(0, item.NienKhoa.length - 3)} (Danh sách đính kèm)` }
                    ],
                    alignment: "justify",
                    fontSize: 14,
                    font: "TimesNewRoman",
                    marginTop: 5,
                    lineHeight: 1.5,
                    // margin: [0, 20, 0, 20]
                    marginBottom: 20,
                },
                {
                    text: 'Kế hoạch thực hiện:',
                    alignment: "justify",
                    fontSize: 14,
                    font: "TimesNewRoman",
                    bold: true,
                    // marginTop: 3,
                    lineHeight: 1.5,
                    preserveLeadingSpaces: true,
                    // margin: [0, 0, 0, 5],
                },
                {
                    text: `• Xác định tên đề tài và thực hiện đề cương: ${moment(vueData.ThoiGianXDDeTai).format('DD/MM/YYYY')}`,
                    alignment: "justify",
                    fontSize: 14,
                    font: "TimesNewRoman",
                    marginTop: 5,
                    lineHeight: 1.5,
                    marginLeft: 20,
                    preserveLeadingSpaces: true,
                },
                {
                    text: '\t• Thời hạn bảo vệ luận văn: Tối thiểu 06 tháng tính từ ngày ban hành Quyết định giao đề tài',
                    alignment: "justify",
                    fontSize: 14,
                    font: "TimesNewRoman",
                    marginTop: 5,
                    lineHeight: 1.5,
                    marginLeft: 20,
                },
                {
                    text: 'Rất mong nhận được sự hỗ trợ, giúp đỡ và cộng tác của Quý Thầy/Cô.',
                    alignment: "justify",
                    fontSize: 14,
                    font: "TimesNewRoman",
                    marginTop: 10,
                    lineHeight: 1.5,
                    preserveLeadingSpaces: true,
                },
                {
                    text: 'Trân trọng./.',
                    alignment: "justify",
                    fontSize: 14,
                    font: "TimesNewRoman",
                    marginTop: 5,
                    lineHeight: 1.5,
                    preserveLeadingSpaces: true,
                },
                {
                    text: [
                        { text: 'Liên hệ', bold: true, decoration: 'underline', italics: true },
                        ': 0251.3951924 (Khoa Sau đại học); 0945656262 (Trưởng khoa Sau Đại học)./.'
                    ],
                    alignment: "justify",
                    fontSize: 14,
                    font: "TimesNewRoman",
                    marginTop: 5,
                    // margin: [0, 20, 0, 20]
                    marginBottom: 20,
                },
                {
                    layout: 'noBorders',
                    table: {
                        widths: ['*', '*'],
                        body: [
                            [{ text: '', "style": { italics: true, bold: true, alignment: "left" } }, { text: 'TRƯỞNG KHOA', "style": { bold: true, alignment: "center" } }],
                            [{
                                text: '', "style": { alignment: "left" }
                            }, { text: '\n\nĐã ký', "style": { alignment: "center" } }],
                            [{
                                text: '', "style": { alignment: "left" }
                            }, { text: '\n\nLữ Phi Nga', "style": { bold: true, alignment: "center" } }],
                        ]
                    }
                },
                { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'portrait', margin: [0, 0, 0, 8] },
            ],
        }
        return example
    })
    arrNganh[arrNganh.length - 1].stack.pop()
    console.log("arrNganh[arrNganh.length - 1].stack", arrNganh[arrNganh.length - 1].stack)
    vueData.dataPDF = {
        "pageSize": "A4",
        "pageOrientation": "portrait",
        "defaultStyle": {
            "alignment": "justify",
            "font": "TimesNewRoman"
        },
        background: function (currentPage, pageSize) {
            //4 1234
            console.log("pageSize", pageSize)
            if (pageSize.orientation === "portrait") {
                return {
                    image: 'data:image/png;base64,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',
                    width: 580, //595
                    height: 842,
                    absolutePosition: { x: 10, y: 3 }
                }
            } else {
                return null
            }
        },
        "pageMargins": [
            50, //left
            60,  //top
            40, //right
            20 //bottom
        ],
        content: [],
        styles: {
            tableHeader: {
                fontSize: 12,
                font: "TimesNewRoman",
                alignment: "center"
            },
            header: {
                fontSize: 18,
                bold: true
            },
            subheader: {
                fontSize: 15,
                bold: true
            },
            quote: {
                italics: true
            },
            small: {
                fontSize: 8
            }
        }
    }
    console.log("vueData.dataPdf", vueData.dataPDF)
    vueData.dataPDF.content = arrNganh
    vueData.dataPDF.content.push({ text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'landscape', margin: [0, 0, 0, 8] })
    resultArray.forEach(arr => {
        let flag = true
        arr.forEach(item => {
            if (item.GVHD_2 !== " ") {
                return flag = false
            }
        })
        if (flag) {
            vueData.dataPDF.content.push({
                style: 'header',
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { fontSize: 12, bold: false, alignment: "center" } }, { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', "style": { bold: true, fontSize: 12, alignment: "center" } }],
                        [{ text: 'KHOA SAU ĐẠI HỌC', "style": { bold: true, fontSize: 12, alignment: "center" } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true, fontSize: 12, alignment: "center" } }],
                        [
                            {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0, y1: 0,
                                        x2: 60, y2: 0,
                                        lineWidth: 1
                                    }
                                ],
                                alignment: "center"
                            }, {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0, y1: 0,
                                        x2: 150, y2: 0,
                                        lineWidth: 1
                                    }
                                ],
                                alignment: "center"
                            }
                        ],
                    ]
                }
            })
            vueData.dataPDF.content.push({
                text: `DANH SÁCH HỌC VIÊN - GIẢNG VIÊN HƯỚNG DẪN LUẬN VĂN NGÀNH ${upperCaseString(arr[0].TenNganh)}`,
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 20, 0, 20]
            })
            vueData.dataPDF.content.push({
                style: 'tableHeader',
                table: { widths: [20, 47, 55, 65, 38, 60, 58, 84, 170, 65], body: generateTable(arr) },
            }, { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'landscape', margin: [0, 0, 0, 8] })
        }
        else {
            vueData.dataPDF.content.push({
                style: 'header',
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { fontSize: 12, bold: false, alignment: "center" } }, { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', "style": { bold: true, fontSize: 12, alignment: "center" } }],
                        [{ text: 'KHOA SAU ĐẠI HỌC', "style": { bold: true, fontSize: 12, alignment: "center" } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true, fontSize: 12, alignment: "center" } }],
                        [
                            {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0, y1: 0,
                                        x2: 60, y2: 0,
                                        lineWidth: 1
                                    }
                                ],
                                alignment: "center"
                            }, {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0, y1: 0,
                                        x2: 150, y2: 0,
                                        lineWidth: 1
                                    }
                                ],
                                alignment: "center"
                            }
                        ],
                    ]
                }
            })
            vueData.dataPDF.content.push({
                text: `DANH SÁCH HỌC VIÊN - GIẢNG VIÊN HƯỚNG DẪN LUẬN VĂN NGÀNH ${upperCaseString(arr[0].TenNganh)}`,
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 20, 0, 20]
            })
            vueData.dataPDF.content.push({
                style: 'tableHeader',
                table: { widths: [20, 47, 55, 50, 34, 54, 58, 68, 160, 60, 60], body: generateTable2GVHD(arr) },
            }, { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'landscape', margin: [0, 0, 0, 8] })
        }
    })
    vueData.dataPDF.content.pop()
}