// function getTenNganh(nganhID) {
//     const tenNganh = vueData.NganhGiangDay.find(nganh => nganh.NganhID == nganhID)
//     if (tenNganh) {
//         return tenNganh.TenNganh
//     } else return ""
// }
// function GetTenNganh(nganhID) {
//     if (vueData.GlobalHeArr) {
//         const data = vueData.GlobalHeArr.find(item => item.Nganh_ID == nganhID)
//         return data.Ten_Nganh
//     }
// }
function getNganhName(nganhID) {
    const name = vueData.NganhGiangDay.find(item => item.NganhID == nganhID)
    if (name) {
        return name.TenNganh
    } else {
        return ""
    }
}
function deleteGiangVien(giangVienID) {
    console.log("giangVienID", giangVienID)
    confirm({
        title: "Xác nhận xóa",
        content: (`Bạn muốn xóa giảng viên này`),
        action: () => {
            ajaxCALL("/giangvien_del", {
                GiangVienID: giangVienID
            }, (res) => {
                Vue.$toast.success(`Xóa thành công`, { position: 'top' })
                CALL("getDsGiangVien")
            }, (error) => {
                Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
                console.log("fail to delete", error)
            })
        },
    });
}
function getGiangVienRecord(giangVien) {
    vueData.RecordGiangVien = giangVien
    vueData.GiangVienName = giangVien.HoTenGiangVien
    console.log("vueData.RecordGiangVien", vueData.RecordGiangVien)
    vueData.isUpdDialog = true
}