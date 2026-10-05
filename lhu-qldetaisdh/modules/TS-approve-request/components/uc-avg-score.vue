<template>
	<div>
		<v-text-field class="uc-ar-score-field mb-3 mt-1" color="success" outlined dense v-model="item.Text_Content"
			:hint="item.Data_Exp" hide-details disabled />
	</div>
</template>

<script>
	export default {
		name: "uc-avg-score",
		props: {
			detaiprocess: { type: Array, default: () => [] },
			item: { type: Object, default: () => ({}) }
		},
		data() {
			return {}
		},
		mounted() { },
		computed: {
			detaiProcess: function () {
				return this.detaiprocess
			},
			result() {
				const arr = this.detaiProcess
					.map(detail => (detail.Task_Detail_Type === 'DIEM' ? parseFloat(detail.Text_Content) : null))
					.filter(item => item !== null && !isNaN(item));
	
				const sum = arr.reduce((acc, val) => acc + val, 0);
				const avg = arr.length > 0 ? sum / arr.length : 0;
				return avg;
			}
		},
		watch: {
			result(newResult) {
				this.item.Text_Content = newResult.toFixed(2);
			},
		},
		methods: {},
	}
</script>