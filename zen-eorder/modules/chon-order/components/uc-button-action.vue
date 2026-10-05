<template>
    <div class="text-center">
        <v-btn :disabled="vueData.DSBan.length === 0" class="ma-1" color="primary" elevation="0" @click="vueData.IsShowDialogChangeTable = true"><v-icon left>mdi-sync</v-icon>Đổi bàn</v-btn>
        <v-btn :disabled="vueData.DSBan.length === 0" class="ma-1" color="primary" elevation="0" @click="vueData.IsShowDialogMergeTable = true"><v-icon left>mdi-content-copy</v-icon>Gộp bàn</v-btn>
        <v-btn :disabled="vueData.DSBan.length === 0" class="ma-1" color="primary" elevation="0" @click="vueData.IsShowDialogCancelMergeTable = true"><v-icon left>mdi-close-box-multiple-outline</v-icon>Hủy gộp bàn</v-btn>
        <v-btn :disabled="vueData.DSBan.length === 0" class="ma-1" color="primary" elevation="0" @click="vueData.IsShowDialogSplitTable = true"><v-icon left>mdi-scissors-cutting</v-icon>Tách hóa đơn</v-btn>
        <v-btn :disabled="vueData.DSBan.length === 0" class="ma-1" elevation="0" @click="vueData.IshowDialogMangVe = true"><v-icon left>mdi-shopping</v-icon>Mang về</v-btn>
        <uc-modal-change-table v-if="vueData.DSBan.length > 0" :show_dialog="vueData.IsShowDialogChangeTable" />
        <uc-modal-merge-table v-if="vueData.DSBan.length > 0" :show_dialog="vueData.IsShowDialogMergeTable" />
        <uc-modal-merge-cancel-table v-if="vueData.DSBan.length > 0" :show_dialog="vueData.IsShowDialogCancelMergeTable" />
        <uc-modal-split-table v-if="vueData.DSBan.length > 0" :show_dialog="vueData.IsShowDialogSplitTable" />
        <uc-modal-take-away v-if="vueData.DSBan.length > 0" :show_dialog.sync="vueData.IshowDialogMangVe" />
    </div>
</template>

<script>
export default {}
</script>
