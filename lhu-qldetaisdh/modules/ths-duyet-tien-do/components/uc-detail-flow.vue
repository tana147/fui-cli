<template>
	<div style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding-right: 4px; padding-top: 12px;">
		<!-- Fixed Header Block: Thông tin học viên -->
		<div class="uc-student-info-bar mb-3 flex-shrink-0" v-if="studentDisplayId">
			<div class="uc-student-info-item">
				<v-icon small class="mr-1 uc-student-icon">mdi-account-circle</v-icon>
				<span class="uc-student-label">Học viên:</span>
				<span class="uc-student-name">{{ studentDisplayName }}</span>
			</div>
			<div class="uc-student-info-item">
				<v-icon small class="mr-1 uc-student-icon">mdi-card-account-details-outline</v-icon>
				<span class="uc-student-id">{{ studentDisplayId }}</span>
			</div>
			<div class="uc-student-info-item">
				<v-icon small class="mr-1 uc-student-icon">mdi-school-outline</v-icon>
				<span class="uc-student-class">{{ studentClassId }}</span>
			</div>
		</div>

		<div v-if="activeDsRootProcess && activeDsRootProcess.length > 0" class="d-flex flex-column flex-grow-1 min-h-0" style="overflow: hidden;">
			<!-- Header hiển thị tên bước đang duyệt dưới dạng thanh ngang phẳng chuyên nghiệp - Cố định -->
			<v-card flat color="indigo" dark class="px-4 py-2 d-flex align-center justify-space-between mb-3 flex-shrink-0"
				style="min-height: 48px; border-radius: 4px;">
				<div class="subtitle-1 font-weight-bold d-flex align-center">
					<v-icon left>mdi-file-tree</v-icon>
					Bước duyệt: {{ activeRootStep.Step_Index || (selectedRootIndex + 1) }}./ {{ activeRootStep.Task_Name }}
				</div>
				<div class="d-flex align-center" style="gap: 8px;">
					<v-btn-toggle v-if="activeDsRootProcess.length > 1" v-model="selectedRootIndex" mandatory dense class="mr-2">
						<v-btn v-for="(r, rIdx) in activeDsRootProcess" :key="rIdx" small class="text-none font-weight-bold" @click="onLoadDetail(r.Flow_ID)">
							Bước {{ r.Step_Index || (rIdx + 1) }}
						</v-btn>
					</v-btn-toggle>
					<v-chip small :color="getChipColor(activeRootStep.Flow_Status)" dark class="font-weight-bold">
						{{ getChipColorText(activeRootStep.Flow_Status) }}
					</v-chip>
				</div>
			</v-card>

			<!-- Vùng nội dung chỉ cuộn danh sách tiêu chí -->
			<div class="flex-grow-1 min-h-0 pb-2" style="overflow-y: auto; overflow-x: hidden; padding-right: 2px;">
				<v-card outlined style="border: 1px solid #dbe7ee !important;">
					<div v-for="(item, index) in detailProcess" :key="index" class="py-4 px-4"
						style="border-bottom: 1px solid #eef2f5;">
						<v-row align="center" no-gutters>
							<!-- Cột bên trái: Nội dung mô tả và các component nhập liệu -->
							<v-col cols="10">
								<span class="d-flex align-center">
									<h4 v-show="shouldShowDuocOnlyField(item)" class="text-body-1 font-weight-medium grey--text text--darken-4">
										{{ activeRootStep.Step_Index || (selectedRootIndex + 1) }}.{{ index + 1 }}./ {{ item.TASK_DETAIL_DESCRIPTION }}
									</h4>
									<div v-if="item.Task_Detail_Type === 'CHECKBOX'" class="ml-3">
										<v-checkbox large color="success" :hint="item.Data_Exp"
											v-model="item.Text_Content" persistent-hint />
									</div>
								</span>

								<v-autocomplete
									v-if="item.Task_Detail_Type === 'SELECT' && item.FieldName === 'VanBangChungChiDauRa'"
									v-model="item.Text_Content" :items="DsNNDauRa" item-text="text" item-value="value"
									outlined dense hide-details class="mt-2">
									<template v-slot:item="{ item, attrs, on }">
										<v-subheader v-if="item.header">
											{{ item.header }}
										</v-subheader>
										<v-list-item v-else v-bind="attrs" v-on="on">
											<v-list-item-content>
												<v-list-item-title>{{ item.text }}</v-list-item-title>
											</v-list-item-content>
										</v-list-item>
									</template>
								</v-autocomplete>

								<v-autocomplete
									v-if="item.Task_Detail_Type === 'SELECT' && item.FieldName === 'TenNgoaiNguDauRa'"
									v-model="item.Text_Content" :items="DsTenNgoaiNgu" item-text="text"
									item-value="value" outlined dense hide-details class="mt-2" />

								<v-text-field
									v-if="item.Task_Detail_Display === 1 && (item.Task_Detail_Type === 'NUMBER' || item.Task_Detail_Type === 'NUMBERVIEW')"
									class="text-right-input mt-2" v-model="item.Text_Content" placeholder="Nhập số"
									type="number" min="0" step="0.01" inputmode="decimal" @keydown="preventNegative"
									dense outlined color="success" />

								<c-textarea-comp class="mt-2 mb-1" :item-des="item" :text-rules="textRules" :allow-edit="true"
									v-if="item.Task_Detail_Type === 'TEXT' || item.Task_Detail_Type === 'TEXTVIEW' || item.Task_Detail_Type === 'TEXTAREA'" />
								<c-file-comp :item-des="item" :item="item" :allow-upload="true" :api-file="apiFile" :url-read-file="urlReadFile"
									v-if="item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW'" class="mt-2" />
								<c-score-comp :item-des="item"
									v-if="item.Task_Detail_Type === 'DIEM' || item.Task_Detail_Type === 'FORMULAR'" class="mt-2" />

								<!-- Kiểm tra trùng tên đề tài đã đăng ký -->
								<div class="mt-2" v-if="item.FN_Check === 'fnCheckDeTaiDaDangKy'">
									<div class="d-flex align-center justify-center" style="gap: 15px">
										<v-textarea v-model="item.Text_Content" outlined name="input-7-1"
											rows="1" color="green" auto-grow dense hide-details />
										<v-btn color="warning"
											@click="checkDeTaiDaDky(studentDisplayId, item.Text_Content)"
											:disabled="!item.Text_Content">
											Kiểm tra đề tài đã đăng ký
										</v-btn>
									</div>
									<div class="mt-3 mb-2" v-if="checkDeTaiFlag !== null">
										<div v-if="checkDeTaiFlag === true" class="d-flex justify-center align-center">
											<h4 class="success--text">
												<v-icon class="mb-1" color="success">mdi-check-bold</v-icon>
												Giống với tên đề tài đã đăng ký
											</h4>
										</div>
										<div v-if="checkDeTaiFlag === false" class="d-flex justify-center align-center">
											<h4 class="error--text">
												<v-icon class="mb-1" color="error">mdi-alert-circle</v-icon>
												Khác tên đề tài đã đăng ký
											</h4>
										</div>
									</div>
									<div class="d-flex align-center mt-2 mb-2" v-if="resultKtraDeTai">
										<h4 class="primary--text">Tên đề tài trong Quyết định:</h4>
										<p class="mb-0 ml-2">
											{{ resultKtraDeTai }}
										</p>
									</div>
								</div>

								<div class="dateWrap mt-2"
									v-if="item.Task_Detail_Type === 'DATE' || item.Task_Detail_Type === 'DATEVIEW'">
									<f-date v-model="item.Text_Content" />
								</div>

								<div v-if="item.Task_Detail_Type === 'TEXTAREA | FUN' && item.FN_Check === 'fnCheckTenDeTai'" class="mt-2">
									<div class="d-flex align-center justify-center" style="gap: 15px">
										<div style="flex-grow: 1;">
											<c-textarea-comp :item-des="item" :text-rules="textRules" :allow-edit="true" />
										</div>
										<v-btn color="warning" @click="checkTopicBtn(item.Text_Content)" class="mb-3">
											Kiểm tra trùng
										</v-btn>
									</div>
									<div class="mb-3" v-if="similiarTopic.length > 0 && item.Text_Content">
										<v-card>
											<v-card-title>
												<span class="primary--text">Những đề tài liên quan</span>
											</v-card-title>
											<v-data-table :headers="headers" :items="similiarTopic"
												class="elevation-1" loading-text="Đang tải dữ liệu..."
												hide-default-footer
												no-data-text="Không có đề tài liên quan" />
										</v-card>
									</div>
								</div>

								<div v-if="item.Task_Detail_Type === 'FUN' && item.FN_Check === 'fnCheckHocPhi(StudentID)'" class="mt-2 w-100">
									<div v-if="item.TinhTrangNoHocPhi == 0 || item.TinhTrangNoHocPhi === '0'" class="d-flex justify-center align-center py-1">
										<h4 class="success--text text-subtitle-2 d-flex align-center">
											<v-icon class="mr-1" color="success">mdi-check-bold</v-icon>
											Không nợ học phí
										</h4>
									</div>
									<div v-else class="d-flex justify-center align-center py-1">
										<span class="primary--text"><b>Tình trạng nợ học phí:</b></span>
										<span :class="{ 'success--text': feeArr == '0', 'red--text': feeArr != '0' }" class="ml-2">
											<b>{{ item.TinhTrangNoHocPhi }} VNĐ</b>
										</span>
									</div>
								</div>

								<div v-if="item.Task_Detail_Type === 'TABLE'" class="mt-2">
									<table-view :item="item" />
								</div>
							</v-col>

							<!-- Cột bên phải: Nút duyệt Checkbox lớn dễ bấm -->
							<v-col cols="2" class="d-flex justify-center align-center">
								<div class="text-center">
									<div class="text-caption grey--text mb-1">Duyệt</div>
									<v-checkbox v-model="item.Flow_Detail_Status"
										@click.native.prevent.stop.capture="checkingStatus(item, activeRootStep)"
										hide-details color="success" class="ma-0 pa-0"></v-checkbox>
								</div>
							</v-col>
						</v-row>
					</div>
				</v-card>
			</div>

			<!-- Fixed Footer Action Bar -->
			<div class="d-flex align-center justify-end w-100 py-2 px-1 flex-shrink-0 mt-2" style="gap: 12px; border-top: 1px solid #eef2f5;">
				<template v-if="isSystemRight1">
					<v-btn color="indigo" dark @click="onCheckButNotSave(detailProcess, activeRootStep)">
						<v-icon left>mdi-check-bold</v-icon>
						Duyệt tất cả
					</v-btn>
				</template>
				<template v-else>
					<v-btn v-if="isStep5" color="grey" outlined @click="openHistoryDialog(activeRootStep)">
						<v-icon left>mdi-history</v-icon>
						Lịch sử nộp
					</v-btn>
					<v-btn v-if="isStep5" color="error" dark @click="openRejectDialog(activeRootStep)">
						<v-icon left>mdi-close-circle</v-icon>
						Từ chối
					</v-btn>
					<v-btn color="success" dark @click="onSave(activeRootStep)">
						<v-icon left>mdi-content-save</v-icon>
						Lưu thông tin
					</v-btn>
					<v-btn color="primary" dark @click="onCheckAll(detailProcess, activeRootStep)">
						<v-icon left>mdi-check-all</v-icon>
						Duyệt & Lưu tất cả
					</v-btn>
				</template>
			</div>
		</div>

		<!-- Dialog Từ chối hồ sơ -->
		<v-dialog v-model="rejectDialog" max-width="500" persistent>
			<v-card>
				<v-card-title class="headline error--text pb-2">
					<v-icon color="error" class="mr-2">mdi-alert-circle</v-icon>
					Từ chối hồ sơ & yêu cầu nộp lại
				</v-card-title>
				<v-card-text class="pt-3">
					<p class="text-caption grey--text mb-2">
						Khi từ chối, toàn bộ phiên nộp hiện tại (file đồ án, file check đạo văn...) sẽ được snapshot vào lịch sử. Học viên sẽ nhận được lý do và nộp lại bản mới.
					</p>
					<v-textarea v-model="rejectionReason" label="Lý do từ chối (*)" outlined rows="3"
						placeholder="Ví dụ: Tỷ lệ trùng lặp 35%, vượt mức cho phép 20%. Vui lòng chỉnh sửa và nộp lại."
						color="error" auto-grow hide-details />
				</v-card-text>
				<v-card-actions class="pb-3 px-4">
					<v-spacer />
					<v-btn text @click="rejectDialog = false" :disabled="isRejecting">Hủy</v-btn>
					<v-btn color="error" dark @click="confirmReject" :loading="isRejecting">
						Xác nhận từ chối
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog Lịch sử nộp bài & kiểm tra đạo văn -->
		<v-dialog v-model="historyDialog" max-width="750">
			<v-card>
				<v-card-title class="headline primary--text pb-2">
					<v-icon color="primary" class="mr-2">mdi-history</v-icon>
					Lịch sử các phiên nộp & kiểm tra đạo văn
				</v-card-title>
				<v-card-text class="pt-2">
					<div v-if="historyLoading" class="text-center py-4">
						<v-progress-circular indeterminate color="primary" class="mr-2" />
						<span>Đang tải lịch sử...</span>
					</div>
					<div v-else-if="historyVersions.length === 0" class="text-center py-6 grey--text">
						Chưa có dữ liệu lịch sử các lần từ chối trước đó.
					</div>
					<div v-else>
						<v-card v-for="(ver, idx) in historyVersions" :key="idx" outlined class="mb-3 pa-3">
							<div class="d-flex justify-space-between align-center mb-1">
								<span class="font-weight-bold red--text">
									Phiên nộp #{{ historyVersions.length - idx }}
								</span>
								<span class="text-caption grey--text">{{ ver.date }}</span>
							</div>
							<div class="mb-2">
								<b>Lý do từ chối:</b>
								<span class="error--text ml-1">{{ ver.reason || 'Không có lý do' }}</span>
							</div>
							<div class="text-caption grey--text mb-1">Các file trong phiên nộp này:</div>
							<div v-for="(fItem, fIdx) in ver.items.filter(i => i.File_ID)" :key="fIdx" class="ml-2 mb-1">
								<v-icon small color="primary" class="mr-1">mdi-file-document-outline</v-icon>
								<span class="font-weight-medium">{{ fItem.Task_Detail_Description }}:</span>
								<a :href="urlReadFile + fItem.File_URL" target="_blank" class="ml-1 text-decoration-none blue--text">
									{{ fItem.File_Name }}
								</a>
							</div>
						</v-card>
					</div>
				</v-card-text>
				<v-card-actions class="pb-3 px-4">
					<v-spacer />
					<v-btn color="primary" text @click="historyDialog = false">Đóng</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<v-card v-else flat class="d-flex align-center justify-center flex-grow-1" style="min-height: 200px;">
			<div class="text-center grey--text">Đang tải tiến trình...</div>
		</v-card>
	</div>
