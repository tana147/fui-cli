<template>
	<v-dialog v-model="isShow" width="800">
		<v-card>
			<v-toolbar density="compact" elevation="0">
				<v-toolbar-title>
					Thêm mới
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-card-text class="pt-0">
				<v-form ref="form">
					<v-row class="pa-4">
						<v-col cols="12" class="pb-0">
							<div class="font-weight-bold">Phân loại theo nhóm</div>
						</v-col>

						<v-col cols="4">
							<v-autocomplete v-model="item.PhanLoai_TinhChat_Id" label="* Nhóm tính chất"
								:items="DSNhomTinhChat" item-title="TenTinhChat" item-value="PhanLoai_TinhChat_Id"
								density="compact" hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-autocomplete v-model="item.PhanLoai_NhomVatTu_Id" label="* Nhóm vật tư"
								:items="DSNhomVTHHFilter" :disabled="!item.PhanLoai_TinhChat_Id"
								item-title="TenNhomVatTu" item-value="PhanLoai_NhomVatTu_Id" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-autocomplete v-model="item.PhanLoai_NhomSanPham_Id" label="* Nhóm tên sản phẩm"
								:items="DSNhomTenSanPham" item-title="TenNhomSanPham"
								item-value="PhanLoai_NhomSanPham_Id" density="compact" hide-details="auto" />
						</v-col>

						<v-col cols="12" class="pb-0">
							<div class="font-weight-bold">Thông tin CCDC</div>
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.MaNoiBo" label="* Mã nội bộ" density="compact"
								:rules="[v => !!v || 'Vui lòng nhập mã nội bộ']" hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.TenHangHoa" label="* Tên CCDC" density="compact"
								:rules="[v => !!v || 'Vui lòng nhập tên CCDC']" hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-autocomplete v-model="item.Chuan_DonViTinh_Id" label="* Đơn vị nhập" :items="DSDonViTinh"
								item-title="TenDonVi" item-value="DonViTinh_Id" density="compact"
								:rules="[v => !!v || 'Vui lòng chọn đơn vị tính']" hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.ThuongHieu" label="Thương hiệu" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.NguonGoc" label="Nguồn gốc" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.QuyCach" label="Quy cách" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="12" class="pb-0">
							<div class="font-weight-bold">Thông tin bổ sung</div>
						</v-col>



						<v-col cols="4">
							<v-text-field v-model="item.HinhDang" label="Hình dạng" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.ChatLieu" label="Chất liệu" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.DoUuTien" label="Độ ưu tiên" type="number" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="12" class="pb-0">
							<div class="font-weight-bold">Thông tin thuế</div>
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.ThueGTGT" label="Thuế GTGT (%)" type="number" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.ThueKhac" label="Thuế khác (%)" type="number" density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="4">
							<v-text-field v-model="item.ThueNhapKhau" label="Thuế nhập khẩu (%)" type="number"
								density="compact" hide-details="auto" />
						</v-col>

						<v-col cols="12">
							<v-textarea v-model="item.MoTa" label="Mô tả" rows="3" auto-grow density="compact"
								hide-details="auto" />
						</v-col>

						<v-col cols="3">
							<v-checkbox v-model="item.Is_TamKhoa" label="Tạm khoá" color="primary" density="compact"
								hide-details="auto" />
						</v-col>
						<v-col cols="3">
							<v-checkbox v-model="item.Is_CaBiet" label="Tài sản" color="primary" density="compact"
								hide-details="auto" />
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn @click="onSaveAndClose" prepend-icon="mdi-content-save-outline" variant="tonal">Lưu &
					Đóng</v-btn>
				<v-btn color="primary" @click="onSaveAndContinue" prepend-icon="mdi-content-save-move"
					variant="flat">Lưu & Tiếp tục</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		DSNhomTinhChat: Array,
		DSNhomVTHH: Array,
		DSNhomTenSanPham: Array,
		DSDonViTinh: Array,
	},
	data() {
		return {
			item: {
				Is_CaBiet: false
			},
			NhomVTHH: null,
			NhomTinhChat: null,
			rules: {
				required: (value) => !!value || 'Trường này không được để trống',
				greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				noSpecialChar: v =>
					/^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
			},
		}
	},
	mounted() {
	},
	computed: {
		DSNhomVTHHFilter() {
			return this.item.NhomTinhChat === null ? this.DSNhomVTHH : this.DSNhomVTHH.filter((x) => x.PhanLoai_TinhChat_Id == this.item.PhanLoai_TinhChat_Id)
		},
	},
	watch: {
		'item.PhanLoai_TinhChat_Id': function () {
			this.item.PhanLoai_NhomVatTu_Id = null
		},
	},
	methods: {
		closeDialog() {
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.$emit('update:isShow', false)
		},

		async onSubmit(TinhTrang) {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.info('Vui lòng nhập đầy đủ thông tin cần thiết')
				return
			}
			const params = {
				PhanLoai_TinhChat_Id: this.item.PhanLoai_TinhChat_Id ?? 0,
				PhanLoai_NhomVatTu_Id: this.item.PhanLoai_NhomVatTu_Id ?? 0,
				PhanLoai_NhomSanPham_Id: this.item.PhanLoai_NhomSanPham_Id ?? 0,
				Chuan_DonViTinh_Id: this.item.Chuan_DonViTinh_Id,
				MaNoiBo: this.item.MaNoiBo ?? '',
				TenHangHoa: this.item.TenHangHoa,
				Is_TamKhoa: this.item.Is_TamKhoa ?? 0,
				Is_CaBiet: this.item.Is_CaBiet ?? 0,
				ThuongHieu: this.item.ThuongHieu ?? '',
				NguonGoc: this.item.NguonGoc ?? '',
				ChatLieu: this.item.ChatLieu ?? '',
				QuyCach: this.item.QuyCach ?? '',
				HinhDang: this.item.HinhDang ?? '',
				DoUuTien: this.item.DoUuTien ?? '',
				ThueGTGT: this.item.ThueGTGT ?? '',
				ThueKhac: this.item.ThueKhac ?? '',
				ThueNhapKhau: this.item.ThueNhapKhau ?? '',
				MoTa: this.item.MoTa ?? '',
			}
			const $this = this
			apiCall("work/TS_CCDC_Insert", params, (res) => {
				if (res) showToast.success("Thành công");
				$this.$emit('handle-add', { ...$this.item, HangHoa_Id: res.data[0].HangHoa_Id }, TinhTrang)
				$this.closeDialog()
			})
		},

		onSaveAndClose() {
			this.isAddAndClose = true
			this.onSubmit('DONG')
		},

		onSaveAndContinue() {
			this.isAddAndClose = false
			this.onSubmit('TIEP_TUC')
		},

	},
}
</script>