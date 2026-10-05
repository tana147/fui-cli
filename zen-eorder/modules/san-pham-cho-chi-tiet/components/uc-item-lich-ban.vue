<template>
    <v-row>
        <v-col cols="12" class="pb-0 success--text subtitle-1">
            <b>{{ CTSanPham_CuaHang.TenCuaHang }}</b>
        </v-col>
        <v-col cols="12" class="pt-1">
            <v-row>
                <v-col>
                    <p class="mb-0"><b>Thứ 2</b></p>
                    <v-text-field single-line v-model="CTSanPham_CuaHang.Thu_2_Tu" dense label="Từ" outlined hide-details></v-text-field>
                    <v-text-field class="mt-1" single-line v-model="CTSanPham_CuaHang.Thu_2_Den" dense label="Đến" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <p class="mb-0"><b>Thứ 3</b></p>
                    <v-text-field single-line v-model="CTSanPham_CuaHang.Thu_3_Tu" dense label="Từ" outlined hide-details></v-text-field>
                    <v-text-field class="mt-1" single-line v-model="CTSanPham_CuaHang.Thu_3_Den" dense label="Đến" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <p class="mb-0"><b>Thứ 4</b></p>
                    <v-text-field single-line v-model="CTSanPham_CuaHang.Thu_4_Tu" dense label="Từ" outlined hide-details></v-text-field>
                    <v-text-field class="mt-1" single-line v-model="CTSanPham_CuaHang.Thu_4_Den" dense label="Đến" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <p class="mb-0"><b>Thứ 5</b></p>
                    <v-text-field single-line v-model="CTSanPham_CuaHang.Thu_5_Tu" dense label="Từ" outlined hide-details></v-text-field>
                    <v-text-field class="mt-1" single-line v-model="CTSanPham_CuaHang.Thu_5_Den" dense label="Đến" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <p class="mb-0"><b>Thứ 6</b></p>
                    <v-text-field single-line v-model="CTSanPham_CuaHang.Thu_6_Tu" dense label="Từ" outlined hide-details></v-text-field>
                    <v-text-field class="mt-1" single-line v-model="CTSanPham_CuaHang.Thu_6_Den" dense label="Đến" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <p class="mb-0"><b>Thứ 7</b></p>
                    <v-text-field single-line v-model="CTSanPham_CuaHang.Thu_7_Tu" dense label="Từ" outlined hide-details></v-text-field>
                    <v-text-field class="mt-1" single-line v-model="CTSanPham_CuaHang.Thu_7_Den" dense label="Đến" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <p class="mb-0"><b>CN</b></p>
                    <v-text-field single-line v-model="CTSanPham_CuaHang.CN_Tu" dense label="Từ" outlined hide-details></v-text-field>
                    <v-text-field class="mt-1" single-line v-model="CTSanPham_CuaHang.CN_Den" dense label="Đến" outlined hide-details></v-text-field>
                </v-col>
                <v-col md="1">
                    <v-btn class="mt-5" color="success" v-on:click="onSave()" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu</v-btn>
                </v-col>
            </v-row>
        </v-col>
    </v-row>
</template>

<script>
export default {
    props: ["sp_ch"],
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
                Thu_2_Tu: formData.Thu_2_Tu,
                Thu_3_Tu: formData.Thu_3_Tu,
                Thu_4_Tu: formData.Thu_4_Tu,
                Thu_5_Tu: formData.Thu_5_Tu,
                Thu_6_Tu: formData.Thu_6_Tu,
                Thu_7_Tu: formData.Thu_7_Tu,
                CN_Tu: formData.CN_Tu,
                Thu_2_Den: formData.Thu_2_Den,
                Thu_3_Den: formData.Thu_3_Den,
                Thu_4_Den: formData.Thu_4_Den,
                Thu_5_Den: formData.Thu_5_Den,
                Thu_6_Den: formData.Thu_6_Den,
                Thu_7_Den: formData.Thu_7_Den,
                CN_Den: formData.CN_Den,
            }
            ajaxCALL("/eorder/SanPhamCho_Update_LichBan", params, (res) => {
                showToast({type: "green", title: "Lưu thiết lập lịch bán thành công"})
            })
        },
    },
}
</script>
