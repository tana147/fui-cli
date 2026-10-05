function loadLocalStorage() {
    const JSONLocal = localStorage.getItem('JSON_PRINT_PDF_DSBVLV')
    if (JSONLocal) {
        const parseJSON = JSON.parse(JSONLocal)
        vueData.DanhSachArr = parseJSON
        vueData.TimeData = vueData.TimeSelect
        vueData.NganhData = vueData.NganhSelect
        // console.log("parseJSON", parseJSON)
        // console.log("TimeSelect", vueData.TimeSelect)
        // console.log("NganhSelect", vueData.NganhSelect)
    }
}
function fillMargin(obj, margin) {
    if (margin) {
        obj.height += (margin[1] + margin[3])
        obj.width += (margin[0] + margin[2])
    }
    return obj
}
function findInlineHeight(cell, maxWidth, usedWidth = 0) {
    if (cell._margin) {
        maxWidth = maxWidth - cell._margin[0] - cell._margin[2]
    }
    let calcLines = (inlines) => {
        if (!inlines) {
            return {
                height: 0,
                width: 0
            }
        }
        let currentMaxHeight = 0
        let lastHadLineEnd = false
        for (const currentNode of inlines) {
            usedWidth += currentNode.width
            if (usedWidth > maxWidth || lastHadLineEnd) {
                currentMaxHeight += currentNode.height
                usedWidth = currentNode.width
            } else {
                currentMaxHeight = Math.max(currentNode.height, currentMaxHeight)
            }
            lastHadLineEnd = !!currentNode.lineEnd
        }
        return fillMargin({
            height: currentMaxHeight,
            width: usedWidth
        }, cell._margin)
    }
    if (cell._offsets) {
        usedWidth += cell._offsets.total
    }
    if (cell._inlines && cell._inlines.length) {
        return calcLines(cell._inlines)
    } else if (cell.stack && cell.stack[0]) {
        return fillMargin(cell.stack.map(item => {
            return findInlineHeight(item, maxWidth)
        }).reduce((prev, next) => {
            return {
                height: prev.height + next.height,
                width: Math.max(prev.width + next.width)
            }
        }), cell._margin)
    } else if (cell.ul) {
        return fillMargin(cell.ul.map(item => {
            return findInlineHeight(item, maxWidth)
        }).reduce((prev, next) => {
            return {
                height: prev.height + next.height,
                width: Math.max(prev.width + next.width)
            }
        }), cell._margin)
    } else if (cell.table) {
        let currentMaxHeight = 0
        for (const currentTableBodies of cell.table.body) {
            const innerTableHeights = currentTableBodies.map(mapTableBodies, maxWidth, usedWidth)
            currentMaxHeight = Math.max(...innerTableHeights, currentMaxHeight)
        }
        return fillMargin({
            height: currentMaxHeight,
            width: usedWidth
        }, cell._margin)
    } else if (cell._height) {
        usedWidth += cell._width
        return fillMargin({
            height: cell._height,
            width: usedWidth
        }, cell._margin)
    }
    return fillMargin({
        height: null,
        width: usedWidth
    }, cell._margin)
}
const rowSpanCell = []
function updateRowSpanCell(rowHeight) {
    for (let i = rowSpanCell.length - 1; i >= 0; i--) {
        const rowCell = rowSpanCell[i]
        rowCell.maxHeight = rowCell.maxHeight + rowHeight
        const {
            maxHeight,
            cellHeight,
            align,
            cell
        } = rowCell
        rowCell.rowSpanCount = rowCell.rowSpanCount - 1
        if (!rowCell.rowSpanCount) {
            if (cellHeight && maxHeight > cellHeight) {
                let topMargin
                let cellAlign = align
                if (Array.isArray(align)) {
                    cellAlign = align
                }
                if (cellAlign === 'bottom') {
                    topMargin = maxHeight - cellHeight
                } else if (cellAlign === 'center') {
                    topMargin = (maxHeight - cellHeight) / 2
                }
                if (topMargin) {
                    if (cell._margin) {
                        cell._margin[1] = cell._margin[1] + topMargin
                    } else {
                        cell._margin = [0, topMargin, 0, 0]
                    }
                }
            }
            rowSpanCell.splice(i, 1)
        }
    }
}
function applyVerticalAlignment(node, rowIndex, align, manualHeight = 0) { // New default argument
    const allCellHeights = node.table.body[rowIndex].map(
        (innerNode, columnIndex) => {
            if (innerNode._span) return null
            const calcWidth = [...Array(innerNode.colSpan || 1).keys()].reduce((acc, i) => {
                return acc + node.table.widths[columnIndex + i]._calcWidth
            }, 0)
            const mFindInlineHeight = findInlineHeight(innerNode, calcWidth, 0, rowIndex, columnIndex)
            return mFindInlineHeight.height
        }
    )
    let maxRowHeight = manualHeight ? manualHeight[rowIndex] : Math.max(...allCellHeights) // handle manual height
    node.table.body[rowIndex].forEach((cell, ci) => {
        // 处理rowSpan的情况
        if (cell.rowSpan) {
            rowSpanCell.push({
                cell,
                rowSpanCount: cell.rowSpan,
                cellHeight: allCellHeights[ci],
                maxHeight: 0,
                align
            })
            return
        }
        if (allCellHeights[ci] && maxRowHeight > allCellHeights[ci]) {
            let topMargin
            let cellAlign = align
            if (Array.isArray(align)) {
                cellAlign = align[ci]
            }
            if (cellAlign === 'bottom') {
                topMargin = maxRowHeight - allCellHeights[ci]
            } else if (cellAlign === 'center') {
                topMargin = (maxRowHeight - allCellHeights[ci]) / 2
            }
            if (topMargin) {
                if (cell._margin) {
                    cell._margin[1] += topMargin
                } else {
                    cell._margin = [0, topMargin, 0, 0]
                }
            }
        }
    })
    updateRowSpanCell(maxRowHeight)
}
//
function generateTable(studentList) {
    let tableSortRows = [];
    tableSortRows.push([
        { text: 'TT', style: { bold: true, alignment: 'center' } },
        { text: 'MSHV', style: { bold: true, alignment: 'center' } },
        { text: 'Họ', style: { bold: true, alignment: 'center' } },
        { text: 'Tên', style: { bold: true, alignment: 'center' } },
        { text: 'Tên đề tài', style: { bold: true, alignment: 'center' } },
        { text: 'Điện thoại', style: { bold: true, alignment: 'center' } },
        { text: 'Khóa', style: { bold: true, alignment: 'center' } },
        { text: 'Email', style: { bold: true, alignment: 'center' } }
    ]);
    for (let i = 0; i < studentList.length; i++) {
        let student = studentList[i];
        tableSortRows.push([
            { text: `${student.STT}`, alignment: 'center' },
            { text: `${student.MSHV}`, alignment: 'center' },
            { text: `${student.Ho}`, alignment: 'left' },
            { text: `${student.Ten}`, alignment: 'left' },
            { text: `${student.DeTai}`, alignment: 'left' },
            { text: `${student.DienThoai}`, alignment: 'center' },
            { text: `${student.Khoa}`, alignment: 'center' },
            { text: `${student.Email}`, alignment: 'left' },
        ])
    }
    return tableSortRows;
}
// const encodedFilterArr = req.query.HoiDongID;
// const filterArr = JSON.parse(decodeURIComponent(encodedFilterArr));
// console.log("filterArr", filterArr)
function InDanhSachBVLV(data) {
    console.log("data", data.ThoiGianBV)
    let tableSortRows = []
    let dataArr = []
    vueData.DanhSachArr.forEach((item, index) => {
        let khoaSplit = item.Nien_Khoa.split('-')[0];
        dataArr.push({
            STT: index + 1,
            MSHV: item.Student_ID,
            Ho: item.Ho_SV,
            Ten: item.Ten_SV,
            DeTai: item.Thesis_Name,
            DienThoai: item.PhoneNumber,
            Khoa: khoaSplit,
            Email: item.Email
        })
    })
    console.log("dataArr", dataArr)
    const mockList = [
        {
            STT: "1",
            MSHV: "921000139",
            Ho: "Khổng Tài",
            Ten: "Múi",
            DeTai: "Hoàn thiện hệ thống kế toán quản trị chi phí tại công ty TNHH MTV Bệnh viên Đại Học Y Dược Shingmark",
            DienThoai: "0903803723",
            Khoa: "2021",
            Email: "abc@gmail.com"
        },
        {
            STT: "2",
            MSHV: "921000139",
            Ho: "Tạ Thị Thanh",
            Ten: "Vân",
            DeTai: "Kiểm tra tính tuân thủ thuế của người nộp thuế thông qua hoạt động thanh tra chống chuyển giá tại Cục thuế tỉnh Đồng Nai",
            DienThoai: "0941795879",
            Khoa: "2021",
            Email: "bde@gmail.com"
        },
        {
            STT: "3",
            MSHV: "921000139",
            Ho: "Nguyễn Nam",
            Ten: "Hải ",
            DeTai: "Hoàn thiện hệ thống kiểm soát nội bộ tại công ty TNHH vận tải Nam Vân",
            DienThoai: "0903052956",
            Khoa: "2020",
            Email: "fgh@gmail.com"
        },
    ]
    tableSortRows = generateTable(dataArr)
    let tableDSHocVien = {
        body: tableSortRows,
        alignment: "center",
        widths: [20, 55, 90, 30, 320, 60, 30, 100]
    }
    vueData.dataPDF = {
        "pageSize": { width: 595, height: 842 },
        "pageOrientation": "landscape",
        "defaultStyle": {
            "alignment": "justify",
            "font": "TimesNewRoman"
        },
        "pageMargins": [ //left, top, right, bottom
            30,
            60,
            30,
            60
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
                    ]
                },
            },
            {
                text: `DANH SÁCH HỌC VIÊN NGÀNH ${vueData.NganhData.toUpperCase()} BẢO VỆ LUẬN VĂN THẠC SĨ NGÀY ${vueData.TimeData}`,
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 20, 0, 0]
            },
            {
                style: 'header',
                table: tableDSHocVien,
                margin: [0, 10, 0, 0],
                layout: {
                    paddingTop: function (index, node) {
                        applyVerticalAlignment(node, index, 'center');
                        return 0;
                    },
                }
            },
            {
                text: `Danh sách có ${dataArr.length} học viên./.`,
                alignment: "left",
                fontSize: 11,
                font: "TimesNewRoman",
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
            }
        }
    }
}