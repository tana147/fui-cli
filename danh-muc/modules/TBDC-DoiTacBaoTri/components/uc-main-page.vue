<template>
	<z-layout>
		<uc-top-bar @add-new-emit="onAddNewEmit" @export-execl-emit='onExportEmit'></uc-top-bar>
		<uc-table-doi-tac :data="dataTable" @editEmit='onEmitEdit' :loadData="loadData">
		</uc-table-doi-tac>

		<uc-modal-add v-model:isShow="isShowDialogAdd" :loadData="loadData"></uc-modal-add>
		<uc-modal-edit v-model:isShow="isShowDialogEdit" :selectedItem="selectedItem"
			:loadData="loadData"></uc-modal-edit>
	</z-layout>
</template>

<script>
export default {
	props: [],
	data() {
		return {
			vueData,
			isShowDialogAdd: false,
			isShowDialogEdit: false,
			dataTable: [],
			selectedItem: {}
		}
	},
	mounted() {
		this.loadData()
	},
	computed: {
	},
	watch: {},
	methods: {
		async loadData() {
			const data = await apiCallPromise('work/TS_DoiTacBaoTri_Select')
			this.dataTable = data
		},

		onAddNewEmit() {
			this.isShowDialogAdd = true
		},

		onEmitEdit(item) {
			this.isShowDialogEdit = true
			this.selectedItem = { ...item }
		},
		onExportEmit() {
			jsonToExcel({
				filename: "DanhSachDoiTacBaoTri.xlsx",
				sheets: [
					{
						name: "DanhSachDoiTacBaoTri",
						data: this.dataTable
					}
				]
			});
		},
	},
}
</script>