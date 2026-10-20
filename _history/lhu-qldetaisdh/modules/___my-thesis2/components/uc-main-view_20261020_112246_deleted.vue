<template>
	<v-row>
		<!-- Cột bên trái: Timeline 5 giai đoạn -->
		<v-col cols="12" md="4" class="pr-md-3">
			<v-card class="pa-2 border rounded-xs d-flex flex-column main-view-card" flat>
				<h4 class="text-subtitle-1 font-weight-bold mb-3 primary--text d-flex align-center flex-shrink-0">
					<v-icon class="mr-2" color="primary">mdi-format-list-bulleted-triangle</v-icon>
					Lộ Trình Đào Tạo
				</h4>

				<div class="flex-grow-1 overflow-y-auto pr-2">
					<v-timeline dense align-top class="phd-timeline">
						<v-timeline-item v-for="(item, index) in rootflow" :key="index"
							:color="getStepTimelineColor(item.Flow_Status, index)"
							:icon="getStepTimelineIcon(item.Flow_Status, item.LOCK_STATUS)" fill-dot small
							class="pb-4 cursor-pointer" @click.native="selectStep(index)">
							<div class="d-flex flex-column">
								<span class="text-subtitle-2 font-weight-bold line-height-1-2"
									:class="activeStepIndex === index ? 'primary--text' : 'grey--text text--darken-3'">
									{{ index + 1 }}. {{ item.TASK_NAME }}
								</span>
								<div class="d-flex align-center mt-1 gap-4">
									<v-chip x-small class="font-weight-bold px-1"
										:class="getStatusChipClass(item.Flow_Status, item.LOCK_STATUS)">
										{{ getStatusLabel(item.Flow_Status, item.LOCK_STATUS) }}
									</v-chip>
								</div>
							</div>
						</v-timeline-item>
					</v-timeline>
				</div>
			</v-card>
		</v-col>

		<!-- Cột bên phải: Chi tiết giai đoạn đang chọn -->
		<v-col cols="12" md="8">
			<v-card class="pa-3 border rounded-xs d-flex flex-column main-view-inner-card" flat>
				<div class="d-flex align-center justify-space-between border-bottom pb-2 mb-3 flex-shrink-0">
					<h3 class="text-h6 font-weight-bold text-uppercase d-flex align-center mb-0 main-view-title">
						<v-avatar size="32" class="mr-2 font-weight-bold text-body-2 white--text" color="primary">
							{{ activeStepIndex + 1 }}
						</v-avatar>
						{{ activeStep.TASK_NAME }}
					</h3>

					<v-chip class="font-weight-bold"
						:class="getStatusChipClass(activeStep.Flow_Status, activeStep.LOCK_STATUS)">
						{{ getStatusLabel(activeStep.Flow_Status, activeStep.LOCK_STATUS) }}
					</v-chip>
				</div>

				<div class="flex-grow-1 overflow-y-auto pr-2">
					<div v-if="dataDetailFlow.length > 0">
						<div v-for="(itemDes, indexDes) in dataDetailFlow" :key="indexDes">
							<div class="d-flex align-center flow-detail-header mb-2">
								<span class="d-flex align-center w-100 flex-wrap">
									<h4 class="text-body-1 font-weight-medium mb-0 line-height-1-4"
										v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV'"
										v-show="shouldShowDuocOnlyField(itemDes)">
										{{ activeStepIndex + 1 }}.{{ indexDes + 1 }} {{ itemDes.Task_Detail_Description
										}}
									</h4>
									<div v-if="itemDes.Task_Detail_Type === 'CHECKBOX'" class="ml-6">
										<div class="d-flex align-center flex-nowrap gap-8">
											<v-checkbox class="mt-0 scale-1-1" large color="success" hide-details
												v-model="itemDes.Text_Content"
												:disabled="activeStep.LOCK_STATUS === 0" />
											<span v-if="itemDes.Data_Exp"
												class="ml-2 text-caption grey--text text--darken-1 white-space-nowrap line-height-1-4">{{
												itemDes.Data_Exp
												}}</span>
										</div>
									</div>
								</span>
								<div v-if="itemDes.Data_Exp !== null && itemDes.Task_Detail_Type === 'FILE'"
									class="ml-auto flex-shrink-0">
									<a class="text-decoration-none" :href="parseDataExp(itemDes.Data_Exp)"
										download="file mẫu">
										<v-btn class="text-none rounded-pill topic-status-badge" color="success" text
											small>
											<v-icon small class="mr-1">mdi-download-circle-outline</v-icon> File mẫu
										</v-btn>
									</a>
								</div>
							</div>

							<v-alert v-if="
									itemDes.isInHoa &&
									itemDes.User_Input === 'HV' &&
									(itemDes.Task_Detail_Type === 'TEXT' ||
										itemDes.Task_Detail_Type === 'TEXTAREA' ||
										itemDes.Task_Detail_Type === 'TEXTAREA | FUN' ||
										itemDes.FieldName === 'ThesisesProfSuggest1')
								" border="right" colored-border type="error" elevation="1" dense class="mb-3">
								{{ itemDes.InHoaError }}
							</v-alert>

							<i class="error--text text-caption d-block mb-2"
								v-if="(itemDes.FieldName === 'namXuatBan' || itemDes.FieldName === 'viTriTacGia') && checkHide()">
								<b>Lưu ý:</b> Phải nhập thông tin <b>Năm xuất bản</b> và <b>Vị trí tác giả</b> khi có
								bài báo khoa học
							</i>

							<v-text-field outlined dense color="success" v-model="itemDes.Text_Content"
								:hint="itemDes.Data_Exp"
								:type="itemDes.Task_Detail_StyleDisplay === 'phone' ? 'number' : itemDes.Task_Detail_StyleDisplay === 'email' ? 'email' : 'text'"
								v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && (itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW')"
								v-show="shouldShowDuocOnlyField(itemDes)"
								:disabled="itemDes.User_Input === 'SDH' || itemDes.Task_Detail_Type === 'TEXTVIEW' || activeStep.LOCK_STATUS === 0"
								class="mb-3" />

							<v-text-field
								v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Display === 1 && (itemDes.Task_Detail_Type === 'NUMBER' || itemDes.Task_Detail_Type === 'NUMBERVIEW')"
								class="text-right-input mb-3" placeholder="Nhập số" v-model="itemDes.Text_Content"
								type="number" min="0" step="0.01" inputmode="decimal" @keydown="preventNegative" dense
								outlined color="success"
								:disabled="itemDes.User_Input === 'SDH' || itemDes.Task_Detail_Type === 'TEXTVIEW' || activeStep.LOCK_STATUS === 0" />

							<div class="mb-3 w-165"
								v-if="itemDes.Task_Detail_Type === 'DATE' || itemDes.Task_Detail_Type === 'DATEVIEW'">
								<f-date v-model="itemDes.Text_Content" :disabled="activeStep.LOCK_STATUS === 0" />
							</div>

							<v-autocomplete
								v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Type === 'SELECT' && itemDes.FieldName === 'VanBangChungChiDauRa'"
								v-model="itemDes.Text_Content" :items="dsNnDauRa" item-text="text" item-value="value"
								outlined dense hide-details class="mb-3"
								:disabled="itemDes.User_Input === 'SDH' || itemDes.Task_Detail_Type === 'TEXTVIEW' || activeStep.LOCK_STATUS === 0">
							</v-autocomplete>

							<v-autocomplete
								v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Type === 'SELECT' && itemDes.FieldName === 'TenNgoaiNguDauRa'"
								v-model="itemDes.Text_Content" :items="dsTenNgoaiNgu" item-text="text"
								item-value="value" outlined dense hide-details class="mb-3"
								:disabled="itemDes.User_Input === 'SDH' || itemDes.Task_Detail_Type === 'TEXTVIEW' || activeStep.LOCK_STATUS === 0" />

							<c-file-comp class="workflow-file-comp mb-3" :lock="activeStep.LOCK_STATUS"
								:itemDes="itemDes" :item="activeStep" :textRules="textRules" :fileRule="fileRules"
								:apiFile="apiFile" :urlReadFile="urlReadFile" v-show="shouldShowDuocOnlyField(itemDes)"
								v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && (itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW')" />

							<c-textarea-comp :itemDes="itemDes" :textRules="textRules" class="mb-3"
								v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Type === 'TEXTAREA'"
								:lock="activeStep.LOCK_STATUS" />

							<c-score-comp class="mb-3"
								v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Type === 'DIEM' || itemDes.Task_Detail_Type === 'FORMULAR'"
								:itemDes="itemDes" />

							<!-- Kiểm tra trùng tên đề tài đã đăng ký -->
							<div v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.FN_Check === 'fnCheckDeTaiDaDangKy'"
								class="mb-3">
								<div class="d-flex align-center justify-center w-100">
									<v-textarea v-model="itemDes.Text_Content" outlined rows="1" color="success"
										flat="false" auto-grow dense hide-details :hint="itemDes.Task_Help" disabled />
								</div>
							</div>

							<!-- Kiem tra trung lap -->
							<div class="mb-3"
								v-if="itemDes.Task_Detail_Type === 'TEXTAREA | FUN' && itemDes.FN_Check === 'fnCheckTenDeTai'">
								<div class="d-flex align-center justify-center flex-column flex-sm-row w-100 gap-15">
									<div class="flex-grow-1 w-100">
										<c-textarea-button-comp :itemDes="itemDes" :textRules="textRules"
											:lock="activeStep.LOCK_STATUS" />
									</div>
									<div>
										<v-btn color="warning" outlined class="text-none"
											@click="checkTopicBtn(itemDes.Text_Content)"
											:disabled="activeStep.LOCK_STATUS === 0">
											<v-icon left small>mdi-text-search</v-icon> Kiểm tra đề tài trùng
										</v-btn>
									</div>
								</div>
								<div
									v-if="itemDes.FN_Check === 'fnCheckTenDeTai' && itemDes.Text_Content && activeStep.Flow_Status !== 'C'">
									<c-similiar-topic-list class="mt-3" :itemDes="itemDes" :similiarList="similiarList"
										v-if="itemDes.FN_Check === 'fnCheckTenDeTai'" />
								</div>
							</div>

							<div v-if="itemDes.Task_Detail_Type === 'FUN'" class="mb-3">
								<div v-if="itemDes.FN_Check === 'fnCheckHocPhi(StudentID)'">
									<div class="mt-2">
										<div v-if="itemDes.TinhTrangNoHocPhi == 0"
											class="d-flex align-center justify-center">
											<h4 class="success--text d-flex align-center">
												<v-icon color="success" class="mr-1">mdi-check-circle-outline</v-icon>
												Không nợ học phí
											</h4>
										</div>
										<div v-else class="text-body-2">
											<span class="info--text"><b>Tình trạng nợ học phí:</b></span>
											<span
												:class="{ 'success--text': feeArr == '0', 'error--text': feeArr != '0' }"
												class="ml-1">
												<b>{{ itemDes.TinhTrangNoHocPhi }} VNĐ</b>
											</span>
										</div>
									</div>
								</div>
							</div>

						</div>
					</div>

					<c-empty-state v-else text="Dữ liệu không tồn tại hoặc chưa được tải"
						icon="mdi-database-off-outline" />
				</div>

				<div class="d-flex justify-end mt-4 pt-3 border-top flex-shrink-0"
					v-if="activeStep.LOCK_STATUS !== 0 && activeStep.Flow_Status !== 'C' && !isSdhRole && dataDetailFlow.length > 0">
					<v-btn color="success" class="text-none font-weight-bold"
						@click="onSave(activeStep.Flow_ID, activeStep)">
						<v-icon left>mdi-content-save-outline</v-icon> Lưu thay đổi
					</v-btn>
				</div>
			</v-card>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		name: "uc-main-view",
	props: {
		rootflow: { type: Array, default: () => [] },
		studentProcess: { type: Array, default: () => [] },
		studentId: { type: [String, Number], default: null },
		apiFile: { type: String, default: '' },
		urlReadFile: { type: String, default: '' }
	},
	data() {
		return {
			activeStepIndex: 0,
			dataDetailFlow: [],
			feeArr: [],
			dsNnDauRa: [],
			dsTenNgoaiNgu: [],
			isSdhRole: false,
			similiarList: [],
			fileRules: {
				max_file_size: '100mb',
				mime_types: [
					{ title: 'All files', extensions: 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg' }
				]
			},
			textRules: [(v) => !!v || 'Không được để trống'],
			initialDetailFlow: null
		}
	},
	computed: {
		activeStep() {
			if (this.rootflow && this.rootflow.length > this.activeStepIndex) {
				return this.rootflow[this.activeStepIndex];
			}
			return {};
		}
	},
	beforeDestroy() {
		window.removeEventListener('beforeunload', this.cleanupUnsavedFiles);
		this.cleanupUnsavedFiles();
	},
	mounted() {
		if (typeof window.ChungChiNgoaiNgu_NameList === "function") this.dsNnDauRa = window.ChungChiNgoaiNgu_NameList();
		if (typeof window.NgoaiNgu_NameList === "function") this.dsTenNgoaiNgu = window.NgoaiNgu_NameList();
		window.addEventListener('beforeunload', this.cleanupUnsavedFiles);
	},
	watch: {
		rootflow: {
			immediate: true,
			handler(val) {
				if (val && val.length > 0) {
					const defaultIdx = val.findIndex((item) => item.LOCK_STATUS === 1);
					this.activeStepIndex = defaultIdx >= 0 ? defaultIdx : 0;
					const defaultFlow = val[this.activeStepIndex];
					if (defaultFlow) {
						this.onLoadDetailFlow(defaultFlow.Flow_ID, defaultFlow.LOCK_STATUS, defaultFlow);
					}
				}
			}
		},
		dataDetailFlow(val) {
			this.updateFileRules(val);
			this.checkSDHRole();
		}
	},
	methods: {
		preventNegative(e) {
			if (e.key === '-' || e.key === 'e' || e.key === '+') e.preventDefault();
		},
		checkHide() {
			if (!this.dataDetailFlow || !this.dataDetailFlow.length) return false;
			return this.dataDetailFlow.some((item) => {
				if (['fileBaiBaoKhoaHoc', 'tenBaiBao', 'tenTapChiHoiThao'].includes(item.FieldName)) {
					const hasText = item.Text_Content !== null && item.Text_Content !== undefined && item.Text_Content !== '';
					const hasFile = item.File_ID !== null && item.File_ID !== undefined && item.File_ID !== '';
					return hasText || hasFile;
				}
				return false;
			});
		},
		shouldShowDuocOnlyField(itemDes) {
			const nganhId = this.studentProcess.length > 0 ? this.studentProcess[0].NganhID : null;
			if (!itemDes || itemDes.FN_Check !== 'DuocOnly') return true;
			return nganhId && nganhId.toString() === '106';
		},
		parseDataExp(dataExp) {
			try {
				const jsonData = JSON.parse(dataExp);
				const currentNganh = this.studentProcess.length > 0 ? this.studentProcess[0].NganhID : null;
				if (currentNganh == jsonData[0].NganhID) {
					return jsonData[0].File;
				} else {
					return jsonData[1].File;
				}
			} catch (error) {
				return dataExp;
			}
		},
		checkSDHRole() {
			if(this.dataDetailFlow && this.dataDetailFlow.length > 0) {
				this.isSdhRole = this.dataDetailFlow.every((item) => item.User_Input === 'SDH');
			}
		},
		countWords(str) {
			if (!str) return 0;
			return str.trim().split(/\s+/).filter(Boolean).length;
		},
		getStatusLabel(status, lock) {
			if (lock === 0) {
				switch (status) {
					case 'W': return 'Bị khóa';
					case 'C': return 'Đã hoàn thành (Khóa)';
					case 'P': return 'Đang xử lý (Khóa)';
					case 'R': return 'Từ chối (Khóa)';
					default: return 'Đang khóa';
				}
			} else {
				switch (status) {
					case 'W': return 'Chờ thực hiện';
					case 'P': return 'Đang thực hiện';
					default: return 'Đang mở';
				}
			}
		},
		getStatusChipClass(status, lock) {
			if (lock === 0) {
				switch (status) {
					case 'C': return 'success--text green lighten-5';
					case 'P': return 'info--text blue lighten-5';
					case 'R': return 'red--text text--darken-3 bg-red-lighten-4';
					default: return 'grey--text text--darken-1 grey lighten-4';
				}
			} else {
				switch (status) {
					case 'P': return 'info--text blue lighten-5 border-info';
					default: return 'amber--text text--darken-3 yellow lighten-5';
				}
			}
		},
		getStepTimelineColor(status, idx) {
			if (this.activeStepIndex === idx) return 'primary';
			switch (status) {
				case 'C': return 'success';
				case 'P': return 'info';
				case 'W': return 'grey lighten-1';
				default: return 'grey';
			}
		},
		getStepTimelineIcon(status, lock) {
			if (lock === 0 && status === 'W') return 'mdi-lock-outline';
			switch (status) {
				case 'C': return 'mdi-check';
				case 'P': return 'mdi-clock-outline';
				case 'W': return 'mdi-dots-horizontal';
				default: return 'mdi-help-circle-outline';
			}
		},
		async selectStep(index) {
			this.activeStepIndex = index;
			const step = this.rootflow[index];
			if (step) {
				await this.onLoadDetailFlow(step.Flow_ID, step.LOCK_STATUS, step);
			}
		},
		updateFileRules(arr) {
			if(!arr) return;
			const item = arr.find((type) => type.Task_Detail_Type === 'FILE' || type.Task_Detail_Type === 'FILEVIEW');
			if (item) {
				if (!item.AllowFileType) {
					this.fileRules.mime_types[0].extensions = 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg';
				} else if (typeof item.AllowFileType === 'string') {
					this.fileRules.mime_types[0].extensions = item.AllowFileType.toLowerCase().replace(/\|/g, ',');
				} else {
					this.fileRules.mime_types[0].extensions = 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg';
				}
			}
		},
		async cleanupUnsavedFiles() {
			if (window.unsavedUploadedFiles && window.unsavedUploadedFiles.length > 0) {
				const fileids = window.unsavedUploadedFiles.join(",");
				try {
					await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: fileids });
				} catch (e) {
					console.error("Lỗi xóa nhiều file rác:", e);
				}
				window.unsavedUploadedFiles = [];
			}
		},
		async onLoadDetailFlow(FLOW_ID, LOCK_STATUS, root) {
			try {
				await this.cleanupUnsavedFiles();
				const res = await ajaxCALLPromise('/Get_FlowDetail', { Flow_ID: FLOW_ID });
				const rawData = res || [];
				
				const mappedData = await Promise.all(rawData.map(async (item) => {
					if (item.Task_Detail_Type === 'TEXTAREA | FUN' && item.FN_Check === 'fnCheckTenDeTai' && item.Text_Content && root.Flow_Status !== 'C') {
						this.checkTopicBtn(item.Text_Content);
					}
					if (root.Flow_Status !== 'C' && item.FN_Check === 'fnCheckHocPhi(StudentID)' && item.Task_Detail_Type === 'FUN') {
						let ttnhp = await this.checkHocPhi(this.studentId);
						return { ...item, FILE_UPLOAD: null, TinhTrangNoHocPhi: ttnhp };
					}
					return { ...item, FILE_UPLOAD: null, TinhTrangNoHocPhi: 0 };
				}));

				this.dataDetailFlow = mappedData.map((item) => {
					if (item.Task_Detail_Type === 'CHECKBOX') {
						item.Text_Content = item.Text_Content === 'True' ? true : false;
					}
					return {
						...item,
						isInHoa: false,
						InHoaError: '',
						Text_Content: item.FieldName === 'QDThanhLapHoiDong_ThoiGian' && item.Text_Content
							? moment(item.Text_Content).format('DD/MM/YYYY')
							: item.Task_Detail_Type === 'DIEM'
								? item.Text_Content ? parseFloat(item.Text_Content).toFixed(2) : null
								: item.Text_Content,
					}
				});
				this.initialDetailFlow = JSON.parse(JSON.stringify(this.dataDetailFlow));
			} catch (error) {
				Vue.$toast.error(`Lỗi tải chi tiết: ${error}`, { position: 'top' });
			}
		},
		async checkHocPhi(studentID) {
			try {
				const res = await ajaxGETCALLPromise(`https://tapi.lhu.edu.vn/fee/NoHP_GetChiTietNoHocPhiByStudent?StudentID=${studentID}`);
				if(res && res.data && res.data.length > 3 && res.data[3].length > 0 && res.data[3][0]) {
					this.feeArr = res.data[3][0].tienphaidong;
					return this.feeArr;
				}
				return 'Không tìm thấy. Vui lòng liên hệ phòng tài chính';
			} catch (error) {
				Vue.$toast.error(`Lỗi kiểm tra học phí`, { position: 'top' });
				return 'Lỗi kiểm tra';
			}
		},
		async checkTopicBtn(TenDeTai) {
			try {
				const res = await ajaxCALLPromise("/Get_SimiliarPaper", { "TenDeTai": TenDeTai });
				this.similiarList = res || [];
			} catch (error) {
				Vue.$toast.error(`Lỗi kiểm tra đề tài trùng`, { position: 'top' });
			}
		},
		async onSave(FLOW_ID, root) {
			let validationPassed = true;
			if (!validationPassed) return;

			try {
				const itemsToSave = this.dataDetailFlow.filter(item => {
					if (item.User_Input !== 'HV') return false;

					const initialItem = this.initialDetailFlow.find(init => init.Task_Detail_ID === item.Task_Detail_ID);
					
					const currentText = typeof item.Text_Content === 'string' ? item.Text_Content.trim() : item.Text_Content;
					const hasInput = (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW')
						? !!item.File_ID
						: (currentText !== null && currentText !== undefined && currentText !== '');

					if (!initialItem) return hasInput;

					const initialText = typeof initialItem.Text_Content === 'string' ? initialItem.Text_Content.trim() : initialItem.Text_Content;

					const isTextChanged = currentText !== initialText;
					const isFileChanged = (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') && (
						item.File_ID !== initialItem.File_ID ||
						item.File_URL !== initialItem.File_URL ||
						item.File_Name !== initialItem.File_Name ||
						item.File_Type !== initialItem.File_Type
					);

					return isTextChanged || isFileChanged;
				});

				if (itemsToSave.length === 0) {
					if (typeof Vue !== 'undefined' && Vue.$toast) {
						Vue.$toast.info("Không có thay đổi nào cần lưu", { position: 'top' });
					}
					return;
				}

				const promises = itemsToSave.map(async (item, index) => {
					await new Promise((resolve) => setTimeout(resolve, 500 * (index + 1)));
					return ajaxCALLPromise('/FlowDetail_UpdateData', {
						Student_ID: this.studentId,
						Process_ID: root.PROCESS_ID,
						Flow_ID: item.Flow_ID,
						Task_ID: item.Task_ID,
						Task_Detail_ID: item.Task_Detail_ID,
						Text_Content: typeof item.Text_Content === 'string' && item.Text_Content ? item.Text_Content.trim() : item.Text_Content,
						File_Name: item.Task_Detail_Type === 'FILE' ? (item.File_Name ?? null) : null,
						File_Type: item.Task_Detail_Type === 'FILE' ? (item.File_Type ?? null) : null,
						File_URL: item.Task_Detail_Type === 'FILE' ? (item.File_URL ?? null) : null,
						File_ID: item.Task_Detail_Type === 'FILE' ? (item.File_ID ?? null) : null,
					});
				});

				await Promise.all(promises);
				
				// Xóa file cũ đã bị thay thế trên server sau khi lưu thành công
				const oldFileIds = [];
				for (let i = 0; i < this.dataDetailFlow.length; i++) {
					const currentItem = this.dataDetailFlow[i];
					const initialItem = this.initialDetailFlow.find(item => item.Task_Detail_ID === currentItem.Task_Detail_ID);
					if (initialItem && (currentItem.Task_Detail_Type === 'FILE' || currentItem.Task_Detail_Type === 'FILEVIEW')) {
						if (initialItem.File_ID && currentItem.File_ID !== initialItem.File_ID) {
							oldFileIds.push(initialItem.File_ID);
						}
					}
				}
				if (oldFileIds.length > 0) {
					try {
						await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: oldFileIds.join(",") });
					} catch (e) {
						console.error("Lỗi xóa các file cũ bị thay thế:", e);
					}
				}

				window.unsavedUploadedFiles = [];
				Vue.$toast.success(`Cập nhật ${root.TASK_NAME} thành công`, { position: 'top' });
				this.$emit('on-reload');
				this.initialDetailFlow = JSON.parse(JSON.stringify(this.dataDetailFlow));
			} catch (error) {
				Vue.$toast.error(`Cập nhật ${root.TASK_NAME} thất bại`, { position: 'top' });
			}
		}
	}
	}
</script>