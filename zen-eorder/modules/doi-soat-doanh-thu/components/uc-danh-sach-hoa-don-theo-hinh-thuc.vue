<template>
	<v-dialog v-model="isShowDialogDanhSachHoaDonTheoLoai" max-width="800px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<v-toolbar-title class="primary--text">
					{{ cuaHang?.TenCuaHang }} •
					{{ caMap[ca?.Ca] }} •
					{{ LoaiDuLieuMap[loaiDuLieu] }} •
					{{ HinhThucMap[HinhThucThanhToan] }}
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="closeDialog">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-card-title>
			<v-card-text>
				<v-data-table :headers="headers" :items="data" :search="search" dense class="table-doi-soat"
					:footer-props="{ itemsPerPageOptions: [10, 20,50,100]}" fixed-header height="360"
					style="border: thin solid rgba(0, 0, 0, .12);">
					<template v-slot:top>
						<div class="d-flex align-center my-2 px-2">
							<v-toolbar-title class="primary--text ">
								Danh sách hoá đơn
							</v-toolbar-title>

							<v-spacer></v-spacer>

							<v-btn small text @click="exportExcel">
								<v-icon color="primary">mdi-microsoft-excel</v-icon>
							</v-btn>

							<v-text-field v-model="search" label="Mã hoá đơn" prepend-inner-icon="mdi-magnify" dense
								class="elevation-0" hide-details single-line style="max-width: 200px" />
						</div>
					</template>

					<template v-slot:item.NgayXuatHoaDon="{ item }">
						{{moment(item.NgayXuatHoaDon).format('DD/MM/YYYY HH:mm:ss')}}
					</template>

					<template v-slot:item.TienKhachTra="{ item }">
						{{item.TienKhachTra.toLocaleString('vi-VN')}}
					</template>

				</v-data-table>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShowDialogDanhSachHoaDonTheoLoai: Boolean,
			data: Array,
			HinhThucThanhToan: String,
			loaiDuLieu: String,
			ca: Object,
			cuaHang: Object,
		},
		data() {
			return {
				search: null,
				caMap: {
					'1': 'Sáng',
					'2': 'Tối',
					'3': 'Đêm'
				},
				HinhThucMap: {
					'TM': 'Tiền mặt',
					'QT': 'Quẹt thẻ',
					'CK': 'Chuyển khoản',
					'SPF': 'Shoppe Food',
					'GRAB': 'Grab',
					'HUY': 'Huỷ',
					'XSM': 'Xanh SM',
				},
				LoaiDuLieuMap: {
					'DOANH_THU': 'Doanh thu',
					'KET_CA': 'Kết ca'
				},
				headers: [
					{
						text: 'Mã hoá đơn',
						align: 'start',
						value: 'MaHoaDon',
					},
					{
						text: 'Thời gian hoàn tất',
						align: 'center',
						value: 'NgayXuatHoaDon',
					},
					{
						text: 'Tiền khách trả',
						align: 'right',
						value: 'TienKhachTra',
					},
				],
			}
		},
		mounted() {
		},
		computed: {},
		watch: {},
		methods: {
			closeDialog() {
				this.$emit('update:isShowDialogDanhSachHoaDonTheoLoai', false)
			},
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
		},
	}
</script>