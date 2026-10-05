<template>
    <div :class="topping?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="topping?.SanPhamID > 0 ? 'width: 100%; background-color: #fff;padding: 3px 0;' : ''">
        <div v-if="topping?.SanPhamID > 0">
            <div class="tr-product">
                <div class="td-product-name-send pa-0 pl-2">+ {{ topping?.TenHienThi }}</div>
                <div class="td-product-print pa-0 pl-2"></div>
                <div class="td-product-qty pa-0">{{ roundSoLuong(topping?.SoLuong) }}</div>
                <div class="td-product-price pa-0">{{ (topping?.SoLuong * topping?.GiaBan_CuaHang).toLocaleString("vi-vn") }}</div>
                <div class="td-product-action"></div>
            </div>
        </div>
        <div v-if="topping?.SanPhamID === 0 || topping?.SanPhamID === null">
            <div v-if="topping?.NhomLienKetChiTiet_ParentID !== null || topping?.NhomLienKetChiTiet_ParentID > 0" class="ml-3 py-1 pt-2">
                <label>{{ topping?.TenHienThi }}</label>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["topping"],
}
</script>
