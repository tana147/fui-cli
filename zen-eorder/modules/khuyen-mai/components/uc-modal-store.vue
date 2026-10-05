<template>
    <v-dialog v-model="vueData.IsShowDialogStore" scrollable width="450">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>
                    Cửa hàng áp dụng <span class="primary--text pl-1">({{ CuaHang_Selected.length }} cửa hàng)</span>
                </v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogStore = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-treeview v-model="CuaHang_Selected" selectable :items="DSCuaHang_Tree" selected-color="primary" hoverable="true" dense></v-treeview>
            </v-card-text>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="onSave" color="primary">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["ct_khuyenmai"],
    data: () => {
        return {
            CuaHang_Selected: [],
            DSCuaHang_Tree: [],
        }
    },
    computed: {
        CTKhuyenMai: function () {
            return this.ct_khuyenmai
        },
    },
    created() {
        this.getStore()
        this.getStoreApply()
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
            const params = {ChuongTrinhID: $this.CTKhuyenMai.ChuongTrinhID}
            ajaxCALL("/eorder/ChuongTrinhCuaHang_Select", params, (res) => {
                let cuaHangSelected = res.data.map((item) => {
                    return "C" + item.CuaHangID
                })
                $this.CuaHang_Selected = cuaHangSelected
            })
        },
        onSave: function () {
            const $this = this
            const params = {
                ChuongTrinhID: $this.CTKhuyenMai.ChuongTrinhID,
                CuaHangApDungID: $this.CuaHang_Selected ? $this.CuaHang_Selected.join(",") : "",
            }
            ajaxCALL("/eorder/ChuongTrinhCuaHang_Update", params, (res) => {
                showMessage({type: "green", title: "Lưu thiết lập cửa hàng thành công"})
                vueData.IsShowDialogStore = false
                runAction(vueData.getChuongTrinh)
            })
        },
    },
}
</script>
