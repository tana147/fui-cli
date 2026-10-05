function mergeTabNhomSanPhamToSanPham(DSNhomSanPham, DSSanPham) {
    let arr = []
    if (DSNhomSanPham && DSSanPham) {
        DSSanPham?.forEach((itemSanPham) => {
            DSNhomSanPham?.forEach((itemNSP, index) => {
                if (itemNSP.NhomSanPhamID === itemSanPham.NhomSanPhamID) {
                    arr.push({...itemSanPham, TabIndex: index})
                }
            })
        })
    }
    return arr
}