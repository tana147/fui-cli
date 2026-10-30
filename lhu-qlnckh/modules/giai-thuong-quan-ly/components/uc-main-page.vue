<template>
	<div class="pa-2 gtql-page">
		<uc-stats :stats="statsData" />

		<uc-main-view
			:table-rows="tableRows"
			:list-loai-giai-thuong="listLoaiGiaiThuong"
			:selected-loai-giai-thuong-id="selectedLoaiGiaiThuongId"
			:selected-loai-giai-thuong-name="selectedLoaiGiaiThuongName"
			:is-loading-export="isLoadingExport"
			@on-change-type="handleChangeType"
			@on-add-reward-type="openAddTypeModal"
			@on-add-reward="openAddRewardModal"
			@on-edit-reward="openEditRewardModal"
			@on-delete-reward="handleDeleteReward"
			@on-open-proofs="openProofsModal"
			@on-view-decision="openDecisionDetailModal"
		/>

		<uc-modal-reward-type
			v-model="isAddTypeModalOpen"
			@on-reload="fetchCategories"
		/>

		<uc-modal-reward
			v-model="isRewardModalOpen"
			:is-edit="isEditReward"
			:reward-item="selectedReward"
			:list-loai-giai-thuong="listLoaiGiaiThuong"
			:list-quyet-dinh="listQuyetDinh"
			:default-loai-giai-thuong-id="selectedLoaiGiaiThuongId"
			@on-reload="fetchRewards"
		/>

		<uc-modal-proofs
			v-model="isProofsModalOpen"
			:reward-item="selectedReward"
			:v-set="vSet"
			@on-reload="fetchRewards"
		/>

		<uc-modal-decision-detail
			v-model="isDecisionDetailModalOpen"
			:qdid="selectedDecisionId"
			:v-set="vSet"
		/>
	</div>
</template>

<script>
	export default {
		name: "uc-main-page",
	data() {
		return {
			// 1. Modal control state
			isAddTypeModalOpen: false,
			isRewardModalOpen: false,
			isEditReward: false,
			isProofsModalOpen: false,
			isDecisionDetailModalOpen: false,

			// 2. Data arrays & objects
			listLoaiGiaiThuong: [],
			listQuyetDinh: [],
			tableRows: [],
			selectedReward: {},
			selectedDecisionId: 0,
			selectedLoaiGiaiThuongId: null,

			// 3. Local state
			isLoadingExport: false,
			vSet: {
				apiFile: "",
				urlReturnFile: ""
			}
		}
	},
	computed: {
		selectedLoaiGiaiThuongName() {
			const found = this.listLoaiGiaiThuong.find(
				item => item.LoaiGiaiThuongID === this.selectedLoaiGiaiThuongId
			)
			return found ? found.TenLoaiGiaiThuong : ""
		},
		statsData() {
			const rows = Array.isArray(this.tableRows) ? this.tableRows : []
			const totalRewards = rows.length
			let rewardsWithFiles = 0
			let rewardsWithDecision = 0

			rows.forEach(item => {
				const filesCount = parseInt(item.SoTapTin, 10)
				if (!isNaN(filesCount) && filesCount > 0) {
					rewardsWithFiles += 1
				}
				if (item.QDID && item.QDID > 0) {
					rewardsWithDecision += 1
				}
			})

			return {
				totalRewards,
				rewardsWithFiles,
				rewardsWithDecision,
				totalTypes: this.listLoaiGiaiThuong.length
			}
		}
	},
	mounted() {
		this.initPlatformConfig()
		this.initPageData()
	},
	methods: {
		initPlatformConfig() {
			const platformSet = (window.vueData && window.vueData.v_Set) || {}
			this.vSet = {
				apiFile: platformSet.apiFile || "https://file.lhu.edu.vn/qlnckh/upload/FileData",
				urlReturnFile: platformSet.urlReturnFile || "https://file.lhu.edu.vn/qlnckh"
			}
		},
		async initPageData() {
			await Promise.all([
				this.fetchCategories(),
				this.fetchDecisions()
			])
		},
		async fetchCategories() {
			const res = await ajaxCALLPromise("/LoaiGiaiThuong_Get_All")
			this.listLoaiGiaiThuong = Array.isArray(res) ? res : []
			if (this.listLoaiGiaiThuong.length > 0) {
				const isCurrentValid = this.selectedLoaiGiaiThuongId !== null &&
					this.selectedLoaiGiaiThuongId !== undefined &&
					this.listLoaiGiaiThuong.some(x => x.LoaiGiaiThuongID === this.selectedLoaiGiaiThuongId)
				if (!isCurrentValid) {
					this.selectedLoaiGiaiThuongId = this.listLoaiGiaiThuong[0].LoaiGiaiThuongID
				}
				await this.fetchRewards()
			} else {
				this.tableRows = []
			}
		},
		async fetchDecisions() {
			const params = { LoaiQD: 1 }
			const res = await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Get_Dropdown", params)
			this.listQuyetDinh = Array.isArray(res) ? res : []
		},
		async fetchRewards() {
			if (this.selectedLoaiGiaiThuongId === null || this.selectedLoaiGiaiThuongId === undefined) {
				this.tableRows = []
				return
			}
			const params = { LoaiGiaiThuongID: this.selectedLoaiGiaiThuongId }
			const res = await ajaxCALLPromise("/GiaiThuong_Get_ByLoaiGiaiThuongID", params)
			this.tableRows = Array.isArray(res) ? res : []
		},
		handleChangeType(typeId) {
			this.selectedLoaiGiaiThuongId = typeId
			this.fetchRewards()
		},
		openAddTypeModal() {
			this.isAddTypeModalOpen = true
		},
		openAddRewardModal() {
			this.isEditReward = false
			this.selectedReward = {}
			this.isRewardModalOpen = true
		},
		openEditRewardModal(item) {
			this.isEditReward = true
			this.selectedReward = Object.assign({}, item)
			this.isRewardModalOpen = true
		},
		handleDeleteReward(item) {
			confirm({
				title: `Bạn có chắc muốn xóa giải thưởng <b><i>${item.TenDeTai || ""}</i></b>?`,
				action: async () => {
					const params = { GiaiThuongID: item.GiaiThuongID }
					await ajaxCALLPromise("/GiaiThuong_Del", params)
					Vue.$toast.success("Xóa giải thưởng thành công", { position: "top" })
					this.fetchRewards()
				}
			})
		},
		openProofsModal(item) {
			this.selectedReward = Object.assign({}, item)
			this.isProofsModalOpen = true
		},
		openDecisionDetailModal(item) {
			this.selectedDecisionId = item.QDID
			this.isDecisionDetailModalOpen = true
		}
	}
	}
</script>