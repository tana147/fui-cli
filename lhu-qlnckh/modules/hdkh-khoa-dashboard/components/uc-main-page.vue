<template>
	<v-container fluid class="pa-3">
		<!-- top bar bộ lọc -->
		<uc-topbar v-model:khoaId="khoaId" v-model:search="search" :khoaList="khoaList" @on-export="onExportData" />

		<!-- Stats -->
		<uc-stats v-if="khoaId && khoaStats" :stats="khoaStats" class='mb-1' />

		<!-- Main view -->
		<div class="main-view-scroll">
			<uc-main-view v-if="dataReady && khoaId && khoaStats" :lecturers="lecturersByKhoaFilter"
				:activities="activities" :ds-forms="dsForms" @on-panel-open="getLecturerActivities"
				@on-approve="approveSubmission" @on-reject="openRejectDialog" @on-view-detail="onViewDetail"
				@on-show-kekhai="showNewKekhaiDialog" />

			<div v-else-if="!khoaId" class="d-flex ga-4 justify-center align-center py-8">
				<v-empty-state text-width="250">
					<template v-slot:media>
						<v-icon size="20">mdi-magnify</v-icon>
					</template>

					<template v-slot:title>
						<div class="text-caption text-high-emphasis">Vui lòng chọn khoa để xem dữ liệu</div>
					</template>
				</v-empty-state>
			</div>
		</div>

		<!-- Dialog Kê khai động -->
		<uc-modal-ke-khai-dong v-model="isDialogKekhaiVisible" :form-definition="formDefinition[0] ?? {}"
			:form-edit-data="selectedSubmissionData" :title="dialogTitle" :map-vai-tro="MapVaiTro"
			:item-status="itemStatus" :v-set="vSet" :ds-g-v="dsGV" :nhan-vien="NhanVien" :dm-get-all="DM_GetALL"
			:selected-year="selectedYear" @saved="onKekhaiSaved" />

		<!-- Dialog từ chối -->
		<uc-modal-reject v-model="rejectDialog.visible" :item="rejectDialog.item" :nhan-vien-id="nhanVienID"
			@on-submit="rejectSubmission" />

		<!-- Dialog xem chi tiết -->
		<uc-modal-detail v-model="viewDialog.visible" :item="viewDialog.item" :nhan-vien-id="nhanVienID" :ds-g-v="dsGV"
			:dm-get-all="DM_GetALL" :map-vai-tro="MapVaiTro" :v-set="vSet" @on-reload="onDetailReload" />
	</v-container>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				vSet: window.vueData?.v_Set || {},
				dataReady: false,
				khoaList: [],
				activities: {},
				dsForms: [],
				isDialogKekhaiVisible: false,
				dialogTitle: "",
				formDefinition: {},
				selectedYear: null,
				userProfile: null,
				NhanVienID: null,
				DM_GetALL: null,
				dsGV: [],
				selectedSubmissionData: {},
				selectedFormCode: null,
				NhanVien: null,
				itemStatus: null,

				// local filter state
				khoaId: null,
				khoaStats: null,
				lecturersByKhoa: null,
				search: null,

				// local dialog state
				rejectDialog: { visible: false, item: null },
				viewDialog: { visible: false, item: null },
				nhanVienID: null, // đang thao tác với giảng viên nào

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
				}
			};
		},
		mounted() {
			this.initPage();
		},
		computed: {
			lecturersByKhoaFilter() {
				if (this.search) {
					return this.lecturersByKhoa?.filter(l =>
						l.HoTen?.toLowerCase().includes(this.search.toLowerCase())
					) || [];
				}
				return this.lecturersByKhoa || [];
			}
		},
		watch: {
			// Lọc theo khoa
			khoaId: async function (val) {
				if (val) {
					const response = await ajaxCALLPromise("/HDKH_Admin_GetThongKeKhoa", { KhoaID: val, NamHoc: this.selectedYear });
					if (response && response.length >= 2) {
						this.khoaStats = response[0][0];
						this.lecturersByKhoa = response[1];
					}
				} else {
					this.khoaStats = null;
					this.lecturersByKhoa = null;
				}
			}
		},
		methods: {
			async initPage() {
				this.dataReady = false;
				this.activities = {};
				this.selectedYear = new Date().getFullYear();

				const [khoaRes, gvRes, formsRes] = await Promise.all([
					ajaxCALLPromise("/HDKH_Admin_GetDanhSachKhoa"),
					ajaxCALLPromise("/TaiKhoan_Seach", { Keyword: "null" }),
					ajaxCALLPromise("/HDKH_Form_GetList")
				]);

				if (khoaRes && Array.isArray(khoaRes)) {
					this.khoaList = khoaRes;
				} else {
					this.khoaList = [];
				}

				if (gvRes && Array.isArray(gvRes)) {
					this.dsGV = gvRes;
				} else {
					this.dsGV = [];
				}

				if (formsRes && Array.isArray(formsRes)) {
					this.dsForms = formsRes;
				} else {
					this.dsForms = [];
				}

				await this.getAllDM();
				this.dataReady = true;
			},
			async getAllDM() {
				this.DM_GetALL = new Map();
				const res = await ajaxCALLPromise('/HDKH_DM_GetAll');
				if (res && res.length > 0) {
					for (let i = 0; i < res.length; i++) {
						const item = res[i];
						if (item && item.length > 0) {
							const code = item[0]?.DanhMucCode;
							if (code) {
								this.DM_GetALL.set(code, item);
							}
						}
					}
				}
			},
			async getLecturerActivities(nhanVienID) {
				if (this.activities && this.activities[nhanVienID]) {
					return;
				}
				const data = await ajaxCALLPromise("/HDKH_Admin_GetKeKhaiByGiangVien", {
					NhanVienID: nhanVienID,
					NamHoc: this.selectedYear
				});
				if (data && Array.isArray(data)) {
					data.forEach((submission) => {
						try {
							if (submission.json_data) {
								const json_data = JSON.parse(submission.json_data);
								const user_json_data = json_data.find((d) => d.MaThanhVien === nhanVienID);
								if (user_json_data) {
									submission.SoGio_DaDuyet = user_json_data.TrangThaiDuyet === 'CHO_DUYET' ? user_json_data.SoGio_HeThongTinh : user_json_data.SoGio_DaDuyet;
									submission.SoGio_HeThongTinh = user_json_data.SoGio_HeThongTinh;
									submission.KetQuaID = user_json_data.KetQuaID;
									submission.TrangThaiDuyet = user_json_data.TrangThaiDuyet;
									submission.DienGiaiCachTinh = user_json_data.DienGiaiCachTinh;
									submission.GhiChuTuChoi = user_json_data.GhiChuTuChoi;
								}
							}
						} catch (e) {
							console.error("Lỗi parse json_data cho submission:", e);
						}
					});
					this.activities = { ...this.activities, [nhanVienID]: data };
				}
			},
			async approveSubmission(submissionID, KetQuaID, nhanVienID, SoGio_DaDuyet) {
				const def_payload = [{ KetQuaID, SoGio_DaDuyet }];
				const KetQuaDuyetJSON = JSON.stringify(def_payload);
				await ajaxCALLPromise("/HDKH_Admin_DuyetKeKhai", {
					SubmissionID: submissionID,
					TrangThaiMoi: 'KHOA_DA_DUYET',
					KetQuaDuyetJSON: KetQuaDuyetJSON
				});
				Vue.$toast.success("Duyệt thành công!", { position: "top" });
				
				delete this.activities[nhanVienID];
				await this.getLecturerActivities(nhanVienID);
			},
			async rejectSubmission(payload, nhanVienID) {
				await ajaxCALLPromise("/HDKH_Admin_DuyetKeKhai", payload);
				Vue.$toast.success("Từ chối thành công!", { position: "top" });
				
				delete this.activities[nhanVienID];
				await this.getLecturerActivities(nhanVienID);
			},
			async showNewKekhaiDialog(formCode, nhanVien) {
				if (!formCode) return;
				try {
					this.selectedFormCode = formCode;
					const res = await ajaxCALLPromise("/HDKH_Form_GetDefinition", { FormID: formCode });
					if (res && res[0]) {
						this.formDefinition = res;
					}
					this.NhanVien = nhanVien;
					this.selectedSubmissionData = {};
					this.itemStatus = 'new';
					this.dialogTitle = `Kê khai mới: ${res[0]?.FormTitle || ''}`;
					this.isDialogKekhaiVisible = true;
				} catch (error) {
					console.error("Lỗi khi lấy định nghĩa form:", error);
					Vue.$toast.error("Không thể tải được form kê khai.");
				}
			},
			openRejectDialog(item, nhanVienID) {
				this.nhanVienID = nhanVienID;
				this.rejectDialog.item = item;
				this.rejectDialog.visible = true;
			},
			onViewDetail(item, nhanVienID) {
				this.nhanVienID = nhanVienID;
				this.viewDialog.item = item;
				this.viewDialog.visible = true;
			},
			async onDetailReload(nhanVienID) {
				delete this.activities[nhanVienID];
				await this.getLecturerActivities(nhanVienID);
			},
			async onKekhaiSaved() {
				if (this.NhanVien && this.NhanVien.NhanVienID) {
					delete this.activities[this.NhanVien.NhanVienID];
					await this.getLecturerActivities(this.NhanVien.NhanVienID);
				}
			},
			async onExportData() {
				const params = {
					KhoaID: this.khoaId,
					NamHoc: this.selectedYear
				}
				const data = await ajaxCALLPromise('/HDKH_Admin_GetThongKeKhoa_Export', params)
				const [sheet1Data, , sheet2Data, forms, submissions] = data;
				const excelSheets = [
					{ name: 'Sheet1', data: sheet1Data },
					{ name: 'Sheet2', data: sheet2Data }
				];
				forms.forEach(form => {
					const groupData = submissions
						.filter(item => item.FormID === form.FormID)
						.map(({ FormID, SubmissionID, ...rest }) => rest);
	
					let finalData = [];
					const parseThongTin = (str) => {
						if (!str) return {};
						const obj = {};
						const lines = String(str).split(/\n|\\n/);
						lines.forEach(line => {
							const index = line.indexOf(':');
							if (index !== -1) {
								const key = line.substring(0, index).trim();
								const value = line.substring(index + 1).trim();
								if (key) obj[key] = value;
							}
						});
						return obj;
					};
	
					if (groupData.length === 0) {
						finalData = [{
							"MaNV": "",
							"HoTen": "",
							"ThongTin": ""
						}];
					} else {
						const firstParsed = parseThongTin(groupData[0].ThongTin);
						const dynamicKeys = Object.keys(firstParsed);
						finalData = groupData.map(item => {
							const { ThongTin, ...rest } = item;
							const currentParsed = parseThongTin(ThongTin);
							const dynamicData = {};
							dynamicKeys.forEach(key => {
								dynamicData[key] = currentParsed[key] || "";
							});
							return {
								...rest,
								...dynamicData
							};
						});
					}
					excelSheets.push({
						name: form.FormCode.substring(0, 31),
						data: finalData
					});
				});
				jsonToExcel({
					sheets: excelSheets,
					filename: (this.label || 'BaoCao') + '.xlsx'
				});
			}
		}
	}
</script>