</template>

<script>
	export default {
		name: "uc-detail-flow",
		props: {
			studentId: { type: String, default: "" },
			studentInfo: { type: Object, default: () => ({}) },
			dsRootProcess: { type: Array, default: () => [] },
			apiFile: { type: String, default: "" },
			urlReadFile: { type: String, default: "" },
			systemRight: { type: Number, default: 0 }
		},
		emits: ['on-reload'],
		data() {
			return {
				selectedRootIndex: 0,
				detailArr: [],
				similiarTopic: [],
				detailProcess: [],
				feeArr: [],
				StudentProcList: [],
				DsNNDauRa: [],
				DsTenNgoaiNgu: [],
				SecondRootFlow: [],
				isDialog: false,
				checkDeTaiFlag: null,
				resultKtraDeTai: null,
				textRules: [(v) => !!v || 'Không được để trống'],
				rejectDialog: false,
				rejectionReason: '',
				isRejecting: false,
				historyDialog: false,
				historyLoading: false,
				historyList: [],
				headers: [
					{ text: 'Tên đề tài', value: 'ThesisName' },
					{ text: 'Khoa', value: 'ThesisMajor' },
					{ text: 'Tác giả', value: 'ThesisStudent' },
				],
			};
		},
		computed: {
			activeDsRootProcess() {
				return this.dsRootProcess || [];
			},
			studentDisplayId() {
				return this.studentInfo?.Student_ID || this.studentInfo?.StudentID || this.studentId || "";
			},
			studentDisplayName() {
				return this.studentInfo?.Student_Name || `${this.studentInfo?.HoSV || ''} ${this.studentInfo?.TenSV || ''}`.trim() || "";
			},
			studentClassId() {
				return this.studentInfo?.Class_ID || this.studentInfo?.LopID || "";
			},
			activeRootStep() {
				if (!this.activeDsRootProcess || this.activeDsRootProcess.length === 0) return {};
				return this.activeDsRootProcess[this.selectedRootIndex] || this.activeDsRootProcess[0];
			},
			isSystemRight1() {
				return this.systemRight === 1 || (typeof vueData !== 'undefined' && vueData.user && vueData.user.SystemRight === 1);
			},
			isStep5() {
				const step = this.activeRootStep;
				if (!step) return false;
				const taskId = Number(step.Children_Task_ID || step.Task_ID || 0);
				const seq = Number(step.Seq || step.SEQ || 0);
				return seq === 30 || [4, 22].includes(taskId) || ['ThS03', 'ThSUD03'].includes(step.Task_Code);
			},
			historyVersions() {
				if (!this.historyList || this.historyList.length === 0) return [];
				const groups = {};
				for (const item of this.historyList) {
					const key = item.NgayTaoLichSu || item.LyDo || 'version';
					if (!groups[key]) {
						groups[key] = {
							date: item.NgayTaoLichSu ? item.NgayTaoLichSu.replace('T', ' ').substring(0, 19) : '',
							reason: item.LyDo,
							items: []
						};
					}
					groups[key].items.push(item);
				}
				return Object.values(groups);
			},
		},
		watch: {
			activeDsRootProcess: {
				async handler(val) {
					if (val && val.length > 0) {
						const pendingIndex = val.findIndex((item) => item.Flow_Status === 'P');
						const targetIndex = pendingIndex !== -1 ? pendingIndex : 0;
						this.selectedRootIndex = targetIndex;
						await this.onLoadDetail(val[targetIndex]?.Flow_ID);
					} else {
						this.detailProcess = [];
					}
				},
				immediate: true
			},
			async selectedRootIndex(val) {
				this.checkDeTaiFlag = null;
				this.resultKtraDeTai = null;
				if (val !== undefined && val !== null && this.activeDsRootProcess && this.activeDsRootProcess[val]) {
					await this.onLoadDetail(this.activeDsRootProcess[val].Flow_ID);
				}
			},
			studentId: {
				async handler(newVal) {
					if (newVal) {
						await this.onLoadStudentProcess(newVal);
					}
				},
				immediate: true
			}
		},
		mounted() {
			this.DsNNDauRa = ChungChiNgoaiNgu_NameList();
			this.DsTenNgoaiNgu = NgoaiNgu_NameList();
		},
		methods: {
			getChipColor(status) {
				switch (status) {
					case 'C': return 'green darken-2';
					case 'W': return 'amber darken-2';
					case 'P': return 'blue darken-2';
					case 'R':
					case 'D': return 'red darken-2';
					case 'N': return 'grey darken-1';
					default: return 'primary';
				}
			},
			getChipColorText(status) {
				switch (status) {
					case 'C': return 'Đã duyệt';
					case 'W': return 'Chờ duyệt';
					case 'P': return 'Đang duyệt';
					case 'R':
					case 'D': return 'Bị từ chối';
					case 'N': return 'Chưa duyệt';
					default: return 'Đang duyệt';
				}
			},
			preventNegative(e) {
				if (e.key === '-' || e.key === 'e' || e.key === '+') {
					e.preventDefault();
				}
			},
			shouldShowDuocOnlyField(itemDes) {
				return true;
			},
			countWords(str) {
				return str.trim().split(/\s+/).filter(Boolean).length;
			},
			async onLoadStudentProcess(studentId) {
				try {
					const res = await ajaxCALLPromise('/Student_Process_Get', {
						Student_ID: studentId,
						IsFull: 0
					});
					this.StudentProcList = (res || []).filter((item) => item.Process_Student_Status !== 'X');
					if (this.StudentProcList.length > 0) {
						await this.onLoadSecondRootFlow();
					}
				} catch (error) {
					console.log('Error onLoadStudentProcess', error);
				}
			},
			async onLoadSecondRootFlow() {
				const lastProcStudentID = this.StudentProcList.length > 0 ? this.StudentProcList[this.StudentProcList.length - 1].Process_Student_ID : 0;
				try {
					this.SecondRootFlow = await ajaxCALLPromise('/Get_RootFlow', {
						StudentID: this.studentDisplayId,
						Process_Student_ID: lastProcStudentID,
						Process_Tree: 1
					});
				} catch (error) {
					console.log('Error onLoadSecondRootFlow', error);
				}
			},
			async checkHocPhi(studentID) {
				const res = await ajaxGETCALLPromise(`https://tapi.lhu.edu.vn/fee/NoHP_GetChiTietNoHocPhiByStudent?StudentID=${studentID}`);
				if (res && res.data && res.data.length > 3 && res.data[3].length > 0 && res.data[3][0]) {
					this.feeArr = res.data[3][0].tienphaidong || 0;
				} else {
					this.feeArr = 0;
				}
				return this.feeArr;
			},
			async onLoadDetail(Flow_ID) {
				if (!Flow_ID || Flow_ID <= 0) return;
				try {
					const res = await ajaxCALLPromise('/SDH_Get_DetailProcessing', { Flow_ID: Flow_ID });
					let promiseData = (res || []).map(async (item) => {
						let ttnhp = 0;
						if (item.FN_Check === 'fnCheckHocPhi(StudentID)' && item.Task_Detail_Type === 'FUN') {
							ttnhp = await this.checkHocPhi(item.Student_id || this.studentDisplayId);
						}
						return {
							...item,
							FILE_UPLOAD: {
								File_ID: item.File_ID,
								File_Name: item.File_Name,
								File_Type: item.File_Type,
								File_URL: item.File_URL,
							},
							Flow_Detail_Status: item.Flow_Detail_Status === 'C',
							TinhTrangNoHocPhi: ttnhp,
						};
					});

					const result = await Promise.all(promiseData);
					this.detailProcess = result.map((item) => {
						if (item.Task_Detail_Type === 'CHECKBOX') {
							item.Text_Content = item.Text_Content === 'True' || item.Text_Content === true;
						}
						return item;
					});
				} catch (error) {
					Vue.$toast.error(error?.responseJSON?.Message || 'Lỗi tải chi tiết', { position: 'top' });
				}
			},
			onLinkTenDeTaiBaoVe(tenDeTai) {
				ajaxCALL(
					'/FlowDetail_Update_TenDeTai',
					{
						StudentID: this.studentDisplayId,
						Text_Content: tenDeTai && typeof tenDeTai === 'string' ? tenDeTai.trim() : tenDeTai,
					},
					() => {},
					(error) => {
						Vue.$toast.error(`${error.responseJSON?.Message || 'Lỗi cập nhật tên đề tài'}`, { position: 'top' });
					}
				);
			},
			async onSave(root) {
				if (!root || !root.Flow_ID) return;
				let validationPassed = true;
				for (const item of this.detailProcess) {
					if (item.AllowNull === '0' && item.Task_Detail_Type !== 'FILE' && item.Task_Detail_Type !== 'FILEVIEW' && !item.Text_Content && item.Task_Detail_Type !== 'FUN') {
						Vue.$toast.error(`Task "${item.TASK_DETAIL_DESCRIPTION}" chưa nhập nội dung`, { position: 'top' });
						validationPassed = false;
						break;
					}
					if (item.FN_Check === 'fnCheckDeTaiDaDangKy') {
						if (!this.checkDeTaiFlag) {
							Vue.$toast.error(`Task "${item.TASK_DETAIL_DESCRIPTION}" chưa kiểm tra khớp đề tài`, { position: 'top' });
							validationPassed = false;
							break;
						} else if (this.checkDeTaiFlag === false) {
							Vue.$toast.error(`Task "${item.TASK_DETAIL_DESCRIPTION}" đề tài không khớp`, { position: 'top' });
							validationPassed = false;
							break;
						}
					}
				}

				if (!validationPassed) return;

				const payloadDetails = this.detailProcess.map((item) => ({
					Task_Detail_ID: item.TASK_DETAIL_ID,
					Text_Content: typeof item.Text_Content === 'string' && item.Text_Content ? item.Text_Content.trim() : (item.Text_Content ?? ''),
					File_Name: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Name ?? null) : null,
					File_Type: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Type ?? null) : null,
					File_URL: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_URL ?? null) : null,
					File_ID: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_ID ?? null) : null,
					Flow_Detail_Status: item.Flow_Detail_Status ? 'C' : 'W',
				}));

				try {
					await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
						Student_ID: this.studentDisplayId,
						Process_ID: root.Process_ID,
						Flow_ID: root.Flow_ID,
						Task_ID: root.Children_Task_ID || this.detailProcess[0]?.TASK_ID,
						JsonDetails: JSON.stringify(payloadDetails),
						IsApproveAll: 0,
					});
					Vue.$toast.success(`Cập nhật ${root.Task_Name} thành công`, { position: 'top' });
				} catch (error) {
					Vue.$toast.error(`${error?.responseJSON?.Message || 'Lỗi cập nhật'}`, { position: 'top' });
				}
			},
			isItemEmpty(item) {
				if (!item) return false;
				const type = item.Task_Detail_Type;
				if (type === 'FILE' || type === 'FILEVIEW') {
					const hasFileId = item.File_ID && String(item.File_ID).trim() !== '';
					const hasFileUrl = item.File_URL && String(item.File_URL).trim() !== '';
					const hasFileName = item.File_Name && String(item.File_Name).trim() !== '';
					const hasUpload = item.FILE_UPLOAD && item.FILE_UPLOAD.File_ID && String(item.FILE_UPLOAD.File_ID).trim() !== '';
					return !(hasFileId || hasFileUrl || hasFileName || hasUpload);
				}
				if (['TEXT', 'TEXTAREA', 'TEXTVIEW', 'DATE', 'DATEVIEW', 'NUMBER', 'NUMBERVIEW', 'SELECT', 'DIEM', 'FORMULAR', 'TEXTAREA | FUN'].includes(type)) {
					if (item.Text_Content === null || item.Text_Content === undefined) return true;
					if (typeof item.Text_Content === 'string' && item.Text_Content.trim() === '') return true;
					return false;
				}
				return false;
			},
			async executeCheckButNotSave(detail, root) {
				try {
					for (const item of detail) {
						if (item.TASK_DETAIL_ID === 46 && item.Text_Content) {
							this.onLinkTenDeTaiBaoVe(item.Text_Content);
						}
					}

					await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
						Student_ID: this.studentDisplayId,
						Process_ID: root.Process_ID,
						Flow_ID: root.Flow_ID,
						Task_ID: root.Children_Task_ID || detail[0]?.TASK_ID,
						JsonDetails: '[]',
						IsApproveAll: 1,
					});

					Vue.$toast.success(`Duyệt thành công`, { position: 'top' });
					const lastIndex = detail.length - 1 >= 0 ? detail.length - 1 : 0;
					if (detail.length > 0 && detail[lastIndex]?.FN_Check === 'fnLastProcess') {
						try {
							await ajaxCALLPromise('/LuanVan_HoanThanh', {
								StudentID: detail[lastIndex].Student_id || this.studentDisplayId,
							});
						} catch (e) {
							console.log('error hoan thanh luan van', e);
						}
					}

					this.$emit('on-reload');
				} catch (err) {
					Vue.$toast.error(`${err?.responseJSON?.Message || 'Duyệt thất bại'}`, { position: 'top' });
				}
			},
			openRejectDialog(root) {
				const daoVanItem = (this.detailProcess || []).find((i) => i.FieldName === 'fileCheckDaoVan');
				const hasDaoVan = daoVanItem && (
					(daoVanItem.File_ID && String(daoVanItem.File_ID).trim() !== '') ||
					(daoVanItem.FILE_UPLOAD && daoVanItem.FILE_UPLOAD.File_ID)
				);
				if (!hasDaoVan) {
					Vue.$toast.error('Vui lòng upload file kết quả kiểm tra đạo văn trước khi từ chối hồ sơ', { position: 'top' });
					return;
				}
				this.rejectionReason = '';
				this.rejectDialog = true;
			},
			async confirmReject() {
				const daoVanItem = (this.detailProcess || []).find((i) => i.FieldName === 'fileCheckDaoVan');
				const fileIdDaoVan = daoVanItem?.File_ID || daoVanItem?.FILE_UPLOAD?.File_ID || '';
				const fileNameDaoVan = daoVanItem?.File_Name || daoVanItem?.FILE_UPLOAD?.File_Name || '';
				const fileUrlDaoVan = daoVanItem?.File_URL || daoVanItem?.FILE_UPLOAD?.File_URL || '';

				if (!fileIdDaoVan) {
					Vue.$toast.error('Vui lòng upload file kết quả kiểm tra đạo văn trước khi từ chối hồ sơ', { position: 'top' });
					return;
				}
				if (!this.rejectionReason || !this.rejectionReason.trim()) {
					Vue.$toast.error('Vui lòng nhập lý do từ chối', { position: 'top' });
					return;
				}
				this.isRejecting = true;
				try {
					await ajaxCALLPromise('/SDH_Reject_Defend_Thesis', {
						Student_ID: this.studentDisplayId,
						Flow_ID: this.activeRootStep?.Flow_ID,
						Task_ID: this.activeRootStep?.Children_Task_ID || this.detailProcess[0]?.TASK_ID,
						LyDo: this.rejectionReason.trim(),
						File_ID_DaoVan: fileIdDaoVan,
						File_Name_DaoVan: fileNameDaoVan,
						File_URL_DaoVan: fileUrlDaoVan,
						sys_UserID: window.vueData?.user?.UserID || ''
					});
					Vue.$toast.success('Đã từ chối và lưu lịch sử phiên nộp thành công', { position: 'top' });
					this.rejectDialog = false;
					this.$emit('on-reload');
				} catch (error) {
					Vue.$toast.error(`Lỗi từ chối: ${error?.responseJSON?.Message || error?.message || ''}`, { position: 'top' });
				} finally {
					this.isRejecting = false;
				}
			},
			async openHistoryDialog(root) {
				this.historyDialog = true;
				this.historyLoading = true;
				try {
					const flowId = root?.Flow_ID;
					const res = await ajaxCALLPromise('/SDH_Get_FlowDetail_His', { Flow_ID: flowId });
					this.historyList = res || [];
				} catch (e) {
					console.log('Error loading history: ', e);
					this.historyList = [];
				} finally {
					this.historyLoading = false;
				}
			},
			async onCheckButNotSave(detail, root) {
				const emptyItems = (detail || []).filter((item) => this.isItemEmpty(item));
				if (emptyItems.length > 0) {
					const emptyNames = emptyItems.map((i) => `• ${i.TASK_DETAIL_DESCRIPTION || 'Mục không tên'}`).join('\n');
					confirm({
						title: 'Cảnh báo còn mục chưa có dữ liệu',
						content: `Còn ${emptyItems.length} mục chưa có nội dung hoặc file đính kèm:\n${emptyNames}\n\nBạn có chắc chắn muốn duyệt tất cả không?`,
						action: async () => {
							await this.executeCheckButNotSave(detail, root);
						},
					});
				} else {
					confirm({
						title: 'Xác nhận duyệt tất cả',
						content: 'Bạn có chắc chắn muốn duyệt tất cả các mục này không?',
						action: async () => {
							await this.executeCheckButNotSave(detail, root);
						},
					});
				}
			},
			async executeCheckAll(detail, root) {
				const payloadDetails = detail.map((item) => ({
					Task_Detail_ID: item.TASK_DETAIL_ID,
					Text_Content: item.Text_Content && typeof item.Text_Content === 'string' ? item.Text_Content.trim() : (item.Text_Content ?? ''),
					File_Name: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Name ?? null) : null,
					File_Type: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Type ?? null) : null,
					File_URL: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_URL ?? null) : null,
					File_ID: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_ID ?? null) : null,
					Flow_Detail_Status: 'C',
				}));

				detail.forEach((item) => (item.Flow_Detail_Status = true));

				try {
					await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
						Student_ID: this.studentDisplayId,
						Process_ID: root.Process_ID,
						Flow_ID: root.Flow_ID,
						Task_ID: root.Children_Task_ID || detail[0]?.TASK_ID,
						JsonDetails: JSON.stringify(payloadDetails),
						IsApproveAll: 1,
					});

					Vue.$toast.success(`Duyệt thành công`, { position: 'top' });
					const lastIndex = detail.length - 1 >= 0 ? detail.length - 1 : 0;
					if (detail.length > 0 && detail[lastIndex]?.FN_Check === 'fnLastProcess') {
						try {
							await ajaxCALLPromise('/LuanVan_HoanThanh', {
								StudentID: detail[lastIndex].Student_id || this.studentDisplayId,
							});
						} catch (e) {
							console.log('error hoan thanh luan van', e);
						}
					}

					this.$emit('on-reload');
				} catch (error) {
					Vue.$toast.error(`Lỗi duyệt tất cả: ${error?.responseJSON?.Message || error?.message || ''}`, { position: 'top' });
				}
			},
			async onCheckAll(detail, root) {
				for (const item of detail) {
					if (item.AllowNull === '0' && item.Task_Detail_Type !== 'FILE' && item.Task_Detail_Type !== 'FILEVIEW' && !item.Text_Content && item.Task_Detail_Type !== 'FUN') {
						Vue.$toast.error(`Task "${item.TASK_DETAIL_DESCRIPTION}" chưa nhập nội dung`, { position: 'top' });
						return;
					}
					if (item.FN_Check === 'fnCheckDeTaiDaDangKy') {
						if (!this.checkDeTaiFlag) {
							Vue.$toast.error(`Task "${item.TASK_DETAIL_DESCRIPTION}" chưa kiểm tra khớp đề tài`, { position: 'top' });
							return;
						} else if (this.checkDeTaiFlag === false) {
							Vue.$toast.error(`Task "${item.TASK_DETAIL_DESCRIPTION}" đề tài không khớp`, { position: 'top' });
							return;
						}
					}
					if (item.TASK_DETAIL_ID === 46 && item.Text_Content) {
						this.onLinkTenDeTaiBaoVe(item.Text_Content);
					}
				}

				const emptyItems = (detail || []).filter((item) => this.isItemEmpty(item));
				if (emptyItems.length > 0) {
					const emptyNames = emptyItems.map((i) => `• ${i.TASK_DETAIL_DESCRIPTION || 'Mục không tên'}`).join('\n');
					confirm({
						title: 'Cảnh báo còn mục chưa có dữ liệu',
						content: `Còn ${emptyItems.length} mục chưa có nội dung hoặc file đính kèm:\n${emptyNames}\n\nBạn có chắc chắn muốn duyệt và lưu tất cả không?`,
						action: async () => {
							await this.executeCheckAll(detail, root);
						},
					});
				} else {
					confirm({
						title: 'Xác nhận duyệt & lưu tất cả',
						content: 'Bạn có chắc chắn muốn duyệt và lưu tất cả các mục này không?',
						action: async () => {
							await this.executeCheckAll(detail, root);
						},
					});
				}
			},
			checkingStatus(item, root) {
				const isApproving = item.Flow_Detail_Status === false;
				let title = 'Xác nhận duyệt';
				let content = '';

				if (isApproving) {
					if (this.isItemEmpty(item)) {
						title = 'Cảnh báo duyệt ô trống';
						content = `Mục "${item.TASK_DETAIL_DESCRIPTION}" hiện chưa có dữ liệu hoặc file đính kèm.\nBạn có chắc chắn muốn duyệt không?`;
					} else {
						content = `Bạn có muốn duyệt mục "${item.TASK_DETAIL_DESCRIPTION}" này không?`;
					}
				} else {
					title = 'Xác nhận hủy duyệt';
					content = `Bạn có muốn hủy duyệt mục "${item.TASK_DETAIL_DESCRIPTION}" này?`;
				}

				confirm({
					title: title,
					content: content,
					action: async () => {
						try {
							const newStatus = item.Flow_Detail_Status === false ? 'C' : 'P';
							await ajaxCALLPromise('/FlowDetail_UpdateStatus', {
								Student_ID: this.studentDisplayId,
								Process_ID: root.Process_ID,
								Flow_ID: item.FLOW_ID,
								Task_ID: item.TASK_ID,
								Task_Detail_ID: item.TASK_DETAIL_ID,
								Flow_Detail_Status: newStatus,
							});
							Vue.$toast.success(`Cập nhật thành công`, { position: 'top' });
							item.Flow_Detail_Status = !item.Flow_Detail_Status;
						} catch (error) {
							Vue.$toast.error(`${error.responseJSON?.Message || 'Lỗi cập nhật'}`, { position: 'top' });
						}
					},
				});
			},
			async checkDeTaiDaDky(studentID, textContent) {
				try {
					const res = await ajaxCALLPromise('/Student_Check_TenDeTaiDaDangKy', { Student_ID: studentID });
					this.resultKtraDeTai = res && res[0]?.Text_Content;
					if (textContent) {
						this.checkDeTaiFlag = this.resultKtraDeTai ? (this.resultKtraDeTai.toLowerCase() === textContent.toLowerCase()) : false;
					} else {
						Vue.$toast.error('Không được bỏ trống ô nhập tên đề tài', { position: 'top' });
					}
				} catch (error) {
					console.error('Error checkDeTaiDaDky', error);
				}
			},
			async checkTopicBtn(TenDeTai) {
				try {
					const res = await ajaxCALLPromise('/Get_SimiliarPaper', { TenDeTai: TenDeTai });
					this.similiarTopic = Array.isArray(res) ? res : (res?.data || []);
				} catch (error) {
					console.error('Error checkTopicBtn', error);
				}
			}
		}
	}
</script>