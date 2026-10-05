<template>
	<div>
		<uc-filter @filterEmit='onSearch'></uc-filter>
		<uc-table :data="dataTable" @viewDetail='handleViewDetail'></uc-table>
		<uc-xem-chi-tiet :isShowDialogViewDetail="isShowDialogViewDetail"
			@update:isShowDialogViewDetail="isShowDialogViewDetail = $event" :item="selectedItem"></uc-xem-chi-tiet>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				vueData,
				filter: null,
				dataTable: [],
				isShowDialogViewDetail: false,
				selectedItem: {}
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {
			onSearch(filter) {
				this.filter = filter
				this.loadData()
			},
			async loadData() {
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_Select_Log', this.filter)
				this.dataTable = data
			},
			handleViewDetail(item) {
				this.selectedItem = item
				this.isShowDialogViewDetail = true
				console.log(item)
			}
		},
	}
</script>