<template>
	<v-card elevation="0" class="ma-1" style="border: thin solid rgba(0, 0, 0, .12);">
		<v-card-text class="pa-0">
			<v-data-table fixed-header :headers="headers" :items="data" class="table-log" height="81vh" :search="search"
				dense :items-per-page="50" :footer-props="{ itemsPerPageOptions: [ 50, 100, 200, 350] }">
				<template v-slot:top>
					<div class="d-flex align-center py-2 px-3">
						<div class="primary--text text-left" style="font-weight: 500; font-size: 1.1rem;">Lịch sử
							chuyển khoản</div>
						<v-spacer></v-spacer>
						<v-btn small text @click="exportExcel" elevation="0">
							<v-icon color=" primary">mdi-microsoft-excel</v-icon>
						</v-btn>
						<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" dense elevation="0" hide-details
							style="max-width: 400px" />
					</div>
				</template>
				<template v-slot:item.KhachTra_CK="{ item }">
					{{item.MaHoaDon ? Number(item.KhachTra_CK)?.toLocaleString('vi-VN') : ''}}
				</template>
				<template v-slot:item.Amount="{ item }">
					{{Number(item.Amount)?.toLocaleString('vi-VN')}}
				</template>
				<template v-slot:item.CreateTime="{ item }">
					{{moment(item.CreateTime).format('DD/MM/YYYY HH:mm:ss')}}
				</template>
				<template v-slot:item.actions="{ item }">
					<v-btn text class="pa-0" icon @click='onMapping(item)'>
						<v-icon color="success">mdi-square-edit-outline</v-icon>
					</v-btn>
				</template>
			</v-data-table>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: {
			data: Array,
		},
		data() {
			return {
				search: null,
				headers: [
					{
						text: 'Thời gian',
						value: 'CreateTime',
						width: 200
					},
					{
						text: 'Mã hoá đơn',
						align: 'start',
						value: 'MaHoaDon',
						width: 150
					},
					{
						text: 'Chuyển khoản',
						align: 'start',
						value: 'KhachTra_CK',
						width: 150
					},
					{
						text: 'Tên cửa hàng',
						align: 'start',
						value: 'TenCuaHang',
						width: 150
					},
					{
						text: 'Ngân hàng',
						align: 'start',
						value: 'BankName',
						width: 110
					},
					{
						text: 'Nội dung',
						align: 'start',
						value: 'OrderInfo',
					},
					{
						text: 'Số tiền',
						align: 'start',
						value: 'Amount',
						width: "150px"
					},
					{
						text: 'Liên kết',
						align: 'center',
						value: 'actions',
						width: "100px"
					},
				],
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {
			exportExcel() {
				jsonToExcel({
					filename: "data.xlsx",
					sheets: [
						{
							name: "data",
							data: this.data
						}
					]
				});
			},
	
			onMapping(item) {
				this.$emit('on-mapping', item)
			}
		},
	}
</script>