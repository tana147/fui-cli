<template>
    <div :class="product?.SoLuong === 0 || product?.TrangThai === 6 || product?.TrangThai === 7 ? 'cancel-text' : ''">
        <div class="tr-product">
            <div class="td-product-name-his">
                <b class="text-green font-weight-bold">{{ product?.SoThuTu }}. {{ product?.TenHienThi }}</b>
                <span style="font-size: 11px" class="gray-text" v-if="product.TienVAT > 0"><br />VAT ({{ product?.PhanTramVAT }}%): {{ product?.TienVAT?.toLocaleString("vi-vn") }}</span>
                <br />
                <p :class="MauTrangThai + '--text mt-1'">{{ product?.TenTrangThai }}</p>
            </div>
            <div class="td-product-qty-his" v-if="!Is_CapNhatSoLuong">
                {{ roundSoLuong(product?.SoLuong) }}
            </div>
            <div class="td-product-qty-his" v-if="Is_CapNhatSoLuong">
                <v-text-field v-model="product.SoLuong" @change="onSaveQuantity" style="width: 50px; display: inline-block" type="number" class="centered-input" hide-details dense hide-spin-buttons></v-text-field>
                <v-btn @click="onSaveQuantity" fab class="text-green btn-plus pl-0 pr-0 ml-1" x-small><v-icon color="success">mdi-check-bold</v-icon></v-btn>
            </div>
            <div class="td-product-price pr-1">
                <span v-if="product?.Is_KhuyenMai === 1"><v-icon :disabled="product?.TrangThai == 6 || product?.TrangThai == 7" @click="onCancelGift" color="primary">mdi-gift</v-icon></span>
                <span v-else>{{ product?.TamTinh?.toLocaleString("vi-vn") }}</span>
            </div>
            <div class="td-product-action" @click.stop="onUpdateZen" :style="{cursor: 'pointer', visibility: HienThiCheckBoxZEN}">
                <v-icon color="success">{{ product.Is_ThanhToanZen === 1 ? "mdi-checkbox-marked" : "mdi-checkbox-blank-outline" }}</v-icon>
            </div>
        </div>
        <div class="tr-product bg-green-2" style="border-bottom: 1px dashed rgb(57 119 68)">
            <span class="ml-3 py-1 pt-2" v-if="product.TenLoaiLy">{{ product.TenLoaiLy }}</span>
            <template v-for="(topping, i) in product?.ThuocTinh?.filter((item) => item?.SoLuong > 0)" :key="i">
                <uc-product-history-topping :topping="topping" :khachhang="khachhang" :zen_con_lai="zen_con_lai" />
            </template>
            <div style="width: 100%" v-if="product?.GhiChu && product?.GhiChu !== ''" class="pl-3 py-1">- Ghi chú: {{ product?.GhiChu }}</div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["product", "order", "khachhang", "zen_con_lai"],
    computed: {
        Is_CapNhatSoLuong: function () {
            //Danh sách sản phẩm được phép cập nhật số lượng
            const $this = this
            // 1612, 2020, 2433: Khăn lạnh
            // 1908: Cá Cơm Chiên Giòn
            // 2505: Rau Củ Quả Ngâm Chua
            const sanPhamId_Arr = [1612, 2020, 2433, 1908, 2505]
            return sanPhamId_Arr.indexOf($this.product.SanPhamID) >= 0
        },
        MauTrangThai: function () {
            const status = this.product.TrangThai
            let color = ""
            if (status === 1) {
                //Đã nhận
                color = ""
            } else if (status === 2) {
                //Đã hoàn thành
                color = "success"
            } else if (status === 5) {
                //Đang chế biến
                color = "warning"
            } else if (status === 6) {
                //Thu ngân hủy
                color = "error"
            } else if (status === 7) {
                //Bếp xác nhận hủy
                color = "error"
            }
            return color
        },
        HienThiCheckBoxZEN: function () {
            return this.khachhang.ZEN > 0 && this.product.Is_KhuyenMai === 0 ? "unset" : "hidden"
        },
    },
    methods: {
        onCancelGift() {
            const $this = this
            confirm({
                title: "Hủy món khuyến mãi",
                content: `Bạn có chắc muốn hủy món khuyến mãi ${$this.product.TenHienThi}?`,
                action: function () {
                    // Gọi API hủy món khuyến mãi
                    const params = {
                        HoaDonChiTietID: $this.product.HoaDonChiTietID,
                    }
                    ajaxCALL("/eorder/HoaDonChiTiet_Huy_KhuyenMai", params, (res) => {
                        if (res.data) {
                            webSocket_Send({group: vueData.webSocket_Hub_Bep, data: Date.now()})
                            webSocket_Send({group: vueData.webSocket_Hub_Order, data: Date.now()})
                            vueData.IsShowDialogHistory = false
                            setTimeout(() => {
                                vueData.IsShowDialogHistory = true
                            }, 100)
                            Vue.$toast.success(`Hủy món khuyến mãi ${$this.product.TenHienThi} thành công`, {position: "top"})
                        }
                    })
                },
            })
        },
        onSaveQuantity() {
            const $this = this
            // Gọi API cập nhật số lượng món khăn lạnh
            const params = {
                HoaDonChiTietID: $this.product.HoaDonChiTietID,
                SoLuong: $this.product.SoLuong === "" ? 0 : $this.product.SoLuong,
                TrangThai: $this.product.TrangThai,
                GhiChu: $this.product.GhiChu,
            }
            ajaxCALL("/eorder/HoaDonChiTiet_Update", params, (res) => {
                if (res.data) {
                    webSocket_Send({group: vueData.webSocket_Hub_Bep, data: Date.now()})
                    webSocket_Send({group: vueData.webSocket_Hub_Order, data: Date.now()})
                    vueData.IsShowDialogHistory = false
                    setTimeout(() => {
                        vueData.IsShowDialogHistory = true
                    }, 100)
                    Vue.$toast.success(`Cập nhật số lượng ${$this.product.TenHienThi} thành công`, {position: "top"})
                    $this.DisableSend = false
                }
            })
        },
        onUpdateZen() {
            const $this = this
            if ($this.order.TrangThai === 1 || $this.order.TrangThai === 9) {
                $this.product.Is_ThanhToanZen = $this.product.Is_ThanhToanZen === 0 ? 1 : 0
            }
        },
    },
}
</script>
