<template>
	<div class="pa-2 gtqd-page">
		<uc-stats :stats="statsData" />

		<uc-main-view
			:table-rows="tableRows"
			:is-loading-export="isLoadingExport"
			@on-add="openAddModal"
			@on-edit="openEditModal"
			@on-delete="handleDelete"
			@on-manage-files="openFilesModal"
		/>

		<uc-modal-decision
			v-model="isDecisionModalOpen"
			:is-edit="isEditDecision"
			:decision-item="selectedDecision"
			@on-reload="fetchDecisions"
		/>

		<uc-modal-files
			v-model="isFilesModalOpen"
			:decision-item="selectedDecision"
			:v-set="vSet"
			@on-reload="fetchDecisions"
		/>
	</div>
</template>

<script>
	export default {
		name: "uc-main-page",
	data() {
		return {
			// 1. Dialog control state
			isDecisionModalOpen: false,
			isEditDecision: false,
			isFilesModalOpen: false,

			// 2. Data arrays & objects
			tableRows: [],
			selectedDecision: {},

			// 3. Local state
			isLoadingExport: false,
			vSet: {
				apiFile: "",
				urlReturnFile: ""
			}
		}
	},
	computed: {
		statsData() {
			const rows = Array.isArray(this.tableRows) ? this.tableRows : []
			const totalDecisions = rows.length
			let decisionsWithFiles = 0
			let totalRewardsLinked = 0
			const years = []

			rows.forEach(item => {
				const fileCount = Number(item.SoTapTin) || 0
				if (fileCount > 0) {
					decisionsWithFiles += 1
				}
				totalRewardsLinked += Number(item.SoGiaiThuong) || 0
				if (item.NamQD && Number(item.NamQD) > 0) {
					years.push(Number(item.NamQD))
				}
			})

			const latestYear = years.length > 0 ? Math.max(...years) : "--"

			return {
				totalDecisions,
				decisionsWithFiles,
				totalRewardsLinked,
				latestYear
			}
		}
	},
	mounted() {
		this.initPlatformConfig()
		this.fetchDecisions()
	},
	methods: {
		initPlatformConfig() {
			const platformSet = (window.vueData && window.vueData.v_Set) || {}
			this.vSet = {
				apiFile: platformSet.apiFile || "https://file.lhu.edu.vn/qlnckh/upload/FileData",
				urlReturnFile: platformSet.urlReturnFile || "https://file.lhu.edu.vn/qlnckh"
			}
		},
		async fetchDecisions() {
			const params = { LoaiQD: 1 }
			const res = await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Get_All", params)
			this.tableRows = Array.isArray(res) ? res : []
		},
		openAddModal() {
			this.isEditDecision = false
			this.selectedDecision = {}
			this.isDecisionModalOpen = true
		},
		openEditModal(item) {
			this.isEditDecision = true
			this.selectedDecision = Object.assign({}, item)
			this.isDecisionModalOpen = true
		},
		openFilesModal(item) {
			this.selectedDecision = Object.assign({}, item)
			this.isFilesModalOpen = true
		},
		handleDelete(item) {
			confirm({
				title: `Bạn có chắc muốn xóa quyết định <b><i>${item.MaSoQD || ""}</i></b>?`,
				action: async () => {
					const params = { QDID: item.QDID }
					await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Del", params)
					Vue.$toast.success("Xóa quyết định thành công", { position: "top" })
					this.fetchDecisions()
				}
			})
		}
	}
	}
</script>