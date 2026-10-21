<template>
	<div>
        <div class="mb-3 d-flex align-center">
            <v-row dense>
                <v-col cols="2">
                    <v-select v-model="major" :items="nganhArr" outlined dense hide-details label="Lọc theo ngành" item-text="TenNganh" item-value="NganhID" />
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
                    <v-select v-model="filterData" :items="filterSelectArr" outlined dense hide-details label="Lọc tiến độ" item-text="text" item-value="value" />
                </v-col>
                <v-col cols="2">
                    <v-select v-model="switchData" :items="loaiThSList" item-text="text" item-value="value" label="Loại thạc sĩ" dense hide-details outlined />
                </v-col>
                <v-col class="d-flex justify-end align-center">
                    <v-btn :loading="isExportAllLoading" @click="printAllMajor" color="primary" :disabled="filterData == 0 || filterData == 2"
                        ><v-icon left>mdi-microsoft-excel</v-icon>Xuất excel tất cả ngành</v-btn
                    >
                    <v-btn
                        :loading="isExportMajorLoading"
                        class="ml-3"
                        v-if="(filterData === 4 && major != 0) || (DsTask.length > 0 && major && major != 0)"
                        @click="onPrintExcel"
                        color="success"
                        :disabled="filterData == 0 || filterData == 2"
                        ><v-icon left>mdi-microsoft-excel</v-icon>Xuất excel ngành {{ filterData === 4 && AllTasks.length > 0 ? AllTasks[0]?.TenNganh : DsTask[0]?.TenNganh }}</v-btn
                    >
                </v-col>
            </v-row>
        </div>
        <f-table
            :label="labelTable"
            :headers="switchData ? tableHeader_UD : tableHeader"
            :items="filterData == 0 || filterData == 4 ? AllTasks : filterData == 1 ? DsTask : filterData == 2 ? DsNotComplete : CompleteStatusTask"
            show-search="true"
            :dense="true"
            :excel="false"
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
            itemsPerPage="-1"
        />

        <div class="mt-2" v-if="fileData !== null">
            <v-card>
                <v-card-title class="primary--text">
                    Danh sách giảng viên
                    <v-spacer></v-spacer>
                    <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search" single-line hide-details />
                </v-card-title>

                <v-data-table :headers="GVInfoHeader" :items="GVInfoArr" dense :search="search" items-per-page="-1" :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
                    <template v-slot:item.stt="{ item, index }">
                        {{ index + 1 }}
                    </template>
                </v-data-table>
            </v-card>
        </div>
    </div>
</template>

