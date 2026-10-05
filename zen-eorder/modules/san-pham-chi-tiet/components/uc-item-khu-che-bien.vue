<template>
    <v-row>
        <v-col cols="12" class="pb-0 success--text subtitle-1">
            <b>{{ sp_ch.TenCuaHang }}</b>
        </v-col>
        <v-col cols="12" class="pt-1">
            <v-row>
                <v-col><v-select dense v-model="sp_ch.KhuCheBienID" label="Khu chế biến (Chính)" outlined hide-details :items="KhuCheBien_Filter" item-value="KhuCheBienID" item-text="TenKhuCheBien_MayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.KhuCheBienID_1" label="Khu chế biến 1" outlined hide-details :items="KhuCheBien_Filter" item-value="KhuCheBienID" item-text="TenKhuCheBien_MayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.KhuCheBienID_2" label="Khu chế biến 2" outlined hide-details :items="KhuCheBien_Filter" item-value="KhuCheBienID" item-text="TenKhuCheBien_MayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.KhuCheBienID_3" label="Khu chế biến 3" outlined hide-details :items="KhuCheBien_Filter" item-value="KhuCheBienID" item-text="TenKhuCheBien_MayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.KhuCheBienID_4" label="Khu chế biến 4" outlined hide-details :items="KhuCheBien_Filter" item-value="KhuCheBienID" item-text="TenKhuCheBien_MayIn" /></v-col>
                <v-col><v-select dense v-model="sp_ch.KhuCheBienID_5" label="Khu chế biến 5" outlined hide-details :items="KhuCheBien_Filter" item-value="KhuCheBienID" item-text="TenKhuCheBien_MayIn" /></v-col>
                <v-col>
                    <v-btn color="success" v-on:click="onSave()" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu</v-btn>
                </v-col>
            </v-row>
        </v-col>
    </v-row>
</template>
<script>
export default {
    props: ["sp_ch", "kcb"],
    computed: {
        KhuCheBien_Filter: function () {
            const $this = this
            const data_filter = $this.kcb.filter((item) => item.CuaHangID === $this.sp_ch.CuaHangID)
            data_filter.unshift({
                CuaHangID: 0,
                KhuCheBienID: null,
                TenKhuCheBien: null,
                TenMayIn: null,
                TenKhuCheBien_MayIn: "Không",
            })
            return data_filter
        },
    },
    methods: {
        onSave() {
            const $this = this
            const formData = $this.sp_ch
            const params = {
                SanPham_CuaHangID: formData.SanPham_CuaHangID,
                KhuCheBienID: formData.KhuCheBienID ?? 0,
                KhuCheBienID_1: formData.KhuCheBienID_1 ?? 0,
                KhuCheBienID_2: formData.KhuCheBienID_2 ?? 0,
                KhuCheBienID_3: formData.KhuCheBienID_3 ?? 0,
                KhuCheBienID_4: formData.KhuCheBienID_4 ?? 0,
                KhuCheBienID_5: formData.KhuCheBienID_5 ?? 0,
            }
            ajaxCALL("/eorder/SanPham_Update_KhuCheBien", params, (res) => {
                showToast({type: "green", title: "Lưu thiết lập khu vực chế biến thành công"})
            })
        },
    },
}
</script>
