const moveToConfigField = (item) => {
    window.location.href = `/hdkh-truong-du-lieu?formID=${item.FormID}`
}
vueData.moveToConfigField = moveToConfigField
const deleteForm = (item) => {
    confirm({
        title: `Bạn có chắc chắn muốn xoá Form <br/><b>${item.FormTitle}</b>?`,
        action: function () {
            console.log(item.FormID)
            Vue.$toast.success('Chưa có API', { position: "top" })
            // ajaxCALL("/HDKH_Form_Delete", {
            //     FieldID: item.FieldID
            // }, res => {
            //     if (res) {
            //         Vue.$toast.success('Xóa thành công!', { position: "top" })
            //         CALL("getDSFields")
            //     }
            // }, error => {
            // })
        }
    });
}
vueData.deleteForm = deleteForm