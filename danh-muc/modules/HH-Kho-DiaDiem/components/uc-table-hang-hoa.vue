<template>
	<v-card>
		<v-card-title class="d-flex align-center ga-2">
			<template v-if="!isMobile">
				<div class="text-primary text-left table-title">
					Danh sách hàng hoá
				</div>
				<v-spacer></v-spacer>
			</template>
			<v-text-field v-model="search" density="compact" variant="underlined" label="Tìm kiếm"
				prepend-inner-icon="mdi-magnify" flat hide-details single-line class="search-field"></v-text-field>
		</v-card-title>
		<v-card-text class="pa-0">
			<v-progress-linear v-if="loading" indeterminate color="primary" />
			<uc-kho-desktop v-if="!isMobile" :items="filteredItems" @on-edit-ca-biet="onClickUpdateCaBiet"
				@on-luan-chuyen="onClickLuanChuyen" />
			<uc-kho-mobile v-else :items="filteredItems" @on-edit-ca-biet="onClickUpdateCaBiet"
				@on-luan-chuyen="onClickLuanChuyen" />
		</v-card-text>
	</v-card>
</template>

<script>
export default {
	props: {
		DSHangHoa: Object,
		loading: Boolean,
	},
	emits: ['on-edit-ca-biet', 'on-xuat-hang-hoa', 'on-luan-chuyen'],
	data() {
		return {
			search: null,
		}
	},
	computed: {
		filteredItems() {
			if (!this.search?.trim()) return this.DSHangHoa.arrayHangHoa

			const keyword = this.search.trim().toLowerCase()

			return this.DSHangHoa.arrayHangHoa.filter(item =>
				item.TenHangHoa?.toLowerCase().includes(keyword) ||
				item.DSCaBiet?.some(cb =>
					cb.SoSeries?.toString().toLowerCase().includes(keyword)
				)
			)
		},
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
	},
	methods: {
		onClickUpdateCaBiet(item) {
			this.$emit('on-edit-ca-biet', item)
		},
		onClickXuatHangHoa(item, parent) {
			let tempItem = { ...item }
			const DSDonViTinh = JSON.parse(parent.DonViQuyDoi ?? '[]')
			const flagBaseUnit = DSDonViTinh?.find((x) => x.DonViTinh_Id === parent.Chuan_DonViTinh_Id)
			if (!flagBaseUnit) {
				DSDonViTinh.push({
					DonViTinh_Id: parent.Chuan_DonViTinh_Id,
					HeSo: 1,
					TenDonViQuyDoi: parent.TenDonVi
				})
			}
			tempItem.TongSauQuyDoi = item.SoLuong
			tempItem.DSDonViTinh = DSDonViTinh
			tempItem.Is_CaBiet = parent.Is_CaBiet
			tempItem.Chuan_DonViTinh_Id = parent.Chuan_DonViTinh_Id
			tempItem.DonViXuat_Id = parent.Chuan_DonViTinh_Id
			tempItem.TenDonVi = parent.TenDonVi
			tempItem.TenHangHoa = parent.TenHangHoa
			let arrayCaBiet = []
			let arraySoLuong = []
			if (tempItem.Is_CaBiet) arrayCaBiet.push(tempItem)
			else arraySoLuong.push(tempItem)
			const object = {
				TenDiaDiem: tempItem.TenDiaDiem,
				TenKhuVuc: tempItem.TenKhuVuc,
				TenHangHoa: tempItem.TenHangHoa,
				DiaDiem_Id: tempItem.DiaDiem_Id,
				arrayCaBiet: arrayCaBiet,
				arraySoLuong: arraySoLuong,
			}
			this.$emit('on-xuat-hang-hoa', object)
		},
		onClickLuanChuyen(item, parent) {
			let tempItem = { ...item }
			const DSDonViTinh = JSON.parse(parent.DonViQuyDoi ?? '[]')
			const flagBaseUnit = DSDonViTinh?.find((x) => x.DonViTinh_Id === parent.Chuan_DonViTinh_Id)
			if (!flagBaseUnit) {
				DSDonViTinh.push({
					DonViTinh_Id: parent.Chuan_DonViTinh_Id,
					HeSo: 1,
					TenDonViQuyDoi: parent.TenDonVi
				})
			}
			tempItem.TongSauQuyDoi = item.SoLuong
			tempItem.DSDonViTinh = DSDonViTinh
			tempItem.Is_CaBiet = parent.Is_CaBiet
			tempItem.Chuan_DonViTinh_Id = parent.Chuan_DonViTinh_Id
			tempItem.DonViChuyen_Id = parent.Chuan_DonViTinh_Id
			tempItem.TenDonVi = parent.TenDonVi
			tempItem.TenHangHoa = parent.TenHangHoa
			this.$emit('on-luan-chuyen', tempItem)
		}
	},
}
</script>