<template>
    <div :class="topping?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="topping?.SanPhamID > 0 ? 'width: 100%; background-color: #fff;padding: 3px 0;' : ''">
        <div v-if="topping?.SanPhamID > 0">
            <div class="tr-product">
                <div class="td-product-name-send pl-5 py-0">
                    + {{ topping?.TenHienThi }} <span style="font-size: 11px" class="gray-text" v-if="topping.TienVAT > 0"><br />VAT ({{ topping?.PhanTramVAT }}%): {{ topping?.TienVAT?.toLocaleString("vi-vn") }}</span>
                    <br />
                </div>
                <div class="td-product-qty py-0">{{ roundSoLuong(topping?.SoLuong) }}</div>
                <div class="td-product-price pr-1 py-0">{{ (topping?.SoLuong * topping?.DonGia).toLocaleString("vi-vn") }}</div>
                <div class="td-product-action" @click.stop="onUpdateDetailZen" :style="{cursor: 'pointer', visibility: HienThiCheckBoxDetailZEN}">
                    <v-icon color="success">{{ topping.Is_ThanhToanZen === 1 ? "mdi-checkbox-marked" : "mdi-checkbox-blank-outline" }}</v-icon>
                </div>
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
    props: ["topping", "khachhang", "zen_con_lai"],
    computed: {
        HienThiCheckBoxDetailZEN: function () {
            return this.khachhang.ZEN > 0 ? "unset" : "hidden"
        },
    },
    methods: {
        onUpdateDetailZen() {
            const $this = this
            if ($this.zen_con_lai < $this.topping.ThanhTien && $this.topping.Is_ThanhToanZen === 0) {
                return Vue.$toast.warning(`Tổng ZEN còn ${this.zen_con_lai.toLocaleString("vi-vn")}, hãy check topping khác`, {position: "top"})
            }
            $this.topping.Is_ThanhToanZen = $this.topping.Is_ThanhToanZen === 0 ? 1 : 0
        },
    },
}
</script>
