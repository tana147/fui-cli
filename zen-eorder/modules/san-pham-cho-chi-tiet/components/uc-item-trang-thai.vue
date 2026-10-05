<template>
    <v-row>
        <v-col cols="12" class="pb-0 success--text subtitle-1">
            <b>{{ CTSanPham_CuaHang.TenCuaHang }}</b>
        </v-col>
        <v-col cols="12" class="pt-1">
            <v-row>
                <v-col md="2">
                    <v-select v-model="CTSanPham_CuaHang.TinhTrang" dense label="Trạng thái món" :items="DSTinhTrang" hide-details outlined></v-select>
                </v-col>
                <v-col>
                    <v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.ChoPhepBan" label="Bán trực tiếp (POS, mPOS)" color="success" hide-details></v-checkbox>
                </v-col>
                <v-col>
                    <v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.ChoPhepBan_App" label="Bán trên App (Khách Order)" color="success" hide-details></v-checkbox>
                </v-col>
                <v-col>
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
            DSTinhTrang: [
                {
                    text: "Đang bán",
                    value: 0,
                },
                {
                    text: "Tạm hết",
                    value: 1,
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
                SanPham_CuaHang_ChoID: formData.SanPham_CuaHang_ChoID,
                TinhTrang: formData.TinhTrang,
                ChoPhepBan: formData.ChoPhepBan,
                ChoPhepBan_App: formData.ChoPhepBan_App,
            }
            ajaxCALL("/eorder/SanPhamCho_Update_TrangThai", params, (res) => {
                showToast({type: "green", title: "Lưu trạng thái thành công"})
            })
        },
    },
}
</script>
