<template>
	<v-data-table :headers="headerPhieuDinhKi" :items="DSPhieuDinhKi" density="compact" fixed-header class="border-t"
		style="height: calc(100vh - 48px);" items-per-page-text="Bản ghi" :items-per-page="20"
		:items-per-page-options="[15, 20, 50, 100]">

		<template v-slot:item.LoaiPhieu="{ item }">
			{{ mapLoaiPhieu[item.LoaiPhieu].text }}
		</template>

		<template v-slot:item.ThongTin="{ item }">
			<div class="d-flex flex-column ga-1 text-caption">
				<div class="d-flex align-center ga-1">
					<span class="text-medium-emphasis">Địa điểm áp dụng</span>
					<v-chip size="x-small" variant="tonal" color="primary">
						{{ item.DSDiaDiem.length }}
					</v-chip>
				</div>
				<!-- <div class="d-flex align-center ga-1 ">
					<span class="text-medium-emphasis">Hàng hoá áp dụng</span>
					<v-chip size="x-small" variant="tonal" color="success">
						{{ item.DSHangHoa.length }}
					</v-chip>
				</div> -->

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
			<uc-empty text="Chưa có phiếu định kì"></uc-empty>
		</template>
	</v-data-table>
</template>

<script>
export default {
	props: {
		DSPhieuDinhKi: Array,
		loadDSPhieuDinhKi: Function
	},
	data() {
		return {
			mapLoaiPhieu: {
				KIEM_KE_DINH_KI: {
					text: 'Phiếu kiểm kê định kì',
					color: 'grey'
				},
				KIEM_KE_HANG_NGAY: {
					text: 'Phiếu kiểm kê hằng ngày',
					color: 'grey'
				},
			},

			mapLoaiDinhKi: {
				NGAY: 'Ngày',
				TUAN: 'Tuần',
				THANG: 'Tháng',
				NAM: 'Năm',
			},

			headerPhieuDinhKi: [
				{ title: "Tên phiếu", key: "TenPhieuDinhKi" },
				{ title: "Loại phiếu", key: "LoaiPhieu", align: 'start' },
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
				PhieuDinhKi_Id: item.PhieuDinhKi_Id,
			}
			showConfirm(
				`Xác nhận xoá: <b>${item.TenPhieuDinhKi}</b>`,
				() => {
					apiCall("work/HH_PhieuDinhKi_Delete", params, (res) => {
						if (res) showToast.success("Thành công");;
						$this.loadDSPhieuDinhKi()
					})
				}
			)

		},

		onRunNow(item) {
			const $this = this
			const params = {
				PhieuDinhKi_Id: item.PhieuDinhKi_Id,
			}
			showConfirm(
				`Xác nhận chạy: <b>${item.TenPhieuDinhKi}</b>`,
				() => {
					apiCall("work/HH_PhieuDinhKi_Run", params, (res) => {
						if (res) showToast.success("Thành công");;
						$this.loadDSPhieuDinhKi()
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