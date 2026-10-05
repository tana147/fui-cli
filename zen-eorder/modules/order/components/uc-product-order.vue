<template>
    <div>
        <div class="tr-product">
            <div class="td-product-name-send primary--text font-weight-bold">{{ product?.TenSanPham }}</div>
            <div class="td-product-qty">{{ product?.SoLuong }}</div>
            <div class="td-product-price">{{ ThanhTien?.toLocaleString("vi-vn") }}</div>
            <div v-on:click.stop="" class="td-product-action text-right pr-2 pl-0">
                <v-btn @click="onEdit()" fab class="primary--text btn-plus pl-0 pr-0" small>Sửa</v-btn>
            </div>
        </div>
        <div class="tr-product bg-green-2" style="border-bottom: 1px dashed rgb(57 119 68)">
            <template v-for="(topping, i) in product?.ThuocTinh?.filter((item) => item?.SoLuong > 0)" :key="i">
                <uc-product-order-topping :topping="topping" />
            </template>
            <div style="width: 100%" v-if="product?.GhiChu && product?.GhiChu !== ''" class="pl-3 py-1">
                - {{ product?.Is_MangVe ? "Mang về - " : "" }}{{ product?.GhiChu }}
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["product"],
    computed: {
        ThanhTien: function () {
            return this.product.SoLuong * this.product.GiaBan_CuaHang
        },
    },
    methods: {
        onEdit() {
            const $this = this
            vueData.SanPhamGuid_Active = $this.product.SanPhamGuid
            vueData.IsShowDialogOrder = false
            vueData.IsShowDialogDetailProduct = true
        },
    },
}
</script>