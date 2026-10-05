<template>
	<div class="position-relative">
		<!-- Floating action bar -->
		<v-slide-y-transition>
			<div v-if="DSDaChon.length > 0" class="thde-action-bar">
				<v-chip size="small" color="primary" variant="tonal">
					Đã chọn: {{ DSDaChon.length }}
				</v-chip>
				<v-btn size="small" color="primary" variant="tonal" prepend-icon="mdi-swap-horizontal"
					@click="onClickLuanChuyen">Luân chuyển</v-btn>
				<v-btn size="small" color="orange" variant="tonal" prepend-icon="mdi-cart" @click="onClickMuaHang">Nhập
					hàng</v-btn>
				<v-btn size="x-small" variant="text" icon="mdi-close" @click="clearSelection" />
			</div>
		</v-slide-y-transition>

		<v-data-table :items="items" v-model:expanded="expanded" :headers="headers" show-expand :height="tableHeight"
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
										<th class="text-center" style="width: 50px;"></th>
										<th class="text-start font-weight-medium">Tên hàng hoá</th>
										<th class="text-start font-weight-medium">Ghi chú</th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="ct in item.ChiTiet" :key="ct.DeXuat_MuaHang_ChiTiet_Id">
										<td class="text-center" style="width: 50px;">
											<v-checkbox v-model="ct.Is_Selected" density="compact" hide-details
												@update:model-value="handleSelected(ct)" />
										</td>
										<td class="text-start font-weight-medium">{{ ct.TenHangHoa }}</td>
										<td class="text-start text-grey-darken-1">{{ ct.GhiChu }}</td>
									</tr>
								</tbody>
							</v-table>
						</v-sheet>
					</td>
				</tr>
			</template>

			<template #no-data>
				<uc-empty text="Chưa có đề xuất cần xử lý" />
			</template>
		</v-data-table>
	</div>
</template>

<script>
	export default {
	props: {
		items: { type: Array, default: function () { return [] } },
		initialExpanded: { type: Array, default: function () { return [] } },
		loading: { type: Boolean, default: false },
	},
	emits: ['open-mua-hang', 'open-luan-chuyen'],
	data() {
		return {
			expanded: [],
			DSDaChon: [],
			headers: [
				{ width: 1, key: 'data-table-expand', align: 'start' },
				{ title: 'Tên địa điểm', key: 'TenDiaDiem', align: 'start' },
				{ title: 'Tình trạng', key: 'TinhTrang', align: 'start' },
				{ title: 'Ngày đề xuất', key: 'NgayDeXuat', align: 'start' },
				{ title: 'Ngày duyệt', key: 'NgayDuyet', align: 'start' },
			],
		}
	},
	computed: {
		tableHeight() {
			return this.DSDaChon.length > 0 ? 'calc(100vh - 200px)' : 'calc(100vh - 152px)'
		}
	},
	watch: {
		initialExpanded: {
			immediate: true,
			handler(val) { this.expanded = val ? [...val] : [] }
		},
		items() { this.clearSelection() }
	},
	methods: {
		formatDateTime: window.formatDateTime,

		formatNgayGio(Ngay, Gio) {
			const date = Ngay?.split('T')[0] ?? ''
			const time = Gio?.slice(0, 8) ?? ''
			return this.formatDateTime(date + ' ' + time)
		},

		handleSelected(item) {
			if (item.Is_Selected) {
				this.DSDaChon.push(item)
			} else {
				const idx = this.DSDaChon.findIndex(function (x) { return x.DeXuat_MuaHang_ChiTiet_Id === item.DeXuat_MuaHang_ChiTiet_Id })
				if (idx !== -1) this.DSDaChon.splice(idx, 1)
			}
		},

		clearSelection() {
			this.DSDaChon.forEach(function (item) { item.Is_Selected = false })
			this.DSDaChon = []
		},

		onClickMuaHang() {
			this.$emit('open-mua-hang', [...this.DSDaChon])
		},

		onClickLuanChuyen() {
			const diaDiemIds = new Set(this.DSDaChon.map(function (item) { return item.DiaDiem_Id }))
			if (diaDiemIds.size !== 1) {
				return showToast.info('Chỉ có thể chọn 1 cửa hàng để tiến hành luân chuyển')
			}
			const arraySoLuong = []
			const arrayCaBiet = []
			this.DSDaChon.forEach(function (item) {
				if (item.Is_CaBiet === true) arrayCaBiet.push(item)
				else arraySoLuong.push(item)
			})
			this.$emit('open-luan-chuyen', {
				DiaDiem_Id: this.DSDaChon[0].DiaDiem_Id,
				TenDiaDiem: this.DSDaChon[0].TenDiaDiem,
				arraySoLuong: arraySoLuong,
				arrayCaBiet: arrayCaBiet,
			})
		},
	},
}
</script>