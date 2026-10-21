<template>
	<v-container fluid class="pa-4">
		<!-- Stats -->
		<uc-stats :stats="schoolStats" />

		<!-- Khu vực 2: Chi tiết theo Khoa -->
		<v-card class="mt-6" v-if="dataReady">
			<v-tabs v-model="activeTab" bg-color="primary" dark>
				<v-tab value="ALL">Tất cả Giảng viên</v-tab>
				<v-tab v-for="khoa in khoaList" :key="khoa.KhoaID" :value="khoa.KhoaID">{{ khoa.TenKhoa }}</v-tab>
			</v-tabs>

			<v-window v-model="activeTab" transition="false" reverse-transition="false" style="overflow: hidden;">
				<v-window-item v-for="khoa in [{ KhoaID: 'ALL', TenKhoa: 'Tất cả' }].concat(khoaList)"
					:key="khoa.KhoaID" :value="khoa.KhoaID" style="overflow: hidden;">
					<v-card-text v-if="activeTab === khoa.KhoaID">

						<!-- Loading background data state -->
						<div v-if="!isKhoaDataLoaded && activeTab === 'ALL'"
							class="d-flex align-center justify-center pa-6 text-grey">
							<v-progress-circular indeterminate color="primary" size="24" class="mr-3">
							</v-progress-circular>
							<span class="text-body-2 font-weight-medium">Đang tải dữ liệu các khoa...</span>
						</div>

						<div v-else-if="!khoaStats[khoa.KhoaID] && khoa.KhoaID !== 'ALL'"
							class="d-flex align-center justify-center pa-6 text-grey">
							<v-progress-circular indeterminate color="primary" size="24" class="mr-3">
							</v-progress-circular>
							<span class="text-body-2 font-weight-medium">Đang tải thống kê khoa...</span>
						</div>

						<div v-else>
							<!-- Thống kê của Khoa -->
							<div v-if="khoaStats[khoa.KhoaID]" class="d-flex ga-4 mb-4 pa-4 bg-blue-lighten-5 rounded">
								<span class="font-weight-medium">Tổng GV: {{ khoaStats[khoa.KhoaID].TongSoGiangVien ===
									null
									? 0 : khoaStats[khoa.KhoaID].TongSoGiangVien
									}}</span>
								<v-divider vertical></v-divider>
								<span class="font-weight-medium">Tỷ lệ HT: {{
									khoaStats[khoa.KhoaID].TyLeHoanThanh == null ? 0 :
									khoaStats[khoa.KhoaID].TyLeHoanThanh.toFixed(1) }}%</span>
								<v-divider vertical></v-divider>
								<span class="font-weight-medium">Giờ TB: {{ khoaStats[khoa.KhoaID].SoGioTB == null ? 0 :
									khoaStats[khoa.KhoaID].SoGioTB.toFixed(1)
									}}</span>
								<v-divider vertical></v-divider>
								<span class="font-weight-medium">Chờ duyệt: {{ khoaStats[khoa.KhoaID].HoatDongChoDuyet
									==
									null ? 0 : khoaStats[khoa.KhoaID].HoatDongChoDuyet
									}}</span>
							</div>

							<!-- Tìm kiếm giảng viên -->
							<div class="d-flex ga-2 mb-4">
								<v-text-field v-model="searchQuery" label="Tìm kiếm theo Tên hoặc Mã giảng viên..."
									prepend-inner-icon="mdi-magnify" variant="outlined" density="compact" hide-details
									clearable class="flex-grow-1"></v-text-field>
								<v-btn color="success" variant="flat" prepend-icon="mdi-microsoft-excel"
									@click="exportToExcel" class="text-none rounded-sm" height="40">
									Xuất Excel
								</v-btn>
							</div>

							<div v-if="filteredLecturers.length === 0"
								class="text-center pa-8 border rounded-sm text-grey">
								<v-icon size="large" class="mb-2 text-grey-lighten-1">mdi-account-search-outline
								</v-icon>
								<div class="text-body-2">Không tìm thấy giảng viên nào phù hợp.</div>
							</div>

							<div v-else>
								<!-- Danh sách Giảng viên -->
								<div :style="`max-height: ${khoa.KhoaID === 'ALL' ? 'calc(50vh + 72px)' : '50vh'}; overflow-y: auto;`"
									class="pr-1">
									<v-expansion-panels>
										<v-expansion-panel v-for="gv in paginatedLecturers" :key="gv.NhanVienID"
											@group:selected="onPanelToggle($event, gv.NhanVienID)">
											<v-expansion-panel-title>
												<uc-lecturer-row :lecturer="gv" :ds-forms="dsForms"
													@on-show-kekhai="showNewKekhaiDialog" />
											</v-expansion-panel-title>
											<v-expansion-panel-text>
												<v-data-table :items="activities[gv.NhanVienID] || []"
													:headers="activityHeaders" :loading="!activities[gv.NhanVienID]"
													density="compact">

													<template v-slot:item.TrangThaiDuyet="{ item }">
														<v-tooltip :text="getStatusTooltip(item.TrangThaiDuyet)"
															location="top">
															<template v-slot:activator="{ props }">
																<v-chip v-bind="props"
																	:color="getStatusColor(item.TrangThaiDuyet)"
																	size="small" variant="flat" label>{{
																	getStatusText(item.TrangThaiDuyet) }}</v-chip>
															</template>
														</v-tooltip>
													</template>

													<template v-slot:item.SoGio_HeThongTinh="{ item }">
														<v-tooltip :text="item.DienGiaiCachTinh" location="top"
															v-if="item.DienGiaiCachTinh">
															<template v-slot:activator="{ props }">
																<span v-bind="props"
																	class="cursor-help font-weight-medium">{{
																	item.SoGio_HeThongTinh }}</span>
															</template>
														</v-tooltip>
														<span v-else>{{ item.SoGio_HeThongTinh }}</span>
													</template>

													<template v-slot:item.CreateTime="{ item }">
														<span>{{ formatDate(item.CreateTime) }}</span>
													</template>

													<template v-slot:item.SoGio_DaDuyet="{ item }">
														<v-text-field v-model.number="item.SoGio_DaDuyet"
															density="compact"
															:readonly="item.TrangThaiDuyet != 'CHO_DUYET'"
															:variant="item.TrangThaiDuyet != 'CHO_DUYET' ? 'plain' : 'outlined'"
															class="my-field text-right" style="text-align: right;">
														</v-text-field>
													</template>

													<template #item.actions="{ item }">
														<div class="d-flex ga-2 justify-end">
															<div v-if="item.TrangThaiDuyet === 'CHO_DUYET'"
																class="d-flex ga-2">
																<v-tooltip text="Duyệt" location="top">
																	<template #activator="{ props }">
																		<v-btn v-bind="props" size="small"
																			color="success" icon="mdi-check"
																			variant="text"
																			@click="approveSubmission(item.SubmissionID, item.KetQuaID, gv.NhanVienID, item.SoGio_DaDuyet)" />
																	</template>
																</v-tooltip>

																<v-tooltip text="Từ chối" location="top">
																	<template #activator="{ props }">
																		<v-btn v-bind="props" size="small" color="error"
																			icon="mdi-close" variant="text"
																			@click="openRejectDialog(item, gv.NhanVienID)" />
																	</template>
																</v-tooltip>
															</div>

															<v-tooltip text="Xem chi tiết" location="top">
																<template #activator="{ props }">
																	<v-btn v-bind="props" size="small" color="default"
																		icon="mdi-eye" variant="text"
																		@click="onViewDetail(item, gv.NhanVienID)" />
																</template>
															</v-tooltip>
														</div>
													</template>

													<template v-slot:no-data>
														<div class="text-center pa-4 text-grey">
															<v-icon size="large" class="mb-2">
																mdi-text-box-search-outline</v-icon>
															<div>Giảng viên chưa kê khai hoạt động nào trong năm học
																này.</div>
														</div>
													</template>
												</v-data-table>
											</v-expansion-panel-text>
										</v-expansion-panel>
									</v-expansion-panels>
								</div>

								<!-- Phân trang -->
								<div class="d-flex justify-center mt-4" v-if="pageLength >= 1">
									<v-pagination v-model="page" :length="pageLength" :total-visible="7"
										density="comfortable" color="primary"></v-pagination>
								</div>
							</div>
						</div>
					</v-card-text>
				</v-window-item>
			</v-window>
		</v-card>

		<!-- Skeleton Loader when initial loading -->
		<v-card class="mt-6 pa-6" v-else>
			<v-skeleton-loader type="article, table"></v-skeleton-loader>
		</v-card>

		<!-- Dialog từ chối -->
		<uc-modal-reject v-model="rejectDialog.visible" :item="rejectDialog.item" :nhan-vien-id="nhanVienID"
			@on-submit="rejectSubmission" />

		<!-- Dialog xem chi tiết -->
		<uc-modal-detail v-model="viewDialog.visible" :item="selectedItem" :nhan-vien-id="nhanVienID" :ds-g-v="dsGV"
			:dm-get-all="DM_GetALL" :map-vai-tro="MapVaiTro" :v-set="vSet" @on-reload="onDetailReload" />

		<!-- Dialog Kê khai động tích hợp -->
		<uc-modal-ke-khai-dong v-model="isDialogKekhaiVisible" :form-definition="formDefinition"
			:form-edit-data="selectedSubmissionData" :title="dialogTitle" :ds-g-v="dsGV" :selected-year="selectedYear"
			:nhan-vien="nhanVienKekhai" :item-status="itemStatus" :v-set="vSet" :dm-get-all="DM_GetALL"
			:map-vai-tro="MapVaiTro" @saved="onKekhaiSaved" />

	</v-container>
