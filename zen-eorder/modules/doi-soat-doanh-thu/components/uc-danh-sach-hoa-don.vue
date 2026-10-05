<template>
	<v-dialog v-model="isShowDialogDanhSachHoaDon" max-width="1200px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<v-toolbar-title class="primary--text">
					{{cuaHang?.TenCuaHang}} • {{ caMap[ca?.Ca]}} • {{ LoaiDuLieuMap[loaiDuLieu] }}
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="closeDialog"><v-icon>mdi-close</v-icon></v-btn>
			</v-card-title>
			<v-card-text>
				<v-data-table dense :headers="headers" :items="data" :search='search'  class="table-doi-soat"
					:footer-props="{ itemsPerPageOptions: [10, 20,50,100]}" fixed-header height="360"
					style="border: thin solid rgba(0, 0, 0, .12);">
					<template v-slot:top>
						<div class="d-flex align-center my-2 px-2">
							<v-toolbar-title class="primary--text ">
								Danh sách hoá đơn
							</v-toolbar-title>

							<v-spacer></v-spacer>

							<v-btn small text @click="exportExcel" elevation="0">
								<v-icon color=" primary">mdi-microsoft-excel</v-icon>
							</v-btn>

							<v-text-field v-model="search" label="Mã hoá đơn" prepend-inner-icon="mdi-magnify" dense
								elevation="0" hide-details style="max-width: 200px" />
						</div>
					</template>

					<template v-slot:item.NgayXuatHoaDon="{ item }">
						{{moment(item.NgayXuatHoaDon).format('DD/MM/YYYY HH:MM:SS')}}
					</template>

					<template v-slot:item.TienKhachTra="{ item }">
						{{item.TienKhachTra.toLocaleString('vi-VN')}}
					</template>

					<template v-slot:item.KhachTra_TienMat="{ item }">
						{{item.KhachTra_TienMat.toLocaleString('vi-VN')}}
					</template>

					<template v-slot:item.KhachTra_CK="{ item }">
						{{item.KhachTra_CK.toLocaleString('vi-VN')}}
					</template>

					<template v-slot:item.KhachTra_SPF="{ item }">
						{{item.KhachTra_SPF.toLocaleString('vi-VN')}}
					</template>

					<template v-slot:item.KhachTra_GRAB="{ item }">
						{{item.KhachTra_GRAB.toLocaleString('vi-VN')}}
					</template>

					<template v-slot:item.KhachTra_QT="{ item }">
						{{item.KhachTra_QT.toLocaleString('vi-VN')}}
					</template>

					<template v-slot:item.TenTrangThai="{ item }">
						<v-chip :color="item.MauTrangThai" small>{{item.TenTrangThai}}</v-chip>
					</template>

				</v-data-table>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShowDialogDanhSachHoaDon: Boolean,
			data: Array,
			ca: Object,
			cuaHang: Object,
			loaiDuLieu: String,
		},
		data() {
			return {
				search: null,
				LoaiDuLieuMap: {
					'DOANH_THU': 'Doanh thu',
					'KET_CA': 'Kết ca'
				},
				caMap: {
					'1': 'Sáng',
					'2': 'Tối',
					'3': 'Đêm'
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
						align: 'end',
						value: 'TienKhachTra',
					},
					{
						text: 'Tiền mặt',
						align: 'end',
						value: 'KhachTra_TienMat',
					},
					{
						text: 'CK',
						align: 'end',
						value: 'KhachTra_CK',
					},
					{
						text: 'SPF',
						align: 'end',
						value: 'KhachTra_SPF',
					},
					{
						text: 'Grab',
						align: 'end',
						value: 'KhachTra_GRAB',
					},
					{
						text: 'Quẹt thẻ',
						align: 'end',
						value: 'KhachTra_QT',
					},
					{
						text: 'Tên trạng thái',
						align: 'center',
						value: 'TenTrangThai',
					},
					{
						text: 'Ghi chú',
						align: 'left',
						value: 'GhiChu',
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
				this.$emit('update:isShowDialogDanhSachHoaDon', false)
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