<template>
    <div :class="product?.SoLuong === 0 || product?.TrangThai === 6 || product?.TrangThai === 7 ? 'cancel-text' : ''">
        <div class="tr-product" @click="onClickDetail">
            <div class="td-product-name">
                <b>{{ index + 1 }}. {{ product?.TenHienThi }}</b>
            </div>
            <div class="td-product-signature">
                <v-icon v-if="product.Is_Signature === 1" color="success">mdi-square-edit-outline</v-icon>
            </div>
            <div class="td-product-qty">
                <span :class="product?.SoLuong > 1 ? 'primary--text' : ''">{{ product?.SoLuong }}</span>
            </div>
            <div class="td-product-unit">{{ product?.DonGia.toLocaleString("vi-vn") }}</div>
            <div class="td-product-zen error--text">
                <v-icon v-if="product.Is_ThanhToanZen === 1" color="error" class="mb-1">mdi-check-bold</v-icon>
            </div>
            <div class="td-product-price pr-1">{{ product?.ThanhTien?.toLocaleString("vi-vn") }}</div>
        </div>
        <div class="tr-product" style="border-bottom: 1px dashed">
            <template v-for="(topping, i) in product?.ThuocTinh?.filter((item) => item?.SoLuong > 0)" :key="i">
                <uc-topping :topping="topping" />
            </template>
            <div style="width: 100%" v-if="product?.GhiChu && product?.GhiChu !== ''" class="pl-1">- Ghi chú: {{ product?.GhiChu }}</div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["product", "index"],
    data: function () {},
    computed: {},
    mounted: function () {},
    methods: {
        onClickDetail() {
            const $this = this
            vueData.CTSanPham = $this.product
            //Nếu sản phẩm Is_Signature thì hiển thị modal chi tiết
            if ($this.product?.Is_Signature === 1) {
                vueData.IsShowDetail = true
            }
        },
    },
}
</script>