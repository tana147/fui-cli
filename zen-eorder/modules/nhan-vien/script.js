Vue.component("modal_store", {
    props: ["ct_nhanvien"],
    data: () => {
        return {
            CuaHang_Selected: [],
            DSCuaHang_Tree: [],
        }
    },
    template: /*html*/ `
        <v-dialog v-model="vueData.IsShowDialogStore" scrollable width="450">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title>Cửa hàng quản lý <span class="primary--text pl-1">({{CuaHang_Selected.length}} cửa hàng)</span></v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="vueData.IsShowDialogStore = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                   <v-treeview v-model="CuaHang_Selected" selectable :items="DSCuaHang_Tree" selected-color="success" hoverable="true" dense></v-treeview>
                </v-card-text>
                <v-card-actions>
                    <v-spacer/>
                    <v-btn text @click="onSave" color="primary">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    `,
    computed: {
        CTNhanVien: function () {
            return this.ct_nhanvien
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
            const params = {NhanVienID: $this.CTNhanVien.NhanVienID}
            ajaxCALL("/eorder/NhanVienCuaHang_Select_ByNhanVienId", params, (res) => {
                let cuaHangSelected = res.data.map((item) => {
                    return "C" + item.CuaHangID
                })
                $this.CuaHang_Selected = cuaHangSelected
            })
        },
        onSave: function () {
            const $this = this
            const params = {
                NhanVienID: $this.CTNhanVien.NhanVienID,
                CuaHangApDungID: $this.CuaHang_Selected ? $this.CuaHang_Selected.join(",") : "",
            }
            ajaxCALL("/eorder/NhanVien_Update_CuaHang", params, (res) => {
                showMessage({type: "green", title: "Lưu thiết lập cửa hàng thành công"})
                vueData.IsShowDialogStore = false
            })
        },
    },
})
Vue.component("modal_role", {
    props: ["ct_bophan"],
    data: () => {
        return {
            Quyen_Selected: [],
            DSQuyen: [],
            DSNhomQuyen: [],
        }
    },
    template: /*html*/ `
        <v-dialog v-model="vueData.IsShowDialogRole" scrollable width="1100">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title>Phân quyền hệ thống <span class="success--text pl-1">({{Quyen_Selected.length}} quyền)</span></v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="vueData.IsShowDialogRole = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-row>
                        <v-col cols="3" v-for="group in DSNhomQuyen">
                            <p class="primary--text mb-0 mt-3"><b>{{group.MoTa}}</b></p>
                            <v-checkbox class="mt-0" v-for="item in DSQuyen.filter((item) => item.NhomQuyen === group.NhomQuyen)" v-model="Quyen_Selected" :label="item.TenQuyen" :value="item.QuyenID" color="success" hide-details></v-checkbox>
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer/>
                    <v-btn text @click="onSave" color="primary">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    `,
    computed: {
        CTBoPhan: function () {
            return this.ct_bophan
        },
    },
    created() {
        this.getRole()
        this.getRoleApply()
    },
    methods: {
        getRole() {
            const $this = this
            ajaxCALL("/eorder/Quyen_Select", {}, (res) => {
                $this.DSQuyen = res.data[0] ?? []
                $this.DSNhomQuyen = res.data[1] ?? []
            })
        },
        getRoleApply() {
            const $this = this
            const params = {BoPhanID: $this.CTBoPhan.BoPhanID}
            ajaxCALL("/eorder/BoPhanQuyen_Select_ByBoPhanId", params, (res) => {
                let quyenSelected = res.data.map((item) => {
                    return item.QuyenID
                })
                $this.Quyen_Selected = quyenSelected ?? []
            })
        },
        onSave: function () {
            const $this = this
            const params = {
                BoPhanID: $this.CTBoPhan.BoPhanID,
                QuyenApDungID: $this.Quyen_Selected ? $this.Quyen_Selected.join(",") : "",
            }
            ajaxCALL("/eorder/BoPhan_Update_Quyen", params, (res) => {
                showMessage({type: "green", title: "Lưu thiết lập quyền thành công"})
                vueData.IsShowDialogRole = false
            })
        },
    },
})