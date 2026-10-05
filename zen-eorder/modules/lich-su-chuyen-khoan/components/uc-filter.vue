<template>
	<div class="page-navigation">
		<v-row>
			<v-col cols="auto">
				<f-date label="Từ ngày" outlined dense v-model="TuNgay" :date-add="0" hide-details />
			</v-col>
			<v-col cols="auto">
				<f-date label="Đến ngày" outlined dense v-model="DenNgay" :date-add="0" hide-details />
			</v-col>
			<v-col cols="auto">
				<v-btn color="primary" elevation="0" @click="onSearch">
					<v-icon left>mdi-filter</v-icon>Tìm
				</v-btn>
			</v-col>
		</v-row>
	</div>
</template>
<script>
	export default {
		data() {
			return {
				vueData,
				TuNgay: null,
				DenNgay: null
			};
		},
		mounted() {
			const now = moment();
			this.DenNgay = now.format("YYYY-MM-DD")
			this.TuNgay = now.subtract(1, "months").format("YYYY-MM-DD")
			this.onSearch()
		},
		computed: {
		},
		watch: {
		},
		methods: {
			onSearch() {
				this.$emit("filterEmit", {
					TuNgay: this.TuNgay,
					DenNgay: this.DenNgay,
				})
			},
		}
	}
</script>