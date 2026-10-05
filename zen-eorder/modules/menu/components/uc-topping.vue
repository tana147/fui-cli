<template>
    <div :class="topping?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="topping?.SanPhamID > 0 ? 'width: 100%; background-color: #fff;padding: 0;' : ''">
        <div v-if="topping?.SanPhamID > 0">
            <div class="tr-product">
                <div class="td-product-name pa-0 pl-5">
                    + {{ topping?.TenHienThi }}
                    <p class="font-weight-light" style="font-size: 13px" v-if="topping.TienVAT_CuaHang_SanPham > 0">
                        VAT: <span class="red--text">{{ topping.TienVAT_CuaHang_SanPham.toLocaleString("vi-vn") }}</span>
                    </p>
                </div>
                <div class="td-product-qty pa-0">
                    <span v-if="topping?.SoLuong !== 1">{{ topping?.SoLuong }}</span>
                </div>
                <div class="td-product-action">
                    <v-icon v-if="topping?.Is_ThanhToanZen === 1" color="success">mdi-checkbox-marked</v-icon>
                </div>
                <div class="td-product-price">{{ ThanhTien.toLocaleString("vi-vn") }}</div>
            </div>
        </div>
        <div v-if="topping?.SanPhamID === 0 || topping?.SanPhamID === null">
            <div v-if="topping?.NhomLienKetChiTiet_ParentID !== null || topping?.NhomLienKetChiTiet_ParentID > 0" class="ml-5">
                <label>{{ topping?.TenHienThi }} </label>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["topping"],
    computed: {
        ThanhTien: function () {
            const $this = this
            if ($this.topping?.Is_ThanhToanZen === 1) {
                return 0
            } else {
                return $this.topping.SoLuong * $this.topping.GiaBan_CuaHang + ($this.topping.TienVAT ?? 0)
            }
        },
    },
}
</script>
