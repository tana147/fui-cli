<template>
    <v-dialog v-model="vueData.IsShowDialogMergeTable" scrollable width="500">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Gộp bàn</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogMergeTable = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-select class="mt-3" label="Chọn bàn gộp" outlined dense v-model="DSBanGop_Selected" :items="DSBan" item-value="BanID" item-text="TenBan" hide-details multiple />
                <v-select class="mt-3" label="Chọn bàn Order QR (Bàn chính)" outlined dense v-model="BanID_Order" :disabled="DSBanGop_Selected?.length === 0" :items="DSBanOrder" item-value="BanID" item-text="TenBan" hide-details />
                <p class="mx-2 my-1 error--text">*Lưu ý: QR Order và Hóa đơn sẽ được gộp vào bàn chính. Các bàn gộp sẽ bị tạm khóa đến khi hóa đơn bàn chính được thanh toán</p>
            </v-card-text>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="onSaveMergeTable" color="success">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["show_dialog"],
    data: function () {
        return {
            DSBanGop_Selected: [],
            BanID_Order: null,
        }
    },
    computed: {
        DSBan() {
            return vueData.DSBan
        },
        DSBanOrder() {
            const $this = this
            return $this.DSBan?.filter((item) => $this.DSBanGop_Selected?.indexOf(item.BanID) >= 0) //Filter những bàn được chọn gộp
        },
    },
    watch: {
        show_dialog() {
            const $this = this
            $this.DSBanGop_Selected = []
            $this.BanID_Order = null
        },
    },
    methods: {
        onSaveMergeTable: function () {
            const $this = this
            if ($this.BanID_Order === null) {
                Vue.$toast.error("Vui lòng chọn bàn Order QR (Bàn chính)", {
                    position: "top",
                })
                return
            }
            const params = {
                BanGopId_List: $this.DSBanGop_Selected.join(","),
                BanID_Chinh: $this.BanID_Order,
            }
            ajaxCALL("/eorder/Ban_Update_GopBan", params, (res) => {
                Vue.$toast.success("Đã gộp bàn thành công", {position: "top"})
                vueData.IsShowDialogMergeTable = false
                runAction(vueData.getBan)
            })
        },
    },
}
</script>
