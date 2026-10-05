<template>
    <v-container class="pa-0">
        <div class="page-navigation" style="padding: 10px 4px">
            <v-row>
                <v-col cols="2" offset="4">
                    <v-autocomplete v-model="vueData.HoaDon.LauID" label="Lầu" :items="ViTri.DSLau" item-text="TenLau" item-value="LauID" outlined dense hide-details />
                </v-col>
                <v-col cols="2">
                    <v-autocomplete v-model="vueData.HoaDon.KhuID" label="Khu vực" :items="ViTri.DSKhu" item-text="TenKhu" item-value="KhuID" outlined dense hide-details />
                </v-col>
            </v-row>
        </div>
        <div class="page-navigation d-flex justify-center" style="gap: 4px">
            <v-btn class="ma-1" color="primary" elevation="0" @click="vueData.IsShowDialogChangeTable = true"><v-icon left>mdi-sync</v-icon>Đổi bàn</v-btn>
            <v-btn class="ma-1" color="primary" elevation="0" @click="vueData.IsShowDialogMergeTable = true"><v-icon left>mdi-content-copy</v-icon>Gộp bàn</v-btn>
            <v-btn class="ma-1" color="primary" elevation="0" @click="vueData.IsShowDialogCancelMergeTable = true"><v-icon left>mdi-close-box-multiple-outline</v-icon>Hủy gộp bàn</v-btn>
            <v-btn class="ma-1" color="primary" elevation="0" @click="vueData.IsShowDialogSplitTable = true"><v-icon left>mdi-scissors-cutting</v-icon>Tách hóa đơn</v-btn>
            <uc-modal-table-change :show_dialog="vueData.IsShowDialogChangeTable" />
            <uc-modal-table-merge :show_dialog="vueData.IsShowDialogMergeTable" />
            <uc-modal-table-merge-cancel :show_dialog="vueData.IsShowDialogCancelMergeTable" />
            <uc-modal-table-split :show_dialog="vueData.IsShowDialogSplitTable" />
        </div>
        <v-row>
            <v-col cols="8" offset="2">
                <div class="my-4 list-ban">
                    <template v-for="item in ViTri.DSBan" :key="item.BanID">
                        <uc-tab-table-item :item="item" :is_modal_choose="false" />
                    </template>
                </div>
            </v-col>
        </v-row>
    </v-container>
</template>

<script>
export default {
    props: ["dslau", "dskhu", "dsban"],
    data() {
        return {
            ViTri: {
                DSLau: this.dslau,
                DSKhu: this.dskhu,
                DSBan: this.dsban,
            },
        }
    },
    watch: {
        dslau: function (value) {
            //Render lại khi DSLau thay đổi
            this.ViTri.DSLau = value
        },
        dskhu: function (value) {
            //Render lại khi DSKhu thay đổi
            this.ViTri.DSKhu = value
        },
        dsban: function (value) {
            //Render lại khi DSBan thay đổi
            this.ViTri.DSBan = value
        },
    },
}
</script>
