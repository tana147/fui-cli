<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" fullscreen persistent>
		<v-card class="modal-update-task-card-fullscreen">
			<c-toolbar @onClose="closeModal" class="flex-shrink-0">
				<template v-slot:title>
					<div class="title primary--text text-left d-flex align-center flex-wrap">
						<span>Nghiên cứu sinh:</span>
						<span class="red--text font-weight-bold ml-1">
							[{{ hocVienDisplay.StudentID }}] {{ hocVienDisplay.HoSV }} {{ hocVienDisplay.TenSV }}
							<span v-if="hocVienDisplay.LopID">[{{ hocVienDisplay.LopID }}]</span>
						</span>
						<v-chip v-if="hocVienDisplay.IsXuLyHocVu" color="red" dark class="ml-2" x-small>
							Đã xử lý học vụ
						</v-chip>
						<v-chip v-if="hocVienDisplay.TenNganh" color="primary" outlined class="ml-2" x-small>
							{{ hocVienDisplay.TenNganh }}
						</v-chip>
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pa-2 grey lighten-5 modal-update-task-body">
				<!-- THÔNG TIN NGHIÊN CỨU SINH (Collapsible) -->
				<v-expansion-panels v-model="infoPanel" accordion class="mb-2 flex-shrink-0">
					<v-expansion-panel class="rounded-xs">
						<v-expansion-panel-header class="pa-3 min-h-40" disable-icon-rotate>
							<div class="d-flex align-center">
								<v-icon color="primary" class="mr-2" size="20">mdi-account-circle-outline</v-icon>
								<span class="text-subtitle-2 font-weight-bold primary--text">
									Thông tin Nghiên cứu sinh (NCS)
								</span>
								<span v-if="studentInfo.Email || studentInfo.SoDienThoai" class="ml-3 text-caption grey--text text--darken-1">
									{{ studentInfo.Email || '' }} <span v-if="studentInfo.Email && studentInfo.SoDienThoai">•</span> {{ studentInfo.SoDienThoai || '' }}
								</span>
							</div>
							<template v-slot:actions>
								<v-icon color="primary" size="20">
									{{ infoPanel === 0 ? 'mdi-chevron-up-circle' : 'mdi-chevron-down-circle' }}
								</v-icon>
							</template>
						</v-expansion-panel-header>

						<v-expansion-panel-content>
							<v-card flat class="pt-1">
								<v-row dense>
									<!-- CỘT 1: THÔNG TIN CÁ NHÂN & CÔNG TÁC -->
									<v-col cols="12" md="6">
										<v-card outlined class="pa-3 rounded-xs grey lighten-5 fill-height">
											<div class="d-flex align-center mb-2">
												<v-icon small color="primary" class="mr-1">mdi-account-details-outline</v-icon>
												<span class="text-caption font-weight-bold primary--text text-uppercase">1. Thông tin cá nhân & Công tác</span>
											</div>
											<v-divider class="mb-3" />

											<!-- 1.1 Thông tin liên hệ -->
											<div class="text-caption font-weight-bold grey--text text--darken-3 mb-1 d-flex align-center">
												<v-icon x-small color="grey darken-2" class="mr-1">mdi-phone-outline</v-icon>
												Thông tin liên hệ
											</div>
											<v-row dense class="mb-1">
												<v-col cols="12" sm="7">
													<v-text-field v-model="studentInfo.Email" label="Email" placeholder="Nhập email" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="5">
													<v-text-field v-model="studentInfo.SoDienThoai" label="Số điện thoại" placeholder="Nhập SĐT" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12">
													<v-text-field v-model="studentInfo.DiaChi" label="Địa chỉ liên hệ / Thường trú" placeholder="Nhập địa chỉ liên hệ" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
											</v-row>

											<!-- 1.2 Lý lịch & Định danh -->
											<v-divider class="my-2" />
											<div class="text-caption font-weight-bold grey--text text--darken-3 mb-1 d-flex align-center">
												<v-icon x-small color="grey darken-2" class="mr-1">mdi-card-account-details-outline</v-icon>
												Lý lịch & Định danh
											</div>
											<v-row dense class="mb-1">
												<v-col cols="12" sm="4">
													<v-select v-model="studentInfo.GioiTinh" :items="['Nam', 'Nữ']" label="Giới tính" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.DanToc" label="Dân tộc" placeholder="Nhập dân tộc" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.QuocTich" label="Quốc tịch" placeholder="Nhập quốc tịch" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.CCCD" label="Số CCCD" placeholder="Nhập số CCCD" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.NgayCap_CCCD" label="Ngày cấp CCCD" placeholder="DD-MM-YYYY" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.NoiSinh" label="Nơi sinh" placeholder="Nhập nơi sinh" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
											</v-row>

											<!-- 1.3 Nghề nghiệp & Đơn vị -->
											<v-divider class="my-2" />
											<div class="text-caption font-weight-bold grey--text text--darken-3 mb-1 d-flex align-center">
												<v-icon x-small color="grey darken-2" class="mr-1">mdi-briefcase-outline</v-icon>
												Nghề nghiệp & Đơn vị công tác
											</div>
											<v-row dense>
												<v-col cols="12">
													<v-text-field v-model="studentInfo.NgheNghiep" label="Nghề nghiệp / Chức vụ" placeholder="Nhập nghề nghiệp, chức vụ" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12">
													<v-text-field v-model="studentInfo.NoiLamViec" label="Nơi làm việc / Cơ quan" placeholder="Nhập cơ quan, nơi làm việc" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
											</v-row>
										</v-card>
									</v-col>

									<!-- CỘT 2: TRÌNH ĐỘ CHUYÊN MÔN & NGOẠI NGỮ -->
									<v-col cols="12" md="6">
										<v-card outlined class="pa-3 rounded-xs grey lighten-5 fill-height">
											<div class="d-flex align-center mb-2">
												<v-icon small color="primary" class="mr-1">mdi-school-outline</v-icon>
												<span class="text-caption font-weight-bold primary--text text-uppercase">2. Trình độ chuyên môn & Ngoại ngữ</span>
											</div>
											<v-divider class="mb-3" />

											<!-- 2.1 Đại học -->
											<div class="text-caption font-weight-bold grey--text text--darken-3 mb-1 d-flex align-center">
												<v-icon x-small color="grey darken-2" class="mr-1">mdi-certificate-outline</v-icon>
												Văn bằng Đại học
											</div>
											<v-row dense class="mb-1">
												<v-col cols="12" sm="7">
													<v-text-field v-model="studentInfo.Truong_DaiHoc" label="Trường Đại học" placeholder="Nhập trường ĐH" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="5">
													<v-text-field v-model="studentInfo.Nganh_DaiHoc" label="Ngành Đại học" placeholder="Nhập ngành ĐH" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.HeDaoTao_DaiHoc" label="Hệ đào tạo ĐH" placeholder="Chính quy..." outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.ThoiGianTotNghiep_DaiHoc" label="Năm tốt nghiệp ĐH" placeholder="Nhập năm tốt nghiệp" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.XepLoai" label="Xếp loại tốt nghiệp" placeholder="Nhập xếp loại" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
											</v-row>

											<!-- 2.2 Thạc sĩ -->
											<v-divider class="my-2" />
											<div class="text-caption font-weight-bold grey--text text--darken-3 mb-1 d-flex align-center">
												<v-icon x-small color="grey darken-2" class="mr-1">mdi-school</v-icon>
												Văn bằng Thạc sĩ
											</div>
											<v-row dense class="mb-1">
												<v-col cols="12" sm="7">
													<v-text-field v-model="studentInfo.Truong_ThacSi" label="Trường Thạc sĩ" placeholder="Nhập trường ThS" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="5">
													<v-text-field v-model="studentInfo.Nganh_ThacSi" label="Ngành Thạc sĩ" placeholder="Nhập ngành ThS" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="6">
													<v-text-field v-model="studentInfo.HeDaoTao_ThacSi" label="Hệ đào tạo ThS" placeholder="Chính quy..." outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="6">
													<v-text-field v-model="studentInfo.ThoiGianTotNghiep_ThacSi" label="Năm tốt nghiệp ThS" placeholder="Nhập năm tốt nghiệp ThS" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
											</v-row>

											<!-- 2.3 Ngoại ngữ & Khảo sát -->
											<v-divider class="my-2" />
											<div class="text-caption font-weight-bold grey--text text--darken-3 mb-1 d-flex align-center">
												<v-icon x-small color="grey darken-2" class="mr-1">mdi-translate</v-icon>
												Ngoại ngữ & Khảo sát đầu vào
											</div>
											<v-row dense>
												<v-col cols="12" sm="4">
													<v-text-field v-model="studentInfo.Loai_NgoaiNgu_DauVao" label="Loại ngoại ngữ" placeholder="Tiếng Anh..." outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="8">
													<v-text-field v-model="studentInfo.NgoaiNgu_DauVao" label="Ngoại ngữ đầu vào" placeholder="Chứng chỉ ngoại ngữ" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="6">
													<v-select v-model="studentInfo.BoSungKienThuc" :items="['Có', 'Không']" label="Bổ sung kiến thức" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
												<v-col cols="12" sm="6">
													<v-select v-model="studentInfo.CongBoKhoaHoc" :items="['Có', 'Không']" label="Có công bố khoa học" outlined dense background-color="white" color="primary" hide-details />
												</v-col>
											</v-row>
										</v-card>
									</v-col>
								</v-row>

								<div class="d-flex justify-end mt-2">
									<v-btn color="success" class="rounded-xs text-none" :loading="savingInfo" @click="onUpdateStudentInfo">
										<v-icon left small>mdi-content-save</v-icon>
										Lưu cập nhật thông tin NCS
									</v-btn>
								</div>
							</v-card>
						</v-expansion-panel-content>
					</v-expansion-panel>
				</v-expansion-panels>

				<!-- THANH 3 TABS QUY TRÌNH CHÍNH & XEM LỊCH SỬ -->
				<v-card class="mb-2 pa-1 rounded-xs flex-shrink-0 border" flat style="background: #ffffff;">
					<div class="d-flex align-center justify-space-between px-2" style="gap: 16px;">
						<!-- 3 Tabs quy trình chính cố định - Co giãn theo chiều ngang khả dụng -->
						<v-tabs
							v-model="activeProcessTabIndex"
							background-color="transparent"
							color="primary"
							class="text-none flex-grow-1"
							@change="onSelectProcessTab"
						>
							<v-tab v-for="(tab, index) in mainProcessTabs" :key="'proc-tab-' + index" class="text-none font-weight-bold">
								<v-icon left small color="primary">{{ tab.icon }}</v-icon>
								{{ tab.name }}
								<v-chip v-if="getProcessCountForAction(tab.action) > 0" x-small class="ml-2 font-weight-bold" color="primary lighten-5 primary--text">
									{{ getProcessCountForAction(tab.action) }}
								</v-chip>
							</v-tab>
						</v-tabs>

						<!-- Khu vực Xem Lịch Sử / Chọn đợt cũ tương ứng với từng Tab -->
						<div class="d-flex align-center ml-auto flex-shrink-0" style="gap: 8px;">
							<!-- Tab 1 (Quy trình chính): Nút mở Modal xem lịch sử quy trình cũ (Reset) -->
							<v-btn
								v-if="activeTabAction === 4"
								text
								small
								color="primary"
								class="rounded-xs text-none font-weight-bold"
								@click="isOpenViewOldProcessModal = true"
							>
								<v-icon left small>mdi-history</v-icon>
								Lịch sử quy trình cũ (Reset)
							</v-btn>

							<!-- Tab 2 (Đổi đề tài) hoặc Tab 3 (Gia hạn) và có nhiều lần: Dropdown chọn lần xem -->
							<div v-else-if="currentActionProcessList.length > 1" class="d-flex align-center">
								<span class="text-caption grey--text text--darken-2 mr-2 font-weight-medium text-no-wrap">
									<v-icon left small color="primary">mdi-history</v-icon> Lần đăng ký:
								</span>
								<v-select
									v-model="selectedProcessStudentId"
									:items="processVersionOptions"
									item-text="text"
									item-value="value"
									dense
									outlined
									hide-details
									class="caption font-weight-medium"
									style="min-width: 260px; max-width: 320px; background: #ffffff;"
									@change="onChangeProcessVersion"
								/>
							</div>
						</div>
					</div>
				</v-card>

				<!-- KHUNG LỘ TRÌNH ĐÀO TẠO TIẾN SĨ (2 CỘT) -->
				<v-row class="ma-0 modal-update-task-row">
					<!-- Cột Trái: Lộ trình Timeline 5 giai đoạn -->
					<v-col cols="12" md="3" class="pa-1 modal-update-task-col">
						<v-card class="pa-3 border rounded-xs white modal-update-task-inner-card" flat outlined>
							<h4 class="text-subtitle-1 font-weight-bold mb-3 primary--text d-flex align-center flex-shrink-0">
								<v-icon class="mr-2" color="primary">mdi-format-list-bulleted-triangle</v-icon>
								Lộ Trình Đào Tạo Tiến Sĩ
							</h4>

							<div v-if="loadingRootFlow" class="text-center py-6">
								<v-progress-circular indeterminate color="primary" size="28" />
								<div class="text-caption grey--text mt-2">Đang tải lộ trình...</div>
							</div>

							<div v-else-if="rootflow && rootflow.length > 0" class="modal-update-task-scroll pr-1">
								<v-timeline dense align-top class="pa-0">
									<v-timeline-item
										v-for="(item, index) in rootflow"
										:key="index"
										:color="getStepTimelineColor(item.Flow_Status, index)"
										:icon="getStepTimelineIcon(item.Flow_Status, item.LOCK_STATUS)"
										fill-dot
										small
										class="pb-3"
										style="cursor: pointer;"
										@click.native="selectStep(index)"
									>
										<div class="d-flex flex-column">
											<span
												class="text-subtitle-2 font-weight-bold"
												:class="activeStepIndex === index ? 'primary--text' : 'grey--text text--darken-3'"
											>
												{{ index + 1 }}. {{ item.TASK_NAME }}
											</span>
											<div class="d-flex align-center mt-1">
												<c-status-chip :status="item.Flow_Status" :lock="item.LOCK_STATUS" x-small />
											</div>
										</div>
									</v-timeline-item>
								</v-timeline>
							</div>

							<div v-else class="text-center py-6 grey--text">
								<v-icon size="36" color="grey lighten-1">mdi-alert-circle-outline</v-icon>
								<div class="text-caption mt-1">Chưa có tiến trình nào được tạo</div>
							</div>
						</v-card>
					</v-col>

					<!-- Cột Phải: Chi tiết nhiệm vụ giai đoạn đang chọn -->
					<v-col cols="12" md="9" class="pa-1 modal-update-task-col">
						<v-card class="pa-3 border rounded-xs white modal-update-task-inner-card" flat outlined>
							<!-- Header giai đoạn -->
							<div class="d-flex align-center justify-space-between border-bottom pb-2 mb-3 flex-shrink-0" v-if="activeStep">
								<h3 class="text-subtitle-1 font-weight-bold text-uppercase d-flex align-center mb-0 primary--text">
									<v-avatar size="28" class="mr-2 font-weight-bold text-body-2 white--text" color="primary">
										{{ activeStepIndex + 1 }}
									</v-avatar>
									{{ activeStep.TASK_NAME || 'Chi tiết nhiệm vụ' }}
								</h3>

								<div class="d-flex align-center">
									<v-btn
										color="primary"
										outlined
										small
										class="mr-2 rounded-xs font-weight-medium text-none"
										@click="openQuickImportDialog"
									>
										<v-icon left small>mdi-file-upload-outline</v-icon>
										Import nhiều file
									</v-btn>
									<v-chip class="font-weight-bold" small :class="getStatusChipClass(activeStep.Flow_Status, activeStep.LOCK_STATUS)">
										{{ getStatusLabel(activeStep.Flow_Status, activeStep.LOCK_STATUS) }}
									</v-chip>
								</div>
							</div>

							<!-- Body chi tiết nhiệm vụ -->
							<div class="modal-update-task-scroll pr-1">
								<div v-if="loadingDetailFlow" class="text-center py-8">
									<v-progress-circular indeterminate color="primary" size="32" />
									<div class="text-caption grey--text mt-2">Đang tải chi tiết nhiệm vụ...</div>
								</div>

								<!-- Giai đoạn có SubGroup Tabs (Chuyên đề, Tiểu luận, Bài báo...) -->
								<div v-else-if="subGroupList.length > 0">
									<v-tabs v-model="activeTab" background-color="transparent" color="primary" class="mb-3 text-none" grow>
										<v-tab v-for="(sub, idx) in subGroupList" :key="'tab-' + idx" class="text-none font-weight-bold">
											<v-icon left small>mdi-book-open-outline</v-icon>
											{{ sub.title }}
											<v-icon right x-small :color="getChuyenDeStatusColor(sub.items)">
												{{ getChuyenDeStatusIcon(sub.items) }}
											</v-icon>
										</v-tab>
									</v-tabs>

									<v-window v-model="activeTab">
										<v-window-item v-for="(sub, idx) in subGroupList" :key="'window-item-' + idx">
											<div class="pa-1">
												<div v-for="(itemDes, idxItem) in sub.items" :key="'item-' + sub.id + '-' + idxItem" class="mb-3">
													<h4 class="text-body-2 font-weight-bold grey--text text--darken-3 mb-1">
														{{ sub.prefix }}.{{ idxItem + 1 }} {{ itemDes.Task_Detail_Description }}
													</h4>

													<!-- File upload & view -->
													<c-file-comp
														v-if="itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW'"
														:item-des="itemDes"
														:item="activeStep"
														:api-file="apiFile"
														:url-read-file="urlReadFile"
														:allow-upload="true"
														:lock="1"
													/>

													<!-- Điểm -->
													<c-score-comp
														v-else-if="itemDes.Task_Detail_Type === 'DIEM' || itemDes.Task_Detail_Type === 'FORMULAR'"
														:item-des="itemDes"
													/>

													<!-- Text Input & Text View (Mở cho phép cập nhật khi import dữ liệu) -->
													<v-text-field
														v-else-if="itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW'"
														v-model="itemDes.Text_Content"
														outlined
														dense
														color="primary"
														hide-details
													/>

													<!-- Number Input -->
													<v-text-field
														v-else-if="itemDes.Task_Detail_Type === 'NUMBER' || itemDes.Task_Detail_Type === 'NUMBERVIEW'"
														v-model="itemDes.Text_Content"
														outlined
														dense
														type="number"
														color="primary"
														hide-details
													/>

													<!-- Date Input -->
													<v-text-field
														v-else-if="itemDes.Task_Detail_Type === 'DATE' || itemDes.Task_Detail_Type === 'DATEVIEW'"
														v-model="itemDes.Text_Content"
														placeholder="YYYY-MM-DD"
														outlined
														dense
														color="primary"
														hide-details
													/>

													<!-- Table / Môn học -->
													<v-textarea
														v-else-if="itemDes.Task_Detail_Type === 'TABLE'"
														v-model="itemDes.Text_Content"
														outlined
														dense
														rows="2"
														auto-grow
														color="primary"
														placeholder="Nhập thông tin..."
														hide-details
													/>

													<!-- Textarea -->
													<c-textarea-comp
														v-else-if="itemDes.Task_Detail_Type === 'TEXTAREA'"
														:item-des="itemDes"
														:lock="1"
														:allow-edit="true"
													/>

													<!-- Checkbox -->
													<div v-else-if="itemDes.Task_Detail_Type === 'CHECKBOX'" class="d-flex align-center">
														<v-checkbox
															v-model="itemDes.Text_Content"
															color="primary"
															dense
															hide-details
															class="ma-0 pa-0"
														/>
														<v-chip x-small class="ml-2 font-weight-medium" :color="itemDes.Text_Content ? 'primary' : 'grey lighten-2'" :dark="!!itemDes.Text_Content">
															{{ itemDes.Text_Content ? 'Đã xác nhận' : 'Chưa xác nhận' }}
														</v-chip>
														<span v-if="itemDes.Data_Exp" class="ml-2 text-caption grey--text text--darken-1">{{ itemDes.Data_Exp }}</span>
													</div>
												</div>
											</div>
										</v-window-item>
									</v-window>
								</div>

								<!-- Giai đoạn tuyến tính phẳng (Không có SubGroup) -->
								<div v-else-if="dataDetailFlow && dataDetailFlow.length > 0">
									<div v-for="(itemDes, indexDes) in dataDetailFlow" :key="indexDes" class="mb-3">
										<h4 class="text-body-2 font-weight-bold grey--text text--darken-3 mb-1">
											{{ activeStepIndex + 1 }}.{{ indexDes + 1 }} {{ itemDes.Task_Detail_Description }}
										</h4>

										<!-- File upload & view -->
										<c-file-comp
											v-if="itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW'"
											:item-des="itemDes"
											:item="activeStep"
											:api-file="apiFile"
											:url-read-file="urlReadFile"
											:allow-upload="true"
											:lock="1"
										/>

										<!-- Điểm -->
										<c-score-comp
											v-else-if="itemDes.Task_Detail_Type === 'DIEM' || itemDes.Task_Detail_Type === 'FORMULAR'"
											:item-des="itemDes"
										/>

										<!-- Text Input & Text View (Mở cho phép cập nhật khi import dữ liệu) -->
										<v-text-field
											v-else-if="itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW'"
											v-model="itemDes.Text_Content"
											outlined
											dense
											color="primary"
											hide-details
										/>

										<!-- Number Input -->
										<v-text-field
											v-else-if="itemDes.Task_Detail_Type === 'NUMBER' || itemDes.Task_Detail_Type === 'NUMBERVIEW'"
											v-model="itemDes.Text_Content"
											outlined
											dense
											type="number"
											color="primary"
											hide-details
										/>

										<!-- Date Input -->
										<v-text-field
											v-else-if="itemDes.Task_Detail_Type === 'DATE' || itemDes.Task_Detail_Type === 'DATEVIEW'"
											v-model="itemDes.Text_Content"
											placeholder="YYYY-MM-DD"
											outlined
											dense
											color="primary"
											hide-details
										/>

										<!-- Table / Môn học -->
										<v-textarea
											v-else-if="itemDes.Task_Detail_Type === 'TABLE'"
											v-model="itemDes.Text_Content"
											outlined
											dense
											rows="2"
											auto-grow
											color="primary"
											placeholder="Nhập thông tin..."
											hide-details
										/>

										<!-- Textarea -->
										<c-textarea-comp
											v-else-if="itemDes.Task_Detail_Type === 'TEXTAREA'"
											:item-des="itemDes"
											:lock="1"
											:allow-edit="true"
										/>

										<!-- Checkbox -->
										<div v-else-if="itemDes.Task_Detail_Type === 'CHECKBOX'" class="d-flex align-center">
											<v-checkbox
												v-model="itemDes.Text_Content"
												color="primary"
												dense
												hide-details
												class="ma-0 pa-0"
											/>
											<v-chip x-small class="ml-2 font-weight-medium" :color="itemDes.Text_Content ? 'primary' : 'grey lighten-2'" :dark="!!itemDes.Text_Content">
												{{ itemDes.Text_Content ? 'Đã xác nhận' : 'Chưa xác nhận' }}
											</v-chip>
											<span v-if="itemDes.Data_Exp" class="ml-2 text-caption grey--text text--darken-1">{{ itemDes.Data_Exp }}</span>
										</div>
									</div>
								</div>

								<!-- Empty state khi không có task nào -->
								<div v-else class="text-center py-8 grey--text">
									<v-icon size="36" color="grey lighten-1">mdi-database-off-outline</v-icon>
									<div class="text-caption mt-1">Không có trường thông tin trong giai đoạn này</div>
								</div>
							</div>

							<!-- Footer: Nút lưu thay đổi của giai đoạn -->
							<div class="d-flex justify-end mt-3 pt-2 border-top flex-shrink-0" v-if="dataDetailFlow && dataDetailFlow.length > 0">
								<v-btn color="primary" class="text-none font-weight-bold rounded-xs" :loading="savingDetail" @click="saveChanges">
									<v-icon left small>mdi-content-save-outline</v-icon>
									Lưu thay đổi nhiệm vụ
								</v-btn>
							</div>
						</v-card>
					</v-col>
				</v-row>
			</v-card-text>

			<uc-modal-view-old-process
				v-model="isOpenViewOldProcessModal"
				:student-item="hocVienDisplay"
			/>

			<!-- DIALOG IMPORT NHIỀU FILE THEO CHỈ MỤC -->
			<v-dialog v-model="isQuickImportDialogOpen" max-width="900" persistent>
				<v-card class="rounded-xs">
					<v-card-title class="headline primary white--text pa-3 d-flex align-center justify-space-between">
						<div class="d-flex align-center">
							<v-icon color="white" class="mr-2">mdi-file-upload-outline</v-icon>
							<span class="text-subtitle-1 font-weight-bold">
								Import nhiều file theo chỉ mục - Giai đoạn {{ activeStepIndex + 1 }}: {{ activeStep ? activeStep.TASK_NAME : '' }}
							</span>
						</div>
						<v-btn icon dark small @click="closeQuickImportDialog">
							<v-icon small>mdi-close</v-icon>
						</v-btn>
					</v-card-title>

					<v-card-text class="pa-4">
						<!-- Nút chọn file & Hướng dẫn -->
						<div class="d-flex align-center justify-space-between mb-3 grey lighten-4 rounded-xs border pa-3">
							<div>
								<div class="font-weight-bold text-body-2 text--primary mb-1">
									<v-icon small color="info" class="mr-1">mdi-information-outline</v-icon>
									Quy ước đặt tên file theo chỉ mục
								</div>
								<div class="text-caption grey--text text--darken-2">
									Tên file có chứa số chỉ mục (ví dụ: <code>1.1_DonDuTuyen.pdf</code>, <code>1.2.pdf</code>, <code>1.7_BangDH.pdf</code>) để hệ thống tự động gán vào đúng mục tương ứng.
								</div>
							</div>
							<div>
								<input
									ref="batchFileInput"
									type="file"
									multiple
									accept=".pdf,.doc,.docx,.png,.jpg,.jpeg"
									class="quick-import-hidden-input"
									@change="onBatchFilesSelected"
								/>
								<v-btn
									color="primary"
									class="text-none font-weight-bold rounded-xs"
									@click="$refs.batchFileInput.click()"
								>
									<v-icon left small>mdi-folder-open-outline</v-icon>
									Chọn các file hồ sơ
								</v-btn>
							</div>
						</div>

						<!-- Bảng Preview Mapping -->
						<div v-if="stagedFiles.length > 0">
							<div class="d-flex align-center justify-space-between mb-2">
								<span class="font-weight-bold text-body-2">
									Danh sách file đã chọn ({{ stagedFiles.length }} file) - Xem trước đối soát:
								</span>
								<v-btn text x-small color="error" class="text-none" @click="clearStagedFiles">
									<v-icon left x-small>mdi-trash-can-outline</v-icon>
									Xóa tất cả file đã chọn
								</v-btn>
							</div>

							<v-simple-table dense class="border rounded-xs mb-3">
								<template v-slot:default>
									<thead>
										<tr class="grey lighten-3">
											<th class="text-center quick-import-table-col-index">Chỉ mục</th>
											<th class="quick-import-table-col-target">Tiêu chí hồ sơ</th>
											<th>File đã chọn</th>
											<th class="text-center quick-import-table-col-size">Dung lượng</th>
											<th class="text-center quick-import-table-col-status">Tình trạng</th>
											<th class="text-center quick-import-table-col-action">Xóa</th>
										</tr>
									</thead>
									<tbody>
										<tr v-for="(item, idx) in stagedFiles" :key="idx">
											<td class="text-center font-weight-bold">
												<span v-if="item.displayIndex" class="primary--text font-weight-bold">{{ item.displayIndex }}</span>
												<span v-else class="grey--text">--</span>
											</td>
											<td>
												<v-select
													v-model="item.matchedTaskDetailId"
													:items="availableTargetItems"
													item-text="label"
													item-value="Task_Detail_ID"
													dense
													outlined
													hide-details
													class="caption my-1"
													@change="onTargetItemChanged(item)"
												/>
											</td>
											<td>
												<div class="d-flex align-center">
													<v-icon small class="mr-1" :color="getFileIcon(item.name).color">
														{{ getFileIcon(item.name).icon }}
													</v-icon>
													<span class="text-caption font-weight-medium text-truncate" :title="item.name">
														{{ item.name }}
													</span>
												</div>
											</td>
											<td class="text-center text-caption grey--text">
												{{ formatFileSize(item.size) }}
											</td>
											<td class="text-center">
												<v-chip
													x-small
													label
													class="font-weight-bold"
													:color="item.status === 'matched' ? 'success' : (item.status === 'manual' ? 'warning' : 'grey')"
													:text-color="item.status === 'matched' || item.status === 'manual' ? 'white' : 'dark'"
												>
													{{ item.status === 'matched' ? 'Đã khớp' : (item.status === 'manual' ? 'Gán thủ công' : 'Chưa gán') }}
												</v-chip>
											</td>
											<td class="text-center">
												<v-btn icon x-small color="error" @click="removeStagedFile(idx)">
													<v-icon small>mdi-close</v-icon>
												</v-btn>
											</td>
										</tr>
									</tbody>
								</template>
							</v-simple-table>
						</div>

						<!-- Empty state khi chưa chọn file nào -->
						<div v-else class="text-center py-8 grey--text border rounded-xs mb-3 quick-import-dropzone">
							<v-icon size="40" color="grey lighten-1">mdi-cloud-upload-outline</v-icon>
							<div class="text-body-2 font-weight-medium mt-2">Chưa có file nào được chọn</div>
							<div class="text-caption grey--text mt-1">Bấm nút "Chọn các file hồ sơ" ở trên để chọn nhiều file cùng lúc</div>
						</div>

						<!-- Thanh tiến trình khi đang upload -->
						<div v-if="isUploadingBatch" class="mt-2">
							<v-progress-linear indeterminate color="primary" rounded height="6" />
							<div class="text-caption primary--text font-weight-bold text-center mt-1">
								{{ uploadProgressText }}
							</div>
						</div>
					</v-card-text>

					<v-card-actions class="pa-3 border-top justify-end">
						<v-btn text class="text-none font-weight-bold" :disabled="isUploadingBatch" @click="closeQuickImportDialog">
							Hủy bỏ
						</v-btn>
						<v-btn
							color="primary"
							class="text-none font-weight-bold rounded-xs"
							:loading="isUploadingBatch"
							:disabled="validStagedFilesCount === 0"
							@click="confirmAndSaveBatchFiles"
						>
							<v-icon left small>mdi-content-save-check-outline</v-icon>
							Xác nhận tải lên & Lưu ({{ validStagedFilesCount }} file)
						</v-btn>
					</v-card-actions>
				</v-card>
			</v-dialog>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-update-task",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			studentItem: {
				type: Object,
				default: () => ({}),
			},
			dsExistStudent: {
				type: Array,
				default: () => [],
			},
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				infoPanel: null,
				studentInfo: {},
				savingInfo: false,

				rootflow: [],
				loadingRootFlow: false,
				activeStepIndex: 0,
				activeTab: 0,

				dataDetailFlow: [],
				initialDetailFlow: null,
				loadingDetailFlow: false,
				savingDetail: false,

				apiFile: "",
				urlReadFile: "",
				studentProcess: [],
				mainProcessTabs: [
					{ key: 'main', action: 4, processId: 6, processTree: "4", name: "Quy trình đào tạo chính", icon: "mdi-school-outline" },
					{ key: 'change', action: 5, processId: 7, processTree: "2", name: "Đổi đề tài / GVHD", icon: "mdi-file-replace-outline" },
					{ key: 'extend', action: 6, processId: 8, processTree: "2", name: "Gia hạn thời gian", icon: "mdi-clock-time-four-outline" },
				],
				activeProcessTabIndex: 0,
				selectedProcessStudentId: null,
				isOpenViewOldProcessModal: false,

				// Quick Batch Import
				isQuickImportDialogOpen: false,
				stagedFiles: [],
				isUploadingBatch: false,
				uploadProgressText: "",
			}
		},
		computed: {
			hocVienDisplay() {
				return this.studentItem || {}
			},
			currentStudentId() {
				return this.studentItem?.StudentID || null
			},
			activeTabAction() {
				return this.mainProcessTabs[this.activeProcessTabIndex]?.action || 4
			},
			currentActionProcessList() {
				if (!this.studentProcess || this.studentProcess.length === 0) return []
				const action = this.activeTabAction
				return this.studentProcess.filter(p => (p.Process_Action || 4) === action)
			},
			processVersionOptions() {
				const list = this.currentActionProcessList
				const total = list.length
				return list.map((item, idx) => {
					const lanNum = total - idx
					const statusText = item.Process_Student_Status === 'C' ? 'Đã hoàn thành' : 'Đang xử lý'
					return {
						text: `Lần ${lanNum} (${statusText})`,
						value: item.Process_Student_ID,
						item: item
					}
				})
			},
			activeStep() {
				if (this.rootflow && this.rootflow.length > this.activeStepIndex) {
					return this.rootflow[this.activeStepIndex]
				}
				return {}
			},
			availableTargetItems() {
				// Nếu giai đoạn có chia SubGroup tabs (Chuyên đề, Tiểu luận, Bài báo...)
				if (this.subGroupList && this.subGroupList.length > 0) {
					const result = []
					this.subGroupList.forEach((sub) => {
						(sub.items || []).forEach((itemDes, idxItem) => {
							if (itemDes.Task_Detail_Type === "FILE" || itemDes.Task_Detail_Type === "FILEVIEW") {
								const displayIndex = `${sub.prefix}.${idxItem + 1}`
								result.push({
									Task_Detail_ID: itemDes.Task_Detail_ID,
									displayIndex: displayIndex,
									label: `${displayIndex}. ${itemDes.Task_Detail_Description}`,
									description: itemDes.Task_Detail_Description,
									type: itemDes.Task_Detail_Type,
								})
							}
						})
					})
					return result
				}

				// Giai đoạn tuyến tính phẳng: chỉ mục hiển thị trên UI là indexDes + 1 trong dataDetailFlow
				const list = this.dataDetailFlow || []
				const result = []
				list.forEach((item, indexDes) => {
					if (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") {
						const displayIndex = `${this.activeStepIndex + 1}.${indexDes + 1}`
						result.push({
							Task_Detail_ID: item.Task_Detail_ID,
							displayIndex: displayIndex,
							label: `${displayIndex}. ${item.Task_Detail_Description}`,
							description: item.Task_Detail_Description,
							type: item.Task_Detail_Type,
						})
					}
				})
				return result
			},
			validStagedFilesCount() {
				return (this.stagedFiles || []).filter((f) => f.matchedTaskDetailId).length
			},
			subGroupList() {
				const list = this.dataDetailFlow
				if (!Array.isArray(list)) return []

				const groupMap = {}
				list.forEach((item) => {
					const groupKey = item.SubGroup
					if (groupKey) {
						if (!groupMap[groupKey]) {
							groupMap[groupKey] = []
						}
						groupMap[groupKey].push(item)
					}
				})

				const sortedKeys = Object.keys(groupMap).sort((a, b) => {
					const prefixA = a.replace(/\d+/g, "").toUpperCase()
					const prefixB = b.replace(/\d+/g, "").toUpperCase()
					if (prefixA !== prefixB) return prefixA.localeCompare(prefixB)
					const numA = parseInt(a.replace(/\D/g, "")) || 0
					const numB = parseInt(b.replace(/\D/g, "")) || 0
					return numA - numB
				})

				const subGroupPrefixMap = {
					CD: "Chuyên đề",
					TL: "Tiểu luận",
					BB: "Bài báo",
					BC: "Báo cáo",
				}

				return sortedKeys.map((key) => {
					const prefix = key.replace(/\d+/g, "")
					const num = parseInt(key.replace(/\D/g, "")) || ""

					let name = subGroupPrefixMap[prefix.toUpperCase()]
					if (!name) {
						name = prefix.charAt(0).toUpperCase() + prefix.slice(1)
					}
					const title = num ? `${name} ${num}` : name

					return {
						id: num || key,
						title: title,
						prefix: num ? `${this.activeStepIndex + 1}.${num}` : `${this.activeStepIndex + 1}`,
						items: groupMap[key],
					}
				})
			},
		},
		watch: {
			value(val) {
				if (val && this.currentStudentId) {
					this.initModal()
				} else if (!val) {
					this.cleanupModal()
				}
			},
			activeStepIndex(newIdx) {
				this.loadStepDetails(newIdx)
			},
		},
		mounted() {
			this.apiFile = window.vueData?.v_Set?.apiFile || ""
			this.urlReadFile = window.vueData?.v_Set?.urlReadFile || ""
		},
		methods: {
			async initModal() {
				this.activeStepIndex = 0
				this.activeTab = 0
				this.activeProcessTabIndex = 0
				this.studentProcess = []
				await this.loadStudentDetailInfo()
				await this.loadStudentProcesses()
			},

			async cleanupUnsavedFiles() {
				if (window.unsavedUploadedFiles && window.unsavedUploadedFiles.length > 0) {
					const filesToDelete = [...window.unsavedUploadedFiles]
					window.unsavedUploadedFiles = []
					const fileids = filesToDelete.join(",")
					try {
						await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: fileids })
					} catch (e) {
						console.error("Lỗi xóa file rác chưa lưu:", e)
					}
				}
			},

			async cleanupModal() {
				await this.cleanupUnsavedFiles()
				this.rootflow = []
				this.dataDetailFlow = []
				this.initialDetailFlow = null
			},

			formatDateDMY(val) {
				if (!val) return ""
				if (typeof moment !== "undefined") {
					const m = moment(val, ["YYYY-MM-DDTHH:mm:ss", "YYYY-MM-DD", "DD-MM-YYYY", "DD/MM/YYYY"], true)
					if (m.isValid()) return m.format("DD-MM-YYYY")
					const mLoose = moment(val)
					if (mLoose.isValid()) return mLoose.format("DD-MM-YYYY")
				}
				if (typeof val === "string" && val.includes("T")) {
					const part = val.split("T")[0]
					const segments = part.split("-")
					if (segments.length === 3) {
						const [y, m, d] = segments
						if (y && m && d && y.length === 4) return `${d}-${m}-${y}`
					}
				}
				return val
			},

			async loadStudentDetailInfo() {
				if (!this.currentStudentId) return
				try {
					const res = await ajaxCALLPromise("/StudentInfo_GetById", { Student_ID: this.currentStudentId })
					if (res && res.length > 0) {
						const info = { ...res[0] }
						if (info.NgayCap_CCCD) {
							info.NgayCap_CCCD = this.formatDateDMY(info.NgayCap_CCCD)
						}
						this.studentInfo = info
					} else {
						const info = { ...this.studentItem }
						if (info.NgayCap_CCCD) {
							info.NgayCap_CCCD = this.formatDateDMY(info.NgayCap_CCCD)
						}
						this.studentInfo = info
					}
				} catch (error) {
					console.error("Lỗi tải thông tin NCS:", error)
					this.studentInfo = { ...this.studentItem }
				}
			},

			async onUpdateStudentInfo() {
				this.savingInfo = true
				try {
					await ajaxCALLPromise("/StudentInfo_Upd", {
						StudentID: this.studentInfo.StudentID || this.currentStudentId,
						NoiSinh: this.studentInfo.NoiSinh || "",
						Email: this.studentInfo.Email || "",
						SoDienThoai: this.studentInfo.SoDienThoai || "",
						GioiTinh: this.studentInfo.GioiTinh || "Nam",
						DanToc: this.studentInfo.DanToc || "",
						QuocTich: this.studentInfo.QuocTich || "Việt Nam",
						CCCD: this.studentInfo.CCCD || "",
						NgayCap_CCCD: this.studentInfo.NgayCap_CCCD || "",
						Truong_DaiHoc: this.studentInfo.Truong_DaiHoc || "",
						Nganh_DaiHoc: this.studentInfo.Nganh_DaiHoc || "",
						ThoiGianTotNghiep_DaiHoc: this.studentInfo.ThoiGianTotNghiep_DaiHoc || "",
						Truong_ThacSi: this.studentInfo.Truong_ThacSi || "",
						Nganh_ThacSi: this.studentInfo.Nganh_ThacSi || "",
						ThoiGianTotNghiep_ThacSi: this.studentInfo.ThoiGianTotNghiep_ThacSi || "",
						XepLoai: this.studentInfo.XepLoai || "",
						NgoaiNgu_DauVao: this.studentInfo.NgoaiNgu_DauVao || "",
						Loai_NgoaiNgu_DauVao: this.studentInfo.Loai_NgoaiNgu_DauVao || "",
						BoSungKienThuc: this.studentInfo.BoSungKienThuc || "Không",
						CongBoKhoaHoc: this.studentInfo.CongBoKhoaHoc || "Không",
						DiaChi: this.studentInfo.DiaChi || "",
						NoiLamViec: this.studentInfo.NoiLamViec || "",
						NgheNghiep: this.studentInfo.NgheNghiep || "",
						HeDaoTao_DaiHoc: this.studentInfo.HeDaoTao_DaiHoc || "",
						HeDaoTao_ThacSi: this.studentInfo.HeDaoTao_ThacSi || "",
					})

					Vue.$toast.success("Cập nhật thông tin NCS thành công", { position: "top" })
					this.$emit("on-reload")
				} catch (error) {
					console.error("Lỗi cập nhật thông tin NCS:", error)
					Vue.$toast.error("Cập nhật thông tin NCS thất bại", { position: "top" })
				} finally {
					this.savingInfo = false
				}
			},

			getProcessCountForAction(action) {
				if (!this.studentProcess) return 0
				return this.studentProcess.filter(p => (p.Process_Action || 4) === action).length
			},

			async loadStudentProcesses() {
				if (!this.currentStudentId) return
				this.loadingRootFlow = true
				try {
					const res = await ajaxCALLPromise("/Student_Process_Get_TS", {
						Student_ID: this.currentStudentId,
						IsFull: 1,
					})
					const actionOrder = { 4: 1, 5: 2, 6: 3 }
					this.studentProcess = (res || []).sort((a, b) => {
						const orderA = actionOrder[a.Process_Action] || 99
						const orderB = actionOrder[b.Process_Action] || 99
						if (orderA !== orderB) return orderA - orderB
						return (b.Process_Student_ID || 0) - (a.Process_Student_ID || 0)
					})
					await this.switchProcessTab(this.activeProcessTabIndex)
				} catch (e) {
					console.error("Lỗi tải danh sách quy trình NCS:", e)
					this.studentProcess = []
					this.rootflow = []
				} finally {
					this.loadingRootFlow = false
				}
			},

			async onSelectProcessTab(index) {
				this.activeProcessTabIndex = index
				await this.switchProcessTab(index)
			},

			async switchProcessTab(tabIndex) {
				const tab = this.mainProcessTabs[tabIndex] || this.mainProcessTabs[0]
				const procs = (this.studentProcess || []).filter(p => (p.Process_Action || 4) === tab.action)
				if (procs.length > 0) {
					this.selectedProcessStudentId = procs[0].Process_Student_ID
					await this.loadRootFlowForProcess(procs[0].Process_Student_ID, tab.processTree)
				} else {
					this.selectedProcessStudentId = null
					this.rootflow = []
					this.dataDetailFlow = []
				}
			},

			async onChangeProcessVersion(psId) {
				const tab = this.mainProcessTabs[this.activeProcessTabIndex] || this.mainProcessTabs[0]
				await this.loadRootFlowForProcess(psId, tab.processTree)
			},

			async loadRootFlowForProcess(processStudentId, processTree = "4", keepCurrentStep = false) {
				if (!this.currentStudentId || !processStudentId) return
				this.loadingRootFlow = true
				try {
					const res = await ajaxCALLPromise("/Get_RootFlow", {
						StudentID: this.currentStudentId,
						Process_Student_ID: processStudentId,
						Process_Tree: String(processTree || "4"),
					})
					// Mở hết tất cả các bước (LOCK_STATUS = 1) để cho phép cập nhật dữ liệu import
					this.rootflow = (res || []).map((item) => ({
						...item,
						LOCK_STATUS: 1,
					}))

					if (!keepCurrentStep) {
						this.activeStepIndex = 0
						if (this.rootflow.length > 0) {
							let defaultIdx = this.rootflow.findIndex((item) => item.Flow_Status === "P")
							if (defaultIdx === -1) {
								for (let i = this.rootflow.length - 1; i >= 0; i--) {
									if (this.rootflow[i].Flow_Status !== "W") {
										defaultIdx = i
										break
									}
								}
							}
							this.activeStepIndex = defaultIdx >= 0 ? defaultIdx : 0
							await this.loadStepDetails(this.activeStepIndex)
						} else {
							this.dataDetailFlow = []
						}
					} else {
						await this.loadStepDetails(this.activeStepIndex)
					}
				} catch (error) {
					console.error("Lỗi tải RootFlow (TS):", error)
					Vue.$toast.error("Lỗi tải lộ trình quy trình NCS", { position: "top" })
					this.rootflow = []
					this.dataDetailFlow = []
				} finally {
					this.loadingRootFlow = false
				}
			},

			async selectStep(index) {
				if (this.activeStepIndex !== index) {
					await this.cleanupUnsavedFiles()
					this.activeStepIndex = index
				}
			},

			async loadStepDetails(idx) {
				if (!this.rootflow || !this.rootflow[idx]) {
					this.dataDetailFlow = []
					return
				}
				const step = this.rootflow[idx]
				this.loadingDetailFlow = true
				try {
					const res = await ajaxCALLPromise("/Get_FlowDetail", { Flow_ID: step.Flow_ID })
					const rawData = res || []

					this.dataDetailFlow = rawData.map((item) => {
						const isCheckbox = item.Task_Detail_Type === "CHECKBOX"
						const checkboxVal = isCheckbox ? (item.Text_Content === true || String(item.Text_Content).toLowerCase() === "true") : false
						return {
							File_ID: null,
							File_Name: null,
							File_Type: null,
							File_URL: null,
							FILE_UPLOAD: null,
							...item,
							Text_Content:
								item.FieldName === "QDThanhLapHoiDong_ThoiGian" && item.Text_Content
									? typeof moment !== "undefined"
										? moment(item.Text_Content).format("DD/MM/YYYY")
										: item.Text_Content
									: item.Task_Detail_Type === "DIEM"
									? item.Text_Content
										? parseFloat(item.Text_Content).toFixed(2)
										: null
									: isCheckbox
									? checkboxVal
									: item.Text_Content,
						}
					})
					this.initialDetailFlow = JSON.parse(JSON.stringify(this.dataDetailFlow))
				} catch (error) {
					console.error("Lỗi tải chi tiết nhiệm vụ:", error)
					Vue.$toast.error(`Lỗi tải chi tiết nhiệm vụ: ${error}`, { position: "top" })
				} finally {
					this.loadingDetailFlow = false
				}
			},

			getStepTimelineColor(status, idx) {
				if (this.activeStepIndex === idx) return "primary"
				switch (status) {
					case "C":
						return "success"
					case "P":
						return "info"
					case "W":
						return "grey lighten-1"
					default:
						return "grey"
				}
			},

			getStepTimelineIcon(status, lock) {
				if (lock === 0 && status === "W") return "mdi-lock-outline"
				switch (status) {
					case "C":
						return "mdi-check"
					case "P":
						return "mdi-clock-outline"
					case "W":
						return "mdi-pencil-outline"
					default:
						return "mdi-help-circle-outline"
				}
			},

			getStatusLabel(status, lock) {
				if (lock === 0) {
					switch (status) {
						case "W":
							return "Bị khóa"
						case "C":
							return "Đã hoàn thành"
						case "P":
							return "Đang xử lý"
						default:
							return "Đang khóa"
					}
				} else {
					switch (status) {
						case "C":
							return "Đã hoàn thành"
						case "P":
							return "Đang thực hiện"
						case "W":
							return "Chờ thực hiện"
						default:
							return "Đang mở"
					}
				}
			},

			getStatusChipClass(status, lock) {
				if (lock === 0) {
					switch (status) {
						case "C":
							return "success--text green lighten-5"
						case "P":
							return "info--text blue lighten-5"
						default:
							return "grey--text text--darken-1 grey lighten-4"
					}
				} else {
					switch (status) {
						case "C":
							return "success--text green lighten-5"
						case "P":
							return "info--text blue lighten-5"
						default:
							return "amber--text text--darken-3 yellow lighten-5"
					}
				}
			},

			getChuyenDeStatusColor(chuyenDeItems) {
				if (!chuyenDeItems || !Array.isArray(chuyenDeItems)) return "grey"
				const hasDiem = chuyenDeItems.some((i) => i.FieldName && i.FieldName.startsWith("Diem") && i.Text_Content)
				const hasFile = chuyenDeItems.some((i) => i.FieldName && i.FieldName.startsWith("Cuon") && i.File_ID)
				if (hasDiem) return "success"
				if (hasFile) return "info"
				return "grey"
			},

			getChuyenDeStatusIcon(chuyenDeItems) {
				if (!chuyenDeItems || !Array.isArray(chuyenDeItems)) return "mdi-circle-medium"
				const hasDiem = chuyenDeItems.some((i) => i.FieldName && i.FieldName.startsWith("Diem") && i.Text_Content)
				const hasFile = chuyenDeItems.some((i) => i.FieldName && i.FieldName.startsWith("Cuon") && i.File_ID)
				if (hasDiem) return "mdi-check-circle-outline"
				if (hasFile) return "mdi-clock-outline"
				return "mdi-circle-medium"
			},

			async saveChanges() {
				const root = this.activeStep
				if (!root || !this.dataDetailFlow || this.dataDetailFlow.length === 0) return

				const itemsToSave = this.dataDetailFlow.filter((item) => {
					const initialItem = (this.initialDetailFlow || []).find((init) => init.Task_Detail_ID === item.Task_Detail_ID)

					const currentText = typeof item.Text_Content === "string" ? item.Text_Content.trim() : item.Text_Content
					const hasInput =
						item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW"
							? !!item.File_ID
							: currentText !== null && currentText !== undefined && currentText !== ""

					if (!initialItem) return hasInput

					const initialText = typeof initialItem.Text_Content === "string" ? initialItem.Text_Content.trim() : initialItem.Text_Content

					const isTextChanged = currentText !== initialText
					const isFileChanged =
						(item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") &&
						(item.File_ID !== initialItem.File_ID ||
							item.File_URL !== initialItem.File_URL ||
							item.File_Name !== initialItem.File_Name ||
							item.File_Type !== initialItem.File_Type)

					return isTextChanged || isFileChanged
				})

				if (itemsToSave.length === 0) {
					Vue.$toast.info("Không có thay đổi nào cần lưu", { position: "top" })
					return
				}

				this.savingDetail = true
				try {
					const detailsPayload = itemsToSave.map((item) => ({
						Task_Detail_ID: item.Task_Detail_ID,
						Text_Content:
							item.Task_Detail_Type === "CHECKBOX"
								? String(!!item.Text_Content)
								: typeof item.Text_Content === "string" && item.Text_Content
								? item.Text_Content.trim()
								: item.Text_Content,
						File_Name: item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? (item.File_Name || null) : null,
						File_Type: item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? (item.File_Type || null) : null,
						File_URL: item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? (item.File_URL || null) : null,
						File_ID: item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? (item.File_ID || null) : null,
					}))

					await ajaxCALLPromise("/FlowDetail_UpdateMulti_TS", {
						Student_ID: this.currentStudentId,
						Process_ID: root.PROCESS_ID,
						Flow_ID: root.Flow_ID,
						Task_ID: root.Children_Task_ID || root.TASK_ID,
						JsonDetails: JSON.stringify(detailsPayload),
						IsApproveAll: 0,
					})

					// Xóa file cũ đã bị thay thế trên server sau khi lưu thành công
					const oldFileIds = []
					for (let i = 0; i < this.dataDetailFlow.length; i++) {
						const currentItem = this.dataDetailFlow[i]
						const initialItem = (this.initialDetailFlow || []).find((item) => item.Task_Detail_ID === currentItem.Task_Detail_ID)
						if (initialItem && (currentItem.Task_Detail_Type === "FILE" || currentItem.Task_Detail_Type === "FILEVIEW")) {
							if (initialItem.File_ID && currentItem.File_ID !== initialItem.File_ID) {
								oldFileIds.push(initialItem.File_ID)
							}
						}
					}
					if (oldFileIds.length > 0) {
						try {
							await ajaxCALLPromise("/FILE_FileDeleteMulti", { FileIDs: oldFileIds.join(",") })
						} catch (e) {
							console.error("Lỗi xóa các file cũ bị thay thế:", e)
						}
					}
					window.unsavedUploadedFiles = []

					Vue.$toast.success(`Cập nhật ${root.TASK_NAME} thành công`, { position: "top" })
					this.$emit("on-reload")
					const tab = this.mainProcessTabs[this.activeProcessTabIndex] || this.mainProcessTabs[0]
					await this.loadRootFlowForProcess(this.selectedProcessStudentId, tab.processTree, true)
				} catch (error) {
					console.error("Lỗi lưu nhiệm vụ:", error)
					Vue.$toast.error(`Cập nhật ${root.TASK_NAME} thất bại`, { position: "top" })
				} finally {
					this.savingDetail = false
				}
			},

			openQuickImportDialog() {
				this.stagedFiles = []
				this.isQuickImportDialogOpen = true
			},

			async closeQuickImportDialog() {
				if (this.isUploadingBatch) return
				this.clearStagedFiles()
				await this.cleanupUnsavedFiles()
				this.isQuickImportDialogOpen = false
			},

			clearStagedFiles() {
				this.stagedFiles = []
				if (this.$refs.batchFileInput) {
					this.$refs.batchFileInput.value = ""
				}
			},

			removeStagedFile(idx) {
				this.stagedFiles.splice(idx, 1)
			},

			onBatchFilesSelected(e) {
				const files = Array.from(e.target.files || [])
				if (files.length === 0) return

				const targets = this.availableTargetItems || []

				files.forEach((file) => {
					// Regex bóc tách số chỉ mục: ví dụ "1.1", "1.16", "2.1.1" từ tên file
					const match = file.name.match(/(?:^|[_\-\s\[\(])(\d+(?:\.\d+)+)(?:[_\-\s\]\).]|$)/)
					let matchedTarget = null
					let status = "unassigned"

					if (match) {
						const indexCode = match[1]
						matchedTarget = targets.find((t) => t.displayIndex === indexCode)
						if (matchedTarget) {
							status = "matched"
						}
					}

					this.stagedFiles.push({
						file: file,
						name: file.name,
						size: file.size,
						matchedTaskDetailId: matchedTarget ? matchedTarget.Task_Detail_ID : null,
						displayIndex: matchedTarget ? matchedTarget.displayIndex : null,
						status: status,
					})
				})

				if (this.$refs.batchFileInput) {
					this.$refs.batchFileInput.value = ""
				}
			},

			onTargetItemChanged(item) {
				const target = (this.availableTargetItems || []).find((t) => t.Task_Detail_ID === item.matchedTaskDetailId)
				if (target) {
					item.displayIndex = target.displayIndex
					item.status = "manual"
				} else {
					item.displayIndex = null
					item.status = "unassigned"
				}
			},

			formatFileSize(bytes) {
				if (!bytes || bytes === 0) return "0 B"
				const k = 1024
				const sizes = ["B", "KB", "MB", "GB"]
				const i = Math.floor(Math.log(bytes) / Math.log(k))
				return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
			},

			getFileIcon(fileName) {
				if (!fileName) return { icon: "mdi-file-outline", color: "grey" }
				const ext = fileName.split(".").pop().toLowerCase()
				if (["pdf"].includes(ext)) return { icon: "mdi-file-pdf-box", color: "red" }
				if (["doc", "docx"].includes(ext)) return { icon: "mdi-file-word-box", color: "blue" }
				if (["xls", "xlsx"].includes(ext)) return { icon: "mdi-file-excel-box", color: "green" }
				if (["png", "jpg", "jpeg"].includes(ext)) return { icon: "mdi-file-image-box", color: "purple" }
				return { icon: "mdi-file-outline", color: "grey" }
			},

			uploadSingleBatchFile(file) {
				return new Promise((resolve, reject) => {
					const token = window.$awt || (typeof getCookie === "function" ? "Bearer " + getCookie("awt") : "")
					if (!window.plupload) {
						const formData = new FormData()
						formData.append("file", file)
						formData.append("name", file.name)
						fetch(this.apiFile, {
							method: "POST",
							headers: token ? { authorization: token } : {},
							body: formData,
						})
							.then((r) => r.json())
							.then((res) => {
								const resFile = res && res.Files && res.Files[0] ? res.Files[0] : res
								resolve(resFile)
							})
							.catch(reject)
						return
					}

					const dummyBtn = document.createElement("div")
					dummyBtn.id = "batch-btn-" + Math.random().toString(36).substring(2)
					dummyBtn.style.display = "none"
					document.body.appendChild(dummyBtn)

					let uploadedResult = null
					const uploader = new window.plupload.Uploader({
						runtimes: "html5,html4",
						browse_button: dummyBtn.id,
						url: this.apiFile,
						headers: {
							authorization: token,
							uploaddata: Date.now(),
						},
						init: {
							PostInit: function (up) {
								up.addFile(file)
							},
							FilesAdded: function (up) {
								up.start()
							},
							FileUploaded: function (up, f, result) {
								try {
									uploadedResult = JSON.parse(result.response)
								} catch (e) {
									uploadedResult = null
								}
							},
							UploadComplete: function () {
								if (dummyBtn && dummyBtn.parentNode) dummyBtn.parentNode.removeChild(dummyBtn)
								const resFile =
									uploadedResult && uploadedResult.Files && uploadedResult.Files[0]
										? uploadedResult.Files[0]
										: uploadedResult || {}
								resolve(resFile)
							},
							Error: function (up, err) {
								if (dummyBtn && dummyBtn.parentNode) dummyBtn.parentNode.removeChild(dummyBtn)
								reject(err)
							},
						},
					})
					uploader.init()
				})
			},

			async confirmAndSaveBatchFiles() {
				const validFiles = this.stagedFiles.filter((f) => f.matchedTaskDetailId)
				if (validFiles.length === 0) {
					Vue.$toast.warning("Vui lòng gán ít nhất 1 file vào tiêu chí hợp lệ", { position: "top" })
					return
				}

				this.isUploadingBatch = true
				const uploadedFiles = []

				try {
					for (let i = 0; i < validFiles.length; i++) {
						const item = validFiles[i]
						this.uploadProgressText = `Đang tải lên (${i + 1}/${validFiles.length}): ${item.name}...`
						const res = await this.uploadSingleBatchFile(item.file)
						if (res) {
							const fileId = res.FILE_ID || res.FileID || res.fileId
							const fileName = res.FILE_NAME || res.FileName || item.name
							const fileType = res.FILE_CONTENTTYPE || res.ContentType || item.file.type
							const fileUrl = res.FILE_URL || res.FileUrl || (fileId ? "/FileData/" + fileId : "")

							uploadedFiles.push({
								Task_Detail_ID: item.matchedTaskDetailId,
								File_ID: fileId,
								File_Name: fileName,
								File_Type: fileType,
								File_URL: fileUrl,
							})

							if (!window.unsavedUploadedFiles) window.unsavedUploadedFiles = []
							if (fileId && !window.unsavedUploadedFiles.includes(fileId)) {
								window.unsavedUploadedFiles.push(fileId)
							}
						}
					}

					// Cập nhật vào dataDetailFlow
					uploadedFiles.forEach((up) => {
						const detail = (this.dataDetailFlow || []).find((d) => d.Task_Detail_ID === up.Task_Detail_ID)
						if (detail) {
							detail.File_ID = up.File_ID
							detail.File_Name = up.File_Name
							detail.File_Type = up.File_Type
							detail.File_URL = up.File_URL
						}
					})

					this.uploadProgressText = "Đang lưu thay đổi vào cơ sở dữ liệu..."
					await this.saveChanges()

					Vue.$toast.success(`Đã cập nhật thành công ${uploadedFiles.length} file!`, { position: "top" })
					this.isQuickImportDialogOpen = false
					this.stagedFiles = []
				} catch (error) {
					console.error("Lỗi khi import file hàng loạt:", error)
					Vue.$toast.error("Có lỗi xảy ra khi tải lên file: " + (error.message || error), { position: "top" })
					await this.cleanupUnsavedFiles()
				} finally {
					this.isUploadingBatch = false
					this.uploadProgressText = ""
				}
			},

			closeModal() {
				this.$emit("input", false)
			},
		},
	}
</script>