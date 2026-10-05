<template>
	<v-dialog v-model="isShow" width="800">
		<v-card>
			<v-toolbar density="compact" elevation="0" class="mt-2">
				<v-toolbar-title class="mb-2">
					Danh sách phiếu
					<div class="text-subtitle-2 ">
						Thuộc phiếu: {{ selectedItem.TenPhieuDinhKi }}
					</div>
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>

			<v-card-text class="pt-0">
				<v-data-table :headers="headers" :items="items" height="500" density="compact"
					items-per-page-text="Bản ghi" :items-per-page="15" :items-per-page-options="[15, 20]">
					<template v-slot:item.LoaiPhieuKiemKe="{ item }">
						{{ mapLoaiPhieu[item.LoaiPhieuKiemKe].text }}
					</template>

					<template v-slot:item.TinhTrang="{ item }">
						<v-chip size="small" :color="mapTinhTrangPhieu[item.TinhTrang]?.color">
							{{ mapTinhTrangPhieu[item.TinhTrang]?.text }}
						</v-chip>
					</template>
					<template v-slot:item.action="{ item }">
						<v-btn icon="mdi-trash-can" variant="text" color="error" size="small" @click="onDelete(item)" />
					</template>
					<template #no-data>
						<uc-empty text="Chưa có dữ liệu" />
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShow: Boolean,
			selectedItem: Object,
			items: Array,
			loadListPhieuById: Function,
		},
		emits: ["update:isShow"],
		data() {
			return {
				mapTinhTrangPhieu,
				mapLoaiPhieu: {
					KIEM_KE_DINH_KI: {
						text: "Kiểm kê định kì",
						color: "primary"
					},
					KIEM_KE_HANG_NGAY: {
						text: "Kiểm kê hằng ngày",
						color: "grey"
					},
				},
				headers: [
					{ title: "Loại phiếu", key: "LoaiPhieuKiemKe" },
					{ title: "Tên phiếu", key: "TenPhieuKiemKe" },
					{ title: "Tình trạng", key: "TinhTrang" },
					{ title: "", key: "action", sortable: false },
				]
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {
			closeDialog() {
				this.$emit('update:isShow', false)
			},
	
			async onDelete(item) {
				const $this = this
				const params = {
					PhieuKiemKe_Id: item.PhieuKiemKe_Id,
				}
				showConfirm(
					`Xác nhận xoá: <b>${item.TenPhieuKiemKe}</b>`,
					() => {
						apiCall("work/HH_PhieuKiemKe_Delete", params, (res) => {
							if (res) showToast.success("Thành công")
							$this.loadListPhieuById(this.selectedItem.PhieuDinhKi_Id)
						})
					}
				)
			}
		},
	}
</script>