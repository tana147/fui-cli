function GetDSNam() {
    const yearNow = moment().year()
    let dsYear = []
    for (let y = yearNow; y >= 2024; y--) {
        dsYear.push(y)
    }
    return dsYear
}
function handleColumnHinhThucThoiGian(HinhThucThoiGian) {
    let findIndexHeader = vueData.headers.findIndex(col => col.value && col.value == 'HinhThucThoiGian')
    if (findIndexHeader == -1) return
    vueData.headers[findIndexHeader].text = (vueData.DSHinhThucThoiGian.find(obj => obj.value == HinhThucThoiGian).text) ?? 'Hình thức thời gian'
}