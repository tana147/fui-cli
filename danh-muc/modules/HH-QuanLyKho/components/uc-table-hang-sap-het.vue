<template>
	<v-card>
		<v-card-title class="d-flex align-center ga-2">
			<template v-if="!isMobile">
				<div class="text-primary text-left table-title">
					Danh sách hàng hoá sắp hết
				</div>
				<v-spacer></v-spacer>
			</template>
			<v-text-field v-model="search" density="compact" variant="underlined" label="Tìm kiếm"
				prepend-inner-icon="mdi-magnify" flat hide-details single-line class="search-field"></v-text-field>
		</v-card-title>
		<v-card-text class="pa-0">
			<v-progress-linear v-if="loading" indeterminate color="primary" />
			<v-data-table :items="filteredItems" :headers="headerHangSapHet"
				:group-by="[{ key: 'HangHoa_Id', order: 'desc' }]" height="calc(100vh - 177px)" density="compact"
				:disable-sort="true" fixed-header hide-default-footer :items-per-page="-1">
				<template v-slot:group-header="{ item, columns, toggleGroup, isGroupOpen }">
					<tr>
						<td :colspan="columns.length">
							<div class="d-flex align-center">
								<v-btn :icon="isGroupOpen(item) ? '$expand' : '$next'" color="medium-emphasis"
									density="comfortable" size="small" variant="outlined" @click="toggleGroup(item)" />

								<span class="ms-4 font-weight-medium cursor-pointer" @click="toggleGroup(item)">
									{{ item.items[0].raw.TenHangHoa }}
								</span>

								<v-chip class="mx-2" size="x-small">
									{{ item.items.length }}
								</v-chip>
								<v-spacer />
							</div>
						</td>
					</tr>
				</template>
				<template #no-data>
					<uc-empty text="Chưa có hàng hoá sắp hết" />
				</template>
			</v-data-table>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
	
		props: {
			DSHangSapHet: Array,
			loading: { type: Boolean, default: false },
		},
		data() {
			return {
				search: null,
			}
		},
	
		computed: {
			filteredItems() {
				if (!this.search?.trim()) return this.DSHangSapHet
	
				const keyword = this.search.trim().toLowerCase()
	
				return this.DSHangSapHet.filter(item =>
					item.TenHangHoa?.toLowerCase().includes(keyword)
				)
			},
			isMobile() {
				return this.$vuetify.display.smAndDown
			},
			headerHangSapHet() {
				return [
					{ title: '', key: 'data-table-group', width: '50px' },
					{ title: this.isMobile ? "Địa điểm" : "Tên địa điểm", key: "TenDiaDiem", align: 'start' },
					{ title: this.isMobile ? "Tối thiểu" : "Tồn tối thiểu", key: "TonToiThieu", align: 'end' },
					{ title: this.isMobile ? "Hiện tại" : "Tồn hiện tại", key: "TonHienTai", align: 'end' },

				]
			}
		},
	
		watch: {
		},
	}
</script>