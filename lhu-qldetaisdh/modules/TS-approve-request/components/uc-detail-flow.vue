<template>
	<div style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding-right: 4px; padding-top: 12px;">
		<!-- Fixed Header Block: Thông tin học viên -->
		<div class="uc-student-info-bar mb-3 flex-shrink-0" v-if="studentInfo">
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
								<span class="uc-ar-name-padding d-flex align-center">
									<h4 v-show="shouldShowDuocOnlyField(item)"
										class="text-body-1 font-weight-medium grey--text text--darken-4">
										{{ activeRootStep.Step_Index || (selectedRootIndex + 1) }}.{{ index + 1 }}./ {{ item.TASK_DETAIL_DESCRIPTION }}
									</h4>
									<div v-if="item.Task_Detail_Type === 'CHECKBOX'" class="ml-3">
										<v-checkbox large color="success" :hint="item.Data_Exp" v-model="item.Text_Content"
											persistent-hint class="ma-0 pa-0" hide-details />
									</div>
								</span>

								<uc-text v-show="shouldShowDuocOnlyField(item)" class="mt-2" :item="item"
									:text-rules="textRules"
									v-if="item.Task_Detail_Type === 'TEXT' || item.Task_Detail_Type === 'TEXTVIEW'" />
							<c-file-comp :item-des="item" :allow-upload="true" :api-file="apiFile"
								:url-read-file="urlReadFile"
								v-if="item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW'"
								class="mt-2" />
							<c-textarea-comp class="mt-2 mb-1" :item-des="item" :text-rules="textRules"
								:allow-edit="true" v-if="item.Task_Detail_Type === 'TEXTAREA'" />

							<!-- Kiểm tra trùng tên đề tài đã đăng ký -->
							<div class="mb-2 mt-2" v-if="item.FN_Check === 'fnCheckDeTaiDaDangKy'">
								<div class="d-flex align-center justify-center" style="gap: 15px">
									<v-textarea v-model="item.Text_Content" outlined name="input-7-1" rows="1"
										color="green" flat="false" auto-grow dense hide-details />

									<v-btn color="warning" @click="checkDeTaiDaDky(studentId, item.Text_Content)"
										class="mt-0" :disabled="item.Text_Content === null || item.Text_Content === ''">
										Kiểm tra đề tài đã đăng ký</v-btn>
								</div>
								<div class="mt-3 mb-2" v-if="checkDeTaiFlag !== null">
									<div v-if="checkDeTaiFlag === true" class="d-flex justify-center align-center">
										<h4 class="success--text text-subtitle-2">
											<v-icon class="mb-1" color="success">mdi-check-bold</v-icon>
											Giống với tên đề tài đã đăng ký
										</h4>
									</div>

									<div v-if="checkDeTaiFlag === false" class="d-flex justify-center align-center">
										<h4 class="error--text text-subtitle-2">
											<v-icon class="mb-1" color="error">mdi-alert-circle</v-icon>
											Khác tên đề tài đã đăng ký
										</h4>
									</div>
								</div>
								<div class="d-flex align-center mb-2 mt-2" v-if="resultKtraDeTai">
									<h4 class="primary--text text-subtitle-2">Tên đề tài trong Quyết định:</h4>
									<p class="mb-0 ml-2 text-body-2">
										{{ resultKtraDeTai }}
									</p>
								</div>
							</div>

							<v-text-field
								v-if="item.Task_Detail_Type === 'DATE' || item.Task_Detail_Type === 'DATEVIEW'"
								v-model="item.Text_Content" type="date" outlined dense hide-details color="success"
								class="mt-2" />

							<div class="mt-2"
								v-if="item.Task_Detail_Type === 'TEXTAREA | FUN' && item.FN_Check === 'fnCheckTenDeTai'">
								<div class="d-flex align-center justify-center" style="gap: 15px">
									<div class="uc-ar-input-container">
										<c-textarea-comp :item-des="item" :text-rules="textRules" :allow-edit="true" />
									</div>
									<v-btn color="warning" @click="checkTopicBtn(item.Text_Content)" class="mb-3">Kiểm
										tra đề tài trùng</v-btn>
								</div>
							</div>
						</v-col>

						<!-- Cột bên phải: Nút duyệt Checkbox lớn dễ bấm -->
						<v-col cols="2" class="d-flex justify-center align-center">
							<div class="text-center">
								<div class="text-caption grey--text mb-1">Duyệt</div>
								<v-checkbox v-model="item.Flow_Detail_Status"
									@click.native.prevent.stop.capture="checkingStatus(item, activeRootStep)"
									hide-details class="ma-0 pa-0"></v-checkbox>
							</div>
						</v-col>
					</v-row>

					<!-- Hiển thị học phí (FUN) rộng 100% dòng -->
					<div v-if="item.Task_Detail_Type === 'FUN' && item.FN_Check === 'fnCheckHocPhi(StudentID)'"
						class="mt-3 w-100">
						<div class="mb-1 mt-1">
							<div>
								<div v-if="item.TinhTrangNoHocPhi == 0 || item.TinhTrangNoHocPhi === '0'"
									class="d-flex justify-center align-center">
									<h4 class="success--text text-subtitle-2">
										<v-icon class="mb-1" color="success">mdi-check-bold</v-icon>
										Không nợ học phí
									</h4>
								</div>
								<div v-else class="d-flex justify-center align-center">
									<span class="primary--text"><b>Tình trạng nợ học phí:</b></span>
									<span class="red--text ml-2">
										<b>{{ item.TinhTrangNoHocPhi }}</b>
										<b
											v-if="typeof item.TinhTrangNoHocPhi === 'number' || !isNaN(item.TinhTrangNoHocPhi)">
											VNĐ</b>
									</span>
								</div>
							</div>
						</div>
					</div>

					<!-- Bảng đề tài liên quan hiển thị rộng 100% dòng -->
					<div class="mt-3 w-100"
						v-if="item.Task_Detail_Type === 'TEXTAREA | FUN' && item.FN_Check === 'fnCheckTenDeTai' && item.Text_Content !== ''">
						<div class="mb-1">
							<v-card v-if="similiarTopic.length > 0">
								<v-card-title class="py-2">
									<span class="primary--text text-subtitle-1">Những đề tài liên quan</span>
								</v-card-title>
								<div>
									<v-data-table :headers="[
										{ text: 'Mã HV', value: 'StudentID' },
										{ text: 'Tên Học Viên', value: 'StudentName' },
										{ text: 'Tên Đề Tài', value: 'ThesisName' },
									]" :items="similiarTopic" class="elevation-1" loading-text="Đang tải dữ liệu..." hide-default-footer="true"
										no-data-text="Không có đề tài liên quan" />
								</div>
							</v-card>
							<div class="d-flex justify-center align-center">
								<h4 v-if="similiarTopic.length === 0" class="success--text text-subtitle-2">
									<v-icon class="mb-1" color="success">mdi-check-bold</v-icon> Không có đề tài liên
									quan
								</h4>
							</div>
						</div>
					</div>

					<!-- Bảng thành viên hội đồng hiển thị rộng 100% dòng -->
					<div v-if="item.Task_Detail_Type === 'TABLE'" class="mt-3 w-100">
						<uc-table-view :item="item" />
					</div>
				</div>
			</v-card>
		</div>

		<!-- Fixed Footer Action Bar: Các nút luôn cố định ở dưới cùng -->
		<div class="d-flex align-center justify-end w-100 py-2 px-1 flex-shrink-0 mt-2" style="gap: 12px; border-top: 1px solid #eef2f5;">
				<!-- Nút Lưu thông tin nhập liệu -->
				<v-btn color="success" dark @click="onSaveAllDataOnly(detailProcess, activeRootStep)">
					<v-icon left>mdi-content-save</v-icon>
					Lưu thông tin
				</v-btn>

				<!-- Nút Duyệt & Lưu tất cả -->
				<v-btn color="primary" dark @click="onCheckAll(detailProcess, activeRootStep)">
					<v-icon left>mdi-check-all</v-icon>
					Duyệt & Lưu tất cả
				</v-btn>

				<!-- Nút Duyệt nhanh không lưu (Chỉ dành cho Admin/Quyền hệ thống) -->
				<v-btn color="indigo" dark @click="onCheckButNotSave(detailProcess, activeRootStep)"
					v-if="systemRight === 1">
					<v-icon left>mdi-check-bold</v-icon>
					Duyệt tất cả (Không lưu)
				</v-btn>
			</div>
		</div>
		<v-card v-else flat class="d-flex align-center justify-center" style="min-height: 200px;">
			<div class="text-center grey--text">Đang tải tiến trình...</div>
		</v-card>
	</div>
