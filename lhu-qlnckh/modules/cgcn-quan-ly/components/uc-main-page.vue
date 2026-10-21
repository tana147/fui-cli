<template>
	<div class="cgcn-page pa-2">
		<uc-stats :stats-data="statsData" class="mb-2" />

		<uc-main-view
			:table-rows="tableRows"
			@on-add="openAddModal"
			@on-edit="openEditModal"
			@on-delete="handleDelete"
			@on-view-files="openFilesModal"
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
			// 1. Dialog control state
			isAddModalOpen: false,
			isEditModalOpen: false,
			isFileModalOpen: false,

			// 2. API data arrays/objects
			tableRows: [],
			selectedFiles: [],

			// 3. Local state
			editItem: {},
			selectedContractNo: "",
			vSet: {
				apiFile: "",
				urlReturnFile: ""
			}
		}
	},
	computed: {
		statsData() {
			const rows = Array.isArray(this.tableRows) ? this.tableRows : []
			const totalProjects = rows.length
			let totalValue = 0
			let withFilesCount = 0
			const years = []

			rows.forEach(item => {
				totalValue += Number(item.GiaTriHopDong) || 0
				const files = this.parseFileData(item.FileData)
				if (files.length > 0) {
					withFilesCount += 1
				}
				if (item.NamThucHien) {
					years.push(Number(item.NamThucHien))
				}
			})

			const latestYear = years.length > 0 ? Math.max(...years) : "-"

			return {
				totalProjects,
				totalValue,
				withFilesCount,
				latestYear
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
			const data = await ajaxCALLPromise("/ChuyenGiaoCongNghe_Get")
			this.tableRows = Array.isArray(data) ? data : []
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
		handleDelete(item) {
			confirm({
				title: `Bạn có muốn xóa dự án/hợp đồng chuyển giao công nghệ <b><i>${item.TenDuAn || ""}</i></b>?`,
				action: async () => {
					const params = { CGCNID: item.CGCNID }
					await ajaxCALLPromise("/ChuyenGiaoCongNghe_Del", params)
					Vue.$toast.success("Xóa thành công", { position: "top" })
					this.fetchList()
				}
			})
		}
	}
	}
</script>