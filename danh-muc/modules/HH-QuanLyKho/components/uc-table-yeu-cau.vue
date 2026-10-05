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

	emits: ['on-view-detail'],

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
		onViewDetailYeuCau(item) {
			this.$emit('on-view-detail', item)
		}
	}

}
</script>