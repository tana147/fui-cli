<template>
	<div>
        <v-dialog v-model="vueData.isTemBuuKienDialog" transition="dialog-bottom-transition" max-width="1400px"
            persistent>
            <v-card>
                <c-toolbar @onClose="closeDialog">
                    <template v-slot:title>
                        <p class="title mb-0 primary--text">Nhập thông tin tem bưu kiện</p>
                    </template>
                </c-toolbar>

                <v-card-text>
                    <div>
                        <v-row>
                            <v-col cols="7">
                                <v-text-field v-model="SenderObj.Sender" label="Người gửi" outlined dense
                                    hide-details />
                            </v-col>
                            <v-col cols="2">
                                <v-text-field v-model="SenderObj.SDT" type="number" label="SĐT" outlined dense
                                    hide-details />
                            </v-col>
                            <v-col cols="9">
                                <v-textarea rows="2" v-model="SenderObj.DiaChi" label="Địa chỉ" outlined dense
                                    hide-details auto-grow />
                            </v-col>
                        </v-row>
                    </div>

                    <v-card class="mt-3">
                        <v-card-title class="primary--text">
                            Danh sách giảng viên in tem bưu điện
                            <v-spacer></v-spacer>
                            <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search" single-line
                                hide-details></v-text-field>
                        </v-card-title>
                        <v-data-table v-model="selectTable" :items="DsGiangVien" :headers="tableHeader" :search="search"
                            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" item-key="GiangVienID"
                            dense>
                            <template v-slot:item.IsSelect="{ item }">
                                <div class="d-flex align-center justify-center">
                                    <v-checkbox class="p-0" v-model="item.IsSelect" dense hide-details />
                                </div>
                            </template>
                            <template v-slot:item.STT="{ index }">
                                {{ index + 1 }}
                            </template>
                            <template v-slot:item.HoTen="{ item }"> {{ item.HocViHocHam }}. {{ item.HoTenGiangVien }}
                            </template>
                            <template v-slot:item.DiaChi="{ item }">
                                <v-textarea rows="1" v-model="item.DiaChi" outlined dense hide-details auto-grow />
                            </template>
                            <template v-slot:item.SoDienThoai="{ item }">
                                <div class="phoneWrap d-flex align-center justify-center">
                                    <v-text-field class="mt-2 mb-2" v-model="item.SoDienThoai" type="number" outlined
                                        dense hide-details />
                                </div>
                            </template>
                        </v-data-table>
                    </v-card>
                </v-card-text>

                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn :disabled="selectTable.length === 0" color="success" @click="printTem">In tem bưu điện
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
	export default {
		props: ['existgiangvien'],
    data() {
        return {
            search: '',
            DsGiangVien: [],
            selectTable: [],
            SenderObj: {
                Sender: 'KHOA SAU ĐẠI HỌC, TRƯỜNG ĐẠI HỌC LẠC HỒNG',
                DiaChi: 'Số 10 Huỳnh Văn Nghệ, phường Trấn Biên, tỉnh Đồng Nai.',
                SDT: '02513951924',
            },

            tableHeader: [
                {
                    text: 'Chọn',
                    value: 'IsSelect',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Họ tên giảng viên',
                    value: 'HoTen',
                    width: 200,
                },
                {
                    text: 'Ngành giảng dạy',
                    value: 'NganhGiangDay',
                    width: 200,
                },
                {
                    text: 'Số điện thoại',
                    value: 'SoDienThoai',
                    width: 170,
                },
                {
                    text: 'Địa chỉ',
                    value: 'DiaChi',
                },
            ],
        }
    },
    mounted() {},
    computed: {
        IsTemBuuKien: function () {
            return vueData.isTemBuuKienDialog
        },
        ExistsGiangVien: function () {
            return this.existgiangvien
        },
    },
    watch: {
        IsTemBuuKien: function (val) {
            if (val) {
                this.onLoadAllGiangVien()
            }
        },
        DsGiangVien: function (val) {
            if (val) {
                this.selectTable = val.map((item) => item)
            }
        },
    },
    methods: {
        handleSelection(selectedItems) {
            // Duyệt qua danh sách gốc và cập nhật IsSelect
            this.DsGiangVien.forEach((item) => {
                item.IsSelect = selectedItems.some((selected) => selected.GiangVienID === item.GiangVienID)
            })

            console.log('Danh sách đã chọn:', selectedItems)
        },
        printTem() {
            console.log(
                'this.selectTable',
                this.selectTable.filter((item) => item.IsSelect),
            )
            // Xóa mục khỏi localStorage trước khi lưu trữ mới
            let dataArr = []
            dataArr.push(this.SenderObj)
            dataArr.push(this.selectTable.filter((item) => item.IsSelect))
            localStorage.removeItem('JSON_PRINT_PDF_TEM_BUU_DIEN')
            localStorage.setItem('JSON_PRINT_PDF_TEM_BUU_DIEN', JSON.stringify(dataArr))

            const url = `https://qldetaisdh.lhu.edu.vn/ths-in-tem-buu-dien`
            const newTab = window.open(url, '_blank')
            newTab.focus()
        },
        onLoadAllGiangVien() {
            ajaxCALL(
                '/giangvien_get',
                null,
                (res) => {
                    const dataArr = res.data
                    console.log('dataArr', dataArr)
                    this.ExistsGiangVien.forEach((giangVien) => {
                        let filter = dataArr.find((item) => giangVien.ThanhVienHoiDong_ID === item.GiangVienID)
                        if (filter) {
                            this.DsGiangVien.push({ ...filter, IsSelect: giangVien.IsSelect })
                        }
                    })

                    console.log('this.ExistsGiangVien', this.ExistsGiangVien)
                    console.log('this.DsGiangVien', this.DsGiangVien)
                },
                (error) => {
                    Vue.$toast.error(`Lấy danh sách giảng viên thất bại`, { position: 'top' })
                    console.log('Fail to load teacher', error)
                },
            )
        },
        closeDialog() {
            this.DsGiangVien = []
            vueData.isTemBuuKienDialog = false
        },
    },
	}
</script>