<template>
	<v-card elevation="2" class="px-2"
		style="border-radius: 12px; box-shadow: rgba(0, 0, 0, 0.1) 0px 1px 1px; height:  height: 650px; ">
		<!-- <v-card-title class="ml-0 pl-0 text- font-weight-bold"> -->
		<div class="d-flex mt-3 mb-3 text-primary">
			<v-badge inline class="" :content="value.length" color="red">
				<h4 style="" class="mr-2">Báo sửa mới</h4>
			</v-badge>
		</div>
		<v-virtual-scroll :items="value" height="650">
			<template v-slot:default="{ item }">
				<uc-baosua :priority="item.DoUuTien" :priorityname="item.TenDoUuTien" :key="item.MaBaoSua"
					:title="item.TenTaiSan" :department="item.TenViTriPhong" :note="item.GhiChu"
					:product="item.TenDanhMuc" :requestId="item.MaBaoSua" :user="item.HoTenNguoiBaoSua"
					:userid="item.CreateUser" :statusText="item.TenTinhTrang" :statusID="item.MaTinhTrang"
					:statuscolor="'green'" :timeAgo="item.TGBaoSua" @task-click="showTaskDetail(item)">

				</uc-baosua>
				<!-- <v-divider></v-divider> -->
			</template>
		</v-virtual-scroll>

		<!-- <uc-chi-tiet-sua-chua @update="reloadData()" ref="chiTietBaoSua"></uc-chi-tiet-sua-chua> -->
		<v-dialog v-model="dialogHinhAnh" max-width="500px">
			<v-card>
				<v-toolbar color="primary">
					<v-toolbar-title>Hình ảnh tài sản</v-toolbar-title>

					<v-btn icon="mdi-close" @click="dialogHinhAnh = false"></v-btn>
				</v-toolbar>

				<v-divider></v-divider>
				<v-card-text class="text-center">
					<v-img v-if="hinhDinhKem" :src="`data:image/png;base64,` + hinhDinhKem" contain></v-img>
					<div v-else class="text-grey">Không có hình ảnh</div>
				</v-card-text>

			</v-card>
		</v-dialog>

		<v-dialog v-model="acceptDialog" max-width="450px">
			<v-card class="custom-card">
				<v-card-title class="text-h6 font-weight-bold">Xác nhận tiếp nhận</v-card-title>

				<v-divider></v-divider>

				<v-card-text class="pa-4">
					<v-textarea v-model="note" label="Ghi chú (nếu có)" outlined rows="3">
					</v-textarea>
				</v-card-text>

				<v-divider></v-divider>

				<v-card-actions class="pa-4">
					<v-spacer></v-spacer>
					<v-btn class="text-grey-lighten-1" outlined @click="acceptDialog = false">
						<v-icon left>mdi-close</v-icon> Đóng
					</v-btn>
					<v-btn color="green" dark @click="confirmAccept">
						<v-icon left>mdi-check-circle</v-icon> Tiếp nhận
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

	</v-card>

</template>

<script>

export default {
	props: ["value"],
	data() {
		return {
			dialogHinhAnh: false,
			hinhDinhKem: "",
			dialog: false,
			acceptDialog: false,
			selectedTask: null,
			note: "",

		};
	},
	mounted() {
		// this.getBaoSuaMoi();
		// console.log(this.dulieu);
		// console.log(this.$vuetify.display.mobile)
	},
	methods: {
		formatDateTime: window.formatDateTime,

		async reloadData() {
			// await this.getBaoSuaMoi();
			this.$emit("update");
		},
		// async getBaoSuaMoi() {
		// 	try {
		// 		const res = await axios.post("BaoSua_SelectBaoSuaMoi");
		// 		this.dulieu = res.data.data;
		// 	} catch (error) {
		// 		showMessage({ type: "red", title: error.response.data.Message });
		// 	}
		// },

		showTaskDetail(task) {
			this.selectedTask = task;
			this.$refs.chiTietBaoSua.open(task.MaBaoSua);
		},

		openAcceptDialog() {
			this.acceptDialog = true;
		},
		async confirmAccept() {
			await axios.post("TS_TiepNhanBaoSua_Insert", {
				GhiChi: this.note,
				MaBaoSua: this.selectedTask.MaBaoSua
			})
				.then(() => {
					CALL({ "MESS": "Tiếp nhận thành công" })
					this.acceptDialog = false;
					this.dialog = false;
					this.getdsbaosuamoi();
				})
				.catch((error) => {
					CALL({ "MESS": error.responsed.data.Message })
				})
		},
		async getHinhAnh() {
			try {
				console.log("MaBaoSua gửi lên:", this.selectedTask.MaBaoSua);
				const response = await axios.post("/TS_BaoSua_SelectHinhAnh", {
					MaBaoSua: this.selectedTask.MaBaoSua
				});
				console.log(response.data.data[0].HinhAnh)
				if (response.data.data && response.data.data[0].HinhAnh) {
					this.hinhDinhKem = response.data.data[0].HinhAnh;
					this.dialogHinhAnh = true;
				} else {
					showMessage({ type: "red", title: "Không có hình ảnh" });
				}
			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi khi tải hình ảnh" });
			}
		},
		getStatusColor(maTinhTrang) {
			switch (maTinhTrang) {
				case 0:
					return 'error';
					break;
				case 1:
					return 'light-green';
					break;
				case 2:
					return 'orange';
					break;
				case 3:
					return 'green';
					break;
				case 4:
					return 'light-blue-accent-3';
					break;

				default:
					return 'green';
					break;
			}
		},


	}
}
</script>