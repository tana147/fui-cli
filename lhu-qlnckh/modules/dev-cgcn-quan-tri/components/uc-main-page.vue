<template>
	<div class="cgcn-page pa-2">
		<uc-stats :stats-data="statsData" class="mb-2" />

		<uc-main-view
			:table-rows="tableRows"
			:status-counts="statusCounts"
			@on-add="openAddModal"
			@on-edit="openEditModal"
			@on-delete="handleDelete"
			@on-view-files="openFilesModal"
			@on-approve="handleApprove"
			@on-reject="handleReject"
		/>

		<uc-modal-add
			v-model="isAddModalOpen"
			:v-set="vSet"
			@on-reload="fetchList"
		/>

		<uc-modal-edit
			v-model="isEditModalOpen"
			:edit-item="editItem"
			:v-set="vSet"
			@on-reload="fetchList"
		/>

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
				isAddModalOpen: false,
				isEditModalOpen: false,
				isFileModalOpen: false,

				tableRows: [],
				selectedFiles: [],
				editItem: {},
				selectedContractNo: "",

				statusCounts: {
					totalAll: 0,
					countDraft: 0,
					countPending: 0,
					countApproved: 0,
					countRejected: 0
				},

				vSet: {
					apiFile: "",
					urlReturnFile: ""
				}
			}
		},
		computed: {
			statsData() {
				const rows = Array.isArray(this.tableRows) ? this.tableRows : []
				let totalValueApproved = 0

				rows.forEach(item => {
					// Chỉ tính giá trị của các hợp đồng đã được phê duyệt (TrangThai = 3)
					if (Number(item.TrangThai) === 3) {
						totalValueApproved += Number(item.GiaTriHopDong) || 0
					}
				})

				return {
					totalProjects: this.statusCounts.totalAll || rows.length,
					totalValue: totalValueApproved,
					countPending: this.statusCounts.countPending,
					countApproved: this.statusCounts.countApproved,
					countRejected: this.statusCounts.countRejected
				}
			}
		},
		mounted() {
			this.initPlatformConfig()
			this.fetchList()
		},
		methods: {
			initPlatformConfig() {
				const platformSet = window.vueData && window.vueData.v_Set ? window.vueData.v_Set : {}
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
					const res = await ajaxCALLPromise("/DEV_CGCN_Get", {
						TrangThai: null,
						NamHoc: null,
						TuKhoa: null
					})
					if (Array.isArray(res)) {
						if (Array.isArray(res[0])) {
							this.tableRows = res[0]
							const badgeStats = (Array.isArray(res[1]) && res[1][0]) ? res[1][0] : null
							if (badgeStats) {
								this.statusCounts = {
									totalAll: badgeStats.TotalAll || 0,
									countDraft: badgeStats.CountDraft || 0,
									countPending: badgeStats.CountPending || 0,
									countApproved: badgeStats.CountApproved || 0,
									countRejected: badgeStats.CountRejected || 0
								}
							} else {
								this.recalcCounts(this.tableRows)
							}
						} else {
							this.tableRows = res
							this.recalcCounts(this.tableRows)
						}
					} else {
						this.tableRows = []
					}
				} catch (err) {
					console.error("fetchList error:", err)
					this.tableRows = []
				}
			},
			recalcCounts(rows) {
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
				this.statusCounts = {
					totalAll: list.length,
					countDraft: draft,
					countPending: pending,
					countRejected: rejected,
					countApproved: approved
				}
			},
			openAddModal() {
				this.isAddModalOpen = true
			},
			openEditModal(item) {
				this.editItem = Object.assign({}, item)
				this.isEditModalOpen = true
			},
			openFilesModal(payload) {
				this.selectedFiles = this.parseFileData(payload.FileData)
				this.selectedContractNo = payload.SoHopDong || payload.TenDuAn || ""
				this.isFileModalOpen = true
			},
			async handleApprove(item) {
				try {
					await ajaxCALLPromise("/DEV_CGCN_Duyet", {
						CGCNID: item.CGCNID,
						TrangThai: 3,
						LyDoReject: ""
					})
					Vue.$toast.success(`Đã phê duyệt hồ sơ: ${item.TenDuAn}`, { position: "top" })
					this.fetchList()
				} catch (err) {
					console.error("Approve error:", err)
				}
			},
			async handleReject(payload) {
				try {
					await ajaxCALLPromise("/DEV_CGCN_Duyet", {
						CGCNID: payload.item.CGCNID,
						TrangThai: 4,
						LyDoReject: payload.reason
					})
					Vue.$toast.success("Đã trả về yêu cầu bổ sung!", { position: "top" })
					this.fetchList()
				} catch (err) {
					console.error("Reject error:", err)
				}
			},
			handleDelete(item) {
				confirm({
					title: `Bạn có muốn xóa dự án/hợp đồng chuyển giao công nghệ <b><i>${item.TenDuAn || ""}</i></b>?`,
					action: async () => {
						const params = { CGCNID: item.CGCNID }
						await ajaxCALLPromise("/DEV_CGCN_Del", params)
						Vue.$toast.success("Xóa thành công", { position: "top" })
						this.fetchList()
					}
				})
			}
		}
	}
</script>