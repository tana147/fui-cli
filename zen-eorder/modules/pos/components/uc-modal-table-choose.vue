<template>
    <v-dialog v-model="vueData.IsShowDialogChooseTable" width="500" scrollable>
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Chọn bàn</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogChooseTable = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-row>
                    <v-col cols="6">
                        <v-autocomplete v-model="vueData.HoaDon.LauID" label="Lầu" :items="vueData.DSLau" item-text="TenLau" item-value="LauID" outlined dense @change="onChangeLau" />
                    </v-col>
                    <v-col cols="6">
                        <v-autocomplete v-model="vueData.HoaDon.KhuID" label="Khu vực" :items="vueData.DSKhu" item-text="TenKhu" item-value="KhuID" outlined dense @change="onChangeKhu" />
                    </v-col>
                </v-row>
                <div class="my-4 list-ban">
                    <template v-for="item in vueData.DSBan" :key="item.BanID">
                        <uc-tab-table-item :item="item" :is_modal_choose="true"/>
                    </template>
                </div>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: [],
    data() {
        return {}
    },
    mounted() {},
    watch: {},
    computed: {},
    methods: {
        onChangeLau(value) {
            let obj = vueData.DSLau.find((item) => item.LauID === value)
            vueData.HoaDon.TenLau = obj.TenLau
        },
        onChangeKhu(value) {
            let obj = this.DSKhu.find((item) => item.KhuID === value)
            vueData.HoaDon.TenKhu = obj.TenKhu
        },
        StyleStatus(item) {
            let style = "font-size: 16px;font-weight: 500;color: #b3b3b3!important;"
            if (item.HoaDonID > 0) {
                style += `;color:#4caf50!important;background-color:#c8edc8`
            }
            if (item.Is_TreMon_1) {
                style += `;color:#fff!important;border-color:${item.MauThoiGianCheBien_1};background-color:${item.MauThoiGianCheBien_1}`
            }
            if (item.Is_TreMon_2) {
                style += `;color:#fff!important;border-color:${item.MauThoiGianCheBien_2};background-color:${item.MauThoiGianCheBien_2}`
            }
            if (item.Is_YeuCauThanhToan) {
                style += `;color:#fff!important;border-color:${item.MauYeuCauThanhToan};background-color:${item.MauYeuCauThanhToan}`
            }
            if (item.Is_MangVe) {
                style += `;border: 3px solid ${item.MauMangVe}`
            }
            return style
        },
    },
}
</script>
