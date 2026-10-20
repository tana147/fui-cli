<template>
	<div>
        <v-row style="margin: 0" class="mb-0">
            <v-col cols="3" class="pl-0">
                <!-- formattedNganhID -->
                <v-select v-model="selectNganhID" :items="heArr" outlined dense hide-details label="Lọc theo ngành"
                    item-text="Ten_Nganh" item-value="Nganh_ID"></v-select>
            </v-col>
        </v-row>
        <v-card>
            <v-card-title class="primary--text">
                Danh sách giảng viên
                <v-spacer></v-spacer>
                <v-text-field class="searchBar" v-model="search" prepend-inner-icon="mdi-magnify" label="Search"
                    single-line hide-details />
            </v-card-title>
            <v-data-table :headers="GiangViengHeaders" :items="DSHoiDongFilter" item-key="GiangVienID"
                class="elevation-1" :search="search" :items-per-page="10" height="150">
                <template v-slot:item.addBtn="{ item }">
                    <v-btn @click="addGiangVien(item)" text color="success">
                        <v-icon size="20">mdi-plus</v-icon>
                    </v-btn>
                </template>
            </v-data-table>
        </v-card>

        <v-row class="mt-1">
            <v-col cols="3"> </v-col>
        </v-row>

        <v-card class="mt-3">
            <v-card-title class="primary--text">Danh sách hội đồng</v-card-title>
            <v-data-table :headers="GiangVienSelectedHeaders" :items="temp" item-key="GiangVienID"
                hide-default-footer="true" width="400" no-data-text="Chưa có giảng viên">
                <template v-slot:item.count="{ item, index }">
                    {{ index + 1 }}
                </template>
                <template v-slot:item.ChucTrach="{ item }">
                    <v-autocomplete outlined hide-details dense class="chucTrachSelect" v-model="item.ChucTrach"
                        :items="DSChucTrach" item-text="ChucTrach" item-value="ChucTrach" placeholder="Chọn chức trách"
                        color="success" @change="handleChucTrachChange(item)" />
                </template>
                <template v-slot:item.deleteBtn="{ item }">
                    <v-btn @click="deleteGiangVien(item)" text color="error">
                        <v-icon size="20">mdi-trash-can-outline</v-icon>
                    </v-btn>
                </template>
            </v-data-table>
        </v-card>
    </div>
</template>

