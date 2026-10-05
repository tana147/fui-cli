<template>
    <v-dialog v-model="vueData.IsShowDialogKhuyenMai" scrollable width="500">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>
                    Danh sách Voucher <span class="primary--text ml-2">({{ ds_spkm.length }})</span>
                </v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogKhuyenMai = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-list v-if="ds_spkm.length > 0" dense>
                    <v-list-item v-for="sp in ds_spkm" :key="sp.SanPhamID">
                        <v-list-item-avatar><v-img :src="sp.AnhSanPham_Url"></v-img></v-list-item-avatar>
                        <v-list-item-content>
                            <v-list-item-title>
                                {{ sp.MaSanPham }} - {{ sp.TenNgan }}
                            </v-list-item-title>
                            <v-list-item-subtitle>
                                Đơn giá: {{ sp.GiaBan_CuaHang.toLocaleString("vi-vn") }} ({{ sp.VAT_CuaHang }}% VAT)
                                <br />
                                Hết hạn: {{ sp.NgayHetHan }}
                                <br />
                                <span v-if="isDisableVoucher(sp)" class="red--text">{{ messageVoucher(sp) }}</span>
                            </v-list-item-subtitle>
                        </v-list-item-content>
                        <v-list-item-action>
                            <v-btn :disabled="isDisableVoucher(sp)" icon @click="onChooseVoucher(sp)"><v-icon color="primary">mdi-gift</v-icon></v-btn>
                        </v-list-item-action>
                    </v-list-item>
                </v-list>
                <p v-else>Không tìm thấy Voucher</p>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["show_dialog", "ds_spkm", "value", "order", "Panel"],
    methods: {
        isDisableVoucher: function (SanPham) {
            return SanPham.Is_CungCuaHang === 0 || SanPham.Is_DisableVoucher === 1 || SanPham.Is_Holiday === 1
        },
        messageVoucher: function (SanPham) {
            let msg = ""
            if (SanPham.Is_CungCuaHang === 0) {
                msg = "Voucher không áp dụng cho cửa hàng"
            } else if (SanPham.Is_DisableVoucher === 1) {
                msg = "Khách đã đổi 2 voucher trong ngày"
            } else if (SanPham.Is_Holiday === 1) {
                msg = "Voucher không áp dụng cho ngày lễ"
            }
            return msg
        },
        onChooseVoucher: function (SanPham) {
            const $this = this
            const sanpham = SanPham
            if ($this.order.find((item) => item.Is_KhuyenMai === 1)) {
                Vue.$toast.error("Hóa đơn đã được áp dụng Voucher")
                return
            }
            if (sanpham.TinhTrang === 1) {
                Vue.$toast.error("Sản phẩm đang tạm hết, vui lòng thử lại sau")
                return
            }
            //Case 1: Danh sách order không có món khuyến mãi
            //  ---> Hiển thị thông báo và đóng
            const indexSanPham = $this.order.findIndex((item) => item.TrangThai !== 6 && item.TrangThai !== 7 && item.Is_ThanhToanZen === 0 && item.SanPhamID === sanpham.SanPhamID)
            if (indexSanPham < 0) {
                Vue.$toast.error("Sản phẩm khuyến mãi không nằm trong danh sách món order")
                vueData.IsShowDialogKhuyenMai = false
                return //Nếu không order món khuyến mãi thì không xử lý
            }
            //Case 2: Danh sách order có món khuyến mãi và số lượng = 1
            //  ---> Cập nhật món đó Is_KhuyenMai = 1 và set lại giá món = giá khuyến mãi
            if ($this.order[indexSanPham].SoLuong === 1) {
                $this.order[indexSanPham].PhanTramVAT = 0
                $this.order[indexSanPham].TienVAT = 0
                $this.order[indexSanPham].TienVAT_App = 0
                $this.order[indexSanPham].TienVAT_CuaHang_SanPham = 0
                $this.order[indexSanPham].VAT_App = 0
                $this.order[indexSanPham].VAT_CuaHang = 0
                $this.order[indexSanPham].TongTienMon = 0
                $this.order[indexSanPham].Is_KhuyenMai = 1
                $this.order[indexSanPham].ThanhTien = 0
                vueData.IsShowDialogKhuyenMai = false
            }
            //Case 3: Danh sách order có món khuyến mãi và số lượng > 1
            //  ---> Giảm 1 số lượng món và add thêm 1 món khuyến mãi vào danh sách order
            else if ($this.order[indexSanPham].SoLuong > 1) {
                //3.1. Giảm số lượng món trong dánh sách order
                $this.order[indexSanPham].SoLuong = $this.order[indexSanPham].SoLuong - 1
                $this.order[indexSanPham].ThanhTien = $this.order[indexSanPham].SoLuong * sanpham.GiaBan_CuaHang
                if ($this.order[indexSanPham].TienVAT_CuaHang_SanPham > 0) {
                    $this.order[indexSanPham].TienVAT_CuaHang_SanPham = CT_TienVAT($this.order[indexSanPham].TienVAT_CuaHang_SanPham, $this.order[indexSanPham].PhanTramVAT, $this.order[indexSanPham].ThanhTien)
                }
                //3.2. Add món khuyến mãi vào danh sách
                //Khởi tạo tổng tiền món trước
                const uuid = uuidv4()
                sanpham.SanPhamGUID = uuid
                const cloneTopping = JSON.parse(JSON.stringify(vueData.DSChiTietLienKet))
                const listTopping = cloneTopping.filter((item) => {
                    if (item.NhomLienKetID === sanpham.NhomLienKetID) {
                        item.Is_ThanhToanZen = item.Is_ThanhToanZen ?? 0
                        //Phải clone tiền VAT ra để có được tiền VAT gốc, biến TienVAT đang được sử dụng tính toán, nếu TienVAT về = 0 thì sẽ ko hiển thị ra UI
                        //Vì thế lúc TienVAT = 0 thì phải lấy TienVAT_CuaHang_SanPham để thay thế
                        item.TienVAT_CuaHang_SanPham = item.TienVAT
                        item.SanPhamGUID = uuid
                        return item
                    }
                })
                sanpham.ThuocTinh = listTopping
                sanpham.SoLuong = 1
                $this.value.TongMonChuaTra += 1
                sanpham.PhanTramVAT = 0
                sanpham.TienVAT = 0
                sanpham.TienVAT_App = 0
                sanpham.TienVAT_CuaHang_SanPham = 0
                sanpham.VAT_App = 0
                sanpham.VAT_CuaHang = 0
                sanpham.TongTienMon = 0
                sanpham.Is_KhuyenMai = 1
                sanpham.ThanhTien = 0
                sanpham.TongTienMon = 0
                //Thêm sản phẩm vào dsorder
                $this.order.push({
                    ...sanpham,
                    SoLuongThucTe: 1,
                    GhiChu: "",
                    Is_ThanhToanZen: 0,
                    Is_MangVe: 0,
                    HoaDonID: 0,
                    HoaDonChiTietID: 0,
                })
                //Sort lại order theo Nước > Topping > Bánh
                $this.order = sortOrder($this.order)
                //Tự động mở topping khi thêm sản phẩm
                if ($this.order.length > 0) {
                    let spuid = sanpham.SanPhamGUID
                    let indexSP = $this.order.findIndex((item) => item.SanPhamGUID === spuid)
                    $this.$emit("update:Panel", indexSP)
                }
                //Scroll tới sản phẩm khi vừa mới thêm vào dsorder
                this.$nextTick(() => {
                    setTimeout(() => {
                        const itemId = `item-${sanpham.SanPhamGUID}`
                        const titleElement = document.getElementById(itemId)
                        if (titleElement) {
                            titleElement.scrollIntoView({
                                behavior: "smooth",
                                block: "nearest",
                            })
                        }
                    }, 0)
                })
                //Set tiền = 0 nếu thêm sản phẩm
                if (this.value.HinhThucThanhToan.length === 2) {
                    $this.value.KhachTra_TienMat = 0
                    $this.value.KhachTra_CK = 0
                    $this.value.KhachTra_SPF = 0
                    $this.value.KhachTra_XSM = 0
                    $this.value.KhachTra_GRAB = 0
                    $this.value.KhachTra_QT = 0
                    $this.value.KhachTra_HT1 = 0
                    $this.value.KhachTra_HT2 = 0
                    $this.value.KhachTra_HT3 = 0
                }
                vueData.IsShowDialogKhuyenMai = false
            }
        },
    },
}
</script>
