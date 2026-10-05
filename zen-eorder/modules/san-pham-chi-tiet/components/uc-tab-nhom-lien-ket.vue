<template>
    <div class="page-section">
        <v-card elevation="0">
            <v-toolbar dense flat>
                <v-toolbar-title> Nhóm liên kết </v-toolbar-title>
            </v-toolbar>
            <v-card-text>
                <v-row>
                    <v-col md="5">
                        <v-row>
                            <v-col>
                                <v-select dense v-model="CTSanPham.NhomLienKetID" label="Nhóm liên kết" outlined hide-details :items="DSNhomLienKet" item-value="NhomLienKetID" item-text="MaNhomLienKet"> </v-select>
                            </v-col>
                            <v-col cols="2" style="align-items: center; display: flex">
                                <v-btn :disabled="!CTSanPham.NhomLienKetID" @click="onDelete()" icon color="red">
                                    <v-icon dark>mdi-trash-can</v-icon>
                                </v-btn>
                            </v-col>
                        </v-row>
                    </v-col>
                </v-row>
                <v-data-table class="mt-4" :headers="headers" :items="DSChiTietNhomLienKet" item-key="NhomLienKetChiTietID" :items-per-page="100" :hide-default-footer="true">
                    <template v-slot:item.TenHienThi="{item}">
                        <span :class="item.NhomLienKetChiTiet_ParentID === null ? 'font-weight-bold' : 'ml-10'"> {{ item.ThuTu }}. {{ item.TenHienThi }} </span>
                    </template>
                    <template v-slot:item.MaSanPham="{item}">
                        <span v-if="item.SanPhamID > 0">{{ item.MaSanPham }}</span>
                    </template>
                    <template v-slot:item.SoLuongToiThieu="{item}">
                        <span>{{ item.SoLuongToiThieu }} → {{ item.SoLuongToiDa }}</span>
                    </template>
                    <template v-slot:item.MacDinh="{item}">
                        <v-chip small v-if="item.MacDinh == 1" color="success">Có</v-chip>
                    </template>
                    <template v-slot:item.TinhTrang="{item}">
                        <v-icon dense color="red">{{ item.TinhTrang == 0 ? "" : "mdi-lock" }}</v-icon>
                    </template>
                </v-data-table>
            </v-card-text>
            <v-card-actions>
                <v-btn :disabled="!(CTSanPham.NhomLienKetID > 0)" color="success" v-on:click="onSave()" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu nhóm liên kết</v-btn>
            </v-card-actions>
        </v-card>
    </div>
</template>
<script>
export default {
    props: ["ct_sanpham"],
    computed: {
        CTSanPham: function () {
            return this.ct_sanpham
        },
    },
    data: () => ({
        headers: [
            {text: "Tên hiển thị", value: "TenHienThi"},
            {text: "Sản phẩm", value: "MaSanPham"},
            {text: "Số lượng", value: "SoLuongToiThieu", align: "center"},
            {text: "Mặc định", value: "MacDinh", align: "center"},
            {text: "Tạm khóa", value: "TinhTrang", align: "center"},
        ],
        DSNhomLienKet: [],
        DSChiTietNhomLienKet: [],
    }),
    watch: {
        "CTSanPham.NhomLienKetID": function (data) {
            const $this = this
            if (data) {
                $this.getLinkById()
            }
        },
    },
    methods: {
        getLink() {
            const $this = this
            ajaxCALL("/eorder/NhomLienKet_Select", {}, (res) => {
                $this.DSNhomLienKet = res.data
            })
        },
        getLinkById() {
            const $this = this
            const nhomLienKetID = $this.CTSanPham.NhomLienKetID
            if (nhomLienKetID && nhomLienKetID > 0) {
                ajaxCALL("/eorder/NhomLienKetChiTiet_Select_ByNhomLienKetId", {NhomLienKetID: nhomLienKetID}, (res) => {
                    $this.DSChiTietNhomLienKet = res.data
                })
            }
        },
        onDelete() {
            const $this = this
            const params = {SanPhamID: $this.CTSanPham.SanPhamID, NhomLienKetID: 0}
            ajaxCALL("/eorder/SanPham_Update_NhomLienKet", params, (res) => {
                showToast({type: "green", title: "Xóa nhóm liên kết thành công"})
                $this.CTSanPham.NhomLienKetID = null
                $this.DSChiTietNhomLienKet = []
            })
        },
        onSave() {
            const params = {
                SanPhamID: this.CTSanPham.SanPhamID,
                NhomLienKetID: this.CTSanPham.NhomLienKetID,
            }
            ajaxCALL("/eorder/SanPham_Update_NhomLienKet", params, (res) => {
                showToast({type: "green", title: "Lưu nhóm liên kết thành công"})
            })
        },
    },
    mounted: function () {
        this.getLink()
        this.getLinkById()
    },
}
</script>
