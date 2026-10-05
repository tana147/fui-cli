<template>
	<v-card elevation="0" class="ma-1" style="border: thin solid rgba(0, 0, 0, .12);">
		<v-card-text class=" pa-0">
			<v-data-table fixed-header :headers="headers" :items="data" class="table-log"
				style="height: calc(100vh - 102px);" :search='search' dense :items-per-page="50"
				:footer-props="{ itemsPerPageOptions: [15,50,100]}">

				<template v-slot:top>
					<div class="d-flex align-center mb-2 pt-3">
						<v-spacer></v-spacer>

						<v-btn small text @click="exportExcel" elevation="0">
							<v-icon color=" primary">mdi-microsoft-excel</v-icon>
						</v-btn>

						<v-text-field v-model="search" label="Từ khoá" prepend-inner-icon="mdi-magnify" dense
							elevation="0" hide-details style="max-width: 400px" />
					</div>
				</template>

				<template v-slot:item.NhanVienCapNhat="{ item }">
					{{item.NhanVienCapNhat}} - {{item.TenNhanVienCapNhat}}
				</template>

				<template v-slot:item.Ca="{ item }">
					{{caMap[item.Ca]}}
				</template>

				<template v-slot:item.BackupTime="{ item }">
					{{moment(item.BackupTime).format('DD/MM/YYYY HH:MM:SS')}}
				</template>

				<template v-slot:item.NgayDoiSoat="{ item }">
					{{moment(item.NgayDoiSoat).format('DD/MM/YYYY')}}
				</template>

				<template v-slot:item.actions="{ item }">
					<v-btn text class="pa-0" icon @click='viewDetail(item)'>
						<v-icon color="success">mdi-eye</v-icon>
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
						text: 'Tên cửa hàng',
						align: 'start',
						value: 'TenCuaHang',
					},
					{
						text: 'Ngày đối soát',
						align: 'start',
						value: 'NgayDoiSoat',
					},
					{
						text: 'Ca làm việc',
						align: 'start',
						value: 'Ca',
					},
					{
						text: 'Giờ cập nhật',
						align: 'center',
						value: 'BackupTime',
					},
					{
						text: 'Người cập nhật',
						align: 'center',
						value: 'NhanVienCapNhat',
					},
					{
						text: 'Ghi chú',
						align: 'center',
						value: 'GhiChuDoiSoat',
					},
					{
						text: 'Thao tác',
						align: 'center',
						value: 'actions',
					},
				],
				trangThaiMap: {
					'NOT': 'Chưa đối soát',
					'WRONG': 'Có sai lệch',
					'COMPLETED': 'Đã đối soát'
				},
				caMap: {
					'1': 'Sáng',
					'2': 'Tối',
					'3': 'Đêm'
				}
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
			viewDetail(item) {
				this.$emit('viewDetail', item)
			}
		},
	}
</script>