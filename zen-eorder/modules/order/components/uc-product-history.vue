<template>
    <div :class="product?.SoLuong === 0 || product?.TrangThai === 6 || product?.TrangThai === 7 ? 'cancel-text' : ''">
        <div class="tr-product">
            <div class="td-product-name-his">
                <b class="primary--text font-weight-bold">{{ product?.SoThuTu }}. {{ product?.TenHienThi }}</b> <br />
                <span :class="MauTrangThai + '--text'">{{ product?.TenTrangThai }}</span>
            </div>
            <div class="td-product-qty">{{ product?.SoLuong }}</div>
            <div class="td-product-price pr-1">{{ ThanhTien?.toLocaleString("vi-vn") }}</div>
        </div>
        <div class="tr-product bg-green-2" style="border-bottom: 1px dashed rgb(57 119 68)">
            <template v-for="(topping, i) in product?.ThuocTinh?.filter((item) => item?.SoLuong > 0)" :key="i">
                <uc-product-history-topping :topping="topping" />
            </template>
            <div v-if="product?.GhiChu && product?.GhiChu !== ''" class="pl-3 py-1">- {{ product?.GhiChu }}</div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["product"],
    computed: {
        ThanhTien: function () {
            return this.product.SoLuong * this.product.DonGia
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
