function initCTKD() {
    const initChiTietKiemDem = {
        To_500000: 0,
        To_200000: 0,
        To_100000: 0,
        To_50000: 0,
        To_20000: 0,
        To_10000: 0,
        To_5000: 0,
        To_2000: 0,
        To_1000: 0,
        To_500: 0,
    }
    let ctkiemdem = localStorage.getItem("ChiTietKiemDem")
    if (ctkiemdem) {
        ctkiemdem = JSON.parse(localStorage.getItem("ChiTietKiemDem"))
    } else {
        localStorage.setItem("ChiTietKiemDem", JSON.stringify(initChiTietKiemDem))
        ctkiemdem = initChiTietKiemDem
    }
    vueData.To_500000 = parseInt(ctkiemdem.To_500000)
    vueData.To_200000 = parseInt(ctkiemdem.To_200000)
    vueData.To_100000 = parseInt(ctkiemdem.To_100000)
    vueData.To_50000 = parseInt(ctkiemdem.To_50000)
    vueData.To_20000 = parseInt(ctkiemdem.To_20000)
    vueData.To_10000 = parseInt(ctkiemdem.To_10000)
    vueData.To_5000 = parseInt(ctkiemdem.To_5000)
    vueData.To_2000 = parseInt(ctkiemdem.To_2000)
    vueData.To_1000 = parseInt(ctkiemdem.To_1000)
    vueData.To_500 = parseInt(ctkiemdem.To_500)
}
Vue.component("nav_component", {
    template: /*html*/ `
        <v-row class="v-toolbar__title white--text">
            <v-col cols="4" style="display: flex; align-items: center;">
                <v-icon @click="window.location.href = '/'" class="float-left px-3" color="white">mdi-home</v-icon>
            </v-col>
            <v-col cols="4" class="text-center">ZEN EORDER - KẾT CA</v-col>
       </v-row>
    `,
})
Vue.component("info_component", {
    template: /*html*/ `
        <v-row>
            <v-col cols="2"></v-col>
            <v-col cols="8" class="page-section">
                <v-row>
                    <v-col cols="12" class="text-center">
                        <h3 class='primary--text mt-3'>PHIẾU KẾT CA {{CT_KetCa?.TenCuaHang}}</h3>
                        <div class="d-flex justify-center align-center">
                            <span>Đóng ca: <b>Ngày {{CT_KetCa?.NgayKetCa}} {{CT_KetCa?.GioKetCa}}</b></span>
                            <span class="ml-5">Nhân viên kết ca: <b>{{CT_KetCa?.NhanVienKetCa}}</b></span>
                            <div style="width: 200px; gap: 7px" class="pl-5 d-flex flex-row justify-center align-center">
                                <span>Ca:</span>
                                <v-select label="" outlined dense v-model="vueData.Ca" :items="DSCa" item-value="Id" item-text="Ca" hide-details />
                            </div>
                        </div>
                    </v-col>
                    <v-col cols="4">
                         <h4 class='primary--text mb-1 text-center'>TỔNG THU THỰC</h4>
                         <v-simple-table dense>
                            <template v-slot:default>
                                <thead>
                                    <tr>
                                        <th class="text-center">Hình thức</th>
                                        <th class="text-center">Tổng tiền</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>Tiền mặt (A)</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_TienMat.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td>Chuyển khoản</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_CK.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td>Quẹt thẻ</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_QuetThe.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td>ShopeeFood</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_SPF.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td>Xanh SM</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_XSM.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td>Grab</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_GRAB.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td>HT1</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_HT1.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td>HT2</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_HT2.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td>HT3</td>
                                        <td class="text-right">{{ CT_Tong.KhachTra_HT3.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr>
                                        <td><b>Tổng</b></td>
                                        <td class="text-right"><b>{{ CT_Tong.TongDoanhThu.toLocaleString('vi-vn') }}</b></td>
                                    </tr>
                                    <tr>
                                        <td class="primary--text"><b>ZEN đã dùng</b></td>
                                        <td class="primary--text text-right"><b>{{ CT_Tong.KhachTra_Zen.toLocaleString('vi-vn') }}</b></td>
                                    </tr>
                                </tbody>
                            </template>
                        </v-simple-table>
                    </v-col>
                    <v-col cols="8"><money-component/></v-col>
                    <v-col cols="4" class="py-2 d-flex" style="align-items:center">
                        <span><b>Chênh lệch (B - A): <span class="red--text">{{(TongTienKiemDem - CT_Tong.KhachTra_TienMat).toLocaleString('vi-vn')}}</span></b></span>
                    </v-col>
                    <v-col cols="6" class="py-2 d-flex" style="align-items:center">
                        <span><b>Tổng tiền (B): <span>{{TongTienKiemDem.toLocaleString('vi-vn')}}</span></b></span>
                    </v-col>
                    <v-col cols="2" class="py-2 d-flex" style="justify-content:right" >
                        <v-btn @click="onLuuTamChiTietKiemDem" color="primary" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu tạm kiểm đếm</v-btn>
                    </v-col>
                    <v-col cols="12" class="py-2">
                        <v-textarea auto-grow rows="1" v-model="vueData.GhiChu" label="Ghi chú" outlined dense hide-details></v-textarea>
                    </v-col>
                    <v-col cols="4">
                        <h4 class='primary--text mb-1 text-center'>DOANH THU THEO NHÓM (BAO GỒM ZEN)</h4>
                        <v-simple-table dense>
                            <template v-slot:default>
                                <thead>
                                    <tr>
                                        <th class="text-center">Nhóm</th>
                                        <th class="text-right">Tổng tiền</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="item in DS_NhomSanPham">
                                        <td>{{ item.TenNhomSanPham }}</td>
                                        <td class="text-right">{{ item.ThanhTien.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr v-if="DS_NhomSanPham.length === 0">
                                        <td colspan="2" class="text-center">Không tìm thấy dữ liệu</td>
                                    </tr>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <td class="text-center font-weight-bold">Tổng</td>
                                        <td class="text-right font-weight-bold">{{DS_NhomSanPham_Sum.toLocaleString('vi-vn')}}</td>
                                    </tr>
                                </tfoot>
                            </template>
                        </v-simple-table>
                    </v-col>
                    <v-col cols="8" class="text-center">
                        <h4 class='primary--text mb-1'>HÓA ĐƠN CHƯA THANH TOÁN</h4>
                        <v-simple-table dense>
                            <template v-slot:default>
                                <thead>
                                    <tr>
                                        <th class="text-center">TK Order</th>
                                        <th class="text-center">SL đơn</th>
                                        <th class="text-right">Tổng tiền</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="item in DS_ChuaThanhToan">
                                        <td>{{ item.NhanVienThemMoi }}</td>
                                        <td>{{ item.SoLuongDon }}</td>
                                        <td class="text-right">{{ item.TongTien.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr v-if="DS_ChuaThanhToan.length === 0">
                                        <td colspan="3" class="text-center">Không tìm thấy dữ liệu</td>
                                    </tr>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <td class="text-center font-weight-bold">Tổng</td>
                                        <td class="text-center font-weight-bold">{{DS_ChuaThanhToan_Count.toLocaleString('vi-vn')}}</td>
                                        <td class="text-right font-weight-bold">{{DS_ChuaThanhToan_Sum.toLocaleString('vi-vn')}}</td>
                                    </tr>
                                </tfoot>
                            </template>
                        </v-simple-table>
                    </v-col>
                    <v-col cols="12" class="text-center">
                        <h4 class='primary--text mb-1'>HÓA ĐƠN HỦY</h4>
                        <v-simple-table dense>
                            <template v-slot:default>
                                <thead>
                                    <tr>
                                        <th class="text-center">Mã hóa đơn</th>
                                        <th class="text-center">Tổng tiền</th>
                                        <th class="text-center">Ghi chú</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="item in DS_HoaDonHuy">
                                        <td class="text-center">{{ item.MaHoaDon }}</td>
                                        <td class="text-center">{{ item.TienPhaiTra.toLocaleString('vi-vn') }}</td>
                                        <td class="text-center">{{ item.GhiChu }}</td>
                                    </tr>
                                    <tr v-if="DS_HoaDonHuy.length === 0">
                                        <td colspan="3" class="text-center">Không tìm thấy dữ liệu</td>
                                    </tr>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <td class="text-center font-weight-bold">Tổng</td>
                                        <td class="text-center font-weight-bold">{{DS_HoaDonHuy_Sum.toLocaleString('vi-vn')}}</td>
                                        <td></td>
                                    </tr>
                                </tfoot>
                            </template>
                        </v-simple-table>
                    </v-col>
                    <v-col cols="12" class="text-center">
                        <h4 class='primary--text mb-1'>MÓN HỦY</h4>
                        <v-simple-table dense>
                            <template v-slot:default>
                                <thead>
                                    <tr>
                                        <th class="text-center">Mã hóa đơn</th>
                                        <th class="text-center">Tên món</th>
                                        <th class="text-center">Trạng thái</th>
                                        <th class="text-center">Ghi chú</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="item in DS_MonHuy">
                                        <td class="text-center">{{ item.MaHoaDon }}</td>
                                        <td class="text-center">{{ item.TenHienThi }}</td>
                                        <td class="text-center">{{ item.TrangThaiMon }}</td>
                                        <td class="text-center">{{ item.GhiChu }}</td>
                                    </tr>
                                    <tr v-if="DS_MonHuy.length === 0">
                                        <td colspan="4" class="text-center">Không tìm thấy dữ liệu</td>
                                    </tr>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <td colspan="3" class="text-center font-weight-bold">Tổng</td>
                                        <td class="text-center font-weight-bold">{{DS_MonHuy.length}} món</td>
                                    </tr>
                                </tfoot>
                            </template>
                        </v-simple-table>
                    </v-col>
                    <v-col cols="12" class="text-center">
                        <h4 class='primary--text mb-1'>CHI TIẾT MÓN (BAKERY)</h4>
                        <v-simple-table dense>
                            <template v-slot:default>
                                <thead>
                                    <tr>
                                        <th class="text-center">Tên sản phẩm</th>
                                        <th class="text-center">Đơn vị</th>
                                        <th class="text-right">Số lượng</th>
                                        <th class="text-right">Đơn giá</th>
                                        <th class="text-right">Doanh thu</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="item in DS_SanPham">
                                        <td class="text-center">{{ item.TenSanPham }}</td>
                                        <td class="text-center">{{ item.TenDonViTinh }}</td>
                                        <td class="text-right">{{ item.SoLuong.toLocaleString('vi-vn') }}</td>
                                        <td class="text-right">{{ item.DonGia.toLocaleString('vi-vn') }}</td>
                                        <td class="text-right">{{ item.ThanhTien.toLocaleString('vi-vn') }}</td>
                                    </tr>
                                    <tr v-if="DS_SanPham.length === 0">
                                        <td colspan="5" class="text-center">Không tìm thấy dữ liệu</td>
                                    </tr>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <td colspan="4" class="text-center font-weight-bold">Tổng</td>
                                        <td class="text-right font-weight-bold">{{DS_SanPham_Sum.toLocaleString('vi-vn')}}</td>
                                    </tr>
                                </tfoot>
                            </template>
                        </v-simple-table>
                    </v-col>
                    <v-col cols="12" class="text-center my-3">
                        <v-btn color='error' @click="onConfirm" elevation="0"><v-icon left>mdi-cash-lock</v-icon>Thực hiện kết ca</v-btn>
                    </v-col>
                </v-row>
            </v-col>
            <v-col cols="3"></v-col>
       </v-row>
    `,
    data() {
        return {
            DSCa: [
                { Id: 0, Ca: "Không" },
                { Id: 1, Ca: "Sáng" },
                { Id: 2, Ca: "Tối" },
                { Id: 3, Ca: "Đêm" },
            ],
        }
    },
    methods: {
        onLuuTamChiTietKiemDem: function () {
            let param = {
                To_500000: checkNumber(vueData.To_500000) ? vueData.To_500000 : 0,
                To_200000: checkNumber(vueData.To_200000) ? vueData.To_200000 : 0,
                To_100000: checkNumber(vueData.To_100000) ? vueData.To_100000 : 0,
                To_50000: checkNumber(vueData.To_50000) ? vueData.To_50000 : 0,
                To_20000: checkNumber(vueData.To_20000) ? vueData.To_20000 : 0,
                To_10000: checkNumber(vueData.To_10000) ? vueData.To_10000 : 0,
                To_5000: checkNumber(vueData.To_5000) ? vueData.To_5000 : 0,
                To_2000: checkNumber(vueData.To_2000) ? vueData.To_2000 : 0,
                To_1000: checkNumber(vueData.To_1000) ? vueData.To_1000 : 0,
                To_500: checkNumber(vueData.To_500) ? vueData.To_500 : 0,
            }
            localStorage.setItem("ChiTietKiemDem", JSON.stringify(param))
            Vue.$toast.success("Lưu tạm chi tiết kiểm đếm thành công", { position: "top" })
        },
        onConfirm: function () {
            confirm({
                title: "Xác nhận kết ca",
                content: `Bạn có chắc muốn kết ca?`,
                action: function () {
                    const params = {
                        CuaHangID: vueData.CuaHangID,
                        GhiChu: vueData.GhiChu ?? "",
                        Ca: vueData.Ca,
                        To_500000: checkNumber(vueData.To_500000) ? vueData.To_500000 : 0,
                        To_200000: checkNumber(vueData.To_200000) ? vueData.To_200000 : 0,
                        To_100000: checkNumber(vueData.To_100000) ? vueData.To_100000 : 0,
                        To_50000: checkNumber(vueData.To_50000) ? vueData.To_50000 : 0,
                        To_20000: checkNumber(vueData.To_20000) ? vueData.To_20000 : 0,
                        To_10000: checkNumber(vueData.To_10000) ? vueData.To_10000 : 0,
                        To_5000: checkNumber(vueData.To_5000) ? vueData.To_5000 : 0,
                        To_2000: checkNumber(vueData.To_2000) ? vueData.To_2000 : 0,
                        To_1000: checkNumber(vueData.To_1000) ? vueData.To_1000 : 0,
                        To_500: checkNumber(vueData.To_500) ? vueData.To_500 : 0,
                    }
                    ajaxCALL("/eorder/KetCa_Insert_V2", params, (res) => {
                        if (res.data[0].KetCaLogID > 0) {
                            window.open(`/ket-ca-xuat-file?id=${res.data[0].KetCaLogID}&out=1&download=1`)
                            localStorage.removeItem("ChiTietKiemDem")
                            setTimeout(function () {
                                window.location.reload()
                            }, 2000)
                        }
                    })
                },
            })
        },
    },
    computed: {
        CT_KetCa: function () {
            return vueData.CT_KetCa[0][0]
        },
        DS_NhomSanPham: function () {
            return vueData.CT_KetCa[1]
        },
        DS_NhomSanPham_Sum: function () {
            let sum = 0
            if (vueData.CT_KetCa[1].length > 0) {
                vueData.CT_KetCa[1].forEach((item) => {
                    sum += item.ThanhTien
                })
            }
            return sum
        },
        DS_SanPham: function () {
            return vueData.CT_KetCa[2]
        },
        DS_SanPham_Sum: function () {
            let sum = 0
            if (vueData.CT_KetCa[2].length > 0) {
                vueData.CT_KetCa[2].forEach((item) => {
                    sum += item.ThanhTien
                })
            }
            return sum
        },
        CT_Tong: function () {
            return vueData.CT_KetCa[3][0]
        },
        DS_ChuaThanhToan: function () {
            return vueData.CT_KetCa[4]
        },
        DS_ChuaThanhToan_Count: function () {
            let count = 0
            if (vueData.CT_KetCa[4].length > 0) {
                vueData.CT_KetCa[4].forEach((item) => {
                    count += item.SoLuongDon
                })
            }
            return count
        },
        DS_ChuaThanhToan_Sum: function () {
            let sum = 0
            if (vueData.CT_KetCa[4].length > 0) {
                vueData.CT_KetCa[4].forEach((item) => {
                    sum += item.TongTien
                })
            }
            return sum
        },
        DS_HoaDonHuy: function () {
            return vueData.CT_KetCa[5]
        },
        DS_HoaDonHuy_Sum: function () {
            let sum = 0
            if (vueData.CT_KetCa[5].length > 0) {
                vueData.CT_KetCa[5].forEach((item) => {
                    sum += item.TienPhaiTra
                })
            }
            return sum
        },
        DS_MonHuy: function () {
            return vueData.CT_KetCa[6]
        },
        TongTienKiemDem: function () {
            const tongKiemDem = vueData.To_500000 * 500000 + vueData.To_200000 * 200000 + vueData.To_100000 * 100000 + vueData.To_50000 * 50000 + vueData.To_20000 * 20000 + vueData.To_10000 * 10000 + vueData.To_5000 * 5000 + vueData.To_2000 * 2000 + vueData.To_1000 * 1000 + vueData.To_500 * 500
            return tongKiemDem
        },
    },
})
Vue.component("money-component", {
    template: /*html*/ `
        <v-row>
            <v-col cols="12"><h4 class='primary--text text-center'>CHI TIẾT KIỂM ĐẾM</h4></v-col>
            <v-col cols="6" class="py-2">
                 <v-text-field v-model="vueData.To_500000" label="Tờ 500.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_500000 * 500000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_200000" label="Tờ 200.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_200000 * 200000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_100000" label="Tờ 100.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_100000 * 100000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_50000" label="Tờ 50.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_50000 * 50000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_20000" label="Tờ 20.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_20000 * 20000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_10000" label="Tờ 10.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_10000 * 10000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_5000" label="Tờ 5.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_5000 * 5000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_2000" label="Tờ 2.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_2000 * 2000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_1000" label="Tờ 1.000đ" type="number" outlined dense hide-details :suffix="(vueData.To_1000 * 1000).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
            <v-col cols="6" class="py-2">
                <v-text-field v-model="vueData.To_500" label="Tờ 500đ" type="number" outlined dense hide-details :suffix="(vueData.To_500 * 500).toLocaleString('vi-vn')"></v-text-field>
            </v-col>
        </v-row>
    `,
})