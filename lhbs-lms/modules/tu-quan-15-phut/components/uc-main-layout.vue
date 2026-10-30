<template>
	<div class="uc-tu-quan-15-phut pa-2 pa-sm-3">
		<!-- Header Card Tinh Gọn (Single Modern Card, không border thô) -->
		<v-card class="mb-3 bg-white" elevation="0" rounded="lg" style="border: 1px solid #f1f5f9;">
			<!-- Dòng 1: Tiêu đề + Bộ lọc Tuần & Khối + Nút thao tác -->
			<div class="px-3 px-sm-4 py-2 d-flex align-center justify-space-between flex-nowrap ga-2 border-b" style="border-bottom-color: #f8fafc !important;">
				<!-- Khối Trái: Icon + Tiêu đề + Bộ chọn Tuần & Khối -->
				<div class="d-flex align-center flex-nowrap ga-2 ga-sm-3 flex-grow-1" style="min-width: 0;">
					<div class="d-flex align-center ga-2 flex-shrink-0">
						<v-icon size="20" color="primary">mdi-clock-check-outline</v-icon>
						<div>
							<div class="font-weight-bold text-subtitle-2 text-grey-darken-4" style="line-height: 1.2; font-size: 14px;">
								15 Phút Tự Quản
							</div>
							<div class="text-caption text-medium-emphasis d-none d-md-block" style="font-size: 10.5px; line-height: 1;">
								7:15 – 7:30 · Năm học 2026 - 2027
							</div>
						</div>
					</div>

					<!-- Bộ chọn Tuần (Thời khóa biểu) hiển thị đầy đủ, không bị cắt dấu ba chấm -->
					<div class="d-flex align-center ga-0.5 week-selector-wrap" style="width: 375px; min-width: 340px; flex-shrink: 0;">
						<v-btn icon="mdi-chevron-left" variant="text" density="compact" size="small" :disabled="selectedWeekIndex <= 0" @click="prevWeek" />
						<v-select
							v-model="selectedWeek"
							:items="availableWeekList"
							item-title="title"
							item-value="id"
							return-object
							density="compact"
							variant="outlined"
							color="primary"
							hide-details
							prepend-inner-icon="mdi-calendar-range"
							class="compact-filter-select flex-grow-1"
							style="font-size: 11.5px;"
							@update:model-value="onWeekSelected"
						/>
						<v-btn icon="mdi-chevron-right" variant="text" density="compact" size="small" :disabled="selectedWeekIndex >= availableWeekList.length - 1" @click="nextWeek" />
					</div>

					<!-- Bộ chọn Khối lớp (chỉ hiện khi ở tab Quản sinh hoặc Báo cáo, VÀ không phải là tài khoản chỉ có quyền GVCN) -->
					<div v-if="!isGVCNRole && activeTab !== 'gvcn'" style="width: 95px;" class="flex-shrink-0">
						<v-select
							v-model="selectedKhoi"
							:items="khoiList"
							item-title="name"
							item-value="id"
							density="compact"
							variant="outlined"
							hide-details
							class="compact-filter-select"
							style="font-size: 11.5px;"
							@update:model-value="onFilterChanged"
						/>
					</div>
				</div>

				<!-- Khối Phải: Nút Làm mới & Menu đổi vai trò -->
				<div class="d-flex align-center ga-1 ms-auto flex-shrink-0">
					<v-btn icon="mdi-refresh" variant="text" size="small" color="grey-darken-2" :loading="isLoading" @click="reloadData" title="Làm mới dữ liệu" />

					<!-- Chip vai trò kèm menu đổi vai trò kiểm tra phân quyền (chỉ hiện khi là Admin) -->
					<v-menu v-if="canSwitchRole" location="bottom end">
						<template v-slot:activator="{ props }">
							<v-chip
								v-bind="props"
								:color="currentRoleColor"
								size="small"
								:prepend-icon="currentRoleIcon"
								append-icon="mdi-menu-down"
								class="font-weight-medium text-white cursor-pointer px-2.5"
								variant="flat"
								title="Nhấn để đổi vai trò kiểm tra phân quyền"
							>
								{{ currentRoleName }}
							</v-chip>
						</template>
						<v-card min-width="260" class="pa-2 rounded-lg" elevation="4">
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
										<v-avatar size="26" :color="r.color" class="text-white me-2">
											<v-icon size="15" color="white">{{ r.icon }}</v-icon>
										</v-avatar>
									</template>
									<v-list-item-title class="font-weight-medium" style="font-size: 12.5px;">
										{{ r.name }}
									</v-list-item-title>
									<v-list-item-subtitle style="font-size: 10.5px;">
										{{ r.description }}
									</v-list-item-subtitle>
								</v-list-item>
							</v-list>
						</v-card>
					</v-menu>
				</div>
			</div>

			<!-- Dòng 2: Tabs chức năng (Quản sinh / GVCN / Báo cáo) - Chỉ hiện khi có từ 2 tab trở lên -->
			<v-tabs
				v-if="hasMultipleTabs"
				:key="'tabs-' + currentSystemRight"
				v-model="activeTab"
				color="primary"
				density="compact"
				class="border-b px-2"
				style="min-height: 40px;"
			>
				<v-tab v-if="canAccessQuanSinh" value="quansinh" class="text-none font-weight-medium px-3 text-caption text-sm-body-2" style="height: 40px;">
					<v-icon start size="16" class="me-1">mdi-clipboard-check-outline</v-icon>
					Quản sinh chấm điểm
					<v-badge v-if="pendingCheckCount > 0" color="warning" :content="pendingCheckCount" inline class="ms-1" />
				</v-tab>
				<v-tab v-if="canAccessGvcn" value="gvcn" class="text-none font-weight-medium px-3 text-caption text-sm-body-2" style="height: 40px;">
					<v-icon start size="16" class="me-1">mdi-calendar-clock-outline</v-icon>
					GVCN đăng kí lịch
				</v-tab>
				<v-tab v-if="canAccessBaoCao" value="baocao" class="text-none font-weight-medium px-3 text-caption text-sm-body-2" style="height: 40px;">
					<v-icon start size="16" class="me-1">mdi-chart-box-outline</v-icon>
					Báo cáo & thi đua
				</v-tab>
			</v-tabs>

			<!-- Dòng 3: Thanh chọn Ngày Thứ 2 - Thứ 6 (Chỉ hiện khi ở Tab Quản sinh) -->
			<div v-if="activeTab === 'quansinh'" class="px-3 px-sm-4 py-2 bg-grey-lighten-5">
				<v-btn-toggle
					v-model="selectedDay"
					mandatory
					variant="text"
					class="w-100 d-flex clean-days-toggle"
					style="height: auto !important; min-height: 48px !important;"
					@update:model-value="onDayChanged"
				>
					<v-btn
						v-for="d in daysOfWeek"
						:key="d.val"
						:value="d.val"
						class="text-none flex-grow-1 px-1 clean-day-btn"
						style="flex: 1 1 0% !important; min-width: 0 !important; height: 100% !important; min-height: 44px !important;"
					>
						<div class="text-center py-0.5 w-100 d-flex flex-column justify-center align-center">
							<div class="d-flex align-center justify-center ga-1" style="line-height: 1.2;">
								<span class="font-weight-bold d-none d-sm-inline" style="font-size: 13px;">{{ d.label }}</span>
								<span class="font-weight-bold d-inline d-sm-none" style="font-size: 13px;">T{{ d.val }}</span>
								<v-icon
									v-if="isSpecificDayInPast(d.val)"
									size="12"
									:color="selectedDay === d.val ? 'white' : 'blue-grey-darken-1'"
									title="Đã qua ngày"
								>mdi-lock-outline</v-icon>
								<v-icon
									v-else-if="isSpecificDayToday(d.val)"
									size="12"
									:color="selectedDay === d.val ? 'white' : 'green-darken-3'"
									:title="isPastQsCutoffTime() ? 'Hôm nay (Đã khóa sau 09:30)' : 'Hôm nay (Đang mở)'"
								>{{ isPastQsCutoffTime() ? 'mdi-lock-clock' : 'mdi-pencil' }}</v-icon>
								<v-icon
									v-else-if="isSpecificDayInFuture(d.val)"
									size="12"
									:color="selectedDay === d.val ? 'white' : 'grey-darken-1'"
									title="Chưa đến ngày (Xem trước & in phiếu)"
								>mdi-clock-outline</v-icon>
							</div>
							<div class="d-flex align-center justify-center ga-1 mt-0.5 text-caption" style="font-size: 10.5px; line-height: 1.1;">
								<span class="clean-day-date">{{ d.date }}</span>
								<span v-if="isSpecificDayToday(d.val)" :class="selectedDay === d.val ? 'day-today-badge-active' : 'day-today-badge'">(Nay)</span>
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
				<!-- Action Toolbar Quản sinh: Phẳng, Tinh giản, Không lồng Card -->
				<div class="mb-3 d-flex align-center justify-space-between flex-wrap ga-2 text-caption">
					<!-- Trái: Tóm tắt trạng thái ngày (text thanh lịch, 1 chip trạng thái mỏng) -->
					<div class="d-flex align-center ga-2 flex-wrap">
						<span class="font-weight-bold text-grey-darken-4 text-subtitle-2">
							{{ currentDayLabel }}
						</span>
						<v-chip
							v-if="isReadOnlyDay"
							size="x-small"
							:color="isTodayQsLocked ? 'amber-darken-3' : (isPastDay ? 'blue-grey' : 'grey')"
							variant="tonal"
							class="font-weight-medium"
						>
							<v-icon start size="12">{{ isPastDay || isTodayQsLocked ? 'mdi-lock-outline' : 'mdi-clock-outline' }}</v-icon>
							{{ isPastDay ? 'Đã khóa' : (isTodayQsLocked ? 'Khóa sau 09:30' : 'Chưa đến ngày') }}
						</v-chip>
						<span class="text-medium-emphasis">·</span>
						<span v-if="selectedDay === 2" class="text-medium-emphasis">
							Thứ Hai: GVCN sinh hoạt toàn trường
						</span>
						<span v-else class="text-medium-emphasis">
							<strong class="text-success font-weight-bold">{{ tuQuanClassesCount }}/{{ currentClasses.length }}</strong> lớp tự quản
							<span v-if="gvcnSinHoatCount > 0" class="d-none d-sm-inline"> · <strong>{{ gvcnSinHoatCount }}</strong> GVCN sinh hoạt</span>
						</span>
					</div>

					<!-- Phải: Nút hành động chính & Trạng thái tự lưu -->
					<div class="d-flex align-center ga-1.5 ms-auto">
						<!-- Trạng thái tự động lưu dạng dot tinh tế thay vì chip to -->
						<div v-if="!isBghRole" class="d-flex align-center ga-1 me-2 text-grey-darken-2" style="font-size: 11.5px;">
							<template v-if="qsAutoSaveStatus === 'saving'">
								<v-progress-circular indeterminate size="10" width="1.5" color="warning" class="me-1" />
								<span class="text-warning font-weight-medium">Đang lưu...</span>
							</template>
							<template v-else>
								<span class="status-dot-green"></span>
								<span class="font-weight-medium text-success-darken-2">Đã tự lưu</span>
								<span v-if="qsLastSavedTime" class="text-medium-emphasis ms-0.5" style="font-size: 10.5px;">({{ qsLastSavedTime }})</span>
							</template>
						</div>

						<v-btn
							v-if="!isBghRole"
							size="small"
							color="teal-darken-1"
							variant="tonal"
							prepend-icon="mdi-check-all"
							class="text-none font-weight-medium"
							@click="markAllGood"
						>
							Tất cả Đạt
						</v-btn>

						<v-btn
							size="small"
							variant="outlined"
							color="grey-darken-3"
							prepend-icon="mdi-printer"
							class="text-none font-weight-medium"
							@click="openPrintDialog('daily')"
						>
							In phiếu
						</v-btn>

						<v-menu location="bottom end">
							<template #activator="{ props }">
								<v-btn v-bind="props" icon="mdi-dots-vertical" size="small" variant="text" color="grey-darken-3" />
							</template>
							<v-list density="compact" rounded="lg">
								<v-list-item v-if="canModifyCriteria" prepend-icon="mdi-plus" title="Thêm tiêu chí" @click="openAddCriteriaDialog(null)" />
								<v-list-item prepend-icon="mdi-share-variant-outline" title="Gửi Zalo" @click="exportDailyReport" />
								<template v-if="isDevOrAdminRole">
									<v-divider class="my-1" />
									<v-list-subheader class="text-caption font-weight-bold text-uppercase" style="font-size: 10px; height: 26px;">Giả lập quy định khóa (Dev / Test)</v-list-subheader>
									<v-list-item
										prepend-icon="mdi-clock-outline"
										title="Thời gian thực tế hệ thống"
										:active="mockDateOverride === null && mockHourOverride === null"
										@click="setMockDateAndHour(null, null)"
									/>
									<v-list-item
										prepend-icon="mdi-lock-open-outline"
										title="Sáng Thứ Hai (09:00 - Mở đăng ký tuần cho GVCN)"
										:active="mockScenarioName === 'monday_morning'"
										@click="setMockDateAndHour('monday_morning', 9)"
									/>
									<v-list-item
										prepend-icon="mdi-lock-outline"
										title="Thứ Ba - Thứ Sáu (Khóa đăng ký GVCN, Mở QS chấm)"
										:active="mockScenarioName === 'midweek_morning' && mockHourOverride === 8"
										@click="setMockDateAndHour('midweek_morning', 8)"
									/>
									<v-list-item
										prepend-icon="mdi-clock-alert-outline"
										title="Sau 09:30 sáng (10:00 - Khóa Quản sinh nhập điểm)"
										:active="mockHourOverride === 10"
										@click="setMockDateAndHour('midweek_morning', 10)"
									/>
								</template>
							</v-list>
						</v-menu>
					</div>
				</div>

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
									<th style="width: 200px; min-width: 190px; text-align: left; padding: 6px 12px;">Lớp & GVCN</th>
									<th
										v-for="(tc, i) in getMergedPrintCriteria()"
										:key="'tbl-th-' + tc.id"
										style="text-align: center; padding: 6px 3px; width: 130px; min-width: 118px; max-width: 145px; position: relative;"
										:class="{ 'bg-blue-lighten-5': tc.isCustom }"
									>
										<!-- Nút Xóa tiêu chí bổ sung -->
										<v-tooltip v-if="tc.isCustom && canModifyCriteria" text="Xóa tiêu chí này" location="top">
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
														{{ 'TC' + (i + 1) + ': ' + getCriterionMainTitle(tc.ten) }}
													</div>
													<div v-if="getCriterionSubTitle(tc.ten)" class="text-grey-darken-2 text-center px-0.5 mt-0.5" style="font-size: 10px; line-height: 1.2; font-weight: 500;">
														{{ getCriterionSubTitle(tc.ten) }}
													</div>
												</div>
											</template>
											<span><strong>{{ 'TC' + (i + 1) + ': ' + getCriterionMainTitle(tc.ten) }}</strong> {{ getCriterionSubTitle(tc.ten) }}</span>
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
									<!-- Cột Lớp & GVCN & Trạng thái ngày -->
									<td style="padding: 6px 12px; width: 200px; min-width: 190px;">
										<div class="d-flex flex-column justify-center" style="min-width: 175px;">
											<!-- Dòng 1: Tên lớp + Badge trạng thái (Phân biệt 3 màu trực quan) -->
											<div class="d-flex align-center justify-space-between ga-1">
												<span class="font-weight-bold text-subtitle-2 text-primary" style="font-size: 14.5px; line-height: 22px;">{{ cls.TenLop }}</span>
												
												<!-- Thứ 2: Toàn trường GVCN sinh hoạt -->
												<v-chip
													v-if="selectedDay === 2"
													size="x-small"
													color="blue-grey-lighten-2"
													variant="tonal"
													class="font-weight-medium text-blue-grey-darken-3 px-1.5"
													style="height: 20px; font-size: 11px;"
												>
													<v-icon start size="12">mdi-account-tie</v-icon>
													GVCN sinh hoạt
												</v-chip>

												<!-- Thứ 3 - Thứ 6: Trạng thái ngày -->
												<template v-else>
													<!-- 1. Quản sinh đã ghi nhận GVCN có mặt (Mã GV) -->
													<v-chip
														v-if="cls.GVCNCoMat"
														size="x-small"
														color="blue-grey-darken-2"
														variant="flat"
														class="font-weight-bold text-white px-2"
														style="height: 20px; font-size: 11px;"
													>
														<v-icon start size="12" color="white">mdi-account-check</v-icon>
														GV có mặt (GV)
													</v-chip>

													<!-- 2. Lớp đang Tự quản: Badge xanh lá Tự quản -->
													<v-chip
														v-else-if="cls.IsTuQuan"
														size="x-small"
														color="success"
														variant="tonal"
														class="font-weight-bold px-2"
														style="height: 20px; font-size: 11px;"
													>
														<v-icon start size="11" color="success">mdi-shield-check</v-icon>
														Lớp tự quản
													</v-chip>

													<!-- 3. Lớp không đăng ký tự quản: GVCN sinh hoạt cố định -->
													<v-chip
														v-else
														size="x-small"
														color="grey-lighten-1"
														variant="tonal"
														class="font-weight-medium text-grey-darken-3 px-1.5"
														style="height: 20px; font-size: 11px;"
													>
														<v-icon start size="12" color="grey-darken-2">mdi-account-tie</v-icon>
														GVCN sinh hoạt
													</v-chip>
												</template>
											</div>

											<!-- Dòng 2: Tên GVCN + Nút thao tác của Quản sinh (Cố định, không rớt dòng) -->
											<div class="d-flex align-center justify-space-between mt-1 ga-1" style="white-space: nowrap;">
												<div
													class="text-caption text-truncate text-medium-emphasis"
													:title="cls.TenGVCN"
													style="max-width: 105px; font-size: 11.5px; line-height: 1.2;"
												>
													{{ cls.TenGVCN }}
												</div>

												<!-- Nút thao tác nhanh Quản sinh -->
												<template v-if="selectedDay !== 2 && !isReadOnlyDay">
													<!-- Khi lớp đang tự quản: Nút bấm để ghi nhận GV có mặt -->
													<v-btn
														v-if="cls.IsTuQuan && !cls.GVCNCoMat"
														size="x-small"
														variant="flat"
														color="blue-grey-lighten-4"
														class="text-blue-grey-darken-4 font-weight-bold text-none px-1.5"
														style="height: 20px; font-size: 10.5px; border: 1px solid #b0bec5;"
														prepend-icon="mdi-account-check"
														title="Bấm khi GVCN có mặt tại lớp lúc 07:15"
														@click="toggleGvcnPresent(cls)"
													>
														GV có mặt
													</v-btn>

													<!-- Khi đã báo GV: Nút hoàn tác để đổi lại nếu bấm nhầm -->
													<v-btn
														v-else-if="cls.GVCNCoMat"
														size="x-small"
														variant="text"
														color="primary"
														class="font-weight-bold text-none px-1"
														style="height: 20px; font-size: 10.5px;"
														prepend-icon="mdi-undo"
														title="Bấm để hoàn tác lại thành Lớp tự quản"
														@click="toggleGvcnPresent(cls)"
													>
														Đổi lại
													</v-btn>
												</template>
											</div>
										</div>
									</td>

									<!-- Các cột Tiêu chí -->
									<td
										v-for="(tc, i) in getMergedPrintCriteria()"
										:key="'tbl-tc-' + cls.LopID + '-' + tc.id"
										style="text-align: center; padding: 4px 2px; width: 130px; min-width: 118px; max-width: 145px;"
									>
										<div v-if="!cls.IsTuQuan" class="text-medium-emphasis font-weight-medium" style="font-size: 12px;">
											—
										</div>
										<div v-else-if="isClassHavingCriteria(cls, tc)" class="d-inline-flex justify-center w-100">
											<div class="score-group">
												<button
													type="button"
													class="score-btn-item score-btn-d"
													:class="{ 'score-active-d': findClassCriterion(cls, tc).score !== 1 }"
													title="Đạt"
													@click="setCriterionScore(cls, tc, 2)"
												>
													Đ
												</button>
												<button
													type="button"
													class="score-btn-item score-btn-cd"
													:class="{ 'score-active-cd': findClassCriterion(cls, tc).score === 1 }"
													title="Chưa đạt"
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
											:placeholder="!cls.IsTuQuan ? 'GVCN có mặt (Không chấm tự quản)...' : 'Nhập ghi chú / nội dung vi phạm...'"
											density="compact"
											variant="plain"
											hide-details
											auto-grow
											rows="1"
											max-rows="4"
											:disabled="!cls.IsTuQuan"
											class="compact-table-textarea"
											:class="{ 'opacity-60': !cls.IsTuQuan }"
											style="font-size: 13px !important;"
											:input-attrs="{ style: 'font-size: 13px !important; line-height: 1.4 !important;' }"
											@update:model-value="onQsNoteChange"
										/>
									</td>

									<!-- Cột Xếp loại -->
									<td style="text-align: center; padding: 4px;">
										<span
											v-if="!cls.IsTuQuan || getClassDailyResult(cls).code === 'GVCN'"
											class="table-rank-badge rank-gvcn font-weight-bold"
										>
											{{ selectedDay === 2 && !cls.IsTuQuan ? 'Chào cờ' : 'Không chấm' }}
										</span>
										<span
											v-else
											class="table-rank-badge"
											:class="{
												'rank-dat': getClassDailyResult(cls).code === 'D',
												'rank-ccg': getClassDailyResult(cls).code === 'CCG',
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
						<!-- Header Thẻ: Lớp, GVCN & Xếp loại (Cấu trúc 2 tầng thoáng đãng, không bị chèn ép) -->
						<div class="px-3 py-2.5 bg-grey-lighten-5 border-b">
							<!-- Tầng 1: STT + Tên lớp & Badge Xếp loại ngày -->
							<div class="d-flex align-center justify-space-between">
								<div class="d-flex align-center ga-2">
									<v-avatar color="primary" size="24" class="text-white text-caption font-weight-bold">
										{{ idx + 1 }}
									</v-avatar>
									<span class="font-weight-bold text-subtitle-1 text-primary" style="font-size: 15px !important; line-height: 1.2;">
										{{ cls.TenLop }}
									</span>
								</div>

								<!-- Badge xếp loại trên Mobile Card -->
								<div>
									<span v-if="selectedDay === 2" class="text-medium-emphasis font-weight-medium text-caption">—</span>
									<span
										v-else-if="cls.GVCNCoMat"
										class="table-rank-badge rank-gvcn font-weight-bold"
										style="font-size: 11px;"
									>
										Không chấm
									</span>
									<span
										v-else-if="!cls.IsTuQuan"
										class="text-medium-emphasis font-weight-medium text-caption"
									>
										—
									</span>
									<span
										v-else
										class="table-rank-badge"
										:class="{
											'rank-dat': getClassDailyResult(cls).code === 'D',
											'rank-ccg': getClassDailyResult(cls).code === 'CCG',
											'rank-chuadat': getClassDailyResult(cls).code === 'CD'
										}"
									>
										{{ getScoreBadgeText(cls) }}
									</span>
								</div>
							</div>

							<!-- Tầng 2: Tên GVCN & Badge trạng thái + Nút GV có mặt -->
							<div class="d-flex align-center justify-space-between mt-2 pt-1.5 border-t border-grey-lighten-3">
								<div class="text-caption text-grey-darken-2" style="font-size: 11.5px;">
									GVCN: <span class="font-weight-medium text-grey-darken-3">{{ cls.TenGVCN }}</span>
								</div>

								<div class="d-flex align-center ga-1.5 flex-shrink-0">
									<span
										v-if="selectedDay === 2"
										class="table-status-badge badge-gvcn"
										style="height: 22px; font-size: 10.5px;"
									>
										<v-icon size="12" class="me-0.5" color="blue-grey-darken-2">mdi-account-tie</v-icon>
										GVCN sinh hoạt
									</span>
									<template v-else>
										<!-- Khi đã ghi nhận GVCN có mặt -->
										<v-chip
											v-if="cls.GVCNCoMat"
											size="x-small"
											color="blue-grey-darken-2"
											variant="flat"
											class="font-weight-bold text-white px-2"
											style="height: 22px; font-size: 10.5px;"
										>
											<v-icon start size="12" color="white">mdi-account-check</v-icon>
											GV có mặt (GV)
										</v-chip>

										<!-- Khi đang Tự quản: Badge Tự quản + Nút GV có mặt -->
										<template v-else-if="cls.IsTuQuan">
											<v-chip
												size="x-small"
												color="success"
												variant="tonal"
												class="font-weight-bold px-2"
												style="height: 22px; font-size: 10.5px;"
											>
												<v-icon start size="12" color="success">mdi-shield-check</v-icon>
												Tự quản
											</v-chip>
											<v-btn
												v-if="!isReadOnlyDay"
												size="x-small"
												variant="flat"
												color="blue-grey-lighten-4"
												class="text-blue-grey-darken-4 font-weight-bold text-none px-2"
												style="height: 22px; font-size: 10.5px; border: 1px solid #b0bec5;"
												prepend-icon="mdi-account-check"
												@click="toggleGvcnPresent(cls)"
											>
												GV có mặt
											</v-btn>
										</template>

										<!-- Lớp không đăng ký tự quản -->
										<v-chip
											v-else
											size="x-small"
											color="grey-lighten-1"
											variant="tonal"
											class="font-weight-medium text-grey-darken-3 px-2"
											style="height: 22px; font-size: 10.5px;"
										>
											<v-icon start size="12" color="grey-darken-2">mdi-account-tie</v-icon>
											GVCN sinh hoạt
										</v-chip>
									</template>
								</div>
							</div>
						</div>

						<!-- Nội dung chấm điểm trên Mobile -->
						<div class="pa-3">
							<!-- Nếu GVCN sinh hoạt / Thứ 2 / GVCN có mặt: Thông báo ngắn gọn -->
							<div v-if="selectedDay === 2 || !cls.IsTuQuan || cls.GVCNCoMat" class="pa-2.5 rounded-lg bg-blue-grey-lighten-5 border border-blue-grey-lighten-4 d-flex align-center justify-space-between flex-wrap ga-2 text-caption text-blue-grey-darken-3">
								<div class="d-flex align-center">
									<v-icon size="16" color="blue-grey-darken-2" class="me-1.5">mdi-account-tie</v-icon>
									<span>
										{{ selectedDay === 2 ? 'Thứ Hai: Tiết sinh hoạt đầu tuần cùng GVCN' : (cls.GVCNCoMat ? 'Quản sinh ghi nhận: GVCN có mặt tại lớp (Mã "GV")' : 'Lớp không đăng ký tự quản — GVCN sinh hoạt trực tiếp') }}
									</span>
								</div>
								<v-btn
									v-if="cls.GVCNCoMat && selectedDay !== 2 && !isReadOnlyDay"
									size="x-small"
									variant="text"
									color="primary"
									class="text-none px-1 font-weight-bold"
									@click="toggleGvcnPresent(cls)"
								>
									Đổi sang Tự quản
								</v-btn>
							</div>

							<!-- Nếu lớp tự quản: Hiển thị từng tiêu chí bấm Đ - CĐ dạng Segmented Control bo đều, dễ chạm -->
							<div v-else class="d-flex flex-column ga-2">
								<div
									v-for="(tc, i) in getMergedPrintCriteria()"
									:key="'m-tc-' + cls.LopID + '-' + tc.id"
									class="pa-2.5 rounded-lg bg-grey-lighten-5 d-flex align-center justify-space-between ga-2 border border-grey-lighten-3"
								>
									<div class="flex-grow-1 pe-2">
										<div class="font-weight-medium text-grey-darken-4 text-caption" style="line-height: 1.35; font-size: 12.5px;">
											{{ 'TC' + (i + 1) + ': ' + getCriterionMainTitle(tc.ten) }}
										</div>
										<div v-if="getCriterionSubTitle(tc.ten)" class="text-caption text-grey-darken-1 mt-0.5" style="font-size: 10.5px; line-height: 1.25;">
											{{ getCriterionSubTitle(tc.ten) }}
										</div>
									</div>

									<!-- Nút bấm điểm Đ - CĐ dạng Segmented Control Pill -->
									<div class="mobile-score-group flex-shrink-0">
										<button
											type="button"
											class="mobile-score-btn mobile-score-btn-d"
											:class="{ 'active': findClassCriterion(cls, tc).score !== 1 }"
											title="Đạt"
											@click="setCriterionScore(cls, tc, 2)"
										>
											Đ
										</button>
										<button
											type="button"
											class="mobile-score-btn mobile-score-btn-cd"
											:class="{ 'active': findClassCriterion(cls, tc).score === 1 }"
											title="Chưa đạt"
											@click="setCriterionScore(cls, tc, 1)"
										>
											CĐ
										</button>
									</div>
								</div>

								<!-- Ô nhận xét / ghi chú vi phạm trên Mobile -->
								<div class="mt-2">
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
				<v-card class="mb-3 pa-3" elevation="0" rounded="lg" style="border: 1px solid #f1f5f9 !important; background: #ffffff;">
					<!-- Dòng 1: Thông tin lớp & Dropdown đổi lớp & Nút lưu -->
					<div class="d-flex align-center justify-space-between flex-wrap ga-2 pb-2.5 mb-2.5" style="border-bottom: 1px solid #f1f5f9 !important;">
						<!-- Trái: Tên lớp, GVCN -->
						<div class="d-flex align-center flex-wrap" style="gap: 12px;">
							<v-avatar size="32" rounded="lg" style="background: #f1f5f9;">
								<v-icon color="teal-darken-1" size="18">mdi-google-classroom</v-icon>
							</v-avatar>
							<div>
								<div class="d-flex align-center flex-wrap ga-2">
									<span class="font-weight-bold" style="font-size: 15px !important; color: #1e293b; line-height: 1.2;">
										Lớp {{ gvcnClassInfo.TenLop }}
									</span>
								</div>
								<div class="text-caption text-medium-emphasis" style="font-size: 11.5px !important;">
									GVCN: <span class="text-grey-darken-3 font-weight-medium">{{ gvcnClassInfo.TenGVCN }}</span> · Sĩ số: <span class="font-weight-medium">{{ gvcnClassInfo.SiSo }} học sinh</span>
								</div>
							</div>
						</div>

						<!-- Phải: Dropdown đổi lớp (chỉ hiện khi là Quản sinh/BGH/Admin) & Badge -->
						<div class="d-flex align-center ga-2 flex-wrap w-100 w-sm-auto justify-space-between justify-sm-end">
							<!-- Dropdown đổi lớp: Tuyệt đối không hiển thị cho role GVCN (kể cả Admin đang test role GVCN) -->
							<div v-if="showClassSelectorOnGvcn" class="flex-grow-1 flex-sm-grow-0" style="min-width: 220px; max-width: 100%;">
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

							<!-- Nhóm Badge số buổi & Trạng thái Tự động lưu -->
							<div class="d-flex align-center ga-2 flex-wrap flex-grow-1 flex-sm-grow-0 justify-space-between justify-sm-end w-100 w-sm-auto">
								<v-chip
									:color="gvcnTargetMet ? 'success' : 'warning'"
									size="small"
									variant="tonal"
									class="font-weight-medium px-2.5 rounded-pill flex-grow-1 flex-sm-grow-0 justify-center"
									style="font-size: 11.5px; height: 26px;"
								>
									<v-icon start size="13">{{ gvcnTargetMet ? 'mdi-check-circle' : 'mdi-alert-circle' }}</v-icon>
									Tự quản: {{ gvcnTuQuanCount }}/4 ngày {{ gvcnTargetMet ? '(đạt ≥ 2)' : '(cần ≥ 2)' }}
								</v-chip>

								<!-- Trạng thái: Đã khóa đăng ký tuần (Từ T3 đến T6) HOẶC Trạng thái tự động lưu -->
								<v-chip
									v-if="isGvcnRegistrationLockedForSelectedWeek()"
									color="blue-grey"
									size="small"
									variant="tonal"
									class="font-weight-medium px-2.5 rounded-pill flex-grow-1 flex-sm-grow-0 justify-center"
									style="font-size: 11.5px; height: 26px;"
								>
									<v-icon start size="13">mdi-lock-outline</v-icon>
									<span class="font-weight-medium">Đã khóa đăng ký (T3 - T6)</span>
								</v-chip>
								<v-chip
									v-else
									:color="autoSaveStatus === 'saving' ? 'amber-darken-3' : 'success'"
									size="small"
									variant="tonal"
									class="font-weight-medium px-2.5 rounded-pill flex-grow-1 flex-sm-grow-0 justify-center"
									style="font-size: 11.5px; height: 26px; transition: all 0.25s ease;"
								>
									<template v-if="autoSaveStatus === 'saving'">
										<v-progress-circular indeterminate size="10" width="2" color="amber-darken-3" class="me-1" />
										<span class="font-weight-medium">Đang lưu...</span>
									</template>
									<template v-else>
										<v-icon start size="13" color="success">mdi-cloud-check-outline</v-icon>
										<span class="font-weight-medium">Đã lưu tự động</span>
										<span v-if="lastSavedTime" class="ms-1 text-caption text-grey-darken-1" style="font-size: 10px;">({{ lastSavedTime }})</span>
									</template>
								</v-chip>
							</div>
						</div>
					</div>

					<!-- Thông báo quy định thời gian đăng ký tuần (Clean minimal callout) -->
					<div class="px-3 py-2 mb-2.5 d-flex align-center justify-space-between flex-wrap ga-2" style="background: #f8fafc; border-left: 3px solid #94a3b8; border-radius: 0 6px 6px 0; font-size: 11.5px; line-height: 1.45; color: #475569;">
						<div class="d-flex align-center ga-2">
							<v-icon size="15" color="blue-grey-darken-1">mdi-clock-lock-outline</v-icon>
							<span><strong>Quy định:</strong> Mở đăng ký từ <strong>T7 tuần trước đến hết sáng T2</strong>. Khóa tự động từ <strong>T3 đến hết T6</strong>. Ngày không tự quản, GVCN sinh hoạt trực tiếp cùng lớp.</span>
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
					<div class="mb-3 rounded-lg overflow-hidden bg-white" style="border: 1px solid #f1f5f9 !important;">
						<!-- Tiêu đề các ngày trong tuần (TKB Header) -->
						<div class="d-flex text-center" style="background-color: #f8fafc; border-bottom: 1px solid #f1f5f9 !important;">
							<div
								v-for="day in gvcnWeekSchedule"
								:key="'tkb-head-' + day.key"
								class="flex-grow-1 py-1.5 px-0.5"
								:class="{
									'text-grey-darken-4 font-weight-bold': day.key === 2,
									'text-success font-weight-medium': day.key !== 2 && day.IsTuQuan,
									'text-grey-darken-3 font-weight-medium': day.key !== 2 && !day.IsTuQuan
								}"
								:style="day.key === 2 ? 'flex-basis: 0; min-width: 0; border-right: 1px solid #cbd5e1; background-color: #e2e8f0;' : 'flex-basis: 0; min-width: 0; border-right: 1px solid #f1f5f9;'"
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
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center tkb-monday-cell"
									style="flex-basis: 0; min-width: 0; cursor: not-allowed; user-select: none; border-right: 1px solid #cbd5e1;"
									title="Thứ 2: Bắt buộc toàn trường GVCN sinh hoạt đầu tuần"
									@click="showNotice('Thứ Hai bắt buộc GVCN sinh hoạt đầu tuần toàn trường, không áp dụng tự quản!', 'info')"
								>
									<div class="d-flex align-center ga-0.5 text-grey-darken-3 font-weight-medium" style="font-size: 11px; line-height: 1.2;">
										<v-icon size="12" color="grey-darken-2">mdi-lock</v-icon>
										<span class="d-none d-sm-inline">GVCN sinh hoạt</span>
										<span class="d-inline d-sm-none">GVCN</span>
									</div>
									<div class="text-caption text-grey-darken-1 mt-0.5 d-none d-sm-block font-weight-medium" style="font-size: 9.5px; line-height: 1;">
										(Cố định)
									</div>
								</div>

								<!-- 2. TUẦN ĐÃ KHÓA ĐĂNG KÝ (KHÓA TỪ THỨ BA ĐẾN HẾT THỨ SÁU HOẶC QUÁ HẠN SÁNG THỨ HAI) -->
								<div
									v-else-if="isGvcnRegistrationLockedForSelectedWeek()"
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center tkb-stripe-disabled"
									style="flex-basis: 0; min-width: 0; cursor: not-allowed; user-select: none; border-right: 1px solid #f1f5f9;"
									:title="getGvcnLockReasonMessage()"
									@click="showNotice(getGvcnLockReasonMessage(), 'warning')"
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

								<!-- 2.5 LỚP ĐANG DÍNH CHẾ TÀI -->
								<div
									v-else-if="isClassBlocked(selectedGvcnClassId)"
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center bg-red-lighten-5 cursor-not-allowed"
									style="flex-basis: 0; min-width: 0; user-select: none; border-right: 1px solid #f1f5f9;"
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
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center tkb-cell-registered cursor-pointer transition-all"
									style="flex-basis: 0; min-width: 0; user-select: none; border-right: 1px solid #f1f5f9;"
									title="Bấm để chuyển về GVCN sinh hoạt"
									@click="toggleGvcnDay(day)"
								>
									<div class="d-flex align-center ga-0.5 text-success font-weight-medium" style="font-size: 11px; line-height: 1.2;">
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
									class="flex-grow-1 py-1 px-0.5 d-flex flex-column align-center justify-center tkb-cell-available cursor-pointer transition-all"
									style="flex-basis: 0; min-width: 0; user-select: none; border-right: 1px solid #f1f5f9;"
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
						<div class="d-flex text-center" style="background-color: #fafbfc; border-top: 1px solid #f1f5f9 !important;">
							<div
								v-for="day in gvcnWeekSchedule"
								:key="'tkb-note-' + day.key"
								class="flex-grow-1 py-1 px-1 tkb-note-cell d-flex align-center justify-center"
								:class="{ 'tkb-monday-note-cell': day.key === 2, 'tkb-stripe-disabled': day.key !== 2 && isDayGvcnLocked(day.key) }"
								:style="day.key === 2 ? 'flex-basis: 0; min-width: 0; border-right: 1px solid #cbd5e1; background-color: #e2e8f0;' : 'flex-basis: 0; min-width: 0; border-right: 1px solid #f1f5f9;'"
							>
								<input
									type="text"
									v-model="day.GhiChu"
									:placeholder="day.key === 2 ? 'Cố định' : (isDayGvcnLocked(day.key) ? 'Đã khóa' : 'Ghi chú...')"
									:disabled="isDayGvcnLocked(day.key)"
									class="tkb-note-native-input"
									:class="{ 'tkb-monday-input': day.key === 2 }"
									@input="onNoteInput"
								/>
							</div>
						</div>
					</div>
				</v-card>

				<!-- KHỐI 2: NHẬT KÍ ĐÁNH GIÁ NỀ NẾP LỚP TRONG TUẦN (BẢNG NGANG GỌN GÀNG, 1 VIEW NHÌN THẤY TOÀN BỘ) -->
				<v-card elevation="0" rounded="lg" class="overflow-hidden" style="border: 1px solid #f1f5f9 !important; background: #ffffff;">
					<div class="px-3 py-2 d-flex align-center justify-space-between flex-wrap ga-2" style="background-color: #f8fafc; border-bottom: 1px solid #f1f5f9 !important;">
						<div class="d-flex align-center ga-2 text-primary font-weight-bold" style="font-size: 13px;">
							<v-icon size="18">mdi-clipboard-text-clock-outline</v-icon>
							<span>Nhật ký quản sinh chấm điểm nề nếp lớp {{ gvcnClassInfo.TenLop }} — {{ selectedWeek ? selectedWeek.title : 'Tuần này' }}</span>
							<v-chip v-if="isPastSelectedWeek" size="x-small" color="blue-grey" variant="flat" class="ms-1 text-white font-weight-medium">
								Dữ liệu lịch sử tuần trước
							</v-chip>
						</div>
						<div class="text-caption text-medium-emphasis font-italic" style="font-size: 11px;">
							[Đ] = Đạt · [CĐ] = Chưa đạt
						</div>
					</div>

					<!-- Bảng Desktop (>= 960px) -->
					<div class="d-none d-md-block table-responsive">
						<table class="w-100 evaluation-master-table" style="min-width: 960px; font-size: 12.5px;">
							<thead>
								<tr style="height: 40px;">
									<th style="width: 120px; min-width: 120px; text-align: left; padding: 6px 10px; white-space: nowrap;">Thứ & ngày</th>
									<th style="width: 140px; min-width: 140px; text-align: center; padding: 6px 8px; white-space: nowrap;">Lịch GVCN</th>
									<th style="width: 105px; min-width: 100px; text-align: center; padding: 4px 6px; vertical-align: middle; white-space: nowrap;">
										<div class="font-weight-medium text-grey-darken-3" style="font-size: 11.5px; line-height: 1.2;">TC1: Không gian</div>
										<div class="text-grey-darken-1 mt-0.5" style="font-size: 10px; line-height: 1.1; font-weight: 400;">(Sạch sẽ, bảng, sàn)</div>
									</th>
									<th style="width: 105px; min-width: 100px; text-align: center; padding: 4px 6px; vertical-align: middle; white-space: nowrap;">
										<div class="font-weight-medium text-grey-darken-3" style="font-size: 11.5px; line-height: 1.2;">TC2: Nội dung</div>
										<div class="text-grey-darken-1 mt-0.5" style="font-size: 10px; line-height: 1.1; font-weight: 400;">(Đọc sách, chủ đề)</div>
									</th>
									<th style="width: 105px; min-width: 100px; text-align: center; padding: 4px 6px; vertical-align: middle; white-space: nowrap;">
										<div class="font-weight-medium text-grey-darken-3" style="font-size: 11.5px; line-height: 1.2;">TC3: Nề nếp</div>
										<div class="text-grey-darken-1 mt-0.5" style="font-size: 10px; line-height: 1.1; font-weight: 400;">(Nghiêm túc, tích cực)</div>
									</th>
									<th style="width: 120px; min-width: 115px; text-align: center; padding: 6px 8px; white-space: nowrap;">Xếp loại</th>
									<th style="min-width: 180px; text-align: left; padding: 6px 12px;">Ghi chú vi phạm / nhận xét</th>
									<th style="width: 140px; min-width: 135px; text-align: left; padding: 6px 12px; white-space: nowrap;">Quản sinh chấm</th>
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
									<td style="text-align: center; padding: 4px 8px; white-space: nowrap;">
										<span v-if="log.ThuLabel === 'Thứ 2'" class="text-blue-grey-darken-2 font-weight-medium d-inline-flex align-center ga-1" style="font-size: 11.5px; white-space: nowrap;">
											<v-icon size="14" color="blue-grey">mdi-school</v-icon> SH đầu tuần
										</span>
										<span v-else-if="!log.IsTuQuan" class="text-grey-darken-2 font-weight-medium d-inline-flex align-center ga-1" style="font-size: 11.5px; white-space: nowrap;">
											<v-icon size="14" color="grey-darken-2">mdi-account-tie</v-icon> GVCN sinh hoạt
										</span>
										<span v-else class="text-success font-weight-medium d-inline-flex align-center ga-1" style="font-size: 11.5px; white-space: nowrap;">
											<v-icon size="14" color="success">mdi-account-group-outline</v-icon> Lớp tự quản
										</span>
									</td>
									<!-- TC1 -->
									<td style="text-align: center; padding: 4px;">
										<span v-if="log.KetQua === 'CHUA_CHAM' || log.ThuLabel === 'Thứ 2' || !log.IsTuQuan" class="text-medium-emphasis">—</span>
										<template v-else>
											<v-chip v-if="getLogCritScore(log, 0) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5" style="height: 20px;">
												CĐ
											</v-chip>
											<span v-else class="text-success font-weight-medium" style="font-size: 12px;">✓ Đạt</span>
										</template>
									</td>
									<!-- TC2 -->
									<td style="text-align: center; padding: 4px;">
										<span v-if="log.KetQua === 'CHUA_CHAM' || log.ThuLabel === 'Thứ 2' || !log.IsTuQuan" class="text-medium-emphasis">—</span>
										<template v-else>
											<v-chip v-if="getLogCritScore(log, 1) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5" style="height: 20px;">
												CĐ
											</v-chip>
											<span v-else class="text-success font-weight-medium" style="font-size: 12px;">✓ Đạt</span>
										</template>
									</td>
									<!-- TC3 -->
									<td style="text-align: center; padding: 4px;">
										<span v-if="log.KetQua === 'CHUA_CHAM' || log.ThuLabel === 'Thứ 2' || !log.IsTuQuan" class="text-medium-emphasis">—</span>
										<template v-else>
											<v-chip v-if="getLogCritScore(log, 2) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5" style="height: 20px;">
												CĐ
											</v-chip>
											<span v-else class="text-success font-weight-medium" style="font-size: 12px;">✓ Đạt</span>
										</template>
									</td>
									<!-- Xếp loại -->
									<td style="text-align: center; padding: 4px 6px;">
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
											:color="log.KetQua === 'D' ? 'success' : (log.KetQua === 'CCG' ? 'amber-darken-3' : 'error')"
											:variant="log.KetQua === 'CD' ? 'flat' : 'tonal'"
											:class="log.KetQua === 'CD' ? 'font-weight-bold rounded-pill px-2' : 'font-weight-medium rounded-pill px-2'"
										>
											{{ log.KetQua === 'D' ? 'Đạt (Đ)' : (log.KetQua === 'CCG' ? 'Cần cố gắng (CCG)' : 'Chưa đạt (CĐ)') }}
										</v-chip>
									</td>
									<!-- Ghi chú vi phạm / nhận xét của Quản sinh -->
									<td class="text-left" style="padding: 4px 12px;">
										<template v-if="log.NoiDungViPham">
											<span v-if="log.HasViolation" class="text-error font-weight-medium d-inline-flex align-center ga-1">
												<v-icon size="14" color="error">mdi-alert-circle</v-icon>
												{{ log.NoiDungViPham }}
											</span>
											<span v-else class="text-grey-darken-3 font-italic d-inline-flex align-center ga-1" style="font-size: 12.5px;">
												<v-icon size="14" color="grey-darken-1">mdi-comment-text-outline</v-icon>
												{{ log.NoiDungViPham }}
											</span>
										</template>
										<span v-else class="text-medium-emphasis">—</span>
									</td>
									<!-- Quản sinh chấm -->
									<td class="text-left text-medium-emphasis" style="padding: 6px 12px; font-size: 12px; white-space: nowrap;">
										<span v-if="log.ThuLabel === 'Thứ 2' || !log.IsTuQuan || log.KetQua === 'CHUA_CHAM'">—</span>
										<span v-else class="text-grey-darken-3 font-weight-medium">{{ log.NguoiCham || '—' }}</span>
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
									<span v-else class="text-caption text-success font-weight-medium">Lớp tự quản</span>
									<v-chip v-if="log.KetQua === 'CHUA_CHAM'" size="x-small" color="grey-darken-1" variant="tonal" class="font-weight-medium rounded-pill px-2 ms-1">
										Chưa diễn ra
									</v-chip>
									<v-chip v-else-if="log.ThuLabel !== 'Thứ 2' && log.IsTuQuan" size="x-small" :color="log.KetQua === 'D' ? 'success' : (log.KetQua === 'CCG' ? 'amber-darken-3' : 'error')" variant="flat" :class="log.KetQua === 'CD' ? 'font-weight-bold rounded-pill text-white px-2 ms-1' : 'font-weight-medium rounded-pill text-white px-2 ms-1'">
										{{ log.KetQua === 'D' ? 'Đạt' : (log.KetQua === 'CCG' ? 'CCG' : 'CĐ') }}
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
									<span class="font-weight-medium text-grey-darken-3">TC1. Thông thoáng, ngăn nắp, sạch sẽ</span>
									<span class="ms-2">
										<v-chip v-if="getLogCritScore(log, 0) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5">CĐ</v-chip>
										<span v-else class="text-success font-weight-medium">✓ Đạt</span>
									</span>
								</div>
								<div class="d-flex align-center justify-space-between" style="font-size: 11.5px;">
									<span class="font-weight-medium text-grey-darken-3">TC2. Hoạt động 15p có nội dung cụ thể</span>
									<span class="ms-2">
										<v-chip v-if="getLogCritScore(log, 1) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5">CĐ</v-chip>
										<span v-else class="text-success font-weight-medium">✓ Đạt</span>
									</span>
								</div>
								<div class="d-flex align-center justify-space-between" style="font-size: 11.5px;">
									<span class="font-weight-medium text-grey-darken-3">TC3. Tập thể tham gia nghiêm túc, tích cực</span>
									<span class="ms-2">
										<v-chip v-if="getLogCritScore(log, 2) === 1" size="x-small" color="error" variant="flat" class="font-weight-bold px-1.5">CĐ</v-chip>
										<span v-else class="text-success font-weight-medium">✓ Đạt</span>
									</span>
								</div>
							</div>

							<!-- Ghi chú vi phạm / nhận xét nếu có -->
							<div
								v-if="log.NoiDungViPham"
								class="pa-2 rounded text-caption font-weight-medium mb-1 border d-flex align-start ga-1"
								:class="log.HasViolation ? 'bg-red-lighten-5 border-red-lighten-3 text-error' : 'bg-grey-lighten-5 border-grey-lighten-2 text-grey-darken-3'"
							>
								<v-icon size="14" :color="log.HasViolation ? 'error' : 'grey-darken-2'" class="mt-0.5 flex-shrink-0">
									{{ log.HasViolation ? 'mdi-alert-circle' : 'mdi-comment-text-outline' }}
								</v-icon>
								<span>{{ log.NoiDungViPham }}</span>
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
						<!-- Nhóm nút In báo cáo & Sao chép nhanh gửi Zalo (Responsive trên Mobile không bị tràn hay cắt chữ) -->
						<div class="d-flex align-center ga-1.5 ga-sm-2 ms-sm-auto w-100 w-sm-auto">
							<v-btn
								size="small"
								variant="outlined"
								color="primary"
								prepend-icon="mdi-printer"
								class="text-none font-weight-medium flex-grow-1 flex-sm-grow-0 px-2"
								style="min-width: 0; font-size: 11.5px; height: 32px;"
								@click="openPrintDialog(bghViewMode === 'month' ? 'bgh_summary' : 'daily')"
							>
								In phiếu<span class="d-none d-sm-inline ms-0.5"> / báo cáo</span>
							</v-btn>
							<v-btn
								size="small"
								variant="outlined"
								color="success"
								prepend-icon="mdi-file-excel-outline"
								class="text-none font-weight-medium flex-grow-1 flex-sm-grow-0 px-2"
								style="min-width: 0; font-size: 11.5px; height: 32px;"
								@click="exportExcelReport"
							>
								Xuất Excel
							</v-btn>
							<v-btn
								size="small"
								variant="outlined"
								color="grey-darken-3"
								prepend-icon="mdi-share-variant-outline"
								class="text-none font-weight-medium flex-grow-1 flex-sm-grow-0 px-2"
								style="min-width: 0; font-size: 11.5px; height: 32px;"
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
								:title="isSpecificDayInFuture(d.val) ? (d.label + ' (' + d.date + ') - Chưa diễn ra') : (d.label + ' (' + d.date + ')')"
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
					<!-- Giao diện Desktop (>= 600px): Dải ngang tinh tế có đường phân cách -->
					<div class="d-none d-sm-flex align-center justify-space-between flex-wrap ga-2 text-caption">
						<!-- Inline metrics khi xem theo Ngày -->
						<div v-if="bghViewMode === 'day'" class="d-flex align-center ga-3 ga-sm-4 flex-wrap">
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">Tự quản {{ bghIsViewingToday ? 'hôm nay' : bghActiveDayLabel }}:</span>
								<span class="font-weight-bold text-grey-darken-4">{{ reportSummary.tuQuanCount }}/{{ reportSummary.totalClasses }} lớp</span>
							</div>
							<v-divider vertical class="my-1 d-none d-sm-block" />
							<div class="d-flex align-center">
								<span class="text-medium-emphasis me-1">Xếp loại Đạt (Đ):</span>
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

						<div class="d-flex align-center ga-1.5 text-caption">
							<template v-if="bghViewMode === 'day'">
								<v-icon size="15" color="primary">mdi-account-check-outline</v-icon>
								<span class="text-medium-emphasis">{{ bghActiveDay === 2 ? 'Quản sinh:' : 'Quản sinh chấm nề nếp:' }}</span>
								<v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold">
									{{ bghActiveDay === 2 ? 'Không chấm (GVCN sinh hoạt)' : (((dayClassesDetail && dayClassesDetail.length > 0 && dayClassesDetail[0].NguoiCham && dayClassesDetail[0].NguoiCham !== '—')) ? dayClassesDetail[0].NguoiCham : 'QS. Trần Tuấn') }}
								</v-chip>
							</template>
							<template v-else>
								<v-icon size="15" color="primary">mdi-shield-account-outline</v-icon>
								<span class="text-medium-emphasis">Quản sinh phụ trách khối:</span>
								<v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold">
									QS. Trần Tuấn
								</v-chip>
							</template>
						</div>
					</div>

					<!-- Giao diện Mobile (< 600px): Lưới 2x2 chỉ số ngăn nắp, thẳng thớm, không dồn chữ -->
					<div class="d-flex d-sm-none flex-column ga-2 text-caption">
						<template v-if="bghViewMode === 'day'">
							<div class="d-grid" style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
								<div class="pa-2 bg-grey-lighten-5 rounded border d-flex flex-column">
									<span class="text-grey-darken-1" style="font-size: 11px;">Tự quản:</span>
									<span class="font-weight-bold text-grey-darken-4" style="font-size: 13px;">{{ reportSummary.tuQuanCount }}/{{ reportSummary.totalClasses }} lớp</span>
								</div>
								<div class="pa-2 bg-grey-lighten-5 rounded border d-flex flex-column">
									<span class="text-grey-darken-1" style="font-size: 11px;">Xếp loại Đạt (Đ):</span>
									<span class="font-weight-bold text-success" style="font-size: 13px;">{{ reportSummary.goodCount }} lớp</span>
								</div>
								<div class="pa-2 bg-grey-lighten-5 rounded border d-flex flex-column">
									<span class="text-grey-darken-1" style="font-size: 11px;">Chưa đạt (CĐ):</span>
									<span class="font-weight-bold" :class="reportSummary.violationCount > 0 ? 'text-error' : 'text-grey-darken-3'" style="font-size: 13px;">
										{{ reportSummary.violationCount }} lớp
									</span>
								</div>
								<div class="pa-2 bg-grey-lighten-5 rounded border d-flex flex-column">
									<span class="text-grey-darken-1" style="font-size: 11px;">Đang xem:</span>
									<span class="font-weight-bold text-grey-darken-4" style="font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">{{ bghActiveDayLabel }}</span>
								</div>
							</div>
							<div class="d-flex align-center justify-space-between pt-1 border-t border-grey-lighten-3" style="font-size: 11px;">
								<span class="text-grey-darken-1">{{ bghActiveDay === 2 ? 'Quản sinh:' : 'Quản sinh chấm nề nếp:' }}</span>
								<v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold" style="height: 20px;">
									<v-icon start size="11">mdi-account-check</v-icon>
									{{ bghActiveDay === 2 ? 'Không chấm (GVCN sinh hoạt)' : (((dayClassesDetail && dayClassesDetail.length > 0 && dayClassesDetail[0].NguoiCham && dayClassesDetail[0].NguoiCham !== '—')) ? dayClassesDetail[0].NguoiCham : 'QS. Trần Tuấn') }}
								</v-chip>
							</div>
						</template>
						<template v-else>
							<div class="d-grid" style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
								<div class="pa-2 bg-grey-lighten-5 rounded border d-flex flex-column">
									<span class="text-grey-darken-1" style="font-size: 11px;">Chu kỳ:</span>
									<span class="font-weight-bold text-grey-darken-4" style="font-size: 12px;">4 tuần liên tiếp</span>
								</div>
								<div class="pa-2 bg-grey-lighten-5 rounded border d-flex flex-column">
									<span class="text-grey-darken-1" style="font-size: 11px;">Khen thưởng:</span>
									<span class="font-weight-bold text-success" style="font-size: 12px;">{{ monthlySummaryStats.khenThuongDetail }}</span>
								</div>
								<div class="pa-2 bg-grey-lighten-5 rounded border d-flex flex-column">
									<span class="text-grey-darken-1" style="font-size: 11px;">Biểu dương:</span>
									<span class="font-weight-bold text-grey-darken-4" style="font-size: 12px;">{{ monthlySummaryStats.bieuDuongDetail }}</span>
								</div>
								<div class="pa-2 bg-grey-lighten-5 rounded border d-flex flex-column">
									<span class="text-grey-darken-1" style="font-size: 11px;">Tạm dừng TQ:</span>
									<span class="font-weight-bold" :class="monthlySummaryStats.tamDungCount > 0 ? 'text-error' : 'text-grey-darken-4'" style="font-size: 12px;">{{ monthlySummaryStats.tamDungDetail }}</span>
								</div>
							</div>
							<div class="d-flex align-center justify-space-between pt-1 border-t border-grey-lighten-3" style="font-size: 11px;">
								<span class="text-grey-darken-1">Quản sinh khối:</span>
								<v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold" style="height: 20px;">
									QS. Trần Tuấn
								</v-chip>
							</div>
						</template>
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
										<th class="text-left" style="width: 165px; padding: 6px 10px;">GVCN</th>
										<th class="text-center" style="width: 140px; padding: 6px 8px;">Quản sinh chấm</th>
										<th class="text-center" style="width: 130px; padding: 6px 8px;">Hình thức 15p</th>
										<th class="text-center" style="width: 125px; padding: 6px 8px;">GVCN có mặt (7:15)</th>
										<th class="text-center" style="width: 110px; padding: 6px 8px;">Xếp loại ngày</th>
										<th class="text-center" style="width: 90px; padding: 6px 4px;">TC1: K.Gian</th>
										<th class="text-center" style="width: 90px; padding: 6px 4px;">TC2: Nội dung</th>
										<th class="text-center" style="width: 90px; padding: 6px 4px;">TC3: Nghiêm túc</th>
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
											<v-chip v-if="row.IsTuQuan && row.NguoiCham && row.NguoiCham !== '—'" size="x-small" variant="tonal" color="primary" class="font-weight-medium">
												<v-icon start size="12">mdi-account-check</v-icon>
												{{ row.NguoiCham }}
											</v-chip>
											<span v-else class="text-medium-emphasis font-weight-medium" style="font-size: 13px;">—</span>
										</td>
										<td class="text-center" style="padding: 6px 8px;">
											<span class="table-rank-badge" :class="row.IsTuQuan ? 'rank-dat' : 'rank-gvcn'">
												{{ row.IsTuQuan ? 'Lớp tự quản' : (row.GVCNCoMat ? 'GVCN có mặt (GV)' : 'GVCN sinh hoạt') }}
											</span>
										</td>
										<td class="text-center" style="padding: 6px 8px;">
											<template v-if="!row.IsTuQuan">
												<span v-if="row.GVCNCoMat" class="text-success font-weight-medium d-flex align-center justify-center ga-1" style="font-size: 12px;">
													<v-icon size="15" color="success">mdi-check-circle</v-icon> Có mặt
												</span>
												<span v-else class="text-error font-weight-bold d-flex align-center justify-center ga-1" style="font-size: 12px;">
													<v-icon size="15" color="error">mdi-close-circle</v-icon> Vắng mặt
												</span>
											</template>
											<span v-else class="text-medium-emphasis font-weight-medium" style="font-size: 13px;">—</span>
										</td>
										<td class="text-center" style="padding: 6px 8px;">
											<span v-if="row.Result.code === 'GVCN' || row.Result.code === '—' || !row.IsTuQuan" class="text-medium-emphasis font-weight-medium" style="font-size: 13px;">—</span>
											<span
												v-else
												class="table-rank-badge"
												:class="{
													'rank-dat': row.Result.code === 'D',
													'rank-ccg': row.Result.code === 'CCG',
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
												:class="row.TC1 === 1 ? 'rank-chuadat' : 'rank-dat'"
											>
												{{ row.TC1 === 1 ? 'CĐ' : 'Đạt' }}
											</span>
										</td>
										<td class="text-center" style="padding: 6px 4px;">
											<span v-if="row.TC2 === null" class="text-medium-emphasis font-weight-medium">—</span>
											<span
												v-else
												class="table-rank-badge"
												:class="row.TC2 === 1 ? 'rank-chuadat' : 'rank-dat'"
											>
												{{ row.TC2 === 1 ? 'CĐ' : 'Đạt' }}
											</span>
										</td>
										<td class="text-center" style="padding: 6px 4px;">
											<span v-if="row.TC3 === null" class="text-medium-emphasis font-weight-medium">—</span>
											<span
												v-else
												class="table-rank-badge"
												:class="row.TC3 === 1 ? 'rank-chuadat' : 'rank-dat'"
											>
												{{ row.TC3 === 1 ? 'CĐ' : 'Đạt' }}
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
							rounded="xl"
							class="border bg-white overflow-hidden"
							:class="{ 'border-red-lighten-2 bg-red-lighten-5': row.HasViolation, 'border-grey-lighten-2': !row.HasViolation }"
						>
							<!-- Header Thẻ BGH Mobile: Cấu trúc 2 tầng thoáng đãng, không bị chèn ép -->
							<div class="px-3 py-2.5 bg-grey-lighten-5 border-b">
								<!-- Tầng 1: STT + Tên lớp & Badge Xếp loại ngày -->
								<div class="d-flex align-center justify-space-between">
									<div class="d-flex align-center ga-2">
										<v-avatar color="primary" size="24" class="text-white text-caption font-weight-bold">
											{{ row.STT }}
										</v-avatar>
										<span class="font-weight-bold text-subtitle-1 text-primary" style="font-size: 15px !important; line-height: 1.2;">
											{{ row.TenLop }}
										</span>
									</div>

									<!-- Badge xếp loại ngày -->
									<div>
										<span v-if="row.Result.code === 'GVCN' || row.Result.code === '—' || !row.IsTuQuan" class="text-medium-emphasis font-weight-medium text-caption">—</span>
										<span
											v-else
											class="table-rank-badge font-weight-bold"
											:class="{
												'rank-dat': row.Result.code === 'D',
												'rank-ccg': row.Result.code === 'CCG',
												'rank-chuadat': row.Result.code === 'CD'
											}"
											style="font-size: 11px; height: 22px;"
										>
											{{ row.Result.text }}
										</span>
									</div>
								</div>

								<!-- Tầng 2: Tên GVCN & Badge trạng thái -->
								<div class="d-flex align-center justify-space-between mt-2 pt-1.5 border-t border-grey-lighten-3">
									<div class="text-caption text-grey-darken-2" style="font-size: 11.5px;">
										GVCN: <span class="font-weight-medium text-grey-darken-3">{{ row.TenGVCN }}</span>
									</div>
									<span
										class="table-status-badge"
										:class="row.IsTuQuan ? 'badge-tuquan' : 'badge-gvcn'"
										style="height: 22px; font-size: 10.5px;"
									>
										<v-icon size="12" class="me-0.5" :color="row.IsTuQuan ? 'success' : 'blue-grey-darken-2'">
											{{ row.IsTuQuan ? 'mdi-shield-check' : 'mdi-account-tie' }}
										</v-icon>
										{{ row.IsTuQuan ? 'Tự quản' : 'GVCN sinh hoạt' }}
									</span>
								</div>
							</div>

							<!-- Thân thẻ BGH Mobile -->
							<div class="pa-3 text-caption">
								<div v-if="!row.IsTuQuan" class="pa-2 rounded-lg bg-blue-grey-lighten-5 border border-blue-grey-lighten-4 d-flex align-center text-caption text-blue-grey-darken-3">
									<v-icon size="16" color="blue-grey-darken-2" class="me-1.5">mdi-account-tie</v-icon>
									<span>GVCN trực tiếp sinh hoạt cùng lớp (Không chấm tự quản)</span>
								</div>
								<div v-else class="d-flex flex-column ga-2">
									<div class="d-flex align-center justify-space-between py-1 border-b border-grey-lighten-3">
										<span class="text-grey-darken-3 font-weight-medium" style="font-size: 12px;">TC1: Không gian (Sạch sẽ, bảng, sàn):</span>
										<span
											class="table-rank-badge px-2"
											:class="row.TC1 === 1 ? 'rank-chuadat' : 'rank-dat'"
											style="font-size: 11px; height: 20px;"
										>
											{{ row.TC1 === 1 ? 'Chưa đạt' : 'Đạt' }}
										</span>
									</div>
									<div class="d-flex align-center justify-space-between py-1 border-b border-grey-lighten-3">
										<span class="text-grey-darken-3 font-weight-medium" style="font-size: 12px;">TC2: Nội dung (Đọc sách, chủ đề):</span>
										<span
											class="table-rank-badge px-2"
											:class="row.TC2 === 1 ? 'rank-chuadat' : 'rank-dat'"
											style="font-size: 11px; height: 20px;"
										>
											{{ row.TC2 === 1 ? 'Chưa đạt' : 'Đạt' }}
										</span>
									</div>
									<div class="d-flex align-center justify-space-between py-1">
										<span class="text-grey-darken-3 font-weight-medium" style="font-size: 12px;">TC3: Nề nếp (Nghiêm túc, tích cực):</span>
										<span
											class="table-rank-badge px-2"
											:class="row.TC3 === 1 ? 'rank-chuadat' : 'rank-dat'"
											style="font-size: 11px; height: 20px;"
										>
											{{ row.TC3 === 1 ? 'Chưa đạt' : 'Đạt' }}
										</span>
									</div>
								</div>

								<!-- Ghi chú vi phạm nếu có -->
								<div v-if="row.GhiChuViPham" class="mt-2 pt-1.5 border-t text-caption" :class="row.HasViolation ? 'text-error font-weight-medium' : 'text-grey-darken-2'">
									<v-icon size="14" :color="row.HasViolation ? 'error' : 'grey'">{{ row.HasViolation ? 'mdi-alert-circle' : 'mdi-information-outline' }}</v-icon>
									Ghi chú: {{ row.GhiChuViPham }}
								</div>

								<!-- Footer: Quản sinh chấm -->
								<div class="d-flex align-center justify-space-between mt-2 pt-1.5 border-t border-grey-lighten-3 text-grey-darken-1" style="font-size: 10.5px;">
									<span>Quản sinh chấm / theo dõi:</span>
									<span class="font-weight-medium text-grey-darken-3">{{ row.IsTuQuan && row.NguoiCham && row.NguoiCham !== '—' ? row.NguoiCham : '—' }}</span>
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
							<div v-if="!rewardClasses || !rewardClasses.length" class="text-center py-6 text-grey-darken-1 text-caption">
								<v-icon size="36" color="grey-lighten-1" class="mb-2">mdi-calendar-clock</v-icon>
								<div class="font-weight-bold text-subtitle-2 text-grey-darken-3">Chu kỳ đánh giá Tháng {{ currentEvaluationMonth }}/2026 chưa bắt đầu</div>
								<div class="text-medium-emphasis mt-1">Dữ liệu thi đua và đề xuất khen thưởng sẽ được cập nhật tự động khi bước vào chu kỳ đánh giá.</div>
							</div>
							<v-row v-else dense>
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
												<span class="text-success font-weight-bold">Đã đạt {{ item.SoTuanTot || 1 }}/4 tuần Đạt chuẩn</span>
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
					<v-card id="bgh-khoi-evidence-table" elevation="0" rounded="lg" class="border overflow-hidden bg-white" style="scroll-margin-top: 80px;">
						<div class="px-3 py-2 bg-grey-lighten-4 border-b">
							<div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-2">
								<div class="d-flex align-center ga-2">
									<v-icon color="grey-darken-3" size="18">mdi-table-large</v-icon>
									<span class="font-weight-bold text-subtitle-2 text-grey-darken-4">
										Chi tiết nề nếp các lớp toàn Khối {{ selectedKhoi || 6 }} — Tuần {{ outerMonthlySelectedWeekNum }} (Tháng {{ currentEvaluationMonth }}/2026)
									</span>
								</div>
								<div class="d-flex align-center ga-2 ms-auto">
									<v-btn
										size="small"
										variant="outlined"
										color="primary"
										prepend-icon="mdi-printer"
										class="text-none font-weight-medium"
										@click="printOuterKhoiEvidence"
									>
										In chi tiết toàn khối
									</v-btn>
									<v-btn
										size="small"
										variant="outlined"
										color="success"
										prepend-icon="mdi-file-excel-outline"
										class="text-none font-weight-medium"
										@click="exportKhoiWeekExcel"
									>
										Xuất Excel tuần
									</v-btn>
								</div>
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
											v-for="hw in monthEvaluationWeeks.filter(x => !x.isFuture)"
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
										style="height: 48px; transition: all 0.3s ease;"
										:class="{ 'bg-grey-lighten-5': rIdx % 2 === 1, 'bg-amber-lighten-5 font-weight-bold': highlightedClassId === row.LopID }"
										:style="highlightedClassId === row.LopID ? 'box-shadow: inset 0 0 0 2px #f59e0b;' : ''"
									>
										<td class="text-center" style="padding: 6px;">{{ rIdx + 1 }}</td>
										<td class="font-weight-medium text-left px-2">
											<span :class="['CD', 'CHETAI'].includes((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status) ? 'text-error font-weight-bold' : 'text-grey-darken-4 font-weight-medium'">{{ row.TenLop }}</span>
										</td>
										<td class="text-left px-2 text-medium-emphasis">{{ row.TenGVCN }}</td>
										<td
											v-for="d in ((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).days || [])"
											:key="'outer-kd-' + row.LopID + '-' + d.dayNum"
											class="text-center px-1"
											style="vertical-align: middle;"
										>
											<template v-if="d.rankCode === 'CHETAI'">
												<span class="text-error" title="Tạm dừng tự quản (Áp dụng chế tài)">—</span>
											</template>
											<template v-else-if="d.tcText === '—' && d.rankText === '—'">
												<span class="text-medium-emphasis">—</span>
											</template>
											<template v-else-if="d.rankCode === 'GV'">
												<div class="d-flex flex-column align-center justify-center">
													<span class="table-rank-badge rank-gvcn" style="font-size: 10px; padding: 1px 6px;">GV</span>
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
								:class="{ 'border-error': ['CD', 'CHETAI'].includes((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status), 'border-warning bg-amber-lighten-5': highlightedClassId === row.LopID }"
								:style="highlightedClassId === row.LopID ? 'box-shadow: 0 0 0 2px #f59e0b; transition: all 0.3s ease;' : 'transition: all 0.3s ease;'"
							>
								<div class="pa-3">
									<div class="d-flex align-center justify-space-between mb-2">
										<div class="d-flex align-center ga-2">
											<span class="font-weight-medium text-subtitle-1" :class="['CD', 'CHETAI'].includes((row.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || row.w1).status) ? 'text-error font-weight-bold' : 'text-grey-darken-4'">
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
												<template v-if="d.rankCode === 'CHETAI'">
													<span class="text-error" style="font-size: 11px;" title="Tạm dừng tự quản (Áp dụng chế tài)">—</span>
												</template>
												<template v-else-if="d.tcText === '—' && d.rankText === '—'">
													<span class="text-medium-emphasis" style="font-size: 11px;">—</span>
												</template>
												<template v-else-if="d.rankCode === 'GV'">
													<span class="table-rank-badge rank-gvcn" style="font-size: 9px; padding: 0 4px;">GV</span>
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
							<div v-if="(monthEvaluationWeeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || {}).isOngoing">
								<strong>Tổng hợp Tuần {{ outerMonthlySelectedWeekNum }}:</strong>
								Khối {{ selectedKhoi || 6 }} đang trong tuần đánh giá thứ {{ outerMonthlySelectedWeekNum }}. Dữ liệu đối soát tự động theo tiến độ chấm điểm.
							</div>
							<div v-else-if="(monthEvaluationWeeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || {}).isFuture">
								<strong>Tổng hợp Tuần {{ outerMonthlySelectedWeekNum }}:</strong>
								Khối {{ selectedKhoi || 6 }} chưa bước vào tuần đánh giá thứ {{ outerMonthlySelectedWeekNum }} (Tháng {{ currentEvaluationMonth }}/2026).
							</div>
							<div v-else>
								<strong>Tổng hợp kết quả Tuần {{ outerMonthlySelectedWeekNum }}:</strong>
								Khối {{ selectedKhoi || 6 }} có
								<strong class="text-success">{{ monthlyClassRecords.filter(r => ['T', 'D'].includes((r.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || r.w1).status)).length }} lớp Đạt</strong>,
								<strong class="text-primary">{{ monthlyClassRecords.filter(r => (r.weeks.find(x => x.weekNum === outerMonthlySelectedWeekNum) || r.w1).status === 'DT').length }} lớp Duy trì</strong>,
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
									<template v-if="currentEvaluationMonth === 9">Đạt {{ evidenceDialog.classItem.SoTuanTot }}/4 tuần Đạt (Đã xét 4/4 tuần)</template>
									<template v-else-if="currentEvaluationMonth > 10">Đạt 0/4 tuần (Chu kỳ Tháng {{ currentEvaluationMonth }} chưa diễn ra)</template>
									<template v-else>Đạt {{ evidenceDialog.classItem.SoTuanTot }}/4 tuần Đạt (Đã xét 3/4 tuần)</template>
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
											<template v-if="d.rankCode === 'CHETAI'">
												<div class="d-flex flex-column align-center justify-center">
													<span class="text-error" title="Tạm dừng tự quản (Áp dụng chế tài)">—</span>
												</div>
											</template>
											<template v-else-if="d.tcText === '—' && d.rankText === '—'">
												<span class="text-medium-emphasis">—</span>
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
								{{ currentEvaluationMonth === 9 ? 'Kết quả đánh giá Tháng 9/2026:' : (currentEvaluationMonth > 10 ? 'Tiến độ đánh giá Tháng ' + currentEvaluationMonth + '/2026:' : 'Tiến độ đánh giá Tháng 10/2026:') }}
							</div>
							<template v-if="currentEvaluationMonth === 9">
								<div v-if="evidenceDialog.classItem.IsRewardEligible">
									Lớp {{ evidenceDialog.classItem.TenLop }} đã hoàn thành trọn vẹn 4/4 tuần Đạt trong Tháng 9/2026. Đã chính thức được công nhận danh hiệu "Lớp tự quản tốt" và cộng thưởng <strong class="text-success">{{ evidenceDialog.classItem.DiemThiDua }}</strong>.
								</div>
								<div v-else-if="evidenceDialog.classItem.IsEffortReward">
									Lớp {{ evidenceDialog.classItem.TenLop }} đã đạt 3/4 tuần Đạt trong Tháng 9/2026. Đã chính thức được tuyên dương danh hiệu "Biểu dương nỗ lực nề nếp" và cộng thưởng <strong class="text-success">{{ evidenceDialog.classItem.DiemThiDua }}</strong>.
								</div>
								<div v-else>
									Lớp {{ evidenceDialog.classItem.TenLop }} đã hoàn thành chu kỳ thi đua nề nếp Tháng 9/2026 (đạt chuẩn nề nếp tự quản 15 phút đầu giờ).
								</div>
							</template>
							<template v-else-if="currentEvaluationMonth > 10">
								<div>
									Chu kỳ đánh giá Tháng {{ currentEvaluationMonth }}/2026 ({{ monthCycleDateRange }}) chưa bắt đầu. Lớp {{ evidenceDialog.classItem.TenLop }} chưa phát sinh dữ liệu chấm nề nếp.
								</div>
							</template>
							<template v-else>
								<div v-if="evidenceDialog.classItem.IsLeading">
									Lớp {{ evidenceDialog.classItem.TenLop }} đã hoàn thành {{ evidenceDialog.classItem.SoTuanTot }} tuần Đạt đã xét và đang dẫn đầu tiến độ thi đua. Tuần 4 đang diễn ra (26/10 – 01/11). Danh hiệu "Lớp tự quản tốt" và điểm cộng (<span class="font-weight-medium text-success">{{ evidenceDialog.classItem.DiemThiDua }}</span>) sẽ được xét duyệt chính thức sau ngày 01/11/2026 khi kết thúc chu kỳ 4 tuần.
								</div>
								<div v-else-if="evidenceDialog.classItem.IsRewardEligible">
									Lớp {{ evidenceDialog.classItem.TenLop }} hoàn thành 4/4 tuần Đạt trong tháng 10. Đề xuất cộng <strong class="text-success">{{ evidenceDialog.classItem.DiemThiDua }}</strong> và công nhận danh hiệu "Lớp tự quản tốt".
								</div>
								<div v-else-if="evidenceDialog.classItem.SoTuanCD > 0">
									Lớp {{ evidenceDialog.classItem.TenLop }} có <strong class="text-error">{{ evidenceDialog.classItem.SoTuanCD }} tuần Chưa đạt</strong> (Tuần 1 ghi nhận vi phạm nề nếp). Đã áp dụng chế tài: <strong class="text-error">Tạm dừng tự quản Tuần 2</strong>. Lớp đã chấn chỉnh và tham gia tự quản trở lại ở các tuần tiếp theo.
								</div>
								<div v-else>
									Lớp {{ evidenceDialog.classItem.TenLop }} đã hoàn thành các tuần đã xét. Tuần 4 đang diễn ra. Tiếp tục duy trì nề nếp để tích lũy điểm thi đua tháng.
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
											v-for="hw in monthEvaluationWeeks.filter(x => !x.isFuture)"
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
											<span :class="['CD', 'CHETAI'].includes((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status) ? 'text-error font-weight-bold' : 'text-grey-darken-4 font-weight-medium'">{{ row.TenLop }}</span>
										</td>
										<td class="text-left px-2 text-medium-emphasis">{{ row.TenGVCN }}</td>
										<td
											v-for="d in ((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).days || [])"
											:key="'ev-kd-' + row.LopID + '-' + d.dayNum"
											class="text-center px-1"
											style="vertical-align: middle;"
										>
											<template v-if="d.rankCode === 'CHETAI'">
												<span class="text-error" title="Tạm dừng tự quản (Áp dụng chế tài)">—</span>
											</template>
											<template v-else-if="d.tcText === '—' && d.rankText === '—'">
												<span class="text-medium-emphasis">—</span>
											</template>
											<template v-else-if="d.rankCode === 'GV'">
												<div class="d-flex flex-column align-center justify-center">
													<span class="table-rank-badge rank-gvcn" style="font-size: 10px; padding: 1px 6px;">GV</span>
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
								:class="{ 'border-error': ['CD', 'CHETAI'].includes((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status) }"
							>
								<div class="pa-3">
									<div class="d-flex align-center justify-space-between mb-2">
										<div class="d-flex align-center ga-2">
											<span class="font-weight-medium text-subtitle-1" :class="['CD', 'CHETAI'].includes((row.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || row.w1).status) ? 'text-error font-weight-bold' : 'text-grey-darken-4'">
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
												<template v-if="d.rankCode === 'CHETAI'">
													<span class="text-error" style="font-size: 11px;" title="Tạm dừng tự quản (Áp dụng chế tài)">—</span>
												</template>
												<template v-else-if="d.tcText === '—' && d.rankText === '—'">
													<span class="text-medium-emphasis" style="font-size: 11px;">—</span>
												</template>
												<template v-else-if="d.rankCode === 'GV'">
													<span class="table-rank-badge rank-gvcn" style="font-size: 9px; padding: 0 4px;">GV</span>
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
							<div v-if="(monthEvaluationWeeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || {}).isOngoing">
								<strong>Tổng hợp Tuần {{ evidenceDialog.selectedWeekNum }}:</strong>
								Khối {{ selectedKhoi || 6 }} đang trong tuần đánh giá thứ {{ evidenceDialog.selectedWeekNum }}. Dữ liệu đang được ghi nhận theo nhật ký Quản sinh.
							</div>
							<div v-else-if="(monthEvaluationWeeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || {}).isFuture">
								<strong>Tổng hợp Tuần {{ evidenceDialog.selectedWeekNum }}:</strong>
								Khối {{ selectedKhoi || 6 }} chưa bước vào tuần đánh giá thứ {{ evidenceDialog.selectedWeekNum }} (Tháng {{ currentEvaluationMonth }}/2026).
							</div>
							<div v-else>
								<strong>Tổng hợp kết quả Tuần {{ evidenceDialog.selectedWeekNum }}:</strong>
								Khối {{ selectedKhoi || 6 }} có
								<strong class="text-success">{{ monthlyClassRecords.filter(r => ['T', 'D'].includes((r.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || r.w1).status)).length }} lớp Đạt</strong>,
								<strong class="text-primary">{{ monthlyClassRecords.filter(r => (r.weeks.find(x => x.weekNum === evidenceDialog.selectedWeekNum) || r.w1).status === 'DT').length }} lớp Duy trì</strong>,
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
									label="Phiếu giám sát ngày (kèm kết quả QS)"
									color="primary"
									class="mr-sm-6 mr-3 mb-1 font-weight-medium"
								/>
								<v-radio
									value="weekly_result"
									label="Sổ theo dõi cả tuần (kèm kết quả QS)"
									color="primary"
									class="mr-sm-6 mr-3 mb-1 font-weight-medium"
								/>
								<v-radio
									value="weekly"
									label="Sổ theo dõi cả tuần (phiếu trắng cho Sao đỏ)"
									color="primary"
									class="mr-sm-6 mr-3 mb-1 font-weight-medium"
								/>
								<v-radio
									value="bgh_summary"
									label="Báo cáo nề nếp tuần (Ban Giám hiệu)"
									color="primary"
									class="mb-1 font-weight-medium"
								/>
							</template>

							<!-- 2. Khi ở tab Quản sinh: -->
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
									class="mr-sm-6 mr-3 mb-1 font-weight-medium"
								/>
								<v-radio
									value="weekly_result"
									label="Sổ theo dõi cả tuần (kèm kết quả đã chấm)"
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

						<!-- Thống kê nề nếp tuần theo chuẩn 22/10 -->
						<div class="mb-3 pa-2 bg-blue-grey-lighten-5 rounded border text-caption d-flex align-center justify-space-between flex-wrap ga-2" style="font-size: 9.5pt;">
							<div>Tổng số lớp: <strong>{{ bghWeeklyReportClasses.length }} lớp</strong></div>
							<div>Đạt (Đ) (+0.5đ): <strong style="color: #16a34a;">{{ bghWeeklyReportStats.datCount }} lớp</strong></div>
							<div>Duy trì (DT): <strong style="color: #1565c0;">{{ bghWeeklyReportStats.duyTriCount }} lớp</strong></div>
							<div>Chưa đạt / Dừng TQ: <strong style="color: #c62828;">{{ bghWeeklyReportStats.cdCount }} lớp</strong></div>
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
												{{ d.code === 'CC' ? 'Chào cờ' : (d.code === 'CHETAI' ? 'Tạm dừng TQ' : (d.code === 'GV' ? 'GV' : (d.code === '—' ? '—' : ('[' + d.code + '] ' + d.statusText)))) }}
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
								{{ (printDialog.mode === 'weekly' || printDialog.mode === 'weekly_result') ? 'SỔ GIÁM SÁT 15 PHÚT TỰ QUẢN CẢ TUẦN' : 'PHIẾU GIÁM SÁT 15 PHÚT TỰ QUẢN ĐẦU GIỜ' }}
							</div>
							<div style="font-size: 11pt; font-style: italic;">
								{{ printDialog.mode === 'weekly' ? '(Phiếu trắng dùng cho Quản sinh khối & Đội Sao đỏ / Đoàn viên xung kích theo dõi)' : ((printDialog.mode === 'weekly_result') ? '(Bản tổng hợp kết quả Quản sinh đánh giá các ngày trong tuần)' : ((isBghRole || activeTab === 'baocao') ? '(Bản tổng hợp kết quả Quản sinh đánh giá gửi Ban Giám Hiệu)' : '(Dành cho Quản sinh khối & Đội Sao đỏ / Đoàn viên xung kích theo dõi)')) }}
							</div>
						</div>

						<div class="d-flex justify-space-between mb-3 text-body-2" style="font-size: 11pt;">
							<div><strong>{{ selectedKhoiName }}</strong></div>
							<div>{{ selectedWeek ? selectedWeek.title : 'Tuần học' }}</div>
							<div v-if="printDialog.mode === 'daily'">Ngày chấm: <strong>{{ currentDayLabel }}</strong></div>
						</div>

						<div class="text-caption mb-2 text-medium-emphasis" style="font-style: italic; font-size: 10pt;">
							* Hướng dẫn: Đánh giá từng phòng học: <strong>[Đ] = Đạt, [CĐ] = Chưa đạt</strong>. Ghi rõ mô tả cụ thể sự việc vào Bảng ghi nhận chi tiết (minh chứng).
						</div>

						<!-- Bảng ghi chú các tiêu chí (Legend) giúp tiêu đề bảng ngắn gọn, không bị co ép -->
						<div class="mb-3 pa-2 bg-grey-lighten-4 rounded border text-caption" style="font-size: 8.5pt; line-height: 1.4;">
							<div class="font-weight-bold text-grey-darken-3 mb-1">Nội dung chi tiết các tiêu chí (Hướng dẫn 22/10/2026):</div>
							<div class="d-flex flex-wrap ga-x-4 ga-y-1">
								<div v-for="(tc, i) in getMergedPrintCriteria()" :key="'legend-' + i">
									<strong>{{ 'TC' + (i + 1) + ': ' + getCriterionMainTitle(tc.ten) }}</strong> {{ getCriterionSubTitle(tc.ten) }}
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
											<div style="font-weight: bold;">{{ 'TC' + (i + 1) + ': ' + getCriterionMainTitle(tc.ten) }}</div>
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
													[DỪNG TỰ QUẢN]
												</span>
											</template>
											<template v-else-if="selectedDay === 2">
												<span style="color: #546e7a; display: block; font-size: 8pt;">(Sinh hoạt đầu tuần)</span>
											</template>
											<template v-else-if="cls.IsTuQuan">
												<span style="color: #2e7d32; display: block; font-size: 8pt;">(Lớp tự quản)</span>
											</template>
											<template v-else>
												<span style="color: #546e7a; display: block; font-size: 8pt;">(Chưa đăng ký TQ)</span>
											</template>
										</td>
										<td v-for="(tc, i) in getMergedPrintCriteria()" :key="i" style="padding: 2px 4px;">
											<!-- NẾU THỨ 2 HOẶC LỚP BỊ TẠM DỪNG TỰ QUẢN -->
											<div v-if="isClassBlocked(cls.LopID) || selectedDay === 2" style="color: #64748b; font-size: 11pt; font-weight: 500;">
												—
											</div>
											<!-- BGH XEM HOẶC IN KÈM KẾT QUẢ: NẾU KHÔNG TỰ QUẢN THÌ HIỆN GẠCH NGANG -->
											<div v-else-if="(isBghRole || activeTab === 'baocao') && !cls.IsTuQuan" style="color: #64748b; font-size: 11pt; font-weight: 500;">
												—
											</div>
											<!-- NẾU CÓ TIÊU CHÍ CHẤM -->
											<div v-else-if="isClassHavingCriteria(cls, tc)" style="white-space: nowrap; font-size: 8.5pt; display: inline-flex; gap: 6px; align-items: center; justify-content: center;">
												<template v-if="isBghRole || activeTab === 'baocao'">
													<!-- BGH: ĐÁNH DẤU VÀO THEO ĐÁNH GIÁ CỦA QUẢN SINH -->
													<span :style="{ fontWeight: findClassCriterion(cls, tc).score !== 1 ? 'bold' : 'normal', color: findClassCriterion(cls, tc).score !== 1 ? '#2e7d32' : '#888' }">
														{{ findClassCriterion(cls, tc).score !== 1 ? '[✓] Đ' : '[ ] Đ' }}
													</span>
													<span :style="{ fontWeight: findClassCriterion(cls, tc).score === 1 ? 'bold' : 'normal', color: findClassCriterion(cls, tc).score === 1 ? '#c62828' : '#888' }">
														{{ findClassCriterion(cls, tc).score === 1 ? '[✓] CĐ' : '[ ] CĐ' }}
													</span>
												</template>
												<template v-else>
													<!-- QUẢN SINH: PHIẾU TRẮNG CHO SAO ĐỎ ĐI CHẤM -->
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

							<!-- Bảng preview tuần CHUẨN MA TRẬN NGANG PHỤ LỤC A (VĂN BẢN 22/10) -->
							<div v-else>
								<div class="mb-2" style="font-weight: bold; font-size: 11pt; color: #1565c0; text-transform: uppercase;">
									Phần A. PHIẾU GIÁM SÁT HẰNG TUẦN (ÁP DỤNG TỪ THỨ BA ĐẾN THỨ SÁU)
								</div>
								<div style="overflow-x: auto;">
									<table style="width: 100%; border-collapse: collapse; font-size: 8pt; text-align: center; border: 1px solid #333;" border="1">
										<thead>
											<tr style="background-color: #f2f2f2; height: 26px;">
												<th rowspan="2" style="width: 28px; padding: 2px;">STT</th>
												<th rowspan="2" style="width: 50px; padding: 2px;">Lớp</th>
												<th colspan="4" style="padding: 2px;">THỨ BA<br><span style="font-size: 7pt; font-weight: normal;">({{ getDateStringForDay(3).split('-').slice(1).reverse().join('/') }})</span></th>
												<th colspan="4" style="padding: 2px;">THỨ TƯ<br><span style="font-size: 7pt; font-weight: normal;">({{ getDateStringForDay(4).split('-').slice(1).reverse().join('/') }})</span></th>
												<th colspan="4" style="padding: 2px;">THỨ NĂM<br><span style="font-size: 7pt; font-weight: normal;">({{ getDateStringForDay(5).split('-').slice(1).reverse().join('/') }})</span></th>
												<th colspan="4" style="padding: 2px;">THỨ SÁU<br><span style="font-size: 7pt; font-weight: normal;">({{ getDateStringForDay(6).split('-').slice(1).reverse().join('/') }})</span></th>
												<th colspan="5" style="padding: 2px; background-color: #e8eaf6;">TỔNG HỢP TUẦN</th>
												<th rowspan="2" style="min-width: 90px; padding: 2px; text-align: left;">Ghi chú</th>
											</tr>
											<tr style="background-color: #f8fafc; height: 22px; font-size: 7pt;">
												<th>TC1</th><th>TC2</th><th>TC3</th><th>KQ</th>
												<th>TC1</th><th>TC2</th><th>TC3</th><th>KQ</th>
												<th>TC1</th><th>TC2</th><th>TC3</th><th>KQ</th>
												<th>TC1</th><th>TC2</th><th>TC3</th><th>KQ</th>
												<th style="width: 42px;">Số ngày TQ</th>
												<th style="width: 32px;">Số ngày Đ</th>
												<th style="width: 38px;">Số ngày CCG</th>
												<th style="width: 32px;">Số ngày CĐ</th>
												<th style="width: 70px;">Xếp loại tuần</th>
											</tr>
										</thead>
										<tbody>
											<tr
												v-for="(row, idx) in weeklyClassMatrix"
												:key="'preview-matrix-row-' + row.LopID"
												style="height: 26px;"
												:style="{ backgroundColor: row.IsBlocked ? '#fff5f5' : (idx % 2 === 1 ? '#fafafa' : '#ffffff') }"
											>
												<td>{{ idx + 1 }}</td>
												<td style="font-weight: bold;" :style="{ color: row.IsBlocked ? '#c62828' : 'inherit' }">{{ row.TenLop }}</td>
												<!-- THỨ 3 -->
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 3).tc1 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 3).tc2 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 3).tc3 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}" :class="{ 'font-weight-bold': !row.IsBlocked }">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 3).kq }}</td>
												<!-- THỨ 4 -->
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 4).tc1 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 4).tc2 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 4).tc3 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}" :class="{ 'font-weight-bold': !row.IsBlocked }">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 4).kq }}</td>
												<!-- THỨ 5 -->
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 5).tc1 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 5).tc2 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 5).tc3 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}" :class="{ 'font-weight-bold': !row.IsBlocked }">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 5).kq }}</td>
												<!-- THỨ 6 -->
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 6).tc1 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 6).tc2 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 6).tc3 }}</td>
												<td :style="row.IsBlocked ? { background: 'repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px)' } : {}" :class="{ 'font-weight-bold': !row.IsBlocked }">{{ row.IsBlocked ? '' : getWeeklyMatrixCell(row, 6).kq }}</td>
												<!-- TỔNG HỢP -->
												<td>{{ printDialog.mode === 'weekly' ? '' : row.TuQuanCount }}</td>
												<td style="color: #2e7d32; font-weight: bold;">{{ printDialog.mode === 'weekly' ? '' : (row.DatCount || '') }}</td>
												<td style="color: #f59e0b; font-weight: bold;">{{ printDialog.mode === 'weekly' ? '' : (row.CcgCount || '') }}</td>
												<td style="color: #c62828; font-weight: bold;">{{ printDialog.mode === 'weekly' ? '' : (row.CdCount || '') }}</td>
												<td style="font-weight: bold;">{{ printDialog.mode === 'weekly' ? '' : row.XepLoaiTuan }}</td>
												<td style="text-align: left; padding: 1px 4px; font-size: 7.5pt;" :style="{ color: row.IsBlocked ? '#c62828' : 'inherit' }">
													{{ row.IsBlocked ? 'Chế tài do Tuần 1 Chưa đạt' : '' }}
												</td>
											</tr>
										</tbody>
									</table>
								</div>

								<!-- 2 Hộp chú thích chuẩn theo Phụ lục A -->
								<div class="d-flex ga-2 mt-2" style="font-size: 8pt; line-height: 1.35;">
									<div class="pa-2 border rounded" style="width: 50%; background-color: #fcfcfc;">
										<div style="font-weight: bold; margin-bottom: 2px;">Kí hiệu ghi phiếu:</div>
										<div>• Ô tiêu chí: <strong>Đ</strong> = Đạt; <strong>CĐ</strong> = Chưa đạt.</div>
										<div>• Ô KQ ngày: <strong>Đ</strong> / <strong>CCG</strong> (Cần cố gắng) / <strong>CĐ</strong>.</div>
										<div>• <strong>GV</strong> = Lớp đăng kí nhưng GVCN có mặt → không đánh giá, không tính là ngày tự quản (ghi "GV" vào ô KQ ngày).</div>
										<div>• <strong>/</strong> = Lớp không đăng kí tự quản ngày đó (gạch chéo cả 4 ô của ngày).</div>
										<div>• <strong>TC1:</strong> Lớp học thông thoáng, ngăn nắp; sàn, bảng sạch sẽ.</div>
										<div>• <strong>TC2:</strong> Hoạt động 15 phút có nội dung cụ thể.</div>
										<div>• <strong>TC3:</strong> Tập thể lớp tham gia nghiêm túc, tích cực.</div>
									</div>
									<div class="pa-2 border rounded" style="width: 50%; background-color: #fcfcfc;">
										<div style="font-weight: bold; margin-bottom: 2px;">Cách xếp loại (Mục III của Hướng dẫn):</div>
										<div>• <strong>Ngày:</strong> Đ = cả 3 TC Đạt; CCG = có 1 TC CĐ; CĐ = có từ 2 TC CĐ.</div>
										<div>• <strong>Tuần (tính trên số ngày tự quản thực tế):</strong></div>
										<div>- <strong>Đạt (Đ):</strong> từ 2 ngày trở lên và 100% số ngày xếp Đ → cộng 0,5 điểm thi đua.</div>
										<div>- <strong>Chưa đạt (CĐ):</strong> ≥ 50% số ngày xếp CĐ → dừng tự quản tuần tiếp theo.</div>
										<div>- <strong>Duy trì (DT):</strong> các trường hợp còn lại → không cộng điểm, tiếp tục tự quản.</div>
										<div style="font-style: italic; color: #555;">* Ngày CCG không tính là ngày Đ khi xét mức Đạt, không tính là ngày CĐ khi xét mức Chưa đạt.</div>
									</div>
								</div>

								<!-- PHẦN B. GHI NHẬN CHI TIẾT VÀ HƯỚNG DẪN ĐÁNH GIÁ (CHUẨN 22/10) -->
								<div class="mt-3">
									<div style="font-weight: bold; font-size: 10.5pt; color: #1565c0; margin-bottom: 3px;">
										Phần B. GHI NHẬN CHI TIẾT VÀ HƯỚNG DẪN ĐÁNH GIÁ
									</div>
									<div style="font-weight: bold; font-size: 9pt;">
										1. Bảng ghi nhận chi tiết các trường hợp Chưa đạt
									</div>
									<div style="font-style: italic; font-size: 8pt; color: #666; margin-bottom: 3px;">
										(Ghi ngay khi phát hiện, mô tả khách quan, cụ thể – làm căn cứ khi GVCN phản hồi trước 11:00)
									</div>
									<table style="width: 100%; border-collapse: collapse; font-size: 8pt; text-align: center; border: 1px solid #333;" border="1">
										<thead>
											<tr style="background-color: #f2f2f2; height: 22px;">
												<th style="width: 32px;">STT</th>
												<th style="width: 95px;">Thứ / Ngày</th>
												<th style="width: 55px;">Lớp</th>
												<th style="width: 85px;">Tiêu chí CĐ</th>
												<th style="text-align: left; padding-left: 6px;">Mô tả cụ thể sự việc (minh chứng)</th>
												<th style="width: 100px;">Người ghi nhận</th>
												<th style="width: 125px;">Quản sinh xác nhận đã báo GVCN</th>
											</tr>
										</thead>
										<tbody>
											<template v-if="printDialog.mode !== 'weekly' && getWeeklyViolationsForPrint().length > 0">
												<tr v-for="v in getWeeklyViolationsForPrint()" :key="'v-' + v.stt" style="height: 24px;">
													<td>{{ v.stt }}</td>
													<td>{{ v.thuNgay }}</td>
													<td style="font-weight: bold;">{{ v.lop }}</td>
													<td style="color: #c62828; font-weight: bold;">{{ v.tieuChiCD }}</td>
													<td style="text-align: left; padding-left: 6px;">{{ v.moTa }}</td>
													<td>{{ v.nguoiGhi }}</td>
													<td>{{ v.baoGVCN }}</td>
												</tr>
											</template>
											<template v-else>
												<tr v-for="n in 5" :key="'v-blank-' + n" style="height: 24px;">
													<td>{{ n }}</td>
													<td></td>
													<td></td>
													<td></td>
													<td></td>
													<td></td>
													<td></td>
												</tr>
											</template>
										</tbody>
									</table>

									<!-- 2. Biểu hiện cụ thể & 3. Quy trình ghi phiếu -->
									<div class="mt-2" style="font-size: 7.5pt;">
										<div style="font-weight: bold; font-size: 8.5pt; margin-bottom: 2px;">2. Biểu hiện cụ thể để xếp mức Đ/CĐ từng tiêu chí:</div>
										<table style="width: 100%; border-collapse: collapse; font-size: 7.5pt; border: 1px solid #333;" border="1">
											<thead>
												<tr style="background-color: #f2f2f2; height: 20px; text-align: center;">
													<th style="width: 28%;">Tiêu chí</th>
													<th style="width: 36%;">Ghi "Đ" (Đạt) khi</th>
													<th style="width: 36%;">Ghi "CĐ" (Chưa đạt) khi</th>
												</tr>
											</thead>
											<tbody>
												<tr>
													<td style="padding: 2px 4px; font-weight: bold;">TC1. Lớp học thông thoáng, ngăn nắp; sàn, bảng sạch sẽ.</td>
													<td style="padding: 2px 4px;">– Sàn sạch, không có rác; bảng đã được lau sạch.<br>– Bàn ghế, đồ dùng sắp xếp ngăn nắp.<br>– Lớp thông thoáng (cửa mở, đèn quạt phù hợp).</td>
													<td style="padding: 2px 4px; color: #c62828;">– Còn rác trên sàn, hộc bàn; bảng chưa lau.<br>– Bàn ghế, đồ dùng lộn xộn.<br>– Lớp bí, thiếu thông thoáng.</td>
												</tr>
												<tr>
													<td style="padding: 2px 4px; font-weight: bold;">TC2. Hoạt động 15 phút có nội dung cụ thể (đọc sách, chia sẻ...).</td>
													<td style="padding: 2px 4px;">– Có nội dung cụ thể, rõ ràng.<br>– BCS điều hành đúng khung 5 phút nền nếp + 10 phút chủ đề, bắt đầu đúng 07:15.</td>
													<td style="padding: 2px 4px; color: #c62828;">– Không có nội dung; học sinh ngồi tự do.<br>– Nội dung không rõ ràng hoặc lớp không bắt đầu hoạt động đúng giờ.</td>
												</tr>
												<tr>
													<td style="padding: 2px 4px; font-weight: bold;">TC3. Tập thể lớp tham gia nghiêm túc, tích cực.</td>
													<td style="padding: 2px 4px;">– Học sinh giữ trật tự, tập trung theo điều hành của BCS.<br>– Tích cực hưởng ứng, tham gia hoạt động.</td>
													<td style="padding: 2px 4px; color: #c62828;">– Nhiều học sinh làm việc riêng, ồn ào, đi lại tự do.<br>– Không hợp tác với BCS lớp.</td>
												</tr>
											</tbody>
										</table>

										<div style="font-weight: bold; font-size: 8.5pt; margin-top: 4px; margin-bottom: 2px;">3. Quy trình ghi phiếu:</div>
										<div style="line-height: 1.3; color: #333;">
											1. Chiều thứ Hai: Nhận lịch đăng kí tự quản; ghi tên lớp, gạch chéo (/) các ngày lớp không đăng kí.<br>
											2. 07:15 – 07:30 (thứ Ba – thứ Sáu): Đến từng lớp có đăng kí, ghi Đ/CĐ từng tiêu chí rồi ghi KQ ngày (Đ/CCG/CĐ). Nếu GVCN có mặt: ghi "GV", không đánh giá.<br>
											3. Khi có tiêu chí CĐ: Ghi mô tả cụ thể sự việc vào Bảng ghi nhận chi tiết (mục 1).<br>
											4. Trước 09:30: Quản sinh khối tổng hợp, thông báo kết quả ngày; GVCN phản hồi (nếu có) trước 11:00.<br>
											5. Thứ Sáu (trước 16:00): Tổng hợp tuần, xếp loại tuần (Đ/DT/CĐ), kí xác nhận và thông báo kết quả.
										</div>
									</div>
								</div>

								<div class="d-flex justify-end mt-2" style="font-style: italic; font-size: 9pt;">
									Trấn Biên, ngày ...... tháng 10 năm 2026
								</div>
							</div>
						</div>

						<!-- Kí tên cuối trang chuẩn Phụ lục A & B (22/10) -->
						<div class="d-flex justify-space-between mt-5 text-center" style="font-size: 10.5pt; page-break-inside: avoid;">
							<div style="width: 32%;">
								<div style="font-weight: bold;">BÍ THƯ ĐOÀN – TPT ĐỘI</div>
								<div style="font-style: italic; font-size: 9pt;">(Kí và ghi rõ họ tên)</div>
								<div style="height: 45px;"></div>
								<div style="font-weight: bold;">Lưu Quý Đồng</div>
							</div>
							<div style="width: 32%;">
								<div style="font-weight: bold;">QUẢN SINH KHỐI</div>
								<div style="font-style: italic; font-size: 9pt;">(Kí và ghi rõ họ tên)</div>
								<div style="height: 45px;"></div>
							</div>
							<div style="width: 32%;">
								<div style="font-weight: bold;">NGƯỜI GIÁM SÁT</div>
								<div style="font-style: italic; font-size: 9pt;">(Sao đỏ / ĐV xung kích)</div>
								<div style="height: 45px;"></div>
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
			currentUserCode: '',
			currentUserAccount: '',
			myHomeroomClasses: [],
			isRealAdmin: false,
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
			highlightedClassId: null,

			currentClasses: [],

			// 3 Tiêu chí cơ bản chuẩn: Không gian, Nội dung, Nề nếp
			baseCriteria: [
				{ id: 'c1', ten: 'TC1: Không gian (Sạch sẽ, bảng, sàn)', shortTitle: 'TC1: Không gian', score: 2, isCustom: false },
				{ id: 'c2', ten: 'TC2: Nội dung (Đọc sách, chủ đề)', shortTitle: 'TC2: Nội dung', score: 2, isCustom: false },
				{ id: 'c3', ten: 'TC3: Nề nếp (Nghiêm túc, tích cực)', shortTitle: 'TC3: Nề nếp', score: 2, isCustom: false }
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
			mockDateOverride: null,
			mockScenarioName: '',

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
				MaGVCN: 'NV0000134',
				Account: 'nguyennt',
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

			penaltyOverrides: {},
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
			var nowMs = new Date().getTime();
			var curIdx = this.weekList.findIndex(w => nowMs >= w.startMs && nowMs <= w.endMs);
			if (curIdx === -1) {
				curIdx = this.weekList.findIndex(w => w.startDate === '2026-10-12');
				if (curIdx === -1) curIdx = 0;
			}
			// Ở tab Báo cáo & Thi đua: ẨN LUÔN tuần sau, chỉ hiển thị tối đa đến tuần hiện tại (curIdx)
			// Ở tab Quản sinh hoặc GVCN: Cho phép xem trước 1 tuần kế tiếp (curIdx + 1) để đăng ký và in phiếu
			var maxIdx = (this.activeTab === 'baocao') ? curIdx : Math.min(this.weekList.length - 1, curIdx + 1);
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
			// Mở toàn bộ quy tắc chặn cho Quản sinh để mọi người demo tự do
			return false;
		},
		canModifyCriteria() {
			return !this.isBghRole;
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
						MaGVCN: item.MaGVCN,
						Account: item.Account,
						SiSo: item.SiSo,
						Khoi: k,
						label: 'Lớp ' + item.TenLop + ' — ' + item.TenGVCN
					});
				});
			});
			return all;
		},
		myGvcnClasses() {
			if (this.isGVCNRole) {
				if (this.myHomeroomClasses && this.myHomeroomClasses.length > 0) {
					return this.myHomeroomClasses;
				}
				var uId = (this.currentUserCode || '').toUpperCase();
				var userAcc = (this.currentUserAccount || '').toLowerCase();
				var teacherName = (this.currentUserName || '').toLowerCase().trim();
				var list = this.allSchoolClasses.filter(function(c) {
					return (c.MaGVCN && c.MaGVCN.toUpperCase() === uId) ||
						(c.Account && c.Account.toLowerCase() === userAcc) ||
						(c.TenGVCN && teacherName && (c.TenGVCN.toLowerCase() === teacherName || teacherName.includes(c.TenGVCN.toLowerCase())));
				});
				if (list.length) return list;
				var currentSelected = this.allSchoolClasses.find(c => String(c.LopID) === String(this.selectedGvcnClassId));
				return currentSelected ? [currentSelected] : (this.allSchoolClasses.slice(0, 1));
			}
			if (this.isRealAdmin) return this.allSchoolClasses;
			return this.allSchoolClasses;
		},
		availableGvcnClasses() {
			if (this.isGVCNRole) return this.myGvcnClasses;
			if (this.isRealAdmin) return this.allSchoolClasses;
			return this.allSchoolClasses;
		},
		showClassSelectorOnGvcn() {
			// GVCN tuyệt đối không được đổi lớp. Chỉ Quản sinh / BGH / Admin (khi không ở vai trò GVCN) mới thấy selector để hỗ trợ
			return !this.isGVCNRole;
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
				return res.code === 'D' || res.code === 'T';
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
				var isBlocked = that.isClassBlocked(cls.LopID);
				var hasPenaltyOverride = that.penaltyOverrides && (that.penaltyOverrides[cls.LopID] !== undefined);
				var isApplied = hasPenaltyOverride ? that.penaltyOverrides[cls.LopID] : isBlocked;

				if (isBlocked || isApplied) {
					result.push({
						LopID: cls.LopID,
						TenLop: cls.TenLop,
						TenKhoi: 'Khối ' + k,
						TenGVCN: cls.TenGVCN,
						SoLanViPham: cdCount,
						TotalTuQuanDays: totalTuQuanDays,
						IsThresholdMet: isBlocked,
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
			var m = this.currentEvaluationMonth;
			if (m === 9) {
				return '07/09/2026 – 04/10/2026';
			}
			if (m === 10) {
				return '05/10/2026 – 01/11/2026';
			}
			if (m === 11) {
				return '02/11/2026 – 29/11/2026';
			}
			if (m === 12) {
				return '30/11/2026 – 27/12/2026';
			}
			var mWeeks = (this.weekList || []).filter(w => w.month === m);
			if (mWeeks.length) {
				var startW = mWeeks[0];
				var endW = mWeeks[mWeeks.length - 1];
				var formatD = function(str) {
					var p = (str || '').split('-');
					return p.length === 3 ? (p[2] + '/' + p[1] + '/' + p[0]) : str;
				};
				return formatD(startW.startDate) + ' – ' + formatD(endW.endDate);
			}
			return '05/10/2026 – 01/11/2026';
		},
		monthProgressDescription() {
			var m = this.currentEvaluationMonth;
			var nowMs = new Date().getTime();
			var realWeek = (this.weekList || []).find(w => nowMs >= w.startMs && nowMs <= w.endMs);
			var realWeekNum = realWeek ? realWeek.weekNum : 4;
			var realMonth = realWeek ? realWeek.month : 10;

			if (m === 9) {
				return 'Chu kỳ Tháng 9/2026 đã hoàn thành trọn vẹn 4/4 tuần đánh giá (07/09 – 04/10/2026). Đã hoàn tất xét duyệt khen thưởng và cộng điểm thi đua (+02 điểm) cho các lớp tự quản tốt tháng 9.';
			}
			if (m > realMonth) {
				return 'Chu kỳ Tháng ' + m + '/2026 chưa diễn ra (' + this.monthCycleDateRange + '). Dữ liệu đối soát tự quản và xét duyệt thi đua sẽ bắt đầu được ghi nhận khi bước vào tuần đánh giá đầu tiên của tháng.';
			}
			if (m < realMonth) {
				return 'Chu kỳ Tháng ' + m + '/2026 đã kết thúc (' + this.monthCycleDateRange + '). Đã hoàn tất xét duyệt khen thưởng và cộng điểm thi đua.';
			}
			// m === realMonth (hiện tại là Tháng 10/2026)
			if (realWeekNum === 4) {
				return 'Đã hoàn thành 3/4 tuần đánh giá (Tuần 1, 2, 3). Tuần 4 đang diễn ra (26/10 – 01/11/2026). Danh hiệu thi đua và điểm cộng (+02 điểm) sẽ được xét duyệt chính thức sau ngày 01/11/2026 khi kết thúc đủ chu kỳ 4 tuần.';
			} else if (realWeekNum === 3) {
				return 'Đã hoàn thành Tuần 1, 2. Tuần 3 đang diễn ra (19/10 – 25/10/2026). Tuần 4 chưa tới. Danh hiệu thi đua và điểm cộng sẽ được xét duyệt sau ngày 01/11/2026.';
			}
			return 'Đã kết thúc Tuần 1 (05/10 - 11/10). Tuần 2 đang diễn ra (12/10 – 18/10/2026). Tuần 3 và 4 chưa tới. Danh hiệu thi đua và điểm cộng (+02 điểm) sẽ được xét duyệt chính thức sau ngày 01/11/2026 khi kết thúc đủ chu kỳ 4 tuần.';
		},
		monthlySummaryStats() {
			var m = this.currentEvaluationMonth;
			var nowMs = new Date().getTime();
			var realWeek = (this.weekList || []).find(w => nowMs >= w.startMs && nowMs <= w.endMs);
			var realWeekNum = realWeek ? realWeek.weekNum : 4;
			var realMonth = realWeek ? realWeek.month : 10;

			if (m === 9) {
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
			if (m > realMonth) {
				return {
					labelKhenThuong: 'Dẫn đầu tiến độ:',
					khenThuongCount: 0,
					khenThuongDetail: '0 lớp (Chu kỳ chưa bắt đầu)',
					showBieuDuong: false,
					bieuDuongCount: 0,
					bieuDuongDetail: '—',
					tamDungCount: 0,
					tamDungDetail: '0 lớp'
				};
			}
			if (realWeekNum >= 3) {
				return {
					labelKhenThuong: 'Dẫn đầu tiến độ (' + (realWeekNum - 1) + ' tuần Đạt):',
					khenThuongCount: 4,
					khenThuongDetail: '4 lớp (06A, 06C, 06E, 06G)',
					showBieuDuong: false,
					bieuDuongCount: 0,
					bieuDuongDetail: 'Xét sau 01/11',
					tamDungCount: 0,
					tamDungDetail: '0 lớp (06D đã chấn chỉnh xong)'
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
			var nowMs = new Date().getTime();
			var curWeek = (this.weekList || []).find(w => nowMs >= w.startMs && nowMs <= w.endMs);
			var realMonth = curWeek ? curWeek.month : 10;
			var realWeekNum = curWeek ? curWeek.weekNum : 4;

			var weeksDef = [];
			var mWeeks = (this.weekList || []).filter(w => w.month === m);
			if (mWeeks.length) {
				weeksDef = mWeeks.slice(0, 4).map(function(w) {
					var p1 = (w.startDate || '').split('-');
					var p2 = (w.endDate || '').split('-');
					var dStr = (p1[2] + '/' + p1[1]) + ' - ' + (p2[2] + '/' + p2[1]);
					return {
						weekNum: w.weekNum,
						label: 'Tuần ' + w.weekNum,
						dates: dStr
					};
				});
			} else {
				if (m === 9) {
					weeksDef = [
						{ weekNum: 1, label: 'Tuần 1', dates: '07/09 - 13/09' },
						{ weekNum: 2, label: 'Tuần 2', dates: '14/09 - 20/09' },
						{ weekNum: 3, label: 'Tuần 3', dates: '21/09 - 27/09' },
						{ weekNum: 4, label: 'Tuần 4', dates: '28/09 - 04/10' }
					];
				} else if (m === 11) {
					weeksDef = [
						{ weekNum: 1, label: 'Tuần 1', dates: '02/11 - 08/11' },
						{ weekNum: 2, label: 'Tuần 2', dates: '09/11 - 15/11' },
						{ weekNum: 3, label: 'Tuần 3', dates: '16/11 - 22/11' },
						{ weekNum: 4, label: 'Tuần 4', dates: '23/11 - 29/11' }
					];
				} else {
					weeksDef = [
						{ weekNum: 1, label: 'Tuần 1', dates: '05/10 - 11/10' },
						{ weekNum: 2, label: 'Tuần 2', dates: '12/10 - 18/10' },
						{ weekNum: 3, label: 'Tuần 3', dates: '19/10 - 25/10' },
						{ weekNum: 4, label: 'Tuần 4', dates: '26/10 - 01/11' }
					];
				}
			}

			return weeksDef.map(function(w) {
				var isPast = false;
				var isOngoing = false;
				var isFuture = false;
				var statusText = '';
				var statusClass = '';

				if (realMonth > m) {
					isPast = true;
					statusText = '(Đã xét)';
					statusClass = 'text-success';
				} else if (realMonth < m) {
					isFuture = true;
					statusText = '(Chưa tới)';
					statusClass = 'text-medium-emphasis';
				} else {
					if (w.weekNum < realWeekNum) {
						isPast = true;
						statusText = '(Đã xét)';
						statusClass = 'text-success';
					} else if (w.weekNum === realWeekNum) {
						isOngoing = true;
						statusText = '(Đang diễn ra)';
						statusClass = 'text-blue-darken-2';
					} else {
						isFuture = true;
						statusText = '(Chưa tới)';
						statusClass = 'text-medium-emphasis';
					}
				}

				return {
					weekNum: w.weekNum,
					label: w.label,
					dates: w.dates,
					isPast: isPast,
					isOngoing: isOngoing,
					isFuture: isFuture,
					statusText: statusText,
					statusClass: statusClass
				};
			});
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
							{ dayNum: 3, label: 'Thứ 3', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
							{ dayNum: 4, label: 'Thứ 4', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
							{ dayNum: 5, label: 'Thứ 5', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
							{ dayNum: 6, label: 'Thứ 6', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' }
						];
					};

					if (isAorC) {
						w1 = { weekNum: 1, label: 'Tuần 1', dates: '07/09 - 13/09', status: 'D', text: 'Đạt (Đ)', detail: '4/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '14/09 - 20/09', status: 'D', text: 'Đạt (Đ)', detail: '4/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w3 = { weekNum: 3, label: 'Tuần 3', dates: '21/09 - 27/09', status: 'D', text: 'Đạt (Đ)', detail: '4/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w4 = { weekNum: 4, label: 'Tuần 4', dates: '28/09 - 04/10', status: 'D', text: 'Đạt (Đ)', detail: '4/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };

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
							XepLoaiThang: 'Đạt chuẩn',
							IsLeading: false,
							IsRewardEligible: true,
							IsEffortReward: false,
							DeXuatKhenThuong: 'Lớp tự quản tốt (+02 điểm)',
							DiemThiDua: '+02 điểm chính thức',
							DanhHieu: 'Đạt chuẩn: Lớp tự quản tốt tháng 9'
						};
					} else if (isEorG) {
						w1 = { weekNum: 1, label: 'Tuần 1', dates: '07/09 - 13/09', status: 'D', text: 'Đạt (Đ)', detail: '3/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '14/09 - 20/09', status: 'D', text: 'Đạt (Đ)', detail: '3/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w3 = { weekNum: 3, label: 'Tuần 3', dates: '21/09 - 27/09', status: 'D', text: 'Đạt (Đ)', detail: '3/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w4 = { weekNum: 4, label: 'Tuần 4', dates: '28/09 - 04/10', status: 'D', text: 'Đạt (Đ)', detail: '3/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };

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
							XepLoaiThang: 'Đạt chuẩn',
							IsLeading: false,
							IsRewardEligible: false,
							IsEffortReward: true,
							DeXuatKhenThuong: 'Biểu dương nỗ lực (+01 điểm)',
							DiemThiDua: '+01 điểm chính thức',
							DanhHieu: 'Biểu dương: Nỗ lực nề nếp tự quản'
						};
					} else {
						w1 = { weekNum: 1, label: 'Tuần 1', dates: '07/09 - 13/09', status: 'D', text: 'Đạt (Đ)', detail: '2/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '14/09 - 20/09', status: 'D', text: 'Đạt (Đ)', detail: '2/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w3 = { weekNum: 3, label: 'Tuần 3', dates: '21/09 - 27/09', status: 'D', text: 'Đạt (Đ)', detail: '2/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };
						w4 = { weekNum: 4, label: 'Tuần 4', dates: '28/09 - 04/10', status: 'D', text: 'Đạt (Đ)', detail: '2/4 ngày Đạt', violations: 0, note: '', isPast: true, days: makeDays('D') };

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

			var nowMs = new Date().getTime();
			var realWeek = (that.weekList || []).find(w => nowMs >= w.startMs && nowMs <= w.endMs);
			var realMonth = realWeek ? realWeek.month : 10;

			// =================== CÁC THÁNG TƯƠNG LAI CHƯA TỚI (VÍ DỤ THÁNG 11) ===================
			if (m > realMonth) {
				return classList.map(function(cls, idx) {
					var makeEmptyDays = function() {
						return [
							{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
							{ dayNum: 3, label: 'Thứ 3', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
							{ dayNum: 4, label: 'Thứ 4', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
							{ dayNum: 5, label: 'Thứ 5', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
							{ dayNum: 6, label: 'Thứ 6', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' }
						];
					};
					var makeEmptyWeek = function(wNum) {
						var curW = (that.monthEvaluationWeeks || []).find(function(x) { return x.weekNum === wNum; }) || {};
						return {
							weekNum: wNum,
							label: 'Tuần ' + wNum,
							dates: curW.dates || '',
							status: 'FUTURE',
							text: 'Chưa diễn ra',
							detail: '',
							violations: 0,
							note: '—',
							isFuture: true,
							isPast: false,
							isCurrent: false,
							days: makeEmptyDays()
						};
					};
					var w1 = makeEmptyWeek(1), w2 = makeEmptyWeek(2), w3 = makeEmptyWeek(3), w4 = makeEmptyWeek(4);
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
						weeks: [w1, w2, w3, w4],
						SoTuanTot: 0,
						SoTuanCD: 0,
						XepLoaiThang: 'Chưa đánh giá',
						IsLeading: false,
						IsRewardEligible: false,
						IsEffortReward: false,
						DeXuatKhenThuong: 'Chưa diễn ra',
						DiemThiDua: '0 điểm',
						DanhHieu: ''
					};
				});
			}

			// =================== CHU KỲ THÁNG 10 (TIẾN ĐỘ THỜI GIAN THỰC TẾ) ===================
			return classList.map(function(cls, idx) {
				var streak = (that.baseStreaksByClass && that.baseStreaksByClass[cls.LopID]) || 0;
				var isBlockedThisWeek = that.weeklyBlockedClasses.some(function(b) { return b.LopID === cls.LopID && b.IsApplied; });
				var effectiveStreak = isBlockedThisWeek ? 0 : streak;

				var nowMs = new Date().getTime();
				var realWeek = (that.weekList || []).find(w => nowMs >= w.startMs && nowMs <= w.endMs);
				var realWeekNum = realWeek ? realWeek.weekNum : 4;
				var week4Obj = (that.weekList || []).find(w => w.month === 10 && w.weekNum === 4);
				var w1, w2, w3, w4;

				function makeFutureWeekDays() {
					return [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
						{ dayNum: 4, label: 'Thứ 4', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
						{ dayNum: 5, label: 'Thứ 5', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' },
						{ dayNum: 6, label: 'Thứ 6', tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' }
					];
				}

				function makeOngoingWeekDays(targetWeek) {
					var weekDays = [];
					var violations = [];
					var notes = [];
					var tgtW = targetWeek || week4Obj || that.selectedWeek;

					for (var dVal = 2; dVal <= 6; dVal++) {
						var dLabel = dVal === 2 ? 'Thứ 2' : (dVal === 3 ? 'Thứ 3' : (dVal === 4 ? 'Thứ 4' : (dVal === 5 ? 'Thứ 5' : 'Thứ 6')));
						var dateStr = that.getDateStringForDay(dVal, tgtW);
						var parts = dateStr.split('-');
						var dayDate = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
						dayDate.setHours(0, 0, 0, 0);
						var today = new Date();
						today.setHours(0, 0, 0, 0);
						var isFutureDay = dayDate.getTime() > today.getTime();

						if (isFutureDay) {
							weekDays.push({ dayNum: dVal, label: dLabel, tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' });
						} else if (dVal === 2) {
							// Thứ 2: Sinh hoạt đầu tuần, GVCN sinh hoạt cùng lớp
							weekDays.push({ dayNum: 2, label: dLabel, tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' });
						} else {
							// Lấy snapshot chấm điểm thực tế của Quản sinh cho lớp trong ngày dVal
							var sKey = dateStr + '_' + cls.LopID;
							var snap = that.dailySnapshots[sKey];
							if (snap && snap.IsSaved) {
								if (!snap.IsTuQuan) {
									weekDays.push({ dayNum: dVal, label: dLabel, tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' });
								} else {
									var tcs = snap.TieuChiList || [];
									var s1 = tcs[0] ? tcs[0].score : 2;
									var s2 = tcs[1] ? tcs[1].score : 2;
									var s3 = tcs[2] ? tcs[2].score : 2;
									var tcText = (s1 === 1 ? 'CĐ' : 'Đ') + '  ' +
									             (s2 === 1 ? 'CĐ' : 'Đ') + '  ' +
									             (s3 === 1 ? 'CĐ' : 'Đ');
									var cdC = (s1 === 1 ? 1 : 0) + (s2 === 1 ? 1 : 0) + (s3 === 1 ? 1 : 0);
									var rCode = cdC >= 2 ? 'CD' : (cdC === 1 ? 'CCG' : 'D');
									var rText = rCode === 'D' ? 'Đ' : (rCode === 'CCG' ? 'CCG' : 'CĐ');
									var rColor = rCode === 'D' ? '#16a34a' : (rCode === 'CCG' ? '#d97706' : '#dc2626');
									weekDays.push({ dayNum: dVal, label: dLabel, tcText: tcText, rankText: rText, rankCode: rCode, tcColor: rColor });

									if (rCode === 'CD' || rCode === 'CCG') {
										violations.push(dLabel);
									}
									if (snap.GhiChuViPham && snap.GhiChuViPham.trim()) {
										notes.push(dLabel + ': ' + snap.GhiChuViPham.trim());
									}
								}
							} else {
								weekDays.push({ dayNum: dVal, label: dLabel, tcText: '—', rankText: '—', rankCode: 'FUTURE', tcColor: '#94a3b8' });
							}
						}
					}

					var dynNote = '';
					if (notes.length > 0) {
						dynNote = notes.join('; ');
					} else if (violations.length > 0) {
						dynNote = 'Ghi nhận ngày ' + violations.join(', ');
					}

					return {
						days: weekDays,
						violations: violations.length,
						note: dynNote
					};
				}

				// 1. Tuần 1 (05/10 - 11/10): ĐÃ KẾT THÚC
				if (['06A', '06C', '06E', '06G'].includes(cls.TenLop)) {
					var detailStr = (cls.TenLop === '06A') ? '4/4 ngày Đạt' : '3/4 ngày Đạt';
					w1 = { weekNum: 1, label: 'Tuần 1', dates: '05/10 - 11/10', status: 'D', text: 'Đạt (Đ)', detail: detailStr, violations: 0, note: '', isPast: true };
				} else if (cls.TenLop === '06D') {
					w1 = { weekNum: 1, label: 'Tuần 1', dates: '05/10 - 11/10', status: 'CD', text: 'Chưa đạt', detail: '2 ngày CĐ', violations: 2, note: 'Vi phạm nề nếp 2 buổi (T4, T5) - Tạm dừng tự quản Tuần 2', isPast: true };
				} else {
					w1 = { weekNum: 1, label: 'Tuần 1', dates: '05/10 - 11/10', status: 'D', text: 'Đạt (Đ)', detail: '2/4 ngày Đạt', violations: 0, note: '', isPast: true };
				}

				var days1 = [];
				if (cls.TenLop === '06A' || ['06C', '06E', '06G'].includes(cls.TenLop)) {
					days1 = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' }
					];
				} else if (cls.TenLop === '06D') {
					days1 = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'Đ  CĐ  Đ', rankText: 'CCG', rankCode: 'CCG', tcColor: '#d97706' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'Đ  CĐ  CĐ', rankText: 'CĐ', rankCode: 'CD', tcColor: '#dc2626' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' }
					];
				} else {
					days1 = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' }
					];
				}
				w1.days = days1;

				// 2. Tuần 2 (12/10 - 18/10):
				if (realWeekNum > 2) {
					if (cls.TenLop === '06D') {
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '12/10 - 18/10', status: 'CHETAI', text: 'Tạm dừng TQ', detail: 'Chế tài Tuần 2', violations: 0, note: 'Chế tài do Tuần 1 Chưa đạt', isPast: true };
						w2.days = [
							{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
							{ dayNum: 3, label: 'Thứ 3', tcText: '—', rankText: '—', rankCode: 'CHETAI', tcColor: '#dc2626' },
							{ dayNum: 4, label: 'Thứ 4', tcText: '—', rankText: '—', rankCode: 'CHETAI', tcColor: '#dc2626' },
							{ dayNum: 5, label: 'Thứ 5', tcText: '—', rankText: '—', rankCode: 'CHETAI', tcColor: '#dc2626' },
							{ dayNum: 6, label: 'Thứ 6', tcText: '—', rankText: '—', rankCode: 'CHETAI', tcColor: '#dc2626' }
						];
					} else {
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '12/10 - 18/10', status: 'D', text: 'Đạt (Đ)', detail: '4/4 ngày Đạt', violations: 0, note: '', isPast: true };
						w2.days = [
							{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
							{ dayNum: 3, label: 'Thứ 3', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
							{ dayNum: 4, label: 'Thứ 4', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
							{ dayNum: 5, label: 'Thứ 5', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
							{ dayNum: 6, label: 'Thứ 6', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' }
						];
					}
				} else if (realWeekNum === 2) {
					if (cls.TenLop === '06D') {
						w2 = { weekNum: 2, label: 'Tuần 2', dates: '12/10 - 18/10', status: 'CHETAI', text: 'Tạm dừng TQ', detail: '', violations: 0, note: 'Chế tài do Tuần 1 Chưa đạt', isCurrent: true };
						w2.days = [
							{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
							{ dayNum: 3, label: 'Thứ 3', tcText: '—', rankText: '—', rankCode: 'CHETAI', tcColor: '#dc2626' },
							{ dayNum: 4, label: 'Thứ 4', tcText: '—', rankText: '—', rankCode: 'CHETAI', tcColor: '#dc2626' },
							{ dayNum: 5, label: 'Thứ 5', tcText: '—', rankText: '—', rankCode: 'CHETAI', tcColor: '#dc2626' },
							{ dayNum: 6, label: 'Thứ 6', tcText: '—', rankText: '—', rankCode: 'CHETAI', tcColor: '#dc2626' }
						];
					} else {
						var live2 = makeOngoingWeekDays();
						w2 = {
							weekNum: 2,
							label: 'Tuần 2',
							dates: '12/10 - 18/10',
							status: 'CURRENT',
							text: 'Đang diễn ra',
							detail: '',
							violations: live2.violations,
							note: live2.note,
							isCurrent: true,
							days: live2.days
						};
					}
				} else {
					w2 = { weekNum: 2, label: 'Tuần 2', dates: '12/10 - 18/10', status: 'FUTURE', text: 'Chưa diễn ra', detail: '', violations: 0, note: '', isFuture: true, days: makeFutureWeekDays() };
				}

				// 3. Tuần 3 (19/10 - 25/10):
				if (realWeekNum > 3) {
					w3 = { weekNum: 3, label: 'Tuần 3', dates: '19/10 - 25/10', status: 'D', text: 'Đạt (Đ)', detail: cls.TenLop === '06D' ? '3/4 ngày Đạt' : '4/4 ngày Đạt', violations: 0, note: cls.TenLop === '06D' ? 'Đã hoàn thành chấn chỉnh nề nếp' : '', isPast: true };
					w3.days = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' }
					];
				} else if (realWeekNum === 3) {
					var live3 = makeOngoingWeekDays();
					w3 = {
						weekNum: 3,
						label: 'Tuần 3',
						dates: '19/10 - 25/10',
						status: 'CURRENT',
						text: 'Đang diễn ra',
						detail: '',
						violations: live3.violations,
						note: live3.note,
						isCurrent: true,
						days: live3.days
					};
				} else {
					w3 = { weekNum: 3, label: 'Tuần 3', dates: '19/10 - 25/10', status: 'FUTURE', text: 'Chưa diễn ra', detail: '', violations: 0, note: '', isFuture: true, days: makeFutureWeekDays() };
				}

				// 4. Tuần 4 (26/10 - 01/11):
				if (realWeekNum === 4) {
					var live4 = makeOngoingWeekDays(week4Obj);
					w4 = {
						weekNum: 4,
						label: 'Tuần 4',
						dates: '26/10 - 01/11',
						status: 'CURRENT',
						text: 'Đang diễn ra',
						detail: '',
						violations: live4.violations,
						note: live4.note,
						isCurrent: true,
						days: live4.days
					};
				} else if (realWeekNum > 4) {
					w4 = { weekNum: 4, label: 'Tuần 4', dates: '26/10 - 01/11', status: 'D', text: 'Đạt (Đ)', detail: '4/4 ngày Đạt', violations: 0, note: '', isPast: true };
					w4.days = [
						{ dayNum: 2, label: 'Thứ 2', tcText: '—', rankText: '—', rankCode: 'NONE', tcColor: '#94a3b8' },
						{ dayNum: 3, label: 'Thứ 3', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 4, label: 'Thứ 4', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 5, label: 'Thứ 5', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' },
						{ dayNum: 6, label: 'Thứ 6', tcText: 'Đ  Đ  Đ', rankText: 'Đ', rankCode: 'D', tcColor: '#16a34a' }
					];
				} else {
					w4 = { weekNum: 4, label: 'Tuần 4', dates: '26/10 - 01/11', status: 'FUTURE', text: 'Chưa diễn ra', detail: '', violations: 0, note: '', isFuture: true, days: makeFutureWeekDays() };
				}

				var weeks = [w1, w2, w3, w4];
				var completedWeeks = weeks.filter(function(w) { return w.isPast; });
				var datCount = completedWeeks.filter(function(w) { return w.status === 'T' || w.status === 'D'; }).length;
				var cdCount = completedWeeks.filter(function(w) { return w.status === 'CD' || w.status === 'CHETAI'; }).length;

				var isLeading = (datCount >= 3 && cdCount === 0);
				var isBlocked = (w4.status === 'CHETAI');

				var xepLoaiThang = isBlocked ? 'Dừng TQ Tuần 4' : (isLeading ? 'Dẫn đầu tiến độ' : 'Đang duy trì');
				var deXuatKhenThuong = isLeading ? 'Đạt 3/3 tuần đã xét (+1,5 đ thi đua)' : (cdCount > 0 ? 'Đã chấn chỉnh nề nếp' : 'Đang theo dõi');
				var diemThiDua = isLeading ? '+1,5 điểm / 3 tuần' : '+1,0 điểm';

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
					SoTuanTot: datCount,
					SoTuanCD: cdCount,
					XepLoaiThang: xepLoaiThang,
					IsLeading: isLeading,
					IsRewardEligible: false,
					IsEffortReward: false,
					DeXuatKhenThuong: deXuatKhenThuong,
					DiemThiDua: diemThiDua,
					DanhHieu: isLeading ? 'Lớp dẫn đầu tiến độ (3 tuần Đạt)' : ''
				};
			});
		},
		rewardClasses() {
			var that = this;
			var m = this.currentEvaluationMonth;
			var nowMs = new Date().getTime();
			var realWeek = (that.weekList || []).find(w => nowMs >= w.startMs && nowMs <= w.endMs);
			var realMonth = realWeek ? realWeek.month : 10;

			if (m > realMonth) {
				return [];
			}

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
						TrangThai: r.IsRewardEligible ? 'Đã hoàn thành 4/4 tuần Đạt' : 'Đã hoàn thành 3/4 tuần Đạt',
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
			var curWeekNum = (this.selectedWeek && this.selectedWeek.weekNum) ? this.selectedWeek.weekNum : 4;
			return list.map(function(r) {
				return {
					LopID: r.LopID,
					TenLop: r.TenLop,
					TenKhoi: r.TenKhoi,
					TenGVCN: r.TenGVCN,
					SiSo: r.SiSo,
					SoTuanTot: r.SoTuanTot,
					SoTuanCD: r.SoTuanCD,
					TrangThai: curWeekNum >= 3 ? ('Đang dẫn đầu chu kỳ: Đạt ' + r.SoTuanTot + '/' + r.SoTuanTot + ' tuần đã xét') : 'Đang dẫn đầu chu kỳ: Tuần 1 Đạt (0 lỗi)',
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
				var datCount = 0;
				var ccgCount = 0;
				var cdCount = 0;
				var tuQuanCount = 0; // Số ngày tự quản thực tế

				that.daysOfWeek.forEach(function(d) {
					if (that.isSpecificDayInFuture(d.val)) {
						daysRes[d.val] = { code: 'FUTURE', text: '—', color: 'grey' };
						return;
					}
					var dayClasses = that.getClassesForPrintDay(d.val);
					var found = dayClasses.find(function(c) { return String(c.LopID) === String(cls.LopID); });
					var res = found ? that.getClassDailyResult(found, d.val) : { code: 'GVCN', text: '—', color: 'blue-grey' };
					daysRes[d.val] = res;

					// Chỉ tính ngày Tự quản thực tế (Thứ 3 - Thứ 6 và GVCN không có mặt)
					if (found && found.IsTuQuan && !found.GVCNCoMat && d.val !== 2) {
						tuQuanCount++;
						if (res.code === 'D') datCount++;
						else if (res.code === 'CCG') ccgCount++;
						else if (res.code === 'CD') cdCount++;
					}
				});

				var isBlocked = that.isClassBlocked(cls.LopID);
				var hasEvaluated = (datCount + ccgCount + cdCount > 0);
				var xepLoaiTuann = '—';
				var colorTuann = 'medium-emphasis';
				var bonusPoints = 0;

				var futureCount = that.daysOfWeek.filter(function(d) {
					return d.val !== 2 && that.isSpecificDayInFuture(d.val);
				}).length;

				// Chuẩn văn bản 22/10/2026:
				// Đánh giá hằng tuần (tính trên số ngày tự quản thực tế):
				// - Đạt (Đ): Có từ 02 ngày tự quản thực tế trở lên và 100% số ngày xếp Đạt -> Cộng 0,5 điểm thi đua
				// - Chưa đạt (CĐ): Từ 50% số ngày tự quản thực tế xếp CĐ trở lên -> Dừng tự quản tuần tiếp theo
				// - Duy trì (DT): Các trường hợp còn lại -> Không cộng điểm, lớp tiếp tục tự quản
				if (isBlocked) {
					xepLoaiTuann = 'Dừng tự quản';
					colorTuann = 'error';
				} else if (!hasEvaluated || tuQuanCount === 0) {
					xepLoaiTuann = '—';
					colorTuann = 'medium-emphasis';
				} else if (tuQuanCount > 0 && (cdCount / tuQuanCount) >= 0.5) {
					xepLoaiTuann = 'Chưa đạt (CĐ)';
					colorTuann = 'error';
				} else if (futureCount > 0 && tuQuanCount < 2 && cdCount === 0) {
					xepLoaiTuann = 'Đang diễn ra';
					colorTuann = 'info';
				} else if (tuQuanCount >= 2 && datCount === tuQuanCount) {
					xepLoaiTuann = 'Đạt (Đ)';
					colorTuann = 'success';
					bonusPoints = 0.5;
				} else {
					xepLoaiTuann = 'Duy trì (DT)';
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
					DatCount: datCount,
					CcgCount: ccgCount,
					CdCount: cdCount,
					XepLoaiTuan: xepLoaiTuann,
					XepLoaiColor: colorTuann,
					BonusPoints: bonusPoints,
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
				var gvcnPresent = (isMonday || !isTq) ? true : (cls.GVCNCoMat !== undefined ? !!cls.GVCNCoMat : false);
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
					NguoiCham: (isMonday || !isTq) ? '' : (cls.NguoiCham || (cls.RawItem && cls.RawItem.NguoiCham) || (that.currentUserName ? ('QS. ' + that.currentUserName) : 'QS. Trần Tuấn')),
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
		canSwitchRole() {
			return !!this.isRealAdmin;
		},
		isDevOrAdminRole() {
			return this.currentSystemRight === 9 || this.currentSystemRight === 5;
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
			var dat = 0;
			var duyTri = 0;
			var blocked = 0;
			classes.forEach(function(c) {
				if (c.isApplied || c.xepLoaiTuan === 'Tạm dừng TQ' || c.xepLoaiTuan === 'Chưa đạt (CĐ)' || c.xepLoaiTuan === 'Chưa đạt') {
					blocked++;
				} else if (c.xepLoaiTuan === 'Đạt (Đ)' || c.xepLoaiTuan === 'Đạt') {
					dat++;
				} else {
					duyTri++;
				}
			});
			return {
				total: classes.length,
				datCount: dat,
				duyTriCount: duyTri,
				cdCount: blocked
			};
		}
	},
	watch: {
		activeTab(newTab) {
			if (newTab) {
				try {
					sessionStorage.setItem('lastActiveTab', newTab);
					localStorage.setItem('lastActiveTab', newTab);
				} catch (e) {}
			}
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
				this.onWeekSelected();
			}
			if (newTab === 'quansinh') {
				this.loadClassesForCurrentDay();
			} else if (newTab === 'gvcn') {
				if (this.selectedGvcnClassId) {
					this.loadGvcnScheduleForClass(this.selectedGvcnClassId);
					this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
				}
			}
		},
		selectedGvcnClassId(newVal) {
			if (newVal) {
				try {
					sessionStorage.setItem('lastSelectedGvcnClassId', String(newVal));
					localStorage.setItem('lastSelectedGvcnClassId', String(newVal));
				} catch (e) {}
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
		if (this.selectedWeek && this.selectedWeek.weekNum) {
			this.outerMonthlySelectedWeekNum = this.selectedWeek.weekNum;
			this.evidenceDialog.selectedWeekNum = this.selectedWeek.weekNum;
		}
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
		this.gvcnClassInfo.TrangThaiLop = this.isClassBlocked(this.selectedGvcnClassId) ? 2 : 1;
		this.loadGvcnScheduleForClass(this.selectedGvcnClassId);
		this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
		var now = new Date();
		this.lastSavedTime = String(now.getHours()).padStart(2, '0') + ':' + String(now.getMinutes()).padStart(2, '0');
		this.qsLastSavedTime = this.lastSavedTime;
		this.fetchWeekDataFromApi();
	},
	mounted() {
		this.initUserRole();
		this.fetchWeekDataFromApi();
	},
	methods: {
		callApi(endpoint, params, callback) {
			try {
				if (typeof ajaxCALL === 'function') {
					ajaxCALL(endpoint, params, function(res) {
						if (typeof callback === 'function') {
							callback(res);
						}
					});
				} else if (typeof ajaxCALLPromise === 'function') {
					ajaxCALLPromise(endpoint, params).then(function(res) {
						if (typeof callback === 'function') {
							callback(res);
						}
					}).catch(function(err) {
						console.warn('API error (' + endpoint + '):', err);
						if (typeof callback === 'function') {
							callback(null);
						}
					});
				} else {
					if (typeof callback === 'function') {
						callback(null);
					}
				}
			} catch (e) {
				console.warn('Error invoking API ' + endpoint + ':', e);
				if (typeof callback === 'function') {
					callback(null);
				}
			}
		},
		fetchWeekDataFromApi() {
			if (!this.selectedWeek) return;
			var that = this;
			var curWeek = this.selectedWeek;
			var weekId = curWeek.id;
			var startDate = curWeek.startDate;
			var endDate = curWeek.endDate;

			// 1. Tải lịch tự quản của tất cả các lớp trong tuần từ database backend
			this.callApi('lms/TuQuan_DangKyLich_Get', { StartDate: startDate, TuanHocID: weekId }, function(res) {
				var rows = res;
				if (res && res.data) rows = res.data;
				if (Array.isArray(rows) && rows.length > 0) {
					var groups = {};
					rows.forEach(function(r) {
						var k = (r.TuanHocID || weekId) + '_' + r.LopID;
						if (!groups[k]) groups[k] = [];
						groups[k].push({
							key: r.key || r.Thu,
							label: r.label,
							date: r.date,
							IsTuQuan: (r.IsTuQuan === true || r.IsTuQuan === 1 || r.IsTuQuan === '1'),
							CoMat: (r.CoMat === true || r.CoMat === 1 || r.CoMat === '1'),
							isFixed: (r.key === 2 || r.Thu === 2),
							GhiChu: r.GhiChu || ''
						});
					});
					for (var cacheKey in groups) {
						that.gvcnSchedulesByClass[cacheKey] = groups[cacheKey];
					}
					that.saveSchedulesToLocalStorage();
					if (that.selectedGvcnClassId) {
						that.loadGvcnScheduleForClass(that.selectedGvcnClassId);
					}
					that.evalUpdateVersion++;
				}
			});

			// 2. Tải toàn bộ đánh giá nề nếp của Quản sinh trong tuần từ database backend
			this.callApi('lms/TuQuan_DanhGiaNgay_Get', { StartDate: startDate, EndDate: endDate }, function(res) {
				var rows = res;
				if (res && res.data) rows = res.data;
				if (Array.isArray(rows) && rows.length > 0) {
					rows.forEach(function(r) {
						var snapKey = r.NgayYMD + '_' + r.LopID;
						var tieuChi = [];
						try {
							if (typeof r.TieuChiList === 'string') {
								tieuChi = JSON.parse(r.TieuChiList);
							} else if (Array.isArray(r.TieuChiList)) {
								tieuChi = r.TieuChiList;
							}
						} catch (e) {}

						that.dailySnapshots[snapKey] = {
							TieuChiList: tieuChi,
							GhiChuViPham: r.GhiChuViPham || '',
							IsTuQuan: (r.IsTuQuan === true || r.IsTuQuan === 1 || r.IsTuQuan === '1'),
							GVCNCoMat: (r.GVCNCoMat === true || r.GVCNCoMat === 1 || r.GVCNCoMat === '1'),
							IsSaved: true,
							NguoiCham: r.NguoiCham || 'Quản sinh khối'
						};
					});
					that.dailySnapshots = Object.assign({}, that.dailySnapshots);
					that.saveSnapshotsToLocalStorage();
					that.evalUpdateVersion++;
					that.loadClassesForCurrentDay();
					if (that.selectedGvcnClassId) {
						that.loadGvcnHistoryForClass(that.selectedGvcnClassId);
					}
				}
			});
		},
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
					window.localStorage.setItem('lhbs_gvcn_schedules_cache_v4', JSON.stringify(this.gvcnSchedulesByClass));
				}
			} catch (e) {
				console.warn('Cannot write localStorage:', e);
			}
		},
		loadSchedulesFromLocalStorage() {
			try {
				if (typeof window !== 'undefined' && window.localStorage) {
					// Dọn dẹp cache cũ để tránh nạp lại cấu hình tự động đăng ký trước đó
					if (window.localStorage.getItem('lhbs_gvcn_schedules_cache')) {
						window.localStorage.removeItem('lhbs_gvcn_schedules_cache');
					}
					if (window.localStorage.getItem('lhbs_gvcn_schedules_cache_v2')) {
						window.localStorage.removeItem('lhbs_gvcn_schedules_cache_v2');
					}
					if (window.localStorage.getItem('lhbs_gvcn_schedules_cache_v3')) {
						window.localStorage.removeItem('lhbs_gvcn_schedules_cache_v3');
					}
					var raw = window.localStorage.getItem('lhbs_gvcn_schedules_cache_v4');
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

			// Đồng bộ ngay tức thì bộ nhớ cache in-memory để các tab Quản sinh / Báo cáo thấy ngay
			this.gvcnSchedulesByClass[cacheKey] = JSON.parse(JSON.stringify(this.gvcnWeekSchedule));
			this.saveSchedulesToLocalStorage();

			var that = this;
			var wait = (delayMs !== undefined) ? delayMs : 400;
			this.autoSaveTimer = setTimeout(function() {
				that.lastSavedTime = that.formatCurrentTime();
				that.autoSaveStatus = 'saved';

				// GỌI API LƯU VÀO DATABASE BACKEND
				// Khi lưu lịch GVCN: ưu tiên lưu mã/tài khoản của GVCN phụ trách lớp đó
				// (để nếu Admin thao tác hộ thì hệ thống vẫn ghi nhận là GVCN của lớp đó thực hiện)
				var gvcnUserCode = (that.gvcnClassInfo && (that.gvcnClassInfo.Account || that.gvcnClassInfo.MaGVCN))
					|| (function() {
						if (!that.allSchoolClasses) return null;
						var c = that.allSchoolClasses.find(function(x) { return String(x.LopID) === String(lopId); });
						return c ? (c.Account || c.MaGVCN || c.TenGVCN) : null;
					})()
					|| that.currentUserCode || that.currentUserName || 'GVCN';

				var payload = {
					LopID: parseInt(lopId, 10),
					TuanHocID: parseInt(weekId, 10),
					StartDate: (that.selectedWeek && that.selectedWeek.startDate) ? that.selectedWeek.startDate : '',
					EndDate: (that.selectedWeek && that.selectedWeek.endDate) ? that.selectedWeek.endDate : '',
					ScheduleJson: JSON.stringify(that.gvcnWeekSchedule),
					UserCode: gvcnUserCode
				};
				that.callApi('lms/TuQuan_DangKyLich_Save', payload, function(res) {
					console.log('[API TuQuan_DangKyLich_Save]:', res);
				});
			}, wait);
		},
		autoSaveDailyEvaluation(delayMs) {
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
						GVCNCoMat: !!c.GVCNCoMat,
						IsSaved: true,
						NguoiCham: c.NguoiCham || that.currentUserName || 'Quản sinh khối'
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

				// GỌI API LƯU ĐÁNH GIÁ VÀO DATABASE BACKEND
				var evalsToSave = that.currentClasses.map(function(c) {
					var xepLoai = 'DAT';
					var cdCount = 0;
					if (c.TieuChiList) {
						c.TieuChiList.forEach(function(tc) {
							if (tc.score === 1) cdCount++;
						});
					}
					if (cdCount >= 2) xepLoai = 'CD';
					else if (cdCount === 1) xepLoai = 'CCG';

					return {
						LopID: parseInt(c.LopID, 10),
						IsTuQuan: !!c.IsTuQuan,
						GVCNCoMat: !!c.GVCNCoMat,
						TieuChiList: c.TieuChiList,
						GhiChuViPham: c.GhiChuViPham || '',
						NguoiCham: c.NguoiCham || that.currentUserName || 'Quản sinh khối',
						XepLoai: xepLoai
					};
				});

				var payload = {
					Ngay: dateStr,
					TuanHocID: (that.selectedWeek && that.selectedWeek.id) ? that.selectedWeek.id : 1,
					EvaluationsJson: JSON.stringify(evalsToSave),
					UserCode: that.currentUserCode || that.currentUserName || 'Quản sinh khối'
				};
				that.callApi('lms/TuQuan_DanhGiaNgay_Save', payload, function(res) {
					console.log('[API TuQuan_DanhGiaNgay_Save]:', res);
				});
			}, wait);
		},
		toggleGvcnPresent(cls) {
			if (!cls) return;

			var isCurrentlyPresent = !!cls.GVCNCoMat || !cls.IsTuQuan;
			if (isCurrentlyPresent) {
				// Chuyển lại thành Lớp tự quản để Quản sinh chấm điểm
				cls.GVCNCoMat = false;
				cls.IsTuQuan = true;
				if (cls.GhiChuViPham && cls.GhiChuViPham.indexOf('GVCN có mặt') !== -1) {
					cls.GhiChuViPham = '';
				}
				this.showNotice('Lớp ' + cls.TenLop + ': Đã chuyển lại thành Lớp tự quản', 'info');
			} else {
				// Đánh dấu GVCN có mặt (Ghi nhận "GV" theo Hướng dẫn 22/10)
				cls.GVCNCoMat = true;
				cls.IsTuQuan = false;
				this.showNotice('Đã ghi nhận Lớp ' + cls.TenLop + ': GVCN có mặt (GV) — Không đánh giá tự quản', 'success');
			}

			this.currentClasses = [...this.currentClasses];
			this.evalUpdateVersion++;
			this.autoSaveDailyEvaluation(200);
		},
		onQsNoteChange() {
			this.evalUpdateVersion++;
			this.autoSaveDailyEvaluation(600);
		},
		onNoteInput() {
			this.autoSaveGvcnSchedule(400);
		},
		initUserRole() {
			var user = (typeof vueData !== 'undefined' && vueData && vueData.user)
				? vueData.user
				: (typeof window !== 'undefined' && window.vueData && window.vueData.user ? window.vueData.user : null);
			if (!user) {
				try {
					var storedUser = localStorage.getItem('user') || sessionStorage.getItem('user');
					if (storedUser) user = JSON.parse(storedUser);
				} catch (e) {}
			}
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

				var uId = String(user.UserID || user.MaNhanVien || user.UserCode || user.UserName || user.Account || '').trim().toUpperCase();
				this.currentUserCode = uId;
				var userAcc = String(user.Account || user.UserName || '').trim().toLowerCase();
				this.currentUserAccount = userAcc;

				// Kiểm tra vai trò Admin thực tế (chỉ Admin thực sự mới được thấy nút chuyển vai trò)
				// Ban Giám hiệu (3, 5), Quản sinh (4), Giáo viên chủ nhiệm (1) trên máy thực tế KHÔNG BAO GIỜ THẤY nút này.
				var realSr = (sr != null && !isNaN(Number(sr))) ? Number(sr) : 0;
				var isAdm = false;
				if (realSr === 9 || user.SystemRight === 9 || user.IsSuperAdmin === 1 || user.IsSuperAdmin === true || ['DEV000054', 'NA0000022'].includes(uId)) {
					isAdm = true;
				}
				if ([1, 3, 4, 5].includes(realSr) && !['DEV000054', 'NA0000022'].includes(uId)) {
					isAdm = false;
				}
				this.isRealAdmin = isAdm;

				var that = this;

				// 1. Nhận diện sơ bộ từ danh sách lớp có sẵn trong client (chỉ áp dụng cho tài khoản giáo viên, KHÔNG gán cho Admin)
				var matchedClasses = [];
				if (!isAdm) {
					if (uId) {
						matchedClasses = this.allSchoolClasses.filter(function(c) {
							return (c.MaGVCN && c.MaGVCN.toUpperCase() === uId) ||
								(c.Account && c.Account.toUpperCase() === uId);
						});
					}
					if (!matchedClasses.length && userAcc) {
						matchedClasses = this.allSchoolClasses.filter(function(c) {
							return (c.Account && c.Account.toLowerCase() === userAcc) ||
								(c.MaGVCN && c.MaGVCN.toLowerCase() === userAcc);
						});
					}
					if (!matchedClasses.length && user.LopID) {
						matchedClasses = this.allSchoolClasses.filter(function(c) {
							return String(c.LopID) === String(user.LopID);
						});
					}
					if (!matchedClasses.length) {
						var teacherName = (this.currentUserName || user.FullName || user.DisplayName || '').toLowerCase().trim();
						if (teacherName) {
							matchedClasses = this.allSchoolClasses.filter(function(c) {
								var gvName = (c.TenGVCN || '').toLowerCase().trim();
								return gvName && (gvName === teacherName || teacherName.includes(gvName) || gvName.includes(teacherName));
							});
						}
					}
				}

				if (matchedClasses.length > 0) {
					this.myHomeroomClasses = matchedClasses;
					if (this.currentSystemRight === 1 || user.SystemRight === 1 || !this.isBghOrAdmin) {
						this.currentSystemRight = 1;
						this.activeTab = 'gvcn';
					}
					var target = matchedClasses[0];
					this.selectedGvcnClassId = String(target.LopID);
					this.gvcnClassInfo.LopID = target.LopID;
					this.gvcnClassInfo.TenLop = target.TenLop;
					this.gvcnClassInfo.TenGVCN = target.TenGVCN;
					this.gvcnClassInfo.SiSo = target.SiSo;
					this.gvcnClassInfo.TrangThaiLop = this.isClassBlocked(target.LopID) ? 2 : 1;
					if (target.Khoi) {
						this.selectedKhoi = target.Khoi;
					}
					if (!this.currentUserName || this.currentUserName === 'Quản sinh khối') {
						this.currentUserName = target.TenGVCN;
					}
				} else {
					this.myHomeroomClasses = [];
					var savedTab = null;
					var savedClassId = null;
					try {
						savedTab = sessionStorage.getItem('lastActiveTab') || localStorage.getItem('lastActiveTab');
						savedClassId = sessionStorage.getItem('lastSelectedGvcnClassId') || localStorage.getItem('lastSelectedGvcnClassId');
					} catch (e) {}

					if (savedTab) {
						this.activeTab = savedTab;
					} else if (this.currentSystemRight === 3 || this.currentSystemRight === 5) {
						this.activeTab = 'baocao';
					} else if (this.currentSystemRight === 1) {
						this.activeTab = 'gvcn';
					} else {
						this.activeTab = 'quansinh';
					}

					// Với Admin / Quản sinh: Khôi phục lớp đã chọn trước đó (nếu có) hoặc mặc định lớp đầu tiên (06A)
					var defaultClass = null;
					if (savedClassId) {
						defaultClass = this.allSchoolClasses.find(function(c) { return String(c.LopID) === String(savedClassId); });
					}
					if (!defaultClass && this.allSchoolClasses && this.allSchoolClasses.length > 0) {
						defaultClass = this.allSchoolClasses[0];
					}

					if (defaultClass) {
						this.selectedGvcnClassId = String(defaultClass.LopID);
						this.gvcnClassInfo.LopID = defaultClass.LopID;
						this.gvcnClassInfo.TenLop = defaultClass.TenLop;
						this.gvcnClassInfo.TenGVCN = defaultClass.TenGVCN;
						this.gvcnClassInfo.MaGVCN = defaultClass.MaGVCN || '';
						this.gvcnClassInfo.Account = defaultClass.Account || '';
						this.gvcnClassInfo.SiSo = defaultClass.SiSo;
						this.gvcnClassInfo.TrangThaiLop = this.isClassBlocked(defaultClass.LopID) ? 2 : 1;
						if (defaultClass.Khoi) {
							this.selectedKhoi = defaultClass.Khoi;
						}
					}
				}

				// 2. Gọi API lms/Lop_Get_ByGVCN của hệ thống để xác nhận chính xác từ Database máy chủ (chỉ dành cho giáo viên, không áp dụng cho Admin)
				if (!isAdm) {
					this.callApi('lms/Lop_Get_ByGVCN', { NienKhoa: 2026 }, function(res) {
						var rows = res;
						if (res && res.data) rows = res.data;
						if (Array.isArray(rows) && rows.length > 0) {
							var serverList = [];
							rows.forEach(function(r) {
								// Nếu TenLop từ DB là nhóm tổ hợp (như 10A1, 10A2, 11B1, 11B2, 12C1, 12C2), quy về lớp gốc 10A, 11B, 12C
								var baseName = (r.TenLop || '').replace(/[12]$/, '').trim();
								var found = that.allSchoolClasses.find(function(c) {
									return String(c.LopID) === String(r.LopID) ||
										c.TenLop.toLowerCase() === (r.TenLop || '').toLowerCase() ||
										c.TenLop.toLowerCase() === baseName.toLowerCase();
								});
								if (found) {
									if (!serverList.some(function(x) { return String(x.LopID) === String(found.LopID); })) {
										serverList.push(found);
									}
								} else {
									serverList.push({
										LopID: String(r.LopID),
										TenLop: r.TenLop,
										TenGVCN: that.currentUserName,
										Khoi: r.KhoiID,
										label: 'Lớp ' + r.TenLop + (that.currentUserName ? ' — ' + that.currentUserName : '')
									});
								}
							});

							that.myHomeroomClasses = serverList;

							// Nếu không phải BGH/Admin thì chuyển ngay về chế độ GVCN của lớp này
							if (!that.isBghOrAdmin) {
								that.currentSystemRight = 1;
								that.activeTab = 'gvcn';
							}

							var currentTarget = serverList.find(function(c) {
								return String(c.LopID) === String(that.selectedGvcnClassId);
							}) || serverList[0];

							if (currentTarget) {
								that.selectedGvcnClassId = String(currentTarget.LopID);
								that.gvcnClassInfo.LopID = currentTarget.LopID;
								that.gvcnClassInfo.TenLop = currentTarget.TenLop;
								that.gvcnClassInfo.TenGVCN = currentTarget.TenGVCN;
								that.gvcnClassInfo.SiSo = currentTarget.SiSo;
								that.gvcnClassInfo.TrangThaiLop = that.isClassBlocked(currentTarget.LopID) ? 2 : 1;
								if (currentTarget.Khoi) {
									that.selectedKhoi = currentTarget.Khoi;
								}
								if (!that.currentUserName || that.currentUserName === 'Quản sinh khối') {
									that.currentUserName = currentTarget.TenGVCN;
								}
								that.loadGvcnScheduleForClass(currentTarget.LopID);
								that.loadGvcnHistoryForClass(currentTarget.LopID);
							}
						}
					});
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
				var curClassId = this.selectedGvcnClassId;
				try {
					curClassId = curClassId || sessionStorage.getItem('lastSelectedGvcnClassId') || localStorage.getItem('lastSelectedGvcnClassId');
				} catch (e) {}
				var gvClass = null;
				if (curClassId) {
					gvClass = this.allSchoolClasses.find(function(c) { return String(c.LopID) === String(curClassId); });
				}
				if (!gvClass) {
					gvClass = this.allSchoolClasses.find(function(c) { return c.TenLop === '06A'; }) || this.allSchoolClasses[0];
				}
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

				var title = 'Tuần ' + weekInMonth + ' - Tháng ' + month + ' (' + d1 + ' - ' + d2 + ')';

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
			if (this.isPastDay || this.isTodayQsLocked || this.isBghRole || !dateStr || !this.currentClasses || this.currentClasses.length === 0) return;
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
			this.currentActiveDateStr = this.getDateStringForDay(this.selectedDay);
			if (this.selectedWeek && this.selectedWeek.weekNum) {
				this.outerMonthlySelectedWeekNum = this.selectedWeek.weekNum;
				this.evidenceDialog.selectedWeekNum = this.selectedWeek.weekNum;
			}
			this.loadClassesForCurrentDay();
			if (this.selectedGvcnClassId) {
				if (this.gvcnClassInfo) {
					this.gvcnClassInfo.TrangThaiLop = this.isClassBlocked(this.selectedGvcnClassId) ? 2 : 1;
				}
				this.loadGvcnScheduleForClass(this.selectedGvcnClassId);
				this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
			}
			this.fetchWeekDataFromApi();
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
			var d = new Date();
			if (this.mockDateOverride) {
				d = new Date(this.mockDateOverride.getTime());
			}
			if (this.mockHourOverride !== null && this.mockHourOverride !== undefined) {
				d.setHours(this.mockHourOverride, this.mockMinuteOverride || 0, 0, 0);
			}
			return d;
		},
		isPastQsCutoffTime() {
			var now = this.getCurrentTimeForRules();
			var hours = now.getHours();
			var minutes = now.getMinutes();
			return (hours > 9) || (hours === 9 && minutes >= 30);
		},
		isPastGvcnCutoffTime() {
			return this.isGvcnRegistrationLockedForSelectedWeek();
		},
		isGvcnRegistrationLockedForSelectedWeek() {
			// Mở toàn quyền đăng ký cho demo
			return false;
		},
		getGvcnLockReasonMessage() {
			return '';
		},
		isDayGvcnLocked(dayKey) {
			// Mở toàn quyền đăng ký cho demo
			return false;
		},
		setMockDateAndHour(scenario, hour) {
			if (!scenario) {
				this.mockDateOverride = null;
				this.mockScenarioName = '';
				this.mockHourOverride = null;
				this.mockMinuteOverride = 0;
				this.evalUpdateVersion++;
				this.showNotice('Đã chuyển về thời gian thực tế hệ thống', 'info');
				return;
			}
			var startStr = (this.selectedWeek && this.selectedWeek.startDate) || '2026-10-05';
			var parts = startStr.split('-');
			var monday = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
			if (scenario === 'monday_morning') {
				// Sáng Thứ Hai lúc 09:00 (trong khung mở đăng ký)
				var d = new Date(monday.getTime());
				d.setHours(hour || 9, 0, 0, 0);
				this.mockDateOverride = d;
				this.mockScenarioName = 'monday_morning';
				this.mockHourOverride = hour || 9;
				this.mockMinuteOverride = 0;
				this.evalUpdateVersion++;
				this.showNotice('Giả lập: Sáng Thứ Hai (09:00) — Đang mở đăng ký tuần cho GVCN', 'info');
			} else if (scenario === 'midweek_morning') {
				// Thứ Tư trong tuần (Thứ Ba đến Thứ Sáu: đã khóa đăng ký GVCN)
				var d = new Date(monday.getTime() + 2 * 24 * 60 * 60 * 1000);
				d.setHours(hour || 8, 0, 0, 0);
				this.mockDateOverride = d;
				this.mockScenarioName = 'midweek_morning';
				this.mockHourOverride = hour || 8;
				this.mockMinuteOverride = 0;
				this.evalUpdateVersion++;
				var label = (hour >= 10) ? 'Thứ Tư (10:00) — Khóa đăng ký GVCN và khóa Quản sinh chấm (> 09:30)' : 'Thứ Tư (08:00) — Khóa đăng ký GVCN (T3-T6), Mở Quản sinh chấm';
				this.showNotice('Giả lập: ' + label, 'info');
			}
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
						{ id: 'c1', ten: 'TC1: Không gian (Sạch sẽ, bảng, sàn)', shortTitle: 'TC1: Không gian', score: 3, isCustom: false },
						{ id: 'c2', ten: 'TC2: Nội dung (Đọc sách, chủ đề)', shortTitle: 'TC2: Nội dung', score: 3, isCustom: false },
						{ id: 'c3', ten: 'TC3: Nề nếp (Nghiêm túc, tích cực)', shortTitle: 'TC3: Nề nếp', score: 3, isCustom: false }
					],
					GhiChuViPham: '',
					IsSaved: true,
					NguoiCham: 'Quản sinh khối'
				};
				that.dailySnapshots[keyT2] = snap;
				that.dailySnapshots[legacyKey] = snap;
			});

			// 2. Snapshot Thứ 3 (06/10/2026): Nền nếp Đạt, tất cả các lớp Đạt chuẩn (kể cả 06D)
			classList.forEach(function(item) {
				var keyT3 = '2026-10-06_' + item.LopID;
				var legacyKey = '3_' + item.LopID;
				var snap = {
					IsTuQuan: true,
					GVCNCoMat: false,
					TieuChiList: [
						{ id: 'c1', ten: 'TC1: Không gian (Sạch sẽ, bảng, sàn)', shortTitle: 'TC1: Không gian', score: 3, isCustom: false },
						{ id: 'c2', ten: 'TC2: Nội dung (Đọc sách, chủ đề)', shortTitle: 'TC2: Nội dung', score: 3, isCustom: false },
						{ id: 'c3', ten: 'TC3: Nề nếp (Nghiêm túc, tích cực)', shortTitle: 'TC3: Nề nếp', score: 3, isCustom: false }
					],
					GhiChuViPham: '',
					IsSaved: true,
					NguoiCham: 'QS. Trần Tuấn'
				};
				that.dailySnapshots[keyT3] = snap;
				that.dailySnapshots[legacyKey] = snap;
			});

			// 3. Snapshot Thứ 4 (07/10/2026): Nền nếp Đạt, tất cả các lớp Đạt chuẩn (kể cả 06D)
			classList.forEach(function(item) {
				var keyT4 = '2026-10-07_' + item.LopID;
				var legacyKey = '4_' + item.LopID;
				var snap = {
					IsTuQuan: true,
					GVCNCoMat: false,
					TieuChiList: [
						{ id: 'c1', ten: 'TC1: Không gian (Sạch sẽ, bảng, sàn)', shortTitle: 'TC1: Không gian', score: 3, isCustom: false },
						{ id: 'c2', ten: 'TC2: Nội dung (Đọc sách, chủ đề)', shortTitle: 'TC2: Nội dung', score: 3, isCustom: false },
						{ id: 'c3', ten: 'TC3: Nề nếp (Nghiêm túc, tích cực)', shortTitle: 'TC3: Nề nếp', score: 3, isCustom: false }
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
						{ id: 'c1', ten: 'TC1: Không gian (Sạch sẽ, bảng, sàn)', shortTitle: 'TC1: Không gian', score: is06D ? 1 : 3, isCustom: false },
						{ id: 'c2', ten: 'TC2: Nội dung (Đọc sách, chủ đề)', shortTitle: 'TC2: Nội dung', score: 3, isCustom: false },
						{ id: 'c3', ten: 'TC3: Nề nếp (Nghiêm túc, tích cực)', shortTitle: 'TC3: Nề nếp', score: is06D ? 1 : 3, isCustom: false }
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
					{ id: 'c1', ten: 'TC1: Không gian (Sạch sẽ, bảng, sàn)', shortTitle: 'TC1: Không gian', score: 1, isCustom: false },
					{ id: 'c2', ten: 'TC2: Nội dung (Đọc sách, chủ đề)', shortTitle: 'TC2: Nội dung', score: 3, isCustom: false },
					{ id: 'c3', ten: 'TC3: Nề nếp (Nghiêm túc, tích cực)', shortTitle: 'TC3: Nề nếp', score: 1, isCustom: false }
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
					{"LopID": "2719", "TenLop": "06A", "TenGVCN": "Nguyễn Thảo Nguyên", "MaGVCN": "NV0000738", "Account": "PHC", "SiSo": 27},
					{"LopID": "2720", "TenLop": "06B", "TenGVCN": "Chu Thùy Diệu My", "MaGVCN": "NV0000353", "Account": "yennth", "SiSo": 28},
					{"LopID": "2721", "TenLop": "06C", "TenGVCN": "Lê Thị Hoà", "MaGVCN": "NV0001332", "Account": "hoalt", "SiSo": 29},
					{"LopID": "2722", "TenLop": "06D", "TenGVCN": "Nguyễn Ngọc Bảo Trâm", "MaGVCN": "NV0000786", "Account": "TSN", "SiSo": 29},
					{"LopID": "2723", "TenLop": "06E", "TenGVCN": "Phạm Thị Oanh", "MaGVCN": "NV0000371", "Account": "chientran", "SiSo": 27},
					{"LopID": "2724", "TenLop": "06F", "TenGVCN": "Lê Thị Thúy Ly", "MaGVCN": "NV0000788", "Account": "TXH", "SiSo": 27},
					{"LopID": "2725", "TenLop": "06G", "TenGVCN": "Trần Thuỳ Dung", "MaGVCN": "NV0000825", "Account": "TXH", "SiSo": 28},
					{"LopID": "2726", "TenLop": "06H", "TenGVCN": "Lê Thị Thanh Thủy", "MaGVCN": "NV0000082", "Account": "NV0000197", "SiSo": 27}
				],
				7: [
					{"LopID": "2670", "TenLop": "07A", "TenGVCN": "Nguyễn Thị Lành", "MaGVCN": "NV0000517", "Account": "lanhnt", "SiSo": 29},
					{"LopID": "2669", "TenLop": "07B", "TenGVCN": "Nguyễn Thị Thanh Thùy", "MaGVCN": "NV0000675", "Account": "TSN", "SiSo": 28},
					{"LopID": "2668", "TenLop": "07C", "TenGVCN": "Nguyễn Thị Sen", "MaGVCN": "NV0001090", "Account": "NV0000197", "SiSo": 28},
					{"LopID": "2667", "TenLop": "07D", "TenGVCN": "Nguyễn Thị Mai", "MaGVCN": "NV0001291", "Account": "maint", "SiSo": 29},
					{"LopID": "2666", "TenLop": "07E", "TenGVCN": "Nguyễn Trần Gia Hân", "MaGVCN": "NV0001089", "Account": "NV0000197", "SiSo": 29},
					{"LopID": "2665", "TenLop": "07F", "TenGVCN": "Cao Thị Lan Hương", "MaGVCN": "NV0001187", "Account": "huongctl", "SiSo": 29},
					{"LopID": "2664", "TenLop": "07G", "TenGVCN": "Trần Thị Toàn", "MaGVCN": "NV0001413", "Account": "toantt", "SiSo": 28},
					{"LopID": "2663", "TenLop": "07H", "TenGVCN": "Lê Nguyễn Anh Thư", "MaGVCN": "NV0001223", "Account": "thulna", "SiSo": 29}
				],
				8: [
					{"LopID": "2662", "TenLop": "08A", "TenGVCN": "Nguyễn Kim Bảo Khánh", "MaGVCN": "NV0000750", "Account": "TSN", "SiSo": 29},
					{"LopID": "2661", "TenLop": "08B", "TenGVCN": "Đỗ Hoài Lượng", "MaGVCN": "NV0000475", "Account": "yennth", "SiSo": 29},
					{"LopID": "2660", "TenLop": "08C", "TenGVCN": "Nguyễn Mai Khanh", "MaGVCN": "NV0000979", "Account": "TTN", "SiSo": 29},
					{"LopID": "2659", "TenLop": "08D", "TenGVCN": "Phạm Minh Trường", "MaGVCN": "NV0000278", "Account": "yennth", "SiSo": 29},
					{"LopID": "2658", "TenLop": "08E", "TenGVCN": "Nguyễn Thị Thắm", "MaGVCN": "NV0000415", "Account": "yennth", "SiSo": 29},
					{"LopID": "2657", "TenLop": "08F", "TenGVCN": "Trần Thị Thanh Dung", "MaGVCN": "NV0001057", "Account": "NV0000197", "SiSo": 30}
				],
				9: [
					{"LopID": "2656", "TenLop": "09A", "TenGVCN": "Nguyễn Hoài Giang", "MaGVCN": "NV0000524", "Account": "yennth", "SiSo": 27},
					{"LopID": "2655", "TenLop": "09B", "TenGVCN": "Phạm Thị Linh", "MaGVCN": "NV0000037", "Account": "chientran", "SiSo": 27},
					{"LopID": "2654", "TenLop": "09C", "TenGVCN": "Nguyễn Thị Trí", "MaGVCN": "NV0000283", "Account": "chientran", "SiSo": 29},
					{"LopID": "2653", "TenLop": "09D", "TenGVCN": "Trần Văn Hạnh", "MaGVCN": "NV0000791", "Account": "TTT", "SiSo": 26},
					{"LopID": "2652", "TenLop": "09E", "TenGVCN": "Đỗ Thị Thanh Huyền", "MaGVCN": "NV0000673", "Account": "TTT", "SiSo": 27},
					{"LopID": "2651", "TenLop": "09F", "TenGVCN": "Nguyễn Thị Phương Nam", "MaGVCN": "NV0001121", "Account": "NV0000197", "SiSo": 27},
					{"LopID": "2650", "TenLop": "09G", "TenGVCN": "Lưu Gia Tuệ", "MaGVCN": "NV0001030", "Account": "NV0000968", "SiSo": 29},
					{"LopID": "2649", "TenLop": "09H", "TenGVCN": "Lê Hồng Linh", "MaGVCN": "NV0000787", "Account": "TXH", "SiSo": 26}
				],
				10: [
					{"LopID": "2727", "TenLop": "10A", "TenGVCN": "Lê Thị Hạnh", "MaGVCN": "NV0000693", "Account": "TTN", "SiSo": 29},
					{"LopID": "2281", "TenLop": "10B", "TenGVCN": "Hà Thị Hằng", "MaGVCN": "NV0000684", "Account": "TTT", "SiSo": 33},
					{"LopID": "2282", "TenLop": "10C", "TenGVCN": "La Gia Nghi", "MaGVCN": "NV0000479", "Account": "2018-09-14 10:09:00", "SiSo": 33},
					{"LopID": "2283", "TenLop": "10D", "TenGVCN": "Lê Văn Hải", "MaGVCN": "NV0000408", "Account": "yennth", "SiSo": 31},
					{"LopID": "2284", "TenLop": "10E", "TenGVCN": "Triệu Quang Vĩnh", "MaGVCN": "NV0000397", "Account": "yennth", "SiSo": 35},
					{"LopID": "2285", "TenLop": "10F", "TenGVCN": "Huỳnh Phạm Quế Anh", "MaGVCN": "NV0000824", "Account": "TXH", "SiSo": 31}
				],
				11: [
					{"LopID": "2286", "TenLop": "11A", "TenGVCN": "Nguyễn Thị Thu Mai", "MaGVCN": "NV0000951", "Account": "NV0000197", "SiSo": 55},
					{"LopID": "2647", "TenLop": "11B", "TenGVCN": "Trần Thanh Tâm", "MaGVCN": "NV0001370", "Account": "T.Anh", "SiSo": 36},
					{"LopID": "2289", "TenLop": "11C", "TenGVCN": "Lê Thanh Điền", "MaGVCN": "NV0000021", "Account": "chientran", "SiSo": 48},
					{"LopID": "2290", "TenLop": "11D", "TenGVCN": "Phạm Phi Cường", "MaGVCN": "NV0000347", "Account": "yennth", "SiSo": 52},
					{"LopID": "2291", "TenLop": "11E", "TenGVCN": "Tô Hoàng Thật", "MaGVCN": "NV0000291", "Account": "yennth", "SiSo": 53}
				],
				12: [
					{"LopID": "2277", "TenLop": "12A", "TenGVCN": "Nguyễn Quốc Việt", "MaGVCN": "NV0000292", "Account": "chientran", "SiSo": 29},
					{"LopID": "2292", "TenLop": "12B", "TenGVCN": "Biện Thị Kim Thắm", "MaGVCN": "NV0000031", "Account": "chientran", "SiSo": 57},
					{"LopID": "2641", "TenLop": "12C", "TenGVCN": "Nguyễn Thị Thảo Loan", "MaGVCN": "NV0000177", "Account": "chientran", "SiSo": 35},
					{"LopID": "2295", "TenLop": "12D", "TenGVCN": "Nguyễn Thị Bích Hạnh", "MaGVCN": "NV0000903", "Account": "TXH", "SiSo": 59},
					{"LopID": "2296", "TenLop": "12E", "TenGVCN": "Nguyễn Thị Bích Ngọc", "MaGVCN": "NV0000244", "Account": "yennth", "SiSo": 56}
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
						var raw = window.localStorage.getItem('lhbs_gvcn_schedules_cache_v4');
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
				var isWeek1 = (!curWeek || curWeek.startDate === '2026-10-05' || curWeek.weekNum === 1);
				var isWeek2 = (curWeek && (curWeek.startDate === '2026-10-12' || curWeek.weekNum === 2));
				var isWeek3 = (curWeek && (curWeek.startDate === '2026-10-19' || curWeek.weekNum === 3));

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
					} else if (isWeek2) {
						if (is06D) {
							// Tuần 2: Lớp 06D chấp hành chế tài tạm dừng tự quản 01 tuần
							isTuQuan = false;
							coMat = true;
							ghiChu = 'GVCN có mặt (Chế tài)';
						} else {
							isTuQuan = true;
							coMat = false;
							ghiChu = 'Ban cán sự điều hành';
						}
					} else if (isWeek3) {
						if (is06D) {
							// Tuần 3: 06D đã hoàn thành củng cố, tự quản 3 buổi (Thứ 3, 4, 5) đạt yêu cầu
							isTuQuan = (i === 1 || i === 2 || i === 3);
							coMat = !isTuQuan;
							ghiChu = isTuQuan ? 'Ban cán sự điều hành' : '';
						} else {
							isTuQuan = true;
							coMat = false;
							ghiChu = 'Ban cán sự điều hành';
						}
					} else {
						// Tuần 4 (đang mở đăng ký) và các tuần mới: MẶC ĐỊNH KHÔNG TỰ ĐĂNG KÝ
						// Để GVCN tự chủ động chọn các ngày đăng ký tự quản (Thứ 3 đến Thứ 6)
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
			var isBlocked = this.isClassBlocked(item.LopID);
			var sched = this.getScheduleForClass(item.LopID);
			var daySched = sched ? sched.find(function(s) { return s.key === dayVal; }) : null;
			var isTuQuan = (dayVal !== 2) && !isBlocked && daySched ? !!daySched.IsTuQuan : false;
			return {
				LopID: item.LopID,
				TenLop: item.TenLop,
				TenGVCN: item.TenGVCN,
				IsTuQuan: isTuQuan,
				TieuChiList: criteria,
				GhiChuViPham: '',
				IsSaved: false,
				NguoiCham: isTuQuan ? 'Quản sinh khối' : '—'
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
						var isBlocked = that.isClassBlocked(item.LopID);
						var isWeek1Historical = (that.selectedWeek && that.selectedWeek.startDate === '2026-10-05');

						// Quyền quyết định Tự quản hay GVCN sinh hoạt thuộc về lịch đăng ký của GVCN (daySched):
						// Nếu GVCN không đăng ký tự quản -> Luôn là GVCN sinh hoạt, Quản sinh không chấm điểm
						var gvcnDangKyTuQuan = (dayVal !== 2) && !isBlocked && (daySched ? !!daySched.IsTuQuan : (isWeek1Historical && snap.IsTuQuan !== undefined ? !!snap.IsTuQuan : false));
						if (isWeek1Historical && item.TenLop === '06D' && dayVal === 5) {
							gvcnDangKyTuQuan = true;
						}

						// Quản sinh chỉ ghi nhận có mặt đột xuất khi lớp có đăng ký tự quản nhưng GVCN vẫn có mặt tại lớp
						var isGvcnPresent = gvcnDangKyTuQuan && (snap.GVCNCoMat !== undefined ? !!snap.GVCNCoMat : false);
						var isTuQuan = gvcnDangKyTuQuan && !isGvcnPresent;

						return {
							LopID: item.LopID,
							TenLop: item.TenLop,
							TenGVCN: item.TenGVCN,
							IsTuQuan: isTuQuan,
							GVCNCoMat: isGvcnPresent,
							TieuChiList: JSON.parse(JSON.stringify(snap.TieuChiList || [])),
							GhiChuViPham: isTuQuan ? (snap.GhiChuViPham || '') : '',
							IsSaved: true,
							NguoiCham: isTuQuan ? (snap.NguoiCham || 'Quản sinh khối') : '—'
						};
					}
					return that.createFreshClassItem(item, dateStr);
				});
			} else if (this.dailyWorkingState[dateStr] && this.dailyWorkingState[dateStr].length > 0) {
				// Priority 2: Nếu ngày này có working state (đồng bộ IsTuQuan mới nhất từ lịch GVCN)
				var stateClasses = JSON.parse(JSON.stringify(this.dailyWorkingState[dateStr]));
				stateClasses.forEach(function(c) {
					var sched = that.getScheduleForClass(c.LopID);
					var daySched = sched ? sched.find(function(s) { return s.key === dayVal; }) : null;
					var isBlocked = that.isClassBlocked(c.LopID);
					var gvcnDangKyTuQuan = (dayVal !== 2) && !isBlocked && (daySched ? !!daySched.IsTuQuan : c.IsTuQuan);
					var isGvcnPresent = gvcnDangKyTuQuan && !!c.GVCNCoMat;
					c.IsTuQuan = gvcnDangKyTuQuan && !isGvcnPresent;
					c.GVCNCoMat = isGvcnPresent;
				});
				this.currentClasses = stateClasses;
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
				// Nếu là GVCN thì luôn giữ lớp của GVCN, không tự động nhảy về list[0]
				var target = currentSelected || (that.isGVCNRole ? null : list[0]);
				if (target) {
					that.selectedGvcnClassId = target.LopID;
					that.gvcnClassInfo.LopID = target.LopID;
					that.gvcnClassInfo.TenLop = target.TenLop;
					that.gvcnClassInfo.TenGVCN = target.TenGVCN;
					that.gvcnClassInfo.MaGVCN = target.MaGVCN || '';
					that.gvcnClassInfo.Account = target.Account || '';
					that.gvcnClassInfo.SiSo = target.SiSo;
					that.gvcnClassInfo.TrangThaiLop = that.isClassBlocked(target.LopID) ? 2 : 1;
					that.loadGvcnScheduleForClass(target.LopID);
					that.loadGvcnHistoryForClass(target.LopID);
				}
			}
		},
		onGvcnClassChanged(newClassId) {
			if (!newClassId) return;
			this.selectedGvcnClassId = String(newClassId);
			try {
				sessionStorage.setItem('lastSelectedGvcnClassId', String(newClassId));
				localStorage.setItem('lastSelectedGvcnClassId', String(newClassId));
			} catch (e) {}
			var found = this.allSchoolClasses.find(function(c) {
				return String(c.LopID) === String(newClassId);
			});
			if (found) {
				this.gvcnClassInfo.LopID = found.LopID;
				this.gvcnClassInfo.TenLop = found.TenLop;
				this.gvcnClassInfo.TenGVCN = found.TenGVCN;
				this.gvcnClassInfo.MaGVCN = found.MaGVCN || '';
				this.gvcnClassInfo.Account = found.Account || '';
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

			var that = this;
			var curWeek = this.selectedWeek;
			var weekId = curWeek ? curWeek.id : 1;
			var startDate = curWeek ? curWeek.startDate : '';
			var cacheKey = weekId + '_' + lopId;

			this.callApi('lms/TuQuan_DangKyLich_Get', { LopID: parseInt(lopId, 10), StartDate: startDate, TuanHocID: parseInt(weekId, 10) }, function(res) {
				var data = res;
				if (res && res.data) data = res.data;
				if (Array.isArray(data) && data.length > 0) {
					var loadedSched = JSON.parse(JSON.stringify(that.gvcnWeekSchedule));
					data.forEach(function(row) {
						var dayKey = row.key || row.Thu;
						var found = loadedSched.find(function(d) { return d.key === dayKey; });
						if (found) {
							found.IsTuQuan = (row.IsTuQuan === true || row.IsTuQuan === 1 || row.IsTuQuan === '1');
							found.CoMat = (row.CoMat === true || row.CoMat === 1 || row.CoMat === '1');
							if (row.GhiChu !== undefined && row.GhiChu !== null) {
								found.GhiChu = row.GhiChu;
							}
						}
					});
					that.gvcnWeekSchedule = loadedSched;
					that.gvcnSchedulesByClass[cacheKey] = JSON.parse(JSON.stringify(loadedSched));
					that.saveSchedulesToLocalStorage();
					that.loadGvcnHistoryForClass(lopId);
					that.evalUpdateVersion++;
				}
			});
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
						HasViolation: false,
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

				// Xác định trạng thái tự quản hay GVCN sinh hoạt: Lịch đăng ký của GVCN (sDay) là căn cứ quyết định
				var isWeek1Hist = (that.selectedWeek && that.selectedWeek.startDate === '2026-10-05');
				var isTuQuan = (dayNum !== 2) && sDay ? !!sDay.IsTuQuan : false;
				if (isWeek1Hist && String(lopId) === '2722' && dateStr === '2026-10-08') {
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
							{ ten: 'TC1: Không gian (Sạch sẽ, bảng, sàn)', score: 3 },
							{ ten: 'TC2: Nội dung (Đọc sách, chủ đề)', score: 3 },
							{ ten: 'TC3: Nề nếp (Nghiêm túc, tích cực)', score: 3 }
						],
						KetQua: 'GVCN',
						NoiDungViPham: '',
						HasViolation: false,
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
						HasViolation: false,
						NguoiCham: isFuture ? '—' : 'Chưa chấm'
					});
				} else {
					// Quản sinh ĐÃ CHẤM: Đọc trực tiếp tiêu chí, xếp loại và ghi chú từ Quản sinh
					var tcs = classData.TieuChiList || [];
					var cdCount = tcs.filter(function(tc) { return tc.score === 1; }).length;
					var ghiChu = classData.GhiChuViPham || '';

					// Chuẩn văn bản 22/10/2026: Đạt (0 CĐ), Cần cố gắng (1 CĐ), Chưa đạt (>= 2 CĐ)
					var ketQua = 'D';
					if (cdCount >= 2) {
						ketQua = 'CD';
					} else if (cdCount === 1) {
						ketQua = 'CCG';
					} else {
						ketQua = 'D';
					}

					var hasViolation = (cdCount > 0);

					history.push({
						Thu: dayNum,
						ThuLabel: dayLabels[i],
						Ngay: sDay.date,
						IsTuQuan: true,
						TieuChiList: JSON.parse(JSON.stringify(tcs)),
						KetQua: ketQua,
						NoiDungViPham: ghiChu,
						HasViolation: hasViolation,
						NguoiCham: classData.NguoiCham || 'QS. Trần Tuấn'
					});
				}
			}
			this.gvcnClassHistory = history;
		},
		openAddCriteriaDialog(targetClass) {
			if (!this.canModifyCriteria) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể thêm tiêu chí.' : (this.isTodayQsLocked ? 'Hệ thống đã khóa sau 09:30, không thể thêm tiêu chí.' : (this.selectedDay === 2 ? 'Thứ 2 toàn trường sinh hoạt cùng GVCN, không áp dụng tiêu chí.' : 'Không thể thêm tiêu chí.'));
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
			if (!this.canModifyCriteria) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể thêm tiêu chí.' : (this.isTodayQsLocked ? 'Hệ thống đã khóa sau 09:30, không thể thêm tiêu chí.' : (this.selectedDay === 2 ? 'Thứ 2 toàn trường sinh hoạt cùng GVCN, không áp dụng tiêu chí.' : 'Không thể thêm tiêu chí.'));
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
			if (!this.canModifyCriteria) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể xóa tiêu chí.' : 'Không thể xóa tiêu chí.';
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
			if (!this.canModifyCriteria) {
				var msg = this.isPastDay ? 'Ngày đã qua! Dữ liệu đã khóa lưu trữ lịch sử, không thể xóa tiêu chí.' : 'Không thể xóa tiêu chí.';
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
		isClassBlocked(lopId, targetWeek) {
			if (!lopId) return false;
			var idStr = String(lopId);
			var week = targetWeek || this.selectedWeek;
			var weekNum = (week && week.weekNum) ? week.weekNum : null;
			var startStr = (week && week.startDate) ? week.startDate : '';
			var month = (week && week.month) ? week.month : 10;

			// 1. Kiểm tra penaltyOverrides thủ công nếu có override theo week_lopId hoặc lopId
			var weekKey = (startStr || ('w' + weekNum));
			var overrideWithWeek = weekKey + '_' + idStr;
			if (this.penaltyOverrides && this.penaltyOverrides[overrideWithWeek] !== undefined) {
				return !!this.penaltyOverrides[overrideWithWeek];
			}
			if (this.penaltyOverrides && this.penaltyOverrides[idStr] !== undefined) {
				return !!this.penaltyOverrides[idStr];
			}

			// 2. Quy chế nề nếp tự quản 15 phút (Mục 2a):
			// "Tuần tự quản trước bị ghi nhận Chưa đạt (CĐ) -> Tạm dừng tự quản 01 tuần tiếp theo.
			// GVCN bắt buộc phải quay lại có mặt trực tiếp 5/5 buổi hằng ngày lúc 7:15 để củng cố.
			// Sau khi củng cố, nếu được đánh giá lớp đạt yêu cầu, GVCN tiếp tục đăng kí cho lớp tự quản."
			//
			// Áp dụng với dữ liệu thực tế mẫu:
			// - Lớp 06D (2722) vi phạm nề nếp vào Thứ 5 (08/10) Tuần 1 Tháng 10 và bị xếp Chưa đạt (CĐ).
			// - Do đó, lớp 06D chỉ chấp hành chế tài tạm dừng tự quản đúng 01 tuần tiếp theo tại TUẦN 2 (12/10 - 18/10/2026).
			// - Sang TUẦN 3 (19/10 - 25/10) và TUẦN 4 (26/10 - 01/11): Chế tài 01 tuần đã kết thúc, lớp đã củng cố đạt yêu cầu,
			//   GVCN tiếp tục đăng ký tự quản bình thường (không bị chế tài, không bị khóa đăng ký).
			if (idStr === '2722') {
				if (month === 10 && (weekNum === 2 || startStr === '2026-10-12')) {
					return true;
				}
				return false;
			}

			return false;
		},
		getClassDailyResult(item, dayVal) {
			var dVal = (dayVal !== undefined) ? dayVal : (this.activeTab === 'baocao' && this.bghViewMode === 'day' ? this.bghActiveDay : this.selectedDay);
			if (!item) return { code: 'GVCN', text: '—', color: 'blue-grey' };
			// Lớp không tự quản (GVCN sinh hoạt / GVCN có mặt):
			if (!item.IsTuQuan || item.GVCNCoMat) {
				return { code: 'GVCN', text: dVal === 2 ? 'Chào cờ' : 'Không chấm', color: 'blue-grey', label: 'Không tính tự quản' };
			}
			if (!item.TieuChiList || !item.TieuChiList.length) {
				return { code: 'D', text: 'Đạt', color: 'success' };
			}
			// Tính số tiêu chí Chưa đạt (score === 1)
			var cdCount = item.TieuChiList.filter(function(tc) { return tc.score === 1; }).length;

			// Chuẩn văn bản 22/10/2026:
			// Đạt (Đ): Cả 03 tiêu chí Đạt (cdCount === 0)
			// Cần cố gắng (CCG): Có 01 tiêu chí Chưa đạt (cdCount === 1)
			// Chưa đạt (CĐ): Có từ 02 tiêu chí Chưa đạt trở lên (cdCount >= 2)
			if (cdCount >= 2) {
				return { code: 'CD', text: 'Chưa đạt', color: 'error' };
			}
			if (cdCount === 1) {
				return { code: 'CCG', text: 'Cần cố gắng', color: 'amber-darken-3' };
			}
			return { code: 'D', text: 'Đạt', color: 'success' };
		},
		itemHasViolation(item, dayVal) {
			var dVal = (dayVal !== undefined) ? dayVal : (this.activeTab === 'baocao' && this.bghViewMode === 'day' ? this.bghActiveDay : this.selectedDay);
			if (!item || !item.IsTuQuan || item.GVCNCoMat) return false;
			var res = this.getClassDailyResult(item, dVal);
			return res.code === 'CD' || res.code === 'CCG';
		},
		openRewardEvidenceDialog(item) {
			if (!item) return;
			var targetLopId = item.LopID;
			this.highlightedClassId = targetLopId;
			this.outerMonthlySelectedWeekNum = (this.currentEvaluationMonth === 9 ? 4 : ((this.selectedWeek && this.selectedWeek.weekNum) || 4));
			this.$nextTick(function() {
				var el = document.getElementById('bgh-khoi-evidence-table');
				if (el) {
					el.scrollIntoView({ behavior: 'smooth', block: 'start' });
				}
			});
			var that = this;
			setTimeout(function() {
				that.highlightedClassId = null;
			}, 3500);
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
			html += '<strong>Tiến độ tháng:</strong> Đạt ' + cls.SoTuanTot + '/4 tuần Đạt &nbsp;&nbsp;|&nbsp;&nbsp; <strong>Điểm thi đua:</strong> ' + (cls.DiemThiDua || '0 điểm') + ' &nbsp;&nbsp;|&nbsp;&nbsp; <strong>Tiến độ:</strong> ' + (cls.XepLoaiThang || 'Đang theo dõi');
			html += '</div>';
			html += '<table><thead><tr>';
			html += '<th style="width: 55px;">Tuần</th><th style="width: 90px;">Thời gian</th><th style="width: 55px;">Thứ 2</th><th style="width: 55px;">Thứ 3</th><th style="width: 55px;">Thứ 4</th><th style="width: 55px;">Thứ 5</th><th style="width: 55px;">Thứ 6</th><th style="width: 85px;">Kết quả tuần</th><th>Ghi chú vi phạm trong tuần</th><th style="width: 75px;">Trạng thái</th>';
			html += '</tr></thead><tbody>';
			(cls.weeks || []).forEach(function(w) {
				html += '<tr>';
				html += '<td class="text-center"><strong>' + w.label + '</strong></td>';
				html += '<td class="text-center" style="font-size: 9.5pt;">' + w.dates + '/2026</td>';
				(w.days || []).forEach(function(d) {
					if (d.rankCode === 'CHETAI') {
						html += '<td class="text-center" style="color: #c62828;">—</td>';
					} else if (d.tcText === '—' && d.rankText === '—') {
						html += '<td class="text-center" style="color: #888;">—</td>';
					} else {
						var color = (d.rankCode === 'T' || d.rankCode === 'D' ? '#16a34a' : '#c62828');
						html += '<td class="text-center" style="font-size: 8.5pt; padding: 4px 2px;"><strong style="letter-spacing: 0.5px;">' + d.tcText + '</strong><br><strong style="color:' + color + ';">' + d.rankText + '</strong></td>';
					}
				});
				var detailStr = w.detail ? ('<br><small style="color:#666;">' + w.detail + '</small>') : '';
				html += '<td class="text-center"><strong>' + w.text + '</strong>' + detailStr + '</td>';
				html += '<td style="font-size: 9.5pt;' + (w.note && w.note !== '—' ? ' color: #c62828; font-weight: bold;' : ' color: #666;') + '">' + (w.note || '—') + '</td>';
				var danhGiaCol = '';
				if (w.status === 'T' || w.status === 'D') danhGiaCol = '<strong style="color:#16a34a;">Đạt (Đ)</strong>';
				else if (w.status === 'DT') danhGiaCol = '<span style="color:#1565c0;">Duy trì (DT)</span>';
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
					html += 'Lớp hoàn thành trọn vẹn 4/4 tuần Đạt trong Tháng 9/2026. Đạt danh hiệu "Lớp tự quản tốt" và cộng ' + cls.DiemThiDua + '.';
				} else if (cls.IsEffortReward) {
					html += 'Lớp hoàn thành 3/4 tuần Đạt trong Tháng 9/2026. Tuyên dương danh hiệu "Biểu dương nỗ lực nề nếp" và cộng ' + cls.DiemThiDua + '.';
				} else {
					html += 'Lớp hoàn thành chu kỳ thi đua nề nếp Tháng 9/2026.';
				}
			} else if (this.currentEvaluationMonth > 10) {
				html += 'Chu kỳ đánh giá Tháng ' + this.currentEvaluationMonth + '/2026 chưa bắt đầu. Lớp chưa phát sinh dữ liệu chấm nề nếp.';
			} else {
				var curWeekNum = (this.selectedWeek && this.selectedWeek.weekNum) ? this.selectedWeek.weekNum : 4;
				if (cls.IsLeading) {
					html += 'Lớp hoàn thành ' + cls.SoTuanTot + ' tuần Đạt đã xét và đang dẫn đầu thi đua Tháng 10. Tuần ' + curWeekNum + ' đang diễn ra. Danh hiệu và điểm cộng (' + cls.DiemThiDua + ') sẽ được xét duyệt chính thức sau ngày 01/11/2026 khi kết thúc chu kỳ 4 tuần.';
				} else if (cls.IsRewardEligible) {
					html += 'Lớp hoàn thành 4/4 tuần Đạt. Đề xuất cộng ' + cls.DiemThiDua + ' và trao danh hiệu "Lớp tự quản tốt".';
				} else if (cls.SoTuanCD > 0) {
					html += 'Lớp có ' + cls.SoTuanCD + ' tuần Chưa đạt (Tuần 1 ghi nhận vi phạm nề nếp). Đã áp dụng chế tài Tạm dừng tự quản Tuần 2. Lớp đã chấn chỉnh nề nếp và tham gia tự quản tốt ở các tuần tiếp theo.';
				} else {
					html += 'Lớp hoàn thành nhiệm vụ nề nếp các tuần đã xét. Tuần ' + curWeekNum + ' đang theo dõi.';
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
					if (d.rankCode === 'CHETAI') {
						html += '<td class="text-center" style="color: #c62828;">—</td>';
					} else if (d.tcText === '—' && d.rankText === '—') {
						html += '<td class="text-center" style="color: #888;">—</td>';
					} else {
						var color = (d.rankCode === 'T' ? '#2e7d32' : (d.rankCode === 'D' ? '#1565c0' : '#c62828'));
						html += '<td class="text-center" style="font-size: 8pt; padding: 3px 1px;"><strong style="letter-spacing: 0.5px;">' + d.tcText + '</strong><br><strong style="color:' + color + ';">' + d.rankText + '</strong></td>';
					}
				});
				var detailStr = w.detail ? ('<br><small style="color:#666;">' + w.detail + '</small>') : '';
				html += '<td class="text-center"><strong>' + w.text + '</strong>' + detailStr + '</td>';
				html += '<td style="font-size: 9pt;' + (w.note && w.note !== '—' ? ' color: #c62828; font-weight: bold;' : ' color: #666;') + '">' + (w.note || '—') + '</td>';
				var danhGiaCol = '';
				if (w.status === 'T' || w.status === 'D') danhGiaCol = '<strong style="color:#16a34a;">Đạt (Đ)</strong>';
				else if (w.status === 'DT') danhGiaCol = '<span style="color:#1565c0;">Duy trì (DT)</span>';
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
		printOuterKhoiEvidence() {
			this.evidenceDialog.selectedWeekNum = this.outerMonthlySelectedWeekNum || 1;
			this.printKhoiEvidence();
		},
		ensureXLSXLoaded() {
			return new Promise(function(resolve, reject) {
				if (window.XLSX) {
					resolve(window.XLSX);
					return;
				}
				var script = document.createElement('script');
				script.src = 'https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js';
				script.onload = function() { resolve(window.XLSX); };
				script.onerror = function() { reject(new Error('Không thể tải thư viện XLSX. Vui lòng kiểm tra kết nối mạng.')); };
				document.head.appendChild(script);
			});
		},
		async exportExcelReport() {
			try {
				var XLSX = await this.ensureXLSXLoaded();
				if (!XLSX) {
					this.showNotice('Không tìm thấy thư viện xuất Excel (XLSX).', 'error');
					return;
				}
				if (this.bghViewMode === 'day') {
					this.exportDailyExcel(XLSX);
				} else {
					this.exportMonthlyExcel(XLSX);
				}
			} catch (err) {
				console.error('Lỗi xuất Excel:', err);
				this.showNotice('Có lỗi xảy ra khi xuất file Excel: ' + (err.message || err), 'error');
			}
		},
		exportDailyExcel(XLSX) {
			var k = this.selectedKhoi || 6;
			var dayObj = this.bghActiveDayObj || {};
			var dayLabel = dayObj.label || ('Thứ ' + this.bghActiveDay);
			var dayDate = dayObj.date || '';
			var dateStr = this.getDateStringForDay(this.bghActiveDay);
			var criteria = this.getMergedPrintCriteria();

			var headerRow1 = ['TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG - BÁO CÁO NỀ NẾP 15 PHÚT TỰ QUẢN ĐẦU GIỜ'];
			var headerRow2 = ['Khối: ' + k + ' | Ngày: ' + dayLabel + ' (' + dayDate + ') | Thời gian xuất: ' + this.formatCurrentTime()];
			var headerRow3 = [];

			var tableHeaders = ['STT', 'Lớp', 'GVCN', 'Sĩ số', 'Hình thức'];
			criteria.forEach(function(tc, idx) {
				tableHeaders.push((idx + 1) + '. ' + (tc.shortTitle || tc.ten));
			});
			tableHeaders.push('Ghi chú vi phạm / Nhận xét', 'Xếp loại', 'Người kiểm tra');

			var dataRows = (this.dayClassesDetail || []).map(function(row) {
				var tcValues = criteria.map(function(tc) {
					if (!row.IsTuQuan) return '—';
					var raw = row.RawItem;
					var found = raw && raw.TieuChiList ? raw.TieuChiList.find(function(t) { return t.id === tc.id; }) : null;
					if (!found) return '—';
					return found.score === 1 ? 'Chưa đạt' : 'Đạt';
				});

				var xepLoai = '—';
				if (!row.IsTuQuan) {
					xepLoai = 'GVCN sinh hoạt';
				} else if (row.Result && row.Result.text) {
					xepLoai = row.Result.text;
				}

				var nguoiCham = (row.RawItem && row.RawItem.NguoiCham) || 'Quản sinh khối';

				return [
					row.STT,
					row.TenLop,
					row.TenGVCN,
					row.SiSo || 36,
					row.IsTuQuan ? 'Tự quản' : 'GVCN sinh hoạt',
					...tcValues,
					row.GhiChuViPham || '',
					xepLoai,
					nguoiCham
				];
			});

			var aoa = [headerRow1, headerRow2, headerRow3, tableHeaders, ...dataRows];
			var worksheet = XLSX.utils.aoa_to_sheet(aoa);

			worksheet['!merges'] = [
				{ s: { r: 0, c: 0 }, e: { r: 0, c: tableHeaders.length - 1 } },
				{ s: { r: 1, c: 0 }, e: { r: 1, c: tableHeaders.length - 1 } }
			];

			var colWidths = [
				{ wch: 6 },
				{ wch: 10 },
				{ wch: 22 },
				{ wch: 8 },
				{ wch: 16 }
			];
			criteria.forEach(function() {
				colWidths.push({ wch: 22 });
			});
			colWidths.push(
				{ wch: 35 },
				{ wch: 14 },
				{ wch: 18 }
			);
			worksheet['!cols'] = colWidths;

			var workbook = XLSX.utils.book_new();
			var safeDate = dateStr.replace(/-/g, '');
			XLSX.utils.book_append_sheet(workbook, worksheet, ('Ngay_' + dayLabel.replace(/\s+/g, '')).slice(0, 31));

			var fileName = 'Bao_Cao_Ne_Nep_Khoi_' + k + '_' + dayLabel.replace(/\s+/g, '_') + '_' + safeDate + '.xlsx';
			XLSX.writeFile(workbook, fileName);
			this.showNotice('Xuất file Excel báo cáo ngày thành công: ' + fileName, 'success');
		},
		buildWeekDetailWorksheet(XLSX, k, m, weekNum) {
			var weekDays = this.getKhoiDetailWeekDays(weekNum);
			var curWeekObj = (this.monthEvaluationWeeks || []).find(function(x) { return x.weekNum === weekNum; });
			var weekDates = curWeekObj ? curWeekObj.dates : '';
			var weekLabelWithDates = 'TUẦN ' + weekNum + (weekDates ? ' (' + weekDates + ')' : '');

			var hRow1 = ['CHI TIẾT ĐỐI SOÁT NỀ NẾP CÁC LỚP TOÀN KHỐI ' + k + ' — ' + weekLabelWithDates + ' (THÁNG ' + m + '/2026)'];
			var hRow2 = ['Thời gian xuất: ' + this.formatCurrentTime()];
			var hRow3 = [];

			var headers = ['STT', 'Lớp', 'GVCN'];
			weekDays.forEach(function(d) {
				headers.push(d.label + ' (' + d.date + ')');
			});
			headers.push('Kết quả tuần', 'Ghi chú vi phạm trong tuần', 'Trạng thái');

			var rows = (this.monthlyClassRecords || []).map(function(row, idx) {
				var w = (row.weeks && row.weeks.find(function(x) { return x.weekNum === weekNum; })) || {};
				var dayTexts = (w.days || []).map(function(d) {
					if (!d || (d.tcText === '—' && d.rankText === '—')) return '—';
					if (d.rankCode === 'CHETAI') return 'Chế tài';
					return (d.tcText ? d.tcText + ' - ' : '') + (d.rankText || '—');
				});
				while (dayTexts.length < 5) dayTexts.push('—');

				var stText = '';
				if (w.status === 'T' || w.status === 'D') stText = 'Đạt (Đ)';
				else if (w.status === 'DT') stText = 'Duy trì (DT)';
				else if (w.status === 'CD') stText = 'Chưa đạt';
				else if (w.status === 'CHETAI') stText = 'Chế tài TQ';
				else if (w.status === 'CURRENT') stText = 'Đang diễn ra';
				else stText = 'Chưa tới';

				return [
					idx + 1,
					row.TenLop,
					row.TenGVCN,
					...dayTexts,
					w.text || '—',
					w.note && w.note !== '—' ? w.note : '',
					stText
				];
			});

			var aoa = [hRow1, hRow2, hRow3, headers, ...rows];
			var ws = XLSX.utils.aoa_to_sheet(aoa);
			ws['!merges'] = [
				{ s: { r: 0, c: 0 }, e: { r: 0, c: headers.length - 1 } },
				{ s: { r: 1, c: 0 }, e: { r: 1, c: headers.length - 1 } }
			];
			var colWidths = [
				{ wch: 6 },
				{ wch: 10 },
				{ wch: 22 }
			];
			weekDays.forEach(function() { colWidths.push({ wch: 18 }); });
			colWidths.push(
				{ wch: 18 },
				{ wch: 38 },
				{ wch: 16 }
			);
			ws['!cols'] = colWidths;

			var tabDateStr = weekDates ? (' (' + weekDates.replace(/\//g, '.') + ')') : '';
			var sheetTabName = ('Tuần ' + weekNum + tabDateStr).slice(0, 31);

			return { ws: ws, tabName: sheetTabName };
		},
		exportMonthlyExcel(XLSX) {
			var k = this.selectedKhoi || 6;
			var m = this.currentEvaluationMonth;
			var workbook = XLSX.utils.book_new();

			// SHEET 1: TỔNG HỢP THI ĐUA THÁNG
			var h1Row1 = ['TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG - BẢNG TỔNG HỢP THI ĐUA 15 PHÚT TỰ QUẢN'];
			var h1Row2 = ['Khối: ' + k + ' | Chu kỳ: Tháng ' + m + '/2026 (' + this.monthCycleDateRange + ') | Thời gian xuất: ' + this.formatCurrentTime()];
			var h1Row3 = [];

			var w1Dates = (this.monthEvaluationWeeks && this.monthEvaluationWeeks[0]) ? (' (' + this.monthEvaluationWeeks[0].dates + ')') : '';
			var w2Dates = (this.monthEvaluationWeeks && this.monthEvaluationWeeks[1]) ? (' (' + this.monthEvaluationWeeks[1].dates + ')') : '';
			var w3Dates = (this.monthEvaluationWeeks && this.monthEvaluationWeeks[2]) ? (' (' + this.monthEvaluationWeeks[2].dates + ')') : '';
			var w4Dates = (this.monthEvaluationWeeks && this.monthEvaluationWeeks[3]) ? (' (' + this.monthEvaluationWeeks[3].dates + ')') : '';

			var headersSheet1 = [
				'STT', 'Lớp', 'GVCN', 'Sĩ số',
				'Tuần 1' + w1Dates,
				'Tuần 2' + w2Dates,
				'Tuần 3' + w3Dates,
				'Tuần 4' + w4Dates,
				'Số tuần Đạt (Đ)', 'Số tuần Duy trì (DT)', 'Số tuần Chưa đạt (CĐ)',
				'Điểm thi đua', 'Xếp loại tháng', 'Khen thưởng / Ghi chú'
			];

			var rowsSheet1 = (this.monthlyClassRecords || []).map(function(cls, idx) {
				var wList = cls.weeks || [];
				var w1 = wList[0] || {};
				var w2 = wList[1] || {};
				var w3 = wList[2] || {};
				var w4 = wList[3] || {};

				var note = '';
				if (cls.IsRewardEligible) note = 'Khen thưởng tự quản Đạt chuẩn';
				else if (cls.IsEffortReward) note = 'Biểu dương nỗ lực';
				else if (cls.IsLeading) note = 'Dẫn đầu tiến độ';
				else if (cls.SoTuanChuaDat >= 2) note = 'Tạm dừng tự quản (2 tuần CĐ)';

				return [
					idx + 1,
					cls.TenLop,
					cls.TenGVCN,
					cls.SiSo || 36,
					w1.text || '—',
					w2.text || '—',
					w3.text || '—',
					w4.text || '—',
					cls.SoTuanTot || 0,
					cls.SoTuanDat || 0,
					cls.SoTuanChuaDat || 0,
					cls.DiemThiDua || '0 điểm',
					cls.XepLoaiThang || 'Đang theo dõi',
					note
				];
			});

			var aoaSheet1 = [h1Row1, h1Row2, h1Row3, headersSheet1, ...rowsSheet1];
			var ws1 = XLSX.utils.aoa_to_sheet(aoaSheet1);
			ws1['!merges'] = [
				{ s: { r: 0, c: 0 }, e: { r: 0, c: headersSheet1.length - 1 } },
				{ s: { r: 1, c: 0 }, e: { r: 1, c: headersSheet1.length - 1 } }
			];
			ws1['!cols'] = [
				{ wch: 6 },
				{ wch: 10 },
				{ wch: 22 },
				{ wch: 8 },
				{ wch: 20 },
				{ wch: 20 },
				{ wch: 20 },
				{ wch: 20 },
				{ wch: 12 },
				{ wch: 12 },
				{ wch: 16 },
				{ wch: 14 },
				{ wch: 18 },
				{ wch: 30 }
			];
			XLSX.utils.book_append_sheet(workbook, ws1, ('Tổng hợp Tháng ' + m).slice(0, 31));

			var fileName = 'Bao_Cao_Thi_Dua_Khoi_' + k + '_Thang_' + m + '.xlsx';
			XLSX.writeFile(workbook, fileName);
			this.showNotice('Xuất file Excel tổng hợp thi đua tháng thành công: ' + fileName, 'success');
		},
		async exportKhoiWeekExcel() {
			try {
				var XLSX = await this.ensureXLSXLoaded();
				if (!XLSX) {
					this.showNotice('Không tìm thấy thư viện xuất Excel (XLSX).', 'error');
					return;
				}
				var k = this.selectedKhoi || 6;
				var m = this.currentEvaluationMonth;
				var weekNum = this.outerMonthlySelectedWeekNum || 1;
				var workbook = XLSX.utils.book_new();

				var weekSheetData = this.buildWeekDetailWorksheet(XLSX, k, m, weekNum);
				XLSX.utils.book_append_sheet(workbook, weekSheetData.ws, weekSheetData.tabName);

				var curWeekObj = (this.monthEvaluationWeeks || []).find(function(x) { return x.weekNum === weekNum; });
				var weekDates = curWeekObj ? curWeekObj.dates : '';
				var safeDates = weekDates ? ('_' + weekDates.replace(/\s+/g, '').replace(/\//g, '-')) : '';

				var fileName = 'Chi_Tiet_Ne_Nep_Khoi_' + k + '_Tuan_' + weekNum + safeDates + '_Thang_' + m + '.xlsx';
				XLSX.writeFile(workbook, fileName);
				this.showNotice('Xuất file Excel Tuần ' + weekNum + ' thành công: ' + fileName, 'success');
			} catch (err) {
				console.error('Lỗi xuất Excel tuần:', err);
				this.showNotice('Có lỗi xảy ra khi xuất file Excel: ' + (err.message || err), 'error');
			}
		},
		getKhoiDetailWeekDays(weekNum) {
			var w = weekNum || 1;
			var m = this.currentEvaluationMonth;
			var startDates;
			if (m === 9) {
				startDates = { 1: '2026-09-07', 2: '2026-09-14', 3: '2026-09-21', 4: '2026-09-28' };
			} else if (m === 11) {
				startDates = { 1: '2026-11-02', 2: '2026-11-09', 3: '2026-11-16', 4: '2026-11-23' };
			} else {
				startDates = { 1: '2026-10-05', 2: '2026-10-12', 3: '2026-10-19', 4: '2026-10-26' };
			}
			var startStr = startDates[w] || (m === 9 ? '2026-09-07' : (m === 11 ? '2026-11-02' : '2026-10-05'));
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
			if (val === 2 || val === 3) return 'Đạt';
			if (val === 1) return 'Chưa đạt';
			return '—';
		},
		getWeeklyMatrixCell(row, dVal) {
			if (row.IsBlocked) {
				return { isBlocked: true, tc1: '', tc2: '', tc3: '', kq: '' };
			}
			// 1. Kiểm tra đăng ký lịch cuối cùng của GVCN cho ngày dVal
			var sched = this.getScheduleForClass(row.LopID);
			var daySched = sched ? sched.find(function(s) { return s.key === dVal; }) : null;
			var isRegisteredTuQuan = !!(daySched && daySched.IsTuQuan);

			// 2. Nếu ngày này lớp KHÔNG đăng ký tự quản (hoặc GVCN chọn có mặt sinh hoạt trực tiếp)
			// => GẠCH CHÉO (/) cả 4 ô để Sao đỏ biết hôm đó GVCN có mặt, không đi chấm
			if (!isRegisteredTuQuan) {
				return {
					isNotRegistered: true,
					isTuQuan: false,
					tc1: '/',
					tc2: '/',
					tc3: '/',
					kq: '/'
				};
			}

			// 3. Nếu ngày này GVCN CÓ đăng ký tự quản:
			// A. Ở chế độ "Phiếu trắng cho Sao đỏ đi chấm" (weekly):
			//    => Để ô trống hoàn toàn để Sao đỏ đến lớp ghi Đ / CĐ vào
			if (this.printDialog.mode === 'weekly') {
				return {
					isBlank: true,
					isTuQuan: true,
					tc1: '',
					tc2: '',
					tc3: '',
					kq: ''
				};
			}

			// B. Ở chế độ "kèm kết quả đã chấm" (weekly_result):
			var dayClasses = this.getClassesForPrintDay(dVal);
			var found = dayClasses.find(function(c) { return String(c.LopID) === String(row.LopID); });
			var hasEvaluated = found && (found.IsSaved || (found.TieuChiList && found.TieuChiList.some(function(tc) { return tc.score === 1; })) || (found.GhiChuViPham && found.GhiChuViPham.trim()));

			if (found && hasEvaluated) {
				var res = this.getClassDailyResult(found, dVal);
				var tcs = found.TieuChiList || [];
				var s1 = tcs[0] ? tcs[0].score : 2;
				var s2 = tcs[1] ? tcs[1].score : 2;
				var s3 = tcs[2] ? tcs[2].score : 2;
				return {
					hasEvaluated: true,
					isTuQuan: true,
					tc1: s1 === 1 ? 'CĐ' : 'Đ',
					tc2: s2 === 1 ? 'CĐ' : 'Đ',
					tc3: s3 === 1 ? 'CĐ' : 'Đ',
					kq: res.code
				};
			}

			// Ngày tự quản nhưng chưa đến lượt chấm / chưa chấm: để ô trống
			return {
				isPending: true,
				isTuQuan: true,
				tc1: '',
				tc2: '',
				tc3: '',
				kq: ''
			};
		},
		getClassDayPrintData(lopId, dVal) {
			var isBlocked = this.isClassBlocked(lopId);
			var dayClasses = this.getClassesForPrintDay(dVal);
			var found = dayClasses.find(function(c) { return String(c.LopID) === String(lopId); });
			if (isBlocked) {
				return { tc1: '—', tc2: '—', tc3: '—', kq: 'GV', isBlocked: true };
			}
			if (found && found.GVCNCoMat) {
				return { tc1: '—', tc2: '—', tc3: '—', kq: 'GV', isGvcnPresent: true };
			}
			// Nếu lớp có đánh giá thực tế đã lưu/đã chấm:
			var hasEvaluated = found && (found.IsSaved || (found.TieuChiList && found.TieuChiList.some(function(tc) { return tc.score === 1; })) || (found.GhiChuViPham && found.GhiChuViPham.trim()));
			if (found && found.IsTuQuan && hasEvaluated) {
				var res = this.getClassDailyResult(found, dVal);
				var tcs = found.TieuChiList || [];
				var s1 = tcs[0] ? tcs[0].score : 2;
				var s2 = tcs[1] ? tcs[1].score : 2;
				var s3 = tcs[2] ? tcs[2].score : 2;
				return {
					tc1: s1 === 1 ? 'CĐ' : 'Đ',
					tc2: s2 === 1 ? 'CĐ' : 'Đ',
					tc3: s3 === 1 ? 'CĐ' : 'Đ',
					kq: res.code,
					isTuQuan: true
				};
			}
			// Nếu chưa đánh giá hoặc ngày chưa đến: để '—' chứ tuyệt đối KHÔNG gạch chéo '/' làm hiểu nhầm chưa chấm đã gạch
			return { tc1: '—', tc2: '—', tc3: '—', kq: '—', isPending: true };
		},
		getWeeklyViolationsForPrint() {
			var that = this;
			var list = [];
			var idx = 1;
			[3, 4, 5, 6].forEach(function(dVal) {
				var dayClasses = that.getClassesForPrintDay(dVal);
				var dLabel = (dVal === 3 ? 'Thứ 3' : (dVal === 4 ? 'Thứ 4' : (dVal === 5 ? 'Thứ 5' : 'Thứ 6')));
				var dateStr = that.getDateStringForDay(dVal);
				var dateDM = dateStr ? (dateStr.split('-')[2] + '/' + dateStr.split('-')[1]) : '';

				dayClasses.forEach(function(cls) {
					if (cls.IsTuQuan && !cls.GVCNCoMat && !that.isClassBlocked(cls.LopID)) {
						var hasCd = false;
						if (cls.TieuChiList) {
							cls.TieuChiList.forEach(function(tc, tcIdx) {
								if (tc.score === 1) {
									hasCd = true;
									list.push({
										stt: idx++,
										thuNgay: dLabel + ' (' + dateDM + ')',
										lop: cls.TenLop,
										tieuChiCD: 'TC' + (tcIdx + 1),
										moTa: cls.GhiChuViPham || ('Chưa đạt ' + tc.ten),
										nguoiGhi: cls.NguoiCham || (that.currentUserName ? ('QS. ' + that.currentUserName) : 'Quản sinh khối'),
										baoGVCN: 'Đã báo qua LMS (09:30)'
									});
								}
							});
						}
						// Nếu có ghi chú vi phạm cụ thể nhưng không chọn riêng tiêu chí nào
						if (!hasCd && cls.GhiChuViPham && cls.GhiChuViPham.trim()) {
							list.push({
								stt: idx++,
								thuNgay: dLabel + ' (' + dateDM + ')',
								lop: cls.TenLop,
								tieuChiCD: 'Nhắc nhở',
								moTa: cls.GhiChuViPham.trim(),
								nguoiGhi: cls.NguoiCham || (that.currentUserName ? ('QS. ' + that.currentUserName) : 'Quản sinh khối'),
								baoGVCN: 'Đã báo qua LMS (09:30)'
							});
						}
					}
				});
			});
			return list;
		},
		markAllGood() {
			var hasExistingViolation = this.currentClasses.some(function(c) {
				return (c.TieuChiList && c.TieuChiList.some(function(tc) { return tc.score === 1; })) || (c.GhiChuViPham && c.GhiChuViPham.trim());
			});
			if (hasExistingViolation) {
				if (!confirm('Khối đang có lớp ghi nhận Chưa đạt hoặc có Ghi chú vi phạm. Bạn có chắc muốn đặt lại TOÀN BỘ các lớp thành ĐẠT không?')) {
					return;
				}
			}
			this.currentClasses.forEach(function(item) {
				if (item.TieuChiList) {
					item.TieuChiList.forEach(function(tc) {
						tc.score = 2; // Đạt
					});
				}
				item.GhiChuViPham = '';
			});
			this.evalUpdateVersion++;
			this.showNotice('Đã đánh giá tất cả tiêu chí của các lớp thành ĐẠT!', 'info');
			this.autoSaveDailyEvaluation(150);
		},
		saveDailyEvaluation() {
			this.autoSaveDailyEvaluation(0);
			this.showNotice('Đã lưu kết quả đánh giá ngày ' + this.currentDayLabel + ' thành công!', 'success');
		},
		toggleGvcnDay(day) {
			day.IsTuQuan = !day.IsTuQuan;
			day.CoMat = !day.IsTuQuan;

			// 1. Cập nhật ngay tức thì vào cache tuần
			var weekId = this.selectedWeek ? this.selectedWeek.id : 1;
			var lopId = this.selectedGvcnClassId;
			var cacheKey = weekId + '_' + lopId;
			this.gvcnSchedulesByClass[cacheKey] = JSON.parse(JSON.stringify(this.gvcnWeekSchedule));
			this.saveSchedulesToLocalStorage();

			// 2. Cập nhật snapshot ngày & working state của Quản sinh cho ngày này
			var targetDateStr = this.getDateStringForDay(day.key);
			var snapKey = targetDateStr + '_' + lopId;
			if (this.dailySnapshots[snapKey]) {
				this.dailySnapshots[snapKey].IsTuQuan = day.IsTuQuan;
				this.dailySnapshots[snapKey].GVCNCoMat = false;
				if (!day.IsTuQuan) {
					this.dailySnapshots[snapKey].NguoiCham = '—';
				} else if (!this.dailySnapshots[snapKey].NguoiCham || this.dailySnapshots[snapKey].NguoiCham === '—') {
					this.dailySnapshots[snapKey].NguoiCham = this.currentUserName ? ('QS. ' + this.currentUserName) : 'Quản sinh khối';
				}
			}
			if (this.dailyWorkingState[targetDateStr]) {
				var dwClass = this.dailyWorkingState[targetDateStr].find(function(c) { return String(c.LopID) === String(lopId); });
				if (dwClass) {
					dwClass.IsTuQuan = day.IsTuQuan;
					dwClass.GVCNCoMat = false;
					if (!day.IsTuQuan) dwClass.NguoiCham = '—';
				}
			}

			// 3. Nếu đang mở đúng ngày này trong currentClasses thì đồng bộ ngay
			if (this.selectedDay === day.key) {
				var curCls = this.currentClasses.find(function(c) { return String(c.LopID) === String(lopId); });
				if (curCls) {
					curCls.IsTuQuan = day.IsTuQuan;
					curCls.GVCNCoMat = false;
					if (!day.IsTuQuan) curCls.NguoiCham = '—';
					this.currentClasses = [...this.currentClasses];
				}
			}

			this.autoSaveGvcnSchedule(0);
			this.loadGvcnHistoryForClass(this.selectedGvcnClassId);
			this.showNotice('Đã tự động lưu ' + day.label + ' (' + (day.IsTuQuan ? 'Lớp tự quản' : 'GVCN sinh hoạt') + ')', 'success');
		},
		saveGvcnSchedule() {
			this.isSaving = true;
			var that = this;
			that.autoSaveGvcnSchedule(0);
			setTimeout(function() {
				that.isSaving = false;
				that.showNotice('Đã lưu thành công đăng kí tự quản tuần này cho lớp ' + that.gvcnClassInfo.TenLop + ' (' + that.gvcnTuQuanCount + ' ngày tự quản)!', 'success');
			}, 300);
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
					text += '- Kết quả: 100% các lớp tự quản duy trì nền nếp Đạt sáng nay, không có lớp nào Chưa đạt.\n';
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
			var datCount = 0;
			var ccgCount = 0;
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
				// Nếu Quản sinh đã chấm điểm hoặc có ghi chú vi phạm thì xác nhận là tự quản (trừ khi GVCN có mặt)
				if (classData && !classData.GVCNCoMat && classData.TieuChiList && (classData.TieuChiList.some(function(tc) { return tc.score === 1; }) || classData.GhiChuViPham)) {
					isTuQuan = true;
				}
				if (classData && classData.GVCNCoMat) {
					isTuQuan = false;
				}

				if (!isTuQuan || that.isSpecificDayInFuture(dayVal)) {
					var isGvcnPresent = !!(classData && classData.GVCNCoMat);
					daysResult.push({
						dayVal: dayVal,
						dayLabel: d.label,
						date: d.date,
						isTuQuan: false,
						statusText: isGvcnPresent ? 'GV (Có mặt)' : '—',
						code: isGvcnPresent ? 'GV' : '—',
						color: isGvcnPresent ? '#546e7a' : '#757575',
						bg: isGvcnPresent ? '#eceff1' : '#f5f5f5',
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

				// Tính kết quả theo tiêu chí Quản sinh đã chấm (Chuẩn văn bản 22/10/2026)
				var tcs = classData.TieuChiList || [];
				var cdInDay = tcs.filter(function(tc) { return tc.score === 1; }).length;
				var ghiChu = classData.GhiChuViPham || '';

				var resCode = 'D';
				var resText = 'Đạt';
				var resColor = '#16a34a';
				var resBg = '#ecfdf5';

				var isDayCd = (cdInDay >= 2);
				var isDayCcg = (cdInDay === 1);

				if (isDayCd) {
					// Tiêu chí Chưa đạt (có >= 2 tiêu chí CĐ)
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
				} else if (isDayCcg) {
					// Cần cố gắng (có 1 tiêu chí CĐ)
					resCode = 'CCG';
					resText = 'Cần cố gắng';
					resColor = '#d97706';
					resBg = '#fffbeb';
					ccgCount++;

					var ccgItems = tcs.filter(function(tc) { return tc.score === 1; }).map(function(tc, idx) { return that.formatCriterionItem(tc, idx); });
					var ccgBadges = ccgItems.map(function(vi) { return vi.badgeText; }).join('; ');
					violations.push({
						day: d.label + ' (' + d.date + ')',
						tieuChi: ccgBadges || 'Lưu ý nề nếp',
						viPhamList: ccgItems,
						ghiChu: ghiChu || 'Cần cố gắng chấn chỉnh'
					});
				} else {
					// Đạt (cả 3 tiêu chí Đạt)
					resCode = 'D';
					resText = 'Đạt';
					resColor = '#16a34a';
					resBg = '#ecfdf5';
					datCount++;
				}

				var isGvcnPresent = (classData && classData.GVCNCoMat !== undefined) ? !!classData.GVCNCoMat : false;

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

			// Xếp loại tuần theo chuẩn văn bản 22/10/2026:
			// - Đạt (Đ): Có từ 02 ngày tự quản thực tế trở lên và 100% số ngày xếp Đạt -> Cộng 0,5 điểm thi đua
			// - Chưa đạt (CĐ): Từ 50% số ngày tự quản thực tế xếp CĐ trở lên -> Dừng tự quản tuần tiếp theo
			// - Duy trì (DT): Các trường hợp còn lại -> Không cộng điểm, lớp tiếp tục tự quản
			var isBlocked = that.isClassBlocked(cls.LopID);
			var hasPenaltyOverride = that.penaltyOverrides && (that.penaltyOverrides[cls.LopID] !== undefined);
			var isApplied = hasPenaltyOverride ? that.penaltyOverrides[cls.LopID] : isBlocked;

			var hasEvaluated = (datCount + ccgCount + cdCount > 0);
			var xepLoaiTuan = '—';
			var xepLoaiColor = '#757575';
			var xepLoaiBg = '#f5f5f5';

			if (isApplied || isBlocked) {
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
			} else if (tuQuanCount > 0 && (cdCount / tuQuanCount) >= 0.5) {
				xepLoaiTuan = 'Chưa đạt (CĐ)';
				xepLoaiColor = '#c62828';
				xepLoaiBg = '#ffebee';
			} else if (tuQuanCount >= 2 && datCount === tuQuanCount) {
				xepLoaiTuan = 'Đạt (Đ)';
				xepLoaiColor = '#16a34a';
				xepLoaiBg = '#ecfdf5';
			} else {
				xepLoaiTuan = 'Duy trì (DT)';
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
				datCount: datCount,
				ccgCount: ccgCount,
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
				this.printDialog.mode = 'weekly_result';
			} else {
				this.printDialog.mode = 'weekly';
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
					var isBlocked = that.isClassBlocked(item.LopID);
					var isWeek1Hist = (that.selectedWeek && that.selectedWeek.startDate === '2026-10-05');
					var isTuQuan = (dayVal !== 2) && !isBlocked && (daySched ? !!daySched.IsTuQuan : (isWeek1Hist && snap.IsTuQuan !== undefined ? !!snap.IsTuQuan : false));
					if (isWeek1Hist && item.TenLop === '06D' && dayVal === 5) {
						isTuQuan = true;
					}
					return {
						LopID: item.LopID,
						TenLop: item.TenLop,
						TenGVCN: item.TenGVCN,
						IsTuQuan: isTuQuan,
						GVCNCoMat: isTuQuan ? false : (daySched && daySched.IsTuQuan && !!snap.GVCNCoMat),
						TieuChiList: JSON.parse(JSON.stringify(snap.TieuChiList || [])),
						GhiChuViPham: snap.GhiChuViPham || '',
						NguoiCham: snap.NguoiCham || item.NguoiCham || (that.currentUserName ? ('QS. ' + that.currentUserName) : 'QS. Trần Tuấn'),
						IsSaved: true
					};
				}
				var sched = that.getScheduleForClass(item.LopID);
				var daySched = sched ? sched.find(function(s) { return s.key === dayVal; }) : null;
				var isBlocked = that.isClassBlocked(item.LopID);
				var isTuQuan = (dayVal !== 2) && !isBlocked && (daySched ? !!daySched.IsTuQuan : false);
				return {
					LopID: item.LopID,
					TenLop: item.TenLop,
					TenGVCN: item.TenGVCN,
					IsTuQuan: isTuQuan,
					TieuChiList: JSON.parse(JSON.stringify(that.baseCriteria)),
					GhiChuViPham: '',
					NguoiCham: item.NguoiCham || (that.currentUserName ? ('QS. ' + that.currentUserName) : 'QS. Trần Tuấn'),
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
			if (!cls.IsTuQuan) return;
			var crit = this.findClassCriterion(cls, tc);
			if (crit) {
				crit.score = score;
				this.evalUpdateVersion++;
				this.autoSaveDailyEvaluation(300);
			}
		},
		getCriterionFullName(name) {
			if (!name) return '';
			var s = name.toLowerCase();
			if (s.indexOf('không gian') !== -1 || s.indexOf('sạch sẽ') !== -1 || s.indexOf('bàn ghế') !== -1 || s.indexOf('tc1') !== -1 || s.indexOf('thông thoáng') !== -1) {
				return 'Không gian (Sạch sẽ, bảng, sàn)';
			}
			if (s.indexOf('nội dung') !== -1 || s.indexOf('đọc sách') !== -1 || s.indexOf('chủ đề') !== -1 || s.indexOf('tc2') !== -1) {
				return 'Nội dung (Đọc sách, chủ đề)';
			}
			if (s.indexOf('nề nếp') !== -1 || s.indexOf('nền nếp') !== -1 || s.indexOf('nghiêm túc') !== -1 || s.indexOf('tâm thế') !== -1 || s.indexOf('tc3') !== -1 || s.indexOf('tác phong') !== -1) {
				return 'Nề nếp (Nghiêm túc, tích cực)';
			}
			// Tiêu chí bổ sung: bỏ số thứ tự "1. ", "4. ", "TC1: " nếu có, giữ nguyên tên đầy đủ
			return name.replace(/^(TC)?[0-9]+[.:\s-]+\s*/i, '').trim();
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
				html += '<div>Đạt (Đ) (+0.5đ): <strong style="color: #16a34a;">' + stats.datCount + ' lớp</strong></div>';
				html += '<div>Duy trì (DT): <strong style="color: #1565c0;">' + stats.duyTriCount + ' lớp</strong></div>';
				html += '<div>Chưa đạt / Dừng TQ: <strong style="color: #c62828;">' + stats.cdCount + ' lớp</strong></div>';
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
				var isBghPrint = (self.isBghRole || self.activeTab === 'baocao');

				if (mode === 'daily') {
					html += '<div style="text-align: center;">';
					html += '<div style="font-size: 11pt; font-weight: bold; text-transform: uppercase;">TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG</div>';
					html += '<div style="font-size: 9pt; font-style: italic;">Đoàn TNCS Hồ Chí Minh – Liên đội THCS Lạc Hồng</div>';
					html += '<h2 style="margin: 4px 0; font-size: 13pt; text-transform: uppercase;">PHIẾU GIÁM SÁT "15 PHÚT TỰ QUẢN ĐẦU GIỜ"</h2>';
					html += '<div style="font-size: 9pt; font-style: italic;">(Áp dụng từ thứ Ba đến thứ Sáu – Dành cho Quản sinh khối, Sao đỏ, Đoàn viên xung kích)</div>';
					html += '</div>';

					html += '<div class="meta-row" style="font-size: 10pt; margin: 6px 0;">';
					var displayKhoiDaily = khoiName.startsWith('Khối') ? khoiName : ('Khối: ' + khoiName);
					html += '<div><strong>' + displayKhoiDaily + '</strong></div>';
					html += '<div>' + weekTitle + '</div>';
					html += '<div>Ngày chấm: <strong>' + dayLabel + '</strong></div>';
					html += '</div>';

					html += '<div class="legend-box">';
					html += '<strong>Nội dung tiêu chí:</strong> ';
					var legendItems = criteriaList.map(function(tc, idx) {
						return '<strong>TC' + (idx + 1) + ':</strong> ' + tc.ten;
					});
					html += legendItems.join(' &nbsp; | &nbsp; ');
					html += '<div style="font-style: italic; font-size: 8.5pt; margin-top: 2px;">* Quy định đánh giá: [Đ] = Đạt, [CĐ] = Chưa đạt. Xếp loại ngày: Đạt (cả 3 TC Đạt); Cần cố gắng (có 1 TC Chưa đạt); Chưa đạt (từ 2 TC Chưa đạt trở lên).</div>';
					html += '</div>';

					html += '<table><thead><tr>';
					html += '<th style="width: 38px;">STT</th><th style="width: 70px;">Lớp</th><th style="width: 140px; text-align: left; padding-left: 6px;">GVCN</th>';
					criteriaList.forEach(function(tc, idx) {
						var sub = self.getCriterionSubTitle(tc.ten);
						html += '<th style="min-width: 100px;"><div style="font-weight: bold;">TC' + (idx + 1) + ': ' + self.getCriterionMainTitle(tc.ten) + '</div>' + (sub ? '<div style="font-size: 7.5pt; font-weight: normal; color: #555; line-height: 1.2;">' + sub + '</div>' : '') + '</th>';
					});
					html += '<th style="min-width: 140px; text-align: left; padding-left: 6px;">Ghi chú vi phạm / Kí tên</th></tr></thead><tbody>';

					classes.forEach(function(cls, idx) {
						var isBlocked = self.isClassBlocked(cls.LopID);
						var rowBg = isBlocked ? 'background-color: #fff5f5;' : '';
						html += '<tr style="height: 36px;' + rowBg + '">';
						html += '<td>' + (idx + 1) + '</td>';
						html += '<td style="font-weight: bold; font-size: 10.5pt;' + (isBlocked ? ' color: #c62828;' : '') + '">' + cls.TenLop + '</td>';
						var gvcnSub = '';
						if (isBlocked) {
							gvcnSub = ' <span style="color:#c62828; font-weight:bold; font-size:8.5pt; display:block;">[TẠM DỪNG TỰ QUẢN]</span>';
						} else if (self.selectedDay === 2) {
							gvcnSub = ' <span style="color:#546e7a; font-size:8.5pt; display:block;">(Sinh hoạt đầu tuần)</span>';
						} else if (cls.IsTuQuan) {
							gvcnSub = ' <span style="color:#2e7d32; font-size:8.5pt; display:block;">(Lớp tự quản)</span>';
						} else {
							gvcnSub = ' <span style="color:#546e7a; font-size:8.5pt; display:block;">(Chưa đăng ký TQ)</span>';
						}
						html += '<td class="text-left" style="font-size: 9.5pt; padding-left: 6px;"><div>' + cls.TenGVCN + '</div>' + gvcnSub + '</td>';
						criteriaList.forEach(function(tc) {
							var hasTc = cls.TieuChiList ? cls.TieuChiList.some(function(x) { return x.id === tc.id; }) : true;
							html += '<td>';
							if (isBlocked) {
								html += '<span style="color:#c62828; font-size:11pt; font-weight:500;">—</span>';
							} else if (self.selectedDay === 2) {
								html += '<span style="color:#64748b; font-size:11pt; font-weight:500;">—</span>';
							} else if (isBghPrint && !cls.IsTuQuan) {
								html += '<span style="color:#64748b; font-size:11pt; font-weight:500;">—</span>';
							} else if (hasTc) {
								if (isBghPrint) {
									var sc = self.findClassCriterion(cls, tc).score;
									var dStr = (sc !== 1) ? '<strong style="color:#2e7d32;">[✓] Đ</strong>' : '<span style="color:#888;">[ ] Đ</span>';
									var cdStr = (sc === 1) ? '<strong style="color:#c62828;">[✓] CĐ</strong>' : '<span style="color:#888;">[ ] CĐ</span>';
									html += '<div class="cb-group">' + dStr + ' ' + cdStr + '</div>';
								} else {
									html += '<div class="cb-group"><span>[ ] Đ</span><span>[ ] CĐ</span></div>';
								}
							} else {
								html += '<span style="color:#bbb;">—</span>';
							}
							html += '</td>';
						});
						var noteTxt = isBlocked ? 'Chế tài do Tuần 1 Chưa đạt' : (cls.GhiChuViPham || '');
						html += '<td class="text-left" style="font-size: 9pt; padding-left: 6px;' + (isBlocked ? ' color:#c62828; font-weight:bold;' : '') + '">' + noteTxt + '</td>';
						html += '</tr>';
					});
					html += '</tbody></table>';

					html += '<div style="text-align: right; margin-top: 15px; font-style: italic; font-size: 10pt;">Trấn Biên, ngày ...... tháng 10 năm 2026</div>';

					html += '<div class="sign-block" style="display: flex; justify-content: space-between; margin-top: 15px; text-align: center; font-size: 10.5pt; page-break-inside: avoid;">';
					html += '<div style="width: 32%;"><strong>BÍ THƯ ĐOÀN – TPT ĐỘI</strong><br><i style="font-size: 9pt;">(Ký xác nhận)</i><div style="height: 45px;"></div><strong>Lưu Quý Đồng</strong></div>';
					html += '<div style="width: 32%;"><strong>QUẢN SINH KHỐI</strong><br><i style="font-size: 9pt;">(Ký và ghi rõ họ tên)</i><div style="height: 45px;"></div></div>';
					html += '<div style="width: 32%;"><strong>NGƯỜI GIÁM SÁT</strong><br><i style="font-size: 9pt;">(Sao đỏ / ĐV xung kích)</i><div style="height: 45px;"></div></div>';
					html += '</div>';
				} else {
					// MODE WEEKLY / WEEKLY_RESULT: CHUẨN MA TRẬN PHỤ LỤC A & B (VĂN BẢN 22/10/2026)
					var isBlankWeekly = (self.printDialog.mode === 'weekly');
					var isCapThpt = (self.selectedKhoi >= 10);
					var capText = isCapThpt ? '☐ THCS &nbsp; ☑ THPT' : '☑ THCS &nbsp; ☐ THPT';
					var weekDatesText = self.selectedWeek ? (self.selectedWeek.startDate + ' đến ' + self.selectedWeek.endDate) : '';
					var weekNumText = self.selectedWeek ? self.selectedWeek.weekNum : 2;

					html += '<div style="text-align: center;">';
					html += '<div style="font-size: 11pt; font-weight: bold; text-transform: uppercase;">TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG</div>';
					html += '<div style="font-size: 9pt; font-style: italic;">Đoàn TNCS Hồ Chí Minh – Liên đội THCS Lạc Hồng</div>';
					html += '<h2 style="margin: 4px 0; font-size: 13pt; text-transform: uppercase;">PHỤ LỤC: PHIẾU GIÁM SÁT "15 PHÚT TỰ QUẢN ĐẦU GIỜ"</h2>';
					var subNoticeWeekly = isBlankWeekly
						? '(Phiếu trắng dùng cho Quản sinh khối, sao đỏ, đoàn viên xung kích từ thứ Ba đến thứ Sáu)'
						: '(Bản tổng hợp kết quả Quản sinh đánh giá 15 phút tự quản cả tuần)';
					html += '<div style="font-size: 8.5pt; font-style: italic;">' + subNoticeWeekly + '</div>';
					html += '<h3 style="color: #1565c0; margin: 4px 0; font-size: 11pt;">Phần A. PHIẾU GIÁM SÁT HẰNG TUẦN</h3>';
					html += '</div>';

					html += '<div class="meta-row" style="font-size: 9.5pt; margin-top: 4px; margin-bottom: 6px;">';
					html += '<div>Khối: <strong>' + (self.selectedKhoi || 6) + '</strong></div>';
					html += '<div>Cấp: <strong>' + capText + '</strong></div>';
					html += '<div>Tuần: <strong>' + weekNumText + '</strong></div>';
					html += '<div>Từ ngày: <strong>' + weekDatesText + '</strong></div>';
					html += '<div>Người giám sát: <strong>Quản sinh khối / Sao đỏ</strong></div>';
					html += '</div>';

					// BẢNG MA TRẬN PHẦN A
					var d3Str = self.getDateStringForDay(3).split('-').slice(1).reverse().join('/');
					var d4Str = self.getDateStringForDay(4).split('-').slice(1).reverse().join('/');
					var d5Str = self.getDateStringForDay(5).split('-').slice(1).reverse().join('/');
					var d6Str = self.getDateStringForDay(6).split('-').slice(1).reverse().join('/');

					html += '<table style="font-size: 8pt; width: 100%; border-collapse: collapse;">';
					html += '<thead>';
					html += '<tr style="background-color: #f2f2f2; height: 26px;">';
					html += '<th rowspan="2" style="width: 28px;">STT</th>';
					html += '<th rowspan="2" style="width: 55px;">Lớp</th>';
					html += '<th colspan="4">THỨ BA<br><span style="font-size: 7pt; font-weight: normal;">(' + d3Str + ')</span></th>';
					html += '<th colspan="4">THỨ TƯ<br><span style="font-size: 7pt; font-weight: normal;">(' + d4Str + ')</span></th>';
					html += '<th colspan="4">THỨ NĂM<br><span style="font-size: 7pt; font-weight: normal;">(' + d5Str + ')</span></th>';
					html += '<th colspan="4">THỨ SÁU<br><span style="font-size: 7pt; font-weight: normal;">(' + d6Str + ')</span></th>';
					html += '<th colspan="5" style="background-color: #e8eaf6;">TỔNG HỢP TUẦN</th>';
					html += '<th rowspan="2" style="min-width: 90px; text-align: left; padding-left: 4px;">Ghi chú</th>';
					html += '</tr>';
					html += '<tr style="background-color: #f8fafc; height: 22px; font-size: 7pt;">';
					html += '<th>TC1</th><th>TC2</th><th>TC3</th><th>KQ</th>';
					html += '<th>TC1</th><th>TC2</th><th>TC3</th><th>KQ</th>';
					html += '<th>TC1</th><th>TC2</th><th>TC3</th><th>KQ</th>';
					html += '<th>TC1</th><th>TC2</th><th>TC3</th><th>KQ</th>';
					html += '<th style="width: 42px;">Số ngày TQ</th>';
					html += '<th style="width: 32px;">Số ngày Đ</th>';
					html += '<th style="width: 38px;">Số ngày CCG</th>';
					html += '<th style="width: 32px;">Số ngày CĐ</th>';
					html += '<th style="width: 70px;">Xếp loại tuần</th>';
					html += '</tr>';
					html += '</thead><tbody>';

					var matrix = self.weeklyClassMatrix;
					matrix.forEach(function(row, idx) {
						var bg = row.IsBlocked ? 'background-color: #fff5f5;' : (idx % 2 === 1 ? 'background-color: #fafafa;' : '');
						var clsColor = row.IsBlocked ? 'color: #c62828;' : '';
						html += '<tr style="height: 26px; ' + bg + '">';
						html += '<td>' + (idx + 1) + '</td>';
						html += '<td style="font-weight: bold; ' + clsColor + '">' + row.TenLop + '</td>';
						[3, 4, 5, 6].forEach(function(dVal) {
							if (row.IsBlocked) {
								var stripeStyle = 'background: repeating-linear-gradient(-45deg, #f8fafc, #f8fafc 4px, #e2e8f0 4px, #e2e8f0 8px);';
								html += '<td style="' + stripeStyle + '"></td>';
								html += '<td style="' + stripeStyle + '"></td>';
								html += '<td style="' + stripeStyle + '"></td>';
								html += '<td style="' + stripeStyle + '"></td>';
							} else {
								var cell = self.getWeeklyMatrixCell(row, dVal);
								html += '<td>' + cell.tc1 + '</td>';
								html += '<td>' + cell.tc2 + '</td>';
								html += '<td>' + cell.tc3 + '</td>';
								html += '<td style="font-weight: bold;">' + cell.kq + '</td>';
							}
						});
						if (isBlankWeekly) {
							// TRÊN PHIẾU TRẮNG: CÁC CỘT TỔNG HỢP TUẦN ĐỂ TRỐNG ĐỂ TỔNG HỢP BẰNG TAY CUỐI TUẦN
							html += '<td></td>';
							html += '<td></td>';
							html += '<td></td>';
							html += '<td></td>';
							html += '<td></td>';
							var noteStr = row.IsBlocked ? 'Tạm dừng tự quản 01 tuần' : '';
							html += '<td class="text-left" style="font-size: 7.5pt; padding-left: 4px;' + (row.IsBlocked ? ' color:#c62828;' : '') + '">' + noteStr + '</td>';
						} else {
							html += '<td>' + row.TuQuanCount + '</td>';
							html += '<td style="color: #2e7d32; font-weight: bold;">' + row.DatCount + '</td>';
							html += '<td style="color: #f59e0b; font-weight: bold;">' + row.CcgCount + '</td>';
							html += '<td style="color: #c62828; font-weight: bold;">' + row.CdCount + '</td>';
							html += '<td style="font-weight: bold;">' + row.XepLoaiTuan + '</td>';
							var noteStr = row.IsBlocked ? 'Tạm dừng tự quản 01 tuần' : '';
							html += '<td class="text-left" style="font-size: 7.5pt; padding-left: 4px;' + (row.IsBlocked ? ' color:#c62828;' : '') + '">' + noteStr + '</td>';
						}
						html += '</tr>';
					});
					html += '</tbody></table>';

					// 2 HỘP HƯỚNG DẪN
					html += '<div style="display: flex; gap: 8px; margin-top: 6px; font-size: 7.5pt; line-height: 1.35;">';
					html += '<div style="width: 50%; border: 1px solid #ccc; padding: 4px 6px; background-color: #fcfcfc;">';
					html += '<strong>Kí hiệu ghi phiếu:</strong><br>';
					html += '• Ô tiêu chí: <strong>Đ</strong> = Đạt; <strong>CĐ</strong> = Chưa đạt.<br>';
					html += '• Ô KQ ngày: <strong>Đ</strong> / <strong>CCG</strong> (Cần cố gắng) / <strong>CĐ</strong>.<br>';
					html += '• <strong>GV</strong> = Lớp đăng kí nhưng GVCN có mặt → không đánh giá, không tính là ngày tự quản.<br>';
					html += '• <strong>/</strong> = Lớp không đăng kí tự quản ngày đó (gạch chéo cả 4 ô của ngày).<br>';
					html += '• <strong>TC1:</strong> Lớp thông thoáng, ngăn nắp; sàn, bảng sạch sẽ.<br>';
					html += '• <strong>TC2:</strong> Hoạt động 15 phút có nội dung cụ thể.<br>';
					html += '• <strong>TC3:</strong> Tập thể lớp tham gia nghiêm túc, tích cực.';
					html += '</div>';
					html += '<div style="width: 50%; border: 1px solid #ccc; padding: 4px 6px; background-color: #fcfcfc;">';
					html += '<strong>Cách xếp loại (Mục III của Hướng dẫn):</strong><br>';
					html += '• <strong>Ngày:</strong> Đ = cả 3 TC Đạt; CCG = có 1 TC CĐ; CĐ = có từ 2 TC CĐ.<br>';
					html += '• <strong>Tuần (tính trên số ngày tự quản thực tế):</strong><br>';
					html += '- <strong>Đạt (Đ):</strong> từ 2 ngày trở lên và 100% số ngày xếp Đ → cộng 0,5 điểm thi đua.<br>';
					html += '- <strong>Chưa đạt (CĐ):</strong> ≥ 50% số ngày xếp CĐ → dừng tự quản tuần tiếp theo.<br>';
					html += '- <strong>Duy trì (DT):</strong> các trường hợp còn lại → không cộng điểm, tiếp tục tự quản.<br>';
					html += '<i style="color:#555;">* Ngày CCG không tính là ngày Đ khi xét mức Đạt, không tính là ngày CĐ khi xét mức Chưa đạt.</i>';
					html += '</div></div>';

					// PHẦN B
					html += '<div style="margin-top: 8px; page-break-inside: avoid;">';
					html += '<div style="font-weight: bold; font-size: 10.5pt; color: #1565c0;">Phần B. GHI NHẬN CHI TIẾT VÀ HƯỚNG DẪN ĐÁNH GIÁ</div>';
					html += '<div style="font-weight: bold; font-size: 9pt; margin-top: 2px;">1. Bảng ghi nhận chi tiết các trường hợp Chưa đạt</div>';
					html += '<div style="font-style: italic; font-size: 7.5pt; color: #666; margin-bottom: 2px;">(Ghi ngay khi phát hiện, mô tả khách quan, cụ thể – làm căn cứ khi GVCN phản hồi trước 11:00)</div>';
					
					html += '<table style="font-size: 7.5pt; width: 100%; border-collapse: collapse;">';
					html += '<thead><tr style="background-color: #f2f2f2; height: 22px;">';
					html += '<th style="width: 30px;">STT</th><th style="width: 95px;">Thứ / Ngày</th><th style="width: 55px;">Lớp</th><th style="width: 80px;">Tiêu chí CĐ</th><th style="text-align: left; padding-left: 6px;">Mô tả cụ thể sự việc (minh chứng)</th><th style="width: 100px;">Người ghi nhận</th><th style="width: 125px;">Quản sinh xác nhận đã báo GVCN</th>';
					html += '</tr></thead><tbody>';

					var vList = isBlankWeekly ? [] : self.getWeeklyViolationsForPrint();
					if (vList.length > 0) {
						vList.forEach(function(v) {
							html += '<tr style="height: 22px;">';
							html += '<td>' + v.stt + '</td><td>' + v.thuNgay + '</td><td style="font-weight:bold;">' + v.lop + '</td><td style="color:#c62828; font-weight:bold;">' + v.tieuChiCD + '</td>';
							html += '<td class="text-left" style="padding-left: 6px;">' + v.moTa + '</td><td>' + v.nguoiGhi + '</td><td>' + v.baoGVCN + '</td>';
							html += '</tr>';
						});
					} else {
						for (var bn = 1; bn <= 5; bn++) {
							html += '<tr style="height: 26px;"><td>' + bn + '</td><td></td><td></td><td></td><td></td><td></td><td></td></tr>';
						}
					}
					html += '</tbody></table>';

					// 2. Biểu hiện & 3. Quy trình
					html += '<div style="margin-top: 6px; font-size: 7.5pt;">';
					html += '<div style="font-weight: bold; font-size: 8.5pt; margin-bottom: 2px;">2. Biểu hiện cụ thể để xếp mức Đ/CĐ từng tiêu chí:</div>';
					html += '<table style="font-size: 7pt; width: 100%; border-collapse: collapse;"><thead><tr style="background-color: #f2f2f2; height: 20px;">';
					html += '<th style="width: 28%;">Tiêu chí</th><th style="width: 36%;">Ghi "Đ" (Đạt) khi</th><th style="width: 36%;">Ghi "CĐ" (Chưa đạt) khi</th>';
					html += '</tr></thead><tbody>';
					html += '<tr><td style="padding: 2px 4px; font-weight: bold;">TC1. Lớp thông thoáng, ngăn nắp; sàn, bảng sạch sẽ.</td><td style="padding: 2px 4px;">– Sàn sạch, không có rác; bảng đã lau.<br>– Bàn ghế, đồ dùng sắp xếp ngăn nắp.<br>– Lớp thông thoáng (cửa mở, đèn quạt phù hợp).</td><td style="padding: 2px 4px; color:#c62828;">– Còn rác trên sàn, hộc bàn; bảng chưa lau.<br>– Bàn ghế, đồ dùng lộn xộn.<br>– Lớp bí, thiếu thông thoáng.</td></tr>';
					html += '<tr><td style="padding: 2px 4px; font-weight: bold;">TC2. Hoạt động 15 phút có nội dung cụ thể.</td><td style="padding: 2px 4px;">– Có nội dung cụ thể, rõ ràng.<br>– BCS điều hành đúng khung 5 phút nề nếp + 10 phút chủ đề, bắt đầu đúng 07:15.</td><td style="padding: 2px 4px; color:#c62828;">– Không có nội dung; học sinh ngồi tự do.<br>– Nội dung không rõ ràng hoặc không bắt đầu đúng giờ.</td></tr>';
					html += '<tr><td style="padding: 2px 4px; font-weight: bold;">TC3. Tập thể lớp tham gia nghiêm túc, tích cực.</td><td style="padding: 2px 4px;">– Học sinh giữ trật tự, tập trung theo điều hành BCS.<br>– Tích cực hưởng ứng, tham gia hoạt động.</td><td style="padding: 2px 4px; color:#c62828;">– Nhiều học sinh làm việc riêng, ồn ào, tự do đi lại.<br>– Không hợp tác với BCS lớp.</td></tr>';
					html += '</tbody></table>';

					html += '<div style="font-weight: bold; font-size: 8.5pt; margin-top: 4px; margin-bottom: 2px;">3. Quy trình ghi phiếu:</div>';
					html += '<div style="line-height: 1.3; color: #333;">';
					html += '1. Chiều thứ Hai: Nhận lịch đăng kí; ghi tên lớp, gạch chéo (/) các ngày không đăng kí. &nbsp;|&nbsp; 2. 07:15 – 07:30 (thứ Ba – thứ Sáu): Đến lớp ghi Đ/CĐ từng tiêu chí rồi ghi KQ ngày (Đ/CCG/CĐ). Nếu GVCN có mặt: ghi "GV", không đánh giá.<br>';
					html += '3. Khi có tiêu chí CĐ: Ghi mô tả cụ thể sự việc vào Bảng ghi nhận chi tiết (mục 1). &nbsp;|&nbsp; 4. Trước 09:30: Tổng hợp, thông báo KQ ngày; GVCN phản hồi trước 11:00. &nbsp;|&nbsp; 5. Thứ Sáu (trước 16:00): Tổng hợp tuần, xếp loại tuần (Đ/DT/CĐ), kí xác nhận và thông báo kết quả.';
					html += '</div></div>';

					html += '<div style="text-align: right; margin-top: 6px; font-style: italic; font-size: 9pt;">Trấn Biên, ngày ...... tháng 10 năm 2026</div>';
					html += '</div>';

					html += '<div class="sign-block" style="display: flex; justify-content: space-between; margin-top: 15px; text-align: center; font-size: 10pt; page-break-inside: avoid;">';
					html += '<div style="width: 32%;"><strong>BÍ THƯ ĐOÀN – TPT ĐỘI</strong><br><i style="font-size: 8.5pt;">(Kí xác nhận)</i><div style="height: 45px;"></div><strong>Lưu Quý Đồng</strong></div>';
					html += '<div style="width: 32%;"><strong>QUẢN SINH KHỐI</strong><br><i style="font-size: 8.5pt;">(Kí, ghi rõ họ tên)</i><div style="height: 45px;"></div></div>';
					html += '<div style="width: 32%;"><strong>NGƯỜI GIÁM SÁT</strong><br><i style="font-size: 8.5pt;">(Sao đỏ / ĐV xung kích)</i><div style="height: 45px;"></div></div>';
					html += '</div>';
				}
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
	background-color: #ecfdf5 !important;
	color: #065f46 !important;
	border: 1px solid #bbf7d0 !important;
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
	background-color: #16a34a !important;
	color: #ffffff !important;
	box-shadow: 0 1px 3px rgba(22, 163, 74, 0.4);
}
.score-btn-item.score-btn-d:hover:not(:disabled):not(.score-active-d) {
	background-color: #dcfce7 !important;
	color: #15803d !important;
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

/* Mobile Segmented Score Control - Nút bấm dạng Segmented Control bo tròn, cân xứng, chống méo */
.mobile-score-group {
	display: inline-flex;
	align-items: center;
	background-color: #f1f5f9;
	padding: 2.5px;
	border-radius: 8px;
	border: 1px solid #cbd5e1;
	gap: 2px;
	user-select: none;
}
.mobile-score-btn {
	min-width: 40px;
	height: 32px;
	padding: 0 10px;
	border-radius: 6px;
	border: none;
	outline: none;
	background: transparent;
	color: #64748b;
	font-size: 13px;
	font-weight: 700;
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	line-height: 1;
	transition: all 0.15s ease;
	box-sizing: border-box;
}
.mobile-score-btn:hover:not(:disabled):not(.active) {
	background-color: #e2e8f0;
	color: #1e293b;
}
.mobile-score-btn.mobile-score-btn-d.active {
	background-color: #16a34a !important;
	color: #ffffff !important;
	box-shadow: 0 1px 3px rgba(22, 163, 74, 0.4);
}
.mobile-score-btn.mobile-score-btn-cd.active {
	background-color: #dc2626 !important;
	color: #ffffff !important;
	box-shadow: 0 1px 3px rgba(220, 38, 38, 0.4);
}
.score-disabled .mobile-score-btn {
	cursor: default;
	pointer-events: none;
}

/* Clean LMS Styles */
.compact-filter-select .v-field__input {
	padding-top: 3px !important;
	padding-bottom: 3px !important;
	padding-inline-start: 4px !important;
	padding-inline-end: 2px !important;
	min-height: 32px !important;
	height: 32px !important;
	font-size: 11.5px !important;
	white-space: nowrap !important;
}
.compact-filter-select .v-field {
	border-radius: 8px !important;
	background-color: #f8fafc !important;
}
.compact-filter-select .v-select__selection {
	overflow: visible !important;
	margin-inline-end: 0 !important;
}
.compact-filter-select .v-select__selection-text {
	white-space: nowrap !important;
	overflow: visible !important;
	text-overflow: clip !important;
	font-weight: 500 !important;
}
.week-selector-wrap {
	min-width: 340px;
	max-width: 420px;
}
@media (max-width: 600px) {
	.week-selector-wrap {
		min-width: 0 !important;
		max-width: 100% !important;
	}
}
.clean-days-toggle {
	background-color: #f1f5f9 !important;
	border: 1px solid #cbd5e1 !important;
	border-radius: 10px !important;
	padding: 4px !important;
	gap: 4px !important;
	height: auto !important;
	min-height: 48px !important;
	overflow: visible !important;
}
.clean-day-btn {
	border-radius: 7px !important;
	background: transparent !important;
	color: #334155 !important;
	transition: all 0.2s ease !important;
	height: auto !important;
	min-height: 42px !important;
	padding: 2px 4px !important;
}
.clean-day-btn .v-btn__content {
	height: 100% !important;
	width: 100% !important;
	padding: 0 !important;
}
.clean-day-btn:hover {
	background-color: #ffffff !important;
	color: #0f172a !important;
	box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08) !important;
}
.clean-days-toggle .v-btn--active {
	background-color: #217D46 !important;
	color: #ffffff !important;
	box-shadow: 0 2px 6px rgba(33, 125, 70, 0.35) !important;
}
.clean-days-toggle .v-btn--active .font-weight-bold,
.clean-days-toggle .v-btn--active .clean-day-date,
.clean-days-toggle .v-btn--active .v-icon {
	color: #ffffff !important;
}
.clean-day-date {
	color: #64748b;
	font-weight: 500;
}
.day-today-badge {
	background: #dcfce7;
	color: #166534;
	font-weight: 700;
	font-size: 10px;
	padding: 1px 5px;
	border-radius: 4px;
	letter-spacing: 0.2px;
	display: inline-block;
}
.day-today-badge-active {
	background-color: #fef08a !important;
	color: #854d0e !important;
	font-weight: 800;
	font-size: 10px;
	padding: 1px 5px;
	border-radius: 4px;
	letter-spacing: 0.2px;
	display: inline-block;
}
.status-dot-green {
	width: 7px;
	height: 7px;
	border-radius: 50%;
	background-color: #16a34a;
	display: inline-block;
	box-shadow: 0 0 0 2px rgba(22, 163, 74, 0.2);
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
.table-rank-badge.rank-tot,
.table-rank-badge.rank-dat {
	background-color: #ecfdf5 !important;
	color: #065f46 !important;
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

/* Ô SỌC CHÉO CHẾ TÀI TRÀN FULL TOÀN BỘ Ô KHI LỚP BỊ TẠM DỪNG TỰ QUẢN (CHUẨN IMAGE MẪU) */
.cell-striped-blocked {
	background: repeating-linear-gradient(
		-45deg,
		#f8fafc,
		#f8fafc 6px,
		#e2e8f0 6px,
		#e2e8f0 12px
	) !important;
	border-left: 1px solid #e2e8f0 !important;
	border-right: 1px solid #e2e8f0 !important;
	padding: 0 !important;
}
.cell-striped-blocked-mobile {
	width: 100%;
	height: 22px;
	border-radius: 4px;
	background: repeating-linear-gradient(
		-45deg,
		#f8fafc,
		#f8fafc 5px,
		#e2e8f0 5px,
		#e2e8f0 10px
	) !important;
	border: 1px solid #e2e8f0 !important;
	display: block;
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
.badge-week-tag.tag-tot,
.badge-week-tag.tag-current {
	background-color: #ecfdf5 !important;
	color: #065f46 !important;
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
.tkb-monday-cell {
	background-color: #edf2f7 !important;
	color: #334155 !important;
	transition: all 0.2s ease;
}
.tkb-monday-note-cell {
	background-color: #e2e8f0 !important;
}
.tkb-note-native-input.tkb-monday-input,
.tkb-note-native-input.tkb-monday-input:disabled {
	background-color: #edf2f7 !important;
	border-color: #cbd5e1 !important;
	color: #334155 !important;
	font-weight: 500 !important;
	opacity: 1 !important;
}

.tkb-stripe-disabled {
	background-color: #f8fafc;
	color: #94a3b8;
	transition: all 0.2s ease;
}

/* Ô được đăng ký tự quản: Xanh lá cây tươi sáng, thanh thoát */
.tkb-cell-registered {
	background-color: #f0fdf4 !important;
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