<template>
	<v-container>
		<v-card>
			<v-card-actions>
				<v-row>
					<v-col cols="12" sm="6">
						<h2 style="" class="text-primary">Quản lý nhóm sửa chữa</h2>
					</v-col>
					<v-col cols="12" sm="3" align-self="center">

						<v-row class="justify-start justify-sm-end">
							<v-btn rounded size="small" color="primary" prepend-icon="mdi-plus" @click="openDialog()"
								text="Thêm nhóm" variant="tonal">
							</v-btn>

						</v-row>
					</v-col>
					<v-col cols="12" md="3">
						<v-text-field v-model="searchMain" density="compact" label="Search"
							prepend-inner-icon="mdi-magnify" variant="solo-filled" flat hide-details single-line>
						</v-text-field>
					</v-col>
				</v-row>
			</v-card-actions>

			<v-divider></v-divider>

			<v-data-table :hide-default-footer="true" :headers="groupHeaders" :search="searchMain"
				:loading="loadingNhomSuaChua" :items="dsNhomSuaChua">
				<template v-slot:item.actions="{ item }">
					<div class="d-flex">
						<v-btn size="small" icon="mdi-pencil" variant="text" color="blue" class="ml-n3"
							@click="openDiaLogEditNhom(item)">
						</v-btn>
						<v-btn size="small" icon="mdi-delete" variant="text" color="red"
							@click="deleteNhom(item.MaNhom)">
						</v-btn>
					</div>

				</template>
				<template v-slot:item.TenNhom="{ item }">
					<span style="cursor: pointer;" @click="openDialogNhom(item, item.MaNhom)"><b>{{ item.TenNhom
							}}</b></span>
				</template>
				<template v-slot:item.TenLoaiDanhMuc="{ item}">
					<v-btn size="small" color="primary" variant="tonal"
						@click="()=>{thy=item.MaNhom;openDialogDanhMuc(item)}">
						<v-icon>mdi-plus</v-icon>
					</v-btn>
				</template>
			</v-data-table>
		</v-card>
	</v-container>

	<v-dialog v-model="dialog" max-width="500px">
		<v-card>
			<v-form ref="formThemNhom">
				<v-toolbar>
					<v-toolbar-title class="text-primary">Thêm nhóm</v-toolbar-title>
					<!-- <v-btn icon="mdi-close" @click="dialog = false"></v-btn> -->
				</v-toolbar>
				<v-divider></v-divider>
				<v-card-text>
					<v-text-field :rules="[v => !!v || 'Tên nhóm là bắt buộc']" v-model="form.tenNhom" label="Tên nhóm"
						required></v-text-field>
				</v-card-text>

				<v-card-actions>
					<v-spacer></v-spacer>

					<v-btn text="Đóng" variant="plain" @click="dialog = false"></v-btn>

					<v-btn color="primary" variant="tonal" class="font-weight-bold"
						@click="validate('formThemNhom', insertNhom, 'Bạn có muốn thêm tên nhóm?')">
						Lưu
					</v-btn>
				</v-card-actions>
			</v-form>

		</v-card>
	</v-dialog>

	<v-dialog v-model="dialogEditNhom" max-width="500px">
		<v-card>
			<v-form ref="formEditNhom">
				<v-toolbar>
					<v-toolbar-title class="text-primary">Cập nhật</v-toolbar-title>

					<!-- <v-btn icon="mdi-close" @click="dialogEditNhom = false"></v-btn> -->
				</v-toolbar>
				<v-divider></v-divider>

				<v-card-text>
					<v-text-field :rules="[v => !!v || 'Tên nhóm là bắt buộc']" v-model="form.tenNhom" label="Tên nhóm"
						required>
					</v-text-field>
				</v-card-text>

				<v-card-actions>
					<v-spacer></v-spacer>

					<v-btn text="Đóng" variant="plain" @click="dialogEditNhom = false"></v-btn>

					<v-btn color="primary" variant="tonal" class="font-weight-bold"
						@click="validate('formEditNhom', editNhom, 'Bạn có muốn sửa tên nhóm?')">
						Lưu
					</v-btn>
				</v-card-actions>
			</v-form>

		</v-card>
	</v-dialog>

	<!-- Dialog chi tiết nhân viên với bảng -->
	<v-dialog v-model="dialogNhanVien" max-width="600px">
		<v-card>
			<v-card-actions>
				<v-row>
					<v-col cols="12" sm="5">
						<h3 style="" class="text-primary ml-2 mt-1">{{ selectedGroupName }}</h3>
					</v-col>

					<v-col cols="12" sm="4" align-self="center">
						<v-row justify="start" justify-sm="end" class="ml-1">
							<v-btn rounded size="small" color="primary" prepend-icon="mdi-plus"
								@click="openThemNhanVien()" text="Thêm nhân viên" variant="tonal">
							</v-btn>
						</v-row>
					</v-col>

					<v-col cols="12" sm="3">
						<v-text-field class="" v-model="searchNhanVien" density="compact" label="Search"
							prepend-inner-icon="mdi-magnify" variant="solo-filled" flat hide-details single-line>
						</v-text-field>
					</v-col>

				</v-row>
			</v-card-actions>

			<v-divider></v-divider>

			<v-card>
				<v-data-table-virtual :loading="loadingNhanVien" :search="searchNhanVien" :items="dsNhanVien"
					:headers="employeeHeaders" :hide-default-footer="true" height="400" density="compact">

					<template v-slot:item.Xoa="{item}">
						<v-btn variant="text" size="small" color="red" @click="deleteNhanVien(item.ID)"
							icon="mdi-delete">
						</v-btn>
					</template>

				</v-data-table-virtual>
			</v-card>
			<v-card-actions>
				<v-btn text="Đóng" variant="tonal" @click="dialogNhanVien = false"></v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>

	<v-dialog v-model="dialogThemNhanVien" max-width="500px">

		<v-card>
			<v-form ref="formThemNhanVien">
				<v-toolbar>
					<v-toolbar-title class="text-primary">Thêm nhân viên vào nhóm</v-toolbar-title>
					<!-- <v-btn icon="mdi-close" @click="dialogThemNhanVien = false"></v-btn> -->
				</v-toolbar>

				<v-card-text>
					<v-autocomplete required
						:rules="[v => Array.isArray(v) && v.length > 0 || 'Vui lòng chọn nhân viên']" chips multiple
						v-model="nhanVienDangChon" :items="dsNhanVienPB" item-title="HoTen" item-value="MaNV"
						color="primary" label="Chọn nhân viên"></v-autocomplete>
				</v-card-text>

				<v-card-actions class="justify-end">
					<v-btn text @click="dialogThemNhanVien = false">Hủy</v-btn>
					<v-btn color="primary" variant="tonal"
						@click="validate('formThemNhanVien', insertNhanvien, 'Bạn có muốn thêm nhân viên vào nhóm?')">
						Lưu</v-btn>

				</v-card-actions>
			</v-form>

		</v-card>
	</v-dialog>

	<!-- Dialog chọn danh mục sửa chữa -->
	<v-dialog v-model="dialogDanhMuc">
		<v-card>
			<v-toolbar>
				<v-toolbar-title class="text-primary">Quản lý danh mục sửa chữa</v-toolbar-title>

				<v-btn icon="mdi-close" @click="dialogDanhMuc = false"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text>
				<v-row>
					<!-- BÊN TRÁI: Form thêm -->

					<v-col cols="12" md="4">
						<v-card>
							<v-form ref="formThemDanhMuc">
								<v-toolbar>
									<v-toolbar-title>Thêm mới</v-toolbar-title>
								</v-toolbar>
								<v-divider></v-divider>
								<v-card-text>
									<v-select required v-model="selectedLoaiDanhMuc" :items="dsLoaiDanhMuc"
										item-value="MaLoai" item-title="TenLoai" label="Loại danh mục" dense outlined
										return-object style="margin-bottom: 10px;" :rules="[rules.required]"
										@update:model-value="getDSDanhMuc"></v-select>
									<v-autocomplete required :rules="[rules.required]" chips multiple color="primary"
										return-object v-model="maDanhMucDangChon" :items="dsDanhMuc" density="compact"
										item-value="MaDM" item-title="TenDanhMuc" :clearable="false" label="Danh mục">
									</v-autocomplete>
								</v-card-text>
								<v-card-actions>
									<v-spacer></v-spacer>
									<v-btn color="primary" variant="tonal"
										@click="validate('formThemDanhMuc', addNewCategory,'Bạn muốn thêm danh mục mới cho trong nhóm?')">
										<v-icon left>mdi-plus</v-icon> Thêm
									</v-btn>
								</v-card-actions>
							</v-form>
						</v-card>

					</v-col>

					<!-- BÊN PHẢI: Bảng hiển thị -->
					<v-col cols="12" md="8">
						<v-row>
							<v-col cols="12" md="4">
								<span class="text-primary">[ Số lượng: {{ danhMucSuaChua.length }} ]</span>
							</v-col>
							<v-col cols="12" md="8">
								<v-text-field class="" v-model="searchDanhMuc" density="compact" label="Search"
									prepend-inner-icon="mdi-magnify" variant="solo-filled" flat hide-details
									single-line></v-text-field>
							</v-col>
						</v-row>

						<v-card>
							<v-data-table-virtual :loading="loadingDanhMuc" :items="danhMucSuaChua"
								:search="searchDanhMuc" :headers="categoryTableHeaders" height="500" density="compact"
								dense hide-default-footer>
								<template v-slot:item.Xoa="{item}">
									<v-btn variant="text" size="small" color="red" @click="deleteDanhMuc(item.ID)"
										icon="mdi-delete"></v-btn>
								</template>
							</v-data-table-virtual>
						</v-card>

					</v-col>
				</v-row>
			</v-card-text>

		</v-card>
	</v-dialog>

	<uc-confirm ref="confirm"></uc-confirm>
