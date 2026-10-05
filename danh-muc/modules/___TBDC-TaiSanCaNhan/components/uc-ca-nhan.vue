<template>
	<v-container fluid>
		<v-row>
			<v-col cols="12" class="border-sm rounded elevation-2">
				<v-card flat>
					<v-layout class="my-1 d-flex align-center">
						<v-spacer></v-spacer>
						<v-item-group v-model="tinhTrangTaiSan" mandatory selected-class="bg-primary text--white ">

							<v-item :value="1" v-slot="{ isSelected, selectedClass, toggle }">

								<v-btn size="small" :prepend-icon="isSelected ? 'mdi-check' : ''"
									:class="selectedClass" @click="toggle" variant="tonal" class="rounded-pill">
									Đang sở hữu
								</v-btn>

							</v-item>

							<v-item :value="2" v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn :prepend-icon="isSelected ? 'mdi-check' : ''" v-if="thongKe.ChoXacNhan == 0"
									size="small" :class="selectedClass" @click="toggle" variant="tonal"
									class="rounded-pill ma-2">
									Chờ xác nhận
								</v-btn>
								<v-badge v-else color="error" :content="thongKe.ChoXacNhan">
									<v-btn :prepend-icon="isSelected ? 'mdi-check' : ''" size="small"
										:class="selectedClass" @click="toggle" variant="tonal"
										class="rounded-pill ma-2">
										Chờ xác nhận
									</v-btn>
								</v-badge>
							</v-item>

						</v-item-group>

						<v-divider inset class="border-opacity-50 mr-2" vertical></v-divider>

						<v-card flat class="d-inline-flex align-center px-2 py-1 py-0 cursor-pointer"
							color="red-lighten-2" variant="outlined" @click="isTaiSanDangSua = !isTaiSanDangSua"
							:disabled="tinhTrangTaiSan == 2">
							<v-radio v-model="isTaiSanDangSua" :value="true" color="red-lighten-2" density="compact"
								hide-details class="mr-1" />

							<v-icon icon="mdi-tools" color="red-lighten-2" size="16" class="mx-1" />

							<span class="text-body-2 font-weight-medium lh-tight">
								Tài sản
								<span class="d-block">đang sửa</span>
							</span>
						</v-card>

						<v-divider inset class="border-opacity-50 mx-2" vertical></v-divider>

						<v-autocomplete style="max-width: 300px" class="my-3" density="compact" label="Loại"
							:items="dsLoai" v-model="maDanhMuc" item-title="TenDanhMuc" item-value="DanhMucID"
							:clearable="false">
						</v-autocomplete>

						<v-autocomplete style="max-width: 300px" class="my-3 mx-2" density="compact" label="Vị trí"
							:items="dsViTriPhongCaNhan" v-model="maViTriPhongCaNhan" item-title="TenViTriPhong"
							item-value="MaViTriPhong" :clearable="false">
						</v-autocomplete>
						<!-- <v-btn prepend-icon='mdi-magnify' variant='tonal' class="mr-2" color="primary">Lọc
							<template v-slot:prepend>
								<v-icon color="success">mdi-magnify</v-icon>
							</template>
