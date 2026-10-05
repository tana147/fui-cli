function onPrintOrder() {
    if (vueData.CTHoaDon) {
        const params = {
            HoaDonID: vueData.CTHoaDon.HoaDonID,
        }
        ajaxCALL("/eorder/LichSu_HoaDon_In", params, (res) => {
            if (res.data) {
                Vue.$toast.success("In thành công", { position: "top" })
            }
        })
    }
}
Vue.component("tab-history-component", {
    props: ["chid"],
    data: () => {
        return {
            DSNhanVien: [],
            DSTrangThai: [
                { value: 1, text: "Chờ xử lý" },
                { value: 2, text: "Chờ thanh toán" },
                { value: 3, text: "Đã thanh toán" },
                { value: 4, text: "Đã hoàn tất" },
             //   { value: 5, text: "Đã hủy" },
                { value: 6, text: "Đã thanh toán một phần" },
                { value: 7, text: "Đã trả hàng" },
                { value: 8, text: "Đang đặt trước" },
                { value: 9, text: "Đang tiếp nhận" },
            ],
            DSHinhThucThanhToan: [
                { value: 0, text: "Tất cả" },
                { value: 1, text: "Tiền mặt" },
                { value: 2, text: "Chuyển khoản" },
                { value: 4, text: "Quẹt thẻ" },
                { value: 3, text: "Shopee Food" },
                { value: 6, text: "Grab" },
                { value: 5, text: "ZEN" },
                { value: 7, text: "Xanh SM" },
            ],
            HeaderTable: [
                {
                    text: "Mã hóa đơn",
                    el: "t-button",
                    value: "Button_Detail",
                    attr: {
                        color: "green",
                        ":label": "item.MaSoHoaDon",
                        ":action": {
                            FUN: "onOpenDetailTable",
                            IN: {
                                data: "{{item}}",
                            },
                        },
                    },
                },
                {
                    text: "Nhân viên tạo",
                    value: "NhanVienThemMoi",
                },
                {
                    text: "Giờ tạo",
                    el: "span",
                    value: "GioThemMoi",
                    innerHTML: "{{item.NgayThemMoi}} {{item.GioThemMoi}}",
                    width: 150,
                },
                {
                    text: "Nhân viên thanh toán",
                    value: "NhanVienThanhToan",
                },
                {
                    text: "Giờ thanh toán",
                    value: "NgayXuatHoaDon",
                    width: 150,
                },
                {
                    text: "Khách hàng",
                    value: "TenKhachHang",
                    width: 200,
                },
                {
                    text: "Bàn",
                    el: "span",
                    value: "TenBan",
                    innerHTML: "{{item.TenBan}}",
                },
                {
                    text: "Tạm tính",
                    value: "TongTien",
                    el: "span",
                    innerHTML: "{{item.TongTien.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Tổng VAT",
                    value: "TongVAT",
                    el: "span",
                    innerHTML: "{{item.TongVAT.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Phí giao hàng",
                    value: "GiaoHang_Phi",
                    el: "span",
                    innerHTML: "{{item.GiaoHang_Phi.toLocaleString('vi-vn')}}",
                },
                {
                    text: "ZEN",
                    value: "KhachTra_Zen",
                    el: "span",
                    innerHTML: "{{item.KhachTra_Zen.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Khách phải trả",
                    value: "TienPhaiTra",
                    el: "span",
                    innerHTML: "{{item.TienPhaiTra.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Tiền mặt",
                    value: "KhachTra_TienMat",
                    el: "span",
                    innerHTML: "{{item.KhachTra_TienMat.toLocaleString('vi-vn')}}",
                },
                {
                    text: "CK",
                    value: "KhachTra_CK",
                    el: "span",
                    innerHTML: "{{item.KhachTra_CK.toLocaleString('vi-vn')}}",
                },
                {
                    text: "SPF",
                    value: "KhachTra_SPF",
                    el: "span",
                    innerHTML: "{{item.KhachTra_SPF.toLocaleString('vi-vn')}}",
                },
                {
                    text: "XSM",
                    value: "KhachTra_XSM",
                    el: "span",
                    innerHTML: "{{item.KhachTra_XSM.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Grab",
                    value: "KhachTra_GRAB",
                    el: "span",
                    innerHTML: "{{item.KhachTra_GRAB.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Quẹt thẻ",
                    value: "KhachTra_QT",
                    el: "span",
                    innerHTML: "{{item.KhachTra_QT.toLocaleString('vi-vn')}}",
                },
                {
                    text: "HT1",
                    value: "KhachTra_HT1",
                    el: "span",
                    innerHTML: "{{item.KhachTra_HT1.toLocaleString('vi-vn')}}",
                },
                {
                    text: "HT2",
                    value: "KhachTra_HT2",
                    el: "span",
                    innerHTML: "{{item.KhachTra_HT2.toLocaleString('vi-vn')}}",
                },
                {
                    text: "HT3",
                    value: "KhachTra_HT3",
                    el: "span",
                    innerHTML: "{{item.KhachTra_HT3.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Trạng thái",
                    value: "TenTrangThai",
                    width: 250,
                },
            ],
            DataFilter: {
                MaDonHang: "",
                TuNgay: moment().format("YYYY-MM-DD"),
                DenNgay: moment().format("YYYY-MM-DD"),
                TrangThai: "",
                NhanVienThanhToan: null,
                HinhThucThanhToan: 0,
            },
            Tong_Thu: 0,
            Tong_DangTiepNhan: 0,
            Tong_DaThanhToan: 0,
            DS_ThongKe_NhomSanPham: [],
            DS_ThongKe_HinhThucThanhToan: [],
        }
    },
    computed: {
        HeaderFilter() {
            const $this = this
            let filtered = null
            if (vueData.LoaiPhanHieuID !== 2) {
                filtered = $this.HeaderTable.filter((item) => item.value !== "GioThemMoi" && item.value !== "TenBan" && item.value !== "TongVAT")
            } else {
                filtered = $this.HeaderTable
            }
            return filtered
        },
    },
    template: /*html*/ `
        <div>
            <div class="page-section">
                <v-row>
                    <v-col cols="3">
                        <v-text-field v-model="DataFilter.MaDonHang" outlined dense label="Nhập mã đơn hàng" hide-details></v-text-field>
                    </v-col>
                    <v-col cols="2">
                        <f-date outlined v-model="DataFilter.TuNgay" date-add="0" dense label="Từ ngày" hide-details></f-date>
                    </v-col>
                    <v-col cols="2">
                        <f-date outlined v-model="DataFilter.DenNgay" date-add="0" dense label="Đến ngày" hide-details></f-date>
                    </v-col>
                    <v-col cols="2">
                        <v-select outlined v-model="DataFilter.TrangThai" dense label="Trạng thái" :items="DSTrangThai" multiple persistent-hint hide-details></v-select>
                    </v-col>
                    <v-col cols="3">
                        <v-select outlined v-model="DataFilter.HinhThucThanhToan" dense label="Hình thức thanh toán" :items="DSHinhThucThanhToan" hide-details></v-select>
                    </v-col>
                    <v-col cols="3">
                        <v-combobox outlined v-model="DataFilter.NhanVienThanhToan" dense label="Nhân viên thanh toán" :items="DSNhanVien" item-text="TenDangNhap" item-value="MaNhanVien" hide-details></v-combobox>
                    </v-col>
                    <v-col cols="3">
                        <v-btn color="primary" @click="getTableOrder()" elevation="0"><v-icon left>mdi-magnify</v-icon>Tìm</v-btn>
                    </v-col>
                </v-row>
                <div class="d-flex flex-row justify-space-between mt-4">
                    <div class="text-center">Đang tiếp nhận <br/> <b class="red--text">{{Tong_DangTiepNhan.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">Đã thanh toán <br/> <b class="red--text">{{Tong_DaThanhToan.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">Tổng thu <br/> <b class="red--text">{{Tong_Thu.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">Tiền mặt <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_TienMat.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">Chuyển khoản <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_CK.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">ShopeeFood <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_SPF.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">Xanh SM <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_XSM.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">Grab <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_GRAB.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">Quẹt thẻ <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_QT.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">HT1 <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_HT1.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">HT2 <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_HT2.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">HT3 <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_HT3.toLocaleString('vi-vn')}}</b></div>
                    <div class="text-center">ZEN <br/> <b class="red--text">{{DS_ThongKe_HinhThucThanhToan[0]?.KhachTra_Zen.toLocaleString('vi-vn')}}</b></div>
                </div>
            </div>
            <f-table
                class="mt-1"
                label="Danh sách đơn hàng"
                :excel="true"
                :items="vueData.DSHoaDon_Table"
                :items-per-page="20"
                :footer-props="{'items-per-page-options':[20,50,150,300]}"
                :headers="HeaderFilter"
                height="calc(100vh - 408px)"
                :show-search="true"
                :fixed-header="true"
                dense
            />
        </div>
    `,
    mounted: function () {
        this.getEmployee()
        this.getTableOrder()
    },
    watch: {
        chid: function (val) {
            this.getTableOrder()
        },
    },
    methods: {
        getTableOrder() {
            const $this = this
            //Reset lại dữ liệu thống kê
            $this.Tong_Thu = 0
            $this.Tong_DangTiepNhan = 0
            $this.Tong_DaThanhToan = 0
            $this.DS_ThongKe_NhomSanPham = []
            $this.DS_ThongKe_HinhThucThanhToan = []
            vueData.DSHoaDon_Table = []
            //Gọi API lấy dữ liệu
            if (vueData.CuaHangID) {
                const params = {
                    ...$this.DataFilter,
                    NhanVienThanhToan: $this.DataFilter.NhanVienThanhToan?.MaNhanVien ?? "0",
                    TrangThai: $this.DataFilter.TrangThai ? $this.DataFilter.TrangThai.join(",") : "",
                    CuaHangID: vueData.CuaHangID,
                }
                ajaxCALL("/eorder/LichSu_HoaDon", params, (res) => {
                    if (res.data) {
                        vueData.DSHoaDon_Table = res.data[0] ?? []
                        $this.DS_ThongKe_NhomSanPham = res.data[1] ?? []
                        $this.DS_ThongKe_HinhThucThanhToan = res.data[2] ?? []
                        $this.DSNhanVien = res.data[3]
                        res.data[0].map((item) => {
                            $this.Tong_Thu += item.TienPhaiTra
                            if (item.TrangThai === 3 || item.TrangThai === 4 || item.TrangThai === 5) {
                                $this.Tong_DaThanhToan += item.TienPhaiTra
                            } else {
                                $this.Tong_DangTiepNhan += item.TienPhaiTra
                            }
                        })
                        if (vueData.CuaHangID !== parseInt(vueData.CuaHangID_Local)) {
                            $this.DataFilter.NhanVienThanhToan = $this.DSNhanVien[0]
                        }
                    }
                })
            }
        },
        getEmployee() {
            const $this = this
            ajaxCALL("/eorder/NhanVien_Select_Dropdown", {}, (res) => {
                $this.DSNhanVien = res.data
                $this.DataFilter.NhanVienThanhToan = res.data[0]
            })
        },
    },
})
function onOpenDetailTable(item) {
    const detail = item.data
    const params = { HoaDonID: detail.HoaDonID }
    ajaxCALL("/eorder/LichSu_HoaDon_ChiTiet", params, (res) => {
        if (res.data) {
            vueData.CTHoaDon = detail
            vueData.DSChiTietHoaDon = res.data
            vueData.IsShowDialogDetail = true
        }
    })
}