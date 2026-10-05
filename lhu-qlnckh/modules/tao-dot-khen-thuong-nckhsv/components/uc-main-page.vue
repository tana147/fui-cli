<template>
	<v-card>
		<v-card-title class="d-flex align-center">
			<span class="primary--text">Quản lý đợt khen thưởng nghiên cứu khoa học</span>
			<v-spacer></v-spacer>
			<v-dialog v-model="isShowModalAdd" max-width="600px">
				<template v-slot:activator="{ on, attrs }">
					<v-btn color="success" fab x-small outlined class="mb-2" @click="createItem">
						<v-icon>mdi-plus</v-icon>
					</v-btn>
				</template>
				<v-card>
					<v-card-title>
						<span class="text-h5 primary--text">Thêm mới đợt khen thưởng</span>
						<v-spacer></v-spacer>
						<v-btn fab small icon @click="closeModalCreate">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</v-card-title>
					<v-card-text>
						<v-form ref="formRef" lazy-validation>
							<v-row>
								<v-col cols="4">
									<v-text-field label="Năm học" v-model="formData.NamHoc" outlined hide-details
										dense></v-text-field>
								</v-col>
								<v-col cols="12">
									<v-text-field label="Tên đợt khen thưởng" v-model="formData.TenDot" outlined
										hide-details dense></v-text-field>
								</v-col>
								<v-col cols="12">
									<v-select label="Loại hội đồng" :items="vueData.DSLoaiHoiDong"
										v-model="formData.LoaiHoiDong" item-text="TenLoaiHoiDong" outlined dense
										hide-details item-value="LoaiHoiDongID">
									</v-select>
								</v-col>
							</v-row>
						</v-form>
					</v-card-text>
					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn text @click="closeModalCreate">
							Đóng
						</v-btn>
						<v-btn text color="primary" @click="onAddItem">
							Thêm mới
						</v-btn>
					</v-card-actions>
				</v-card>
			</v-dialog>
		</v-card-title>
		<v-card-text>
			<v-data-table :items="vueData.DSDotKhenThuong" :headers="headers" :items-per-page="50">
				<template v-slot:item.Actions="{ item }">
					<div class="d-flex">
						<v-spacer></v-spacer>
						<v-icon style="font-size:18px" color="red darken-3" small class="mr-2"
							@click="deleteItem(item)">
							mdi-trash-can-outline
						</v-icon>
						<v-icon style="font-size:18px" color="green darken-2" small class="mr-2"
							@click="editItem(item)">
							mdi-square-edit-outline
						</v-icon>
					</div>
				</template>
			</v-data-table>
			<v-dialog v-model="isShowModalEdit" max-width="600px">
				<v-card>
					<v-card-title class="d-flex align-center">
						<span class="primary--text">Cập nhật đợt khen thưởng</span>
						<v-spacer></v-spacer>
						<v-icon @click="CloseModalEdit()">mdi-close</v-icon>
					</v-card-title>
					<v-card-text>
						<v-form ref="formRefEdit" lazy-validation>
							<v-row>
								<v-col cols="4">
									<v-text-field label="Năm học" v-model="record.NamHoc" outlined hide-details
										dense></v-text-field>
								</v-col>
								<v-col cols="12">
									<v-text-field label="Tên đợt khen thưởng" v-model="record.TenDot" outlined
										hide-details dense></v-text-field>
								</v-col>
								<v-col cols="12">
									<v-select label="Loại hội đồng" :items="vueData.DSLoaiHoiDong"
										v-model="record.LoaiHoiDong" item-text="TenLoaiHoiDong" outlined dense
										hide-details item-value="LoaiHoiDongID">
									</v-select>
								</v-col>
							</v-row>
						</v-form>
					</v-card-text>
					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn text @click="CloseModalEdit()">Đóng</v-btn>
						<v-btn text color="primary" @click="onEditItem()">Cập nhật</v-btn>
					</v-card-actions>
				</v-card>
			</v-dialog>
		</v-card-text>
	</v-card>
</template>

<script>
export default {
	props: [],
	data() {
		return {
			vueData,
			isShowModalAdd: false,
			isShowModalEdit: false,
			DSDotKhenThuong: [],
			formData: {
				LoaiHoiDong: 1,
				TenDot: "",
				NamHoc: ""
			},
			record: {},
			headers: [
				{
					text: 'Tên đợt',
					value: 'TenDot'
				},
				{
					text: 'Năm học',
					value: 'NamHoc',
					align: 'center'
				},
				{
					text: 'Loại hội đồng',
					value: 'TenLoaiHoiDong'
				},
				{
					text: 'Thao tác',
					value: 'Actions',
					align: 'center',
					width: '100px'
				},
			],
			items: [],
		}
	},
	mounted() { },
	computed: {
	},
	watch: {},
	methods: {
		closeModalCreate() {
			this.isShowModalAdd = false
			this.$refs.formRef.reset()
		},
		createItem() {
			this.isShowModalAdd = true
		},
		async onAddItem() {
			// const form = this.$refs.formRef
			// let { valid } = await form.validate()
			// if (!valid) return
			let params = { ...this.formData }
			ajaxCALL('/NCKH_Dot_Ins', params, (res) => {
				if (res) {
					this.closeModalCreate()
					this.$refs.formRef.reset()
					Vue.$toast.success("Thêm đợt khen thưởng thành công!", { position: "top" })
					CALL("NCKH_Dot_Get")
				}
			})
		},
		editItem(record) {
			this.record = Object.assign({}, record)
			this.isShowModalEdit = true
		},
		deleteItem(item) {
			const $this = this
			console.log('item', item);
			confirm({
				title: `Bạn có chắc muốn xóa đợt khen thưởng này?`,
				action: async function () {
					ajaxCALL('/NCKH_Dot_Del', {
						DotID: item.DotId
					}, res => {
						CALL("NCKH_Dot_Get")
						Vue.$toast.success("Xóa đợt khen thưởng thành công!", { position: "top" })
					})
				}
			});
		},
		CloseModalEdit() {
			this.isShowModalEdit = false
		},
		async onEditItem() {
			// const form = this.$refs.formRef
			// let { valid } = await form.validate()
			// if (!valid) return
			let params = { ...this.record }
			ajaxCALL('/NCKH_Dot_Upd', params, (res) => {
				if (res) {
					this.CloseModalEdit()
					Vue.$toast.success("Cập nhật đợt khen thưởng!", { position: "top" })
					CALL("NCKH_Dot_Get")
				}
			})
		},
		toExcel() {
			jsonToExcel({ data: vueData.DSDotKhenThuong, filename: "ThongKeBaiBao.xlsx" });
			Vue.$toast.success("Đã xuất Excel", { position: 'top' });
		},

	},
}
</script>