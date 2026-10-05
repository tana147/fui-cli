<template>
	<v-data-table :headers="headerLichDinhKi" :items="DSLichDinhKi" density="compact" fixed-header class="border-t"
		style="height: calc(100vh - 48px);" items-per-page-text="Bản ghi" :items-per-page="20"
		:items-per-page-options="[15, 20, 50, 100]">

		<template v-slot:item.ThongTin="{ item }">
			<div class="d-flex flex-column ga-1 text-caption">
				<div class="d-flex align-center ga-1">
					<span class="text-medium-emphasis">Địa điểm áp dụng</span>
					<v-chip size="x-small" variant="tonal" color="primary">
						{{ item.DSDiaDiem.length }}
					</v-chip>
				</div>
			</div>
		</template>

		<template v-slot:item.LoaiDinhKi="{ item }">
			{{ mapLoaiDinhKi[item.LoaiDinhKi] }}
		</template>

		<template v-slot:item.LanChayTiepTheo="{ item }">
			{{ formatDate(item.LanChayTiepTheo) ?? 'Chưa có' }}
		</template>

		<template v-slot:item.LanChayCuoiCung="{ item }">
			{{ formatDate(item.LanChayCuoiCung) ?? 'Chưa có' }}
		</template>

		<template v-slot:item.Is_TamKhoa="{ item }">
			<template v-if="item.Is_TamKhoa">
				<v-icon color="primary">mdi-lock </v-icon>
			</template>
		</template>

		<template v-slot:item.actions="{ item }">
			<v-menu>
				<template v-slot:activator="{ props }">
					<v-btn size="small" variant="text" v-bind="props" icon="mdi-dots-vertical"></v-btn>
				</template>
				<v-list density="compact">
					<v-list-item @click="onRunNow(item)" prepend-icon="mdi-play-circle"
						title="Chạy ngay lập tức"></v-list-item>
					<v-divider />
					<v-list-item @click="onViewList(item)" prepend-icon="mdi-eye"
						title="Xem danh sách phiếu"></v-list-item>
					<v-divider />
					<v-list-item @click="onEdit(item)" prepend-icon="mdi-square-edit-outline"
						title="Cập nhật"></v-list-item>
					<v-divider />
					<v-list-item @click="onDelete(item)" prepend-icon="mdi-trash-can" title="Xóa"></v-list-item>
				</v-list>
			</v-menu>
		</template>

		<template v-slot:no-data>
			<uc-empty text="Chưa có lịch định kì"></uc-empty>
		</template>
	</v-data-table>
</template>

<script>
export default {
	props: {
		DSLichDinhKi: Array,
		loadDSLichDinhKi: Function
	},
	data() {
		return {
			mapLoaiDinhKi: {
				NGAY: 'Ngày',
				TUAN: 'Tuần',
				THANG: 'Tháng',
				NAM: 'Năm',
			},

			headerLichDinhKi: [
				{ title: "Tên lịch", key: "TenLichDinhKi" },
				{ title: "Loại định kì", key: "LoaiDinhKi", align: 'start' },
				{ title: "Thông tin", key: "ThongTin", align: 'start' },
				{ title: "Lần chạy cuối cùng", key: "LanChayCuoiCung" },
				// { title: "Lần chạy tiếp theo", key: "LanChayTiepTheo" },
				{ title: "Ghi chú", key: "GhiChu" },
				{ title: "Tạm khoá", key: "Is_TamKhoa", align: 'center' },
				{ title: '', key: 'actions', sortable: false },
			],
		}
	},
	mounted() { },
	computed: {},
	watch: {},
	methods: {
		formatDate: window.formatDate,

		onEdit(item) {
			this.$emit("edit-emit", item)
		},

		async onDelete(item) {
			const $this = this
			const params = {
				LichDinhKi_Id: item.LichDinhKi_Id,
			}
			showConfirm(
				`Xác nhận xoá: <b>${item.TenLichDinhKi}</b>`,
				() => {
					apiCall("work/TS_LichDinhKi_Delete", params, (res) => {
						if (res) showToast.success("Thành công");;
						$this.loadDSLichDinhKi()
					})
				}
			)

		},

		onRunNow(item) {
			const $this = this
			const params = {
				LichDinhKi_Id: item.LichDinhKi_Id,
			}
			showConfirm(
				`Xác nhận chạy: <b>${item.TenLichDinhKi}</b>`,
				() => {
					apiCall("work/TS_LichDinhKi_Run", params, (res) => {
						if (res) showToast.success("Thành công");;
						$this.loadDSLichDinhKi()
					})
				}
			)
		},
		onViewList(item) {
			this.$emit("view-list-emit", item)
		}
	},
}
</script>