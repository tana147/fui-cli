async function initPage() {
    const ajaxCALLPromise = (url, params) => {
        return new Promise(resolve => {
            ajaxCALL(url, params, res => {
                resolve(res.data)
            })
        })
    }
    const arr = []
    for (var capid of [1, 2, 3]) {
        console.log(capid)
        const data = await ajaxCALLPromise('lms/KhoiHocByCapHoc_Get', { CapID: capid })
        arr.push(data)
    }
    vueData.DSKhoi = arr.flat()
}
function onChamBai(sub) {
    openWindow({
        title: "Chấm bài",
        // Danh sách này chỉ lấy submission giao theo lớp; truyền rõ scope để
        // trang chấm không rơi vào mặc định CLASS khi mở từ entry point khác.
        url: `/lms_tc_grade_asm?SubmissionID=${sub.SubmissionID}&AssignType=CLASS`
    })
}
vueData.onChamBai = onChamBai
vueData.initPage = initPage