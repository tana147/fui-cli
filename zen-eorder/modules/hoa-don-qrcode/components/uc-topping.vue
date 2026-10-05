<template>
    <div :class="topping?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="topping?.SanPhamID > 0 ? 'width: 100%;' : ''">
        <div v-if="topping?.SanPhamID > 0">
            <div class="tr-product">
                <div class="td-product-name pl-2" style="font-style: italic">+ {{ topping?.TenHienThi }}</div>
                <div class="td-product-signature"></div>
                <div class="td-product-qty">
                    <span :class="topping?.SoLuong > 1 ? 'primary--text' : ''">{{ topping?.SoLuong }}</span>
                </div>
                <div class="td-product-unit">{{ topping?.DonGia.toLocaleString("vi-vn") }}</div>
                <div class="td-product-zen">
                    <v-icon v-if="topping.Is_ThanhToanZen === 1" color="error" small class="mb-1">mdi-check-bold</v-icon>
                </div>
                <div class="td-product-price pr-1">{{ (topping?.SoLuong * topping?.DonGia).toLocaleString("vi-vn") }}</div>
            </div>
        </div>
        <div v-if="topping?.SanPhamID === 0 || topping?.SanPhamID === null">
            <div v-if="topping?.NhomLienKetChiTiet_ParentID !== null || topping?.NhomLienKetChiTiet_ParentID > 0">
                <span class="px-1">-</span><label>{{ topping?.TenHienThi }}</label>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["topping"],
    data: function () {},
    computed: {},
    mounted: function () {},
    methods: {},
}
</script>
