<template>
	<div>
		<uc-filter @filterEmit='onSearch'></uc-filter>
		<uc-table :data="dataTable" @on-mapping='handleMapping'></uc-table>
		<uc-mapping :isShowDialogMapping="isShowDialogMapping"
			@update:isShowDialogMapping="isShowDialogMapping = $event" :item="selectedItem"></uc-mapping>
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
				isShowDialogMapping: false,
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
				const data = await this.vueData.ajaxCALLPromise('/eorder/HoaDon_Bank_Select_Log', this.filter)
				this.dataTable = data
			},
			handleMapping(item) {
				this.selectedItem = { ...item }
				this.isShowDialogMapping = true
			}
		},
	}
</script>