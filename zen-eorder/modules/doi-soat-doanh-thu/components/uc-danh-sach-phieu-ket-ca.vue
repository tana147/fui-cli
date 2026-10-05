<template>
	<v-dialog v-model="isShowDialogDanhSachPhieuKetCa" max-width="800px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<v-toolbar-title>
					Danh sách phiếu kết ca
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="closeDialog">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-card-title>
			<v-card-text>
				<v-data-table :headers="headers" :items="data" hide-default-footer dense>

					<template v-slot:item.ThoiGianKetCa="{ item }">
						{{item.NgayKetCa_HienThi}} - {{item.GioKetCa_HienThi}}
					</template>

					<template v-slot:item.actions="{ item }">
						<v-btn plain color="primary" @click="XemChiTietPhieuKetCa(item)">Xem chi tiết</v-btn>
					</template>

				</v-data-table>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShowDialogDanhSachPhieuKetCa: Boolean,
			data: Array
		},
		data() {
			return {
				headers: [
					{
						text: 'Nhân viên kết ca',
						align: 'start',
						value: 'NhanVienKetCa',
					},
					{
						text: 'Thời gian kết ca',
						align: 'start',
						value: 'ThoiGianKetCa',
					},
					{
						text: 'Ghi chú kết ca',
						align: 'start',
						value: 'GhiChu',
					},
					{
						text: 'Thao tác',
						align: 'center',
						value: 'actions',
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
				this.$emit('update:isShowDialogDanhSachPhieuKetCa', false)
			},
			XemChiTietPhieuKetCa(item) {
				window.open(`https://eorder.zenfoodcourt.vn/ket-ca-xuat-file?id=${item.KetCaLogID}`, '_blank');
			}
		},
	}
</script>