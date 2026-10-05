<template>
    <v-dialog v-model="vueData.IsShowDialogChangeTable" scrollable width="500">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Đổi bàn</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogChangeTable = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <p class="font-weight-bold primary--text mb-2">Đổi từ bàn</p>
                <v-select class="mt-1" label="Bàn" outlined dense v-model="BanID_Cu" :items="DSBan_Cu" item-value="BanID" item-text="TenBan" hide-details />
                <p class="mx-2 my-1 error--text">*Lưu ý: Chỉ được đổi bàn đang được tiếp nhận đơn hàng</p>
                <p class="font-weight-bold primary--text mb-2">Đổi sang bàn</p>
                <v-autocomplete class="mt-1" v-model="LauID" label="Lầu" :items="vueData.DSLau" item-text="TenLau" item-value="LauID" outlined hide-details dense />
                <v-autocomplete class="mt-3" v-model="KhuID" label="Khu vực" :items="DSKhu" item-text="TenKhu" item-value="KhuID" outlined hide-details dense />
                <v-select class="mt-3" label="Bàn" outlined dense v-model="BanID_Moi" :items="DSBan_Moi" item-value="BanID" item-text="TenBan" hide-details />
                <p class="mx-2 my-1 error--text">*Lưu ý: Chỉ được đổi sang bàn trống chưa được tiếp nhận đơn hàng</p>
            </v-card-text>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="onSaveChangeTable" color="success">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["show_dialog"],
    data: function () {
        return {
            BanID_Cu: null,
            BanID_Moi: null,
            LauID: vueData.LauID ?? 0,
            KhuID: vueData.KhuID ?? 0,
            DSLau: vueData.DSLau ?? [],
            DSKhu: vueData.DSKhu ?? [],
            DSBan_Moi: vueData.DSBan ?? [],
        }
    },
    computed: {
        DSBan_Cu() {
            return vueData.DSBan?.filter((item) => item.HoaDonID > 0) //Filter bàn có hóa đơn
        },
    },
    watch: {
        show_dialog(value) {
            const $this = this
            if (value === false) {
                $this.BanID_Cu = null
                $this.BanID_Moi = null
            }
        },
        LauID(value) {
            const $this = this
            if (value) {
                runAction(vueData.getKhuSelectByLauId)
            }
        },
        KhuID(value) {
            const $this = this
            if (value) {
                runAction(vueData.getBan)
            }
        },
    },
    methods: {
        onSaveChangeTable: function () {
            const $this = this
            const params = {
                BanID_Cu: $this.BanID_Cu,
                BanID_Moi: $this.BanID_Moi,
            }
            ajaxCALL("/eorder/Ban_Update_DoiBan", params, (res) => {
                Vue.$toast.success("Đã đổi bàn thành công", {position: "top"})
                vueData.IsShowDialogChangeTable = false
                runAction(vueData.getBan)
            })
        },
    },
}
</script>