</template>

<script>
	export default {
		name: 'uc-main-page',
		data: () => ({
			vSet: window.vueData?.v_Set || {},
			activeTab: 'ALL',
			rejectDialog: { visible: false, item: null },
			viewDialog: { visible: false, item: null },
			nhanVienID: null,
			isLoading: false,
			rules: {
				required: value => (value !== null && value !== undefined && value !== '') || 'Trường này là bắt buộc.',
			},
			formDefinition: {},
			selectedItem: null,
			activityHeaders: [
				{ title: 'Loại hình', key: 'FormTitle' },
				{ title: 'Tên hoạt động', key: 'TenHoatDong_CuThe' },
				{ title: 'Ngày kê khai', key: 'CreateTime', sortable: true },
				{ title: 'Số giờ hệ thống tính', key: 'SoGio_HeThongTinh', align: 'end' },
				{ title: 'Số giờ đã duyệt', key: 'SoGio_DaDuyet', align: 'end' },
				{ title: 'Trạng thái', key: 'TrangThaiDuyet' },
				{ title: 'Hành động', key: 'actions', sortable: false, align: 'end', width: '200px' },
			],
			MapVaiTro: {
				"DE_TAI_NCKH": [1, 2, 10, 11],
				"SACH_GIAO_TRINH": [0, 10],
				"BAI_BAO_KH": [4, 5, 6, 7, 8, 9, 10],
				"HD_XET_TUYEN": [4, 5, 6, 7, 8, 9, 10],
				"SO_HUU_TRI_TUE": [2, 10],
				"PHAN_BIEN": [10],
				"HUONG_DAN_NCKH": [10],
				"HUONG_DAN_HOC_SINH_NCKH": [10],
				"HUONG_DAN_LUAN_VAN": [10],
				"CUOC_THI_KHCN": [10],
				"CGCN": [10],
				"BC_HOI_THAO": [10],
				"HOI_DONG_CHAM_THI": [10],
				"NV_KHAC": [10],
			},

			// Local State thực tế thay thế vueData
			schoolStats: {},
			khoaList: [],
			khoaStats: {},
			lecturersByKhoa: {},
			activities: {},
			dsForms: [],
			dsGV: [],
			selectedYear: null,
			dataReady: false,
			isKhoaDataLoaded: false,
			DM_GetALL: new Map(),

			isDialogKekhaiVisible: false,
			nhanVienKekhai: {},
			itemStatus: 'new',
			dialogTitle: '',
			selectedSubmissionData: {},

			// State phục vụ tìm kiếm & phân trang
			searchQuery: '',
			page: 1,
			itemsPerPage: 15
		}),
		computed: {
			FieldFillter() {
				return this.formDefinition.Fields?.filter((x) => x?.FieldName !== 'vai_tro')
			},
			allMaGV() {
				let res = []
				if (Array.isArray(this.dsGV)) {
					this.dsGV.forEach((gv) => res.push(gv.MaNV))
				}
				return res;
			},
			allTenGV() {
				let res = []
				if (Array.isArray(this.dsGV)) {
					this.dsGV.forEach((gv) => res.push(`${gv.HoNV} ${gv.TenNV}`))
				}
				return res;
			},
			filteredLecturers() {
				const lecturers = this.getLecturersForTab(this.activeTab);
				if (!this.searchQuery) return lecturers;
				const q = this.searchQuery.toLowerCase().trim();
				return lecturers.filter(gv => 
					(gv.HoTen && gv.HoTen.toLowerCase().includes(q)) || 
					(gv.NhanVienID && String(gv.NhanVienID).toLowerCase().includes(q))
				);
			},
			paginatedLecturers() {
				const start = (this.page - 1) * this.itemsPerPage;
				const end = start + this.itemsPerPage;
				return this.filteredLecturers.slice(start, end);
			},
			pageLength() {
				return Math.ceil(this.filteredLecturers.length / this.itemsPerPage) || 1;
			}
		},
		watch: {
			activeTab() {
				this.page = 1;
				this.searchQuery = '';
			},
			searchQuery() {
				this.page = 1;
			}
		},
		async mounted() {
			await this.initPage();
		},
		methods: {
			async initPage() {
				this.dataReady = false;
				this.selectedYear = new Date().getFullYear();
				this.activities = {};
				this.khoaStats = {};
				this.lecturersByKhoa = {};
				this.isKhoaDataLoaded = false;
				this.selectedSubmissionData = {};
				this.formDefinition = {};
				this.isDialogKekhaiVisible = false;

				try {
					// Gọi API khởi tạo song song
					const [statsRes, khoaRes, dmRes, formsRes, dsGVRes] = await Promise.all([
						ajaxCALLPromise("/HDKH_Admin_GetThongKeTongHop", { NamHoc: this.selectedYear }),
						ajaxCALLPromise("/HDKH_Admin_GetDanhSachKhoa"),
						ajaxCALLPromise("/HDKH_DM_GetAll"),
						ajaxCALLPromise("/HDKH_Form_GetList"),
						ajaxCALLPromise("/TaiKhoan_Seach", { Keyword: "null" })
					]);

					if (statsRes && statsRes.length > 0) {
						this.schoolStats = statsRes[0][0] || {};
					} else {
						this.schoolStats = {};
					}

					this.khoaList = Array.isArray(khoaRes) ? khoaRes : [];

					// Khởi tạo Map danh mục
					this.DM_GetALL = new Map();
					if (dmRes && dmRes.length > 0) {
						for (let i = 0; i < dmRes.length; i++) {
							const item = dmRes[i] ?? {};
							if (item[0]?.DanhMucCode) {
								this.DM_GetALL.set(item[0].DanhMucCode, dmRes[i]);
							}
						}
					}

					this.dsForms = formsRes || [];
					this.dsGV = dsGVRes || [];

					// Render UI chính lập tức
					this.dataReady = true;

					// Tải dữ liệu các khoa ở background
					if (this.khoaList.length > 0) {
						this.loadAllKhoaData();
					} else {
						this.isKhoaDataLoaded = true;
					}

				} catch (error) {
					console.error("Lỗi khởi tạo dashboard:", error);
					this.khoaList = [];
					this.dataReady = true;
					this.isKhoaDataLoaded = true;
				}
			},
			async loadAllKhoaData() {
				if (!this.khoaList || this.khoaList.length === 0) {
					this.isKhoaDataLoaded = true;
					return;
				}

				const newKhoaStats = {};
				const newLecturersByKhoa = {};

				const promises = this.khoaList.map(async (khoa) => {
					try {
						const response = await ajaxCALLPromise("/HDKH_Admin_GetThongKeKhoa", { 
							KhoaID: khoa.KhoaID, 
							NamHoc: this.selectedYear 
						});
						if (response && response.length >= 2) {
							newKhoaStats[khoa.KhoaID] = response[0][0];
							newLecturersByKhoa[khoa.KhoaID] = response[1];
						}
					} catch (error) {
						console.error(`Lỗi khi tải dữ liệu cho khoa ${khoa.KhoaID}:`, error);
					}
				});

				await Promise.all(promises);

				// Gán phản ứng để UI cập nhật
				this.khoaStats = { ...this.khoaStats, ...newKhoaStats };
				this.lecturersByKhoa = { ...this.lecturersByKhoa, ...newLecturersByKhoa };
				this.isKhoaDataLoaded = true;
			},
			async getLecturerActivities(nhanVienID) {
				if (this.activities && this.activities[nhanVienID]) {
					return;
				}

				try {
					const responseData = await ajaxCALLPromise("/HDKH_Admin_GetKeKhaiByGiangVien", { 
						NhanVienID: nhanVienID, 
						NamHoc: this.selectedYear 
					});

					if (Array.isArray(responseData)) {
						responseData.forEach((submission) => {
							try {
								const json_data = JSON.parse(submission.json_data || "[]");
								const user_json_data = json_data.find((data) => data.MaThanhVien === nhanVienID) || {};
								
								submission.SoGio_DaDuyet = user_json_data.TrangThaiDuyet === 'CHO_DUYET' 
									? user_json_data.SoGio_HeThongTinh 
									: user_json_data.SoGio_DaDuyet;
								submission.SoGio_HeThongTinh = user_json_data.SoGio_HeThongTinh;
								submission.KetQuaID = user_json_data.KetQuaID;
								submission.TrangThaiDuyet = user_json_data.TrangThaiDuyet;
								submission.DienGiaiCachTinh = user_json_data.DienGiaiCachTinh;
							} catch (e) {
								console.error("Lỗi parse json_data của submission:", e);
							}
						});

						this.activities = { ...this.activities, [nhanVienID]: responseData };
					}
				} catch (error) {
					console.error("Lỗi khi lấy danh sách kê khai của giảng viên:", error);
				}
			},
			async approveSubmission(submissionID, KetQuaID, nhanVienID, SoGio_DaDuyet) {
				const def_payload = [{ KetQuaID, SoGio_DaDuyet }];
				const KetQuaDuyetJSON = JSON.stringify(def_payload);

				try {
					await ajaxCALLPromise("/HDKH_Admin_DuyetKeKhai", { 
						SubmissionID: submissionID, 
						TrangThaiMoi: 'KHOA_DA_DUYET', 
						KetQuaDuyetJSON: KetQuaDuyetJSON 
					});
					Vue.$toast.success("Duyệt thành công!", { position: "top" });
					
					this.activities = { ...this.activities };
					delete this.activities[nhanVienID];
					await this.getLecturerActivities(nhanVienID);
				} catch (error) {
					console.error("Lỗi khi duyệt kê khai:", error);
				}
			},
			async rejectSubmission(payload, nhanVienID) {
				try {
					await ajaxCALLPromise("/HDKH_Admin_DuyetKeKhai", payload);
					Vue.$toast.success("Từ chối thành công!", { position: "top" });
					
					this.activities = { ...this.activities };
					delete this.activities[nhanVienID];
					await this.getLecturerActivities(nhanVienID);
				} catch (error) {
					console.error("Lỗi khi từ chối kê khai:", error);
				}
			},
			async showNewKekhaiDialog(formCode, nhanVien) {
				if (!formCode) return;
				try {
					const response = await ajaxCALLPromise("/HDKH_Form_GetDefinition", { FormID: formCode });
					this.formDefinition = response[0] ?? {};
					this.nhanVienKekhai = nhanVien;
					this.selectedSubmissionData = {};
					this.itemStatus = 'new';
					this.dialogTitle = `Kê khai mới: ${this.formDefinition.FormTitle || ''}`;
					this.isDialogKekhaiVisible = true;
				} catch (error) {
					console.error("Lỗi khi lấy định nghĩa form:", error);
					Vue.$toast.error("Không thể tải được form kê khai.", { position: "top" });
				}
			},
			onKekhaiSaved() {
				if (this.nhanVienKekhai && this.nhanVienKekhai.NhanVienID) {
					this.activities = { ...this.activities };
					delete this.activities[this.nhanVienKekhai.NhanVienID];
					this.getLecturerActivities(this.nhanVienKekhai.NhanVienID);
				}
			},
			getStatusColor(status) {
				const map = { 'KHOA_DA_DUYET': 'success', 'CHO_DUYET': 'info', 'KHOA_TU_CHOI': 'error' };
				return map[status] || 'grey';
			},
			getStatusText(status) {
				const map = { 'KHOA_DA_DUYET': 'Đã duyệt', 'CHO_DUYET': 'Chờ duyệt', 'KHOA_TU_CHOI': 'Bị từ chối' };
				return map[status] || 'Không xác định';
			},
			getStatusTooltip(status) {
				const map = {
					'KHOA_DA_DUYET': 'Đã được phê duyệt.', 'CHO_DUYET': 'Đang chờ xem xét.', 'KHOA_TU_CHOI': 'Bị từ chối.'
				};
				return map[status] || 'Trạng thái không xác định.';
			},
			getLecturersForTab(khoaId) {
				if (!this.lecturersByKhoa) return [];
				if (khoaId === 'ALL') {
					const allLecturers = Object.values(this.lecturersByKhoa).flat().filter(Boolean);
					const uniqueLecturers = Array.from(new Map(allLecturers.map(item => [item['NhanVienID'], item])).values());
					return uniqueLecturers;
				}
				return this.lecturersByKhoa[khoaId] || [];
			},
			formatDate(dateString) {
				if (!dateString) return '';
				return new Date(dateString).toLocaleDateString('vi-VN');
			},
			onPanelToggle(event, nhanVienID) {
				if (event && event.value) {
					this.getLecturerActivities(nhanVienID);
				}
			},
			openRejectDialog(item, nhanVienID) {
				this.rejectDialog.item = item;
				this.rejectDialog.visible = true;
				this.nhanVienID = nhanVienID;
			},
			onViewDetail(item, nhanVienID) {
				this.nhanVienID = nhanVienID;
				this.selectedItem = item;
				this.viewDialog.visible = true;
			},
			async onDetailReload(nhanVienID) {
				this.activities = { ...this.activities };
				delete this.activities[nhanVienID];
				await this.getLecturerActivities(nhanVienID);
			},
			submitRejection() {
				const payload = {
					SubmissionID: this.rejectDialog.item.SubmissionID,
					TrangThaiMoi: 'KHOA_TU_CHOI',
					GhiChuTuChoi: this.rejectDialog.reason
				};
				this.rejectSubmission(payload, this.nhanVienID);
				this.rejectDialog.visible = false;
			},
			async updateSubmission(submissionID) {
				const arrayMinhChung = this.formData.MinhChung ?? []
				const hasFile = arrayMinhChung.some(x => x.FileID != null && String(x.FileID).trim() !== "")
				if (!hasFile) {
					Vue.$toast.error('Vui lòng tải lên ít nhất một file minh chứng để lưu cập nhật.', { position: 'top' });
					return;
				}
				let def_payload = {
					FormCode: this.formDefinition.FormCode,
					FormID: this.formDefinition.FormID,
					NamHoc: 2025,
					KeKhai_LienQuan_ID: 0,
				}
				const payload = {
					SubmissionID: submissionID,
					FormCode: this.formDefinition.FormCode,
					NamHoc: 2025,
					Fields: { ...this.formData, vai_tro: this.formData.ThanhVien[0].VaiTroID },
					ThanhVien: this.formData.ThanhVien,
					MinhChung: this.formData.MinhChung,
					sys_RawData: JSON.stringify(def_payload)
				};
				await ajaxCALLPromise('/HDKH_KeKhai_CalculateAndSave', payload);
				if (this.pendingDeleteFileIDs && this.pendingDeleteFileIDs.length > 0) {
					const delPayload = { FileIDs: this.pendingDeleteFileIDs.join(',') };
					await ajaxCALLPromise('/FILE_FileDeleteMulti', delPayload);
				}
				Vue.$toast.success('Chỉnh sửa hoạt động thành công!', { position: 'top' });
				this.viewDialog.visible = false
				
				this.activities = { ...this.activities };
				delete this.activities[this.nhanVienID];
				await this.getLecturerActivities(this.nhanVienID);
			},
			deleteSubmission(submissionID) {
				confirm({
					title: "Bạn có chắc chắn muốn xóa hoạt động này?",
					action: async () => {
						try {
							await ajaxCALLPromise('/HDKH_KeKhai_Delete', { SubmissionID: submissionID });
							Vue.$toast.success('Xóa hoạt động thành công', { position: 'top' });
							this.viewDialog.visible = false;
							
							this.activities = { ...this.activities };
							delete this.activities[this.nhanVienID];
							await this.getLecturerActivities(this.nhanVienID);
						} catch (error) {
							console.error("Lỗi xóa hoạt động:", error);
						}
					}
				});
			},
			removeThanhVien(index) {
				this.formData.ThanhVien.splice(index, 1);
			},
			async removeMinhChung(index) {
				const fileID = this.formData.MinhChung[index].FileID
				if (fileID !== null && fileID !== undefined) {
					if (this.uploadedFileIDs.includes(fileID)) {
						const payload = { FileID: fileID }
						await ajaxCALLPromise('/FILE_FileDelete', payload);
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID);
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' });
					} else {
						this.pendingDeleteFileIDs.push(fileID);
					}
				}
				this.formData.MinhChung.splice(index, 1);
			},
			addThanhVien(defaultUserId = null, defaultName = null) {
				if (!this.formData.ThanhVien) this.formData.ThanhVien = [];
				this.formData.ThanhVien.push({
					NhanVienID: defaultUserId,
					VaiTroID: null,
					ViTri: this.formData.ThanhVien.length + 1,
					HoTen: defaultName,
					isNhanVienLHU: true,
					isTacGiaLienHe: false
				});
			},
			addMinhChung(defaultUrl = "", defaultFileID = "") {
				if (!this.formData.MinhChung) this.formData.MinhChung = [];
				this.formData.MinhChung.push({
					URLMinhChung: defaultUrl,
					FileID: defaultFileID,
					FileName: null
				});
			},
			uploadFileMinhChung(file, index) {
				if (file && file.Files && file.Files[0]) {
					const fileID = file.Files[0].FILE_ID;
					this.uploadedFileIDs.push(fileID);
					this.formData.MinhChung[index].FileID = fileID;
					this.formData.MinhChung[index].FileName = file.Files[0].FILE_NAME;
				}
			},
			async del_fileMinhChung(index) {
				const fileID = this.formData.MinhChung[index].FileID
				if (fileID !== null && fileID !== undefined) {
					if (this.uploadedFileIDs.includes(fileID)) {
						const payload = { FileID: fileID }
						await ajaxCALLPromise('/FILE_FileDelete', payload);
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID);
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' });
					} else {
						this.pendingDeleteFileIDs.push(fileID);
					}
				}
				this.formData.MinhChung[index].FileID = null;
				this.formData.MinhChung[index].FileName = null;
			},
			async closeViewDialog() {
				if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
					try {
						const payload = { FileIDs: this.uploadedFileIDs.join(',') };
						await ajaxCALLPromise('/FILE_FileDeleteMulti', payload);
					} catch (e) {
						console.error("Lỗi xóa file tạm:", e);
					}
				}
				this.viewDialog.visible = false;
			},
			exportToExcel() {
				const tabName = this.activeTab === 'ALL' ? 'Tất cả' : (this.khoaList.find(k => k.KhoaID === this.activeTab)?.TenKhoa || this.activeTab);
				const rawData = this.getLecturersForTab(this.activeTab);
				
				if (!rawData || rawData.length === 0) {
					Vue.$toast.warning("Không có dữ liệu để xuất Excel", { position: 'top' });
					return;
				}
				
				const exportData = rawData.map((item, index) => ({
					"STT": index + 1,
					"Mã giảng viên": item.NhanVienID,
					"Họ tên": item.HoTen,
					"Định mức gốc (giờ)": item.DinhMucGoc || 0,
					"Miễn giảm (giờ)": item.TongGioMienGiam || 0,
					"Bảo lưu (giờ)": item.SoGioBaoLuuNamTruoc || 0,
					"Nợ cũ (giờ)": item.SoGioThieuNamTruoc || 0,
					"Nghĩa vụ trong năm (giờ)": item.NghiaVuTrongNam || 0,
					"Số giờ phải thực hiện (giờ)": item.SoGioPhaiThucHien || 0,
					"Tổng giờ đã thực hiện (giờ)": item.TongGioDaThucHien || 0,
					"Kết quả": item.KetQua || 'Chưa đạt'
				}));
				
				jsonToExcel({
					data: exportData,
					filename: `ThongKe_NCKH_${tabName.replace(/\s+/g, '_')}_${this.selectedYear}.xlsx`
				});
				Vue.$toast.success("Đã xuất Excel thành công!", { position: 'top' });
			},
		}
	}
</script>