<script>
	export default {
		props: [],
    data() {
        return {
            isExportAllLoading: false,
            isExportMajorLoading: false,

            NienKhoaValue: null,
            major: '0',
            DsNienKhoa: [],
            nganhArr: [],
            FILE_UPLOAD: null,
            File_ID: null,
            File_Name: null,
            File_Url: null,
            fileDataHeader: null,
            fileData: null,
            GVInfoArr: [],
            CompleteStatusTask: [],
            DsTask: [],
            AllTaskComplete: [],
            DsNotComplete: [],
            AllTasks: [],

            DsTaskOrigin: [],
            DsNotCompleteOrigin: [],
            CompleteStatusTaskOrigin: [],
            AllTasksOrigin: [],
            AllTaskCompleteOrigin: [],

            search: '',
            switchData: false,
            filterData: 1,
            labelTable: '',

            loaiThSList: [
                {
                    text: 'Thạc sĩ ứng dụng',
                    value: true,
                },
                {
                    text: 'Thạc sĩ nghiên cứu',
                    value: false,
                },
            ],

            filterSelectArr: [
                {
                    text: 'Tất cả học viên',
                    value: 0,
                },
                {
                    text: 'Đã nộp đủ file và tên đề tài',
                    value: 1,
                },
                {
                    text: 'Chưa nộp đủ file và tên đề tài',
                    value: 2,
                },
                {
                    text: 'Đã nộp đủ file và đã được duyệt',
                    value: 3,
                },
                {
                    text: 'Chưa đăng ký bảo vệ',
                    value: 4,
                },
            ],

            fileRules: {
                max_file_size: '100mb',
                mime_types: [
                    {
                        title: 'Excel files',
                        extensions: 'xlsx,xls',
                    },
                ],
            },

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
                    value: 'Student_ID',
                    el: 'div',
                    width: 190,
                    innerHTML: `<span class='primary--text'><b>{{item.Student_Name}}</b></span><br /><b>{{item.Student_ID}}</b><span class='amber--text'>																																[{{item.Class_ID}}]</span>`,
                },
                {
                    text: 'Ngành',
                    value: 'TenNganh',
                    width: 170,
                },
                {
                    text: 'Niên khóa',
                    value: 'NienKhoa',
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Đề tài học viên đăng ký bảo vệ',
                    value: 'ThesisName',
                    width: 450,
                },
                {
                    text: 'GVHD 1',
                    value: 'ThesisesProf1',
                    width: 170,
                },
                {
                    text: 'GVHD 2',
                    value: 'ThesisesProf2',
                    width: 170,
                },
                {
                    text: 'Lý lịch khoa học',
                    value: 'lyLich',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_LyLich_ID !== null && item.File_LyLich_ID !== ''">
											<v-chip label outlined class="mb-3" color="deep-purple accent-4">
											<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_LyLich_ID" target="_blank"
											style="color: deep-purple accent-4"><v-icon>mdi-download</v-icon></a>
											</v-chip>
										</div>
																													
										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
									</div>`,
                },
                {
                    text: 'Phiếu đăng ký bảo vệ luận văn',
                    value: 'Dky',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_DangKy_ID !== null && item.File_DangKy_ID !== ''">
											<v-chip label outlined class="mb-3" color="deep-purple accent-4">
											<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_DangKy_ID" target="_blank"
											style="color: deep-purple accent-4"><v-icon>mdi-download</v-icon></a>
											</v-chip>
										</div>
																	
										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
										</div>`,
                },
                {
                    text: 'Nhận xét GVHD 1',
                    value: 'nXetGvhdChinh',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_NhanXetGVHD1_ID !== null && item.File_NhanXetGVHD1_ID !== ''">
											<v-chip label outlined class="mb-3" color="deep-purple accent-4">
											<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_NhanXetGVHD1_ID" target="_blank"
												style="color: deep-purple accent-4"><v-icon>mdi-download</v-icon></a>
											</v-chip>
										</div>
																		
										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
									</div>`,
                },
                {
                    text: 'Nhận xét GVHD 2',
                    value: 'nXetGvhdPhu',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_NhanXetGVHD2_ID !== null && item.File_NhanXetGVHD2_ID !== ''">
											<v-chip label outlined class="mb-3" color="deep-purple accent-4">
											<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_NhanXetGVHD2_ID" target="_blank"
											style="color: deep-purple accent-4"><v-icon>mdi-download</v-icon></a>
											</v-chip>
										</div>
																		
										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
									</div>`,
                },
                {
                    text: 'Luận văn PDF',
                    value: 'luanVanPDF',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_LuanVanPDF_ID !== null && item.File_LuanVanPDF_ID !== ''">
											<v-chip label outlined class="mb-3" color="deep-purple accent-4">
												<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_LuanVanPDF_ID" target="_blank"
													style="color: deep-purple accent-4"><v-icon>mdi-download</v-icon></a>
											</v-chip>
										</div>
									
										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
									</div>`,
                },
                {
                    text: 'Luận văn WORD',
                    value: 'luanVanWord',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_LuanVanWORD_ID !== null && item.File_LuanVanWORD_ID !== ''">
										<v-chip label outlined class="mb-3" color="deep-purple accent-4">
										<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_LuanVanWORD_ID" target="_blank"
										style="color: deep-purple accent-4"><v-icon>mdi-download</v-icon></a>
										</v-chip>
									</div>
								
									<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
										Chưa upload file
									</v-chip>
								</div>`,
                },
            ],

            tableHeader_UD: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Học viên',
                    value: 'Student_ID',
                    el: 'div',
                    width: 190,
                    innerHTML: `<span class='primary--text'><b>{{item.Student_Name}}</b></span><br /><b>{{item.Student_ID}}</b><span class='amber--text'>[{{item.Class_ID}}]</span>`,
                },
                {
                    text: 'Ngành',
                    value: 'TenNganh',
                    width: 170,
                },
                {
                    text: 'Niên khóa',
                    value: 'NienKhoa',
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Đề tài học viên đăng ký bảo vệ',
                    value: 'ThesisName',
                    width: 450,
                },
                {
                    text: 'GVHD 1',
                    value: 'ThesisesProf1',
                    width: 170,
                },
                {
                    text: 'GVHD 2',
                    value: 'ThesisesProf2',
                    width: 170,
                },
                {
                    text: 'Lý lịch khoa học',
                    value: 'lyLich',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_LyLich_ID !== null && item.File_LyLich_ID !== ''">
											<v-chip label outlined class="mb-3" color="deep-purple accent-4">
											<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_LyLich_ID" target="_blank"
											style="color: deep-purple accent-4"><v-icon>mdi-monitor-arrow-down</v-icon></a>
											</v-chip>
										</div>
																													
										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
									</div>`,
                },
                {
                    text: 'Phiếu đăng ký bảo vệ luận văn',
                    value: 'Dky',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_DangKy_ID !== null && item.File_DangKy_ID !== ''">
											<v-chip label outlined class="mb-3" color="deep-purple accent-4">
											<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_DangKy_ID" target="_blank"
											style="color: deep-purple accent-4"><v-icon>mdi-monitor-arrow-down</v-icon></a>
											</v-chip>
										</div>
																	
										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
										</div>`,
                },
                {
                    text: 'Nhận xét GVHD',
                    value: 'nXetGvhdChinh',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_NhanXetGVHD1_ID !== null && item.File_NhanXetGVHD1_ID !== ''">
											<v-chip label outlined class="mb-3" color="deep-purple accent-4">
											<v-icon left>mdi-file-check-outline</v-icon>
											<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_NhanXetGVHD1_ID" target="_blank"
												style="color: deep-purple accent-4"><v-icon>mdi-monitor-arrow-down</v-icon></a>
											</v-chip>
										</div>
																		
										<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
											Chưa upload file
										</v-chip>
									</div>`,
                },
                {
                    text: 'File đồ án',
                    value: 'luanVanWord',
                    sortable: false,
                    align: 'center',
                    el: 'div',
                    innerHTML: `<div class="mt-3">
										<div v-if="item.File_LuanVanWORD_ID !== null && item.File_LuanVanWORD_ID !== ''">
										<v-chip label outlined class="mb-3" color="deep-purple accent-4">
										<v-icon left>mdi-file-check-outline</v-icon>
										<a :href="vueData.v_Set.urlReadFile + '/FileData/' + item.File_LuanVanWORD_ID" target="_blank"
										style="color: deep-purple accent-4"><v-icon>mdi-monitor-arrow-down</v-icon></a>
										</v-chip>
									</div>
								
									<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
										Chưa upload file
									</v-chip>
								</div>`,
                },
            ],
        }
    },
    mounted() {
        this.getDsNganh()
        this.getTask(0)
        this.getNienKhoa()
        const fixedCols = 2
        let inlineStyle = `th:nth-child(-n+${fixedCols}), td:nth-child(-n+${fixedCols}) {
									position: sticky !important;
									left: 0 !important;
									top: 0 !important;
									background: #ffffff !important;
									z-index: 1;
								}
								
								th:nth-child(-n+${fixedCols}) {
									z-index: 3 !important;
								}`
        const widths = []
        for (let i = 0; i < fixedCols; i++) {
            if (!this.tableHeader[i].width) {
                this.tableHeader[i].width = '150px'
            }
            if (i > 0) {
                widths.push(this.tableHeader[i - 1].width + 'px')
            }
            inlineStyle += `th:nth-child(${i + 1}), td:nth-child(${i + 1}) {
									left: calc(${widths.join(' + ')}) !important;
								}`
        }
        const style = document.createElement('style')
        style.innerHTML = inlineStyle
        document.head.appendChild(style)
    },
    computed: {
        switchLabel: function () {
            return this.switchData ? 'Thạc sĩ ứng dụng' : 'Thạc sĩ nghiên cứu'
        },
    },
    watch: {
        major: function (val) {
            let nganhID = parseInt(val)
            this.NienKhoaValue = this.DsNienKhoa[0]?.NienKhoa
            if (nganhID !== null) {
                console.log('val', val)
                this.getTask(nganhID)
            }
        },
        FILE_UPLOAD: function (val) {
            if (val) {
                console.log('val', val.Files[0].FILE_NAME)
                this.File_ID = val.Files[0].FILE_ID
                this.File_Name = val.Files[0].FILE_NAME
                this.File_Url = val.Files[0].FILE_URL
                this.loadExcelGVInfo()
            }
        },
        switchData: function () {
            let nganhID = parseInt(this.major)
            this.NienKhoaValue = this.DsNienKhoa[0]?.NienKhoa
            if (nganhID !== null) {
                this.getTask(nganhID)
            }
        },
        filterData: function (newVal, oldVal) {
            this.NienKhoaValue = this.DsNienKhoa[0]?.NienKhoa
            this.labelTable = this.labelContent()
            if (newVal === 4) {
                this.getTask(parseInt(this.major))
            }
            if (oldVal === 4 && newVal !== 4) {
                this.getTask(parseInt(this.major))
            }
        },
        NienKhoaValue: function (val) {
            // "filterData == 0 || filterData == 4 ? AllTasks : filterData == 1 ? DsTask : filterData == 2 ? DsNotComplete : CompleteStatusTask"
            if (this.filterData == 0 || this.filterData == 4) {
                this.AllTasks = val === '0' ? this.AllTasksOrigin : this.resetSTT(this.AllTasksOrigin.filter((item) => item.NienKhoa == val))
                this.labelTable = this.labelContent()
            } else if (this.filterData == 1) {
                this.DsTask = val === '0' ? this.DsTaskOrigin : this.resetSTT(this.DsTaskOrigin.filter((item) => item.NienKhoa == val))
                this.labelTable = this.labelContent()
            } else if (this.filterData == 2) {
                this.DsNotComplete = val === '0' ? this.DsNotCompleteOrigin : this.resetSTT(this.DsNotCompleteOrigin.filter((item) => item.NienKhoa == val))
                this.labelTable = this.labelContent()
            } else {
                this.CompleteStatusTask = val === '0' ? this.CompleteStatusTaskOrigin : this.resetSTT(this.CompleteStatusTaskOrigin.filter((item) => item.NienKhoa == val))
                this.labelTable = this.labelContent()
            }
        },
    },
    methods: {
        labelContent() {
            return `
	                    <span>Danh sách học viên đăng ký bảo vệ luận văn/đồ án:</span>
	                    <span class="pink--text">Tất cả (${
                            this.filterData == 0 || this.filterData == 4
                                ? this.AllTasks.length
                                : this.filterData == 1
                                  ? this.DsTask.length
                                  : this.filterData == 2
                                    ? this.DsNotComplete.length
                                    : this.CompleteStatusTask.length
                        })</span>
	                    ${this.filterData === 0 ? `<span class="success--text">Đã nộp đủ (${this.DsTask.length})</span>` : ''}
	                    ${this.filterData === 0 ? `<span class="warning--text">Chưa nộp đủ (${this.DsNotComplete.length})</span>` : ''}
	                    ${this.filterData === 0 ? `<span class="Teal--text">Đã nộp đủ và đã được duyệt (${this.CompleteStatusTask.length})</span>` : ''}`
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
        onPrintExcel() {
            this.isExportMajorLoading = true
            if ((this.filterData === 4 && this.AllTasks.length > 0 && this.major) || this.DsTask.length > 0) {
                let dataArr = []

                switch (this.filterData) {
                    case 1:
                        dataArr = this.DsTask
                        break
                    case 3:
                        dataArr = this.CompleteStatusTask
                        break
                    case 4:
                        dataArr = this.AllTasks
                        break
                }

                let RefindData = [
                    {
                        Nganh: this.filterData === 4 ? this.AllTasks[0].TenNganh.toUpperCase() : this.DsTask[0].TenNganh.toUpperCase(),
                        SoLuong: dataArr.length,
                        NganhID: this.major,
                        ProcessID: this.switchData ? 4 : 1,
                        DanhSach: [],
                    },
                ]
                let dataObj = {}

                dataArr.forEach((item, index) => {
                    dataObj = {
                        STT: index + 1,
                        MSHV: parseInt(item.Student_ID),
                        LopID: item.Class_ID,
                        Ho: this.firstName(item.Student_Name),
                        Ten: this.lastName(item.Student_Name),
                        DeTai: item.ThesisName ?? '',
                        GVHD1: item.ThesisesProf1 ?? '',
                        GVHD2: item.ThesisesProf2 ?? '',
                    }

                    RefindData[0].DanhSach.push(dataObj)
                })

                this.genXMlApi(RefindData[0], this.filterData === 4 ? this.AllTasks[0].TenNganh : this.DsTask[0].TenNganh)

                console.log('refind data', RefindData)
                this.isExportMajorLoading = false
            } else {
                this.isExportMajorLoading = false
                Vue.$toast.error(`Danh sách trống`, { position: 'top' })
            }
        },
        printAllMajor() {
            this.isExportAllLoading = true
            if (this.AllTaskComplete.length > 0) {
                let tempGroups = {} // Đối tượng tạm để lưu trữ các nhóm theo Nganh_ID

                this.AllTaskComplete.forEach((item, index) => {
                    let nganhID = item.Nganh_ID
                    if (!tempGroups[nganhID]) {
                        // Nếu nhóm với Nganh_ID này chưa tồn tại, tạo mới
                        tempGroups[nganhID] = {
                            Nganh: item.TenNganh.toUpperCase(),
                            SoLuong: 0,
                            NganhID: this.major,
                            ProcessID: item.Process_ID,
                            DanhSach: [],
                        }
                    }

                    let dataObj = {
                        STT: tempGroups[nganhID].DanhSach.length + 1,
                        MSHV: parseInt(item.Student_ID),
                        LopID: item.Class_ID,
                        Ho: this.firstName(item.Student_Name),
                        Ten: this.lastName(item.Student_Name),
                        DeTai: item.ThesisName ?? '',
                        GVHD1: item.ThesisesProf1 ?? '',
                        GVHD2: item.ThesisesProf2 ?? '',
                    }

                    tempGroups[nganhID].DanhSach.push(dataObj)
                })
                console.log('tempGroups', tempGroups)

                // Chuyển các nhóm từ đối tượng tạm vào RefindData
                let RefindData = []

                for (let nganhID in tempGroups) {
                    if (tempGroups.hasOwnProperty(nganhID)) {
                        tempGroups[nganhID].SoLuong = tempGroups[nganhID].DanhSach.length // Cập nhật số lượng
                        RefindData.push(tempGroups[nganhID]) // Thêm nhóm vào RefindData
                    }
                }

                if (RefindData.length > 0) {
                    RefindData.forEach((item) => {
                        this.genXMlApi(item, item.Nganh)
                    })
                    this.isExportAllLoading = false
                } else {
                    this.isExportAllLoading = false
                    Vue.$toast.error(`Nhóm danh sách học viên thất bại`, { position: 'top' })
                }

                console.log('RefindData', RefindData)
            } else {
                this.isExportAllLoading = false
                Vue.$toast.error(`Danh sách trống`, { position: 'top' })
            }
        },
        genXMlApi(dataArr, tenNganh) {
            dataArr.DanhSach = this.resetSTT(dataArr.DanhSach.sort((a, b) => a.Ten.localeCompare(b.Ten)))
            const myHeaders = new Headers()
            myHeaders.append('Content-Type', 'application/json')
            const requestOptions = {
                method: 'POST',
                headers: myHeaders,
                // .sort((a, b) => a.Ten.localeCompare(b.Ten))
                body: JSON.stringify(dataArr),
                redirect: 'follow',
            }

            // https://gendocx.iotsoftvn.com
            // http://localhost:5244
            fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/thong-ke', requestOptions)
                .then((response) => response.blob())
                .then((blob) => {
                    var url = window.URL.createObjectURL(blob)
                    var a = document.createElement('a')
                    a.href = url
                    a.download = `Thống kê ${tenNganh.toLowerCase() ?? ''}.xlsx`
                    document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
                    a.click()
                    a.remove() //afterwards we remove the element again
                })
                .catch((error) => console.error(error))

            console.log('dataArr', dataArr)
        },
        firstName(fullName) {
            if (!fullName) return ''
            const parts = fullName.trim().split(' ')
            return parts.length > 1 ? parts.slice(0, parts.length - 1).join(' ') : ''
        },
        lastName(fullName) {
            if (!fullName) return ''
            const parts = fullName.trim().split(' ')
            return parts.length > 1 ? parts[parts.length - 1] : ''
        },
        resetSTT(ds) {
            let filter = ds.map((item, index) => {
                return {
                    ...item,
                    STT: index + 1,
                }
            })

            return filter
        },
        getTask(nganhID) {
            const $this = this
            this.DsTask = []
            this.DsNotComplete = []
            this.CompleteStatusTask = []
            this.AllTasks = []

            const filterValidTasks = (tasks) => {
                // (nganhID === 102 || (nganhID === 106 && this.switchData))
                if (this.switchData) {
                    // Filter đố án
                    console.log('itemxxxxx', tasks)
                    return tasks.filter((item) => item.Process_ID === 4 && item.File_DangKy_ID && item.File_LyLich_ID && item.File_NhanXetGVHD1_ID && item.File_LuanVanWORD_ID)
                } else {
                    // Filter luận văn
                    return tasks.filter(
                        (item) => item.Process_ID !== 4 && item.File_DangKy_ID && item.File_LuanVanPDF_ID && item.File_LyLich_ID && item.File_NhanXetGVHD1_ID && item.File_LuanVanWORD_ID,
                    )
                }
            }

            const filterUnValidTasks = (tasks) => {
                if (this.switchData) {
                    // Filter đồ án
                    return tasks.filter((item) => item.Process_ID === 4 && (!item.File_DangKy_ID || !item.File_LyLich_ID || !item.File_NhanXetGVHD1_ID || !item.File_LuanVanWORD_ID))
                } else {
                    // Filter luận văn
                    return tasks.filter(
                        (item) =>
                            item.Process_ID !== 4 && (!item.File_DangKy_ID || !item.File_LuanVanPDF_ID || !item.File_LyLich_ID || !item.File_NhanXetGVHD1_ID || !item.File_LuanVanWORD_ID),
                    )
                }
            }

            const allTaskLoaiThS = (tasks) => {
                if (this.switchData) {
                    // Filter đồ án
                    return tasks.filter((item) => item.Process_ID === 4)
                } else {
                    // Filter luận văn
                    return tasks.filter((item) => item.Process_ID !== 4)
                }
            }

            const filterCompleteStatus = (task) => {
                return task.filter((item) => item.Process_Status_Register === 'C')
            }

            if (this.filterData === 4) {
                // SDH_Get_TaskRegister_GetByStatus
                ajaxCALL(
                    '/SDH_Get_TaskRegisterDefend',
                    {
                        Nganh_Id: nganhID,
                        // 1 là làm Luận văn/Đồ án
                        Process_Action: 1,
                        // P là status Processing
                        Flow_Status: 'W',
                    },
                    (res) => {
                        const filterAllTask = allTaskLoaiThS(res.data)
                        this.AllTasks = this.resetSTT(filterAllTask)
                        this.AllTasksOrigin = this.resetSTT(filterAllTask)

                        // this.DsTaskOrigin = res.data
                        this.labelTable = `
	                            <span>Danh sách học viên chưa đăng ký bảo vệ luận văn/đồ án:</span>
	                            <span class="pink--text">Tất cả (${this.AllTasks.length})</span>`
                    },
                    (error) => {
                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        console.log('Fail to load task registed', error)
                    },
                )
            } else {
                ajaxCALL(
                    '/SDH_Get_TaskRegisterDefend',
                    {
                        Nganh_Id: nganhID,
                        // 1 là làm Luận văn/Đồ án
                        Process_Action: 1,
                        // P là status Processing
                        Flow_Status: this.filterData !== 4 ? 'P' : 'W',
                    },
                    (res) => {
                        const filteredTasks = filterValidTasks(res.data)
                        const filteredUnvalid = filterUnValidTasks(res.data)
                        const filterCompleteStatusTask = filterCompleteStatus(res.data)
                        const filterAllTask = allTaskLoaiThS(res.data)

                        this.DsTask = this.resetSTT(filteredTasks)
                        this.DsTaskOrigin = this.resetSTT(filteredTasks)

                        this.DsNotComplete = this.resetSTT(filteredUnvalid)
                        this.DsNotCompleteOrigin = this.resetSTT(filteredUnvalid)

                        this.CompleteStatusTask = this.resetSTT(filterCompleteStatusTask)
                        this.CompleteStatusTaskOrigin = this.resetSTT(filterCompleteStatusTask)

                        // res.data
                        this.AllTasks = this.resetSTT(filterAllTask)
                        this.AllTasksOrigin = this.resetSTT(filterAllTask)

                        if (nganhID === 0) {
                            this.AllTaskComplete = this.resetSTT(filteredTasks)
                            this.AllTaskCompleteOrigin = this.resetSTT(filteredTasks)
                        }

                        this.labelTable = this.labelContent()

                        console.log('this.AllTaskComplete', this.AllTaskComplete)
                    },
                    (error) => {
                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        console.log('Fail to load task registed', error)
                    },
                )
            }
        },

        async getDsNganh() {
            this.nganhArr = await getNganhCaoHocPromise({ hasAllOption: true });
        },

        deleteFile() {},
        async loadExcelGVInfo() {
            try {
                const url = 'https://file.lhu.edu.vn/qldetaisdh/' + this.File_Url // Replace with the actual URL
                const response = await fetch(url)
                if (!response.ok) throw new Error('Network response was not ok')

                const arrayBuffer = await response.arrayBuffer()

                const workbook = new ExcelJS.Workbook()
                await workbook.xlsx.load(arrayBuffer)

                const worksheet = workbook.getWorksheet(1) // Get the first worksheet
                const jsonData = []

                worksheet.eachRow((row, rowNumber) => {
                    const rowData = row.values.slice(1) // Remove empty first element
                    jsonData.push(rowData)
                })

                if (jsonData.length > 0) {
                    this.fileDataHeader = jsonData[0]
                    jsonData.splice(0, 1)
                    this.fileData = jsonData
                }

                // Ensure each row has length 14 by adding empty elements
                const maxLength = 15
                this.fileData = this.fileData.map((row) => {
                    while (row.length < maxLength) {
                        row.push('') // Add empty string or null as needed
                    }
                    return row
                })

                // Map fileData to objects and push to DataArr
                this.GVInfoArr = this.fileData.map((row) => {
                    return {
                        STT: row[0] || null,
                        HoTen: row[1] || null,
                        HocHamHocVi: row[2] || null,
                        DonVi: row[3] || null,
                        DienThoai: row[4] || null,
                        Email: typeof row[5] === 'object' ? row[5].text.trim() || null : row[5].trim() || null,
                        DiaChi: row[6] || null,
                        MST: row[7] || null,
                        STK: row[8] || null,
                        NganHang: row[9] || null,
                    }
                })

                console.log('this.GVInfoArr', this.GVInfoArr)
                console.log('this.fileDataHeader', this.fileDataHeader)
                console.log('this.fileData', this.fileData)
            } catch (error) {
                console.error('Error loading Excel file:', error)
            }
        },
    },
	}
</script>