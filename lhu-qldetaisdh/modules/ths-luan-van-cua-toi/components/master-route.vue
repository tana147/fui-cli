<template>
	<v-container>
		<v-expansion-panels v-if="DetailInfo" v-model="detailInfoPanel" accordion class="student-info-panels mb-5">
			<v-expansion-panel>
				<v-expansion-panel-header class="student-info-collapse-header" disable-icon-rotate>
					<div>
						<h3 class="student-info-card__title">Thông tin học viên</h3>
						<!-- <p class="student-info-card__subtitle">Dữ liệu chỉ để xem, không chỉnh sửa</p> -->
					</div>

					<template v-slot:actions>
						<v-icon color="#1d5b7a">{{ detailInfoPanel === 0 ? 'mdi-chevron-up-circle' :
							'mdi-chevron-down-circle' }}</v-icon>
					</template>
				</v-expansion-panel-header>

				<v-expansion-panel-content>
					<v-card class="student-info-card" outlined>
						<v-row dense class="px-3 pb-3 pt-1">
							<v-col v-for="field in detailInfoSchema" :key="field.key" cols="12" sm="6" md="4">
								<div class="student-info-label">{{ field.label }}</div>

								<div v-if="field.type === 'yesNo'" class="student-info-chip-wrap">
									<v-chip small label :class="getYesNoChipClass(DetailInfo[field.key])">
										{{ getDetailInfoValue(field) }}
									</v-chip>
								</div>

								<div v-else class="student-info-text">
									{{ getDetailInfoValue(field) }}
								</div>
							</v-col>
						</v-row>
					</v-card>
				</v-expansion-panel-content>
			</v-expansion-panel>
		</v-expansion-panels>

		<v-expansion-panels v-model="vueData.Panel" accordion class="workflow-panels">
			<v-expansion-panel v-for="(item, index) in rootflow" :key="index">
				<v-expansion-panel-header :step="index + 1"
					@click="onLoadDetailFlow(item.Flow_ID, item.LOCK_STATUS, item)"
					:class="getStepColor(item.Flow_Status, item.LOCK_STATUS)"
					:style="item.LOCK_STATUS ? { height: '48px' } : null" disable-icon-rotate>
					<div class="stepperStep mt-1">
						<h4>{{ index + 1 }}./ {{ item.TASK_NAME }}</h4>
					</div>
					<template v-slot:actions>
						<v-icon color="white">{{ getStepIcon(item.Flow_Status, item.LOCK_STATUS) }}</v-icon>
					</template>
				</v-expansion-panel-header>
				<v-expansion-panel-content class="workflow-panel-content" :step="index + 1"
					:style="dataDetailFlow && dataDetailFlow.length > 0 ? getStyleStatusLock(item.LOCK_STATUS) : null">
					<div>
						<v-alert type="error" dense outlined class="mb-3" v-if="item.Flow_Status === 'R' && isStep5(item)">
							<div class="d-flex align-center justify-space-between">
								<div>
									<b>Hồ sơ chưa đạt yêu cầu kiểm tra đạo văn và bị từ chối.</b>
									<div class="mt-1" v-if="latestRejectionReason">Lý do: <i>{{ latestRejectionReason }}</i></div>
								</div>
								<v-btn small color="error" outlined @click="openHistoryModal(item.Flow_ID)" class="ml-2">
									<v-icon left small>mdi-history</v-icon>
									Lịch sử nộp
								</v-btn>
							</div>
						</v-alert>
						<div v-if="dataDetailFlow.length > 0">
							<div v-for="(itemDes, indexDes) in dataDetailFlow" :key="indexDes">
								<div class="d-flex align-center flow-detail-header">
									<span class="d-flex align-center flow-detail-title-wrap">
										<h4 v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV'" v-show="shouldShowDuocOnlyField(itemDes)">
											{{ index + 1 }}.{{ indexDes + 1 }}
											{{ itemDes.Task_Detail_Description }}</h4>
										<div v-if="itemDes.Task_Detail_Type === 'CHECKBOX'" class="ml-6">
											<div class="checkbox-inline-wrap">
												<v-checkbox class="checkboxMod" large color="success"
													v-model="itemDes.Text_Content" :disabled="item.LOCK_STATUS === 0" />
												<span v-if="itemDes.Data_Exp" class="checkbox-inline-hint">{{
													itemDes.Data_Exp }}</span>
											</div>
										</div>
									</span>
									<div v-if="itemDes.Data_Exp !== null && itemDes.Task_Detail_Type === 'FILE'"
										class="ml-auto flow-detail-download">
										<!-- itemDes.Data_Exp -->
										<a class="flow-detail-download-link" :href="parseDataExp(itemDes.Data_Exp)"
											download="file mẫu">
											<v-btn class="flow-detail-download-btn" color="success" text>
												<v-icon small>mdi-download-circle</v-icon>
												File mẫu
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
                                    " border="right" colored-border type="error" elevation="2" dense>
									{{ itemDes.InHoaError }}
								</v-alert>

								<i class="red--text mt-0"
									v-if="(itemDes.FieldName === 'tenTapChiHoiThao' || itemDes.FieldName === 'namXuatBan' || itemDes.FieldName === 'viTriTacGia') && checkHide()"><b>Lưu
										ý:</b> Phải nhập thông tin <b>Tên tạp chí / hội thảo</b>, <b>Năm xuất bản</b> và <b>Vị trí tác giả</b> khi có
									bài báo khoa học</i>

								<!-- <text-comp :itemdes="itemDes" :textRules="textRules"></text-comp> -->
								<v-text-field outlined dense color="success" v-model="itemDes.Text_Content"
									:hint="itemDes.Data_Exp"
									:type="itemDes.Task_Detail_StyleDisplay === 'phone' ? 'number' : itemDes.Task_Detail_StyleDisplay === 'email' ? 'email' : 'text'"
									v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && (itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW')"
									v-show="shouldShowDuocOnlyField(itemDes)"
									:disabled="itemDes.User_Input === 'SDH' || itemDes.Task_Detail_Type === 'TEXTVIEW' || item.LOCK_STATUS === 0">
											<template #message="{ message }">
												<span style="color: red;">{{ message }}</span>
											</template>
								</v-text-field>

								<v-text-field
									v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Display === 1 && (itemDes.Task_Detail_Type === 'NUMBER' || itemDes.Task_Detail_Type === 'NUMBERVIEW')"
									class="text-right-input" placeholder="Nhập số" v-model="itemDes.Text_Content"
									type="number" min="0" step="0.01" inputmode="decimal" @keydown="preventNegative"
									dense outlined color="success"
									:disabled="itemDes.User_Input === 'SDH' || itemDes.Task_Detail_Type === 'TEXTVIEW' || item.LOCK_STATUS === 0" >
									<template #message="{ message }">
										<span style="color: red;">{{ message }}</span>
									</template>
								</v-text-field>

								<div class="dateWrap"
									v-if="itemDes.Task_Detail_Type === 'DATE' || itemDes.Task_Detail_Type === 'DATEVIEW'">
									<f-date v-model="itemDes.Text_Content" :disabled="item.LOCK_STATUS === 0" />
								</div>

								<v-autocomplete
									v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Type === 'SELECT' && itemDes.FieldName === 'VanBangChungChiDauRa'"
									v-model="itemDes.Text_Content" :items="DsNNDauRa" item-text="text"
									item-value="value" outlined dense hide-details
									:disabled="itemDes.User_Input === 'SDH' || itemDes.Task_Detail_Type === 'TEXTVIEW' || item.LOCK_STATUS === 0">
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
									v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Type === 'SELECT' && itemDes.FieldName === 'TenNgoaiNguDauRa'"
									v-model="itemDes.Text_Content" :items="DsTenNgoaiNgu" item-text="text"
									item-value="value" outlined dense hide-details
									:disabled="itemDes.User_Input === 'SDH' || itemDes.Task_Detail_Type === 'TEXTVIEW' || item.LOCK_STATUS === 0" />

								<file-comp class="workflow-file-comp" :lock="item.LOCK_STATUS" :itemdes="itemDes"
									:item="item" :textRules="textRules" :filerule="fileRules"
									v-show="shouldShowDuocOnlyField(itemDes)"
									v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && (itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW')" />
								<textarea-comp :itemdes="itemDes" :textRules="textRules"
									v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Type === 'TEXTAREA'" :lock="item.LOCK_STATUS" />
								<score-comp
									v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.Task_Detail_Type === 'DIEM' || itemDes.Task_Detail_Type === 'FORMULAR'"
									:itemdes="itemDes" />

								<!-- Kiểm tra trùng tên đề tài đã đăng ký -->
								<div v-if="itemDes.Task_Detail_StyleDisplay !== 'hideFromHV' && itemDes.FN_Check === 'fnCheckDeTaiDaDangKy'">
									<div class="d-flex align-center justify-center flow-textarea-wrap"
										style="gap: 15px">
										<v-textarea v-model="itemDes.Text_Content" class="mt-2" outlined
											name="input-7-1" rows="1" color="green" flat="false" auto-grow dense
											:hint="itemDes.Task_Help" disabled />
									</div>
								</div>

								<!-- Kiem tra trung lap -->
								<div
									v-if="itemDes.Task_Detail_Type === 'TEXTAREA | FUN' && itemDes.FN_Check === 'fnCheckTenDeTai'">
									<div class="d-flex align-center justify-center flex-column flex-sm-row mb-3 topic-check-wrap"
										style="gap: 15px">
										<div class="flex-grow-1 w-100">
											<textarea-button-comp :itemdes="itemDes" :textRules="textRules"
												:lock="item.LOCK_STATUS" />
										</div>

										<div>
											<v-btn color="warning" @click="checkTopicBtn(itemDes.Text_Content)"
												:disabled="item.LOCK_STATUS === 0"> Kiểm tra đề tài trùng </v-btn>
										</div>
									</div>

									<!-- kiem tra func -->
									<div
										v-if="itemDes.FN_Check === 'fnCheckTenDeTai' && itemDes.Text_Content !== null && itemDes.Text_Content !== '' && item.Flow_Status !== 'C'">
										<similiar-topic-list class="mb-5" :itemdes="itemDes"
											v-if="itemDes.FN_Check === 'fnCheckTenDeTai'" />
									</div>
								</div>

								<div v-if="itemDes.Task_Detail_Type === 'FUN'">
									<div v-if="itemDes.FN_Check === 'fnCheckHocPhi(StudentID)'">
										<div class="mb-3 mt-2">
											<div>
												<div v-if="itemDes.TinhTrangNoHocPhi == 0"
													class="d-flex justify-center align-center">
													<h4 class="success--text">
														<v-icon class="mb-1" color="success">mdi-check-bold</v-icon>
														Không nợ học phí
													</h4>
												</div>
												<div v-else>
													<span class="primary--text"><b>Tình trạng nợ học phí:</b></span>
													<span
														:class="{ 'success--text': feeArr == '0', 'red--text': feeArr != '0' }">
														<b>{{ itemDes.TinhTrangNoHocPhi }} VNĐ</b>
													</span>
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>

							<div class="d-flex justify-end mt-3"
								v-if="item.LOCK_STATUS !== 0 && item.Flow_Status !== 'C' && !checkSDH">
								<v-btn color="success" @click="onSave(item.Flow_ID, item)" class="mb-3">Lưu</v-btn>
							</div>
						</div>

						<div v-else>
							<p>Dữ liệu không tồn tại</p>
						</div>
					</div>
				</v-expansion-panel-content>
			</v-expansion-panel>
		</v-expansion-panels>

		<!-- Dialog Lịch sử nộp bài dành cho học viên -->
		<v-dialog v-model="historyModal" max-width="750">
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
					<div v-else-if="studentHistoryVersions.length === 0" class="text-center py-6 grey--text">
						Chưa có dữ liệu lịch sử các lần từ chối trước đó.
					</div>
					<div v-else>
						<v-card v-for="(ver, idx) in studentHistoryVersions" :key="idx" outlined class="mb-3 pa-3">
							<div class="d-flex justify-space-between align-center mb-1">
								<span class="font-weight-bold red--text">
									Phiên nộp #{{ studentHistoryVersions.length - idx }}
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
								<a :href="vueData.v_Set.urlReadFile + fItem.File_URL" target="_blank" class="ml-1 text-decoration-none blue--text">
									{{ fItem.File_Name }}
								</a>
							</div>
						</v-card>
					</div>
				</v-card-text>
				<v-card-actions class="pb-3 px-4">
					<v-spacer />
					<v-btn color="primary" text @click="historyModal = false">Đóng</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-container>
</template>

<script>
	export default {
		props: ['rootflow'],
	    data() {
	        return {
	            e6: 0,
	            isDialog: false,
	            dataDetailFlow: [],
	            activeStep: 0,
	            feeArr: [],
	            DsNNDauRa: [],
	            DsTenNgoaiNgu: [],
	            DsDiemHocPhan: [],
	            student_id: null,
	            checkSDH: null,
	            latestRejectionReason: '',
	            historyModal: false,
	            historyLoading: false,
	            historyList: [],
	            checkDeTaiFlag: null,
	            resultKtraDeTai: null,
	            bangDiemLabel: 'Danh sách môn học',
	            DetailInfo: null,
	            detailInfoPanel: null,
	            detailInfoSchema: [
	                { key: 'Email', label: 'Email' },
	                { key: 'NoiSinh', label: 'Nơi sinh' },
	                { key: 'SoDienThoai', label: 'Số điện thoại' },
	                { key: 'DanToc', label: 'Dân tộc' },
	                { key: 'QuocTich', label: 'Quốc tịch' },
	                { key: 'CCCD', label: 'CCCD' },
	                { key: 'NgayCap_CCCD', label: 'Ngày cấp CCCD', type: 'date' },
	                { key: 'Truong_DaiHoc', label: 'Trường đại học' },
	                { key: 'Nganh_DaiHoc', label: 'Ngành đại học' },
	                { key: 'XepLoai', label: 'Xếp loại' },
	                { key: 'NgoaiNgu_DauVao', label: 'Ngoại ngữ đầu vào' },
	                { key: 'BoSungKienThuc', label: 'Bổ sung kiến thức', type: 'yesNo' },
	                { key: 'CongBoKhoaHoc', label: 'Công bố khoa học', type: 'yesNo' },
	            ],
	
	            fileRules: {
	                max_file_size: '100mb',
	                mime_types: [
	                    {
	                        title: 'All files',
	                        extensions: 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg',
	                    },
	                ],
	            },
	
	            textRules: [(v) => !!v || 'Không được để trống'],
	            headers: [
	                {
	                    text: 'Tên đề tài',
	                    value: 'ThesisName',
	                },
	                {
	                    text: 'Khoa',
	                    value: 'ThesisMajor',
	                },
	                {
	                    text: 'Tác giả',
	                    value: 'ThesisStudent',
	                },
	            ],
	
	            tableBangDiemHeader: [
	                {
	                    text: 'STT',
	                    value: 'STT',
	                    class: 'renderCol',
	                    sortable: false,
	                    align: 'center',
	                    width: 50,
	                },
	                {
	                    text: 'Mã môn học',
	                    value: 'MonHocID',
	                    sortable: false,
	                    align: 'center',
	                },
	                {
	                    text: 'Tên môn học',
	                    value: 'TenMH',
	                    sortable: false,
	                },
	                {
	                    text: 'Hệ số',
	                    value: 'HeSo',
	                    sortable: false,
	                    align: 'center',
	                },
	                {
	                    text: 'Điểm thành phần',
	                    value: 'DiemThanhPhanList',
	                    sortable: false,
	                    align: 'center',
	                },
	                {
	                    text: 'Điểm trung bình',
	                    value: 'DiemTBMon',
	                    sortable: false,
	                    align: 'center',
	                },
	            ],
	        }
	    },
	    mounted() {
	        this.DsNNDauRa = ChungChiNgoaiNgu_NameList()
	        this.DsTenNgoaiNgu = NgoaiNgu_NameList()
	    },
	    created() { },
	    computed: {
	        PanelControl: function () {
	            return vueData.Panel
	        },
			studentHistoryVersions() {
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
	        rootflow: function (val) {
	            if (val.length > 0) {
	                this.student_id = val[0].STUDENT_ID
	                this.onLoadDetailFlow(vueData.DefaultFLow?.Flow_ID, vueData.DefaultFLow?.LOCK_STATUS, vueData.DefaultFLow)
	                vueData.Panel = val?.findIndex((item) => item.LOCK_STATUS === 1)
	                this.onLoadInfo()
	            }
	        },
	        dataDetailFlow: function (val) {
	            console.log('watch... xxxxx', val)
	            console.log('AHVCBNGD', vueData.StudentProcess)
	            const studentId = (vueData && vueData.StudentProcess && vueData.StudentProcess.length > 0) ? vueData.StudentProcess[0].Student_ID : null
	
	            const findDiemHocPhan = val.find((item) => item.FieldName === 'DiemHocPhan')
	            // if (findDiemHocPhan) {
	            //     this.onLoadDiemThanhPhan(studentId)
	            //         .then((data) => {
	            //             this.DsDiemHocPhan = data
	            //             console.log('DsDiemHocPhan', this.DsDiemHocPhan)
	            //         })
	            //         .catch((err) => {
	            //             console.log('Loi', err)
	            //         })
	            // }
	
	            this.updateFileRules(val)
	            let check = val.find((item) => item.FN_Check === 'fnCheckHocPhi(StudentID)')
	            this.checkSDHRole()
	
	            const findDeTaiDKy = val.find((item) => item.FN_Check === 'fnCheckDeTaiDaDangKy')
	            if (findDeTaiDKy) {
	                console.log('finded', findDeTaiDKy)
	
	                // Nếu tìm thấy trường FN_Check === 'fnCheckDeTaiDaDangKy', thì theo dõi sự thay đổi trong Text_Content của itemDes
	                this.$watch(
	                    function () {
	                        return findDeTaiDKy.Text_Content
	                    },
	                    function (newVal, oldVal) {
	                        // Thực hiện các hành động cần thiết khi dữ liệu nhập liệu thay đổi
	                        this.checkDeTaiFlag = null
	                        this.resultKtraDeTai = null
	                    },
	                )
	            }
	        },
	        PanelControl: function (val) {
	            this.checkDeTaiFlag = null
	            this.resultKtraDeTai = null
	        },
	    },
	    methods: {
	        preventNegative(e) {
	            // Chặn các ký tự '-', 'e', '+' và số âm
	            if (e.key === '-' || e.key === 'e' || e.key === '+') {
	                e.preventDefault()
	            }
	        },
	
	        checkHide() {
	            if (!this.dataDetailFlow || !this.dataDetailFlow.length) return false
	            const fileItem = this.dataDetailFlow.find((item) => item.FieldName === 'fileBaiBaoKhoaHoc')
	            const nameItem = this.dataDetailFlow.find((item) => item.FieldName === 'tenBaiBao')
	            const hasFile = Boolean(fileItem && (fileItem.File_ID || fileItem.File_URL))
	            const hasName = Boolean(nameItem && typeof nameItem.Text_Content === 'string' && nameItem.Text_Content.trim() !== '')
	            return hasFile && hasName
	        },
	
	        onLoadInfo() {
	            ajaxCALL('/StudentInfo_GetById', { Student_ID: this.student_id }, (res) => {
	                if (res.data.length > 0) {
	                    this.DetailInfo = res.data[0]
	                    // Nếu là Nghiên cứu sinh (Tiến sĩ), tự động chuyển sang trang Luận án Tiến sĩ
	                    if (this.DetailInfo?.HeDaoTao === 'Phd') {
	                        window.location.href = '/ts-luan-an-cua-toi'
	                        return
	                    }
	                }
	                console.log('DetailInfo', this.DetailInfo)
	            })
	        },
	
	        getDetailInfoValue(field) {
	            const rawValue = this.DetailInfo ? this.DetailInfo[field.key] : null
	
	            if (field.type === 'date') {
	                return this.formatDisplayDate(rawValue)
	            }
	
	            if (field.type === 'yesNo') {
	                return this.formatYesNoValue(rawValue)
	            }
	
	            if (rawValue === null || rawValue === undefined || rawValue === '') {
	                return '-'
	            }
	
	            return rawValue
	        },
	
	        formatDisplayDate(value) {
	            if (!value) {
	                return '-'
	            }
	
	            const m = moment(value)
	            return m.isValid() ? m.format('DD/MM/YYYY') : value
	        },
	
	        formatYesNoValue(value) {
	            if (value === null || value === undefined || value === '') {
	                return 'Chưa cập nhật'
	            }
	
	            const normalizedValue = String(value).trim().toLowerCase()
	            if (normalizedValue === 'có' || normalizedValue === 'co') {
	                return 'Có'
	            }
	            if (normalizedValue === 'không' || normalizedValue === 'khong') {
	                return 'Không'
	            }
	
	            return String(value)
	        },
	
	        getYesNoChipClass(value) {
	            const normalizedValue = this.formatYesNoValue(value)
	
	            if (normalizedValue === 'Có') {
	                return 'student-info-chip student-info-chip--yes'
	            }
	            if (normalizedValue === 'Không') {
	                return 'student-info-chip student-info-chip--no'
	            }
	
	            return 'student-info-chip student-info-chip--empty'
	        },
	
	        shouldShowDuocOnlyField(itemDes) {
	            if (!itemDes || itemDes.FN_Check !== 'DuocOnly') {
	                return true
	            }
	            const studentProcess = typeof vueData !== 'undefined' && vueData ? vueData.StudentProcess : null
	            const nganhId = Array.isArray(studentProcess) && studentProcess.length > 0 ? studentProcess[0].NganhID : null
	            return nganhId != null && String(nganhId) === '106'
	        },
	
	        onLoadDiemThanhPhan(studentID) {
	            return new Promise(function (resolve, reject) {
	                $.ajax({
	                    type: 'GET',
	                    headers: {
	                        authorization: $awt,
	                    },
	                    url: `https://tapi.lhu.edu.vn/mark/MarkViewer_GetBangDiem?studentId=${studentID}`,
	                    contentType: 'application/json; charset=utf-8',
	                    dataType: 'json',
	                    crossDomain: true,
	                    success: function (res) {
	                        const data = res.data.map((item, index) => {
	                            return {
	                                ...item,
	                                STT: index + 1,
	                                DiemThanhPhanList: JSON.parse(item.DiemThanhPhan),
	                            }
	                        })
	                        resolve(data)
	                    },
	                    error: function (xhr, ajaxOptions, thrownError) {
	                        reject(xhr.responseJSON.Message)
	                        $.dialog({
	                            icon: 'fas fa-exclamation',
	                            title: 'Error',
	                            content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
	                            type: 'red',
	                            columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
	                            closeIcon: true,
	                            buttons: {
	                                ok: {
	                                    text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
	                                    btnClass: 'btn-blue',
	                                },
	                            },
	                        })
	                    },
	                    complete: function () { },
	                })
	            })
	        },
	
	        validateText(str) {
	            if (str === null || str === undefined || str === '' || typeof str !== 'string') {
	                return false
	            }
	            // Regex kiểm tra ký tự đầu tiên
	            const lowercaseRegex = /^[a-zàáâãèéêìíòóôõùúăđĩũơỳỷỹýỵ]$/
	            console.log('str', str)
	            // Chữ cái đầu tiên viết thường
	            if (lowercaseRegex.test(str.charAt(0))) {
	                return 0
	            }
	            let totalLatinChars = 0
	            let upperCaseCount = 0
	
	            // Loại bỏ hoặc mở rộng regex
	            const vietnameseRegex = /[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂƠÊÒÓÔĐêềệễẵặạảấầẩẫậếềểễệỳỷỹỳýỳỵ]/
	
	            for (let i = 0; i < str.length; i++) {
	                const char = str.charAt(i)
	                const charCode = str.charCodeAt(i)
	
	                // Chỉ đếm các ký tự Latin hoặc tiếng Việt
	                if (vietnameseRegex.test(char)) {
	                    totalLatinChars++
	
	                    // Kiểm tra in hoa
	                    if ((charCode >= 65 && charCode <= 90) || (char >= 'À' && char <= 'Ỵ')) {
	                        upperCaseCount++
	                    }
	                }
	            }
	
	            const totalChars = totalLatinChars
	
	            // Phần còn lại của logic giữ nguyên
	            if (totalChars === 0) {
	                return false
	            }
	
	            const upperCaseRatio = upperCaseCount / totalChars
	
	            return upperCaseRatio > 0.9
	        },
	        parseDataExp(dataExp) {
	            try {
	                const jsonData = JSON.parse(dataExp)
	                if (this.ExistData?.NganhID == jsonData[0].NganhID) {
	                    return jsonData[0].File
	                } else {
	                    return jsonData[1].File
	                }
	            } catch (error) {
	                console.log('Không thể parse dataExp sang JSON, trả về dataExp ban đầu.', dataExp)
	                return dataExp
	            }
	        },
	
	        checkSDHRole() {
	            this.checkSDH = this.dataDetailFlow.every((item) => item.User_Input === 'SDH')
	            console.log('flag', this.checkSDH)
	        },
	
	        countWords(str) {
	            return str.trim().split(/\s+/).filter(Boolean).length
	        },
	
	        checkSpecialValid(text) {
	            if (!text) {
	                return { valid: true }
	            }
	
	            // 2. Bắt buộc phải có dấu tiếng Việt
	            const vietnameseAccentRegex = /[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐ]/i
	
	            if (!vietnameseAccentRegex.test(text)) {
	                return {
	                    valid: false,
	                    reason: 'NO_VIETNAMESE_ACCENT',
	                    message: 'Phải nhập tiếng Việt có dấu',
	                }
	            }
	
	            // 3. Không cho phép chữ cái đầu viết thường
	            const firstChar = text.charAt(0)
	            const lowercaseFirstCharRegex = /^[a-zàáâãèéêìíòóôõùúăđĩũơỳỷỹýỵ]/
	
	            if (lowercaseFirstCharRegex.test(firstChar)) {
	                return { valid: false, reason: 'FIRST_CHAR_LOWERCASE', message: 'Chữ cái đầu tiên phải viết hoa' }
	            }
	
	            // 4. Đếm chữ cái Latin / Việt & chữ in hoa
	            let totalLetters = 0
	            let uppercaseCount = 0
	
	            const letterRegex = /[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠƯàáâãèéêìíòóôõùúăđĩũơưỳýỵỷỹđ]/
	
	            for (let i = 0; i < text.length; i++) {
	                const char = text[i]
	
	                if (letterRegex.test(char)) {
	                    totalLetters++
	
	                    // A-Z hoặc À–Ỵ
	                    const code = char.charCodeAt(0)
	                    if ((code >= 65 && code <= 90) || (char >= 'À' && char <= 'Ỵ')) {
	                        uppercaseCount++
	                    }
	                }
	            }
	
	            // 5. Không cho phép viết hoa quá 90%
	            const uppercaseRatio = uppercaseCount / totalLetters
	            if (uppercaseRatio > 0.9) {
	                return { valid: false, reason: 'TOO_MUCH_UPPERCASE', message: 'Không được nhập toàn bộ in hoa' }
	            }
	
	            // 6. Hợp lệ
	            return { valid: true }
	        },
	
	        async onSave(FLOW_ID, root) {
	            let validationPassed = true
	            let hasInvalidText = false
				console.log("this.dataDetailFlow", this.dataDetailFlow)
	            const validateItem = (item) => {
	                // Kiểm tra các điều kiện khác
	                // AllowNull == 0 là không được bỏ trống
	                // Chỉ kiểm tra những bước nào dành cho học viên nhập
	                if (item.User_Input === 'HV') {
	                    const validationResult = this.validateText(item.Text_Content)
	
	                    if (item.UI_Component !== 'SkipCheckUpperCase' && validationResult && validationResult !== 0) {
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Không được nhập toàn bộ in hoa'
	                    } else if (item.UI_Component !== 'SkipCheckUpperCase' && validationResult === 0 && item.Task_Detail_StyleDisplay !== 'email') {
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Chữ cái đầu tiên phải viết hoa'
	                    } else if ((item.FieldName === 'SoCap_HDYSH' || item.FieldName === 'SoCap_HDYSH_ID') && item.Text_Content && item.Text_Content !== item.Text_Content.toUpperCase()) {
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Số hội đồng Y Đức phải viết hoa toàn bộ'
	                    } else {
	                        item.isInHoa = false
	                        item.InHoaError = ''
	                    }

	                    if (item.FieldName === 'ThesisesProfSuggest1' && item.Text_Content) {
	                        const specialCheck = this.checkSpecialValid(item.Text_Content)
	                        item.isInHoa = !specialCheck.valid
	                        item.InHoaError = specialCheck.message || ''

	                        if (!specialCheck.valid) {
	                            validationPassed = false
	                        }
	                    }

	                    const isHidden = item.Task_Detail_StyleDisplay === 'hideFromHV' || !this.shouldShowDuocOnlyField(item)

	                    // 1. Kiểm tra File bắt buộc (AllowNull == 0)
	                    if (String(item.AllowNull) === '0' && (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') && !isHidden) {
	                        const fileId = item.File_ID ? String(item.File_ID).trim() : ''
	                        const isFileEmpty = !fileId || fileId === 'null' || fileId === 'undefined'
	                        if (isFileEmpty) {
	                            Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa upload file`, { position: 'top' })
	                            validationPassed = false
	                        }
	                    }

	                    // Kiểm tra định dạng file hợp lệ nếu có upload file
	                    if ((item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') && !isHidden && item.File_Name && item.AllowFileType) {
	                        const fileName = item.File_Name || ''
	                        const ext = fileName.includes('.') ? fileName.split('.').pop().toLowerCase() : ''
	                        const allowed = typeof item.AllowFileType === 'string'
	                            ? item.AllowFileType.toLowerCase().replace(/\./g, '').split(/[|,]/).map((e) => e.trim()).filter(Boolean)
	                            : []
	                        if (ext && allowed.length > 0 && !allowed.includes(ext)) {
	                            Vue.$toast.error(`Task "${item.Task_Detail_Description}": File không đúng định dạng cho phép (${allowed.join(', ').toUpperCase()})`, { position: 'top' })
	                            validationPassed = false
	                        }
	                    }

	                    // 2. Kiểm tra Nội dung văn bản bắt buộc (AllowNull == 0)
	                    if (String(item.AllowNull) === '0' && !['FILE', 'FILEVIEW', 'FUN', 'CHECKBOX', 'TABLE'].includes(item.Task_Detail_Type) && !isHidden) {
	                        const val = item.Text_Content
	                        const isTextEmpty = val === null || val === undefined || (typeof val === 'string' && val.trim() === '')
	                        if (isTextEmpty) {
	                            Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập nội dung`, { position: 'top' })
	                            validationPassed = false
	                        }
	                    }
	
	                    // Backup chức năng
	                    // if (item.FN_Check === 'fnCheckDeTaiDaDangKy') {
	                    //     if (!this.checkDeTaiFlag) {
	                    //         Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa kiểm tra khớp đề tài`, { position: 'top' })
	                    //         validationPassed = false
	                    //     } else if (this.checkDeTaiFlag === false) {
	                    //         Vue.$toast.error(`Task "${item.Task_Detail_Description}" đề tài không khớp với đề tài đã đăng ký`, { position: 'top' })
	                    //         validationPassed = false
	                    //     }
	                    // }
	
	                    if (item.FN_Check === 'fnCheckLimit' && this.countWords(item.Text_Content) < 120) {
	                        Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập đủ 120 từ`, { position: 'top' })
	                        validationPassed = false
	                    }
	
	                    // Kiểm tra điều kiện bài báo khoa học
	                    if (['tenTapChiHoiThao', 'namXuatBan', 'viTriTacGia'].includes(item.FieldName) && this.checkHide()) {
	                        const val = item.Text_Content
	                        const isEmpty = val === null || val === undefined || (typeof val === 'string' && val.trim() === '')
	                        if (isEmpty) {
	                            Vue.$toast.error(`Phải nhập thông tin tại "${item.Task_Detail_Description || item.FieldName}"`, { position: 'top' })
	                            validationPassed = false
	                        }
	                    }

	                    // Kiểm tra điều kiện Hội đồng đạo đức trong NCYSH (Ngành Dược)
	                    if (['SoCap_HDYSH', 'SoCap_HDYSH_ID', 'NoiCap_HDYSH', 'NoiCap_HDYSH_ID'].includes(item.FieldName) && !isHidden) {
	                        const fileItem = this.dataDetailFlow.find((i) => i.FieldName === 'File_HDYSH_ID')
	                        const fileId = fileItem?.File_ID ? String(fileItem.File_ID).trim() : ''
	                        const hasFile = Boolean(fileId && fileId !== 'null' && fileId !== 'undefined')
	                        if (hasFile) {
	                            const val = item.Text_Content
	                            const isEmpty = val === null || val === undefined || (typeof val === 'string' && val.trim() === '')
	                            if (isEmpty) {
	                                Vue.$toast.error(`Đã upload file Y đức, vui lòng nhập "${item.Task_Detail_Description || item.FieldName}"`, { position: 'top' })
	                                validationPassed = false
	                            }
	                        }
	                    }

	                    if (item.FieldName === 'File_HDYSH_ID' && !isHidden) {
	                        const soCapItem = this.dataDetailFlow.find((i) => i.FieldName === 'SoCap_HDYSH' || i.FieldName === 'SoCap_HDYSH_ID')
	                        const noiCapItem = this.dataDetailFlow.find((i) => i.FieldName === 'NoiCap_HDYSH' || i.FieldName === 'NoiCap_HDYSH_ID')
	                        const soCapVal = typeof soCapItem?.Text_Content === 'string' ? soCapItem.Text_Content.trim() : soCapItem?.Text_Content
	                        const noiCapVal = typeof noiCapItem?.Text_Content === 'string' ? noiCapItem.Text_Content.trim() : noiCapItem?.Text_Content
	                        const hasInfo = Boolean(soCapVal || noiCapVal)
	                        const fileId = item.File_ID ? String(item.File_ID).trim() : ''
	                        const isFileEmpty = !fileId || fileId === 'null' || fileId === 'undefined'
	                        if (hasInfo && isFileEmpty) {
	                            Vue.$toast.error(`Đã nhập thông tin Y đức, vui lòng upload "${item.Task_Detail_Description || item.FieldName}"`, { position: 'top' })
	                            validationPassed = false
	                        }
	                    }
	                }
	            }
	
	            // Thực hiện validate
	            this.dataDetailFlow.forEach(validateItem)
	
	            if (!validationPassed) {
	                console.log('Validation failed')
	                return
	            }
	
	            if (hasInvalidText) {
	                Vue.$toast.error(`Cập nhật thất bại do lỗi viết in hoa`, { position: 'top' })
	                return
	            }
	
	            console.log('Validation passed, updating... xxxxxxx', this.dataDetailFlow)
	            const payloadDetails = this.dataDetailFlow.map((item) => ({
	                Task_Detail_ID: item.Task_Detail_ID,
	                Text_Content: typeof item.Text_Content === 'string' && item.Text_Content ? item.Text_Content.trim() : (item.Text_Content ?? ''),
	                File_Name: item.Task_Detail_Type === 'FILE' ? (item.File_Name ?? null) : null,
	                File_Type: item.Task_Detail_Type === 'FILE' ? (item.File_Type ?? null) : null,
	                File_URL: item.Task_Detail_Type === 'FILE' ? (item.File_URL ?? null) : null,
	                File_ID: item.Task_Detail_Type === 'FILE' ? (item.File_ID ?? null) : null,
	                Flow_Detail_Status: 'P'
	            }))

	            try {
	                await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
	                    Student_ID: vueData.user.UserID,
	                    Process_ID: root.PROCESS_ID,
	                    Flow_ID: root.Flow_ID || this.dataDetailFlow[0]?.Flow_ID,
	                    Task_ID: root.Children_Task_ID || root.TASK_ID || this.dataDetailFlow[0]?.Task_ID,
	                    JsonDetails: JSON.stringify(payloadDetails),
	                    IsApproveAll: 0
	                })
	                Vue.$toast.success(`Cập nhật ${root.TASK_NAME} thành công`, { position: 'top' })
	                // CALL('getStudentRootFlow')
	            } catch (err) {
	                console.error('Fail to save', err)
	                Vue.$toast.error(`Cập nhật ${root.TASK_NAME} thất bại`, { position: 'top' })
	            }
	        },
	        async onLoadDetailFlow(FLOW_ID, LOCK_STATUS, root) {
	            const $this = this
	            console.log('ABCDFSC', vueData.StudentProcess)
	            const TCQLD_NganhID = (vueData && vueData.StudentProcess && vueData.StudentProcess.length > 0) ? vueData.StudentProcess[0].NganhID : null
	            const Duoc_NganhID = '106'
	
	            ajaxCALL(
	                '/Get_FlowDetail',
	                { Flow_ID: FLOW_ID },
	                async (res) => {
	                    // Lấy detail của flow id đó
	                    let filterarr = res.data
	                        // .filter((item) => {
	                        //     if (TCQLD_NganhID !== Duoc_NganhID) {
	                        //         return item.FN_Check !== 'DuocOnly'
	                        //     }
	                        //     return true
	                        // })
	                        .map(async (item) => {
	                            if (
	                                item.Task_Detail_Type === 'TEXTAREA | FUN' &&
	                                item.FN_Check === 'fnCheckTenDeTai' &&
	                                item.Text_Content !== null &&
	                                item.Text_Content !== '' &&
	                                root.Flow_Status !== 'C'
	                            ) {
	                                checkTopicBtn(item.Text_Content)
	                            }
	
	                            if (root.Flow_Status !== 'C' && item.FN_Check === 'fnCheckHocPhi(StudentID)' && item.Task_Detail_Type === 'FUN') {
	                                let ttnhp = await this.checkHocPhi($this.student_id)
	                                return {
	                                    ...item,
	                                    FILE_UPLOAD: null,
	                                    TinhTrangNoHocPhi: ttnhp,
	                                }
	                            }
	
	                            return { ...item, FILE_UPLOAD: null, TinhTrangNoHocPhi: 0 }
	                        })
	
	                    Promise.all(filterarr).then((res) => {
	                        console.log('set..', res)
	                        $this.dataDetailFlow = res.map((item) => {
									if (item.Task_Detail_Type === 'CHECKBOX') {
									item.Text_Content =
									item.Text_Content === true ||
									String(item.Text_Content).toLowerCase() === 'true'
									
									console.log('item.Text_Content', item.Text_Content)
									}
	                            return {
	                                ...item,
	                                isInHoa: false,
	                                InHoaError: '',
	                                Text_Content:
	                                    item.FieldName === 'QDThanhLapHoiDong_ThoiGian' && item.Text_Content
	                                        ? moment(item.Text_Content).format('DD/MM/YYYY')
	                                        : item.Task_Detail_Type === 'DIEM'
	                                            ? item.Text_Content
	                                                ? parseFloat(item.Text_Content).toFixed(2)
	                                                : null
	                                            : item.Text_Content,
	                            }
	                        })
	                        console.log('xxx', $this.dataDetailFlow)
	                    })

	                    if (root && root.Flow_Status === 'R') {
	                        ajaxCALL('/SDH_Get_FlowDetail_His', { Flow_ID: FLOW_ID }, (hisRes) => {
	                            if (hisRes && hisRes.data && hisRes.data.length > 0) {
	                                $this.latestRejectionReason = hisRes.data[0].LyDo || ''
	                            }
	                        })
	                    } else {
	                        $this.latestRejectionReason = ''
	                    }
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('Error: ', error)
	                },
	            )
	        },
	
	        checkHocPhi(studentID) {
	            const $this = this
	            return new Promise(function (resolve, reject) {
	                $.ajax({
	                    type: 'GET',
	                    headers: {
	                        authorization: $awt,
	                    },
	                    url: `https://tapi.lhu.edu.vn//fee/NoHP_GetChiTietNoHocPhiByStudent?StudentID=${studentID}`,
	                    contentType: 'application/json; charset=utf-8',
	                    dataType: 'json',
	                    crossDomain: true,
	                    success: function (res) {
	                        $this.feeArr = res.data.length > 3 && res.data[3].length > 0 && res.data[3][0] ? res.data[3][0].tienphaidong : 'Không tìm thấy. Vui lòng liên hệ phòng tài chính'
	                        // return $this.feeArr
	                        resolve($this.feeArr)
	                    },
	                    error: function (xhr, ajaxOptions, thrownError) {
	                        $.dialog({
	                            icon: 'fas fa-exclamation',
	                            title: 'Error',
	                            content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
	                            type: 'red',
	                            columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
	                            closeIcon: true,
	                            buttons: {
	                                ok: {
	                                    text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
	                                    btnClass: 'btn-blue',
	                                },
	                            },
	                        })
	                    },
	                    complete: function () { },
	                })
	            })
	        },
	
	        isStep5(item) {
	            if (!item) return false
	            const seq = Number(item.Seq || item.SEQ || 0)
	            const taskId = Number(item.Task_ID || item.Children_Task_ID || 0)
	            return seq === 30 || [4, 22].includes(taskId) || ['ThS03', 'ThSUD03'].includes(item.Task_Code)
	        },
	        async openHistoryModal(flowId) {
	            this.historyModal = true
	            this.historyLoading = true
	            try {
	                const res = await ajaxCALLPromise('/SDH_Get_FlowDetail_His', { Flow_ID: flowId })
	                this.historyList = res || []
	            } catch (e) {
	                console.log('Error loading history: ', e)
	                this.historyList = []
	            } finally {
	                this.historyLoading = false
	            }
	        },
	        checkDeTaiDaDky(studentID, textContent) {
	            ajaxCALL(
	                '/Student_Check_TenDeTaiDaDangKy',
	                {
	                    Student_ID: studentID,
	                },
	                (res) => {
	                    this.resultKtraDeTai = res.data[0]?.Text_Content
	                    console.log('check success', this.resultKtraDeTai)
	
	                    if (textContent !== null && textContent !== '') {
	                        if (this.resultKtraDeTai.toLowerCase() === textContent.toLowerCase()) {
	                            this.checkDeTaiFlag = true
	                        } else {
	                            this.checkDeTaiFlag = false
	                        }
	                    } else {
	                        Vue.$toast.error(`Không được bỏ trống ô nhập tên đề tài bảo vệ`, { position: 'top' })
	                    }
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('check de tai da dang ky fail: ', error)
	                },
	            )
	        },
	
	        getStepColor(name, lock) {
	            if (lock == 0) {
	                //LOCK_STATUS = 0 CHƯA ĐƯỢC LÀM, 1: ĐƯỢC LÀM
	                switch (name) {
	                    case 'W': //W: WAIT
	                        return 'blue lighten-4'
	                    case 'C': //C: COMPLETED
	                        return 'green darken-1'
	                    case 'P': //P:PROCESSING
	                        return 'blue darken-2'
	                    case 'R': //R: REJECTED
	                        return 'red darken-2'
	                    default:
	                        return 'secondary'
	                }
	            } else {
	                //LOCK = 1 : 1: ĐƯỢC LÀM
	                switch (name) {
	                    case 'W': //W: WAIT
	                        return 'amber'
	                    case 'P': //P:PROCESSING
	                        return 'blue darken-2'
	                    case 'R': //R: REJECTED
	                        return 'red darken-2'
	                    case 'C': //C: COMPLETED
	                        return 'green darken-1'
	                    default:
	                        return 'secondary'
	                }
	            }
	        },
	        getStyleStatusLock(lock) {
	            if (lock === 0) {
	                return 'pointer-events: auto; opacity: 1;'
	                // return "pointer-events: none; opacity: 1;"
	            } else {
	                return 'pointer-events: auto; opacity: 1;'
	            }
	        },
	        getStepIcon(name, lock) {
	            if (lock == 0 && name == 'W') {
	                //LOCK_STATUS = 0 CHƯA ĐƯỢC LÀM, 1: ĐƯỢC LÀM
	                return 'mdi-lock'
	            } else {
	                switch (name) {
	                    case 'W': //W: WAIT
	                        return 'mdi-information'
	                    case 'C': //C: COMPLETED
	                        return 'mdi-check-bold'
	                    case 'P': //P:PROCESSING
	                        return 'mdi-timer-sand'
	                    case 'R': //R: REJECTED
	                        return 'mdi-close-thick'
	                    default:
	                        return 'water-boiler-alert'
	                }
	            }
	        },
	        updateFileRules(arr) {
	            const item = arr.find((type) => type.Task_Detail_Type === 'FILE' || type.Task_Detail_Type === 'FILEVIEW')
	            // Kiểm tra nếu AllowFileType là null hoặc undefined
	            if (item) {
	                if (item.AllowFileType === null || item.AllowFileType === undefined) {
	                    // Đặt giá trị mặc định cho extensions trong fileRules
	                    this.fileRules.mime_types[0].extensions = 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg'
	                    console.log('fileRules 1', this.fileRules, item)
	                } else {
	                    // Kiểm tra nếu AllowFileType là một chuỗi
	                    if (typeof item.AllowFileType === 'string') {
	                        // Chuyển đổi AllowFileType thành chữ thường và thay dấu | thành dấu ,
	                        const lowerCaseExtensions = item.AllowFileType.toLowerCase().replace(/\|/g, ',')
	                        console.log('lowerCaseExtensions', lowerCaseExtensions)
	
	                        // Cập nhật extensions trong fileRules
	                        this.fileRules.mime_types[0].extensions = lowerCaseExtensions
	                        console.log('fileRules 2', this.fileRules)
	                    } else {
	                        // Nếu AllowFileType không phải là chuỗi, đặt giá trị mặc định cho extensions trong fileRules
	                        this.fileRules.mime_types[0].extensions = 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg'
	                        console.log('fileRules 3', this.fileRules)
	                    }
	                }
	            }
	        },
	    },
	}
</script>