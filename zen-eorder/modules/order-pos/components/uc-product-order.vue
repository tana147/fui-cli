<template>
    <div>
        <div class="tr-product">
            <div class="td-product-name-send text-green font-weight-bold">{{ Product?.TenNgan }}</div>
            <div class="td-product-print">
                <v-icon v-if="product?.Is_GuiBepBar === 1" color="primary">mdi-chef-hat</v-icon>
            </div>
            <div class="td-product-qty">{{ roundSoLuong(Product?.SoLuong) }}</div>
            <div class="td-product-price">{{ ThanhTien?.toLocaleString("vi-vn") }}</div>
            <div v-on:click.stop="" class="td-product-action text-right pr-2 pl-0">
                <v-btn @click="onEdit()" fab class="text-green btn-plus pl-0 pr-0" small>Sửa</v-btn>
            </div>
        </div>
        <div class="tr-product bg-green-2" style="border-bottom: 1px dashed rgb(57 119 68)">
            <div class="ml-3 py-1 pt-2" v-if="Product?.Is_MangVe">Mang về</div>
            <template v-for="(topping, i) in Product?.ThuocTinh?.filter((item) => item?.SoLuong > 0)" :key="i">
                <uc-product-order-topping :topping="topping" />
            </template>
            <div style="width: 100%" v-if="Product?.GhiChu && Product?.GhiChu !== ''" class="pl-3 py-1">- Ghi chú: {{ Product?.Is_MangVe ? "Mang về - " : "" }}{{ Product?.GhiChu }}</div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["product"],
    computed: {
        Product: function () {
            return this.product ?? {}
        },
        ThanhTien: function () {
            return this.Product.SoLuong * this.Product.GiaBan_CuaHang
        },
    },
    methods: {
        onEdit() {
            const $this = this
            vueData.SanPhamGuid_Active = $this.Product.SanPhamGuid
            const index = vueData.DSOrder.findIndex((item) => item.SanPhamGuid === this.Product.SanPhamGuid)
            vueData.ItemProduct = vueData.DSOrder[index]
            vueData.IsShowDialogDetailProduct = true
        },
    },
}
</script>
