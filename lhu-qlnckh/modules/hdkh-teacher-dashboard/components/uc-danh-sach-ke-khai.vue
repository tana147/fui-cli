<template>
	<v-card>
		<v-data-table :headers="headers" :items="items" :items-per-page="10" item-key="SubmissionID"
			class="elevation-1">
			<template v-slot:item.TrangThaiDuyet="{ item }">
				<v-tooltip :text="item.GhiChuTuChoi || getStatusTooltip(item.TrangThaiDuyet)" location="top">
					<template v-slot:activator="{ props }">
						<v-chip v-bind="props" :color="getStatusColor(item.TrangThaiDuyet)" size="small" variant="flat"
							label>{{ getStatusText(item.TrangThaiDuyet) }}</v-chip>
					</template>
				</v-tooltip>
			</template>
			<template v-slot:item.SoGio_HeThongTinh="{ item }">
				<v-tooltip :text="item.DienGiaiCachTinh" location="top">
					<template v-slot:activator="{ props }">
						<span v-bind="props">{{item.SoGio_HeThongTinh}} </span>
					</template>
				</v-tooltip>
			</template>
			<template v-slot:item.CreateTime="{ item }">
				<span>{{ formatDate(item.CreateTime) }}</span>
			</template>
			<template v-slot:item.actions="{ item }">
				<div class="d-flex ga-1">
					<v-btn :disabled="canEditOrDelete(item.TrangThaiDuyet)" icon="mdi-eye" size="small" variant="text"
						color="grey" title="Xem chi tiết" @click="$emit('view', item)" />
					<v-btn :disabled="!canEditOrDelete(item.TrangThaiDuyet)" icon="mdi-pencil" size="small"
						variant="text" color="primary" title="Chỉnh sửa" @click="$emit('edit', item)" />
					<v-btn :disabled="!canEditOrDelete(item.TrangThaiDuyet)" icon="mdi-delete" size="small"
						variant="text" color="error" title="Xóa" @click="$emit('delete', item)" />
				</div>
			</template>
			<template v-slot:no-data>
				<div class="text-center pa-4 text-grey">
					<v-icon size="large" class="mb-2">mdi-text-box-search-outline</v-icon>
					<div>Bạn chưa kê khai hoạt động nào trong năm học này.</div>
				</div>
			</template>
		</v-data-table>
	</v-card>
</template>

<script>
	export default {
		name: 'uc-danh-sach-ke-khai',
		emits: ['view', 'edit', 'delete'],
		props: { items: { type: Array, default: () => [] } },
		data() {
			return {
				headers: [
					{ title: 'Loại hình', key: 'FormTitle' },
					{ title: 'Tên hoạt động', key: 'TenHoatDong_CuThe' },
					{ title: 'Ngày kê khai', key: 'CreateTime', sortable: true },
					{ title: 'Số giờ hệ thống tính', key: 'SoGio_HeThongTinh', align: 'end' },
					{ title: 'Số giờ đã duyệt', key: 'SoGio_DaDuyet', align: 'center' },
					{ title: 'Trạng thái', key: 'TrangThaiDuyet' },
					{ title: 'Hành động', key: 'actions', sortable: false, align: 'center', width: '120px' },
				],
			};
		},
		methods: {
			getStatusColor(status) {
				const map = { 'KHOA_DA_DUYET': 'success', 'CHO_DUYET': 'info', 'KHOA_TU_CHOI': 'error' };
				return map[status] || 'grey';
			},
			getStatusText(status) {
				const map = { 'KHOA_DA_DUYET': 'Đã duyệt', 'CHO_DUYET': 'Chờ duyệt', 'KHOA_TU_CHOI': 'Bị từ chối' };
				return map[status] || 'Không xác định';
			},
			getStatusTooltip(status) {
				const map = {
					'KHOA_DA_DUYET': 'Đã được phê duyệt.', 'CHO_DUYET': 'Đang chờ xem xét.', 'KHOA_TU_CHOI': 'Bị từ chối.'
				};
				return map[status] || 'Trạng thái không xác định.';
			},
			formatDate(dateString) {
				if (!dateString) return '';
				return new Date(dateString).toLocaleDateString('vi-VN');
			},
			canEditOrDelete(status) {
				return status === 'CHO_DUYET';
			}
		}
	}
</script>