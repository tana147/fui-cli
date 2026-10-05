<template>
	<div>
        <v-row class="mb-3">
            <v-col cols="4" md="3">
                <v-select v-model="nganhid" :items="NganhGiangDay" outlined dense hide-details label="Lọc theo ngành" item-text="TenNganh" item-value="NganhID" />
            </v-col>

            <v-col cols="4" md="2">
                <v-autocomplete
                    v-model="nienkhoa"
                    :items="DsNienKhoa"
                    item-text="TenNienKhoa"
                    item-value="NienKhoa"
                    outlined
                    multiple
                    small-chips
                    dense
                    hide-details
                    placeholder="Chọn niên khóa"
                    label="Niên khóa"
                />
            </v-col>

            <v-col cols="4" md="2">
                <div class="d-flex">
                    <v-select v-model="trangthaiselect" :items="TrangThaiList" outlined dense hide-details label="Trạng thái" item-text="text" item-value="value" />

                    <v-btn @click="onApplyFilters" color="primary" class="ml-3 mr-2">
                        <v-icon dense left>mdi-filter</v-icon>
                        Lọc
                    </v-btn>
                </div>
            </v-col>

            <v-col cols="12" md="5" class="text-right">
                <v-btn :loading="isExportLoading" @click="onPrintExcel" color="success">
                    <v-icon dense left>mdi-microsoft-excel</v-icon>
                    Xuất file excel
                </v-btn>
            </v-col>
        </v-row>

        <c-table
            :items="DsTKNopDeCuong"
            :label="labelTable"
            :headers="tableHeader"
            dense
            items-per-page="-1"
            isNew="false"
            isEdit="false"
            isSearch
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
        >
            <template v-slot:item.HoTenMaSV="{ item }">
                <span class="primary--text">
                    <b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
                </span>
                <br />
                <b>{{ item.Student_ID }}</b>
                <span class="amber--text"> [{{ item.Lop_ID }}]</span>
            </template>
            <template v-slot:item.Flow_Detail_Status="{ item }">
                <v-chip v-if="item.Flow_Detail_Status === 'W'" color="warning" outlined>Chưa nộp</v-chip>
                <v-chip v-else-if="item.Flow_Detail_Status === 'P'" color="primary" outlined>Đang chờ duyệt</v-chip>
            </template>
        </c-table>
    </div>
</template>

