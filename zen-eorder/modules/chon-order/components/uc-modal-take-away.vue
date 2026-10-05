<template>
    <v-dialog v-model="vueData.IshowDialogMangVe" scrollable width="500">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Mang về</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IshowDialogMangVe = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-list>
                    <template v-if="DSMangVe.length === 0">
                        <div class="text-center pt-5">
                            <p class="text-center"><v-icon large>mdi-inbox-full</v-icon> <br />Không có hóa đơn mang về</p>
                        </div>
                    </template>
                    <template v-else v-for="(item, index) in DSMangVe" :key="index">
                        <v-list-item>
                            <v-list-item-content>
                                <v-list-item-title>
                                    <b class="primary--text">{{ item.MaSoHoaDon }}</b> <v-chip color="success" small>{{ item.TenTrangThai }}</v-chip>
                                </v-list-item-title>
                                <v-list-item-subtitle class="black--text mt-1">
                                    <p class="mb-1" v-if="item.GhiChu.length !== 0">Ghi chú : {{ item.GhiChu }}</p>
                                    <v-row>
                                        <v-col cols="6">
                                            <p class="mb-1">
                                                Tạm tính: <b>{{ item.TongTien.toLocaleString("vi-VN") }}</b>
                                            </p>
                                            <p class="mb-1">
                                                VAT: <b>{{ item.TongVAT.toLocaleString("vi-VN") }}</b>
                                            </p>
                                        </v-col>
                                        <v-col cols="6">
                                            <p class="mb-1">
                                                ZEN: <b>{{ item.KhachTra_Zen.toLocaleString("vi-VN") }}</b>
                                            </p>
                                            <p class="mb-1">
                                                Khách phải trả: <b>{{ item.TienPhaiTra.toLocaleString("vi-VN") }}</b>
                                            </p>
                                        </v-col>
                                    </v-row>
                                </v-list-item-subtitle>
                            </v-list-item-content>
                            <v-list-item-action>
                                <v-btn fab color="primary" small @click="redirectMPOS(item)" elevation="0">
                                    <v-icon>mdi-arrow-right</v-icon>
                                </v-btn>
                            </v-list-item-action>
                        </v-list-item>
                        <v-divider></v-divider>
                    </template>
                </v-list>
            </v-card-text>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="window.location.href = '/order-pos?chid=' + vueData.CuaHangID" color="success">Tạo mới hóa đơn mang về</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["show_dialog"],
    data() {
        return {
            DSMangVe: [],
        }
    },
    watch: {
        show_dialog: function (val) {
            if (val) {
                const params = {CuaHangID: vueData.CuaHangID}
                ajaxCALL("/eorder/HoaDon_Select_MangVe", params, (res) => {
                    if (res.data) {
                        this.DSMangVe = res.data
                    }
                })
            }
        },
    },
    methods: {
        redirectMPOS(item) {
            window.location.href = "/order-pos?chid=" + vueData.CuaHangID + "&hdid=" + item.HoaDonID
        },
    },
}
</script>
