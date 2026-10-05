<template>
    <div class="text-left">
        <v-btn color="primary" @click="vueData.IsShowDialogSettingProduct = true" elevation="0"><v-icon left>mdi-cog</v-icon>Thiết lập nhiều cửa hàng</v-btn>
        <uc-modal-thiet-lap-nang-cao :show_dialog="vueData.IsShowDialogSettingProduct" :ct_sanpham="ct_sanpham" :sp_ch="sp_ch" />
    </div>
</template>

<script>
export default {
    props: ["ct_sanpham", "sp_ch"],
}
</script>
