<template>
	<div class="page-navigation pa-3 pt-1">
		<div class="primary--text text-left pb-2" style="font-weight: 500; font-size: 1.1rem;">Lịch sử đối soát doanh
			thu</div>
		<div>
			<v-row>
				<v-col cols="3">
					<v-select label="Cửa hàng" outlined dense v-model="CuaHangID" :items="vueData.DSCuaHang"
						hide-details item-value="CuaHangID" item-text="TenCuaHang">
					</v-select>
				</v-col>

				<v-col cols="auto">
					<v-btn color="primary" elevation="0" @click="onSearch">
						<v-icon left>mdi-filter</v-icon>Tìm
					</v-btn>
				</v-col>
			</v-row>
		</div>
	</div>
</template>
<script>
	export default {
		data() {
			return {
				vueData,
				CuaHangID: 0,
			};
		},
		mounted() {
			this.onSearch()
		},
		computed: {
		},
		watch: {
		},
		methods: {
			onSearch() {
				this.$emit("filterEmit", {
					CuaHangID: this.CuaHangID,
				})
			},
		}
	}
</script>