</template>

<script>
	export default {
		name: "uc-detail-flow",
	props: {
		studentId: { type: [String, Number], default: "" },
		studentInfo: { type: Object, default: () => ({}) },
		dsRootProcess: { type: Array, default: () => [] },
		apiFile: { type: String, default: "" },
		urlReadFile: { type: String, default: "" },
		systemRight: { type: Number, default: 0 }
	},
	data() {
		return {
			selectedRootIndex: 0,
			detailProcess: [],
			initialDetailProcess: [],
			similiarTopic: [],
			checkDeTaiFlag: null,
			resultKtraDeTai: '',
			feeArr: '0',
			
			textRules: [
				(v) => !!v || 'Vui lòng nhập thông tin',
			],
			
			DsNNDauRa: [],

			DsTenNgoaiNgu: [
				{ text: 'Tiếng Anh', value: 'Tiếng Anh' },
				{ text: 'Tiếng Trung', value: 'Tiếng Trung' },
				{ text: 'Tiếng Nhật', value: 'Tiếng Nhật' },
				{ text: 'Tin Học', value: 'Tin Học' },
			],
		}
	},
	computed: {
		studentDisplayName() {
			return this.studentInfo?.Student_Name || `${this.studentInfo?.HoSV || ''} ${this.studentInfo?.TenSV || ''}`.trim() || '';
		},
		studentDisplayId() {
			return this.studentInfo?.Student_ID || this.studentInfo?.StudentID || this.studentId || '';
		},
		studentClassId() {
			return this.studentInfo?.Class_ID || this.studentInfo?.LopID || '';
		},
		activeDsRootProcess() {
			return this.dsRootProcess || [];
		},
		activeRootStep() {
			if (!this.activeDsRootProcess || this.activeDsRootProcess.length === 0) return {};
			return this.activeDsRootProcess[this.selectedRootIndex] || this.activeDsRootProcess[0];
		},
		activeProcess() {
			return this.activeRootStep;
		}
	},
	watch: {
		studentId: async function (newVal) {
			await this.cleanupUnsavedFiles();
			this.detailProcess = [];
			this.checkDeTaiFlag = null;
			this.resultKtraDeTai = '';
		},
		activeDsRootProcess: {
			async handler(val) {
				if (val && val.length > 0) {
					let targetIndex = 0;
					if (this.studentInfo && (this.studentInfo.Flow_ID || this.studentInfo.Task_ID)) {
						const matchedIdx = val.findIndex(p => 
							(this.studentInfo.Flow_ID && p.Flow_ID === this.studentInfo.Flow_ID) ||
							(this.studentInfo.Task_ID && (p.Children_Task_ID === this.studentInfo.Task_ID || p.Task_ID === this.studentInfo.Task_ID))
						);
						if (matchedIdx !== -1) targetIndex = matchedIdx;
					}
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
			this.resultKtraDeTai = '';
			if (val !== undefined && val !== null && this.activeDsRootProcess && this.activeDsRootProcess[val]) {
				await this.onLoadDetail(this.activeDsRootProcess[val].Flow_ID);
			}
		},
		studentInfo: {
			async handler(newVal, oldVal) {
				if (newVal && (!oldVal || newVal.Flow_ID !== oldVal.Flow_ID || newVal.Task_ID !== oldVal.Task_ID || newVal.Student_ID !== oldVal.Student_ID)) {
					await this.cleanupUnsavedFiles();
					if (this.activeDsRootProcess && this.activeDsRootProcess.length > 0) {
						let targetIndex = 0;
						if (newVal.Flow_ID) {
							const idx = this.activeDsRootProcess.findIndex(p => p.Flow_ID === newVal.Flow_ID);
							if (idx !== -1) targetIndex = idx;
						} else if (newVal.Task_ID) {
							const idx = this.activeDsRootProcess.findIndex(p => p.Children_Task_ID === newVal.Task_ID || p.Task_ID === newVal.Task_ID);
							if (idx !== -1) targetIndex = idx;
						}
						this.selectedRootIndex = targetIndex;
						await this.onLoadDetail(this.activeDsRootProcess[targetIndex]?.Flow_ID);
					}
				}
			},
			deep: true
		}
	},
	mounted() {
		if (typeof ChungChiNgoaiNgu_NameList === 'function') {
			this.DsNNDauRa = ChungChiNgoaiNgu_NameList()
		}
		window.addEventListener('beforeunload', this.cleanupUnsavedFiles);
	},
	beforeDestroy() {
		window.removeEventListener('beforeunload', this.cleanupUnsavedFiles);
		this.cleanupUnsavedFiles()
	},
	methods: {
		async cleanupUnsavedFiles() {
			if (window.unsavedUploadedFiles && window.unsavedUploadedFiles.length > 0) {
				const fileids = window.unsavedUploadedFiles.join(",");
				try {
					await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: fileids });
				} catch (e) {
					console.error("Lỗi xóa file rác (Approve Request):", e);
				}
				window.unsavedUploadedFiles = [];
			}
		},
		loadActiveDetail() {
			if (this.activeProcess && this.activeProcess.Flow_ID) {
				this.onLoadDetail(this.activeProcess.Flow_ID);
			} else {
				this.detailProcess = [];
			}
		},
		getChipColor(name) {
			switch (name) {
				case "W":
					return "info";
				case "C":
					return "success";
				case "P":
					return "blue light-2";
				case "R":
					return "error";
				default:
					return "secondary";
			}
		},
		getChipColorText(status) {
			switch (status) {
				case "W": return "Đang chờ";
				case "C": return "Đã hoàn thành";
				case "P": return "Đang xử lý";
				case "R": return "Bị từ chối";
				default: return "Chưa thực hiện";
			}
		},
		getStepIcon(name) {
			switch (name) {
				case "w": //W: WAIT
					return "mdi-information"
				case "C": //C: COMPLETED
					return "mdi-check-bold"
				case "P": //P: PROCESSING
					return "mdi-pencil"
				case "R": //R: REJECT
					return "mdi-close"
				default:
					return "mdi-help"
			}
		},
		preventNegative(e) {
			if (e.key === '-' || e.key === 'e' || e.key === '+') {
				e.preventDefault()
			}
		},
		countWords(str) {
			if (!str) return 0
			return str.trim().split(/\s+/).length
		},
		shouldShowDuocOnlyField(itemDes) {
			return true
		},
		isChanged(item) {
			const initialItem = this.initialDetailProcess.find(init => init.TASK_DETAIL_ID === item.TASK_DETAIL_ID)
			
			const currentText = typeof item.Text_Content === 'string' ? item.Text_Content.trim() : item.Text_Content
			const hasInput = (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW')
				? !!(item.File_ID || item.File_URL)
				: (currentText !== null && currentText !== undefined && currentText !== '')

			if (!initialItem) return hasInput

			const initialText = typeof initialItem.Text_Content === 'string' ? initialItem.Text_Content.trim() : initialItem.Text_Content

			const isTextChanged = currentText !== initialText
			const isFileChanged = (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') && (
				item.File_ID !== initialItem.File_ID ||
				item.File_URL !== initialItem.File_URL ||
				item.File_Name !== initialItem.File_Name ||
				item.File_Type !== initialItem.File_Type
			)

			return isTextChanged || isFileChanged
		},
		async checkHocPhi(studentID) {
			try {
				const res = await ajaxGETCALLPromise(`https://tapi.lhu.edu.vn//fee/NoHP_GetChiTietNoHocPhiByStudent?StudentID=${studentID}`);
				this.feeArr = res && res.data && res.data.length > 3 && res.data[3].length > 0 && res.data[3][0] 
					? res.data[3][0].tienphaidong 
					: 'Không tìm thấy. Vui lòng liên hệ phòng tài chính';
				return this.feeArr;
			} catch (error) {
				console.log('check hoc phi that bai: ', error);
				return 'Không tìm thấy. Vui lòng liên hệ phòng tài chính';
			}
		},
		async onLinkTenDeTaiBaoVe(TenDeTai) {
			try {
				await ajaxCALLPromise('/Student_Link_TenDeTaiBaoVe', {
					Student_ID: this.studentId,
					Text_Content: TenDeTai,
				});
				console.log('link de tai thanh cong');
			} catch (error) {
				Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi liên kết đề tài', { position: 'top' });
				console.log('error', error);
			}
		},
		async onSaveAllDataOnly(detailProcess, root) {
			const $this = this
			const changedItems = detailProcess.filter(item => this.isChanged(item))
			
			if (changedItems.length === 0) {
				Vue.$toast.info('Không có thông tin nào thay đổi', { position: 'top' })
				return
			}

			for (const item of changedItems) {
				if (item.FieldName === 'TenDeTaiBaoVe' && item.Text_Content) {
					await this.onLinkTenDeTaiBaoVe(item.Text_Content)
				}
			}

			const payloadDetails = changedItems.map(item => ({
				Task_Detail_ID: item.TASK_DETAIL_ID,
				Text_Content: item.Text_Content && typeof item.Text_Content === 'string' ? item.Text_Content.trim() : (item.Text_Content ?? ''),
				File_Name: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Name ?? null) : null,
				File_Type: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Type ?? null) : null,
				File_URL: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_URL ?? null) : null,
				File_ID: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_ID ?? null) : null,
				Flow_Detail_Status: item.Flow_Detail_Status ? 'C' : 'W'
			}))

			try {
				await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
					Student_ID: $this.studentId,
					Process_ID: root.Process_ID,
					Flow_ID: root.Flow_ID,
					Task_ID: root.Children_Task_ID || detailProcess[0]?.TASK_ID,
					JsonDetails: JSON.stringify(payloadDetails),
					IsApproveAll: 0
				})

				const oldFileIds = []
				for (const item of changedItems) {
					const initialItem = $this.initialDetailProcess.find(init => init.TASK_DETAIL_ID === item.TASK_DETAIL_ID)
					if (initialItem && ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type)) {
						if (initialItem.File_ID && item.File_ID !== initialItem.File_ID) {
							oldFileIds.push(initialItem.File_ID)
						}
					}
				}
				if (oldFileIds.length > 0) {
					try {
						await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: oldFileIds.join(",") })
					} catch (e) {
						console.error("Lỗi xóa file cũ bị thay thế (Approve):", e)
					}
				}

				window.unsavedUploadedFiles = []
				Vue.$toast.success('Lưu thông tin thành công', { position: 'top' })
				$this.$emit('on-reload')
				$this.initialDetailProcess = JSON.parse(JSON.stringify($this.detailProcess))
			} catch (error) {
				Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi lưu thông tin', { position: 'top' })
			}
		},
		onSaveSingle(item, root) {
			const $this = this
			return new Promise(async (resolve, reject) => {
				if (!this.isChanged(item)) {
					resolve()
					return
				}
				let apiName = '/FlowDetail_UpdateData';
				
				try {
					await ajaxCALLPromise(
						apiName,
						{
							Student_ID: $this.studentId,
							Flow_ID: item.FLOW_ID,
							Task_ID: item.TASK_ID,
							Process_ID: root.Process_ID,
							Task_Detail_ID: item.TASK_DETAIL_ID,
							Text_Content: item.Text_Content && typeof item.Text_Content === 'string' ? item.Text_Content.trim() : item.Text_Content,
							File_Name: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Name ?? null) : null,
							File_Type: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Type ?? null) : null,
							File_URL: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_URL ?? null) : null,
							File_ID: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_ID ?? null) : null,
						}
					);
					if (item.File_ID && window.unsavedUploadedFiles) {
						window.unsavedUploadedFiles = window.unsavedUploadedFiles.filter(id => id !== item.File_ID);
					}
					const initialItem = $this.initialDetailProcess.find(init => init.TASK_DETAIL_ID === item.TASK_DETAIL_ID);
					if (initialItem && ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type)) {
						if (initialItem.File_ID && item.File_ID !== initialItem.File_ID) {
							try {
								await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: initialItem.File_ID });
							} catch (e) {
								console.error("Lỗi xóa file cũ bị thay thế (Approve Single):", e);
							}
						}
					}
					const initIdx = $this.initialDetailProcess.findIndex(init => init.TASK_DETAIL_ID === item.TASK_DETAIL_ID)
					if (initIdx !== -1) {
						$this.initialDetailProcess[initIdx] = JSON.parse(JSON.stringify(item))
					}
					resolve()
				} catch (error) {
					Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi lưu thông tin', { position: 'top' })
					reject(error)
				}
			})
		},
		onCheckButNotSave(detailProcess, root) {
			const $this = this
			confirm({
				title: 'Duyệt tất cả',
				content: 'Bạn có chắc chắn muốn duyệt tất cả các mục này không?',
				action: async () => {
					try {
						await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
							Student_ID: $this.studentId,
							Process_ID: root.Process_ID,
							Flow_ID: root.Flow_ID,
							Task_ID: root.Children_Task_ID || detailProcess[0]?.TASK_ID,
							JsonDetails: '[]',
							IsApproveAll: 1
						})
						Vue.$toast.success('Duyệt tất cả thành công', { position: 'top' })
						$this.$emit('on-reload')
					} catch (error) {
						Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi duyệt tất cả', { position: 'top' })
					}
				},
			})
		},
		onCheckAll(detailProcess, root) {
			const $this = this
			confirm({
				title: 'Duyệt tất cả',
				content: 'Bạn có chắc chắn muốn duyệt và lưu tất cả các mục này không?',
				action: async () => {
					for (const item of detailProcess) {
						if (item.FieldName === 'TenDeTaiBaoVe' && item.Text_Content) {
							await this.onLinkTenDeTaiBaoVe(item.Text_Content)
						}
					}

					const payloadDetails = detailProcess.map(item => ({
						Task_Detail_ID: item.TASK_DETAIL_ID,
						Text_Content: item.Text_Content && typeof item.Text_Content === 'string' ? item.Text_Content.trim() : (item.Text_Content ?? ''),
						File_Name: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Name ?? null) : null,
						File_Type: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Type ?? null) : null,
						File_URL: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_URL ?? null) : null,
						File_ID: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_ID ?? null) : null,
						Flow_Detail_Status: 'C'
					}))

					try {
						await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
							Student_ID: $this.studentId,
							Process_ID: root.Process_ID,
							Flow_ID: root.Flow_ID,
							Task_ID: root.Children_Task_ID || detailProcess[0]?.TASK_ID,
							JsonDetails: JSON.stringify(payloadDetails),
							IsApproveAll: 1
						})

						const oldFileIds = []
						for (const item of detailProcess) {
							const initialItem = $this.initialDetailProcess.find(init => init.TASK_DETAIL_ID === item.TASK_DETAIL_ID)
							if (initialItem && ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type)) {
								if (initialItem.File_ID && item.File_ID !== initialItem.File_ID) {
									oldFileIds.push(initialItem.File_ID)
								}
							}
						}
						if (oldFileIds.length > 0) {
							try {
								await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: oldFileIds.join(",") })
							} catch (e) {
								console.error("Lỗi xóa file cũ bị thay thế (Approve):", e)
							}
						}

						const lastIndex = detailProcess.length - 1 >= 0 ? detailProcess.length - 1 : 0
						if (detailProcess[lastIndex] && detailProcess[lastIndex].FN_Check === 'fnLastProcess') {
							try {
								await ajaxCALLPromise('/LuanVan_HoanThanh', {
									StudentID: detailProcess[lastIndex].Student_id || $this.studentId,
								})
							} catch (e) {
								console.log('error hoan thanh luan van', e)
							}
						}

						window.unsavedUploadedFiles = []
						Vue.$toast.success('Duyệt tất cả thành công', { position: 'top' })
						$this.$emit('on-reload')
					} catch (error) {
						Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi duyệt tất cả', { position: 'top' })
					}
				},
			})
		},
		checkingStatus(item, root) {
			const $this = this
			let validationPassed = true
			
			if (item.Flow_Detail_Status === false) {
				if (item.FN_Check === 'fnCheckLimit' && this.countWords(item.Text_Content) < 120) {
					Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập đủ 120 từ`, { position: 'top' })
					validationPassed = false
				}
			}

			if (validationPassed) {
				confirm({
					title: 'Xác nhận duyệt',
					content:
						item.Flow_Detail_Status === false
							? `Bạn có muốn duyệt mục "${item.TASK_DETAIL_DESCRIPTION}" này không?`
							: `Bạn có muốn hủy duyệt mục "${item.TASK_DETAIL_DESCRIPTION}" này?`,
					action: async () => {
						const updateStatus = async () => {
							item.Flow_Detail_Status_Name = item.Flow_Detail_Status === false ? 'C' : 'P'
							try {
								await ajaxCALLPromise(
									'/FlowDetail_UpdateStatus',
									{
										Student_ID: $this.studentId,
										Process_ID: root.Process_ID,
										Flow_ID: item.FLOW_ID,
										Task_ID: item.TASK_ID,
										Task_Detail_ID: item.TASK_DETAIL_ID,
										Flow_Detail_Status: item.Flow_Detail_Status_Name,
									}
								);
								Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
								item.Flow_Detail_Status = !item.Flow_Detail_Status
								$this.$emit('on-reload')
							} catch (error) {
								Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi cập nhật trạng thái', { position: 'top' })
							}
						}

						if (!item.Flow_Detail_Status) {
							if (this.systemRight === 1) {
								updateStatus()
							} else {
								this.onSaveSingle(item, root)
									.then(() => {
										updateStatus()
									})
									.catch((error) => {
										console.log('Error in onSaveSingle', error)
									})
							}
						} else {
							updateStatus()
						}
					},
				})
			}
		},
		async checkDeTaiDaDky(studentID, textContent) {
			try {
				const res = await ajaxCALLPromise(
					'/Student_Check_TenDeTaiDaDangKy',
					{
						Student_ID: studentID,
					}
				);
				this.resultKtraDeTai = res[0]?.Text_Content || ''

				if (textContent !== null && textContent !== '') {
					if (this.resultKtraDeTai.toLowerCase() === textContent.toLowerCase()) {
						this.checkDeTaiFlag = true
					} else {
						this.checkDeTaiFlag = false
					}
				} else {
					Vue.$toast.error(`Không được bỏ trống ô nhập tên đề tài bảo vệ`, { position: 'top' })
				}
			} catch (error) {
				Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi kiểm tra đề tài', { position: 'top' })
				console.log('check de tai da dang ky fail: ', error)
			}
		},
		async onLoadDetail(Flow_ID) {
			const $this = this

			if (Flow_ID && Flow_ID > 0) {
				try {
					const res = await ajaxCALLPromise('/SDH_Get_DetailProcessing', { Flow_ID: Flow_ID })

					let promiseData = res.map(async (item) => {
						if (item.FN_Check === 'fnCheckHocPhi(StudentID)' && item.Task_Detail_Type === 'FUN') {
							let ttnhp = await this.checkHocPhi(item.Student_id)
							return {
								...item,
								FILE_UPLOAD: {
									File_ID: item.File_ID,
									File_Name: item.File_Name,
									File_Type: item.File_Type,
									File_URL: item.File_URL,
								},
								Flow_Detail_Status: item.Flow_Detail_Status === 'C' || item.Flow_Detail_Status === true,
								TinhTrangNoHocPhi: ttnhp,
							}
						}

						return {
							...item,
							FILE_UPLOAD: {
								File_ID: item.File_ID,
								File_Name: item.File_Name,
								File_Type: item.File_Type,
								File_URL: item.File_URL,
							},
							Flow_Detail_Status: item.Flow_Detail_Status === 'C' || item.Flow_Detail_Status === true,
							TinhTrangNoHocPhi: 0,
						}
					})

					Promise.all(promiseData).then((result) => {
						$this.detailProcess = result.map((item) => {
							if (item.Task_Detail_Type === 'CHECKBOX') {
								item.Text_Content = item.Text_Content === true || String(item.Text_Content).toLowerCase() === 'true'
							}
							return item
						})
						$this.initialDetailProcess = JSON.parse(JSON.stringify($this.detailProcess))
					})
				} catch (error) {
					Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi tải chi tiết', { position: 'top' })
					console.log('Error: ', error)
				}
			}
		},
		async checkTopicBtn(TenDeTai) {
			try {
				const res = await ajaxCALLPromise(
					'/Get_SimiliarPaper',
					{
						TenDeTai: TenDeTai,
					}
				);
				this.similiarTopic = res;
			} catch (error) {
				Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi kiểm tra trùng đề tài', { position: 'top' })
				console.log('Error: ', error)
			}
		},
		onCloseCheckDialog() {
			this.similiarTopic = []
		},
	},
	}
</script>