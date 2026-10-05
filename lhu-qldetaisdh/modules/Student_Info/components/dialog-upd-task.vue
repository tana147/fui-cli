<template>
	<div>
		<v-dialog v-model="vueData.isUpdTask" transition="dialog-bottom-transition" fullscreen max-width="1400px"
			persistent>
			<v-card>
				<c-toolbar @onClose="closeModal">
					<template v-slot:title>
						<div class="title primary--text text-left">
							Học viên:
							<span class="red--text">
								[{{ HocVienData.StudentID }}] {{ HocVienData.HoSV }}
								{{ HocVienData.TenSV }}
								[{{ HocVienData.LopID }}]
							</span>
							<v-chip v-if="HocVienData.IsXuLyHocVu" color="red" dark class="ml-2"> Đã xử lý học vụ
							</v-chip>
						</div>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-container>
						<div class="mb-5">
							<p class="pb-0 mb-3 primary--text text-h6">Cập nhật thông tin học viên</p>
							<!-- {{ExistData}} -->
							<v-row dense>
								<v-col cols="6">
									<v-text-field v-model="ExistData.Email" label="Email" placeholder="Nhập email"
										outlined color="primary" dense hide-details />
								</v-col>
								<v-col cols="1">
									<v-select v-model="ExistData.GioiTinh" :items="genderList" label="Giới tính"
										outlined color="primary" dense hide-details />
								</v-col>
								<v-col cols="3">
									<v-text-field v-model="ExistData.NoiSinh" label="Nơi sinh"
										placeholder="Nhập nơi sinh" outlined color="primary" dense hide-details />
								</v-col>
								<v-col cols="2">
									<v-text-field v-model="ExistData.SoDienThoai" label="SĐT" placeholder="Nhập SĐT"
										outlined color="primary" dense hide-details />
								</v-col>

								<v-col cols="3">
									<v-text-field v-model="ExistData.DanToc" label="Dân tộc" placeholder="Nhập dân tộc"
										outlined color="primary" dense hide-details />
								</v-col>
								<v-col cols="3">
									<v-text-field v-model="ExistData.QuocTich" label="Quốc tịch"
										placeholder="Nhập quốc tịch" outlined color="primary" dense hide-details />
								</v-col>
								<v-col cols="3">
									<v-text-field v-model="ExistData.CCCD" label="Số CCCD" placeholder="Nhập CCCD"
										outlined color="primary" dense hide-details />
								</v-col>
								<!-- <v-col cols="3">
									<f-date v-model="ExistData.NgayCap_CCCD" label="Ngày cấp CCCD" outlined
										color="primary" dense hide-details />
								</v-col> -->

								<v-col cols="3">
									<v-text-field v-model="ExistData.Truong_DaiHoc" label="Trường Đại học"
										placeholder="Nhập trường đại học" outlined color="primary" dense hide-details />
								</v-col>
								<v-col cols="3">
									<v-text-field v-model="ExistData.Nganh_DaiHoc" label="Ngành Đại học"
										placeholder="Nhập ngành đại học" outlined color="primary" dense hide-details />
								</v-col>
								<v-col cols="3">
									<!-- <f-date v-model="ExistData.ThoiGianTotNghiep_DaiHoc"
										label="Thời gian tốt nghiệp đại học" outlined color="primary" dense
										hide-details /> -->
									<v-text-field v-model="ExistData.ThoiGianTotNghiep_DaiHoc" @keydown="onPrevent"
										label="Năm tốt nghiệp đại học" placeholder="Nhập năm tốt nghiệp đại học"
										outlined color="primary" dense hide-details />
								</v-col>
								<v-col cols="3">
									<v-text-field v-model="ExistData.XepLoai" label="Xếp loại"
										placeholder="Nhập xếp loại" outlined color="primary" dense hide-details />
								</v-col>

								<v-col cols="3">
									<v-autocomplete v-model="ExistData.Loai_NgoaiNgu_DauVao"
										label="Loại ngoại ngữ đầu vào" placeholder="Chọn loại ngoại ngữ đầu vào"
										:items="DsOriginalTenNN" item-text="text" item-value="value" outlined dense
										hide-details />
								</v-col>
								<v-col cols="3">
									<v-text-field v-model="ExistData.NgoaiNgu_DauVao" label="Ngoại ngữ đầu vào"
										placeholder="Nhập ngoại ngữ đầu vào" outlined color="primary" dense
										hide-details />
								</v-col>
								<v-col cols="3">
									<v-autocomplete v-model="ExistData.BoSungKienThuc" label="Bổ sung kiến thức"
										:items="DsYesNo" item-text="text" item-value="value" outlined dense
										hide-details />
								</v-col>
								<v-col cols="3">
									<v-autocomplete v-model="ExistData.CongBoKhoaHoc" label="Công bố khoa học"
										:items="DsYesNo" item-text="text" item-value="value" outlined dense
										hide-details />
								</v-col>
							</v-row>

							<div class="d-flex justify-end mt-4">
								<v-btn @click="onUpdateInfo" color="success">Lưu cập nhật thông tin</v-btn>
							</div>
						</div>

						<hr />

						<div class="mt-3">
							<p class="pb-0 mb-3 primary--text text-h6">Cập nhật dữ liệu chi tiết các bước</p>

							<div class="mb-3 actionSelect d-flex justify-end align-center ml-auto">
								<v-btn class="mr-2" color="warning" @click="confirmBox">Đổi/Điều chỉnh tên đề
									tài/GVHD</v-btn>
								<v-select class="process-select mr-2" style="min-width: 200px;" label="Loại process" v-model="processActionData"
									:items="processActionList" outlined dense hide-details />
								<v-select v-if="processActionData === 2 && changeProcessList.length > 0"
									class="process-select" style="min-width: 340px;" label="Lần đổi/điều chỉnh"
									v-model="selectedChangeProcessID" :items="changeProcessList" outlined dense
									hide-details @change="onChangeSelectedChangeProcess" />
							</div>

							<!-- Luận văn của học viên -->
							<div>
								<v-expansion-panels v-model="vueData.Panel" accordion>
									<v-expansion-panel v-for="(item, index) in rootArr" :key="index">
										<v-expansion-panel-header :step="index + 1"
											@click="onLoadDetailFlow(item.Flow_ID, item.Flow_Status, item.Children_Task_ID)"
											:class="getStepColor(item.Flow_Status, item.LOCK_STATUS)"
											:style="item.LOCK_STATUS ? { height: '48px' } : null" disable-icon-rotate>
											<div class="stepperStep mt-1">
												<h4>{{ index + 1 }}./ {{ item.TASK_NAME }}</h4>
											</div>
											<template v-slot:actions>
												<v-icon color="white">{{ getStepIcon(item.Flow_Status, item.LOCK_STATUS)
													}}</v-icon>
											</template>
										</v-expansion-panel-header>

										<v-expansion-panel-content :step="index + 1">
											<div>
												<div v-if="hasOldData && processActionData === 1"
													class="mt-3 d-flex justify-center align-center">
													<v-btn
														@click="watchOldData(item.Flow_ID, item.Flow_Status, item.Children_Task_ID)"
														color="primary" text><v-icon left>{{ IsWatchOldData ?
															'mdi-eye-off' : 'mdi-eye-outline' }}</v-icon>{{
														IsWatchOldData ? 'Ẩn dữ liệu cũ' : 'Xem dữ liệu cũ' }}
													</v-btn>
												</div>
												<div v-if="DS_OldHoiDong.length > 0"
													class="mt-3 d-flex justify-center align-center flex-wrap" style="gap: 8px">
													<v-btn @click="historyData(item)" color="pink" text> <v-icon
															left>mdi-database</v-icon> Xem Dữ liệu bảo vệ chưa đạt
													</v-btn>
													<v-btn @click="onSyncFromFailData(item)" color="teal darken-1" text>
														<v-icon left>mdi-sync</v-icon> Đồng bộ từ dữ liệu chưa đạt
													</v-btn>
												</div>
												<div v-if="dataDetailFlow.length > 0">
													<div v-for="(itemDes, indexDes) in dataDetailFlow" :key="indexDes">
														<div v-if="itemDes.Task_Detail_Display === 1">
															<div class="d-flex align-center mt-3">
																<span class="d-flex align-center">
																	<h4 v-show="shouldShowDuocOnlyField(itemDes)"
																		v-if="itemDes.Task_Detail_Display === 1"
																		:class="itemDes.IsOldProc ? 'blurText' : ''">
																		{{ index + 1 }}.{{ itemDes.STT }} {{
																		itemDes.Task_Detail_Description }}
																	</h4>
																	<!-- itemDes.FN_Check !== 'DuocOnly' && -->

																	<div v-if="itemDes.Task_Detail_Type === 'CHECKBOX'"
																		class="ml-6">
																		<v-checkbox class="checkboxMod" large
																			color="success" :hint="itemDes.Data_Exp"
																			v-model="itemDes.Text_Content"
																			persistent-hint
																			:disabled="itemDes.IsOldProc" />
																	</div>
																</span>
																<!-- <div v-if="itemDes.Data_Exp !== null && itemDes.Task_Detail_Type === 'FILE'" class="ml-auto">
                                                                    <a :href="parseDataExp(itemDes.Data_Exp)" download="file mẫu">
                                                                        <v-btn color="success" text> <v-icon>mdi-download-circle</v-icon> File mẫu </v-btn>
                                                                    </a>
                                                                </div> -->
																<div v-if="itemDes.Data_Exp !== null && itemDes.Task_Detail_Type === 'FILE'"
																	class="ml-auto flow-detail-download">
																	<!-- itemDes.Data_Exp -->
																	<a class="flow-detail-download-link"
																		:href="parseDataExp(itemDes.Data_Exp)"
																		download="file mẫu">
																		<v-btn class="flow-detail-download-btn"
																			color="success" text>
																			<v-icon small>mdi-download-circle</v-icon>
																			File mẫu
																		</v-btn>
																	</a>
																</div>
															</div>

															<v-alert v-if="
                                                                    itemDes.isInHoa &&
                                                                    (itemDes.User_Input === 'SDH' ||
                                                                        itemDes.Task_Detail_Type === 'TEXT' ||
                                                                        itemDes.Task_Detail_Type === 'TEXTAREA' ||
                                                                        itemDes.Task_Detail_Type === 'TEXTAREA | FUN' ||
                                                                        itemDes.FieldName === 'ThesisesProfSuggest1')
                                                                " border="right" colored-border type="error"
																elevation="2" dense>
																{{ itemDes.InHoaError }}
															</v-alert>

															<i class="red--text mt-0"
																v-if="(itemDes.FieldName === 'namXuatBan' || itemDes.FieldName === 'viTriTacGia') && checkHide()"><b>Lưu
																	ý:</b> Phải nhập thông tin <b>Năm xuất bản</b> và
																<b>Vị trí tác giả</b> khi có bài báo khoa học</i>
															<!-- <v-text-field outlined dense color="success"
																v-model="itemDes.Text_Content" :hint="itemDes.Data_Exp"
																v-show="shouldShowDuocOnlyField(itemDes)"
																:disabled="itemDes.IsOldProc || item.Flow_Status === 'C'"
																v-if="itemDes.Task_Detail_Display === 1 && (itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW')" /> -->
															<v-text-field outlined dense color="success"
																v-model="itemDes.Text_Content" :hint="itemDes.Data_Exp"
																v-show="shouldShowDuocOnlyField(itemDes)"
																:disabled="itemDes.IsOldProc"
																v-if="itemDes.Task_Detail_Display === 1 && (itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW')">
																<template #message="{ message }">
																	<span style="color: red;">{{ message }}</span>
																</template>
															</v-text-field>
															<v-text-field v-if="
                                                                    itemDes.Task_Detail_Display === 1 && (itemDes.Task_Detail_Type === 'NUMBER' || itemDes.Task_Detail_Type === 'NUMBERVIEW')
                                                                " class="text-right-input"
																v-model="itemDes.Text_Content" placeholder="Nhập số"
																type="number" min="0" step="0.01" inputmode="decimal"
																@keydown="preventNegative" dense outlined
																:disabled="itemDes.IsOldProc"
																color="success" />

															<!-- itemDes.FN_Check !== 'DuocOnly' && -->
															<div class="dateWrap"
																v-if="itemDes.Task_Detail_Type === 'DATE' || itemDes.Task_Detail_Type === 'DATEVIEW'">
																<f-date v-model="itemDes.Text_Content" :disabled="itemDes.IsOldProc" />
															</div>

															<v-autocomplete
																v-if="itemDes.Task_Detail_Type === 'SELECT' && itemDes.FieldName === 'VanBangChungChiDauRa'"
																v-model="itemDes.Text_Content" :items="DsNNDauRa"
																item-text="text" item-value="value" outlined dense
																:disabled="itemDes.IsOldProc"
																hide-details>
																<template v-slot:item="{ item, attrs, on }">
																	<v-subheader v-if="item.header">
																		{{ item.header }}
																	</v-subheader>

																	<v-list-item v-else v-bind="attrs" v-on="on">
																		<v-list-item-content>
																			<v-list-item-title>{{ item.text
																				}}</v-list-item-title>
																		</v-list-item-content>
																	</v-list-item>
																</template>
															</v-autocomplete>

															<v-autocomplete
																v-if="itemDes.Task_Detail_Type === 'SELECT' && itemDes.FieldName === 'TenNgoaiNguDauRa'"
																v-model="itemDes.Text_Content" :items="DsTenNgoaiNgu"
																item-text="text" item-value="value" outlined dense
																:disabled="itemDes.IsOldProc"
																hide-details />

															<div
																v-if="itemDes.Task_Detail_Type === 'TABLE' && itemDes.FieldName === 'DiemHocPhan'">
															</div>

															<!-- file-comp goes here -->
															<file-comp :lock="item.LOCK_STATUS" :itemdes="itemDes"
																:item="item" :textRules="textRules"
																:filerule="fileRules"
																v-show="shouldShowDuocOnlyField(itemDes)"
																v-if="itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW'" />
															<!-- itemDes.FN_Check !== 'DuocOnly' && -->
															<textarea-comp :itemdes="itemDes"
																v-if="itemDes.Task_Detail_Type === 'TEXTAREA'"
																:lock="item.LOCK_STATUS" />

															<score-comp
																v-if="itemDes.Task_Detail_Type === 'DIEM' || itemDes.Task_Detail_Type === 'FORMULAR'"
																:itemdes="itemDes" />

															<!-- Kiểm tra trùng tên đề tài đã đăng ký -->
															<div v-if="itemDes.FN_Check === 'fnCheckDeTaiDaDangKy'">
																<div class="d-flex align-center justify-center"
																	style="gap: 15px">
																	<v-textarea v-model="itemDes.Text_Content"
																		class="mt-2" outlined name="input-7-1" rows="1"
																		color="green" flat="false" auto-grow dense
																		hide-details disabled />
																</div>
																<div class="d-flex align-center mb-2"
																	v-if="resultKtraDeTai && !itemDes.IsOldProc">
																	<h4 class="primary--text">Tên đề tài trong Quyết
																		định:</h4>
																	<p class="mb-0 ml-2">
																		{{ resultKtraDeTai }}
																	</p>
																</div>
															</div>

															<!-- Kiem tra trung lap -->
															<div
																v-if="itemDes.Task_Detail_Type === 'TEXTAREA | FUN' && itemDes.FN_Check === 'fnCheckTenDeTai'">
																<div class="d-flex align-center justify-center"
																	style="gap: 15px">
																	<div style="width: 100%">
																		<textarea-button-comp :itemdes="itemDes"
																			:lock="item.LOCK_STATUS" />
																	</div>
																	<div>
																		<v-btn :disabled="itemDes.IsOldProc"
																			color="warning"
																			@click="checkTopicBtn(itemDes.Text_Content)"
																			class="mb-6">
																			Kiểm tra đề tài trùng</v-btn>
																	</div>
																</div>
																<!-- kiem tra func -->
																<div
																	v-if="itemDes.FN_Check === 'fnCheckTenDeTai' && itemDes.Text_Content !== null && itemDes.Text_Content !== ''">
																	<similiar-topic-list class="mb-5" :itemdes="itemDes"
																		v-if="itemDes.FN_Check === 'fnCheckTenDeTai'" />
																</div>
															</div>

															<div v-if="itemDes.Task_Detail_Type === 'FUN'">
																<div
																	v-if="itemDes.FN_Check === 'fnCheckHocPhi(StudentID)'">
																	<div class="mb-3 mt-2">
																		<div>
																			<div v-if="itemDes.TinhTrangNoHocPhi == 0"
																				class="d-flex justify-center align-center">
																				<h4 class="success--text">
																					<v-icon class="mb-1"
																						color="success">mdi-check-bold</v-icon>
																					Không nợ học phí
																				</h4>
																			</div>
																			<div v-else>
																				<span class="primary--text"><b>Tình
																						trạng nợ học phí:</b></span>
																				<span
																					:class="{ 'success--text': feeArr == '0', 'red--text': feeArr != '0' }">
																					<b>{{ itemDes.TinhTrangNoHocPhi }}
																						VNĐ</b>
																				</span>
																			</div>
																		</div>
																	</div>
																</div>
															</div>

															<table-chung :tableHeader="tableHoiDongHeader"
																:label="hoiDongLabel" :itemdes="itemDes"
																:DataArray="itemDes.DataArray"
																v-if="itemDes.FieldName === 'HoiDongID'" />

															<table-chung :tableHeader="tableBangDiemHeader"
																:label="bangDiemLabel" :itemdes="itemDes"
																:DataArray="DsDiemHocPhan"
																v-if="itemDes.FieldName === 'DiemHocPhan'" />
														</div>
													</div>
													<div>
														<!-- Có thể sử dụng sau -->
														<!-- <v-btn color="error"
															@click="unCheckAll(dataDetailFlow, item, item.Flow_ID)"
															class="mb-3">Hủy Duyệt</v-btn> -->
														<!-- v-if="processActionData === 1" -->
														<div v-if="vueData.user.SystemRight === 1"
															class="d-flex justify-end mt-3">
															<v-btn v-if="processActionData === 1" color="indigo" dark
																@click="onCheckButNotSave(dataDetailFlow, item, item.Flow_ID)"
																class="mb-3 ml-3"
																:disabled="HocVienData.IsXuLyHocVu">Duyệt
															</v-btn>
														</div>
														<div v-else class="d-flex justify-end mt-3">
															<v-btn color="primary" v-if="processActionData === 1"
																@click="saveAndCheckAll(dataDetailFlow, item, item.Flow_ID)"
																class="mb-3 ml-3"
																:disabled="HocVienData.IsXuLyHocVu">Lưu & Duyệt
															</v-btn>
															<v-btn color="success" @click="onSave(item.Flow_ID, item)"
																class="mb-3 ml-3"
																:disabled="HocVienData.IsXuLyHocVu">Lưu</v-btn>
														</div>
													</div>
												</div>
												<div v-else>
													<p>Dữ liệu không tồn tại</p>
												</div>
											</div>
										</v-expansion-panel-content>
									</v-expansion-panel>
								</v-expansion-panels>
							</div>
						</div>
					</v-container>
				</v-card-text>
			</v-card>
		</v-dialog>
		<old-data-dialog :dsthongtinhoidong="DS_ThongTinHoiDong" :dstvhd="DS_ThanhVienHoiDong"
			:dsdkybaove="DS_DangKyBaoVe" :dsbaove="DS_BaoVe" :thongtinbuoc="ThongTinBuoc" :currentfield="currentStep" />
	</div>
