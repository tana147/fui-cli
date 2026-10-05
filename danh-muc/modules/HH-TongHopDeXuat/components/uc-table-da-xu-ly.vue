<template>
	<v-data-table :items="items" v-model:expanded="expanded" :headers="headers" show-expand height="calc(100vh - 152px)"
		density="compact" :disable-sort="true" fixed-header hide-default-footer item-value="DeXuat_MuaHang_Id"
		item-key="DeXuat_MuaHang_Id" :items-per-page="-1" :loading="loading">

		<template #item.TinhTrang="{ item }">
			<v-chip :color="item.Is_Duyet ? 'success' : 'grey'" size="small" variant="tonal">
				{{ item.Is_Duyet ? 'Đã duyệt' : 'Chưa duyệt' }}
			</v-chip>
		</template>

		<template #item.NgayDeXuat="{ item }">
			{{ formatNgayGio(item.NgayTao, item.GioTao) }}
		</template>

		<template #item.NgayDuyet="{ item }">
			{{ formatNgayGio(item.NgayDuyet, item.GioDuyet) }}
		</template>

		<template v-slot:item.data-table-expand="{ internalItem, isExpanded, toggleExpand }">
			<v-btn :icon="isExpanded(internalItem) ? 'mdi-chevron-up' : 'mdi-chevron-down'" size="small"
				@click="toggleExpand(internalItem)" variant="text" />
		</template>

		<template v-slot:expanded-row="{ columns, item }">
			<tr v-if="item.ChiTiet?.length > 0">
				<td :colspan="columns.length" class="pa-0">
					<v-sheet border class="ma-2">
						<v-table density="compact" class="text-body-2">
							<thead class="bg-grey-lighten-4">
								<tr>
									<th class="text-start font-weight-medium">Tên hàng hoá</th>
									<th class="text-start font-weight-medium">Ghi chú</th>
									<th class="text-end font-weight-medium" style="width:200px">Số lượng</th>
									<th class="text-start font-weight-medium" style="width:200px">Tên đơn vị</th>
									<th class="text-center font-weight-medium" style="width:200px">Hướng xử lý</th>
									<th class="font-weight-medium">Ngày xử lý</th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="ct in item.ChiTiet" :key="ct.DeXuat_MuaHang_ChiTiet_Id">
									<td class="text-start font-weight-medium">{{ ct.TenHangHoa }}</td>
									<td class="text-start text-grey-darken-1">{{ ct.GhiChu }}</td>
									<td class="text-end">{{ ct.SoLuong }}</td>
									<td class="text-start">{{ ct.TenDonVi }}</td>
									<td class="text-center">
										<v-chip size="small"
											:color="{ LUAN_CHUYEN: 'blue', MUA_HANG: 'green' }[ct.XuLy]">
											{{ { LUAN_CHUYEN: 'Luân chuyển', MUA_HANG: 'Mua hàng' }[ct.XuLy] }}
										</v-chip>
									</td>
									<td class="text-start">{{ formatNgayGio(ct.NgayXuLy, ct.GioXuLy) }}</td>
								</tr>
							</tbody>
						</v-table>
					</v-sheet>
				</td>
			</tr>
		</template>

		<template #no-data>
			<uc-empty text="Chưa có đề xuất đã xử lý" />
		</template>
	</v-data-table>
</template>

<script>
	export default {
	props: {
		items: { type: Array, default: function () { return [] } },
		loading: { type: Boolean, default: false },
	},
	data() {
		return {
			expanded: [],
			headers: [
				{ width: 1, key: 'data-table-expand', align: 'start' },
				{ title: 'Tên địa điểm', key: 'TenDiaDiem', align: 'start' },
				{ title: 'Tình trạng', key: 'TinhTrang', align: 'start' },
				{ title: 'Ngày đề xuất', key: 'NgayDeXuat', align: 'start' },
				{ title: 'Ngày duyệt', key: 'NgayDuyet', align: 'start' },
			],
		}
	},
	methods: {
		formatDateTime: window.formatDateTime,

		formatNgayGio(Ngay, Gio) {
			const date = Ngay?.split('T')[0] ?? ''
			const time = Gio?.slice(0, 8) ?? ''
			return this.formatDateTime(date + ' ' + time)
		},
	},
}
</script>