</v-btn> -->
					</v-layout>

				</v-card>
				<v-divider></v-divider>
				<v-card flat>
					<v-toolbar class="mt-2">
						<v-toolbar-title class="text-primary"><b>Danh sách tài sản
								[{{ dsTaiSanCaNhan.length }}]</b>
						</v-toolbar-title>
						<v-spacer></v-spacer>
						<v-text-field style="max-width: 400px" class="mx-4" v-model="search" density="compact"
							label="Tìm kiếm" prepend-inner-icon="mdi-magnify" variant="solo-filled" flat hide-details
							single-line>
						</v-text-field>
					</v-toolbar>
					<v-divider></v-divider>
					<v-data-table-virtual :loading="loadingTaiSan" :group-by="groupBy" v-model="selected"
						:headers="headers" :items="dsTaiSanCaNhan" item-value="MaCaBiet" show-select hide-default-footer
						:search="search" height="500" density="compact" fixed-header>
						<template v-slot:group-header="{ item, columns, toggleGroup, isGroupOpen }">
							<tr>
								<td :colspan="columns.length">
									<div class="d-flex align-center">
										<v-btn :icon="isGroupOpen(item) ? '$expand' : '$next'" color="medium-emphasis"
											density="comfortable" size="small" variant="outlined"
											@click="toggleGroup(item)">
										</v-btn>

										<v-checkbox v-model="groupSelection[item.value]" class="ms-4" density="compact"
											style="margin-top: -2px;" @change="toggleGroupSelection(item)"></v-checkbox>

										<span style=" cursor: pointer;" class=" ms-4" @click="toggleGroup(item)">{{
											item.items[0].raw.TenTaiSan }} - {{ item.items[0].raw.TenModel }} - [
											{{ item.items.length }} ]</span>

										<v-chip v-if="item.items[0].raw.TinhTrang == 8" class="ms-2" size="x-small"
											color="red">
											New
										</v-chip>
									</div>
								</td>
							</tr>
						</template>
						<template v-slot:item.TaiSanLienKet="{ item }">
							<v-chip color="primary" variant="tonal" size="small" class="mx-1"
								v-for="i in JSON.parse(item.TaiSanLienKet)">

								<uc-asset-info :tentaisan="i.TenTaiSan" :macabiet="i.MaCaBiet"></uc-asset-info>
							</v-chip>
						</template>

						<template v-slot:item.TenTaiSan="{ item }">
							<uc-asset-info classforname="text-subtitle-2 " :tentaisan="item.TenTaiSan"
								:macabiet="item.MaCaBiet" :mataisan="item.MaTS"></uc-asset-info>
						</template>


					</v-data-table-virtual>

					<!-- nút chức năng -->
					<div>
						<v-fab absolute app v-show="selected.length > 0" :color="showFabmenu ? '' : 'primary'"
							location="right top" size="large" icon>
							<v-icon>{{ showFabmenu ? 'mdi-close' : 'mdi-pencil' }}</v-icon>
							<v-speed-dial v-model="showFabmenu" location="bottom center" transition="slide-y-transition"
								activator="parent">

								<v-tooltip v-if="tinhTrangTaiSan == 2" text="Xác nhận tài sản">
									<template v-slot:activator="{ props }">

										<v-btn variant="flat" color="primary" v-bind="props" icon
											@click="xacNhanTaiSan">
											<v-icon size="24">mdi-check-circle</v-icon>
										</v-btn>
									</template>
								</v-tooltip>

								<v-tooltip text="Chuyển vị trí" v-if="tinhTrangTaiSan != 2">
									<template v-slot:activator="{ props }">
										<v-btn variant="flat" color="warning" v-bind="props" icon
											@click="showChuyenTaiSan = true">
											<v-icon>mdi-map-marker-radius</v-icon>
										</v-btn>
									</template>
								</v-tooltip>

								<v-tooltip text="Trả tài sản">
									<template v-slot:activator="{ props }">

										<v-btn variant="flat" color="red" v-bind="props" icon @click="traTaiSan">
											<v-icon>mdi-arrow-u-left-top-bold</v-icon>
										</v-btn>
									</template>
								</v-tooltip>

							</v-speed-dial>
						</v-fab>
					</div>
				</v-card>

			</v-col>
		</v-row>


		<v-dialog v-model="showChuyenTaiSan" max-width="500px">
			<v-card>
				<v-form ref="formChuyenTaiSan">
					<v-toolbar color="primary">
						<v-toolbar-title>Chuyển vị trí</v-toolbar-title>
						<v-btn size="small" icon="mdi-close" @click="showChuyenTaiSan = false"></v-btn>
					</v-toolbar>
					<v-divider></v-divider>

					<v-card-text>
						<v-autocomplete required :rules="[v => !!v || 'Vui lòng vị trí']" class="my-3" density="compact"
							label="Vị trí phòng" :items="dsViTri" v-model="viTriDangChon" item-title="TenViTriPhong"
							item-value="MaViTriPhong">
						</v-autocomplete>
					</v-card-text>
					<v-divider></v-divider>

					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn variant="tonal" @click="validate('formChuyenTaiSan', chuyenViTri)" color="primary">
							Chuyển
						</v-btn>
					</v-card-actions>
				</v-form>
			</v-card>
		</v-dialog>

		<uc-confirm ref="confirm"></uc-confirm>
	</v-container>
</template>

