<template>
    <div>
        <v-dialog v-model="vueData.isThongKeKinhPhiDialog" transition="dialog-bottom-transition" max-width="1380px" persistent>
            <v-card>
                <c-toolbar @onClose="closeDialog">
                    <template v-slot:title>
                        <p class="title mb-0 primary--text">Thống kê kinh phí</p>
                    </template>
                </c-toolbar>

                <v-card-text>
                    <v-row>
                        <v-col cols="2">
                            <v-text-field v-model="ThongKeData.SQD" label="Số KH" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <v-select v-model="type" label="Chọn theo hệ đào tạo" outlined dense :items="DsHeDaoTao" item-text="VALUE" item-value="KEY" hide-details />
                        </v-col>
                        <v-col cols="3">
                            <v-select v-model="ThongKeData.Nganh" :items="heArr" outlined dense hide-details label="Ngành" item-text="Ten_Nganh" item-value="Ten_Nganh" />
                        </v-col>
                        <v-col cols="2">
                            <v-text-field v-model="ThongKeData.NamHoc" label="Năm học" outlined dense hide-details />
                        </v-col>
                        <v-col cols="3">
                            <v-textarea v-model="ThongKeData.DiaDiem" rows="1" auto-grow label="Địa điểm" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <f-date v-model="ThongKeData.SelectDate" label="Ngày bảo vệ" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <f-time v-model="ThongKeData.ThoiGianBatDau" label="Thời gian bắt đầu" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <f-time v-model="ThongKeData.ThoiGianKetThuc" label="Thời gian kết thúc" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <v-text-field v-model="ThongKeData.SoLuong" label="Số lượng học viên" outlined dense hide-details type="number" />
                        </v-col>
                        <v-col cols="2">
                            <v-text-field v-model="ThongKeData.MaDuTru" label="Mã dự trù" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <f-date v-model="ThongKeData.NgayXuatFile" label="Ngày xuất file" outlined dense hide-details />
                        </v-col>
                        <v-col>
                            <v-radio-group v-model="ThongKeData.ProcessID" row>
                                <v-radio label="Thạc sĩ nghiên cứu" value="1"></v-radio>
                                <v-radio label="Thạc sĩ ứng dụng" value="4"></v-radio>
                            </v-radio-group>
                        </v-col>
                    </v-row>

                    <div class="d-flex align-center justify-center mt-4 mb-3 primary--text">
                        <h3>BẢNG DỰ TRÙ KINH PHÍ HỘI ĐỒNG ĐÁNH GIÁ LUẬN VĂN THẠC SĨ</h3>
                    </div>

                    <div>
                        <v-simple-table dense>
                            <template v-slot:default>
                                <thead>
                                    <tr>
                                        <th class="text-center font-weight-bold sttColumn">TT</th>
                                        <th class="text-center font-weight-bold contentColumn">NỘI DUNG</th>
                                        <th class="text-center font-weight-bold contentColumn">ĐƠN GIÁ</th>
                                        <th class="text-center font-weight-bold contentColumn soLuongWidth">SỐ LƯỢNG</th>
                                        <th class="text-center font-weight-bold contentColumn thanhTienWidth">THÀNH TIỀN</th>
                                        <th class="text-center font-weight-bold contentColumn">GHI CHÚ</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="(item, index) in ThongKeData.DanhSach" :key="index">
                                        <!-- Row TỔNG CỘNG -->
                                        <template v-if="index === ThongKeData.DanhSach.length - 2">
                                            <td colspan="4" class="text-center font-weight-bold">TỔNG CỘNG</td>
                                            <td class="text-center font-weight-bold">{{ tongCong }}</td>
                                            <td>
                                                <v-text-field v-model="item.GhiChu" dense hide-details outlined />
                                            </td>
                                        </template>
                                        <!-- Row cuối cùng "(.................)" -->
                                        <template v-else-if="index === ThongKeData.DanhSach.length - 1">
                                            <td colspan="6" class="text-center font-weight-bold">
                                                <v-text-field class="mt-2 mb-2" label="Nhập tiền bằng chữ" v-model="item.STT" dense hide-details outlined />
                                            </td>
                                        </template>
                                        <!-- Các row bình thường -->
                                        <template v-else>
                                            <td class="text-center sttColumn">{{ item.STT }}</td>
                                            <td class="contentColumn">{{ item.NoiDung }}</td>
                                            <td>
                                                <v-text-field v-model="item.DonGia" dense hide-details outlined reverse @input="calculateThanhTien(item)" />
                                            </td>
                                            <td>
                                                <v-text-field v-model="item.SoLuong" dense hide-details outlined reverse type="number" @input="calculateThanhTien(item)" />
                                            </td>
                                            <td class="text-center font-weight-bold">
                                                {{ item.ThanhTien }}
                                                <!-- <v-text-field v-model="item.ThanhTien" dense hide-details outlined reverse /> -->
                                            </td>
                                            <td>
                                                <v-textarea class="mt-2 mb-2" rows="1" v-model="item.GhiChu" dense hide-details outlined auto-grow />
                                            </td>
                                        </template>
                                    </tr>
                                </tbody>
                            </template>
                        </v-simple-table>
                    </div>
                </v-card-text>

                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn @click="printWord" color="primary">Xuất file Word</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            DsHeDaoTao: [],
            heArr: [],
            type: 'C',
            t: ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'],

            ThongKeData: {
                SQD: '            /KH-K.SĐH',
                Ngay: '',
                Thang: '',
                Nam: '',
                Nganh: null,
                NgayBaoVe: '',
                SelectDate: '',
                DiaDiem: 'Phòng họp - Cơ sở 1',
                ThoiGianBatDau: '',
                GioBatDau: '',
                PhutBatDau: '',
                ThoiGianKetThuc: '',
                GioKetThuc: '',
                PhutKetThuc: '',
                MaDuTru: '',
                NamHoc: '',
                SoLuong: '1',
                NguoiTao: '',
                NgayXuatFile: '',
                ProcessID: '1',
                DanhSach: [],
            },
        }
    },
    mounted() {},
    computed: {
        ThongKeDialog: function () {
            return vueData.isThongKeKinhPhiDialog
        },
        tongCong() {
            return this.ThongKeData.DanhSach.slice(0, this.ThongKeData.DanhSach.length - 2) // Bỏ row "TỔNG CỘNG" và row "(...................)"
                .reduce((sum, item) => sum + parseInt(item.ThanhTien.replace(/\./g, '') || 0, 10), 0)
                .toLocaleString('vi-VN') // Định dạng số theo kiểu tiền tệ Việt Nam
        },
    },
    watch: {
        ThongKeDialog: function (val) {
            if (val) {
                this.loadheDaoTao()
                this.getDsNganh('C')
                this.ThongKeData.DanhSach = this.getDanhSach('1')
            }
        },
        type: function (val) {
            if (val) {
                this.getDsNganh(val)
            }
        },
        tongCong: function (val) {
            if (val) {
                this.ThongKeData.DanhSach[this.ThongKeData.DanhSach.length - 1].STT = `(${this.moneyToText(parseInt(val.replace(/\./g, '') || 0))}./.)`
            }
        },
        'ThongKeData.SoLuong': function (val) {
            this.ThongKeData.DanhSach.forEach((item, index) => {
                if (index < this.ThongKeData.DanhSach.length - 1 && index < this.ThongKeData.DanhSach.length - 2) {
                    item.SoLuong = val
                    item.ThanhTien = (parseInt(item.DonGia.replace(/\./g, '') || 0) * parseInt(val)).toLocaleString('vi-VN')
                } else if (val === '') {
                    item.SoLuong = '0'
                    item.ThanhTien = (parseInt(item.DonGia.replace(/\./g, '') || 0) * 0).toLocaleString('vi-VN')
                }
            })
        },
        'ThongKeData.ProcessID': function (val) {
            this.ThongKeData.DanhSach = this.getDanhSach(val)
        },
    },
    methods: {
        getDanhSach(processId) {
            const data = {
                1: [
                    { STT: '1', NoiDung: 'Giảng viên hướng dẫn độc lập', DonGia: '6.000.000', SoLuong: '1', ThanhTien: '6.000.000', GhiChu: '' },
                    { STT: '', NoiDung: 'Giảng viên hướng dẫn chính', DonGia: '0', SoLuong: '0', ThanhTien: '0', GhiChu: '' },
                    { STT: '', NoiDung: 'Giảng viên hướng dẫn phụ', DonGia: '0', SoLuong: '0', ThanhTien: '0', GhiChu: '' },
                    { STT: '2', NoiDung: 'Chủ tịch hội đồng', DonGia: '900.000', SoLuong: '1', ThanhTien: '900.000', GhiChu: '' },
                    { STT: '3', NoiDung: 'Phản biện 1', DonGia: '900.000', SoLuong: '1', ThanhTien: '900.000', GhiChu: '' },
                    { STT: '4', NoiDung: 'Phản biện 2', DonGia: '900.000', SoLuong: '1', ThanhTien: '900.000', GhiChu: '' },
                    { STT: '5', NoiDung: 'Ủy viên', DonGia: '650.000', SoLuong: '1', ThanhTien: '650.000', GhiChu: '' },
                    { STT: '6', NoiDung: 'Thư ký', DonGia: '750.000', SoLuong: '1', ThanhTien: '750.000', GhiChu: '' },
                    { STT: '7', NoiDung: 'Tổ chức bảo vệ luận văn', DonGia: '300.000', SoLuong: '1', ThanhTien: '300.000', GhiChu: '' },
                    { STT: 'TỔNG CỘNG:', NoiDung: '', DonGia: '', SoLuong: '', ThanhTien: '10.400.000', GhiChu: '' },
                    { STT: '(Mười triệu bốn trăm nghìn đồng./.)', NoiDung: '', DonGia: '', SoLuong: '', ThanhTien: '', GhiChu: '' },
                ],
                default: [
                    { STT: '1', NoiDung: 'Giảng viên hướng dẫn độc lập', DonGia: '5.000.000', SoLuong: '1', ThanhTien: '5.000.000', GhiChu: '' },
                    { STT: '', NoiDung: 'Giảng viên hướng dẫn chính', DonGia: '0', SoLuong: '0', ThanhTien: '0', GhiChu: '' },
                    { STT: '', NoiDung: 'Giảng viên hướng dẫn phụ', DonGia: '0', SoLuong: '0', ThanhTien: '0', GhiChu: '' },
                    { STT: '2', NoiDung: 'Chủ tịch hội đồng', DonGia: '800.000', SoLuong: '1', ThanhTien: '800.000', GhiChu: '' },
                    { STT: '3', NoiDung: 'Phản biện 1', DonGia: '900.000', SoLuong: '1', ThanhTien: '900.000', GhiChu: '' },
                    { STT: '4', NoiDung: 'Phản biện 2', DonGia: '0', SoLuong: '0', ThanhTien: '0', GhiChu: '' },
                    { STT: '5', NoiDung: 'Ủy viên', DonGia: '0', SoLuong: '0', ThanhTien: '0', GhiChu: '' },
                    { STT: '6', NoiDung: 'Thư ký', DonGia: '700.000', SoLuong: '1', ThanhTien: '700.000', GhiChu: '' },
                    { STT: '7', NoiDung: 'Tổ chức bảo vệ luận văn', DonGia: '300.000', SoLuong: '1', ThanhTien: '300.000', GhiChu: '' },
                    { STT: 'TỔNG CỘNG:', NoiDung: '', DonGia: '', SoLuong: '', ThanhTien: '7.700.000', GhiChu: '' },
                    { STT: '(Bảy triệu bảy trăm nghìn đồng./.)', NoiDung: '', DonGia: '', SoLuong: '', ThanhTien: '', GhiChu: '' },
                ],
            }

            return data[processId] || data['default']
        },
        calculateThanhTien(item) {
            const donGia = parseInt(item.DonGia.replace(/\./g, '') || 0)
            const soLuong = parseFloat(item.SoLuong || 0)
            item.ThanhTien = (donGia * soLuong).toLocaleString('vi-VN')
        },
        printWord() {
            console.log('ngay xuat file', this.formatCustomDate(this.ThongKeData.NgayXuatFile))
            const ngayXuatFileArr = this.formatCustomDate(this.ThongKeData.NgayXuatFile).split('/')
            // [0] Ngày, [1] Tháng, [2] Năm
            console.log('ngayXuatFileArr', ngayXuatFileArr)
            let checkNull = false
            const userID = parseInt(vueData.user.UserID.replace(/GV|NV/, ''), 10)

            const fields = [
                { field: this.ThongKeData.Nganh, message: 'Chưa chọn ngành' },
                { field: this.ThongKeData.NamHoc, message: 'Chưa nhập năm học' },
                { field: this.ThongKeData.SoLuong, message: 'Chưa nhập số lượng học viên theo QĐ' },
                { field: this.ThongKeData.SelectDate, message: 'Chưa chọn ngày bảo vệ' },
                { field: this.ThongKeData.ThoiGianBatDau, message: 'Chưa chọn giờ bắt đầu' },
                { field: this.ThongKeData.ThoiGianKetThuc, message: 'Chưa chọn giờ kết thúc' },
                { field: this.ThongKeData.DiaDiem, message: 'Chưa nhập địa điểm' },
                { field: this.ThongKeData.MaDuTru, message: 'Chưa nhập mã dự trù' },
                { field: this.ThongKeData.SQD, message: 'Chưa nhập SQĐ' },
            ]

            checkNull = fields.some(({ field, message }) => {
                if (!field) {
                    Vue.$toast.error(message, { position: 'top' })
                    return true
                }
                return false
            })

            if (!checkNull) {
                let dateObj = new Date()

                // Format ngày tháng năm theo định dạng dd/MM/yyyy
                let day = dateObj.getDate()
                let month = dateObj.getMonth() + 1 // Tháng bắt đầu từ 0
                let year = dateObj.getFullYear()

                this.ThongKeData.GioBatDau = this.getHour(this.ThongKeData.ThoiGianBatDau)
                this.ThongKeData.PhutBatDau = this.getMinute(this.ThongKeData.ThoiGianBatDau)
                console.log('bat dau', this.ThongKeData.GioBatDau, this.ThongKeData.PhutBatDau)

                this.ThongKeData.GioKetThuc = this.getHour(this.ThongKeData.ThoiGianKetThuc)
                this.ThongKeData.PhutKetThuc = this.getMinute(this.ThongKeData.ThoiGianKetThuc)
                console.log('ket thuc', this.ThongKeData.GioKetThuc, this.ThongKeData.PhutKetThuc)

                if (ngayXuatFileArr.length === 3) {
                    this.ThongKeData.Ngay = ngayXuatFileArr[0].toString()
                    this.ThongKeData.Thang = ngayXuatFileArr[1].toString()
                    this.ThongKeData.Nam = ngayXuatFileArr[2].toString()
                } else {
                    this.ThongKeData.Ngay = day.toString()
                    this.ThongKeData.Thang = month.toString()
                    this.ThongKeData.Nam = year.toString()
                }

                this.ThongKeData.NgayBaoVe = this.formatCustomDate(this.ThongKeData.SelectDate)
                console.log('this.ThongKeData.NgayBaoVe', this.ThongKeData.NgayBaoVe)

                this.ThongKeData.NguoiTao = userID.toString()
                console.log('this.ThongKeData.NguoiTao', this.ThongKeData.NguoiTao)

                this.ThongKeData.ProcessID = parseInt(this.ThongKeData.ProcessID)

                this.ThongKeData.DanhSach[this.ThongKeData.DanhSach.length - 2].ThanhTien = this.tongCong

                const myHeaders = new Headers()
                myHeaders.append('Content-Type', 'application/json')

                const requestOptions = {
                    method: 'POST',
                    headers: myHeaders,
                    body: JSON.stringify(this.ThongKeData),
                    redirect: 'follow',
                }

                // http://localhost:5244
                // https://gendocx.iotsoftvn.com
                fetch('https://gendocx.iotsoftvn.com/api/generate-docx/thong-ke-kinh-phi', requestOptions)
                    .then((response) => response.blob())
                    .then((blob) => {
                        var url = window.URL.createObjectURL(blob)
                        var a = document.createElement('a')
                        a.href = url
                        a.download = 'Thong ke kinh phi.docx'
                        document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
                        a.click()
                        a.remove() //afterwards we remove the element again
                    })
                    .catch((error) => console.error(error))
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
        getDsNganh(heID) {
            ajaxCALL(
                '/Nganh_Get_ByHeID',
                {
                    HeID: heID,
                },
                (res) => {
                    this.heArr = res.data
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                },
            )
        },
        getHour(time) {
            const [hour, minute] = time.split(':')
            return hour
        },
        getMinute(time) {
            const [hour, minute] = time.split(':')
            return minute
        },
        formatDate(date) {
            if (date) {
                return moment(date, 'YYYY-MM-DD').format('DD/MM/YYYY')
            } else {
                return ''
            }
        },
        closeDialog() {
            vueData.isThongKeKinhPhiDialog = false
            this.ThongKeData.SQD = '           /QĐ-ĐHLH'
            this.ThongKeData.Nganh = null
            this.ThongKeData.NamHoc = ''
            this.ThongKeData.SoLuong = ''
            this.ThongKeData.NgayBaoVe = null
            this.ThongKeData.GioBatDau = null
            this.ThongKeData.GioKetThuc = null
            this.ThongKeData.DiaDiem = 'Phòng họp - Cơ sở 1'
            this.ThongKeData.MaDuTru = ''
        },

        moneyToText(value) {
            if (value === 0) return this.t[0]
            let result = '',
                suffix = ''

            do {
                let ty = value % 1e9
                value = Math.floor(value / 1e9)
                result = value > 0 ? this._convertMillions(ty, true) + suffix + result : this._convertMillions(ty, false) + suffix + result
                suffix = ' tỷ'
            } while (value > 0)

            return this.capitalize(result.trim() + ' đồng')
        },

        // Hàm xử lý hàng triệu
        _convertMillions(number, withSuffix) {
            let millions = Math.floor(number / 1e6)
            number %= 1e6
            let thousands = Math.floor(number / 1e3)
            number %= 1e3

            let result = ''
            if (millions > 0) {
                result += this._convertHundreds(millions, withSuffix) + ' triệu'
                withSuffix = true
            }
            if (thousands > 0) {
                result += this._convertHundreds(thousands, withSuffix) + ' ngàn'
                withSuffix = true
            }
            if (number > 0) {
                result += this._convertHundreds(number, withSuffix)
            }
            return result
        },

        // Hàm xử lý hàng trăm
        _convertHundreds(number, withSuffix) {
            let hundreds = Math.floor(number / 100)
            number %= 100
            let result = ''

            if (withSuffix || hundreds > 0) {
                result = ' ' + this.t[hundreds] + ' trăm'
                result += this._convertTens(number, true)
            } else {
                result = this._convertTens(number, false)
            }
            return result
        },

        // Hàm xử lý hàng chục
        _convertTens(number, withZeroPrefix) {
            let tens = Math.floor(number / 10)
            let units = number % 10
            let result = ''

            if (tens > 1) {
                result = ' ' + this.t[tens] + ' mươi'
                if (units === 1) result += ' mốt'
            } else if (tens === 1) {
                result = ' mười'
                if (units === 1) result += ' một'
            } else if (withZeroPrefix && units > 0) {
                result = ' lẻ'
            }

            if (units === 5 && tens >= 1) {
                result += ' lăm'
            } else if (units === 4 && tens >= 1) {
                result += ' bốn'
            } else if (units > 1 || (units === 1 && tens === 0)) {
                result += ' ' + this.t[units]
            }

            return result
        },

        // Hàm viết hoa chữ cái đầu tiên
        capitalize(text) {
            return text.charAt(0).toUpperCase() + text.slice(1)
        },
    },
}
</script>
