<template>
	<div>
        <v-dialog v-model="vueData.isSelectDialog" transition="dialog-bottom-transition" max-width="1400px" persistent>
            <v-card>
                <c-toolbar @onClose="closeDialog">
                    <template v-slot:title>
                        <p class="title mb-0 primary--text">Danh sách học viên</p>
                    </template>
                </c-toolbar>

                <div class="d-flex align-center justify-end mr-5">
                    <v-btn :disabled="HocVienArr.length === 0" color="primary" @click="onPrint">In thư mời</v-btn>
                </div>

                <v-card-title>
                    <v-spacer></v-spacer>
                    <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search" single-line
                        hide-details></v-text-field>
                </v-card-title>
                <v-card-text>
                    <v-data-table v-model="selectTable" :items="HocVienArr" :headers="tableHeader" :search="search"
                        :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" show-select
                        item-key="studentid" dense>
                        <template v-slot:item.HoTenSV="{ item }">
                            <span class="green--text">
                                <b> {{ item.HoSV }} {{ item.TenSV }}</b>
                            </span>
                            <br />
                            <b>{{ item.studentid }}</b>
                            <span class="amber--text"> [{{ item.lopId }}]</span>
                        </template>
                    </v-data-table>
                </v-card-text>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
	export default {
		props: ['getgvhd'],
    data() {
        return {
            HocVienArr: [],
            selectTable: [],
            GiangVienInfo: {},
            search: '',

            tableHeader: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Họ tên',
                    value: 'HoTenSV',
                    width: 150,
                },

                {
                    text: 'Niên khóa',
                    value: 'NienKhoa',
                    width: 80,
                },
                {
                    text: 'Ngành',
                    value: 'TenNganh',
                    width: 140,
                },
                {
                    text: 'GVHD 1',
                    value: 'GVHD_1',
                    width: 180,
                },
                {
                    text: 'GVHD 2',
                    value: 'GVHD_2',
                    width: 180,
                },
                {
                    text: 'Tên đề tài',
                    value: 'TenDeTai',
                    width: 300,
                },
            ],
        }
    },
    mounted() {},
    computed: {
        GetGVHD: function () {
            return this.getgvhd
        },
        isSelectDialog: function () {
            return vueData.isSelectDialog
        },
    },
    watch: {
        isSelectDialog: function (val) {
            if (val) {
                this.onGetDeTai()
            }
        },
        HocVienArr: function (val) {
            this.selectTable = val.map((item) => item)
        },
    },
    methods: {
        onPrint() {
            let url

            localStorage.removeItem('JSON_PRINT_PDF_DSHV')
            localStorage.removeItem('JSON_PRINT_PDF_GiangVienInfo')

            localStorage.setItem('JSON_PRINT_PDF_DSHV', JSON.stringify(this.selectTable))
            localStorage.setItem('JSON_PRINT_PDF_GiangVienInfo', JSON.stringify(this.GiangVienInfo))

            url = `https://qldetaisdh.lhu.edu.vn/rpt_teacher_invite?GVHD=${this.GetGVHD.GVHD}&TimeSelect=${this.GetGVHD.ThoiGian}`
            const newTab = window.open(url, '_blank')
            newTab.focus()
        },
        closeDialog() {
            vueData.isSelectDialog = false
        },
        onGetDeTai() {
            ajaxCALL(
                '/GetDeTaiByGiaoVien',
                {
                    GiaoVien: this.GetGVHD.GVHD,
                },
                (res) => {
                    this.GiangVienInfo = res.data[0][0]
                    this.HocVienArr = res.data[1].map((item, index) => {
                        return {
                            ...item,
                            STT: index + 1,
                            HoTenSV: item.HoSV + ' ' + item.TenSV,
                            IsSelect: true,
                        }
                    })
                    console.log('this.HocVienArr', this.HocVienArr)
                    console.log('this.GiangVienInfo', this.GiangVienInfo)
                },
                (error) => {
                    Vue.$toast.error(`Lấy danh sách đề tài thất bại`, { position: 'top' })
                    console.log('Fail to load thesis', error)
                },
            )
        },
    },
	}
</script>