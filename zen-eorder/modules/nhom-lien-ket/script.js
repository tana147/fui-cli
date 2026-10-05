function updateStatus(data) {
    const formData = data.data
    if (formData.NhomLienKetChiTietID) {
        const params = {NhomLienKetChiTietID: formData.NhomLienKetChiTietID, TinhTrang: formData.TinhTrang}
        ajaxCALL("/eorder/NhomLienKetChiTiet_Update_TinhTrang", params, (res) => {
            if (res.data) {
                formData.TinhTrang = formData.TinhTrang === 0 ? 1 : 0 //Set ngược lại table
            }
        })
    }
}