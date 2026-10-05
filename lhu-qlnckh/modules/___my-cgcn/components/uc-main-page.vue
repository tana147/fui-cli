<template>
	<div class="cgcn-page pa-2">
		<!-- Thống kê cá nhân -->
		<uc-stats :stats-data="statsData" class="mb-2" />

		<!-- Danh sách & Bộ lọc -->
		<uc-main-view
			:table-rows="tableRows"
			:stats-data="statsData"
			@on-add="openAddModal"
			@on-edit="openEditModal"
			@on-delete="handleDelete"
			@on-submit="handleSubmit"
			@on-view-files="openFilesModal"
		/>

		<!-- Modal Kê khai / Chỉnh sửa -->
		<uc-modal-contract
			v-model="isContractModalOpen"
			:item-data="selectedItem"
			:v-set="vSet"
			@on-reload="fetchList"
		/>

		<!-- Modal Xem Minh chứng -->
		<uc-modal-files
			v-model="isFileModalOpen"
			:attached-files="selectedFiles"
			:contract-no="selectedContractNo"
			:v-set="vSet"
		/>
	</div>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				isContractModalOpen: false,
				isFileModalOpen: false,

				tableRows: [],
				selectedFiles: [],
				selectedItem: {},
				selectedContractNo: "",

				statsData: {
					totalAll: 0,
					countDraft: 0,
					countPending: 0,
					countRejected: 0,
					countApproved: 0
				},

				vSet: {
					apiFile: "",
					urlReturnFile: ""
				}
			}
		},
		mounted() {
			this.initPlatformConfig()
			this.fetchList()
		},
		methods: {
			initPlatformConfig() {
				const platformSet = (window.vueData && window.vueData.v_Set) ? window.vueData.v_Set : {}
				this.vSet = {
					apiFile: platformSet.apiFile || "https://file.lhu.edu.vn/qlnckh/upload/FileData",
					urlReturnFile: platformSet.urlReturnFile || "https://file.lhu.edu.vn/qlnckh"
				}
			},
			parseFileData(rawFileData) {
				if (!rawFileData) return []
				if (Array.isArray(rawFileData)) return rawFileData
				if (typeof rawFileData === "string") {
					try {
						const parsed = JSON.parse(rawFileData)
						return Array.isArray(parsed) ? parsed : []
					} catch (e) {
						return []
					}
				}
				return []
			},
			async fetchList() {
				try {
					const res = await ajaxCALLPromise("/DEV_CGCN_Get_ByNhanVienSubmit", {
						NhanVienSubmit: null,
						TrangThai: null,
						NamHoc: null
					})
					if (Array.isArray(res)) {
						if (Array.isArray(res[0])) {
							this.tableRows = res[0]
							const badgeStats = (Array.isArray(res[1]) && res[1][0]) ? res[1][0] : null
							if (badgeStats) {
								this.statsData = {
									totalAll: badgeStats.TotalAll || 0,
									countDraft: badgeStats.CountDraft || 0,
									countPending: badgeStats.CountPending || 0,
									countRejected: badgeStats.CountRejected || 0,
									countApproved: badgeStats.CountApproved || 0
								}
							} else {
								this.recalcStatsFromRows(this.tableRows)
							}
						} else {
							this.tableRows = res
							this.recalcStatsFromRows(this.tableRows)
						}
					} else {
						this.tableRows = []
					}
				} catch (err) {
					console.error("fetchList error:", err)
					this.tableRows = []
				}
			},
			recalcStatsFromRows(rows) {
				const list = Array.isArray(rows) ? rows : []
				let draft = 0, pending = 0, rejected = 0, approved = 0
				list.forEach(item => {
					if (!item) return
					const s = Number(item.TrangThai)
					if (s === 1) draft += 1
					else if (s === 2) pending += 1
					else if (s === 4) rejected += 1
					else if (s === 3) approved += 1
				})
				this.statsData = {
					totalAll: list.length,
					countDraft: draft,
					countPending: pending,
					countRejected: rejected,
					countApproved: approved
				}
			},
			openAddModal() {
				this.selectedItem = {}
				this.isContractModalOpen = true
			},
			openEditModal(item) {
				this.selectedItem = Object.assign({}, item)
				this.isContractModalOpen = true
			},
			openFilesModal(payload) {
				this.selectedFiles = this.parseFileData(payload.FileData)
				this.selectedContractNo = payload.SoHopDong || payload.TenDuAn || ""
				this.isFileModalOpen = true
			},
			handleSubmit(item) {
				confirm({
					title: `Bạn có chắc muốn gửi hồ sơ <b><i>${item.TenDuAn}</i></b> để Quản trị KH&CN thẩm định?`,
					action: async () => {
						await ajaxCALLPromise("/DEV_CGCN_Submit", { CGCNID: item.CGCNID })
						Vue.$toast.success("Gửi hồ sơ thẩm định thành công!", { position: "top" })
						this.fetchList()
					}
				})
			},
			handleDelete(item) {
				confirm({
					title: `Bạn có chắc muốn xóa dự thảo hồ sơ <b><i>${item.TenDuAn}</i></b>?`,
					action: async () => {
						await ajaxCALLPromise("/DEV_CGCN_Del", { CGCNID: item.CGCNID })
						Vue.$toast.success("Xóa dự thảo thành công!", { position: "top" })
						this.fetchList()
					}
				})
			}
		}
	}
</script>