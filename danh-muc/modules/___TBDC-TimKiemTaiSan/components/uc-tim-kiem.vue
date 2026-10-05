<template>
	<v-card>
		<v-expansion-panels variant="accordion" v-model="cachTim">
			<v-expansion-panel :value="3">
				<v-expansion-panel-title min-height="50px" class="py-0 text-subtitle-1 font-weight-medium"><v-icon
						class="mr-2">mdi-magnify</v-icon>Tìm
					theo mã, tên, người quản lý, tình trạng</v-expansion-panel-title>
				<v-expansion-panel-text>
					<v-row @keydown.enter.prevent="locTaiSanTheoDieuKien">
						<v-col cols="12" md="2">
							<v-btn block prepend-icon="mdi-qrcode-scan" color="primary" variant="tonal"
								@click="showQrDialog = true">
								Quét mã tài sản
							</v-btn>
						</v-col>

						<v-col cols="12" md="2">
							<v-text-field density="compact" label="Mã TS" v-model="nhapMaTS">
							</v-text-field>
						</v-col>

						<v-col cols="12" md="2">
							<v-text-field density="compact" label="Tên tài sản" v-model="nhapTenTS">
							</v-text-field>
						</v-col>

						<v-col cols="12" md="2">
							<v-autocomplete :return-object="true" density="compact" label="Người quản lý"
								:items="dsNguoiQuanLy" v-model="nguoiDangChon" item-title="HoTen" item-value="MaNV">
							</v-autocomplete>
						</v-col>

						<v-col cols="12" md="2">
							<v-autocomplete :return-object="true" density="compact" label="Tình trạng kiểm kê"
								:items="dsTinhTrangKiemKe" v-model="tinhTrangKKDangChon" item-title="TrangThaiMoTa"
								item-value="TrangThaiThucTe">
							</v-autocomplete>
						</v-col>

						<v-col cols="12" md="2">
							<v-autocomplete :return-object="true" density="compact" label="Tình trạng"
								:items="dsTinhTrang" v-model="tinhTrangDangChon" item-title="TenTinhTrang"
								item-value="TinhTrangID">
							</v-autocomplete>
						</v-col>
					</v-row>

					<v-card-actions class="py-0">
						<v-spacer></v-spacer>
						<v-btn rounded color="primary" prepend-icon="mdi-magnify" text="Tìm kiếm" variant="tonal"
							@click="locTaiSanTheoDieuKien"></v-btn>
						<v-btn rounded color="blue-grey" prepend-icon="mdi-rotate-3d-variant" text="Đặt lại"
							variant="tonal" @click="resetBoLoc"></v-btn>
					</v-card-actions>
				</v-expansion-panel-text>
			</v-expansion-panel>
			<v-expansion-panel :value="1">
				<v-expansion-panel-title min-height="50px" class="py-0 text-subtitle-1 font-weight-medium"><v-icon
						class="mr-2">mdi-magnify</v-icon> Tìm
					theo vị trí - loại tài sản</v-expansion-panel-title>
				<v-expansion-panel-text>
					<v-row @keydown.enter.prevent="getDanhSachTaiSan">
						<v-col>
							<v-row>
								<v-col cols="12" md="2">
									<v-autocomplete clearable :return-object="true" density="compact"
										v-model="coSoDangChon" label="Cơ sở" :items="dsCoSo" item-title="TenCoSo"
										item-value="MaCoSo">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" md="2">
									<v-autocomplete clearable :return-object="true" density="compact"
										v-model="toaNhaDangChon" label="Toà nhà" :items="dsToaNha" item-title="ToaNha"
										item-value="MaToaNha">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" md="2">
									<v-autocomplete clearable :return-object="true" density="compact"
										v-model="phongBanDangChon" label="Phòng ban" :items="dsPhongBan"
										item-title="TenPhongBan" item-value="PhongBanID">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" md="3">
									<v-autocomplete clearable :return-object="true" density="compact"
										v-model="viTriDangChon" label="Vị trí" :items="dsViTri"
										item-title="TenViTriPhong" item-value="MaViTriPhong">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" md="3">
									<v-autocomplete clearable :return-object="true" density="compact" label="Loại"
										:items="dsLoai" v-model="loaiDangChon" item-title="TenDanhMuc"
										item-value="MaDM">
									</v-autocomplete>
								</v-col>
							</v-row>
							<v-row>
								<v-col>
									<v-card-actions class="py-0">
										<v-spacer></v-spacer>
										<v-btn rounded color="primary" prepend-icon="mdi-magnify" text="Tìm tài sản"
											variant="tonal" @click="getDanhSachTaiSan"></v-btn>
									</v-card-actions>
								</v-col>
							</v-row>
						</v-col>
					</v-row>
				</v-expansion-panel-text>
			</v-expansion-panel>
			<v-expansion-panel v-if="dsThongSoKyThuat.length>0" :value="2">
				<v-expansion-panel-title min-height="50px" class="py-0 text-subtitle-1 font-weight-medium"><v-icon
						class="mr-2">mdi-magnify</v-icon>Tìm
					theo thông số kỹ thuật</v-expansion-panel-title>
				<v-expansion-panel-text>
					<v-row v-if="dsThongSoKyThuat.length > 0" @keydown.enter.prevent="timTheoThongSoKyThuat">
						<v-col>
							<v-row>
								<v-col v-for="item in dsThongSoKyThuat" :key="item.label" cols="12" md="2" class="py-2">
									<v-autocomplete v-model="thongSoTim[item.label]" :label="item.label"
										:items="item.values" item-title="text" item-value="value" clearable
										density="compact" />
								</v-col>
							</v-row>

							<v-row>
								<v-col>
									<v-card-actions class="py-0">
										<v-spacer></v-spacer>
										<v-btn rounded color="primary" prepend-icon="mdi-magnify"
											text="Tìm theo thông số kỹ thuật" variant="tonal"
											@click="timTheoThongSoKyThuat" />
									</v-card-actions>
								</v-col>
							</v-row>
						</v-col>
					</v-row>

				</v-expansion-panel-text>
			</v-expansion-panel>


		</v-expansion-panels>
	</v-card>

	<v-card class="mt-3">
		<v-card-title class="d-flex text-primary">

			Danh sách tài sản [{{dsTaiSan.length}}]
			<v-spacer></v-spacer>
			<v-text-field class="" style="max-width: 300px" v-model="search" density="compact" label="Search"
				prepend-inner-icon="mdi-magnify" variant="solo-filled" flat hide-details single-line></v-text-field>

		</v-card-title>
		<v-card-text>


			<v-divider></v-divider>
			<v-data-table-virtual :loading="loading" :headers="headerTaiSan" :items="dsTaiSan" item-value="MaCaBiet"
				hide-default-footer height="600" density="compact" fixed-header :search="search">

				<template v-slot:item.TenTaiSan="{item}">
					<uc-asset-info :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet" :mataisan="item.MaTS"
						classforname="text-subtitle-2" />
				</template>

			</v-data-table-virtual>
		</v-card-text>
	</v-card>

	<v-dialog :fullscreen="$vuetify.display.xs" v-model="showQrDialog" width="500">
		<v-card>
			<v-toolbar>
				<v-toolbar-title class="text-primary">Quét mã tài sản</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn size="small" icon="mdi-close" @click="showQrDialog = false"></v-btn>
			</v-toolbar>
			<v-card-text style="padding: 0; aspect-ratio: 1 / 1; width: 100%">
				<uc-qr v-model="maCaBietQuet" @scan-success="showInfoAsset" ref="qrScanner">
					<template #default>
						<v-row class="mt-2">
							<v-col class="px-0" cols="4"></v-col>
							<v-col class="px-0" cols="4" style="text-align: center;">
								<v-btn icon variant="flat" color="primary" @click="$refs.qrScanner?.triggerFileInput()">
									<v-icon color="white">mdi-image</v-icon>
								</v-btn>
								<div style="color: gray; font-size: 0.75rem; margin-top: 4px;">Thư viện</div>
							</v-col>
							<v-col class="px-0" cols="4"></v-col>
						</v-row>
					</template>
				</uc-qr>
			</v-card-text>
		</v-card>
	</v-dialog>


	<uc-confirm ref="confirm"></uc-confirm>
	<uc-asset-info ref="assetInfoRef"></uc-asset-info>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				tinhTrangKKDangChon: null,
				dsTinhTrangKiemKe: [],
				tinhTrangDangChon: null,
				thongSoTim: {},
				showQrDialog: false,
				maCaBietQuet: null,
				loading: false,
				dsTinhTrang: [],
				operators: ['=', '>=', '<=', '>', '<'],
				filters: {
					ram: { operator: '>=', value: null, },
					cpu: '', storage: {
						operator: '=', value: null,
					},
				},
				tuNgay: null,
				denNgay: null,
				nguoiDangChon: null,
				search: null,
				dsNguoiQuanLy: [],
				nhapTenTS: null,
				nhapMaTS: null,
				dsTaiSan: [],
				dsToaNha: [],
				dsCoSo: [],
				dsPhongBan: [],
				cachTim: 3,
				dsViTri: [],
				dsLoai: [],
				dsThongSoKyThuat: [],
				coSoDangChon: {
					"TenCoSo": "Tất cả",
					"MaCoSo": 0
				},
				toaNhaDangChon: {
					"ToaNha": "Tất cả",
					"MaToaNha": 0
				},
				phongBanDangChon: {
					"TenPhongBan": "Tất cả",
					"PhongBanID": '0'
				},
				viTriDangChon: {
					"TenViTriPhong": "Tất cả",
					"MaViTriPhong": 0
				},
				loaiDangChon: {
					"TenDanhMuc": "Tất cả",
					"MaDM": 0
				},
				headerTaiSan: [
					{ title: 'STT', key: 'STT' },
					{ title: 'Mã TS', key: 'MaVach' },
					{ title: 'Tên tài sản', key: 'TenTaiSan' },
					{ title: 'Phòng ban', key: 'TenPhongBan' },
					{ title: 'Tên vị trí phòng', key: 'TenViTriPhong' },
					{ title: 'Hãng SX', key: 'TenHang' },
					{ title: 'Người quản lý', key: 'TenCaNhanDuocCap' },
					{ title: 'Ngày bảo hành', key: 'NgayBaoHanh' },
	
				],
				rules: {
					required: (value) => {
						if (value === null || value === undefined || value === "") return 'Trường này là bắt buộc';
						if (typeof value === 'object' && Object.keys(value).length === 0) return 'Trường này là bắt buộc';
						return true;
					},
				},
			}
		},
		mounted() {
			this.getDanhSachCoSo();
			this.getDanhSachToaNha();
			this.getDanhSachPhongBan();
			this.getDanhSachViTri();
			this.getDanhSachDanhMucTaiSan();
			this.getNguoiQuanLy();
			this.getDanhSachTinhTrangKiemKe();
			// this.getDanhSachTaiSan();
			this.getDanhSachTinhTrang();
		},
		computed: {},
		watch: {
			filters: {
				deep: true,
				handler(val) {
					this.$emit('update:filters', val);
				},
			},
			coSoDangChon() {
				// Khi chọn Cơ sở -> Reset Tòa nhà về tất cả (tuỳ logic bạn muốn lọc tòa nhà theo cơ sở không)
				// Reset Vị trí về mặc định
				this.viTriDangChon = { "TenViTriPhong": "Tất cả", "MaViTriPhong": 0 };
	
				// Gọi lại danh sách vị trí để lọc theo Cơ sở mới chọn
				this.getDanhSachViTri();
	
				// Tùy chọn: Nếu bạn muốn lọc cả danh sách Tòa nhà theo Cơ sở thì gọi hàm getToaNha ở đây
				// this.getDanhSachToaNha();
			},
	
			toaNhaDangChon() {
				// Khi chọn Tòa nhà -> Reset Vị trí về mặc định
				this.viTriDangChon = { "TenViTriPhong": "Tất cả", "MaViTriPhong": 0 };
	
				// Quan trọng: Gọi lại danh sách vị trí để lọc theo Tòa nhà mới chọn
				this.getDanhSachViTri();
			},
	
			phongBanDangChon() {
				this.viTriDangChon = { "TenViTriPhong": "Tất cả", "MaViTriPhong": 0 };
				this.getDanhSachViTri();
			},
	
			viTriDangChon() {
				// this.getDanhSachTaiSan();
			},
	
			loaiDangChon() {
				// this.getDanhSachTaiSan();
				this.getThongSoKyThuat();
			}
		},
		methods: {
			async getThongSoKyThuat() {
				try {
					const response = await axios.post("TS_ThongSoKyThuat_Select_ThongSo_ByMaDanhMuc", {
						MaDanhMuc: this.loaiDangChon.MaDM
					});
					let kq = response.data.data || [];
					const grouped = kq.reduce((acc, item) => {
						const found = acc.find(x => x.label === item.TenThongSo)
						if (found) {
							if (!found.values.includes(item.GiaTri)) {
								found.values.push(item.GiaTri)
							}
						} else {
							acc.push({
								label: item.TenThongSo,
								values: [item.GiaTri]
							})
						}
						return acc
					}, [])
					this.dsThongSoKyThuat = grouped;
					console.log(this.dsThongSoKyThuat)
	
				} catch (error) {
					console.log(error)
					showMessage({ type: "red", title: error.response.data.Message })
				}
			},
	
			async showInfoAsset() {
				this.showQrDialog = false;
				await this.$refs.assetInfoRef.open(this.maCaBietQuet);
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
	
			async timTheoThongSoKyThuat() {
				try {
					this.loading = true;
	
					// xóa key có giá trị null
					const payload = Object.fromEntries(
						Object.entries(this.thongSoTim).filter(([key, val]) => val != null && val !== '')
					)
					const response = await axios.post("TS_CaBietTaiSan_Select_ByThongSoKyThuat", {
						DieuKienJSON: payload
					});
					this.dsTaiSan = response.data.data || [];
	
				} catch (error) {
	
					showMessage({ type: "red", title: error.response.data.Message })
				}
				finally {
					this.loading = false;
				}
			},
	
			async getDanhSachCoSo() {
				try {
					const response = await axios.post("TS_CoSo_Select");
					this.dsCoSo = response.data.data || [];
					this.dsCoSo.unshift({ "TenCoSo": "Tất cả", "MaCoSo": 0 })
				} catch (error) {
					console.error('Error fetching assets:', error);
					showMessage({ type: "red", title: error.response.data.Message })
				}
			},
	
			async getDanhSachToaNha() {
				try {
					const response = await axios.post("TS_ToaNha_Select");
					this.dsToaNha = response.data.data || [];
					this.dsToaNha.unshift({ "ToaNha": "Tất cả", "MaToaNha": 0 })
				} catch (error) {
					console.error('Error fetching assets:', error);
					showMessage({ type: "red", title: error.response.data.Message })
				}
			},
	
			async getDanhSachViTri() {
				try {
					let phongBanID = this.phongBanDangChon?.PhongBanID ?? '0';
					// Lấy giá trị Cơ sở và Tòa nhà đang chọn
					let maCoSo = this.coSoDangChon?.MaCoSo || 0;
					let maToaNha = this.toaNhaDangChon?.MaToaNha || 0;
	
					const response = await axios.post("TS_ViTriPhongBan_SelectByPhongBan", {
						PhongBanID: phongBanID == '0' ? null : String(phongBanID),
						MaCoSo: maCoSo,     // Truyền thêm
						MaToaNha: maToaNha  // Truyền thêm
					});
	
					this.dsViTri = response.data.data || [];
					this.dsViTri.unshift({ "TenViTriPhong": "Tất cả", "MaViTriPhong": 0 });
	
					// Reset vị trí đang chọn về 'Tất cả' nếu danh sách thay đổi
					if (!this.dsViTri.find(x => x.MaViTriPhong === this.viTriDangChon?.MaViTriPhong)) {
						this.viTriDangChon = { "TenViTriPhong": "Tất cả", "MaViTriPhong": 0 };
					}
	
				} catch (error) {
					console.error('Lỗi khi lấy danh sách vị trí:', error);
				}
			},
	
			async getDanhSachDanhMucTaiSan() {
				try {
					const response = await axios.post("TS_DanhMuc_Select");
					this.dsLoai = response.data.data || [];
					this.dsLoai.unshift({ "TenDanhMuc": "Tất cả", "MaDM": 0 });
				} catch (error) {
					console.error('Error fetching assets:', error);
				}
			},
	
			async getDanhSachPhongBan() {
				try {
					const response = await axios.post("TS_PhongBan_Select");
					this.dsPhongBan = response.data.data || [];
					this.dsPhongBan.unshift({ "TenPhongBan": "Tất cả", "PhongBanID": 0 })
				} catch (error) {
					console.error('Error fetching assets:', error);
				}
			},
	
			async getDanhSachTaiSan() {
				try {
	
					this.loading = true;
					let response = [];
					if (!this.phongBanDangChon || !this.viTriDangChon || !this.loaiDangChon) {
						return;
					}
					response = await axios.post("TS_TaiSan_Select_CoSo_ToaNha_PhongBan_TinhTrang_ViTri_DanhMuc_Update", {
						TinhTrangID: -1,
						PhongBanID: this.phongBanDangChon.PhongBanID,
						ViTriPhongID: this.viTriDangChon?.MaViTriPhong || 0,
						DanhMucID: this.loaiDangChon?.MaDM || 0,
						MaCoSo: this.coSoDangChon?.MaCoSo || 0,
						MaToaNha: this.toaNhaDangChon?.MaToaNha || 0
					});
					this.dsTaiSan = response.data.data || [];
	
				} catch (error) {
					console.error('Error fetching assets:', error);
				} finally {
					this.loading = false
				}
			},
	
			async getNguoiQuanLy() {
				this.dsNguoiQuanLy = await axios.post("TS_Select_NhanVien_AllPhongBan")
					.then((responsed) => {
						const dataRaw = responsed.data.data || [];
	
						// --- ĐOẠN CODE LỌC TRÙNG ---
						// Sử dụng Map để giữ lại các MaNV duy nhất
						const uniqueNhanVien = Array.from(new Map(dataRaw.map(item => [item.MaNV, item])).values());
	
						return uniqueNhanVien;
						// ---------------------------
					})
					.catch((error) => {
						// Kiểm tra an toàn để tránh lỗi nếu error.response không tồn tại
						const msg = error.response?.data?.Message || "Lỗi lấy danh sách người quản lý";
						showMessage({ type: "red", title: msg })
						return []; // Trả về mảng rỗng nếu lỗi
					})
			},
	
			async getDanhSachTinhTrangKiemKe() {
				this.dsTinhTrangKiemKe = await axios.post("TS_TrangThaiThucTe_Select")
					.then((responsed) => {
						return responsed.data.data
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
			},
	
			resetBoLoc() {
				// 1. Đưa các biến lọc về mặc định
				this.nhapMaTS = null;
				this.nhapTenTS = null;
				this.nguoiDangChon = null;
				this.tinhTrangKKDangChon = null;
				this.tinhTrangDangChon = null;
				this.coSoDangChon = { "TenCoSo": "Tất cả", "MaCoSo": 0 };
				this.toaNhaDangChon = { "ToaNha": "Tất cả", "MaToaNha": 0 };
				this.phongBanDangChon = { "TenPhongBan": "Tất cả", "PhongBanID": '0' };
				this.viTriDangChon = { "TenViTriPhong": "Tất cả", "MaViTriPhong": 0 };
				this.loaiDangChon = { "TenDanhMuc": "Tất cả", "MaDM": 0 };
	
				// 2. Xóa các bộ lọc thông số kỹ thuật (nếu có)
				this.thongSoTim = {};
				this.dsTaiSan = [];
			},
	
			async locTaiSanTheoDieuKien() {
				try {
					this.loading = true;
					this.dsTaiSan = [];
					const response = await axios.post('TS_TaiSan_LocDieuKienTim', {
						MaVach: this.nhapMaTS || '',
						TenTaiSan: this.nhapTenTS || '',
						CaNhanDuocCap: this.nguoiDangChon?.MaNV || '',
						// TuNgay: this.tuNgay,
						// DenNgay: this.denNgay,
						TrangThaiThucTe: this.tinhTrangKKDangChon?.TrangThaiThucTe ?? -1,
						TinhTrangDaThanhLy: this.tinhTrangDangChon?.TinhTrangID || -1,
					});
	
					this.dsTaiSan = response.data.data;
				} catch (error) {
					console.error('Lỗi khi gọi API lọc tài sản:', error);
					showMessage({ type: "red", title: error.response.data.Message })
				} finally {
					this.loading = false
				}
			},
	
			async getDanhSachTinhTrang() {
				this.dsTinhTrang = await axios.post("TS_TaiSan_LocTinhTrang")
					.then((responsed) => {
						return responsed.data.data
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
			},
	
		},
	}
</script>