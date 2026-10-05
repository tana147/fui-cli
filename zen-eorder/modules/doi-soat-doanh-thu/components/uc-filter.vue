<template>
	<div class="page-navigation pa-3 pt-1">
		<div class="primary--text text-left pb-2" style="font-weight: 500; font-size: 1.1rem;">Đối soát doanh thu</div>
		<div>
			<v-row>
				<v-col cols="4">
					<v-select label=" Cửa hàng" outlined dense v-model="CuaHangID" :items="vueData.DSCuaHang"
						hide-details item-value="CuaHangID" item-text="TenCuaHang">
					</v-select>
				</v-col>
				<v-col cols="auto">
					<f-date label="Từ ngày" outlined dense v-model="TuNgayDoiSoat" :date-add="0" hide-details />
				</v-col>
				<v-col cols="auto">
					<f-date label="Đến ngày" outlined dense v-model="DenNgayDoiSoat" :date-add="0" hide-details />
				</v-col>
				<v-col cols="auto">
					<v-select label="Trạng thái đối soát" outlined dense v-model="TrangThaiDoiSoat"
						:items="DSTrangThaiDoiSoat" hide-details item-value="value" item-text="text">
					</v-select>
				</v-col>
				<v-col cols="auto">
					<v-btn color="primary" elevation="0" @click="onSearch">
						<v-icon left>mdi-filter</v-icon>Tìm
					</v-btn>
				</v-col>
				<v-col cols="auto">
					<v-btn color="primary" elevation="0" @click="onDoiSoat">
						<v-icon left>mdi-clipboard-check</v-icon>Thực hiện đối soát
					</v-btn>
				</v-col>
				<v-col cols="auto">
					<v-btn color="primary" elevation="0" @click="onDongBoMulti">
						<v-icon left>mdi-refresh</v-icon>Đồng bộ
					</v-btn>
				</v-col>
				<v-col cols="auto">
					<v-btn color="primary" elevation="0" @click="onExport" style="min-width:0px">
						<v-icon>mdi-microsoft-excel</v-icon>
					</v-btn>
				</v-col>
				<v-col cols="auto">
					<v-btn color="primary" elevation="0" @click="onHistory">
						<v-icon left>mdi-history</v-icon>Lịch sử
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
				TuNgayDoiSoat: null,
				DenNgayDoiSoat: null,
				TrangThaiDoiSoat: 'ALL',
				DSTrangThaiDoiSoat: [
					{ value: "ALL", text: "Tất cả" },
					{ value: "NOT", text: "Chưa đối soát" },
					{ value: "WRONG", text: "Có sai lệch" },
					{ value: "COMPLETED", text: "Đã đối soát" }
				]
			};
		},
		mounted() {
			const now = moment();
			this.TuNgayDoiSoat = now.subtract(1, "days").format("YYYY-MM-DD")
			this.DenNgayDoiSoat = this.TuNgayDoiSoat
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
					TrangThai: this.TrangThaiDoiSoat,
					TuNgayDoiSoat: this.TuNgayDoiSoat,
					DenNgayDoiSoat: this.DenNgayDoiSoat,
				})
			},
			onDoiSoat() {
				this.$emit("doiSoatEmit")
			},
			onExport() {
				this.$emit("exportEmit")
			},
			onHistory() {
				window.open(`https://eorder.zenfoodcourt.vn/lich-su-doi-soat-doanh-thu`, '_blank');
			},
			onDongBoMulti() {
				this.$emit("dongBoMultiEmit")
			}
		}
	}
</script>