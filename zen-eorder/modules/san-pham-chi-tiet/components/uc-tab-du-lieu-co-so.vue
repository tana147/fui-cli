<template>
    <div class="page-section">
        <v-card elevation="0">
            <v-toolbar dense flat>
                <v-toolbar-title>Dữ liệu cơ sở</v-toolbar-title>
            </v-toolbar>
            <v-card-text>
                <v-row>
                    <v-col md="3">
                        <f-image-update v-model="CTSanPham.AnhSanPham_Url" v-on:update="onUpload" :api-upload="vueData.v_Set.apiFile" label="Ảnh sản phẩm" dialog-width="600" dialog-height="400" :size="{width: 800, height: 800}" quality="0.5" :croper-attr="{'stencil-props': {aspectRatio: 1}, 'default-size': {width: 9999, height: 9999}, transitions: true, 'image-restriction': 'fit-area'}" />
                    </v-col>
                    <v-col md="9">
                        <v-row>
                            <v-col md="2">
                                <v-text-field v-model="CTSanPham.MaSanPham" dense label="Mã sản phẩm" outlined hide-details readonly></v-text-field>
                            </v-col>
                            <v-col md="5">
                                <v-text-field v-model="CTSanPham.TenSanPham" dense label="Tên sản phẩm" outlined hide-details :rules="[rules.required]"></v-text-field>
                            </v-col>
                            <v-col md="5">
                                <v-text-field v-model="CTSanPham.TenNgan" dense label="Tên ngắn" outlined hide-details :rules="[rules.required]"></v-text-field>
                            </v-col>
                            <v-col md="12">
                                <v-text-field v-model="CTSanPham.TenSanPham_HoaDon" dense label="Tên hiển thị hoá đơn điện tử" outlined hide-details :rules="[rules.required]"></v-text-field>
                            </v-col>
                            <v-col md="12">
                                <v-textarea v-model="CTSanPham.MoTa" dense label="Mô tả" outlined hide-details rows="2"></v-textarea>
                            </v-col>
                            <v-col md="3">
                                <v-select v-model="CTSanPham.LoaiSanPham" dense label="Loại sản phẩm" :items="DSLoaiSanPham" hide-details outlined></v-select>
                            </v-col>
                            <v-col md="3">
                                <v-select dense v-model="CTSanPham.DonViTinhID" label="Đơn vị bán" outlined hide-details :items="DSDonViTinh" item-value="DonViTinhID" item-text="TenDVT" />
                            </v-col>
                            <v-col md="2">
                                <v-text-field v-model="CTSanPham.ChiSoNo" type="number" dense label="Chỉ số no" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col md="2">
                                <v-text-field v-model="CTSanPham.ThoiGianCheBien_1" type="number" dense label="TGCB mức 1 (Phút)" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col md="2">
                                <v-text-field v-model="CTSanPham.ThoiGianCheBien_2" type="number" dense label="TGCB mức 2 (Phút)" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col md="3">
                                <v-select dense v-model="CTSanPham.NhomSanPhamID" label="Nhóm sản phẩm" outlined hide-details :items="DSNhomSanPham" item-value="NhomSanPhamID" item-text="TenNhomSanPham" />
                            </v-col>
                            <v-col md="3">
                                <v-select dense v-model="CTSanPham.NhomSanPham_HoaDonID" label="Nhóm hóa đơn" outlined hide-details :items="DSNhomSanPhamHoaDon" item-value="NhomSanPham_HoaDonID" item-text="TenNhomSanPhamHoaDon" />
                            </v-col>
                            <v-col md="4">
                                <v-select dense v-model="CTSanPham.NhomLoaiLyID" label="Nhóm loại ly" outlined hide-details :items="DSNhomLoaiLy" item-value="NhomLoaiLyID" item-text="TenNhomLoaiLy" />
                            </v-col>
                             <v-col md="2">
                                <v-text-field v-model="CTSanPham.DiemLoaiLy" type="number" dense label="Điểm loại ly" outlined hide-details></v-text-field>
                            </v-col>
                        </v-row>
                    </v-col>
                    <v-col md="12">
                        <p class="black--text subtitle-1 mb-1"><b>Mã pha chế</b></p>
                        <v-row>
                            <v-col md="4">
                                <v-text-field v-model="CTSanPham.MaPhaChe" dense label="Mã pha chế" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col md="2">
                                <v-text-field v-model="CTSanPham.MaLy" dense label="Mã ly (Cup Size)" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col md="2">
                                <v-text-field v-model="CTSanPham.MaViMacDinh" dense label="Mã vị" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col md="2">
                                <v-text-field v-model="CTSanPham.MaNhietDoMacDinh" dense label="Mã nhiệt độ" outlined hide-details></v-text-field>
                            </v-col>
                        </v-row>
                    </v-col>
                    <v-col md="12">
                        <p class="black--text subtitle-1 mb-1"><b>Nhóm báo cáo</b></p>
                        <v-row>
                            <v-col md="2">
                                <v-select dense v-model="CTSanPham.NhomSanPham_BaoCaoID" label="Nhóm báo cáo (chính)" outlined hide-details :items="DSNhomSanPhamBaoCao" item-value="NhomSanPham_BaoCaoID" item-text="TenNhomSanPhamBaoCao" />
                            </v-col>
                            <v-col md="2">
                                <v-select dense v-model="CTSanPham.NhomSanPham_BaoCaoID_1" label="Nhóm báo cáo 1" outlined hide-details :items="DSNhomSanPhamBaoCao" item-value="NhomSanPham_BaoCaoID" item-text="TenNhomSanPhamBaoCao" />
                            </v-col>
                            <v-col md="2">
                                <v-select dense v-model="CTSanPham.NhomSanPham_BaoCaoID_2" label="Nhóm báo cáo 2" outlined hide-details :items="DSNhomSanPhamBaoCao" item-value="NhomSanPham_BaoCaoID" item-text="TenNhomSanPhamBaoCao" />
                            </v-col>
                            <v-col md="2">
                                <v-select dense v-model="CTSanPham.NhomSanPham_BaoCaoID_3" label="Nhóm báo cáo 3" outlined hide-details :items="DSNhomSanPhamBaoCao" item-value="NhomSanPham_BaoCaoID" item-text="TenNhomSanPhamBaoCao" />
                            </v-col>
                            <v-col md="2">
                                <v-select dense v-model="CTSanPham.NhomSanPham_BaoCaoID_4" label="Nhóm báo cáo 4" outlined hide-details :items="DSNhomSanPhamBaoCao" item-value="NhomSanPham_BaoCaoID" item-text="TenNhomSanPhamBaoCao" />
                            </v-col>
                            <v-col md="2">
                                <v-select dense v-model="CTSanPham.NhomSanPham_BaoCaoID_5" label="Nhóm báo cáo 5" outlined hide-details :items="DSNhomSanPhamBaoCao" item-value="NhomSanPham_BaoCaoID" item-text="TenNhomSanPhamBaoCao" />
                            </v-col>
                        </v-row>
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions>
                <v-btn color="success" v-on:click="onSave()" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu dữ liệu cơ sở</v-btn>
            </v-card-actions>
        </v-card>
    </div>
