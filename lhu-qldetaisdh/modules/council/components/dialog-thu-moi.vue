<template>
	<div>
        <v-dialog v-model="vueData.isThuMoiDialog" transition="dialog-bottom-transition" max-width="1680px" persistent>
            <v-card>
                <c-toolbar @onClose="closeDialog">
                    <template v-slot:title>
                        <p class="title mb-0 primary--text">Thư mời giảng viên</p>
                    </template>
                </c-toolbar>
                <v-card-text>
                    <v-row>
                        <v-col cols="6">
                            <v-textarea rows="1" auto-grow v-model="diaDiem" label="Địa điểm" outlined dense
                                hide-details />
                        </v-col>
                        <v-col cols="2">
                            <f-time v-model="timePicker" label="Giờ bắt đầu" placeholder="Giờ bắt đầu" outlined dense
                                hide-details />
                        </v-col>
                        <v-col cols="2">
                            <f-date v-model="datePicker" label="Ngày bắt đầu" placeholder="Ngày bắt đầu" outlined dense
                                hide-details />
                        </v-col>
                        <v-col cols="2">
                            <v-select v-model="nganhSelect" :items="heArr" outlined dense hide-details label="Ngành"
                                item-text="TenNganh" item-value="TenNganh" />
                        </v-col>
                        <v-col class="d-flex align-center">
                            <v-radio-group hide-details dense v-model="nganhType" row>
                                <v-radio label="Thạc sĩ nghiên cứu" value="1"></v-radio>
                                <v-radio label="Thạc sĩ ứng dụng" value="4"></v-radio>
                            </v-radio-group>
                        </v-col>
                    </v-row>
                    <v-card class="mt-3">
                        <v-card-title class="primary--text">
                            Danh sách giảng viên
                            <v-spacer></v-spacer>
                            <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search" single-line
                                hide-details></v-text-field>
                        </v-card-title>
                        <v-data-table v-model="selectGiangVien" :search="search" :headers="headerCTable"
                            :items="DsGiangVien" isNew="false" isEdit="false" items-per-page="-1"
                            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" show-select
                            item-key="GiangVienID">
                            <template v-slot:item.Student_ID="{ item }">
                                <span class="green--text">
                                    <b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
                                </span>
                                <br />
                                <b>{{ item.Student_ID }}</b>
                                <span class="amber--text"> [{{ item.Lop_ID }}]</span>
                            </template>
                        </v-data-table>
                    </v-card>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn @click="printWord" color="primary">Xuất file word</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
	export default {
		props: ['dshddetai', 'dsgiangvien', 'nganhgiangday', 'dshedaotao'],
    data() {
        return {
            nganhSelect: '',
            timePicker: '',
            datePicker: '',
            type: 'C',
            diaDiem: 'Phòng Họp, Cơ sở 1, Trường Đại học Lạc Hồng',
            search: '',
            heArr: [],
            DsHeDaoTao: [],
            selectGiangVien: [],
            DsDeTai: [],
            existGV: [],
            NganhGiangDay: [],
            GVSelect: '',
            nganhType: '1',

            headerCTable: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Học hàm, học vị',
                    value: 'HocViHocHam',
                    width: 150,
                },
                {
                    text: 'Họ tên',
                    value: 'HoTenGiangVien',
                    width: 150,
                },
                {
                    text: 'Ngành giảng dạy',
                    value: 'NganhGiangDay',
                    // width: 300
                },
                {
                    text: 'Cơ quan',
                    value: 'CoQuanCongTac',
                },
            ],
        }
    },
    mounted() {},
    computed: {
        DsGiangVien: function () {
            return this.dsgiangvien
        },
        existNganh() {
            const nganh = this.DsGiangVien.map((item) => item.NganhGiangDay)
            return nganh.map((item) => ({ TenNganh: item }))
        },
        ThuMoiDialog: function () {
            return vueData.isThuMoiDialog
        },
    },
    watch: {
        dshddetai: function (val) {
            if (val) {
                this.DsDeTai = val.filter((item) => item.HoiDongID)
            }
        },
        DsDeTai: function (val) {
            if (val) {
                const GV1 = val.map((item) => item.Thesises_Prof1)
                const GV2 = val.map((item) => item.Thesises_Prof2)
                this.existGV.push(...GV1.map((item) => ({ GiangVien: item })))
                this.existGV.push(...GV2.filter((item) => item !== null && item !== '' && item !== ' ').map((item) => ({ GiangVien: item })))
                console.log('this.existGV', this.existGV)
            }
        },
        ThuMoiDialog: function (val) {
            if (val) {
                this.loadheDaoTao()
                this.getDsNganh()
            }
        },
    },
    methods: {
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

        async printWord() {
            if (this.diaDiem && this.timePicker && this.datePicker && this.nganhSelect && this.selectGiangVien.length > 0) {
                const currentDate = new Date()

                // Lấy ngày, tháng, và năm
                const day = currentDate.getDate()
                const month = currentDate.getMonth() + 1
                const year = currentDate.getFullYear()

                const userID = parseInt(vueData.user.UserID.replace(/GV|NV/, ''), 10)
                console.log('userID', userID, vueData.user.UserID)

                console.log('timePicker', this.timePicker)

                // Tách giờ và phút từ this.timePicker
                const [hour, minute] = this.timePicker.split(':')

                for (const item of this.selectGiangVien) {
                    const apiData = {
                        HoTen: item.HocViHocHam + '. ' + item.HoTenGiangVien,
                        Nganh: removeKhoaID(this.nganhSelect),
                        Gio: hour,
                        Phut: minute,
                        NgayBatDau: this.formatCustomDate(this.datePicker),
                        DiaDiem: this.diaDiem,
                        Ngay: day.toString(),
                        Thang: month.toString(),
                        Nam: year.toString(),
                        LuuVT: userID.toString(),
                        ProcessID: parseInt(this.nganhType),
                    }

                    const myHeaders = new Headers()
                    myHeaders.append('Content-Type', 'application/json')

                    const requestOptions = {
                        method: 'POST',
                        headers: myHeaders,
                        body: JSON.stringify(apiData),
                        redirect: 'follow',
                    }

                    try {
                        // http://localhost:5244
                        // https://gendocx.iotsoftvn.com
                        const response = await fetch('https://gendocx.iotsoftvn.com/api/generate-docx/thu-moi', requestOptions)
                        const blob = await response.blob()
                        const url = window.URL.createObjectURL(blob)
                        const a = document.createElement('a')
                        a.href = url
                        a.download = `Thu moi ${item.HocViHocHam}. ${item.HoTenGiangVien}.docx`
                        document.body.appendChild(a) // We need to append the element to the DOM -> otherwise it will not work in Firefox
                        a.click()
                        a.remove() // Afterwards, we remove the element again
                    } catch (error) {
                        console.error(error)
                    }
                }
                this.closeDialog()
            } else {
                Vue.$toast.error(`Chưa nhập đủ địa điểm, thời gian, ngày bắt đầu, giảng viên và ngành`, { position: 'top' })
            }
        },
        loadheDaoTao() {
            ajaxCALL(
                '/hedaotao_get',
                null,
                (res) => {
                    this.DsHeDaoTao = res.data
                    console.log('this.DsHeDaoTao', this.DsHeDaoTao)
                },
                (error) => {
                    Vue.$toast.error(` ${error.responseJSON ? error.responseJSON.Message : error.message}`, { position: 'top' })
                },
            )
        },
        async getDsNganh() {
            this.heArr = await getNganhCaoHocPromise();
        },
        closeDialog() {
            vueData.isThuMoiDialog = false
        },
    },
	}
</script>