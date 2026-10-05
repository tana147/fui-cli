<template>
    <v-dialog v-model="vueData.IsShowDialogKhuyenMai" persistent scrollable width="500">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>
                    Danh sách voucher <span class="primary--text pl-1">({{ ds_spkm.length }})</span>
                </v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogKhuyenMai = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text class="pa-2">
                <v-list v-if="ds_spkm.length > 0">
                    <v-list-item v-for="sp in ds_spkm" :key="sp.SanPhamID">
                        <v-list-item-avatar><v-img :src="sp.AnhSanPham_Url"></v-img></v-list-item-avatar>
                        <v-list-item-content>
                            <v-list-item-title>
                                <b>{{ sp.MaSanPham }} - {{ sp.TenNgan }} </b> <br />
                                Đơn giá: {{ sp.GiaBan_CuaHang.toLocaleString("vi-vn") }} ({{ sp.VAT_CuaHang }}% VAT)
                            </v-list-item-title>
                            <v-list-item-subtitle>
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
                <p v-else class="text-center pb-5">Không tìm thấy Voucher</p>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["ds_spkm", "order", "khid"],
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
            if (sanpham.TinhTrang === 1) {
                Vue.$toast.error("Sản phẩm đang tạm hết, vui lòng thử lại sau", {position: "top"})
                return
            }
            if ($this.order.find((item) => item.Is_KhuyenMai === 1)) {
                Vue.$toast.error("Hóa đơn đã được áp dụng Voucher", {position: "top"})
                return
            }
            //Case 1: Danh sách order không có món khuyến mãi ---> Hiển thị thông báo và đóng
            const indexSanPham = $this.order.findIndex((item) => item.TrangThai !== 6 && item.TrangThai !== 7 && item.Is_ThanhToanZen === 0 && item.SanPhamID === sanpham.SanPhamID)
            if (indexSanPham < 0) {
                Vue.$toast.error("Sản phẩm khuyến mãi không nằm trong danh sách món order", {position: "top"})
                vueData.IsShowDialogKhuyenMai = false
                return //Nếu không order món khuyến mãi thì không xử lý
            }
            //Case 2: Nếu danh sách có món khuyến mãi ---> Gọi API xử lý món khuyến mãi
            confirm({
                title: "Sử dụng Voucher",
                content: `Bạn có chắc muốn sử dụng Voucher này?`,
                action: function () {
                    const params = {
                        CuaHangID: vueData.CuaHangID,
                        HoaDonID: vueData.HoaDonID,
                        Voucher_SanPhamID: SanPham.SanPhamID,
                        KhachHangID: $this.khid,
                    }
                    ajaxCALL("/eorder/HoaDon_Mpos_Insert_Voucher", params, (res) => {
                        vueData.IsShowDialogKhuyenMai = false //Ẩn modal
                        Vue.$toast.success(`Sử dụng Voucher thành công`, {position: "top"})
                        webSocket_Send({group: vueData.webSocket_Hub_Bep, data: Date.now()})
                        webSocket_Send({group: vueData.webSocket_Hub_Order, data: Date.now()})
                        vueData.IsShowDialogHistory = false
                        setTimeout(() => {
                            vueData.IsShowDialogHistory = true
                        }, 100)
                    })
                },
            })
        },
    },
}
</script>
