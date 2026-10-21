<template>
	<div>
        <v-row>
            <v-col cols="2">
                <v-autocomplete v-model="nganhSelect" :items="NganhArr" outlined dense hide-details label="Ngành" item-text="TenNganh" item-value="NganhID" />
            </v-col>
            <v-col cols="2">
                <v-autocomplete v-model="giangVienSelect" :items="DsGiangVien" label="Lọc theo giảng viên" item-text="Prof_Name" item-value="Prof_Name" outlined dense hide-details />
            </v-col>
            <v-col cols="2">
                <v-autocomplete v-model="selectTrangThai" :items="filterSelect" label="Lọc theo trạng thái" item-text="text" item-value="value" outlined dense hide-details />
            </v-col>
            <v-col cols="1">
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
            </v-col>
            <v-col>
                <v-btn color="pink" :loading="isLoading" dark @click="filterDsDeTai"> <v-icon left>mdi-filter</v-icon> Lọc </v-btn>
            </v-col>
        </v-row>
        <div class="d-flex justify-end mb-3">
            <v-btn :loading="isLoading" color="success" dark @click="printExcel"> <v-icon left>mdi-microsoft-excel</v-icon> Xuất excel </v-btn>
        </div>
        <v-row>
            <v-col cols="9">
                <v-card>
                    <v-card-title class="pink--text">
                        Danh sách Đề tài ({{ DsDeTaiFilter.length }})
                        <v-spacer></v-spacer>
                        <v-text-field class="searchBar mb-5" v-model="search" prepend-inner-icon="mdi-magnify" label="Search" single-line hide-details />
                    </v-card-title>
                    <v-data-table
                        class="table-frozen-cols"
                        :search="search"
                        :headers="headerDeTaiTable"
                        :items="DsDeTaiFilter"
                        :dense="true"
                        :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
                        itemsPerPage="-1"
                    >
                        <template v-slot:item.HoTenMaSV="{ item }">
                            <span class="primary--text"
                                ><b>{{ item.HoTen }}</b></span
                            ><br /><b>{{ item.Student_ID }}</b
                            ><span class="amber--text"> [{{ item.Lop_ID }}]</span>
                        </template>
                        <template v-slot:item.FileThesisConfirm="{ item }">
                            <div class="mt-3">
                                <div v-if="item.FileThesisConfirm">
                                    <v-chip label outlined class="mb-3" color="deep-purple accent-4">
                                        <v-icon left>mdi-file-check-outline</v-icon>
                                        <a :href="vueData.v_Set.urlReadFile + item.FileThesisConfirm" target="_blank" style="color: deep-purple accent-4">File Quyết định</a>
                                    </v-chip>
                                </div>

                                <v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label> Chưa upload file </v-chip>
                            </div>
                        </template>
                    </v-data-table>
                </v-card>
                <!-- <f-table
                    :label="deTaiLabel"
                    :headers="headerDeTaiTable"
                    :items="DsDeTaiFilter"
                    show-search="true"
                    :dense="true"
                    :excel="false"
                    :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
                    itemsPerPage="-1"
                /> -->
            </v-col>
            <v-col cols="3">
                <!-- Ds giang vien -->
                <v-card>
                    <v-card-title class="pink--text">
                        Danh sách Giảng viên ({{ DsGvCopy.length }})
                        <v-spacer></v-spacer>
                        <v-text-field class="searchBar mb-5" v-model="GiangVienSearch" prepend-inner-icon="mdi-magnify" label="Search" single-line hide-details />
                    </v-card-title>
                    <v-data-table
                        :search="GiangVienSearch"
                        :headers="headerGVTable"
                        :items="DsGvCopy"
                        :dense="true"
                        :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
                        itemsPerPage="-1"
                    />
                </v-card>
                <!-- <f-table :label="giangVienLabel" show-search="true" :headers="headerGVTable" :items="DsGvCopy" :dense="true" :excel="false"
					:footer-props="{'items-per-page-options':[15, 100, 150, -1]}" itemsPerPage="-1" /> -->
            </v-col>
        </v-row>
    </div>
</template>