<script>
	export default {
		data() {
        return {
            isExportLoading: false,
            nganhid: '0',
            nienkhoa: ['0'], // Khởi tạo là mảng cho multiple
            trangthaiselect: '0',
            appliedNienKhoa: ['0'], // Biến lưu trạng thái niên khóa khi bấm Lọc
            appliedTrangThai: '0', // Biến lưu trạng thái khi bấm Lọc
            NganhGiangDay: [],
            DsNienKhoa: [],
            DsTKNopDeCuongRoot: [],

            TrangThaiList: [
                { text: '- Tất cả -', value: '0' },
                { text: 'Chưa nộp', value: 'W' },
                { text: 'Đang chờ duyệt', value: 'P' },
            ],
            tableHeader: [
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
                    width: 200,
                },
                {
                    text: 'Niên khóa',
                    value: 'Nien_Khoa',
                    sortable: false,
                    align: 'center',
                    width: 110,
                },
                {
                    text: 'Tên ngành',
                    value: 'Ten_Nganh',
                    width: 200,
                },
                {
                    text: 'GVHD 1',
                    value: 'Thesises_Prof1',
                    width: 180,
                },
                {
                    text: 'GVHD 2',
                    value: 'Thesises_Prof2',
                    width: 180,
                },
                {
                    text: 'Tên đề tài dự kiến',
                    value: 'ThesisNameSuggest',
                },
                {
                    text: 'Tên đề tài chính thức',
                    value: 'Thesis_Name',
                },
                  {
                    text: 'Ngày đăng ký',
                    value: 'NgayDangKy',
                    width: 130,
                    sortable: false
                },
                {
                    text: 'Trạng thái',
                    value: 'Flow_Detail_Status',
                    sortable: false,
                    align: 'center',
                },
            ],
        }
    },
    mounted() {
        this.onLoadNganhGiangDay()
        this.getNienKhoa()
        this.onLoadThongKeNopDeCuong('0')
    },
    computed: {
        // Lọc dữ liệu hiển thị trên bảng từ dữ liệu gốc DsTKNopDeCuongRoot
        // Chỉ filter khi các biến applied thay đổi (sau khi nhấn Lọc)
        DsTKNopDeCuong() {
            let data = this.DsTKNopDeCuongRoot

            if (this.appliedTrangThai !== '0') {
                data = data.filter((item) => item.Flow_Detail_Status === this.appliedTrangThai)
            }
            if (!this.appliedNienKhoa.includes('0') && this.appliedNienKhoa.length > 0) {
                // Kiểm tra niên khóa thuộc danh sách áp dụng lọc
                data = data.filter((item) => this.appliedNienKhoa.includes(String(item.Nien_Khoa)))
            }

            return data
        },

        labelTable() {
            return `Danh sách học viên (${this.DsTKNopDeCuong.length})`
        },
    },
    watch: {
        nganhid: function (val) {
            this.onLoadThongKeNopDeCuong(val)
        },
        nienkhoa(newVal, oldVal) {
            // Xử lý loại trừ khi chọn Niên khóa: "Tất cả" (ID là '0') với các phần tử khác
            if (!newVal || newVal.length === 0) {
                this.nienkhoa = ['0']
                return
            }

            const wasAllSelected = oldVal.includes('0')
            const isAllSelected = newVal.includes('0')

            if (wasAllSelected && isAllSelected && newVal.length > 1) {
                // Đang chọn "Tất cả" mà chọn thêm phần tử khác -> Bỏ "Tất cả" đi
                this.nienkhoa = newVal.filter((item) => item !== '0')
            } else if (!wasAllSelected && isAllSelected) {
                // Đang chọn các phần tử khác mà lại gắn "Tất cả" vào -> Bỏ hết các phần tử khác đi
                this.nienkhoa = ['0']
            }
        },
    },
    methods: {
        // Cập nhật giá trị lọc vào biến applied khi nhấn nút "Lọc"
        onApplyFilters() {
            this.appliedNienKhoa = [...this.nienkhoa]
            this.appliedTrangThai = this.trangthaiselect
        },

        // Gọi API lấy dữ liệu Thống kê nộp đề cương theo Ngành
        onLoadThongKeNopDeCuong(nganhID) {
            ajaxCALL(
                '/SDH_ThongKe_DeTai_ChuaNopDeCuong',
                {
                    Nganh_ID: nganhID,
                },
                (res) => {
                    this.DsTKNopDeCuongRoot = res.data.map((item, index) => {
                        return {
                            ...item,
                            STT: index + 1,
                            HoTenMaSV: item.Ho_SV + ' ' + item.Ten_SV + ' ' + item.Student_ID + ' ' + item.Lop_ID,
                            NgayDangKy: moment(item.NgayDangKy).format('DD-MM-YYYY')
                        }
                    })
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON?.Message || 'Lỗi lấy dữ liệu'}`, { position: 'top' })
                    console.log('Fail to load thong ke nop de cuong', error)
                },
            )
        },

        // API lấy danh sách Ngành giảng dạy
        async onLoadNganhGiangDay() {
            this.NganhGiangDay = await getNganhCaoHocPromise({ hasAllOption: true });
        },

        // API lấy danh sách Niên khóa
        getNienKhoa() {
            const $this = this
            $.ajax({
                type: 'GET',
                headers: {
                    authorization: window.$awt || $awt,
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
                    $this.nienkhoa = [$this.DsNienKhoa[0]?.NienKhoa || '0']
                    $this.appliedNienKhoa = [$this.DsNienKhoa[0]?.NienKhoa || '0']
                },
                error: function (xhr) {
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

        // Helper trả về Tên ngành để xuất excel
        nganhName(nganhid) {
            const nganh = this.NganhGiangDay.find((item) => item.NganhID === nganhid)
            return nganh ? nganh.TenNganh?.toUpperCase() : ''
        },

        // Xuất file excel
        onPrintExcel() {
            this.isExportLoading = true
            const dataArr = []
            this.DsTKNopDeCuong.forEach((item) => {
                const data = {
                    STT: item.STT,
                    MSHV: item.Student_ID,
                    LopID: item.Lop_ID,
                    Ho: item.Ho_SV,
                    Ten: item.Ten_SV,
                    DeTai: item.ThesisNameSuggest,
                    DeTaiChinhThuc: item.Thesis_Name,
                    NienKhoa: item.Nien_Khoa,
                    Nganh: item.Ten_Nganh,
                    GVHD1: item.Thesises_Prof1,
                    GVHD2: item.Thesises_Prof2,
                    NgayDangKy: item.NgayDangKy
                }
                dataArr.push(data)
            })

            const apiData = {
                Nganh: this.nganhid === '0' ? '' : this.nganhName(this.nganhid),
                SoLuong: this.DsTKNopDeCuong.length,
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

            fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/thong-ke-nop-de-cuong', requestOptions)
                .then((response) => response.blob())
                .then((blob) => {
                    var url = window.URL.createObjectURL(blob)
                    var a = document.createElement('a')
                    a.href = url
                    a.download = `Danh sach nop de cuong.xlsx`
                    document.body.appendChild(a)
                    a.click()
                    a.remove()
                    this.isExportLoading = false
                })
                .catch((error) => {
                    this.isExportLoading = false
                    console.error(error)
                })
        },
    },
	}
</script>