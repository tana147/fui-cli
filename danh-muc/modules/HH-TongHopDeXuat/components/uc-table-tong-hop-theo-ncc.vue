<template>
	<div class="position-relative">
		<!-- Floating action bar -->
		<v-slide-y-transition>
			<div v-if="DSDaChon.length > 0" class="thde-action-bar">
				<v-chip size="small" color="primary" variant="tonal">
					Đã chọn: {{ DSDaChon.length }}
				</v-chip>
				<v-btn size="small" color="primary" variant="flat" prepend-icon="mdi-truck-delivery"
					@click="onClickDatHang">Tạo phiếu đặt hàng</v-btn>
				<v-btn size="x-small" variant="text" icon="mdi-close" @click="clearSelection" />
			</div>
		</v-slide-y-transition>

		<v-data-table :items="items" v-model:expanded="expanded" :headers="headers" show-expand :height="tableHeight"
			density="compact" :disable-sort="true" fixed-header hide-default-footer :items-per-page="-1"
			item-value="GoiY_NhaCungCap_Id" item-key="GoiY_NhaCungCap_Id" :loading="loading">

			<template v-slot:item.data-table-expand="{ internalItem, isExpanded, toggleExpand }">
				<v-btn :icon="isExpanded(internalItem) ? 'mdi-chevron-up' : 'mdi-chevron-down'" size="small"
					@click="toggleExpand(internalItem)" variant="text" />
			</template>

			<template v-slot:expanded-row="{ columns, item }">
				<tr v-if="item.Children?.length > 0">
					<td :colspan="columns.length" class="pa-0">
						<v-sheet border class="ma-2">
							<v-table density="compact" class="text-body-2">
								<thead class="bg-grey-lighten-4">
									<tr>
										<th class="text-center" style="width: 50px;"></th>
										<th class="text-start font-weight-medium">Tên hàng hoá</th>
										<th class="text-start font-weight-medium">Tên địa điểm</th>
										<th class="text-end font-weight-medium" style="width:200px">Số lượng</th>
										<th class="text-start font-weight-medium" style="width:200px">ĐVT</th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="child in item.Children" :key="child.DeXuat_MuaHang_ChiTiet_Id">
										<td class="text-center" style="width: 50px;">
											<v-checkbox v-model="child.Is_Selected" density="compact" hide-details
												@update:model-value="handleSelected(child)" />
										</td>
										<td class="text-start font-weight-medium">{{ child.TenHangHoa }}</td>
										<td>{{ child.TenDiaDiem }}</td>
										<td class="text-end">{{ child.SoLuong }}</td>
										<td class="text-start">{{ child.TenDonVi }}</td>
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
	emits: ['open-dat-hang'],
	data() {
		return {
			expanded: [],
			DSDaChon: [],
			headers: [
				{ width: 1, key: 'data-table-expand', align: 'start' },
				{ title: 'Tên nhà cung cấp', key: 'TenNhaCungCap', align: 'start' },
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

		onClickDatHang() {
			const items = this.DSDaChon.map(function (item) {
				return {
					...item,
					NhaCungCap_Id: item.GoiY_NhaCungCap_Id,
					DiaDiemNhan_Id: item.DiaDiem_Id,
				}
			})
			this.$emit('open-dat-hang', items)
		},
	},
}
</script>