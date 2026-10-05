<template>
	<v-row class="ma-0 ts-main-view-row fill-height">
		<!-- Cột bên trái: Timeline 5 giai đoạn -->
		<v-col cols="12" md="3" class="pa-1 fill-height">
			<v-card class="pa-2 border rounded-xs d-flex flex-column main-view-card fill-height" flat>
				<h4 class="text-subtitle-1 font-weight-bold mb-3 primary--text d-flex align-center flex-shrink-0">
					<v-icon class="mr-2" color="primary">mdi-format-list-bulleted-triangle</v-icon>
					Lộ Trình Đào Tạo Tiến Sĩ
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
		<v-col cols="12" md="9" class="pa-1 fill-height">
			<v-card class="pa-3 border rounded-xs d-flex flex-column main-view-inner-card fill-height" flat>
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
					<!-- GIAI ĐOẠN PHÂN NHÓM (Có tab song song nếu dữ liệu có SubGroup) -->
					<div v-if="subGroupList.length > 0">
						<v-tabs v-model="activeTab" background-color="transparent" color="primary"
							class="mb-4 text-none" grow>
							<v-tab v-for="(sub, idx) in subGroupList" :key="'tab-' + idx"
								class="text-none font-weight-bold">
								<v-icon left>mdi-book-open-outline</v-icon>{{ sub.title }}
								<v-icon right x-small :color="getChuyenDeStatusColor(sub.items)">
									{{ getChuyenDeStatusIcon(sub.items) }}
								</v-icon>
							</v-tab>
						</v-tabs>

						<v-window v-model="activeTab">
							<v-window-item v-for="(sub, idx) in subGroupList" :key="'window-item-' + idx">
								<div class="pa-1">
									<div v-for="(itemDes, idxItem) in sub.items" :key="'item-' + sub.id + '-' + idxItem"
										class="mb-4">
										<div class="d-flex align-center">
											<h4 class="text-body-2 font-weight-bold grey--text text--darken-3 mb-1">
												{{ sub.prefix }}.{{ idxItem + 1 }} {{ itemDes.Task_Detail_Description }}
											</h4>
											<div v-if="itemDes.Task_Detail_Type === 'CHECKBOX'" class="ml-3 d-flex align-center">
												<v-checkbox v-model="itemDes.Text_Content" color="success"
													:disabled="itemDes.User_Input === 'SDH' || activeStep.LOCK_STATUS === 0"
													hide-details class="ma-0 pa-0" />
												<v-chip x-small class="ml-2 font-weight-medium" :color="itemDes.Text_Content ? 'success' : 'grey lighten-2'" :dark="!!itemDes.Text_Content">
													{{ itemDes.Text_Content ? 'Đã xác nhận' : (itemDes.User_Input === 'SDH' ? 'Chưa xác nhận' : 'Chưa nộp') }}
												</v-chip>
												<span v-if="itemDes.Data_Exp" class="ml-2 text-caption grey--text text--darken-1">{{ itemDes.Data_Exp }}</span>
											</div>
										</div>

										<!-- File upload & view -->
										<c-file-comp
											v-if="itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW'"
											:itemDes="itemDes"
											:lock="itemDes.User_Input === 'SDH' ? 0 : activeStep.LOCK_STATUS"
											:item="activeStep" :apiFile="apiFile" :urlReadFile="urlReadFile" />

										<!-- Điểm -->
										<c-score-comp v-else-if="itemDes.Task_Detail_Type === 'DIEM'"
											:itemDes="itemDes" />

										<!-- Text view (Thông tin tĩnh) -->
										<v-text-field v-else-if="itemDes.Task_Detail_Type === 'TEXTVIEW'"
											v-model="itemDes.Text_Content" outlined dense disabled
											background-color="grey lighten-4" class="mb-0" />

										<!-- Text Input -->
										<v-text-field v-else-if="itemDes.Task_Detail_Type === 'TEXT'"
											v-model="itemDes.Text_Content" outlined dense color="success"
											:disabled="itemDes.User_Input === 'SDH' || activeStep.LOCK_STATUS === 0" />
									</div>
								</div>
							</v-window-item>
						</v-window>
					</div>

					<!-- CÁC GIAI ĐOẠN KHÁC (Tuyến tính / Phẳng) -->
					<div v-else>
						<div v-if="dataDetailFlow && dataDetailFlow.length > 0">
							<div v-for="(itemDes, indexDes) in dataDetailFlow" :key="indexDes" class="mb-4">
								<div class="d-flex align-center">
									<h4 class="text-body-2 font-weight-bold grey--text text--darken-3 mb-1">
										{{ activeStepIndex + 1 }}.{{ indexDes + 1 }} {{ itemDes.Task_Detail_Description }}
									</h4>
									<div v-if="itemDes.Task_Detail_Type === 'CHECKBOX'" class="ml-3 d-flex align-center">
										<v-checkbox v-model="itemDes.Text_Content" color="success"
											:disabled="itemDes.User_Input === 'SDH' || activeStep.LOCK_STATUS === 0"
											hide-details class="ma-0 pa-0" />
										<v-chip x-small class="ml-2 font-weight-medium" :color="itemDes.Text_Content ? 'success' : 'grey lighten-2'" :dark="!!itemDes.Text_Content">
											{{ itemDes.Text_Content ? 'Đã xác nhận' : (itemDes.User_Input === 'SDH' ? 'Chưa xác nhận' : 'Chưa nộp') }}
										</v-chip>
										<span v-if="itemDes.Data_Exp" class="ml-2 text-caption grey--text text--darken-1">{{ itemDes.Data_Exp }}</span>
									</div>
								</div>

								<!-- File upload & view -->
								<c-file-comp
									v-if="itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW'"
									:itemDes="itemDes" :lock="itemDes.User_Input === 'SDH' ? 0 : activeStep.LOCK_STATUS"
									:item="activeStep" :apiFile="apiFile" :urlReadFile="urlReadFile" />

								<!-- Text view (Thông tin tĩnh) -->
								<v-text-field v-else-if="itemDes.Task_Detail_Type === 'TEXTVIEW'"
									v-model="itemDes.Text_Content" outlined dense disabled
									background-color="grey lighten-4" class="mb-0" />

								<!-- Text Input -->
								<v-text-field v-else-if="itemDes.Task_Detail_Type === 'TEXT'"
									v-model="itemDes.Text_Content" outlined dense color="success"
									:disabled="itemDes.User_Input === 'SDH' || activeStep.LOCK_STATUS === 0" />

								<!-- Textarea -->
								<c-textarea-comp v-else-if="itemDes.Task_Detail_Type === 'TEXTAREA'" :itemDes="itemDes"
									:lock="itemDes.User_Input === 'SDH' ? 0 : activeStep.LOCK_STATUS" />
							</div>
						</div>

						<c-empty-state v-else text="Không tìm thấy trường thông tin" icon="mdi-database-off-outline" />
					</div>
				</div>

				<!-- Nút Lưu thay đổi -->
				<div class="d-flex justify-end mt-4 pt-3 border-top flex-shrink-0"
					v-if="activeStep.LOCK_STATUS === 1 && activeStep.Flow_Status !== 'C' && hasHvInput">
					<v-btn color="success" class="text-none font-weight-bold" @click="saveChanges()">
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
		urlReadFile: { type: String, default: '' },
		subGroupMap: { type: Object, default: () => ({}) }
	},
	data() {
		return {
			activeStepIndex: 0,
			activeTab: 0,
			dataDetailFlow: [],
			initialDetailFlow: null,
			isMounted: false
		}
	},
	mounted() {
		window.addEventListener('beforeunload', this.cleanupUnsavedFiles);
		this.isMounted = true;
		this.loadStepDetails(this.activeStepIndex);
	},
	beforeDestroy() {
		window.removeEventListener('beforeunload', this.cleanupUnsavedFiles);
		this.cleanupUnsavedFiles();
	},
	computed: {
		activeStep() {
			if (this.rootflow && this.rootflow.length > this.activeStepIndex) {
				return this.rootflow[this.activeStepIndex];
			}
			return {};
		},
		subGroupList() {
			const list = this.dataDetailFlow;
			if (!Array.isArray(list)) return [];

			// 1. Nhóm các task động duy nhất theo trường SubGroup
			const groupMap = {};
			list.forEach(item => {
				const groupKey = item.SubGroup;
				if (groupKey) {
					if (!groupMap[groupKey]) {
						groupMap[groupKey] = [];
					}
					groupMap[groupKey].push(item);
				}
			});

			// 2. Sắp xếp các nhóm động theo chữ cái và số thứ tự
			const sortedKeys = Object.keys(groupMap).sort((a, b) => {
				const prefixA = a.replace(/\d+/g, '').toUpperCase();
				const prefixB = b.replace(/\d+/g, '').toUpperCase();
				if (prefixA !== prefixB) return prefixA.localeCompare(prefixB);
				const numA = parseInt(a.replace(/\D/g, '')) || 0;
				const numB = parseInt(b.replace(/\D/g, '')) || 0;
				return numA - numB;
			});

			const subGroupPrefixMap = {
				'CD': 'Chuyên đề',
				'TL': 'Tiểu luận',
				'BB': 'Bài báo',
				'BC': 'Báo cáo',
				...this.subGroupMap
			};

			return sortedKeys.map(key => {
				const prefix = key.replace(/\d+/g, '');
				const num = parseInt(key.replace(/\D/g, '')) || '';
				
				let name = subGroupPrefixMap[prefix.toUpperCase()];
				if (!name) {
					name = prefix.charAt(0).toUpperCase() + prefix.slice(1);
				}
				const title = num ? `${name} ${num}` : name;

				return {
					id: num || key,
					title: title,
					prefix: num ? `${this.activeStepIndex + 1}.${num}` : `${this.activeStepIndex + 1}`,
					items: groupMap[key]
				};
			});
		},
		hasHvInput() {
			return this.dataDetailFlow && this.dataDetailFlow.some(item => item.User_Input === 'HV');
		}
	},
	watch: {
		rootflow: {
			immediate: true,
			handler(val) {
				if (val && val.length > 0) {
					let defaultIdx = val.findIndex((item) => item.LOCK_STATUS === 1);
					if (defaultIdx === -1) {
						for (let i = val.length - 1; i >= 0; i--) {
							if (val[i].Flow_Status !== 'W') {
								defaultIdx = i;
								break;
							}
						}
					}
					const oldIdx = this.activeStepIndex;
					this.activeStepIndex = defaultIdx >= 0 ? defaultIdx : 0;
					if (this.isMounted && oldIdx === this.activeStepIndex) {
						this.loadStepDetails(this.activeStepIndex);
					}
				}
			}
		},
		activeStepIndex(idx) {
			this.loadStepDetails(idx);
		}
	},
	methods: {
		async cleanupUnsavedFiles() {
			if (window.unsavedUploadedFiles && window.unsavedUploadedFiles.length > 0) {
				const fileids = window.unsavedUploadedFiles.join(",");
				try {
					await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: fileids });
				} catch (e) {
					console.error("Lỗi xóa nhiều file rác (TS):", e);
				}
				window.unsavedUploadedFiles = [];
			}
		},
		async selectStep(index) {
			await this.cleanupUnsavedFiles();
			this.activeStepIndex = index;
		},
		async loadStepDetails(idx) {
			if (!this.rootflow || !this.rootflow[idx]) return;
			const step = this.rootflow[idx];
			try {
				await this.cleanupUnsavedFiles();
				const res = await ajaxCALLPromise('/Get_FlowDetail', { Flow_ID: step.Flow_ID });
				const rawData = res || [];
				
				this.dataDetailFlow = rawData.map((item) => {
					const isCheckbox = item.Task_Detail_Type === 'CHECKBOX';
					const checkboxVal = isCheckbox ? (item.Text_Content === true || String(item.Text_Content).toLowerCase() === 'true') : false;
					return {
						File_ID: null,
						File_Name: null,
						File_Type: null,
						File_URL: null,
						FILE_UPLOAD: null,
						...item,
						Text_Content: item.FieldName === 'QDThanhLapHoiDong_ThoiGian' && item.Text_Content
							? moment(item.Text_Content).format('DD/MM/YYYY')
							: item.Task_Detail_Type === 'DIEM'
								? item.Text_Content ? parseFloat(item.Text_Content).toFixed(2) : null
								: isCheckbox
									? checkboxVal
									: item.Text_Content,
					}
				});
				this.initialDetailFlow = JSON.parse(JSON.stringify(this.dataDetailFlow));
			} catch (error) {
				if (typeof Vue !== 'undefined' && Vue.$toast) {
					Vue.$toast.error(`Lỗi tải chi tiết: ${error}`, { position: 'top' });
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
		getStatusLabel(status, lock) {
			if (lock === 0) {
				switch (status) {
					case 'W': return 'Bị khóa';
					case 'C': return 'Đã hoàn thành';
					case 'P': return 'Đang xử lý';
					default: return 'Đang khóa';
				}
			} else {
				switch (status) {
					case 'W': return 'Chờ thực hiện';
					case 'P': return 'Đang mở';
					default: return 'Đang mở';
				}
			}
		},
		getStatusChipClass(status, lock) {
			if (lock === 0) {
				switch (status) {
					case 'C': return 'success--text green lighten-5';
					case 'P': return 'info--text blue lighten-5';
					default: return 'grey--text text--darken-1 grey lighten-4';
				}
			} else {
				switch (status) {
					case 'P': return 'info--text blue lighten-5 border-info';
					default: return 'amber--text text--darken-3 yellow lighten-5';
				}
			}
		},
		getChuyenDeStatusColor(chuyenDeItems) {
			if (!chuyenDeItems || !Array.isArray(chuyenDeItems)) return 'grey';
			const hasDiem = chuyenDeItems.some(i => i.FieldName && i.FieldName.startsWith('Diem') && i.Text_Content);
			const hasFile = chuyenDeItems.some(i => i.FieldName && i.FieldName.startsWith('Cuon') && i.File_ID);
			if (hasDiem) return 'success';
			if (hasFile) return 'info';
			return 'grey';
		},
		getChuyenDeStatusIcon(chuyenDeItems) {
			if (!chuyenDeItems || !Array.isArray(chuyenDeItems)) return 'mdi-circle-medium';
			const hasDiem = chuyenDeItems.some(i => i.FieldName && i.FieldName.startsWith('Diem') && i.Text_Content);
			const hasFile = chuyenDeItems.some(i => i.FieldName && i.FieldName.startsWith('Cuon') && i.File_ID);
			if (hasDiem) return 'mdi-check-circle-outline';
			if (hasFile) return 'mdi-clock-outline';
			return 'mdi-circle-medium';
		},
		async saveChanges() {
			const root = this.activeStep;
			try {
				// Lọc các trường thông tin thực sự cần lưu (do học viên nhập và có thay đổi)
				const itemsToSave = this.dataDetailFlow.filter(item => {
					// Chỉ xử lý khi User_Input là HV
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
						Text_Content: typeof item.Text_Content === 'string' && item.Text_Content ? item.Text_Content.trim() : (item.Task_Detail_Type === 'CHECKBOX' ? String(!!item.Text_Content) : item.Text_Content),
						File_Name: (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') ? (item.File_Name ?? null) : null,
						File_Type: (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') ? (item.File_Type ?? null) : null,
						File_URL: (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') ? (item.File_URL ?? null) : null,
						File_ID: (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') ? (item.File_ID ?? null) : null,
					});
				});

				await Promise.all(promises);

				// Xóa file cũ đã bị thay thế trên server sau khi lưu thành công
				const oldFileIds = [];
				for (let i = 0; i < itemsToSave.length; i++) {
					const currentItem = itemsToSave[i];
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
				if (typeof Vue !== 'undefined' && Vue.$toast) {
					Vue.$toast.success(`Cập nhật ${root.TASK_NAME} thành công`, { position: 'top' });
				}
				this.$emit('on-reload');
				this.initialDetailFlow = JSON.parse(JSON.stringify(this.dataDetailFlow));
			} catch (error) {
				if (typeof Vue !== 'undefined' && Vue.$toast) {
					Vue.$toast.error(`Cập nhật ${root.TASK_NAME} thất bại`, { position: 'top' });
				}
			}
		}
	}
	}
</script>