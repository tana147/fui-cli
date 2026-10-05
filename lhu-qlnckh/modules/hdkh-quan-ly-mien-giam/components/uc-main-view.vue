<template>
	<div>
		<v-select v-model="localKhoaId" label="Chọn khoa" class="mb-2" :items="khoaList" item-value="KhoaID"
			item-title="TenKhoa"></v-select>

		<div v-if="localKhoaId && dsNhanVien">
			<v-card elevation="0">
				<v-card-text class="pa-0">
					<div class="d-flex mb-3 align-center">
						<v-btn-toggle v-model="nckhFilter" color="primary" density="compact" mandatory
							variant="outlined" class="mr-4">
							<v-btn value="all" class="text-caption">Tất cả</v-btn>
							<v-btn value="yes" class="text-caption">Tham gia NCKH</v-btn>
							<v-btn value="no" class="text-caption">Không tham gia</v-btn>
						</v-btn-toggle>
						<v-spacer></v-spacer>
						<v-btn color="primary" prepend-icon="mdi-plus" class="mr-2" @click="$emit('on-add-nhan-vien')">
							Thêm nhân viên
						</v-btn>
						<v-btn color="success" variant="text" icon="mdi-file-excel" @click="onExportExcel"
							title="Xuất Excel"></v-btn>
						<v-text-field v-model="search" variant="underlined" prepend-inner-icon="mdi-filter-outline"
							label="Tìm kiếm" single-line hide-details dense style="max-width: 300px;"></v-text-field>
					</div>
					<v-data-table class="mb-1 elevation-1" :headers="headers" :items="filteredNhanVien" :search="search"
						height="calc(100vh - 204px)" :items-per-page="-1" hide-default-footer dense>
						<template v-slot:item.Is_ThamGiaNCKH="{ item }">
							<v-icon
								v-if="item.Is_ThamGiaNCKH === 1 || item.Is_ThamGiaNCKH === true || item.Is_ThamGiaNCKH === '1'"
								color="success">mdi-check</v-icon>
						</template>
						<template v-slot:item.actions="{ item }">
							<div class="d-flex ga-1 justify-center">
								<v-btn icon="mdi-eye" size="small" variant="text" color="default" title="Xem chi tiết"
									@click="$emit('on-view-detail', item)" />
								<v-btn icon="mdi-square-edit-outline" size="small" variant="text" color="primary"
									title="Sửa" @click="$emit('on-edit-nhan-vien', item)" />
								<v-btn icon="mdi-trash-can-outline" size="small" variant="text" color="error"
									title="Xóa" @click="$emit('on-delete-nhan-vien', item)" />
							</div>
						</template>
					</v-data-table>
				</v-card-text>
			</v-card>
		</div>

		<div v-else class="d-flex ga-4 justify-center align-center">
			<v-empty-state text-width="250">
				<template v-slot:media>
					<v-icon size="20">mdi-magnify</v-icon>
				</template>
				<template v-slot:title>
					<div class="text-caption text-high-emphasis">Không tìm thấy dữ liệu</div>
				</template>
			</v-empty-state>
		</div>
	</div>
</template>

<script>
	export default {
		name: "uc-main-view",
		props: {
			khoaList: { type: Array, default: () => [] },
			value: { type: [String, Number, Object], default: null },
			modelValue: { type: [String, Number, Object], default: null },
			dsNhanVien: { type: Array, default: null }
		},
		emits: ["input", "update:modelValue", "on-view-detail"],
		data() {
			return {
				search: "",
				nckhFilter: "all",
				headers: [
					{ title: "STT", value: "STT", align: "center", width: 50 },
					{ title: "Mã nhân viên", value: "NhanVienID", align: "center", width: 120 },
					{ title: "Họ và tên", value: "HoTen", width: 200 },
					{ title: "Học vị", value: "HocVi", width: 200 },
					{ title: "Chức vụ", value: "ChucVu", width: 200 },
					{ title: "Tham gia NCKH", value: "Is_ThamGiaNCKH", align: "center", width: 130 },
					{ title: "Định mức giờ chuẩn", value: "DinhMucGioChuan", align: "end", width: 180 },
					{ title: "Tổng số giờ miễn giảm", value: "TongSoGioMienGiam", align: "end", width: 180 },
					{ title: "Lý do miễn/giảm", value: "DanhSachLyDo", width: 300 },
					{ title: "Thao tác", value: "actions", align: "center", sortable: false, width: 150 },
				]
			}
		},
		computed: {
			localKhoaId: {
				get() { return this.modelValue !== null ? this.modelValue : this.value; },
				set(val) {
					let id = val;
					if (val && typeof val === 'object' && val.KhoaID !== undefined) {
						id = val.KhoaID;
					}
					this.$emit("input", id);
					this.$emit("update:modelValue", id);
				}
			},
			filteredNhanVien() {
				if (!this.dsNhanVien) return [];
				if (this.nckhFilter === "yes") {
					return this.dsNhanVien.filter(item => item.Is_ThamGiaNCKH === 1 || item.Is_ThamGiaNCKH === true || item.Is_ThamGiaNCKH === "1");
				}
				if (this.nckhFilter === "no") {
					return this.dsNhanVien.filter(item => item.Is_ThamGiaNCKH === 0 || item.Is_ThamGiaNCKH === false || item.Is_ThamGiaNCKH === "0" || item.Is_ThamGiaNCKH === null || item.Is_ThamGiaNCKH === undefined);
				}
				return this.dsNhanVien;
			}
		},
		methods: {
			onExportExcel() {
				jsonToExcel({
					data: this.filteredNhanVien,
					filename: `DanhSachGiangVien.xlsx`
				});
			}
		}
	}
</script>