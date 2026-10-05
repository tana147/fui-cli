<template>
	<div>
        <dialog-tem-buu-kien :existgiangvien="existGiangVien" />

        <v-dialog v-model="vueData.isCouncilInfoManager" transition="dialog-bottom-transition" fullscreen
            max-width="1780px" persistent>
            <v-card>
                <c-toolbar @onClose="closeDialog">
                    <template v-slot:title>
                        <p class="title mb-0 primary--text">Thông tin thành viên hội đồng</p>
                    </template>
                </c-toolbar>

                <v-card-text>
                    <!-- <div>
						<v-row>
							<v-col cols="2">
								<v-select :items="existGiangVien" item-text="ThanhVienHoiDong"
									item-value="ThanhVienHoiDong" hide-details dense outlined
									label="Giảng viên HĐ trong danh sách" />
							</v-col>
						</v-row>
					</div> -->

                    <div class="mb-3 mt-1">
                        <p class="pb-0 mb-3 primary--text text-h6">Xuất các file thư mời, bảng thống kê, mẫu nhận xét
                            cho giảng viên hội đồng</p>
                        <div class="mt-3">
                            <!-- <h4 class="mb-3 mt-3" class="primary--text">In thư mời</h4> -->
                            <v-row>
                                <v-col cols="2">
                                    <v-select v-model="selectNganh" :items="heArr" outlined dense hide-details
                                        label="Ngành" item-text="TenNganh" item-value="NganhID" />
                                </v-col>
                                <v-col cols="2">
                                    <v-select :disabled="selectNganh == 0" v-model="selectThoiGianBV"
                                        :items="existNgayBaoVe" item-text="ThoiGianBaoVe" item-value="ThoiGianBaoVe"
                                        hide-details dense outlined label="Thời gian bảo vệ" />
                                </v-col>
                                <v-col cols="2">
                                    <f-time :disabled="!selectThoiGianBV" v-model="timePicker" label="Giờ bắt đầu"
                                        placeholder="Giờ bắt đầu" outlined dense hide-details />
                                </v-col>
                                <v-col cols="2">
                                    <f-date v-model="datePicker" label="Ngày bắt đầu" placeholder="Ngày bắt đầu"
                                        outlined dense hide-details />
                                </v-col>
                                <v-col cols="3">
                                    <v-textarea rows="1" v-model="diaDiem" label="Địa điểm" outlined dense hide-details
                                        auto-grow />
                                </v-col>
                            </v-row>
                        </div>

                        <div v-if="selectNganh !== 0 && selectThoiGianBV && HDThanhVien.length > 0"
                            class="d-flex align-center justify-end mt-3">
                            <div>
                                <v-radio-group v-model="nganhType" row>
                                    <v-radio label="Thạc sĩ nghiên cứu" value="1"></v-radio>
                                    <v-radio label="Thạc sĩ ứng dụng" value="4"></v-radio>
                                </v-radio-group>
                            </div>
                            <v-btn @click="printAllFile" color="primary">
                                <v-icon left>mdi-zip-box-outline</v-icon> Xuất các file hội đồng
                            </v-btn>
                            <v-btn class="ml-3" @click="printExcelDSBVLV" color="purple" dark>
                                <v-icon left>mdi-microsoft-excel</v-icon>Xuất file tổng DSBV
                            </v-btn>
                            <v-btn class="ml-3" @click="openTemBuuDien" color="deep-purple darken-1" dark>
                                <v-icon left>mdi-file-pdf-box</v-icon>In tem dán bưu kiện
                            </v-btn>
                            <v-btn class="ml-3" @click="printTemDan" color="deep-orange darken-4" dark>
                                <v-icon left>mdi-file-pdf-box</v-icon>In tem dán bìa thư
                            </v-btn>
                        </div>
                    </div>

                    <div class="mt-3">
                        <v-card>
                            <v-card-title class="primary--text">
                                {{ lableTable }}
                                <v-spacer></v-spacer>
                                <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search"
                                    single-line hide-details></v-text-field>
                            </v-card-title>
                            <v-simple-table>
                                <thead>
                                    <tr>
                                        <th class="text-center sttWrap">Chọn</th>
                                        <th class="text-center sttWrap">STT</th>
                                        <th class="timeWrap">Thời gian bắt đầu</th>
                                        <th class="timeWrap">Thời gian kết thúc</th>
                                        <th class="text-center thoiGianBVWrap">Thời gian bảo vệ</th>
                                        <th class="hoTenWrap">Họ và tên</th>
                                        <th>Số điện thoại</th>
                                        <th>Tên đề tài</th>
                                        <th class="gvhdWrap">Giảng viên 1</th>
                                        <th class="gvhdWrap">Giảng viên 2</th>
                                        <th class="thanhVienWrap">Thành viên hội đồng</th>
                                        <th class="chucTrachWrap">Chức trách</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="(item, index) in mergedItems" :key="index">
                                        <!-- Select -->
                                        <td class="text-center" v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            <v-checkbox v-model="item.IsSelect" hide-details dense />
                                        </td>

                                        <!-- STT -->
                                        <td v-if="item.rowspan > 0" :rowspan="item.rowspan" class="text-center">
                                            {{ item.STT }}
                                        </td>

                                        <!-- Thời gian bắt đầu -->
                                        <td v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            <f-time v-model="item.TimeStart" outlined dense hide-details />
                                        </td>

                                        <!-- Thời gian kết thúc -->
                                        <td v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            <f-time v-model="item.TimeEnd" outlined dense hide-details />
                                        </td>

                                        <!-- Thời gian bảo vệ -->
                                        <td class="text-center" v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            {{ item.ThoiGianBaoVe }}
                                        </td>

                                        <!-- Họ và tên học viên -->
                                        <td v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            <span class="green--text">
                                                <b>{{ item.Ho_SV }} {{ item.Ten_SV }}</b>
                                            </span>
                                            <br />
                                            <b>{{ item.Student_ID }}</b>
                                            <span class="amber--text">[{{ item.Lop_ID }}]</span>
                                        </td>

                                        <!-- Số điện thoại -->
                                        <td v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            <span>
                                                <b>{{ item.PhoneNumber }}</b>
                                            </span>
                                            <br />
                                            <span>{{ item.Email }}</span>
                                        </td>

                                        <!-- Tên luận văn -->
                                        <td v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            {{ item.Thesis_Name }}
                                        </td>

                                        <!-- Giảng viên 1 -->
                                        <td v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            {{ item.Thesises_Prof1 }}
                                        </td>

                                        <!-- Giảng viên 2 -->
                                        <td v-if="item.rowspan > 0" :rowspan="item.rowspan">
                                            {{ item.Thesises_Prof2 }}
                                        </td>

                                        <!-- Họ tên Hội đồng -->
                                        <td>{{ item.ThanhVienHoDong_HocViHocHam }}. {{ item.ThanhVienHoiDong_HoTen }}
                                        </td>

                                        <!-- Chức trách -->
                                        <td>
                                            {{ item.ThanhVienHoiDong_ChucTrach }}
                                        </td>
                                    </tr>
                                </tbody>
                            </v-simple-table>
                        </v-card>
                    </div>
                </v-card-text>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
	export default {
		props: ['hearr'],
    data() {
        return {
            HDThanhVien: [],
            OriginalHD: [],
            heArr: [],
            selectNganh: 0,
            existNgayBaoVe: [],
            existGiangVien: [],
            selectThoiGianBV: null,
            diaDiem: 'Phòng Họp, Cơ sở 1, Trường Đại học Lạc Hồng',
            timePicker: '',
            datePicker: '',
            lableTable: 'Danh sách hội đồng',
            search: '',
            nganhType: '1',

            headerTable: [
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
                    text: 'Giờ bắt đầu',
                    value: 'TimeStart',
                    width: 120,
                },
                {
                    text: 'Giờ kết thúc',
                    value: 'TimeEnd',
                    width: 120,
                },
                {
                    text: 'Thời gian bảo vệ',
                    value: 'ThoiGianBaoVe',
                    width: 144,
                    sortable: false,
                    align: 'center',
                },
                {
                    text: 'Họ tên',
                    value: 'Student_ID',
                    width: 200,
                },
                {
                    text: 'SĐT/Email',
                    value: 'PhoneNumber',
                },
                {
                    text: 'Đề tài',
                    value: 'Thesis_Name',
                },
                {
                    text: 'GVHD 1',
                    value: 'Thesises_Prof1',
                    width: 130,
                },
                {
                    text: 'GVHD 2',
                    value: 'Thesises_Prof2',
                    width: 130,
                },
                {
                    text: 'Thành viên hội đồng',
                    value: 'ThanhVienHoiDong_HoTen',
                    width: 170,
                },
                {
                    text: 'Chức trách',
                    value: 'ThanhVienHoiDong_ChucTrach',
                    width: 110,
                },
            ],
        }
    },
    mounted() {},
    computed: {
        CouncilInfoManager: function () {
            return vueData.isCouncilInfoManager
        },
        mergedItems() {
            let countMap = {}
            return this.HDThanhVien.filter((item) => {
                const searchTerm = this.search.toLowerCase()
                return String(item.Student_ID).toLowerCase().includes(searchTerm) || item.Ho_SV.toLowerCase().includes(searchTerm) || item.Ten_SV.toLowerCase().includes(searchTerm)
            }).map((item, index, array) => {
                if (!countMap[item.Student_ID]) {
                    let count = array.filter((i) => i.Student_ID === item.Student_ID).length
                    countMap[item.Student_ID] = count
                    item.rowspan = count // Gán rowspan trực tiếp vào item
                } else {
                    item.rowspan = -1
                }
                return item // Trả về chính item thay vì tạo object mới
            })
        },
    },
    watch: {
        CouncilInfoManager: function (val) {
            if (val) {
                this.onLoadThanhVienHD(0)
                this.getDsNganh()
            }
        },
        selectNganh: function (val) {
            this.selectThoiGianBV = null
            this.timePicker = null
            if (val !== -1) {
                this.onLoadThanhVienHD(val)
            }
        },
        HDThanhVien: function (val) {
            if (val) {
                const ngay = this.OriginalHD.map((item) => item.ThoiGianBaoVe)
                const uniqueNgay = [...new Set(ngay.filter((item) => item))]
                this.existNgayBaoVe = uniqueNgay.map((item) => ({ ThoiGianBaoVe: item }))

                const temp = {}
                val.forEach((item) => {
                    if (item.ThanhVienHoiDong_HoTen) {
                        temp[item.ThanhVienHoiDong_HoTen] = {
                            ThanhVienHoiDong_ID: item.ThanhVienHoiDong_ID,
                            ThanhVienHoDong_HocViHocHam: item.ThanhVienHoDong_HocViHocHam,
                            ThanhVienHoiDong_ChucTrach: item.ThanhVienHoiDong_ChucTrach,
                        }
                    }
                })
                const uniqueGiangVien = Object.keys(temp).map((hoTen) => ({
                    IsSelect: false,
                    ThanhVienHoiDong: hoTen,
                    ThanhVienHoDong_HocViHocHam: temp[hoTen].ThanhVienHoDong_HocViHocHam,
                    ThanhVienHoiDong_ID: temp[hoTen].ThanhVienHoiDong_ID,
                    ThanhVienHoiDong_ChucTrach: temp[hoTen].ThanhVienHoiDong_ChucTrach,
                }))

                this.existGiangVien = uniqueGiangVien
            }
        },
        selectThoiGianBV: function (val) {
            if (val) {
                this.datePicker = moment(val, 'DD/MM/YYYY').format('YYYY-MM-DD')
                this.timePicker = null
                // console.log("xxxxxxxxxx", this.HDThanhVien[17].ThoiGianBaoVe)
                this.HDThanhVien = this.OriginalHD.filter((item) => item.ThoiGianBaoVe === val)
                let stt = 1
                const uniqueStudent = this.removeDuplicatesByStudentID(this.HDThanhVien)
                uniqueStudent.forEach((item) => {
                    for (let i = 0; i < this.HDThanhVien.length; i++) {
                        if (item.Student_ID === this.HDThanhVien[i].Student_ID) {
                            this.HDThanhVien[i].STT = stt
                        }
                    }
                    stt++
                })

                this.lableTable = `Danh sách hội đồng: ${uniqueStudent.length} đề tài`
            }
        },
        timePicker: function (val) {
            if (val) {
                console.log('HDThanhVien', this.HDThanhVien)
                const uniqueThanhVien = this.distinctByStudentID(this.HDThanhVien)
                // console.log('uniqueThanhVien', uniqueThanhVien)
                let currentTime = this.parseTime(val)

                uniqueThanhVien.forEach((item) => {
                    const timeStart = this.formatTime(currentTime) // Format thành "HH:mm"
                    currentTime.setMinutes(currentTime.getMinutes() + 30) // Cộng thêm 30 phút
                    const timeEnd = this.formatTime(currentTime)
                    this.HDThanhVien.forEach((thanhVien) => {
                        if (thanhVien.Student_ID === item.Student_ID) {
                            thanhVien.TimeStart = timeStart
                            thanhVien.TimeEnd = timeEnd
                        }
                    })
                })
            }
        },
    },
    methods: {
        updateIsSelect(arr) {
            // Bước 1: Tạo danh sách Student_ID có IsSelect === false
            let studentIdsToUpdate = new Set(arr.filter((item) => !item.IsSelect).map((item) => item.Student_ID))

            // Bước 2: Duyệt mảng và cập nhật IsSelect thành false nếu Student_ID có trong danh sách
            return arr.map((item) => {
                if (studentIdsToUpdate.has(item.Student_ID)) {
                    return { ...item, IsSelect: false } // Tạo object mới để Vue re-render
                }
                return item
            })
        },
        findHoiDongByID(hoiDongID) {
            return new Promise((resolve, reject) => {
                ajaxCALL(
                    '/HoiDong_Get_ByHoiDongID',
                    {
                        HoiDong_ID: hoiDongID,
                    },
                    (res) => {
                        resolve(res.data) // Resolve promise với dữ liệu
                    },
                    (error) => {
                        console.log('fail to find hoi dong by ID', error.responseJSON.Message)
                        reject(error) // Reject promise nếu có lỗi
                    },
                )
            })
        },
        async printExcelDSBVLV() {
            const filterHDThanhVien = this.updateIsSelect(this.HDThanhVien).filter((item) => item.IsSelect)

            if (filterHDThanhVien.length > 0) {
                let stt = 1
                const uniqueStudent = this.removeDuplicatesByStudentID(filterHDThanhVien).sort((a, b) => {
                    if (!a.Ten_SV) return 1 // Đẩy `null` hoặc `undefined` xuống cuối
                    if (!b.Ten_SV) return -1
                    return a.Ten_SV.localeCompare(b.Ten_SV)
                })
                uniqueStudent.forEach((item) => {
                    for (let i = 0; i < filterHDThanhVien.length; i++) {
                        if (item.Student_ID === filterHDThanhVien[i].Student_ID) {
                            filterHDThanhVien[i].STT = stt
                        }
                    }
                    stt++
                })

                console.log('filterArr', uniqueStudent)
                const ThanhVienArr = []

                for (const item of uniqueStudent) {
                    try {
                        const data = await this.findHoiDongByID(item.HoiDongID)
                        console.log('data', data)

                        if (data) {
                            // Thông tin hội đồng
                            const HoiDongThanhVien = data[1]
                            // Array thành viên trong hội dồng
                            const obj = {
                                STT: item.STT,
                                TimeStart: item.TimeStart,
                                TimeEnd: item.TimeEnd,
                                MSHV: item.Student_ID,
                                Ho: item.Ho_SV,
                                Ten: item.Ten_SV,
                                DeTai: item.Thesis_Name,
                                GVHD1: item.Thesises_Prof1,
                                GVHD2: item.Thesises_Prof2 ? item.Thesises_Prof2.trim() : '',
                                LopID: item.Lop_ID,
                                Nganh_ID: item.Nganh_ID,
                                ChuTich: '',
                                PhanBien1: '',
                                PhanBien2: '',
                                ThuKy: '',
                                UyVien: '',
                            }

                            const chucTrachMapping = {
                                'Chủ tịch': 'ChuTich',
                                'Phản biện 1': 'PhanBien1',
                                'Phản biện 2': 'PhanBien2',
                                'Phản biện': 'PhanBien1',
                                'Thư ký': 'ThuKy',
                                'Ủy viên': 'UyVien',
                            }

                            HoiDongThanhVien.forEach((tv) => {
                                const key = chucTrachMapping[tv.ChucTrach]
                                if (key) {
                                    obj[key] = `${tv.HocViHocHam}. ${tv.HoTenGiangVien}`
                                }
                            })

                            ThanhVienArr.push(obj)
                        }
                    } catch (error) {
                        console.error('Error:', error)
                    }
                }
                console.log('ThanhVienArr', ThanhVienArr)

                const apiData = {
                    Nganh: this.getTenNganh(this.selectNganh).toUpperCase() ?? '',
                    NganhID: this.selectNganh.toString() ?? '',
                    NgayBaoVe: this.formatCustomDate(this.selectThoiGianBV),
                    ProcessID: parseInt(this.nganhType),
                    DanhSach: ThanhVienArr,
                }
                console.log('apiData', apiData)

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
                fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/bv-luan-van', requestOptions)
                    .then((response) => response.blob())
                    .then((blob) => {
                        var url = window.URL.createObjectURL(blob)
                        var a = document.createElement('a')
                        a.href = url
                        a.download = `Danh sach BVLV.xlsx`
                        document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
                        a.click()
                        a.remove() //afterwards we remove the element again
                    })
                    .catch((error) => console.error(error))
            } else {
                Vue.$toast.error(`Danh sách chưa có dữ liệu hội đồng`, { position: 'top' })
            }
        },
        distinctByStudentID(arr) {
            const unique = new Map() // Dùng Map để lưu trữ các phần tử duy nhất
            arr.forEach((item) => {
                if (!unique.has(item.Student_ID)) {
                    unique.set(item.Student_ID, item) // Thêm phần tử nếu Student_ID chưa tồn tại
                }
            })
            return Array.from(unique.values()) // Trả về mảng các phần tử duy nhất
        },
        parseTime(timeStr) {
            // Chuyển chuỗi "HH:mm" thành đối tượng Date
            const [hours, minutes] = timeStr.split(':').map(Number)
            const date = new Date()
            date.setHours(hours, minutes, 0, 0)
            return date
        },
        formatTime(date) {
            // Chuyển đổi Date thành chuỗi "HH:mm"
            const hours = String(date.getHours()).padStart(2, '0')
            const minutes = String(date.getMinutes()).padStart(2, '0')
            return `${hours}:${minutes}`
        },
        openTemBuuDien() {
            const filterHDThanhVien = this.updateIsSelect(this.mergedItems)

            // Nếu this.existGiangVien không phải Map, chuyển đổi nó thành Map
            if (!(this.existGiangVien instanceof Map)) {
                this.existGiangVien = new Map(this.existGiangVien.map((item) => [item.ThanhVienHoiDong_ID, item]))
            }

            // Tạo Set để lưu các ID đã cập nhật thành true
            let updatedToTrue = new Set()

            // Duyệt danh sách để cập nhật IsSelect trong existGiangVien
            filterHDThanhVien.forEach((item) => {
                if (item.IsSelect === true && this.existGiangVien.has(item.ThanhVienHoiDong_ID)) {
                    this.existGiangVien.get(item.ThanhVienHoiDong_ID).IsSelect = true
                    updatedToTrue.add(item.ThanhVienHoiDong_ID) // Đánh dấu đã set true
                } else if (item.IsSelect === false && this.existGiangVien.has(item.ThanhVienHoiDong_ID)) {
                    if (!updatedToTrue.has(item.ThanhVienHoiDong_ID)) {
                        // Chỉ update false nếu chưa từng set true trước đó
                        this.existGiangVien.get(item.ThanhVienHoiDong_ID).IsSelect = false
                    }
                }
            })

            // Chuyển Map thành Array
            this.existGiangVien = Array.from(this.existGiangVien.values())

            console.log('result zzzz', this.existGiangVien)
            console.log('danh sach hd', filterHDThanhVien)

            vueData.isTemBuuKienDialog = true
        },
        printTemDan() {
            let dataArr = []
            let allGVChucTrach = []
            console.log('this.HDThanhVien', this.HDThanhVien)

            this.HDThanhVien.forEach((item) => {
                allGVChucTrach.push({
                    ThanhVienHoiDong_ID: item.ThanhVienHoiDong_ID,
                    ThanhVienHoDong_HocViHocHam: item.ThanhVienHoDong_HocViHocHam,
                    ThanhVienHoiDong_HoTen: item.ThanhVienHoiDong_HoTen,
                    ThanhVienHoiDong_ChucTrach: item.ThanhVienHoiDong_ChucTrach,
                })
            })
            this.existGiangVien.forEach((item) => {
                const filter = this.HDThanhVien.filter((thanhVien) => item.ThanhVienHoiDong === thanhVien.ThanhVienHoiDong_HoTen)
                dataArr.push({
                    ThanhVienHoiDong_ID: item.ThanhVienHoiDong_ID,
                    HoTenThanhVien: item.ThanhVienHoDong_HocViHocHam + '. ' + item.ThanhVienHoiDong,
                    SoCuonLuanVan: filter.length,
                    ChucTrach: item.ThanhVienHoiDong_ChucTrach,
                })
            })
            console.log('this.existGiangVienxxxxx', this.existGiangVien)
            console.log('dataArrxxxxxxx', dataArr)
            // Xóa mục khỏi localStorage trước khi lưu trữ mới
            localStorage.removeItem('JSON_PRINT_PDF_TEM')
            localStorage.setItem('JSON_PRINT_PDF_TEM', JSON.stringify(dataArr))

            localStorage.removeItem('JSON_PRINT_ALL_GV_CHUC_TRACH')
            localStorage.setItem('JSON_PRINT_ALL_GV_CHUC_TRACH', JSON.stringify(allGVChucTrach))

            console.log('dataArr', dataArr)
            const url = `https://qldetaisdh.lhu.edu.vn/rpt_Tem_Dan`
            const newTab = window.open(url, '_blank')
            newTab.focus()
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

        async printAllFile() {
            let checkDateTimeNull = false

            if (!this.timePicker) {
                checkDateTimeNull = true
                Vue.$toast.error(`Không được bỏ trống giờ bắt đầu`, { position: 'top' })
            }
            if (!this.datePicker) {
                checkDateTimeNull = true
                Vue.$toast.error(`Không được bỏ trống ngày bắt đầu`, { position: 'top' })
            }

            if (!checkDateTimeNull) {
                const currentDate = new Date()
                const day = currentDate.getDate()
                const month = currentDate.getMonth() + 1
                const year = currentDate.getFullYear()
                // NV, GV
                const userID = parseInt(vueData.user.UserID?.slice(-4))
                const [hour, minute] = this.timePicker.split(':')

                let zip = new JSZip()

                // 1) Lấy các bản ghi đang được chọn để xuất file.
                // map(...spread) để clone object, tránh chỉnh sửa trực tiếp dữ liệu gốc trong this.HDThanhVien.
                const filterHDThanhVien = this.updateIsSelect(this.HDThanhVien)
                    .filter((item) => item.IsSelect)
                    .map((item) => ({ ...item }))

                // 2) Gom nhóm theo Student_ID để xác định "nguồn giờ" dùng chung cho từng học viên.
                // Quy tắc chọn nguồn giờ:
                // - Nếu Student_ID chưa có trong map: lấy phần tử đầu tiên làm mặc định.
                // - Nếu gặp dòng có chức trách "Chủ tịch": ghi đè để ưu tiên giờ của Chủ tịch.
                const timeRangeByStudentId = filterHDThanhVien.reduce((acc, item) => {
                    if (!acc[item.Student_ID]) {
                        acc[item.Student_ID] = item
                        return acc
                    }

                    if (item.ThanhVienHoiDong_ChucTrach === 'Chủ tịch') {
                        acc[item.Student_ID] = item
                    }

                    return acc
                }, {})

                // 3) Đồng bộ lại TimeStart/TimeEnd cho mọi dòng trùng Student_ID.
                // matchedItem là đại diện đã chọn ở bước 2 (ưu tiên Chủ tịch).
                const normalizedHDThanhVien = filterHDThanhVien.map((item) => {
                    const matchedItem = timeRangeByStudentId[item.Student_ID]

                    return {
                        ...item,
                        TimeStart: matchedItem?.TimeStart || item.TimeStart,
                        TimeEnd: matchedItem?.TimeEnd || item.TimeEnd,
                    }
                })

                for (const giangVien of this.existGiangVien) {
                    let excelDataArr = []
                    let stt = 1
                    // 4) Từ đây dùng normalizedHDThanhVien để dữ liệu xuất ra đã có giờ thống nhất theo từng Student_ID.
                    for (const hdThanhVien of normalizedHDThanhVien) {
                        if (hdThanhVien.ThanhVienHoiDong_HoTen === giangVien.ThanhVienHoiDong) {
                            excelDataArr.push({
                                STT: stt,
                                TimeStart: hdThanhVien.TimeStart,
                                TimeEnd: hdThanhVien.TimeEnd,
                                MSHV: hdThanhVien.Student_ID,
                                Khoa: hdThanhVien.Nien_Khoa,
                                Ho: hdThanhVien.Ho_SV,
                                Ten: hdThanhVien.Ten_SV,
                                DeTai: hdThanhVien.Thesis_Name,
                                GVHD1: hdThanhVien.Thesises_Prof1?.trim(),
                                GVHD2: hdThanhVien.Thesises_Prof2 ? hdThanhVien.Thesises_Prof2.trim() : '',
                                ThanhVien: hdThanhVien.ThanhVienHoDong_HocViHocHam + '. ' + hdThanhVien.ThanhVienHoiDong_HoTen,
                                ChucTrach: hdThanhVien.ThanhVienHoiDong_ChucTrach,
                            })
                            stt++
                        }
                    }

                    console.log('excelDataArr', excelDataArr)

                    excelDataArr = [...new Map(excelDataArr.map((item) => [item.MSHV, item])).values()]

                    const excelApiData = {
                        Nganh: this.getTenNganh(this.selectNganh).toUpperCase(),
                        NgayBaoVe: this.formatCustomDate(this.selectThoiGianBV),
                        DanhSach: this.resetSTT(excelDataArr),
                        ProcessID: parseInt(this.nganhType),
                    }

                    const wordApiData = {
                        HoTen: giangVien.ThanhVienHoDong_HocViHocHam + '. ' + giangVien.ThanhVienHoiDong,
                        Nganh: this.getTenNganh(this.selectNganh),
                        Gio: hour,
                        Phut: minute,
                        NgayBatDau: this.formatCustomDate(this.datePicker),
                        DiaDiem: this.diaDiem,
                        Ngay: day.toString().padStart(2, '0'),
                        Thang: month === 1 || month === 2 ? `0${month}` : month.toString(),
                        Nam: year.toString(),
                        LuuVT: userID,
                        ProcessID: parseInt(this.nganhType),
                    }

                    const myHeaders = new Headers()
                    myHeaders.append('Content-Type', 'application/json')

                    const excelRequestOptions = {
                        method: 'POST',
                        headers: myHeaders,
                        body: JSON.stringify(excelApiData),
                        redirect: 'follow',
                    }

                    const wordRequestOptions = {
                        method: 'POST',
                        headers: myHeaders,
                        body: JSON.stringify(wordApiData),
                        redirect: 'follow',
                    }

                    try {
                        // http://localhost:5244
                        // https://gendocx.iotsoftvn.com
                        const excelResponse = await fetch('https://gendocx.iotsoftvn.com/api/generate-docx/gui-bai', excelRequestOptions)
                        const excelBlob = await excelResponse.blob()

                        const wordResponse = await fetch('https://gendocx.iotsoftvn.com/api/generate-docx/thu-moi', wordRequestOptions)
                        const wordBlob = await wordResponse.blob()

                        const smallZip = new JSZip()
                        smallZip.file(`${this.selectThoiGianBV.replace(/\//g, '-')}_Thong_ke_hoi_dong_${excelDataArr[0].ThanhVien}.xlsx`, excelBlob)
                        smallZip.file(`${this.selectThoiGianBV.replace(/\//g, '-')}_Thu_moi_${giangVien.ThanhVienHoiDong}.docx`, wordBlob)

                        const smallZipContent = await smallZip.generateAsync({ type: 'blob' })
                        zip.file(`${giangVien.ThanhVienHoiDong}.zip`, smallZipContent)
                    } catch (error) {
                        console.error(error)
                    }
                }

                zip.generateAsync({ type: 'blob' }).then((content) => {
                    saveAs(content, `${this.selectThoiGianBV}_file thành viên hội đồng.zip`)
                })
            }
        },

        getTenNganh(nganhID) {
            const nganhName = this.heArr.find((item) => item.NganhID == nganhID)
            if (nganhName) {
                return removeKhoaID(nganhName.TenNganh)
            } else {
                Vue.$toast.error(` Không tìm thấy tên ngành`, { position: 'top' })
            }
        },

        resetSTT(ds) {
            ds.forEach((item, index) => {
                item.STT = index + 1
            })
            return ds
        },

        removeDuplicatesByStudentID(array) {
            const seen = new Set()
            const uniqueArray = array.filter((item) => {
                const duplicate = seen.has(item.Student_ID)
                seen.add(item.Student_ID)
                return !duplicate
            })
            return uniqueArray // Trả về độ dài của mảng đã loại bỏ trùng lặp
        },

        getNgayBaoVe() {
            const ngay = this.HDThanhVien.map((item) => item.ThoiGianBaoVe)
            this.existNgayBaoVe = ngay.filter((item) => item).map((item) => ({ ThoiGianBaoVe: item }))
        },
        onLoadThanhVienHD(nganhID) {
            const priorityOrder = ['Chủ tịch', 'Phản biện 1', 'Phản biện 2', 'Ủy viên', 'Thư ký']

            ajaxCALL(
                '/HoiDong_DeTai_Get_ThanhVien',
                {
                    NganhID: nganhID,
                },
                (res) => {
                    this.HDThanhVien = res.data
                        .map((item) => {
                            return {
                                ...item,
                                IsSelect: true,
                                ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null,
                                TimeStart: '',
                                TimeEnd: '',
                            }
                        })
                        // Kết quả = 2 là bảo vệ thất bại
                        .filter((item) => item.KetQuaHoiDong !== 2)
                        .sort((a, b) => {
                            // Kiểm tra nếu Ten_SV của a hoặc b là null hoặc undefined, đẩy chúng xuống cuối
                            if (!a.Ten_SV && !b.Ten_SV) return 0 // Nếu cả 2 đều null hoặc undefined, không thay đổi thứ tự
                            if (!a.Ten_SV) return 1 // Nếu a.Ten_SV là null hoặc undefined, đẩy xuống cuối
                            if (!b.Ten_SV) return -1 // Nếu b.Ten_SV là null hoặc undefined, đẩy xuống cuối

                            // Nếu cả hai Ten_SV đều hợp lệ, so sánh chúng
                            return a.Ten_SV.localeCompare(b.Ten_SV)
                        })
                        .sort((a, b) => {
                            // Sắp xếp lần thứ hai dựa vào Student_ID và ThanhVienHoiDong_ChucTrach
                            if (a.Student_ID === b.Student_ID) {
                                const aIndex = priorityOrder.indexOf(a.ThanhVienHoiDong_ChucTrach)
                                const bIndex = priorityOrder.indexOf(b.ThanhVienHoiDong_ChucTrach)
                                return aIndex - bIndex // Sắp xếp theo thứ tự ưu tiên
                            }
                        })
                        .reduce(
                            (acc, item) => {
                                // Biến để theo dõi STT và Student_ID cuối cùng
                                if (!acc.previousStudentID || acc.previousStudentID !== item.Student_ID) {
                                    acc.STT++ // Tăng STT khi gặp Student_ID mới
                                    acc.previousStudentID = item.Student_ID // Cập nhật Student_ID cuối cùng
                                }
                                acc.result.push({
                                    ...item,
                                    STT: acc.STT, // Gán STT hiện tại
                                })
                                return acc
                            },
                            { STT: 0, previousStudentID: null, result: [] },
                        ).result // Trả về danh sách kết quả

                    this.OriginalHD = res.data
                        .map((item) => {
                            return {
                                ...item,
                                IsSelect: true,
                                ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null,
                                TimeStart: '',
                                TimeEnd: '',
                            }
                        })
                        // Kết quả = 2 là bảo vệ thất bại
                        .filter((item) => item.KetQuaHoiDong !== 2)
                        .sort((a, b) => {
                            // Kiểm tra nếu Ten_SV của a hoặc b là null hoặc undefined, đẩy chúng xuống cuối
                            if (!a.Ten_SV && !b.Ten_SV) return 0 // Nếu cả 2 đều null hoặc undefined, không thay đổi thứ tự
                            if (!a.Ten_SV) return 1 // Nếu a.Ten_SV là null hoặc undefined, đẩy xuống cuối
                            if (!b.Ten_SV) return -1 // Nếu b.Ten_SV là null hoặc undefined, đẩy xuống cuối

                            // Nếu cả hai Ten_SV đều hợp lệ, so sánh chúng
                            return a.Ten_SV.localeCompare(b.Ten_SV)
                        })
                        .sort((a, b) => {
                            // Sắp xếp lần thứ hai dựa vào Student_ID và ThanhVienHoiDong_ChucTrach
                            if (a.Student_ID === b.Student_ID) {
                                const aIndex = priorityOrder.indexOf(a.ThanhVienHoiDong_ChucTrach)
                                const bIndex = priorityOrder.indexOf(b.ThanhVienHoiDong_ChucTrach)
                                return aIndex - bIndex // Sắp xếp theo thứ tự ưu tiên
                            }
                        })
                        .reduce(
                            (acc, item) => {
                                // Biến để theo dõi STT và Student_ID cuối cùng
                                if (!acc.previousStudentID || acc.previousStudentID !== item.Student_ID) {
                                    acc.STT++ // Tăng STT khi gặp Student_ID mới
                                    acc.previousStudentID = item.Student_ID // Cập nhật Student_ID cuối cùng
                                }
                                acc.result.push({
                                    ...item,
                                    STT: acc.STT, // Gán STT hiện tại
                                })
                                return acc
                            },
                            { STT: 0, previousStudentID: null, result: [] },
                        ).result // Trả về danh sách kết quả

                    const uniqueDeTai = Array.from(new Set(this.HDThanhVien.map((item) => item.Student_ID)))
                    this.lableTable = `Danh sách hội đồng: ${uniqueDeTai.length} đề tài`
                    console.log('this.HDThanhVien', this.HDThanhVien)
                },
                (error) => {
                    Vue.$toast.error(` ${error.responseJSON ? error.responseJSON.Message : error.message}`, { position: 'top' })
                    console.log('Fail to load hoi dong thanh vien', error)
                },
            )
        },
        async getDsNganh() {
            this.heArr = await getNganhCaoHocPromise({ hasAllOption: true });
        },
        closeDialog() {
            vueData.isCouncilInfoManager = false
            this.selectNganh = 0
            this.selectThoiGianBV = null
            this.timePicker = null
            this.datePicker = null
            this.HDThanhVien = []
        },
    },
	}
</script>