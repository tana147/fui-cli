<template>
    <div>
        <div class="page-section">
            <div class="d-flex flex-row justify-space-between">
                <div class="text-center">
                    Chi phí sản phẩm <br />
                    <b class="red--text">{{ chiPhi_SanPham.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Chi phí sở thích phục phụ <br />
                    <b class="red--text">{{ chiPhi_LienKet.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Tổng chi phí <br />
                    <b class="red--text">{{ (chiPhi_SanPham + chiPhi_LienKet).toLocaleString("vi-vn") }}</b>
                </div>
            </div>
        </div>
        <div class="page-section mt-2">
            <v-card elevation="0">
                <v-toolbar dense flat>
                    <v-toolbar-title>
                        Nguyên liệu món: <span class="success--text ml-1">{{ CTSanPham?.TenSanPham }} - {{ CTSanPham?.MaSanPham }}</span>
                    </v-toolbar-title>
                    <v-btn @click="onOpenProduct" class="mx-3" fab dark x-small elevation="0" color="success">
                        <v-icon dark>mdi-plus</v-icon>
                    </v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-data-table class="mt-4" :headers="header_SanPham" :items="DSNguyenLieu_SanPham" item-key="SanPhamNguyenLieuID" :items-per-page="100" :hide-default-footer="true">
                        <template v-slot:item.GiaSuDung="{item}">
                            <span>{{ item.GiaSuDung.toLocaleString("vi-vn") }}</span>
                        </template>
                        <template v-slot:item.GiaNhap="{item}">
                            <span>{{ item.GiaNhap.toLocaleString("vi-vn") }}</span>
                        </template>
                        <template v-slot:item.ActionDelete="{item}">
                            <v-btn text color="error" @click="onDelete(item)"><v-icon dark>mdi-trash-can</v-icon></v-btn>
                        </template>
                    </v-data-table>
                </v-card-text>
            </v-card>
        </div>
        <div class="page-section mt-2">
            <v-card elevation="0">
                <v-toolbar dense flat>
                    <v-toolbar-title> Nguyên liệu: <span class="success--text ml-1">Sở Thích Phục Vụ</span> </v-toolbar-title>
                    <v-btn @click="onOpenLink" class="mx-3" fab dark x-small elevation="0" color="success">
                        <v-icon dark>mdi-plus</v-icon>
                    </v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-data-table class="mt-4" :headers="header_NhomLienKet" :items="DSNguyenLieu_LienKet" item-key="SanPhamNguyenLieuID" :items-per-page="100" :hide-default-footer="true">
                        <template v-slot:item.GiaSuDung="{item}">
                            <span>{{ item.GiaSuDung.toLocaleString("vi-vn") }}</span>
                        </template>
                        <template v-slot:item.GiaNhap="{item}">
                            <span>{{ item.GiaNhap.toLocaleString("vi-vn") }}</span>
                        </template>
                        <template v-slot:item.ActionDelete="{item}">
                            <v-btn text color="error" @click="onDelete(item)"><v-icon dark>mdi-trash-can</v-icon></v-btn>
                        </template>
                    </v-data-table>
                </v-card-text>
            </v-card>
        </div>
        <v-dialog v-model="isShowDialog_Product" scrollable width="900">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title>Thêm nguyên liệu - [{{ CTSanPham?.MaSanPham }}] {{ CTSanPham?.TenSanPham }}</v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="isShowDialog_Product = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-row>
                        <v-col cols="6">
                            <v-combobox class="mt-2" outlined v-model="FormData.NguyenLieuID" dense label="Nguyên liệu" :items="DMNguyenLieu" item-text="MaTenNguyenLieu" item-value="NguyenLieuID" hide-details></v-combobox>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field class="mt-2" v-model="FormData.GramSuDung" type="number" label="Gram sử dụng" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field class="mt-2" v-model="FormData.GiaSuDung" type="number" label="Chi phí sử dụng" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="6">
                            <v-combobox class="mt-2" outlined v-model="FormData.DonViNhapID" dense label="Đơn vị nhập" :items="DSDonViTinh" item-text="TenDVT" item-value="DonViTinhID" hide-details></v-combobox>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field class="mt-2" v-model="FormData.GiaNhap" type="number" label="Giá nhập" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field class="mt-2" v-model="FormData.HeSoChuyenDoi" label="Hệ số chuyển đổi" outlined dense hide-details></v-text-field>
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer />
                    <v-btn text @click="onSave" color="success">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
        <v-dialog v-model="isShowDialog_Link" scrollable width="900">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title>Thêm nguyên liệu - Sở Thích Phục Vụ</v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="isShowDialog_Link = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-row>
                        <v-col cols="12">
                            <v-combobox class="mt-2" outlined v-model="FormData.NhomLienKetChiTietID" dense label="Sở thích phục vụ" :items="DSChiTietNhomLienKet" item-text="TenNoiBo" item-value="NhomLienKetChiTietID" hide-details></v-combobox>
                        </v-col>
                        <v-col cols="6">
                            <v-combobox class="mt-2" outlined v-model="FormData.NguyenLieuID" dense label="Nguyên liệu" :items="DMNguyenLieu" item-text="MaTenNguyenLieu" item-value="NguyenLieuID" hide-details></v-combobox>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field class="mt-2" v-model="FormData.GramSuDung" type="number" label="Gram sử dụng" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field class="mt-2" v-model="FormData.GiaSuDung" type="number" label="Chi phí sử dụng" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="6">
                            <v-combobox class="mt-2" outlined v-model="FormData.DonViNhapID" dense label="Đơn vị nhập" :items="DSDonViTinh" item-text="TenDVT" item-value="DonViTinhID" hide-details></v-combobox>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field class="mt-2" v-model="FormData.GiaNhap" type="number" label="Giá nhập" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field class="mt-2" v-model="FormData.HeSoChuyenDoi" label="Hệ số chuyển đổi" outlined dense hide-details></v-text-field>
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer />
                    <v-btn text @click="onSave" color="success">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>
<script>
export default {
    props: ["ct_sanpham"],
    data: () => ({
        header_SanPham: [
            {text: "Mã nguyên liệu", value: "MaNguyenLieu"},
            {text: "Tên nguyên liệu", value: "TenNguyenLieu"},
            {text: "Sử dụng (Gram)", value: "GramSuDung", align: "right"},
            {text: "Chi phí sử dụng (VNĐ)", value: "GiaSuDung", align: "right"},
            {text: "Đơn vị nhập", value: "TenDonViNhap", align: "center"},
            {text: "Giá nhập (VNĐ)", value: "GiaNhap", align: "right"},
            {text: "Hệ số chuyển đổi", value: "HeSoChuyenDoi", align: "center"},
            {text: "", value: "ActionDelete"},
        ],
        header_NhomLienKet: [
            {text: "Tên STPV", value: "TenNhomLienKet"},
            {text: "Mã nguyên liệu", value: "MaNguyenLieu"},
            {text: "Tên nguyên liệu", value: "TenNguyenLieu"},
            {text: "Sử dụng (Gram)", value: "GramSuDung", align: "right"},
            {text: "Chi phí sử dụng (VNĐ)", value: "GiaSuDung", align: "right"},
            {text: "Đơn vị nhập", value: "TenDonViNhap", align: "center"},
            {text: "Giá nhập (VNĐ)", value: "GiaNhap", align: "right"},
            {text: "Hệ số chuyển đổi", value: "HeSoChuyenDoi", align: "center"},
            {text: "", value: "ActionDelete"},
        ],
        DSDonViTinh: [],
        DMNguyenLieu: [],
        DSChiTietNhomLienKet: [],
        DSNguyenLieu: [],
        DSNguyenLieu_SanPham: [],
        DSNguyenLieu_LienKet: [],
        FormData: {
            SanPhamNguyenLieuID: 0,
            NhomLienKetChiTietID: null,
            NguyenLieuID: null,
            GramSuDung: 0,
            GiaSuDung: 0,
            DonViNhapID: null,
            GiaNhap: 0,
            HeSoChuyenDoi: "",
        },
        chiPhi_SanPham: 0,
        chiPhi_LienKet: 0,
        isShowDialog_Product: false,
        isShowDialog_Link: false,
    }),
    computed: {
        CTSanPham: function () {
            return this.ct_sanpham
        },
    },
    methods: {
        getUnit() {
            const $this = this
            ajaxCALL("/eorder/DonViTinh_Select", {}, (res) => {
                $this.DSDonViTinh = res.data
            })
        },
        getNguyenLieu() {
            const $this = this
            ajaxCALL("/eorder/NguyenLieu_Select", {}, (res) => {
                $this.DMNguyenLieu = res.data
            })
        },
        getData() {
            const $this = this
            ajaxCALL("/eorder/SanPhamNguyenLieu_Select", {SanPhamID: $this.CTSanPham?.SanPhamID}, (res) => {
                $this.DSNguyenLieu = res.data
                $this.DSNguyenLieu_SanPham = $this.DSNguyenLieu.filter((item) => item.NhomLienKetChiTietID === 0)
                $this.DSNguyenLieu_LienKet = $this.DSNguyenLieu.filter((item) => item.NhomLienKetChiTietID > 0)
                let totalChiPhiSanPham = 0
                let totalChiPhiLienKet = 0
                $this.DSNguyenLieu_SanPham.forEach((item) => {
                    totalChiPhiSanPham += item.GiaSuDung
                })
                $this.DSNguyenLieu_LienKet.forEach((item) => {
                    totalChiPhiLienKet += item.GiaSuDung
                })
                $this.chiPhi_SanPham = totalChiPhiSanPham
                $this.chiPhi_LienKet = totalChiPhiLienKet
            })
        },
        getLinkById() {
            const $this = this
            const nhomLienKetID = $this.CTSanPham.NhomLienKetID
            if (nhomLienKetID && nhomLienKetID > 0) {
                ajaxCALL("/eorder/NhomLienKetChiTiet_Select_ByNhomLienKetId", {NhomLienKetID: nhomLienKetID}, (res) => {
                    const filter = res.data.filter((item) => item.SanPhamID === 0 && item.NhomLienKetChiTiet_ParentID > 0)
                    $this.DSChiTietNhomLienKet = filter
                })
            }
        },
        onOpenProduct() {
            const $this = this
            $this.FormData = {
                SanPhamNguyenLieuID: 0,
                NhomLienKetChiTietID: null,
                NguyenLieuID: null,
                GramSuDung: 0,
                GiaSuDung: 0,
                DonViNhapID: null,
                GiaNhap: 0,
                HeSoChuyenDoi: "",
            }
            $this.isShowDialog_Product = true
        },
        onOpenLink() {
            const $this = this
            $this.FormData = {
                SanPhamNguyenLieuID: 0,
                NguyenLieuID: null,
                GramSuDung: 0,
                GiaSuDung: 0,
                DonViNhapID: null,
                GiaNhap: 0,
                HeSoChuyenDoi: "",
            }
            $this.isShowDialog_Link = true
        },
        onDelete(data) {
            const $this = this
            confirm({
                title: "Xác nhận xóa nguyên liệu",
                content: `Bạn có chắc muốn xóa nguyên liệu ${data.TenNguyenLieu}?`,
                action: function () {
                    ajaxCALL("/eorder/SanPhamNguyenLieu_Delete", {SanPhamNguyenLieuID: data.SanPhamNguyenLieuID}, (res) => {
                        $this.getData()
                    })
                },
            })
        },
        onSave() {
            const $this = this
            //Xử lý param
            $this.FormData.SanPhamID = $this.CTSanPham?.SanPhamID
            $this.FormData.SanPhamNguyenLieuID = 0
            //Nếu thêm nguyên liệu cho sản phẩm
            if ($this.isShowDialog_Product) {
                $this.FormData.NhomLienKetChiTietID = null
            }
            const params = {
                SanPhamID: $this.CTSanPham?.SanPhamID,
                DonViNhapID: $this.FormData.DonViNhapID?.DonViTinhID ?? 0,
                GiaNhap: checkNumber($this.FormData?.GiaNhap) ? $this.FormData?.GiaNhap : 0,
                GiaSuDung: checkNumber($this.FormData?.GiaSuDung) ? $this.FormData?.GiaSuDung : 0,
                GramSuDung: checkNumber($this.FormData?.GramSuDung) ? $this.FormData?.GramSuDung : 0,
                HeSoChuyenDoi: $this.FormData?.HeSoChuyenDoi ?? "",
                NguyenLieuID: $this.FormData.NguyenLieuID?.NguyenLieuID ?? 0,
                NhomLienKetChiTietID: $this.FormData.NhomLienKetChiTietID?.NhomLienKetChiTietID ?? 0,
                Is_SanPham: $this.isShowDialog_Product,
            }
            ajaxCALL("/eorder/SanPhamNguyenLieu_Insert", params, (res) => {
                showToast({type: "green", title: "Lưu nguyên liệu thành công"})
                $this.getData()
                $this.isShowDialog_Product = false
                $this.isShowDialog_Link = false
            })
        },
    },
    mounted: function () {
        this.getData()
        this.getNguyenLieu()
        this.getUnit()
        this.getLinkById()
    },
}
</script>
