function removeFileHopDong() {
    const index = vueData.DS_TapTinDinhKem.findIndex(item => item.FILE_ID === vueData.FileID_Remove)
    vueData.DS_TapTinDinhKem.splice(index,1)
}
function initFile() {
    vueData.fileEX = {
        max_file_size: '15mb',
        mime_types: [{ title: "All files", extensions: "*" }]
    }
}