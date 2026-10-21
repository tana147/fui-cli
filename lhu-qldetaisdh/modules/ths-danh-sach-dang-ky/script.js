function updProf(item) {
    console.log("item", item)
    ajaxCALL("/Theise_Upd_Prof", {
        Student_ID: item.Student_ID,
        ThesisesProf1: item.ThesisesProf1,
        ThesisesProf2: item.ThesisesProf2
    }, (res) => {
        Vue.$toast.success(`Cập nhật giảng viên của học viên ${item.Student_Name} thành công`, { position: 'top' });
        vueData.isDialog = false
    }, (error) => {
        Vue.$toast.error(`Cập nhật giảng viên của học viên ${item.HoTen} thất bại`, { position: 'top' });
        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
        console.log("Fail to update prof", error)
    })
}
function onOpenDialog(item) {
    vueData.taskRegistData = item
    console.log("vueData.taskRegistData", vueData.taskRegistData)
    vueData.isDialog = true
}