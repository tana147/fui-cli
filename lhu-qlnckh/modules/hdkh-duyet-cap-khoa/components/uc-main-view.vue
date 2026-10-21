<template>
	<div>
		<v-expansion-panels v-if="lecturers && lecturers.length > 0">
			<v-expansion-panel v-for="gv in lecturers" :key="gv.NhanVienID"
				@group:selected="onPanelToggle($event, gv.NhanVienID)">
				<v-expansion-panel-title>
					<uc-lecturer-row :lecturer="gv" :dsForms="dsForms"
						@on-show-kekhai="(formID, lecturer) => $emit('on-show-kekhai', formID, lecturer)" />
				</v-expansion-panel-title>
				<v-expansion-panel-text>
					<v-data-table :items="activities[gv.NhanVienID] || []" :headers="activityHeaders"
						:loading="!activities[gv.NhanVienID]" density="compact">

						<template v-slot:item.TrangThaiDuyet="{ item }">
							<v-tooltip :text="item.GhiChuTuChoi || getStatusTooltip(item.TrangThaiDuyet)"
								location="top">
								<template v-slot:activator="{ props }">
									<v-chip v-bind="props" :color="getStatusColor(item.TrangThaiDuyet)" size="small"
										variant="flat" label>{{
										getStatusText(item.TrangThaiDuyet) }}</v-chip>
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

						<template v-slot:item.SoGio_DaDuyet="{ item }">
							<v-text-field v-model.number="item.SoGio_DaDuyet" density="compact"
								:readonly="item.TrangThaiDuyet != 'CHO_DUYET'"
								:variant="item.TrangThaiDuyet != 'CHO_DUYET' ? 'plain' : 'outlined'" class="my-field">
							</v-text-field>
						</template>

						<template #item.actions="{ item }">
							<div class="d-flex ga-2 justify-end">
								<div v-if="item.TrangThaiDuyet === 'CHO_DUYET'">
									<v-tooltip text="Duyệt" location="top">
										<template #activator="{ props }">
											<v-btn v-bind="props" size="small" color="success" icon="mdi-check"
												variant="text"
												@click="$emit('on-approve', item.SubmissionID, item.KetQuaID, gv.NhanVienID, item.SoGio_DaDuyet)" />
										</template>
									</v-tooltip>

									<v-tooltip text="Từ chối" location="top">
										<template #activator="{ props }">
											<v-btn v-bind="props" size="small" color="error" icon="mdi-close"
												variant="text" @click="$emit('on-reject', item, gv.NhanVienID)" />
										</template>
									</v-tooltip>
								</div>

								<v-tooltip text="Xem chi tiết" location="top">
									<template #activator="{ props }">
										<v-btn v-bind="props" size="small" color="default" icon="mdi-eye" variant="text"
											@click="$emit('on-view-detail', item, gv.NhanVienID)" />
									</template>
								</v-tooltip>
							</div>
						</template>

						<template v-slot:no-data>
							<div class="text-center pa-4 text-grey">
								<v-icon size="large" class="mb-2">mdi-text-box-search-outline</v-icon>
								<div>Giảng viên chưa kê khai hoạt động nào trong năm học này.</div>
							</div>
						</template>
					</v-data-table>
				</v-expansion-panel-text>
			</v-expansion-panel>
		</v-expansion-panels>

		<div v-else class="d-flex ga-4 justify-center align-center">
			<v-empty-state text-width="250">
				<template v-slot:media>
					<v-icon size="20">mdi-magnify</v-icon>
				</template>

				<template v-slot:title>
					<div class="text-caption text-high-emphasis">Không tìm thấy giảng viên nào</div>
				</template>
			</v-empty-state>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-main-view',
		props: {
			lecturers: { type: Array, default: () => [] },
			activities: { type: Object, default: () => ({}) },
			dsForms: { type: Array, default: () => [] }
		},
		emits: ['on-panel-open', 'on-approve', 'on-reject', 'on-view-detail', 'on-show-kekhai'],
		data() {
			return {
				activityHeaders: [
					{ title: 'Loại hình', key: 'FormTitle' },
					{ title: 'Tên hoạt động', key: 'TenHoatDong_CuThe' },
					{ title: 'Ngày kê khai', key: 'CreateTime', sortable: true },
					{ title: 'Số giờ hệ thống tính', key: 'SoGio_HeThongTinh', align: 'end' },
					{ title: 'Số giờ đã duyệt', key: 'SoGio_DaDuyet', align: 'center', },
					{ title: 'Trạng thái', key: 'TrangThaiDuyet', width: '150px' },
					{ title: 'Hành động', key: 'actions', sortable: false, align: 'end', width: '200px' },
				]
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
			onPanelToggle(event, nhanVienID) {
				if (event && event.value) {
					this.$emit('on-panel-open', nhanVienID);
				}
			},
			formatDate(dateString) {
				if (!dateString) return '';
				return new Date(dateString).toLocaleDateString('vi-VN');
			}
		}
	}
</script>