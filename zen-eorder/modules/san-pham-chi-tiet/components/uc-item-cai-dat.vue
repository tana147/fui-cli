<template>
    <v-row>
        <v-col cols="12" class="pb-0 success--text subtitle-1">
            <b>{{ CTSanPham_CuaHang.TenCuaHang }}</b>
        </v-col>
        <v-col cols="12" class="pt-1">
            <v-row>
                <v-col md="1">
                    <v-text-field v-model="CTSanPham_CuaHang.MaSoSanPham" dense label="Mã số" outlined hide-details></v-text-field>
                </v-col>
                <v-col md="2">
                    <v-text-field v-model="CTSanPham_CuaHang.SoLuongTon" dense label="Số lượng tồn" outlined hide-details></v-text-field>
                </v-col>
                <v-col md="2">
                    <v-select v-model="CTSanPham_CuaHang.CachBan" dense label="Cách bán" :items="DSCachBan" hide-details outlined></v-select>
                </v-col>
                <v-col>
                    <v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.SoLuongThapPhan" label="Thập phân" color="success" hide-details></v-checkbox>
                </v-col>
                <v-col>
                    <v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.MaintainQuanlityRatio" label="Ratio" color="success" hide-details></v-checkbox>
                </v-col>
                <v-col>
                    <v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.Is_Signature" label="Signature" color="success" hide-details></v-checkbox>
                </v-col>
                <v-col>
                    <v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.Is_BestSeller" label="Bán chạy" color="success" hide-details></v-checkbox>
                </v-col>
                <v-col md="1">
                    <v-btn color="success" v-on:click="onSave()" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu</v-btn>
                </v-col>
            </v-row>
        </v-col>
    </v-row>
</template>

<script>
export default {
    props: ["sp_ch"],
    data: () => {
        return {
            DSCachBan: [
                {
                    text: "Trực tiếp",
                    value: 0,
                },
                {
                    text: "Linh động",
                    value: 1,
                },
                {
                    text: "Kèm theo",
                    value: 2,
                },
            ],
        }
    },
    computed: {
        CTSanPham_CuaHang: function () {
            return this.sp_ch ?? {}
        },
    },
    methods: {
        onSave() {
            const $this = this
            const formData = $this.CTSanPham_CuaHang
            const params = {
                SanPham_CuaHangID: formData.SanPham_CuaHangID,
                MaSoSanPham: formData.MaSoSanPham,
                SoLuongTon: formData.SoLuongTon,
                CachBan: formData.CachBan,
                QuanLyLot: formData.QuanLyLot,
                QuanLyTon: formData.QuanLyTon,
                SoLuongThapPhan: formData.SoLuongThapPhan,
                MaintainQuanlityRatio: formData.MaintainQuanlityRatio,
                Is_Signature: formData.Is_Signature,
                Is_BestSeller: formData.Is_BestSeller,
            }
            ajaxCALL("/eorder/SanPham_Update_CaiDat", params, (res) => {
                showToast({type: "green", title: "Lưu cài đặt thành công"})
                //Gửi Socket sang màn hình Menu POS
                const webSocketHubMenu = `menu_pos_${$this.sp_ch.CuaHangID}`
                vueData.webSocket = {[webSocketHubMenu]: null}
                webSocket_Send({group: webSocketHubMenu, data: Date.now()})
            })
        },
    },
}
</script>
