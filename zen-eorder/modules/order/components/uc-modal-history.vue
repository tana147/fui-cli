<template>
    <v-dialog v-model="is_show_dialog" fullscreen scrollable persistent transition="dialog-top-transition">
        <v-card class="model-order">
            <div class="title white--text bg-green pa-2 text-center">DANH SÁCH MÓN ĐÃ GỬI</div>
            <div class="order-body">
                <p class="pa-2 border-bottom font-weight-bold">
                    Hóa đơn: <span class="red--text">{{ HoaDon?.MaHoaDon }}</span> (Bàn {{ HoaDon?.TenBan }})
                </p>
                <template v-for="(item, i) in HoaDon?.ChiTietHoaDon" :key="item.HoaDonChiTietID">
                    <uc-product-history :product="item" />
                </template>
            </div>
            <div class="order-footer">
                <div class="pa-3 border-bottom d-flex text-right justify-center justify-space-between font-weight-bold">
                    <div class="text-center">
                        <span>Tạm tính</span><br /><b class="green--text">{{ HoaDon?.TongTien?.toLocaleString("vi-vn") }}</b>
                    </div>
                    <div class="text-center">
                        <span>VAT</span><br /><b class="green--text">{{ HoaDon?.TongVAT?.toLocaleString("vi-vn") }}</b>
                    </div>
                    <div class="text-center">
                        <span>ZEN</span><br /><b class="green--text">{{ HoaDon?.KhachTra_Zen?.toLocaleString("vi-vn") }}</b>
                    </div>
                    <div class="text-center">
                        <span>Thành tiền</span><br /><b class="red--text">{{ HoaDon?.TienPhaiTra?.toLocaleString("vi-vn") }}</b>
                    </div>
                </div>
                <div class="pa-3">
                    <v-btn block @click="onClose()" elevation="0"><v-icon left>mdi-arrow-left</v-icon>Trở về danh sách món</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["is_show_dialog", "loaddata"],
    data: function () {
        return {
            HoaDon: {},
            IntervalReload: null,
        }
    },
    computed: {
        IsShowApprove() {
            //1: Chờ xử lý, 2: Chờ thanh toán, 3: Đã thanh toán, 4: Hoàn tất, 5: Đã hủy, 6: Đã thanh toán một phần, 7: Đã trả hàng, 8: Đặt trước, 9: Tiếp nhận đơn hàng
            return this.HoaDon.TrangThai === 1 || this.HoaDon.TrangThai === 9
        },
    },
    watch: {
        is_show_dialog: function (isShow) {
            const $this = this
            if (isShow) {
                const hoaDonID = vueData.HoaDonID
                if (hoaDonID && hoaDonID > 0) {
                    $this.getData() //First load
                    $this.IntervalReload = setInterval($this.getData, 30000) //5s
                }
            } else {
                clearInterval($this.IntervalReload)
            }
        },
        loaddata: {
            handler: function (newValue) {
                if (this.is_show_dialog) this.getData()
            },
            deep: true,
        },
    },
    methods: {
        onClose() {
            vueData.IsShowDialogHistory = false
        },
        getData() {
            const $this = this
            const hoaDonID = vueData.HoaDonID
            if (hoaDonID && hoaDonID > 0) {
                const params = {
                    QrCode: vueData.QrCode,
                    HoaDonID: hoaDonID,
                }
                ajaxCALL("/eorder/auth/HoaDon_Select_ById", params, (res) => {
                    if (res.data) {
                        const resHoaDon = res.data[0][0] ?? {}
                        const resChiTietHoaDon = res.data[1] ?? []
                        const productJsonData = []
                        const productFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 1)
                        const toppingFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 0)
                        productFilter.forEach((item, index) => {
                            const topping = toppingFilter.filter((topping) => topping.SanPhamGUID === item.SanPhamGUID)
                            const product = {...item, SoThuTu: index + 1, ThuocTinh: topping}
                            productJsonData.push(product)
                        })
                        const dataJson = {...resHoaDon, ChiTietHoaDon: productJsonData}
                        $this.HoaDon = dataJson
                    }
                })
            }
        },
        onApproved() {
            const $this = this
            const oldStatus = $this.HoaDon.TrangThai
            $this.HoaDon.TrangThai = 2 //Chờ thanh toán
            const params = {
                QrCode: vueData.QrCode,
                HoaDonID: $this.HoaDon.HoaDonID,
            }
            ajaxCALL("/eorder/auth/HoaDon_XacNhan", params, (res) => {
                if (res.data) {
                    Vue.$toast.success(`Xác nhận thanh toán thành công`, {position: "top"})
                } else {
                    $this.HoaDon.TrangThai = oldStatus //Cập nhật lại trạng thái cũ nếu lỗi
                }
            })
        },
    },
}
</script>
