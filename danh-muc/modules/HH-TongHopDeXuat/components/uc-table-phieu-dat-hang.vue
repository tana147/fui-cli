<template>
	<v-data-table :items="items" :headers="headers" height="calc(100vh - 152px)" density="compact" :disable-sort="true"
		fixed-header items-per-page-text="Bản ghi" :items-per-page="20" :items-per-page-options="[15, 20, 50, 100]"
		:loading="loading">

		<template #item.NgayDatHang="{ item }">
			{{ formatDate(item.NgayDatHang) }}
		</template>

		<template #item.TinhTrang="{ item }">
			<v-chip :color="mapTinhTrangPhieu[item.TinhTrang]?.color" size="small">
				{{ mapTinhTrangPhieu[item.TinhTrang]?.text }}
			</v-chip>
		</template>

		<template #item.actions="{ item }">
			<v-btn size="small" variant="text" icon="mdi-eye" @click="onViewDetail(item)" />
		</template>

		<template #no-data>
			<uc-empty text="Chưa có phiếu đặt hàng" />
		</template>
	</v-data-table>
</template>

<script>
	export default {
	props: {
		items: { type: Array, default: function () { return [] } },
		loading: { type: Boolean, default: false },
	},
	emits: ['on-view-detail'],
	data() {
		return {
			mapTinhTrangPhieu,
			headers: [
				{ title: 'Tên địa điểm', key: 'TenDiaDiem', align: 'start' },
				{ title: 'Tên nhà cung cấp', key: 'TenNhaCungCap', align: 'start' },
				{ title: 'Người đặt', key: 'TenNhanVien', align: 'start' },
				{ title: 'Ngày đặt hàng', key: 'NgayDatHang', align: 'start' },
				{ title: 'Tình trạng', key: 'TinhTrang', align: 'start' },
				{ title: '', key: 'actions', align: 'center', width: 60 },
			],
		}
	},
	methods: {
		formatDate: window.formatDate,
		onViewDetail(item) {
			this.$emit('on-view-detail', item)
		},
	},
}
</script>