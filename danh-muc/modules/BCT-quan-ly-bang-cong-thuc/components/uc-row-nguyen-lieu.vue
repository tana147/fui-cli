<template>
	<div class="row-nguyen-lieu">
		<!-- Chế độ edit: hiển thị autocomplete -->
		<uc-search-nguyen-lieu v-if="isEditing" :key="'nvl-' + rowData.STT" v-model="rowData.HangHoa_Id"
			:initValue="initValue" isClearable density="compact" isUnderlined isHideDetail label=""
			placeholder="Tìm kiếm nguyên vật liệu" loaiNguyenLieu="NL,BTP" @update:modelValue="onSelectChange"
			style="min-width: 300px" />

		<!-- Chế độ xem: chỉ hiển thị text -->
		<div v-else @click="$emit('edit-row')" class="recipe-clickable-cell">
			{{ rowData.MaNoiBo + ' - ' + (rowData.TenHangHoa || '-') }}
		</div>
	</div>
</template>

<script>
export default {
	props: {
		rowData: {
			type: Object,
			required: true
		},
		isEditing: {
			type: Boolean,
			default: false
		}
	},

	emits: ['update-row', 'edit-row'],

	data() {
		return {
		}
	},

	computed: {
		initValue() {
			if (!this.rowData.HangHoa_Id) return null

			return {
				title: `${this.rowData.MaNoiBo || ''} - ${this.rowData.TenHangHoa || ''}`.trim(),
				value: this.rowData.HangHoa_Id
			}
		}
	},

	watch: {
		isEditing(val) {
			if (val) this.loadNguyenLieuOptions()
		},
	},

	mounted() {
		if (this.isEditing && this.rowData.HangHoa_Id) {
			this.loadNguyenLieuOptions()
		}
	},

	methods: {
		// HÀM XỬ LÝ ĐƠN VỊ
		xuLyDonViVaGia({ quyDoiInfo, nguyenLieuInfo, donViHienTai }) {
			const danhSachQuyDoiHopLe = (quyDoiInfo || []).filter(x => !x.Is_TamKhoa)

			const donGiaApDung = Number(nguyenLieuInfo?.DonGia_ApDung ?? 0)
			const donViGocId = Number(nguyenLieuInfo?.Chuan_DonViTinh_Id ?? 0)

			const coQuyDoi = danhSachQuyDoiHopLe.length > 0

			const donViDangChon =
				coQuyDoi
					? (
						danhSachQuyDoiHopLe.some(x => Number(x.QuyDoi_DonViTinh_Id) === Number(donViHienTai))
							? Number(donViHienTai)
							: Number(danhSachQuyDoiHopLe[0].QuyDoi_DonViTinh_Id)
					)
					: donViGocId

			const donViQuyDoiOptions = coQuyDoi
				? danhSachQuyDoiHopLe.map(x => ({
					QuyDoi_DonViTinh_Id: Number(x.QuyDoi_DonViTinh_Id),
					QuyDoi_DonViTinh_Ten: x.QuyDoi_DonViTinh_Ten
				}))
				: []

			const donViGocOptions = [{
				DonViTinh_Id: donViGocId,
				TenDonVi: nguyenLieuInfo?.TenDonVi || ''
			}]

			let tenDonVi = ''
			let giaNguyenVatLieu = donGiaApDung
			let tenThayThe = ''

			if (coQuyDoi) {
				const qd = danhSachQuyDoiHopLe.find(x => Number(x.QuyDoi_DonViTinh_Id) === Number(donViDangChon))
				tenDonVi = qd?.QuyDoi_DonViTinh_Ten || ''
				tenThayThe = qd?.TenThayThe ?? ''
				const heSo = Number(qd?.QuyDoi_HeSo || 0)
				giaNguyenVatLieu = heSo > 0 ? donGiaApDung / heSo : 0
			} else {
				tenDonVi = nguyenLieuInfo?.TenDonVi || ''
				tenThayThe = ''
				giaNguyenVatLieu = donGiaApDung // đơn vị gốc -> lấy giá gốc, KHÔNG chia
			}

			return {
				DonViCheck: coQuyDoi,
				DonVi: donViDangChon,
				TenDonVi: tenDonVi,

				DonViQuyDoiOptions: donViQuyDoiOptions,
				DonViGocOptions: donViGocOptions,

				TenThayTheUpdate: tenThayThe,
				TenThayThe: tenThayThe,

				GiaNguyenVatLieu: giaNguyenVatLieu
			}
		},


		// LOAD OPTIONS KHI MỞ EDIT
		async loadNguyenLieuOptions() {

			if (!this.rowData?.HangHoa_Id) return

			try {
				const res = await new Promise((resolve, reject) => {
					apiCall(
						"/work/MT_NguyenLieu_Select_By_Id",
						{ HangHoa_Id: this.rowData.HangHoa_Id },
						resolve,
						reject
					)
				})

				const nguyenLieuInfo = res.data?.[0]?.[0]
				const quyDoiInfo = res.data?.[1] || []
				if (!nguyenLieuInfo) return

				const duLieuDonViGia = this.xuLyDonViVaGia({
					quyDoiInfo,
					nguyenLieuInfo,
					donViHienTai: this.rowData.DonVi
				})

				const optionsData = {
					MaNoiBo: nguyenLieuInfo.MaNoiBo ?? this.rowData.MaNoiBo ?? '',
					TenHangHoa: nguyenLieuInfo.TenHangHoa ?? this.rowData.TenHangHoa ?? '',

					DonGia_ApDung: Number(nguyenLieuInfo.DonGia_ApDung ?? this.rowData.DonGia_ApDung ?? 0),
					QuyDoiInfo: quyDoiInfo,

					...duLieuDonViGia
				}

				this.$emit('update-row', optionsData)

			} catch (error) {
				console.error('Lỗi load nguyên liệu:', error)
			}
		},


		// KHI CHỌN NGUYÊN LIỆU MỚI
		async onSelectChange(HangHoa_Id) {

			// console.log('Check')

			if (!HangHoa_Id) return
			if (HangHoa_Id === this.rowData.HangHoa_Id) return

			try {
				const res = await new Promise((resolve, reject) => {
					apiCall(
						"/work/MT_NguyenLieu_Select_By_Id",
						{ HangHoa_Id },
						resolve,
						reject
					)
				})

				const nguyenLieuInfo = res.data?.[0]?.[0]
				const quyDoiInfo = res.data?.[1] || []
				if (!nguyenLieuInfo) return

				const duLieuDonViGia = this.xuLyDonViVaGia({
					quyDoiInfo,
					nguyenLieuInfo,
					donViHienTai: this.rowData.DonVi
				})

				const updatedData = {
					HangHoa_Id,
					MaNoiBo: nguyenLieuInfo.MaNoiBo ?? '',
					TenHangHoa: nguyenLieuInfo.TenHangHoa ?? '',

					DonGia_ApDung: Number(nguyenLieuInfo.DonGia_ApDung ?? 0),
					QuyDoiInfo: quyDoiInfo,

					...duLieuDonViGia
				}

				this.$emit('update-row', updatedData)

			} catch (error) {
				console.error('Không thể tải nguyên liệu:', error)
			}
		}

	}
}
</script>
