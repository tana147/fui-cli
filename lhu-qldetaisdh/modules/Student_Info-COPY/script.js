let number = 0
function onSave(ds) {
    if (Array.isArray(ds)) {
        ds.forEach((item) => (item.isSelect = true))
    } else {
        ds.isSelect = true
    }
    ajaxCALL(
        '/Student_INS_obj',
        {
            StudentObjArr: JSON.stringify(ds),
            Process_Action: 1,
        },
        (res) => {
            vueData.reloadStuNienKhoa = number
            number += 1
            Vue.$toast.success(`Thêm học viên thành công`, { position: 'top' })
            console.log('Save success', ds)
            ds.isCanDelete = true
        },
        (error) => {
            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
            console.log('Save fail', error)
        },
    )
}
// Xu Ly Hoc Vu
let dem = 0
function onXuLyHocVu(item) {
    confirm({
        title: `Bạn có muốn xử lý học vụ học viên ${item.HoSV} ${item.TenSV} không ?`,
        action: async () => {
            ajaxCALL(
                '/Student_XuLyHocVu',
                {
                    Student_ID: item.StudentID,
                },
                (res) => {
                    item.IsXuLyHocVu = true
                    vueData.reloadXuLyHocVu = dem
                    dem += 1
                    Vue.$toast.success(`Đã xử lý học vụ ${item.HoSV} ${item.TenSV}`, { position: 'top' })
                    console.log('Save success')
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('Save fail', error)
                },
            )
        },
        cancel: function () { }.bind(this),
    })
}
function delectStudent(item) {
    confirm({
        title: 'Xóa học viên',
        content: `Bạn có muốn xóa học viên này không?`,
        action: () => {
            ajaxCALL(
                '/Student_Remove',
                {
                    StudentID: item.StudentID,
                },
                (res) => {
                    Vue.$toast.success(`Xóa học viên ${item.HoTen} thành công`, { position: 'top' })
                    item.isExist = false
                    item.isSelect = false
                },
                (error) => {
                    Vue.$toast.error(`Xóa học viên ${item.HoTen} thất bại`, { position: 'top' })
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('Fail to delete student', error)
                },
            )
        },
        cancel: function () { }.bind(this),
    })
}
function selectHocVien(item) {
    vueData.hocVienObj = item
    vueData.isUpdTask = true
}
function getStudentDetail(item) {
    vueData.StudentDetail = item
    vueData.isOpenReset = true
}
function openOldView(item) {
    vueData.StudentDetail = item
    vueData.isOpenViewOld = true
}
async function onLoadRootFlowHis(studentID) {
    return new Promise((resolve, reject) => {
        ajaxCALL(
            '/Get_RootFlow_His',
            {
                StudentID: studentID
            },
            (res) => {
                resolve(res.data)
            },
            (error) => {
                Vue.$toast.error(error?.responseJSON?.Message || 'Có lỗi xảy ra', {
                    position: 'top'
                })
                reject([])
            }
        )
    })
}
async function onLoadFlowDetailHis(flowID) {
    return new Promise((resolve, reject) => {
        ajaxCALL(
            '/SDH_Get_FlowDetail_His',
            {
                Flow_ID: flowID
            },
            (res) => {
                resolve(res.data)
            },
            (error) => {
                Vue.$toast.error(error?.responseJSON?.Message || 'Có lỗi xảy ra', {
                    position: 'top'
                })
                reject([])
            }
        )
    })
}
function checkTopicBtn(TenDeTai) {
    ajaxCALL(
        '/Get_SimiliarPaper',
        {
            TenDeTai: TenDeTai,
        },
        (res) => {
            vueData.similiarTopic = res.data
            vueData.similiarList = res.data
        },
        (error) => {
            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
            console.log('Error: ', error)
        },
    )
}