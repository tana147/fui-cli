const deleteField = (item) => {
    confirm({
        title: `Bạn có chắc chắn muốn xoá Field <br><b>${item.FieldLabel}?</br>`,
        action: function () {
            ajaxCALL("/HDKH_Field_Delete", {
                FieldID: item.FieldID
            }, res => {
                if (res) {
                    Vue.$toast.success('Xóa thành công!', { position: "top" })
                    CALL("getDSFields")
                }
            }, error => {
            })
        }
    });
}
const moveToRuleDefinition = () => {
    window.location.href = `/hdkh-quy-tac-tinh-gio?FormID=${vueData.formID}`
}
vueData.deleteField = deleteField
vueData.moveToRuleDefinition = moveToRuleDefinition