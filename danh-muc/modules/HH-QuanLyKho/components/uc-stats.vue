<template>
	<v-row class="mt-2 g-0" density="compact" align="stretch">
		<v-col cols="12" md="4" class="d-flex pa-0">
			<v-card elevation="0" class="flex-grow-1 d-flex flex-column justify-space-between border-0 filter-panel">
				<v-card-text class="pt-2 d-flex flex-column justify-space-between">
					<div class="v-toolbar-title mb-2 ml-2">
						Quản lý kho
					</div>
					<v-row dense class="mt-1 mb-0" align="center">
						<v-col cols="5" class="pb-0">
							<v-autocomplete v-model="DiaDiem_Id" :items="DSDiaDiemTatCa" item-value="DiaDiem_Id"
								item-title="TenDiaDiem" label="Địa điểm" density="compact" variant="outlined"
								hide-details :disabled="loading" />
						</v-col>
						<template v-if="isShowFilterDiaDiem">
							<v-col cols="5" class="pb-0">
								<v-select v-model="LoaiHangHoa" :items="DSLoaiHangHoa" item-value="value"
									item-title="title" label="Loại hàng hoá" density="compact" variant="outlined"
									hide-details :disabled="loading" />
							</v-col>
						</template>
						<template v-else>
							<v-col cols="5" class="pb-0">
								<v-autocomplete v-model="LoaiYeuCau" :items="DSLoaiYeuCau" item-value="value"
									item-title="title" label="Loại yêu cầu" density="compact" variant="outlined"
									hide-details :disabled="loading" />
							</v-col>
						</template>
						<v-col cols="2" class="pb-0 d-flex justify-center">
							<v-btn color="primary" variant="text" prepend-icon="mdi-reload" density="compact"
								size="small" @click="emitLoadData()">
								{{ isMobile ? '' : 'Làm mới' }}
							</v-btn>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</v-col>

		<v-col cols="12" md="8" class="d-flex pa-0">
			<v-card elevation="0" class="flex-grow-1 d-flex flex-column border-0 stats-panel">
				<v-card-text class="pt-2">
					<v-item-group v-model="TinhTrangHangHoa" mandatory :disabled="loading"
						selected-class="bg-primary text-white elevation-4">
						<v-row v-if="!isMobile" density="compact">
							<v-col cols="12" sm="6" md="4">
								<v-item value="TRONG_KHO" v-slot="{ isSelected, selectedClass, toggle }">
									<uc-stat-card @click="toggle" :bgclass="selectedClass" class="stat-card-hover"
										:colortitle="isSelected ? 'white' : 'grey-darken-1'"
										:value="stats.HangHoaTrongKho" title="Trong kho" icon="mdi-warehouse"
										coloricon="green-darken-2" bgicon="green-lighten-5" />
								</v-item>
							</v-col>

							<v-col cols="12" sm="6" md="4">
								<v-item value="YEU_CAU_CHO_XAC_NHAN" v-slot="{ isSelected, selectedClass, toggle }">
									<uc-stat-card @click="toggle" :bgclass="selectedClass" class="stat-card-hover"
										:colortitle="isSelected ? 'white' : 'grey-darken-1'" title="Chờ xác nhận"
										:value="stats.YeuCauChoXacNhan" icon="mdi-timer-sand" coloricon="amber-darken-2"
										bgicon="amber-lighten-5" />
								</v-item>
							</v-col>

							<v-col cols="12" sm="6" md="4">
								<v-item value="HANG_SAP_HET" v-slot="{ isSelected, selectedClass, toggle }">
									<uc-stat-card @click="toggle" :bgclass="selectedClass" class="stat-card-hover"
										:colortitle="isSelected ? 'white' : 'grey-darken-1'" title="Hàng sắp hết"
										:value="stats.HangSapHet" icon="mdi-alert" coloricon="amber-darken-3"
										bgicon="amber-lighten-5" />
								</v-item>
							</v-col>
						</v-row>
						<div v-else class="stat-mobile-scroll">
							<v-item value="TRONG_KHO" v-slot="{ isSelected, selectedClass, toggle }">
								<div class="stat-mobile-item">
									<uc-stat-card @click="loading ? null : toggle()" :bgclass="selectedClass"
										:class="{ 'opacity-50': loading }"
										:colortitle="isSelected ? 'white' : 'grey-darken-1'"
										:value="stats.HangHoaTrongKho" title="Trong kho" icon="mdi-warehouse"
										coloricon="green-darken-2" bgicon="green-lighten-5" />
								</div>
							</v-item>

							<v-item value="YEU_CAU_CHO_XAC_NHAN" v-slot="{ isSelected, selectedClass, toggle }">
								<div class="stat-mobile-item">
									<uc-stat-card @click="loading ? null : toggle()" :bgclass="selectedClass"
										:class="{ 'opacity-50': loading }"
										:colortitle="isSelected ? 'white' : 'grey-darken-1'" title="Chờ xác nhận"
										:value="stats.YeuCauChoXacNhan" icon="mdi-timer-sand" coloricon="amber-darken-2"
										bgicon="amber-lighten-5" />
								</div>
							</v-item>

							<v-item value="HANG_SAP_HET" v-slot="{ isSelected, selectedClass, toggle }">
								<div class="stat-mobile-item">
									<uc-stat-card @click="loading ? null : toggle()" :bgclass="selectedClass"
										:class="{ 'opacity-50': loading }"
										:colortitle="isSelected ? 'white' : 'grey-darken-1'" title="Hàng sắp hết"
										:value="stats.HangSapHet" icon="mdi-alert" coloricon="amber-darken-3"
										bgicon="amber-lighten-5" />
								</div>
							</v-item>
						</div>
					</v-item-group>

				</v-card-text>
			</v-card>
		</v-col>
		<v-col cols="12" class="pa-0">
			<v-divider class="my-2" />
		</v-col>
	</v-row>