<script>
export default {
	data() {
		return {
			showChuyenTaiSan: false,
			search: null,
			selected: [],
			groupBy: [{ key: 'MaTS', order: 'desc' }],
			groupSelection: {},
			dsViTriPhongCaNhan: [],
			viTriDangChon: null,
			dsViTri: [],
			thongKe: {
				DangSoHuu: 0,
				ChoXacNhan: 0
			},
			filters: [
				{
					ID: 1,
					Ten: 'Đang sở hữu'
				}
			],
			isTaiSanDangSua: false,
			tinhTrangTaiSan: 1,
			maDanhMuc: 0,
			maViTriPhongCaNhan: 0,
			loadingTaiSan: false,
			dsLoai: [],
			showFabmenu: false,
			maViTriPhongCaNhan: 0,
			dsTaiSanCaNhan: [],

			dsLoc: [
				{
					ID: 1,
					Ten: 'Đang sở hữu'
				},
				{
					ID: 2,
					Ten: 'Chờ xác nhận'
				},
				{
					ID: 3,
					Ten: 'Đang sửa chữa'
				}
			],
			headers: [
				{ title: 'Mã', key: 'MaVach' },
				{
					title: 'Tên',
					align: 'start',
					sortable: false,
					key: 'TenTaiSan',
				},
				{ title: 'Model', key: 'TenModel' },
				{ title: 'Danh mục', key: 'TenDanhMuc' },
				{ title: 'Vị trí', key: 'TenViTriPhong' },

				{ title: 'Mô tả', key: 'MoTa' },
				// { title: 'Trạng thái', key: 'TinhTrangBaoSua' },
				{ title: 'Tài sản liên kết', key: 'TaiSanLienKet' },

			],
		};
	},
	computed: {
		groupedItems() {
			return this.dsTaiSanCaNhan.reduce((acc, item) => {
				if (!acc[item.MaTS]) acc[item.MaTS] = [];
				acc[item.MaTS].push(item);
				return acc;
			}, {});
		}
	},
	async mounted() {
		this.getDanhSachDanhMucTaiSan();
		this.getTaiSanCaNhan();
		this.getThongKe();
		await this.getViTriPhongByCaNhan();
	},
	watch: {
		isTaiSanDangSua(newVal) {
			console.log(this.isTaiSanDangSua);
			// this.getTaiSanCaNhanDangSua();
			// this.isTaiSanDangSua = !this.isTaiSanDangSua;


			if (newVal === true) {
				this.getTaiSanCaNhanDangSua();
			} else {
				this.getTaiSanCaNhan();
			}
		},
		maViTriPhongCaNhan() {
			this.getTaiSanCaNhan();
		},
		tinhTrangTaiSan() {
			this.getTaiSanCaNhan();
			this.selected = [];
			if (this.tinhTrangTaiSan) {
				this.isTaiSanDangSua = false;
			}
		},
		maDanhMuc() {
			this.getTaiSanCaNhan();
		},
		selected(newVal) {
			this.updateGroupSelection();
		},
		filters(newVal) {
			if (newVal.includes(1) && newVal.includes(2)) {
				if (newVal.indexOf(1) > newVal.indexOf(2)) {
					// Người dùng vừa chọn 1 → remove 2
					this.filters = newVal.filter(id => id !== 2);
				} else {
					// Người dùng vừa chọn 2 → remove 1
					this.filters = newVal.filter(id => id !== 1);
				}
			}
		}
	},
	methods: {
		updateGroupSelection() {
			const newGroupSelection = {};
			Object.keys(this.groupedItems).forEach(group => {
				const groupItems = this.groupedItems[group];
				const allSelected = groupItems.every(item =>
					this.selected.includes(item.MaCaBiet)
				);
				newGroupSelection[group] = allSelected;
			});
			this.groupSelection = newGroupSelection;
		},
		toggleGroupSelection(group) {
			const groupItems = this.groupedItems[group.value];
			const allSelected = groupItems.every(item =>
				this.selected.includes(item.MaCaBiet)
			);

			if (allSelected) {
				// Remove all items from this group
				this.selected = this.selected.filter(item =>
					!groupItems.some(groupItem => groupItem.MaCaBiet === item)
				);
			} else {
				// Add all items from this group
				const groupItemIds = groupItems.map(item => item.MaCaBiet);
				this.selected = [...new Set([...this.selected, ...groupItemIds])];
			}
		},
		async validate(refName, callback, confirmText = "Bạn có muốn lưu dữ liệu?", reset = true) {

			const form = this.$refs[refName];
			if (!form) {
				console.warn(`Form ref "${refName}" not found.`);
				return;
			}

			const { valid } = await form.validate();

			if (valid && typeof callback === "function") {
				const confirmed = await this.$refs.confirm.open(confirmText);
				if (!confirmed) return;
				await callback();
				if (reset) form.reset();
			}
		},
		async getViTriPhongByCaNhan() {
			try {
				const kq = await axios.post("TaiSanCaNhan_SelectViTriPhong")
				this.dsViTriPhongCaNhan = kq.data.data
				this.dsViTriPhongCaNhan.unshift({ "MaViTriPhong": 0, "TenViTriPhong": "Tất cả" })
				this.maViTriPhongCaNhan = 0
			} catch (error) {
				showMessage({ type: "red", title: error.response.data.Message })
			}
		},
		async getDanhSachViTri() {
			try {

				const response = await axios.post("ViTriPhong_SelectByPhongBan", {
					PhongBanID: vueData.user.DepartmentID
				});
				this.dsViTri = response.data.data || [];

			} catch (error) {
				console.error('Error fetching assets:', error);
			}
		},

		async getTaiSanCaNhan() {
			this.loadingTaiSan = true;
			this.dsTaiSanCaNhan = await axios.post("TaiSan_Select_CaNhan_TinhTrang_DanhMuc", {
				TinhTrang: this.tinhTrangTaiSan,
				DanhMuc: this.maDanhMuc,
				ViTri: this.maViTriPhongCaNhan


			})
				.then((responsed) => {
					return responsed.data.data
				})
				.catch((error) => {
					showMessage({ type: "red", title: error.response.data.Message })
				})
			this.loadingTaiSan = false;
		},

		async getTaiSanCaNhanDangSua() {
			this.loadingTaiSan = true;
			this.dsTaiSanCaNhan = await axios.post("TaiSanCaNhan_DangSua", {
				TinhTrang: 10,
				DanhMuc: this.maDanhMuc,
				ViTri: this.maViTriPhongCaNhan


			})
				.then((responsed) => {
					return responsed.data.data
				})
				.catch((error) => {
					showMessage({ type: "red", title: error.response.data.Message })
				})
			this.loadingTaiSan = false;
		},

		async xacNhanTaiSan() {
			try {
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn xác nhận tài sản?',
						okText: 'Xác nhận',
						cancelText: 'Hủy',
						okColor: 'primary',
						cancelColor: 'blue-grey'
					}
				);
				if (!confirmed) return;
				await axios.post("CaNhan_XacNhanTaiSan", {
					DanhSachMaCaBiet: this.selected.toString()
				})
					.then(() => {
						CALL({ "MESS": "Cập nhật thành công" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})

				this.getTaiSanCaNhan();
				this.getThongKe();
			} catch (error) {
				showMessage({ type: "red", title: "Lỗi cập nhật" })
			}
		},

		async chuyenViTri() {
			try {
				await axios.post("CaNhan_ChuyenViTriTaiSan", {
					DanhSachMaCaBiet: this.selected.toString(),
					ViTriPhongID: this.viTriDangChon
				})
					.then(() => {
						CALL({ "MESS": "Cập nhật thành công" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})

				this.getTaiSanCaNhan();
				this.getThongKe();
				this.showChuyenTaiSan = false;
			} catch (error) {
				showMessage({ type: "red", title: "Lỗi cập nhật" })
			}
		},

		async traTaiSan() {
			try {
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn trả tài sản?',
						okText: 'Xác nhận',
						cancelText: 'Hủy',
						okColor: 'primary',
						cancelColor: 'blue-grey'
					}
				);
				if (!confirmed) return;
				await axios.post("CaNhan_TraTaiSan", {
					DanhSachMaCaBiet: this.selected.toString()
				})
					.then(() => {
						CALL({ "MESS": "Cập nhật thành công" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})

				this.getTaiSanCaNhan();
				this.getThongKe();
			} catch (error) {
				showMessage({ type: "red", title: "Lỗi cập nhật" })
			}
		},

		async getDanhSachDanhMucTaiSan() {
			try {
				const response = await axios.post("DanhMuc_Select_Option");
				this.dsLoai = response.data.data || [];
				this.dsLoai.unshift({ "TenDanhMuc": "Tất cả", "DanhMucID": 0 });
			} catch (error) {
				showMessage({ type: "red", title: "Lỗi lấy danh mục" })
			}
		},
		async getThongKe() {
			try {
				const response = await axios.post("obj/TaiSan_CaNhan_ThongKe");
				this.thongKe = response.data.data || [];

			} catch (error) {
				showMessage({ type: "red", title: "Lỗi lấy thống kê" })
			}
		},



	},

}	
</script>

<style>
.toggle-container {
	position: relative;
	display: inline-block;
}

/* Toggle gốc */
.toggle {
	background: #f1f3f5;
	border-radius: 10px;
	padding: 0;
	overflow: hidden;
	position: relative;
	z-index: 2;
}

/* Nền trượt */
.toggle-slider {
	position: absolute;
	top: 0;
	left: 0;
	width: 50%;
	/* vì có 2 nút */
	height: 100%;
	background: #ffffff;
	border-radius: 10px;
	box-shadow: 0 1px 4px rgba(0, 0, 0, 0.15);
	transition: transform 0.25s ease;
	z-index: 1;
}

.toggle-slider.right {
	transform: translateX(100%);
}

.toggle-btn {
	z-index: 3;
	background: transparent !important;
	position: relative;
}
</style>