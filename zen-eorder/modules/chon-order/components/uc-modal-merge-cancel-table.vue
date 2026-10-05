<template>
    <v-dialog v-model="vueData.IsShowDialogCancelMergeTable" scrollable width="500">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Hủy gộp bàn</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogCancelMergeTable = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-select class="mt-3" label="Chọn bàn hủy gộp" outlined dense v-model="BanID" :items="DSBanCancel" item-value="BanID" item-text="TenBan" hide-details />
                <p class="mx-2 my-1 error--text">*Lưu ý: Dữ liệu hóa đơn đã được gộp vẫn lưu ở bàn chính</p>
            </v-card-text>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="onSaveCancelMergeTable" color="success">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["show_dialog"],
    data: function () {
        return {
            BanID: null,
        }
    },
    computed: {
        DSBan() {
            return vueData.DSBan
        },
        DSBanCancel() {
            const $this = this
            return $this.DSBan?.filter((item) => item.TrangThai === 6) //Filter những bàn đang gộp
        },
    },
    watch: {
        show_dialog() {
            const $this = this
            $this.BanID = null
        },
    },
    methods: {
        onSaveCancelMergeTable: function () {
            const $this = this
            const params = {BanID: $this.BanID}
            ajaxCALL("/eorder/Ban_Update_HuyGopBan", params, (res) => {
                Vue.$toast.success("Hủy gộp bàn thành công", {position: "top"})
                vueData.IsShowDialogCancelMergeTable = false
                runAction(vueData.getBan)
            })
        },
    },
}
</script>
