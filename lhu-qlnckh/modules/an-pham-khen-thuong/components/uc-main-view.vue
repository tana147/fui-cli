<template>
	<div class="article-table-section">
		<v-card class="article-table-card">
			<v-card-title class="pa-3 pa-sm-4 d-flex flex-wrap align-center justify-space-between" style="gap: 12px;">
				<span class="primary--text font-weight-bold text-subtitle-1 text-sm-h6 me-auto">Danh sách bài báo đề nghị khen thưởng</span>
				<div class="d-flex flex-wrap align-center justify-start justify-sm-end flex-grow-1 flex-sm-grow-0" style="gap: 10px;">
					<v-select v-model="nhomAnPhamId" style="min-width: 180px; max-width: 260px;" :items="dsBaiBaoChange" item-text="TenLoai"
						item-value="LoaiID" label="Nhóm ấn phẩm" outlined dense hide-details class="flex-grow-1 flex-sm-grow-0"></v-select>
					<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm"
						outlined dense hide-details single-line style="min-width: 180px; max-width: 280px;" class="flex-grow-1 flex-sm-grow-0"></v-text-field>
					<v-btn color="success" fab small outlined @click="openAdd" title="Thêm đề xuất">
						<v-icon>mdi-plus</v-icon>
					</v-btn>
				</div>
			</v-card-title>

			<v-card-text class="article-table-content">
				<v-data-table class="article-table" :headers="headersArticlesObj" :items="filteredItems"
					:search="search" :footer-props="{ 'items-per-page-options': [25, 50, 100, -1] }"
					:items-per-page="50"
					:mobile-breakpoint="0">
					<template v-slot:item.TrangThai="{ item }">
						<v-chip :color="getColorStatus(item.TrangThaiID)">
							{{ item.TrangThai }}
						</v-chip>
					</template>
					<template v-slot:item.nhomanpham="{ item }">
						<v-chip outlined color="primary" v-if="item.NhomAnPham === 1">Ấn phẩm khoa học</v-chip>
						<v-chip v-if="item.NhomAnPham === 2" outlined color="success">Hỗ trợ Đầu vào Cao học</v-chip>
						<v-chip v-if="item.NhomAnPham === 3" outlined color="orange">Có hướng dẫn Cao học</v-chip>
					</template>
					<template v-slot:item.TenAnPham="{ item }">
						<p class="font-weight-medium mb-1">{{ item.TenAnPham }}</p>
						<v-chip v-if="item.Is_DeNghiXetThuong === false" x-small color="grey darken-1" dark label class="font-weight-medium">
							Chỉ kê khai LLKH
						</v-chip>
						<v-chip v-else x-small color="primary" outlined label class="font-weight-medium">
							Xét khen thưởng
						</v-chip>
					</template>
					<template v-slot:item.actions="{ item }">
						<div class="d-flex flex-row align-center justify-center">
							<v-icon style="font-size:18px"
								v-if="item.TrangThaiID === 1 || item.TrangThaiID === 2 || item.TrangThaiID === 5"
								color="red darken-3" small class="mr-2" @click="deleteItem(item)">
								mdi-trash-can-outline
							</v-icon>
							<v-icon
								v-if="item.TrangThaiID === 1 || item.TrangThaiID === 2 || item.TrangThaiID === 5 || item.TrangThaiID === 3"
								style="font-size:18px" color="green darken-2" small class="mr-2"
								@click="editItem(item)">
								mdi-square-edit-outline
							</v-icon>
						</div>
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>
	</div>
</template>

<script>
	export default {
		name: 'uc-main-view',
	props: {
		tableRows: { type: Array, default: () => [] }
	},
	emits: ['on-add', 'on-edit', 'on-delete'],
	data() {
		return {
			// 1. Controls
			search: "",

			// 2. API / Static arrays
			headersArticlesObj: [
				{ text: 'STT', sortable: false, value: "STT", align: "center", width: 60 },
				{ text: 'Tên bài báo', sortable: false, value: "TenAnPham", width: 280 },
				{ text: 'Tác giả', sortable: false, value: "TacGia", width: 200 },
				{ text: 'Đơn vị', value: "DonViDaiDien", width: 140 },
				{ text: 'Danh mục bài báo/ấn phẩm', sortable: false, value: 'TenLoaiAnPham', width: 200 },
				{ text: 'Tên tạp chí', sortable: false, value: 'TenTapChi', width: 200 },
				{ text: 'Tên danh mục tạp chí', sortable: false, value: "TenLoaiDanhMucTapChi", width: 180 },
				{ text: 'Nơi đăng', sortable: false, value: "NoiDangBai", width: 120, align: "center" },
				{ text: 'Năm đăng', sortable: true, value: "NamDangBai", width: 110, align: "center" },
				{ text: 'Nhóm ấn phẩm', value: "nhomanpham", sortable: false, width: 170, align: "center" },
				{ text: 'Trạng thái', sortable: true, value: "TrangThai", width: 140, align: "center" },
				{ text: 'Thao tác', value: "actions", sortable: false, align: "center", width: 100 },
			],
			loaiBaiBao: [
				{ TenLoai: "Ấn phẩm khoa học", LoaiID: 1 },
				{ TenLoai: "Hỗ trợ Đầu vào Cao học", LoaiID: 2 },
				{ TenLoai: "Có tham gia đào tạo nghiên cứu sính", LoaiID: 3 }
			],

			// 3. Local state
			nhomAnPhamId: 4,
		}
	},
	computed: {
		dsBaiBaoChange() {
			return [...this.loaiBaiBao, { TenLoai: "Tất cả", LoaiID: 4 }]
		},
		filteredItems() {
			if (this.nhomAnPhamId === 4) {
				return this.tableRows
			}
			return this.tableRows.filter(item => item.NhomAnPham === this.nhomAnPhamId)
		}
	},
	methods: {
		getColorStatus(statusId) {
			return getColorStatusAnPham(statusId)
		},
		openAdd() {
			this.$emit('on-add')
		},
		editItem(item) {
			this.$emit('on-edit', item)
		},
		deleteItem(item) {
			this.$emit('on-delete', item)
		}
	}
	}
</script>