</template>

<script>
	export default {
		props: {
			dulieu: {
				type: Array
			}
		},
		data() {
			return {
				loadingNhomSuaChua: false,
				dsNhomSuaChua: [],
				loadingDanhMuc: false,
				loadingNhanVien: false,
				maNhanVienSuaChua: null,
				maNhomDangChon: null,
				dsLoaiDanhMuc: [],
				thy: null,
				dsDanhMuc: [],
				fromAPI: false,
				thongBao: false,
				dsNhanVien: [],
				dsPhongBan: [],
				dialogThemNhanVien: false,
				dialogEditNhom: false,
				showDialogDelete: false,
				dsNhanVienPB: [],
				selectedPhongBan: null,
				selectedNhanVien: null,
				danhMuc: null,
				searchMain: '', 
				searchNhanVien: '', 
				searchDanhMuc: '',
				danhMucSuaChua: [],
				nhanVienDangChon: [],
				maDanhMucDangChon: [],
				listdanhmuc: false,
				newCategory: '',
				dialog: false,
				dialogNhanVien: false,
				dialogDanhMuc: false,
				selectedGroup: null,
				selectedGroupName: '',
				selectedLoaiDanhMuc: null,
				categoryTableHeaders: [
					{ title: 'Loại danh mục', key: 'TenLoai' },
					{ title: 'Tên danh mục', key: 'TenDanhMuc' },
					{ title: 'Xóa', key: 'Xoa' },
				],
				form: {
					tenNhom: '',
					tenDanhMuc: '',
					tenLoaiDanhMuc: '',
				},
	
				groupHeaders: [
					{ title: 'Tên nhóm', key: 'TenNhom' },
					{ title: 'Danh mục sửa chữa', key: 'TenLoaiDanhMuc' },
					{ title: 'Chức năng', key: 'actions', sortable: false },
				],
				employeeHeaders: [
					{ title: 'Mã nhân viên', key: 'MaNV' },
					{ title: 'Họ tên nhân viên', key: 'HoTen' },
					{ title: 'Xóa', key: 'Xoa' },
	
				],
				rules: {
					required: value => {
						if (Array.isArray(value)) {
							return value.length > 0 || 'Vui lòng vị trí';
						}
						return !!value && String(value).trim().length > 0 || 'Vui lòng điền đầy đủ dữ liệu';
					}
				}
			};
		},
		mounted() {
			this.getNhomSuaChua();
			this.getDSLoaiDanhMuc();
		},
		watch: {
			async selectedLoaiDanhMuc(newVal, oldVal) {
				// if (newVal !== oldVal && newVal !== null) {
				// 	if (!this.fromAPI) {
				// 		this.danhMuc = null;
				// 	}
				// 	await this.getDSDanhMuc();
				// }
				await this.getDSDanhMuc();
			},
			async selectedPhongBan(newVal, oldVal) {
				await this.getNhanVienPhongBan();
			}
		},
		methods: {
			async getNhomSuaChua() {
				this.loadingNhomSuaChua = true;
				try {
					const res = await axios.post("TS_selectNhomSuaChua", {});
	
					this.dsNhomSuaChua = res.data.data || res.data;
				} catch (error) {
					// Giả định hàm showMessage đã được khai báo global
					showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi tải dữ liệu" });
				} finally {
					this.loadingNhomSuaChua = false;
				}
			},
			alert(kieu, message) {
				this.kieu = kieu;
				this.message = message;
				this.thongBao = true;
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
	
	
			async getDMSuachua(maNhom) {
				this.loadingDanhMuc = true;
				// Phải có await ở đây để code bên ngoài biết khi nào nó chạy xong
				this.danhMucSuaChua = await axios.post("TS_Select_DanhMucSua_ByNhom", {
					NhomDanhMucID: maNhom
				})
					.then((res) => {
						return res.data.data;
					})
					.catch((err) => {
						console.log(err);
						return []; // Trả về mảng rỗng nếu lỗi để không bị crash
					});
	
				this.loadingDanhMuc = false;
			},
			
	
			async deleteNhanVien(ID) {
	
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn xóa nhân viên ra khỏi nhóm?',
						okText: 'Xóa',
						cancelText: 'Hủy',
						okColor: 'red', // màu của nút OK
						cancelColor: 'blue-grey'// màu của nút cancel
					}
				);
				if (!confirmed) return;
				await axios.post("TS_NhanVienSuaChua_Delete",
					{
						ID: ID
					}
				)
					.then(() => {
						CALL({ "MESS": "Xóa thành công" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				this.getDSNhanvienSuaChua();
			},
	
			async deleteDanhMuc(ID) {
	
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn xóa danh mục ra khỏi danh sách?',
						okText: 'Xóa',
						cancelText: 'Hủy',
						okColor: 'red', // màu của nút OK
						cancelColor: 'blue-grey'// màu của nút cancel
					}
				);
				if (!confirmed) return;
				await axios.post("TS_DanhMucSuaChua_Delete",
					{
						ID: ID
					}
				)
					.then(() => {
						CALL({ "MESS": "Xóa thành công" })
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
				this.getDMSuachua(this.thy);
			},
	
			async insertNhom() {
				if (!this.form.tenNhom || this.form.tenNhom.trim() === "") {
					showMessage({ type: "red", title: "Vui lòng nhập tên nhóm" });
					return;
				}
	
				try {
					await axios.post("TS_Insert_NhomDanhMucSuaChua", {
						TenNhom: this.form.tenNhom,
					});
	
					this.dialog = false;
					CALL({ MESS: "Đã thêm" });
					// CALL(vueData.getNhomSuaChua);
					this.getNhomSuaChua();
				} catch (error) {
					showMessage({ type: "red", title: error.response.data.Message });
				}
			},
			async getDSLoaiDanhMuc() {
				console.log("Hàm loại danh mục");
				this.dsLoaiDanhMuc = await axios.post("TS_LoaiDanhMuc_Select_Option"
				)
					.then((res) => {
						console.log("API loại danh mục");
						return res.data.data;
					})
					.catch((err) => {
						console.log(err); nhanVienDangChon
					})
			},
			async getNhanVienPhongBan() {
				this.dsNhanVienPB = await axios.post("TS_NhanVien_Select_InsertNhomSuaChua",
					{
						MaNhom: this.maNhomDangChon
					}
				)
					.then((res) => {
						return res.data.data
					})
					.catch((err) => {
						console.log(err);
					});
				console.log("danhsach: ", this.dsNhanVienPB);
	
			},
			async getDSNhanvienSuaChua() {
				this.loadingNhanVien = true;
				this.dsNhanVien = await axios.post("TS_NhanVienSuaChua_Select", {
					MaNhom: this.maNhomDangChon
				})
					.then((res) => {
	
						return res.data.data;
	
					})
					.catch((err) => {
						console.log(err);
					})
				this.loadingNhanVien = false;
			},
	
			async editNhom() {
				await axios.post("TS_UpdateNhom", {
					MaNhom: this.selectedGroup.MaNhom,
					TenNhom: this.form.tenNhom
				})
					.then((res) => {
						this.dialogEditNhom = false;
						CALL({ MESS: "Cập nhật thành công" });
						return res.data.data;
					})
					.catch((err) => {
	
						let errorMsg = "Đã xảy ra lỗi.";
						if (err.response && err.response.data && err.response.data.Message) {
							errorMsg = err.response.data.Message;
						}
						showMessage({ type: "red", title: errorMsg })
					})
				// CALL(vueData.getNhomSuaChua);
				this.getNhomSuaChua();
	
			},
			async deleteNhom(maNhom) {
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn xóa nhóm?',
						okText: 'Xóa',
						cancelText: 'Hủy',
						okColor: 'red', // màu của nút OK
						cancelColor: 'blue-grey'// màu của nút cancel
					}
				);
				if (!confirmed) return;
				await axios.post("TS_NhomSuaChua_Delete", {
					MaNhom: maNhom,
				})
					.then((res) => {
						CALL({ MESS: "Xoá thành công" });
						this.showDialogDelete = false;
						return res.data.data;
					})
					.catch((err) => {
						console.log(err);
					})
				// CALL(vueData.getNhomSuaChua);
				this.getNhomSuaChua();
			},
	
			async insertNhanvien() {
				await axios.post("TS_NhanVienSuaChua_Insert", {
					MaNhom: this.selectedGroup.MaNhom,
					MaNV: this.nhanVienDangChon.toString()
				})
					.then((res) => {
						CALL({ "MESS": "Đã thêm" });
						// this.dialogNhanVien = false;
						this.dialogThemNhanVien = false;
					})
					.catch((err) => {
						showMessage({ type: "red", title: error.response.data.Message });
	
						console.log(err);
					});
	
				this.getDSNhanvienSuaChua();
			},
	
			async insertDanhMucSuaChua(maNhom) {
				await axios.post("TS_InsertDanhMucLoaiDM_MaNhom", {
					MaNhom: maNhom,
					LoaiDanhMucID: this.selectedLoaiDanhMuc.LoaiDanhMucID,
					DanhMucID: this.maDanhMucDangChon.map(nv => nv.DanhMucID).toString()
				})
					.then((res) => {
	
						CALL({ "MESS": "Đã thêm" });
						// this.dialogDanhMuc = false;
	
						return res.data.data
	
					})
					.catch((err) => {
	
						showMessage({ type: "red", title: error.response.data.Message });
						this.dialogDanhMuc = false;
						console.log(err);
					});
	
	
			},
			async getDSDanhMuc() {
				// console.log("Đang lấy danh sách danh mục để hiển thị dropdown...");
	
				// SỬA ĐOẠN NÀY: Bỏ .filter, lấy toàn bộ MaDM đang có trong danh sách sửa chữa
				const listMaDM = this.danhMucSuaChua
					.map(item => item.MaDM)
					.join(',');
	
				// Kiểm tra xem chuỗi này có chứa ID vừa thêm không
				console.log("Danh sách ID sẽ loại trừ:", listMaDM);
	
				this.dsDanhMuc = await axios.post("TS_DanhMuc_SelectByLoaiDanhMucID", {
					LoaiDanhMucID: this.selectedLoaiDanhMuc.LoaiDanhMucID,
					ListDanhMuc: listMaDM, // Gửi toàn bộ ID đang có
					NhomDanhMucID: 0,
					MaNhomKyThuat: this.selectedGroup.MaNhom
				})
					.then((res) => {
						return res.data.data;
					})
					.catch((err) => {
						console.log(err);
						return [];
					});
			},
	
	
			dialogThemNhanVienNhomSuaChua() {
				this.dialogThemNhanVien = false;
				this.insertNhanvien();
				console.log(this.selectedGroup);
				this.getDSNhanvienSuaChua();
				this.nhanVienDangChon = null;
				this.selectedPhongBan = null;
				this.dialogNhanVien = false;
	
			},
			openDialogNhom(item, maNhom) {
				this.maNhomDangChon = maNhom;
				this.getDSNhanvienSuaChua();
				this.selectedGroupName = item.TenNhom;
				this.selectedGroup = item;
				this.dialogNhanVien = true;
				this.getNhanVienPhongBan();
			},
			openDialog() {
				this.form = { tenNhom: '' };
				this.dialog = true;
			},
	
			openDiaLogEditNhom(group) {
				this.selectedGroup = group;
				console.log("Nhom: ", group.MaNhom);
				this.selectedGroupName = group.TenNhom;
				this.form.tenNhom = group.TenNhom;
				this.dialogEditNhom = true;
	
			},
	
			openDialogDelete(group) {
				this.selectedGroup = group;
				console.log("Nhom: ", group.MaNhom);
				this.showDialogDelete = true;
	
			},
			openDialogDanhMuc(group) {
				this.selectedGroup = group;
				// console.log("Nhom: ", group.MaNhom);
				this.selectedLoaiDanhMuc = group.tenLoaiDanhMuc || null;
				this.dialogDanhMuc = true;
				this.getDMSuachua(group.MaNhom);
			},
	
			async addNewCategory() {
				// 1. Thêm
				await this.insertDanhMucSuaChua(this.selectedGroup.MaNhom);
	
				// 2. Cập nhật danh sách (BẮT BUỘC CÓ AWAIT)
				await this.getDMSuachua(this.selectedGroup.MaNhom);
	
				// 3. Reset ô chọn
				this.maDanhMucDangChon = [];
	
				// 4. Gọi lại dropdown (nó sẽ dùng danh sách mới nhất từ bước 2 để loại trừ)
				if (this.selectedLoaiDanhMuc) {
					await this.getDSDanhMuc();
				}
			},
			openThemNhanVien(group, maNhom) {
				// console.log("MaNhom của nhóm được chọn:", this.selectedGroup.MaNhom);
				this.dialogThemNhanVien = true;
			},
	
		},
	}
</script>