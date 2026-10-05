<template>

	<v-row>
		<v-col cols="12" md="3">
			<uc-stat-card @thongKe="showTaiSanCho" title="Chờ phòng ban xác nhận" :value="slTaiSan.TongTaiSan"
				icon="mdi-package-variant-closed-plus" coloricon="blue darken-2" bgicon="#E3F2FD" />
		</v-col>
		<v-col cols="12" md="3">
			<uc-stat-card title="Đang luân chuyển" :value="slTaiSan.TongDangLuanChuyen" icon="mdi-rotate-3d-variant"
				coloricon="green darken-2" bgicon="#BFF6C3"></uc-stat-card>
		</v-col>
		<v-col cols="12" md="3">
			<uc-stat-card @thongKe="showSuaTaiSan" title="Đang sửa chữa" :value="slTaiSan.TongDangSuaChua"
				icon="mdi-tools" coloricon="orange darken-2" bgicon="#FEF3C7"></uc-stat-card>
		</v-col>
		<v-col cols="12" md="3">
			<uc-stat-card @thongKe="showTaiSanHetHan" title="Tài sản hết hạn" :value="slTaiSan.TongTaiSanHetHan"
				icon="mdi-alert" coloricon="red darken-2" bgicon="#FEE2E2"></uc-stat-card>
		</v-col>
	</v-row>
	<!--Tài sản chờ xác nhận  -->
	<v-dialog v-model="dialog" max-width="800px">
		<v-card class="custom-card">
			<v-toolbar color="primary">
				<v-toolbar-title>Danh sách tài sản chờ xác nhận</v-toolbar-title>
				<v-btn icon="mdi-close" @click="dialog = false"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text>
				<v-expansion-panels class="mt-3">
					<!-- Lặp qua dữ liệu đã nhóm -->
					<v-expansion-panel v-for="(group, phongBan) in groupedTaiSanChoXacNhan" :key="phongBan">
						<v-expansion-panel-title style="padding-top: 0px; padding-bottom: 0px">
							<div class="d-flex justify-space-between align-center" style="width: 100%;">
								<span>{{ phongBan }} - [ {{ group.length}} ]</span>
							</div>
						</v-expansion-panel-title>
						<v-expansion-panel-text>
							<v-data-table-virtual :items-per-page="-1" hide-default-footer :items="group"
								:headers="header" item-value="MaCaBiet">
								<template v-slot:item.TenTaiSan="{item}">
									<uc-asset-info classforname="text-subtitle-2" :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet"
										:mataisan="item.MaTS"></uc-asset-info>
								</template>
							</v-data-table-virtual>
						</v-expansion-panel-text>
					</v-expansion-panel>
				</v-expansion-panels>
			</v-card-text>
		</v-card>
	</v-dialog>

	<!-- Đang sửa chữa tài sản -->
	<v-dialog v-model="dialogSuaChuaTaiSan" max-width="800px">
		<v-card class="custom-card">
			<v-toolbar color="primary">
				<v-toolbar-title>Danh sách tài sản đang sửa chữa</v-toolbar-title>
				<v-btn icon="mdi-close" @click="dialogSuaChuaTaiSan = false"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text>
				<v-expansion-panels class="mt-3">
					<!-- Lặp qua dữ liệu đã nhóm -->
					<v-expansion-panel v-for="(group, phongBan) in groupedSuaChuaTaiSan" :key="phongBan">
						<v-expansion-panel-title style="padding-top: 0px; padding-bottom: 0px">
							<div class="d-flex justify-space-between align-center" style="width: 100%;">
								<span>{{ phongBan }} - [ {{ group.length}} ]</span>
							</div>
						</v-expansion-panel-title>
						<v-expansion-panel-text>
							<v-data-table-virtual hide-default-footer :items="group" :headers="headerSuaChuaTaiSan"
								item-value="MaCaBiet">
								<template v-slot:item.TenTaiSan="{item}">
									<uc-asset-info classforname="text-subtitle-2" :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet"
										:mataisan="item.MaTS"></uc-asset-info>
								</template>
							</v-data-table-virtual>
						</v-expansion-panel-text>
					</v-expansion-panel>
				</v-expansion-panels>
			</v-card-text>
		</v-card>
	</v-dialog>


	<!--Tài sản hết hạn-->
	<v-dialog v-model="dialogTaiSanHetHan" max-width="800px">
		<v-card class="custom-card">
			<v-toolbar color="primary">
				<v-toolbar-title>Danh sách tài sản hết hạn</v-toolbar-title>
				<v-btn icon="mdi-close" @click="dialogTaiSanHetHan = false"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text>
				<v-expansion-panels class="mt-3">
					<!-- Lặp qua dữ liệu đã nhóm -->
					<v-expansion-panel v-for="(group, phongBan) in groupedTaiSanHetHan" :key="phongBan">
						<v-expansion-panel-title style="padding-top: 0px; padding-bottom: 0px">
							<div class="d-flex justify-space-between align-center" style="width: 100%;">
								<span>{{ phongBan }} - [ {{ group.length}} ]</span>
							</div>
						</v-expansion-panel-title>
						<v-expansion-panel-text>
							<v-data-table-virtual hide-default-footer :items="group" :headers="headerTaiSanHetHan"
								item-value="MaCaBiet">
								<template v-slot:item.TenTaiSan="{item}">								
									<uc-asset-info classforname="text-subtitle-2" :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet"
										:mataisan="item.MaTS"></uc-asset-info>
								</template>
							</v-data-table-virtual>
						</v-expansion-panel-text>
					</v-expansion-panel>
				</v-expansion-panels>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: ["reload"],
		data() {
			return {
	
				slTaiSan: [],
				dialog: false,
				dialogSuaChuaTaiSan: false,
				header: [
					{ title: "STT", key: "STT" },
					{ title: "Tên tài sản", key: "TenTaiSan" },
					{ title: "Ngày chuyển", key: "NgayChuyen" },
	
	
				],
				selectedTask: null,
				dsTaiSanChoXacNhan: [],
				dsSuaChuaTaiSan: [],
				headerSuaChuaTaiSan: [
					{ title: "STT", key: "STT" },
					{ title: "Tên tài sản", key: "TenTaiSan" },
					{ title: "Vị trí phòng", key: "TenViTriPhong" },
					{ title: "Mô tả", key: "GhiChu" },
					{ title: "Ngày báo sửa", key: "TGBaoSua" },
	
				],
				dialogTaiSanHetHan: false,
				dsTaiSanHetHan: [],
				headerTaiSanHetHan: [
					{ title: "STT", key: "STT" },
					{ title: "Tên tài sản", key: "TenTaiSan" },
					{ title: "Vị trí phòng", key: "TenViTriPhong" },
					{ title: "Ngày hết hạn", key: "NgayHetHanBaoHanh" },
					
	
				]
	
			};
		},
		async mounted() {
			await this.getTongTaiSan()
		},
		computed: {
			// Nhóm dữ liệu theo TenPhongBan
			groupedTaiSanChoXacNhan() {
				const grouped = {};
				this.dsTaiSanChoXacNhan.forEach((item) => {
					const phongBan = item.TenPhongBan;
					if (!grouped[phongBan]) {
						grouped[phongBan] = [];
					}
					const stt = grouped[phongBan].length + 1;
	
					grouped[phongBan].push({
						STT: stt,
						TenTaiSan: item.TenTaiSan,
						NgayChuyen: item.NgayChuyen,
						MaCaBiet: item.MaCaBiet
					});
				});
				return grouped;
			},
			groupedSuaChuaTaiSan() {
				const grouped = {};
				this.dsSuaChuaTaiSan.forEach((item) => {
					const phongBan = item.TenPhongBan;
					if (!grouped[phongBan]) {
						grouped[phongBan] = [];
					}
					const stt = grouped[phongBan].length + 1;
	
					grouped[phongBan].push({
						STT: stt,
						TenTaiSan: item.TenTaiSan,
						TenViTriPhong: item.TenViTriPhong,
						GhiChu: item.GhiChu,
						TGBaoSua: item.TGBaoSua,
						MaCaBiet: item.MaCaBiet
					});
				});
				return grouped;
			},
			groupedTaiSanHetHan() {
				const grouped = {};
				this.dsTaiSanHetHan.forEach((item) => {
					const phongBan = item.TenPhongBan;
					if (!grouped[phongBan]) {
						grouped[phongBan] = [];
					}
	
					const stt = grouped[phongBan].length + 1;
	
					grouped[phongBan].push({
						STT: stt,
						TenTaiSan: item.TenTaiSan,
						TenViTriPhong: item.TenViTriPhong,
						NgayHetHanBaoHanh: item.NgayHetHanBaoHanh,
						MaCaBiet: item.MaCaBiet
					});
				});
				return grouped;
			},
		},
		watch: {
			async reload(){
				await this.getTongTaiSan();
			},
			async dialog() {
				if (this.dialog == true) {
					await this.getTaiSanChoXacNhan();
				}
			},
			async dialogSuaChuaTaiSan() {
				if (this.dialogSuaChuaTaiSan == true) {
					await this.getSuaChuaTaiSan();
				}
			},
			async dialogTaiSanHetHan() {
				if (this.dialogTaiSanHetHan == true) {
					await this.getTaiSanHetHan();
				}
			},
		},
		methods: {
			async getTongTaiSan() {
				this.slTaiSan = await axios.post("obj/TS_ThongKe_DashBoard")
					.then((responsed) => {
	
						return responsed.data.data
					})
					.catch()
				console.log(this.slTaiSan)
			},
			showTaiSanCho(task) {
				this.selectedTask = task;
				this.dialog = true;
			},
			showSuaTaiSan(task) {
				this.selectedTask = task;
				this.dialogSuaChuaTaiSan = true;
			},
			showTaiSanHetHan(task) {
				this.selectedTask = task;
				this.dialogTaiSanHetHan = true;
			},
			async getTaiSanChoXacNhan() {
				this.dsTaiSanChoXacNhan = await axios.post("/TS_CaBietTaiSan_Select_ChoXacNhan", {
				})
					.then((resp) => {
						return resp.data.data
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				console.log(this.dsTaiSanChoXacNhan)
			},
			async getSuaChuaTaiSan() {
				this.dsSuaChuaTaiSan = await axios.post("/TS_TiepNhanBaoSua_SelectByTinhTrang", {
				})
					.then((resp) => {
						return resp.data.data
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				console.log(this.dsSuaChuaTaiSan)
			},
			async getTaiSanHetHan() {
				this.dsTaiSanHetHan = await axios.post("/TS_TaiSan_Select_HetHanBaoHanh", {
				})
					.then((resp) => {
						return resp.data.data
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				console.log(this.dsTaiSanHetHan)
			},
		},
	
	}
</script>