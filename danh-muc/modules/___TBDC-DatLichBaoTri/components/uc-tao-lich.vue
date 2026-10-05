<template>
	<v-dialog v-model="dialog" fullscreen persistent transition="dialog-bottom-transition">
		<v-card>
			<v-toolbar density="compact" color="primary">
				<v-toolbar-title>Thiết lập lịch bảo trì</v-toolbar-title>
				<v-btn icon="mdi-close" variant="text" @click="dialog = false" />
			</v-toolbar>

			<v-form ref="form" @submit.prevent="submit">
				<v-card-text class="pa-4">
					<v-row>
						<v-col cols="12" md="4" lg="4">
							<div class="text-subtitle-2 text-primary mb-2 text-uppercase">1. Thông tin chung</div>
							<v-card variant="outlined" class="pa-3 mb-4 bg-grey-lighten-5">
								<v-text-field v-model="formData.tenLich" label="Tên đợt bảo trì (*)" density="compact"
									variant="outlined" :rules="rules.required" class="mb-2" bg-color="white" />
								<v-text-field v-model="displayDonGia" label="Chi phí dự kiến / TS" density="compact"
									variant="outlined" @keypress="onlyNumberInput" bg-color="white" suffix="VND" />
							</v-card>

							<div class="text-subtitle-2 text-primary mb-2 text-uppercase">2. Thời gian & Lặp lại</div>
							<v-card variant="outlined" class="pa-3 mb-4 bg-grey-lighten-5">
								<v-select v-model="formData.loaiDinhKi" :items="CONSTANTS.REPEAT_TYPES"
									item-title="title" item-value="value" label="Định kỳ" density="compact"
									variant="outlined" bg-color="white" hide-details class="mb-2" />

								<v-text-field v-if="formData.loaiDinhKi !== 4" v-model="formData.soLanDinhKi"
									label="Khoảng cách giữa các lần (tuần/tháng...)" placeholder="VD: 2 tuần 1 lần"
									type="number" min="1" density="compact" variant="outlined" bg-color="white"
									class="mb-2" />

								<div v-if="formData.loaiDinhKi === 1" class="mb-3">
									<label class="text-caption font-weight-bold mb-1 d-block">Chọn thứ lặp lại:</label>
									<v-btn-toggle v-model="formData.recurringDay" color="primary" density="compact"
										divided mandatory class="d-flex flex-wrap bg-white w-100">
										<v-btn v-for="day in CONSTANTS.DAYS_OF_WEEK" :key="day.value" :value="day.value"
											size="x-small" class="flex-grow-1" style="min-width: 30px;">
											{{ day.label }}
										</v-btn>
									</v-btn-toggle>
								</div>

								<v-text-field v-if="formData.loaiDinhKi === 2" v-model="formData.ngayTrongThang"
									label="Ngày diễn ra (1-31)" type="number" density="compact" variant="outlined"
									bg-color="white" :rules="rules.dayInMonth" class="mb-2" />

								<uc-date-picker v-model="formData.startDate" label="Ngày bắt đầu (*)" :min="minDate"
									:rules="rules.required" class="mb-2" />

								<v-text-field v-model="formData.soLanLap" label="Số lần lặp lại" type="number"
									density="compact" variant="outlined" bg-color="white" suffix="lần"
									:disabled="formData.loaiDinhKi === 4" />
							</v-card>

							<div class="d-flex justify-space-between align-center mb-2">
								<div class="text-subtitle-2 text-primary text-uppercase">3. Checklist công việc</div>
								<v-btn size="x-small" color="primary" variant="text" prepend-icon="mdi-plus"
									@click="addTask">Thêm</v-btn>
							</div>
							<v-card variant="outlined" class="pa-3 bg-grey-lighten-5"
								style="max-height: 200px; overflow-y: auto;">
								<div v-if="formData.taskList.length === 0"
									class="text-caption text-center text-grey py-2">Chưa có công việc nào.</div>
								<div v-for="(task, index) in formData.taskList" :key="index"
									class="d-flex align-center mb-2">
									<span class="text-caption mr-2 text-grey font-weight-bold">{{ index + 1 }}.</span>
									<v-text-field v-model="task.name" placeholder="Tên công việc..." density="compact"
										variant="outlined" bg-color="white" hide-details />
									<v-btn icon="mdi-delete" size="small" color="red" variant="text" class="ml-1"
										@click="removeTask(index)"></v-btn>
								</div>
							</v-card>

						</v-col>

						<v-col cols="12" md="8" lg="8">

							<div class="d-flex justify-space-between align-center mb-2">
								<div class="text-subtitle-2 text-primary text-uppercase">4. Chọn tài sản bảo trì</div>
								<div class="text-caption text-grey">Đã chọn: <b class="text-primary">{{
									selectedAssets.length }}</b> tài sản</div>
							</div>

							<div class="d-flex align-center gap-2 my-2" style="gap: 10px;">

								<v-select v-model="filters.coSo" :items="lists.coSo" item-title="TenCoSo"
									item-value="MaCoSo" label="Cơ sở" density="compact" variant="solo-filled"
									return-object hide-details @update:model-value="onCoSoChange" />

								<v-autocomplete v-model="filters.khu" :return-object="false" :items="lists.dsKhu"
									item-title="ToaNha" item-value="MaToaNha" label="Khu" density="compact"
									variant="solo-filled" hide-details />

								<v-autocomplete v-model="filters.phongBan" :items="lists.phongBan"
									item-title="TenPhongBan" item-value="PhongBanID" label="Phòng ban" density="compact"
									variant="solo-filled" return-object hide-details
									@update:model-value="onPhongBanChange" />



								<v-autocomplete v-model="filters.viTri" :items="lists.viTri" item-title="TenViTriPhong"
									item-value="MaViTriPhong" :return-object="false" label="Vị trí" density="compact"
									variant="solo-filled" multiple hide-details></v-autocomplete>

								<v-autocomplete v-model="filters.loaiTaiSan" :return-object="false"
									:items="lists.loaiTaiSan" item-title="TenLoai" item-value="MaLoai" label="Loại"
									density="compact" variant="solo-filled" @update:model-value="onLoaiChange"
									hide-details />

								<v-autocomplete v-model="filters.danhMuc" multiple :return-object="false"
									:items="lists.dsDanhMuc" item-title="TenDanhMuc" item-value="MaDM" label="Danh mục"
									density="compact" variant="solo-filled" hide-details />

								<v-btn color="primary" height="40" prepend-icon="mdi-refresh" @click="getDanhSachTaiSan"
									:loading="loading">
									Tải dữ liệu
								</v-btn>
							</div>
							<div>
								<v-text-field class="mt-1" v-model="search" density="compact" variant="outlined"
									label="Tìm kiếm" hide-details bg-color="white" prepend-inner-icon="mdi-magnify" />
							</div>

							<v-card border class="mb-4">
								<v-data-table :headers="headers" :items="lists.dsTaiSan" v-model="selectedAssets"
									show-select item-value="MaCaBiet" height="350" :items-per-page="100" fixed-header
									:loading="loading" :search="search" hover>
									<template #item.TenTaiSan="{ item }">
										<!-- <uc-asset-info :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet"
											classforname="font-weight-bold text-primary" /> -->
									</template>
								</v-data-table>
							</v-card>

							<div class="text-subtitle-2 text-primary mb-2 text-uppercase">5. Phân công trách nhiệm</div>
							<v-card variant="outlined" class="pa-3 bg-grey-lighten-5">
								<v-row>
									<v-col cols="12" md="6" class="border-e-md">
										<div
											class="font-weight-bold text-caption mb-2 text-uppercase text-grey-darken-2">
											<v-icon start size="small">mdi-account-hard-hat</v-icon> Đơn vị thực hiện
										</div>

										<v-radio-group v-model="formData.radioChiuTrachNhiem" inline density="compact"
											hide-details class="mb-2">
											<v-radio label="Đối tác" value="1" color="primary"></v-radio>
											<v-radio label="Nội bộ" value="2" color="primary"></v-radio>
										</v-radio-group>

										<div v-if="formData.radioChiuTrachNhiem === '2'">
											<v-autocomplete v-model="formData.dsNhanVienThucHien"
												:items="lists.nhanVien" item-title="HoTen" item-value="MaNV"
												label="Chọn nhân viên thực hiện" multiple chips closable-chips
												density="compact" variant="outlined" bg-color="white"
												hint="Có thể chọn nhiều người" persistent-hint>
												<template v-slot:chip="{ props, item }">
													<v-chip v-bind="props" :text="item.raw.HoTen" label
														size="small"></v-chip>
												</template>
											</v-autocomplete>
										</div>

										<div v-else>
											<v-autocomplete v-model="formData.donViBaoTri" :items="lists.donViBaoTri"
												item-title="TenDoiTac" item-value="MaDoiTac" label="Chọn đơn vị đối tác"
												density="compact" variant="outlined" bg-color="white" hide-details
												prepend-inner-icon="mdi-domain" />
										</div>
									</v-col>

									<v-col cols="12" md="6">
										<div
											class="font-weight-bold text-caption mb-2 text-uppercase text-grey-darken-2">
											<v-icon start size="small">mdi-account-eye</v-icon> Người giám sát (Nội bộ)
										</div>

										<div style="height: 40px" class="d-none d-md-block"></div>

										<v-autocomplete v-model="formData.dsNguoiGiamSat" :items="lists.nhanVien"
											item-title="HoTen" item-value="MaNV" label="Chọn người giám sát" multiple
											chips closable-chips density="compact" variant="outlined" bg-color="white"
											hint="Ai chịu trách nhiệm nghiệm thu?" persistent-hint>
											<template v-slot:chip="{ props, item }">
												<v-chip v-bind="props" :text="item.raw.HoTen" label
													size="small"></v-chip>
											</template>
										</v-autocomplete>
									</v-col>
								</v-row>
							</v-card>

							<v-textarea v-model="formData.note" label="Ghi chú chung" rows="2" variant="outlined"
								density="compact" hide-details class="mt-3" />
						</v-col>
					</v-row>
				</v-card-text>

				<v-divider></v-divider>
				<v-card-actions class="pt-2">
					<v-spacer></v-spacer>
					<v-btn color="grey-darken-1" variant="text" @click="dialog = false">Hủy bỏ</v-btn>
					<v-btn color="primary" variant="elevated" prepend-icon="mdi-check" type="submit"
						:loading="submitting">
						Hoàn tất
					</v-btn>
				</v-card-actions>
			</v-form>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	data() {
		return {
			dialog: false, loading: false, submitting: false, search: '', selectedAssets: [],
			CONSTANTS: {
				REPEAT_TYPES: [{ value: 4, title: 'Theo Ngày' }, { value: 1, title: 'Theo Tuần' }, { value: 2, title: 'Theo Tháng' }, { value: 3, title: 'Theo Năm' }],
				DAYS_OF_WEEK: [{ label: "T2", value: 2 }, { label: "T3", value: 3 }, { label: "T4", value: 4 }, { label: "T5", value: 5 }, { label: "T6", value: 6 }, { label: "T7", value: 7 }, { label: "CN", value: 1 }]
			},
			rules: { required: [v => !!v || 'Bắt buộc'], dayInMonth: [v => (v > 0 && v < 32) || '1-31'] },
			headers: [{ title: 'Tên tài sản', key: 'TenTaiSan' }, { title: 'Mã', key: 'MaVach' }, { title: 'Danh mục', key: 'TenDanhMuc' }, { title: 'Vị trí', key: 'TenViTriPhong' }],

			formData: {
				tenLich: '', soLanDinhKi: null, loaiDinhKi: 1, startDate: null,
				ngayTrongThang: null, soLanLap: 1, donGia: 0, recurringDay: 2, note: '',

				radioChiuTrachNhiem: '1',
				donViBaoTri: null,
				dsNhanVienThucHien: [], // Mảng ID
				dsNguoiGiamSat: [],     // Mảng ID

				taskList: [{ name: 'Kiểm tra hoạt động' }]
			},

			filters: { coSo: null, phongBan: null, viTri: null, loaiTaiSan: null, khu: null, danhMuc: null },
			lists: { coSo: [], phongBan: [], viTri: [], loaiTaiSan: [], nhanVien: [], donViBaoTri: [], dsTaiSan: [], dsKhu: [], dsDanhMuc: [] }
		};
	},
	computed: {
		minDate() { return new Date(); },
		displayDonGia: {
			get() { return this.formData.donGia ? Number(this.formData.donGia).toLocaleString('vi-VN') : ''; },
			set(val) { this.formData.donGia = val ? Number(val.replace(/[^0-9]/g, '')) : 0; }
		}
	},

	methods: {
		open() {
			this.dialog = true;
			// this.initData();
			this.selectedAssets = [];
			this.formData.taskList = [{ name: '' }];
			// Reset nhân sự
			this.formData.dsNhanVienThucHien = [];
			this.formData.dsNguoiGiamSat = [];


			if (!this.formData.loaiDinhKi) this.formData.loaiDinhKi = 1;
			if (!this.formData.recurringDay) this.formData.recurringDay = 2;
		},
		addTask() { this.formData.taskList.push({ name: '' }); },
		removeTask(index) { this.formData.taskList.splice(index, 1); },
		onlyNumberInput(e) { if (e.key < '0' || e.key > '9') e.preventDefault(); },

		async initData() {
			try {
				const [resCoSo, resLoai, resDoiTac] = await Promise.all([
					axios.post("TS_CoSo_Select_Combobox"), axios.post("TS_LoaiDanhMuc_Select_Option"), axios.post("TS_SelectDoiTacBaoTri"),
				]);
				this.lists.coSo = resCoSo.data.data || [];
				await this.getDanhSachDanhMucTaiSan();
				this.lists.donViBaoTri = resDoiTac.data.data || [];
				await this.getNhanVien();
				this.filters = { coSo: null, phongBan: { TenPhongBan: "Tất cả", PhongBanID: 0 }, viTri: null, loaiTaiSan: 0, danhMuc: [0] };
				this.lists.loaiTaiSan = [{ TenLoai: "Tất cả", MaLoai: 0 }, ...(resLoai.data.data || [])];

			} catch (e) { console.error(e); }
		},
		async onCoSoChange() {
			if (!this.filters.coSo) return;

			await this.getDanhSachKhu();

			const res = await axios.post("TS_PhongBan_SelectByMaToaNha", { MaCoSo: this.filters.coSo.MaCoSo });
			this.lists.phongBan = [{ TenPhongBan: "Tất cả", PhongBanID: -1 }, ...res.data.data];
			this.filters.phongBan = this.lists.phongBan[0];
			this.onPhongBanChange();

		},
		async onLoaiChange() {
			if (!this.filters.loaiTaiSan) return;

			await this.getDanhSachDanhMucTaiSan();
		},

		async onKhuChange() {
			if (!this.filters.khu) return;
			await this.getDanhSachToaNha();
			const res = await axios.post("TS_PhongBan_SelectByMaToaNha", { MaCoSo: this.filters.coSo.MaCoSo });
			this.lists.phongBan = [{ TenPhongBan: "Tất cả", PhongBanID: 'ALL' }, ...res.data.data];
			this.filters.phongBan = this.lists.phongBan[0];
			this.onPhongBanChange();

		},

		async onPhongBanChange() {
			const res = await axios.post("TS_ViTriPhong_SelectByPhongBanCoSo", { PhongBanID: this.filters.phongBan.PhongBanID, MaCoSo: this.filters.coSo?.MaCoSo });
			this.lists.viTri = [{ TenViTriPhong: "Tất cả", MaViTriPhong: 0 }, ...res.data.data];
			this.filters.viTri = [0];
			// this.getDanhSachTaiSan();
		},
		async getDanhSachKhu() {
			try {
				// 1. Lấy mã cơ sở an toàn (nếu null thì coi như là 0)
				let maCoSo = this.filters.coSo?.MaCoSo || 0;

				let response;

				// 2. Gọi API tùy theo có chọn cơ sở hay không
				if (maCoSo !== 0) {
					response = await axios.post("TS_ToaNha_SelectByMaCoSo_Combobox", {
						MaCoSo: maCoSo
					});
				} else {
					response = await axios.post("TS_ToaNha_Select");
				}

				// 3. Cập nhật danh sách
				this.lists.dsKhu = response.data.data || [];

				// 4. Tạo đối tượng mặc định
				const itemTatCa = { "ToaNha": "Tất cả", "MaToaNha": 0 };
				this.lists.dsKhu.unshift(itemTatCa);


				// 5. QUAN TRỌNG NHẤT: Gán giá trị đang chọn bằng chính phần tử đầu tiên của danh sách
				// Việc này ngăn chặn Vue tạo ra vòng lặp render
				this.filters.dsKhu = 0;

			} catch (error) {
				console.error('Lỗi lấy danh sách tòa nhà:', error);
			}
		},

		async getDanhSachDanhMucTaiSan() {
			try {
				const response = await axios.post("TS_DanhMuc_Select_byLoaiForCombobox", { MaLoai: this.filters.loaiTaiSan || 0 });
				this.lists.dsDanhMuc = response.data.data || [];
				this.lists.dsDanhMuc.unshift({ "TenDanhMuc": "Tất cả", "MaDM": 0 });
				this.filters.danhMuc = [0];
			} catch (error) {
				console.error('Error fetching assets:', error);
			}
		},

		async getDanhSachTaiSan() {
			if (!this.filters.coSo) return;
			this.loading = true;
			try {
				const res = await axios.post("TS_TaiSan_Select_PhongBan_TinhTrang_ViTri_DanhMuc_BaoTri", {
					CoSoID: this.filters.coSo.MaCoSo, TinhTrangID: -1, PhongBanID: this.filters.phongBan.PhongBanID,
					ListViTriPhong: this.filters.viTri.toString(), LoaiDanhMuc: this.filters.loaiTaiSan,
					MaToaNha: this.filters.khu,
					ListDanhMuc: this.filters.danhMuc.toString()
				});
				this.lists.dsTaiSan = res.data.data || [];
			} finally { this.loading = false; }
		},
		async getNhanVien() {
			try {
				const res = await axios.post("TS_NhanVien_Select_BaoTri")
				this.lists.nhanVien = res.data.data || [];
			} catch (error) {
				const errorMsg = error.response?.data?.Message || "Lỗi lấy nhân viên bảo trì";
				showMessage({ type: "red", title: errorMsg });
			}
		},
		async submit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid || this.selectedAssets.length === 0) return alert("Vui lòng kiểm tra lại thông tin!");

			const cleanTaskList = this.formData.taskList.filter(t => t.name && t.name.trim() !== '').map(t => t.name);
			const jsonTaskList = JSON.stringify(cleanTaskList);

			// Logic xử lý nhân sự
			let strNhanVien = "";
			// Chỉ lấy nhân viên thực hiện nếu chọn Radio 2 (Nội bộ)
			if (this.formData.radioChiuTrachNhiem === '2') {
				strNhanVien = this.formData.dsNhanVienThucHien.join(',');
			}
			// Người giám sát thì luôn lấy
			let strGiamSat = this.formData.dsNguoiGiamSat.join(',');

			if (!await this.$refs.confirm.open({ title: 'Xác nhận', message: 'Tạo lịch bảo trì này?' })) return;

			this.submitting = true;
			try {
				const payload = {
					"TenLichBaoTri": this.formData.tenLich,
					"NgayBatDau": this.formData.startDate,
					"LoaiDinhKi": Number(this.formData.loaiDinhKi),
					"SoLanLap": Number(this.formData.soLanLap),
					"SoKyDinhKy": Number(this.formData.soLanDinhKi),
					"DonGia": Number(this.formData.donGia),
					"NgayTrongTuan": this.formData.loaiDinhKi === 1 ? Number(this.formData.recurringDay) : undefined,
					"NgayTrongThang": this.formData.loaiDinhKi === 2 ? Number(this.formData.ngayTrongThang) : undefined,
					"NoiDungDinhKy": this.formData.note,
					"DanhSachMaCaBiet": this.selectedAssets.join(','),
					"DanhSachCongViec": jsonTaskList,
					"MaDoiTac": this.formData.radioChiuTrachNhiem === '1' ? this.formData.donViBaoTri : undefined,

					// Gửi chuỗi ID nhân sự lên
					"DSNhanVienThucHien": strNhanVien,
					"DSNguoiGiamSat": strGiamSat
				};

				await axios.post("TS_LichBaoTriDinhKy_Insert_CheckList", payload);

				this.dialog = false;
				this.selectedAssets = [];
				this.$emit('refresh');
			} catch (e) { console.error(e); alert("Lỗi: " + (e.response?.data?.Message || e.message)); }
			finally { this.submitting = false; }
		},
	}
}
</script>