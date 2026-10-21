// Thêm dòng tiêu đề (header)
// tableRows.push([
//     { text: 'STT', style: { bold: true } },
//     { text: 'MSHV', style: { bold: true } },
//     { text: 'Họ tên', style: { bold: true }, colSpan: 2 },
//     {},
//     { text: 'Ngày sinh', style: { bold: true } },
//     { text: 'Nơi sinh', style: { bold: true } },
//     { text: 'Tên đề tài', style: { bold: true } },
//     { text: 'Giảng viên hướng dẫn', style: { bold: true } }
// ]);
// // Sử dụng vòng lặp thông thường để thêm dòng cho mỗi sinh viên
// for (let i = 0; i < data.Decision_StudentList.length; i++) {
//     let student = data.Decision_StudentList[i];
//     tableRows.push([
//         { text: `${String(student.STT).padStart(2, '0')}` },
//         { text: `${student.Student_ID}` },
//         { text: `${student.Ho_SV} ` },
//         { text: `${student.Ten_SV} ` },
//         { text: `${student.Ngay_Sinh} ` },
//         { text: `${student.Noi_Sinh} ` },
//         { text: `${student.Thesis_Name} ` },
//         { text: `${student.Thesises_Prof1} ` }
//     ]);
// }
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
                // console.log('topMargin', topMargin)
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
    allCellHeights.pop();
    let maxRowHeight = manualHeight ? manualHeight[rowIndex] : Math.max(...allCellHeights) // handle manual height
    node.table.body[rowIndex].forEach((cell, ci) => {
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
                // console.log(cell, maxRowHeight, allCellHeights[ci])
            }
            if (topMargin) {
                if (cell._margin) {
                    cell._margin[1] += topMargin
                    // cell._margin[1] += topMargin
                } else {
                    // console.log("topMargin xxx", topMargin)
                    cell._margin = [0, topMargin, 0, 0]
                }
            }
        }
    })
    updateRowSpanCell(maxRowHeight)
}
//
function groupByProfessors(studentList) {
    let grouped = {};
    studentList.forEach(student => {
        let key = student.Thesises_Prof1 + '-' + student.Thesises_Prof2;
        if (!grouped[key]) {
            grouped[key] = {
                Thesises_Prof1: student.Thesises_Prof1,
                Thesises_Prof2: student.Thesises_Prof2,
                Students: []
            };
        }
        grouped[key].Students.push(student);
    });
    console.log("group list xxx", Object.values(grouped))
    return Object.values(grouped);
}
function groupForEachProf(studentList) {
    const groupedStudents = [];
    studentList.forEach(student => {
        // Tạo một khóa kết hợp của Thesises_Prof1 và Thesises_Prof2
        const key = `${student.Thesises_Prof1}-${student.Thesises_Prof2}`;
        // Tìm hoặc tạo một đối tượng mới trong groupedStudents cho Thesises_Prof1
        let prof1Group = groupedStudents.find(group => group.Thesises_Prof === student.Thesises_Prof1);
        if (!prof1Group) {
            prof1Group = { Thesises_Prof: student.Thesises_Prof1, Students: [], currentSTT: 1 };
            groupedStudents.push(prof1Group);
        }
        prof1Group.Students.push({ ...student, Thesises_Prof: student.Thesises_Prof1, key, STT: prof1Group.currentSTT });
        prof1Group.currentSTT++;
        // Tìm hoặc tạo một đối tượng mới trong groupedStudents cho Thesises_Prof2 nếu nó không rỗng hoặc null
        if (student.Thesises_Prof2) {
            let prof2Group = groupedStudents.find(group => group.Thesises_Prof === student.Thesises_Prof2);
            if (!prof2Group) {
                prof2Group = { Thesises_Prof: student.Thesises_Prof2, Students: [], currentSTT: 1 };
                groupedStudents.push(prof2Group);
            }
            prof2Group.Students.push({ ...student, Thesises_Prof: student.Thesises_Prof2, key, STT: prof2Group.currentSTT });
            prof2Group.currentSTT++;
        }
    });
    // Loại bỏ thuộc tính currentSTT khỏi mỗi nhóm trước khi trả về
    groupedStudents.forEach(group => {
        delete group.currentSTT;
    });
    return groupedStudents;
}
function generateTable(sortedStudentList) {
    let checkGVHD2Null = sortedStudentList.some(item => item.Thesises_Prof2 === "" || item.Thesises_Prof2 === null);
    let tableSortRows = [];
    let currentOrder = 1; // Biến đếm thứ tự bắt đầu từ 1
    if (!checkGVHD2Null) {
        tableSortRows.push([
            { text: 'TT', style: { bold: true, alignment: 'center' } },
            { text: 'MSHV', style: { bold: true, alignment: 'center' } },
            { text: 'Họ', style: { bold: true, alignment: 'center' } },
            { text: 'Tên', style: { bold: true, alignment: 'center' } },
            { text: 'Ngày sinh', style: { bold: true, alignment: 'center' } },
            { text: 'Nơi sinh', style: { bold: true, alignment: 'center' } },
            { text: 'Tên đề tài', style: { bold: true, alignment: 'center' } },
            { text: 'GVHD 1', style: { bold: true, alignment: 'center' } },
            { text: 'GVHD 2', style: { bold: true, alignment: 'center' } }
        ]);
    } else {
        tableSortRows.push([
            { text: 'TT', style: { bold: true, alignment: 'center' } },
            { text: 'MSHV', style: { bold: true, alignment: 'center' } },
            { text: 'Họ', style: { bold: true, alignment: 'center' } },
            { text: 'Tên', style: { bold: true, alignment: 'center' } },
            { text: 'Ngày sinh', style: { bold: true, alignment: 'center' } },
            { text: 'Nơi sinh', style: { bold: true, alignment: 'center' } },
            { text: 'Tên đề tài', style: { bold: true, alignment: 'center' } },
            { text: 'GVHD', style: { bold: true, alignment: 'center' } },
        ]);
    }
    // Tạo cấu trúc dữ liệu tạm thời để lưu trữ các nhóm sinh viên
    let groupedStudents = {};
    for (let i = 0; i < sortedStudentList.length; i++) {
        let group = sortedStudentList[i];
        let key = group.Thesises_Prof1 + '-' + group.Thesises_Prof2;
        if (!groupedStudents[key]) {
            groupedStudents[key] = {
                Thesises_Prof1: group.Thesises_Prof1,
                Thesises_Prof2: group.Thesises_Prof2,
                Students: []
            };
        }
        groupedStudents[key].Students.push(...group.Students);
    }
    // Lặp qua các nhóm sinh viên đã được nhóm
    for (let key in groupedStudents) {
        let group = groupedStudents[key];
        let students = group.Students;
        let rowspan = students.length;
        // So tu cua cot
        let countChar = 0;
        students.forEach(item => countChar += item.Thesis_Name.split(' ').length);
        let rowChar = Math.ceil(countChar / 9); // Tinh ra so dong ~9 tu / dong
        // Tinh ra so height
        const rowHeight = rowChar * 10;
        const marginTop = (rowHeight / 2) + (parseInt(rowspan) >= 2 ? 5 : -5);
        let marginArr = [0, 5 * rowspan, 0, 0];
        // let marginArr = [0, 30, 0, 0];
        // let marginArr = [0, marginTop, 0, 0];
        if (!checkGVHD2Null) {
            if (students.length > 0) {
                tableSortRows.push([
                    { text: `${currentOrder++}`, alignment: 'center' }, // Sử dụng biến đếm thứ tự
                    { text: `${students[0].Student_ID}`, alignment: 'left' },
                    { text: `${students[0].Ho_SV}`, alignment: 'left' },
                    { text: `${students[0].Ten_SV}`, alignment: 'left' },
                    { text: `${students[0].Ngay_Sinh}`, alignment: 'left' },
                    { text: `${students[0].Noi_Sinh}`, alignment: 'left' },
                    { text: `${students[0].Thesis_Name}`, alignment: 'left' },
                    {
                        stack: [{ text: group.Thesises_Prof1, alignment: 'left' }],
                        rowSpan: rowspan,
                        alignment: 'left',
                        margin: marginArr
                    },
                    {
                        stack: [{ text: group.Thesises_Prof2, alignment: 'left' }],
                        rowSpan: rowspan,
                        alignment: 'left',
                        margin: marginArr
                    },
                ]);
            }
        } else {
            if (students.length > 0) {
                tableSortRows.push([
                    { text: `${currentOrder++}`, alignment: 'center' }, // Sử dụng biến đếm thứ tự
                    { text: `${students[0].Student_ID}`, alignment: 'left' },
                    { text: `${students[0].Ho_SV}`, alignment: 'left' },
                    { text: `${students[0].Ten_SV}`, alignment: 'left' },
                    { text: `${students[0].Ngay_Sinh}`, alignment: 'left' },
                    { text: `${students[0].Noi_Sinh}`, alignment: 'left' },
                    { text: `${students[0].Thesis_Name}`, alignment: 'left' },
                    {
                        stack: [{ text: group.Thesises_Prof1, alignment: 'left' }],
                        rowSpan: rowspan,
                        alignment: 'left',
                        margin: marginArr
                    },
                ]);
            }
        }
        // Thêm các dòng còn lại của nhóm mà không có dữ liệu cho cột "Giảng viên hướng dẫn"
        for (let j = 1; j < students.length; j++) {
            let student = students[j];
            tableSortRows.push([
                { text: `${currentOrder++}`, alignment: 'center' }, // Sử dụng biến đếm thứ tự
                { text: `${student.Student_ID}`, alignment: 'left' },
                { text: `${student.Ho_SV}`, alignment: 'left' },
                { text: `${student.Ten_SV}`, alignment: 'left' },
                { text: `${student.Ngay_Sinh}`, alignment: 'left' },
                { text: `${student.Noi_Sinh}`, alignment: 'left' },
                { text: `${student.Thesis_Name}`, alignment: 'left' },
                { text: '', alignment: 'left' } // Ô trống cho cột "Giảng viên hướng dẫn" các hàng tiếp theo
            ]);
        }
    }
    return tableSortRows;
}
function generateSperateTable(group) {
    let tableRows = [];
    // Thêm tiêu đề bảng
    const checkGVHD2Null = group.Students.some(item => item.Thesises_Prof2 === "" || item.Thesises_Prof2 === null)
    if (!checkGVHD2Null) {
        tableRows.push([
            { text: 'TT', style: { bold: true } },
            { text: 'MSHV', style: { bold: true } },
            { text: 'Họ', style: { bold: true } },
            { text: 'Tên', style: { bold: true } },
            { text: 'Ngày sinh', style: { bold: true } },
            { text: 'Nơi sinh', style: { bold: true } },
            { text: 'Tên đề tài', style: { bold: true } },
            { text: 'GVHD 1', style: { bold: true } },
            { text: 'GVHD 2', style: { bold: true } },
        ]);
    } else {
        tableRows.push([
            { text: 'TT', style: { bold: true } },
            { text: 'MSHV', style: { bold: true } },
            { text: 'Họ', style: { bold: true } },
            { text: 'Tên', style: { bold: true } },
            { text: 'Ngày sinh', style: { bold: true } },
            { text: 'Nơi sinh', style: { bold: true } },
            { text: 'Tên đề tài', style: { bold: true } },
            { text: 'GVHD', style: { bold: true } },
        ]);
    }
    let students = group.Students;
    let rowspan = students.length;
    let countChar = 0
    students.forEach(item => countChar += item.Thesis_Name.split(' ').length)
    let rowChar = Math.ceil(countChar / 9) //Tinh ra so dong ~9 tu / dong
    //Tinh ra so height
    const rowHeight = rowChar * 10
    const marginTop = (rowHeight / 2) + (parseInt(rowspan) >= 2 ? 8 : -5)
    let marginArr = [0, 5 * rowspan, 0, 0];
    // let marginArr = [0, 30, 0, 0];
    // let marginArr = [0, marginTop, 0, 0];
    for (let i = 0; i < students.length; i++) {
        let student = students[i];
        let row = [
            { text: `${student.STT}` },
            { text: `${student.Student_ID}`, alignment: 'left' },
            { text: `${student.Ho_SV}`, alignment: 'left' },
            { text: `${student.Ten_SV}`, alignment: 'left' },
            { text: `${student.Ngay_Sinh}`, alignment: 'left' },
            { text: `${student.Noi_Sinh}`, alignment: 'left' },
            { text: `${student.Thesis_Name}`, alignment: 'left', },
            // {
            //     text: [
            //         { text: `GVHD 1: ${student.Thesises_Prof1}\n`, alignment: 'left' },
            //         { text: `\nGVHD 2: ${student.Thesises_Prof2}`, alignment: 'left' },
            //     ]
            // }
        ];
        row.push({
            stack: [
                { text: student.Thesises_Prof1, alignment: 'left' },
            ],
            rowSpan: rowspan,
            alignment: 'left',
            margin: marginArr
        });
        if (student.Thesises_Prof2 !== "" || student.Thesises_Prof2 !== null) {
            row.push({
                stack: [
                    { text: student.Thesises_Prof2, alignment: 'left' },
                ],
                rowSpan: rowspan,
                alignment: 'left',
                margin: marginArr
            });
            tableRows.push(row);
        }
    }
    return tableRows;
}
function InQuyetDinhThacSi(data) {
    let tableSortRows = [];
    let sortedStudentList = [];
    let groupEachProf = []
    sortedStudentList = groupByProfessors(data.Decision_StudentList);
    console.log("sortedStudentList", sortedStudentList)
    groupEachProf = groupForEachProf(data.Decision_StudentList)
    console.log("groupEachProf", groupEachProf)
    // console.log("groupByProfessors", sortedStudentList);
    tableSortRows = generateTable(sortedStudentList)
    // console.log("tableSortRows", tableSortRows)
    // Tạo table object với dòng dữ liệu được tạo ra
    let checkGVHD2Null = sortedStudentList.some(item => item.Thesises_Prof2 === "" || item.Thesises_Prof2 === null);
    let tableDSHocVien = {
        widths: checkGVHD2Null ? [25, 55, 80, 40, 55, 60, 235, 100] : [25, 55, 80, 40, 55, 60, 235, 55, 55],
        body: tableSortRows,
        alignment: "center"
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
            60, //left
            65,  //top
            40, //right
            20 //bottom
        ],
        "content": [
            {
                style: 'header',
                layout: 'noBorders',
                table: {
                    widths: ['*', '270'],
                    body: [
                        [{ text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', "style": { fontSize: 13 } }, { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', "style": { bold: true, fontSize: 13 } }],
                        [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { bold: true, fontSize: 13, margin: [0, 0, 0, 0] } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true, fontSize: 14, margin: [0, 0, 0, 0] } }],
                        [{
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: -1,
                                    x2: 100, y2: -1,
                                    lineWidth: 0.5,
                                }
                            ]
                        }, {
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: -1,
                                    x2: 170, y2: -1,
                                    lineWidth: 0.5
                                }
                            ]
                        }],
                        [{ text: `Số: ${data.Decision_SoQD}`, "style": { margin: [0, 50, 0, 50], fontSize: 13 } }
                            , { text: `Đồng Nai, ngày ${data.Decision_NgayQD} tháng ${data.Decision_ThangQD} năm ${data.Decision_NamQD}`, "style": { italics: true, margin: [0, 50, 0, 50], fontSize: 13 } }],
                    ]
                }
            },
            {
                text: '\nQUYẾT ĐỊNH',
                alignment: "center",
                fontSize: 15,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 5, 0, 5]
            },
            {
                text: 'Về việc công nhận tên đề tài và giảng viên hướng dẫn luận văn thạc sĩ ',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: `ngành ${data.Decision_Nganh} - khóa ${data.Decision_NienKhoa.slice(0, data.Decision_NienKhoa.length - 3)}${(data.Decision_Dot === '' || data.Decision_Dot === null) ? '' : '.' + data.Decision_Dot}`,
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 0, 0, 5]
            },
            {
                table: {
                    widths: ['*', 'auto', '*'],
                    body: [
                        [
                            '',
                            {
                                canvas: [
                                    {
                                        type: 'line',
                                        x1: 0, y1: 0,
                                        x2: 150, y2: 0,
                                        lineWidth: 1
                                    }
                                ]
                            },
                            ''
                        ]
                    ]
                },
                layout: 'noBorders'
            },
            {
                text: 'HIỆU TRƯỞNG TRƯỜNG ĐẠI HỌC LẠC HỒNG',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 12, 0, 12],
                lineHeight: 1
            },
            {
                text: [
                    { text: '\t\t\tCăn cứ Quyết định số 790/TTg ngày 24/9/1997 của Thủ tướng Chính phủ về việc thành lập Trường Đại học dân lập Lạc Hồng;\n', },
                    ``
                ],
                alignment: "justify",
                fontSize: 13,
                italics: true,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                // margin: [0, 0, 0, 5]
                margin: [0, 6, 0, 0],
                lineHeight: 1,
            },
            {
                text: [
                    { text: '\t\t\tCăn cứ Quyết định số 1801/QĐ-TTg ngày 22/10/2015 của Thủ tướng Chính phủ về việc chuyển đổi loại hình của Trường Đại học dân lập Lạc Hồng;\n', },
                    ``
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                italics: true,
                margin: [0, 6, 0, 0],
                lineHeight: 1,
            },
            {
                text: [
                    { text: '\t\t\tCăn cứ Quy chế tổ chức và hoạt động của Trường Đại học Lạc Hồng;', },
                    ``
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                italics: true,
                margin: [0, 6, 0, 0],
                lineHeight: 1,
            },
            {
                text: [
                    { text: '\t\t\tCăn cứ Quyết định số 05/QĐ-ĐHLH.K2 ngày 08/6/2021 của Hội nghị nhà đầu tư về việc công nhận chức vụ Hiệu trưởng Trường Đại học tư thục Lạc Hồng nhiệm kỳ 2020-2025;', },
                    ``
                ],
                alignment: "justify",
                fontSize: 13,
                italics: true,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 6, 0, 0],
                lineHeight: 1,
            },
            {
                text: [
                    { text: '\t\t\tCăn cứ Quyết định số 787/QĐ-ĐHLH ngày 28/12/2021 của Hiệu trưởng trường Đại học Lạc Hồng về việc ban hành Quy chế tuyển sinh và đào tạo trình độ thạc sĩ;', },
                    ``
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                italics: true,
                margin: [0, 6, 0, 0],
                lineHeight: 1,
            },
            {
                text: [
                    { text: '\t\t\tCăn cứ chức năng và quyền hạn của Hiệu trưởng Trường Đại học Lạc Hồng;', },
                    ``
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                italics: true,
                margin: [0, 6, 0, 0],
                lineHeight: 1,
            },
            {
                text: [
                    { text: '\t\t\tTheo đề nghị của Trưởng Khoa Sau đại học.', },
                    ``
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                italics: true,
                margin: [0, 6, 0, 0],
                lineHeight: 1,
            },
            {
                text: 'QUYẾT ĐỊNH:',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 6, 0, 6],
                lineHeight: 1,
            },
            {
                text: [
                    { text: '\t\t\tĐiều 1. ', bold: true },
                    `Công nhận tên đề tài và giảng viên hướng dẫn luận văn cho ${data.Decision_SLHVBangSo} (${data.Decision_SLHVBangChu}) học viên khóa ${data.Decision_NienKhoa.slice(0, data.Decision_NienKhoa.length - 3)}${(data.Decision_Dot === '' || data.Decision_Dot === null) ? '' : '.' + data.Decision_Dot}, ngành ${data.Decision_Nganh}, mã số: ${data.Decision_MaSo} (danh sách kèm theo).`
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 6],
                lineHeight: 1.15,
            },
            {
                text: [
                    { text: '\t\t\tĐiều 2. ', bold: true },
                    'Học viên, giảng viên hướng dẫn có trách nhiệm thực hiện nhiệm vụ và được hưởng các quyền lợi ghi trong Quy chế đào tạo trình độ thạc sĩ.'
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 6],
                lineHeight: 1.15,
            },
            {
                text: [
                    { text: '\t\t\tĐiều 3. ', bold: true },
                    'Trưởng khoa Sau đại học, các đơn vị liên quan, người hướng dẫn khoa học và các học viên có tên trong Điều 1 chịu trách nhiệm thi hành Quyết định này./.'
                ],
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 6],
                lineHeight: 1.15,
            },
            {
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: 'Nơi nhận:', "style": { italics: true, bold: true, alignment: "left", fontSize: 12 } }, { text: 'HIỆU TRƯỞNG', "style": { bold: true, alignment: "center" } }],
                        [{
                            text: `- Như Điều 3;\n - Lưu: VT, K.SĐH, (${data.Decision_NguoiTao}).`, "style": { alignment: "left", fontSize: 10 }
                        }, { text: '\n\n\n\n\n\nLâm Thành Hiển', "style": { bold: true, alignment: "center" } }],
                    ]
                }
            },
            { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'landscape', margin: [0, 0, 0, 8] },
            {
                style: 'header',
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', "style": {} }, { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', "style": { bold: true } }],
                        [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { bold: true } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true } }],
                        [{
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: -1,
                                    x2: 100, y2: -1,
                                    lineWidth: 0.5
                                }
                            ]
                        }, {
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: -1,
                                    x2: 150, y2: -1,
                                    lineWidth: 0.5
                                }
                            ]
                        }]
                    ]
                }
            },
            {
                text: 'DANH SÁCH HỌC VIÊN, TÊN ĐỀ TÀI VÀ GIẢNG VIÊN HƯỚNG DẪN LUẬN VĂN THẠC SĨ ',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 20, 0, 5]
            },
            {
                text: `NGÀNH ${data.Decision_Nganh.toUpperCase()} - KHÓA ${data.Decision_NienKhoa.slice(0, data.Decision_NienKhoa.length - 3)}${(data.Decision_Dot === '' || data.Decision_Dot === null) ? '' : '.' + data.Decision_Dot}`,
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: `(Kèm theo Quyết định số ${data.Decision_SoQD} ngày ${data.Decision_NgayQD} tháng ${data.Decision_ThangQD} năm ${data.Decision_NamQD} của Hiệu trưởng Trường Đại học Lạc Hồng)`,
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                margin: [0, 0, 0, 5]
            },
            {
                style: 'header',
                table: tableDSHocVien,
                layout: {
                    paddingTop: function (index, node) {
                        applyVerticalAlignment(node, index, 'center');
                        return 0;
                    },
                    hLineWidth: function (i, node) {
                        return 0.5; // Độ dày của đường viền ngang
                    },
                    vLineWidth: function (i, node) {
                        return 0.5; // Độ dày của đường viền dọc
                    },
                    hLineColor: function (i, node) {
                        return 'black'; // Màu của đường viền ngang
                    },
                    vLineColor: function (i, node) {
                        return 'black'; // Màu của đường viền dọc
                    }
                }
            },
            {
                text: `Danh sách có ${data.Decision_SLHVBangSo} (${data.Decision_SLHVBangChu}) học viên./.`,
                alignment: "justify",
                fontSize: 13,
                font: "TimesNewRoman",
                preserveLeadingSpaces: true,
                margin: [0, 0, 0, 5]
            },
            {
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: '', "style": { italics: true, bold: true, alignment: "left" } }, { text: 'HIỆU TRƯỞNG', "style": { bold: true, alignment: "center", fontSize: 13 } }],
                        [{
                            text: '', "style": { alignment: "left" }
                        }, { text: '\n\n\n\n\nLâm Thành Hiển', "style": { bold: true, alignment: "center", fontSize: 13 } }],
                    ]
                }
            },
            { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'landscape', margin: [0, 0, 0, 8] },
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
    for (let i = 0; i < groupEachProf.length; i++) {
        let filterArr = sortedStudentList.filter(item => item.Thesises_Prof1 === groupEachProf[i].Thesises_Prof || item.Thesises_Prof2 === groupEachProf[i].Thesises_Prof)
        let filterTableRow = generateTable(filterArr)
        // let tableDSHocVien = {
        //     widths: checkGVHD2Null ? [25, 55, 80, 40, 55, 60, 235, 100] : [25, 55, 80, 40, 55, 60, 235, 55, 55],
        //     body: tableSortRows,
        //     alignment: "center"
        // };
        vueData.dataPDF.content.push(
            {
                style: 'header',
                layout: 'noBorders',
                table: {
                    widths: ['*', '*'],
                    body: [
                        [{ text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', "style": {} }, { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', "style": { bold: true } }],
                        [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { bold: true } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true } }],
                        [{
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: -1,
                                    x2: 100, y2: -1,
                                    lineWidth: 0.5
                                }
                            ]
                        }, {
                            canvas: [
                                {
                                    type: 'line',
                                    x1: 0, y1: -1,
                                    x2: 150, y2: -1,
                                    lineWidth: 0.5
                                }
                            ]
                        }]
                    ]
                }
            },
            {
                text: 'DANH SÁCH HỌC VIÊN, TÊN ĐỀ TÀI VÀ GIẢNG VIÊN HƯỚNG DẪN LUẬN VĂN THẠC SĨ ',
                alignment: "center",
                fontSize: 14,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 20, 0, 5]
            },
            {
                text: `NGÀNH ${data.Decision_Nganh.toUpperCase()} - KHÓA ${data.Decision_NienKhoa.slice(0, data.Decision_NienKhoa.length - 3)}${(data.Decision_Dot === '' || data.Decision_Dot === null) ? '' : '.' + data.Decision_Dot}`,
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                bold: true,
                margin: [0, 0, 0, 5]
            },
            {
                text: `(Trích từ Quyết định số ${data.Decision_SoQD}, ngày ${data.Decision_NgayQD} tháng ${data.Decision_ThangQD} năm ${data.Decision_NamQD} của Hiệu trưởng Trường Đại học Lạc Hồng)`,
                alignment: "center",
                fontSize: 13,
                font: "TimesNewRoman",
                italics: true,
                margin: [0, 0, 0, 5]
            },
            //
        )
        vueData.dataPDF.content.push({
            style: 'header',
            table: { widths: checkGVHD2Null ? [25, 55, 80, 40, 55, 60, 235, 80, 100] : [25, 55, 80, 40, 55, 60, 235, 50, 55], body: filterTableRow },
            layout: {
                paddingTop: function (index, node) {
                    applyVerticalAlignment(node, index, 'center');
                    return 0;
                },
                hLineWidth: function (i, node) {
                    return 0.5; // Độ dày của đường viền ngang
                },
                vLineWidth: function (i, node) {
                    return 0.5; // Độ dày của đường viền dọc
                },
                hLineColor: function (i, node) {
                    return 'black'; // Màu của đường viền ngang
                },
                vLineColor: function (i, node) {
                    return 'black'; // Màu của đường viền dọc
                }
            }
        }, { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'landscape', margin: [0, 0, 0, 8] });
    }
    // for (let i = 0; i < groupEachProf.length; i++) {
    //     let group = groupEachProf[i];
    //     let seperateTable = generateSperateTable(group);
    //     // console.log("custom table", seperateTable);
    //     vueData.dataPDF.content.push(
    //         {
    //             style: 'header',
    //             layout: 'noBorders',
    //             table: {
    //                 widths: ['*', '*'],
    //                 body: [
    //                     [{ text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO', "style": {} }, { text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', "style": { bold: true } }],
    //                     [{ text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG', "style": { bold: true } }, { text: 'Độc lập - Tự do - Hạnh phúc', "style": { bold: true } }],
    //                     [{
    //                         canvas: [
    //                             {
    //                                 type: 'line',
    //                                 x1: 0, y1: -1,
    //                                 x2: 100, y2: -1,
    //                                 lineWidth: 0.5
    //                             }
    //                         ]
    //                     }, {
    //                         canvas: [
    //                             {
    //                                 type: 'line',
    //                                 x1: 0, y1: -1,
    //                                 x2: 150, y2: -1,
    //                                 lineWidth: 0.5
    //                             }
    //                         ]
    //                     }]
    //                 ]
    //             }
    //         },
    //         {
    //             text: 'DANH SÁCH HỌC VIÊN, TÊN ĐỀ TÀI VÀ GIẢNG VIÊN HƯỚNG DẪN LUẬN VĂN THẠC SĨ ',
    //             alignment: "center",
    //             fontSize: 14,
    //             font: "TimesNewRoman",
    //             bold: true,
    //             margin: [0, 20, 0, 5]
    //         },
    //         {
    //             text: `NGÀNH ${data.Decision_Nganh.toUpperCase()} - KHÓA ${data.Decision_NienKhoa.slice(0, data.Decision_NienKhoa.length - 3)}${(data.Decision_Dot === '' || data.Decision_Dot === null) ? '' : '.' + data.Decision_Dot}`,
    //             alignment: "center",
    //             fontSize: 13,
    //             font: "TimesNewRoman",
    //             bold: true,
    //             margin: [0, 0, 0, 5]
    //         },
    //         {
    //             text: `(Trích từ Quyết định số ${data.Decision_SoQD}, ngày ${data.Decision_NgayQD} tháng ${data.Decision_ThangQD} năm ${data.Decision_NamQD} của Hiệu trưởng Trường Đại học Lạc Hồng)`,
    //             alignment: "center",
    //             fontSize: 13,
    //             font: "TimesNewRoman",
    //             italics: true,
    //             margin: [0, 0, 0, 5]
    //         },
    //         //
    //     )
    //     vueData.dataPDF.content.push({
    //         style: 'header',
    //         table: { widths: checkGVHD2Null ? [25, 55, 80, 40, 55, 60, 235, 80, 100] : [25, 55, 80, 40, 55, 60, 235, 50, 55], body: seperateTable },
    //         layout: {
    //             paddingTop: function (index, node) {
    //                 applyVerticalAlignment(node, index, 'center');
    //                 return 0;
    //             },
    //             hLineWidth: function (i, node) {
    //                 return 0.5; // Độ dày của đường viền ngang
    //             },
    //             vLineWidth: function (i, node) {
    //                 return 0.5; // Độ dày của đường viền dọc
    //             },
    //             hLineColor: function (i, node) {
    //                 return 'black'; // Màu của đường viền ngang
    //             },
    //             vLineColor: function (i, node) {
    //                 return 'black'; // Màu của đường viền dọc
    //             }
    //         }
    //     }, { text: '', fontSize: 14, bold: true, pageBreak: 'before', pageOrientation: 'landscape', margin: [0, 0, 0, 8] });
    // }
    vueData.dataPDF.content.pop()
}