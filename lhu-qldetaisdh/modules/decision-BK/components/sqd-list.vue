<template>
	<div class="mt-5">
        <!-- thêm quyết định -->
        <dialog-add-sqd :isDialogAdd.sync="vueData.isDialogAdd" :nganhArr="nganhArr" />

        <!-- Cap SQD -->
        <dialog-give-sqd :isDialogSQD.sync="vueData.isDetailDialog" />

        <!-- edit SQD -->
        <student-edit-dialog :isEdit.sync="vueData.isEdit" :nganhArr="nganhArr" :majorlist="MajorList" :detaildecision="vueData.detailDecision" :detailstudent="vueData.detailStudent" :hearr="vueData.heArr" />

        <v-row class="mb-1">
            <v-col cols="3">
                <v-autocomplete v-model="major" :items="nganhArr" outlined dense hide-details label="Lọc theo ngành" item-text="TenNganh" item-value="NganhID" />
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
                <v-autocomplete v-model="tieuDeSelect" :items="DsTieuDe" item-text="Name" item-value="Value" outlined dense hide-details placeholder="Chọn tiêu đề" label="Tiêu đề" />
            </v-col>
            <v-col cols="1">
                <div class="mr-3">
                    <v-btn color="primary" dark @click="filterQD"> <v-icon left>mdi-filter</v-icon> Lọc </v-btn>
                </div>
            </v-col>
            <v-col>
                <!-- sqd list -->
                <div class="d-flex align-item justify-end mb-3">
                    <v-btn color="primary" @click="vueData.isDialogAdd = true" class="btnAddSQDWrap"> <v-icon>mdi-plus</v-icon>Thêm mới quyết định </v-btn>
                </div>
            </v-col>
        </v-row>

        <f-table
            items-per-page="-1"
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
            :label="tableLabel"
            :show-search="true"
            :fixed-header="true"
            :show-select="false"
            :fixed-cols="3"
            :mobile-breakpoint="800"
            :excel="true"
            :headers="headerTable"
            :items="DecisionFilter"
            item-key="TenTacGia"
            dense="true"
            :update-api="{
                'default-item': {},
                delete: {
                    CONFIRM: 'Bạn có xóa Số Quyết Định này?',
                    API: '/Decision_Del',
                    IN: {
                        Decision_ID: 'item.Decision_ID',
                    },
                    MESS: 'Xóa thành công',
                    CALLBACK: [
                        {
                            EXE: 'this.getDecision()',
                        },
                    ],
                },
            }"
        >
            <!-- Xóa nhưng không xóa SQĐ đã nhập -->
            <template v-slot:item.stt="{ item, index }">
                {{ index + 1 }}
            </template>
        </f-table>
    </div>
</template>

