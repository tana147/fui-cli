<template>
	<v-data-table :headers="headers" :items="DSAnPhamToTrinh" class="elevation-2 align-center">
		<template v-slot:top>
			<v-toolbar flat>
				<v-toolbar-title class="primary--text font-weight-medium">
					Danh sách ấn phẩm được khen thưởng
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-dialog v-model="dialog" max-width="1368px">
					<template v-slot:activator="{ on, attrs }">
						<v-btn @click="add_anPham" color="success" fab x-small outlined class="mb-2">
							<v-icon>mdi-plus</v-icon>
						</v-btn>
					</template>
					<v-card>
						<v-card-title class="mb-5">
							<span class="text-h5 primary--text ">Danh sách ấn phẩm chưa có quyết định khen{{" "}}
								thưởng</span>
							<v-spacer></v-spacer>
							<v-btn fab small icon @click="close">
								<v-icon>mdi-close</v-icon>
							</v-btn>
						</v-card-title>
						<v-card-text>
							<uc-table-an-pham-chua-khen-thuong v-model="value" :dsanphamchuacoquyetdinh="DSAnPham"
								ref="clickToReceivedAnPham">
							</uc-table-an-pham-chua-khen-thuong>
						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="close">Đóng</v-btn>
							<v-btn class="ml-2" color="primary" @click="save">Thêm</v-btn>
						</v-card-actions>
					</v-card>

				</v-dialog>
			</v-toolbar>
		</template>
		<template v-slot:item.actions="{ item }">
			<v-icon style="font-size:18px" @click="deleteItem(item)" color="red darken-3" small class="mr-2">
				mdi-trash-can-outline
			</v-icon>
		</template>
	</v-data-table>
</template>

<script>
	export default {
		props: ["value", "dsanphamchuakhenthuong", "soqd"],
		data() {
			return {
				dialog: false,
				headers: [
					{ text: 'STT', sortable: false, value: "STT", align: 'center' },
					{ text: 'Tên ấn phẩm', sortable: false, value: "TenAnPham", },
					{ text: 'Tác giả', sortable: false, value: "TacGia", },
					{ text: 'Tên tạp chí', sortable: false, value: "TenTapChi" },
					{ text: 'Năm đăng', sortable: false, value: "NamDangBai", width: "100", align: 'center' },
					{ text: 'Nơi đăng', sortable: false, value: "NoiDangBai", width: "120" },
					{ text: 'Thao tác', sortable: false, value: "actions", width: "100", align: 'center' },
				],
			}
		},
		mounted() {
	
		},
		computed: {
			DSAnPham: function () {
				return this.dsanphamchuakhenthuong
			},
			DSAnPhamToTrinh: function () {
				return this.value
			},
			SoQuyetDinh: function () {
				return this.soqd
			}
		},
		watch: {
			dialog(val) {
				val || this.close()
			},
		},
		methods: {
			add_anPham() {
				if (this.SoQuyetDinh !== null || this.SoQuyetDinh === "") {
	
					return Vue.$toast.warning("Không thể thực hiện thao tác khi đã ra quyết định khen thưởng", { position: "top" })
				}
				this.dialog = true
			},
			close() {
				this.dialog = false
			},
			save() {
				this.$refs.clickToReceivedAnPham.save()
				this.$emit("input", this.value)
				this.close()
			},
			deleteItem(item) {
				if (this.SoQuyetDinh !== null || this.SoQuyetDinh === "") {
					return Vue.$toast.warning("Không thể thực hiện thao tác khi đã ra quyết định khen thưởng", { position: "top" })
				}
				this.value.splice(this.value.indexOf(item), 1)
			},
		},
	}
</script>