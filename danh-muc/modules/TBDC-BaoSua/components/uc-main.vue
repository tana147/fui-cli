<template>
	<z-layout>
		<uc-top-bar></uc-top-bar>
		<uc-table :DSDiaDiem="DSDiaDiem"></uc-table>
	</z-layout>
</template>

<script>
export default {
	props: [],
	data() {
		return {
			DSDiaDiem: [],

		}
	},
	mounted() {
		this.loadData()
	},
	computed: {},
	watch: {},
	methods: {
		loadData() {
			this.loadDSDiaDiem()
		},

		async loadDSDiaDiem() {
			const data = await apiCallPromise('work/HH_DiaDiem_Select')
			this.DSDiaDiem = data
		},
	},
}
</script>