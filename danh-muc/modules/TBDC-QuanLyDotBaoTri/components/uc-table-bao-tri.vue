<template>
	<div class="pa-2 border-b border-t">
		<v-row dense>
			<v-col cols="3">
				<v-text-field v-model="search" density="compact" variant="outlined" label="Tìm kiếm" flat
					clearable></v-text-field>
			</v-col>
		</v-row>
	</div>

	<v-data-table v-if="!isMobile" :headers="headers" :items="DSDotBaoTri" :search="search" density="compact"
		fixed-header style="height:calc(100vh - 105px)" items-per-page-text="Bản ghi" :items-per-page="20"
		:items-per-page-options="[15, 20, 50, 100]">

		<template #item.NgayDuKien="{ item }">
			{{ formatDate(item.NgayDuKien) }}
		</template>

		<template #item.LoaiHinhThucHien="{ item }">
			{{ mapLoaiHinhThucHien[item.LoaiHinhThucHien] }}
		</template>

		<template v-slot:item.TinhTrang="{ item }">
			<v-chip :color="mapTinhTrangPhieu[item.TinhTrang].color" size="small">
				{{ mapTinhTrangPhieu[item.TinhTrang].text }}
			</v-chip>
		</template>

		<template v-slot:item.actions="{ item }">
			<v-menu>
				<template v-slot:activator="{ props }">
					<v-btn size="small" variant="text" v-bind="props" icon="mdi-dots-vertical"></v-btn>
				</template>
				<v-list density="compact">
					<v-list-item @click="onViewDetail(item)" prepend-icon="mdi-eye" title="Xem chi tiết" />
					<v-divider />
					<v-list-item @click="onDelete(item)" prepend-icon="mdi-trash-can" title="Xóa"></v-list-item>
				</v-list>
			</v-menu>
		</template>

		<template v-slot:no-data>
			<uc-empty text="Chưa có đợt bảo trì"></uc-empty>
		</template>
	</v-data-table>
	<div v-else class="bg-grey-lighten-5 min-h-100 pb-4 mt-2" style="height: calc(100vh - 110px);">
		<v-card v-for="(event, index) in DSDotBaoTri" :key="index" class="mb-3 rounded-lg elevation-2"
			:style="{ borderLeft: '5px solid ' + event.color }" @click="onViewDetail(event)">
			<div class="pa-3">
				<div class="d-flex justify-space-between align-start mb-2">
					<div class="font-weight-bold text-subtitle-1 text-primary line-clamp-2" style="line-height:1.3">
						{{ event.TenDotBaoTri }}
					</div>

					<div class="d-flex align-center text-body-2 text-medium-emphasis ga-1 line-clamp-1">
						<v-icon size="14">mdi-map-marker</v-icon>
						{{ event.TenDiaDiem }}
					</div>
					<v-chip size="x-small" :color="mapTinhTrangPhieu[event.TinhTrang].color" label variant="flat"
						class="ml-2 flex-shrink-0">
						{{ mapTinhTrangPhieu[event.TinhTrang].text }}
					</v-chip>
				</div>
				<div class="d-flex align-center text-caption text-grey-darken-2 mb-2">
					<v-icon size="x-small" start color="grey">
						mdi-calendar-range
					</v-icon>
					<span class="mr-3 font-weight-medium">
						{{ formatDate(event.NgayDuKien) }}
					</span>
					<v-icon size="x-small" start color="grey">
						mdi-account-wrench
					</v-icon>
					<span>
						{{ mapLoaiHinhThucHien[event.LoaiHinhThucHien] }}
					</span>

				</div>
				<div class="d-flex justify-space-between align-center pt-2 mt-1">
					<span class="text-caption text-grey">
						Số lượng thiết bị: {{ event.SoLuongTaiSan }}
					</span>
					<v-spacer></v-spacer>
					<v-menu>
						<template v-slot:activator="{ props }">
							<v-btn size="small" variant="text" v-bind="props" icon="mdi-dots-vertical"></v-btn>
						</template>
						<v-list density="compact">
							<v-list-item @click="onViewDetail(event)" prepend-icon="mdi-eye" title="Xem chi tiết" />
							<v-divider />
							<v-list-item @click="onDelete(event)" prepend-icon="mdi-trash-can"
								title="Xóa"></v-list-item>
						</v-list>
					</v-menu>
				</div>
			</div>
		</v-card>
	</div>
</template>

<script>
export default {
	props: {
		DSDotBaoTri: Array,
		loadDSDotBaoTri: Function,
	},
	emits: ['on-view-detail'],

	data() {
		return {
			mapTinhTrangPhieu,
			headers: [
				{ title: "Tên đợt bảo trì", key: "TenDotBaoTri" },
				{ title: "Địa điểm", key: "TenDiaDiem" },
				{ title: "Ngày dự kiến", key: "NgayDuKien" },
				{ title: "Số lượng tài sản", key: "SoLuongTaiSan", align: 'center' },
				{ title: "Tình trạng", key: "TinhTrang" },
				{ title: "Người thực hiện", key: "LoaiHinhThucHien", align: 'start' },
				{ title: "Ghi chú", key: "GhiChu" },
				{ title: "", key: "actions" },
			],
			search: null,
			mapLoaiHinhThucHien: {
				'NOI_BO': 'Nội bộ',
				'THUE_NGOAI': 'Thuê ngoài',
				null: 'Chưa phân công'
			}
		}
	},

	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
	},

	methods: {
		formatDate: window.formatDate,
		onViewDetail(event) {
			this.$emit('on-view-detail', event)
		},
		onEdit(item) {
			if (item.TinhTrang !== 'HOAN_THANH') return showToast.info('Không thể cập nhật')
		},
		onDelete(item) {
			if (item.TinhTrang !== 'TAO_MOI') return showToast.info('Không thể xoá')
			const params = {
				DotBaoTri_Id: item.DotBaoTri_Id
			}
			const $this = this
			apiCall('/work/TS_DotBaoTri_Delete', params, () => {
				showToast.success('Xóa đợt bảo trì thành công!')
				$this.loadDSDotBaoTri()
			})
		},

	}

}
</script>