</template>

<script>
export default {
    props: ["ct_sanpham"],
    data: () => {
        return {
            DSDonViTinh: [],
            DSNhomSanPham: [],
            DSNhomSanPhamHoaDon: [],
            DSNhomSanPhamBaoCao: [],
            DSNhomLoaiLy: [],
            DSLoaiSanPham: [
                {text: "Sản phẩm", value: 0},
                {text: "Dịch vụ", value: 1},
                {text: "Nguyên liệu", value: 2},
            ],
            rules: {
                required: (value) => !!value || "Bắt buộc",
            },
        }
    },
    computed: {
        CTSanPham: function () {
            return this.ct_sanpham ?? {}
        },
    },
    methods: {
        onUpload($event) {
            const $this = this
            $this.CTSanPham.AnhSanPham_FileID = $event.returnData.Files[0].FileID
            $this.CTSanPham.AnhSanPham_Url = vueData.v_Set.urlReturnFile + $event.returnData.Files[0].Url
        },
        getUnit() {
            const $this = this
            ajaxCALL("/eorder/DonViTinh_Select", {}, (res) => {
                $this.DSDonViTinh = res.data
            })
        },
        getProductGroup() {
            const $this = this
            ajaxCALL("/eorder/NhomSanPham_Select", {}, (res) => {
                $this.DSNhomSanPham = res.data
            })
        },
        getProductGroupInvoice() {
            const $this = this
            ajaxCALL("/eorder/NhomSanPhamHoaDon_Select", {}, (res) => {
                $this.DSNhomSanPhamHoaDon = res.data
            })
        },
        getProductGroupReport() {
            const $this = this
            ajaxCALL("/eorder/NhomSanPhamBaoCao_Select", {}, (res) => {
                $this.DSNhomSanPhamBaoCao = res.data
            })
        },
        getCupType() {
            const $this = this
            ajaxCALL("/eorder/NhomLoaiLy_Select", {}, (res) => {
                $this.DSNhomLoaiLy = res.data
                $this.DSNhomLoaiLy.unshift({
                    NhomLoaiLyID: 0,
                    TenNhomLoaiLy: "Trống",
                    MoTa: "",
                })
            })
        },
        onSave() {
            const formData = this.CTSanPham
            const params = {
                SanPhamID: formData.SanPhamID,
                AnhSanPham_FileID: formData.AnhSanPham_FileID,
                TenSanPham: formData.TenSanPham,
                TenSanPham_HoaDon: formData.TenSanPham_HoaDon,
                TenNgan: formData.TenNgan,
                MoTa: formData.MoTa,
                LoaiSanPham: formData.LoaiSanPham,
                NhomSanPhamID: formData.NhomSanPhamID,
                NhomSanPham_HoaDonID: formData.NhomSanPham_HoaDonID,
                NhomSanPham_BaoCaoID: formData.NhomSanPham_BaoCaoID,
                NhomSanPham_BaoCaoID_1: formData.NhomSanPham_BaoCaoID_1,
                NhomSanPham_BaoCaoID_2: formData.NhomSanPham_BaoCaoID_2,
                NhomSanPham_BaoCaoID_3: formData.NhomSanPham_BaoCaoID_3,
                NhomSanPham_BaoCaoID_4: formData.NhomSanPham_BaoCaoID_4,
                NhomSanPham_BaoCaoID_5: formData.NhomSanPham_BaoCaoID_5,
                NhomLoaiLyID: formData.NhomLoaiLyID ?? 0,
                DiemLoaiLy: formData.DiemLoaiLy ?? 0,
                DonViTinhID: formData.DonViTinhID,
                ChiSoNo: formData.ChiSoNo,
                ThoiGianCheBien_1: formData.ThoiGianCheBien_1,
                ThoiGianCheBien_2: formData.ThoiGianCheBien_2,
                MaLy: formData.MaLy,
                MaPhaChe: formData.MaPhaChe,
                MaViMacDinh: formData.MaViMacDinh,
                MaNhietDoMacDinh: formData.MaNhietDoMacDinh,
            }
            ajaxCALL("/eorder/SanPham_Update_DuLieuCoSo", params, (res) => {
                showToast({type: "green", title: "Lưu dữ liệu cơ sở thành công"})
            })
        },
    },
    mounted: function () {
        const $this = this
        $this.getUnit()
        $this.getProductGroup()
        $this.getProductGroupInvoice()
        $this.getProductGroupReport()
        $this.getCupType()
    },
}
</script>
