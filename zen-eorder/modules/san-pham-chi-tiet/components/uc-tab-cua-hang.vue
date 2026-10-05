<template>
    <div class="page-section">
        <v-card elevation="0">
            <v-toolbar dense flat>
                <v-toolbar-title>
                    Cửa hàng áp dụng<span class="ml-2 success--text">({{ CuaHang_Selected.length }} cửa hàng)</span>
                </v-toolbar-title>
            </v-toolbar>
            <v-card-text class="pl-0">
                <v-treeview v-model="CuaHang_Selected" selectable :items="DSCuaHang_Tree" selected-color="success" hoverable="true" dense></v-treeview>
            </v-card-text>
            <v-card-actions>
                <v-btn color="success" v-on:click="onSave()" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu cửa hàng áp dụng</v-btn>
            </v-card-actions>
        </v-card>
    </div>
</template>
<script>
export default {
    props: ["ct_sanpham"],
    data: () => {
        return {
            CuaHang_Selected: [],
            DSCuaHang_Tree: [],
        }
    },
    computed: {
        CTSanPham: function () {
            return this.ct_sanpham ?? {}
        },
    },
    methods: {
        getStore() {
            const $this = this
            ajaxCALL("/eorder/CuaHang_Select_Tree", {}, (res) => {
                $this.DSCuaHang_Tree = convertJsonToTree(res.data)
            })
        },
        getStoreApply() {
            const $this = this
            ajaxCALL("/eorder/SanPhamCuaHang_Select_ById", {SanPhamID: $this.CTSanPham.SanPhamID}, (res) => {
                let cuaHangSelected = res.data.map((item) => {
                    return "C" + item.CuaHangID
                })
                $this.CuaHang_Selected = cuaHangSelected
            })
        },
        onSave() {
            const $this = this
            const formData = $this.CTSanPham
            const params = {
                SanPhamID: formData.SanPhamID,
                CuaHangApDungID: $this.CuaHang_Selected ? $this.CuaHang_Selected.join(",") : "",
            }
            ajaxCALL("/eorder/SanPham_Update_CuaHang", params, (res) => {
                showToast({type: "green", title: "Lưu cửa hàng áp dụng thành công"})
                runAction(vueData.getSanPhamCuaHang)
            })
        },
    },
    mounted: function () {
        this.getStore()
        this.getStoreApply()
    },
}
</script>
