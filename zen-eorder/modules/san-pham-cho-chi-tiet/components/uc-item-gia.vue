<template>
    <v-row>
        <v-col cols="12" class="pb-0 success--text subtitle-1">
            <b>{{ CTSanPham_CuaHang.TenCuaHang }}</b>
        </v-col>
        <v-col cols="12" class="pt-1">
            <v-row>
                <v-col>
                    <v-text-field type="number" v-model="CTSanPham_CuaHang.GiaBan_CuaHang" dense label="Giá bán (Tại cửa hàng)" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <v-text-field type="number" v-model="CTSanPham_CuaHang.VAT_CuaHang" dense label="% Thuế VAT (Tại cửa hàng)" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <v-text-field type="number" v-model="CTSanPham_CuaHang.GiaBan_App" dense label="Giá bán (Trên App)" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <v-text-field type="number" v-model="CTSanPham_CuaHang.VAT_App" dense label="% Thuế VAT (Trên App)" outlined hide-details></v-text-field>
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
                GiaBan_CuaHang: formData.GiaBan_CuaHang,
                GiaBan_App: formData.GiaBan_App,
                VAT_CuaHang: formData.VAT_CuaHang,
                VAT_App: formData.VAT_App,
            }
            ajaxCALL("/eorder/SanPhamCho_Update_Gia", params, (res) => {
                showToast({type: "green", title: "Lưu thiết lập giá thành công"})
            })
        },
    },
}
</script>