<script>
	export default {
		props: ['decisionarr', 'decisionfilter'],
    data() {
        return {
            major: '',
            nganhArr: [],
            DecisionFilter: [],
            DecistionFilterOriginal: [],
            DsNienKhoa: [],
            DsTieuDe: [],

            AddData: {
                Decision_TieuDe: '',
                Decision_Nganh: '',
                Decision_NienKhoa: '',
                Decision_Dot: '',
                Decision_MaSo: '',
                Decision_Type: '',
                Decision_Description: '',
            },

            MajorList: [],
            NganhID: null,
            NienKhoaValue: null,
            tieuDeSelect: '0',
            Student_Obj: [],
            editArr: [],
            typeList: ['Thạc sĩ', 'Tiến sĩ'],
            fileRules: {
                max_file_size: '100mb',
                mime_types: [
                    {
                        title: 'All files',
                        extensions: 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg',
                    },
                ],
            },
            fileName: '',
            updateApi: {
                delete: {
                    CONFIRM: 'Bạn có xóa Số Quyết Định này?',
                    API: '/Decision_Del',
                    IN: {
                        Decision_ID: 'item.Decision_ID',
                    },
                    MESS: 'Xóa thành công',
                    CALLBACK: [
                        {
                            CALL: 'testDelete',
                        },
                    ],
                },
            },
            headerTable: [
                {
                    text: 'STT',
                    value: 'stt',
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Tiêu đề',
                    value: 'Decision_TieuDe',
                },
                {
                    text: 'Ngành',
                    value: 'Decision_Nganh',
                },
                {
                    text: 'Đợt',
                    value: 'Decision_Dot',
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Niên khóa',
                    value: 'Decision_NienKhoa',
                },
                {
                    text: 'Mã ngành',
                    value: 'Decision_MaSo',
                },
                {
                    text: 'Số quyết định',
                    value: 'Decision_SoQD',
                },
                {
                    text: 'Loại',
                    value: 'Decision_Type',
                },
                {
                    text: 'Tải file QĐ',
                    value: 'fileQD',
                    align: 'center',
                    sortable: false,
                    el: 'div',
                    innerHTML: `<v-chip v-if="item.DecisionFile_ID" color="deep-purple accent-4" outlined label hide-details>
												<v-icon left>mdi-file-check-outline</v-icon>
												<a style="color: deep-purple accent-4" :href="vueData.v_Set.urlReadFile + item.DecisionFile_Url"
													target="_blank">File QĐ</a>
											</v-chip>
											<v-chip v-else color="deep-purple accent-4" outlined label hide-details>
												Chưa có file QĐ
											</v-chip>`,
                },
                {
                    el: 'div',
                    value: 'giveSQD',
                    sortable: false,
                    innerHTML: `<v-btn @click='onDetailDecision(item.Decision_ID)' text color='success'>Cấp SQĐ</v-btn>`,
                },
                {
                    el: 'div',
                    value: 'editDecision',
                    disabled: true,
                    sortable: false,
                    innerHTML: `<v-btn :disabled="item.DecisionFile_ID !== null" @click='onEditData(item.Decision_ID)' text color='info'>Cập nhật</v-btn>`,
                },
                {
                    text: 'In quyết định',
                    align: 'center',
                    sortable: false,
                    el: 'div',
                    value: 'printAction',
                    innerHTML: `<div class="d-flex align-center justify-center">
										<v-btn text @click="onPrintInTable(item)" color='orange darken-4'><v-icon>mdi-file-pdf-box</v-icon></v-btn>
										<v-btn text @click="onPrintWord(item.Decision_ID)" color='yellow darken-2'><v-icon>mdi-zip-box</v-icon></v-btn>
									</div>`,
                },
                {
                    text: '',
                    value: 'ctrl-update',
                    align: 'center',
                },
            ],
        }
    },
    computed: {
        decisionArr: function () {
            return this.decisionarr
        },
        tableLabel: function () {
            return `Danh sách quyết định (${this.DecisionFilter.length})`
        },
    },
    watch: {
        // major: function (val) {
        //     if (val) {
        //         if (val !== '0') {
        //             console.log('val', typeof val)
        //             this.DecisionFilter = this.resetSTT(this.decisionArr.filter((item) => item.Decision_NganhID == parseInt(val)))
        //             this.DecistionFilterOriginal = this.resetSTT(this.decisionArr.filter((item) => item.Decision_NganhID == parseInt(val)))
        //         } else {
        //             this.DecisionFilter = this.resetSTT(this.decisionArr)
        //             this.DecistionFilterOriginal = this.resetSTT(this.decisionArr)
        //         }
        //     }
        // },
        decisionfilter: function (val) {
            if (val) {
                //loc trung SQD
                let uniqueDecisions = val.filter((item) => item.DecisionFile_ID === null || item.DecisionFile_ID === '')
                this.DecisionFilter = this.resetSTT(val)
                this.DecistionFilterOriginal = this.resetSTT(val)

                this.DsTieuDe = this.DecisionFilter.map((item) => item.Decision_TieuDe)
                    .filter((value, index, self) => self.indexOf(value) === index)
                    .map((title) => {
                        let value = 'Khác'
                        const lower = title.toLowerCase()

                        if (lower.includes('công nhận tên đề tài')) {
                            value = 'Giao đề tài'
                        } else if (lower.includes('thành lập hội đồng')) {
                            value = 'Lập hội đồng'
                        } else if (lower.includes('đổi tên đề tài')) {
                            value = 'Đổi đề tài'
                        } else if (lower.includes('điều chỉnh tên đề tài')) {
                            value = 'Điều chỉnh đề tài'
                        } else if (lower.includes('đổi giảng viên hướng dẫn')) {
                            value = 'Đổi GVHD'
                        } else if (lower.includes('điều chỉnh giảng viên hướng dẫn')) {
                            value = 'Điều chỉnh GVHD'
                        } else if (lower.includes('đổi tên đề tài và giảng viên hướng dẫn')) {
                            value = 'Đổi tên đề tài và GVHD'
                        }

                        return {
                            Name: value,
                            Value: title,
                        }
                    })
                this.DsTieuDe.unshift({ Name: '- Tất cả -', Value: '0' })

                console.log('this.DecisionFilter YYYY', this.DecisionFilter)
                console.log('this.DsTieuDe zzzzz', this.DsTieuDe)
            }
        },

        NganhID(newVal) {
            const selectedMajor = this.MajorList.find((major) => major.Nganh_ID === newVal)
            if (selectedMajor) {
                this.AddData.Decision_Nganh = selectedMajor.Ten_Nganh
            }
        },
    },
    mounted() {
        this.getAllMajor()
        this.getHeDaoTao()
        this.getNienKhoa()
    },
    methods: {
        filterQD() {
            let dataArr = this.DecistionFilterOriginal
            console.log('dataArrxxxxxx', dataArr)

            if (this.major !== '0') {
                console.log('val', this.major)
                dataArr = this.resetSTT(dataArr.filter((item) => item.Decision_NganhID == parseInt(this.major)))
            }

            if (this.tieuDeSelect !== '0') {
                console.log('this.tieuDeSelect', this.tieuDeSelect)
                dataArr = dataArr.filter((item) => item.Decision_TieuDe === this.tieuDeSelect)
            }

            if (this.NienKhoaValue !== '0') {
                dataArr = dataArr.filter((item) => item.Decision_NienKhoa === this.NienKhoaValue)
            }

            this.DecisionFilter = this.resetSTT(dataArr)
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
        resetSTT(ds) {
            ds.forEach((item, index) => {
                item.stt = index + 1
            })
            return ds
        },
        getAllMajor() {
            const $this = this
            ajaxCALL(
                '/Nganh_GetAll',
                null,
                (res) => {
                    const data = res.data.map((item) => {
                        return { ...item, Nganh_ID: parseInt(item.Nganh_ID) }
                    })
                    $this.MajorList = data
                    $this.NganhID = data[0].Nganh_ID
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                },
            )
        },
        getHeDaoTao() {
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
                        NganhID: '0',
                        TenNganh: '- Tất cả -',
                    }

                    $this.nganhArr = res.data.map((item, index, array) => {
                        // Kiểm tra trùng lặp tên ngành (không phân biệt hoa/thường)
                        const isDuplicate = array.some((el, i) => i !== index && el.TenNganh.toLowerCase() === item.TenNganh.toLowerCase())

                        // Nếu trùng thì gắn thêm KhoaID
                        const rawName = isDuplicate ? `${item.TenNganh} (${item.KhoaID})` : item.TenNganh

                        const originalName = isDuplicate ? item.TenNganh : ''

                        vueData.NganhGlobal = res.data

                        // Gộp xử lý removeHocHam vào chung 1 vòng map
                        return {
                            ...item,
                            TenNganh: removeHocHam(rawName),
                            OriginalName: removeHocHam(originalName),
                        }
                    })

                    $this.nganhArr.unshift(allListObj)
                    $this.major = '0'
                    console.log('$this.nganhArr', $this.nganhArr)
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
    },
	}
</script>