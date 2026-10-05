const deleteGioChuan = (item) => {
    confirm({
        title: `Bạn có chắc chắn muốn xoá thông tin định mức giờ chuẩn <br/><b>${item.TenChucDanh}</b>?`,
        action: function () {
            ajaxCALL("/HDKH_DM_ChucDanhHocVi_Delete", {
                ID: item.ID
            }, res => {
                if (res) {
                    Vue.$toast.success('Xóa thành công!', { position: "top" })
                    CALL("getDSGioChuan")
                }
            }, error => {
            })
        }
    });
}
vueData.deleteGioChuan = deleteGioChuan