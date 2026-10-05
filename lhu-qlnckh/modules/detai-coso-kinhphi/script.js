function initFile() {
    vueData.fileEX = {
        max_file_size: '15mb',
        mime_types: [{ title: "All files", extensions: "*" }]
    }
}
function showIsSelected() {
    const promise = vueData.isSelected.map(item => {
        vueData.TienDo_Obj.QDID = vueData.ResponseQuyetDinhIns[0].QDID
        vueData.TienDo_Obj.SoQD = vueData.ResponseQuyetDinhIns[0].MaSoQD
        vueData.TienDo_Obj.FileID = vueData.FileID_QD.FileID
        vueData.TienDo_Obj.GhiChu = vueData.ResponseQuyetDinhIns[0].MoTaQD
        vueData.TienDo_Obj.FileName = vueData.FileID_QD.FileName
        vueData.TienDo_Obj.SoTien = item.KinhPhi
        vueData.TienDo_Obj.SoTT = vueData.ResponseQuyetDinhIns[0].Dot
        vueData.TienDo_Obj.NgayTienDo = vueData.ResponseQuyetDinhIns[0].NgayQD + "/" + vueData.ResponseQuyetDinhIns[0].ThangQD + "/" + vueData.ResponseQuyetDinhIns[0].NamQD
        apiTienDoInsObj(item).then(() => {
            vueData.TienDo_Obj = Object.assign({}, vueData.TienDo_Obj_Default)
            item.KinhPhi = null
        })
    })
    Promise.all(promise).then(() => {
        vueData.ResponseQuyetDinhIns = null
        CALL("getQuyetDinh")
    })
}
function apiTienDoInsObj(item) {
    return new Promise((resolve, reject) => {
        ajaxCALL("/KHCN_TienDo_Ins_Obj", {
            DeTaiKHCNID: item.DeTaiKHCNID,
            TienDoKHCNObj: vueData.TienDo_Obj
        }, res => {
            resolve(res)
        }, err => {
        })
    })
}
function apiTienDoUpdObj(item) {
    ajaxCALL("/KHCN_TienDo_Upd_Obj", {
        TienDoKHCNObj: item
    }, res => {}, err => {})
}
function updateTienDoObj() {
    vueData.DS_TienDo_Get_ByQDID.forEach(item => {
        item.SoQD = vueData.ResponseQuyetDinhUpd[0].MaSoQD
        item.SoTT = vueData.ResponseQuyetDinhUpd[0].Dot
        item.NgayTienDo = vueData.ResponseQuyetDinhUpd[0].NgayQD + "/" + vueData.ResponseQuyetDinhUpd[0].ThangQD + "/" + vueData.ResponseQuyetDinhUpd[0].NamQD
        item.GhiChu = vueData.ResponseQuyetDinhUpd[0].MoTaQD
        item.FileID = vueData.FileID_QD.FileID
        item.FileName = vueData.FileID_QD.FileName
        item.FileURL = vueData.FileID_QD.FileUrl
        apiTienDoUpdObj(item)
    })
    CALL("getQuyetDinh")
}
function del_fileItem() {
    vueData.FileID_QD.FileID = null
    vueData.FileID_QD.FileName = null
    vueData.FileID_QD.FileUrl = null
}