<script>
	export default {
		props: {
        value: {
            type: Array,
        },
        dshdgiangvien: {
            type: Array,
        },
        hoidong: {
            type: Array,
        },
        dshedaotao: {
            type: Array,
        },
        isDialogClosed: {
            type: Boolean,
        },
        hearr: {
            type: Array,
        },
        onSelected: {
            type: Function,
        },
        getCouncilTime: {
            type: Function,
        },
        isadddialog: {
            type: Boolean,
        },
    },

    data() {
        return {
            search: '',
            type: '',
            DSHoiDongFilter: [],
            temp: [],
            councilTime: '',
            selectNganhID: 0,
            GiangViengHeaders: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Họ tên giảng viên',
                    value: 'HoTenHocHamHocVi',
                    width: 180,
                },
                {
                    text: 'Ngành giảng dạy',
                    value: 'NganhGiangDay',
                    width: 180,
                },
                {
                    text: 'Cơ quan công tác',
                    value: 'CoQuanCongTac',
                    width: 200,
                },
                {
                    text: 'Thêm giảng viên',
                    value: 'addBtn',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
            ],
            GiangVienSelectedHeaders: [
                {
                    text: 'STT',
                    value: 'count',
                    sortable: false,
                    align: 'center',
                    // class: "custom-col",
                    width: 30,
                },
                {
                    text: 'Họ tên giảng viên',
                    value: 'HoTenHocHamHocVi',
                    width: 150,
                },
                {
                    text: 'Ngành giảng dạy',
                    value: 'NganhGiangDay',
                    width: 150,
                    // class: "custom-col",
                },
                {
                    text: 'Cơ quan công tác',
                    value: 'CoQuanCongTac',
                    width: 240,
                },
                {
                    text: 'Chức trách',
                    value: 'ChucTrach',
                    align: 'start',
                    sortable: false,
                    width: 180,
                },
                {
                    text: 'Xóa giảng viên',
                    value: 'deleteBtn',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
            ],
        }
    },
    computed: {
        HoiDong: function () {
            return this.hoidong
        },
        DSHeDaoTao: function () {
            return this.dshedaotao
        },
        heArr: function () {
            return this.hearr
        },
        formattedNganhID: {
            get() {
                return this.HoiDong.Nganh_ID.toString()
            },
            set(value) {
                this.HoiDong.Nganh_ID = value
            },
        },
        DSChucTrach: function () {
            if (this.HoiDong.Process_ID === 4) {
                return vueData.ThSUDChucTrach
            } else {
                return vueData.DSHoiDongChucTrach
            }
        },
    },
    watch: {
        formattedNganhID: {
            handler(val) {
                vueData.nganhGiangDayID = parseInt(val)
                this.handleFormattedNganhIDChange(val)
            },
            immediate: true, // Kích hoạt ngay từ khi component được tạo
        },
        selectNganhID: function (val) {
            if (val) {
                this.handleFormattedNganhIDChange(val)
            }
        },
        isDialogClosed(newVal) {
            if (!newVal) {
                this.temp = []
            }
        },
        GiangVienSelected: function () {
            this.$emit('onSelected', this.temp)
        },
        councilTime: function () {
            this.$emit('getCouncilTime', this.councilTime)
        },
    },
    mounted() {},
    methods: {
        handleFormattedNganhIDChange(val) {
            vueData.nganhGiangDayID = parseInt(val)
            ajaxCALL(
                '/HoiDong_GiangVien_Get',
                {
                    NganhID: parseInt(val),
                },
                (res) => {
                    this.DSHoiDongFilter = res.data.map((item) => {
                        return {
                            ...item,
                            HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                        }
                    })
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('Error to call ajax number 2', error)
                },
            )
        },
        checkingQuantity(item) {
            if (this.DSGVSelected.length < 5) {
                // Cho phép chuyển đổi trạng thái Is_Chon
                item.Is_Chon = !item.Is_Chon
            } else {
                // Không cho phép chuyển từ false sang true
                if (item.Is_Chon) {
                    // Hiển thị toast khi cập nhật thất bại
                    item.Is_Chon = false
                } else {
                    console.log('this.DSGVSelected.length', false)
                    Vue.$toast.error(`Quá số lượng thành viên hội đồng`, { position: 'top' })
                }
            }
        },
        deleteGiangVien(item) {
            const index = this.temp.indexOf(item)

            if (index !== -1) {
                this.temp.splice(index, 1)
                this.temp.sort((a, b) => a.STT - b.STT)
                console.log('delete temp', this.temp)
                this.$emit('onSelected', this.temp)
            }
        },
        addGiangVien(item) {
            const { GiangVienID } = item
            const { GiangVienID1, GiangVienID2 } = this.HoiDong

            const isDuplicate = this.temp.some((gv) => gv.GiangVienID === GiangVienID)
            const isOverLimit = this.temp.length >= 5
            const isGVHD = GiangVienID === GiangVienID1 || GiangVienID === GiangVienID2

            if (isDuplicate) {
                Vue.$toast.error('Đã tồn tại giảng viên này', { position: 'top' })
                return
            }

            if (isOverLimit) {
                Vue.$toast.error('Quá số lượng thành viên', { position: 'top' })
                return
            }

            if (isGVHD) {
                Vue.$toast.error('Không được chọn GVHD làm thành viên', { position: 'top' })
                return
            }

            this.temp.push(item)
            this.temp.sort((a, b) => a.STT - b.STT)
            this.$emit('onSelected', this.temp)
        },
        handleChucTrachChange(item) {
            this.$emit('onSelected', this.temp)
        },
    },
	}
</script>