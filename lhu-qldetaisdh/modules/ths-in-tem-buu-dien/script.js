function loadLocalStorage() {
    const JSONLocal = localStorage.getItem('JSON_PRINT_PDF_TEM_BUU_DIEN')
    if (JSONLocal) {
        const parseJSON = JSON.parse(JSONLocal)
        vueData.SenderInfo = parseJSON[0]
        vueData.ReceiverInfo = parseJSON[1]
        console.log('vueData.SenderInfo', vueData.SenderInfo)
        console.log('vueData.ReceiverInfo', vueData.ReceiverInfo)
    }
}
function InTemBuuDien() {
    let content = vueData.ReceiverInfo.map((item, index) => {
        const col = index % 2; // 0 hoặc 1, xác định cột (trái hoặc phải)
        const row = Math.floor(index / 2); // xác định hàng
        return {
            stack: [
                {
                    text: `NGƯỜI GỬI: ${vueData.SenderInfo.Sender}`,
                    style: "senderMargin",
                    alignment: 'left',
                    bold: true,
                    marginTop: index % 2 !== 0 ? 10 : 0,
                },
                {
                    text: `${vueData.SenderInfo.DiaChi}`,
                    style: "senderMargin",
                    alignment: 'left',
                },
                {
                    text: `SĐT: ${vueData.SenderInfo.SDT}`,
                    style: "senderMargin",
                    alignment: 'left',
                },
                {
                    text: `NGƯỜI NHẬN: ${item.HocViHocHam}. ${item.HoTenGiangVien}`,
                    style: "receiverMargin",
                    alignment: 'left',
                    marginTop: 115,
                    bold: true
                },
                {
                    columns: [
                        {
                            text: `${item.DiaChi ? item.DiaChi : '....................................................................................'}`,
                            style: "receiverMargin",
                            alignment: 'left',
                            width: 600,
                        }
                    ]
                },
                {
                    text: `SĐT: ${item.SoDienThoai ? item.SoDienThoai : '..........................................................................'}`,
                    style: "receiverMargin",
                    alignment: 'left',
                },
                ...((index + 1) % 3 !== 0 ? [ // Chỉ thêm dòng phân cách nếu không phải phần tử thứ 3 trên trang
                    {
                        text: `...................................................................................................................................................................................................................................`,
                        margin: [-50, 5, 0, 5],
                        alignment: 'left',
                    }
                ] : [])
            ],
            margin: [0, row, 0, 0],
            pageBreak: index % 3 === 2 ? 'after' : null // Ngắt trang sau mỗi 2 phần tử
        };
    });
    // Xử lý logic loại bỏ trang trắng (nếu có)
    // content = content.filter((item, index) => {
    //     // Loại bỏ phần tử có `pageBreak` nếu nó nằm cuối mảng
    //     if (item.pageBreak === 'after' && index === content.length - 1) {
    //         return false;
    //     }
    //     return true;
    // });
    vueData.dataPDF = {
        "pageSize": { width: 595, height: 842 },
        "pageOrientation": "potrait",
        "defaultStyle": {
            "alignment": "justify",
            "font": "TimesNewRoman"
        },
        "pageMargins": [
            0, //left, top, right, bottom
            5,
            0,
            0
        ],
        "content": content,
        styles: {
            receiverMargin: {
                margin: [240, 5, 0, 0],
                fontSize: 14
            },
            senderMargin: {
                margin: [0, 5, 0, 0],
                fontSize: 14
            }
        }
    };
}