<template>
	<v-dialog v-model="isShowDialogChuyenKhoanThucTe" max-width="700px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<v-row>
					<v-col cols="auto">
						<f-date label="Từ ngày" outlined dense v-model="TuNgay" :date-add="0" hide-details />
					</v-col>
					<v-col cols="auto">
						<f-date label="Đến ngày" outlined dense v-model="DenNgay" :date-add="0" hide-details />
					</v-col>
					<v-col cols="auto">
						<v-btn color="primary" elevation="0" @click="loadData">
							<v-icon left>mdi-filter</v-icon>Tìm
						</v-btn>
					</v-col>
					<v-spacer></v-spacer>
					<v-col cols="auto">
						<v-btn icon @click="closeDialog">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</v-col>
				</v-row>
			</v-card-title>
			<v-card-text>
				<v-data-table dense :headers="headers" :items="dataTable" :search='search' class="table-doi-soat"
					:footer-props="{ itemsPerPageOptions: [10, 20] }" fixed-header height="360" disable-sort
					style="border: thin solid rgba(0, 0, 0, .12);">
					<template v-slot:top>
						<div class="d-flex align-center mt-3 px-2 ">
							<v-toolbar-title class="primary--text ">
								Chuyển khoản thực tế
							</v-toolbar-title>
							<v-spacer></v-spacer>
							<v-btn small text @click="exportExcel" elevation="0">
								<v-icon color=" primary">mdi-microsoft-excel</v-icon>
							</v-btn>
							<v-text-field v-model="search" label="Ngày" prepend-inner-icon="mdi-magnify" dense
								elevation="0" hide-details style="max-width: 200px" />
							<v-btn fab x-small outlined class="ml-3 primary--text" @click="onAdd">
								<v-icon size="18">
									mdi-plus
								</v-icon>
							</v-btn>
						</div>
					</template>

					<template v-slot:item.GiaTri="{ item }">
						{{ item.GiaTri.toLocaleString('vi-VN') }}
					</template>

					<template v-slot:item.actions="{ item }">
						<v-btn icon small @click="onDelete(item)" x-small fab>
							<v-icon small color="error">mdi-trash-can-outline</v-icon>
						</v-btn>

						<v-btn @click="onEdit(item)" x-small fab icon>
							<v-icon color="green darken-2">mdi-square-edit-outline</v-icon>
						</v-btn>
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>

		<!-- dialog -->
		<v-dialog v-model="isShow" max-width="400">
			<v-card>
				<v-card-title style="padding: 12px 12px 0px 12px">
					<v-toolbar-title class="primary--text">
						{{ item.isAdd === true ? 'Thêm mới' : 'Cập nhật' }}
					</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon @click="closeDialogChild">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<v-card-text>
					<v-form ref="form">
						<v-row>
							<v-col cols='6'>
								<f-date v-if="isShow" label="Ngày" v-model="item.Ngay" outlined dense hide-details />
							</v-col>
							<v-col cols='6'>
								<v-text-field label="Số tiền" v-model="item.GiaTri" type="number" outlined dense
									:rules="[v => !!v || 'Không được để trống']" hide-details />
							</v-col>
						</v-row>
					</v-form>
				</v-card-text>

				<v-card-actions>
					<v-spacer />
					<v-btn color="primary" @click="onSubmit">{{ item.isAdd === true ? 'Thêm' : 'Lưu' }}</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShowDialogChuyenKhoanThucTe: Boolean,
	},
	data() {
		return {
			vueData,
			search: null,
			TuNgay: null,
			DenNgay: null,
			isShow: false,
			item: {},
			dataTable: [],
			headers: [
				{
					text: 'Ngày',
					align: 'start',
					value: 'NgayHienThi',
				},
				{
					text: 'Số tiền',
					align: 'end',
					value: 'GiaTri',
				},
				{
					text: "",
					value: "actions",
					align: "center",
					width: 100,
					sortable: false,
				},
			],
		}
	},
	mounted() {
		this.TuNgay = moment().startOf('month').format('YYYY-MM-DD')
		this.DenNgay = moment().format('YYYY-MM-DD')
		this.loadData()
	},
	computed: {
	},
	watch: {
	},
	methods: {
		closeDialog() {
			this.$emit('update:isShowDialogChuyenKhoanThucTe', false)
		},

		async loadData() {
			const params = {
				TuNgay: this.TuNgay,
				DenNgay: this.DenNgay
			}
			const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatChuyenKhoan_Select', params)
			this.dataTable = data
		},

		exportExcel() {
			jsonToExcel({
				filename: "data.xlsx",
				sheets: [
					{
						name: "data",
						data: this.dataTable
					}
				]
			});
		},
		onAdd() {
			this.isShow = true
			this.item.isAdd = true
		},
		onEdit(item) {
			this.item = { ...item }
			this.item.isAdd = false
			this.isShow = true
		},

		async onDelete(item) {
			const params = {
				DoiSoat_ChuyenKhoanID: item.DoiSoat_ChuyenKhoanID,
			}
			const $this = this
			confirm({
				title: `<b>Xác nhận</b>`,
				message: `Xoá tiền chuyển khoản thực tế của ngày: <b>${item.NgayHienThi} </b>`,
				action: function () {
					ajaxCALL("/eorder/DoiSoatChuyenKhoan_Delete", params, (res) => {
						showToast({ type: "green", title: "Xoá tiền chuyển khoản thực tế thành công!" })
						$this.loadData()
					})
				},
			})
		},

		async onSubmit() {
			const valid = this.$refs.form.validate()
			if (!valid) {
				Vue.$toast.info('Vui lòng nhập đầy đủ thông tin', { position: "top" })
				return
			}
			const params = {
				Ngay: this.item.Ngay,
				GiaTri: this.item.GiaTri,
				DoiSoat_ChuyenKhoanID: this.item.isAdd === true ? 0 : this.item.DoiSoat_ChuyenKhoanID,
			}
			const url = this.item.isAdd === true ? "DoiSoatChuyenKhoan_Insert" : "DoiSoatChuyenKhoan_Update"
			const data = await this.vueData.ajaxCALLPromise(`/eorder/${url}`, params)
			if (data)
				Vue.$toast.success("Thành công", { position: "top" });
			else
				Vue.$toast.error("Thất bại", { position: "top" });
			this.loadData()
			this.closeDialogChild()
		},

		closeDialogChild() {
			this.$refs.form.resetValidation()
			this.$refs.form.reset()
			this.isShow = false
			this.item = {}
		}
	},
}
</script>