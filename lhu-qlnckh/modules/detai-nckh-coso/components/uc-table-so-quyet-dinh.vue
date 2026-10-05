<template>
	<div>
		<v-data-table :items="ArrSQD" :headers="headersSQD" class="elevation-1">
			<template v-slot:top>
				<v-toolbar flat>
					<v-toolbar-title>Danh sách số quyết định</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn color="success" @click="openDialog" fab x-small outlined class="mb-2">
						<v-icon>mdi-plus</v-icon>
					</v-btn>
					<v-dialog v-model="dialog" max-width="800px">
						<v-card>
							<v-card-title>
								<span class=" primary--text font-weight-medium">Thêm quyết định cấp kinh phí</span>
								<v-spacer></v-spacer>
								<v-btn fab small icon @click="closeDialog">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text class="mt-3">
								<v-form>
									<v-row dense>
										<v-col cols="5">
											<v-text-field label="Số quyết định" outlined dense
												hide-details></v-text-field>
										</v-col>
										<v-col cols="2">
											<v-text-field label="Ngày QĐ" outlined dense hide-details></v-text-field>
										</v-col>
										<v-col cols="2">
											<v-text-field label="Tháng QĐ" outlined dense hide-details></v-text-field>
										</v-col>
										<v-col cols="3">
											<v-text-field label="Năm QĐ" outlined dense hide-details></v-text-field>
										</v-col>
										<v-col cols="12" class="mt-3">
											<v-textarea rows="2" label="Mô tả quyết định" outlined dense
												hide-details></v-textarea>
										</v-col>
									</v-row>
								</v-form>
								<v-data-table class="elevation-1 mt-3" :items="ArrBaiBao" :headers="headersBaiBao">
									<template v-slot:top>
										<v-toolbar flat>
											<v-toolbar-title>Danh sách đề tài</v-toolbar-title>
											<v-spacer></v-spacer>
											<v-btn color="success" @click="openDialogDeTai" fab x-small outlined class="mb-2">
												<v-icon>mdi-plus</v-icon>
											</v-btn>
										</v-toolbar>
										<v-dialog v-model="dialogDeTai" width="750px">
											<v-card>
												<v-card-title>
													<span class=" primary--text font-weight-medium">Danh sách đề tài chưa có quyết định</span>
													<v-spacer></v-spacer>
													<v-btn fab small icon @click="closeDialogDeTai">
														<v-icon>mdi-close</v-icon>
													</v-btn>
												</v-card-title>
												<v-card-text>
													<v-data-table class="elevation-1" :headers="headersDeTai" :items="DSDeTai" show-select>
													</v-data-table>
												</v-card-text>
												<v-card-actions>
													<v-spacer></v-spacer>
													<v-btn @click="closeDialogDeTai">Đóng</v-btn>
													<v-btn color="primary">Thêm</v-btn>
												</v-card-actions>
											</v-card>
											
										</v-dialog>
									</template>

									<template v-slot:item.actions="{ item }">
										<div style="display:flex; justify-content:center">
											<v-icon style="font-size:18px" color="red darken-3" small class="mr-2">
												mdi-trash-can-outline
											</v-icon>
											<v-icon style="font-size:18px;" color="green darken-2" small class="mr-2">
												mdi-square-edit-outline
											</v-icon>
										</div>
									</template>
								</v-data-table>
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="closeDialog">Đóng</v-btn>
								<v-btn @click="saveSQD" color="primary">{{titleBtn}}</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
				</v-toolbar>
			</template>

			<template v-slot:item.actions="{ item }">
				<div style="display:flex; justify-content:center">
					<v-icon style="font-size:18px" color="red darken-3" small class="mr-2">
						mdi-trash-can-outline
					</v-icon>
					<v-icon style="font-size:18px;" color="green darken-2" small class="mr-2">
						mdi-square-edit-outline
					</v-icon>
				</div>
			</template>
		</v-data-table>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				ArrBaiBao: [],
				DSDeTai:[],
				dialogDeTai:false,
				dialog: false,
				headersSQD: [
					{ text: "Số quyết định", value: "", sortable: false },
					{ text: "Mô tả", value: "", sortable: false },
					{ text: "Ngày,Tháng,Năm QĐ", value: "", sortable: false },
					{ text: "Số bài báo", value: "", sortable: false },
					{ text: "Thao tác", value: "actions", sortable: false, align: "center" }
				],
				headersBaiBao: [
					{ text: "Nhóm đề tài", value: "", sortable: false },
					{ text: "Mã số", value: "", sortable: false },
					{ text: "Tên đề tài", value: "", sortable: false },
					{ text: "Đơn vị", value: "", sortable: false },
					{ text: "Thao tác", value: "actions", sortable: false, align: "center" }
				],
				headersDeTai: [
				{ text: "Nhóm đề tài", value: "", sortable: false },
				{ text: "Mã số", value: "", sortable: false },
				{ text: "Tên đề tài", value: "", sortable: false },
				{ text: "Đơn vị", value: "", sortable: false },
				{ text: "Thao tác", value: "actions", sortable: false, align: "center" }
				],
				ArrSQD: [],
				editedIndex: -1,
			}
		},
		mounted() { },
		computed: {
			titleDialog: function () {
				return this.editedIndex === -1 ? "Thêm quyết định cấp kinh phí" : "Chỉnh sửa quyết định cấp kinh phí"
			},
			titleBtn: function () {
				return this.editedIndex === -1 ? "Thêm" : "Lưu"
			}
		},
		watch: {},
		methods: {
			openDialog() {
				this.dialog = true
			},
			closeDialog() {
				this.dialog = false
			},
			saveSQD() {
				this.closeDialog()
			},
			openDialogDeTai() {
			this.dialogDeTai = true
			},
			closeDialogDeTai() {
			this.dialogDeTai = false
			},
		},
	}
</script>