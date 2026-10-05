<template>
	<div class="page-section">
		<v-card elevation="0">
			<v-toolbar dense flat>
				<v-toolbar-title>Dữ liệu cơ sở</v-toolbar-title>
			</v-toolbar>
			<v-card-text>
				<v-row>
					<v-col md="2">
						<f-image-update v-model="CTSanPham.AnhSanPham_Url" v-on:update="onUpload"
							:api-upload="vueData.v_Set.apiFile" label="Ảnh sản phẩm" dialog-width="600"
							dialog-height="400" :size="{width: 800, height: 800}" quality="0.5"
							:croper-attr="{'stencil-props': {aspectRatio: 1}, 'default-size': {width: 9999, height: 9999}, transitions: true, 'image-restriction': 'fit-area'}" />
					</v-col>
					<v-col md="10">
						<v-row>
							<v-col md="2">
								<v-text-field v-model="CTSanPham.MaSanPham" dense label="Mã sản phẩm" outlined
									hide-details></v-text-field>
							</v-col>
							<v-col md="5">
								<v-text-field v-model="CTSanPham.TenSanPham" dense label="Tên sản phẩm" outlined
									hide-details></v-text-field>
							</v-col>
							<v-col md="5">
								<v-text-field v-model="CTSanPham.TenNgan" dense label="Tên ngắn" outlined hide-details>
								</v-text-field>
							</v-col>
							<v-col md="12">
								<v-textarea v-model="CTSanPham.MoTa" dense label="Mô tả" outlined hide-details rows="2">
								</v-textarea>
							</v-col>
							<v-col md="4">
								<v-select v-model="CTSanPham.LoaiSanPham" dense label="Loại sản phẩm"
									:items="DSLoaiSanPham" hide-details outlined></v-select>
							</v-col>
							<v-col md="4">
								<v-select dense v-model="CTSanPham.NhomSanPhamID" label="Nhóm sản phẩm" outlined
									hide-details :items="DSNhomSanPham" item-value="NhomSanPhamID"
									item-text="TenNhomSanPham" />
							</v-col>
							<v-col md="4">
								<v-select dense v-model="CTSanPham.NhomSanPham_HoaDonID" label="Nhóm sản phẩm hóa đơn"
									outlined hide-details :items="DSNhomSanPhamHoaDon" item-value="NhomSanPham_HoaDonID"
									item-text="TenNhomSanPhamHoaDon" />
							</v-col>
							<v-col md="2">
								<v-select dense v-model="CTSanPham.DonViTinhID" label="Đơn vị bán" outlined hide-details
									:items="DSDonViTinh" item-value="DonViTinhID" item-text="TenDVT" />
							</v-col>
							<v-col md="2">
								<v-text-field v-model="CTSanPham.ChiSoNo" type="number" dense label="Chỉ số no" outlined
									hide-details></v-text-field>
							</v-col>
							<v-col md="2">
								<v-text-field v-model="CTSanPham.ThoiGianCheBien_1" type="number" dense
									label="TGCB mức 1 (Phút)" outlined hide-details></v-text-field>
							</v-col>
							<v-col md="2">
								<v-text-field v-model="CTSanPham.ThoiGianCheBien_2" type="number" dense
									label="TGCB mức 2 (Phút)" outlined hide-details></v-text-field>
							</v-col>
							<v-col md="4">
								<v-text-field v-model="CTSanPham.MaPhaChe" dense label="Mã pha chế" outlined
									hide-details></v-text-field>
							</v-col>
							<v-col md="2">
								<v-text-field v-model="CTSanPham.MaLy" dense label="Cup size mặc định" outlined
									hide-details></v-text-field>
							</v-col>
							<v-col md="2">
								<v-text-field v-model="CTSanPham.MaViMacDinh" dense label="Mã vị mặc định" outlined
									hide-details></v-text-field>
							</v-col>
							<v-col md="2">
								<v-text-field v-model="CTSanPham.MaNhietDoMacDinh" dense label="Mã nhiệt độ mặc định"
									outlined hide-details></v-text-field>
							</v-col>
						</v-row>
					</v-col>
				</v-row>
			</v-card-text>
			<v-card-actions>
				<v-btn color="success" v-on:click="onSave()" elevation="0">
					<v-icon left>mdi-content-save</v-icon>Lưu dữ liệu cơ sở
				</v-btn>
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
            DSLoaiSanPham: [
                {text: "Sản phẩm", value: 0},
                {text: "Dịch vụ", value: 1},
                {text: "Nguyên liệu", value: 2},
            ],
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
            ajaxCALL("/eordertest/DonViTinh_Select", {}, (res) => {
                $this.DSDonViTinh = res.data
            })
        },
        getProductGroup() {
            const $this = this
            ajaxCALL("/eordertest/NhomSanPham_Select", {}, (res) => {
                $this.DSNhomSanPham = res.data
            })
        },
        getProductGroupInvoice() {
            const $this = this
            ajaxCALL("/eordertest/NhomSanPhamHoaDon_Select", {}, (res) => {
                $this.DSNhomSanPhamHoaDon = res.data
            })
        },
        onSave() {
            const formData = this.CTSanPham
            const params = {
                SanPhamID: formData.SanPhamID,
                AnhSanPham_FileID: formData.AnhSanPham_FileID,
                MaSanPham: formData.MaSanPham,
                TenSanPham: formData.TenSanPham,
                TenNgan: formData.TenNgan,
                MoTa: formData.MoTa,
                LoaiSanPham: formData.LoaiSanPham,
                NhomSanPhamID: formData.NhomSanPhamID,
                NhomSanPham_HoaDonID: formData.NhomSanPham_HoaDonID,
                DonViTinhID: formData.DonViTinhID,
                ChiSoNo: formData.ChiSoNo,
                ThoiGianCheBien_1: formData.ThoiGianCheBien_1,
                ThoiGianCheBien_2: formData.ThoiGianCheBien_2,
                MaLy: formData.MaLy,
                MaPhaChe: formData.MaPhaChe,
                MaViMacDinh: formData.MaViMacDinh,
                MaNhietDoMacDinh: formData.MaNhietDoMacDinh,
            }
            ajaxCALL("/eordertest/SanPham_Update_DuLieuCoSo", params, (res) => {
                showToast({type: "green", title: "Lưu dữ liệu cơ sở thành công"})
            })
        },
    },
    mounted: function () {
        const $this = this
        $this.getUnit()
        $this.getProductGroup()
        $this.getProductGroupInvoice()
    },
}
</script>