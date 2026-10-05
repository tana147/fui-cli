<template>
	<div class="pa-2 border-b border-t" :style="isMobile ? { paddingTop: '52px !important' } : {}">
		<v-row dense>
			<v-col cols="12" md="3">
				<v-autocomplete v-model="DiaDiem_Id" density="compact" :items="DSDiaDiem" item-value="DiaDiem_Id"
					item-title="TenDiaDiem" label="Địa điểm">
				</v-autocomplete>
			</v-col>
			<v-col cols="8" md="3">
				<v-text-field v-model="search" density="compact" variant="outlined" label="Tìm kiếm" flat
					clearable></v-text-field>
			</v-col>
			<v-col cols="auto">
				<v-btn prepend-icon="mdi-magnify" @click="onSearch">Tìm</v-btn>
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
			<v-btn size="small" color="primary" variant="text" prepend-icon="mdi-play-circle" @click="onExecute(item)">
				Thực hiện
			</v-btn>
		</template>

		<template v-slot:no-data>
			<uc-empty text="Chưa có đợt bảo trì"></uc-empty>
		</template>
	</v-data-table>
	<div v-else class="bg-grey-lighten-5 min-h-100 pb-4 mt-2" style="height: calc(100vh - 198px);">
		<v-card v-for="(event, index) in DSDotBaoTri" :key="index" class="mb-3 rounded-lg elevation-2"
			:style="{ borderLeft: '5px solid ' + event.color }" @click="onExecute(event)">
			<div class="pa-3">
				<div class="d-flex justify-space-between align-start mb-2">
					<div class="font-weight-bold text-subtitle-1 text-primary line-clamp-2" style="line-height:1.3">
						{{ event.TenDotBaoTri }}
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
					<v-btn size="small" color="primary" variant="text" prepend-icon="mdi-play-circle"
						@click="onExecute(event)">
						Thực hiện
					</v-btn>
				</div>
			</div>
		</v-card>
	</div>
</template>

<script>
export default {
	props: {
		DSDotBaoTri: Array,
		DSDiaDiem: Array,
		loadDSDotBaoTri: Function,
	},
	emits: ['on-execute', 'load-data'],

	data() {
		return {
			mapTinhTrangPhieu,
			headers: [
				{ title: "Tên đợt bảo trì", key: "TenDotBaoTri" },
				{ title: "Ngày dự kiến", key: "NgayDuKien" },
				{ title: "Số lượng tài sản", key: "SoLuongTaiSan", align: 'center' },
				{ title: "Tình trạng", key: "TinhTrang" },
				{ title: "Ghi chú", key: "GhiChu" },
				{ title: "", key: "actions" },
			],
			mapLoaiHinhThucHien: {
				'NOI_BO': 'Nội bộ',
				'THUE_NGOAI': 'Thuê ngoài',
				null: 'Chưa phân công'
			},
			search: null,
			DiaDiem_Id: null,
		}
	},

	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
	},

	methods: {
		formatDate: window.formatDate,

		onSearch() {
			const params = {
				DiaDiem_Id: this.DiaDiem_Id
			}
			this.$emit('load-data', params)
		},

		onExecute(item) {
			this.$emit('on-execute', item)
		},
	}

}
</script>