</template>

<script>
	export default {
		props: ['dsexiststudent'],
	    data() {
	        return {
	            x: null,
	            rootArr: [],
	            dataDetailFlow: [],
	            initialDetailFlow: [],
	            feeArr: [],
	            student_id: null,
	            ExistData: {},
	            checkDeTaiFlag: null,
	            resultKtraDeTai: null,
	            selectProcessData: 0,
	            StudentProcList: [],
	            SecondRootFlow: [],
	            IsWatchOldData: false,
	            hasOldData: false,
	            studentChangeType: {
	                hasOldThesis: false,
	                hasOldProf: false,
	                hasOldQD: false,
	            },
	            studentChangeHistory: [],
	            processActionData: 1,
	            selectedChangeProcessID: null,
	
	            DS_RootProcess: [],
	            changDataArr: [],
	            DsNNDauRa: [],
	            DsTenNgoaiNgu: [],
	            DsYesNo: [],
	            DsOriginalTenNN: [],
	
	            DS_OldHoiDong: [],
	            DS_ThongTinHoiDong: [],
	            DS_ThanhVienHoiDong: [],
	            DS_DangKyBaoVe: [],
	            DS_BaoVe: [],
	            DsDiemHocPhan: [],
	            ThongTinBuoc: null,
	            currentStep: 0,
	            Duoc_NganhID: '106',
	
	            hoiDongLabel: 'Danh sách thành viên hội đồng',
	            bangDiemLabel: 'Danh sách môn học',
	
	            genderList: [
	                {
	                    text: 'Nam',
	                    value: 'Nam',
	                },
	                {
	                    text: 'Nữ',
	                    value: 'Nữ',
	                },
	            ],
	
	            processActionList: [
	                {
	                    text: 'Làm Luận văn/Đồ án',
	                    value: 1,
	                },
	                {
	                    text: 'Đổi/Điều chỉnh đề tài/GVHD',
	                    value: 2,
	                },
	                {
	                    text: 'Gia hạn đề tài',
	                    value: 3,
	                },
	            ],
	
	            HocHamHocViList: [
	                {
	                    HocHamHocVi: 'GS.TS.',
	                },
	                {
	                    HocHamHocVi: 'GS.TSKH.',
	                },
	                {
	                    HocHamHocVi: 'PGS.TS.',
	                },
	                {
	                    HocHamHocVi: 'PGS.TSKH.',
	                },
	                {
	                    HocHamHocVi: 'TS.DS.',
	                },
	                {
	                    HocHamHocVi: 'TS.',
	                },
	            ],
	
	            tableHoiDongHeader: [
	                {
	                    text: 'STT',
	                    value: 'STT',
	                    class: 'renderCol',
	                    sortable: false,
	                    align: 'center',
	                    width: 50,
	                },
	                {
	                    text: 'Họ và tên',
	                    value: 'HoTenHocHamHocVi',
	                },
	                {
	                    text: 'Ngành giảng dạy',
	                    value: 'NganhGiangDay',
	                },
	                {
	                    text: 'Cơ quan công tác',
	                    value: 'CoQuanCongTac',
	                },
	                {
	                    text: 'Chức trách',
	                    value: 'ChucTrach',
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
	
	            selectProcess: [
	                {
	                    text: 'Đề tài của học viên',
	                    value: 0,
	                },
	                {
	                    text: 'Đổi đề tài',
	                    value: 1,
	                },
	            ],
	        }
	    },
	    mounted() { },
	    computed: {
	        HocVienData: function () {
	            return vueData.hocVienObj
	        },
	        isUpdData: function () {
	            return vueData.isUpdTask
	        },
	        PanelControl: function () {
	            return vueData.Panel
	        },
	        changeProcessList: function () {
	            if (!this.changDataArr || this.changDataArr.length === 0) return []
	            const total = this.changDataArr.length
	            return this.changDataArr.map((item, index) => {
	                const num = total - index
	                const displayDate = item.Updated_At || item.Created_At
	                const dateStr = displayDate ? moment(displayDate).format('DD/MM/YYYY HH:mm') : ''
	                return {
	                    text: `Lần đổi ${num} - ${dateStr}`,
	                    value: item.Process_Student_ID,
	                }
	            })
	        },
	    },
	    watch: {
	        processActionData: function (val) {
	            if (val === 1) {
	                vueData.Panel = null
	                this.onLoadRootFlow()
	            } else if (val === 2) {
	                vueData.Panel = null
	                this.onLoadChangeRootFlow()
	            } else if (val === 3) {
	            }
	        },
	        rootArr: function (val) {
	            if (val.length > 0) {
	                this.student_id = val[0].STUDENT_ID
	            }
	        },
	        HocVienData: function (val) {
	            if (val) {
	                console.log('val', val)
	                // this.onLoadRootFlow()
	            }
	        },
	        dataDetailFlow: function (val) {
	            if (val.length > 0) {
	                const findDiemHocPhan = val.find((item) => item.FieldName === 'DiemHocPhan')
	                if (findDiemHocPhan) {
	                    this.onLoadDiemThanhPhan(this.HocVienData.StudentID)
	                        .then((data) => {
	                            this.DsDiemHocPhan = data
	                        })
	                        .catch((err) => {
	                            console.log('Loi', err)
	                        })
	                }
	
	                const findField = val.find((item) => item.FieldName === 'HoiDongID' || item.FieldName === 'fileDangKyBaoVe' || item.FieldName === 'MarkAVG')
	                if (findField) {
	                    this.onLoadOldHoiDong(parseInt(findField.Text_Content))
	                } else {
	                    this.DS_OldHoiDong = []
	                }
	
	                console.log('watch...', val)
	                this.updateFileRules(val)
	
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
	            }
	        },
	        isUpdData: function (val) {
	            if (!val) {
	                this.rootArr = []
	                this.StudentProcList = []
	                this.IsWatchOldData = false
	            }
	
	            if (val) {
	                this.DsNNDauRa = ChungChiNgoaiNgu_NameList()
	                this.DsTenNgoaiNgu = NgoaiNgu_NameList()
	                this.DsOriginalTenNN = NgoaiNgu_NameList()
	                this.DsYesNo = YesNoArray()
	                console.log('is upd dialog true', val)
	                this.onLoadStudentPocess(this.HocVienData.StudentID)
	                    .then(() => {
	                        return this.onLoadSecondRootFlow()
	                    })
	                    .then(() => {
	                        return this.onLoadRootFlow()
	                    })
	                    .catch((error) => {
	                        console.error('Error in API chain:', error)
	                    })
	
	                this.ExistData = this.dsexiststudent.find((item) => item.StudentID === this.HocVienData.StudentID)
	                console.log('ExistData before', this.ExistData)
	                this.ExistData.NgayCap_CCCD = this.ExistData.NgayCap_CCCD ? moment(this.ExistData.NgayCap_CCCD).format('YYYY-MM-DD') : null
	                // this.ExistData.ThoiGianTotNghiep_DaiHoc = this.ExistData.ThoiGianTotNghiep_DaiHoc ? moment(this.ExistData.ThoiGianTotNghiep_DaiHoc).format('YYYY-MM-DD') : null
	                console.log('ExistData after', this.ExistData)
	
	                if (this.ExistData.Loai_NgoaiNgu_DauVao) {
	                    this.DsNNDauRa = this.DsNNDauRa.filter((item) => item.fogrein_type === this.ExistData.Loai_NgoaiNgu_DauVao)
	                    this.DsTenNgoaiNgu = this.DsTenNgoaiNgu.filter((item) => item.value === this.ExistData.Loai_NgoaiNgu_DauVao)
	                }
	            } else {
	                console.log('is upd dialog false', val)
	                vueData.Panel = null
	                this.rootArr = []
	            }
	        },
	        PanelControl: function (val) {
	            this.checkDeTaiFlag = null
	            this.resultKtraDeTai = null
	        },
	        selectProcessData: function (val) {
	            if (val === 1) {
	                this.onLoadChangeTopicRoot()
	            }
	        },
	    },
	    methods: {
	        onPrevent(e) {
	            this.preventNegative(e)
	            this.onlyNumber(e)
	        },
	
	        preventNegative(e) {
	            if (e.key === '-' || e.key === 'e' || e.key === '+') {
	                e.preventDefault()
	            }
	        },
	
	        onlyNumber(e) {
	            if (e.ctrlKey) {
	                const allowCtrlKeys = ['a', 'c', 'v', 'x']
	                if (allowCtrlKeys.includes(e.key.toLowerCase())) return
	            }
	            const allowKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab']
	            if (allowKeys.includes(e.key)) return
	            const value = e.target.value
	            if (/^\d$/.test(e.key)) return
	            if (e.key === ',') {
	                if (value.includes(',')) e.preventDefault()
	                return
	            }
	            e.preventDefault()
	        },
	
	        checkHide() {
	            if (!this.dataDetailFlow || !this.dataDetailFlow.length) return false
	            return this.dataDetailFlow.some((item) => {
	                if (['fileBaiBaoKhoaHoc', 'tenBaiBao', 'tenTapChiHoiThao'].includes(item.FieldName)) {
	                    // Kiểm tra có file, hoặc có chữ nhập vào
	                    const hasText = item.Text_Content !== null && item.Text_Content !== undefined && item.Text_Content !== ''
	                    const hasFile = item.File_ID !== null && item.File_ID !== undefined && item.File_ID !== ''
	                    return hasText || hasFile
	                }
	                return false
	            })
	        },
	        preventNegative(e) {
	            // Chặn các ký tự '-', 'e', '+' và số âm
	            if (e.key === '-' || e.key === 'e' || e.key === '+') {
	                e.preventDefault()
	            }
	        },
	
	        shouldShowDuocOnlyField(itemDes) {
	            if (!itemDes || itemDes.FN_Check !== 'DuocOnly') {
	                return true
	            }
	
	            return this.HocVienData.NganhID.toString() === '106'
	        },
	
	        historyData(item) {
	            console.log('item', item)
	            const findField = this.dataDetailFlow.find((item) => ['HoiDongID', 'fileDangKyBaoVe', 'MarkAVG'].includes(item.FieldName))
	
	            const fieldToStepMap = {
	                HoiDongID: 1, // Hội đồng/Thành viên hội đồng
	                fileDangKyBaoVe: 2, // Đăng ký bảo vệ
	                MarkAVG: 3, // Bảo vệ đề tài
	            }
	
	            this.currentStep = fieldToStepMap[findField?.FieldName] ?? 0
	
	            this.ThongTinBuoc = item
	            vueData.isOldData = true
	        },

	        onSyncFromFailData(item) {
	            const $this = this
	            confirm({
	                title: `Xác nhận đồng bộ toàn bộ hồ sơ (luận văn, bài báo, đơn từ...) từ đợt bảo vệ chưa đạt sang đợt hiện tại cho học viên ${this.HocVienData.StudentID} - ${this.HocVienData.HoSV} ${this.HocVienData.TenSV}?`,
	                action: () => {
	                    ajaxCALL(
	                        '/HoiDong_Fail_Restore',
	                        {
	                            StudentID: $this.HocVienData.StudentID,
	                        },
	                        (res) => {
	                            Vue.$toast.success('Đồng bộ dữ liệu thành công', { position: 'top' })
	                            $this.onLoadDetailFlow(item.Flow_ID, item.Flow_Status, item.Children_Task_ID)
	                            if (typeof CALL === 'function') {
	                                CALL('getStudentList')
	                            }
	                        },
	                        (error) => {
	                            const msg = error && error.responseJSON ? error.responseJSON.Message : error.message
	                            Vue.$toast.error(`Đồng bộ thất bại: ${msg}`, { position: 'top' })
	                        },
	                    )
	                },
	                cancel: () => {},
	            })
	        },
	
	        onLoadOldHoiDong(hoiDongID) {
	            ajaxCALL(
	                '/HoiDong_Old_Get',
	                {
	                    StudentID: this.HocVienData.StudentID,
	                },
	                (res) => {
	                    const allEmpty = res.data.every((arr) => Array.isArray(arr) && arr.length === 0)
	
	                    if (allEmpty) {
	                        this.DS_OldHoiDong = []
	                        this.DS_ThongTinHoiDong = []
	                        this.DS_ThanhVienHoiDong = []
	                        this.DS_DangKyBaoVe = []
	                        this.DS_BaoVe = []
	                        return
	                    }
	
	                    this.DS_OldHoiDong = res.data
	                    this.DS_ThongTinHoiDong = res.data[0]
	                    this.DS_ThanhVienHoiDong = res.data[1]
	                    this.DS_DangKyBaoVe = res.data[2]
	                    this.DS_BaoVe = res.data[3]
	
	                    console.log('this.DS_ThongTinHoiDong', this.DS_ThongTinHoiDong)
	                    console.log('this.DS_ThanhVienHoiDong', this.DS_ThanhVienHoiDong)
	                    console.log('this.DS_DangKyBaoVe', this.DS_DangKyBaoVe)
	                    console.log('this.DS_BaoVe', this.DS_BaoVe)
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('Load old hoi dong fail: ', error)
	                },
	            )
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
	        watchOldData(flowID, FlowStatus, ChildrenTaskID) {
	            this.IsWatchOldData = !this.IsWatchOldData
	
	            this.onLoadDetailFlow(flowID, FlowStatus, ChildrenTaskID)
	        },
	        checkValidGVHD(name) {
	            if (!name) return false
	
	            console.log(
	                'test result',
	                this.HocHamHocViList.some((item) => name.startsWith(item.HocHamHocVi)),
	            )
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
	        validateText(str) {
	            if (str === null || str === undefined || str === '' || str === true || str === false) {
	                return false
	            }
	            // Regex kiểm tra ký tự đầu tiên
	            const lowercaseRegex = /^[a-zàáâãèéêìíòóôõùúăđĩũơỳỷỹýỵ]$/
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
	                if (this.ExistData.NganhID == jsonData[0].NganhID) {
	                    return jsonData[0].File
	                } else {
	                    return jsonData[1].File
	                }
	            } catch (error) {
	                console.log('Không thể parse dataExp sang JSON, trả về dataExp ban đầu.', dataExp)
	                return dataExp
	            }
	        },
	
	        countWords(str) {
	            return str.trim().split(/\s+/).filter(Boolean).length
	        },
	
	        // Hàm này chỉ dùng để gọi ở button
	        async onSave(FLOW_ID, root) {
	            const $this = this
	            let validationPassed = true
	            let hasInvalidText = false
	            let fail = 'None fail'
	
	            // Duyệt qua dataDetailFlow để kiểm tra tính hợp lệ và gán lỗi
	            const validateItem = (item) => {
	                if (item.Task_Detail_Display === 1) {
	                    const validationResult = this.validateText(item.Text_Content)
	                    if (item.UI_Component !== 'SkipCheckUpperCase' && validationResult && validationResult !== 0) {
	                        fail = 'fail at step 1'
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Không được nhập toàn bộ in hoa'
	                        console.log('item fail', item)
	                        console.log('item.InHoaError', item.InHoaError)
	                    } else if (item.UI_Component !== 'SkipCheckUpperCase' && validationResult === 0 && item.Task_Detail_StyleDisplay !== 'email') {
	                        fail = 'fail at step 2'
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Chữ cái đầu tiên phải viết hoa'
	                        console.log('item.InHoaError', item.InHoaError)
	                    } else if ((item.FieldName === 'SoCap_HDYSH' || item.FieldName === 'SoCap_HDYSH_ID') && item.Text_Content && item.Text_Content !== item.Text_Content.toUpperCase()) {
	                        fail = 'fail at step 3'
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Số hội đồng Y Đức phải viết hoa toàn bộ'
	                        console.log('item.InHoaError', item.InHoaError)
	                    } else {
	                        item.isInHoa = false
	                        item.InHoaError = ''
	                    }
	
	                    if (item.FieldName === 'ThesisesProfSuggest1' && item.Text_Content) {
	                        const specialCheck = this.checkSpecialValid(item.Text_Content)
	                        item.isInHoa = !specialCheck.valid
	                        item.InHoaError = specialCheck.message || ''
	
	                        validationPassed = specialCheck.valid
	                    }
	
	                    // Kiểm tra các điều kiện khác
	                    // AllowNull == 0 là không được bỏ trống
	                    if (item.AllowNull === '0' && item.Task_Detail_Type !== 'FILE' && item.Task_Detail_Type !== 'FILEVIEW' && !item.Text_Content && item.Task_Detail_Type !== 'FUN') {
	                        Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập nội dung`, { position: 'top' })
	                        validationPassed = false
	                    }
	
	                    // AllowNull == 0 là không được bỏ trống
	                    if (item.AllowNull === '0' && (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') && !item.File_ID && item.Task_Detail_Type !== 'FUN') {
	                        Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa upload file`, { position: 'top' })
	                        validationPassed = false
	                    }
	
	                    if (item.FN_Check === 'fnCheckLimit' && this.countWords(item.Text_Content) < 120) {
	                        Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập đủ 120 từ`, { position: 'top' })
	                        validationPassed = false
	                    }
	
	                    // Kiểm tra điều kiện bài báo khoa học
	                    if ((item.FieldName === 'namXuatBan' || item.FieldName === 'viTriTacGia') && this.checkHide()) {
	                        if (item.Text_Content === null || item.Text_Content === undefined || item.Text_Content === '') {
	                            Vue.$toast.error(`Phải nhập thông tin tại "${item.Task_Detail_Description}"`, { position: 'top' })
	                            validationPassed = false
	                        }
	                    }
	                }
	            }
	
	            // Thực hiện validate
	            this.dataDetailFlow.filter((ft) => !ft.IsOldProc)
	            console.log('dataDetailFlow xxxxxxx', this.dataDetailFlow)
	            this.dataDetailFlow.forEach((item) => validateItem(item))
	
	            if (!validationPassed) {
	                console.log('Validation failed')
	                return
	            }
	
	            // Nếu có lỗi, hiển thị thông báo và dừng lại
	            if (hasInvalidText) {
	                console.log('fail', fail)
	                Vue.$toast.error(`Cập nhật thất bại do lỗi viết in hoa`, { position: 'top' })
	                return
	            }
	
	            // 1. Chỉ lọc ra các item thực sự có thay đổi so với initialDetailFlow
	            const changedItems = this.dataDetailFlow.filter((currentItem) => {
	                const initialItem = (this.initialDetailFlow || []).find((item) => {
	                    if (currentItem.Flow_Detail_ID && item.Flow_Detail_ID) {
	                        return item.Flow_Detail_ID === currentItem.Flow_Detail_ID
	                    }
	                    return item.Task_Detail_ID === currentItem.Task_Detail_ID
	                })
	                if (!initialItem) return true

	                const curText = currentItem.Text_Content != null ? String(currentItem.Text_Content).trim() : ''
	                const initText = initialItem.Text_Content != null ? String(initialItem.Text_Content).trim() : ''
	                const textChanged = curText !== initText

	                const curFileId = currentItem.File_ID != null ? String(currentItem.File_ID).trim() : ''
	                const initFileId = initialItem.File_ID != null ? String(initialItem.File_ID).trim() : ''
	                const fileChanged = curFileId !== initFileId

	                return textChanged || fileChanged
	            })

	            if (changedItems.length === 0) {
	                Vue.$toast.info('Không có thay đổi nào cần lưu', { position: 'top' })
	                return
	            }

	            // 2. Chỉ gọi API tuần tự cho đúng những item có thay đổi
	            let hasSaveError = false
	            for (const item of changedItems) {
	                try {
	                    await new Promise((resolve, reject) => {
	                        ajaxCALL(
	                            '/FlowDetail_UpdateData',
	                            {
	                                Student_ID: (this.rootArr && this.rootArr[0]?.STUDENT_ID) || this.HocVienData?.StudentID || this.student_id,
	                                Process_ID: root.PROCESS_ID || root.Process_ID,
	                                Flow_ID: item.Flow_ID,
	                                Task_ID: item.Task_ID,
	                                Task_Detail_ID: item.Task_Detail_ID,
	                                Flow_Detail_ID: item.Flow_Detail_ID,
	                                Text_Content: item.Task_Detail_Type === 'CHECKBOX'
	                                    ? (item.Text_Content ? 'True' : 'false')
	                                    : (item.Text_Content && typeof item.Text_Content === 'string' ? item.Text_Content.trim() : item.Text_Content),
	                                File_Name: item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW' ? (item.File_Name ?? null) : null,
	                                File_Type: item.File_Type ?? null,
	                                File_URL: item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW' ? (item.File_URL ?? null) : null,
	                                File_ID: item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW' ? (item.File_ID ?? null) : null,
	                            },
	                            () => resolve('success'),
	                            (error) => {
	                                Vue.$toast.error(`${error?.responseJSON?.Message || 'Lỗi cập nhật'}`, { position: 'top' })
	                                reject('fail')
	                            },
	                        )
	                    })
	                } catch (err) {
	                    hasSaveError = true
	                    break
	                }
	            }

	            if (hasSaveError) {
	                Vue.$toast.error(`Cập nhật ${root.TASK_NAME} thất bại`, { position: 'top' })
	            } else {
	                // 3. Xóa các file cũ đã bị thay thế trên server (dọn file rác)
	                const oldFileIds = []
	                for (const currentItem of changedItems) {
	                    const initialItem = (this.initialDetailFlow || []).find((item) => {
	                        if (currentItem.Flow_Detail_ID && item.Flow_Detail_ID) {
	                            return item.Flow_Detail_ID === currentItem.Flow_Detail_ID
	                        }
	                        return item.Task_Detail_ID === currentItem.Task_Detail_ID
	                    })
	                    if (initialItem && ['FILE', 'FILEVIEW'].includes(currentItem.Task_Detail_Type)) {
	                        if (initialItem.File_ID && currentItem.File_ID !== initialItem.File_ID) {
	                            oldFileIds.push(initialItem.File_ID)
	                        }
	                    }
	                }
	                if (oldFileIds.length > 0) {
	                    try {
	                        await new Promise((res) => {
	                            ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: oldFileIds.join(',') }, () => res(), () => res())
	                        })
	                    } catch (e) {
	                        console.error('Lỗi xóa các file cũ bị thay thế:', e)
	                    }
	                }

	                Vue.$toast.success(`Cập nhật ${root.TASK_NAME || root.Task_Name || ''} thành công`, { position: 'top' })

	                const flowId = root.Flow_ID || root.FLOW_ID || FLOW_ID
	                const flowStatus = root.Flow_Status || root.FLOW_STATUS
	                const childrenTaskId = root.Children_Task_ID || root.CHILDREN_TASK_ID

	                // 1 - Làm luận văn
	                if ($this.processActionData === 1) {
	                    $this.onLoadRootFlow()
	                    $this.onLoadDetailFlow(flowId, flowStatus, childrenTaskId)
	                    // 2 - Đổi đề tài
	                } else if ($this.processActionData === 2) {
	                    $this.onLoadChangeRootFlow($this.selectedChangeProcessID)
	                    $this.onLoadDetailFlow(flowId, flowStatus, childrenTaskId)
	                }
	            }
	        },
	        //  undo từ success sang processing (không được xóa)
	        unCheckAll(detail, root, flowID) {
	            const $this = this
	
	            return new Promise((resolve, reject) => {
	                let promises = detail
	                    .filter((ft) => !ft.IsOldProc)
	                    .map((item, index) => {
	                        return new Promise((innerResolve, innerReject) => {
	                            setTimeout(
	                                () => {
	                                    ajaxCALL(
	                                        '/FlowDetail_UpdateStatus',
	                                        {
	                                            Student_ID: $this.HocVienData.StudentID,
	                                            Process_ID: root.PROCESS_ID,
	                                            Flow_Detail_Status: 'P',
	                                        },
	                                        (res) => {
	                                            // item.Flow_Detail_Status = true;
	                                            innerResolve('success')
	                                        },
	                                        (error) => {
	                                            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                                            innerReject('fail')
	                                        },
	                                    )
	                                },
	                                500 * (index + 1),
	                            )
	                        })
	                    })

	                Promise.allSettled(promises)
	                    .then((results) => {
	                        const allSuccessful = results.every((result) => result.status === 'fulfilled')
	                        console.log('results', results)
	                        Vue.$toast.success(`Hủy duyệt thành công`, { position: 'top' })
	                        this.onLoadRootFlow()
	                    })
	                    .catch((err) => {
	                        reject('error')
	                    })
	            })
	        },

	        validateFlowDetail(detailList) {
	            let validationPassed = true
	            let hasInvalidText = false

	            const validateItem = (item) => {
	                if (item.Task_Detail_Display === 1) {
	                    const validationResult = this.validateText(item.Text_Content)

	                    if (item.UI_Component !== 'SkipCheckUpperCase' && validationResult && validationResult !== 0) {
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Không được nhập toàn bộ in hoa'
	                    } else if (item.UI_Component !== 'SkipCheckUpperCase' && validationResult === 0 && item.Task_Detail_StyleDisplay !== 'email') {
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Chữ cái đầu tiên phải viết hoa'
	                    } else if ((item.FieldName === 'SoCap_HDYSH' || item.FieldName === 'SoCap_HDYSH_ID') && item.Text_Content &&
	                        item.Text_Content !== item.Text_Content.toUpperCase()) {
	                        hasInvalidText = true
	                        item.isInHoa = true
	                        item.InHoaError = 'Số hội đồng Y Đức phải viết hoa toàn bộ'
	                    } else {
	                        item.isInHoa = false
	                        item.InHoaError = ''
	                    }

	                    if (item.FieldName === 'ThesisesProfSuggest1') {
	                        const specialCheck = this.checkSpecialValid(item.Text_Content)
	                        item.isInHoa = !specialCheck.valid
	                        item.InHoaError = specialCheck.message || ''

	                        validationPassed = specialCheck.valid
	                    }

	                    // Kiểm tra các điều kiện khác
	                    // AllowNull == 0 là không được bỏ trống
	                    if (item.AllowNull === '0' && item.Task_Detail_Type !== 'FILE' && item.Task_Detail_Type !== 'FILEVIEW' && !item.Text_Content && item.Task_Detail_Type !== 'FUN') {
	                        Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập nội dung`, { position: 'top' })
	                        validationPassed = false
	                    }

	                    // AllowNull == 0 là không được bỏ trống
	                    if (item.AllowNull === '0' && (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') && !item.File_ID && item.Task_Detail_Type !== 'FUN') {
	                        Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa upload file`, { position: 'top' })
	                        validationPassed = false
	                    }

	                    if (item.FN_Check === 'fnCheckLimit' && this.countWords(item.Text_Content) < 120) {
	                        Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập đủ 120 từ`, { position: 'top' })
	                        validationPassed = false
	                    }

	                    // Kiểm tra điều kiện bài báo khoa học
	                    if ((item.FieldName === 'namXuatBan' || item.FieldName === 'viTriTacGia') && this.checkHide()) {
	                        if (item.Text_Content === null || item.Text_Content === undefined || item.Text_Content === '') {
	                            Vue.$toast.error(`Phải nhập thông tin Năm xuất bản và Vị trí tác giả tại "${item.Task_Detail_Description}"`, { position: 'top' })
	                            validationPassed = false
	                        }
	                    }
	                }
	            }

	            const activeDetails = (detailList || []).filter((ft) => !ft.IsOldProc)
	            activeDetails.forEach((item) => validateItem(item))

	            if (!validationPassed) {
	                return false
	            }

	            if (hasInvalidText) {
	                Vue.$toast.error(`Cập nhật thất bại do lỗi viết in hoa`, { position: 'top' })
	                return false
	            }

	            return true
	        },

	        async saveCheck(FLOW_ID, root) {
	            return this.validateFlowDetail(this.dataDetailFlow)
	        },

	        async onCheckButNotSave(detail, root, flowID) {
	            const $this = this
	            const isSpecialCase =
	                this.ExistData?.NganhID == '102' ||
	                (this.ExistData?.NganhID == '106' && ['23CP911', '23CP912', '23CP913'].includes(this.ExistData?.LopID))

	            const processID = $this.processActionData === 1 ? (isSpecialCase ? 4 : (root.PROCESS_ID || 1)) : root.PROCESS_ID
	            const studentId = (this.rootArr && this.rootArr[0]?.STUDENT_ID) || this.HocVienData?.StudentID || this.student_id
	            const taskId = root.Children_Task_ID || root.TASK_ID || root.Task_ID || (detail && detail[0] && detail[0].Task_ID)

	            const activeDetails = (detail || this.dataDetailFlow || [])
	                .filter((ft) => !ft.IsOldProc)
	                .map((item) => ({
	                    Task_Detail_ID: item.Task_Detail_ID,
	                    Flow_Detail_Status: 'C',
	                }))

	            try {
	                const res = await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
	                    Student_ID: studentId,
	                    Process_ID: processID,
	                    Flow_ID: flowID,
	                    Task_ID: taskId,
	                    JsonDetails: JSON.stringify(activeDetails),
	                    IsApproveAll: 1,
	                })

	                if (res !== null) {
	                    Vue.$toast.success('Duyệt thành công', { position: 'top' })

	                    const itemDeTai = (detail || $this.dataDetailFlow || []).find((d) => d.Task_Detail_ID === 46)
	                    if (itemDeTai && itemDeTai.Text_Content) {
	                        $this.onLinkTenDeTaiBaoVe(itemDeTai.Text_Content)
	                    }

	                    const lastIndex = $this.dataDetailFlow.length - 1 >= 0 ? $this.dataDetailFlow.length - 1 : 0
	                    if ($this.dataDetailFlow[lastIndex] && $this.dataDetailFlow[lastIndex].FN_Check === 'fnLastProcess') {
	                        ajaxCALL(
	                            '/LuanVan_HoanThanh',
	                            {
	                                StudentID: $this.dataDetailFlow[lastIndex].Student_id || studentId,
	                            },
	                            () => {},
	                            (error) => {
	                                Vue.$toast.error(`${error?.responseJSON?.Message || 'Lỗi hoàn thành'}`, { position: 'top' })
	                            },
	                        )
	                    }

	                    if ($this.processActionData === 1) {
	                        $this.onLoadRootFlow()
	                    } else if ($this.processActionData === 2) {
	                        $this.onLoadChangeRootFlow($this.selectedChangeProcessID)
	                    }
	                }
	            } catch (error) {
	                Vue.$toast.error('Duyệt thất bại', { position: 'top' })
	            }
	        },

	        async saveAndCheckAll(detail, root, flowID) {
	            const $this = this

	            // 1. Kiểm tra tính hợp lệ của form
	            if (!this.validateFlowDetail(this.dataDetailFlow)) {
	                return
	            }

	            // 2. Xác định tham số
	            const isSpecialCase =
	                this.ExistData?.NganhID == '102' ||
	                (this.ExistData?.NganhID == '106' && ['23CP911', '23CP912', '23CP913'].includes(this.ExistData?.LopID))

	            const processID = $this.processActionData === 1 ? (isSpecialCase ? 4 : (root.PROCESS_ID || 1)) : root.PROCESS_ID
	            const studentId = (this.rootArr && this.rootArr[0]?.STUDENT_ID) || this.HocVienData?.StudentID || this.student_id
	            const taskId = root.Children_Task_ID || root.TASK_ID || root.Task_ID || (detail && detail[0] && detail[0].Task_ID)

	            // 3. Chuẩn bị payload JsonDetails gom dữ liệu và trạng thái 'C'
	            const activeDetails = (detail || this.dataDetailFlow || [])
	                .filter((ft) => !ft.IsOldProc)
	                .map((item) => ({
	                    Task_Detail_ID: item.Task_Detail_ID,
	                    Text_Content:
	                        item.Text_Content && typeof item.Text_Content === 'string'
	                            ? item.Text_Content.trim()
	                            : typeof item.Text_Content === 'boolean'
	                              ? (item.Text_Content ? 'True' : 'False')
	                              : item.Text_Content,
	                    File_ID: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_ID ?? null) : null,
	                    File_Name: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Name ?? null) : null,
	                    File_Type: item.File_Type ?? null,
	                    File_URL: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_URL ?? null) : null,
	                    Flow_Detail_Status: 'C',
	                }))

	            try {
	                // 4. Gọi 1 API duy nhất FlowDetail_UpdateMulti thay thế toàn bộ foreach
	                const res = await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
	                    Student_ID: studentId,
	                    Process_ID: processID,
	                    Flow_ID: flowID,
	                    Task_ID: taskId,
	                    JsonDetails: JSON.stringify(activeDetails),
	                    IsApproveAll: 1,
	                })

	                if (res !== null) {
	                    Vue.$toast.success('Duyệt thành công', { position: 'top' })

	                    // Liên kết tên đề tài bảo vệ nếu có Task_Detail_ID === 46
	                    const itemDeTai = activeDetails.find((d) => d.Task_Detail_ID === 46)
	                    if (itemDeTai && itemDeTai.Text_Content) {
	                        $this.onLinkTenDeTaiBaoVe(itemDeTai.Text_Content)
	                    }

	                    // Hoàn thành luận văn nếu là bước cuối
	                    const lastIndex = $this.dataDetailFlow.length - 1 >= 0 ? $this.dataDetailFlow.length - 1 : 0
	                    if ($this.dataDetailFlow[lastIndex] && $this.dataDetailFlow[lastIndex].FN_Check === 'fnLastProcess') {
	                        ajaxCALL(
	                            '/LuanVan_HoanThanh',
	                            {
	                                StudentID: $this.dataDetailFlow[lastIndex].Student_id || studentId,
	                            },
	                            () => {},
	                            (error) => {
	                                Vue.$toast.error(`${error?.responseJSON?.Message || 'Lỗi hoàn thành'}`, { position: 'top' })
	                            },
	                        )
	                    }

	                    // Tải lại tiến trình
	                    if ($this.processActionData === 1) {
	                        $this.onLoadRootFlow()
	                    } else if ($this.processActionData === 2) {
	                        $this.onLoadChangeRootFlow($this.selectedChangeProcessID)
	                    }
	                }
	            } catch (error) {
	                Vue.$toast.error('Duyệt thất bại', { position: 'top' })
	            }
	        },
	
	        onLinkTenDeTaiBaoVe(tenDeTai) {
	            console.log('link thesis!!!!')
	            const $this = this
	
	            ajaxCALL(
	                '/FlowDetail_Update_TenDeTai',
	                {
	                    StudentID: $this.HocVienData.StudentID,
	                    Text_Content: tenDeTai && typeof tenDeTai === 'string' ? tenDeTai.trim() : tenDeTai,
	                },
	                (res) => {
	                    console.log('Update status success')
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                },
	            )
	
	            // Children_Task_ID 4 là Đăng ký bảo vệ luận văn Thạc sĩ
	            // const rootBaoVeLuanVan = this.rootArr.find((item) => item.Children_Task_ID === 4)
	            // let BaoVeDeTai
	            // console.log('rootBaoVeLuanVan', rootBaoVeLuanVan)
	
	            // if (!rootBaoVeLuanVan) {
	            // 	Vue.$toast.error(`Không tìm thấy root Đăng ký bảo vệ Luận văn Thạc sĩ`, { position: 'top' })
	            // 	return
	            // }
	
	            // ajaxCALL(
	            // 	'/SDH_Get_FlowDetail',
	            // 	{ Flow_ID: rootBaoVeLuanVan.Flow_ID },
	            // 	(res) => {
	            // 		// item.Task_Detail_ID === 119 là Tên đề tài bảo vệ
	            // 		BaoVeDeTai = res.data.filter((item) => item.Task_Detail_Display === 1).find((item) => item.Task_Detail_ID === 119)
	
	            // 		if (!BaoVeDeTai) {
	            // 			Vue.$toast.error(`Không tìm thấy bước Nhập tên đề tài bảo vệ`, { position: 'top' })
	            // 			return
	            // 		}
	
	            // 		let apiName
	
	            // 		if (vueData.user.SystemRight === 1) {
	            // 			apiName = '/FlowDetail_Update_Allowed_Data'
	            // 		} else {
	            // 			apiName = '/FlowDetail_UpdateData'
	            // 		}
	
	            // 		// item.Task_Detail_ID === 46 là Tên đề tài chính thức
	            // 		ajaxCALL(
	            // 			apiName,
	            // 			{
	            // 				Student_ID: $this.HocVienData.StudentID,
	            // 				Process_ID: rootBaoVeLuanVan.PROCESS_ID,
	            // 				Flow_ID: BaoVeDeTai.Flow_ID,
	            // 				Task_ID: BaoVeDeTai.Task_ID,
	            // 				Task_Detail_ID: BaoVeDeTai.Task_Detail_ID, // Task_Detail_ID 119 là Tên đề tài bảo vệ (Bước 5)
	            // 				Text_Content: tenDeTai && typeof tenDeTai === 'string' ? tenDeTai.trim() : tenDeTai,
	            // 				File_Name: ['FILE', 'FILEVIEW'].includes(BaoVeDeTai.Task_Detail_Type) ? (BaoVeDeTai.File_Name ?? null) : null,
	            // 				File_Type: ['FILE', 'FILEVIEW'].includes(BaoVeDeTai.Task_Detail_Type) ? (BaoVeDeTai.File_Type ?? null) : null,
	            // 				File_URL: ['FILE', 'FILEVIEW'].includes(BaoVeDeTai.Task_Detail_Type) ? (BaoVeDeTai.File_URL ?? null) : null,
	            // 				File_ID: ['FILE', 'FILEVIEW'].includes(BaoVeDeTai.Task_Detail_Type) ? (BaoVeDeTai.File_ID ?? null) : null,
	            // 			},
	            // 			(res) => {
	            // 				console.log('Update status success')
	            // 			},
	            // 			(error) => {
	            // 				Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	            // 			},
	            // 		)
	            // 	},
	            // 	(error) => {
	            // 		Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	            // 		console.log('Error: ', error)
	            // 	},
	            // )
	        },
	
	        confirmBox() {
	            // Kiểm tra nếu quy trình đổi trước đó chưa hoàn thành (chưa complete) thì không cho phép tạo mới
	            if (this.changDataArr && this.changDataArr.length > 0) {
	                const latestProc = this.changDataArr[0]
	                if ((latestProc.use_yn === true || latestProc.use_yn === 1) && latestProc.Process_Student_Status !== 'C') {
	                    Vue.$toast.warning('Quy trình đổi/điều chỉnh trước đó chưa hoàn tất (chưa duyệt hoàn thành). Không thể tạo quy trình đổi mới.', { position: 'top' })
	                    return
	                }
	            }

	            confirm({
	                title: 'Bạn có muốn tạo mới thủ tục đổi/điều chỉnh đề tài/GVHD không?',
	                action: () => {
	                    this.onProcessStudent()
	                    vueData.Panel = null
	                    vueData.isUpdTask = false
	                },
	                cancel: function () {
	                    // window.location.href = "https://qldetaisdh.lhu.edu.vn/my-thesis";
	                }.bind(this),
	            })
	        },
	
	        onProcessStudent() {
	            // Dữ liệu tham khảo
	            // const processAction =
	            //     this.HocVienData.NganhID == '102' ||
	            //     (this.HocVienData.NganhID == '106' && (this.HocVienData.LopID === '23CP911' || this.HocVienData.LopID === '23CP912' || this.HocVienData.LopID === '23CP913'))
	            //         ? 4
	            //         : 1
	            const expireDate = new Date().getFullYear().toString() + '-12-12'
	            const insertNew = 0
	
	            ajaxCALL(
	                '/Process_Student_Ins',
	                {
	                    // Action 2 là đổi đề tài
	                    Process_Action: 2,
	                    Student_ID: this.HocVienData.StudentID,
	                    Expire_Date: expireDate,
	                    insert_new: insertNew,
	                },
	                () => {
	                    Vue.$toast.success(`Tạo mới quy trình đổi/điều chỉnh đề tài/GVHD thành công`, { position: 'top' })
	                    console.log('Tạo mới quy trình đổi/điều chỉnh đề tài/GVHD thành công')
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('Fail to Process_Student_Ins', error)
	                },
	            )
	        },
	
	        onLoadChangeTopicRoot() {
	            const $this = this
	            console.log('this.HocVienData xxxxxx', this.HocVienData)
	            if ($this.student_id.length > 0) {
	                ajaxCALL(
	                    '/Get_RootFlow',
	                    {
	                        StudentID: this.HocVienData.StudentID,
	                        Process_Action: 2,
	                    },
	                    (res) => {
	                        this.DS_RootProcess = res.data
	                        console.log('this.DS_RootProcess', this.DS_RootProcess)
	                    },
	                    (error) => {
	                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                        console.log('Error: ', error)
	                    },
	                )
	            }
	        },
	
	        onLoadChangeRootFlow(targetProcessStuID) {
	            const $this = this
	            ajaxCALL(
	                '/Student_Process_Change_Get',
	                {
	                    Student_ID: this.HocVienData.StudentID,
	                    // 2 là đổi đề tài
	                    Process_Action: 2,
	                },
	                (res) => {
	                    $this.changDataArr = res.data || []
	                    console.log('changeData 1', $this.changDataArr)

	                    if ($this.changDataArr.length > 0) {
	                        if (targetProcessStuID && $this.changDataArr.some((c) => c.Process_Student_ID === targetProcessStuID)) {
	                            $this.selectedChangeProcessID = targetProcessStuID
	                        } else if (!$this.selectedChangeProcessID || !$this.changDataArr.some((c) => c.Process_Student_ID === $this.selectedChangeProcessID)) {
	                            $this.selectedChangeProcessID = $this.changDataArr[0].Process_Student_ID
	                        }

	                        $this.loadRootFlowByChangeProcess($this.selectedChangeProcessID)
	                    } else {
	                        $this.rootArr = []
	                        $this.selectedChangeProcessID = null
	                        Vue.$toast.error(`Không có dữ liệu về quy trình đổi đề tài`, { position: 'top' })
	                    }
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('Error: ', error)
	                },
	            )
	        },

	        onChangeSelectedChangeProcess(val) {
	            vueData.Panel = null
	            this.dataDetailFlow = []
	            this.initialDetailFlow = []
	            this.loadRootFlowByChangeProcess(val)
	        },

	        loadRootFlowByChangeProcess(processStudentID) {
	            const $this = this
	            ajaxCALL(
	                '/Get_RootFlow',
	                {
	                    StudentID: this.HocVienData.StudentID,
	                    Process_Student_ID: processStudentID,
	                    // 2 là đổi đề tài
	                    Process_Tree: 2,
	                },
	                (res) => {
	                    $this.rootArr = res.data || []
	                    console.log('root arr', $this.rootArr)
	                },
	                (error) => {
	                    Vue.$toast.error(`${error?.responseJSON?.Message || 'Lỗi tải các bước'}`, { position: 'top' })
	                    console.log('error to load change root flow', error)
	                },
	            )
	        },
	
	        getDecisionTitleForChange(changeItem) {
	            if (!changeItem) {
	                return {
	                    file: 'File Quyết định đổi/điều chỉnh đề tài',
	                    no: 'Số quyết định đổi/điều chỉnh đề tài',
	                }
	            }
	            if (changeItem.Description_QD_File && changeItem.Description_QD_No) {
	                return {
	                    file: changeItem.Description_QD_File,
	                    no: changeItem.Description_QD_No,
	                }
	            }
	            const loai = parseInt(changeItem.LoaiDieuChinh)
	            if (loai === 1) {
	                return {
	                    file: 'File Quyết định đổi/điều chỉnh tên đề tài',
	                    no: 'Số quyết định đổi/điều chỉnh tên đề tài',
	                }
	            } else if (loai === 2) {
	                return {
	                    file: 'File Quyết định thay đổi GVHD',
	                    no: 'Số quyết định thay đổi GVHD',
	                }
	            } else if (loai === 3) {
	                return {
	                    file: 'File Quyết định đổi tên đề tài và thay đổi GVHD',
	                    no: 'Số quyết định đổi tên đề tài và thay đổi GVHD',
	                }
	            }

	            const hasOldThesis = this.studentChangeType?.hasOldThesis
	            const hasOldProf = this.studentChangeType?.hasOldProf

	            if (hasOldThesis && !hasOldProf) {
	                return {
	                    file: 'File Quyết định đổi/điều chỉnh tên đề tài',
	                    no: 'Số quyết định đổi/điều chỉnh tên đề tài',
	                }
	            } else if (!hasOldThesis && hasOldProf) {
	                return {
	                    file: 'File Quyết định thay đổi GVHD',
	                    no: 'Số quyết định thay đổi GVHD',
	                }
	            } else if (hasOldThesis && hasOldProf) {
	                return {
	                    file: 'File Quyết định đổi tên đề tài và thay đổi GVHD',
	                    no: 'Số quyết định đổi tên đề tài và thay đổi GVHD',
	                }
	            }

	            return {
	                file: 'File Quyết định đổi/điều chỉnh đề tài',
	                no: 'Số quyết định đổi/điều chỉnh đề tài',
	            }
	        },

	        async checkStudentChangeType() {
	            this.studentChangeType = {
	                hasOldThesis: false,
	                hasOldProf: false,
	                hasOldQD: false,
	            }
	            this.studentChangeHistory = []
	            if (!this.HocVienData?.StudentID) return

	            try {
	                await new Promise((resolve) => {
	                    ajaxCALL(
	                        '/Student_Change_History_Get',
	                        { Student_ID: this.HocVienData.StudentID },
	                        (res) => {
	                            this.studentChangeHistory = res.data || []
	                            resolve()
	                        },
	                        () => resolve()
	                    )
	                })
	            } catch (e) {
	                console.log('Error loading student change history:', e)
	            }

	            if (this.studentChangeHistory.length > 0) {
	                const hasOldThesis = this.studentChangeHistory.some((item) => {
	                    const loai = parseInt(item.LoaiDieuChinh)
	                    return loai === 1 || loai === 3
	                })
	                const hasOldProf = this.studentChangeHistory.some((item) => {
	                    const loai = parseInt(item.LoaiDieuChinh)
	                    return loai === 2 || loai === 3 || (!loai && (item.ThesisesProf1New || item.ThesisesProf2New))
	                })
	                this.studentChangeType = {
	                    hasOldThesis,
	                    hasOldProf,
	                    hasOldQD: true,
	                }
	            }
	            console.log('Detected studentChangeType:', this.studentChangeType, 'studentChangeHistory:', this.studentChangeHistory)
	        },

	        onLoadRootFlow() {
	            console.log('xxxxxxxxxxxxxx', this.SecondRootFlow)
	            const firstProcStudentID = this.StudentProcList.length > 0 ? this.StudentProcList[0].Process_Student_ID : 0
	            ajaxCALL(
	                '/Get_RootFlow',
	                {
	                    StudentID: this.HocVienData.StudentID,
	                    Process_Student_ID: firstProcStudentID,
	                    // 1 là làm luận văn
	                    Process_Tree: 1,
	                },
	                (res) => {
	                    this.rootArr = res.data
	                    console.log('root arr', this.rootArr)
	                    this.checkStudentChangeType()
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('error to load NDV detail', error.responseJSON.Message)
	                },
	            )
	        },

	        onLoadSecondRootFlow() {
	            return new Promise((resolve, reject) => {
	                const lastProcStudentID = this.StudentProcList.length > 0 ? this.StudentProcList[this.StudentProcList.length - 1].Process_Student_ID : 0
	
	                ajaxCALL(
	                    '/Get_RootFlow',
	                    {
	                        StudentID: this.HocVienData.StudentID,
	                        Process_Student_ID: lastProcStudentID,
	                        Process_Tree: 1,
	                    },
	                    (res) => {
	                        this.SecondRootFlow = res.data
	                        console.log('SecondRootFlow', this.SecondRootFlow)
	                        resolve() // Gọi resolve khi API hoàn thành
	                    },
	                    (error) => {
	                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                        console.log('error to load NDV detail', error.responseJSON.Message)
	                        reject(error) // Gọi reject khi API lỗi
	                    },
	                )
	            })
	        },
	
	        onLoadStudentPocess(studentId) {
	            return new Promise((resolve, reject) => {
	                ajaxCALL(
	                    '/Student_Process_Get',
	                    {
	                        Student_ID: studentId,
	                        IsFull: 0, // 0: Lấy TOP 2; 1: Lấy tất cả
	                    },
	                    (res) => {
	                        this.StudentProcList = res.data
	                        console.log('this.StudentProcList', this.StudentProcList)
	                        resolve() // Gọi resolve khi API hoàn thành
	                    },
	                    (error) => {
	                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                        console.log('error to load student process', error.responseJSON.Message)
	                        reject(error) // Gọi reject khi API lỗi
	                    },
	                )
	            })
	        },
	
	        async onLoadDetailFlow(FLOW_ID, root, childrenTaskID) {
	            const $this = this
	            let secondFlowDetail = []
	
	            // Hàm gọi API trả về Promise lấy dữ liệu cũ (use_yn = 0) chỉ áp dụng cho Quy trình chính (processActionData === 1)
	            const getSecondFlowDetail = () => {
	                return new Promise((resolve) => {
	                    if ($this.processActionData !== 1) {
	                        secondFlowDetail = []
	                        $this.hasOldData = false
	                        resolve([])
	                        return
	                    }

	                    const flowIdsToFetch = [FLOW_ID]
	                    if ($this.SecondRootFlow && $this.SecondRootFlow.length > 0) {
	                        const flowPosition = $this.SecondRootFlow.find((item) => item.Children_Task_ID === childrenTaskID)
	                        if (flowPosition && flowPosition.Flow_ID && !flowIdsToFetch.includes(flowPosition.Flow_ID)) {
	                            flowIdsToFetch.push(flowPosition.Flow_ID)
	                        }
	                    }

	                    const fetchPromises = flowIdsToFetch.map((fId) => {
	                        return new Promise((innerResolve) => {
	                            ajaxCALL(
	                                '/Get_FlowDetail_OldTree',
	                                { Flow_ID: fId },
	                                (res) => {
	                                    const data = (res.data || []).map((item) => ({
	                                        ...item,
	                                        IsOldProc: true,
	                                    }))
	                                    innerResolve(data)
	                                },
	                                (error) => {
	                                    console.log('Error to load old flow detail: ', error)
	                                    innerResolve([])
	                                }
	                            )
	                        })
	                    })

	                    Promise.all(fetchPromises).then((results) => {
	                        secondFlowDetail = results.flat()
	                        $this.hasOldData = secondFlowDetail.length > 0
	                        resolve(secondFlowDetail)
	                    })
	                })
	            }
	
	            try {
	                // Chờ API đầu tiên hoàn tất trước khi gọi API thứ hai
	                await getSecondFlowDetail()
	                console.log('secondFlowDetail', secondFlowDetail)

	                const hasOldThesis = this.studentChangeType?.hasOldThesis || secondFlowDetail.some((sf) => [46, 56, 59, 111, 119].includes(sf.Task_Detail_ID))
	                const hasOldProf = this.studentChangeType?.hasOldProf || secondFlowDetail.some((sf) => [47, 57, 60, 112, 55, 62].includes(sf.Task_Detail_ID))
	                const hasAnyOldChange = hasOldThesis || hasOldProf || this.studentChangeType?.hasOldQD || secondFlowDetail.length > 0

	                let qdFileTitle = 'File Quyết định Giao đề tài'
	                let qdNoTitle = 'Số quyết định duyệt'
	                if (this.studentChangeHistory && this.studentChangeHistory.length > 0) {
	                    const lastChange = this.studentChangeHistory[this.studentChangeHistory.length - 1]
	                    const titleObj = this.getDecisionTitleForChange(lastChange)
	                    qdFileTitle = titleObj.file
	                    qdNoTitle = titleObj.no
	                } else if (hasAnyOldChange) {
	                    if (hasOldThesis && !hasOldProf) {
	                        qdFileTitle = 'File Quyết định đổi/điều chỉnh tên đề tài'
	                        qdNoTitle = 'Số quyết định đổi/điều chỉnh tên đề tài'
	                    } else if (!hasOldThesis && hasOldProf) {
	                        qdFileTitle = 'File Quyết định thay đổi GVHD'
	                        qdNoTitle = 'Số quyết định thay đổi GVHD'
	                    } else if (hasOldThesis && hasOldProf) {
	                        qdFileTitle = 'File Quyết định đổi tên đề tài và thay đổi GVHD'
	                        qdNoTitle = 'Số quyết định đổi tên đề tài và thay đổi GVHD'
	                    }
	                }

	                const taskDescriptionMap = {
	                    ThesisName: hasOldThesis ? 'Nhập tên đề tài đổi/điều chỉnh Chính Thức (Không đổi)' : 'Nhập tên đề tài Chính Thức (Không đổi)',
	                    ThesisNameDefend: hasOldThesis ? 'Tên đề tài đổi/điều chỉnh bảo vệ' : 'Tên đề tài bảo vệ',
	                    ThesisConfirm: qdFileTitle,
	                    ThesisConfirmNo: qdNoTitle,
	                }

	                const taskDescript = (item) => {
	                    if (hasAnyOldChange && taskDescriptionMap[item.FieldName]) {
	                        return taskDescriptionMap[item.FieldName]
	                    }
	                    return item.Task_Detail_Description
	                }
	
	                const TCQLD_NganhID = this.ExistData?.NganhID
	
	                // Gọi API thứ hai sau khi API đầu tiên xong
	                ajaxCALL(
	                    '/SDH_Get_FlowDetail',
	                    { Flow_ID: FLOW_ID },
	                    async (res) => {
	                        let filterarr = res.data
	                            // .filter((item) => {
	                            //     if (TCQLD_NganhID !== Duoc_NganhID) {
	                            //         return item.FN_Check !== 'DuocOnly'
	                            //     }
	                            //     return true
	                            // })
	                            .map(async (item) => {
	                                if (root !== 'C' && item.Task_Detail_Type === 'TEXTAREA | FUN' && item.FN_Check === 'fnCheckTenDeTai' && item.Text_Content) {
	                                    checkTopicBtn(item.Text_Content)
	                                }
	
	                                if (root !== 'C' && item.FN_Check === 'fnCheckHocPhi(StudentID)' && item.Task_Detail_Type === 'FUN') {
	                                    let ttnhp = await $this.checkHocPhi($this.student_id)
	
	                                    return {
	                                        ...item,
	                                        FILE_UPLOAD: null,
	                                        TinhTrangNoHocPhi: ttnhp,
	                                        DataArray: [],
	                                    }
	                                }
	
	                                return {
	                                    ...item,
	                                    FILE_UPLOAD: null,
	                                    TinhTrangNoHocPhi: 0,
	                                    DataArray: [],
	                                }
	                            })
	
	                        Promise.all(filterarr).then(async (res) => {
	                            const processDataDetailFlow = (data) => {
	                                return data.map((item, index) => ({
	                                    ...item,
	                                    isInHoa: false,
	                                    InHoaError: '',
	                                    IsOldProc: false,
	                                    STT: index + 1,
	                                    Text_Content:
	                                        item.Task_Detail_Type === 'CHECKBOX'
	                                            ? String(item.Text_Content).toLowerCase() === 'true'
	                                            : item.FieldName === 'QDThanhLapHoiDong_ThoiGian' && item.Text_Content
	                                                ? moment(item.Text_Content).format('DD/MM/YYYY')
	                                                : item.Task_Detail_Type === 'DIEM'
	                                                    ? item.Text_Content
	                                                        ? parseFloat(item.Text_Content).toFixed(2)
	                                                        : null
	                                                    : item.Text_Content,
	                                    UI_Component: item.UI_Component,
	                                    Task_Detail_Description: taskDescript(item),
	                                }))
	                            }
	
	                            $this.dataDetailFlow = processDataDetailFlow(res)
	
	                            if ($this.processActionData === 1 && $this.IsWatchOldData && secondFlowDetail.length > 0) {
	                                const taskDetailIdMap = new Map()
	                                let currentSTT = 1
	
	                                $this.dataDetailFlow = $this.dataDetailFlow.flatMap((item) => {
	                                    const matchingItems = secondFlowDetail.filter((sf) => {
	                                        return sf.Task_Detail_ID === item.Task_Detail_ID && sf.Flow_Detail_ID !== item.Flow_Detail_ID
	                                    })
	
	                                    // Sắp xếp các bản ghi cũ theo thứ tự thời gian tăng dần (cũ nhất -> cũ gần nhất)
	                                    matchingItems.sort((a, b) => (a.Flow_Detail_ID || 0) - (b.Flow_Detail_ID || 0))
	
	                                    // Nếu Task_Detail_ID chưa có STT, gán STT mới
	                                    if (!taskDetailIdMap.has(item.Task_Detail_ID)) {
	                                        taskDetailIdMap.set(item.Task_Detail_ID, currentSTT++)
	                                    }
	                                    const STT = taskDetailIdMap.get(item.Task_Detail_ID)
	
	                                    // Xử lý tiêu đề theo từng phiên bản cho bước Quyết định
	                                    const isQDFile = ['ThesisConfirm', 'FileQuyetDinh'].includes(item.FieldName) || [3, 63].includes(item.Task_Detail_ID)
	                                    const isQDNo = ['ThesisConfirmNo', 'SoQuyetDinh'].includes(item.FieldName) || [4, 64].includes(item.Task_Detail_ID)
	
	                                    const updatedMatchingItems = matchingItems.map((sf, idx) => {
	                                        let desc = sf.Task_Detail_Description
	                                        if (isQDFile) {
	                                            const matchedChange = $this.studentChangeHistory.find((c) => c.QD_FileName && sf.File_Name && c.QD_FileName.trim() === sf.File_Name.trim())
	                                            if (matchedChange) {
	                                                desc = $this.getDecisionTitleForChange(matchedChange).file
	                                            } else if (idx === 0) {
	                                                desc = 'File Quyết định Giao đề tài'
	                                            } else {
	                                                const changeItem = $this.studentChangeHistory[idx - 1]
	                                                desc = $this.getDecisionTitleForChange(changeItem).file
	                                            }
	                                        } else if (isQDNo) {
	                                            const matchedChange = $this.studentChangeHistory.find((c) => c.QD_SoQD && sf.Text_Content && c.QD_SoQD.trim() === sf.Text_Content.trim())
	                                            if (matchedChange) {
	                                                desc = $this.getDecisionTitleForChange(matchedChange).no
	                                            } else if (idx === 0) {
	                                                desc = 'Số quyết định duyệt'
	                                            } else {
	                                                const changeItem = $this.studentChangeHistory[idx - 1]
	                                                desc = $this.getDecisionTitleForChange(changeItem).no
	                                            }
	                                        }
	
	                                        return {
	                                            ...sf,
	                                            STT,
	                                            Task_Detail_Description: desc,
	                                        }
	                                    })
	
	                                    // Cập nhật tiêu đề cho bản ghi hiện tại mới nhất
	                                    let currentDesc = item.Task_Detail_Description
	                                    if (matchingItems.length > 0) {
	                                        if (isQDFile) {
	                                            const matchedCurrent = $this.studentChangeHistory.find((c) => c.QD_FileName && item.File_Name && c.QD_FileName.trim() === item.File_Name.trim())
	                                            const lastChangeItem = matchedCurrent || $this.studentChangeHistory[$this.studentChangeHistory.length - 1]
	                                            if (lastChangeItem) {
	                                                currentDesc = $this.getDecisionTitleForChange(lastChangeItem).file
	                                            }
	                                        } else if (isQDNo) {
	                                            const matchedCurrent = $this.studentChangeHistory.find((c) => c.QD_SoQD && item.Text_Content && c.QD_SoQD.trim() === item.Text_Content.trim())
	                                            const lastChangeItem = matchedCurrent || $this.studentChangeHistory[$this.studentChangeHistory.length - 1]
	                                            if (lastChangeItem) {
	                                                currentDesc = $this.getDecisionTitleForChange(lastChangeItem).no
	                                            }
	                                        }
	                                    }
	
	                                    const updatedItem = {
	                                        ...item,
	                                        STT,
	                                        Task_Detail_Description: currentDesc,
	                                    }
	
	                                    return [...updatedMatchingItems, updatedItem]
	                                })
	                            }
	
	
	
	                            const loadHoiDongData = async () => {
	                                const promises = $this.dataDetailFlow.map((item) => {
	                                    if (item.Task_Detail_Type === 'TABLE' && item.Text_Content) {
	                                        return new Promise((resolve, reject) => {
	                                            ajaxCALL(
	                                                '/HoiDong_Get_ByHoiDongID',
	                                                { HoiDong_ID: parseInt(item.Text_Content) },
	                                                (res) => {
	                                                    item.DataArray = res.data[1].map((gv, index) => ({
	                                                        ...gv,
	                                                        STT: index + 1,
	                                                    }))
	                                                    console.log('Load DsGiangVien success', item.DataArray)
	                                                    resolve()
	                                                },
	                                                (error) => {
	                                                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                                                    console.log('error to load DsGiangVien', error)
	                                                    reject(error)
	                                                },
	                                            )
	                                        })
	                                    } else {
	                                        return Promise.resolve()
	                                    }
	                                })
	
	                                await Promise.all(promises)
	                            }
	
	                            // Sau khi xử lý dataDetailFlow, gọi API HoiDong và gán dữ liệu
	                            loadHoiDongData().then(() => {
	                                $this.initialDetailFlow = JSON.parse(JSON.stringify($this.dataDetailFlow))
	                                console.log('Final dataDetailFlow', $this.dataDetailFlow)
	                            })
	                        })
	                    },
	                    (error) => {
	                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                        console.log('Error: ', error)
	                    },
	                )
	            } catch (error) {
	                console.error('Error in onLoadDetailFlow:', error)
	            }
	        },
	
	        updateFileRules(arr) {
	            const item = arr.find((type) => type.Task_Detail_Type === 'FILE' || type.Task_Detail_Type === 'FILEVIEW')
	            // Kiểm tra nếu AllowFileType là null hoặc undefined
	            console.log('item xxx', item)
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
	                        resolve($this.feeArr)
	                    },
	                    error: function (xhr, ajaxOptions, thrownError) {
	                        resolve(0)
	                    },
	                    complete: function () { },
	                })
	            })
	        },
	
	        getStyleStatusLock(lock) {
	            console.log('lock', lock)
	            if (lock === 'W') {
	                return 'pointer-events: none; opacity: 0.5;'
	            } else {
	                return 'pointer-events: auto; opacity: 1;'
	            }
	        },
	
	        getStepColor(name, lock) {
	            switch (name) {
	                case 'C': // C: COMPLETED
	                    return 'green darken-1'
	                case 'P': // P: PROCESSING
	                    return 'blue darken-2'
	                case 'R': // R: REJECTED
	                    return 'red darken-2'
	                case 'X': // X: CŨ / ĐÃ ĐỔI
	                    return 'blue-grey'
	                case 'W': // W: WAIT
	                    return lock == 1 ? 'amber' : 'blue lighten-4'
	                default:
	                    return 'blue-grey lighten-1'
	            }
	        },

	        getStepIcon(name, lock) {
	            if (name === 'X') {
	                return 'mdi-history'
	            }
	            if (lock == 0 && name == 'W') {
	                // LOCK_STATUS = 0 CHƯA ĐƯỢC LÀM, 1: ĐƯỢC LÀM
	                return 'mdi-lock'
	            } else {
	                switch (name) {
	                    case 'W': // W: WAIT
	                        return 'mdi-information'
	                    case 'C': // C: COMPLETED
	                        return 'mdi-check-bold'
	                    case 'P': // P: PROCESSING
	                        return 'mdi-timer-sand'
	                    case 'R': // R: REJECTED
	                        return 'mdi-close-thick'
	                    default:
	                        return 'mdi-information'
	                }
	            }
	        },
	
	        onUpdateInfo() {
	            ajaxCALL(
	                '/StudentInfo_Upd',
	                {
	                    StudentID: this.ExistData.StudentID,
	                    NoiSinh: this.ExistData.NoiSinh,
	                    Email: this.ExistData.Email,
	                    SoDienThoai: this.ExistData.SoDienThoai,
	                    DanToc: this.ExistData.DanToc,
	                    QuocTich: this.ExistData.QuocTich,
	                    CCCD: this.ExistData.CCCD,
	                    // NgayCap_CCCD: this.ExistData.NgayCap_CCCD ? this.ExistData.NgayCap_CCCD : '',
	                    Truong_DaiHoc: this.ExistData.Truong_DaiHoc,
	                    Nganh_DaiHoc: this.ExistData.Nganh_DaiHoc,
	                    ThoiGianTotNghiep_DaiHoc: this.ExistData.ThoiGianTotNghiep_DaiHoc,
	                    XepLoai: this.ExistData.XepLoai,
	                    NgoaiNgu_DauVao: this.ExistData.NgoaiNgu_DauVao,
	                    Loai_NgoaiNgu_DauVao: this.ExistData.Loai_NgoaiNgu_DauVao,
	                    BoSungKienThuc: this.ExistData.BoSungKienThuc,
	                    CongBoKhoaHoc: this.ExistData.CongBoKhoaHoc,
	                    GioiTinh: this.ExistData.GioiTinh,
	                },
	                (res) => {
	                    console.log('upd info success')
	                    Vue.$toast.success(`Cập nhật thông tin học viên thành công`, { position: 'top' })
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('Fail to update student info')
	                },
	            )
	        },
	
	        closeModal() {
	            if (window.unsavedUploadedFiles && window.unsavedUploadedFiles.length > 0) {
	                const fileids = window.unsavedUploadedFiles.join(',')
	                window.unsavedUploadedFiles = []
	                ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: fileids }, () => {}, () => {})
	            }
	            this.DS_OldHoiDong = []
	            this.DS_ThongTinHoiDong = []
	            this.DS_ThanhVienHoiDong = []
	            this.DS_DangKyBaoVe = []
	            this.DS_BaoVe = []
	            this.initialDetailFlow = []
	            this.processActionData = 1
	            vueData.isUpdTask = false
	        },
	    },
	}
</script>