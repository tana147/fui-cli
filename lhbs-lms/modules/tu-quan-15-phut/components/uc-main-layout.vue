<template>
	<div class="uc-tu-quan-15-phut pa-2 pa-sm-4">
		<!-- Header Card -->
		<v-card class="mb-2 mb-sm-3" elevation="1" rounded="lg">
			<v-card-item class="py-2 py-sm-3 px-3 px-sm-4">
				<div class="d-flex align-center flex-wrap ga-2 ga-sm-3">
					<v-avatar color="primary" size="38" class="text-white flex-shrink-0">
						<v-icon size="22">mdi-clock-check-outline</v-icon>
					</v-avatar>
					<div class="flex-grow-1">
						<div class="text-subtitle-1 text-sm-h6 font-weight-bold text-primary d-flex align-center flex-wrap ga-1 ga-sm-2">
							<span>15 phút tự quản đầu giờ</span>
							<span class="text-caption text-medium-emphasis d-none d-sm-inline">(7:15 – 7:30)</span>
							<v-chip size="x-small" color="primary" variant="tonal" class="font-weight-medium">2026 - 2027</v-chip>
						</div>
					</div>
					<div class="d-flex align-center ga-2">
						<!-- Chip vai trò kèm menu đổi vai trò thử nghiệm phân quyền -->
						<v-menu location="bottom end">
							<template v-slot:activator="{ props }">
								<v-chip
									v-bind="props"
									:color="currentRoleColor"
									size="small"
									:prepend-icon="currentRoleIcon"
									append-icon="mdi-menu-down"
									class="font-weight-medium text-white cursor-pointer px-3 elevation-1"
									variant="flat"
									title="Nhấn để đổi vai trò kiểm tra phân quyền"
								>
									{{ currentRoleName }}
								</v-chip>
							</template>
							<v-card min-width="270" class="pa-2 rounded-lg" elevation="4">
								<div class="d-flex align-center justify-space-between px-3 py-1">
									<span class="text-caption font-weight-medium text-medium-emphasis">Phân quyền vai trò</span>
									<v-chip size="x-small" color="primary" variant="tonal">FUI SystemRight</v-chip>
								</div>
								<v-divider class="my-1" />
								<v-list density="compact" nav>
									<v-list-item
										v-for="r in userRoles"
										:key="r.id"
										:value="r.id"
										:active="currentSystemRight === r.id"
										:color="r.color"
										@click="switchRole(r.id)"
										class="rounded-lg mb-1"
									>
										<template v-slot:prepend>
											<v-avatar size="28" :color="r.color" class="text-white me-2">
												<v-icon size="16" color="white">{{ r.icon }}</v-icon>
											</v-avatar>
										</template>
										<v-list-item-title class="font-weight-medium" style="font-size: 13px;">
											{{ r.name }}
										</v-list-item-title>
										<v-list-item-subtitle style="font-size: 11px;">
											{{ r.description }}
										</v-list-item-subtitle>
									</v-list-item>
								</v-list>
							</v-card>
						</v-menu>
					</div>
				</div>
			</v-card-item>

			<!-- Main Navigation Tabs (Phân quyền theo vai trò - Chỉ hiển thị khi có từ 2 tab trở lên như BGH/Admin) -->
			<v-divider v-if="hasMultipleTabs" />
			<v-tabs v-if="hasMultipleTabs" :key="'tabs-' + currentSystemRight" v-model="activeTab" color="primary" grow density="comfortable">
				<v-tab v-if="canAccessQuanSinh" value="quansinh" class="text-none font-weight-medium px-2 px-sm-4 text-caption text-sm-body-2">
					<v-icon start size="18" class="me-1">mdi-clipboard-check-outline</v-icon>
					<span class="d-none d-sm-inline">Quản sinh chấm điểm</span>
					<span class="d-inline d-sm-none">Quản sinh</span>
					<v-badge v-if="pendingCheckCount > 0" color="warning" :content="pendingCheckCount" inline class="ms-1" />
				</v-tab>
				<v-tab v-if="canAccessGvcn" value="gvcn" class="text-none font-weight-medium px-2 px-sm-4 text-caption text-sm-body-2">
					<v-icon start size="18" class="me-1">mdi-calendar-clock-outline</v-icon>
					<span class="d-none d-sm-inline">GVCN đăng kí lịch</span>
					<span class="d-inline d-sm-none">Lịch GVCN</span>
				</v-tab>
				<v-tab v-if="canAccessBaoCao" value="baocao" class="text-none font-weight-medium px-2 px-sm-4 text-caption text-sm-body-2">
					<v-icon start size="18" class="me-1">mdi-chart-box-outline</v-icon>
					<span class="d-none d-sm-inline">Báo cáo & thi đua</span>
					<span class="d-inline d-sm-none">Báo cáo</span>
				</v-tab>
			</v-tabs>

			<!-- Filter Bar (Nằm bên dưới Tab chức năng) -->
			<v-divider />
			<div class="px-3 px-sm-4 pt-2 pt-sm-3 bg-grey-lighten-5" :class="activeTab === 'quansinh' ? 'pb-1' : 'pb-2 pb-sm-3'">
				<!-- Row 1: Chọn Tuần (Thời khóa biểu), Khối, và Nút Làm Mới -->
				<div class="d-flex align-center flex-wrap ga-2 ga-sm-3" :class="{ 'mb-2': activeTab === 'quansinh' }">
					<!-- Chọn Tuần -->
					<div class="d-flex align-center ga-1 flex-grow-1 flex-sm-grow-0 w-100 w-sm-auto" style="min-width: 0; max-width: 100%;">
						<v-btn icon="mdi-chevron-left" variant="text" density="compact" :disabled="selectedWeekIndex <= 0" @click="prevWeek" />
						<v-select
							v-model="selectedWeek"
							:items="availableWeekList"
							item-title="title"
							item-value="id"
							return-object
							label="Thời khóa biểu"
							density="compact"
							variant="outlined"
							color="primary"
							hide-details
							prepend-inner-icon="mdi-calendar-outline"
							class="flex-grow-1 bg-white"
							style="min-width: 200px;"
							@update:model-value="onWeekSelected"
						/>
						<v-btn icon="mdi-chevron-right" variant="text" density="compact" :disabled="selectedWeekIndex >= availableWeekList.length - 1" @click="nextWeek" />
					</div>

					<!-- Chọn Khối (chỉ hiện khi không phải GVCN) -->
					<div v-if="!isGVCNRole" style="min-width: 110px;" class="flex-grow-1 flex-sm-grow-0">
						<v-select
							v-model="selectedKhoi"
							:items="khoiList"
							item-title="name"
							item-value="id"
							label="Khối lớp"
							density="compact"
							variant="outlined"
							hide-details
							class="bg-white"
							@update:model-value="onFilterChanged"
						/>
					</div>

					<v-spacer class="d-none d-md-block" />

					<!-- Nút làm mới (Desktop) -->
					<v-btn class="d-none d-sm-flex text-none font-weight-medium" prepend-icon="mdi-refresh" variant="outlined" color="teal" size="small" :loading="isLoading" @click="reloadData">
						Làm mới
					</v-btn>

					<!-- Nút làm mới (Mobile) -->
					<v-btn class="d-flex d-sm-none" icon="mdi-refresh" variant="outlined" color="teal" density="compact" size="small" :loading="isLoading" @click="reloadData" />
				</div>

				<!-- Row 2: Chọn Ngày (Thứ 2 - Thứ 6) full width segmented bar (Chỉ hiện khi ở Tab Quản sinh chấm điểm) -->
				<v-btn-toggle
					v-if="activeTab === 'quansinh'"
					v-model="selectedDay"
					mandatory
					density="compact"
					variant="text"
					class="w-100 d-flex mobile-days-toggle"
					@update:model-value="onDayChanged"
				>
					<v-btn
						v-for="d in daysOfWeek"
						:key="d.val"
						:value="d.val"
						:disabled="isSpecificDayInFuture(d.val)"
						class="text-none flex-grow-1 px-1"
						style="flex: 1 1 0% !important; min-width: 0 !important;"
						:style="{ opacity: isSpecificDayInFuture(d.val) ? 0.38 : 1, cursor: isSpecificDayInFuture(d.val) ? 'not-allowed' : 'pointer' }"
					>
						<div class="text-center py-1 w-100">
							<div class="d-flex align-center justify-center ga-1" style="line-height: 1.2;">
								<span class="font-weight-bold d-none d-sm-inline" style="font-size: 12px;">{{ d.label }}</span>
								<span class="font-weight-bold d-inline d-sm-none" style="font-size: 12px;">T{{ d.val }}</span>
								<v-icon
									v-if="isSpecificDayInPast(d.val)"
									size="12"
									color="blue-grey-darken-1"
									title="Đã qua ngày"
								>mdi-lock-outline</v-icon>
								<v-icon
									v-else-if="isSpecificDayToday(d.val)"
									size="12"
									:color="isPastQsCutoffTime() ? 'blue-grey-darken-1' : 'primary'"
									:title="isPastQsCutoffTime() ? 'Hôm nay (Đã khóa sau 09:30)' : 'Hôm nay (Đang mở)'"
								>{{ isPastQsCutoffTime() ? 'mdi-lock-clock' : 'mdi-pencil' }}</v-icon>
								<v-icon
									v-else-if="isSpecificDayInFuture(d.val)"
									size="12"
									color="grey-lighten-1"
									title="Chưa đến ngày"
								>mdi-clock-outline</v-icon>
							</div>
							<div class="d-flex align-center justify-center ga-1 mt-0.5" style="font-size: 10px; line-height: 1;">
								<span class="text-medium-emphasis">{{ d.date }}</span>
								<span v-if="isSpecificDayInPast(d.val)" class="text-blue-grey-darken-1 font-weight-medium d-none d-sm-inline" style="font-size: 9.5px;">(Khóa)</span>
								<span v-else-if="isSpecificDayToday(d.val)" :class="isPastQsCutoffTime() ? 'text-blue-grey-darken-1 font-weight-medium' : 'text-primary font-weight-medium'" class="d-none d-sm-inline" style="font-size: 9.5px;">{{ isPastQsCutoffTime() ? '(Khóa sau 9h30)' : '(Mở)' }}</span>
								<span v-else-if="isSpecificDayInFuture(d.val)" class="text-grey font-weight-medium d-none d-sm-inline" style="font-size: 9.5px;">(Chưa đến)</span>
							</div>
						</div>
					</v-btn>
				</v-btn-toggle>
			</div>
		</v-card>

		<!-- TAB CONTENT -->
		<v-window :key="'window-' + currentSystemRight" v-model="activeTab">
			<!-- TAB 1: QUẢN SINH CHẤM ĐIỂM -->
			<v-window-item value="quansinh">
				<!-- Action Toolbar Quản sinh (Tinh gọn, chuẩn Executive UX) -->
				<v-card class="mb-3 pa-2 pa-sm-3" elevation="0" rounded="lg" border>
					<div class="d-flex align-center justify-space-between flex-wrap ga-2">
						<!-- Nhóm thông tin trạng thái: Nổi bật thứ đang chấm to rõ, chuẩn LMS -->
						<div class="d-flex align-center ga-2 flex-wrap">
							<v-tooltip location="bottom" :text="isTodayQsLocked ? 'Hệ thống đã khóa sau 09:30 theo quy định nhà trường. Dữ liệu đã chốt tự động gửi cho GVCN & BGH.' : (isPastDay ? 'Ngày đã qua, dữ liệu đã khóa lưu trữ.' : (isFutureDay ? 'Chưa đến ngày, hệ thống chưa mở chấm.' : ''))" :disabled="!isReadOnlyDay || isBghRole">
								<template #activator="{ props: lockProps }">
									<v-chip
										v-bind="lockProps"
										:color="isBghRole ? 'primary' : (isPastDay ? 'blue-grey-darken-1' : (isTodayQsLocked ? 'blue-grey-darken-1' : (isFutureDay ? 'grey-darken-1' : (selectedDay === 2 ? 'blue-grey-darken-2' : 'primary'))))"
										variant="flat"
										size="small"
										class="font-weight-medium px-3 rounded-pill text-white shadow-sm"
										style="min-height: 28px;"
									>
										<v-icon start size="15" color="white">{{ isPastDay || isTodayQsLocked ? 'mdi-lock-outline' : (isFutureDay ? 'mdi-clock-outline' : (selectedDay === 2 ? 'mdi-school' : 'mdi-calendar-check')) }}</v-icon>
										{{ isPastDay ? ('Đã khóa: ' + currentDayLabel) : (isTodayQsLocked ? ('Đã khóa sau 09:30: ' + currentDayLabel) : (isFutureDay ? ('Chưa đến ngày: ' + currentDayLabel) : (selectedDay === 2 ? ('Thứ 2: GVCN sinh hoạt (không chấm)') : (isBghRole ? ('Đang xem: ' + currentDayLabel) : ('Đang chấm: ' + currentDayLabel))))) }}
									</v-chip>
								</template>
							</v-tooltip>
							<span class="text-caption text-medium-emphasis">({{ selectedKhoiName }} · {{ currentClasses.length }} lớp)</span>
							<v-chip v-if="selectedDay === 2" size="x-small" color="blue-grey" variant="tonal" class="font-weight-medium px-2 rounded-pill">
								<v-icon start size="13">mdi-school</v-icon>
								Thứ Hai: GVCN sinh hoạt toàn trường
							</v-chip>
							<template v-else>
								<v-chip size="x-small" color="indigo" variant="tonal" class="font-weight-medium px-2 rounded-pill">
									<v-icon start size="13">mdi-account-group</v-icon>
									Lớp tự quản: {{ tuQuanClassesCount }}/{{ currentClasses.length }}
								</v-chip>
								<v-chip v-if="gvcnSinHoatCount > 0" size="x-small" color="blue-grey" variant="tonal" class="font-weight-medium px-2 rounded-pill">
									<v-icon start size="13">mdi-account-tie</v-icon>
									GVCN sinh hoạt: {{ gvcnSinHoatCount }}
								</v-chip>
							</template>
						</div>

						<!-- Nhóm thao tác tinh gọn (Desktop): Tự động lưu chuẩn Executive UX đồng bộ giống GVCN -->
						<div class="d-none d-sm-flex align-center ga-2">
							<v-btn
								v-if="!isBghRole"
								size="small"
								color="teal"
								variant="outlined"
								prepend-icon="mdi-check-all"
								class="text-none font-weight-medium"
								:disabled="isReadOnlyDay || selectedDay === 2"
								@click="markAllGood"
							>
								Chấm tất cả Tốt
							</v-btn>

							<!-- Badge chỉ xem cho BGH -->
							<v-chip
								v-if="isBghRole"
								color="grey-darken-2"
								size="small"
								variant="tonal"
								class="font-weight-medium px-3 rounded-pill"
								style="min-height: 28px;"
							>
								<v-icon start size="15" color="grey-darken-2">mdi-eye-outline</v-icon>
								<span class="font-weight-medium">Chế độ xem</span>
							</v-chip>

							<!-- Trạng thái tự động lưu của Quản sinh (chỉ hiển thị khi đang trong ngày được chấm) -->
							<v-chip
								v-if="!isBghRole && !isReadOnlyDay && selectedDay !== 2"
								:color="qsAutoSaveStatus === 'saving' ? 'amber-darken-3' : 'success'"
								size="small"
								:variant="qsAutoSaveStatus === 'saving' ? 'flat' : 'tonal'"
								class="font-weight-medium px-3 rounded-pill"
								style="transition: all 0.25s ease; min-height: 28px;"
							>
								<template v-if="qsAutoSaveStatus === 'saving'">
									<v-progress-circular indeterminate size="12" width="2" color="white" class="me-1.5" />
									<span class="text-white font-weight-medium">Đang lưu...</span>
								</template>
								<template v-else>
									<v-icon start size="15" color="success">mdi-cloud-check</v-icon>
									<span class="font-weight-medium text-success-darken-2">Đã lưu tự động</span>
									<span v-if="qsLastSavedTime" class="ms-1 text-caption text-grey-darken-1" style="font-size: 10.5px;">({{ qsLastSavedTime }})</span>
								</template>
							</v-chip>

							<!-- Menu Tiện ích: Gom In phiếu, Thêm tiêu chí, Zalo gọn gàng -->
							<v-menu location="bottom end">
								<template #activator="{ props }">
									<v-btn
										v-bind="props"
										size="small"
										variant="outlined"
										color="grey-darken-2"
										append-icon="mdi-chevron-down"
										class="text-none font-weight-medium"
									>
										Tiện ích
									</v-btn>
								</template>
								<v-list density="compact" rounded="lg" elevation="2">
									<v-list-item
										prepend-icon="mdi-printer"
										title="In phiếu chấm (Sao đỏ)"
										@click="openPrintDialog"
									/>
									<v-list-item
										v-if="!isReadOnlyDay"
										prepend-icon="mdi-plus-box-outline"
										title="Thêm tiêu chí ngày này"
										@click="openAddCriteriaDialog(null)"
									/>
									<v-list-item
										prepend-icon="mdi-share-variant-outline"
										title="Sao chép gửi Zalo"
										@click="exportDailyReport"
									/>
									<v-divider class="my-1" />
									<v-list-subheader class="text-caption font-weight-bold text-uppercase" style="font-size: 10px; height: 26px;">Giả lập mốc giờ kiểm thử</v-list-subheader>
									<v-list-item
										prepend-icon="mdi-clock-outline"
										title="Giờ thực tế hệ thống"
										:active="mockHourOverride === null"
										@click="setMockTime(null)"
									/>
									<v-list-item
										prepend-icon="mdi-clock-fast"
										title="Trước 6h sáng (05:30 - Mở hết)"
										:active="mockHourOverride === 5"
										@click="setMockTime(5, 30)"
									/>
									<v-list-item
										prepend-icon="mdi-clock-fast"
										title="08:00 sáng (Sau 6h sáng, trước 9h30: Khóa GV, Mở QS)"
										:active="mockHourOverride === 8"
										@click="setMockTime(8, 0)"
									/>
									<v-list-item
										prepend-icon="mdi-clock-alert"
										title="Sau 9h30 sáng (10:00 - Khóa cả GV & QS)"
										:active="mockHourOverride === 10"
										@click="setMockTime(10, 0)"
									/>
								</v-list>
							</v-menu>
						</div>

						<!-- Nhóm thao tác Mobile: Tự động lưu giống GVCN -->
						<div class="d-flex d-sm-none align-center ga-1.5 w-100 justify-space-between pt-1 border-t">
							<v-btn
								v-if="!isBghRole"
								size="small"
								color="teal"
								variant="outlined"
								class="text-none font-weight-medium"
								:disabled="isReadOnlyDay || selectedDay === 2"
								@click="markAllGood"
							>
								Tất cả Tốt
							</v-btn>

							<!-- Chip Chế độ xem Mobile -->
							<v-chip
								v-if="isBghRole"
								color="grey-darken-2"
								size="small"
								variant="tonal"
								class="font-weight-medium px-2 rounded-pill flex-grow-1 justify-center"
							>
								<v-icon start size="13" color="grey-darken-2">mdi-eye-outline</v-icon>
								Chế độ xem
							</v-chip>

							<!-- Chip tự động lưu Mobile (chỉ hiển thị khi đang trong ngày được chấm) -->
							<v-chip
								v-if="!isBghRole && !isReadOnlyDay && selectedDay !== 2"
								:color="qsAutoSaveStatus === 'saving' ? 'amber-darken-3' : 'success'"
								size="small"
								:variant="qsAutoSaveStatus === 'saving' ? 'flat' : 'tonal'"
								class="font-weight-medium px-2 rounded-pill flex-grow-1 justify-center"
							>
								<template v-if="qsAutoSaveStatus === 'saving'">
									<v-progress-circular indeterminate size="11" width="2" color="white" class="me-1" />
									Đang lưu...
								</template>
								<template v-else>
									<v-icon start size="13" color="success">mdi-cloud-check</v-icon>
									Đã tự lưu <span v-if="qsLastSavedTime" class="ms-0.5" style="font-size: 10px;">({{ qsLastSavedTime }})</span>
								</template>
							</v-chip>

							<v-menu location="bottom end">
								<template #activator="{ props }">
									<v-btn v-bind="props" icon="mdi-dots-vertical" size="small" variant="text" />
								</template>
								<v-list density="compact" rounded="lg">
									<v-list-item prepend-icon="mdi-printer" title="In phiếu chấm" @click="openPrintDialog" />
									<v-list-item v-if="!isReadOnlyDay" prepend-icon="mdi-plus" title="Thêm tiêu chí" @click="openAddCriteriaDialog(null)" />
									<v-list-item prepend-icon="mdi-share-variant-outline" title="Gửi Zalo" @click="exportDailyReport" />
									<v-divider class="my-1" />
									<v-list-item prepend-icon="mdi-clock-outline" title="Giờ thực tế" @click="setMockTime(null)" />
									<v-list-item prepend-icon="mdi-clock-fast" title="05:30 sáng (Mở hết)" @click="setMockTime(5, 30)" />
									<v-list-item prepend-icon="mdi-clock-fast" title="08:00 sáng (Khóa GV, Mở QS)" @click="setMockTime(8, 0)" />
									<v-list-item prepend-icon="mdi-clock-alert" title="10:00 sáng (Khóa GV & QS)" @click="setMockTime(10, 0)" />
								</v-list>
							</v-menu>
						</div>
					</div>
				</v-card>

				<!-- Thông báo đặc biệt Thứ 2: Toàn trường GVCN sinh hoạt đầu tuần -->
				<v-alert
					v-if="selectedDay === 2"
					type="info"
					variant="tonal"
					density="compact"
					rounded="lg"
					class="mb-3 py-1.5 border"
					icon="mdi-school"
				>
					<div class="text-caption font-weight-medium">
						<strong>Thứ Hai — Tiết sinh hoạt đầu tuần cùng GVCN:</strong>
						Toàn bộ các lớp trong trường sinh hoạt trực tiếp cùng Giáo viên chủ nhiệm. Ngày này không áp dụng tự quản và Quản sinh không chấm nề nếp tự quản.
					</div>
				</v-alert>


				<!-- BẢNG TỔNG HỢP (DESKTOP >= 960px) -->
				<v-card elevation="0" rounded="lg" class="mb-4 overflow-hidden border d-none d-md-block" style="border-color: #eaecf0 !important;">
					<div class="table-responsive">
						<table class="w-100 evaluation-master-table" style="font-size: 13px;">
							<thead>
								<tr style="height: 44px;">
									<th style="width: 45px; text-align: center; padding: 6px;">STT</th>
									<th style="width: 135px; text-align: left; padding: 6px 10px;">Lớp & GVCN</th>
									<th
										v-for="(tc, i) in getMergedPrintCriteria()"
										:key="'tbl-th-' + tc.id"
										style="text-align: center; padding: 6px 3px; width: 130px; min-width: 118px; max-width: 145px; position: relative;"
										:class="{ 'bg-blue-lighten-5': tc.isCustom }"
									>
										<!-- Nút Xóa tiêu chí bổ sung -->
										<v-tooltip v-if="tc.isCustom && !isReadOnlyDay" text="Xóa tiêu chí này" location="top">
											<template #activator="{ props: delProps }">
												<v-btn
													v-bind="delProps"
													icon="mdi-close"
													size="x-small"
													variant="flat"
													color="red-lighten-5"
													class="text-error font-weight-medium"
													style="position: absolute; top: 3px; right: 3px; width: 22px; height: 22px; min-width: 22px; z-index: 2;"
													@click.stop="removeCustomCriterion(tc)"
												/>
											</template>
										</v-tooltip>

										<!-- Vùng hiển thị thông tin tiêu chí có tooltip hướng xuống dưới -->
										<v-tooltip location="bottom" :open-delay="200">
											<template #activator="{ props: tooltipProps }">
												<div
													v-bind="tooltipProps"
													class="cursor-help d-flex flex-column align-center justify-center py-1"
													style="user-select: none;"
												>
													<div class="font-weight-medium text-grey-darken-4 text-center px-0.5" style="font-size: 11.5px; line-height: 1.25;">
														{{ (i + 1) + '. ' + getCriterionMainTitle(tc.ten) }}
													</div>
													<div v-if="getCriterionSubTitle(tc.ten)" class="text-grey-darken-2 text-center px-0.5 mt-0.5" style="font-size: 10px; line-height: 1.2; font-weight: 500;">
														{{ getCriterionSubTitle(tc.ten) }}
													</div>
												</div>
											</template>
											<span><strong>{{ (i + 1) + '. ' + getCriterionMainTitle(tc.ten) }}</strong> {{ getCriterionSubTitle(tc.ten) }}</span>
											<div v-if="tc.isCustom" class="text-caption text-amber-lighten-3">
												({{ tc.scope === 'class' ? (tc.tenLop ? 'Áp dụng riêng: Lớp ' + tc.tenLop : 'Áp dụng riêng 1 lớp') : 'Tiêu chí bổ sung cả khối' }})
											</div>
										</v-tooltip>
									</th>
									<th style="min-width: 250px; text-align: left; padding: 6px 12px;">Ghi chú vi phạm / nhận xét</th>
									<th style="width: 110px; min-width: 105px; text-align: center; padding: 6px;">Xếp loại</th>
								</tr>
							</thead>
							<tbody>
								<tr
									v-for="(cls, idx) in currentClasses"
									:key="'tbl-row-' + cls.LopID"
									class="table-row-hover"
									:class="{
										'bg-red-lighten-5': itemHasViolation(cls),
										'bg-blue-grey-lighten-5': (selectedDay === 2 || !cls.IsTuQuan) && !itemHasViolation(cls)
									}"
									style="height: 46px;"
								>
									<!-- Cột STT -->
									<td style="text-align: center; font-weight: 500; color: #666;">
										{{ idx + 1 }}
									</td>

									<!-- Cột Lớp & GVCN & Trạng thái ngày -->
									<td style="padding: 6px 12px;">
										<div class="d-flex flex-column justify-center">
											<div class="d-flex align-center ga-2">
												<span class="font-weight-medium text-subtitle-2 text-primary" style="font-size: 14px; line-height: 22px;">{{ cls.TenLop }}</span>
												<span
													v-if="selectedDay === 2 || !cls.IsTuQuan"
													class="table-status-badge badge-gvcn"
												>
													<v-icon size="13" class="me-1" color="blue-grey-darken-2">mdi-account-tie</v-icon>
													GVCN sinh hoạt
												</span>
												<span
													v-else
													class="table-status-badge badge-tuquan"
												>
													<v-icon size="13" class="me-1" color="indigo-darken-3">mdi-account-group</v-icon>
													Tự quản
												</span>
											</div>
											<div class="text-caption text-truncate text-medium-emphasis mt-0.5" style="max-width: 160px; font-size: 11.5px; line-height: 1.2;">
												{{ cls.TenGVCN }}
											</div>
										</div>
									</td>

									<!-- Các cột Tiêu chí -->
									<td
										v-for="(tc, i) in getMergedPrintCriteria()"
										:key="'tbl-tc-' + cls.LopID + '-' + tc.id"
										style="text-align: center; padding: 4px 2px; width: 130px; min-width: 118px; max-width: 145px;"
									>
										<div v-if="selectedDay === 2 || !cls.IsTuQuan" class="text-medium-emphasis font-weight-medium" style="font-size: 12px;">
											—
										</div>
										<div v-else-if="isClassHavingCriteria(cls, tc)" class="d-inline-flex justify-center w-100">
											<div class="score-group" :class="{ 'score-disabled': isReadOnlyDay }">
												<button
													type="button"
													class="score-btn-item score-btn-t"
													:class="{ 'score-active-t': findClassCriterion(cls, tc).score === 3 }"
													:disabled="isReadOnlyDay"
													title="Tốt (3 điểm)"
													@click="setCriterionScore(cls, tc, 3)"
												>
													T
												</button>
												<button
													type="button"
													class="score-btn-item score-btn-d"
													:class="{ 'score-active-d': findClassCriterion(cls, tc).score === 2 }"
													:disabled="isReadOnlyDay"
													title="Đạt (2 điểm)"
													@click="setCriterionScore(cls, tc, 2)"
												>
													Đ
												</button>
												<button
													type="button"
													class="score-btn-item score-btn-cd"
													:class="{ 'score-active-cd': findClassCriterion(cls, tc).score === 1 }"
													:disabled="isReadOnlyDay"
													title="Chưa đạt (1 điểm)"
													@click="setCriterionScore(cls, tc, 1)"
												>
													CĐ
												</button>
											</div>
										</div>
										<span v-else style="color: #bbb;">—</span>
									</td>

									<!-- Cột Ghi chú / Nhận xét -->
									<td style="padding: 4px 8px; min-width: 200px;">
										<v-textarea
											v-model="cls.GhiChuViPham"
											:placeholder="selectedDay === 2 ? 'Thứ 2: GVCN sinh hoạt cùng lớp...' : (!cls.IsTuQuan ? 'GVCN sinh hoạt cùng lớp (Không chấm tự quản)...' : (isFutureDay ? 'Chưa đến ngày (Khóa nhận xét)...' : (isPastDay ? 'Ngày đã qua (Khóa không cho sửa)...' : 'Nhập ghi chú / nội dung vi phạm...')))"
											density="compact"
											variant="plain"
											hide-details
											auto-grow
											rows="1"
											max-rows="4"
											:disabled="isReadOnlyDay || selectedDay === 2 || !cls.IsTuQuan"
											class="compact-table-textarea"
											:class="{ 'opacity-60': isReadOnlyDay || selectedDay === 2 || !cls.IsTuQuan }"
											style="font-size: 13px !important;"
											:input-attrs="{ style: 'font-size: 13px !important; line-height: 1.4 !important;' }"
											@update:model-value="onQsNoteChange"
										/>
									</td>

									<!-- Cột Xếp loại -->
									<td style="text-align: center; padding: 4px;">
										<span v-if="getClassDailyResult(cls).code === 'GVCN'" class="text-medium-emphasis font-weight-medium" style="font-size: 13px;">—</span>
										<span
											v-else
											class="table-rank-badge"
											:class="{
												'rank-tot': getClassDailyResult(cls).code === 'T',
												'rank-dat': getClassDailyResult(cls).code === 'D',
												'rank-chuadat': getClassDailyResult(cls).code === 'CD'
											}"
										>
											{{ getScoreBadgeText(cls) }}
										</span>
									</td>
								</tr>
							</tbody>
						</table>
					</div>
				</v-card>

				<!-- DANH SÁCH THẺ LỚP HỌC MOBILE (< 960px): CHUẨN UX ĐIỆN THOẠI, KHÔNG CUỘN NGANG -->
				<div class="d-block d-md-none d-flex flex-column ga-3 mb-4">
					<v-card
						v-for="(cls, idx) in currentClasses"
						:key="'m-cls-card-' + cls.LopID"
						elevation="0"
						rounded="xl"
						class="border bg-white overflow-hidden"
						:class="{
							'border-red-lighten-2 bg-red-lighten-5': itemHasViolation(cls),
							'border-grey-lighten-2': !itemHasViolation(cls)
						}"
					>
						<!-- Header Thẻ: Lớp, GVCN & Xếp loại -->
						<div class="px-3 py-2.5 bg-grey-lighten-5 border-b d-flex align-center justify-space-between flex-wrap ga-2">
							<div class="d-flex align-center ga-2">
								<v-avatar color="primary" size="24" class="text-white text-caption font-weight-medium">
									{{ idx + 1 }}
								</v-avatar>
								<div>
									<div class="d-flex align-center ga-1.5">
										<span class="font-weight-medium text-subtitle-2 text-primary">{{ cls.TenLop }}</span>
										<span
											v-if="selectedDay === 2 || !cls.IsTuQuan"
											class="table-status-badge badge-gvcn"
											style="height: 20px; font-size: 10.5px;"
										>
											<v-icon size="12" class="me-0.5" color="blue-grey-darken-2">mdi-account-tie</v-icon>
											GVCN sinh hoạt
										</span>
										<span
											v-else
											class="table-status-badge badge-tuquan"
											style="height: 20px; font-size: 10.5px;"
										>
											<v-icon size="12" class="me-0.5" color="indigo-darken-3">mdi-account-group</v-icon>
											Tự quản
										</span>
									</div>
									<div class="text-caption text-medium-emphasis" style="font-size: 11px;">
										GVCN: {{ cls.TenGVCN }}
									</div>
								</div>
							</div>

							<!-- Badge xếp loại trên Mobile Card -->
							<div>
								<span v-if="getClassDailyResult(cls).code === 'GVCN'" class="text-medium-emphasis font-weight-medium text-caption">—</span>
								<span
									v-else
									class="table-rank-badge"
									:class="{
										'rank-tot': getClassDailyResult(cls).code === 'T',
										'rank-dat': getClassDailyResult(cls).code === 'D',
										'rank-chuadat': getClassDailyResult(cls).code === 'CD'
									}"
								>
									{{ getScoreBadgeText(cls) }}
								</span>
							</div>
						</div>

						<!-- Nội dung chấm điểm trên Mobile -->
						<div class="pa-3">
							<!-- Nếu GVCN sinh hoạt / Thứ 2: Thông báo ngắn gọn -->
							<div v-if="selectedDay === 2 || !cls.IsTuQuan" class="pa-2.5 rounded-lg bg-grey-lighten-4 text-center text-caption text-medium-emphasis">
								<v-icon size="16" color="blue-grey" class="me-1">mdi-account-tie</v-icon>
								GVCN trực tiếp sinh hoạt — Không chấm điểm tự quản
							</div>

							<!-- Nếu lớp tự quản: Hiển thị từng tiêu chí bấm T - Đ - CĐ to rõ ngón tay dễ chạm -->
							<div v-else class="d-flex flex-column ga-2">
								<div
									v-for="(tc, i) in getMergedPrintCriteria()"
									:key="'m-tc-' + cls.LopID + '-' + tc.id"
									class="pa-2 rounded-lg bg-grey-lighten-5 d-flex align-center justify-space-between ga-2"
								>
									<div class="flex-grow-1 pe-1">
										<div class="font-weight-medium text-grey-darken-4 text-caption" style="line-height: 1.3;">
											{{ (i + 1) + '. ' + getCriterionMainTitle(tc.ten) }}
										</div>
										<div v-if="getCriterionSubTitle(tc.ten)" class="text-caption text-grey-darken-1" style="font-size: 10.5px; line-height: 1.2;">
											{{ getCriterionSubTitle(tc.ten) }}
										</div>
									</div>

									<!-- Nút bấm điểm T - Đ - CĐ kích thước to, dễ bấm trên màn hình cảm ứng -->
									<div class="score-group flex-shrink-0" :class="{ 'score-disabled': isReadOnlyDay }">
										<button
											type="button"
											class="score-btn-item score-btn-t"
											:class="{ 'score-active-t': findClassCriterion(cls, tc).score === 3 }"
											:disabled="isReadOnlyDay"
											style="width: 32px; height: 32px; font-size: 13px;"
											@click="setCriterionScore(cls, tc, 3)"
										>
											T
										</button>
										<button
											type="button"
											class="score-btn-item score-btn-d"
											:class="{ 'score-active-d': findClassCriterion(cls, tc).score === 2 }"
											:disabled="isReadOnlyDay"
											style="width: 32px; height: 32px; font-size: 13px;"
											@click="setCriterionScore(cls, tc, 2)"
										>
											Đ
										</button>
										<button
											type="button"
											class="score-btn-item score-btn-cd"
											:class="{ 'score-active-cd': findClassCriterion(cls, tc).score === 1 }"
											:disabled="isReadOnlyDay"
											style="width: 32px; height: 32px; font-size: 13px;"
											@click="setCriterionScore(cls, tc, 1)"
										>
											CĐ
										</button>
									</div>
								</div>

								<!-- Ô nhận xét / ghi chú vi phạm trên Mobile -->
								<div class="mt-1">
									<div class="text-caption font-weight-medium text-grey-darken-3 mb-1">Ghi chú vi phạm / nhận xét:</div>
									<v-textarea
										v-model="cls.GhiChuViPham"
										placeholder="Nhập ghi chú vi phạm nếu có..."
										density="compact"
										variant="outlined"
										hide-details
										auto-grow
										rows="1"
										max-rows="3"
										:disabled="isReadOnlyDay"
										class="bg-white"
										style="font-size: 12.5px;"
										@update:model-value="onQsNoteChange"
									/>
								</div>
							</div>
						</div>
					</v-card>
				</div>
			</v-window-item>

			<!-- TAB 2: GVCN ĐĂNG KÍ LỊCH TRỰC & THEO DÕI NỀ NẾP TUẦN -->
			<v-window-item value="gvcn">
				<!-- KHỐI 1: ĐĂNG KÍ LỊCH TRỰC DIỆN TUẦN -->
				<v-card class="mb-3 pa-3" elevation="0" rounded="lg" border style="border-color: #eaecf0 !important;">
					<!-- Dòng 1: Thông tin lớp & Dropdown đổi lớp & Nút lưu -->
					<div class="d-flex align-center justify-space-between flex-wrap ga-2 pb-2.5 mb-2.5 border-b" style="border-bottom-color: #f1f5f9 !important;">
						<!-- Trái: Tên lớp, GVCN -->
						<div class="d-flex align-center flex-wrap" style="gap: 12px;">
							<v-avatar color="teal-lighten-5" size="36" class="border border-teal-lighten-3 elevation-1">
								<v-icon color="teal-darken-2" size="20">mdi-google-classroom</v-icon>
							</v-avatar>
							<div>
								<div class="d-flex align-center flex-wrap ga-2">
									<span class="font-weight-medium text-subtitle-1 text-primary" style="font-size: 16px !important; line-height: 1.2;">
										Lớp {{ gvcnClassInfo.TenLop }}
									</span>
								</div>
								<div class="text-caption text-medium-emphasis" style="font-size: 12px !important;">
									GVCN: <span class="text-grey-darken-3 font-weight-medium">{{ gvcnClassInfo.TenGVCN }}</span> · Sĩ số: <span class="font-weight-medium">{{ gvcnClassInfo.SiSo }} học sinh</span>
								</div>
							</div>
						</div>

						<!-- Phải: Dropdown đổi lớp (chỉ hiện khi là BGH/Admin) & Badge & Nút Lưu -->
						<div class="d-flex align-center ga-2 flex-wrap w-100 w-sm-auto justify-space-between justify-sm-end">
							<!-- Dropdown đổi lớp: Chỉ hiển thị cho BGH/Admin -->
							<div v-if="!isGVCNRole" class="flex-grow-1 flex-sm-grow-0" style="min-width: 240px; max-width: 100%;">
								<v-select
									v-model="selectedGvcnClassId"
									:items="availableGvcnClasses"
									item-title="label"
									item-value="LopID"
									label="Đổi lớp xem lịch"
									density="compact"
									variant="outlined"
									hide-details
									prepend-inner-icon="mdi-google-classroom"
									class="bg-white"
									@update:model-value="onGvcnClassChanged"
								/>
							</div>

							<!-- Nhóm Badge số buổi & Trạng thái Tự động lưu (Bỏ hẳn nút Lưu) -->
							<div class="d-flex align-center ga-2 flex-wrap flex-grow-1 flex-sm-grow-0 justify-space-between justify-sm-end w-100 w-sm-auto">
								<v-chip
									:color="gvcnTargetMet ? 'success' : 'warning'"
									size="small"
									class="font-weight-medium px-3 rounded-pill text-white flex-grow-1 flex-sm-grow-0 justify-center"
									variant="flat"
								>
									<v-icon start size="14" color="white">{{ gvcnTargetMet ? 'mdi-check-circle' : 'mdi-alert-circle' }}</v-icon>
									Tự quản: {{ gvcnTuQuanCount }}/4 ngày {{ gvcnTargetMet ? '(đạt chỉ tiêu ≥ 2)' : '(cần tối thiểu 2 ngày)' }}
								</v-chip>

								<!-- Trạng thái: Lịch sử tuần trước (Đã khóa) HOẶC Trạng thái tự động lưu -->
								<v-chip
									v-if="isPastSelectedWeek"
									color="blue-grey-darken-1"
									size="small"
									variant="tonal"
									class="font-weight-medium px-3 rounded-pill flex-grow-1 flex-sm-grow-0 justify-center"
									style="min-height: 28px;"
								>
									<v-icon start size="15" color="blue-grey-darken-1">mdi-lock-outline</v-icon>
									<span class="font-weight-medium">Lịch sử tuần trước (đã khóa)</span>
								</v-chip>
								<v-chip
									v-else
									:color="autoSaveStatus === 'saving' ? 'amber-darken-3' : 'success'"
									size="small"
									:variant="autoSaveStatus === 'saving' ? 'flat' : 'tonal'"
									class="font-weight-medium px-3 rounded-pill flex-grow-1 flex-sm-grow-0 justify-center"
									style="transition: all 0.25s ease; min-height: 28px;"
								>
									<template v-if="autoSaveStatus === 'saving'">
										<v-progress-circular indeterminate size="12" width="2" color="white" class="me-1.5" />
										<span class="text-white font-weight-medium">Đang lưu...</span>
									</template>
									<template v-else>
										<v-icon start size="15" color="success">mdi-cloud-check</v-icon>
										<span class="font-weight-medium text-success-darken-2">Đã lưu tự động</span>
										<span v-if="lastSavedTime" class="ms-1 text-caption text-grey-darken-1" style="font-size: 10.5px;">({{ lastSavedTime }})</span>
									</template>
								</v-chip>
							</div>
						</div>
					</div>

					<!-- Cảnh báo lớp dính chế tài tạm dừng tự quản -->
					<v-alert
						v-if="isClassBlocked(selectedGvcnClassId)"
						type="error"
						variant="tonal"
						density="comfortable"
						class="mb-3"
						icon="mdi-alert-octagon"
					>
						<div class="font-weight-medium d-flex align-center ga-2 mb-1">
							<span style="font-size: 13.5px;">Tạm dừng tự quản (chế tài 01 tuần)</span>
							<v-chip size="x-small" color="error" variant="flat" class="text-white font-weight-medium px-1.5">Quy chế nề nếp</v-chip>
						</div>
						<div class="text-caption" style="font-size: 12px; line-height: 1.55;">
							<div><strong>a) Biểu hiện xem xét:</strong> Tuần tự quản trước bị ghi nhận Chưa đạt (CĐ).</div>
							<div><strong>b) Hệ quả:</strong> Tạm dừng tự quản 01 tuần tiếp theo. GVCN bắt buộc phải quay lại có mặt trực tiếp 5/5 buổi hằng ngày lúc 7:15 để trực tiếp quản lý, củng cố xây dựng lại nền nếp lớp.</div>
							<div class="text-medium-emphasis mt-0.5"><em>* Sau khi củng cố, nếu được đánh giá lớp đạt yêu cầu, GVCN tiếp tục đăng kí cho lớp tự quản.</em></div>
						</div>
					</v-alert>

					<!-- LƯỚI THỜI KHÓA BIỂU ĐĂNG KÍ (TKB GRID TRỰC QUAN) -->
					<div class="mb-3 border rounded-lg overflow-hidden bg-white" style="border-color: #eaecf0 !important;">
						<!-- Tiêu đề các ngày trong tuần (TKB Header) -->
						<div class="d-flex text-center border-b" style="background-color: #f8fafc; border-bottom-color: #f1f5f9 !important;">
							<div
								v-for="day in gvcnWeekSchedule"
								:key="'tkb-head-' + day.key"
								class="flex-grow-1 py-1 px-0.5 border-e"
								:class="{
									'bg-blue-grey-lighten-5 text-blue-grey-darken-3': day.key === 2,
									'bg-indigo-lighten-5 text-primary font-weight-medium': day.key !== 2 && day.IsTuQuan,
									'text-grey-darken-3 font-weight-medium': day.key !== 2 && !day.IsTuQuan
								}"
								style="flex-basis: 0; min-width: 0;"
							>
								<div class="d-flex align-center justify-center ga-0.5 font-weight-medium text-caption" style="font-size: 11.5px; line-height: 1.2;">
									<span class="d-none d-sm-inline">{{ day.label }}</span>
									<span class="d-inline d-sm-none font-weight-bold">T{{ day.key }}</span>
									<span class="text-medium-emphasis font-weight-normal ms-0.5" style="font-size: 10px;">({{ day.date }})</span>
									<v-icon v-if="isDayGvcnLocked(day.key)" size="11" color="grey-darken-1">mdi-lock-outline</v-icon>
								</div>
							</div>
						</div>

						<!-- Các ô TKB: Chiều cao tinh gọn 46px (không chiếm diện tích) -->
						<div class="d-flex text-center" style="min-height: 46px;">
							<template v-for="day in gvcnWeekSchedule" :key="'tkb-cell-' + day.key">
								<!-- 1. THỨ 2 CỐ ĐỊNH: Bắt buộc toàn trường GVCN sinh hoạt -->
								<div
									v-if="day.key === 2"
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center border-e tkb-stripe-disabled"
									style="flex-basis: 0; min-width: 0; cursor: not-allowed; user-select: none;"
									title="Thứ 2: Bắt buộc toàn trường GVCN sinh hoạt đầu tuần"
									@click="showNotice('Thứ Hai bắt buộc GVCN sinh hoạt đầu tuần toàn trường, không áp dụng tự quản!', 'info')"
								>
									<div class="d-flex align-center ga-0.5 text-blue-grey-darken-2 font-weight-medium" style="font-size: 11px; line-height: 1.2;">
										<v-icon size="12" color="blue-grey-darken-1">mdi-lock</v-icon>
										<span class="d-none d-sm-inline">GVCN sinh hoạt</span>
										<span class="d-inline d-sm-none">GVCN</span>
									</div>
									<div class="text-caption text-medium-emphasis mt-0.5 d-none d-sm-block" style="font-size: 9.5px; line-height: 1;">
										(Cố định)
									</div>
								</div>

								<!-- 2. NGÀY ĐÃ QUA TRONG QUÁ KHỨ -->
								<div
									v-else-if="isSpecificDayInPast(day.key)"
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center border-e tkb-stripe-disabled"
									style="flex-basis: 0; min-width: 0; cursor: not-allowed; user-select: none;"
									:title="'Ngày ' + day.label + ' đã qua! Dữ liệu đã khóa lưu trữ lịch sử.'"
									@click="showNotice('Ngày ' + day.label + ' đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể chỉnh sửa.', 'info')"
								>
									<div class="d-flex align-center ga-0.5 font-weight-medium" :class="day.IsTuQuan ? 'text-teal-darken-3' : 'text-blue-grey-darken-2'" style="font-size: 11px; line-height: 1.2;">
										<v-icon size="12" :color="day.IsTuQuan ? 'teal' : 'blue-grey-darken-1'">mdi-lock</v-icon>
										<span class="d-none d-sm-inline">{{ day.IsTuQuan ? 'Lớp tự quản' : 'GVCN sinh hoạt' }}</span>
										<span class="d-inline d-sm-none">{{ day.IsTuQuan ? 'Tự quản' : 'GVCN' }}</span>
									</div>
									<div class="text-caption text-medium-emphasis mt-0.5 d-none d-sm-block" style="font-size: 9px; line-height: 1;">
										(Đã khóa)
									</div>
								</div>

								<!-- 2.1 NGÀY HÔM NAY SAU 06:00 SÁNG -->
								<div
									v-else-if="isSpecificDayToday(day.key) && isPastGvcnCutoffTime()"
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center border-e tkb-stripe-disabled"
									style="flex-basis: 0; min-width: 0; cursor: not-allowed; user-select: none;"
									:title="'Đã quá 06:00 sáng hôm nay (' + day.label + ')! Không thể đăng ký hoặc thay đổi lịch.'"
									@click="showNotice('Đã quá 06:00 sáng hôm nay (' + day.label + ')! Không thể đăng ký hoặc thay đổi lịch theo quy định của nhà trường.', 'warning')"
								>
									<div class="d-flex align-center ga-0.5 font-weight-medium" :class="day.IsTuQuan ? 'text-teal-darken-3' : 'text-blue-grey-darken-2'" style="font-size: 11px; line-height: 1.2;">
										<v-icon size="12" :color="day.IsTuQuan ? 'teal' : 'blue-grey-darken-1'">mdi-lock</v-icon>
										<span class="d-none d-sm-inline">{{ day.IsTuQuan ? 'Lớp tự quản' : 'GVCN sinh hoạt' }}</span>
										<span class="d-inline d-sm-none">{{ day.IsTuQuan ? 'Tự quản' : 'GVCN' }}</span>
									</div>
									<div class="text-caption text-medium-emphasis mt-0.5 d-none d-sm-block" style="font-size: 9px; line-height: 1;">
										(Khóa 6h)
									</div>
								</div>

								<!-- 2.5 LỚP ĐANG DÍNH CHẾ TÀI -->
								<div
									v-else-if="isClassBlocked(selectedGvcnClassId)"
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center border-e bg-red-lighten-5 cursor-not-allowed"
									style="flex-basis: 0; min-width: 0; user-select: none;"
									@click="showNotice('Lớp đang chấp hành chế tài tạm dừng tự quản 01 tuần! GVCN bắt buộc phải quay lại có mặt trực tiếp 5/5 buổi hằng ngày lúc 7:15 để củng cố xây dựng lại nền nếp lớp.', 'warning')"
								>
									<div class="d-flex align-center ga-0.5 font-weight-medium text-error" style="font-size: 11px; line-height: 1.2;">
										<v-icon size="12" color="error">mdi-account-tie</v-icon>
										<span class="d-none d-sm-inline">GVCN có mặt</span>
										<span class="d-inline d-sm-none">7:15</span>
									</div>
									<div class="text-caption text-error font-weight-medium mt-0.5 d-none d-sm-block" style="font-size: 9px; line-height: 1;">
										(Chế tài)
									</div>
								</div>

								<!-- 3. NGÀY CHO PHÉP CHỌN & ĐÃ ĐĂNG KÍ TỰ QUẢN -->
								<div
									v-else-if="day.IsTuQuan"
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center border-e tkb-cell-registered cursor-pointer transition-all"
									style="flex-basis: 0; min-width: 0; user-select: none;"
									title="Bấm để chuyển về GVCN sinh hoạt"
									@click="toggleGvcnDay(day)"
								>
									<div class="d-flex align-center ga-0.5 text-success-darken-1 font-weight-medium" style="font-size: 11px; line-height: 1.2;">
										<v-icon size="13" color="success">mdi-check-circle</v-icon>
										<span class="d-none d-sm-inline">Lớp tự quản</span>
										<span class="d-inline d-sm-none">Tự quản</span>
									</div>
									<div class="text-caption text-grey-darken-1 mt-0.5 d-none d-sm-block" style="font-size: 9px; line-height: 1;">
										(Bấm đổi)
									</div>
								</div>

								<!-- 4. NGÀY CHO PHÉP CHỌN & CHƯA ĐĂNG KÍ (GVCN SINH HOẠT) -->
								<div
									v-else
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center border-e tkb-cell-available cursor-pointer transition-all"
									style="flex-basis: 0; min-width: 0; user-select: none;"
									:title="'Bấm vào để đăng kí tự quản cho ' + day.label"
									@click="toggleGvcnDay(day)"
								>
									<div class="d-flex align-center ga-0.5 text-grey-darken-3 font-weight-medium" style="font-size: 11px; line-height: 1.2;">
										<v-icon size="12" color="grey-darken-2">mdi-account-tie</v-icon>
										<span class="d-none d-sm-inline">GVCN sinh hoạt</span>
										<span class="d-inline d-sm-none">GVCN</span>
									</div>
									<div class="text-primary font-weight-medium mt-0.5 d-inline-flex align-center ga-0.5" style="font-size: 9.5px; line-height: 1;">
										<v-icon size="11" color="primary">mdi-plus-circle-outline</v-icon>
										<span class="d-none d-sm-inline">Đăng kí tự quản</span>
										<span class="d-inline d-sm-none">Đăng kí</span>
									</div>
								</div>
							</template>
						</div>

						<!-- HÀNG 2: GHI CHÚ RIÊNG CHO TỪNG NGÀY (Gọn gàng 22px) -->
						<div class="d-flex text-center border-t" style="background-color: #fafbfc; border-top-color: #f1f5f9 !important;">
							<div
								v-for="day in gvcnWeekSchedule"
								:key="'tkb-note-' + day.key"
								class="flex-grow-1 py-1 px-1 border-e tkb-note-cell d-flex align-center justify-center"
								:class="{ 'tkb-stripe-disabled': isDayGvcnLocked(day.key) }"
								style="flex-basis: 0; min-width: 0;"
							>
								<input
									type="text"
									v-model="day.GhiChu"
									:placeholder="day.key === 2 ? 'Cố định' : (isDayGvcnLocked(day.key) ? 'Đã khóa' : 'Ghi chú...')"
									:disabled="isDayGvcnLocked(day.key)"
									class="tkb-note-native-input"
									@input="onNoteInput"
								/>
							</div>
						</div>
					</div>
				</v-card>

				<!-- KHỐI 2: NHẬT KÍ ĐÁNH GIÁ NỀ NẾP LỚP TRONG TUẦN (BẢNG NGANG GỌN GÀNG, 1 VIEW NHÌN THẤY TOÀN BỘ) -->
				<v-card elevation="0" rounded="lg" class="overflow-hidden border" style="border-color: #eaecf0 !important;">
					<div class="px-3 py-2 bg-grey-lighten-5 border-b d-flex align-center justify-space-between flex-wrap ga-2" style="border-bottom-color: #f1f5f9 !important;">
						<div class="d-flex align-center ga-2 text-primary font-weight-bold" style="font-size: 13px;">
							<v-icon size="18">mdi-clipboard-text-clock-outline</v-icon>
							<span>Nhật ký quản sinh chấm điểm nề nếp lớp {{ gvcnClassInfo.TenLop }} — {{ selectedWeek ? selectedWeek.title : 'Tuần này' }}</span>
							<v-chip v-if="isPastSelectedWeek" size="x-small" color="blue-grey" variant="flat" class="ms-1 text-white font-weight-medium">
								Dữ liệu lịch sử tuần trước
							</v-chip>
						</div>
						<div class="text-caption text-medium-emphasis font-italic" style="font-size: 11px;">
							[T] = Tốt · [Đ] = Đạt · [CĐ] = Cần cố gắng
						</div>
					</div>

					<!-- Bảng Desktop (>= 960px) -->
					<div class="d-none d-md-block table-responsive">
						<table class="w-100 evaluation-master-table" style="font-size: 12.5px;">
							<thead>
								<tr style="height: 38px;">
									<th style="width: 120px; text-align: left; padding: 4px 10px;">Thứ & ngày</th>
									<th style="width: 110px; text-align: center; padding: 4px;">Lịch GVCN</th>
									<th style="width: 130px; min-width: 120px; text-align: center; padding: 6px 4px; vertical-align: middle;">
										<div class="font-weight-medium text-grey-darken-4" style="font-size: 12px; line-height: 1.25;">1. Không gian lớp</div>
										<div class="text-grey-darken-2 mt-0.5" style="font-size: 11px; line-height: 1.25; font-weight: 400;">(Mở cửa, VS, bàn ghế)</div>
									</th>
									<th style="width: 165px; min-width: 145px; text-align: center; padding: 6px 4px; vertical-align: middle;">
										<div class="font-weight-medium text-grey-darken-4" style="font-size: 12px; line-height: 1.25;">2. Nền nếp & chuẩn bị tâm thế học tập</div>
										<div class="text-grey-darken-2 mt-0.5" style="font-size: 11px; line-height: 1.25; font-weight: 400;">(Sĩ số, tác phong, sách vở)</div>
									</th>
									<th style="width: 130px; min-width: 120px; text-align: center; padding: 6px 4px; vertical-align: middle;">
										<div class="font-weight-medium text-grey-darken-4" style="font-size: 12px; line-height: 1.25;">3. Sinh hoạt chủ đề</div>
										<div class="text-grey-darken-2 mt-0.5" style="font-size: 11px; line-height: 1.25; font-weight: 400;">(Đúng 7:20, nghiêm túc)</div>
									</th>
									<th style="width: 105px; text-align: center; padding: 4px 8px; border-left: 1px solid #e2e8f0 !important; border-right: 1px solid #e2e8f0 !important;">Xếp loại</th>
									<th style="min-width: 250px; text-align: left; padding: 4px 14px;">Ghi chú vi phạm / nhận xét của Quản sinh</th>
									<th style="width: 130px; text-align: left; padding: 4px 10px;">Quản sinh chấm</th>
								</tr>
							</thead>
							<tbody>
								<tr
									v-for="log in gvcnClassHistory"
									:key="log.Ngay"
									class="table-row-hover"
									:class="{ 'bg-red-lighten-5': log.KetQua === 'CD' }"
									style="height: 38px;"
								>
									<td class="font-weight-medium text-left" style="padding: 4px 10px;">
										{{ log.ThuLabel }} ({{ log.Ngay }})
									</td>
									<td style="text-align: center; padding: 4px;">
										<span v-if="log.ThuLabel === 'Thứ 2'" class="text-blue-grey-darken-2 font-weight-medium d-inline-flex align-center ga-1" style="font-size: 11.5px;">
											<v-icon size="14" color="blue-grey">mdi-school</v-icon> SH đầu tuần
										</span>
										<span v-else-if="!log.IsTuQuan" class="text-grey-darken-2 font-weight-medium d-inline-flex align-center ga-1" style="font-size: 11.5px;">
											<v-icon size="14" color="grey-darken-2">mdi-account-tie</v-icon> GVCN sinh hoạt
										</span>
										<span v-else class="text-indigo font-weight-medium d-inline-flex align-center ga-1" style="font-size: 11.5px;">
											<v-icon size="14" color="indigo">mdi-account-group-outline</v-icon> Lớp tự quản
										</span>
									</td>
									<!-- TC1: Không gian -->
									<td style="text-align: center; padding: 4px;">
										<span v-if="log.KetQua === 'CHUA_CHAM' || log.ThuLabel === 'Thứ 2' || !log.IsTuQuan" class="text-medium-emphasis">—</span>
										<template v-else>
											<v-chip v-if="getLogCritScore(log, 0) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5" style="height: 20px;">
												CĐ
											</v-chip>
											<span v-else-if="getLogCritScore(log, 0) === 3" class="text-success font-weight-medium" style="font-size: 12px;">✓ Tốt</span>
											<span v-else-if="getLogCritScore(log, 0) === 2" class="text-grey-darken-2 font-weight-medium" style="font-size: 12px;">Đạt</span>
											<span v-else class="text-medium-emphasis">—</span>
										</template>
									</td>
									<!-- TC2: Nền nếp -->
									<td style="text-align: center; padding: 4px;">
										<span v-if="log.KetQua === 'CHUA_CHAM' || log.ThuLabel === 'Thứ 2' || !log.IsTuQuan" class="text-medium-emphasis">—</span>
										<template v-else>
											<v-chip v-if="getLogCritScore(log, 1) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5" style="height: 20px;">
												CĐ
											</v-chip>
											<span v-else-if="getLogCritScore(log, 1) === 3" class="text-success font-weight-medium" style="font-size: 12px;">✓ Tốt</span>
											<span v-else-if="getLogCritScore(log, 1) === 2" class="text-grey-darken-2 font-weight-medium" style="font-size: 12px;">Đạt</span>
											<span v-else class="text-medium-emphasis">—</span>
										</template>
									</td>
									<!-- TC3: Chủ đề -->
									<td style="text-align: center; padding: 4px;">
										<span v-if="log.KetQua === 'CHUA_CHAM' || log.ThuLabel === 'Thứ 2' || !log.IsTuQuan" class="text-medium-emphasis">—</span>
										<template v-else>
											<v-chip v-if="getLogCritScore(log, 2) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5" style="height: 20px;">
												CĐ
											</v-chip>
											<span v-else-if="getLogCritScore(log, 2) === 3" class="text-success font-weight-medium" style="font-size: 12px;">✓ Tốt</span>
											<span v-else-if="getLogCritScore(log, 2) === 2" class="text-grey-darken-2 font-weight-medium" style="font-size: 12px;">Đạt</span>
											<span v-else class="text-medium-emphasis">—</span>
										</template>
									</td>
									<!-- Xếp loại -->
									<td style="text-align: center; padding: 4px 8px; border-left: 1px solid #e2e8f0 !important; border-right: 1px solid #e2e8f0 !important;">
										<v-chip
											v-if="log.KetQua === 'CHUA_CHAM'"
											size="x-small"
											color="grey-darken-1"
											variant="tonal"
											class="font-weight-medium rounded-pill px-2"
										>
											Chưa diễn ra
										</v-chip>
										<span
											v-else-if="log.ThuLabel === 'Thứ 2' || !log.IsTuQuan"
											class="text-medium-emphasis font-weight-medium"
											style="font-size: 13px;"
										>
											—
										</span>
										<v-chip
											v-else
											size="x-small"
											:color="log.KetQua === 'T' ? 'success' : (log.KetQua === 'D' ? 'primary' : 'error')"
											:variant="log.KetQua === 'CD' ? 'flat' : 'tonal'"
											:class="log.KetQua === 'CD' ? 'font-weight-bold rounded-pill px-2' : 'font-weight-medium rounded-pill px-2'"
										>
											{{ log.KetQua === 'T' ? 'Tốt' : (log.KetQua === 'D' ? 'Đạt' : 'Chưa đạt') }}
										</v-chip>
									</td>
									<!-- Ghi chú vi phạm -->
									<td class="text-left" style="padding: 4px 14px;">
										<span v-if="log.NoiDungViPham" class="text-error font-weight-medium">
											⚠️ {{ log.NoiDungViPham }}
										</span>
										<span v-else class="text-medium-emphasis">—</span>
									</td>
									<!-- Quản sinh chấm -->
									<td class="text-left text-medium-emphasis" style="padding: 4px 10px; font-size: 11px;">
										<span v-if="log.ThuLabel === 'Thứ 2' || !log.IsTuQuan || log.KetQua === 'CHUA_CHAM'">—</span>
										<span v-else>{{ log.NguoiCham || '—' }}</span>
									</td>
								</tr>
								<tr v-if="gvcnClassHistory.length === 0">
									<td colspan="8" class="text-center pa-4 text-medium-emphasis">
										Chưa có dữ liệu đánh giá nào trong tuần này.
									</td>
								</tr>
							</tbody>
						</table>
					</div>

					<!-- Danh sách thẻ Mobile (< 960px): Mỗi ngày 1 card rõ ràng, không cuộn ngang -->
					<div class="d-flex d-md-none flex-column pa-2 ga-2">
						<div
							v-for="log in gvcnClassHistory"
							:key="'m-log-' + log.Ngay"
							class="pa-3 rounded-lg border bg-white"
							:class="{ 'border-red-lighten-2 bg-red-lighten-5': log.KetQua === 'CD' }"
						>
							<div class="d-flex align-center justify-space-between mb-2">
								<div class="d-flex align-center ga-1">
									<v-icon size="16" color="primary">mdi-calendar-check</v-icon>
									<span class="font-weight-medium text-body-2">{{ log.ThuLabel }} ({{ log.Ngay }})</span>
								</div>
								<div class="d-flex align-center ga-1">
									<span v-if="log.ThuLabel === 'Thứ 2'" class="text-caption text-blue-grey-darken-2 font-weight-medium">SH đầu tuần</span>
									<span v-else-if="!log.IsTuQuan" class="text-caption text-grey-darken-2 font-weight-medium">GVCN sinh hoạt</span>
									<span v-else class="text-caption text-indigo font-weight-medium">Lớp tự quản</span>
									<v-chip v-if="log.KetQua === 'CHUA_CHAM'" size="x-small" color="grey-darken-1" variant="tonal" class="font-weight-medium rounded-pill px-2 ms-1">
										Chưa diễn ra
									</v-chip>
									<v-chip v-else-if="log.ThuLabel !== 'Thứ 2' && log.IsTuQuan" size="x-small" :color="log.KetQua === 'T' ? 'success' : (log.KetQua === 'D' ? 'grey-darken-1' : 'error')" variant="flat" :class="log.KetQua === 'CD' ? 'font-weight-bold rounded-pill text-white px-2 ms-1' : 'font-weight-medium rounded-pill text-white px-2 ms-1'">
										{{ log.KetQua === 'T' ? 'Tốt' : (log.KetQua === 'D' ? 'Đạt' : 'CĐ') }}
									</v-chip>
								</div>
							</div>

							<!-- 3 Tiêu chí đầy đủ -->
							<div v-if="log.KetQua === 'CHUA_CHAM'" class="pa-2 rounded bg-grey-lighten-5 border text-center text-caption text-medium-emphasis mb-2 font-italic">
								Chưa diễn ra buổi tự quản
							</div>
							<div v-else-if="log.ThuLabel === 'Thứ 2' || !log.IsTuQuan" class="pa-2 rounded bg-grey-lighten-5 border text-center text-caption text-medium-emphasis mb-2">
								GVCN sinh hoạt lớp — Không chấm điểm tự quản
							</div>
							<div v-else class="d-flex flex-column ga-1.5 mb-2 pa-2 rounded bg-grey-lighten-5 border">
								<div class="d-flex align-center justify-space-between" style="font-size: 11.5px;">
									<span class="font-weight-medium text-grey-darken-3">1. Không gian lớp (Mở cửa, VS, bàn ghế)</span>
									<span class="ms-2">
										<v-chip v-if="getLogCritScore(log, 0) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5">CĐ</v-chip>
										<span v-else-if="getLogCritScore(log, 0) === 3" class="text-success font-weight-medium">✓ Tốt</span>
										<span v-else-if="getLogCritScore(log, 0) === 2" class="text-grey-darken-2 font-weight-medium">Đạt</span>
										<span v-else class="text-medium-emphasis">—</span>
									</span>
								</div>
								<div class="d-flex align-center justify-space-between" style="font-size: 11.5px;">
									<span class="font-weight-medium text-grey-darken-3">2. Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)</span>
									<span class="ms-2">
										<v-chip v-if="getLogCritScore(log, 1) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5">CĐ</v-chip>
										<span v-else-if="getLogCritScore(log, 1) === 3" class="text-success font-weight-medium">✓ Tốt</span>
										<span v-else-if="getLogCritScore(log, 1) === 2" class="text-grey-darken-2 font-weight-medium">Đạt</span>
										<span v-else class="text-medium-emphasis">—</span>
									</span>
								</div>
								<div class="d-flex align-center justify-space-between" style="font-size: 11.5px;">
									<span class="font-weight-medium text-grey-darken-3">3. Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)</span>
									<span class="ms-2">
										<v-chip v-if="getLogCritScore(log, 2) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5">CĐ</v-chip>
										<span v-else-if="getLogCritScore(log, 2) === 3" class="text-success font-weight-medium">✓ Tốt</span>
										<span v-else-if="getLogCritScore(log, 2) === 2" class="text-grey-darken-2 font-weight-medium">Đạt</span>
										<span v-else class="text-medium-emphasis">—</span>
									</span>
								</div>
							</div>

							<!-- Ghi chú vi phạm nếu có -->
							<div v-if="log.NoiDungViPham" class="pa-2 rounded bg-red-lighten-4 border border-red-lighten-3 text-caption text-error font-weight-bold mb-1">
								⚠️ {{ log.NoiDungViPham }}
							</div>

							<div class="d-flex justify-end text-caption text-medium-emphasis" style="font-size: 10.5px;">
								<span v-if="log.ThuLabel === 'Thứ 2' || !log.IsTuQuan || log.KetQua === 'CHUA_CHAM'">Người chấm: —</span>
								<span v-else>Người chấm: {{ log.NguoiCham || '—' }}</span>
							</div>
						</div>
						<div v-if="gvcnClassHistory.length === 0" class="text-center pa-4 text-medium-emphasis text-caption">
							Chưa có dữ liệu đánh giá nào trong tuần này.
						</div>
					</div>
				</v-card>
			</v-window-item>

			<!-- TAB 3: BÁO CÁO & THI ĐUA (THEO NGÀY · THEO TUẦN · THEO THÁNG & ĐỐI CHIẾU 4 TUẦN MINH BẠCH) -->
			<v-window-item value="baocao">
				<!-- 1. BỘ CHUYỂN ĐỔI CHẾ ĐỘ XEM & ĐIỀU HƯỚNG BÁO CÁO -->
				<div class="mb-3">
					<!-- Hàng 1: Chế độ xem & Thao tác in/xuất -->
					<div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-2">
						<div class="d-flex align-center ga-2 flex-grow-1 flex-sm-grow-0">
							<span class="text-caption font-weight-medium text-grey-darken-3 d-none d-sm-inline">Chế độ xem:</span>
							<v-btn-toggle v-model="bghViewMode" mandatory color="primary" density="compact" rounded="lg" class="flex-grow-1 flex-sm-grow-0">
								<v-btn value="day" prepend-icon="mdi-calendar-today" class="text-none font-weight-medium px-2 px-sm-3 flex-grow-1 flex-sm-grow-0" style="font-size: 11.5px; height: 32px;">
									<span class="d-none d-sm-inline">Báo cáo theo </span>Ngày
								</v-btn>
								<v-btn value="month" prepend-icon="mdi-trophy-outline" class="text-none font-weight-medium px-2 px-sm-3 flex-grow-1 flex-sm-grow-0" style="font-size: 11.5px; height: 32px;">
									<span class="d-none d-sm-inline">Tổng hợp & </span>Thi đua
								</v-btn>
							</v-btn-toggle>
						</div>

						<!-- Khi xem theo Tháng trên Desktop: hiển thị thông tin tháng đánh giá thi đua -->
						<div v-if="bghViewMode === 'month'" class="d-none d-md-flex align-center ga-1.5 text-caption font-weight-medium text-grey-darken-3 px-1">
							<v-icon size="16" color="primary">mdi-calendar-month</v-icon>
							<span>Tháng {{ currentEvaluationMonth }}/2026 (4 tuần đánh giá)</span>
						</div>

						<!-- Nhóm nút In báo cáo & Sao chép nhanh gửi Zalo -->
						<div class="d-flex align-center ga-2 ms-auto">
							<v-btn
								size="small"
								variant="outlined"
								color="primary"
								prepend-icon="mdi-printer"
								class="text-none font-weight-medium"
								@click="openPrintDialog(bghViewMode === 'month' ? 'bgh_summary' : 'daily')"
							>
								In phiếu / báo cáo
							</v-btn>
							<v-btn
								size="small"
								variant="outlined"
								color="grey-darken-3"
								prepend-icon="mdi-share-variant-outline"
								class="text-none font-weight-medium"
								@click="exportDailyReport"
							>
								Gửi Zalo
							</v-btn>
						</div>
					</div>

					<!-- Hàng 2: Thanh chọn ngày trong tuần (2 dòng: Thứ ở trên, Ngày ở dưới) -->
					<div v-if="bghViewMode === 'day'" class="w-100">
						<v-btn-toggle
							:model-value="bghActiveDay"
							mandatory
							density="compact"
							color="primary"
							variant="flat"
							rounded="lg"
							class="w-100 d-flex bg-white border"
							style="border-color: #eaecf0 !important; height: 44px; min-height: 44px;"
							@update:model-value="val => { if (!isSpecificDayInFuture(val)) bghSelectedDay = val; }"
						>
							<v-btn
								v-for="d in daysOfWeek"
								:key="'bgh-bar-day-' + d.val"
								:value="d.val"
								:disabled="isSpecificDayInFuture(d.val)"
								class="text-none flex-grow-1 px-1 font-weight-medium"
								style="flex: 1 1 0% !important; min-width: 0 !important; height: 100% !important;"
								:style="{
									opacity: isSpecificDayInFuture(d.val) ? 0.38 : 1,
									cursor: isSpecificDayInFuture(d.val) ? 'not-allowed' : 'pointer'
								}"
								:title="isSpecificDayInFuture(d.val) ? 'Chưa tới ngày (chưa có dữ liệu)' : (d.label + ' (' + d.date + ')')"
							>
								<div class="text-center py-0.5 w-100">
									<!-- Dòng 1: Thứ ở trên -->
									<div class="d-flex align-center justify-center ga-1" style="line-height: 1.2;">
										<span class="d-none d-sm-inline font-weight-medium" style="font-size: 11.5px;">{{ d.label }}</span>
										<span class="d-inline d-sm-none font-weight-bold" style="font-size: 11.5px;">T{{ d.val }}</span>
										<span v-if="isSpecificDayToday(d.val)" class="font-weight-bold" style="font-size: 9.5px; opacity: 0.95;">(Nay)</span>
									</div>
									<!-- Dòng 2: Ngày ở dưới -->
									<div class="text-caption mt-0.5" style="font-size: 10px; line-height: 1;" :class="bghActiveDay === d.val ? 'text-white' : 'text-medium-emphasis'">
										{{ d.date }}
									</div>
								</div>
							</v-btn>
						</v-btn-toggle>
					</div>
				</div>

				<!-- 2. THANH CHỈ SỐ TỔNG HỢP (METRIC STRIP TỐI GIẢN THEO CHẾ ĐỘ XEM) -->
				<v-card elevation="0" rounded="lg" class="mb-3 border bg-white px-3 py-2">
					<div class="d-flex align-center justify-space-between flex-wrap ga-2 text-caption">
						<!-- Inline metrics khi xem theo Ngày -->
						<div v-if="bghViewMode === 'day'" class="d-flex align-center ga-3 ga-sm-4 flex-wrap">
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">Tự quản {{ bghIsViewingToday ? 'hôm nay' : bghActiveDayLabel }}:</span>
								<span class="font-weight-bold text-grey-darken-4">{{ reportSummary.tuQuanCount }}/{{ reportSummary.totalClasses }} lớp</span>
							</div>
							<v-divider vertical class="my-1 d-none d-sm-block" />
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">Xếp loại Tốt:</span>
								<span class="font-weight-bold text-success">{{ reportSummary.goodCount }} lớp</span>
							</div>
							<v-divider vertical class="my-1 d-none d-sm-block" />
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">Chưa đạt (CĐ):</span>
								<span class="font-weight-bold" :class="reportSummary.violationCount > 0 ? 'text-error' : 'text-grey-darken-3'">
									{{ reportSummary.violationCount }} lớp
								</span>
							</div>
							<v-divider vertical class="my-1 d-none d-sm-block" />
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">Đang xem:</span>
								<span class="font-weight-bold text-grey-darken-4">{{ bghActiveDayLabel }}</span>
							</div>
						</div>

						<!-- Inline metrics khi xem Tổng hợp & Thi đua -->
						<div v-else class="d-flex align-center ga-3 ga-sm-4 flex-wrap">
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">Chu kỳ đánh giá tháng:</span>
								<span class="font-weight-bold text-grey-darken-4">4 tuần liên tiếp</span>
							</div>
							<v-divider vertical class="my-1 d-none d-sm-block" />
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">{{ monthlySummaryStats.labelKhenThuong }}</span>
								<span class="font-weight-bold text-success">{{ monthlySummaryStats.khenThuongDetail }}</span>
							</div>
							<template v-if="monthlySummaryStats.showBieuDuong">
								<v-divider vertical class="my-1 d-none d-sm-block" />
								<div class="d-flex align-center">
									<span class="text-medium-emphasis me-1">Biểu dương nỗ lực:</span>
									<span class="font-weight-bold text-grey-darken-4">{{ monthlySummaryStats.bieuDuongDetail }}</span>
								</div>
							</template>
							<v-divider vertical class="my-1 d-none d-sm-block" />
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">Tạm dừng tự quản:</span>
								<span class="font-weight-bold" :class="monthlySummaryStats.tamDungCount > 0 ? 'text-error' : 'text-grey-darken-4'">{{ monthlySummaryStats.tamDungDetail }}</span>
							</div>
						</div>

						<div class="text-caption text-medium-emphasis font-italic d-none d-md-block">
							{{ bghViewMode === 'day' ? 'Dữ liệu chấm điểm trực tiếp từ Quản sinh khối' : 'Theo dõi nề nếp & thi đua 4 tuần trong tháng' }}
						</div>
					</div>
				</v-card>

				<!-- CHẾ ĐỘ 1: XEM THEO NGÀY (CHI TIẾT ĐẦY ĐỦ TOÀN BỘ CÁC LỚP TRONG NGÀY) -->
				<div v-if="bghViewMode === 'day'" class="d-flex flex-column ga-3">
					<!-- Báo cáo nhanh vi phạm ngày đang chọn -->
					<div v-if="todayViolations.length === 0" class="pa-2.5 rounded-lg bg-grey-lighten-5 border d-flex align-center ga-2 text-caption font-weight-medium text-grey-darken-3">
						<v-icon size="18" :color="reportSummary.tuQuanCount === 0 ? 'info' : 'success'">{{ reportSummary.tuQuanCount === 0 ? 'mdi-information-outline' : 'mdi-check-circle-outline' }}</v-icon>
						<span v-if="reportSummary.tuQuanCount === 0">Ngày {{ bghActiveDayLabel }} không có lớp tự quản (toàn khối GVCN trực tiếp sinh hoạt). Không có vi phạm.</span>
						<span v-else>Tất cả các lớp trong khối đạt nề nếp ngày {{ bghActiveDayLabel }}. Không có vi phạm.</span>
					</div>
					<div v-else class="pa-2.5 rounded-lg bg-grey-lighten-5 border">
						<div class="d-flex align-center ga-2 text-error font-weight-bold text-caption mb-1.5">
							<v-icon size="16" color="error">mdi-alert-circle-outline</v-icon>
							<span>Ghi nhận {{ todayViolations.length }} lớp có vi phạm ngày {{ bghActiveDayLabel }}:</span>
						</div>
						<div class="d-flex flex-column ga-1.5">
							<div
								v-for="v in todayViolations"
								:key="'td-day-v-' + v.LopID"
								class="pa-2 bg-white rounded border text-caption"
							>
								<div class="d-flex align-center justify-space-between mb-1">
									<span class="font-weight-bold text-grey-darken-4">Lớp {{ v.TenLop }} <span class="font-weight-regular text-medium-emphasis">({{ v.TenGVCN }})</span></span>
									<span class="text-error font-weight-bold">Chưa đạt</span>
								</div>
								<div class="d-flex align-center flex-wrap ga-1 my-0.5">
									<span class="text-medium-emphasis me-1">Vi phạm:</span>
									<template v-if="getViolatedCriteriaList(v).length">
										<span v-for="(vtc, vtcIdx) in getViolatedCriteriaList(v)" :key="'bgh-vtc-day-' + vtcIdx" class="badge-tc-violation">
											<span class="tc-code-tag">{{ vtc.code }}</span>{{ vtc.name }}
										</span>
									</template>
									<span v-else class="badge-tc-violation">Tiêu chí nề nếp</span>
								</div>
								<div v-if="v.GhiChuViPham" class="text-grey-darken-2 font-italic ps-1" style="font-size: 11.5px;">
									Ghi chú: {{ v.GhiChuViPham }}
								</div>
							</div>
						</div>
					</div>

					<!-- Bảng chi tiết toàn bộ các lớp trong ngày (Desktop >= 960px) -->
					<v-card elevation="0" rounded="lg" class="border overflow-hidden bg-white d-none d-md-block">
						<div class="px-3 py-2 bg-grey-lighten-4 border-b d-flex align-center justify-space-between">
							<div class="d-flex align-center ga-2">
								<v-icon color="grey-darken-3" size="18">mdi-format-list-checks</v-icon>
								<span class="font-weight-bold text-subtitle-2 text-grey-darken-4">
									Bảng theo dõi nề nếp 15 phút đầu giờ toàn khối — {{ bghActiveDayLabel }}
								</span>
							</div>
							<span class="text-caption text-medium-emphasis">Tổng số: {{ dayClassesDetail.length }} lớp</span>
						</div>

						<div class="table-responsive">
							<table class="w-100 evaluation-master-table" style="font-size: 12.5px;">
								<thead>
									<tr class="bg-grey-lighten-5" style="height: 38px;">
										<th class="text-center" style="width: 45px; padding: 6px;">STT</th>
										<th class="text-left" style="width: 75px; padding: 6px 10px;">Lớp</th>
										<th class="text-left" style="width: 175px; padding: 6px 10px;">GVCN</th>
										<th class="text-center" style="width: 140px; padding: 6px 8px;">Hình thức 15p</th>
										<th class="text-center" style="width: 130px; padding: 6px 8px;">GVCN có mặt (7:15)</th>
										<th class="text-center" style="width: 110px; padding: 6px 8px;">Xếp loại ngày</th>
										<th class="text-center" style="width: 95px; padding: 6px 4px;">TC1: K.Gian</th>
										<th class="text-center" style="width: 95px; padding: 6px 4px;">TC2: Nề nếp</th>
										<th class="text-center" style="width: 95px; padding: 6px 4px;">TC3: Chủ đề</th>
										<th class="text-left" style="padding: 6px 12px;">Ghi chú / Chi tiết vi phạm</th>
									</tr>
								</thead>
								<tbody>
									<tr
										v-for="row in dayClassesDetail"
										:key="'day-row-' + row.LopID"
										style="height: 44px;"
									>
										<td class="text-center" style="padding: 6px;">{{ row.STT }}</td>
										<td class="text-left font-weight-medium" style="padding: 6px 10px;">
											<span :class="row.HasViolation ? 'text-error font-weight-bold' : 'text-grey-darken-4 font-weight-medium'">{{ row.TenLop }}</span>
										</td>
										<td class="text-left font-weight-medium" style="padding: 6px 10px; color: #334155;">
											{{ row.TenGVCN }}
										</td>
										<td class="text-center" style="padding: 6px 8px;">
											<span class="table-rank-badge" :class="row.IsTuQuan ? 'rank-dat' : 'rank-gvcn'">
												{{ row.IsTuQuan ? 'Lớp tự quản' : 'GVCN sinh hoạt' }}
											</span>
										</td>
										<td class="text-center" style="padding: 6px 8px;">
											<span v-if="row.GVCNCoMat" class="text-success font-weight-medium d-flex align-center justify-center ga-1" style="font-size: 12px;">
												<v-icon size="15" color="success">mdi-check-circle</v-icon> Có mặt
											</span>
											<span v-else-if="row.IsTuQuan" class="text-medium-emphasis" style="font-size: 11.5px;">
												Lớp tự quản
											</span>
											<span v-else class="text-error font-weight-bold" style="font-size: 12px;">
												Vắng mặt
											</span>
										</td>
										<td class="text-center" style="padding: 6px 8px;">
											<span v-if="row.Result.code === 'GVCN' || row.Result.code === '—' || !row.IsTuQuan" class="text-medium-emphasis font-weight-medium" style="font-size: 13px;">—</span>
											<span
												v-else
												class="table-rank-badge"
												:class="{
													'rank-tot': row.Result.code === 'T',
													'rank-dat': row.Result.code === 'D',
													'rank-chuadat': row.Result.code === 'CD'
												}"
											>
												{{ row.Result.text }}
											</span>
										</td>
										<td class="text-center" style="padding: 6px 4px;">
											<span v-if="row.TC1 === null" class="text-medium-emphasis font-weight-medium">—</span>
											<span
												v-else
												class="table-rank-badge"
												:class="row.TC1 === 3 ? 'rank-tot' : (row.TC1 === 1 ? 'rank-chuadat' : 'rank-dat')"
											>
												{{ row.TC1 === 3 ? 'Tốt' : (row.TC1 === 1 ? 'CĐ' : 'Đạt') }}
											</span>
										</td>
										<td class="text-center" style="padding: 6px 4px;">
											<span v-if="row.TC2 === null" class="text-medium-emphasis font-weight-medium">—</span>
											<span
												v-else
												class="table-rank-badge"
												:class="row.TC2 === 3 ? 'rank-tot' : (row.TC2 === 1 ? 'rank-chuadat' : 'rank-dat')"
											>
												{{ row.TC2 === 3 ? 'Tốt' : (row.TC2 === 1 ? 'CĐ' : 'Đạt') }}
											</span>
										</td>
										<td class="text-center" style="padding: 6px 4px;">
											<span v-if="row.TC3 === null" class="text-medium-emphasis font-weight-medium">—</span>
											<span
												v-else
												class="table-rank-badge"
												:class="row.TC3 === 3 ? 'rank-tot' : (row.TC3 === 1 ? 'rank-chuadat' : 'rank-dat')"
											>
												{{ row.TC3 === 3 ? 'Tốt' : (row.TC3 === 1 ? 'CĐ' : 'Đạt') }}
											</span>
										</td>
										<td class="text-left" style="padding: 6px 12px;">
											<span v-if="row.HasViolation" class="text-error font-italic font-weight-medium">
												{{ row.GhiChuViPham }}
											</span>
											<span v-else-if="row.GhiChuViPham" class="text-caption text-medium-emphasis font-italic">
												{{ row.GhiChuViPham }}
											</span>
											<span v-else class="text-medium-emphasis">—</span>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
					</v-card>

					<!-- Danh sách thẻ Mobile BGH (< 960px): Chuẩn di động, xem từng lớp nhanh chóng -->
					<div class="d-block d-md-none d-flex flex-column ga-2.5">
						<v-card
							v-for="row in dayClassesDetail"
							:key="'m-bgh-row-' + row.LopID"
							elevation="0"
							rounded="lg"
							class="border bg-white overflow-hidden"
							:class="{ 'border-red-lighten-2 bg-red-lighten-5': row.HasViolation }"
						>
							<div class="px-3 py-2 bg-grey-lighten-5 border-b d-flex align-center justify-space-between flex-wrap ga-2">
								<div class="d-flex align-center ga-2">
									<v-avatar color="primary" size="24" class="text-white text-caption font-weight-bold">
										{{ row.STT }}
									</v-avatar>
									<div>
										<span class="font-weight-bold text-subtitle-2 text-primary me-1">{{ row.TenLop }}</span>
										<span class="text-caption text-medium-emphasis">({{ row.TenGVCN }})</span>
									</div>
								</div>
								<div class="d-flex align-center ga-1.5">
									<span class="table-rank-badge" :class="row.IsTuQuan ? 'rank-dat' : 'rank-gvcn'" style="font-size: 11px;">
										{{ row.IsTuQuan ? 'Tự quản' : 'GVCN sinh hoạt' }}
									</span>
									<span v-if="row.Result.code === 'GVCN' || row.Result.code === '—' || !row.IsTuQuan" class="text-medium-emphasis font-weight-medium text-caption">—</span>
									<span
										v-else
										class="table-rank-badge"
										:class="{
											'rank-tot': row.Result.code === 'T',
											'rank-dat': row.Result.code === 'D',
											'rank-chuadat': row.Result.code === 'CD'
										}"
										style="font-size: 11px;"
									>
										{{ row.Result.text }}
									</span>
								</div>
							</div>

							<div class="pa-2.5 text-caption">
								<div v-if="!row.IsTuQuan" class="text-medium-emphasis text-center py-1 font-italic">
									GVCN trực tiếp sinh hoạt cùng lớp (Không chấm tự quản)
								</div>
								<div v-else class="d-flex flex-column ga-1">
									<div class="d-flex align-center justify-space-between py-0.5 border-b">
										<span class="text-grey-darken-3">1. Không gian lớp:</span>
										<span class="font-weight-bold" :class="row.TC1 === 3 ? 'text-success' : (row.TC1 === 1 ? 'text-error' : 'text-primary')">
											{{ row.TC1 === 3 ? 'Tốt' : (row.TC1 === 1 ? 'Chưa đạt' : 'Đạt') }}
										</span>
									</div>
									<div class="d-flex align-center justify-space-between py-0.5 border-b">
										<span class="text-grey-darken-3">2. Nền nếp học tập:</span>
										<span class="font-weight-bold" :class="row.TC2 === 3 ? 'text-success' : (row.TC2 === 1 ? 'text-error' : 'text-primary')">
											{{ row.TC2 === 3 ? 'Tốt' : (row.TC2 === 1 ? 'Chưa đạt' : 'Đạt') }}
										</span>
									</div>
									<div class="d-flex align-center justify-space-between py-0.5">
										<span class="text-grey-darken-3">3. Sinh hoạt chủ đề:</span>
										<span class="font-weight-bold" :class="row.TC3 === 3 ? 'text-success' : (row.TC3 === 1 ? 'text-error' : 'text-primary')">
											{{ row.TC3 === 3 ? 'Tốt' : (row.TC3 === 1 ? 'Chưa đạt' : 'Đạt') }}
										</span>
									</div>
								</div>

								<div v-if="row.GhiChuViPham" class="mt-2 pt-1.5 border-t text-caption" :class="row.HasViolation ? 'text-error font-weight-medium' : 'text-grey-darken-2'">
									<v-icon size="14" :color="row.HasViolation ? 'error' : 'grey'">{{ row.HasViolation ? 'mdi-alert-circle' : 'mdi-information-outline' }}</v-icon>
									{{ row.GhiChuViPham }}
								</div>
							</div>
						</v-card>
					</div>
				</div>
				<!-- CHẾ ĐỘ 2: TỔNG HỢP & THI ĐUA (TIẾN ĐỘ THÁNG & ĐỐI SOÁT 4 TUẦN MINH CHỨNG CHI TIẾT) -->
				<div v-if="bghViewMode === 'month'" class="d-flex flex-column ga-3">
					<!-- BANNER TIẾN ĐỘ THI ĐUA THÁNG TỐI GIẢN -->
					<v-card elevation="0" rounded="lg" class="border overflow-hidden bg-white">
						<div class="px-3 py-2 bg-grey-lighten-4 border-b d-flex align-center justify-space-between flex-wrap ga-2">
							<div class="d-flex align-center ga-2">
								<v-icon color="grey-darken-3" size="18">mdi-trophy-outline</v-icon>
								<div>
									<span class="font-weight-bold text-subtitle-2 text-grey-darken-4">
										Lớp dẫn đầu thi đua & Đề xuất khen thưởng — Tháng {{ currentEvaluationMonth }}/2026
									</span>
									<span class="ms-2 text-caption text-medium-emphasis">
										(Chu kỳ: {{ monthCycleDateRange }})
									</span>
								</div>
							</div>
							<span class="text-caption font-weight-medium text-grey-darken-3">
								{{ rewardClasses.length }} lớp {{ currentEvaluationMonth === 9 ? 'đạt khen thưởng' : 'dẫn đầu tiến độ' }}
							</span>
						</div>

						<!-- Thông báo giải thích rõ ràng tiến độ chu kỳ tháng -->
						<div class="px-3 py-2 bg-blue-grey-lighten-5 border-b d-flex align-center ga-2 text-caption text-grey-darken-3">
							<v-icon size="16" color="blue-grey-darken-2">mdi-information-outline</v-icon>
							<span>
								<strong>Tiến độ:</strong> {{ monthProgressDescription }}
							</span>
						</div>

						<div class="pa-3 bg-white">
							<v-row dense>
								<v-col v-for="item in rewardClasses" :key="'month-rw-' + item.LopID" cols="12" md="6">
									<div class="pa-3 rounded-lg border bg-white d-flex flex-column ga-2 h-100">
										<div class="d-flex align-center justify-space-between">
											<div class="d-flex align-center ga-2">
												<v-avatar color="amber-lighten-5" size="32" class="border border-amber-lighten-3">
													<v-icon color="amber-darken-3" size="18">mdi-trophy-award</v-icon>
												</v-avatar>
												<div>
													<div class="font-weight-bold text-subtitle-2 text-grey-darken-4">
														Lớp {{ item.TenLop }} <span class="font-weight-regular text-medium-emphasis">({{ item.TenGVCN }})</span>
													</div>
													<div class="text-caption text-medium-emphasis">
														{{ item.DanhHieu }}
													</div>
												</div>
											</div>
											<span class="reward-tag-leading">
												{{ item.DiemThiDua }}
											</span>
										</div>

										<!-- 4 tuần đánh giá cụ thể theo tiến độ -->
										<div class="pa-2.5 bg-grey-lighten-5 rounded-lg">
											<div class="text-caption text-grey-darken-3 font-weight-medium mb-1.5 d-flex align-center justify-space-between">
												<span>Tiến độ 4 tuần:</span>
												<span class="text-success font-weight-bold">Đã đạt {{ item.SoTuanTot || 1 }}/4 tuần Tốt</span>
											</div>
											<div class="d-flex align-center flex-wrap ga-1.5">
												<span
													v-for="w in item.DanhSachTuan"
													:key="'m-w-' + item.LopID + '-' + w.tuan"
													class="badge-week-tag"
													:class="w.status === 'T' ? 'tag-tot' : (w.status === 'CURRENT' ? 'tag-current' : (w.status === 'CHETAI' ? 'tag-chuadat' : 'tag-future'))"
												>
													{{ w.label }}: {{ w.ketQua }}
												</span>
											</div>
										</div>

										<div class="d-flex align-center justify-space-between pt-1">
											<span class="text-caption text-medium-emphasis font-italic">
												Tuần 1 không có vi phạm, đang duy trì nề nếp
											</span>
											<v-btn
												size="small"
												variant="text"
												color="primary"
												append-icon="mdi-chevron-right"
												class="text-none font-weight-medium px-2"
												@click="openRewardEvidenceDialog(item)"
											>
												Xem chi tiết
											</v-btn>
										</div>
									</div>
								</v-col>
							</v-row>
						</div>
					</v-card>

					<!-- BẢNG CHI TIẾT NỀ NẾP & ĐỐI SOÁT CÁC LỚP TOÀN KHỐI (HIỂN THỊ TRỰC TIẾP RA NGOÀI) -->
					<v-card elevation="0" rounded="lg" class="border overflow-hidden bg-white">
						<div class="px-3 py-2 bg-grey-lighten-4 border-b">
							<div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-2">
								<div class="d-flex align-center ga-2">
									<v-icon color="grey-darken-3" size="18">mdi-table-large</v-icon>
									<span class="font-weight-bold text-subtitle-2 text-grey-darken-4">
										Chi tiết nề nếp các lớp toàn Khối {{ selectedKhoi || 6 }} — Tuần {{ outerMonthlySelectedWeekNum }} (Tháng {{ currentEvaluationMonth }}/2026)
									</span>
								</div>
								<v-btn
									size="small"
									variant="outlined"
									color="primary"
									prepend-icon="mdi-printer"
									class="text-none font-weight-medium ms-auto"
									@click="printOuterKhoiEvidence"
								>
									In chi tiết toàn khối
								</v-btn>
							</div>

							<!-- Thanh chọn Tuần (100% bề ngang trên mobile, có thể cuộn ngang hoặc bấm trực tiếp) -->
							<div class="d-flex align-center ga-1.5 w-100" style="min-width: 0;">
								<span class="text-caption font-weight-medium text-grey-darken-3 flex-shrink-0 d-none d-sm-inline">Xem tuần:</span>
								<div class="week-toggle-scroll-wrapper flex-grow-1">
									<v-btn-toggle
										v-model="outerMonthlySelectedWeekNum"
										mandatory
										density="compact"
										rounded="lg"
										color="primary"
										class="d-flex"
										style="min-width: max-content;"
									>
										<v-btn
											v-for="hw in monthEvaluationWeeks"
											:key="'outer-btn-w-' + hw.weekNum"
											:value="hw.weekNum"
											size="small"
											class="text-none font-weight-medium px-2.5 flex-shrink-0"
										>
											<span class="d-none d-md-inline">{{ hw.label }} ({{ hw.dates }})</span>
											<span class="d-inline d-md-none">{{ hw.label }}</span>
											<span
												class="ms-1 font-weight-medium"
												:style="outerMonthlySelectedWeekNum === hw.weekNum ? 'color: #ffffff !important;' : (hw.isOngoing ? 'color: #0284c7 !important;' : (hw.isPast ? 'color: #2e7d32 !important;' : ''))"
											>
												{{ hw.statusText }}
											</span>
										</v-btn>
									</v-btn-toggle>
								</div>
							</div>
						</div>

						<!-- BẢNG DESKTOP (d-none d-md-block) -->
						<div class="table-responsive d-none d-md-block">
							<table class="w-100 evaluation-master-table" style="font-size: 12.5px;">
								<thead>
									<tr class="bg-grey-lighten-4" style="height: 38px;">
										<th class="text-center" style="padding: 6px; width: 45px;">STT</th>
										<th class="text-left" style="padding: 6px 10px; width: 85px;">Lớp</th>
										<th class="text-left" style="padding: 6px 10px; width: 165px;">GVCN</th>
										<th
											v-for="d in outerSelectedWeekDays"
											:key="'outer-th-d-' + d.dayVal"
											class="text-center"
											style="padding: 4px 2px; width: 75px;"
										>
											<div class="font-weight-medium">{{ d.label }}</div>
											<div class="text-caption text-medium-emphasis" style="font-size: 11px; line-height: 1.1; font-weight: normal;">({{ d.date }})</div>
										</th>
										<th class="text-center" style="padding: 6px 6px; width: 110px;">Kết quả tuần</th>
										<th class="text-left" style="padding: 6px 10px; min-width: 180px;">Ghi chú vi phạm trong tuần</th>
										<th class="text-center" style="padding: 6px 6px; width: 80px;">Trạng thái</th>
									</tr>
								</thead>
								<tbody>
									<tr
										v-for="(row, rIdx) in monthlyClassRecords"
										:key="'outer-khoi-row-' + row.LopID"
										style="height: 48px;"
										:class="{ 'bg-grey-lighten-5': rIdx % 2 === 1 }"
									>
										<td class="text-center" style="padding: 6px;">{{ rIdx + 1 }}</td>
										<td class="font-weight-medium text-left px-2">
											<span :class="row.SoTuanCD > 0 ? 'text-error font-weight-medium' : 'text-grey-darken-4'">{{ row.TenLop }}</span>
										</td>
										<td class="text-left px-2 text-medium-emphasis">{{ row.TenGVCN }}</td>
										<td
											v-for="d in ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).days || [])"
											:key="'outer-kd-' + row.LopID + '-' + d.dayNum"
											class="text-center px-1"
											style="vertical-align: middle;"
										>
											<template v-if="d.tcText === '—' && d.rankText === '—'">
												<span class="text-medium-emphasis">—</span>
											</template>
											<template v-else-if="d.rankCode === 'CHETAI'">
												<div class="d-flex flex-column align-center justify-center">
													<span class="table-rank-badge rank-chuadat" style="font-size: 10px; padding: 1px 4px;">Chế tài</span>
												</div>
											</template>
											<template v-else>
												<div class="d-flex flex-column align-center ga-0.5">
													<span class="font-weight-medium" style="font-size: 10.5px; letter-spacing: 1px;" :style="{ color: d.tcColor }">
														{{ d.tcText }}
													</span>
													<span
														class="table-rank-badge"
														:class="d.rankCode === 'T' ? 'rank-tot' : (d.rankCode === 'D' ? 'rank-dat' : 'rank-chuadat')"
														style="font-size: 10px; padding: 1px 6px; min-width: 22px;"
													>
														{{ d.rankText }}
													</span>
												</div>
											</template>
										</td>
										<td class="text-center px-2">
											<div class="d-flex flex-column align-center ga-0.5">
												<span class="table-rank-badge" :class="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'T' ? 'rank-tot' : ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'D' ? 'rank-dat' : ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CD' ? 'rank-chuadat' : ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CHETAI' ? 'rank-chuadat' : ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CURRENT' ? 'rank-ongoing' : 'rank-future'))))">
													{{ (row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).text }}
												</span>
												<span v-if="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).detail" class="text-caption text-grey-darken-1" style="font-size: 10px;">
													{{ (row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).detail }}
												</span>
											</div>
										</td>
										<td class="text-left px-2 text-caption">
											<span v-if="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).note && (row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).note !== '—'" class="text-error font-weight-medium">
												{{ (row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).note }}
											</span>
											<span v-else class="text-medium-emphasis">—</span>
										</td>
										<td class="text-center px-2">
											<v-icon v-if="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'T'" size="18" color="success">mdi-check-circle-outline</v-icon>
											<v-icon v-else-if="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'D'" size="18" color="primary">mdi-check</v-icon>
											<v-icon v-else-if="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CD' || (row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CHETAI'" size="18" color="error">mdi-alert-circle-outline</v-icon>
											<v-icon v-else-if="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CURRENT'" size="18" color="blue-grey">mdi-clock-outline</v-icon>
											<span v-else class="text-medium-emphasis">—</span>
										</td>
									</tr>
								</tbody>
							</table>
						</div>

						<!-- DANH SÁCH CARD CHO MOBILE (d-block d-md-none) -->
						<div class="d-block d-md-none pa-3">
							<v-card
								v-for="(row, rIdx) in monthlyClassRecords"
								:key="'outer-khoi-card-' + row.LopID"
								elevation="0"
								rounded="xl"
								class="mb-3 bg-white border"
								:class="{ 'border-error': row.SoTuanCD > 0 }"
							>
								<div class="pa-3">
									<div class="d-flex align-center justify-space-between mb-2">
										<div class="d-flex align-center ga-2">
											<span class="font-weight-medium text-subtitle-1" :class="row.SoTuanCD > 0 ? 'text-error font-weight-bold' : 'text-primary'">
												{{ row.TenLop }}
											</span>
											<span class="text-body-2 text-medium-emphasis">({{ row.TenGVCN }})</span>
										</div>
										<span class="table-rank-badge" :class="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'T' ? 'rank-tot' : ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'D' ? 'rank-dat' : ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CD' ? 'rank-chuadat' : ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CHETAI' ? 'rank-chuadat' : ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status === 'CURRENT' ? 'rank-ongoing' : 'rank-future'))))">
											{{ (row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).text }}
										</span>
									</div>

									<!-- 5 ngày T2 - T6: Nền dịu không viền khung lồng nhau -->
									<div class="d-flex align-center justify-space-between text-center bg-grey-lighten-5 rounded-lg pa-2 mb-2">
										<div
											v-for="d in ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).days || [])"
											:key="'outer-kd-m-' + row.LopID + '-' + d.dayNum"
											class="flex-grow-1"
										>
											<div class="text-grey-darken-1 font-weight-medium" style="font-size: 10px;">
												{{ d.dayNum === 2 ? 'T2' : (d.dayNum === 3 ? 'T3' : (d.dayNum === 4 ? 'T4' : (d.dayNum === 5 ? 'T5' : 'T6'))) }}
											</div>
											<div class="mt-0.5">
												<template v-if="d.tcText === '—' && d.rankText === '—'">
													<span class="text-medium-emphasis" style="font-size: 11px;">—</span>
												</template>
												<template v-else-if="d.rankCode === 'CHETAI'">
													<span class="table-rank-badge rank-chuadat" style="font-size: 9px; padding: 0 2px;">Chế tài</span>
												</template>
												<template v-else>
													<span
														class="table-rank-badge"
														:class="d.rankCode === 'T' ? 'rank-tot' : (d.rankCode === 'D' ? 'rank-dat' : 'rank-chuadat')"
														style="font-size: 9.5px; padding: 0 4px; min-width: 18px;"
													>
														{{ d.rankText }}
													</span>
												</template>
											</div>
										</div>
									</div>

									<!-- Ghi chú vi phạm trong tuần (nếu có) -->
									<div v-if="(row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).note && (row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).note !== '—'" class="text-caption bg-red-lighten-5 rounded-lg px-2.5 py-1.5 text-grey-darken-3">
										<div class="d-flex align-center ga-1 text-error" style="font-size: 10.5px;">
											<v-icon size="13" color="error">mdi-alert-circle-outline</v-icon>
											<span class="font-weight-medium">Ghi chú vi phạm:</span>
										</div>
										<div class="mt-0.5 text-error font-weight-medium">
											{{ (row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).note }}
										</div>
									</div>
								</div>
							</v-card>
						</div>

						<!-- Tổng kết nề nếp toàn khối ngoài bảng -->
						<div class="pa-3 border-t text-caption bg-grey-lighten-5 text-grey-darken-3 d-flex align-center justify-space-between flex-wrap ga-2">
							<div>
								<strong>Tổng hợp kết quả Tuần {{ outerMonthlySelectedWeekNum }}:</strong>
								Khối {{ selectedKhoi || 6 }} có
								<strong class="text-success">{{ monthlyClassRecords.filter(r => (r.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || r.w1).status === 'T').length }} lớp Tốt</strong>,
								<strong class="text-primary">{{ monthlyClassRecords.filter(r => (r.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || r.w1).status === 'D').length }} lớp Đạt</strong>,
								<strong class="text-error">{{ monthlyClassRecords.filter(r => ['CD', 'CHETAI'].includes((r.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || r.w1).status)).length }} lớp Chưa đạt/Chế tài</strong>.
							</div>
							<div class="text-medium-emphasis font-italic">
								Dữ liệu đối soát tự động từ hệ thống chấm điểm LMS
							</div>
						</div>
					</v-card>
				</div>
			</v-window-item>
		</v-window>

		<!-- DIALOG CHI TIẾT ĐÁNH GIÁ NỀ NẾP (XEM THEO LỚP & TOÀN KHỐI) -->
		<v-dialog v-model="evidenceDialog.show" max-width="1180" persistent scrollable>
			<v-card v-if="evidenceDialog.classItem || evidenceDialog.viewMode === 'khoi'" rounded="lg">
				<v-card-title class="pa-3 px-4 bg-grey-lighten-4 border-b d-flex align-center justify-space-between flex-wrap ga-2">
					<div class="d-flex align-center ga-2 flex-grow-1">
						<v-icon color="grey-darken-3" size="20">mdi-clipboard-text-outline</v-icon>
						<div style="min-width: 0;">
							<div class="text-subtitle-1 font-weight-bold text-grey-darken-4 text-truncate">
								<span v-if="evidenceDialog.viewMode === 'class'">
									Chi tiết 4 tuần — Lớp {{ evidenceDialog.classItem ? evidenceDialog.classItem.TenLop : '' }}
								</span>
								<span v-else>
									Chi tiết toàn Khối {{ selectedKhoi || 6 }} — T{{ currentEvaluationMonth }}/2026
								</span>
							</div>
							<div class="text-caption text-medium-emphasis">
								Tháng {{ currentEvaluationMonth }}/2026 ({{ monthCycleDateRange }})
							</div>
						</div>
					</div>

					<div class="d-flex align-center ga-2 ms-auto">
						<!-- Toggle chuyển đổi xem theo từng lớp hoặc toàn khối -->
						<v-btn-toggle
							v-model="evidenceDialog.viewMode"
							mandatory
							density="compact"
							rounded="lg"
							color="primary"
						>
							<v-btn value="class" size="small" class="text-none font-weight-medium px-2.5">
								<v-icon size="15" class="me-1">mdi-account</v-icon>Từng lớp
							</v-btn>
							<v-btn value="khoi" size="small" class="text-none font-weight-medium px-2.5">
								<v-icon size="15" class="me-1">mdi-account-group</v-icon>Khối {{ selectedKhoi || 6 }}
							</v-btn>
						</v-btn-toggle>

						<v-btn icon="mdi-close" variant="text" size="small" color="grey-darken-2" @click="evidenceDialog.show = false" />
					</div>
				</v-card-title>

				<v-card-text class="pa-4">
					<!-- ================= CHẾ ĐỘ 1: XEM THEO TỪNG LỚP ================= -->
					<template v-if="evidenceDialog.viewMode === 'class' && evidenceDialog.classItem">
						<!-- Thông tin lớp và chọn nhanh lớp khác trong khối -->
						<div class="pa-2.5 mb-3 bg-grey-lighten-5 rounded-lg border d-flex align-center justify-space-between flex-wrap ga-2">
							<div class="d-flex align-center ga-3 flex-wrap">
								<div class="d-flex align-center ga-1.5">
									<span class="text-caption font-weight-medium text-grey-darken-3">Xem lớp:</span>
									<v-select
										v-model="evidenceDialog.selectedClassId"
										:items="monthlyClassRecords"
										item-title="TenLop"
										item-value="LopID"
										density="compact"
										hide-details
										variant="outlined"
										bg-color="white"
										style="width: 110px;"
										@update:model-value="onEvidenceClassChange"
									/>
								</div>
								<div class="text-caption text-medium-emphasis">
									GVCN: <span class="text-grey-darken-3 font-weight-medium">{{ evidenceDialog.classItem.TenGVCN }}</span> · Sĩ số: <span class="text-grey-darken-3 font-weight-medium">{{ evidenceDialog.classItem.SiSo || 36 }} học sinh</span>
								</div>
							</div>

							<div class="d-flex align-center ga-2 text-caption">
								<span class="font-weight-medium" :class="evidenceDialog.classItem.SoTuanCD > 0 ? 'text-error' : 'text-success'">
									Đạt {{ evidenceDialog.classItem.SoTuanTot }}/4 tuần Tốt (Đã xét Tuần 1)
								</span>
								<span class="text-grey-lighten-1">|</span>
								<span class="font-weight-bold" :class="(evidenceDialog.classItem.DiemThiDua && evidenceDialog.classItem.DiemThiDua.startsWith('+')) ? 'text-success' : 'text-grey-darken-4'">
									{{ evidenceDialog.classItem.DiemThiDua }}
								</span>
							</div>
						</div>

						<!-- Bảng kết quả từng tuần của lớp -->
						<div class="text-caption font-weight-medium text-grey-darken-4 mb-1.5 d-flex align-center ga-1.5">
							<v-icon size="16" color="grey-darken-3">mdi-calendar-check</v-icon>
							<span>TIẾN ĐỘ ĐÁNH GIÁ 4 TUẦN — LỚP {{ evidenceDialog.classItem.TenLop }}</span>
						</div>

						<!-- BẢNG DESKTOP (d-none d-md-block) -->
						<div class="table-responsive border rounded-lg overflow-hidden mb-3 d-none d-md-block">
							<table class="w-100 evaluation-master-table" style="font-size: 12.5px;">
								<thead>
									<tr class="bg-grey-lighten-4" style="height: 38px;">
										<th class="text-left" style="padding: 6px 10px; width: 85px;">Tuần</th>
										<th class="text-left" style="padding: 6px 8px; width: 110px;">Thời gian</th>
										<th class="text-center" style="padding: 6px 4px; width: 75px;">Thứ 2</th>
										<th class="text-center" style="padding: 6px 4px; width: 75px;">Thứ 3</th>
										<th class="text-center" style="padding: 6px 4px; width: 75px;">Thứ 4</th>
										<th class="text-center" style="padding: 6px 4px; width: 75px;">Thứ 5</th>
										<th class="text-center" style="padding: 6px 4px; width: 75px;">Thứ 6</th>
										<th class="text-center" style="padding: 6px 6px; width: 110px;">Kết quả tuần</th>
										<th class="text-left" style="padding: 6px 10px; min-width: 180px;">Ghi chú vi phạm trong tuần</th>
										<th class="text-center" style="padding: 6px 6px; width: 80px;">Trạng thái</th>
									</tr>
								</thead>
								<tbody>
									<tr
										v-for="w in (evidenceDialog.classItem.weeks || [])"
										:key="'ev-wk-' + w.weekNum"
										style="height: 48px;"
										:class="{ 'bg-grey-lighten-5': w.weekNum % 2 === 0 }"
									>
										<td class="font-weight-medium text-left px-2">{{ w.label }}</td>
										<td class="text-left px-2 text-medium-emphasis" style="font-size: 11.5px;">{{ w.dates }}/2026</td>
										<td
											v-for="d in (w.days || [])"
											:key="'ev-day-' + w.weekNum + '-' + d.dayNum"
											class="text-center px-1"
											style="vertical-align: middle;"
										>
											<template v-if="d.tcText === '—' && d.rankText === '—'">
												<span class="text-medium-emphasis">—</span>
											</template>
											<template v-else-if="d.rankCode === 'CHETAI'">
												<div class="d-flex flex-column align-center justify-center">
													<span class="table-rank-badge rank-chuadat" style="font-size: 10px; padding: 1px 4px;">Chế tài</span>
												</div>
											</template>
											<template v-else>
												<div class="d-flex flex-column align-center ga-0.5">
													<span class="font-weight-medium" style="font-size: 10.5px; letter-spacing: 1px;" :style="{ color: d.tcColor }">
														{{ d.tcText }}
													</span>
													<span
														class="table-rank-badge"
														:class="d.rankCode === 'T' ? 'rank-tot' : (d.rankCode === 'D' ? 'rank-dat' : 'rank-chuadat')"
														style="font-size: 10px; padding: 1px 6px; min-width: 22px;"
													>
														{{ d.rankText }}
													</span>
												</div>
											</template>
										</td>
										<td class="text-center px-2">
											<div class="d-flex flex-column align-center ga-0.5">
												<span class="table-rank-badge" :class="w.status === 'T' ? 'rank-tot' : (w.status === 'D' ? 'rank-dat' : (w.status === 'CD' ? 'rank-chuadat' : (w.status === 'CHETAI' ? 'rank-chuadat' : (w.status === 'CURRENT' ? 'rank-ongoing' : 'rank-future'))))">
													{{ w.text }}
												</span>
												<span v-if="w.detail" class="text-caption text-grey-darken-1" style="font-size: 10px;">{{ w.detail }}</span>
											</div>
										</td>
										<td
											class="text-left px-2 text-caption"
											:class="{
												'text-medium-emphasis font-italic': !w.note || w.note === '—'
											}"
										>
											<span v-if="w.note && w.note !== '—'" class="text-error font-weight-medium">{{ w.note }}</span>
											<span v-else class="text-medium-emphasis">—</span>
										</td>
										<td class="text-center px-2">
											<v-icon v-if="w.status === 'T'" size="18" color="success">mdi-check-circle-outline</v-icon>
											<v-icon v-else-if="w.status === 'D'" size="18" color="primary">mdi-check</v-icon>
											<v-icon v-else-if="w.status === 'CD' || w.status === 'CHETAI'" size="18" color="error">mdi-alert-circle-outline</v-icon>
											<v-icon v-else-if="w.status === 'CURRENT'" size="18" color="blue-grey">mdi-clock-outline</v-icon>
											<span v-else class="text-medium-emphasis">—</span>
										</td>
									</tr>
								</tbody>
							</table>
						</div>

						<!-- DANH SÁCH CARD CHO MOBILE (d-block d-md-none) -->
						<div class="d-block d-md-none mb-3">
							<v-card
								v-for="w in (evidenceDialog.classItem.weeks || [])"
								:key="'ev-wk-card-' + w.weekNum"
								elevation="0"
								rounded="xl"
								class="mb-3 bg-white border"
								:class="{ 'border-error': ['CD', 'CHETAI'].includes(w.status) }"
							>
								<div class="pa-3">
									<div class="d-flex align-center justify-space-between mb-2">
										<div class="d-flex align-center ga-1.5">
											<span class="font-weight-medium text-subtitle-1 text-grey-darken-4">{{ w.label }}</span>
											<span class="text-body-2 text-medium-emphasis">({{ w.dates }})</span>
										</div>
										<span class="table-rank-badge" :class="w.status === 'T' ? 'rank-tot' : (w.status === 'D' ? 'rank-dat' : (w.status === 'CD' ? 'rank-chuadat' : (w.status === 'CHETAI' ? 'rank-chuadat' : (w.status === 'CURRENT' ? 'rank-ongoing' : 'rank-future'))))">
											{{ w.text }}
										</span>
									</div>

									<!-- 5 ngày T2 - T6: Nền dịu không viền lồng nhau -->
									<div class="d-flex align-center justify-space-between text-center bg-grey-lighten-5 rounded-lg pa-2 mb-2">
										<div
											v-for="d in (w.days || [])"
											:key="'ev-day-m-' + w.weekNum + '-' + d.dayNum"
											class="flex-grow-1"
										>
											<div class="text-grey-darken-1 font-weight-medium" style="font-size: 10px;">
												{{ d.dayNum === 2 ? 'T2' : (d.dayNum === 3 ? 'T3' : (d.dayNum === 4 ? 'T4' : (d.dayNum === 5 ? 'T5' : 'T6'))) }}
											</div>
											<div class="mt-0.5">
												<template v-if="d.tcText === '—' && d.rankText === '—'">
													<span class="text-medium-emphasis" style="font-size: 11px;">—</span>
												</template>
												<template v-else-if="d.rankCode === 'CHETAI'">
													<span class="table-rank-badge rank-chuadat" style="font-size: 9px; padding: 0 2px;">Chế tài</span>
												</template>
												<template v-else>
													<span
														class="table-rank-badge"
														:class="d.rankCode === 'T' ? 'rank-tot' : (d.rankCode === 'D' ? 'rank-dat' : 'rank-chuadat')"
														style="font-size: 9.5px; padding: 0 4px; min-width: 18px;"
													>
														{{ d.rankText }}
													</span>
												</template>
											</div>
										</div>
									</div>

									<!-- Ghi chú vi phạm trong tuần (nếu có) -->
									<div v-if="w.note && w.note !== '—'" class="text-caption bg-red-lighten-5 rounded-lg px-2.5 py-1.5 text-grey-darken-3">
										<div class="d-flex align-center ga-1 text-error" style="font-size: 10.5px;">
											<v-icon size="13" color="error">mdi-alert-circle-outline</v-icon>
											<span class="font-weight-medium">Ghi chú vi phạm:</span>
										</div>
										<div class="mt-0.5 text-error font-weight-medium">
											{{ w.note }}
										</div>
									</div>
								</div>
							</v-card>
						</div>

						<!-- Kết luận đánh giá của lớp -->
						<div class="pa-3 rounded-lg border text-caption" :class="evidenceDialog.classItem.SoTuanCD > 0 ? 'bg-red-lighten-5 border-red-lighten-4 text-grey-darken-4' : 'bg-grey-lighten-5 text-grey-darken-3'">
							<div class="font-weight-medium mb-1 text-subtitle-2" :class="evidenceDialog.classItem.SoTuanCD > 0 ? 'text-error' : 'text-grey-darken-4'">
								{{ currentEvaluationMonth === 9 ? 'Kết quả đánh giá Tháng 9/2026:' : 'Tiến độ đánh giá Tháng 10/2026:' }}
							</div>
							<template v-if="currentEvaluationMonth === 9">
								<div v-if="evidenceDialog.classItem.IsRewardEligible">
									Lớp {{ evidenceDialog.classItem.TenLop }} đã xuất sắc hoàn thành trọn vẹn 4/4 tuần Tốt trong Tháng 9/2026. Đã chính thức được công nhận danh hiệu "Lớp tự quản tốt" và cộng thưởng <strong class="text-success">{{ evidenceDialog.classItem.DiemThiDua }}</strong>.
								</div>
								<div v-else-if="evidenceDialog.classItem.IsEffortReward">
									Lớp {{ evidenceDialog.classItem.TenLop }} đã xuất sắc đạt 3/4 tuần Tốt trong Tháng 9/2026. Đã chính thức được tuyên dương danh hiệu "Biểu dương nỗ lực nề nếp" và cộng thưởng <strong class="text-success">{{ evidenceDialog.classItem.DiemThiDua }}</strong>.
								</div>
								<div v-else>
									Lớp {{ evidenceDialog.classItem.TenLop }} đã hoàn thành chu kỳ thi đua nề nếp Tháng 9/2026 (đạt chuẩn nề nếp tự quản 15 phút đầu giờ).
								</div>
							</template>
							<template v-else>
								<div v-if="evidenceDialog.classItem.IsLeading">
									Lớp {{ evidenceDialog.classItem.TenLop }} đã xuất sắc đạt Tuần 1 Tốt (0 lỗi vi phạm) và đang dẫn đầu tiến độ thi đua. Tuần 2 đang theo dõi, Tuần 3 và 4 chưa tới. Danh hiệu "Lớp tự quản tốt" và điểm cộng (<span class="font-weight-medium text-success">{{ evidenceDialog.classItem.DiemThiDua }}</span>) sẽ được xét duyệt chính thức sau ngày 01/11/2026 khi kết thúc chu kỳ 4 tuần.
								</div>
								<div v-else-if="evidenceDialog.classItem.IsRewardEligible">
									Lớp {{ evidenceDialog.classItem.TenLop }} hoàn thành xuất sắc 4/4 tuần Tốt trong tháng 10. Đề xuất cộng <strong class="text-success">{{ evidenceDialog.classItem.DiemThiDua }}</strong> và công nhận danh hiệu "Lớp tự quản tốt".
								</div>
								<div v-else-if="evidenceDialog.classItem.SoTuanCD > 0">
									Lớp {{ evidenceDialog.classItem.TenLop }} có <strong class="text-error">{{ evidenceDialog.classItem.SoTuanCD }} tuần Chưa đạt</strong> (Tuần 1 ghi nhận vi phạm nề nếp). Đã áp dụng chế tài: <strong class="text-error">Tạm dừng tự quản Tuần 2</strong> (GVCN trực tiếp quản lý và sinh hoạt 5/5 ngày để chấn chỉnh nề nếp).
								</div>
								<div v-else>
									Lớp {{ evidenceDialog.classItem.TenLop }} đã hoàn thành nề nếp Tuần 1 Đạt. Tuần 2 đang theo dõi; Tuần 3 và 4 chưa diễn ra. Tiếp tục duy trì nề nếp để tích lũy điểm thi đua tháng.
								</div>
							</template>
						</div>
					</template>

					<!-- ================= CHẾ ĐỘ 2: XEM TOÀN KHỐI ================= -->
					<template v-else>
						<!-- Bộ chọn Tuần và thông tin Khối -->
						<!-- Bộ chọn Tuần và thông tin Khối -->
						<div class="pa-2.5 mb-3 bg-grey-lighten-5 rounded-lg border d-flex align-center justify-space-between flex-wrap ga-2">
							<div class="d-flex align-center ga-1.5 w-100" style="min-width: 0;">
								<span class="text-caption font-weight-medium text-grey-darken-3 flex-shrink-0 d-none d-sm-inline">Xem chi tiết tuần:</span>
								<div class="week-toggle-scroll-wrapper flex-grow-1">
									<v-btn-toggle
										v-model="evidenceDialog.selectedWeekNum"
										mandatory
										density="compact"
										rounded="lg"
										color="primary"
										class="d-flex"
										style="min-width: max-content;"
									>
										<v-btn
											v-for="hw in monthEvaluationWeeks"
											:key="'modal-btn-w-' + hw.weekNum"
											:value="hw.weekNum"
											size="small"
											class="text-none font-weight-medium px-2.5 flex-shrink-0"
										>
											<span class="d-none d-md-inline">{{ hw.label }} ({{ hw.dates }})</span>
											<span class="d-inline d-md-none">{{ hw.label }}</span>
											<span
												class="ms-1 font-weight-medium"
												:style="evidenceDialog.selectedWeekNum === hw.weekNum ? 'color: #ffffff !important;' : (hw.isOngoing ? 'color: #0284c7 !important;' : (hw.isPast ? 'color: #2e7d32 !important;' : ''))"
											>
												{{ hw.statusText }}
											</span>
										</v-btn>
									</v-btn-toggle>
								</div>
							</div>

							<div class="text-caption text-medium-emphasis ms-auto">
								Khối <span class="font-weight-medium text-grey-darken-3">{{ selectedKhoi || 6 }}</span> — Tổng số: <span class="font-weight-medium text-grey-darken-3">{{ monthlyClassRecords.length }} lớp</span>
							</div>
						</div>

						<!-- Bảng chi tiết toàn bộ các lớp trong Khối -->
						<div class="text-caption font-weight-medium text-grey-darken-4 mb-1.5 d-flex align-center ga-1.5">
							<v-icon size="16" color="grey-darken-3">mdi-table-large</v-icon>
							<span>CHI TIẾT NỀ NẾP CÁC LỚP TOÀN KHỐI {{ selectedKhoi || 6 }} — TUẦN {{ evidenceDialog.selectedWeekNum }} (THÁNG {{ currentEvaluationMonth }}/2026)</span>
						</div>

						<!-- BẢNG DESKTOP (d-none d-md-block) -->
						<div class="table-responsive border rounded-lg overflow-hidden mb-3 d-none d-md-block">
							<table class="w-100 evaluation-master-table" style="font-size: 12.5px;">
								<thead>
									<tr class="bg-grey-lighten-4" style="height: 38px;">
										<th class="text-center" style="padding: 6px; width: 45px;">STT</th>
										<th class="text-left" style="padding: 6px 10px; width: 85px;">Lớp</th>
										<th class="text-left" style="padding: 6px 10px; width: 165px;">GVCN</th>
										<th
											v-for="d in modalSelectedWeekDays"
											:key="'modal-th-d-' + d.dayVal"
											class="text-center"
											style="padding: 4px 2px; width: 75px;"
										>
											<div style="font-weight: 500;">{{ d.label }}</div>
											<div class="text-caption text-medium-emphasis" style="font-size: 11px; line-height: 1.1; font-weight: normal;">({{ d.date }})</div>
										</th>
										<th class="text-center" style="padding: 6px 6px; width: 110px;">Kết quả tuần</th>
										<th class="text-left" style="padding: 6px 10px; min-width: 180px;">Ghi chú vi phạm trong tuần</th>
										<th class="text-center" style="padding: 6px 6px; width: 80px;">Trạng thái</th>
									</tr>
								</thead>
								<tbody>
									<tr
										v-for="(row, rIdx) in monthlyClassRecords"
										:key="'ev-khoi-row-' + row.LopID"
										style="height: 48px;"
										:class="{ 'bg-grey-lighten-5': rIdx % 2 === 1 }"
									>
										<td class="text-center" style="padding: 6px;">{{ rIdx + 1 }}</td>
										<td class="font-weight-medium text-left px-2">
											<span :class="row.SoTuanCD > 0 ? 'text-error font-weight-bold' : 'text-grey-darken-4 font-weight-medium'">{{ row.TenLop }}</span>
										</td>
										<td class="text-left px-2 text-medium-emphasis">{{ row.TenGVCN }}</td>
										<td
											v-for="d in ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).days || [])"
											:key="'ev-kd-' + row.LopID + '-' + d.dayNum"
											class="text-center px-1"
											style="vertical-align: middle;"
										>
											<template v-if="d.tcText === '—' && d.rankText === '—'">
												<span class="text-medium-emphasis">—</span>
											</template>
											<template v-else-if="d.rankCode === 'CHETAI'">
												<div class="d-flex flex-column align-center justify-center">
													<span class="table-rank-badge rank-chuadat" style="font-size: 10px; padding: 1px 4px;">Chế tài</span>
												</div>
											</template>
											<template v-else>
												<div class="d-flex flex-column align-center ga-0.5">
													<span class="font-weight-medium" style="font-size: 10.5px; letter-spacing: 1px;" :style="{ color: d.tcColor }">
														{{ d.tcText }}
													</span>
													<span
														class="table-rank-badge"
														:class="d.rankCode === 'T' ? 'rank-tot' : (d.rankCode === 'D' ? 'rank-dat' : 'rank-chuadat')"
														style="font-size: 10px; padding: 1px 6px; min-width: 22px;"
													>
														{{ d.rankText }}
													</span>
												</div>
											</template>
										</td>
										<td class="text-center px-2">
											<div class="d-flex flex-column align-center ga-0.5">
												<span class="table-rank-badge" :class="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'T' ? 'rank-tot' : ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'D' ? 'rank-dat' : ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CD' ? 'rank-chuadat' : ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CHETAI' ? 'rank-chuadat' : ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CURRENT' ? 'rank-ongoing' : 'rank-future'))))">
													{{ (row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).text }}
												</span>
												<span v-if="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).detail" class="text-caption text-grey-darken-1" style="font-size: 10px;">
													{{ (row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).detail }}
												</span>
											</div>
										</td>
										<td class="text-left px-2 text-caption">
											<span v-if="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).note && (row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).note !== '—'" class="text-error font-weight-medium">
												{{ (row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).note }}
											</span>
											<span v-else class="text-medium-emphasis">—</span>
										</td>
										<td class="text-center px-2">
											<v-icon v-if="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'T'" size="18" color="success">mdi-check-circle-outline</v-icon>
											<v-icon v-else-if="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'D'" size="18" color="primary">mdi-check</v-icon>
											<v-icon v-else-if="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CD' || (row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CHETAI'" size="18" color="error">mdi-alert-circle-outline</v-icon>
											<v-icon v-else-if="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CURRENT'" size="18" color="blue-grey">mdi-clock-outline</v-icon>
											<span v-else class="text-medium-emphasis">—</span>
										</td>
									</tr>
								</tbody>
							</table>
						</div>

						<!-- DANH SÁCH CARD CHO MOBILE (d-block d-md-none) -->
						<div class="d-block d-md-none mb-3">
							<v-card
								v-for="(row, rIdx) in monthlyClassRecords"
								:key="'ev-khoi-card-' + row.LopID"
								elevation="0"
								rounded="xl"
								class="mb-3 bg-white border"
								:class="{ 'border-error': row.SoTuanCD > 0 }"
							>
								<div class="pa-3">
									<div class="d-flex align-center justify-space-between mb-2">
										<div class="d-flex align-center ga-2">
											<span class="font-weight-medium text-subtitle-1" :class="row.SoTuanCD > 0 ? 'text-error font-weight-bold' : 'text-primary'">
												{{ row.TenLop }}
											</span>
											<span class="text-body-2 text-medium-emphasis">({{ row.TenGVCN }})</span>
										</div>
										<span class="table-rank-badge" :class="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'T' ? 'rank-tot' : ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'D' ? 'rank-dat' : ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CD' ? 'rank-chuadat' : ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CHETAI' ? 'rank-chuadat' : ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status === 'CURRENT' ? 'rank-ongoing' : 'rank-future'))))">
											{{ (row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).text }}
										</span>
									</div>

									<!-- 5 ngày T2 - T6: Nền dịu không viền lồng nhau -->
									<div class="d-flex align-center justify-space-between text-center bg-grey-lighten-5 rounded-lg pa-2 mb-2">
										<div
											v-for="d in ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).days || [])"
											:key="'ev-kd-m-' + row.LopID + '-' + d.dayNum"
											class="flex-grow-1"
										>
											<div class="text-grey-darken-1 font-weight-medium" style="font-size: 10px;">
												{{ d.dayNum === 2 ? 'T2' : (d.dayNum === 3 ? 'T3' : (d.dayNum === 4 ? 'T4' : (d.dayNum === 5 ? 'T5' : 'T6'))) }}
											</div>
											<div class="mt-0.5">
												<template v-if="d.tcText === '—' && d.rankText === '—'">
													<span class="text-medium-emphasis" style="font-size: 11px;">—</span>
												</template>
												<template v-else-if="d.rankCode === 'CHETAI'">
													<span class="table-rank-badge rank-chuadat" style="font-size: 9px; padding: 0 2px;">Chế tài</span>
												</template>
												<template v-else>
													<span
														class="table-rank-badge"
														:class="d.rankCode === 'T' ? 'rank-tot' : (d.rankCode === 'D' ? 'rank-dat' : 'rank-chuadat')"
														style="font-size: 9.5px; padding: 0 4px; min-width: 18px;"
													>
														{{ d.rankText }}
													</span>
												</template>
											</div>
										</div>
									</div>

									<!-- Ghi chú vi phạm trong tuần (nếu có) -->
									<div v-if="(row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).note && (row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).note !== '—'" class="text-caption bg-red-lighten-5 rounded-lg px-2.5 py-1.5 text-grey-darken-3">
										<div class="d-flex align-center ga-1 text-error" style="font-size: 10.5px;">
											<v-icon size="13" color="error">mdi-alert-circle-outline</v-icon>
											<span class="font-weight-medium">Ghi chú vi phạm:</span>
										</div>
										<div class="mt-0.5 text-error font-weight-medium">
											{{ (row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).note }}
										</div>
									</div>
								</div>
							</v-card>
						</div>

						<!-- Tổng kết nề nếp toàn khối -->
						<div class="pa-3 rounded-lg border text-caption bg-grey-lighten-5 text-grey-darken-3 d-flex align-center justify-space-between flex-wrap ga-2">
							<div>
								<strong>Tổng hợp kết quả Tuần {{ evidenceDialog.selectedWeekNum }}:</strong>
								Khối {{ selectedKhoi || 6 }} có
								<strong class="text-success">{{ monthlyClassRecords.filter(r => (r.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || r.w1).status === 'T').length }} lớp Tốt</strong>,
								<strong class="text-primary">{{ monthlyClassRecords.filter(r => (r.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || r.w1).status === 'D').length }} lớp Đạt</strong>,
								<strong class="text-error">{{ monthlyClassRecords.filter(r => ['CD', 'CHETAI'].includes((r.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || r.w1).status)).length }} lớp Chưa đạt/Chế tài</strong>.
							</div>
							<div class="text-medium-emphasis font-italic">
								Dữ liệu đối soát tự động từ hệ thống chấm điểm LMS
							</div>
						</div>
					</template>
				</v-card-text>

				<v-card-actions class="pa-3 bg-grey-lighten-4 border-t d-flex align-center justify-space-between flex-wrap ga-2">
					<div class="text-caption text-medium-emphasis ps-1 d-none d-sm-block">
						Dữ liệu đối soát tự động từ hệ thống chấm điểm LMS
					</div>
					<div class="d-flex align-center justify-space-between justify-sm-end ga-2 w-100 w-sm-auto">
						<v-btn
							v-if="evidenceDialog.viewMode === 'class'"
							variant="outlined"
							color="grey-darken-3"
							size="small"
							prepend-icon="mdi-printer"
							class="text-none font-weight-medium flex-grow-1 flex-sm-grow-0"
							@click="printRewardEvidence"
						>
							In chi tiết lớp
						</v-btn>
						<v-btn
							v-else
							variant="outlined"
							color="primary"
							size="small"
							prepend-icon="mdi-printer"
							class="text-none font-weight-medium flex-grow-1 flex-sm-grow-0"
							@click="printKhoiEvidence"
						>
							In toàn khối
						</v-btn>
						<v-btn variant="flat" color="grey-darken-2" size="small" class="text-none font-weight-medium px-4" @click="evidenceDialog.show = false">
							Đóng
						</v-btn>
					</div>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- DIALOG THÊM & QUẢN LÝ TIÊU CHÍ ĐÁNH GIÁ (DẠNG ĐỘNG) -->
		<v-dialog v-model="criteriaDialog.show" max-width="540" persistent>
			<v-card rounded="lg">
				<v-card-title class="pa-4 bg-white border-b d-flex align-center justify-space-between">
					<div class="d-flex align-center ga-3">
						<v-avatar color="indigo-lighten-5" size="36">
							<v-icon color="indigo-darken-1" size="22">mdi-playlist-plus</v-icon>
						</v-avatar>
						<div>
							<div class="text-subtitle-1 font-weight-bold text-grey-darken-4">Thêm tiêu chí đánh giá</div>
							<div class="text-caption text-medium-emphasis">Bổ sung cột tiêu chí cho bảng theo dõi 15 phút</div>
						</div>
					</div>
					<v-btn icon="mdi-close" variant="text" size="small" color="grey-darken-1" @click="criteriaDialog.show = false" />
				</v-card-title>

				<v-card-text class="pa-4" style="max-height: 70vh; overflow-y: auto;">
					<!-- Thông báo ngày áp dụng rõ ràng -->
					<div class="mb-3 px-3 py-2 bg-indigo-lighten-5 rounded border border-indigo-lighten-4 d-flex align-center ga-2">
						<v-icon color="indigo-darken-2" size="18">mdi-calendar-check-outline</v-icon>
						<span class="text-caption font-weight-medium text-indigo-darken-3">
							Tiêu chí chỉ áp dụng cho riêng ngày: {{ currentDayLabel }} (Không ảnh hưởng các ngày khác)
						</span>
					</div>

					<!-- Phạm vi áp dụng -->
					<div class="text-subtitle-2 font-weight-bold mb-1">Phạm vi áp dụng:</div>
					<v-radio-group v-model="criteriaDialog.scope" density="compact" hide-details class="mb-3">
						<v-radio
							value="all"
							label="Chung cho tất cả các lớp trong khối (ngày này)"
							color="primary"
						/>
						<v-radio
							value="class"
							label="Áp dụng riêng cho 1 lớp cụ thể (ngày này)"
							color="primary"
						/>
					</v-radio-group>

					<!-- Dropdown chọn lớp cụ thể khi chọn scope = class -->
					<v-expand-transition>
						<div v-if="criteriaDialog.scope === 'class'" class="mb-3">
							<v-select
								v-model="criteriaDialog.selectedClassId"
								:items="currentClasses"
								item-title="TenLop"
								item-value="LopID"
								label="Chọn lớp cần thêm tiêu chí *"
								variant="outlined"
								density="comfortable"
								hide-details="auto"
								prepend-inner-icon="mdi-google-classroom"
							>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="'Lớp ' + item.raw.TenLop" :subtitle="'GVCN: ' + item.raw.TenGVCN" />
								</template>
							</v-select>
						</div>
					</v-expand-transition>

					<!-- Tên tiêu chí duy nhất -->
					<div class="mb-3">
						<v-text-field
							v-model="criteriaDialog.ten"
							label="Tên tiêu chí *"
							placeholder="Ví dụ: Kiểm tra tập vở, dụng cụ học tập theo TKB"
							variant="outlined"
							density="comfortable"
							hide-details="auto"
							autofocus
						/>
					</div>

					<!-- Gợi ý tiêu chí nhanh -->
					<div class="mb-3">
						<div class="text-caption font-weight-medium mb-1 text-grey-darken-2">Gợi ý mẫu tiêu chí thường dùng:</div>
						<div class="d-flex flex-wrap ga-1">
							<v-chip
								v-for="(sug, sIdx) in suggestedCriteria"
								:key="'sug-' + sIdx"
								size="small"
								variant="outlined"
								color="indigo-darken-1"
								class="cursor-pointer font-weight-medium"
								@click="selectSuggestedCriteria(sug)"
							>
								+ {{ sug.ten }}
							</v-chip>
						</div>
					</div>

					<!-- Danh sách tiêu chí bổ sung đang có (cho phép xóa tại đây) -->
					<div v-if="getExistingCustomCriteria().length > 0" class="mt-4 pt-3 border-t">
						<div class="text-subtitle-2 font-weight-bold mb-2 d-flex align-center justify-space-between">
							<span class="text-grey-darken-3">
								<v-icon size="16" color="primary" class="me-1">mdi-format-list-checks</v-icon>
								Tiêu chí bổ sung đang áp dụng ({{ getExistingCustomCriteria().length }})
							</span>
						</div>
						<v-list density="compact" class="pa-0 border rounded-lg bg-grey-lighten-5">
							<v-list-item
								v-for="cTc in getExistingCustomCriteria()"
								:key="'manage-tc-' + cTc.id"
								class="px-3 py-1 border-b"
							>
								<template #prepend>
									<v-chip
										size="x-small"
										:color="cTc.scope === 'class' ? 'warning' : 'primary'"
										variant="flat"
										class="me-2 font-weight-medium"
										style="font-size: 9px; height: 18px;"
									>
										{{ cTc.scope === 'class' ? (cTc.tenLop ? 'Lớp ' + cTc.tenLop : 'Riêng') : 'Bổ sung' }}
									</v-chip>
								</template>
								<v-list-item-title class="text-body-2 font-weight-medium">
									{{ cTc.shortTitle || cTc.ten }}
								</v-list-item-title>
								<v-list-item-subtitle class="text-caption text-truncate" style="max-width: 250px;">
									{{ cTc.ten }}
								</v-list-item-subtitle>
								<template #append>
									<v-tooltip text="Xóa tiêu chí này" location="top">
										<template #activator="{ props }">
											<v-btn
												v-bind="props"
												icon="mdi-trash-can-outline"
												size="small"
												variant="text"
												color="error"
												density="compact"
												@click="removeCustomCriterion(cTc)"
											/>
										</template>
									</v-tooltip>
								</template>
							</v-list-item>
						</v-list>
					</div>
				</v-card-text>

				<v-divider />
				<v-card-actions class="pa-3">
					<v-spacer />
					<v-btn variant="text" class="text-none" @click="criteriaDialog.show = false">Đóng</v-btn>
					<v-btn
						color="primary"
						variant="flat"
						class="text-none font-weight-medium"
						:disabled="!criteriaDialog.ten || !criteriaDialog.ten.trim() || (criteriaDialog.scope === 'class' && !criteriaDialog.selectedClassId)"
						@click="confirmAddCriteria"
					>
						Thêm tiêu chí
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		
		<!-- DIALOG IN / XUẤT PHIẾU CHẤM ĐIỂM (CHO SAO ĐỎ & QUẢN SINH) -->
		<!-- DIALOG IN / XUẤT PHIẾU CHẤM ĐIỂM & BÁO CÁO NỀ NẾP (BGH & QUẢN SINH) -->
		<v-dialog v-model="printDialog.show" max-width="960" scrollable>
			<v-card rounded="lg">
				<v-card-title class="pa-4 bg-white border-b d-flex align-center justify-space-between">
					<div class="d-flex align-center ga-3">
						<v-avatar color="primary" variant="tonal" size="36">
							<v-icon color="primary" size="22">mdi-printer-outline</v-icon>
						</v-avatar>
						<span class="text-subtitle-1 font-weight-bold text-grey-darken-4">
							{{ printDialog.mode === 'bgh_summary' ? 'In báo cáo tổng hợp nề nếp tuần (Ban Giám hiệu)' : ((isBghRole || activeTab === 'baocao') ? 'In phiếu giám sát 15 phút tự quản (kèm kết quả đánh giá)' : 'In / xuất phiếu giám sát 15 phút tự quản (A4 photo)') }}
						</span>
					</div>
					<v-btn icon="mdi-close" variant="text" size="small" color="grey-darken-1" @click="printDialog.show = false" />
				</v-card-title>

				<v-card-text class="pa-4">
					<!-- Tùy chọn in -->
					<div class="mb-4 pa-3 bg-grey-lighten-4 rounded-lg border">
						<div class="text-caption font-weight-medium text-grey-darken-3 mb-1 d-flex align-center">
							<v-icon size="16" color="primary" class="mr-1">mdi-file-document-outline</v-icon>
							Hình thức phiếu in:
						</div>
						<v-radio-group v-model="printDialog.mode" inline density="compact" hide-details class="mt-1">
							<!-- 1. Khi ở tab BGH: Xem/In Phiếu giám sát ngày (kèm kết quả QS), Sổ cả tuần (kèm kết quả QS) HOẶC Báo cáo tổng hợp tuần -->
							<template v-if="isBghRole || activeTab === 'baocao'">
								<v-radio
									value="daily"
									label="Phiếu giám sát trong ngày (kèm kết quả Quản sinh đã đánh giá)"
									color="primary"
									class="mr-sm-6 mr-3 mb-1 font-weight-medium"
								/>
								<v-radio
									value="weekly"
									label="Sổ giám sát cả tuần (kèm kết quả Quản sinh đánh giá các ngày)"
									color="primary"
									class="mr-sm-6 mr-3 mb-1 font-weight-medium"
								/>
								<v-radio
									value="bgh_summary"
									label="Báo cáo nề nếp tuần (Ban Giám hiệu - tổng hợp & xếp loại)"
									color="primary"
									class="mr-sm-6 mr-3 mb-1 font-weight-medium"
								/>
							</template>

							<!-- 2. Khi ở tab Quản sinh: Bỏ báo cáo tuần, chỉ in phiếu đi chấm cho Sao đỏ -->
							<template v-else>
								<v-radio
									value="daily"
									label="Phiếu chấm trong ngày (đưa Sao đỏ đi chấm)"
									color="teal"
									class="mr-sm-6 mr-3 mb-1 font-weight-medium"
								/>
								<v-radio
									value="weekly"
									label="Sổ theo dõi cả tuần (phiếu trắng cho Sao đỏ đi chấm)"
									color="teal"
									class="mb-1 font-weight-medium"
								/>
							</template>
						</v-radio-group>
					</div>

					<!-- Preview 1: BÁO CÁO TỔNG HỢP NỀ NẾP TUẦN CHO BAN GIÁM HIỆU (KÈM KẾT QUẢ ĐÃ CHẤM) -->
					<div v-if="printDialog.mode === 'bgh_summary'" class="print-preview-container pa-4 border rounded bg-white" style="font-family: 'Times New Roman', Times, serif; color: #000;">
						<div class="text-center mb-3">
							<div style="font-size: 13pt; font-weight: bold; text-transform: uppercase;">TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG</div>
							<div style="font-size: 14pt; font-weight: bold; margin-top: 4px; color: #1565c0;">BÁO CÁO TỔNG HỢP NỀ NẾP & ĐÁNH GIÁ 15 PHÚT TỰ QUẢN TUẦN</div>
							<div style="font-size: 10.5pt; font-style: italic;">(Kèm kết quả chấm thực tế & ghi chú vi phạm của Quản sinh khối)</div>
						</div>

						<div class="d-flex justify-space-between mb-2 text-body-2" style="font-size: 10.5pt;">
							<div><strong>{{ selectedKhoiName }}</strong></div>
							<div><strong>{{ selectedWeek ? selectedWeek.title : 'Tuần học' }}</strong></div>
							<div>Người lập: <strong>Quản sinh khối</strong></div>
						</div>

						<!-- Thống kê nề nếp tuần -->
						<div class="mb-3 pa-2 bg-blue-grey-lighten-5 rounded border text-caption d-flex align-center justify-space-between flex-wrap ga-2" style="font-size: 9.5pt;">
							<div>Tổng số lớp: <strong>{{ bghWeeklyReportClasses.length }} lớp</strong></div>
							<div>Đạt Tốt / Xuất sắc: <strong style="color: #2e7d32;">{{ bghWeeklyReportStats.totCount }} lớp</strong></div>
							<div>Đạt: <strong style="color: #1565c0;">{{ bghWeeklyReportStats.datCount }} lớp</strong></div>
							<div>Tạm dừng TQ / Nhắc nhở: <strong style="color: #c62828;">{{ bghWeeklyReportStats.blockedCount }} lớp</strong></div>
						</div>

						<div class="table-responsive">
							<table style="width: 100%; border-collapse: collapse; font-size: 9pt; text-align: center; border: 1px solid #333;" border="1">
								<thead>
									<tr style="background-color: #e8eaf6; height: 32px;">
										<th style="width: 32px; padding: 4px;">STT</th>
										<th style="width: 55px; padding: 4px;">Lớp</th>
										<th style="width: 120px; padding: 4px; text-align: left;">GVCN</th>
										<th style="width: 85px; padding: 4px;">Lịch TQ</th>
										<th v-for="d in daysOfWeek" :key="d.val" style="width: 65px; padding: 4px;">
											<div>{{ d.label }}</div>
											<div style="font-size: 7.5pt; font-weight: normal; color: #555;">({{ d.date }})</div>
										</th>
										<th style="width: 85px; padding: 4px;">Xếp loại tuần</th>
										<th style="min-width: 150px; padding: 4px; text-align: left;">Chi tiết đánh giá & Ghi chú của Quản sinh</th>
									</tr>
								</thead>
								<tbody>
									<tr
										v-for="(row, idx) in bghWeeklyReportClasses"
										:key="row.LopID"
										style="height: 36px;"
										:style="{ backgroundColor: row.isApplied ? '#fff5f5' : (idx % 2 === 1 ? '#fafafa' : '#ffffff') }"
									>
										<td>{{ idx + 1 }}</td>
										<td style="font-weight: bold; font-size: 9.5pt;">{{ row.TenLop }}</td>
										<td style="font-size: 8.5pt; text-align: left; padding: 2px 5px;">{{ row.TenGVCN }}</td>
										<td style="font-size: 8pt; padding: 2px 4px;">{{ row.LichSummary }}</td>
										<td v-for="d in row.daysResult" :key="d.dayVal" style="padding: 2px 3px; font-size: 8pt;">
											<div :style="{ color: d.color, fontWeight: 'bold' }">
												{{ d.code === 'CC' ? 'Chào cờ' : (d.code === 'CHETAI' ? 'Tạm dừng TQ' : (d.code === '—' || d.code === 'GV' ? '—' : ('[' + d.code + '] ' + d.statusText))) }}
											</div>
										</td>
										<td style="padding: 2px 4px;">
											<span :style="{ color: row.xepLoaiColor, fontWeight: 'bold', fontSize: '8.5pt' }">
												{{ row.xepLoaiTuan }}
											</span>
										</td>
										<td style="text-align: left; padding: 3px 6px; font-size: 8pt; line-height: 1.3;">
											<div v-if="row.violations.length > 0">
												<div v-for="(v, vIdx) in row.violations" :key="vIdx" style="color: #c62828;">
													<strong>{{ v.day }}:</strong> {{ v.tieuChi }} <span v-if="v.ghiChu">({{ v.ghiChu }})</span>
												</div>
											</div>
											<span v-else-if="!row.hasEvaluated || row.tuQuanCount === 0" style="color: #757575; font-weight: bold;">
												—
											</span>
											<span v-else style="color: #2e7d32;">
												Nề nếp tốt, nghiêm túc (0 lỗi)
											</span>
										</td>
									</tr>
								</tbody>
							</table>
						</div>

						<!-- Kí tên duyệt cho BGH -->
						<div class="d-flex justify-space-between mt-5 text-center" style="font-size: 10.5pt; page-break-inside: avoid;">
							<div style="width: 45%;">
								<div style="font-weight: bold;">NGƯỜI LẬP BÁO CÁO / QUẢN SINH</div>
								<div style="font-style: italic; font-size: 9.5pt;">(Kí và ghi rõ họ tên)</div>
								<div style="height: 50px;"></div>
							</div>
							<div style="width: 45%;">
								<div style="font-weight: bold;">BAN GIÁM HIỆU DUYỆT</div>
								<div style="font-style: italic; font-size: 9.5pt;">(Kí và ghi rõ họ tên)</div>
								<div style="height: 50px;"></div>
							</div>
						</div>
					</div>

					<!-- Preview 2: PHIẾU CHẤM SAO ĐỎ & QUẢN SINH (Daily & Weekly) -->
					<div v-else class="print-preview-container pa-4 border rounded bg-white" style="font-family: 'Times New Roman', Times, serif; color: #000;">
						<div class="text-center mb-3">
							<div style="font-size: 13pt; font-weight: bold; text-transform: uppercase;">TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG</div>
							<div style="font-size: 14pt; font-weight: bold; margin-top: 4px;">
								{{ printDialog.mode === 'weekly' ? 'SỔ GIÁM SÁT 15 PHÚT TỰ QUẢN CẢ TUẦN' : 'PHIẾU GIÁM SÁT 15 PHÚT TỰ QUẢN ĐẦU GIỜ' }}
							</div>
							<div style="font-size: 11pt; font-style: italic;">
								{{ (isBghRole || activeTab === 'baocao') ? (printDialog.mode === 'weekly' ? '(Bản tổng hợp kết quả Quản sinh đánh giá các ngày trong tuần gửi Ban Giám Hiệu)' : '(Bản tổng hợp kết quả Quản sinh đánh giá gửi Ban Giám Hiệu)') : '(Dành cho Quản sinh khối & Đội Sao đỏ / Đoàn viên xung kích theo dõi)' }}
							</div>
						</div>

						<div class="d-flex justify-space-between mb-3 text-body-2" style="font-size: 11pt;">
							<div><strong>{{ selectedKhoiName }}</strong></div>
							<div>{{ selectedWeek ? selectedWeek.title : 'Tuần học' }}</div>
							<div v-if="printDialog.mode === 'daily'">Ngày chấm: <strong>{{ currentDayLabel }}</strong></div>
						</div>

						<div class="text-caption mb-2 text-medium-emphasis" style="font-style: italic; font-size: 10pt;">
							* Hướng dẫn: Đánh giá từng phòng học: <strong>[T] = Tốt, [Đ] = Đạt, [CĐ] = Cần cố gắng</strong>. Ghi rõ nội dung vi phạm cụ thể vào cột Ghi chú.
						</div>

						<!-- Bảng ghi chú các tiêu chí (Legend) giúp tiêu đề bảng ngắn gọn, không bị co ép -->
						<div class="mb-3 pa-2 bg-grey-lighten-4 rounded border text-caption" style="font-size: 8.5pt; line-height: 1.4;">
							<div class="font-weight-bold text-grey-darken-3 mb-1">Nội dung chi tiết các tiêu chí chấm điểm:</div>
							<div class="d-flex flex-wrap ga-x-4 ga-y-1">
								<div v-for="(tc, i) in getMergedPrintCriteria()" :key="'legend-' + i">
									<strong>TC{{ i + 1 }}:</strong> {{ tc.ten }}
								</div>
							</div>
						</div>

						<!-- Bảng preview ngày -->
						<div class="table-responsive">
							<table v-if="printDialog.mode === 'daily'" style="width: 100%; border-collapse: collapse; font-size: 9.5pt; text-align: center; border: 1px solid #333;" border="1">
								<thead>
									<tr style="background-color: #f2f2f2; height: 32px;">
										<th style="width: 38px; padding: 4px;">STT</th>
										<th style="width: 65px; padding: 4px;">Lớp</th>
										<th style="width: 130px; padding: 4px; text-align: left;">GVCN</th>
										<th v-for="(tc, i) in getMergedPrintCriteria()" :key="i" style="padding: 4px; min-width: 100px;">
											<div style="font-weight: bold;">{{ (i + 1) + '. ' + getCriterionMainTitle(tc.ten) }}</div>
											<div v-if="getCriterionSubTitle(tc.ten)" style="font-size: 7.5pt; font-weight: normal; color: #555; line-height: 1.2;">{{ getCriterionSubTitle(tc.ten) }}</div>
										</th>
										<th style="min-width: 130px; padding: 4px; text-align: left;">Ghi chú / Kí tên</th>
									</tr>
								</thead>
								<tbody>
									<tr
										v-for="(cls, idx) in currentClasses"
										:key="cls.LopID"
										style="height: 38px;"
										:style="{ backgroundColor: isClassBlocked(cls.LopID) ? '#fff5f5' : (idx % 2 === 1 ? '#fafafa' : '#ffffff') }"
									>
										<td>{{ idx + 1 }}</td>
										<td style="font-weight: bold; font-size: 10pt;" :style="{ color: isClassBlocked(cls.LopID) ? '#c62828' : 'inherit' }">
											{{ cls.TenLop }}
										</td>
										<td style="font-size: 9pt; text-align: left; padding: 2px 6px;">
											<div>{{ cls.TenGVCN }}</div>
											<!-- TRẠNG THÁI CHẾ TÀI HOẶC TỰ QUẢN -->
											<template v-if="isClassBlocked(cls.LopID)">
												<span style="color: #c62828; font-weight: bold; display: block; font-size: 8pt;">
													[TẠM DỪNG TỰ QUẢN]
												</span>
											</template>
											<template v-else-if="selectedDay === 2 || !cls.IsTuQuan">
												<span style="color: #546e7a; display: block; font-size: 8pt;">(GVCN sinh hoạt)</span>
											</template>
											<template v-else>
												<span style="color: #2e7d32; display: block; font-size: 8pt;">(Lớp tự quản)</span>
											</template>
										</td>
										<td v-for="(tc, i) in getMergedPrintCriteria()" :key="i" style="padding: 2px 4px;">
											<!-- NẾU THỨ 2 HOẶC LỚP BỊ TẠM DỪNG TỰ QUẢN HOẶC GVCN SINH HOẠT TRỰC TIẾP (KHÔNG CHẤM TỰ QUẢN) -->
											<div v-if="isClassBlocked(cls.LopID) || selectedDay === 2 || !cls.IsTuQuan" style="color: #64748b; font-size: 11pt; font-weight: 500;">
												—
											</div>
											<!-- NẾU LÀ NGÀY TỰ QUẢN CÓ CHẤM -->
											<div v-else-if="isClassHavingCriteria(cls, tc)" style="white-space: nowrap; font-size: 8.5pt; display: inline-flex; gap: 4px; align-items: center; justify-content: center;">
												<template v-if="isBghRole || activeTab === 'baocao'">
													<!-- BGH: ĐÁNH DẤU VÀO THEO ĐÁNH GIÁ CỦA QUẢN SINH -->
													<span :style="{ fontWeight: findClassCriterion(cls, tc).score === 3 ? 'bold' : 'normal', color: findClassCriterion(cls, tc).score === 3 ? '#2e7d32' : '#888' }">
														{{ findClassCriterion(cls, tc).score === 3 ? '[✓] T' : '[ ] T' }}
													</span>
													<span :style="{ fontWeight: findClassCriterion(cls, tc).score === 2 ? 'bold' : 'normal', color: findClassCriterion(cls, tc).score === 2 ? '#1565c0' : '#888' }">
														{{ findClassCriterion(cls, tc).score === 2 ? '[✓] Đ' : '[ ] Đ' }}
													</span>
													<span :style="{ fontWeight: findClassCriterion(cls, tc).score === 1 ? 'bold' : 'normal', color: findClassCriterion(cls, tc).score === 1 ? '#c62828' : '#888' }">
														{{ findClassCriterion(cls, tc).score === 1 ? '[✓] CĐ' : '[ ] CĐ' }}
													</span>
												</template>
												<template v-else>
													<!-- QUẢN SINH: PHIẾU TRẮNG CHO SAO ĐỎ ĐI CHẤM -->
													<span>[ ] T</span>
													<span>[ ] Đ</span>
													<span>[ ] CĐ</span>
												</template>
											</div>
											<span v-else style="color: #bbb;">—</span>
										</td>
										<td style="text-align: left; padding: 2px 6px; font-size: 8.5pt;">
											<div v-if="isClassBlocked(cls.LopID)" style="color: #c62828; font-weight: bold;">
												Tạm dừng tự quản 01 tuần (GVCN có mặt 5/5 buổi lúc 7:15)
											</div>
											<div v-else>
												{{ cls.GhiChuViPham || '' }}
											</div>
										</td>
									</tr>
								</tbody>
							</table>

							<!-- Bảng preview tuần -->
							<div v-else>
								<div v-for="d in daysOfWeek" :key="'preview-weekly-' + d.val" class="mb-4">
									<div class="d-flex align-center justify-space-between mb-1">
										<div style="font-weight: bold; font-size: 10.5pt; text-transform: uppercase; color: #1565c0;">
											► {{ d.label }} ({{ d.date }})
										</div>
										<div v-if="d.val === 2" class="text-caption text-grey-darken-1 font-italic" style="font-size: 8.5pt;">
											* Tiết sinh hoạt đầu tuần cùng GVCN (Không chấm tự quản)
										</div>
									</div>
									<table style="width: 100%; border-collapse: collapse; font-size: 9pt; text-align: center; border: 1px solid #333;" border="1">
										<thead>
											<tr style="background-color: #f2f2f2; height: 28px;">
												<th style="width: 35px; padding: 3px;">STT</th>
												<th style="width: 65px; padding: 3px;">Lớp</th>
												<th style="width: 130px; padding: 3px; text-align: left;">GVCN</th>
												<th v-for="(tc, i) in getMergedPrintCriteria()" :key="i" style="padding: 3px; min-width: 95px;">
													<div style="font-weight: bold;">{{ (i + 1) + '. ' + getCriterionMainTitle(tc.ten) }}</div>
													<div v-if="getCriterionSubTitle(tc.ten)" style="font-size: 7pt; font-weight: normal; color: #555; line-height: 1.2;">{{ getCriterionSubTitle(tc.ten) }}</div>
												</th>
												<th style="min-width: 125px; padding: 3px; text-align: left;">Ghi chú / Kí tên</th>
											</tr>
										</thead>
										<tbody>
											<tr
												v-for="(cls, idx) in getClassesForPrintDay(d.val)"
												:key="'weekly-row-' + d.val + '-' + cls.LopID"
												style="height: 34px;"
												:style="{ backgroundColor: isClassBlocked(cls.LopID) ? '#fff5f5' : (idx % 2 === 1 ? '#fafafa' : '#ffffff') }"
											>
												<td>{{ idx + 1 }}</td>
												<td style="font-weight: bold; font-size: 9.5pt;" :style="{ color: isClassBlocked(cls.LopID) ? '#c62828' : 'inherit' }">
													{{ cls.TenLop }}
												</td>
												<td style="font-size: 8.5pt; text-align: left; padding: 2px 5px;">
													<div>{{ cls.TenGVCN }}</div>
													<!-- TRẠNG THÁI CHẾ TÀI HOẶC TỰ QUẢN -->
													<template v-if="isClassBlocked(cls.LopID)">
														<span style="color: #c62828; font-weight: bold; display: block; font-size: 7.5pt;">
															[TẠM DỪNG TỰ QUẢN]
														</span>
													</template>
													<template v-else-if="d.val === 2 || !cls.IsTuQuan">
														<span style="color: #546e7a; display: block; font-size: 7.5pt;">(GVCN sinh hoạt)</span>
													</template>
													<template v-else>
														<span style="color: #2e7d32; display: block; font-size: 7.5pt;">(Lớp tự quản)</span>
													</template>
												</td>
												<td v-for="(tc, i) in getMergedPrintCriteria()" :key="i" style="padding: 2px 4px;">
													<!-- NẾU THỨ 2 HOẶC LỚP BỊ TẠM DỪNG TỰ QUẢN HOẶC GVCN SINH HOẶT TRỰC TIẾP (KHÔNG CHẤM TỰ QUẢN) -->
													<div v-if="isClassBlocked(cls.LopID) || d.val === 2 || !cls.IsTuQuan" style="color: #64748b; font-size: 11pt; font-weight: 500;">
														—
													</div>
													<!-- NẾU CÓ TIÊU CHÍ CHẤM -->
													<div v-else-if="isClassHavingCriteria(cls, tc)" style="white-space: nowrap; font-size: 8pt; display: inline-flex; gap: 3px; align-items: center; justify-content: center;">
														<template v-if="isBghRole || activeTab === 'baocao'">
															<!-- BGH: ĐÁNH DẤU VÀO THEO ĐÁNH GIÁ CỦA QUẢN SINH CỦA NGÀY ĐÓ -->
															<span :style="{ fontWeight: findClassCriterion(cls, tc).score === 3 ? 'bold' : 'normal', color: findClassCriterion(cls, tc).score === 3 ? '#2e7d32' : '#888' }">
																{{ findClassCriterion(cls, tc).score === 3 ? '[✓] T' : '[ ] T' }}
															</span>
															<span :style="{ fontWeight: findClassCriterion(cls, tc).score === 2 ? 'bold' : 'normal', color: findClassCriterion(cls, tc).score === 2 ? '#1565c0' : '#888' }">
																{{ findClassCriterion(cls, tc).score === 2 ? '[✓] Đ' : '[ ] Đ' }}
															</span>
															<span :style="{ fontWeight: findClassCriterion(cls, tc).score === 1 ? 'bold' : 'normal', color: findClassCriterion(cls, tc).score === 1 ? '#c62828' : '#888' }">
																{{ findClassCriterion(cls, tc).score === 1 ? '[✓] CĐ' : '[ ] CĐ' }}
															</span>
														</template>
														<template v-else>
															<!-- QUẢN SINH: PHIẾU TRẮNG CHO SAO ĐỎ -->
															<span>[ ] T</span>
															<span>[ ] Đ</span>
															<span>[ ] CĐ</span>
														</template>
													</div>
													<span v-else style="color: #bbb;">—</span>
												</td>
												<td style="text-align: left; padding: 2px 5px; font-size: 8pt;">
													<div v-if="isClassBlocked(cls.LopID)" style="color: #c62828; font-weight: bold;">
														Tạm dừng tự quản 01 tuần (GVCN có mặt 5/5 buổi lúc 7:15)
													</div>
													<div v-else>
														{{ cls.GhiChuViPham || '' }}
													</div>
												</td>
											</tr>
										</tbody>
									</table>
								</div>
							</div>
						</div>

						<!-- Kí tên cuối trang -->
						<div class="d-flex justify-space-between mt-5 text-center" style="font-size: 11pt; page-break-inside: avoid;">
							<div style="width: 45%;">
								<div style="font-weight: bold;">
									{{ (isBghRole || activeTab === 'baocao') ? 'NGƯỜI LẬP / QUẢN SINH KHỐI' : 'ĐỘI SAO ĐỎ / NGƯỜI CHẤM' }}
								</div>
								<div style="font-style: italic; font-size: 10pt;">(Kí và ghi rõ họ tên)</div>
								<div style="height: 50px;"></div>
							</div>
							<div style="width: 45%;">
								<div style="font-weight: bold;">
									{{ (isBghRole || activeTab === 'baocao') ? 'BAN GIÁM HIỆU DUYỆT' : 'QUẢN SINH KHỐI' }}
								</div>
								<div style="font-style: italic; font-size: 10pt;">(Kí và ghi rõ họ tên)</div>
								<div style="height: 50px;"></div>
							</div>
						</div>
					</div>
				</v-card-text>

				<v-divider />
				<v-card-actions class="pa-3">
					<v-spacer />
					<v-btn variant="text" class="text-none" @click="printDialog.show = false">Đóng</v-btn>
					<v-btn color="primary" variant="flat" prepend-icon="mdi-printer" class="text-none font-weight-bold" @click="executePrint">
						In ngay (Print / PDF)
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Snackbar thông báo -->
		<v-snackbar v-model="snackbar.show" :color="snackbar.color" timeout="3000" location="top right">
			{{ snackbar.text }}
		</v-snackbar>
	</div>
</template>

<script>
	export default {
		name: 'uc-main-layout',
	data() {
		return {
			activeTab: 'quansinh',
			isLoading: false,
			isSaving: false,
			currentUserName: 'Quản sinh khối',
			currentSystemRight: 4, // 4: Quản sinh, 1: GVCN, 3: BGH, 9: Admin
			userRoles: [
				{ id: 4, name: 'Quản sinh', color: 'primary', icon: 'mdi-clipboard-check-outline', description: 'Chấm điểm & xem báo cáo nề nếp khối' },
				{ id: 1, name: 'Giáo viên chủ nhiệm', color: 'teal-darken-1', icon: 'mdi-account-tie', description: 'Chỉ xem tab GVCN đăng kí lịch' },
				{ id: 3, name: 'Ban Giám hiệu', color: 'purple-darken-1', icon: 'mdi-school', description: 'Giám sát Quản sinh & xem báo cáo thi đua' },
				{ id: 9, name: 'System Admin', color: 'red-darken-1', icon: 'mdi-shield-account', description: 'Toàn quyền quản trị hệ thống' }
			],

			weekList: [],
			selectedWeek: null,

			khoiList: [
				{ id: 6, name: 'Khối 6' },
				{ id: 7, name: 'Khối 7' },
				{ id: 8, name: 'Khối 8' },
				{ id: 9, name: 'Khối 9' },
				{ id: 10, name: 'Khối 10' },
				{ id: 11, name: 'Khối 11' },
				{ id: 12, name: 'Khối 12' }
			],
			selectedKhoi: 6,

			daysOfWeek: [
				{ val: 2, label: 'Thứ 2', date: '05/10' },
				{ val: 3, label: 'Thứ 3', date: '06/10' },
				{ val: 4, label: 'Thứ 4', date: '07/10' },
				{ val: 5, label: 'Thứ 5', date: '08/10' },
				{ val: 6, label: 'Thứ 6', date: '09/10' }
			],
			selectedDay: 2,
			bghSelectedDay: null,

			currentClasses: [],

			// 3 Tiêu chí cơ bản chuẩn theo mẫu hướng dẫn (Buổi sáng 7:15 - 7:30)
			baseCriteria: [
				{ id: 'c1', ten: '1. Không gian lớp (Mở cửa, VS, bàn ghế)', shortTitle: 'Không gian lớp (Mở cửa, VS, bàn ghế)', score: 3, isCustom: false },
				{ id: 'c2', ten: '2. Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', shortTitle: 'Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', score: 3, isCustom: false },
				{ id: 'c3', ten: '3. Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', shortTitle: 'Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', score: 3, isCustom: false }
			],

			// Tiêu chí bổ sung theo ngày riêng biệt: { 'YYYY-MM-DD': { global: [], byClass: {} } }
			dailyCustomCriteria: {},

			// Trạng thái làm việc tạm thời theo từng ngày (giữ nguyên khi chuyển qua lại giữa các ngày)
			dailyWorkingState: {},

			// Chuỗi ngày YYYY-MM-DD đang hiển thị
			currentActiveDateStr: '',

			// Kho lưu trữ lịch sử snapshot theo ngày + lớp: { '2026-10-05_2719': { TieuChiList, GhiChuViPham, GVCNCoMat, IsSaved } }
			dailySnapshots: {},
			evalUpdateVersion: 0,

			// Giả lập giờ kiểm thử (null: giờ thực tế hệ thống)
			mockHourOverride: null,
			mockMinuteOverride: 0,

			// Dialog thêm tiêu chí
			criteriaDialog: {
				show: false,
				targetClass: null,
				selectedClassId: null,
				ten: '',
				shortTitle: '',
				scope: 'all'
			},

			suggestedCriteria: [
				{ ten: 'Kiểm tra tập vở, dụng cụ học tập theo TKB' },
				{ ten: 'Tác phong đầu tóc, bảng tên, đồng phục đúng quy định' },
				{ ten: 'Vệ sinh bảng viết, khăn lau, bàn ghế và sọt rác' },
				{ ten: 'Bảo quản thiết bị, máy chiếu và tắt điện phòng học' },
				{ ten: 'Tập trung ổn định đầu giờ đúng 7:15' }
			],

			selectedGvcnClassId: '2719',
			gvcnSchedulesByClass: {},
			autoSaveStatus: 'saved',
			lastSavedTime: '',
			autoSaveTimer: null,
			qsAutoSaveStatus: 'saved',
			qsLastSavedTime: '',
			qsAutoSaveTimer: null,
			isInitializingSchedule: false,
			gvcnClassInfo: {
				LopID: '2719',
				TenLop: '06A',
				TenGVCN: 'Nguyễn Thảo Nguyên',
				SiSo: 36,
				TrangThaiLop: 1,
				GhiChuDangKy: ''
			},
			gvcnWeekSchedule: [
				{ key: 2, label: 'Thứ 2', date: '05/10', IsTuQuan: false, CoMat: true, isFixed: true, GhiChu: 'Sinh hoạt đầu tuần toàn trường' },
				{ key: 3, label: 'Thứ 3', date: '06/10', IsTuQuan: false, CoMat: true, GhiChu: '' },
				{ key: 4, label: 'Thứ 4', date: '07/10', IsTuQuan: false, CoMat: true, GhiChu: '' },
				{ key: 5, label: 'Thứ 5', date: '08/10', IsTuQuan: false, CoMat: true, GhiChu: '' },
				{ key: 6, label: 'Thứ 6', date: '09/10', IsTuQuan: false, CoMat: true, GhiChu: '' }
			],
			gvcnClassHistory: [],

			penaltyOverrides: {
				'2722': true // Mặc định lớp 06D đang dính chế tài tạm dừng tự quản
			},
			baseStreaksByClass: {
				'2719': 4, // 06A
				'2720': 2, // 06B
				'2721': 4, // 06C
				'2722': 0, // 06D (bị vi phạm)
				'2723': 3, // 06E
				'2724': 1, // 06F
				'2725': 3, // 06G
				'2726': 2  // 06H
			},

			printDialog: {
				show: false,
				mode: 'bgh_summary' // 'bgh_summary', 'daily' hoặc 'weekly'
			},
			bghViewMode: 'day', // 'day': xem theo ngày, 'month': xem theo tháng & thi đua (tích hợp đối soát 4 tuần)
			bghSelectedMonth: 10,
			outerMonthlySelectedWeekNum: 1,
			evidenceDialog: {
				show: false,
				classItem: null,
				viewMode: 'class', // 'class': theo từng lớp, 'khoi': toàn khối
				selectedClassId: null,
				selectedWeekNum: 1
			},
			snackbar: {
				show: false,
				text: '',
				color: 'success'
			}
		};
	},
	computed: {
		isPastSelectedWeek() {
			if (!this.selectedWeek) return false;
			var nowMs = new Date().getTime();
			return this.selectedWeek.endMs < nowMs;
		},
		availableWeekList() {
			if (!this.weekList || !this.weekList.length) return [];
			// Cho phép xem lịch sử các tuần trước từ tháng 9 trở đi, tuần hiện tại, và xem trước tối đa 1 tuần kế tiếp
			var nowMs = new Date().getTime();
			var curIdx = this.weekList.findIndex(w => nowMs >= w.startMs && nowMs <= w.endMs);
			if (curIdx === -1) {
				curIdx = this.weekList.findIndex(w => w.startDate === '2026-10-12');
				if (curIdx === -1) curIdx = 0;
			}
			var maxIdx = Math.min(this.weekList.length - 1, curIdx + 1);
			return this.weekList.filter(function(w, idx) {
				return idx <= maxIdx && (w.month >= 9 || w.month <= 6);
			});
		},
		selectedWeekIndex() {
			if (!this.selectedWeek || !this.availableWeekList || !this.availableWeekList.length) return 0;
			return this.availableWeekList.findIndex(w => w.id === this.selectedWeek.id);
		},
		selectedKhoiName() {
			const k = this.khoiList.find(x => x.id === this.selectedKhoi);
			return k ? k.name : '';
		},
		currentDayLabel() {
			const d = this.daysOfWeek.find(x => x.val === this.selectedDay);
			return d ? (d.label + ' (' + d.date + ')') : '';
		},
		realTodayDayVal() {
			var todayDay = this.daysOfWeek.find(d => this.isSpecificDayToday(d.val));
			return todayDay ? todayDay.val : 6;
		},
		realTodayLabel() {
			var todayDay = this.daysOfWeek.find(d => this.isSpecificDayToday(d.val));
			if (todayDay) return todayDay.label + ', ' + todayDay.date;
			var lastDay = this.daysOfWeek[this.daysOfWeek.length - 1];
			return lastDay ? (lastDay.label + ', ' + lastDay.date) : '';
		},
		bghActiveDay() {
			if (this.bghSelectedDay && !this.isSpecificDayInFuture(this.bghSelectedDay)) {
				return this.bghSelectedDay;
			}
			return this.realTodayDayVal;
		},
		bghActiveDayLabel() {
			var d = this.daysOfWeek.find(x => x.val === this.bghActiveDay);
			return d ? (d.label + ', ' + d.date) : this.realTodayLabel;
		},
		bghActiveDayObj() {
			var d = this.daysOfWeek.find(x => x.val === this.bghActiveDay);
			if (d) return d;
			var todayD = this.daysOfWeek.find(x => this.isSpecificDayToday(x.val));
			if (todayD) return todayD;
			return this.daysOfWeek.length ? this.daysOfWeek[this.daysOfWeek.length - 1] : { label: 'Thứ 6', date: '09/10' };
		},
		bghHeaderTitle() {
			var d = this.bghActiveDayObj;
			if (this.bghIsViewingToday) {
				return 'Báo cáo nhanh hôm nay - ' + d.label + ' (' + d.date + ')';
			}
			return 'Báo cáo nhanh ' + d.label + ' (' + d.date + ')';
		},
		bghIsViewingToday() {
			return this.isSpecificDayToday(this.bghActiveDay);
		},
		bghClasses() {
			var _ver = this.evalUpdateVersion;
			return this.getClassesForPrintDay(this.bghActiveDay);
		},
		gvcnAbsentCount() {
			return this.currentClasses.filter(c => !c.IsTuQuan).length;
		},
		pendingCheckCount() {
			// Thứ 2 toàn trường GVCN sinh hoạt, không chấm tự quản -> 0
			if (this.selectedDay === 2 || this.isFutureDay || this.isPastDay || this.isTodayQsLocked) {
				return 0;
			}
			if (!this.currentClasses || !this.currentClasses.length) return 0;
			// Chỉ tính các lớp có áp dụng tự quản (IsTuQuan) mà chưa lưu điểm (!IsSaved)
			return this.currentClasses.filter(c => c.IsTuQuan && !c.IsSaved).length;
		},
		gvcnTuQuanCount() {
			return this.gvcnWeekSchedule.filter(s => s.key !== 2 && s.IsTuQuan).length;
		},
		gvcnAttendanceCount() {
			return this.gvcnWeekSchedule.filter(s => s.CoMat).length;
		},
		gvcnTargetMet() {
			return this.gvcnTuQuanCount >= 2;
		},
		todayViolations() {
			var _ver = this.evalUpdateVersion;
			var classes = (this.activeTab === 'baocao') ? this.bghClasses : (this.currentClasses || []);
			return classes.filter(c => this.itemHasViolation(c));
		},
		isHistoricalDay() {
			// Kiểm tra ngày hiện tại đã có snapshot lưu trữ chưa
			var dateStr = this.getDateStringForDay(this.selectedDay);
			var keyPrefix = dateStr + '_';
			var legacyPrefix = String(this.selectedDay) + '_';
			var isW1 = !this.selectedWeek || this.selectedWeek.startDate === '2026-10-05';
			return Object.keys(this.dailySnapshots).some(k => k.startsWith(keyPrefix) || (isW1 && k.startsWith(legacyPrefix)));
		},
		isTodayQsLocked() {
			var _ver = this.evalUpdateVersion;
			return this.isSpecificDayToday(this.selectedDay) && this.isPastQsCutoffTime();
		},
		isFutureDay() {
			return this.isSpecificDayInFuture(this.selectedDay);
		},
		isPastDay() {
			return this.isSpecificDayInPast(this.selectedDay);
		},
		isReadOnlyDay() {
			return this.isBghRole || this.isFutureDay || this.isPastDay || this.isTodayQsLocked;
		},
		currentClassKhoi() {
			var cid = this.gvcnClassInfo.LopID;
			var f = this.allSchoolClasses.find(c => String(c.LopID) === String(cid));
			return f ? f.Khoi : (this.selectedKhoi || 6);
		},
		allSchoolClasses() {
			var all = [];
			var that = this;
			[6, 7, 8, 9, 10, 11, 12].forEach(function(k) {
				var list = that.getRealClassesByKhoi(k);
				list.forEach(function(item) {
					all.push({
						LopID: item.LopID,
						TenLop: item.TenLop,
						TenGVCN: item.TenGVCN,
						SiSo: item.SiSo,
						Khoi: k,
						label: 'Lớp ' + item.TenLop + ' — ' + item.TenGVCN
					});
				});
			});
			return all;
		},
		availableGvcnClasses() {
			return this.allSchoolClasses;
		},
		tuQuanClassesCount() {
			if (!this.currentClasses) return 0;
			return this.currentClasses.filter(c => c.IsTuQuan).length;
		},
		gvcnSinHoatCount() {
			if (!this.currentClasses) return 0;
			return this.currentClasses.filter(c => !c.IsTuQuan).length;
		},
		reportSummary() {
			var _ver = this.evalUpdateVersion;
			var classes = this.bghClasses;
			var total = classes ? classes.length : 0;
			var that = this;
			var goodCount = classes ? classes.filter(function(c) {
				var res = that.getClassDailyResult(c);
				return res.code === 'T';
			}).length : 0;
			var violationCount = classes ? classes.filter(function(c) { return that.itemHasViolation(c); }).length : 0;
			var tuQuanCount = classes ? classes.filter(function(c) { return c.IsTuQuan; }).length : 0;
			var blockedCount = this.weeklyBlockedClasses.filter(function(b) { return b.IsApplied; }).length;
			return {
				totalClasses: total,
				tuQuanCount: tuQuanCount,
				goodCount: goodCount,
				violationCount: violationCount,
				blockedCount: blockedCount
			};
		},
		weeklyBlockedClasses() {
			var _ver = this.evalUpdateVersion;
			var that = this;
			var k = this.selectedKhoi || 6;
			var classList = this.getRealClassesByKhoi(k);
			var result = [];

			classList.forEach(function(cls) {
				var violationsInWeek = [];

				that.daysOfWeek.forEach(function(d) {
					var dateStr = that.getDateStringForDay(d.val);
					var snapKey = dateStr + '_' + cls.LopID;
					var legacyKey = String(d.val) + '_' + cls.LopID;

					var classData = null;
					if (that.isSpecificDayToday(d.val)) {
						classData = that.currentClasses.find(function(c) { return String(c.LopID) === String(cls.LopID); });
					}
					if (!classData && !that.isSpecificDayInFuture(d.val)) {
						if (that.dailySnapshots[snapKey]) {
							classData = that.dailySnapshots[snapKey];
						} else if (that.selectedWeek && that.selectedWeek.startDate === '2026-10-05' && that.dailySnapshots[legacyKey]) {
							classData = that.dailySnapshots[legacyKey];
						} else if (that.dailyWorkingState[dateStr]) {
							classData = that.dailyWorkingState[dateStr].find(function(c) { return String(c.LopID) === String(cls.LopID); });
						}
					}

					if (d.val !== 2 && classData) {
						var tcs = classData.TieuChiList || [];
						var cdInDay = tcs.filter(function(tc) { return tc.score === 1; }).length;
						var hasVp = (cdInDay >= 2) || (cdInDay >= 1 && classData.GhiChuViPham && classData.GhiChuViPham.trim().length > 0);
						if (hasVp) {
							var violatedTcs = tcs.filter(function(tc) { return tc.score === 1; });
							var viPhamList = violatedTcs.map(function(t, tIdx) {
								return that.formatCriterionItem(t, tIdx);
							});
							var tcNames = viPhamList.map(function(vi) { return vi.badgeText; }).join('; ');
							violationsInWeek.push({
								Ngay: d.label + ' (' + d.date + ')',
								TieuChi: tcNames || 'Tiêu chí nề nếp',
								ViPhamList: viPhamList,
								GhiChu: classData.GhiChuViPham || 'Vi phạm tiêu chí nề nếp'
							});
						}
					}
				});

				var sched = that.getScheduleForClass(cls.LopID);
				var totalTuQuanDays = sched ? sched.filter(function(s) { return s.key !== 2 && s.IsTuQuan; }).length : 2;
				var cdCount = violationsInWeek.length;
				// Quy định khách hàng (Mục 2a): Tuần tự quản bị ghi nhận chưa đạt (CĐ) -> Tạm dừng tự quản 01 tuần tháng tiếp theo
				var isThresholdMet = (cdCount > 0);
				var hasPenaltyOverride = that.penaltyOverrides && (that.penaltyOverrides[cls.LopID] !== undefined);
				var isApplied = hasPenaltyOverride ? that.penaltyOverrides[cls.LopID] : isThresholdMet;

				if (cdCount > 0 || hasPenaltyOverride) {
					result.push({
						LopID: cls.LopID,
						TenLop: cls.TenLop,
						TenKhoi: 'Khối ' + k,
						TenGVCN: cls.TenGVCN,
						SoLanViPham: cdCount,
						TotalTuQuanDays: totalTuQuanDays,
						IsThresholdMet: isThresholdMet,
						IsApplied: isApplied,
						TrangThaiText: isApplied ? 'Tạm dừng tự quản' : 'Đã hủy chế tài',
						TrangThaiColor: isApplied ? 'error' : 'grey-darken-1',
						CacNgayViPham: violationsInWeek
					});
				}
			});

			return result;
		},
		currentEvaluationMonth() {
			return (this.selectedWeek && this.selectedWeek.month) ? this.selectedWeek.month : 10;
		},
		currentEvaluationYear() {
			if (!this.selectedWeek || !this.selectedWeek.startDate) return 2026;
			return parseInt(this.selectedWeek.startDate.split('-')[0], 10) || 2026;
		},
		monthCycleDateRange() {
			if (this.currentEvaluationMonth === 9) {
				return '07/09/2026 – 04/10/2026';
			}
			return '05/10/2026 – 01/11/2026';
		},
		monthProgressDescription() {
			if (this.currentEvaluationMonth === 9) {
				return 'Chu kỳ Tháng 9/2026 đã hoàn thành trọn vẹn 4/4 tuần đánh giá (07/09 – 04/10/2026). Đã hoàn tất xét duyệt khen thưởng và cộng điểm thi đua (+02 điểm) cho các lớp tự quản tốt tháng 9.';
			}
			return 'Đã kết thúc Tuần 1 (05/10 - 11/10). Tuần 2 đang diễn ra (hôm nay Thứ Hai, 12/10). Tuần 3 và 4 chưa tới. Danh hiệu thi đua và điểm cộng (+02 điểm) sẽ được xét duyệt chính thức sau ngày 01/11/2026 khi kết thúc đủ chu kỳ 4 tuần.';
		},
		monthlySummaryStats() {
			if (this.currentEvaluationMonth === 9) {
				return {
					labelKhenThuong: 'Khen thưởng "Lớp tự quản tốt":',
					khenThuongCount: 2,
					khenThuongDetail: '2 lớp (06A, 06C)',
					showBieuDuong: true,
					bieuDuongCount: 2,
					bieuDuongDetail: '2 lớp (06E, 06G)',
					tamDungCount: 0,
					tamDungDetail: '0 lớp'
				};
			}
			return {
				labelKhenThuong: 'Dẫn đầu tiến độ Tuần 1:',
				khenThuongCount: 4,
				khenThuongDetail: '4 lớp (06A, 06C, 06E, 06G)',
				showBieuDuong: false,
				bieuDuongCount: 0,
				bieuDuongDetail: 'Xét sau 01/11',
				tamDungCount: 1,
				tamDungDetail: '1 lớp (06D)'
			};
		},
		monthEvaluationWeeks() {
			var m = this.currentEvaluationMonth;
			if (m === 9) {
				return [
					{ weekNum: 1, label: 'Tuần 1', dates: '07/09 - 13/09', isPast: true, isOngoing: false, isFuture: false, statusText: '(Đã xét)', statusClass: 'text-success' },
					{ weekNum: 2, label: 'Tuần 2', dates: '14/09 - 20/09', isPast: true, isOngoing: false, isFuture: false, statusText: '(Đã xét)', statusClass: 'text-success' },
					{ weekNum: 3, label: 'Tuần 3', dates: '21/09 - 27/09', isPast: true, isOngoing: false, isFuture: false, statusText: '(Đã xét)', statusClass: 'text-success' },
					{ weekNum: 4, label: 'Tuần 4', dates: '28/09 - 04/10', isPast: true, isOngoing: false, isFuture: false, statusText: '(Đã xét)', statusClass: 'text-success' }
				];
			}
			return [
				{ weekNum: 1, label: 'Tuần 1', dates: '05/10 - 11/10', isPast: true, isOngoing: false, isFuture: false, statusText: '(Đã xét)', statusClass: 'text-success' },
				{ weekNum: 2, label: 'Tuần 2', dates: '12/10 - 18/10', isPast: false, isOngoing: true, isFuture: false, statusText: '(Đang diễn ra)', statusClass: 'text-blue-darken-2' },
				{ weekNum: 3, label: 'Tuần 3', dates: '19/10 - 25/10', isPast: false, isOngoing: false, isFuture: true, statusText: '(Chưa tới)', statusClass: 'text-medium-emphasis' },
				{ weekNum: 4, label: 'Tuần 4', dates: '26/10 - 01/11', isPast: false, isOngoing: false, isFuture: true, statusText: '(Chưa tới)', statusClass: 'text-medium-emphasis' }
			];
		},
		monthWeeksList() {
			return this.monthEvaluationWeeks.map(function(w) {
				return {
					weekNum: w.weekNum,
					label: w.label,
					dates: w.dates,
					title: w.label + ' (' + w.dates + ')'
				};
			});
		},
		outerSelectedWeekDays() {
			return this.getKhoiDetailWeekDays(this.outerMonthlySelectedWeekNum);
		},
		modalSelectedWeekDays() {
			return this.getKhoiDetailWeekDays(this.evidenceDialog ? this.evidenceDialog.selectedWeekNum : 1);
		},
		monthlyClassRecords() {
			var that = this;
			var k = this.selectedKhoi || 6;
			var classList = this.getRealClassesByKhoi(k);
			var _ver = this.evalUpdateVersion;
			var m = this.currentEvaluationMonth;

			// =================== CHU KỲ THÁNG 9 (ĐÃ HOÀN THÀNH 4/4 TUẦN) ===================
			if (m === 9) {
				return classList.map(function(cls, idx) {
					var w1, w2, w3, w4;
					var isAorC = ['06A', '06C'].includes(cls.TenLop);
					var isEorG = ['06E', '06G'].includes(cls.TenLop);

					var makeDays = function(rank) {
						return [
							{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
							{ dayNum: 3, label: 'Thứ 3', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
							{ dayNum: 4, label: 'Thứ 4', tcText: (rank === 'T' ? 'T  T  T' : 'T  Đ  T'), rankText: (rank === 'T' ? 'T' : 'Đ'), rankCode: (rank === 'T' ? 'T' : 'D'), tcColor: (rank === 'T' ? '#16a34a' : '#2563eb') },
							{ dayNum: 5, label: 'Thứ 5', tcText: (rank === 'T' ? 'T  T  T' : 'T  Đ  T'), rankText: (rank === 'T' ? 'T' : 'Đ'), rankCode: (rank === 'T' ? 'T' : 'D'), tcColor: (rank === 'T' ? '#16a34a' : '#2563eb') },
							{ dayNum: 6, label: 'Thứ 6', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' }
						];
					};

					if (isAorC) {
						w1 = { weekNum: 1, label: 'Tuần 1', dates: '07/09 - 13/09', status: 'T', text: 'Tốt', detail: '4/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('T') };
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '14/09 - 20/09', status: 'T', text: 'Tốt', detail: '4/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('T') };
						w3 = { weekNum: 3, label: 'Tuần 3', dates: '21/09 - 27/09', status: 'T', text: 'Tốt', detail: '4/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('T') };
						w4 = { weekNum: 4, label: 'Tuần 4', dates: '28/09 - 04/10', status: 'T', text: 'Tốt', detail: '4/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('T') };

						return {
							STT: idx + 1,
							LopID: cls.LopID,
							TenLop: cls.TenLop,
							TenKhoi: 'Khối ' + k,
							TenGVCN: cls.TenGVCN,
							SiSo: cls.SiSo || 36,
							w1: w1, w2: w2, w3: w3, w4: w4,
							weeks: [w1, w2, w3, w4],
							SoTuanTot: 4,
							SoTuanCD: 0,
							XepLoaiThang: 'Xuất sắc',
							IsLeading: false,
							IsRewardEligible: true,
							IsEffortReward: false,
							DeXuatKhenThuong: 'Lớp tự quản tốt (+02 điểm)',
							DiemThiDua: '+02 điểm chính thức',
							DanhHieu: 'Đạt chuẩn: Lớp tự quản tốt tháng 9'
						};
					} else if (isEorG) {
						w1 = { weekNum: 1, label: 'Tuần 1', dates: '07/09 - 13/09', status: 'T', text: 'Tốt', detail: '3/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('T') };
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '14/09 - 20/09', status: 'T', text: 'Tốt', detail: '3/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('T') };
						w3 = { weekNum: 3, label: 'Tuần 3', dates: '21/09 - 27/09', status: (cls.TenLop === '06E' ? 'T' : 'D'), text: (cls.TenLop === '06E' ? 'Tốt' : 'Đạt'), detail: '3/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays(cls.TenLop === '06E' ? 'T' : 'D') };
						w4 = { weekNum: 4, label: 'Tuần 4', dates: '28/09 - 04/10', status: (cls.TenLop === '06E' ? 'D' : 'T'), text: (cls.TenLop === '06E' ? 'Đạt' : 'Tốt'), detail: '3/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays(cls.TenLop === '06E' ? 'D' : 'T') };

						return {
							STT: idx + 1,
							LopID: cls.LopID,
							TenLop: cls.TenLop,
							TenKhoi: 'Khối ' + k,
							TenGVCN: cls.TenGVCN,
							SiSo: cls.SiSo || 36,
							w1: w1, w2: w2, w3: w3, w4: w4,
							weeks: [w1, w2, w3, w4],
							SoTuanTot: 3,
							SoTuanCD: 0,
							XepLoaiThang: 'Tốt',
							IsLeading: false,
							IsRewardEligible: false,
							IsEffortReward: true,
							DeXuatKhenThuong: 'Biểu dương nỗ lực (+01 điểm)',
							DiemThiDua: '+01 điểm chính thức',
							DanhHieu: 'Biểu dương: Nỗ lực nề nếp tự quản'
						};
					} else {
						w1 = { weekNum: 1, label: 'Tuần 1', dates: '07/09 - 13/09', status: 'D', text: 'Đạt', detail: '2/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '14/09 - 20/09', status: 'D', text: 'Đạt', detail: '2/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w3 = { weekNum: 3, label: 'Tuần 3', dates: '21/09 - 27/09', status: 'D', text: 'Đạt', detail: '2/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w4 = { weekNum: 4, label: 'Tuần 4', dates: '28/09 - 04/10', status: 'D', text: 'Đạt', detail: '2/4 ngày tốt', violations: 0, note: '', isPast: true, days: makeDays('D') };

						return {
							STT: idx + 1,
							LopID: cls.LopID,
							TenLop: cls.TenLop,
							TenKhoi: 'Khối ' + k,
							TenGVCN: cls.TenGVCN,
							SiSo: cls.SiSo || 36,
							w1: w1, w2: w2, w3: w3, w4: w4,
							weeks: [w1, w2, w3, w4],
							SoTuanTot: 0,
							SoTuanCD: 0,
							XepLoaiThang: 'Đạt',
							IsLeading: false,
							IsRewardEligible: false,
							IsEffortReward: false,
							DeXuatKhenThuong: 'Hoàn thành nề nếp',
							DiemThiDua: '0 điểm',
							DanhHieu: ''
						};
					}
				});
			}

			// =================== CHU KỲ THÁNG 10 (TIẾN ĐỘ THỜI GIAN THỰC TẾ) ===================
			return classList.map(function(cls, idx) {
				var streak = (that.baseStreaksByClass && that.baseStreaksByClass[cls.LopID]) || 0;
				var isBlockedThisWeek = that.weeklyBlockedClasses.some(function(b) { return b.LopID === cls.LopID && b.IsApplied; });
				var effectiveStreak = isBlockedThisWeek ? 0 : streak;

				// Cấu trúc 4 tuần Tháng 10 theo đúng tiến độ thời gian thực tế:
				// - Tuần 1 (05/10 - 11/10): ĐÃ KẾT THÚC (Đã có kết quả chính thức)
				// - Tuần 2 (12/10 - 18/10): TUẦN HIỆN TẠI (Đang diễn ra - hôm nay Thứ 2)
				// - Tuần 3 (19/10 - 25/10): CHƯA DIỄN RA (Chưa tới)
				// - Tuần 4 (26/10 - 01/11): CHƯA DIỄN RA (Chưa tới)
				var w1, w2, w3, w4;

				// 1. Tuần 1 (Đã hoàn thành):
				if (['06A', '06C', '06E', '06G'].includes(cls.TenLop)) {
					var detailStr = (cls.TenLop === '06A') ? '4/4 ngày tốt' : '3/4 ngày tốt';
					w1 = { weekNum: 1, label: 'Tuần 1', dates: '05/10 - 11/10', status: 'T', text: 'Tốt', detail: detailStr, violations: 0, note: '', isPast: true };
				} else if (cls.TenLop === '06D') {
					w1 = { weekNum: 1, label: 'Tuần 1', dates: '05/10 - 11/10', status: 'CD', text: 'Chưa đạt', detail: '2 ngày CĐ', violations: 2, note: 'Vi phạm nề nếp 2 buổi (T4, T5) - Tạm dừng tự quản Tuần 2', isPast: true };
				} else {
					w1 = { weekNum: 1, label: 'Tuần 1', dates: '05/10 - 11/10', status: 'D', text: 'Đạt', detail: '2/4 ngày tốt', violations: 0, note: '', isPast: true };
				}

				// Chi tiết 5 ngày trong Tuần 1: Thứ 2 không đánh giá tự quản (GVCN sinh hoạt); Thứ 3-6 tự quản
				var days1 = [];
				if (cls.TenLop === '06A') {
					days1 = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' }
					];
				} else if (['06C', '06E', '06G'].includes(cls.TenLop)) {
					days1 = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'T  Đ  T', rankText: 'Đ', rankCode: 'D', tcColor: '#2563eb' }
					];
				} else if (cls.TenLop === '06D') {
					days1 = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'T  CĐ  T', rankText: 'CĐ', rankCode: 'CD', tcColor: '#dc2626' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'T  CĐ  CĐ', rankText: 'CĐ', rankCode: 'CD', tcColor: '#dc2626' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' }
					];
				} else {
					days1 = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'T  Đ  T', rankText: 'Đ', rankCode: 'D', tcColor: '#2563eb' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'T  Đ  T', rankText: 'Đ', rankCode: 'D', tcColor: '#2563eb' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'T  T  T', rankText: 'T', rankCode: 'T', tcColor: '#16a34a' }
					];
				}
				w1.days = days1;

				// 2. Tuần 2 (Tuần hiện tại - đang diễn ra):
				if (cls.TenLop === '06D') {
					w2 = { weekNum: 2, label: 'Tuần 2', dates: '12/10 - 18/10', status: 'CHETAI', text: 'Chế tài TQ', detail: 'GVCN sinh hoạt', violations: 0, note: 'Chấp hành chế tài: GVCN trực tiếp quản lý và sinh hoạt lớp 5/5 ngày', isCurrent: true };
					w2.days = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: 'Chế tài', rankCode: 'CHETAI', tcColor: '#dc2626' },
						{ dayNum: 3, label: 'Thứ 3', tcText: '—', rankText: 'Chế tài', rankCode: 'CHETAI', tcColor: '#dc2626' },
						{ dayNum: 4, label: 'Thứ 4', tcText: '—', rankText: 'Chế tài', rankCode: 'CHETAI', tcColor: '#dc2626' },
						{ dayNum: 5, label: 'Thứ 5', tcText: '—', rankText: 'Chế tài', rankCode: 'CHETAI', tcColor: '#dc2626' },
						{ dayNum: 6, label: 'Thứ 6', tcText: '—', rankText: 'Chế tài', rankCode: 'CHETAI', tcColor: '#dc2626' }
					];
				} else {
					// Lấy dữ liệu thực tế các ngày trong Tuần 2 (12/10 - 18/10):
					// T2 là ngày sinh hoạt đầu tuần / GVCN có mặt; các ngày T3..T6 lấy theo snapshot chấm của Quản sinh
					var week2Days = [];
					var w2Violations = [];
					var w2Notes = [];

					for (var dVal = 2; dVal <= 6; dVal++) {
						var dLabel = dVal === 2 ? 'Thứ 2' : (dVal === 3 ? 'Thứ 3' : (dVal === 4 ? 'Thứ 4' : (dVal === 5 ? 'Thứ 5' : 'Thứ 6')));
						if (that.isSpecificDayInFuture(dVal)) {
							week2Days.push({ dayNum: dVal, label: dLabel, tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' });
						} else if (dVal === 2) {
							// Thứ 2: Sinh hoạt đầu tuần, GVCN sinh hoạt cùng lớp
							week2Days.push({ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' });
						} else {
							// Lấy snapshot chấm điểm thực tế của Quản sinh cho lớp trong ngày dVal
							var dateStr = that.getDateStringForDay(dVal);
							var sKey = dateStr + '_' + cls.LopID;
							var snap = that.dailySnapshots[sKey];
							if (snap && snap.IsSaved) {
								if (!snap.IsTuQuan) {
									week2Days.push({ dayNum: dVal, label: dLabel, tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' });
								} else {
									var tcs = snap.TieuChiList || [];
									var s1 = tcs[0] ? tcs[0].score : 3;
									var s2 = tcs[1] ? tcs[1].score : 3;
									var s3 = tcs[2] ? tcs[2].score : 3;
									var tcText = (s1 === 3 ? 'T' : (s1 === 1 ? 'CĐ' : 'Đ')) + '  ' +
									             (s2 === 3 ? 'T' : (s2 === 1 ? 'CĐ' : 'Đ')) + '  ' +
									             (s3 === 3 ? 'T' : (s3 === 1 ? 'CĐ' : 'Đ'));
									var rCode = (s1 === 1 || s2 === 1 || s3 === 1) ? 'CD' : ((s1 === 3 && s2 === 3 && s3 === 3) ? 'T' : 'D');
									var rText = rCode === 'T' ? 'T' : (rCode === 'D' ? 'Đ' : 'CĐ');
									var rColor = rCode === 'T' ? '#16a34a' : (rCode === 'D' ? '#2563eb' : '#dc2626');
									week2Days.push({ dayNum: dVal, label: dLabel, tcText: tcText, rankText: rText, rankCode: rCode, tcColor: rColor });

									if (rCode === 'CD') {
										w2Violations.push(dLabel);
									}
									if (snap.GhiChuViPham && snap.GhiChuViPham.trim()) {
										w2Notes.push(dLabel + ': ' + snap.GhiChuViPham.trim());
									}
								}
							} else {
								week2Days.push({ dayNum: dVal, label: dLabel, tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' });
							}
						}
					}

					var dynamicNote = '';
					if (w2Notes.length > 0) {
						dynamicNote = w2Notes.join('; ');
					} else if (w2Violations.length > 0) {
						dynamicNote = 'Ghi nhận vi phạm ngày ' + w2Violations.join(', ');
					}

					w2 = {
						weekNum: 2,
						label: 'Tuần 2',
						dates: '12/10 - 18/10',
						status: 'CURRENT',
						text: 'Đang diễn ra',
						detail: '',
						violations: w2Violations.length,
						note: dynamicNote,
						isCurrent: true,
						days: week2Days
					};
				}

				// 3. Tuần 3 (Chưa diễn ra):
				w3 = { weekNum: 3, label: 'Tuần 3', dates: '19/10 - 25/10', status: 'FUTURE', text: 'Chưa diễn ra', detail: '', violations: 0, note: '', isFuture: true };
				w3.days = [
					{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
					{ dayNum: 3, label: 'Thứ 3', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
					{ dayNum: 4, label: 'Thứ 4', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
					{ dayNum: 5, label: 'Thứ 5', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
					{ dayNum: 6, label: 'Thứ 6', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' }
				];

				// 4. Tuần 4 (Chưa diễn ra):
				w4 = { weekNum: 4, label: 'Tuần 4', dates: '26/10 - 01/11', status: 'FUTURE', text: 'Chưa diễn ra', detail: '', violations: 0, note: '', isFuture: true };
				w4.days = [
					{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
					{ dayNum: 3, label: 'Thứ 3', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
					{ dayNum: 4, label: 'Thứ 4', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
					{ dayNum: 5, label: 'Thứ 5', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
					{ dayNum: 6, label: 'Thứ 6', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' }
				];

				var weeks = [w1, w2, w3, w4];
				var totCount = (w1.status === 'T' ? 1 : 0);
				var cdCount = (w1.status === 'CD' ? 1 : 0);

				var isLeading = (totCount === 1 && cdCount === 0);
				var isBlocked = (cdCount > 0);

				var xepLoaiThang = isBlocked ? 'Chế tài Tuần 2' : 'Đang theo dõi';
				var deXuatKhenThuong = isLeading ? 'Ứng viên danh hiệu (+02 đ dự kiến)' : (isBlocked ? 'Tạm dừng tự quản Tuần 2' : 'Đang tích lũy thi đua');
				var diemThiDua = isLeading ? '+02 điểm dự kiến' : '0 điểm';

				return {
					STT: idx + 1,
					LopID: cls.LopID,
					TenLop: cls.TenLop,
					TenKhoi: 'Khối ' + k,
					TenGVCN: cls.TenGVCN,
					SiSo: cls.SiSo || 36,
					w1: w1,
					w2: w2,
					w3: w3,
					w4: w4,
					weeks: weeks,
					SoTuanTot: totCount,
					SoTuanCD: cdCount,
					XepLoaiThang: xepLoaiThang,
					IsLeading: isLeading,
					IsRewardEligible: false,
					IsEffortReward: false,
					DeXuatKhenThuong: deXuatKhenThuong,
					DiemThiDua: diemThiDua,
					DanhHieu: isLeading ? 'Ứng viên: Lớp tự quản tốt' : ''
				};
			});
		},
		rewardClasses() {
			var that = this;
			var m = this.currentEvaluationMonth;

			if (m === 9) {
				var list9 = this.monthlyClassRecords.filter(function(r) { return r.IsRewardEligible || r.IsEffortReward; });
				return list9.map(function(r) {
					return {
						LopID: r.LopID,
						TenLop: r.TenLop,
						TenKhoi: r.TenKhoi,
						TenGVCN: r.TenGVCN,
						SiSo: r.SiSo,
						SoTuanTot: r.SoTuanTot,
						SoTuanCD: r.SoTuanCD,
						TrangThai: r.IsRewardEligible ? 'Đã hoàn thành 4/4 tuần Tốt' : 'Đã hoàn thành 3/4 tuần Tốt',
						DanhHieu: r.DanhHieu,
						DiemThiDua: r.DiemThiDua,
						IsRewardEligible: r.IsRewardEligible,
						DanhSachTuan: r.weeks.map(function(w) {
							return {
								tuan: w.weekNum,
								label: w.label,
								dates: w.dates,
								ketQua: w.detail,
								status: w.status,
								note: w.note
							};
						})
					};
				});
			}

			var list = this.monthlyClassRecords.filter(function(r) { return r.IsLeading; });
			return list.map(function(r) {
				return {
					LopID: r.LopID,
					TenLop: r.TenLop,
					TenKhoi: r.TenKhoi,
					TenGVCN: r.TenGVCN,
					SiSo: r.SiSo,
					SoTuanTot: r.SoTuanTot,
					SoTuanCD: r.SoTuanCD,
					TrangThai: 'Đang dẫn đầu chu kỳ: Tuần 1 đạt Tốt (0 lỗi)',
					DanhHieu: 'Ứng viên tiềm năng: Lớp tự quản tốt',
					DiemThiDua: '+02 điểm dự kiến',
					IsRewardEligible: false,
					DanhSachTuan: r.weeks.map(function(w) {
						return {
							tuan: w.weekNum,
							label: w.label,
							dates: w.dates,
							ketQua: w.status === 'FUTURE' ? 'Chưa tới' : (w.status === 'CURRENT' ? 'Đang diễn ra' : (w.status === 'CHETAI' ? 'Chế tài' : w.detail)),
							status: w.status,
							note: w.note
						};
					})
				};
			});
		},
		weeklyClassMatrix() {
			var that = this;
			var k = this.selectedKhoi || 6;
			var classList = this.getRealClassesByKhoi(k);
			var _ver = this.evalUpdateVersion;

			return classList.map(function(cls, idx) {
				var sched = that.getScheduleForClass(cls.LopID);
				var daysRes = {};
				var totCount = 0;
				var datCount = 0;
				var cdCount = 0;
				var tuQuanCount = 0;

				that.daysOfWeek.forEach(function(d) {
					if (that.isSpecificDayInFuture(d.val)) {
						daysRes[d.val] = { code: 'FUTURE', text: '—', color: 'grey' };
						return;
					}
					var dayClasses = that.getClassesForPrintDay(d.val);
					var found = dayClasses.find(function(c) { return String(c.LopID) === String(cls.LopID); });
					var res = found ? that.getClassDailyResult(found, d.val) : { code: 'GVCN', text: '—', color: 'blue-grey' };
					daysRes[d.val] = res;
					if (found && found.IsTuQuan && d.val !== 2) {
						tuQuanCount++;
						if (res.code === 'T') totCount++;
						else if (res.code === 'D') datCount++;
						else if (res.code === 'CD') cdCount++;
					}
				});

				var isBlocked = that.isClassBlocked(cls.LopID);
				var hasEvaluated = (totCount + datCount + cdCount > 0);
				var xepLoaiTuann = '—';
				var colorTuann = 'medium-emphasis';

				if (isBlocked) {
					xepLoaiTuann = 'Tạm dừng tự quản';
					colorTuann = 'error';
				} else if (!hasEvaluated || tuQuanCount === 0) {
					xepLoaiTuann = '—';
					colorTuann = 'medium-emphasis';
				} else if (cdCount > 0) {
					xepLoaiTuann = 'Chưa đạt';
					colorTuann = 'error';
				} else if (totCount >= 3) {
					xepLoaiTuann = 'Tốt';
					colorTuann = 'success';
				} else {
					xepLoaiTuann = 'Đạt';
					colorTuann = 'primary';
				}

				return {
					STT: idx + 1,
					LopID: cls.LopID,
					TenLop: cls.TenLop,
					TenGVCN: cls.TenGVCN,
					SiSo: cls.SiSo || 36,
					day2: daysRes[2] || { code: 'GVCN', text: 'GVCN', color: 'blue-grey' },
					day3: daysRes[3] || { code: 'FUTURE', text: '—', color: 'grey' },
					day4: daysRes[4] || { code: 'FUTURE', text: '—', color: 'grey' },
					day5: daysRes[5] || { code: 'FUTURE', text: '—', color: 'grey' },
					day6: daysRes[6] || { code: 'FUTURE', text: '—', color: 'grey' },
					TuQuanCount: tuQuanCount,
					TargetMet: tuQuanCount >= 2,
					TotCount: totCount,
					DatCount: datCount,
					CdCount: cdCount,
					XepLoaiTuan: xepLoaiTuann,
					XepLoaiColor: colorTuann,
					IsBlocked: isBlocked
				};
			});
		},
		dayClassesDetail() {
			var that = this;
			var _ver = this.evalUpdateVersion;
			var list = this.bghClasses || [];
			var isMonday = that.bghActiveDay === 2;
			return list.map(function(cls, idx) {
				var res = that.getClassDailyResult(cls, that.bghActiveDay);
				var tcs = cls.TieuChiList || [];
				var isTq = isMonday ? false : (cls.IsTuQuan !== undefined ? !!cls.IsTuQuan : true);
				// Thứ 2 hoặc khi GVCN sinh hoạt cố định thì GVCN luôn luôn có mặt điều hành
				var gvcnPresent = (isMonday || !isTq) ? true : (cls.GVCNCoMat !== undefined ? !!cls.GVCNCoMat : true);
				return {
					STT: idx + 1,
					LopID: cls.LopID,
					TenLop: cls.TenLop,
					TenGVCN: cls.TenGVCN,
					SiSo: cls.SiSo || 36,
					IsTuQuan: isTq,
					GVCNCoMat: gvcnPresent,
					Result: (isMonday || !isTq) ? { code: 'GVCN', text: '—', color: 'blue-grey' } : res,
					HasViolation: isMonday ? false : (res.code === 'CD'),
					TC1: (isMonday || !isTq) ? null : (tcs[0] ? tcs[0].score : 3),
					TC2: (isMonday || !isTq) ? null : (tcs[1] ? tcs[1].score : 3),
					TC3: (isMonday || !isTq) ? null : (tcs[2] ? tcs[2].score : 3),
					GhiChuViPham: (isMonday || !isTq) ? '' : (cls.GhiChuViPham || ''),
					RawItem: cls
				};
			});
		},
		canAccessQuanSinh() {
			return [3, 4, 5, 9].includes(this.currentSystemRight);
		},
		canAccessGvcn() {
			return [1, 9].includes(this.currentSystemRight);
		},
		canAccessBaoCao() {
			return [3, 4, 5, 9].includes(this.currentSystemRight);
		},
		isGVCNRole() {
			return this.currentSystemRight === 1;
		},
		isQuanSinhRole() {
			return this.currentSystemRight === 4;
		},
		isBghRole() {
			return this.currentSystemRight === 3 || this.currentSystemRight === 5;
		},
		hasMultipleTabs() {
			var count = 0;
			if (this.canAccessQuanSinh) count++;
			if (this.canAccessGvcn) count++;
			if (this.canAccessBaoCao) count++;
			return count > 1;
		},
		isBghOrAdmin() {
			return [3, 5, 9].includes(this.currentSystemRight);
		},
		currentRoleInfo() {
			var sr = this.currentSystemRight;
			var found = this.userRoles.find(function(r) { return r.id === sr; });
			return found || {
				id: sr,
				name: 'Người dùng',
				color: 'primary',
				icon: 'mdi-shield-account'
			};
		},
		currentRoleName() {
			return this.currentRoleInfo.name;
		},
		currentRoleColor() {
			return this.currentRoleInfo.color;
		},
		currentRoleIcon() {
			return this.currentRoleInfo.icon;
		},
		bghWeeklyReportClasses() {
			var _ver = this.evalUpdateVersion;
			var that = this;
			var k = this.selectedKhoi || 6;
			var list = this.getRealClassesByKhoi(k);
			return list.map(function(cls) {
				return that.getWeeklyClassEvaluation(cls);
			});
		},
		bghWeeklyReportStats() {
			var classes = this.bghWeeklyReportClasses || [];
			var tot = 0;
			var dat = 0;
			var blocked = 0;
			classes.forEach(function(c) {
				if (c.isApplied) {
					blocked++;
				} else if (c.xepLoaiTuan === 'Xuất sắc' || c.xepLoaiTuan === 'Tốt') {
					tot++;
				} else if (c.xepLoaiTuan === 'Đạt') {
					dat++;
				} else if (c.xepLoaiTuan === 'Cần nhắc nhở') {
					blocked++;
				}
			});
			return {
				total: classes.length,
				totCount: tot,
				datCount: dat,
				blockedCount: blocked
			};
		}
	},
	watch: {
		activeTab(newTab) {
			if (this.qsAutoSaveTimer) {
				clearTimeout(this.qsAutoSaveTimer);
				this.autoSaveDailyEvaluation(0);
			}
			var that = this;
			if (this.selectedWeek && this.availableWeekList && this.availableWeekList.length && !this.availableWeekList.some(function(w) { return w.id === that.selectedWeek.id; })) {
				var nowMs = new Date().getTime();
				var curIdx = this.weekList.findIndex(function(w) { return nowMs >= w.startMs && nowMs <= w.endMs; });
				if (curIdx === -1) curIdx = 0;
				this.selectedWeek = this.weekList[curIdx] || this.availableWeekList[this.availableWeekList.length - 1];
			}
			if (newTab === 'gvcn') {
				if (this.selectedGvcnClassId) {
					this.loadGvcnScheduleForClass(this.selectedGvcnClassId);
					this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
				}
			}
		},
		currentSystemRight(newVal) {
			if (newVal === 1) {
				this.activeTab = 'gvcn';
			} else if (newVal === 3 || newVal === 5) {
				this.activeTab = 'baocao';
			} else if (newVal === 4) {
				this.activeTab = 'quansinh';
			}
		},
		selectedWeek: {
			handler() {
				this.onWeekSelected();
			},
			deep: true
		}
	},
	created() {
		this.loadSchedulesFromLocalStorage();
		this.initUserRole();
		this.weekList = this.generateSchoolYearWeeks();
		var nowMs = new Date().getTime();
		var currentWeek = this.weekList.find(function(w) {
			return nowMs >= w.startMs && nowMs <= w.endMs;
		});
		this.selectedWeek = currentWeek || this.weekList[0];
		this.updateDaysForSelectedWeek();
		// Tự động nhận diện Thứ hôm nay trong tuần (Thứ 2 đến Thứ 6)
		var currentDayOfWeek = new Date().getDay(); // 0: CN, 1: T2, 2: T3, 3: T4, 4: T5, 5: T6, 6: T7
		if (currentDayOfWeek >= 1 && currentDayOfWeek <= 5) {
			this.selectedDay = currentDayOfWeek + 1; // 1 -> 2 (Thứ 2), 2 -> 3 (Thứ 3), 3 -> 4 (Thứ 4), 4 -> 5 (Thứ 5), 5 -> 6 (Thứ 6)
		} else {
			this.selectedDay = 2; // Cuối tuần (thứ 7, CN) thì mặc định Thứ 2
		}
		this.currentActiveDateStr = this.getDateStringForDay(this.selectedDay);
		this.initSampleHistoricalSnapshots();
		this.loadSnapshotsFromLocalStorage();
		this.ensureClass06DThursdaySnapshot();
		this.loadClassesForCurrentDay();
		this.loadGvcnScheduleForClass(this.selectedGvcnClassId);
		this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
		var now = new Date();
		this.lastSavedTime = String(now.getHours()).padStart(2, '0') + ':' + String(now.getMinutes()).padStart(2, '0');
		this.qsLastSavedTime = this.lastSavedTime;
	},
	methods: {
		formatCurrentTime() {
			var now = new Date();
			var hh = String(now.getHours()).padStart(2, '0');
			var mm = String(now.getMinutes()).padStart(2, '0');
			return hh + ':' + mm;
		},
		isDayFullyEvaluated(dayVal) {
			var dateStr = this.getDateStringForDay(dayVal);
			var keyPrefix = dateStr + '_';
			var isW1 = (!this.selectedWeek || this.selectedWeek.startDate === '2026-10-05');
			var legacyPrefix = String(dayVal) + '_';
			return Object.keys(this.dailySnapshots).some(function(k) {
				return k.startsWith(keyPrefix) || (isW1 && k.startsWith(legacyPrefix));
			});
		},
		saveSchedulesToLocalStorage() {
			try {
				if (typeof window !== 'undefined' && window.localStorage) {
					window.localStorage.setItem('lhbs_gvcn_schedules_cache_v2', JSON.stringify(this.gvcnSchedulesByClass));
				}
			} catch (e) {
				console.warn('Cannot write localStorage:', e);
			}
		},
		loadSchedulesFromLocalStorage() {
			try {
				if (typeof window !== 'undefined' && window.localStorage) {
					// Dọn dẹp cache cũ để tránh nạp lại mặc định Thứ 3, Thứ 5
					if (window.localStorage.getItem('lhbs_gvcn_schedules_cache')) {
						window.localStorage.removeItem('lhbs_gvcn_schedules_cache');
					}
					var raw = window.localStorage.getItem('lhbs_gvcn_schedules_cache_v2');
					if (raw) {
						var parsed = JSON.parse(raw);
						if (parsed && typeof parsed === 'object') {
							this.gvcnSchedulesByClass = Object.assign({}, parsed, this.gvcnSchedulesByClass);
						}
					}
				}
			} catch (e) {
				console.warn('Cannot read localStorage:', e);
			}
		},
		saveSnapshotsToLocalStorage() {
			try {
				if (typeof window !== 'undefined' && window.localStorage) {
					window.localStorage.setItem('lhbs_qs_daily_snapshots_cache', JSON.stringify(this.dailySnapshots));
				}
			} catch (e) {
				console.warn('Cannot write snapshots to localStorage:', e);
			}
		},
		loadSnapshotsFromLocalStorage() {
			try {
				if (typeof window !== 'undefined' && window.localStorage) {
					var raw = window.localStorage.getItem('lhbs_qs_daily_snapshots_cache');
					if (raw) {
						var parsed = JSON.parse(raw);
						if (parsed && typeof parsed === 'object') {
							for (var k in parsed) {
								this.dailySnapshots[k] = parsed[k];
							}
						}
					}
				}
			} catch (e) {
				console.warn('Cannot read snapshots from localStorage:', e);
			}
		},
		autoSaveGvcnSchedule(delayMs) {
			if (this.isInitializingSchedule) return;
			var weekId = this.selectedWeek ? this.selectedWeek.id : 1;
			var lopId = this.selectedGvcnClassId;
			if (!lopId || !this.gvcnWeekSchedule || !this.gvcnWeekSchedule.length) return;
			var cacheKey = weekId + '_' + lopId;

			this.autoSaveStatus = 'saving';
			clearTimeout(this.autoSaveTimer);

			var that = this;
			var wait = (delayMs !== undefined) ? delayMs : 400;
			this.autoSaveTimer = setTimeout(function() {
				that.gvcnSchedulesByClass[cacheKey] = JSON.parse(JSON.stringify(that.gvcnWeekSchedule));
				that.saveSchedulesToLocalStorage();

				that.lastSavedTime = that.formatCurrentTime();
				that.autoSaveStatus = 'saved';
			}, wait);
		},
		autoSaveDailyEvaluation(delayMs) {
			if (this.isReadOnlyDay || this.selectedDay === 2) return;
			var wait = (delayMs !== undefined) ? delayMs : 400;
			this.qsAutoSaveStatus = 'saving';
			clearTimeout(this.qsAutoSaveTimer);
			var that = this;
			var dayVal = this.selectedDay;
			var dateStr = this.getDateStringForDay(dayVal);

			this.qsAutoSaveTimer = setTimeout(function() {
				that.currentClasses.forEach(function(c) {
					c.IsSaved = true;
					var snapshotKey = dateStr + '_' + c.LopID;
					that.dailySnapshots[snapshotKey] = {
						TieuChiList: JSON.parse(JSON.stringify(c.TieuChiList)),
						GhiChuViPham: c.GhiChuViPham,
						IsTuQuan: c.IsTuQuan,
						IsSaved: true,
						NguoiCham: c.NguoiCham || 'Quản sinh khối'
					};
				});
				if (that.dailyWorkingState[dateStr]) {
					delete that.dailyWorkingState[dateStr];
				}
				that.dailySnapshots = Object.assign({}, that.dailySnapshots);
				that.evalUpdateVersion++;
				that.saveSnapshotsToLocalStorage();
				that.qsLastSavedTime = that.formatCurrentTime();
				that.qsAutoSaveStatus = 'saved';
				if (that.selectedGvcnClassId) {
					that.loadGvcnHistoryForClass(that.selectedGvcnClassId);
				}
			}, wait);
		},
		onQsNoteChange() {
			if (this.isReadOnlyDay || this.selectedDay === 2) return;
			this.evalUpdateVersion++;
			this.autoSaveDailyEvaluation(600);
		},
		onNoteInput() {
			this.autoSaveGvcnSchedule(400);
		},
		initUserRole() {
			var user = (typeof vueData !== 'undefined' && vueData && vueData.user) ? vueData.user : null;
			if (user) {
				var sr = user.SystemRight;
				if (Array.isArray(sr) && sr.length > 0) {
					sr = sr[0];
				}
				if (sr != null && !isNaN(Number(sr))) {
					this.currentSystemRight = Number(sr);
				}
				if (user.FullName || user.DisplayName) {
					this.currentUserName = user.FullName || user.DisplayName;
				}
				if (this.currentSystemRight === 1) {
					this.activeTab = 'gvcn';
					if (user.LopID) {
						this.selectedGvcnClassId = String(user.LopID);
					}
				} else if (this.currentSystemRight === 3 || this.currentSystemRight === 5) {
					this.activeTab = 'baocao';
				} else {
					this.activeTab = 'quansinh';
				}
			}
		},
		switchRole(roleId) {
			this.currentSystemRight = roleId;
			var targetTab = (roleId === 1) ? 'gvcn' : (roleId === 3 || roleId === 5 ? 'baocao' : 'quansinh');
			this.activeTab = targetTab;
			if (roleId === 1) {
				var that = this;
				var nowMs = new Date().getTime();
				var curIdx = this.weekList.findIndex(function(w) { return nowMs >= w.startMs && nowMs <= w.endMs; });
				if (curIdx === -1) curIdx = 0;
				if (this.selectedWeek && !this.availableWeekList.some(function(w) { return w.id === that.selectedWeek.id; })) {
					this.selectedWeek = this.weekList[curIdx];
					this.onWeekSelected();
				}
				var gvClass = this.allSchoolClasses.find(function(c) { return c.TenLop === '06A'; }) || this.allSchoolClasses[0];
				if (gvClass) {
					this.onGvcnClassChanged(gvClass.LopID);
				} else if (this.selectedGvcnClassId) {
					this.loadGvcnScheduleForClass(this.selectedGvcnClassId);
					this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
				}
			} else if (roleId === 3 || roleId === 5) {
				this.evalUpdateVersion++;
			}
			this.$nextTick(function() {
				this.activeTab = targetTab;
			}.bind(this));
			this.showNotice('Đã chuyển sang vai trò: ' + this.currentRoleName, 'info');
		},
		goToReportView(mode) {
			this.activeTab = 'baocao';
			this.bghViewMode = mode || 'month';
		},
		generateSchoolYearWeeks() {
			var list = [];
			var start = new Date(2026, 7, 17); // 17/08/2026 (Thứ 2)
			var end = new Date(2027, 5, 27);   // 27/06/2027 (Chủ nhật)
			var cur = new Date(start.getTime());
			var monthCounters = {};
			var id = 1;

			while (cur <= end) {
				var curEnd = new Date(cur.getTime());
				curEnd.setDate(cur.getDate() + 6);
				curEnd.setHours(23, 59, 59, 999);

				var month = cur.getMonth() + 1;
				var monthKey = cur.getFullYear() + '_' + month;
				monthCounters[monthKey] = (monthCounters[monthKey] || 0) + 1;
				var weekInMonth = monthCounters[monthKey];

				var d1 = String(cur.getDate()).padStart(2, '0') + '/' +
				         String(cur.getMonth() + 1).padStart(2, '0') + '/' +
				         cur.getFullYear();
				var d2 = String(curEnd.getDate()).padStart(2, '0') + '/' +
				         String(curEnd.getMonth() + 1).padStart(2, '0') + '/' +
				         curEnd.getFullYear();

				var startYMD = cur.getFullYear() + '-' +
				               String(cur.getMonth() + 1).padStart(2, '0') + '-' +
				               String(cur.getDate()).padStart(2, '0');
				var endYMD = curEnd.getFullYear() + '-' +
				             String(curEnd.getMonth() + 1).padStart(2, '0') + '-' +
				             String(curEnd.getDate()).padStart(2, '0');

				var title = 'Tuần ' + weekInMonth + ' - Tháng ' + month + ' - (' + d1 + ' - ' + d2 + ')';

				list.push({
					id: id++,
					title: title,
					weekNum: weekInMonth,
					month: month,
					startDate: startYMD,
					endDate: endYMD,
					startMs: cur.getTime(),
					endMs: curEnd.getTime()
				});

				cur.setDate(cur.getDate() + 7);
			}
			return list;
		},
		getDateStringForDay(dayVal, week) {
			var targetWeek = week || this.selectedWeek;
			var startStr = (targetWeek && targetWeek.startDate) || '2026-10-05';
			var parts = startStr.split('-');
			var monday = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
			var offset = ((dayVal || this.selectedDay || 2) - 2);
			var d = new Date(monday.getTime());
			d.setDate(monday.getDate() + offset);
			var yyyy = d.getFullYear();
			var mm = String(d.getMonth() + 1).padStart(2, '0');
			var dd = String(d.getDate()).padStart(2, '0');
			return yyyy + '-' + mm + '-' + dd;
		},
		saveWorkingStateForDate(dateStr) {
			if (this.isReadOnlyDay || !dateStr || !this.currentClasses || this.currentClasses.length === 0) return;
			var that = this;
			var k = this.selectedKhoi || 6;
			var list = this.getRealClassesByKhoi(k);
			var hasSnapshot = list.some(function(item) {
				return that.dailySnapshots[dateStr + '_' + item.LopID] || (that.selectedWeek && that.selectedWeek.startDate === '2026-10-05' && that.dailySnapshots[String(that.selectedDay) + '_' + item.LopID]);
			});
			if (!hasSnapshot) {
				this.dailyWorkingState[dateStr] = JSON.parse(JSON.stringify(this.currentClasses));
			}
		},
		onDayChanged(newDay) {
			if (this.isSpecificDayInFuture(newDay)) {
				this.selectedDay = this.realTodayDayVal;
				return;
			}
			if (this.currentActiveDateStr) {
				this.saveWorkingStateForDate(this.currentActiveDateStr);
			}
			this.selectedDay = newDay;
			this.currentActiveDateStr = this.getDateStringForDay(newDay);
			this.loadClassesForCurrentDay();
		},
		onWeekSelected() {
			if (this.currentActiveDateStr) {
				this.saveWorkingStateForDate(this.currentActiveDateStr);
			}
			this.updateDaysForSelectedWeek();
			if (this.isSpecificDayInFuture(this.selectedDay)) {
				this.selectedDay = this.realTodayDayVal;
			}
			if (this.bghSelectedDay && this.isSpecificDayInFuture(this.bghSelectedDay)) {
				this.bghSelectedDay = this.realTodayDayVal;
			}
			this.currentActiveDateStr = this.getDateStringForDay(this.selectedDay);
			if (this.selectedWeek && this.selectedWeek.weekNum) {
				this.outerMonthlySelectedWeekNum = this.selectedWeek.weekNum;
				this.evidenceDialog.selectedWeekNum = this.selectedWeek.weekNum;
			}
			this.loadClassesForCurrentDay();
		},
		updateDaysForSelectedWeek() {
			var startStr = (this.selectedWeek && this.selectedWeek.startDate) || '2026-10-05';
			var parts = startStr.split('-');
			var monday = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
			var dayLabels = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6'];
			var newDays = [];
			for (var i = 0; i < 5; i++) {
				var d = new Date(monday.getTime());
				d.setDate(monday.getDate() + i);
				var dd = String(d.getDate()).padStart(2, '0');
				var mm = String(d.getMonth() + 1).padStart(2, '0');
				newDays.push({
					val: i + 2,
					label: dayLabels[i],
					date: dd + '/' + mm
				});
				if (this.gvcnWeekSchedule && this.gvcnWeekSchedule[i]) {
					this.gvcnWeekSchedule[i].date = dd + '/' + mm;
				}
			}
			this.daysOfWeek = newDays;
		},
		isSpecificDayInFuture(dayVal) {
			var startStr = (this.selectedWeek && this.selectedWeek.startDate) || '2026-10-05';
			var parts = startStr.split('-');
			var monday = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
			var dayOffset = (dayVal || 2) - 2;
			var d = new Date(monday.getTime());
			d.setDate(monday.getDate() + dayOffset);
			d.setHours(0, 0, 0, 0);
			var today = new Date();
			today.setHours(0, 0, 0, 0);
			return d.getTime() > today.getTime();
		},
		isSpecificDayInPast(dayVal) {
			var startStr = (this.selectedWeek && this.selectedWeek.startDate) || '2026-10-05';
			var parts = startStr.split('-');
			var monday = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
			var dayOffset = (dayVal || 2) - 2;
			var d = new Date(monday.getTime());
			d.setDate(monday.getDate() + dayOffset);
			d.setHours(0, 0, 0, 0);
			var today = new Date();
			today.setHours(0, 0, 0, 0);
			return d.getTime() < today.getTime();
		},
		isSpecificDayToday(dayVal) {
			return !this.isSpecificDayInPast(dayVal) && !this.isSpecificDayInFuture(dayVal);
		},
		getCurrentTimeForRules() {
			if (this.mockHourOverride !== null && this.mockHourOverride !== undefined) {
				var d = new Date();
				d.setHours(this.mockHourOverride, this.mockMinuteOverride || 0, 0, 0);
				return d;
			}
			return new Date();
		},
		isPastQsCutoffTime() {
			var now = this.getCurrentTimeForRules();
			var hours = now.getHours();
			var minutes = now.getMinutes();
			return (hours > 9) || (hours === 9 && minutes >= 30);
		},
		isPastGvcnCutoffTime() {
			var now = this.getCurrentTimeForRules();
			return now.getHours() >= 6;
		},
		isDayGvcnLocked(dayKey) {
			if (dayKey === 2) return true;
			if (this.isPastSelectedWeek) return true;
			if (this.isSpecificDayInPast(dayKey)) return true;
			if (this.isSpecificDayToday(dayKey) && this.isPastGvcnCutoffTime()) return true;
			return false;
		},
		setMockTime(hour, minute) {
			this.mockHourOverride = hour;
			this.mockMinuteOverride = minute || 0;
			this.evalUpdateVersion++;
			var msg = (hour === null)
				? 'Đã chuyển về giờ thực tế hệ thống'
				: ('Đã giả lập thời gian: ' + String(hour).padStart(2, '0') + ':' + String(minute || 0).padStart(2, '0'));
			this.showNotice(msg, 'info');
		},
		prevWeek() {
			if (this.selectedWeekIndex > 0) {
				this.selectedWeek = this.availableWeekList[this.selectedWeekIndex - 1];
				this.onWeekSelected();
			}
		},
		nextWeek() {
			if (this.selectedWeekIndex < this.availableWeekList.length - 1) {
				this.selectedWeek = this.availableWeekList[this.selectedWeekIndex + 1];
				this.onWeekSelected();
			}
		},
		onFilterChanged() {
			this.loadClassesForCurrentDay();
		},
		reloadData() {
			this.isLoading = true;
			var that = this;
			setTimeout(function() {
				that.loadSnapshotsFromLocalStorage();
				that.loadSchedulesFromLocalStorage();
				that.loadClassesForCurrentDay();
				if (that.selectedGvcnClassId) {
					that.loadGvcnScheduleForClass(that.selectedGvcnClassId);
					that.loadGvcnHistoryForClass(that.selectedGvcnClassId);
				}
				that.isLoading = false;
				that.showNotice('Đã làm mới dữ liệu!', 'success');
			}, 300);
		},
		// Khởi tạo snapshot mẫu lịch sử cho Thứ 2, Thứ 3, Thứ 4 của Tuần 1
		initSampleHistoricalSnapshots() {
			var that = this;
			var classList = this.getRealClassesByKhoi(6);

			// 1. Snapshot Thứ 2 (05/10/2026): Nền nếp tốt, sinh hoạt đầu tuần toàn trường
			classList.forEach(function(item) {
				var keyT2 = '2026-10-05_' + item.LopID;
				var legacyKey = '2_' + item.LopID;
				var snap = {
					IsTuQuan: false,
					GVCNCoMat: true,
					TieuChiList: [
						{ id: 'c1', ten: '1. Không gian lớp (Mở cửa, VS, bàn ghế)', shortTitle: 'Không gian lớp (Mở cửa, VS, bàn ghế)', score: 3, isCustom: false },
						{ id: 'c2', ten: '2. Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', shortTitle: 'Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', score: 3, isCustom: false },
						{ id: 'c3', ten: '3. Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', shortTitle: 'Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', score: 3, isCustom: false }
					],
					GhiChuViPham: '',
					IsSaved: true,
					NguoiCham: 'Quản sinh khối'
				};
				that.dailySnapshots[keyT2] = snap;
				that.dailySnapshots[legacyKey] = snap;
			});

			// 2. Snapshot Thứ 3 (06/10/2026): Nền nếp Tốt, tất cả các lớp đạt Tốt (kể cả 06D)
			classList.forEach(function(item) {
				var keyT3 = '2026-10-06_' + item.LopID;
				var legacyKey = '3_' + item.LopID;
				var snap = {
					IsTuQuan: true,
					GVCNCoMat: false,
					TieuChiList: [
						{ id: 'c1', ten: '1. Không gian lớp (Mở cửa, VS, bàn ghế)', shortTitle: 'Không gian lớp (Mở cửa, VS, bàn ghế)', score: 3, isCustom: false },
						{ id: 'c2', ten: '2. Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', shortTitle: 'Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', score: 3, isCustom: false },
						{ id: 'c3', ten: '3. Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', shortTitle: 'Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', score: 3, isCustom: false }
					],
					GhiChuViPham: '',
					IsSaved: true,
					NguoiCham: 'QS. Trần Tuấn'
				};
				that.dailySnapshots[keyT3] = snap;
				that.dailySnapshots[legacyKey] = snap;
			});

			// 3. Snapshot Thứ 4 (07/10/2026): Nền nếp Tốt, tất cả các lớp đạt Tốt (kể cả 06D)
			classList.forEach(function(item) {
				var keyT4 = '2026-10-07_' + item.LopID;
				var legacyKey = '4_' + item.LopID;
				var snap = {
					IsTuQuan: true,
					GVCNCoMat: false,
					TieuChiList: [
						{ id: 'c1', ten: '1. Không gian lớp (Mở cửa, VS, bàn ghế)', shortTitle: 'Không gian lớp (Mở cửa, VS, bàn ghế)', score: 3, isCustom: false },
						{ id: 'c2', ten: '2. Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', shortTitle: 'Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', score: 3, isCustom: false },
						{ id: 'c3', ten: '3. Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', shortTitle: 'Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', score: 3, isCustom: false }
					],
					GhiChuViPham: '',
					IsSaved: true,
					NguoiCham: 'QS. Trần Tuấn'
				};
				that.dailySnapshots[keyT4] = snap;
				that.dailySnapshots[legacyKey] = snap;
			});

			// 4. Snapshot Thứ 5 (08/10/2026): Lớp 06D vi phạm nề nếp (Không gian lớp, sọt rác, ồn ào -> dính Chưa đạt CĐ)
			classList.forEach(function(item) {
				var keyT5 = '2026-10-08_' + item.LopID;
				var legacyKey = '5_' + item.LopID;
				var is06D = (item.TenLop === '06D');
				var snap = {
					IsTuQuan: true,
					GVCNCoMat: false,
					TieuChiList: [
						{ id: 'c1', ten: '1. Không gian lớp (Mở cửa, VS, bàn ghế)', shortTitle: 'Không gian lớp (Mở cửa, VS, bàn ghế)', score: is06D ? 1 : 3, isCustom: false },
						{ id: 'c2', ten: '2. Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', shortTitle: 'Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', score: is06D ? 1 : 3, isCustom: false },
						{ id: 'c3', ten: '3. Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', shortTitle: 'Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', score: 3, isCustom: false }
					],
					GhiChuViPham: is06D ? 'Sọt rác đầy chưa đổ, cuối lớp còn nhiều rác giấy vụn; 4 học sinh chưa làm bài tập' : '',
					IsSaved: true,
					NguoiCham: 'QS. Trần Tuấn'
				};
				that.dailySnapshots[keyT5] = snap;
				that.dailySnapshots[legacyKey] = snap;
			});
		},
		ensureClass06DThursdaySnapshot() {
			var snap06D = {
				IsTuQuan: true,
				GVCNCoMat: false,
				TieuChiList: [
					{ id: 'c1', ten: '1. Không gian lớp (Mở cửa, VS, bàn ghế)', shortTitle: 'Không gian lớp (Mở cửa, VS, bàn ghế)', score: 1, isCustom: false },
					{ id: 'c2', ten: '2. Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', shortTitle: 'Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', score: 1, isCustom: false },
					{ id: 'c3', ten: '3. Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', shortTitle: 'Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', score: 3, isCustom: false }
				],
				GhiChuViPham: 'Sọt rác đầy chưa đổ, cuối lớp còn nhiều rác giấy vụn; 4 học sinh chưa làm bài tập',
				IsSaved: true,
				NguoiCham: 'QS. Trần Tuấn'
			};
			this.dailySnapshots['2026-10-08_2722'] = snap06D;
			this.dailySnapshots['5_2722'] = snap06D;
		},
		getRealClassesByKhoi(khoiId) {
			var allRealClasses = {
				6: [
					{"LopID": "2719", "TenLop": "06A", "TenGVCN": "Nguyễn Thảo Nguyên", "SiSo": 36},
					{"LopID": "2720", "TenLop": "06B", "TenGVCN": "Chu Thùy Diệu My", "SiSo": 35},
					{"LopID": "2721", "TenLop": "06C", "TenGVCN": "Lê Thị Hòa", "SiSo": 36},
					{"LopID": "2722", "TenLop": "06D", "TenGVCN": "Nguyễn Ngọc Bảo Trâm", "SiSo": 35},
					{"LopID": "2723", "TenLop": "06E", "TenGVCN": "Phạm Thị Oanh", "SiSo": 36},
					{"LopID": "2724", "TenLop": "06F", "TenGVCN": "Lê Thị Thúy Ly", "SiSo": 35},
					{"LopID": "2725", "TenLop": "06G", "TenGVCN": "Trần Thuỳ Dung", "SiSo": 36},
					{"LopID": "2726", "TenLop": "06H", "TenGVCN": "Lê Thị Thanh Thủy", "SiSo": 35}
				],
				7: [
					{"LopID": "2670", "TenLop": "07A", "TenGVCN": "Nguyễn Thị Lành", "SiSo": 36},
					{"LopID": "2669", "TenLop": "07B", "TenGVCN": "Nguyễn Thị Thanh Thùy", "SiSo": 35},
					{"LopID": "2668", "TenLop": "07C", "TenGVCN": "Nguyễn Thị Sen", "SiSo": 36},
					{"LopID": "2667", "TenLop": "07D", "TenGVCN": "Nguyễn Thị Mai", "SiSo": 35},
					{"LopID": "2666", "TenLop": "07E", "TenGVCN": "Nguyễn Trần Gia Hân", "SiSo": 36},
					{"LopID": "2665", "TenLop": "07F", "TenGVCN": "Cao Thị Lan Hương", "SiSo": 35},
					{"LopID": "2664", "TenLop": "07G", "TenGVCN": "Trần Thị Toàn", "SiSo": 36},
					{"LopID": "2663", "TenLop": "07H", "TenGVCN": "Lê Nguyễn Anh Thư", "SiSo": 35}
				],
				8: [
					{"LopID": "2662", "TenLop": "08A", "TenGVCN": "Nguyễn Kim Bảo Khánh", "SiSo": 35},
					{"LopID": "2661", "TenLop": "08B", "TenGVCN": "Đỗ Hoài Lượng", "SiSo": 35},
					{"LopID": "2660", "TenLop": "08C", "TenGVCN": "Nguyễn Mai Khanh", "SiSo": 35},
					{"LopID": "2659", "TenLop": "08D", "TenGVCN": "Phạm Minh Trường", "SiSo": 35},
					{"LopID": "2658", "TenLop": "08E", "TenGVCN": "Nguyễn Thị Thắm", "SiSo": 35},
					{"LopID": "2657", "TenLop": "08F", "TenGVCN": "Trần Thị Thanh Dung", "SiSo": 35}
				],
				9: [
					{"LopID": "2656", "TenLop": "09A", "TenGVCN": "Nguyễn Hoài Giang", "SiSo": 36},
					{"LopID": "2655", "TenLop": "09B", "TenGVCN": "Phạm Thị Linh", "SiSo": 35},
					{"LopID": "2654", "TenLop": "09C", "TenGVCN": "Nguyễn Thị Trí", "SiSo": 36},
					{"LopID": "2653", "TenLop": "09D", "TenGVCN": "Trần Văn Hạnh", "SiSo": 35},
					{"LopID": "2652", "TenLop": "09E", "TenGVCN": "Đỗ Thị Thanh Huyền", "SiSo": 36},
					{"LopID": "2651", "TenLop": "09F", "TenGVCN": "Nguyễn Thị Phương Nam", "SiSo": 35},
					{"LopID": "2650", "TenLop": "09G", "TenGVCN": "Lưu Gia Tuệ", "SiSo": 36},
					{"LopID": "2649", "TenLop": "09H", "TenGVCN": "Lê Hồng Linh", "SiSo": 35}
				],
				10: [
					{"LopID": "2727", "TenLop": "10A", "TenGVCN": "Lê Thị Hạnh", "SiSo": 38},
					{"LopID": "2281", "TenLop": "10B", "TenGVCN": "Hà Thị Hằng", "SiSo": 38},
					{"LopID": "2282", "TenLop": "10C", "TenGVCN": "La Gia Nghi", "SiSo": 38},
					{"LopID": "2283", "TenLop": "10D", "TenGVCN": "Lê Văn Hải", "SiSo": 38},
					{"LopID": "2284", "TenLop": "10E", "TenGVCN": "Triệu Quang Vĩnh", "SiSo": 38},
					{"LopID": "2285", "TenLop": "10F", "TenGVCN": "Huỳnh Phạm Quế Anh", "SiSo": 38}
				],
				11: [
					{"LopID": "2286", "TenLop": "11A", "TenGVCN": "Nguyễn Thị Thu Mai", "SiSo": 36},
					{"LopID": "2647", "TenLop": "11B", "TenGVCN": "Trần Thanh Tâm", "SiSo": 36},
					{"LopID": "2289", "TenLop": "11C", "TenGVCN": "Lê Thanh Điền", "SiSo": 36},
					{"LopID": "2290", "TenLop": "11D", "TenGVCN": "Phạm Phi Cường", "SiSo": 36},
					{"LopID": "2291", "TenLop": "11E", "TenGVCN": "Tô Hoàng Thật", "SiSo": 36}
				],
				12: [
					{"LopID": "2277", "TenLop": "12A", "TenGVCN": "Nguyễn Quốc Việt", "SiSo": 35},
					{"LopID": "2292", "TenLop": "12B", "TenGVCN": "Biện Thị Kim Thắm", "SiSo": 35},
					{"LopID": "2641", "TenLop": "12C", "TenGVCN": "Nguyễn Thị Thảo Loan", "SiSo": 35},
					{"LopID": "2295", "TenLop": "12D", "TenGVCN": "Nguyễn Thị Bích Hạnh", "SiSo": 35},
					{"LopID": "2296", "TenLop": "12E", "TenGVCN": "Nguyễn Thị Bích Ngọc", "SiSo": 35}
				]
			};
			return allRealClasses[khoiId] || allRealClasses[6];
		},
		getScheduleForClass(lopId, week) {
			var curWeek = week || this.selectedWeek;
			var weekId = curWeek ? curWeek.id : 1;
			var cacheKey = weekId + '_' + lopId;

			if (!this.gvcnSchedulesByClass[cacheKey]) {
				try {
					if (typeof window !== 'undefined' && window.localStorage) {
						var raw = window.localStorage.getItem('lhbs_gvcn_schedules_cache_v2');
						if (raw) {
							var parsed = JSON.parse(raw);
							if (parsed && parsed[cacheKey]) {
								this.gvcnSchedulesByClass[cacheKey] = parsed[cacheKey];
							}
						}
					}
				} catch (e) {}
			}

			if (!this.gvcnSchedulesByClass[cacheKey]) {
				var startStr = (curWeek && curWeek.startDate) || '2026-10-05';
				var parts = startStr.split('-');
				var monday = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
				var dayLabels = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6'];
				var is06D = (String(lopId) === '2722');
				var isWeek1 = (!curWeek || curWeek.startDate === '2026-10-05');

				var weekDays = [];
				for (var i = 0; i < 5; i++) {
					var d = new Date(monday.getTime());
					d.setDate(monday.getDate() + i);
					var dd = String(d.getDate()).padStart(2, '0');
					var mm = String(d.getMonth() + 1).padStart(2, '0');
					var dateFormatted = dd + '/' + mm;

					var isFixed = (i === 0); // Thứ 2 luôn cố định GVCN sinh hoạt
					var isTuQuan = false;
					var coMat = true;
					var ghiChu = '';

					if (isFixed) {
						isTuQuan = false;
						coMat = true;
						ghiChu = 'Sinh hoạt đầu tuần toàn trường';
					} else if (isWeek1) {
						if (i === 1) { // Thứ 3
							isTuQuan = true;
							coMat = false;
							ghiChu = 'Ban cán sự điều hành';
						} else if (i === 2) { // Thứ 4
							isTuQuan = is06D;
							coMat = !is06D;
							ghiChu = is06D ? 'Ban cán sự điều hành' : '';
						} else if (i === 3) { // Thứ 5
							isTuQuan = true;
							coMat = false;
							ghiChu = is06D ? 'Ban cán sự điều hành' : 'Sinh hoạt chủ đề nề nếp';
						} else if (i === 4) { // Thứ 6
							var is06A = (String(lopId) === '2719');
							isTuQuan = is06A;
							coMat = !is06A;
							ghiChu = is06A ? 'Ban cán sự điều hành' : '';
						}
					} else {
						// Mặc định KHÔNG chọn ngày tự quản nào để GVCN tự chủ động chọn chỗ đăng ký
						isTuQuan = false;
						coMat = true;
						ghiChu = '';
					}

					weekDays.push({
						key: i + 2,
						label: dayLabels[i],
						date: dateFormatted,
						IsTuQuan: isTuQuan,
						CoMat: coMat,
						isFixed: isFixed,
						GhiChu: ghiChu
					});
				}
				this.gvcnSchedulesByClass[cacheKey] = weekDays;
			}
			if (String(lopId) === '2722' && (!curWeek || curWeek.startDate === '2026-10-05') && this.gvcnSchedulesByClass[cacheKey]) {
				var d5 = this.gvcnSchedulesByClass[cacheKey].find(function(s) { return s.key === 5; });
				if (d5) {
					d5.IsTuQuan = true;
					d5.CoMat = false;
				}
			}
			return this.gvcnSchedulesByClass[cacheKey];
		},
		createFreshClassItem(item, dateStr, idx) {
			var criteria = JSON.parse(JSON.stringify(this.baseCriteria));
			if (this.dailyCustomCriteria[dateStr]) {
				var dateCustom = this.dailyCustomCriteria[dateStr];
				if (dateCustom.global) {
					dateCustom.global.forEach(function(gc) {
						criteria.push({ id: gc.id, ten: gc.ten, shortTitle: gc.shortTitle, score: 3, isCustom: true, scope: 'all', date: dateStr });
					});
				}
				if (dateCustom.byClass && dateCustom.byClass[item.LopID]) {
					dateCustom.byClass[item.LopID].forEach(function(cc) {
						criteria.push({ id: cc.id, ten: cc.ten, shortTitle: cc.shortTitle, score: 3, isCustom: true, scope: 'class', lopId: item.LopID, tenLop: item.TenLop, date: dateStr });
					});
				}
			}
			var dayVal = this.selectedDay;
			var sched = this.getScheduleForClass(item.LopID);
			var daySched = sched ? sched.find(function(s) { return s.key === dayVal; }) : null;
			var isTuQuan = (dayVal !== 2) && daySched ? !!daySched.IsTuQuan : false;
			return {
				LopID: item.LopID,
				TenLop: item.TenLop,
				TenGVCN: item.TenGVCN,
				IsTuQuan: isTuQuan,
				TieuChiList: criteria,
				GhiChuViPham: '',
				IsSaved: false,
				NguoiCham: 'Quản sinh khối'
			};
		},
		loadClassesForCurrentDay() {
			var that = this;
			var k = this.selectedKhoi || 6;
			var list = this.getRealClassesByKhoi(k);
			var dayVal = this.selectedDay;
			var dateStr = this.getDateStringForDay(dayVal);
			this.currentActiveDateStr = dateStr;

			// Priority 1: Nếu ngày này đã có snapshot lịch sử -> Tái hiện 100% snapshot của ngày đó
			var hasAnySnapshot = list.some(function(item) {
				var snapshotKey = dateStr + '_' + item.LopID;
				var legacyKey = String(dayVal) + '_' + item.LopID;
				return that.dailySnapshots[snapshotKey] || (that.selectedWeek && that.selectedWeek.startDate === '2026-10-05' && that.dailySnapshots[legacyKey]);
			});

			if (hasAnySnapshot) {
				this.currentClasses = list.map(function(item) {
					var snapshotKey = dateStr + '_' + item.LopID;
					var legacyKey = String(dayVal) + '_' + item.LopID;
					var snap = that.dailySnapshots[snapshotKey] || ((that.selectedWeek && that.selectedWeek.startDate === '2026-10-05') ? that.dailySnapshots[legacyKey] : null);
					if (snap) {
						var sched = that.getScheduleForClass(item.LopID);
						var daySched = sched ? sched.find(function(s) { return s.key === dayVal; }) : null;
						var isTuQuan = (dayVal !== 2) && (snap.IsTuQuan !== undefined ? !!snap.IsTuQuan : (daySched ? !!daySched.IsTuQuan : false));
						if (item.TenLop === '06D' && dayVal === 5) {
							isTuQuan = true;
						}
						if (dayVal !== 2 && (snap.GhiChuViPham || (snap.TieuChiList && snap.TieuChiList.some(function(tc) { return tc.score === 1; })))) {
							isTuQuan = true;
						}
						return {
							LopID: item.LopID,
							TenLop: item.TenLop,
							TenGVCN: item.TenGVCN,
							IsTuQuan: isTuQuan,
							TieuChiList: JSON.parse(JSON.stringify(snap.TieuChiList)),
							GhiChuViPham: snap.GhiChuViPham || '',
							IsSaved: true,
							NguoiCham: snap.NguoiCham || 'Quản sinh khối'
						};
					}
					return that.createFreshClassItem(item, dateStr);
				});
			} else if (this.dailyWorkingState[dateStr] && this.dailyWorkingState[dateStr].length > 0) {
				// Priority 2: Nếu ngày này có working state (đang chấm dở hoặc đã thêm tiêu chí riêng trong phiên này)
				this.currentClasses = JSON.parse(JSON.stringify(this.dailyWorkingState[dateStr]));
			} else {
				// Priority 3: Khởi tạo mới từ baseCriteria (3 tiêu chí chuẩn) + tiêu chí riêng của chính ngày này nếu có
				this.currentClasses = list.map(function(item, idx) {
					return that.createFreshClassItem(item, dateStr, idx);
				});
			}

			if (hasAnySnapshot) {
				this.qsAutoSaveStatus = 'saved';
				if (!this.qsLastSavedTime) this.qsLastSavedTime = this.formatCurrentTime();
			} else {
				this.qsAutoSaveStatus = 'saved';
			}

			if (list.length > 0) {
				var currentSelected = list.find(function(c) {
					return String(c.LopID) === String(that.selectedGvcnClassId);
				});
				if (!currentSelected && that.allSchoolClasses) {
					currentSelected = that.allSchoolClasses.find(function(c) {
						return String(c.LopID) === String(that.selectedGvcnClassId);
					});
				}
				var target = currentSelected || list[0];
				that.selectedGvcnClassId = target.LopID;
				that.gvcnClassInfo.LopID = target.LopID;
				that.gvcnClassInfo.TenLop = target.TenLop;
				that.gvcnClassInfo.TenGVCN = target.TenGVCN;
				that.gvcnClassInfo.SiSo = target.SiSo;
				that.gvcnClassInfo.TrangThaiLop = that.isClassBlocked(target.LopID) ? 2 : 1;
				that.loadGvcnScheduleForClass(target.LopID);
				that.loadGvcnHistoryForClass(target.LopID);
			}
		},
		onGvcnClassChanged(newClassId) {
			if (!newClassId) return;
			this.selectedGvcnClassId = String(newClassId);
			var found = this.allSchoolClasses.find(function(c) {
				return String(c.LopID) === String(newClassId);
			});
			if (found) {
				this.gvcnClassInfo.LopID = found.LopID;
				this.gvcnClassInfo.TenLop = found.TenLop;
				this.gvcnClassInfo.TenGVCN = found.TenGVCN;
				this.gvcnClassInfo.SiSo = found.SiSo;
				this.gvcnClassInfo.TrangThaiLop = this.isClassBlocked(found.LopID) ? 2 : 1;
				if (found.Khoi && found.Khoi !== this.selectedKhoi) {
					this.selectedKhoi = found.Khoi;
					this.loadClassesForCurrentDay();
				}
			}
			this.loadGvcnScheduleForClass(this.selectedGvcnClassId);
			this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
			this.showNotice('Đã chuyển sang lớp ' + this.gvcnClassInfo.TenLop + ' (GVCN: ' + this.gvcnClassInfo.TenGVCN + ')', 'info');
		},
		loadGvcnScheduleForClass(lopId) {
			var sched = JSON.parse(JSON.stringify(this.getScheduleForClass(lopId)));
			sched.forEach(function(d) {
				if (d.GhiChu === undefined) d.GhiChu = '';
			});
			this.gvcnWeekSchedule = sched;
		},
		getGvcnNoteForDay(dayKey) {
			if (!this.gvcnWeekSchedule) return '';
			var found = this.gvcnWeekSchedule.find(function(d) { return d.key === dayKey; });
			return (found && found.GhiChu) ? found.GhiChu : '';
		},
		loadGvcnHistoryForClass(lopId) {
			var that = this;
			var dayLabels = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6'];
			var sched = this.gvcnWeekSchedule || this.getScheduleForClass(lopId) || [];
			var history = [];

			for (var i = 0; i < 5; i++) {
				var dayNum = i + 2;
				var sDay = sched[i] || { key: dayNum, date: '', IsTuQuan: false, CoMat: true };
				var dateStr = this.getDateStringForDay(dayNum);
				var isFuture = this.isSpecificDayInFuture(dayNum);

				if (dayNum === 2) {
					// Thứ 2: Sinh hoạt đầu tuần toàn trường (GVCN sinh hoạt - Không chấm điểm tự quản)
					history.push({
						Thu: 2,
						ThuLabel: 'Thứ 2',
						Ngay: sDay.date,
						IsTuQuan: false,
						TieuChiList: [],
						KetQua: 'GVCN',
						NoiDungViPham: '',
						NguoiCham: '—'
					});
					continue;
				}

				// Lấy dữ liệu đánh giá thực tế từ Quản sinh cho lớp này
				var snapKey = dateStr + '_' + lopId;
				var legacyKey = String(dayNum) + '_' + lopId;
				var classData = null;
				var isToday = this.isSpecificDayToday(dayNum);

				// Ưu tiên 1: Lấy từ currentClasses NẾU ngày này là HÔM NAY (isToday)
				if (isToday && that.currentClasses && that.currentClasses.length) {
					classData = that.currentClasses.find(function(c) { return String(c.LopID) === String(lopId); });
				}
				// Ưu tiên 2: Lấy từ snapshot đã lưu (CHỈ áp dụng cho ngày quá khứ hoặc hôm nay, KHÔNG áp dụng cho ngày tương lai)
				if (!classData && !isFuture) {
					if (that.dailySnapshots[snapKey]) {
						classData = that.dailySnapshots[snapKey];
					} else if (that.selectedWeek && that.selectedWeek.startDate === '2026-10-05' && that.dailySnapshots[legacyKey]) {
						classData = that.dailySnapshots[legacyKey];
					} else if (that.dailyWorkingState[dateStr]) {
						classData = that.dailyWorkingState[dateStr].find(function(c) { return String(c.LopID) === String(lopId); });
					}
				}

				// Xác định trạng thái tự quản hay GVCN sinh hoạt
				var isTuQuan = false;
				if (classData && classData.IsTuQuan !== undefined) {
					isTuQuan = !!classData.IsTuQuan;
				} else if (sDay) {
					isTuQuan = !!sDay.IsTuQuan;
				}

				// Trường hợp đặc biệt 06D vào Thứ 5 Tuần 1 (08/10/2026) vi phạm
				if (String(lopId) === '2722' && dateStr === '2026-10-08') {
					isTuQuan = true;
				}

				if (!isTuQuan) {
					// GVCN sinh hoạt
					history.push({
						Thu: dayNum,
						ThuLabel: dayLabels[i],
						Ngay: sDay.date,
						IsTuQuan: false,
						TieuChiList: isFuture ? [] : [
							{ ten: 'Không gian lớp (Mở cửa, VS, bàn ghế)', score: 3 },
							{ ten: 'Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)', score: 3 },
							{ ten: 'Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)', score: 3 }
						],
						KetQua: 'GVCN',
						NoiDungViPham: '',
						NguoiCham: '—'
					});
				} else if (isFuture || !classData || (!classData.IsSaved && (!classData.TieuChiList || !classData.TieuChiList.length))) {
					// Lớp tự quản nhưng Quản sinh CHƯA CHẤM (hoặc ngày chưa đến trong tương lai)
					history.push({
						Thu: dayNum,
						ThuLabel: dayLabels[i],
						Ngay: sDay.date,
						IsTuQuan: true,
						TieuChiList: [],
						KetQua: 'CHUA_CHAM',
						NoiDungViPham: '',
						NguoiCham: isFuture ? '—' : 'Chưa chấm'
					});
				} else {
					// Quản sinh ĐÃ CHẤM: Đọc trực tiếp tiêu chí, xếp loại và ghi chú từ Quản sinh
					var tcs = classData.TieuChiList || [];
					var cdCount = tcs.filter(function(tc) { return tc.score === 1; }).length;
					var totCount = tcs.filter(function(tc) { return tc.score === 3; }).length;
					var ghiChu = classData.GhiChuViPham || '';

					var ketQua = 'T';
					if (cdCount >= 2 || (cdCount >= 1 && ghiChu)) {
						ketQua = 'CD';
					} else if (cdCount === 1 || totCount < 2) {
						ketQua = 'D';
					} else {
						ketQua = 'T';
					}

					history.push({
						Thu: dayNum,
						ThuLabel: dayLabels[i],
						Ngay: sDay.date,
						IsTuQuan: true,
						TieuChiList: JSON.parse(JSON.stringify(tcs)),
						KetQua: ketQua,
						NoiDungViPham: ghiChu,
						NguoiCham: classData.NguoiCham || 'QS. Trần Tuấn'
					});
				}
			}
			this.gvcnClassHistory = history;
		},
		openAddCriteriaDialog(targetClass) {
			if (this.isReadOnlyDay) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể thêm tiêu chí.' : 'Chưa đến ngày đánh giá! Không thể thêm tiêu chí cho ngày trong tương lai.';
				this.showNotice(msg, 'warning');
				return;
			}
			this.criteriaDialog.targetClass = targetClass;
			this.criteriaDialog.ten = '';
			this.criteriaDialog.shortTitle = '';
			if (targetClass) {
				this.criteriaDialog.scope = 'class';
				this.criteriaDialog.selectedClassId = targetClass.LopID;
			} else {
				this.criteriaDialog.scope = 'all';
				this.criteriaDialog.selectedClassId = (this.currentClasses.length > 0) ? this.currentClasses[0].LopID : null;
			}
			this.criteriaDialog.show = true;
		},
		selectSuggestedCriteria(sug) {
			if (!sug) return;
			this.criteriaDialog.ten = sug.ten;
			this.criteriaDialog.shortTitle = sug.ten;
		},
		confirmAddCriteria() {
			if (this.isReadOnlyDay) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể thêm tiêu chí.' : 'Chưa đến ngày đánh giá!';
				this.showNotice(msg, 'warning');
				return;
			}
			var ten = this.criteriaDialog.ten ? this.criteriaDialog.ten.trim() : '';
			if (!ten) return;

			var newId = 'tc_' + Date.now();
			var scope = this.criteriaDialog.scope;
			var shortTitle = ten;
			var dateStr = this.getDateStringForDay(this.selectedDay);

			if (!this.dailyCustomCriteria[dateStr]) {
				this.dailyCustomCriteria[dateStr] = { global: [], byClass: {} };
			}

			if (scope === 'all') {
				// Thêm chung cho tất cả các lớp trong ngày này
				var newCrit = { id: newId, ten: ten, shortTitle: shortTitle, isCustom: true, scope: 'all', date: dateStr };
				this.dailyCustomCriteria[dateStr].global.push(newCrit);
				this.currentClasses.forEach(function(item) {
					item.TieuChiList.push({ id: newId, ten: ten, shortTitle: shortTitle, score: 3, isCustom: true, scope: 'all', date: dateStr });
				});
				this.showNotice('Đã thêm tiêu chí "' + ten + '" cho ' + this.currentDayLabel + '!', 'success');
			} else {
				// Thêm riêng cho lớp được chọn từ dropdown trong ngày này
				var targetId = this.criteriaDialog.selectedClassId;
				var target = this.currentClasses.find(function(c) {
					return c.LopID === targetId;
				});
				if (target) {
					if (!this.dailyCustomCriteria[dateStr].byClass[target.LopID]) {
						this.dailyCustomCriteria[dateStr].byClass[target.LopID] = [];
					}
					var newCrit = { id: newId, ten: ten, shortTitle: shortTitle, isCustom: true, scope: 'class', lopId: target.LopID, tenLop: target.TenLop, date: dateStr };
					this.dailyCustomCriteria[dateStr].byClass[target.LopID].push(newCrit);
					target.TieuChiList.push({ id: newId, ten: ten, shortTitle: shortTitle, score: 3, isCustom: true, scope: 'class', lopId: target.LopID, tenLop: target.TenLop, date: dateStr });
					this.showNotice('Đã thêm tiêu chí "' + ten + '" riêng cho Lớp ' + target.TenLop + ' (' + this.currentDayLabel + ')!', 'success');
				} else {
					this.showNotice('Vui lòng chọn lớp áp dụng tiêu chí!', 'warning');
					return;
				}
			}

			// Lưu lại working state của ngày này và kích hoạt phản ứng giao diện
			this.saveWorkingStateForDate(dateStr);
			this.currentClasses = [...this.currentClasses];
			this.criteriaDialog.show = false;
			this.criteriaDialog.ten = '';
			this.criteriaDialog.shortTitle = '';
			this.autoSaveDailyEvaluation(300);
		},
		removeCustomCriterion(tc) {
			if (this.isReadOnlyDay) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể xóa tiêu chí.' : 'Chưa đến ngày đánh giá!';
				this.showNotice(msg, 'warning');
				return;
			}
			if (!tc || !tc.isCustom) return;
			var id = tc.id;
			var title = tc.shortTitle || tc.ten;
			var dateStr = this.getDateStringForDay(this.selectedDay);

			// 1. Chỉ xóa trong dailyCustomCriteria của ngày hiện tại
			if (this.dailyCustomCriteria[dateStr]) {
				if (this.dailyCustomCriteria[dateStr].global) {
					this.dailyCustomCriteria[dateStr].global = this.dailyCustomCriteria[dateStr].global.filter(function(x) { return x.id !== id; });
				}
				for (var k in this.dailyCustomCriteria[dateStr].byClass) {
					if (this.dailyCustomCriteria[dateStr].byClass[k]) {
						this.dailyCustomCriteria[dateStr].byClass[k] = this.dailyCustomCriteria[dateStr].byClass[k].filter(function(x) { return x.id !== id; });
					}
				}
			}

			// 2. Chỉ xóa khỏi currentClasses của ngày hiện tại
			this.currentClasses.forEach(function(cls) {
				if (cls.TieuChiList) {
					cls.TieuChiList = cls.TieuChiList.filter(function(x) { return x.id !== id; });
				}
			});

			// 3. Cập nhật working state của ngày hiện tại
			this.saveWorkingStateForDate(dateStr);

			// TUYỆT ĐỐI KHÔNG XÓA KHỎI dailySnapshots CỦA CÁC NGÀY KHÁC! Lịch sử đánh giá của các ngày trước được bảo toàn 100%!
			this.currentClasses = [...this.currentClasses];
			this.autoSaveDailyEvaluation(300);
			this.showNotice('Đã xóa tiêu chí "' + title + '" của ' + this.currentDayLabel + '!', 'info');
		},
		removeCriteria(classItem, tcId) {
			if (this.isReadOnlyDay) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể xóa tiêu chí.' : 'Chưa đến ngày đánh giá!';
				this.showNotice(msg, 'warning');
				return;
			}
			var tc = null;
			if (classItem && classItem.TieuChiList) {
				tc = classItem.TieuChiList.find(function(x) { return x.id === tcId; });
			}
			if (tc && tc.isCustom) {
				this.removeCustomCriterion(tc);
			} else {
				if (classItem && classItem.TieuChiList) {
					classItem.TieuChiList = classItem.TieuChiList.filter(function(x) { return x.id !== tcId; });
				}
				this.currentClasses = [...this.currentClasses];
				this.showNotice('Đã xóa tiêu chí đánh giá!', 'info');
			}
		},
		getExistingCustomCriteria() {
			var all = this.getMergedPrintCriteria();
			return all.filter(function(tc) { return tc.isCustom; });
		},
		isClassBlocked(lopId) {
			if (!lopId) return false;
			var idStr = String(lopId);
			if (this.penaltyOverrides && this.penaltyOverrides[idStr] !== undefined) {
				return !!this.penaltyOverrides[idStr];
			}
			var found = this.weeklyBlockedClasses ? this.weeklyBlockedClasses.find(function(b) {
				return String(b.LopID) === idStr;
			}) : null;
			return found ? !!found.IsApplied : false;
		},
		getClassDailyResult(item, dayVal) {
			var dVal = (dayVal !== undefined) ? dayVal : (this.activeTab === 'baocao' && this.bghViewMode === 'day' ? this.bghActiveDay : this.selectedDay);
			if (!item) return { code: 'GVCN', text: '—', color: 'blue-grey' };
			// Thứ Hai (ngày 2), hoặc lớp không tự quản (GVCN sinh hoạt):
			if (dVal === 2 || !item.IsTuQuan) {
				return { code: 'GVCN', text: '—', color: 'blue-grey', label: 'Không tính tự quản' };
			}
			if (!item.TieuChiList || !item.TieuChiList.length) {
				return { code: 'T', text: 'Tốt', color: 'success' };
			}
			var cdCount = item.TieuChiList.filter(function(tc) { return tc.score === 1; }).length;
			var totCount = item.TieuChiList.filter(function(tc) { return tc.score === 3; }).length;
			var datCount = item.TieuChiList.filter(function(tc) { return tc.score === 2; }).length;

			// Chưa đạt (CĐ): Có từ 2 tiêu chí CĐ trở lên vào ngày Tự quản (hoặc 1 CĐ kèm ghi chú vi phạm cụ thể)
			if (cdCount >= 2 || (cdCount >= 1 && item.GhiChuViPham && item.GhiChuViPham.trim())) {
				return { code: 'CD', text: 'Chưa đạt', color: 'error' };
			}
			// Tốt (T): Cả 3 tiêu chí Tốt (hoặc 2 Tốt + 1 Đạt, 0 CĐ) vào ngày Tự quản
			if (cdCount === 0 && (totCount === item.TieuChiList.length || (totCount >= 2 && datCount === 1))) {
				return { code: 'T', text: 'Tốt', color: 'success' };
			}
			// Đạt (Đ): Có 2–3 tiêu chí từ Đạt trở lên, tối đa 1 CĐ vào ngày Tự quản
			return { code: 'D', text: 'Đạt', color: 'primary' };
		},
		itemHasViolation(item, dayVal) {
			var dVal = (dayVal !== undefined) ? dayVal : (this.activeTab === 'baocao' && this.bghViewMode === 'day' ? this.bghActiveDay : this.selectedDay);
			if (!item || dVal === 2 || !item.IsTuQuan) return false;
			var res = this.getClassDailyResult(item, dVal);
			return res.code === 'CD';
		},
		openRewardEvidenceDialog(item) {
			if (!item) {
				this.openKhoiEvidenceDialog();
				return;
			}
			var found = this.monthlyClassRecords.find(function(r) { return String(r.LopID) === String(item.LopID); });
			this.evidenceDialog.classItem = found || item;
			this.evidenceDialog.selectedClassId = (found || item).LopID;
			this.evidenceDialog.viewMode = 'class';
			this.evidenceDialog.selectedWeekNum = (this.selectedWeek && this.selectedWeek.weekNum) ? this.selectedWeek.weekNum : 1;
			this.evidenceDialog.show = true;
		},
		openKhoiEvidenceDialog() {
			if (this.monthlyClassRecords && this.monthlyClassRecords.length > 0) {
				this.evidenceDialog.classItem = this.monthlyClassRecords[0];
				this.evidenceDialog.selectedClassId = this.monthlyClassRecords[0].LopID;
			}
			this.evidenceDialog.viewMode = 'khoi';
			this.evidenceDialog.selectedWeekNum = (this.selectedWeek && this.selectedWeek.weekNum) ? this.selectedWeek.weekNum : 1;
			this.evidenceDialog.show = true;
		},
		onEvidenceClassChange(newClassId) {
			var found = this.monthlyClassRecords.find(function(r) { return String(r.LopID) === String(newClassId); });
			if (found) {
				this.evidenceDialog.classItem = found;
			}
		},
		printRewardEvidence() {
			var cls = this.evidenceDialog.classItem;
			if (!cls) return;
			var html = '<!DOCTYPE html><html><head><meta charset="utf-8">';
			html += '<title>Báo cáo nề nếp 4 tuần - Lớp ' + cls.TenLop + '</title>';
			html += '<style>';
			html += '@page { size: A4 portrait; margin: 15mm; }';
			html += 'body { font-family: "Times New Roman", Times, serif; font-size: 11pt; color: #000; margin: 0; padding: 10px; line-height: 1.35; }';
			html += 'h2, h3 { margin: 2px 0; text-align: center; }';
			html += 'table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 10.5pt; }';
			html += 'th, td { border: 1px solid #333; padding: 6px 8px; text-align: left; }';
			html += 'th { background-color: #f2f2f2; text-align: center; }';
			html += '.text-center { text-align: center; }';
			html += '</style></head><body>';
			html += '<div style="text-align: center; text-transform: uppercase; font-weight: bold; font-size: 11pt;">TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG</div>';
			html += '<div style="text-align: center; font-size: 10pt; color: #555; margin-bottom: 8px;">HỆ THỐNG QUẢN LÝ NỀ NẾP & THI ĐUA HỌC ĐƯỜNG</div>';
			html += '<h2 style="font-size: 13.5pt; margin-top: 6px; text-transform: uppercase;">CHI TIẾT ĐỐI SOÁT NỀ NẾP 4 TUẦN THI ĐUA</h2>';
			html += '<div style="text-align: center; font-size: 11pt; font-style: italic; margin-bottom: 12px;">Tháng ' + this.currentEvaluationMonth + '/2026 (' + this.monthCycleDateRange + ')</div>';
			html += '<div style="margin-bottom: 10px; font-size: 11pt;">';
			html += '<strong>Lớp:</strong> ' + cls.TenLop + ' (' + (cls.TenKhoi || 'Khối 6') + ') &nbsp;&nbsp;|&nbsp;&nbsp; <strong>GVCN:</strong> ' + cls.TenGVCN + ' &nbsp;&nbsp;|&nbsp;&nbsp; <strong>Sĩ số:</strong> ' + (cls.SiSo || 36) + ' HS<br>';
			html += '<strong>Tiến độ tháng:</strong> Đạt ' + cls.SoTuanTot + '/4 tuần Tốt &nbsp;&nbsp;|&nbsp;&nbsp; <strong>Điểm thi đua:</strong> ' + (cls.DiemThiDua || '0 điểm') + ' &nbsp;&nbsp;|&nbsp;&nbsp; <strong>Tiến độ:</strong> ' + (cls.XepLoaiThang || 'Đang theo dõi');
			html += '</div>';
			html += '<table><thead><tr>';
			html += '<th style="width: 55px;">Tuần</th><th style="width: 90px;">Thời gian</th><th style="width: 55px;">Thứ 2</th><th style="width: 55px;">Thứ 3</th><th style="width: 55px;">Thứ 4</th><th style="width: 55px;">Thứ 5</th><th style="width: 55px;">Thứ 6</th><th style="width: 85px;">Kết quả tuần</th><th>Ghi chú vi phạm trong tuần</th><th style="width: 75px;">Trạng thái</th>';
			html += '</tr></thead><tbody>';
			(cls.weeks || []).forEach(function(w) {
				html += '<tr>';
				html += '<td class="text-center"><strong>' + w.label + '</strong></td>';
				html += '<td class="text-center" style="font-size: 9.5pt;">' + w.dates + '/2026</td>';
				(w.days || []).forEach(function(d) {
					if (d.tcText === '—' && d.rankText === '—') {
						html += '<td class="text-center" style="color: #888;">—</td>';
					} else if (d.rankCode === 'CHETAI') {
						html += '<td class="text-center"><span style="color:#c62828; font-size: 8.5pt; font-weight:bold;">Chế tài</span></td>';
					} else {
						var color = (d.rankCode === 'T' ? '#2e7d32' : (d.rankCode === 'D' ? '#1565c0' : '#c62828'));
						html += '<td class="text-center" style="font-size: 8.5pt; padding: 4px 2px;"><strong style="letter-spacing: 0.5px;">' + d.tcText + '</strong><br><strong style="color:' + color + ';">' + d.rankText + '</strong></td>';
					}
				});
				var detailStr = w.detail ? ('<br><small style="color:#666;">' + w.detail + '</small>') : '';
				html += '<td class="text-center"><strong>' + w.text + '</strong>' + detailStr + '</td>';
				html += '<td style="font-size: 9.5pt;' + (w.note && w.note !== '—' ? ' color: #c62828; font-weight: bold;' : ' color: #666;') + '">' + (w.note || '—') + '</td>';
				var danhGiaCol = '';
				if (w.status === 'T') danhGiaCol = '<strong style="color:#2e7d32;">Đạt Tốt</strong>';
				else if (w.status === 'D') danhGiaCol = '<span style="color:#1565c0;">Đạt</span>';
				else if (w.status === 'CD') danhGiaCol = '<strong style="color:#c62828;">Chưa đạt</strong>';
				else if (w.status === 'CHETAI') danhGiaCol = '<strong style="color:#c62828;">Chế tài TQ</strong>';
				else if (w.status === 'CURRENT') danhGiaCol = '<span style="color:#0284c7;">Đang diễn ra</span>';
				else danhGiaCol = '<span style="color:#888;">— (Chưa tới)</span>';
				html += '<td class="text-center">' + danhGiaCol + '</td>';
				html += '</tr>';
			});
			html += '</tbody></table>';
			html += '<div style="margin-top: 14px; padding: 10px; border: 1px solid #ccc; background-color: #fafafa; font-size: 10.5pt;">';
			html += '<strong>Tiến độ đánh giá:</strong> ';
			if (this.currentEvaluationMonth === 9) {
				if (cls.IsRewardEligible) {
					html += 'Lớp hoàn thành xuất sắc 4/4 tuần Tốt trong Tháng 9/2026. Đạt danh hiệu "Lớp tự quản tốt" và cộng ' + cls.DiemThiDua + '.';
				} else if (cls.IsEffortReward) {
					html += 'Lớp hoàn thành tốt 3/4 tuần Tốt trong Tháng 9/2026. Tuyên dương danh hiệu "Biểu dương nỗ lực nề nếp" và cộng ' + cls.DiemThiDua + '.';
				} else {
					html += 'Lớp hoàn thành chu kỳ thi đua nề nếp Tháng 9/2026.';
				}
			} else {
				if (cls.IsLeading) {
					html += 'Lớp hoàn thành xuất sắc Tuần 1 Tốt (0 lỗi vi phạm) và đang dẫn đầu thi đua tháng 10. Tuần 2 đang theo dõi, Tuần 3-4 chưa diễn ra. Danh hiệu và điểm cộng (' + cls.DiemThiDua + ') sẽ được xét duyệt chính thức sau ngày 01/11/2026 khi kết thúc chu kỳ 4 tuần.';
				} else if (cls.IsRewardEligible) {
					html += 'Lớp hoàn thành xuất sắc 4/4 tuần Tốt. Đề xuất cộng ' + cls.DiemThiDua + ' và trao danh hiệu "Lớp tự quản tốt".';
				} else if (cls.SoTuanCD > 0) {
					html += 'Lớp có ' + cls.SoTuanCD + ' tuần Chưa đạt (Tuần 1 ghi nhận vi phạm nề nếp). Đã áp dụng chế tài: Tạm dừng tự quản Tuần 2 (GVCN trực tiếp sinh hoạt 5/5 ngày để chấn chỉnh nề nếp).';
				} else {
					html += 'Lớp hoàn thành nhiệm vụ nề nếp Tuần 1 Đạt. Tuần 2 đang theo dõi, Tuần 3 và 4 chưa diễn ra.';
				}
			}
			html += '</div>';
			html += '<div style="margin-top: 35px; display: flex; justify-content: space-between; text-align: center;">';
			html += '<div style="width: 45%;"><strong>QUẢN SINH KHỐI</strong><br><i>(Kí và ghi rõ họ tên)</i></div>';
			html += '<div style="width: 45%;"><strong>BAN GIÁM HIỆU DUYỆT</strong><br><i>(Kí và ghi rõ họ tên)</i></div>';
			html += '</div>';
			html += '</body></html>';

			var printWin = null;
			try { printWin = window.open('', '_blank'); } catch (e) { printWin = null; }
			if (printWin && printWin.document) {
				printWin.document.open();
				printWin.document.write(html);
				printWin.document.close();
				setTimeout(function() {
					try { printWin.focus(); printWin.print(); } catch (err) { console.error(err); }
				}, 400);
			} else {
				var iframe = document.getElementById('tu-quan-print-iframe');
				if (!iframe) {
					iframe = document.createElement('iframe');
					iframe.id = 'tu-quan-print-iframe';
					iframe.style.position = 'fixed';
					iframe.style.right = '0';
					iframe.style.bottom = '0';
					iframe.style.width = '0';
					iframe.style.height = '0';
					iframe.style.border = 'none';
					document.body.appendChild(iframe);
				}
				var doc = iframe.contentWindow.document;
				doc.open();
				doc.write(html);
				doc.close();
				setTimeout(function() {
					try { iframe.contentWindow.focus(); iframe.contentWindow.print(); } catch (err) { console.error(err); }
				}, 400);
			}
		},
		printKhoiEvidence() {
			var k = this.selectedKhoi || 6;
			var weekNum = this.evidenceDialog.selectedWeekNum || 1;
			var weekLabel = 'Tuần ' + weekNum;
			var curWeekObj = (this.monthEvaluationWeeks || []).find(function(x) { return x.weekNum === weekNum; });
			var weekDates = curWeekObj ? curWeekObj.dates : (weekNum === 1 ? '05/10 - 11/10' : '');
			var list = this.monthlyClassRecords;

			var html = '<!DOCTYPE html><html><head><meta charset="utf-8">';
			html += '<title>Báo cáo nề nếp chi tiết Khối ' + k + ' - ' + weekLabel + '</title>';
			html += '<style>';
			html += '@page { size: A4 landscape; margin: 12mm; }';
			html += 'body { font-family: "Times New Roman", Times, serif; font-size: 10pt; color: #000; margin: 0; padding: 5px; line-height: 1.3; }';
			html += 'table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 9.5pt; }';
			html += 'th, td { border: 1px solid #333; padding: 5px 6px; text-align: left; }';
			html += 'th { background-color: #f2f2f2; text-align: center; }';
			html += '.text-center { text-align: center; }';
			html += '</style></head><body>';
			html += '<div style="text-align: center; text-transform: uppercase; font-weight: bold; font-size: 11pt;">TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG</div>';
			html += '<div style="text-align: center; font-size: 9.5pt; color: #555; margin-bottom: 6px;">HỆ THỐNG QUẢN LÝ NỀ NẾP & THI ĐUA HỌC ĐƯỜNG</div>';
			html += '<h2 style="font-size: 13pt; margin: 4px 0; text-align: center; text-transform: uppercase;">CHI TIẾT ĐỐI SOÁT NỀ NẾP TOÀN KHỐI ' + k + ' — ' + weekLabel.toUpperCase() + '</h2>';
			var weekDays = this.getKhoiDetailWeekDays(weekNum);
			html += '<table><thead><tr>';
			html += '<th style="width: 35px;">STT</th><th style="width: 60px;">Lớp</th><th style="width: 140px;">GVCN</th>';
			weekDays.forEach(function(d) {
				html += '<th style="width: 55px; text-align: center;"><div>' + d.label + '</div><div style="font-size: 8pt; font-weight: normal; color: #555;">(' + d.date + ')</div></th>';
			});
			html += '<th style="width: 85px;">Kết quả tuần</th><th>Ghi chú vi phạm trong tuần</th><th style="width: 75px;">Trạng thái</th>';
			html += '</tr></thead><tbody>';

			list.forEach(function(row, idx) {
				var w = (row.weeks && row.weeks.find(function(x) { return x.weekNum === weekNum; })) || row.w1;
				html += '<tr>';
				html += '<td class="text-center">' + (idx + 1) + '</td>';
				html += '<td class="text-center"><strong>' + row.TenLop + '</strong></td>';
				html += '<td>' + row.TenGVCN + '</td>';
				(w.days || []).forEach(function(d) {
					if (d.tcText === '—' && d.rankText === '—') {
						html += '<td class="text-center" style="color: #888;">—</td>';
					} else if (d.rankCode === 'CHETAI') {
						html += '<td class="text-center"><span style="color:#c62828; font-size: 8pt; font-weight:bold;">Chế tài</span></td>';
					} else {
						var color = (d.rankCode === 'T' ? '#2e7d32' : (d.rankCode === 'D' ? '#1565c0' : '#c62828'));
						html += '<td class="text-center" style="font-size: 8pt; padding: 3px 1px;"><strong style="letter-spacing: 0.5px;">' + d.tcText + '</strong><br><strong style="color:' + color + ';">' + d.rankText + '</strong></td>';
					}
				});
				var detailStr = w.detail ? ('<br><small style="color:#666;">' + w.detail + '</small>') : '';
				html += '<td class="text-center"><strong>' + w.text + '</strong>' + detailStr + '</td>';
				html += '<td style="font-size: 9pt;' + (w.note && w.note !== '—' ? ' color: #c62828; font-weight: bold;' : ' color: #666;') + '">' + (w.note || '—') + '</td>';
				var danhGiaCol = '';
				if (w.status === 'T') danhGiaCol = '<strong style="color:#2e7d32;">Đạt Tốt</strong>';
				else if (w.status === 'D') danhGiaCol = '<span style="color:#1565c0;">Đạt</span>';
				else if (w.status === 'CD') danhGiaCol = '<strong style="color:#c62828;">Chưa đạt</strong>';
				else if (w.status === 'CHETAI') danhGiaCol = '<strong style="color:#c62828;">Chế tài TQ</strong>';
				else if (w.status === 'CURRENT') danhGiaCol = '<span style="color:#0284c7;">Đang diễn ra</span>';
				else danhGiaCol = '<span style="color:#888;">— (Chưa tới)</span>';
				html += '<td class="text-center">' + danhGiaCol + '</td>';
				html += '</tr>';
			});
			html += '</tbody></table>';

			html += '<div style="margin-top: 30px; display: flex; justify-content: space-between; text-align: center;">';
			html += '<div style="width: 45%;"><strong>QUẢN SINH KHỐI</strong><br><i>(Kí và ghi rõ họ tên)</i></div>';
			html += '<div style="width: 45%;"><strong>BAN GIÁM HIỆU DUYỆT</strong><br><i>(Kí và ghi rõ họ tên)</i></div>';
			html += '</div>';
			html += '</body></html>';

			var printWin = null;
			try { printWin = window.open('', '_blank'); } catch (e) { printWin = null; }
			if (printWin && printWin.document) {
				printWin.document.open();
				printWin.document.write(html);
				printWin.document.close();
				setTimeout(function() {
					try { printWin.focus(); printWin.print(); } catch (err) { console.error(err); }
				}, 400);
			}
		},
		printOuterKhoiEvidence() {
			this.evidenceDialog.selectedWeekNum = this.outerMonthlySelectedWeekNum || 1;
			this.printKhoiEvidence();
		},
		getKhoiDetailWeekDays(weekNum) {
			var w = weekNum || 1;
			var m = this.currentEvaluationMonth;
			var startDates = (m === 9) ? {
				1: '2026-09-07', 2: '2026-09-14', 3: '2026-09-21', 4: '2026-09-28'
			} : {
				1: '2026-10-05', 2: '2026-10-12', 3: '2026-10-19', 4: '2026-10-26'
			};
			var startStr = startDates[w] || (m === 9 ? '2026-09-07' : '2026-10-05');
			var p = startStr.split('-');
			var d = new Date(parseInt(p[0], 10), parseInt(p[1], 10) - 1, parseInt(p[2], 10));
			var labels = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6'];
			var res = [];
			for (var i = 0; i < 5; i++) {
				var cur = new Date(d.getTime());
				cur.setDate(d.getDate() + i);
				var dayStr = (cur.getDate() < 10 ? '0' : '') + cur.getDate();
				var monthStr = ((cur.getMonth() + 1) < 10 ? '0' : '') + (cur.getMonth() + 1);
				res.push({
					dayVal: i + 2,
					label: labels[i],
					date: dayStr + '/' + monthStr
				});
			}
			return res;
		},
		getViolatedCriteria(item) {
			if (!item || !item.TieuChiList || !item.IsTuQuan) return [];
			return item.TieuChiList.filter(function(tc) {
				return tc.score === 1;
			});
		},
		getViolatedCriteriaSummary(item) {
			if (!item) return '';
			if (item.GhiChuViPham && item.GhiChuViPham.trim()) return item.GhiChuViPham;
			var tcs = this.getViolatedCriteria(item);
			if (tcs && tcs.length) {
				var that = this;
				var items = tcs.map(function(tc, idx) { return that.formatCriterionItem(tc, idx).badgeText; });
				return 'Chưa đạt: ' + items.join('; ');
			}
			return 'Vi phạm tiêu chí nề nếp đầu giờ';
		},
		formatCriterionItem(tc, idx) {
			if (!tc) return { code: 'TC', name: '', fullName: '', badgeText: '' };
			var rawName = tc.ten || (typeof tc === 'string' ? tc : '');
			var fullName = this.getCriterionFullName(rawName);
			var mainTitle = this.getCriterionMainTitle(rawName);
			var code = '';
			var tId = tc.id || '';

			if (tId === 'c1' || rawName.indexOf('1.') === 0 || rawName.toLowerCase().indexOf('không gian') !== -1) {
				code = 'TC1';
			} else if (tId === 'c2' || rawName.indexOf('2.') === 0 || rawName.toLowerCase().indexOf('nền nếp') !== -1 || rawName.toLowerCase().indexOf('nề nếp') !== -1) {
				code = 'TC2';
			} else if (tId === 'c3' || rawName.indexOf('3.') === 0 || rawName.toLowerCase().indexOf('chủ đề') !== -1) {
				code = 'TC3';
			} else if (tc.isCustom) {
				code = tc.scope === 'class' ? 'TC riêng' : 'TC bổ sung';
			} else {
				code = 'TC' + (idx !== undefined ? (idx + 1) : '');
			}

			var cleanName = mainTitle.replace(/^[0-9]+\.\s*/, '').trim();
			return {
				code: code,
				name: cleanName,
				fullName: fullName,
				badgeText: '[' + code + ': ' + cleanName + ']'
			};
		},
		getViolatedCriteriaList(item) {
			if (!item) return [];
			var tcs = item.TieuChiList || [];
			var violated = tcs.filter(function(tc) {
				return tc.score === 1;
			});
			var that = this;
			return violated.map(function(tc, idx) {
				return that.formatCriterionItem(tc, idx);
			});
		},
		getClassBorderClass(item) {
			if (this.itemHasViolation(item)) return 'border-error';
			return 'border-default';
		},
		getScoreBadgeColor(item) {
			return this.getClassDailyResult(item).color;
		},
		getScoreBadgeText(item) {
			return this.getClassDailyResult(item).text;
		},
		formatCriterionText(val) {
			if (val === 3) return 'Tốt';
			if (val === 2) return 'Đạt';
			if (val === 1) return 'Cần cố gắng';
			return '—';
		},
		markAllGood() {
			if (this.isReadOnlyDay) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã được khóa lưu trữ lịch sử, không thể chỉnh sửa.' : 'Chưa đến ngày đánh giá! Không thể chấm điểm cho ngày trong tương lai.';
				this.showNotice(msg, 'warning');
				return;
			}
			this.currentClasses.forEach(function(item) {
				if (item.TieuChiList) {
					item.TieuChiList.forEach(function(tc) {
						tc.score = 3;
					});
				}
				item.GhiChuViPham = '';
			});
			this.evalUpdateVersion++;
			this.showNotice('Đã đặt tất cả tiêu chí của các lớp thành TỐT!', 'info');
			this.autoSaveDailyEvaluation(150);
		},
		saveDailyEvaluation() {
			if (this.isReadOnlyDay) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã được khóa lưu trữ lịch sử, không thể lưu đè.' : 'Chưa đến ngày đánh giá! Không thể lưu kết quả cho ngày trong tương lai.';
				this.showNotice(msg, 'warning');
				return;
			}
			this.isSaving = true;
			this.qsAutoSaveStatus = 'saving';
			var that = this;
			var dayVal = this.selectedDay;
			var dateStr = this.getDateStringForDay(dayVal);

			setTimeout(function() {
				that.isSaving = false;
				// Lưu snapshot cho toàn bộ các lớp vào ngày hiện tại
				that.currentClasses.forEach(function(c) {
					c.IsSaved = true;
					var snapshotKey = dateStr + '_' + c.LopID;
					that.dailySnapshots[snapshotKey] = {
						TieuChiList: JSON.parse(JSON.stringify(c.TieuChiList)),
						GhiChuViPham: c.GhiChuViPham,
						IsTuQuan: c.IsTuQuan,
						IsSaved: true,
						NguoiCham: c.NguoiCham || 'Quản sinh khối'
					};
				});
				if (that.dailyWorkingState[dateStr]) {
					delete that.dailyWorkingState[dateStr];
				}
				that.dailySnapshots = Object.assign({}, that.dailySnapshots);
				that.evalUpdateVersion++;
				that.saveSnapshotsToLocalStorage();
				that.qsLastSavedTime = that.formatCurrentTime();
				that.qsAutoSaveStatus = 'saved';
				if (that.selectedGvcnClassId) {
					that.loadGvcnHistoryForClass(that.selectedGvcnClassId);
				}
				that.showNotice('Đã lưu kết quả đánh giá ngày ' + that.currentDayLabel + ' thành công!', 'success');
			}, 300);
		},
		toggleGvcnDay(day) {
			if (day.key === 2) {
				this.showNotice('Thứ Hai là ngày sinh hoạt đầu tuần cùng GVCN, quy định không áp dụng tự quản!', 'info');
				return;
			}
			if (this.isPastSelectedWeek || this.isSpecificDayInPast(day.key)) {
				this.showNotice('Tuần này hoặc ngày này đã qua! Dữ liệu đã được khóa lưu trữ lịch sử, không thể chỉnh sửa.', 'warning');
				return;
			}
			if (this.isSpecificDayToday(day.key) && this.isPastGvcnCutoffTime()) {
				this.showNotice('Đã quá 06:00 sáng hôm nay (' + day.label + ')! Không thể đăng ký hoặc thay đổi lịch theo quy định của nhà trường.', 'warning');
				return;
			}
			if (this.gvcnClassInfo.TrangThaiLop === 2 || this.isClassBlocked(this.selectedGvcnClassId)) {
				this.showNotice('Lớp ' + this.gvcnClassInfo.TenLop + ' đang chấp hành chế tài tạm dừng tự quản, bắt buộc GVCN sinh hoạt và quản lý nề nếp 5/5 buổi!', 'warning');
				return;
			}
			day.IsTuQuan = !day.IsTuQuan;
			day.CoMat = !day.IsTuQuan;
			this.autoSaveGvcnSchedule();
			this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
			this.showNotice('Đã tự động lưu ' + day.label + ' (' + (day.IsTuQuan ? 'Lớp tự quản' : 'GVCN sinh hoạt') + ')', 'success');
		},
		saveGvcnSchedule() {
			if (this.gvcnClassInfo && this.gvcnClassInfo.TrangThaiLop === 2 && this.gvcnTuQuanCount > 0) {
				this.showNotice('Không thể lưu! Lớp đang bị tạm dừng tự quản (bị xếp loại CĐ tuần trước), bắt buộc GVCN phải có mặt đủ 5/5 buổi trực tiếp.', 'error');
				return;
			}
			if (this.gvcnTuQuanCount < 2) {
				this.showNotice('Chưa đủ chỉ tiêu! Quy định mới (08/10) yêu cầu GVCN đăng kí cho lớp tự quản tối thiểu 02 buổi/tuần (từ Thứ 3 đến Thứ 6). Vui lòng chọn thêm trước khi lưu!', 'error');
				return;
			}
			this.isSaving = true;
			var that = this;
			setTimeout(function() {
				that.autoSaveGvcnSchedule();
				that.isSaving = false;
				that.showNotice('Đã lưu thành công đăng kí tự quản tuần này cho lớp ' + that.gvcnClassInfo.TenLop + ' (' + that.gvcnTuQuanCount + ' ngày tự quản)!', 'success');
			}, 200);
		},
		exportDailyReport() {
			var isBgh = (this.activeTab === 'baocao');
			var dayLabel = isBgh ? this.bghActiveDayLabel : this.currentDayLabel;
			var dayVal = isBgh ? this.bghActiveDay : this.selectedDay;
			var violations = isBgh ? this.todayViolations : (this.todayViolations || []);
			var classes = isBgh ? this.bghClasses : (this.currentClasses || []);
			var tuQuanCount = classes.filter(function(c) { return c.IsTuQuan; }).length;
			var that = this;

			var text = 'THÔNG BÁO NỀ NẾP 15 PHÚT ĐẦU GIỜ (Trước 09:30 sáng) - ' + this.selectedKhoiName + '\n';
			text += 'Ngày: ' + dayLabel + ' (' + (this.selectedWeek ? this.selectedWeek.title : 'Tuần này') + ')\n';
			if (dayVal === 2) {
				text += '- Thứ Hai: Toàn trường sinh hoạt đầu tuần cùng GVCN (Không áp dụng chấm tự quản).\n';
			} else {
				text += '- Tổng số lớp tự quản hôm nay: ' + tuQuanCount + '/' + classes.length + ' lớp.\n';
				if (violations.length === 0) {
					text += '- Kết quả: 100% các lớp tự quản duy trì nền nếp Tốt/Đạt sáng nay, không có lớp nào bị Chưa đạt.\n';
				} else {
					text += '- Lớp tự quản Chưa đạt (có ≥ 2 tiêu chí CĐ):\n';
					violations.forEach(function(v) {
						var viPhamItems = v.TieuChiList ? v.TieuChiList.filter(function(tc) { return tc.score === 1; }).map(function(tc, idx) { return that.formatCriterionItem(tc, idx).badgeText; }) : [];
						var viPhamStr = viPhamItems.length ? viPhamItems.join('; ') : 'Tiêu chí nề nếp';
						text += '  + Lớp ' + v.TenLop + ' (GVCN ' + v.TenGVCN + '): ' + viPhamStr + ' - ' + (v.GhiChuViPham || 'Cần chấn chỉnh') + '\n';
					});
				}
			}
			if (navigator.clipboard) {
				navigator.clipboard.writeText(text);
			}
			this.showNotice('Đã sao chép nội dung báo cáo gửi nhóm Zalo!', 'success');
		},
		toggleApplyPenalty(item) {
			var nextState = !item.IsApplied;
			this.penaltyOverrides[item.LopID] = nextState;
			this.penaltyOverrides = { ...this.penaltyOverrides };
			this.showNotice(nextState ? ('Đã kích hoạt lại chế tài tạm dừng tự quản lớp ' + item.TenLop + '!') : ('Đã hủy chế tài lớp ' + item.TenLop + ' (vẫn lưu vết vi phạm trên báo cáo)'), 'info');
		},
		formatViolationsSummary(violations) {
			if (!violations || !violations.length) return '';
			return violations.map(function(v) {
				var shortDay = v.Ngay ? v.Ngay.split(' ')[0] : '';
				return shortDay + ': ' + (v.TieuChi || 'Vi phạm');
			}).join('; ');
		},
		getWeeklyClassEvaluation(cls) {
			var that = this;
			var sched = that.getScheduleForClass(cls.LopID);
			var daysResult = [];
			var violations = [];
			var totCount = 0;
			var datCount = 0;
			var cdCount = 0;
			var tuQuanCount = 0;

			that.daysOfWeek.forEach(function(d) {
				var dayVal = d.val;
				var dateStr = that.getDateStringForDay(dayVal);
				var snapKey = dateStr + '_' + cls.LopID;
				var legacyKey = String(dayVal) + '_' + cls.LopID;

				var daySched = sched ? sched.find(function(s) { return s.key === dayVal; }) : null;

				// Lấy dữ liệu đánh giá thực tế của Quản sinh (nếu có)
				var classData = null;
				if (that.isSpecificDayToday(dayVal) && that.currentClasses && that.currentClasses.length) {
					classData = that.currentClasses.find(function(c) { return String(c.LopID) === String(cls.LopID); });
				}
				if (!classData && !that.isSpecificDayInFuture(dayVal)) {
					if (that.dailySnapshots[snapKey]) {
						classData = that.dailySnapshots[snapKey];
					} else if (that.selectedWeek && that.selectedWeek.startDate === '2026-10-05' && that.dailySnapshots[legacyKey]) {
						classData = that.dailySnapshots[legacyKey];
					} else if (that.dailyWorkingState[dateStr]) {
						classData = that.dailyWorkingState[dateStr].find(function(c) { return String(c.LopID) === String(cls.LopID); });
					}
				}

				if (dayVal === 2) {
					// Thứ 2 luôn là Chào cờ
					daysResult.push({
						dayVal: dayVal,
						dayLabel: d.label,
						date: d.date,
						isTuQuan: false,
						statusText: 'Chào cờ',
						code: 'CC',
						color: '#1565c0',
						bg: '#e3f2fd',
						ghiChu: '',
						gvcnCoMat: true
					});
					return;
				}

				var isTuQuan = false;
				if (classData && classData.IsTuQuan !== undefined) {
					isTuQuan = !!classData.IsTuQuan;
				} else if (daySched) {
					isTuQuan = !!daySched.IsTuQuan;
				}
				// Nếu Quản sinh đã chấm điểm hoặc có ghi chú vi phạm thì xác nhận là tự quản
				if (classData && classData.TieuChiList && (classData.TieuChiList.some(function(tc) { return tc.score === 1; }) || classData.GhiChuViPham)) {
					isTuQuan = true;
				}

				if (!isTuQuan || that.isSpecificDayInFuture(dayVal)) {
					daysResult.push({
						dayVal: dayVal,
						dayLabel: d.label,
						date: d.date,
						isTuQuan: false,
						statusText: '—',
						code: '—',
						color: '#757575',
						bg: '#f5f5f5',
						ghiChu: '',
						gvcnCoMat: true
					});
					return;
				}

				tuQuanCount++;

				if (!classData) {
					// Chưa chấm
					daysResult.push({
						dayVal: dayVal,
						dayLabel: d.label,
						date: d.date,
						isTuQuan: true,
						statusText: 'Chưa chấm',
						code: '—',
						color: '#9e9e9e',
						bg: '#f5f5f5',
						ghiChu: '',
						gvcnCoMat: true
					});
					return;
				}

				// Tính kết quả theo tiêu chí Quản sinh đã chấm
				var tcs = classData.TieuChiList || [];
				var cdInDay = tcs.filter(function(tc) { return tc.score === 1; }).length;
				var totInDay = tcs.filter(function(tc) { return tc.score === 3; }).length;
				var ghiChu = classData.GhiChuViPham || '';

				var resCode = 'T';
				var resText = 'Tốt';
				var resColor = '#2e7d32';
				var resBg = '#e8f5e9';

				var datInDay = tcs.filter(function(tc) { return tc.score === 2; }).length;
				var isDayCd = cdInDay >= 2 || (cdInDay >= 1 && ghiChu && ghiChu.trim());
				var isDayTot = (cdInDay === 0) && (totInDay === tcs.length || (totInDay >= 2 && datInDay === 1));

				if (isDayCd) {
					// Tiêu chí Chưa đạt
					resCode = 'CD';
					resText = 'Chưa đạt';
					resColor = '#c62828';
					resBg = '#ffebee';
					cdCount++;

					var violatedItems = tcs.filter(function(tc) { return tc.score === 1; }).map(function(tc, idx) { return that.formatCriterionItem(tc, idx); });
					var violatedBadges = violatedItems.map(function(vi) { return vi.badgeText; }).join('; ');
					violations.push({
						day: d.label + ' (' + d.date + ')',
						tieuChi: violatedBadges || 'Vi phạm nề nếp',
						viPhamList: violatedItems,
						ghiChu: ghiChu || 'Không đạt yêu cầu tự quản'
					});
				} else if (!isDayTot) {
					resCode = 'D';
					resText = 'Đạt';
					resColor = '#1565c0';
					resBg = '#e3f2fd';
					datCount++;
					if (ghiChu) {
						violations.push({
							day: d.label + ' (' + d.date + ')',
							tieuChi: 'Lưu ý nề nếp',
							ghiChu: ghiChu
						});
					}
				} else {
					resCode = 'T';
					resText = 'Tốt';
					resColor = '#2e7d32';
					resBg = '#e8f5e9';
					totCount++;
				}

				daysResult.push({
					dayVal: dayVal,
					dayLabel: d.label,
					date: d.date,
					isTuQuan: true,
					statusText: resText,
					code: resCode,
					color: resColor,
					bg: resBg,
					ghiChu: ghiChu,
					gvcnCoMat: isGvcnPresent,
					tieuChiList: tcs
				});
			});

			// Xếp loại tuần & Chế tài theo quy định khách hàng (Mục 2a): Tuần tự quản bị ghi nhận chưa đạt (CĐ)
			var isBlocked = (cdCount > 0);
			var hasPenaltyOverride = that.penaltyOverrides && (that.penaltyOverrides[cls.LopID] !== undefined);
			var isApplied = hasPenaltyOverride ? that.penaltyOverrides[cls.LopID] : (isBlocked || that.isClassBlocked(cls.LopID));

			var hasEvaluated = (totCount + datCount + cdCount > 0);
			var xepLoaiTuan = '—';
			var xepLoaiColor = '#757575';
			var xepLoaiBg = '#f5f5f5';

			if (isApplied || that.isClassBlocked(cls.LopID)) {
				xepLoaiTuan = 'Tạm dừng TQ';
				xepLoaiColor = '#c62828';
				xepLoaiBg = '#ffebee';
				if (violations.length === 0) {
					violations.push({
						day: 'Cả tuần',
						tieuChi: 'Chấp hành chế tài tạm dừng tự quản',
						ghiChu: ''
					});
				}
			} else if (!hasEvaluated || tuQuanCount === 0) {
				xepLoaiTuan = '—';
				xepLoaiColor = '#757575';
				xepLoaiBg = '#f5f5f5';
			} else if (cdCount > 0) {
				xepLoaiTuan = 'Chưa đạt';
				xepLoaiColor = '#c62828';
				xepLoaiBg = '#ffebee';
			} else if (totCount === tuQuanCount && tuQuanCount > 0) {
				xepLoaiTuan = 'Xuất sắc';
				xepLoaiColor = '#1b5e20';
				xepLoaiBg = '#e8f5e9';
			} else {
				xepLoaiTuan = 'Đạt';
				xepLoaiColor = '#1565c0';
				xepLoaiBg = '#e3f2fd';
			}

			// Lịch đăng ký tóm tắt
			var tuQuanDaysLabels = [];
			if (sched) {
				sched.forEach(function(s) {
					if (s.key !== 2 && s.IsTuQuan) {
						var fDay = that.daysOfWeek.find(function(d) { return d.val === s.key; });
						if (fDay) tuQuanDaysLabels.push(fDay.label);
					}
				});
			}
			var lichSummary = tuQuanCount > 0 ? (tuQuanCount + ' buổi (' + tuQuanDaysLabels.join(', ') + ')') : 'Không tự quản';

			return {
				LopID: cls.LopID,
				TenLop: cls.TenLop,
				TenGVCN: cls.TenGVCN,
				LichSummary: lichSummary,
				tuQuanCount: tuQuanCount,
				totCount: totCount,
				datCount: datCount,
				cdCount: cdCount,
				hasEvaluated: hasEvaluated,
				daysResult: daysResult,
				violations: violations,
				xepLoaiTuan: xepLoaiTuan,
				xepLoaiColor: xepLoaiColor,
				xepLoaiBg: xepLoaiBg,
				isApplied: isApplied
			};
		},
		openPrintDialog(mode) {
			if (mode && typeof mode === 'string') {
				this.printDialog.mode = mode;
			} else if (this.activeTab === 'baocao' || this.isBghRole) {
				this.printDialog.mode = 'bgh_summary';
			} else {
				this.printDialog.mode = 'daily';
			}
			this.printDialog.show = true;
		},
		getClassesForPrintDay(dayVal) {
			var that = this;
			var k = this.selectedKhoi || 6;
			var list = this.getRealClassesByKhoi(k);
			if (dayVal === this.selectedDay && this.currentClasses && this.currentClasses.length > 0) {
				return this.currentClasses;
			}
			var dateStr = this.getDateStringForDay(dayVal);
			return list.map(function(item) {
				var snapshotKey = dateStr + '_' + item.LopID;
				var legacyKey = String(dayVal) + '_' + item.LopID;
				var snap = that.dailySnapshots[snapshotKey] || ((that.selectedWeek && that.selectedWeek.startDate === '2026-10-05') ? that.dailySnapshots[legacyKey] : null);
				if (!snap && that.dailyWorkingState[dateStr]) {
					snap = that.dailyWorkingState[dateStr].find(function(c) { return String(c.LopID) === String(item.LopID); });
				}
				if (snap) {
					var sched = that.getScheduleForClass(item.LopID);
					var daySched = sched ? sched.find(function(s) { return s.key === dayVal; }) : null;
					var isTuQuan = (dayVal !== 2) && (snap.IsTuQuan !== undefined ? !!snap.IsTuQuan : (daySched ? !!daySched.IsTuQuan : false));
					if (item.TenLop === '06D' && dayVal === 5) {
						isTuQuan = true;
					}
					if (dayVal !== 2 && (snap.GhiChuViPham || (snap.TieuChiList && snap.TieuChiList.some(function(tc) { return tc.score === 1; })))) {
						isTuQuan = true;
					}
					return {
						LopID: item.LopID,
						TenLop: item.TenLop,
						TenGVCN: item.TenGVCN,
						IsTuQuan: isTuQuan,
						TieuChiList: JSON.parse(JSON.stringify(snap.TieuChiList || [])),
						GhiChuViPham: snap.GhiChuViPham || '',
						IsSaved: true
					};
				}
				var sched = that.getScheduleForClass(item.LopID);
				var daySched = sched ? sched.find(function(s) { return s.key === dayVal; }) : null;
				var isTuQuan = (dayVal !== 2) && (daySched ? !!daySched.IsTuQuan : false);
				return {
					LopID: item.LopID,
					TenLop: item.TenLop,
					TenGVCN: item.TenGVCN,
					IsTuQuan: isTuQuan,
					TieuChiList: JSON.parse(JSON.stringify(that.baseCriteria)),
					GhiChuViPham: '',
					IsSaved: false
				};
			});
		},
		getMergedPrintCriteria() {
			// Lấy tập hợp tất cả các tiêu chí đang có trong các lớp hiển thị
			var map = {};
			var result = [];
			this.currentClasses.forEach(function(cls) {
				if (cls.TieuChiList) {
					cls.TieuChiList.forEach(function(tc) {
						if (!map[tc.id]) {
							map[tc.id] = true;
							result.push(tc);
						}
					});
				}
			});
			return result.length > 0 ? result : this.baseCriteria;
		},
		isClassHavingCriteria(cls, tc) {
			if (!cls || !cls.TieuChiList) return true;
			return cls.TieuChiList.some(function(item) { return item.id === tc.id; });
		},
		findClassCriterion(cls, tc) {
			if (!cls || !cls.TieuChiList) return { score: 3 };
			var found = cls.TieuChiList.find(function(item) { return item.id === tc.id; });
			return found || { score: 3 };
		},
		setCriterionScore(cls, tc, score) {
			if (this.isReadOnlyDay || this.selectedDay === 2 || !cls.IsTuQuan) return;
			var crit = this.findClassCriterion(cls, tc);
			if (crit) {
				crit.score = score;
				this.evalUpdateVersion++;
				this.autoSaveDailyEvaluation(300);
			}
		},
		getCriterionFullName(name) {
			if (!name) return '';
			if (name.indexOf('Không gian') !== -1) {
				return 'Không gian lớp (Mở cửa, VS, bàn ghế)';
			}
			if (name.indexOf('Nền nếp') !== -1 || name.indexOf('Nề nếp') !== -1) {
				return 'Nền nếp & chuẩn bị tâm thế học tập (Sĩ số, tác phong, sách vở)';
			}
			if (name.indexOf('chủ đề') !== -1 || name.indexOf('Chủ đề') !== -1) {
				return 'Sinh hoạt chủ đề (Đúng 7:20, nghiêm túc)';
			}
			// Tiêu chí bổ sung: bỏ số thứ tự "1. ", "4. " nếu có, giữ nguyên tên đầy đủ
			return name.replace(/^[0-9]+[.\s-]+\s*/, '').trim();
		},
		getShortCriterionTitle(name) {
			return this.getCriterionFullName(name);
		},
		getUltraShortCriterionTitle(name) {
			return this.getCriterionFullName(name);
		},
		getCriterionMainTitle(name) {
			if (!name) return '';
			var full = this.getCriterionFullName(name);
			var idx = full.indexOf('(');
			if (idx !== -1) {
				return full.substring(0, idx).trim();
			}
			return full;
		},
		getCriterionSubTitle(name) {
			if (!name) return '';
			var full = this.getCriterionFullName(name);
			var idx = full.indexOf('(');
			if (idx !== -1) {
				return full.substring(idx).trim();
			}
			return '';
		},
		getLogCritScore(log, index) {
			if (!log || !log.TieuChiList || !log.TieuChiList[index]) return 0;
			return log.TieuChiList[index].score;
		},
		executePrint() {
			var self = this;
			var mode = this.printDialog.mode;
			var khoiName = this.selectedKhoiName;
			var weekTitle = this.selectedWeek ? this.selectedWeek.title : 'Tuần học';
			var dayLabel = this.currentDayLabel;
			var criteriaList = this.getMergedPrintCriteria();
			var classes = this.currentClasses;
			var days = this.daysOfWeek;

			var html = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Phiếu Giám Sát 15 Phút Tự Quản - LHBS</title>';
			html += '<style>';
			html += '@page { size: A4 landscape; margin: 8mm 10mm; }';
			html += 'body { font-family: "Times New Roman", serif; color: #000; margin: 0; padding: 5px; }';
			html += 'h2, h3 { margin: 2px 0; text-align: center; }';
			html += '.meta-row { display: flex; justify-content: space-between; margin: 6px 0; font-size: 11pt; }';
			html += '.legend-box { background-color: #f7f7f7; border: 1px solid #ccc; padding: 4px 8px; margin: 6px 0; font-size: 9.5pt; border-radius: 4px; }';
			html += 'table { width: 100%; border-collapse: collapse; margin-top: 6px; }';
			html += 'th, td { border: 1px solid #222; padding: 4px 3px; text-align: center; font-size: 10pt; }';
			html += 'th { background-color: #f0f0f0; }';
			html += '.text-left { text-align: left; }';
			html += '.cb-group { white-space: nowrap; font-size: 9pt; display: inline-flex; gap: 4px; justify-content: center; }';
			html += '.sign-block { display: flex; justify-content: space-between; margin-top: 25px; text-align: center; font-size: 11pt; page-break-inside: avoid; }';
			html += '</style></head><body>';

			if (mode === 'bgh_summary') {
				var reportClasses = this.bghWeeklyReportClasses;
				var stats = this.bghWeeklyReportStats;

				html += '<h2>TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG</h2>';
				html += '<h3 style="color: #1565c0; font-size: 13.5pt;">BÁO CÁO TỔNG HỢP NỀ NẾP & ĐÁNH GIÁ 15 PHÚT TỰ QUẢN TUẦN</h3>';
				html += '<div style="text-align: center; font-style: italic; font-size: 10.5pt; margin-bottom: 6px;">(Kèm kết quả chấm thực tế & ghi chú vi phạm của Quản sinh khối)</div>';

				html += '<div class="meta-row">';
				var displayKhoi = khoiName.startsWith('Khối') ? khoiName : ('Khối: ' + khoiName);
				html += '<div><strong>' + displayKhoi + '</strong></div>';
				html += '<div><strong>' + weekTitle + '</strong></div>';
				html += '<div>Người lập: <strong>Quản sinh khối</strong></div>';
				html += '</div>';

				html += '<div style="background-color: #f0f4f8; border: 1px solid #b0bec5; padding: 6px 12px; margin: 6px 0; font-size: 9.5pt; display: flex; justify-content: space-between; border-radius: 4px;">';
				html += '<div>Tổng số lớp: <strong>' + stats.total + ' lớp</strong></div>';
				html += '<div>Đạt Tốt / Xuất sắc: <strong style="color: #2e7d32;">' + stats.totCount + ' lớp</strong></div>';
				html += '<div>Đạt: <strong style="color: #1565c0;">' + stats.datCount + ' lớp</strong></div>';
				html += '<div>Tạm dừng TQ / Nhắc nhở: <strong style="color: #c62828;">' + stats.blockedCount + ' lớp</strong></div>';
				html += '</div>';

				html += '<table><thead><tr style="background-color: #e8eaf6; height: 32px;">';
				html += '<th style="width: 32px;">STT</th>';
				html += '<th style="width: 55px;">Lớp</th>';
				html += '<th style="width: 125px; text-align: left; padding-left: 6px;">GVCN</th>';
				html += '<th style="width: 85px;">Lịch TQ</th>';
				days.forEach(function(d) {
					html += '<th style="width: 68px;">' + d.label + '<br><span style="font-size: 7.5pt; font-weight: normal;">(' + d.date + ')</span></th>';
				});
				html += '<th style="width: 85px;">Xếp loại tuần</th>';
				html += '<th style="min-width: 160px; text-align: left; padding-left: 6px;">Chi tiết đánh giá & Ghi chú Quản sinh</th>';
				html += '</tr></thead><tbody>';

				reportClasses.forEach(function(row, idx) {
					var rowBg = row.isApplied ? '#fff5f5' : (idx % 2 === 1 ? '#fafafa' : '#ffffff');
					html += '<tr style="height: 34px; background-color: ' + rowBg + ';">';
					html += '<td>' + (idx + 1) + '</td>';
					html += '<td style="font-weight: bold; font-size: 10pt;">' + row.TenLop + '</td>';
					html += '<td class="text-left" style="font-size: 9pt; padding-left: 6px;">' + row.TenGVCN + '</td>';
					html += '<td style="font-size: 8.5pt;">' + row.LichSummary + '</td>';
					row.daysResult.forEach(function(d) {
						var txt = d.code === 'CC' ? 'Chào cờ' : (d.code === 'CHETAI' ? 'Tạm dừng TQ' : (d.code === '—' || d.code === 'GV' ? '—' : ('[' + d.code + '] ' + d.statusText)));
						html += '<td style="color: ' + d.color + '; font-weight: bold; font-size: 8.5pt;">' + txt + '</td>';
					});
					html += '<td style="color: ' + row.xepLoaiColor + '; font-weight: bold; font-size: 9pt;">' + row.xepLoaiTuan + '</td>';
					html += '<td class="text-left" style="font-size: 8.5pt; padding-left: 6px;">';
					if (row.violations.length > 0) {
						var vList = row.violations.map(function(v) {
							return '<span style="color: #c62828;"><strong>' + v.day + ':</strong> ' + v.tieuChi + (v.ghiChu ? ' (' + v.ghiChu + ')' : '') + '</span>';
						});
						html += vList.join('<br>');
					} else if (!row.hasEvaluated || row.tuQuanCount === 0) {
						html += '<span style="color: #757575; font-weight: bold;">—</span>';
					} else {
						html += '<span style="color: #2e7d32;">Nề nếp tốt, nghiêm túc (0 lỗi)</span>';
					}
					html += '</td>';
					html += '</tr>';
				});

				html += '</tbody></table>';

				html += '<div class="sign-block" style="margin-top: 30px;">';
				html += '<div style="width: 45%;"><strong>NGƯỜI LẬP BÁO CÁO / QUẢN SINH</strong><br><i>(Kí và ghi rõ họ tên)</i></div>';
				html += '<div style="width: 45%;"><strong>BAN GIÁM HIỆU DUYỆT</strong><br><i>(Kí và ghi rõ họ tên)</i></div>';
				html += '</div>';
			} else {
				var printTitle = (mode === 'weekly') ? 'SỔ GIÁM SÁT 15 PHÚT TỰ QUẢN CẢ TUẦN' : 'PHIẾU GIÁM SÁT 15 PHÚT TỰ QUẢN ĐẦU GIỜ';
				html += '<h2>TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG</h2>';
				html += '<h3>' + printTitle + '</h3>';
				var subText = (self.isBghRole || self.activeTab === 'baocao')
					? (mode === 'weekly' ? '(Bản tổng hợp kết quả Quản sinh đánh giá các ngày trong tuần gửi Ban Giám Hiệu)' : '(Bản tổng hợp kết quả Quản sinh đánh giá gửi Ban Giám Hiệu)')
					: '(Dành cho Quản sinh khối & Đội Sao đỏ / Đoàn viên xung kích)';
				html += '<div style="text-align: center; font-style: italic; font-size: 10.5pt;">' + subText + '</div>';
				
				html += '<div class="meta-row">';
				var displayKhoi = khoiName.startsWith('Khối') ? khoiName : ('Khối: ' + khoiName);
				html += '<div><strong>' + displayKhoi + '</strong></div>';
				html += '<div>' + weekTitle + '</div>';
				if (mode === 'daily') {
					html += '<div>Ngày chấm: <strong>' + dayLabel + '</strong></div>';
				}
				html += '</div>';

				// Bảng ghi chú các tiêu chí (Legend)
				html += '<div class="legend-box">';
				html += '<strong>Nội dung tiêu chí:</strong> ';
				var legendItems = criteriaList.map(function(tc, idx) {
					return '<strong>TC' + (idx + 1) + ':</strong> ' + tc.ten;
				});
				html += legendItems.join(' &nbsp; | &nbsp; ');
				html += '<div style="font-style: italic; font-size: 8.5pt; margin-top: 2px;">* Đánh giá từng phòng: [T] = Tốt, [Đ] = Đạt, [CĐ] = Cần cố gắng. Chi tiết vi phạm ghi cột Ghi chú.</div>';
				html += '</div>';

				var isBghPrint = (self.isBghRole || self.activeTab === 'baocao');

				if (mode === 'daily') {
					html += '<table><thead><tr>';
					html += '<th style="width: 38px;">STT</th><th style="width: 70px;">Lớp</th><th style="width: 140px; text-align: left; padding-left: 6px;">GVCN</th>';
					criteriaList.forEach(function(tc, idx) {
						var sub = self.getCriterionSubTitle(tc.ten);
						html += '<th style="min-width: 100px;"><div style="font-weight: bold;">' + (idx + 1) + '. ' + self.getCriterionMainTitle(tc.ten) + '</div>' + (sub ? '<div style="font-size: 7.5pt; font-weight: normal; color: #555; line-height: 1.2;">' + sub + '</div>' : '') + '</th>';
					});
					html += '<th style="min-width: 140px; text-align: left; padding-left: 6px;">Ghi chú vi phạm / Kí tên</th></tr></thead><tbody>';

					classes.forEach(function(cls, idx) {
						var isBlocked = self.isClassBlocked(cls.LopID);
						var rowBg = isBlocked ? 'background-color: #fff5f5;' : '';
						html += '<tr style="height: 38px;' + rowBg + '">';
						html += '<td>' + (idx + 1) + '</td>';
						html += '<td style="font-weight: bold; font-size: 10.5pt;' + (isBlocked ? ' color: #c62828;' : '') + '">' + cls.TenLop + '</td>';
						var gvcnSub = '';
						if (isBlocked) {
							gvcnSub = ' <span style="color:#c62828; font-weight:bold; font-size:8.5pt; display:block;">[TẠM DỪNG TỰ QUẢN]</span>';
						} else if (self.selectedDay === 2 || !cls.IsTuQuan) {
							gvcnSub = ' <span style="color:#546e7a; font-size:8.5pt; display:block;">(GVCN sinh hoạt)</span>';
						} else {
							gvcnSub = ' <span style="color:#2e7d32; font-size:8.5pt; display:block;">(Lớp tự quản)</span>';
						}
						html += '<td class="text-left" style="font-size: 9.5pt; padding-left: 6px;"><div>' + cls.TenGVCN + '</div>' + gvcnSub + '</td>';
						criteriaList.forEach(function(tc) {
							var hasTc = cls.TieuChiList ? cls.TieuChiList.some(function(x) { return x.id === tc.id; }) : true;
							html += '<td>';
							if (isBlocked || self.selectedDay === 2 || !cls.IsTuQuan) {
								html += '<span style="color:#64748b; font-size:11pt; font-weight:500;">—</span>';
							} else if (hasTc) {
								if (isBghPrint) {
									var sc = self.findClassCriterion(cls, tc).score;
									var tStr = (sc === 3) ? '<strong style="color:#2e7d32;">[✓] T</strong>' : '<span style="color:#888;">[ ] T</span>';
									var dStr = (sc === 2) ? '<strong style="color:#1565c0;">[✓] Đ</strong>' : '<span style="color:#888;">[ ] Đ</span>';
									var cdStr = (sc === 1) ? '<strong style="color:#c62828;">[✓] CĐ</strong>' : '<span style="color:#888;">[ ] CĐ</span>';
									html += '<div class="cb-group">' + tStr + ' ' + dStr + ' ' + cdStr + '</div>';
								} else {
									html += '<div class="cb-group"><span>[ ] T</span><span>[ ] Đ</span><span>[ ] CĐ</span></div>';
								}
							} else {
								html += '<span style="color:#bbb;">—</span>';
							}
							html += '</td>';
						});
						var noteTxt = isBlocked ? 'Tạm dừng tự quản 01 tuần (GVCN có mặt 5/5 buổi lúc 7:15)' : (cls.GhiChuViPham || '');
						html += '<td class="text-left" style="font-size: 9pt; padding-left: 6px;' + (isBlocked ? ' color:#c62828; font-weight:bold;' : '') + '">' + noteTxt + '</td>';
						html += '</tr>';
					});
					html += '</tbody></table>';
				} else {
					days.forEach(function(d) {
						var dayClasses = self.getClassesForPrintDay(d.val);
						html += '<div style="margin-top: 14px; font-weight: bold; font-size: 11pt; text-transform: uppercase; color: #1565c0;">► ' + d.label + ' (' + d.date + ')</div>';
						if (d.val === 2) {
							html += '<div style="font-size: 8.5pt; font-style: italic; color: #666; margin-bottom: 3px;">* Tiết sinh hoạt đầu tuần cùng GVCN (Không chấm tự quản)</div>';
						}
						html += '<table><thead><tr>';
						html += '<th style="width: 35px;">STT</th><th style="width: 65px;">Lớp</th><th style="width: 130px; text-align: left; padding-left: 6px;">GVCN</th>';
						criteriaList.forEach(function(tc, idx) {
							var sub = self.getCriterionSubTitle(tc.ten);
							html += '<th style="min-width: 95px;"><div style="font-weight: bold;">' + (idx + 1) + '. ' + self.getCriterionMainTitle(tc.ten) + '</div>' + (sub ? '<div style="font-size: 7pt; font-weight: normal; color: #555; line-height: 1.2;">' + sub + '</div>' : '') + '</th>';
						});
						html += '<th style="min-width: 130px; text-align: left; padding-left: 6px;">Ghi chú vi phạm / Kí tên</th></tr></thead><tbody>';
						dayClasses.forEach(function(cls, idx) {
							var isBlocked = self.isClassBlocked(cls.LopID);
							var rowBg = isBlocked ? 'background-color: #fff5f5;' : '';
							html += '<tr style="height: 32px;' + rowBg + '">';
							html += '<td>' + (idx + 1) + '</td>';
							html += '<td style="font-weight: bold;' + (isBlocked ? ' color: #c62828;' : '') + '">' + cls.TenLop + '</td>';
							var gvcnSub = '';
							if (isBlocked) {
								gvcnSub = ' <span style="color:#c62828; font-size:7.5pt; display:block; font-weight:bold;">[TẠM DỪNG TỰ QUẢN]</span>';
							} else if (d.val === 2 || !cls.IsTuQuan) {
								gvcnSub = ' <span style="color:#546e7a; font-size:7.5pt; display:block;">(GVCN sinh hoạt)</span>';
							} else {
								gvcnSub = ' <span style="color:#2e7d32; font-size:7.5pt; display:block;">(Lớp tự quản)</span>';
							}
							html += '<td class="text-left" style="font-size: 9pt; padding-left: 6px;"><div>' + cls.TenGVCN + '</div>' + gvcnSub + '</td>';
							criteriaList.forEach(function(tc) {
								html += '<td>';
								if (isBlocked || d.val === 2 || !cls.IsTuQuan) {
									html += '<span style="color:#64748b; font-size:11pt; font-weight:500;">—</span>';
								} else if (isBghPrint) {
									var sc = self.findClassCriterion(cls, tc).score;
									var tStr = (sc === 3) ? '<strong style="color:#2e7d32;">[✓] T</strong>' : '<span style="color:#888;">[ ] T</span>';
									var dStr = (sc === 2) ? '<strong style="color:#1565c0;">[✓] Đ</strong>' : '<span style="color:#888;">[ ] Đ</span>';
									var cdStr = (sc === 1) ? '<strong style="color:#c62828;">[✓] CĐ</strong>' : '<span style="color:#888;">[ ] CĐ</span>';
									html += '<div class="cb-group">' + tStr + ' ' + dStr + ' ' + cdStr + '</div>';
								} else {
									html += '<div class="cb-group"><span>[ ] T</span><span>[ ] Đ</span><span>[ ] CĐ</span></div>';
								}
								html += '</td>';
							});
							var noteTxt = isBlocked ? 'Tạm dừng tự quản 01 tuần (GVCN có mặt 5/5 buổi lúc 7:15)' : (cls.GhiChuViPham || '');
							html += '<td class="text-left" style="font-size: 8pt; padding-left: 4px;' + (isBlocked ? ' color:#c62828; font-weight:bold;' : '') + '">' + noteTxt + '</td></tr>';
						});
						html += '</tbody></table>';
					});
				}

				var signLeft = isBghPrint ? 'NGƯỜI LẬP / QUẢN SINH KHỐI' : 'ĐỘI SAO ĐỎ / ĐOÀN VIÊN XUNG KÍCH';
				var signRight = isBghPrint ? 'BAN GIÁM HIỆU DUYỆT' : 'QUẢN SINH KHỐI';
				html += '<div class="sign-block">';
				html += '<div style="width: 45%;"><strong>' + signLeft + '</strong><br><i>(Kí và ghi rõ họ tên)</i></div>';
				html += '<div style="width: 45%;"><strong>' + signRight + '</strong><br><i>(Kí và ghi rõ họ tên)</i></div>';
				html += '</div>';
			}

			html += '</body></html>';

			// Thử mở popup in
			var printWin = null;
			try {
				printWin = window.open('', '_blank');
			} catch (e) {
				printWin = null;
			}

			if (printWin && printWin.document) {
				printWin.document.open();
				printWin.document.write(html);
				printWin.document.close();
				setTimeout(function() {
					try {
						printWin.focus();
						printWin.print();
					} catch (err) {
						console.error(err);
					}
				}, 400);
			} else {
				// Trường hợp trình duyệt chặn popup, dùng hidden iframe để in trực tiếp
				var iframe = document.getElementById('tu-quan-print-iframe');
				if (!iframe) {
					iframe = document.createElement('iframe');
					iframe.id = 'tu-quan-print-iframe';
					iframe.style.position = 'fixed';
					iframe.style.right = '0';
					iframe.style.bottom = '0';
					iframe.style.width = '0';
					iframe.style.height = '0';
					iframe.style.border = '0';
					document.body.appendChild(iframe);
				}
				var doc = iframe.contentWindow || iframe.contentDocument;
				if (doc.document) doc = doc.document;
				doc.open();
				doc.write(html);
				doc.close();
				setTimeout(function() {
					try {
						iframe.contentWindow.focus();
						iframe.contentWindow.print();
					} catch (err) {
						window.print();
					}
				}, 400);
			}
		},
		showNotice(text, color) {
			this.snackbar.text = text;
			this.snackbar.color = color || 'success';
			this.snackbar.show = true;
		}
	}
	}
</script>

<style scoped>
.uc-tu-quan-15-phut {
	font-family: inherit;
}
.class-card {
	border: 1px solid #e0e0e0;
	transition: all 0.2s ease-in-out;
}
.class-card:hover {
	box-shadow: 0 4px 12px rgba(0,0,0,0.08) !important;
}
.border-error {
	border-left: 3px solid #ef4444 !important;
}
.border-default {
	border-left: 3px solid #3b82f6 !important;
}
.border-b-dashed {
	border-bottom: 1px dashed #e0e0e0;
}
.schedule-active {
	background-color: #e3f2fd !important;
	border-color: #1976d2 !important;
}
.cursor-pointer {
	cursor: pointer;
}
.table-responsive {
	width: 100%;
	overflow-x: auto;
	-webkit-overflow-scrolling: touch;
}
.mobile-days-toggle {
	width: 100% !important;
	display: flex !important;
	height: 42px !important;
	min-height: 42px !important;
	max-height: 42px !important;
	border: none !important;
	border-radius: 8px !important;
	background: transparent !important;
	box-shadow: none !important;
	overflow: hidden !important;
}
.mobile-days-toggle .v-btn,
.mobile-days-toggle :deep(.v-btn) {
	flex: 1 1 0% !important;
	width: 20% !important;
	max-width: 20% !important;
	min-width: 0 !important;
	height: 100% !important;
	min-height: 100% !important;
	max-height: 100% !important;
	align-self: stretch !important;
	border: none !important;
	border-radius: 6px !important;
	padding: 0 4px !important;
	margin: 0 !important;
	background: transparent;
	transition: all 0.15s ease;
}
.mobile-days-toggle :deep(.v-btn--selected),
.mobile-days-toggle .v-btn.v-btn--selected {
	background-color: #f0fdf4 !important;
	color: #15803d !important;
	font-weight: 700 !important;
	border: none !important;
	box-shadow: none !important;
}
.mobile-days-toggle .v-btn .v-btn__content,
.mobile-days-toggle :deep(.v-btn .v-btn__content) {
	width: 100%;
	height: 100%;
	display: flex;
	align-items: center;
	justify-content: center;
}
.mobile-score-toggle {
	height: 36px !important;
}
.mobile-score-toggle .v-btn {
	height: 36px !important;
}
.v-table table {
	width: 100% !important;
	table-layout: fixed !important;
}
.v-table th.text-center,
.v-table td.text-center {
	text-align: center !important;
}
.v-table th.text-left,
.v-table td.text-left {
	text-align: left !important;
}
.v-table th {
	font-weight: 600 !important;
	white-space: nowrap;
}
/* BẢNG MASTER: BỎ TOÀN BỘ VIỀN DỌC, CHỈ DÙNG ĐƯỜNG KẺ NGANG SIÊU NHẸ (EXECUTIVE AIRY STYLE) */
.evaluation-master-table {
	width: 100% !important;
	border-collapse: separate !important;
	border-spacing: 0 !important;
}
.evaluation-master-table th {
	border: none !important;
	border-bottom: 1px solid #e2e8f0 !important;
	background-color: #f8fafc !important;
	color: #475569 !important;
	font-weight: 600 !important;
	vertical-align: middle !important;
}
.evaluation-master-table td {
	border: none !important;
	border-bottom: 1px solid #f1f5f9 !important;
	vertical-align: middle !important;
}
.evaluation-master-table tbody tr:last-child td {
	border-bottom: none !important;
}

/* BADGES CHẾ TÀI & VI PHẠM: CĂN GIỮA TUYỆT ĐỐI THEO CHIỀU DỌC VÀ NGANG, KHÔNG BỊ LỆCH CHỮ */
.penalty-badge-day {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	height: 22px;
	box-sizing: border-box;
	padding: 0 8px;
	border-radius: 4px;
	font-size: 11px;
	font-weight: 600;
	background-color: #f1f5f9;
	color: #334155;
	border: none;
	white-space: nowrap;
	line-height: 1;
	flex-shrink: 0;
	letter-spacing: 0.1px;
	margin: 0;
}
.penalty-badge-status {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	height: 22px;
	box-sizing: border-box;
	padding: 0 10px;
	border-radius: 9999px;
	font-size: 11.5px;
	font-weight: 600;
	white-space: nowrap;
	line-height: 1;
	text-align: center;
	letter-spacing: 0.2px;
	border: none;
}
.penalty-badge-status.is-blocked {
	background-color: #fef2f2;
	color: #991b1b;
	border: 1px solid #fecaca;
}
.penalty-badge-status.is-canceled {
	background-color: #f8fafc;
	color: #64748b;
	border: 1px solid #e2e8f0;
}
.badge-tc-violation {
	display: inline-flex;
	align-items: center;
	height: 22px;
	box-sizing: border-box;
	padding: 0 8px 0 3px;
	border-radius: 4px;
	font-size: 11px;
	font-weight: 600;
	background-color: #fee2e2;
	color: #991b1b;
	border: none;
	white-space: nowrap;
	line-height: 1;
	flex-shrink: 0;
	margin: 0;
}
.badge-tc-violation .tc-code-tag {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	height: 16px;
	box-sizing: border-box;
	padding: 0 5px;
	font-weight: 800;
	color: #ffffff;
	background-color: #dc2626;
	border-radius: 3px;
	margin-right: 5px;
	font-size: 9.5px;
	letter-spacing: 0.2px;
	line-height: 1;
}

/* LÀM THANH THOÁT TOÀN BỘ BORDERS VUETIFY & TIỆN ÍCH KHUNG CARD */
:deep(.v-card--border),
.v-card--border {
	border-color: #eaecf0 !important;
}
:deep(.border),
.border {
	border-color: #eaecf0 !important;
}
:deep(.border-b),
.border-b {
	border-bottom-color: #f1f5f9 !important;
}
:deep(.border-t),
.border-t {
	border-top-color: #f1f5f9 !important;
}
:deep(.border-e),
.border-e {
	border-right-color: #f1f5f9 !important;
}
:deep(.border-s),
.border-s {
	border-left-color: #f1f5f9 !important;
}
.border-e:last-child {
	border-right: none !important;
}

.table-row-hover:hover {
	background-color: #f8fafc !important;
}
/* Badge trạng thái Lớp & GVCN (Đồng bộ border-radius 6px, chiều cao 22px, không méo) */
.table-status-badge {
	display: inline-flex;
	align-items: center;
	height: 22px;
	padding: 0 8px;
	border-radius: 6px;
	font-size: 11px;
	font-weight: 600;
	line-height: 1;
	white-space: nowrap;
	user-select: none;
}
.badge-tuquan {
	background-color: #eef2ff;
	color: #4338ca;
	border: 1px solid #e0e7ff;
}
.badge-gvcn {
	background-color: #f8fafc;
	color: #475569;
	border: 1px solid #e2e8f0;
}
.badge-chetai {
	background-color: #fee2e2;
	color: #b91c1c;
	border: 1px solid #fca5a5;
	font-weight: 600;
}

/* Bộ chọn điểm T - Đ - CĐ (Trực tiếp, KHÔNG bọc nền xám ngoài, khoảng cách 8px đều nhau) */
.score-group {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 8px; /* Khoảng cách đều nhau giữa T, Đ, CĐ */
	user-select: none;
	background: transparent;
	padding: 0;
	border: none;
}
.score-btn-item {
	width: 26px;
	height: 26px;
	min-width: 26px;
	max-width: 26px;
	border-radius: 50%; /* Tròn đều hoàn hảo */
	border: none;
	outline: none;
	background: transparent;
	color: #475569;
	font-size: 11.5px;
	font-weight: 700;
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 0;
	line-height: 1;
	transition: all 0.15s ease;
	box-sizing: border-box;
}
.score-btn-item:hover:not(:disabled) {
	background-color: #f1f5f9;
	color: #0f172a;
}
.score-btn-item.score-active-t {
	background-color: #16a34a !important;
	color: #ffffff !important;
	box-shadow: 0 1px 3px rgba(22, 163, 74, 0.4);
}
.score-btn-item.score-active-d {
	background-color: #2563eb !important;
	color: #ffffff !important;
	box-shadow: 0 1px 3px rgba(37, 99, 235, 0.4);
}
.score-btn-item.score-active-cd {
	background-color: #dc2626 !important;
	color: #ffffff !important;
	box-shadow: 0 1px 3px rgba(220, 38, 38, 0.4);
	font-size: 10.5px;
}
.score-disabled {
	opacity: 0.88;
	cursor: default;
}
.score-disabled .score-btn-item {
	cursor: default;
	pointer-events: none;
}

/* Badge cột Xếp loại: Rõ ràng, tương phản cao, nền dịu không chói, không viền nặng nề */
.table-rank-badge {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	height: 22px;
	padding: 0 8px;
	border-radius: 4px;
	font-size: 11.5px;
	font-weight: 700;
	line-height: 1;
	white-space: nowrap;
	user-select: none;
	border: none;
}
.table-rank-badge.rank-tot {
	background-color: #ecfdf5;
	color: #065f46;
}
.table-rank-badge.rank-dat {
	background-color: #eff6ff;
	color: #1e40af;
}
.table-rank-badge.rank-chuadat {
	background-color: #fef2f2;
	color: #991b1b;
}
.table-rank-badge.rank-ongoing {
	background-color: #f1f5f9;
	color: #475569;
}
.table-rank-badge.rank-future {
	background-color: #f8fafc;
	color: #94a3b8;
}
.table-rank-badge.rank-gvcn {
	background-color: #f1f5f9;
	color: #334155;
}
.table-rank-badge.rank-chetai {
	background-color: #fef2f2;
	color: #991b1b;
}

/* Tag tuần tiến độ & Tag khen thưởng: Thanh thoát, tương phản chuẩn, không viền lồng nhau */
.badge-week-tag {
	display: inline-flex;
	align-items: center;
	padding: 3px 8px;
	border-radius: 4px;
	font-size: 11px;
	font-weight: 600;
	white-space: nowrap;
	border: none;
}
.badge-week-tag.tag-tot {
	background-color: #ecfdf5;
	color: #065f46;
}
.badge-week-tag.tag-current {
	background-color: #eff6ff;
	color: #1e40af;
}
.badge-week-tag.tag-future {
	background-color: #f1f5f9;
	color: #64748b;
}
.badge-week-tag.tag-chuadat {
	background-color: #fef2f2;
	color: #991b1b;
}
.reward-tag-good {
	display: inline-flex;
	align-items: center;
	padding: 3px 8px;
	border-radius: 4px;
	font-size: 11.5px;
	font-weight: 700;
	background-color: #fef3c7;
	color: #92400e;
	white-space: nowrap;
	border: none;
}
.reward-tag-leading {
	display: inline-flex;
	align-items: center;
	padding: 3px 8px;
	border-radius: 4px;
	font-size: 11.5px;
	font-weight: 700;
	background-color: #fef9c3;
	color: #854d0e;
	white-space: nowrap;
	border: none;
}
.reward-tag-effort {
	display: inline-flex;
	align-items: center;
	padding: 3px 8px;
	border-radius: 4px;
	font-size: 11.5px;
	font-weight: 600;
	background-color: #ecfdf5;
	color: #047857;
	white-space: nowrap;
	border: none;
}
.reward-tag-blocked {
	display: inline-flex;
	align-items: center;
	padding: 3px 8px;
	border-radius: 4px;
	font-size: 11.5px;
	font-weight: 700;
	background-color: #fef2f2;
	color: #991b1b;
	white-space: nowrap;
	border: none;
}

.table-row-hover.row-chetai {
	background-color: #fff1f2 !important;
}

.compact-table-textarea,
.compact-table-textarea :deep(.v-field),
.compact-table-textarea :deep(.v-field__field),
.compact-table-textarea :deep(.v-field__input) {
	padding: 3px 6px !important;
	min-height: 28px !important;
	font-size: 13px !important;
	line-height: 1.4 !important;
}

.compact-table-textarea :deep(textarea) {
	font-size: 13px !important;
	line-height: 1.4 !important;
}

.compact-table-textarea :deep(textarea::placeholder),
.compact-table-textarea :deep(.v-field__input::placeholder),
.compact-table-textarea :deep(::placeholder) {
	font-size: 13px !important;
	opacity: 0.65 !important;
}

/* LƯỚI THỜI KHÓA BIỂU ĐĂNG KÍ (TKB GRID) - MỀM MẠI, THANH THOÁT */
.tkb-stripe-disabled {
	background-color: #f8fafc;
	background-image: repeating-linear-gradient(
		-45deg,
		transparent,
		transparent 8px,
		rgba(100, 116, 139, 0.05) 8px,
		rgba(100, 116, 139, 0.05) 16px
	);
	color: #64748b;
	transition: all 0.2s ease;
}

/* Ô được đăng ký tự quản: Xanh lá cây tươi sáng, viền mảnh mềm */
.tkb-cell-registered {
	background-color: #f0fdf4 !important;
	border-top: 2px solid #16a34a !important;
	color: #15803d !important;
	box-shadow: none !important;
	transition: all 0.2s ease;
}

.tkb-cell-registered:hover:not(.cursor-not-allowed) {
	background-color: #dcfce7 !important;
}

/* Ô có thể chọn (GVCN sinh hoạt): Nền trắng sạch sẽ, hover xanh báo hiệu bấm được */
.tkb-cell-available {
	background-color: #ffffff;
	color: #334155;
	transition: all 0.2s ease;
}

.tkb-cell-available:hover {
	background-color: #f8fafc;
	box-shadow: inset 0 0 0 1px #3b82f6;
}

/* Ô nhập ghi chú riêng từng ngày trong TKB */
.tkb-note-cell {
	background-color: #fafbfc;
	transition: all 0.2s ease;
}
.tkb-note-native-input {
	width: 100%;
	max-width: 100%;
	font-size: 10.5px !important;
	line-height: 1.2 !important;
	padding: 1px 4px !important;
	height: 22px !important;
	border: 1px solid #e2e8f0 !important;
	border-radius: 4px !important;
	background-color: #ffffff !important;
	color: #334155 !important;
	outline: none !important;
	text-align: center !important;
	box-sizing: border-box !important;
	transition: all 0.15s ease !important;
}
.tkb-note-native-input::placeholder {
	font-size: 10.5px !important;
	color: #94a3b8 !important;
}
.tkb-note-native-input:focus {
	border-color: #16a34a !important;
	background-color: #ffffff !important;
	box-shadow: 0 0 0 2px rgba(22, 163, 74, 0.12) !important;
}
.tkb-note-native-input:disabled {
	background-color: #f8fafc !important;
	color: #94a3b8 !important;
	border-color: #f1f5f9 !important;
	cursor: not-allowed !important;
	opacity: 0.75 !important;
}
</style>

<style>
.compact-table-textarea,
.compact-table-textarea .v-field,
.compact-table-textarea .v-field__field,
.compact-table-textarea .v-field__input,
.compact-table-textarea textarea,
.compact-table-textarea input {
	font-size: 13px !important;
	line-height: 1.4 !important;
}

.compact-table-textarea textarea::placeholder,
.compact-table-textarea input::placeholder,
.compact-table-textarea .v-field__input::placeholder,
.compact-table-textarea ::placeholder {
	font-size: 13px !important;
	line-height: 1.4 !important;
	opacity: 0.65 !important;
}

/* Hỗ trợ cuộn ngang mượt mà cho thanh chọn tuần trên Mobile */
.week-toggle-scroll-wrapper {
	overflow-x: auto !important;
	overflow-y: hidden !important;
	-webkit-overflow-scrolling: touch !important;
	touch-action: pan-x !important;
	width: 100% !important;
	padding-bottom: 2px !important;
}
.week-toggle-scroll-wrapper::-webkit-scrollbar {
	height: 3px;
}
.week-toggle-scroll-wrapper::-webkit-scrollbar-thumb {
	background: #cbd5e1;
	border-radius: 4px;
}
</style>