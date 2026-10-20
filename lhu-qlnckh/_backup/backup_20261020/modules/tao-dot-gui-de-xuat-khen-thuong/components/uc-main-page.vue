<template>
	<v-card>
		<v-card-title class="d-flex align-center">
			<span class="text-primary">Tạo đợt đề xuất khen thưởng</span>
			<v-spacer></v-spacer>
			<v-dialog v-model="isShowModalAdd" max-width="800px">
				<template v-slot:activator="{ on, attrs }">
					<v-btn color="success" fab x-small outlined class="mb-2" @click="createItem">
						<v-icon>mdi-plus</v-icon>
					</v-btn>
				</template>
				<v-card>
					<v-card-title>
						<span class="text-h5 primary--text">Thêm mới đợt đề xuất khen thưởng</span>
						<v-spacer></v-spacer>
						<v-btn fab small icon @click="closeModalCreate">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</v-card-title>
					<v-card-text>
						<v-form ref="formRef" lazy-validation>
							<v-row>
								<v-col cols="9">
									<v-text-field label="Tên đợt đề xuất khen thưởng" v-model="formData.TenDot" outlined
										hide-details dense />
								</v-col>
								<v-col cols="3">
									<v-text-field label="Niên khóa" v-model="formData.NienKhoa" outlined hide-details
										dense />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Nội dung thông báo" v-model="formData.ThongBao" outlined
										hide-details dense />
								</v-col>
								<v-col cols="6">
									<v-menu v-model="menu" :close-on-content-click="false" :nudge-right="40"
										transition="scale-transition" offset-y min-width="auto">
										<template v-slot:activator="{ on, attrs }">
											<v-text-field v-model="formData.ThoiGianBatDau" label="Ngày bắt đầu"
												prepend-inner-icon="mdi-calendar" readonly v-bind="attrs" v-on="on"
												outlined hide-details dense />
										</template>
										<v-date-picker v-model="formData.ThoiGianBatDau"
											@input="menu = false"></v-date-picker>
									</v-menu>
								</v-col>
								<v-col cols="6">


									<v-menu v-model="menuDatePickerKetThuc" :close-on-content-click="false"
										:nudge-right="40" transition="scale-transition" offset-y min-width="auto">
										<template v-slot:activator="{ on, attrs }">
											<v-text-field v-model="formData.ThoiGianKetThuc" label="Ngày bắt đầu"
												prepend-inner-icon="mdi-calendar" readonly v-bind="attrs" v-on="on"
												outlined hide-details dense />
										</template>
										<v-date-picker v-model="formData.ThoiGianKetThuc"
											@input="menuDatePickerKetThuc = false"></v-date-picker>
									</v-menu>
								</v-col>
								<v-col cols="3">
									<v-select label="Tình trạng" :items="DSTinhTrang" item-text="text"
										item-value="value" v-model="formData.TinhTrang" outlined dense hide-details>
									</v-select>
								</v-col>
								<v-col cols="12">
									<f-file-upload v-model="formData.FileHuongDan" class=" mr-4 mobile-f-file-upload"
										label="Upload FILE" :url="vueData.v_Set.apiFile" color="white"
										@input="(value) => uploadFileHuongDan(value)" />
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
			<v-data-table :items="vueData.DSDotDeXuat" :headers="headers" :items-per-page="50">
				<template v-slot:item.TinhTrang="{ item }">
					<v-chip outlined color="red" v-if="item.TinhTrang === 0">Đã đóng</v-chip>
					<v-chip outlined color="green" v-else>Đang mở</v-chip>
				</template>
				<template v-slot:item.ThoiGianBatDau="{ item }">
					<span v-if="item.ThoiGianBatDau">{{ item.ThoiGianBatDau?.split("T")[0] }}</span>
				</template>
				<template v-slot:item.ThoiGianKetThuc="{ item }">
					<span v-if="item.ThoiGianKetThuc">{{ item.ThoiGianKetThuc?.split("T")[0] }}</span>
				</template>
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
			<v-dialog v-model="isShowModalEdit" max-width="800px">
				<v-card>
					<v-card-title class="d-flex align-center">
						<span class="primary--text">Cập nhật đợt khen thưởng</span>
						<v-spacer></v-spacer>
						<v-icon @click="CloseModalEdit()">mdi-close</v-icon>
					</v-card-title>
					<v-card-text>
						<v-form ref="formRefEdit" lazy-validation>
							<v-row>
								<v-col cols="9">
									<v-text-field label="Tên đợt đề xuất khen thưởng" v-model="record.TenDot" outlined
										hide-details dense />
								</v-col>
								<v-col cols="3">
									<v-text-field label="Niên khóa" v-model="record.NienKhoa" outlined hide-details
										dense />
								</v-col>
								<v-col cols="12">
									<v-text-field label="Nội dung thông báo" v-model="record.ThongBao" outlined
										hide-details dense />
								</v-col>
								<v-col cols="6">
									<v-menu v-model="menuEdit" :close-on-content-click="false" :nudge-right="40"
										transition="scale-transition" offset-y min-width="auto">
										<template v-slot:activator="{ on, attrs }">
											<v-text-field v-model="record.ThoiGianBatDau" label="Ngày bắt đầu"
												prepend-inner-icon="mdi-calendar" readonly v-bind="attrs" v-on="on"
												outlined hide-details dense />
										</template>
										<v-date-picker v-model="record.ThoiGianBatDau"
											@input="menu = false"></v-date-picker>
									</v-menu>

								</v-col>
								<v-col cols="6">


									<v-menu v-model="menuDatePickerKetThucEdit" :close-on-content-click="false"
										:nudge-right="40" transition="scale-transition" offset-y min-width="auto">
										<template v-slot:activator="{ on, attrs }">
											<v-text-field v-model="record.ThoiGianKetThuc" label="Ngày bắt đầu"
												prepend-inner-icon="mdi-calendar" readonly v-bind="attrs" v-on="on"
												outlined hide-details dense />
										</template>
										<v-date-picker v-model="record.ThoiGianKetThuc"
											@input="menuDatePickerKetThuc = false"></v-date-picker>
									</v-menu>


								</v-col>
								<v-col cols="3">
									<v-select label="Tình trạng" :items="DSTinhTrang" item-text="text"
										item-value="value" v-model="record.TinhTrang" outlined dense hide-details>
									</v-select>
								</v-col>
								<v-col cols="12">
									<f-file-upload v-model="record.FileHuongDan" class=" mr-4 mobile-f-file-upload"
										label="Upload FILE" :url="vueData.v_Set.apiFile" color="white"
										@input="(value) => uploadFileHuongDan(value)" />
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
			menu: false,
			menuDatePickerKetThuc: false,
			menuEdit: false,
			menuDatePickerKetThucEdit: false,
			isShowModalAdd: false,
			isShowModalEdit: false,
			DSDotKhenThuong: [],
			DSTinhTrang: [
				{
					text: 'Đã đóng',
					value: 0
				},
				{
					text: 'Đang mở',
					value: 1
				}
			],
			formData: {
				TenDot: "",
				TinhTrang: null,
				NienKhoa: "",
				ThoiGianBatDau: null,
				ThoiGianKetThuc: null,
				ThongBao: "",
				FileHuongDan: "",
			},
			record: {},
			headers: [
				{
					text: 'Tên đợt',
					value: 'TenDot'
				},
				{
					text: 'Niên khóa',
					value: 'NienKhoa'
				},
				{
					text: 'Ngày bắt đầu',
					value: 'ThoiGianBatDau'
				},
				{
					text: 'Ngày kết thúc',
					value: 'ThoiGianKetThuc'
				},
				{
					text: 'Tình trạng',
					value: 'TinhTrang',
					key: "TinhTrang"
				},
				{
					text: 'Thông báo',
					value: 'ThongBao'
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
		uploadFileHuongDan(value) {
			let file = value.Files[0]
			this.formData.FileHuongDan = file.FILE_ID
			// this.formData.FileUrLAnPham = file.FILE_URL
			// this.formData.FileNameAnPham = file.FILE_NAME
		},
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
			ajaxCALL('/AnPham_Dot_Ins', params, (res) => {
				if (res) {
					this.closeModalCreate()
					this.$refs.formRef.reset()
					Vue.$toast.success("Thêm đợt đề xuất khen thưởng thành công!", { position: "top" })
					CALL("AnPham_Dot_Get")
				}
			})
		},
		editItem(record) {
			this.record = Object.assign({}, record)
			this.record.ThoiGianBatDau = this.record.ThoiGianBatDau ? this.record.ThoiGianBatDau.split("T")[0] : this.record.ThoiGianBatDau;
			this.record.ThoiGianKetThuc = this.record.ThoiGianKetThuc ? this.record.ThoiGianKetThuc.split("T")[0] : this.record.ThoiGianKetThuc;
			this.isShowModalEdit = true
		},
		deleteItem(item) {
			const $this = this
			console.log('item', item);
			confirm({
				title: `Bạn có chắc muốn xóa đợt khen thưởng này?`,
				action: async function () {
					ajaxCALL('/AnPham_Dot_Del', {
						AnPham_DotID: item.AnPham_DotID
					}, res => {
						CALL("AnPham_Dot_Get")
						Vue.$toast.success("Xóa đợt đề xuất khen thưởng thành công!", { position: "top" })
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
			ajaxCALL('/AnPham_Dot_Upd', params, (res) => {
				if (res) {
					this.CloseModalEdit()
					Vue.$toast.success("Cập nhật đợt đề xuất khen thưởng!", { position: "top" })
					CALL("AnPham_Dot_Get")
				}
			})
		}

	},
}
</script>