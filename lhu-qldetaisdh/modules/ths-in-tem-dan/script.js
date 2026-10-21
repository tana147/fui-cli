function loadLocalStorage() {
    const JSONLocal = localStorage.getItem('JSON_PRINT_PDF_TEM')
    const JSONAllGVChucTrach = localStorage.getItem('JSON_PRINT_ALL_GV_CHUC_TRACH')
    if (JSONLocal) {
        const parseJSON = JSON.parse(JSONLocal)
        vueData.ThanhVienHoiDong = parseJSON
    } else {
        console.log('Not found JSONLocal')
    }
    if (JSONAllGVChucTrach) {
        const parseJSON = JSON.parse(JSONAllGVChucTrach)
        vueData.AllGVChucTrach = parseJSON
        console.log('vueData.AllGVChucTrach', vueData.AllGVChucTrach)
    } else {
        console.log('Not found JSONAllGVChucTrach')
    }
}
// Chức trách: Chủ tịch, Ủy viên, Thư ký
function checkChucTrach1(item) {
    const dataArr = vueData.AllGVChucTrach.filter((gv) => item.ThanhVienHoiDong_ID === gv.ThanhVienHoiDong_ID)
    return dataArr.some((element) => element.ThanhVienHoiDong_ChucTrach === 'Chủ tịch' || element.ThanhVienHoiDong_ChucTrach === 'Ủy viên' || element.ThanhVienHoiDong_ChucTrach === 'Thư ký')
}
// Chức trách: Phản biện 1, Phản biện 2
function checkChucTrach2(item) {
    const dataArr = vueData.AllGVChucTrach.filter((gv) => item.ThanhVienHoiDong_ID === gv.ThanhVienHoiDong_ID)
    return dataArr.some((element) => element.ThanhVienHoiDong_ChucTrach === 'Phản biện 1' || element.ThanhVienHoiDong_ChucTrach === 'Phản biện 2')
}
function calculateLeftMargin(text) {
    const textWidth = getTextWidth(text, { fontSize: 20 })
    const canvasWidth = 320 // Chiều rộng của canvas
    // Tính margin left để text được căn giữa
    const marginLeft = (canvasWidth - textWidth) / 2
    return marginLeft
}
function getTextWidth(text, style) {
    return text.length * 8
}
function InTemDan() {
    const content = [
        ...vueData.ThanhVienHoiDong.map((item, index) => {
            const col = index % 2 // 0 hoặc 1, xác định cột (trái hoặc phải)
            const row = Math.floor(index / 2) // xác định hàng
            return {
                stack: [
                    {
                        canvas: [
                            {
                                type: 'rect',
                                x: 0,
                                y: 0,
                                w: 400,
                                h: 180,
                                lineWidth: 4,
                                lineColor: 'black',
                            },
                        ],
                    },
                    {
                        text: `${item.HoTenThanhVien}`,
                        margin: [calculateLeftMargin(item.HoTenThanhVien), -170, 0, 10], // canh chỉnh text trong canvas
                        alignment: 'left',
                        fontSize: 24,
                        color: 'red',
                        bold: true,
                    },
                    {
                        text: `- ${item.SoCuonLuanVan < 10 ? '0' + item.SoCuonLuanVan : item.SoCuonLuanVan} cuốn luận văn`,
                        style: 'canvasContent', // canh chỉnh text trong canvas
                        alignment: 'left',
                    },
                    {
                        text: '- 01 thư mời',
                        style: 'canvasContent',
                        alignment: 'left',
                    },
                    {
                        text: '- 01 bảng thống kê hội đồng',
                        style: 'canvasContent',
                        alignment: 'left',
                    },
                    {
                        text: checkChucTrach2(item) ? `- 01 mẫu nhận xét dành cho giảng viên phản biện` : ``,
                        style: checkChucTrach2(item) ? 'canvasContent' : '',
                        alignment: 'left',
                    },
                    {
                        text: checkChucTrach1(item) ? `- 01 mẫu nhận xét dành cho chủ tịch, ủy viên, thư ký` : ``,
                        style: checkChucTrach1(item) ? 'canvasContent' : '',
                        alignment: 'left',
                    },
                ],
                margin: [col * 420, row, 0, 0], // vị trí của toàn bộ stack trên trang PDF
            }
        }),
    ]
    vueData.dataPDF = {
        pageSize: { width: 595, height: 842 },
        pageOrientation: 'landscape',
        defaultStyle: {
            alignment: 'justify',
            font: 'TimesNewRoman',
        },
        pageMargins: [
            10, //left, top, right, bottom
            10,
            0,
            0,
        ],
        content: content,
        styles: {
            canvasContent: {
                margin: [10, 5, 0, 0],
                fontSize: 18,
            },
        },
    }
}