function printQD_LV_Ths(HoiDongID, nganhID, lopID) {
    const obj = {
        NganhID: nganhID,
        LopID: lopID,
    }
    localStorage.removeItem('JSON_PRINT_PDF_QD_LAP_HD')
    localStorage.setItem('JSON_PRINT_PDF_QD_LAP_HD', JSON.stringify(obj))
    const url = `/ths-in-quyet-dinh-hoi-dong?HoiDong_ID=${HoiDongID}`
    window.open(url, '_blank')
}
function sqdCheckStatus(item) {
    switch (true) {
        case item !== null:
            return false
        default:
            return true
    }
}
function checkInputScoreStatus(item) {
    switch (true) {
        case item.HoiDongID !== null && item.Decision_SoQD !== null:
            return false
        default:
            return true
    }
}
function filterUniqueChucTrach(data) {
    var chucTrachMap = {}
    // Sử dụng reduce để lọc và giữ lại phần tử cuối cùng cho mỗi ChucTrach
    var filteredData = data.reduce(function (result, item) {
        var chucTrachValue = item.ChucTrachID
        // Nếu chưa tồn tại trong đối tượng chucTrachMap, thêm vào và giữ lại phần tử
        if (!chucTrachMap[chucTrachValue]) {
            chucTrachMap[chucTrachValue] = true
            result.push(item)
        } else {
            // Nếu đã tồn tại, thay thế phần tử cuối cùng bằng phần tử mới
            result[result.findIndex((e) => e.ChucTrachID === chucTrachValue)] = item
        }
        return result
    }, [])
    return filteredData
}
// Hàm để loại bỏ các đối tượng trùng nhau
function removeDuplicateObjects(originalArray) {
    var uniqueArray = []
    var stringifiedObjects = []
    for (var i = 0; i < originalArray.length; i++) {
        var stringifiedObject = JSON.stringify(originalArray[i])
        if (!stringifiedObjects.includes(stringifiedObject)) {
            uniqueArray.push(originalArray[i])
            stringifiedObjects.push(stringifiedObject)
        }
    }
    return uniqueArray
}
function isDuplicateObject(array, object) {
    var stringifiedObject = JSON.stringify(object)
    for (var i = 0; i < array.length; i++) {
        if (JSON.stringify(array[i]) === stringifiedObject) {
            return true
        }
    }
    return false
}
function loadChucTrach(nganhID, lopID) {
    ajaxCALL(
        '/HoiDong_ChucTrach_Get',
        {
            NganhID: nganhID,
            LopID: lopID,
        },
        (res) => {
            console.log('res', res.data)
            vueData.DSHoiDongChucTrach = res.data
        },
        (error) => {
            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
            console.log('Fail get chuc trach')
        },
    )
}
Vue.component('table-council', {
    props: ['dshdgiangvien', 'dshdchuctrach', 'dshddetai', 'dshedaotao', 'hearr'],
    data() {
        return {
            type: null,
            major: '',
            heArr: [],
            getDiem: [],
            DsGiangVien: [],
            dateSelect: '-Tất cả-',
            nganhSelect: '',
            DsHeDaoTao: [],
            DsNienKhoa: [],
            HoiDongHVId: '',
            NienKhoaValue: null,
            isHistoryDialogOpen: false,
            isLoadingHistory: false,
            historyList: [],
            historyMembers: [],
            selectedHistoryStudent: null,
            hoiDongStateSelect: 1,
            hoiDongStateList: [
                {
                    text: '- Tất cả -',
                    value: '1',
                },
                {
                    text: 'Chưa lập hội đồng',
                    value: '2',
                },
                {
                    text: 'Đã bảo vệ thành công',
                    value: '3',
                },
                {
                    text: 'Chưa bảo vệ',
                    value: '4',
                },
            ],
            headerCTable: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Học viên',
                    value: 'HoTenMaSV',
                    width: 180,
                },
                {
                    text: 'Ngành',
                    value: 'Ten_Nganh',
                    width: 150,
                },
                {
                    text: 'Niên khóa',
                    value: 'Nien_Khoa',
                    sortable: false,
                    align: 'center',
                    width: 90,
                },
                {
                    text: 'Tên đề tài',
                    value: 'Thesis_Name',
                    width: 300,
                },
                {
                    text: 'Hướng dẫn Khoa học 1',
                    value: 'Thesises_Prof1',
                    class: 'customCol',
                    sortable: false,
                    width: 170,
                },
                {
                    text: 'Hướng dẫn Khoa học 2',
                    value: 'Thesises_Prof2',
                    class: 'customCol',
                    sortable: false,
                    width: 170,
                },
                {
                    text: 'Ngày bảo vệ',
                    value: 'ThoiGianBaoVe',
                    width: 100,
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Hội đồng',
                    value: 'ThaoTacHoiDongBTN',
                    align: 'center',
                    // sortable: false,
                    attr: {
                        margin: '400px',
                    },
                },
                {
                    text: 'Số quyết định',
                    value: 'ThaoTacSQDBTN',
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Nhập điểm',
                    value: 'InputScore',
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'In tệp HDDGLV',
                    value: 'Hddglv',
                    align: 'center',
                    sortable: false,
                    width: 80,
                },
                {
                    text: 'In QĐ',
                    value: 'ThaoTacInQDBTN',
                    class: 'printerCol',
                    align: 'center',
                    width: 80,
                },
                {
                    text: 'Lập lại HĐ',
                    value: 'FailToDefend',
                    class: 'printerCol',
                    align: 'center',
                    width: 120,
                },
            ],
            editedItem: {},
            dataUpdateHD: {
                HoiDong: null,
                GiangVienSelected: null,
                GiangVienMergeSelected: [],
            },
            DSHDGiangVienEstablishCouncil: [],
            DSGiangVienDuKien: [],
            DSGiangVienDuKienDefault: [],
            DSDeTaiCoHoiDong: [],
            dsDeTai: [],
            dsDeTaiOrigin: [],
        }
    },
    mounted() {
        // this.onLoadNganhGiangDay()
        this.getNganhDaoTao()
        this.getNienKhoa()
    },
    computed: {
        DSHoiDongGiangVien: function () {
            return this.dshdgiangvien
        },
        DSHoiDongChucTrach: function () {
            return this.dshdchuctrach
        },
        DSGiangVienDuKienTemp: function () {
            let tempHDGV = this.DSHoiDongGiangVien
            let arrPush = []
            this.DSHDGiangVienEstablishCouncil = tempHDGV.map((item) => {
                return {
                    ...item,
                    Is_Chon: false,
                    Is_Selected: false,
                    HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                }
            })
            this.DSHDGiangVienEstablishCouncil.forEach((giangVien) => {
                const existIndex = this.dsDeTai.findIndex((deTai) => deTai.GiangVienID1 === giangVien.GiangVienID)
                if (existIndex !== -1) {
                    this.DSGiangVienDuKien.push({ ...giangVien, Is_Chon: true })
                }
            })
            this.DSGiangVienDuKienDefault = this.DSGiangVienDuKien
            return arrPush
        },
        dateTime() {
            const dates = this.dsDeTaiOrigin
                .map((item) => item.ThoiGianBaoVe)
                .filter((date) => date !== null)
                .map((date) => ({ ThoiGianBaoVe: date }))
            dates.unshift({ ThoiGianBaoVe: '-Tất cả-' }) // Thêm phần tử vào mảng
            return dates // Trả về mảng
        },
        existNganh() {
            const nganh = this.dsDeTai.map((item) => item.Ten_Nganh)
            return nganh.map((item) => ({ TenNganh: item }))
        },
        ThuMoiDialog: function () {
            return vueData.isThuMoiDialog
        },
    },
    watch: {
        dshddetai: function (val) {
            const $this = this
            if (val.length > 0) {
                const sortedDeTai = val
                    .map((item) => {
                        return {
                            ...item,
                            ThoiGianBaoVe: item.ThoiGianBaoVe && item.ThoiGianBaoVe !== 'Invalid date' ? moment(item.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null,
                        }
                    })
                    .sort((a, b) => a.Ten_SV.localeCompare(b.Ten_SV))
                // Đặt lại STT sau khi sắp xếp
                $this.dsDeTaiOrigin = this.resetSTT(sortedDeTai)
                if ($this.dateSelect) {
                    const filter = $this.dsDeTaiOrigin.filter((item) => {
                        return item.ThoiGianBaoVe === $this.dateSelect
                    })
                    if ($this.dateSelect === '-Tất cả-') {
                        $this.dsDeTai = $this.resetSTT($this.dsDeTaiOrigin)
                    } else {
                        $this.dsDeTai = $this.resetSTT(filter)
                    }
                }
            } else {
                this.dsDeTaiOrigin = []
                this.dsDeTai = []
            }
            console.log(this.dshddetai)
        },
        type: function (val) {
            // this.getHeByID(val)
        },
        major: function (val) {
            vueData.nganhID = parseInt(val)
            this.NienKhoaValue = '0'
            this.dateSelect === '-Tất cả-'
        },
        ThuMoiDialog: function (val) {
            if (val) {
                ajaxCALL(
                    '/giangvien_get',
                    null,
                    (res) => {
                        this.DsGiangVien = res.data.map((item, index) => {
                            return {
                                ...item,
                                STT: index + 1,
                            }
                        })
                        console.log('this.DsGiangVien', this.DsGiangVien)
                    },
                    (error) => {
                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        console.log('Faill to load giang vien', error)
                    },
                )
            }
        },
    },
    methods: {
        getNienKhoa() {
            const $this = this
            $.ajax({
                type: 'GET',
                headers: {
                    authorization: $awt,
                },
                url: `https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa`,
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                crossDomain: true,
                success: function (res) {
                    const obj = {
                        TenNienKhoa: '- Tất cả -',
                        NienKhoa: '0',
                    }
                    $this.DsNienKhoa = res.data.map((item) => {
                        return {
                            ...item,
                            TenNienKhoa: item.NienKhoa,
                            NienKhoa: item.NienKhoa,
                        }
                    })
                    $this.DsNienKhoa.unshift(obj)
                    $this.NienKhoaValue = $this.DsNienKhoa[0]?.NienKhoa
                },
                error: function (xhr, ajaxOptions, thrownError) {
                    $.dialog({
                        icon: 'fas fa-exclamation',
                        title: 'Error',
                        content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
                        type: 'red',
                        columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
                        closeIcon: true,
                        buttons: {
                            ok: {
                                text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
                                btnClass: 'btn-blue',
                            },
                        },
                    })
                },
            })
        },
        resetSTT(deTaiList) {
            return deTaiList.map((item, index) => {
                return {
                    ...item,
                    STT: index + 1,
                }
            })
        },
        addCouncil(item) {
            // this.editedItem = item
            this.editedItem = { ...item, ThoiGian: item.ThoiGianBaoVe, ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null }
            vueData.isAddDialog = true
        },
        onUpdateHoiDong(item) {
            // this.editedItem = item
            this.editedItem = { ...item, ThoiGian: item.ThoiGianBaoVe, ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null }
            console.log('item xxxxxx', item)
            this.dataUpdateHD = {
                HoiDong: null,
                GiangVienSelected: null,
                GiangVienMergeSelected: [],
            }
            ajaxCALL(
                '/HoiDong_Get_ByHoiDongID',
                {
                    HoiDong_ID: item.HoiDongID,
                },
                (res) => {
                    let hoidong = res.data[0][0]
                    let gvSelected = res.data[1]
                    this.dataUpdateHD.HoiDong = hoidong
                    this.dataUpdateHD.GiangVienSelected = gvSelected
                    let tempArr = JSON.parse(JSON.stringify(this.DSHoiDongGiangVien.filter((itemGV) => itemGV.NganhID === item.Nganh_ID)))
                    let resultArr = tempArr.map((item, index) => {
                        let matchingElement = gvSelected.find((element) => element.GiangVienID === item.GiangVienID)
                        if (matchingElement) {
                            matchingElement.Is_Chon = matchingElement.Is_Chon === 0 ? false : true
                            matchingElement.STT = index + 1
                            return Object.assign({}, item, matchingElement)
                        } else {
                            // item.Is_Chon = false
                            item.STT = index + 1
                            return item
                        }
                    })
                    this.dataUpdateHD.GiangVienMergeSelected = resultArr
                    vueData.isUpdateDialog = true
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    Vue.$toast.error(error, { position: 'top' })
                },
            )
        },
        onLoadNganhGiangDay() {
            const $this = this
            $.ajax({
                type: 'GET',
                headers: {
                    authorization: $awt,
                },
                url: `https://tapi.lhu.edu.vn/hoso/SDH_SelectNganh_CaoHoc`,
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                crossDomain: true,
                success: function (res) {
                    vueData.NganhGiangDay = res.data.map((item) => {
                        if (item.TenNganh === 'Tài chính - Ngân hàng' || item.NganhID == 40) {
                            item.TenNganh = 'Tài chính ngân hàng'
                        }
                        return {
                            ...item,
                            NganhID: parseInt(item.NganhID),
                        }
                    })
                    console.log('NganhGiangDay', vueData.NganhGiangDay)
                },
                error: function (xhr, ajaxOptions, thrownError) {
                    $.dialog({
                        icon: 'fas fa-exclamation',
                        title: 'Error',
                        content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
                        type: 'red',
                        columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
                        closeIcon: true,
                        buttons: {
                            ok: {
                                text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
                                btnClass: 'btn-blue',
                            },
                        },
                    })
                },
            })
        },
        onViewHoiDong(item) {
            console.log('YYYYYYY', item)
            this.editedItem = {
                ...item,
                ThoiGian: item.ThoiGianBaoVe,
                ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null,
            }
            this.dataUpdateHD = {
                HoiDong: null,
                GiangVienSelected: null,
                GiangVienMergeSelected: [],
            }
            ajaxCALL(
                '/HoiDong_Get_ByHoiDongID',
                {
                    HoiDong_ID: item.HoiDongID,
                },
                (res) => {
                    let hoidong = res.data[0][0]
                    let gvSelected = res.data[1].map((item) => {
                        return {
                            ...item,
                            HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                        }
                    })
                    let dshdgv = this.DSHoiDongGiangVien
                    this.dataUpdateHD.HoiDong = hoidong
                    this.dataUpdateHD.GiangVienSelected = gvSelected
                    let resultArr = gvSelected.map((item) => ({ ...item, Is_Chon: true }))
                    this.dataUpdateHD.GiangVienMergeSelected = resultArr
                    vueData.isViewDialog = true
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    Vue.$toast.error(error, { position: 'top' })
                },
            )
        },
        onInputScore(item) {
            this.editedItem = {
                ...item,
                ThoiGian: item.ThoiGianBaoVe,
                ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null,
            }
            this.dataUpdateHD = {
                HoiDong: null,
                GiangVienSelected: null,
                GiangVienMergeSelected: [],
            }
            Promise.all([this.getByHoiDongID(this.editedItem.HoiDongID), this.getGiangVienGetDiem(this.editedItem.HoiDongID)]).then(([resGetByHoiDongID, resGiangVienGetDiem]) => {
                //resGetByHoiDongID ----------------------------
                let hoidong = resGetByHoiDongID.data[0][0]
                let gvSelected = resGetByHoiDongID.data[1].map((item) => {
                    return {
                        ...item,
                        HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                    }
                })
                this.dataUpdateHD.HoiDong = hoidong
                this.dataUpdateHD.GiangVienSelected = gvSelected
                let resultArr = gvSelected.map((item) => ({ ...item, Is_Chon: true }))
                this.dataUpdateHD.GiangVienMergeSelected = resultArr
                //resGiangVienGetDiem ----------------------------
                this.getDiem = resGiangVienGetDiem.data
                vueData.isInputDialog = true
            })
        },
        getByHoiDongID(hoidongid) {
            return new Promise((resolve, reject) => {
                if (hoidongid) {
                    ajaxCALL(
                        '/HoiDong_Get_ByHoiDongID',
                        {
                            HoiDong_ID: hoidongid, //item.HoiDongID
                        },
                        (res) => {
                            resolve(res)
                        },
                        (error) => {
                            reject(error)
                            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        },
                    )
                }
            })
        },
        getGiangVienGetDiem(hoidongid) {
            return new Promise((resolve, reject) => {
                if (hoidongid) {
                    ajaxCALL(
                        '/HoiDong_GiangVien_Get_Diem',
                        {
                            HoiDongID: hoidongid, //this.editedItem.HoiDongID
                        },
                        (res) => {
                            resolve(res)
                        },
                        (error) => {
                            reject(error)
                            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        },
                    )
                }
            })
        },
        giveSQD(item) {
            this.editedItem = {
                ...item,
                ThoiGian: item.ThoiGianBaoVe,
                ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null,
            }
            this.dataUpdateHD = {
                HoiDong: null,
                GiangVienSelected: null,
                GiangVienMergeSelected: [],
            }
            ajaxCALL(
                '/HoiDong_Get_ByHoiDongID',
                {
                    HoiDong_ID: item.HoiDongID,
                },
                (res) => {
                    let hoidong = res.data[0][0]
                    let gvSelected = res.data[1].map((item) => {
                        return {
                            ...item,
                            HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                        }
                    })
                    this.dataUpdateHD.HoiDong = hoidong
                    this.dataUpdateHD.GiangVienSelected = gvSelected
                    vueData.isSQDDialog = true
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('Fail to get data update hoi dong', error)
                },
            )
        },
        getNganhDaoTao() {
            const $this = this
            $.ajax({
                type: 'GET',
                headers: {
                    authorization: $awt,
                },
                url: `https://tapi.lhu.edu.vn/hoso/SDH_SelectNganh_CaoHoc`,
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                crossDomain: true,
                success: function (res) {
                    const allListObj = {
                        NganhID: 0,
                        TenNganh: '- Tất cả -',
                        TenNganhHienThi: '- Tất cả -',
                    }
                    $this.heArr = res.data.map((item, index, array) => {
                        if (item.TenNganh === 'Tài chính - Ngân hàng' || item.NganhID == 40) {
                            item.TenNganh = 'Tài chính ngân hàng'
                        }
                        // Kiểm tra trùng lặp tên ngành (không phân biệt hoa/thường)
                        const isDuplicate = array.some((el, i) => i !== index && el.TenNganh.toLowerCase() === item.TenNganh.toLowerCase())
                        // Nếu trùng thì gắn thêm KhoaID
                        const rawName = isDuplicate ? `${item.TenNganh} (${item.KhoaID})` : item.TenNganh
                        // Gộp xử lý removeHocHam vào chung 1 vòng map
                        return {
                            ...item,
                            TenNganh: removeHocHam(rawName),
                        }
                    })
                    $this.heArr.unshift(allListObj)
                },
                error: function (xhr, ajaxOptions, thrownError) {
                    $.dialog({
                        icon: 'fas fa-exclamation',
                        title: 'Error',
                        content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
                        type: 'red',
                        columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
                        closeIcon: true,
                        buttons: {
                            ok: {
                                text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
                                btnClass: 'btn-blue',
                            },
                        },
                    })
                },
            })
        },
        removeDiacriticsAndSpaces(str) {
            // Xóa dấu
            const removedDiacritics = str.normalize('NFD').replace(/[\u0300-\u036f]/g, '')
            // Xóa khoảng trắng
            const removedSpaces = removedDiacritics.replace(/\s/g, '')
            return removedSpaces
        },
        fn_EstablishCouncil() {
            this.DSGiangVienDuKien = this.DSGiangVienDuKienTemp
            this.DSGiangVienDuKienDefault = this.DSGiangVienDuKienTemp
            let dataReturn = []
            if (this.DSHoiDongChucTrach.length > 0) {
                dataReturn = this.DSHoiDongChucTrach.map((chucTrach) => ({
                    ChucTrach: chucTrach.ChucTrach,
                    value: this.removeDiacriticsAndSpaces(chucTrach.ChucTrach),
                    GiangVienID: null,
                }))
            }
            console.log('dsDeTai', this.dsDeTai)
            const cloneDSChucTrach = JSON.parse(JSON.stringify(dataReturn))
            const mergeJson = this.dsDeTai
                .filter((item) => item.HoiDongID === null)
                .map((item, index) => {
                    const addIndex = cloneDSChucTrach.map((itemCTT) => {
                        return { ...itemCTT, Index_CTT: item.STT }
                    })
                    return { ...item, STT: index + 1, Validate_Exist: false, DeTai_DSChucTrach: addIndex }
                })
            console.log('mergeJson', mergeJson)
            console.log('')
            this.DSDeTaiCoHoiDong = mergeJson
            vueData.isTempDialog = true
        },
        printPDF() {
            if (this.dateSelect && this.nganhSelect) {
                const filterArr = this.dsDeTai.filter((item) => item.ThoiGianBaoVe === this.dateSelect)
                console.log('filterArr', filterArr)
                // Xóa mục khỏi localStorage trước khi lưu trữ mới
                localStorage.removeItem('JSON_PRINT_PDF_DSBVLV')
                localStorage.setItem('JSON_PRINT_PDF_DSBVLV', JSON.stringify(filterArr))
                // const url = `https://qldetaisdh.lhu.edu.vn/rpt_task_defend?HoiDongID=${filterArrJSON}&TimeSelect=${this.dateSelect}`;
                const url = `https://qldetaisdh.lhu.edu.vn/ths-in-danh-sach-bao-ve?TimeSelect=${this.dateSelect}&NganhSelect=${this.nganhSelect}`
                const newTab = window.open(url, '_blank')
                newTab.focus()
            } else {
                Vue.$toast.error(`Chưa chọn ngày bảo vệ hoặc ngành trong danh sách`, { position: 'top' })
            }
        },
        getNganhName(nganhID) {
            const filter = this.heArr.find((item) => item.NganhID == nganhID)
            return filter.TenNganh
        },
        printExcel() {
            if (this.major) {
                let filterArr = this.dsDeTai
                if (this.dateSelect !== '-Tất cả-') {
                    filterArr = this.dsDeTai.filter((item) => item.ThoiGianBaoVe === this.dateSelect)
                }
                console.log('filterArr', filterArr)
                let dataArr = []
                const firstItemProcessID = filterArr[0].Process_ID
                filterArr.forEach((item, index) => {
                    let NienkhoaSplit = item.Nien_Khoa.split('-')
                    let tempKhoa = parseInt(NienkhoaSplit[0])
                    let khoaFormat
                    // Kiểm tra xem phần tử cuối cùng có phải là số hay không
                    if (NienkhoaSplit.length > 1) {
                        const lastPart = NienkhoaSplit[NienkhoaSplit.length - 1]
                        khoaFormat = `${NienkhoaSplit[0]}.${isNaN(lastPart) ? lastPart : parseInt(lastPart)}`
                    } else {
                        khoaFormat = item.item.Nien_Khoa.replace('-', '.')
                    }
                    dataArr.push({
                        STT: index + 1,
                        MSHV: item.Student_ID,
                        Ho: item.Ho_SV,
                        Ten: item.Ten_SV,
                        DeTai: item.Thesis_Name,
                        DienThoai: item.PhoneNumber ?? '',
                        // khoaFormat
                        // tempKhoa
                        Khoa: khoaFormat,
                        Email: item.Email ?? '',
                    })
                })
                console.log('dataArr', dataArr)
                const apiData = {
                    Nganh: this.getNganhName(this.major),
                    NgayBaoVe: this.dateSelect !== '-Tất cả-' ? this.formatCustomDate(this.dateSelect) : '',
                    SoLuong: filterArr.length,
                    ProcessID: firstItemProcessID,
                    DanhSach: dataArr,
                }
                const myHeaders = new Headers()
                myHeaders.append('Content-Type', 'application/json')
                const requestOptions = {
                    method: 'POST',
                    headers: myHeaders,
                    body: JSON.stringify(apiData),
                    redirect: 'follow',
                }
                // http://localhost:5244
                // https://gendocx.iotsoftvn.com
                fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/danh-sach-bvkl', requestOptions)
                    .then((response) => response.blob())
                    .then((blob) => {
                        var url = window.URL.createObjectURL(blob)
                        var a = document.createElement('a')
                        a.href = url
                        a.download = `${this.dateSelect !== '-Tất cả-' ? this.dateSelect + ' ' : ''}BVKL ngành ${this.getNganhName(this.major)}.xlsx`
                        document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
                        a.click()
                        a.remove() //afterwards we remove the element again
                    })
                    .catch((error) => console.error(error))
            } else {
                Vue.$toast.error(`Chưa chọn ngày bảo vệ hoặc ngành trong danh sách`, { position: 'top' })
            }
        },
        printAllHDDGLV() {
            if (this.dsDeTai.length > 0) {
                const filterArr = this.dsDeTai
                    .filter((item) => item.HoiDongID) // Lọc các item có HoiDongID truthy
                    .sort((a, b) => {
                        if (!a.Ten_SV) return 1 // Đẩy `null` hoặc `undefined` xuống cuối
                        if (!b.Ten_SV) return -1
                        return a.Ten_SV.localeCompare(b.Ten_SV)
                    })
                let zip = new JSZip() // Tạo một đối tượng JSZip
                let STT = 1 // Biến STT khởi tạo
                let count = 0
                filterArr.forEach((item, index) => {
                    ajaxCALL(
                        '/HoiDong_Get_ByHoiDongID',
                        {
                            HoiDong_ID: item.HoiDongID,
                        },
                        (res) => {
                            const deTaiInfo = res.data[0][0]
                            let hoiDong = res.data[1]
                            let dataArr = []
                            hoiDong.forEach((item, index) => {
                                if (item.HoTenGiangVien) {
                                    const obj = {
                                        STT: (index + 1).toString(),
                                        HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                                        CoQuanCongTac: item.CoQuanCongTac,
                                        TrachNhiem: item.ChucTrach,
                                    }
                                    dataArr.push(obj)
                                }
                            })
                            const apiData = {
                                Nganh: deTaiInfo.TenNganh.toUpperCase(),
                                HocVien: deTaiInfo.HoSV + ' ' + deTaiInfo.TenSV,
                                STT: index + 1,
                                MaNganh: deTaiInfo.MaNganh,
                                DanhSach: dataArr,
                            }
                            console.log('deTaiInfo', deTaiInfo)
                            // console.log("apiData", apiData)
                            const myHeaders = new Headers()
                            myHeaders.append('Content-Type', 'application/json')
                            const requestOptions = {
                                method: 'POST',
                                headers: myHeaders,
                                body: JSON.stringify(apiData),
                                redirect: 'follow',
                            }
                            STT += 1
                            // https://gendocx.iotsoftvn.com
                            fetch('https://gendocx.iotsoftvn.com/api/generate-docx/tem-dan-somi', requestOptions)
                                .then((response) => response.blob())
                                .then((blob) => {
                                    const fileName = `${deTaiInfo.HoSV} ${deTaiInfo.TenSV} HDDGLV.docx`
                                    // Thêm file vào zip
                                    zip.file(fileName, blob)
                                    count += 1 // Tăng biến đếm lên
                                    // STT += 1;  // Tăng STT cho file tiếp theo
                                    // Kiểm tra nếu tất cả các file đã được xử lý
                                    if (count === filterArr.length) {
                                        // Tạo file zip sau khi tất cả file đã được thêm
                                        zip.generateAsync({ type: 'blob' }).then((content) => {
                                            saveAs(content, 'HDDGLV.zip') // Tải xuống file zip
                                        })
                                    }
                                })
                                .catch((error) => {
                                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                                    console.error('Fail to fetch and create file:', error)
                                })
                        },
                        (error) => {
                            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                            console.log('Fail get goi dong by ID', error)
                        },
                    )
                })
                // console.log("filterArr", filterArr)
            } else {
                Vue.$toast.error(`Danh sách chưa có dữ liệu hội đồng`, { position: 'top' })
            }
        },
        formatCustomDate(dateStr) {
            const m = moment(dateStr, ['YYYY-MM-DD', 'DD/MM/YYYY'])
            const day = m.format('DD')
            const year = m.format('YYYY')
            let month = m.month() + 1 // moment month() trả về 0-11 nên phải +1
            if (month === 1 || month === 2) {
                month = `0${month}` // thêm số 0 phía trước
            }
            return `${day}/${month}/${year}`
        },
        printHDDGLV(HoiDongID, giangVienId1, giangVienId2, stt, hoiDongInfo) {
            let GVHD1 = ''
            let CoQuanGV1 = ''
            let GVHD2 = ''
            let CoQuanGV2 = ''
            const fetchGiangVienData = () => {
                return new Promise((resolve, reject) => {
                    ajaxCALL(
                        '/giangvien_get',
                        null,
                        (res) => {
                            resolve(res.data)
                        },
                        (error) => {
                            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                            reject(error)
                        },
                    )
                })
            }
            const fetchHoiDongData = (HoiDongID) => {
                return new Promise((resolve, reject) => {
                    ajaxCALL(
                        '/HoiDong_Get_ByHoiDongID',
                        { HoiDong_ID: HoiDongID },
                        (res) => {
                            resolve(res.data)
                        },
                        (error) => {
                            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                            reject(error)
                        },
                    )
                })
            }
            const downloadFile = (url, filename, zip) => {
                return fetch(url)
                    .then((response) => response.blob())
                    .then((blob) => {
                        zip.file(filename, blob)
                    })
            }
                ; (async () => {
                    try {
                        // https://gendocx.iotsoftvn.com
                        // http://localhost:5244
                        const url = 'https://gendocx.iotsoftvn.com'
                        const giangVien = await fetchGiangVienData()
                        console.log('giangVien list', giangVien)
                        // ID GVHD 1
                        let filterRes1 = giangVien.filter((item) => item.GiangVienID == giangVienId1)
                        if (filterRes1.length > 0) {
                            GVHD1 = filterRes1[0].HocViHocHam + '. ' + filterRes1[0].HoTenGiangVien
                            CoQuanGV1 = filterRes1[0].CoQuanCongTac
                        } else {
                            GVHD1 = hoiDongInfo.Thesises_Prof1
                            CoQuanGV1 = ''
                        }
                        // ID GVHD 2
                        let filterRes2 = giangVien.filter((item) => item.GiangVienID == giangVienId2)
                        if (filterRes2.length > 0) {
                            GVHD2 = filterRes2[0].HocViHocHam + '. ' + filterRes2[0].HoTenGiangVien
                            CoQuanGV2 = filterRes2[0].CoQuanCongTac
                        } else if (hoiDongInfo.Thesises_Prof2?.trim()) {
                            GVHD2 = hoiDongInfo.Thesises_Prof2
                            CoQuanGV2 = ''
                        }
                        const today = new Date()
                        const day = String(today.getDate()).padStart(2, '0') // Định dạng ngày với 2 chữ số
                        const month = String(today.getMonth() + 1).padStart(2, '0') // Định dạng tháng với 2 chữ số (tháng bắt đầu từ 0)
                        const year = today.getFullYear()
                        const hoiDongData = await fetchHoiDongData(HoiDongID)
                        const nganhIDNNA = 102
                        const deTaiInfo = hoiDongData[0][0]
                        const hoiDong = hoiDongData[1]
                        // Set STT cho những đề tài đã lập hội đồng và chưa có Kết quả bảo vệ/Bảo vệ thành công
                        const SttSomi = this.resetSTT(this.dsDeTai.filter((item) => item.HoiDongID && item.KetQuaHoiDong !== 2)).find((item) => item.Student_ID == deTaiInfo.StudentID)
                        console.log('this.resetSTT(this.dsDeTai.filter(item => item.HoiDongID))', this.resetSTT(this.dsDeTai.filter((item) => item.HoiDongID)))
                        console.log('SttSomi', SttSomi)
                        // Ngày bảo vệ
                        let ngayBV = ''
                        // Tháng bảo vệ
                        let thangBV = ''
                        // Năm bảo vệ
                        let namBV = ''
                        if (deTaiInfo.ThoiGianBaoVe) {
                            const splitDate = this.formatCustomDate(deTaiInfo.ThoiGianBaoVe).split(/[-/]/)
                            console.log('splitDatexxxxxx', splitDate)
                            ngayBV = splitDate[0]
                            thangBV = splitDate[1]
                            namBV = splitDate[2]
                        }
                        console.log('deTaiInfo', deTaiInfo)
                        console.log('hoiDong', hoiDong)
                        const m = moment(deTaiInfo.ThoiGianBaoVe, 'YYYY-MM-DD')
                        const dayBaoVe = m.format('DD')
                        const monthNum = m.month() + 1
                        const monthBaoVe = monthNum === 1 || monthNum === 2 ? `0${monthNum}` : `${monthNum}`
                        const yearBaoVe = m.format('YYYY')
                        // console.log("deTaiInfo", STT)
                        // In tem dan
                        let dataArr = []
                        hoiDong.forEach((item, index) => {
                            if (item.HoTenGiangVien) {
                                const obj = {
                                    STT: (index + 1).toString(),
                                    HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                                    CoQuanCongTac: item.CoQuanCongTac ? item.CoQuanCongTac : '',
                                    CoQuanCongTacTiengViet: item.CoQuanCongTacTiengViet ? item.CoQuanCongTacTiengViet : '',
                                    TrachNhiem: item.ChucTrach,
                                }
                                dataArr.push(obj)
                            }
                        })
                        console.log('this.resetSTT(dataArr)', this.resetSTT(dataArr))
                        let apiData = {
                            Nganh: deTaiInfo.TenNganh.toUpperCase(),
                            HocVien: deTaiInfo.HoSV + ' ' + deTaiInfo.TenSV,
                            STT: SttSomi ? SttSomi.STT : 0,
                            MaNganh: deTaiInfo.MaNganh,
                            ProcessID: hoiDongInfo.Process_ID,
                            DanhSach: this.resetSTT(dataArr).map((item) => {
                                return {
                                    ...item,
                                    STT: item.STT.toString(),
                                    CoQuanCongTac: deTaiInfo.NganhID === nganhIDNNA ? item.CoQuanCongTacTiengViet : item.CoQuanCongTac
                                }
                            }),
                        }
                        console.log("apiData", apiData)
                        const zip = new JSZip()
                        let myHeaders = new Headers()
                        myHeaders.append('Content-Type', 'application/json')
                        let requestOptions = {
                            method: 'POST',
                            headers: myHeaders,
                            body: JSON.stringify(apiData),
                            redirect: 'follow',
                        }
                        //https://gendocx.iotsoftvn.com
                        let temDanBlob = await fetch(`${url}/api/generate-docx/tem-dan-somi`, requestOptions).then((response) => response.blob())
                        zip.file(`${deTaiInfo.HoSV} ${deTaiInfo.TenSV} tem dan somi.docx`, temDanBlob)
                        // In phieu diem
                        apiData = {
                            Nganh: deTaiInfo.TenNganh ?? '',
                            SQD: deTaiInfo.Decision_SoQD ?? '',
                            NgayQD: deTaiInfo.Decision_NgayQD + '/' + this.formatSingleMonth(deTaiInfo.Decision_ThangQD) + '/' + deTaiInfo.Decision_NamQD,
                            NgayHop: ngayBV + '/' + thangBV + '/' + namBV,
                            TenHV: deTaiInfo.HoSV + ' ' + deTaiInfo.TenSV,
                            DeTai: deTaiInfo.DeTai ?? '',
                            Ngay: ngayBV ?? '',
                            Thang: thangBV ?? '',
                            Nam: namBV ?? '',
                            MaNganh: deTaiInfo.MaNganh ?? '',
                            ProcessID: hoiDongInfo.Process_ID,
                        }
                        requestOptions.body = JSON.stringify(apiData)
                        // https://gendocx.iotsoftvn.com
                        let phieuDiemBlob = await fetch(`${url}/api/generate-docx/phieu-diem`, requestOptions).then((response) => response.blob())
                        zip.file(`${deTaiInfo.HoSV} ${deTaiInfo.TenSV} Phieu diem.docx`, phieuDiemBlob)
                        // In bien ban nhan xet
                        for (const item of hoiDong) {
                            if (item.HoTenGiangVien) {
                                const apiData = {
                                    Nganh: deTaiInfo.TenNganh ?? '',
                                    SQD: deTaiInfo.Decision_SoQD ?? '',
                                    TenHV: deTaiInfo.HoSV + ' ' + deTaiInfo.TenSV,
                                    DeTai: deTaiInfo.DeTai ?? '',
                                    Ngay: ngayBV ?? '',
                                    Thang: thangBV ?? '',
                                    Nam: namBV ?? '',
                                    MaNganh: deTaiInfo.MaNganh ?? '',
                                    GVHD1: GVHD1 ?? '',
                                    GVHD2: GVHD2 ?? '',
                                    NguoiNhanXet: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                                    DonViCongTac: item.CoQuanCongTac ?? '',
                                    ChucTrach: item.ChucTrach ?? '',
                                    ProcessID: hoiDongInfo.Process_ID,
                                }
                                requestOptions.body = JSON.stringify(apiData)
                                // http://localhost:5244
                                const bienBanNhanXetBlob = await fetch(`${url}/api/generate-docx/bien-ban`, requestOptions).then((response) => response.blob())
                                zip.file(`Bien ban nhan xet ${item.ChucTrach}.docx`, bienBanNhanXetBlob)
                            }
                        }
                        // In bien ban kiem phieu
                        apiData = {
                            TenHV: deTaiInfo.HoSV + ' ' + deTaiInfo.TenSV,
                            DeTai: deTaiInfo.DeTai ?? '',
                            Ngay: ngayBV ?? '',
                            Thang: thangBV ?? '',
                            Nam: namBV ?? '',
                            NgayBaoVe: dayBaoVe ?? '',
                            ThangBaoVe: monthBaoVe ?? '',
                            NamBaoVe: yearBaoVe ?? '',
                            Nganh: deTaiInfo.TenNganh ?? '',
                            SQDLapHD: deTaiInfo.Decision_SoQD ?? '',
                            NgayQDLapHD: deTaiInfo.Decision_NgayQD + '/' + this.formatSingleMonth(deTaiInfo.Decision_ThangQD) + '/' + deTaiInfo.Decision_NamQD,
                            SoLuongThanhVien: deTaiInfo.SLTVHD_So.toString() ?? '',
                            MaNganh: deTaiInfo.MaNganh ?? '',
                            ProcessID: hoiDongInfo.Process_ID,
                        }
                        requestOptions.body = JSON.stringify(apiData)
                        let bienBanKiemPhieuBlob = await fetch(`${url}/api/generate-docx/kiem-phieu`, requestOptions).then((response) => response.blob())
                        zip.file(`${deTaiInfo.HoSV} ${deTaiInfo.TenSV} Kiem phieu.docx`, bienBanKiemPhieuBlob)
                        // In bien ban hop hoi dong
                        apiData = {
                            TenHV: deTaiInfo.HoSV + ' ' + deTaiInfo.TenSV,
                            DeTai: deTaiInfo.DeTai ?? '',
                            Ngay: dayBaoVe ?? '',
                            Thang: monthBaoVe ?? '',
                            Nam: yearBaoVe ?? '',
                            NgayBaoVe: dayBaoVe ?? '',
                            ThangBaoVe: monthBaoVe ?? '',
                            NamBaoVe: yearBaoVe ?? '',
                            Nganh: deTaiInfo.TenNganh ?? '',
                            NgayBaoVe: dayBaoVe ?? '',
                            ThangBaoVe: monthBaoVe ?? '',
                            NamBaoVe: yearBaoVe ?? '',
                            SQDLapHD: deTaiInfo.Decision_SoQD ?? '',
                            NgayQDLapHD: deTaiInfo.Decision_NgayQD + '/' + this.formatSingleMonth(deTaiInfo.Decision_ThangQD) + '/' + deTaiInfo.Decision_NamQD,
                            GVHD1: GVHD1,
                            GVHD2: GVHD2,
                            CoQuanGVHD1: CoQuanGV1,
                            CoQuanGVHD2: CoQuanGV2,
                            MaNganh: deTaiInfo.MaNganh ?? '',
                            ProcessID: hoiDongInfo.Process_ID,
                        }
                        requestOptions.body = JSON.stringify(apiData)
                        let bienBanHopHoiDongBlob = await fetch(`${url}/api/generate-docx/hop-hoi-dong`, requestOptions).then((response) => response.blob())
                        zip.file(`${deTaiInfo.HoSV} ${deTaiInfo.TenSV} Hop hoi dong.docx`, bienBanHopHoiDongBlob)
                        // Tải file zip
                        zip.generateAsync({ type: 'blob' }).then(function (content) {
                            saveAs(content, `${deTaiInfo.HoSV} ${deTaiInfo.TenSV} Ho so.zip`)
                        })
                    } catch (error) {
                        console.error(error)
                    }
                })()
        },
        formatSingleMonth(rawMonth) {
            if (!rawMonth) return ''
            const m = parseInt(rawMonth, 10) // chuyển "08" -> 8, "10" -> 10
            if (isNaN(m) || m < 1 || m > 12) return '' // nếu dữ liệu không hợp lệ
            if (m === 1 || m === 2) {
                return `0${m}` // "01" hoặc "02"
            }
            return `${m}` // "3".."9" hoặc "10".."12"
        },
        printWord_QD(HoiDongID, nganhID, lopID) {
            ajaxCALL(
                '/HoiDong_Get_ByHoiDongID',
                {
                    HoiDong_ID: HoiDongID,
                },
                (res) => {
                    const NNA_NganhID = 102
                    const deTaiInfo = res.data[0][0]
                    let hoiDong = res.data[1]
                    console.log('hoiDong', hoiDong)
                    hoiDong = hoiDong.map((item, index) => {
                        return {
                            ...item,
                            STT: (index + 1).toString(),
                            HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                            CoQuan: item.NganhID === NNA_NganhID
                                ? item.CoQuanCongTacTiengViet ? item.CoQuanCongTacTiengViet : ""
                                : item.CoQuanCongTac,
                        }
                    })
                    console.log('deTaiInfo xxx', deTaiInfo)
                    const apiData = {
                        SQD: deTaiInfo.Decision_SoQD ?? '',
                        Ngay: deTaiInfo.Decision_NgayQD ?? '',
                        Thang: this.formatSingleMonth(deTaiInfo.Decision_ThangQD) ?? '',
                        Nam: deTaiInfo.Decision_NamQD ?? '',
                        DeTai: deTaiInfo.DeTai ?? '',
                        HoTen: deTaiInfo.HoSV + ' ' + deTaiInfo.TenSV,
                        Nganh: deTaiInfo.TenNganh ?? '',
                        NganhID: nganhID,
                        LopID: lopID,
                        ProcessID: deTaiInfo.Process_ID,
                        SoThanhVien: deTaiInfo.SLTVHD_So.toString() ?? '',
                        SoThanhVienBangChu: deTaiInfo.SLTVHD_Chu ?? '',
                        MaNganh: deTaiInfo.MaNganh ?? '',
                        LuuVT: deTaiInfo.Decision_NguoiTao.toString() ?? '',
                        DanhSachHD: hoiDong ?? [],
                    }
                    const myHeaders = new Headers()
                    myHeaders.append('Content-Type', 'application/json')
                    const requestOptions = {
                        method: 'POST',
                        headers: myHeaders,
                        body: JSON.stringify(apiData),
                        redirect: 'follow',
                    }
                    // https://gendocx.iotsoftvn.com
                    // http://localhost:5244
                    fetch('https://gendocx.iotsoftvn.com/api/generate-docx/quyet-dinh-hd', requestOptions)
                        .then((response) => response.blob())
                        .then((blob) => {
                            var url = window.URL.createObjectURL(blob)
                            var a = document.createElement('a')
                            a.href = url
                            a.download = `${deTaiInfo.HoSV} ${deTaiInfo.TenSV} quyet dinh hoi dong.docx`
                            document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
                            a.click()
                            a.remove() //afterwards we remove the element again
                        })
                        .catch((error) => console.error(error))
                    console.log('de tai info', deTaiInfo)
                    console.log('hoi dong', hoiDong)
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('Fail get goi dong by ID', error)
                },
            )
        },
        findExistDeTai(item) {
            const filter = this.dsDeTai.filter((deTai) => deTai.Student_ID === item.Student_ID)
            if (filter.length >= 2) {
                return false
            } else if (filter.length > 0 && item.KetQuaHoiDong === 2) {
                return true
            }
        },
        filterDsDeTai() {
            let data = this.dsDeTaiOrigin
            // Nếu có giá trị và không phải là mặc định
            if (this.dateSelect && this.dateSelect !== '-Tất cả-') {
                data = data.filter((item) => item.ThoiGianBaoVe === this.dateSelect)
            }
            if (this.NienKhoaValue && this.NienKhoaValue !== '0') {
                data = data.filter((item) => item.Nien_Khoa === this.NienKhoaValue)
            }
            if (this.hoiDongStateSelect === '2') {
                data = data.filter((item) => item.Decision_ID === null)
            } else if (this.hoiDongStateSelect === '3') {
                data = data.filter((item) => item.DiemHoiDong)
            } else if (this.hoiDongStateSelect === '4') {
                data = data.filter((item) => !item.DiemHoiDong && item.Decision_ID)
            }
            this.dsDeTai = this.resetSTT(data)
        },
        clearHoiDongFailData(studentID) {
            return new Promise((resolve, reject) => {
                ajaxCALL(
                    '/HoiDong_Fail_NullData',
                    {
                        StudentID: studentID.toString(),
                    },
                    (res) => {
                        Vue.$toast.success(`Xóa dữ liệu cũ bảo vệ thất bại thành công`, { position: 'top' })
                        resolve('Null fail Hoi Dong success')
                    },
                    (error) => {
                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        console.log('Fail null hoi dong')
                        reject(error)
                    },
                )
            })
        },
        setStatusHoiDongFail(studentID) {
            return new Promise((resolve, reject) => {
                ajaxCALL(
                    '/HoiDong_Fail_Set_Status',
                    {
                        StudentID: studentID.toString(),
                    },
                    (res) => {
                        Vue.$toast.success(`Set về trạng thái chưa nộp thành công`, { position: 'top' })
                        resolve('Set W status Hoi Dong success')
                    },
                    (error) => {
                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        console.log('Set status hoi dong fail')
                        reject(error)
                    },
                )
            })
        },
        async failDefend(item) {
            const $this = this
            confirm({
                title: `Xác nhận thành lập lại hội đồng cho học viên ${item.Student_ID} - ${item.Ho_SV} ${item.Ten_SV}?`,
                action: async () => {
                    if (!item.HoiDongID) {
                        Vue.$toast.error(`Chưa lập hội đồng`, { position: 'top' })
                        return
                    }
                    if (!item.Student_ID) {
                        Vue.$toast.error(`Chưa có Student ID`, { position: 'top' })
                        return
                    }
                    ajaxCALL(
                        '/HoiDong_Old_Ins',
                        {
                            HoiDongID: item.HoiDongID,
                            StudentID: item.Student_ID.toString(),
                        },
                        async (res) => {
                            Vue.$toast.success(`Mở lại hội đồng thành công`, { position: 'top' })
                            await $this.clearHoiDongFailData(item.Student_ID)
                            await $this.setStatusHoiDongFail(item.Student_ID)
                            CALL('getHoiDongDeTai')
                        },
                        (error) => {
                            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                            console.log('Fail get chuc trach')
                        },
                    )
                },
                cancel: function () { }.bind(this),
            })
        },
        onViewHistory(item) {
            this.selectedHistoryStudent = item
            this.isHistoryDialogOpen = true
            this.historyList = []
            this.historyMembers = []
            this.isLoadingHistory = true
            ajaxCALL(
                '/HoiDong_History_Get',
                {
                    Student_ID: item.Student_ID.toString(),
                },
                (res) => {
                    this.isLoadingHistory = false
                    if (res && res.data) {
                        this.historyList = res.data[0] || []
                        this.historyMembers = res.data[1] || []
                    }
                },
                (err) => {
                    this.isLoadingHistory = false
                    const msg = err && err.responseJSON && err.responseJSON.Message ? err.responseJSON.Message : 'Không thể tải lịch sử hội đồng'
                    Vue.$toast.error(msg, { position: 'top' })
                }
            )
        },
        formatDateDisplay(val) {
            if (!val) return ''
            const d = new Date(val)
            if (isNaN(d.getTime())) return val
            return d.toLocaleDateString('vi-VN')
        },
        formatScore(val) {
            if (val === null || val === undefined || val === '') return ''
            const num = parseFloat(val)
            if (isNaN(num)) return val
            return parseFloat(num.toFixed(2)).toString()
        },
        getHoiDongStatus(hd) {
            if (hd.Is_Xoa) {
                return { text: 'Đã hủy / Hoãn', color: 'error', cardClass: 'hd-card-deleted', headerBg: 'red lighten-5' }
            }
            if (hd.KetQuaHoiDong === 2) {
                return { text: 'Không đạt (Đã mở lại)', color: 'warning', cardClass: 'hd-card-failed', headerBg: 'orange lighten-5' }
            }
            if (hd.DiemHoiDong !== null && hd.DiemHoiDong !== undefined && hd.DiemHoiDong !== '') {
                return { text: 'Đã có điểm: ' + this.formatScore(hd.DiemHoiDong), color: 'success', cardClass: 'hd-card-active', headerBg: 'green lighten-5' }
            }
            if (hd.HoiDong_Status === 0) {
                return { text: 'Chưa kích hoạt / Bản sao', color: 'grey', cardClass: 'hd-card-inactive', headerBg: 'grey lighten-4' }
            }
            return { text: 'Đang hiệu lực', color: 'primary', cardClass: 'hd-card-active', headerBg: 'blue lighten-5' }
        },
        getHistoryMembers(hoiDongId) {
            if (!this.historyMembers || !Array.isArray(this.historyMembers)) return []
            const members = this.historyMembers.filter((m) => m.HoiDongID === hoiDongId)
            const activeMembers = members.filter((m) => !m.Is_Xoa && m.HoTenGiangVien)
            if (activeMembers.length > 0) return activeMembers
            const latestMap = new Map()
            members.filter((m) => m.HoTenGiangVien).forEach((m) => {
                latestMap.set(m.ChucTrach, m)
            })
            return Array.from(latestMap.values())
        },
    },
    template: /*html*/ `
        <div>
            <!-- Tep so mi cho hoc vien -->
            <dialog-tep-somi :hoidongid="HoiDongHVId"/>
            <!-- Quan ly thong tin thanh vien hoi dong -->
            <dialog-detai-thanhvien :hearr="heArr"/>
            <!-- Thong ke kinh phi -->
            <dialog-thong-ke-kinh-phi />
            <!-- Export Thu moi for giang vien -->
            <dialog-thu-moi :dshddetai="dshddetai" :dsgiangvien="DsGiangVien" :nganhgiangday="vueData.NganhGiangDay" :dshedaotao="dshedaotao" :hearr="heArr"/>
            <!-- Add council by excel -->
            <dialog-add-council-by-excel :dshdgiangvien="dshdgiangvien" :dshddetai="dshddetai"/>
            <!-- Add council -->
            <!-- khi them hoi dong thanh cong thi disable nut them moi hoi dong -->
            <dialog-add-council :editedItem="editedItem" :dshoidonggiangvien="DSHoiDongGiangVien"
                :dshdchuctrach="DSHoiDongChucTrach" :dshedaotao="dshedaotao" :hearr="hearr"> </dialog-add-council>
            <!-- give SQD -->
            <dialog-give-sqd :isqsddialog="vueData.isSQDDialog" :thongtinhocvien="dataUpdateHD.HoiDong"
                :editedItem="editedItem" :dsgiangvien="dataUpdateHD.GiangVienSelected" />
            <!-- update council -->
            <dialog-update-council :editedItem="editedItem" :dshoidonggiangvien="dataUpdateHD.GiangVienSelected"
                :thongtinhocvien="dataUpdateHD.HoiDong" :dshedaotao="dshedaotao" :hearr="hearr"></dialog-update-council>
            <!-- view council -->
            <dialog-view-council :editedItem="editedItem"
                :dshoidonggiangvien="dataUpdateHD.GiangVienMergeSelected"></dialog-view-council>
            <!-- temp council -->
            <dialog-council-temp :editedItem="editedItem" :dshoidonggiangvien="DSHDGiangVienEstablishCouncil"
                :dsgiangviendukien="DSGiangVienDuKien" :dsgiangviendukiendefault="DSGiangVienDuKienDefault"
                :dshdchuctrach="DSHoiDongChucTrach" :dsdetai="DSDeTaiCoHoiDong" :hearr="hearr" />
            <!-- input score -->
            <dialog-input-score :getdiem="getDiem" :editedItem="editedItem"
                :dshoidongId ="dataUpdateHD.HoiDong"
                :dshoidonggiangvien="dataUpdateHD.GiangVienSelected" />
            <!-- Dialog Xem Lịch Sử Hội Đồng -->
            <v-dialog v-model="isHistoryDialogOpen" max-width="900px" scrollable>
                <v-card>
                    <v-card-title class="headline primary--text">
                        <v-icon left color="primary">mdi-history</v-icon>
                        Lịch sử hội đồng: [{{ selectedHistoryStudent ? selectedHistoryStudent.Student_ID : '' }}] {{ selectedHistoryStudent ? selectedHistoryStudent.Ho_SV + ' ' + selectedHistoryStudent.Ten_SV : '' }}
                        <v-spacer></v-spacer>
                        <v-btn icon @click="isHistoryDialogOpen = false">
                            <v-icon>mdi-close</v-icon>
                        </v-btn>
                    </v-card-title>
                    <v-card-text class="pt-2">
                        <div v-if="isLoadingHistory" class="text-center py-6">
                            <v-progress-circular indeterminate color="primary"></v-progress-circular>
                            <div class="caption mt-2">Đang tải lịch sử...</div>
                        </div>
                        <div v-else-if="!historyList || historyList.length === 0" class="text-center py-6 grey--text">
                            Chưa có dữ liệu lịch sử hội đồng.
                        </div>
                        <div v-else>
                            <v-card v-for="(hd, idx) in historyList" :key="hd.HoiDongID" outlined class="mb-3" :class="getHoiDongStatus(hd).cardClass">
                                <v-card-title class="subtitle-1 py-2 d-flex justify-space-between align-center" :class="getHoiDongStatus(hd).headerBg">
                                    <div>
                                        <b>Lần {{ historyList.length - idx }}: HĐ #{{ hd.HoiDongID }}</b>
                                        <span class="ml-2 font-weight-regular" v-if="hd.Decision_SoQD">- QĐ: <b>{{ hd.Decision_SoQD }}</b></span>
                                        <span class="ml-2 font-weight-regular" v-if="hd.ThoiGianBaoVe">- Ngày BV: <b>{{ formatDateDisplay(hd.ThoiGianBaoVe) }}</b></span>
                                    </div>
                                    <div>
                                        <v-chip small :color="getHoiDongStatus(hd).color" dark label>
                                            {{ getHoiDongStatus(hd).text }}
                                        </v-chip>
                                    </div>
                                </v-card-title>
                                <v-card-text class="py-2">
                                    <div v-if="hd.LyDoHuy" class="red--text text--darken-2 mb-2 font-italic">
                                        <b>Lý do hủy/hoãn:</b> {{ hd.LyDoHuy }}
                                    </div>
                                    <div class="caption grey--text mb-2">
                                        <span>Người tạo: {{ hd.Created_By || 'N/A' }} ({{ formatDateDisplay(hd.Created_At) }})</span>
                                        <span v-if="hd.Updated_By" class="ml-3">Người cập nhật/hủy: {{ hd.Updated_By }} ({{ formatDateDisplay(hd.Updated_At) }})</span>
                                    </div>
                                    <v-simple-table dense>
                                        <template v-slot:default>
                                            <thead>
                                                <tr>
                                                    <th class="text-left" style="width: 50px;">STT</th>
                                                    <th class="text-left">Họ tên thành viên</th>
                                                    <th class="text-left">Chức trách</th>
                                                    <th class="text-left">Cơ quan công tác</th>
                                                    <th class="text-center" style="width: 80px;" v-if="hd.DiemHoiDong">Điểm</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(tv, tvIdx) in getHistoryMembers(hd.HoiDongID)" :key="tv.TVHDID">
                                                    <td>{{ tvIdx + 1 }}</td>
                                                    <td>{{ tv.HocViHocHam ? tv.HocViHocHam + '. ' : '' }}{{ tv.HoTenGiangVien }}</td>
                                                    <td><v-chip x-small outlined color="primary">{{ tv.ChucTrach }}</v-chip></td>
                                                    <td>{{ tv.CoQuanCongTac }}</td>
                                                    <td class="text-center font-weight-bold" v-if="hd.DiemHoiDong">
                                                        {{ tv.Diem !== null && tv.Diem !== undefined ? formatScore(tv.Diem) : '-' }}
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </template>
                                    </v-simple-table>
                                </v-card-text>
                            </v-card>
                        </div>
                    </v-card-text>
                    <v-card-actions>
                        <v-spacer></v-spacer>
                        <v-btn text @click="isHistoryDialogOpen = false">Đóng</v-btn>
                    </v-card-actions>
                </v-card>
            </v-dialog>
            <!-- Major filter -->
            <!-- Sửa lỗi responsive: thêm flex-wrap và mb-2 cho các phần tử để tránh bể layer trên macbook -->
            <div class="d-flex align-center mb-3 flex-wrap">
                <div class="selectNganh mb-2">
                    <v-select v-model="major" :items="heArr" outlined dense hide-details label="Lọc theo ngành"
                    item-text="TenNganh" item-value="NganhID" no-data-text="Vui lòng chọn hệ đào tạo"/>
                </div>
                <div class="selectNgayBVLV mb-2">
                    <v-autocomplete v-model="dateSelect" :items="dateTime" item-text="ThoiGianBaoVe" item-value="ThoiGianBaoVe" outlined dense hide-details label='Ngày bảo vệ luận văn' :disabled="!major"/>
                </div>
                <div class="mr-3 selectNienKhoaWrap mb-2">
                    <v-autocomplete
                    v-model="NienKhoaValue"
                    :items="DsNienKhoa"
                    item-text="TenNienKhoa"
                    item-value="NienKhoa"
                    outlined
                    dense
                    hide-details
                    placeholder="Chọn niên khóa"
                    label="Niên khóa"
                />
                </div>
                <div class="mr-3 mb-2">
                    <v-autocomplete v-model="hoiDongStateSelect" :items="hoiDongStateList" item-text="text" item-value="value" outlined dense hide-details label='Trạng thái hội đồng'/>
                </div>
                <div class="mr-3 mb-2">
                    <v-btn color="primary" dark @click="filterDsDeTai"> <v-icon left>mdi-filter</v-icon> Lọc </v-btn>
                </div>
                <!--&& dateSelect !== '-Tất cả-'-->
                <v-btn class="mr-2 mb-2" v-if="major && dateSelect" @click="printExcel" color="success" dark><v-icon left>mdi-microsoft-excel</v-icon>Xuất file học viên đăng ký bảo vệ</v-btn>
                <v-btn class="mr-2 mb-2" @click="vueData.isExcelDialog = true" color="success"><v-icon left>mdi-microsoft-excel</v-icon>Load file excel lập hội đồng</v-btn>
                <!--<v-btn class="mr-2" color="primary" @click="fn_EstablishCouncil"><v-icon left>mdi-list-box-outline</v-icon>Lập nhiều hội đồng</v-btn>-->
                <v-btn class="mr-2 mb-2" v-if="major" @click="printAllHDDGLV" color="success" dark><v-icon left>mdi-microsoft-excel</v-icon>Xuất file HDDGLV</v-btn>
            </div>
            <div class="d-flex align-center justify-end mb-2 selectBar flex-wrap">
                <div class="d-flex align-center flex-wrap">
                    <v-btn @click="vueData.isThuMoiDialog = true" class="ml-3 mb-2" color="primary" dark><v-icon left>mdi-email-newsletter</v-icon>In thư mời giảng viên</v-btn>
                    <v-btn @click="vueData.isThongKeKinhPhiDialog = true" class="ml-3 mb-2" color="warning" dark><v-icon left>mdi-file-chart-outline</v-icon>In thống kê kinh phí</v-btn>
                    <v-btn @click="vueData.isCouncilInfoManager = true" class="ml-3 mb-2" color="teal" dark><v-icon left>mdi-information-box-outline</v-icon>Thông tin thành viên hội đồng</v-btn>
                </div>
            </div>
            <div>
                <!-- dsDeTai-->
                <c-table class="table-frozen-cols" isSearch label="Danh sách hội đồng đánh giá Luận văn Thạc sĩ" :headers="headerCTable"
                    :items="dsDeTai" isNew="false" isEdit="false" items-per-page="-1" :footer-props="{'items-per-page-options':[50, 100, 150, -1]}">
                    <template v-slot:item.HoTenMaSV="{item}">
                        <span class='primary--text'>
                            <b> {{item.Ho_SV}} {{ item.Ten_SV}}</b>
                        </span>
                        <br />
                        <b>{{item.Student_ID}}</b>
                        <span class='amber--text'> [{{item.Lop_ID}}]</span>
                    </template>
                    <template v-slot:item.ThaoTacHoiDongBTN="{item}">
                        <div class="d-flex flex-column align-center py-1">
                        	<v-btn v-if="item.DiemHoiDong" text @click='onViewHoiDong(item)'
                                class='theme--light v-size--default success--text'>
                                Xem Hội Đồng
                            </v-btn>
                            <!--v-if="!item.HoiDongID || item.KetQuaHoiDong === 2"-->
                            <v-btn v-if="!item.HoiDongID" text @click='addCouncil(item)'
                                class='theme--light v-size--default pink--text'>
                                Lập Hội Đồng
                            </v-btn>
                            <v-btn v-if="findExistDeTai(item)" text @click='addCouncil(item)'
                                class='theme--light v-size--default pink--text'>
                                Lập Hội Đồng
                            </v-btn>
                            <!--v-if="item.HoiDongID && !item.Decision_SoQD" -->
                            <v-btn v-if="item.HoiDongID && !item.DiemHoiDong"
                                text @click='onUpdateHoiDong(item)'
                                class='justify-center align-center theme--light v-size--default cyan--text'>
                                Xem & Cập nhật
                            </v-btn>
                            <v-btn text x-small color="indigo" @click='onViewHistory(item)' class="mt-1">
                                <v-icon left x-small>mdi-history</v-icon>Lịch sử HĐ
                            </v-btn>
                        </div>
                    </template>
                    <template v-slot:item.ThaoTacSQDBTN="{item}">
                        <v-btn text @click='giveSQD(item)'
                            v-bind:class="{'success--text': item.Decision_SoQD, 'purple--text': !item.Decision_SoQD}"
                            class='v-btn theme--light v-size--default purple--text'
                            :disabled="sqdCheckStatus(item.HoiDongID)">
                            {{item.Decision_SoQD ? item.Decision_SoQD : 'Cập nhật'}}
                        </v-btn>
                    </template>
                    <template v-slot:item.InputScore="{item}">
                        <v-btn @click="onInputScore(item)" text class='v-btn theme--light v-size--default teal--text'
                            :disabled="checkInputScoreStatus(item)">
                            Nhập điểm
                        </v-btn>
                    </template>
                    <template v-slot:item.ThaoTacInQDBTN="{item}">
                        <div class="d-flex align-center justify-center">
                            <v-icon class="mr-5" @click='printQD_LV_Ths(item.HoiDongID, item.Nganh_ID, item.Lop_ID)' color='orange darken-4'
                            :disabled="sqdCheckStatus(item.HoiDongID)"> mdi-file-pdf-box</v-icon>
                            <v-icon class="mr-5" @click='printWord_QD(item.HoiDongID, item.Nganh_ID, item.Lop_ID)' color='light-blue darken-3'
                            :disabled="sqdCheckStatus(item.HoiDongID)"> mdi-file-word-box</v-icon>
                        </div>
                    </template>
                    <template v-slot:item.FailToDefend="{item}">
                        <div class="d-flex align-center justify-center">
                            <v-chip v-if="item.KetQuaHoiDong === 2" small color="grey lighten-2" class="grey--text text--darken-2" label>
                                Đã mở lại
                            </v-chip>
                            <v-btn v-else :disabled="!item.HoiDongID" small color="error" @click="failDefend(item)" text>
                                Lập lại HĐ
                            </v-btn>
                        </div>
                    </template>
                    <template v-slot:item.Hddglv="{item}">
                        <div class="d-flex align-center justify-center">
                            <v-icon @click='printHDDGLV(item.HoiDongID, item.GiangVienID1, item.GiangVienID2, item.STT, item)' color='yellow darken-2'
                            :disabled="sqdCheckStatus(item.HoiDongID)"> mdi-zip-box</v-icon>
                        </div>
                    </template>
                </c-table>
            </div>
        </div>
    `,
})