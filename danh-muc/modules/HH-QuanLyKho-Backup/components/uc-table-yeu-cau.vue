<template>
	<v-card>
		<v-card-title class="d-flex align-center ga-2">
			<template v-if="!isMobile">
				<div class="text-primary text-left table-title">
					Danh sách yêu cầu chờ xác nhận
				</div>

				<v-spacer></v-spacer>
			</template>
			<v-text-field v-model="search" density="compact" variant="underlined" label="Tìm kiếm"
				prepend-inner-icon="mdi-magnify" flat hide-details single-line class="search-field"></v-text-field>
		</v-card-title>
		<v-card-text class="pa-0">
			<v-progress-linear v-if="loading" indeterminate color="primary" />
			<v-data-table :items="DSYeuCau" :headers="headerYeuCau" height="calc(100vh - 177px)" density="compact"
				:search="search" :disable-sort="true" fixed-header hide-default-footer :items-per-page="-1">
				<template v-slot:item.LoaiPhieu="{ item }">
					<span>{{ mapLoaiPhieu[item.LoaiPhieu].text }}</span>
				</template>

				<template v-slot:item.TinhTrang="{ item }">
					<v-chip :color="mapTinhTrangPhieu[item.TinhTrang].color" size="small">
						{{ mapTinhTrangPhieu[item.TinhTrang].text }}
					</v-chip>
				</template>

				<template v-slot:item.actions="{ item }">
					<v-btn color="primary" variant="tonal" density="compact" prepend-icon="mdi-eye-outline"
						@click="onViewDetailYeuCau(item)">
						Xem chi tiết
					</v-btn>
				</template>
				<template #no-data>
					<uc-empty text="Chưa có yêu cầu chờ duyệt" />
				</template>
			</v-data-table>
		</v-card-text>
	</v-card>
</template>

<script>
export default {

	props: {
		DSYeuCau: Array,
		loading: { type: Boolean, default: false },
	},

	emits: ['emit-view-detail-phieu-nhap', 'emit-view-detail-phieu-kiem-ke'],

	data() {
		return {
			mapTinhTrangPhieu,
			headerYeuCau: [
				{ title: "Loại phiếu", key: "LoaiPhieu", align: 'start' },
				{ title: "Tên phiếu", key: "TenPhieu", align: 'start' },
				{ title: "Tên địa điểm", key: "TenDiaDiem", align: 'start' },
				{ title: "Tình trạng", key: "TinhTrang", align: 'center' },
				{ title: "", key: "actions", align: 'center' },
			],

			mapLoaiPhieu:
			{
				'PHIEU_NHAP': {
					text: 'Phiếu nhập',
					color: 'orange'
				},
				'PHIEU_KIEM_KE': {
					text: 'Phiếu kiểm kê',
					color: 'primary'
				},
			},

			search: null,
		}
	},

	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
	},

	methods: {
		parsePhieuNhap(item, data) {
			const arrayHangHoa = [...data[0], ...data[1]]
			return { ...item, arrayHangHoa: arrayHangHoa }
		},

		parsePhieuKiemKe(item, data) {
			let res = []
			data.forEach((HangHoa) => {
				if (HangHoa.Is_CaBiet) {
					const DSCaBiet = JSON.parse(HangHoa?.DanhSachCaBiet || '[]')
					DSCaBiet.forEach((CaBiet) => {
						CaBiet.DonViTinh = HangHoa.TenDonVi
						CaBiet.DonViKiemKe_Id = HangHoa.Chuan_DonViTinh_Id
						CaBiet.SoLuong = 1
						CaBiet.Tong = 1
						CaBiet.Duyet_DiaDiemThucTe_Id = CaBiet.DiaDiemThucTe_Id
						CaBiet.Duyet_KhuVucThucTe_Id = CaBiet.KhuVucThucTe_Id
						CaBiet.Duyet_TinhTrangThucTe = CaBiet.TinhTrangThucTe
					})
					HangHoa.DSCaBiet = DSCaBiet
				} else {
					let DSDonViTinh = JSON.parse(HangHoa?.DonViQuyDoi || '[]')
					const DSSoLuong = JSON.parse(HangHoa?.DanhSachSoLuong || '[]')
					DSSoLuong.forEach((ItemHangHoa) => {
						ItemHangHoa.DonViKiemKe_Id = ItemHangHoa.DonViKiemKe_Id ?? HangHoa.Chuan_DonViTinh_Id
						const flagBaseUnit = DSDonViTinh?.find((x) => x.DonViTinh_Id === ItemHangHoa.DonViKiemKe_Id)
						if (!flagBaseUnit) {
							DSDonViTinh.push({
								DonViTinh_Id: HangHoa.Chuan_DonViTinh_Id,
								HeSo: 1,
								TenDonViQuyDoi: HangHoa.TenDonVi
							})
						}
						ItemHangHoa.TongSauQuyDoi = ItemHangHoa.SoLuong
						ItemHangHoa.SoLuongDuyet = ItemHangHoa.SoLuongDuyet
					})
					HangHoa.DSSoLuong = DSSoLuong
				}
				res.push(HangHoa.HangHoa_Id)
			})
			return { ...item, arrayKiemKe: data, expanded: res }
		},

		async onViewDetailYeuCau(item) {
			const params = {
				Id: item.Id,
				LoaiYeuCau: item.LoaiPhieu
			}
			item.Info = JSON.parse(item.PhieuInfo || '[]')
			item.DSFile = JSON.parse(item.Info.DanhSachFile || '[]')
			const data = await apiCallPromise('work/HH_Kho_Select_YeuCau_By_Id', params)

			const isPhieuNhap = item.LoaiPhieu === 'PHIEU_NHAP'
			const tempItem = isPhieuNhap ? this.parsePhieuNhap(item, data) : this.parsePhieuKiemKe(item, data)
			const emit = isPhieuNhap ? 'phieu-nhap' : 'phieu-kiem-ke'
			this.$emit(`emit-view-detail-${emit}`, tempItem)
		}
	}

}
</script>