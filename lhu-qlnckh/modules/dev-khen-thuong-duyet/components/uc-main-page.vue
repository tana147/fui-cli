<template>
	<div class="duyet-main-container pa-2">
		<!-- 1. Main View (Bảng duyệt, filter, export Excel theo đợt) -->
		<uc-main-view :dsbaibao="dsHoSo" :dsdotduyet="dsDotDuyet" :is-loading="isLoading"
			@on-edit="openEditModal" @on-reload="fetchDSHoSo"
			@on-manage-dotduyet="isManageDotDuyetOpen = true"
			@on-manage-dot-dexuat="isManageDotDeXuatOpen = true"
			class="flex-grow-1 overflow-hidden" />

		<!-- 3. Modal Thẩm định & Phân bổ tiền thưởng -->
		<uc-modal-edit v-model="isEditModalOpen" :edit-row="editRow"
			:dscongthuckhenthuong="dsCongThuc" :dsdotduyet="dsDotDuyet"
			@on-reload="fetchDSHoSo" @on-manage-dotduyet="isManageDotDuyetOpen = true" />

		<!-- 4. Modal Quản lý Đợt duyệt chi tiền -->
		<uc-dotduyet-manage v-model="isManageDotDuyetOpen" @on-reload="fetchDSDotDuyet" />

		<!-- 5. Modal Quản lý Đợt nộp đề xuất (Dành cho Giảng viên) -->
		<uc-dot-dexuat-manage v-model="isManageDotDeXuatOpen" />
	</div>
</template>

<script>
	export default {
		name: 'uc-main-page',
		data() {
			return {
				// 1. Controls
				isEditModalOpen: false,
				isManageDotDuyetOpen: false,
				isManageDotDeXuatOpen: false,
				isLoading: false,

				// 2. API Data
				dsHoSo: [],
				dsCongThuc: [],
				dsDotDuyet: [],

				// 3. Local state
				editRow: {},
			}
		},
		computed: {
			activeDotDuyet() {
				return (this.dsDotDuyet || []).find(d => d.TinhTrang === 1) || null
			},
		},
		mounted() {
			this.initData()
		},
		methods: {
			async initData() {
				this.isLoading = true
				try {
					await Promise.all([
						this.fetchDSHoSo(),
						this.fetchDSDotDuyet(),
						this.fetchDSCongThuc(),
					])
				} finally {
					this.isLoading = false
				}
			},
			async fetchDSHoSo() {
				const data = await ajaxCALLPromise('/ThiKHCN_Get_ByTrangThai', { TrangThai: '2,3,4' })
				this.dsHoSo = data || []
			},
			async fetchDSDotDuyet() {
				const data = await ajaxCALLPromise('/ThiKHCN_DotDuyet_Get')
				this.dsDotDuyet = data || []
			},
			async fetchDSCongThuc() {
				const data = await ajaxCALLPromise('/ThiKHCN_CongThuc_Get')
				this.dsCongThuc = data || []
			},
			openEditModal(item) {
				this.editRow = item
				this.isEditModalOpen = true
			},
		},
	}
</script>