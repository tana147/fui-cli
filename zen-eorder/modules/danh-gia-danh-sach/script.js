function mapDataDiemDanhGia() {
    const dataFilter = []
    vueData.DSDanhGia[0].forEach(item => {
        const objMap = { ...item }
        const arrDiemDanhGia = vueData.DSDanhGia[2].filter(diem => diem.DanhGiaID === item.DanhGiaID)
        objMap.DiemDanhGia = arrDiemDanhGia
        dataFilter.push(objMap)
    })
    vueData.DSDanhGia_Filter = dataFilter
}