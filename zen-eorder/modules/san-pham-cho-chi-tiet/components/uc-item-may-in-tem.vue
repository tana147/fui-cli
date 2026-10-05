<template>
    <v-row>
        <v-col cols="12" class="pb-0 success--text subtitle-1">
            <b>{{ sp_ch.TenCuaHang }}</b>
        </v-col>
        <v-col cols="12" class="pt-1">
            <v-row>
                <v-col><v-select dense v-model="sp_ch.MayInTemID" label="Máy in tem (Chính)" outlined hide-details :items="MayInTem_Filter" item-value="MayInTemID" item-text="TenMayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.MayInTemID_1" label="Máy in tem 1" outlined hide-details :items="MayInTem_Filter" item-value="MayInTemID" item-text="TenMayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.MayInTemID_2" label="Máy in tem 2" outlined hide-details :items="MayInTem_Filter" item-value="MayInTemID" item-text="TenMayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.MayInTemID_3" label="Máy in tem 3" outlined hide-details :items="MayInTem_Filter" item-value="MayInTemID" item-text="TenMayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.MayInTemID_4" label="Máy in tem 4" outlined hide-details :items="MayInTem_Filter" item-value="MayInTemID" item-text="TenMayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.MayInTemID_5" label="Máy in tem 5" outlined hide-details :items="MayInTem_Filter" item-value="MayInTemID" item-text="TenMayIn" /></v-col>
                <v-col>
                    <v-btn color="success" v-on:click="onSave()" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu</v-btn>
                </v-col>
            </v-row>
        </v-col>
    </v-row>
</template>

<script>
export default {
    props: ["sp_ch", "mit"],
    computed: {
        MayInTem_Filter: function () {
            const $this = this
            const data_filter = $this.mit.filter((item) => item.CuaHangID === $this.sp_ch.CuaHangID)
            data_filter.unshift({
                CuaHangID: 0,
                MayInTemID: null,
                TenMayIn: "Không",
            })
            return data_filter
        },
    },
    methods: {
        onSave() {
            const $this = this
            const formData = $this.sp_ch
            const params = {
                SanPham_CuaHang_ChoID: formData.SanPham_CuaHang_ChoID,
                MayInTemID: formData.MayInTemID ?? 0,
                MayInTemID_1: formData.MayInTemID_1 ?? 0,
                MayInTemID_2: formData.MayInTemID_2 ?? 0,
                MayInTemID_3: formData.MayInTemID_3 ?? 0,
                MayInTemID_4: formData.MayInTemID_4 ?? 0,
                MayInTemID_5: formData.MayInTemID_5 ?? 0,
            }
            ajaxCALL("/eorder/SanPhamCho_Update_MayInTem", params, (res) => {
                showToast({type: "green", title: "Lưu thiết lập máy in tem thành công"})
            })
        },
    },
}
</script>
