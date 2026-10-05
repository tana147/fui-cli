<template>
	<div>
        <!-- Dialog xem chi tiết -->
        <v-dialog v-model="vueData.isDialog" persistent eager transition="dialog-bottom-transition" max-width="900px">
            <v-card>
                <c-toolbar @onClose="closeDialog">
                    <template v-slot:title>
                        <p class="title mb-0 primary--text">
                            <span class="primary--text"> {{ vueData.taskRegistData.Student_Name }}</span> {{ vueData.taskRegistData.Class_ID }}
                            <span class="amber--text"> [{{ vueData.taskRegistData.Student_ID }}]</span>
                            <!-- Phân công giảng viên chính thức -->
                        </p>
                    </template>
                </c-toolbar>
                <v-card-text>
                    <v-row class="mt-1">
                        <v-col class="pt-0 pb-0" cols="12">
                            <p class="pb-0 mb-0 primary--text text-h6">Tên đề tài</p>
                            <p class="txtSize pt-0">{{ vueData.taskRegistData.ThesisNameSuggest }}</p>
                            <!-- <v-text-field v-model="vueData.taskRegistData.ThesisNameSuggest" outlined color="success"
								label="Tên đề tài" dense hide-details disabled /> -->
                        </v-col>
                        <v-col class="pt-0 pb-0" cols="4">
                            <p class="primary--text text-h6 mb-0">GVHD học viên đề xuất</p>
                            <p class="txtSize mb-0">{{ vueData.taskRegistData.ThesisesProfSuggest1 }}</p>
                            <!-- <v-text-field v-model="vueData.taskRegistData.ThesisesProfSuggest1" outlined color="success"
								label="GVHD học viên đề xuất" dense hide-details disabled /> -->
                        </v-col>
                        <v-col class="pt-0 pb-0" cols="4">
                            <p class="primary--text text-h6 mb-0">Ngành</p>
                            <p class="txtSize mb-0">{{ vueData.taskRegistData.Student_Major }}</p>
                            <!-- <v-text-field v-model="vueData.taskRegistData.Student_Major" outlined color="success"
								label="Ngành" dense hide-details disabled /> -->
                        </v-col>
                        <v-col class="pt-0 pb-0" cols="2">
                            <p class="primary--text text-h6 mb-0">Niên khóa</p>
                            <p class="txtSize mb-0">{{ vueData.taskRegistData.Student_Year }}</p>
                            <!-- <v-text-field v-model="vueData.taskRegistData.Student_Year" outlined color="success"
								label="Niên khóa" dense hide-details disabled /> -->
                        </v-col>
                    </v-row>
                    <v-row>
                        <v-col class="pb-0 pt-0 mt-3">
                            <div class="d-flex align-center">
                                <p class="text-h6 primary--text">GVHD đã ký tên đồng ý:</p>
                                <!-- <v-checkbox class="ml-2 mb-1" v-model="vueData.taskRegistData.isGVHDSigned" disabled /> -->
                                <v-icon class="mb-4 ml-3" v-if="vueData.taskRegistData.isGVHDSigned" color="success">mdi-checkbox-marked</v-icon>
                                <v-icon class="mb-4 ml-3" v-else color="success">mdi-checkbox-blank-outline</v-icon>
                            </div>
                        </v-col>
                    </v-row>
                    <p class="mb-3 text-h6 primary--text">Cập nhật Giảng viên hướng dẫn chính thức</p>
                    <v-row>
                        <v-col cols="12">
                            <v-text-field
                                v-model="vueData.taskRegistData.ThesisesProf1"
                                outlined
                                placeholder="Giảng viên hướng dẫn chính"
                                label="Giảng viên hướng dẫn chính"
                                dense
                                hide-details
                            />
                        </v-col>
                        <v-col cols="12">
                            <v-text-field
                                v-model="vueData.taskRegistData.ThesisesProf2"
                                outlined
                                placeholder="Giảng viên hướng dẫn phụ (nếu có)"
                                label="Giảng viên hướng dẫn phụ (nếu có)"
                                dense
                                hide-details
                            />
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn @click="updProf(vueData.taskRegistData)" text color="primary">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- table dữ liệu -->
        <v-row>
            <v-col cols="2">
                <v-select v-model="nganhHocValue" :items="heArr" outlined dense hide-details label="Ngành" item-text="TenNganh" item-value="NganhID" />
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
            <v-col cols="2">
                <v-select class="statusSelect" v-model="switchData" :items="statusList" item-text="text" item-value="value" outlined hide-details dense label="Trạng thái" />
            </v-col>
            <v-col>
                <div class="d-flex justify-end">
                    <v-btn :loading="isLoading" @click="onPrintExcel" class="mb-3" color="success"><v-icon dense smal left>mdi-microsoft-excel</v-icon>Xuất file excel</v-btn>
                </div>
            </v-col>
            <v-col>
                <f-table
                    class="table-frozen-cols"
                    :headers="headerTable"
                    :items="DsTaskRegisted"
                    :label="labelTable"
                    showSearch="true"
                    :excel="false"
                    :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
                    itemsPerPage="-1"
                    dense="true"
                />
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
            DsTaskRegisted: [],
            DSTaskOriginal: [],
            NganhHoc: [],
            DsNienKhoa: [],
            nganhHocValue: '0',
            switchData: true,
            labelTable: 'Danh sách học viên đã đăng ký đề tài (0)',
            flowStatus: 'P',
            taskLenght: 0,
            NienKhoaValue: 0,
            heArr: [],

            statusList: [
                { value: true, text: 'Đã đăng ký đề tài' },
                { value: false, text: 'Chưa đăng ký đề tài' },
            ],

            headerTable: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Học viên',
                    value: 'Student_ID',
                    // el: "div",
                    sortable: false,
                    el: 'span',
                    innerHTML: "<span class='primary--text'><b>{{item.Student_Name}}</b></span><br /><b>{{item.Student_ID}}</b><span class='amber--text'> [{{item.Class_ID}}]</span>",
                    width: 180,
                },
                {
                    text: 'Ngành',
                    value: 'Student_Major',
                    sortable: false,
                    width: '170',
                },
                {
                    text: 'Niên khóa',
                    value: 'Student_Year',
                    align: 'center',
                    sortable: false,
                },
                {
                    text: 'SĐT / Email',
                    value: 'SoDienThoai',
                    sortable: false,
                    el: 'span',
                    innerHTML: '<span>{{item.SoDienThoai}}</span><br /><span>{{item.Email}}</span>',
                },
                {
                    text: 'Tên đề tài đăng ký (dự kiến)',
                    value: 'ThesisNameSuggest',
                    sortable: false,
                    width: 600,
                },
                {
                    text: 'GVHD đề xuất',
                    value: 'ThesisesProfSuggest1',
                    el: 'span',
                    sortable: false,
                    innerHTML: `{{item.ThesisesProfSuggest1}}<span class='success--text' v-if='item.isGVHDSigned'><br/><v-icon dense color='success' >mdi-checkbox-marked</v-icon> Đã ký tên đồng ý<span>`,
                    width: 180,
                },
                {
                    text: 'GV phân công chính',
                    value: 'ThesisesProf1',
                    width: 180,
                },
                {
                    text: 'GV phân công phụ',
                    value: 'ThesisesProf2',
                    width: 180,
                },
                {
                    text: 'File đăng ký',
                    value: 'DeTai',
                    el: 'div',
                    sortable: false,
                    align: 'center',
                    innerHTML: `<v-btn v-if="item.fileDKDeTai !== null && item.fileDKDeTai !== ''" class="pl-0 pr-0" text color="primary" @click="window.open(vueData.v_Set.urlReadFile + item.fileDKDeTai)">Tải file</v-btn>`,
                },
                {
                    text: 'Ngày đăng ký',
                    value: 'NgayDangKy',
                    align: 'center',
                    sortable: false,
                    width: 150,
                },
                {
                    text: 'Phân công GV',
                    value: 'updateBtn',
                    el: 'div',
                    sortable: false,
                    align: 'center',
                    innerHTML: `<v-btn v-if="vueData.flowStatus === 'P'" @click="onOpenDialog(item)" text color="success"><v-icon class="updateCustom" dense>mdi-square-edit-outline</v-icon></v-btn>`,
                },
            ],
        }
    },
    mounted() {
        this.onLoadTaskRegist()
        this.getNienKhoa()
        this.getDsNganh('C')
    },
    computed: {},
    watch: {
        nganhHocValue: function (val) {
            this.NienKhoaValue = this.DsNienKhoa[0]?.NienKhoa
            if (val !== null && val !== '') {
                this.onLoadTaskRegist()
            }
        },
        switchData: function (val) {
            console.log('val data', val)
            this.NienKhoaValue = this.DsNienKhoa[0]?.NienKhoa
            if (val) {
                vueData.flowStatus = 'P'
                this.flowStatus = 'P'
                this.onLoadTaskRegist()
            } else {
                vueData.flowStatus = 'W'
                this.flowStatus = 'W'
                this.onLoadTaskRegist()
            }
        },
        NienKhoaValue: function (val) {
            if (val === '0') {
                this.DsTaskRegisted = this.DSTaskOriginal
                this.labelTable = this.labelContent()
            } else {
                this.DsTaskRegisted = this.resetSTT(
                    this.DSTaskOriginal.filter((item) => {
                        return item.Student_Year === val
                    }),
                )
                this.labelTable = this.labelContent()
            }
        },
        type: function (val) {
            if (val) {
                this.getDsNganh(val)
            }
        },
    },
    methods: {
        async getDsNganh() {
            this.heArr = await getNganhCaoHocPromise({ hasAllOption: true });
        },
        nganhName(nganhid) {
            if (nganhid == 0) {
                return nganhid
            }
            const nganh = this.heArr.find((item) => item.NganhID == nganhid)
            return nganh ? nganh.TenNganh : ''
        },
        onPrintExcel() {
            this.isLoading = true
            const dataArr = []
            this.DsTaskRegisted.forEach((item, index) => {
                const parts = item.Student_Name.trim().split(' ')
                const LastName = parts.pop() // Lấy phần tử cuối cùng là Tên
                const FirstName = parts.join(' ')

                let NienkhoaSplit = item.Student_Year.split('-')

                let khoaFormat

                // Kiểm tra xem phần tử cuối cùng có phải là số hay không
                if (NienkhoaSplit.length > 1) {
                    const lastPart = NienkhoaSplit[NienkhoaSplit.length - 1]
                    khoaFormat = `${NienkhoaSplit[0]}.${isNaN(lastPart) ? lastPart : parseInt(lastPart)}`
                } else {
                    khoaFormat = item.Student_Year.replace('-', '.')
                }

                const data = {
                    STT: index + 1,
                    NienKhoa: khoaFormat ?? '',
                    LopID: item.Class_ID ?? '',
                    MSHV: item.Student_ID ?? '',
                    HoHV: FirstName ?? '',
                    TenHV: LastName ?? '',
                    NgaySinh: item.NgaySinh ?? '',
                    DienThoai: item.SoDienThoai ?? '',
                    Email: item.Email ?? '',
                    TenDeTai: item.ThesisNameSuggest ?? '',
                    GVHDDeNghi: item.ThesisesProfSuggest1 ?? '',
                    GVHDDongY: item.isGVHDSigned ?? '',
                    NgayDangKy: item.NgayDangKy ?? '',
                }
                dataArr.push(data)
            })

            const apiData = {
                Nganh: this.nganhHocValue == 0 ? '' : this.nganhName(this.nganhHocValue)?.toUpperCase(),
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
            fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/thong-ke-dang-ky-de-tai', requestOptions)
                .then((response) => response.blob())
                .then((blob) => {
                    var url = window.URL.createObjectURL(blob)
                    var a = document.createElement('a')
                    a.href = url
                    a.download = `Danh sách đăng ký đề tài ${this.nganhHocValue == 0 ? '' : this.nganhName(this.nganhHocValue)}.xlsx`
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
        labelContent() {
            // 'P'
            if (this.flowStatus === 'P') {
                return 'Danh sách học viên đã đăng ký đề tài (' + this.DsTaskRegisted.length + ')'
            } else {
                return 'Danh sách học viên chưa đăng ký đề tài (' + this.DsTaskRegisted.length + ')'
            }
        },
        resetSTT(arr) {
            return arr.map((item, index) => {
                return {
                    ...item,
                    STT: index + 1,
                }
            })
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
        onLoadTaskRegist() {
            if (this.nganhHocValue !== null && this.nganhHocValue !== '') {
                ajaxCALL(
                    '/SDH_Get_TaskRegisterTheise',
                    {
                        Nganh_ID: this.nganhHocValue,
                        Process_Action: 1,
                        Flow_Status: this.flowStatus,
                    },
                    (res) => {
                        this.DsTaskRegisted = res.data.map((item) => {
                            return {
                                ...item,
                                isGVHDSigned: String(item.isGVHDSigned).toLowerCase() === 'true',
                            }
                        })
                        this.DSTaskOriginal = res.data.map((item) => {
                            return {
                                ...item,
                                isGVHDSigned: String(item.isGVHDSigned).toLowerCase() === 'true',
                            }
                        })
                        this.labelTable = this.labelContent()
                        console.log('this.DsTaskRegisted', this.DsTaskRegisted)
                    },
                    (error) => {
                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        console.log('Fail to load task regist', error)
                    },
                )
            }
        },
        closeDialog() {
            vueData.isDialog = false
            vueData.thesisesProf1 = null
            vueData.thesisesProf2 = null
        },
    },
	}
</script>