<script>
	export default {
		props: [],
    data() {
        return {
            isLoading: false,

            HeArr: [],
            heSelect: 'C',
            NganhArr: [],
            DsDeTaiFilter: [],
            DsDeTaiRoot: [],
            DsGiangVien: [],
            DsGvCopy: [],
            DsNienKhoa: [],
            nganhSelect: '0',
            selectTrangThai: 1,
            tenNganhSelect: '',
            deTaiLabel: '',
            giangVienLabel: 'Danh sách giảng viên',
            giangVienSelect: null,
            GiangVienSearch: '',
            search: '',
            NienKhoaValue: null,

            headerDeTaiTable: [
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
                    text: 'Niên khóa',
                    value: 'Nien_Khoa',
                    width: 95,
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Tên đề tài',
                    value: 'Thesis_Name',
                    width: 300,
                },
                {
                    text: 'GVHD 1',
                    value: 'Thesises_Prof1',
                    width: 200,
                },
                {
                    text: 'GVHD 2',
                    value: 'Thesises_Prof2',
                    width: 200,
                },
                {
                    text: 'SQĐ Lập hội đồng',
                    value: 'SoQDLapHoiDong',
                    sortable: false,
                    align: 'center',
                    width: 140,
                },
                {
                    text: 'Ngày bảo vệ',
                    value: 'ThoiGianBaoVe',
                    sortable: false,
                    align: 'center',
                    width: 120,
                },
                {
                    text: 'Số QĐ giao đề tài',
                    value: 'ThesisConfirmNo',
                    width: 140,
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'File QĐ công nhận đề tài',
                    value: 'FileThesisConfirm',
                    sortable: false,
                    // align: "center",
                    el: 'div',
                    innerHTML: `<div class="mt-3">
																			<div v-if="item.FileThesisConfirm">
																				<v-chip label outlined class="mb-3" color="deep-purple accent-4">
																			<v-icon left>mdi-file-check-outline</v-icon>
																			<a :href="vueData.v_Set.urlReadFile + item.FileThesisConfirm" target="_blank"
																				style="color: deep-purple accent-4">File Quyết định</a>
																				</v-chip>
																			</div>
			
																			<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
																				Chưa upload file
																			</v-chip>
																		</div>
																		`,
                },
            ],

            headerGVTable: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Giảng viên',
                    value: 'Prof_Name',
                    width: 140,
                },
                {
                    text: 'Số lượng đề tài phụ trách',
                    value: 'NumberOfTopics',
                    sortable: false,
                    align: 'center',
                    width: 130,
                },
            ],

            filterSelect: [
                {
                    text: 'Chưa bảo vệ xong',
                    value: 1,
                },
                {
                    text: 'Đã bảo vệ xong',
                    value: 2,
                },
            ],
        }
    },
    mounted() {
        this.onLoadThongKeDeTai(0)
        this.getNienKhoa()
        this.getDsNganh()
    },
    computed: {},
    watch: {
        nganhSelect: function (val) {
            this.NienKhoaValue = '0'
            const nganh = this.NganhArr.find((item) => item.NganhID == val)
            this.tenNganhSelect = nganh?.TenNganh ?? null
            if (val == 0) {
                this.giangVienSelect = null
            }
            if (this.selectTrangThai === 1) {
                this.onLoadThongKeDeTai(val)
            } else {
                this.onLoadThongKeDeTaiDaHT(val)
            }
        },
        selectTrangThai: function (val) {
            this.NienKhoaValue = '0'
            if (val === 1) {
                this.giangVienSelect = '- Tất cả -'
                this.onLoadThongKeDeTai(this.nganhSelect)
            } else {
                this.giangVienSelect = '- Tất cả -'
                this.onLoadThongKeDeTaiDaHT(this.nganhSelect)
            }
        },
        NganhArr: function (val) {
            this.giangVienSelect = null
        },
    },
    methods: {
        async getDsNganh() {
            this.NganhArr = await getNganhCaoHocPromise({ hasAllOption: true });
        },
        filterDsDeTai() {
            let dataArr = this.DsDeTaiRoot

            if (this.giangVienSelect && this.giangVienSelect !== '- Tất cả -') {
                const gv = this.giangVienSelect.trim()

                dataArr = dataArr.filter((item) => {
                    const prof1 = item.Thesises_Prof1?.trim()
                    const prof2 = item.Thesises_Prof2?.trim()

                    return prof1 === gv || prof2 === gv
                })
            }

            if (this.NienKhoaValue !== '0' && this.NienKhoaValue !== 0 && this.NienKhoaValue !== null) {
                console.log('this.dataArr 2', dataArr)
                // console.log("this.DsDeTaiRootYYYYYY", this.DsDeTaiRoot)
                dataArr = dataArr.filter((item) => item.Nien_Khoa == this.NienKhoaValue)
            }

            console.log('this.dataArr 3', dataArr)
            this.DsDeTaiFilter = this.resetSTT(dataArr)
            this.deTaiLabel = ` <span>Danh sách Đề tài </span><span class="pink--text">(${this.DsDeTaiFilter.length})</span>`
        },
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
        resetSTT(arr) {
            return arr.map((item, index) => {
                return {
                    ...item,
                    STT: index + 1,
                }
            })
        },
        printExcel() {
            this.isLoading = true
            const dataArr = []
            console.log('this.DsDeTaiFilter', this.DsDeTaiFilter)
            this.DsDeTaiFilter.forEach((item) => {
                const obj = {
                    STT: item.STT,
                    MSHV: item.Student_ID,
                    HoHV: item.Ho_SV,
                    TenHV: item.Ten_SV,
                    LopID: item.Lop_ID,
                    NienKhoa: item.Nien_Khoa ? item.Nien_Khoa.replace('-', '.') : item.Nien_Khoa,
                    DeTai: item.Thesis_Name,
                    GVHD1: item.Thesises_Prof1,
                    GVHD2: item.Thesises_Prof2,
                    TenNganh: item.Ten_Nganh,
                    SQD_GiaoDeTai: item.ThesisConfirmNo,
                    ThoiGianQD: item.ThoiGianQD,
                    SoQDLapHD: item.SoQDLapHoiDong,
                    NgayBaoVe: item.ThoiGianBaoVe,
                }
                dataArr.push(obj)
            })
            console.log('dataArr', dataArr)
            const apiData = {
                Nganh: this.tenNganhSelect && this.tenNganhSelect !== '- Tất cả -' ? this.tenNganhSelect.toUpperCase() : 'TẤT CẢ',
                GiangVien: this.giangVienSelect && this.giangVienSelect !== '- Tất cả -' ? this.giangVienSelect : 'All',
                NganhID: this.nganhSelect,
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
            // https://gendocx.iotsoftvn.com
            // http://localhost:5244
            fetch('https://gendocx.iotsoftvn.com/api/generate-docx/thong-ke-gvhd', requestOptions)
                .then((response) => response.blob())
                .then((blob) => {
                    var url = window.URL.createObjectURL(blob)
                    var a = document.createElement('a')
                    a.href = url
                    a.download = `Thống kê ngành${this.tenNganhSelect && this.tenNganhSelect !== '- Tất cả -' ? ' ' + this.tenNganhSelect : ''}${this.giangVienSelect && this.giangVienSelect !== '- Tất cả -' ? ' - ' + this.giangVienSelect : ''}.xlsx`
                    document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
                    a.click()
                    a.remove() //afterwards we remove the element again
                    this.isLoading = false
                })
                .catch((error) => {
                    console.error(error)
                    this.isLoading = false
                })
        },
        onLoadThongKeDeTai(nganhID) {
            ajaxCALL(
                '/SDH_ThongKe_DeTai_ChuaHoanThanh',
                {
                    Nganh_ID: nganhID,
                },
                (res) => {
                    this.DsDeTaiFilter =
                        res.data[0]
                            .map((item, index) => {
                                return {
                                    ...item,
                                    STT: index + 1,
                                    HoTen: item.Ho_SV + ' ' + item.Ten_SV,
                                    ThoiGianQD:
                                        item.Decision_NgayQD && item.Decision_ThangQD && item.Decision_NamQD
                                            ? item.Decision_NgayQD + '/' + item.Decision_ThangQD + '/' + item.Decision_NamQD
                                            : '',
                                    ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe).format('DD/MM/YYYY') : item.ThoiGianBaoVe,
                                    HoTenMaSV: item.Ho_SV + ' ' +  item.Ten_SV + ' ' + item.Student_ID + ' ' + item.Lop_ID
                                }
                            })
                            .filter((item, index, self) => {
                                return index === self.findIndex((i) => i.Student_ID === item.Student_ID)
                            }) ?? []
                    this.DsDeTaiRoot =
                        res.data[0]
                            .map((item, index) => {
                                return {
                                    ...item,
                                    STT: index + 1,
                                    HoTen: item.Ho_SV + ' ' + item.Ten_SV,
                                    ThoiGianQD:
                                        item.Decision_NgayQD && item.Decision_ThangQD && item.Decision_NamQD
                                            ? item.Decision_NgayQD + '/' + item.Decision_ThangQD + '/' + item.Decision_NamQD
                                            : '',
                                    ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe).format('DD/MM/YYYY') : item.ThoiGianBaoVe,
                                }
                            })
                            .filter((item, index, self) => {
                                return index === self.findIndex((i) => i.Student_ID === item.Student_ID)
                            }) ?? []
                    this.DsGiangVien =
                        res.data[1].map((item, index) => {
                            return {
                                ...item,
                                STT: index + 1,
                            }
                        }) ?? []

                    this.DsGvCopy = JSON.parse(JSON.stringify(this.DsGiangVien))
                    const dataObj = {
                        Prof_Name: '- Tất cả -',
                    }
                    this.DsGiangVien.unshift(dataObj)

                    this.deTaiLabel = ` <span>Danh sách Đề tài </span><span class="pink--text">(${this.DsDeTaiFilter.length})</span>`
                    this.giangVienLabel = `<span>Danh sách Giảng viên </span><span class="pink--text">(${this.DsGvCopy.length})</span>`

                    console.log('this.DsDeTaiFilter', this.DsDeTaiFilter)
                    console.log('this.DsGiangVien', this.DsGiangVien)
                },
                (error) => {
                    Vue.$toast.error(`Fail to load danh sach thong ke de tai`, { position: 'top' })
                    console.log('Fail to load danh sach thong ke de tai', error)
                },
            )
        },
        onLoadThongKeDeTaiDaHT(nganhID) {
            ajaxCALL(
                '/SDH_ThongKe_DeTai_DaHoanThanh',
                {
                    Nganh_ID: nganhID,
                },
                (res) => {
                    this.DsDeTaiFilter =
                        res.data[0]
                            .map((item, index) => {
                                return {
                                    ...item,
                                    STT: index + 1,
                                    HoTen: item.Ho_SV + ' ' + item.Ten_SV,
                                    ThoiGianQD:
                                        item.Decision_NgayQD && item.Decision_ThangQD && item.Decision_NamQD
                                            ? item.Decision_NgayQD + '/' + item.Decision_ThangQD + '/' + item.Decision_NamQD
                                            : '',
                                    ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe).format('DD/MM/YYYY') : item.ThoiGianBaoVe,
                                }
                            })
                            .filter((item, index, self) => {
                                return index === self.findIndex((i) => i.Student_ID === item.Student_ID)
                            }) ?? []

                    this.DsDeTaiRoot =
                        res.data[0]
                            .map((item, index) => {
                                return {
                                    ...item,
                                    STT: index + 1,
                                    HoTen: item.Ho_SV + ' ' + item.Ten_SV,
                                    ThoiGianQD:
                                        item.Decision_NgayQD && item.Decision_ThangQD && item.Decision_NamQD
                                            ? item.Decision_NgayQD + '/' + item.Decision_ThangQD + '/' + item.Decision_NamQD
                                            : '',
                                    ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe).format('DD/MM/YYYY') : item.ThoiGianBaoVe,
                                }
                            })
                            .filter((item, index, self) => {
                                return index === self.findIndex((i) => i.Student_ID === item.Student_ID)
                            }) ?? []

                    this.DsGiangVien =
                        res.data[1].map((item, index) => {
                            return {
                                ...item,
                                STT: index + 1,
                            }
                        }) ?? []

                    this.DsGvCopy = JSON.parse(JSON.stringify(this.DsGiangVien))
                    const dataObj = {
                        Prof_Name: '- Tất cả -',
                    }
                    this.DsGiangVien.unshift(dataObj)

                    this.deTaiLabel = ` <span>Danh sách Đề tài </span><span class="pink--text">(${this.DsDeTaiFilter.length})</span>`
                    this.giangVienLabel = `<span>Danh sách Giảng viên </span><span class="pink--text">(${this.DsGvCopy.length})</span>`

                    console.log('this.DsDeTaiFilter', this.DsDeTaiFilter)
                    console.log('this.DsGiangVien', this.DsGiangVien)
                },
                (error) => {
                    Vue.$toast.error(`Fail to load danh sach thong ke de tai`, { position: 'top' })
                    console.log('Fail to load danh sach thong ke de tai', error)
                },
            )
        },
    },
	}
</script>