</template>

<script>
	export default {

	props: {
		stats: Object,
		DSDiaDiem: Array,
		loading: { type: Boolean, default: false },
	},

	emits: ['load-data'],

	data() {
		return {
			DSLoai: [],
			DiaDiem_Id: 0,
			TinhTrangHangHoa: 'TRONG_KHO',
			LoaiYeuCau: 'TAT_CA',
			LoaiHangHoa: 'TAT_CA',
			DSLoaiYeuCau: [
				{
					title: 'Tất cả', value: 'TAT_CA'
				},
				{
					title: 'Phiếu nhập', value: 'PHIEU_NHAP'
				},
				{
					title: 'Phiếu kiểm kê', value: 'PHIEU_KIEM_KE'
				}
			],
			DSLoaiHangHoa: [
				{
					title: 'Tất cả', value: "TAT_CA"
				},
				{
					title: 'Nguyên vật liệu', value: 'NVL'
				},
				{
					title: 'Công cụ dụng cụ', value: 'CCDC'
				}
			]
		}
	},

	computed: {
		DSDiaDiemTatCa() {
			return [
				{ DiaDiem_Id: 0, TenDiaDiem: 'Tất cả' },
				...this.DSDiaDiem
			]
		},
		isShowFilterDiaDiem() {
			const isShow = ['TRONG_KHO', 'HANG_SAP_HET']
			return isShow.includes(this.TinhTrangHangHoa) ? true : false
		},
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
	},

	watch: {
		TinhTrangHangHoa: function (newVal, oldVal) {
			if (['DANG_SUA_CHUA', 'TAI_SAN_HET_HAN', 'YEU_CAU_THANH_LY'].includes(this.TinhTrangHangHoa)) {
				showToast.info('Tính năng đang phát triển')
				this.TinhTrangHangHoa = oldVal
				return
			}
			else this.emitLoadData()
		},
		DiaDiem_Id: function () {
			this.emitLoadData()
		},
		LoaiYeuCau: function () {
			this.emitLoadData()
		},
		LoaiHangHoa: function () {
			this.emitLoadData()
		}
	},

	methods: {
		emitLoadData() {
			this.$emit('load-data', {
				TinhTrangHangHoa: this.TinhTrangHangHoa,
				DiaDiem_Id: this.DiaDiem_Id,
				LoaiYeuCau: this.LoaiYeuCau,
				LoaiHangHoa: this.LoaiHangHoa,
			})
		},
	}

}
</script>