<template>
	<div class="lms-dashboard-root teacher-dashboard" ref="containerPage"
		:class="{ 'lms-focus-drawer-open': showFocusDrawer }">
		<!-- TOPBAR -->
		<v-toolbar border density="compact" class="bg-white border-sm lms-topbar"
			style="position:sticky;top:0;z-index:50;flex-shrink:0;">
			<template #prepend>
				<v-btn v-if="$vuetify.display.mobile" icon size="small" @click="showCascadeDrawer = true" class="me-1">
					<v-icon>mdi-menu</v-icon>
					<v-tooltip activator="parent" location="bottom">{{ $t('message.Grade') }}</v-tooltip>
				</v-btn>
			</template>
			<template #title>
				<div class="d-flex align-center flex-nowrap lms-topbar-title" style="min-width: 0; max-width: 100%;">
					<span v-if="!$vuetify.display.mobile" class="text-subtitle-1 font-weight-semibold text-no-wrap lms-topbar-dashboard-label">{{ $t('message.ControlPanel') }}</span>
					<v-btn size="small" class="ms-1 px-1 text-caption lms-topbar-teacher-btn" variant="text"
						v-if="vueData.user.UserID == 'NA0000022' || vueData.user.UserID == 'NV0000134'"
						@click="onHandleOpenChangeGV">{{ $t('message.ChooseTeacher') }}</v-btn>
					<!-- BREADCRUMB -->
					<div class="lms-breadcrumb ms-1 lms-topbar-breadcrumb">
						<template v-for="(bc, i) in cascadeBreadcrumb" :key="i">
							<span v-if="i > 0" class="bc-sep">›</span>
							<span class="bc-chip" :class="[bc.active ? 'bc-active' : bc.done ? 'bc-done' : 'bc-lock', bc.step === 2 ? 'bc-chip--week' : '']"
								:title="bc.label" @click="bc.done ? resetCascadeFrom(bc.step) : null">{{ formatTopbarBreadcrumb(bc.label, bc.step) }}</span>
						</template>
					</div>
				</div>
			</template>
			<template #append>
				<template v-if="!$vuetify.display.mobile">
					<v-btn ref="tourBtnThongKe" class="lms-topbar-action" @click="OpenDashboard()">
						<v-icon class="me-1">mdi-blinds-horizontal-closed</v-icon>{{ $t('message.Statistical') }}
					</v-btn>
					<v-btn ref="tourBtnThuVien" class="lms-topbar-action" @click="OpenMyLiberies()">
						<v-icon class="me-1">mdi-library-shelves</v-icon>{{ $t('message.MyDocument') }}
					</v-btn>
				</template>
				<!-- Đặt Bài cần chấm cạnh các khu vực thao tác chính để cụm header dễ quét hơn. -->
				<v-badge v-if="!$vuetify.display.mobile && focusTaskCount" :content="focusTaskCountLabel"
					color="error" floating offset-x="4" offset-y="4" class="lms-focus-trigger-badge me-3">
					<v-btn size="small" variant="text" class="lms-focus-trigger" @click="showFocusDrawer = true">
						<v-icon start>mdi-clipboard-check-outline</v-icon>
						<span class="lms-focus-trigger__label">{{ focusDrawerLabel }}</span>
					</v-btn>
				</v-badge>
				<v-btn v-else-if="!$vuetify.display.mobile" size="small" variant="text"
					class="lms-focus-trigger me-1" @click="showFocusDrawer = true">
					<v-icon start>mdi-clipboard-check-outline</v-icon>
					<span class="lms-focus-trigger__label">{{ focusDrawerLabel }}</span>
				</v-btn>
				<!-- Mobile giữ icon gọn, nhưng vẫn cho biết có việc cần xử lý. -->
				<v-badge v-else-if="focusTaskCount" :content="focusTaskCountLabel" color="error" floating>
					<v-btn icon size="small" @click="showFocusDrawer = true" class="me-1">
						<v-icon color="teal">mdi-clipboard-check-outline</v-icon>
						<v-tooltip activator="parent" location="bottom">{{ focusDrawerLabel }}</v-tooltip>
					</v-btn>
				</v-badge>
				<v-btn v-else icon size="small" @click="showFocusDrawer = true" class="me-1">
					<v-icon color="teal">mdi-clipboard-check-outline</v-icon>
					<v-tooltip activator="parent" location="bottom">{{ focusDrawerLabel }}</v-tooltip>
				</v-btn>
				<template v-if="!$vuetify.display.mobile">
					<v-btn icon size="small" @click="startTour" class="lms-topbar-action lms-topbar-help">
						<v-icon>mdi-help-circle-outline</v-icon>
						<v-tooltip activator="parent" location="bottom">{{ $t('message.TourGuide') }}</v-tooltip>
					</v-btn>
				</template>
				<!-- Giới hạn cụm ngôn ngữ để hai lá cờ không đẩy tràn phần append ở mép phải toolbar. -->
				<v-btn-toggle v-model="toggle" size="small" class="lms-language-toggle">
					<v-btn class="lms-language-btn" :value="false" :disabled="!toggle" :color="!toggle ? 'green' : 'white'">
						<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="24" max-width="24" />
					</v-btn>
					<v-btn class="lms-language-btn" :value="true" :disabled="toggle" :color="toggle ? 'green' : 'white'">
						<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="24" max-width="24" />
					</v-btn>
				</v-btn-toggle>
			</template>
		</v-toolbar>

		<!-- Mobile: cascade navigation drawer -->
		<v-navigation-drawer v-model="showCascadeDrawer" temporary location="left" width="260" style="top:0">
			<div style="height:100%;display:flex;flex-direction:column;overflow:hidden">
				<!-- Tier 1: Khoi -->
				<div class="lms-tier">
					<div class="lms-tier-hd"><span class="lms-tier-label">{{ $t('message.Grade') }}</span></div>
					<div class="lms-tier-body">
						<template v-if="loadingGroups">
							<div v-for="n in 4" :key="'m-sk-k-' + n" class="lms-t-item" style="pointer-events:none">
								<span class="lms-t-dot" style="background:#e0e0e0"></span>
								<v-skeleton-loader type="text" width="60%" style="flex:1" />
							</div>
						</template>
						<template v-else>
							<div v-for="k in DSKhoiCascade" :key="'m-' + k.KhoiID" class="lms-t-item"
								:class="{ active: cascadeKhoiID === k.KhoiID }" @click="pickKhoi(k.KhoiID)">
								<span class="lms-t-dot" :style="{ background: k.dot }"></span>
								<span class="lms-t-label">{{ k.label }}</span><v-chip v-if="k.hasLibraryOnly" size="x-small" color="grey" variant="tonal">Có nội dung</v-chip><v-icon v-if="k.hasTeaching" size="13" color="success" title="Đang dạy khối">mdi-school-outline</v-icon><v-icon v-if="k.hasDelegated" size="13" color="warning" title="Có tài liệu được chia sẻ">mdi-account-arrow-left-outline</v-icon>
								<v-icon v-if="cascadeKhoiID === k.KhoiID" size="14" color="teal">mdi-check</v-icon>
								<span v-else class="lms-t-arrow">&rsaquo;</span>
							</div>
						</template>
					</div>
				</div>
				<!-- Tier 2: Mon -->
				<div class="lms-tier">
					<div class="lms-tier-hd"><span class="lms-tier-label">{{ $t('message.Subject') }}</span></div>
					<div class="lms-tier-body">
						<div v-if="!cascadeKhoiID" class="lms-tier-locked">
							<v-icon size="13">mdi-lock-outline</v-icon> {{ $t('message.SelectGradeFirst') }}
						</div>
						<div v-for="m in DSMonCascade" v-else :key="'m-' + m.MonHocName" class="lms-t-item"
							:class="{ active: cascadeMonHocName === m.MonHocName }" @click="pickMon(m.MonHocName)">
							<span class="lms-t-dot" :style="{ background: m.dot }"></span>
							<span class="lms-t-label">{{ m.MonHocName === 'Ngoại ngữ' ? 'English' : m.MonHocName
							}}</span><v-chip v-if="m.hasLibraryOnly" size="x-small" color="grey" variant="tonal">Có nội dung</v-chip><v-icon v-if="m.hasDelegated" size="13" color="warning" title="Có nội dung được giáo viên khác phân quyền">mdi-account-arrow-left-outline</v-icon>
							<v-icon v-if="cascadeMonHocName === m.MonHocName" size="14" color="teal">mdi-check</v-icon>
							<span v-else class="lms-t-arrow">&rsaquo;</span>
						</div>
					</div>
				</div>
				<!-- Tier 3: Tuan -->
				<div class="lms-tier" style="flex:1;display:flex;flex-direction:column">
					<div class="lms-tier-hd"><span class="lms-tier-label">{{ $t('message.WeekStudy') }}</span></div>
					<div class="lms-tier-body" style="flex:1;overflow-y:auto">
						<div v-if="!cascadeMonHocName" class="lms-tier-locked">
							<v-icon size="13">mdi-lock-outline</v-icon> {{ $t('message.SelectSubjectFirst') }}
						</div>
						<template v-else>
							<div v-for="w in DSTuanCascade" :key="'m-w-' + w.TuanHocID"
								class="lms-t-item lms-t-item--week" :class="{ active: cascadeTuanID === w.TuanHocID }"
								@click="pickTuan(w.TuanHocID); showCascadeDrawer = false">
								<div class="lms-t-label">
									<div>{{ formatTuanHienThi(w.Tuan_HienThi) }} <v-chip v-if="w.delegatedCount" size="x-small" color="warning" variant="tonal" prepend-icon="mdi-account-arrow-left-outline">{{ w.delegatedCount }}</v-chip></div>
									<div class="d-flex ga-1 mt-1">
										<span v-if="w.isPlanningOnly" class="lms-pill lms-pill-warn">{{ $t('message.NoLessonYet') }}</span>
										<span v-if="w.ok" class="lms-pill lms-pill-ok">{{ w.ok }}</span>
										<span v-if="w.warn" class="lms-pill lms-pill-warn">{{ w.warn }}</span>
										<span v-if="w.danger" class="lms-pill lms-pill-danger">{{ w.danger }}</span>
									</div>
								</div>
								<v-icon v-if="cascadeTuanID === w.TuanHocID" size="14" color="teal">mdi-check</v-icon>
								<span v-else class="lms-t-arrow">&rsaquo;</span>
							</div>
							<div v-if="currentTuanFallback" class="lms-t-item lms-t-item--week"
								:class="{ active: cascadeTuanID === currentTuanFallback.TuanHocID }"
								@click="pickTuan(currentTuanFallback.TuanHocID); showCascadeDrawer = false">
								<div class="lms-t-label">
									<div>{{ formatTuanHienThi(currentTuanFallback.Tuan_HienThi) }}</div>
									<div class="d-flex ga-1 mt-1">
										<span class="lms-pill lms-pill-warn">{{ $t('message.NoLessonYet') }}</span>
									</div>
								</div>
								<v-icon v-if="cascadeTuanID === currentTuanFallback.TuanHocID" size="14" color="teal">
									mdi-check</v-icon>
								<span v-else class="lms-t-arrow">&rsaquo;</span>
							</div>
						</template>
					</div>
				</div>
			</div>
		</v-navigation-drawer>

		<!-- 3-PANEL LAYOUT -->
		<div class="lms-layout">

			<!-- LEFT: CASCADE SIDEBAR (desktop only) -->
			<div class="lms-cascade" ref="tourCascade" v-if="!$vuetify.display.mobile">
				<!-- Tier 1: Khoi -->
				<div class="lms-tier">
					<div class="lms-tier-hd"><span class="lms-tier-label">{{ $t('message.Grade') }}</span></div>
					<div class="lms-tier-body">
						<template v-if="loadingGroups">
							<div v-for="n in 4" :key="'sk-k-' + n" class="lms-t-item" style="pointer-events:none">
								<span class="lms-t-dot" style="background:#e0e0e0"></span>
								<v-skeleton-loader type="text" width="60%" style="flex:1" />
							</div>
						</template>
						<template v-else>
							<div v-for="k in DSKhoiCascade" :key="k.KhoiID" class="lms-t-item"
								:class="{ active: cascadeKhoiID === k.KhoiID }" @click="pickKhoi(k.KhoiID)">
								<span class="lms-t-dot" :style="{ background: k.dot }"></span>
								<span class="lms-t-label">{{ k.label }}</span><v-chip v-if="k.hasLibraryOnly" size="x-small" color="grey" variant="tonal">Có nội dung</v-chip><v-icon v-if="k.hasTeaching" size="13" color="success" title="Đang dạy khối">mdi-school-outline</v-icon><v-icon v-if="k.hasDelegated" size="13" color="warning" title="Có tài liệu được chia sẻ">mdi-account-arrow-left-outline</v-icon>
								<v-icon v-if="cascadeKhoiID === k.KhoiID" size="14" color="teal">mdi-check</v-icon>
								<span v-else class="lms-t-arrow">&rsaquo;</span>
							</div>
						</template>
					</div>
				</div>

				<!-- Tier 2: Mon -->
				<div class="lms-tier">
					<div class="lms-tier-hd">
						<span class="lms-tier-label">{{ $t('message.Subject') }}</span>
					</div>
					<div class="lms-tier-body">
						<div v-if="!cascadeKhoiID" class="lms-tier-locked">
							<v-icon size="13">mdi-lock-outline</v-icon> {{ $t('message.SelectGradeFirst') }}
						</div>
						<div v-for="m in DSMonCascade" v-else :key="m.MonHocName" class="lms-t-item"
							:class="{ active: cascadeMonHocName === m.MonHocName }" @click="pickMon(m.MonHocName)">
							<span class="lms-t-dot" :style="{ background: m.dot }"></span>
							<span class="lms-t-label">{{ m.MonHocName === 'Ngoại ngữ' ? 'English' : m.MonHocName
							}}</span><v-chip v-if="m.hasLibraryOnly" size="x-small" color="grey" variant="tonal">Có nội dung</v-chip><v-icon v-if="m.hasDelegated" size="13" color="warning" title="Có nội dung được giáo viên khác phân quyền">mdi-account-arrow-left-outline</v-icon>
							<v-icon v-if="cascadeMonHocName === m.MonHocName" size="14" color="teal">mdi-check</v-icon>
							<span v-else class="lms-t-arrow">&rsaquo;</span>
						</div>
					</div>
				</div>

				<!-- Tier 3: Tuan -->
				<div class="lms-tier lms-tier-flex">
					<div class="lms-tier-hd">
						<span class="lms-tier-label">{{ $t('message.WeekStudy') }}</span>
					</div>
					<div class="lms-tier-body">
						<div v-if="!cascadeMonHocName" class="lms-tier-locked">
							<v-icon size="13">mdi-lock-outline</v-icon> {{ $t('message.SelectSubjectFirst') }}
						</div>
						<template v-else>
							<div v-for="w in DSTuanCascade" :key="w.TuanHocID" class="lms-t-item lms-t-item--week"
								:class="{ active: cascadeTuanID === w.TuanHocID }" @click="pickTuan(w.TuanHocID)">
								<div class="lms-t-label">
									<div>{{ formatTuanHienThi(w.Tuan_HienThi) }} <v-chip v-if="w.delegatedCount" size="x-small" color="warning" variant="tonal" prepend-icon="mdi-account-arrow-left-outline">{{ w.delegatedCount }}</v-chip></div>
								<div class="d-flex ga-1 mt-1">
									<span v-if="w.isPlanningOnly" class="lms-pill lms-pill-warn">{{ $t('message.NoLessonYet') }}</span>
									<span v-if="w.ok" class="lms-pill lms-pill-ok">{{ w.ok }}</span>
										<span v-if="w.warn" class="lms-pill lms-pill-warn">{{ w.warn }}</span>
										<span v-if="w.danger" class="lms-pill lms-pill-danger">{{ w.danger }}</span>
									</div>
								</div>
								<v-icon v-if="cascadeTuanID === w.TuanHocID" size="14" color="teal">mdi-check</v-icon>
								<span v-else class="lms-t-arrow">&rsaquo;</span>
							</div>
							<div v-if="currentTuanFallback" class="lms-t-item lms-t-item--week"
								:class="{ active: cascadeTuanID === currentTuanFallback.TuanHocID }"
								@click="pickTuan(currentTuanFallback.TuanHocID)">
								<div class="lms-t-label">
									<div>{{ formatTuanHienThi(currentTuanFallback.Tuan_HienThi) }}</div>
									<div class="d-flex ga-1 mt-1">
										<span class="lms-pill lms-pill-warn">{{ $t('message.NoLessonYet') }}</span>
									</div>
								</div>
								<v-icon v-if="cascadeTuanID === currentTuanFallback.TuanHocID" size="14" color="teal">
									mdi-check</v-icon>
								<span v-else class="lms-t-arrow">&rsaquo;</span>
							</div>
						</template>
					</div>
				</div>
			</div>

			<!-- CENTER: MAIN CONTENT -->
			<div class="lms-main">
				<template v-if="!cascadeTuanID">
					<div class="lms-empty-state">
						<v-icon size="44" class="mb-3 opacity-40">mdi-table-search</v-icon>
						<p class="text-body-2 font-weight-medium text-medium-emphasis">
							{{ !cascadeKhoiID ? $t('message.SelectGradeToStart') : !cascadeMonHocName ?
							$t('message.SelectSubjectFirst') : $t('message.SelectWeekStudy') }}
						</p>
						<p class="text-caption text-disabled">{{ $t('message.CurrentWeekAutoSelected') }}</p>
					</div>
				</template>

				<template v-else>
					<!-- Panel header -->
					<div class="lms-panel-head">
						<div>
							<div class="lms-panel-title">
								{{ cascadeMonHocName === 'Ngoại ngữ' ? 'English' : cascadeMonHocName }}
								&nbsp;·&nbsp;{{ formatTuanHienThi(cascadeTuanHienThi) }}
							</div>
							<div class="lms-panel-sub">{{ $t('message.Grade') }} {{ cascadeKhoiID }}</div>
						</div>
						<div v-if="cascadeKhoiItem && hasMyClasses" class="d-flex ga-2 flex-wrap w-100 w-sm-auto lms-panel-actions">
							<v-btn color="teal" variant="outlined" size="small" class="flex-grow-1 flex-sm-grow-0"
								@click="OpenModalAddNoiDung(cascadeKhoiItem, 1)">
								<v-icon start>mdi-plus</v-icon>{{ $t('message.AddLesson') }}
							</v-btn>
							<v-btn color="primary" variant="outlined" size="small" class="flex-grow-1 flex-sm-grow-0"
								@click="OpenModalAddNoiDung(cascadeKhoiItem, 0)">
								<v-icon start>mdi-plus</v-icon>{{ $t('message.AddAssignment') }}
							</v-btn>
						</div>
					</div>

					<!-- Stat grid -->
					<div class="lms-stat-grid" ref="tourStatGrid">
						<div class="lms-stat-card lms-stat-ok">
							<div class="lms-stat-val">{{ centerStats.ok }}</div>
							<div class="lms-stat-label">{{ $t('message.ClassCompleted') }}</div>
						</div>
						<div class="lms-stat-card lms-stat-warn">
							<div class="lms-stat-val">{{ centerStats.warn }}</div>
							<div class="lms-stat-label">{{ $t('message.ClassNeedGrade') }}</div>
						</div>
						<div class="lms-stat-card lms-stat-danger">
							<div class="lms-stat-val">{{ centerStats.danger }}</div>
							<div class="lms-stat-label">{{ $t('message.ClassNoAssignment') }}</div>
						</div>
					</div>

					<!-- Classes + assignments -->
					<div class="lms-table-card" ref="tourClassTable">
						<div class="lms-table-card-head">
							<span class="lms-table-card-title">{{ $t('message.ClassAndAssignmentList') }}</span>
							<span class="text-caption text-disabled">
								{{centerClasses.filter(c => c.LopID !== -1).length}} {{ $t('message.ClassUnit') }}
								<template v-if="centerClasses.some(c => c.LopID === -1)"> &amp; {{
									$t('message.AssignByStudent') }}</template>
							</span>
						</div>
						<div v-if="centerClasses.length === 0"
							class="text-center pa-8 text-disabled d-flex justify-center align-center flex-column">
							<v-icon size="32" class="mb-2 d-block opacity-40">mdi-table-off</v-icon>
							<span class="text-body-2">{{ $t('message.ClassNotAssigned') }}</span>
						</div>
						<template v-else>
							<div v-for="classItem in centerClasses" :key="classItem.LopID">
								<template v-if="classItem.LopID !== -1">
									<div class="lms-class-row">
										<div class="d-flex align-center ga-3">
											<span class="lms-lop-badge">{{ classItem.TenLop }}</span>
											<div>
												<div class="lms-class-name">{{ classItem.TenLop }}</div>
												<div class="lms-class-meta">
													<span>{{ $t('message.ClassSize') }}: {{ classItem.StudentCount }} {{
														$t('message.Students') }}</span>
													<span v-if="getPendingCount(classItem) > 0" class="lms-pending-tag">
														<v-icon size="13">mdi-alert-circle</v-icon>
														{{ getPendingCount(classItem) }} {{ $t('message.NeedGrade') }}
													</span>
												</div>
											</div>
										</div>
										<v-btn icon size="small" variant="text" color="purple"
											@click="xemTinhTrang(classItem)">
											<v-icon>mdi-table-eye</v-icon>
											<v-tooltip activator="parent" location="top">{{ $t('message.ViewGradebook')
												}}</v-tooltip>
										</v-btn>
									</div>
									<div class="lms-assignments-body">
										<div v-if="!classItem.assignments || classItem.assignments.length === 0"
											class="text-center text-grey pa-3 text-caption">
											{{ $t('message.ClassNotAssigned') }}
										</div>
										<uc-assignment-status-row v-for="assignment in classItem.assignments"
											:key="assignment.AssignToClassID" :assignment="assignment" />
									</div>
								</template>
								<template v-else>
									<div class="lms-class-row" style="border-left:3px solid #7E57C2">
										<div class="d-flex align-center ga-3">
											<span class="lms-lop-badge"
												style="background:#7E57C222;color:#7E57C2;border:none">
												<v-icon size="14" color="#7E57C2">mdi-account-group</v-icon>
											</span>
											<div>
												<div class="lms-class-name" style="color:#7E57C2">{{
													$t('message.AssignByStudent') }}</div>
												<div class="lms-class-meta">
													<span>{{ classItem.assignments.length }} {{
														$t('message.PersonalAssignment') }}</span>
												</div>
											</div>
										</div>
									</div>
									<div class="lms-assignments-body">
										<uc-assignment-status-row-assign-to-student
											v-for="assignment in mergeStudentAssignments(classItem.assignments)"
											:key="assignment.AssignmentID" :assignment="assignment" />
									</div>
								</template>
							</div>
						</template>
					</div>
				</template>
			</div>

		</div>

		<!-- Bài tập cần chấm mở theo ngữ cảnh, không chiếm chiều ngang của danh sách lớp. -->
		<v-navigation-drawer v-model="showFocusDrawer" temporary location="right" width="360"
			ref="tourRightSidebar" class="lms-focus-drawer" style="top:0">
			<div class="lms-focus-drawer__content">
				<v-toolbar density="compact" color="white" class="lms-focus-drawer__toolbar">
					<v-toolbar-title class="lms-focus-drawer__title">
						<v-icon size="16" color="teal" class="me-1">mdi-check-circle-outline</v-icon>
						{{ focusDrawerLabel }}
					</v-toolbar-title>
					<template #append>
						<v-btn icon size="small" variant="text" @click="showFocusDrawer = false">
							<v-icon>mdi-close</v-icon>
							<v-tooltip activator="parent" location="bottom">Đóng</v-tooltip>
						</v-btn>
					</template>
				</v-toolbar>
				<div class="lms-focus-drawer__body">
					<uc-focus-task :khoiID="cascadeKhoiID" />
				</div>
			</div>
		</v-navigation-drawer>

		<uc-btn-with-dialog-add-bt v-if="isShowModalAddNoiDung" v-model:is-open="isShowModalAddNoiDung"
			:khoi-item="KhoiItem" :tuan-hoc-id="cascadeTuanID" :default-type="defaultType" />
		<uc-my-liberies v-if="isShowMyLiberies" v-model:is-open="isShowMyLiberies" :ds-mon-hoc-active="DSMonHocActive"
			:teaching-groups="teachingGroups" v-model:content-library="contentLibrary"
			@create-content="(item) => { this.OpenModalAddNoiDung(item) }" />
		<uc-change-user v-if="isShowModalChangeUser" v-model:is-open="isShowModalChangeUser"
			:giaovienid="vueData.GiaoVienID_Selected" />
		<uc-onboarding v-model="drawerOnboarding" @done="onOnboardingDone" @start-tour="startTour" />
		<uc-tour-overlay :active="tourActive" :step="tourStep" :total-steps="tourSteps.length"
			:title="tourSteps[tourStep] && tourSteps[tourStep].title"
			:body="tourSteps[tourStep] && tourSteps[tourStep].body" :target-rect="tourTargetRect" @prev="tourPrev"
			@next="tourNext" @close="closeTour" />
	</div>
</template>

<script>
	export default {
		name: 'uc-lms-tc-dashboard-v2',
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
		props: {
			loadingGroups: Boolean,
			focusTasks: Array,
			teachingGroups: Array,
			schedule: Array,
			activities: Array,
			contentLibrary: Array,
		},
		emits: ['view-class', 'grade-class', 'create-assignment'],
		data() {
			const toggle = localStorage.getItem('IsLanguage') ? (localStorage.getItem('IsLanguage') == 'true' ? true : false) : false
			this.$i18n.locale = toggle ? 'en' : 'vi'
			return {
				vueData,
				toggle,
				isShowModalChangeUser: false,
				showCascadeDrawer: false,
				showFocusDrawer: false,
				isShowModalAddNoiDung: false,
				defaultType: 0,
				DSMonHocActive: [],
				KhoiItem: {},
				isShowMyLiberies: false,
				// Khôi phục lựa chọn khi iframe đóng làm component được mount lại.
				cascadeKhoiID: vueData.cascadeKhoiID ?? null,
				cascadeMonHocName: vueData.cascadeMonHocName ?? null,
				cascadeTuanID: vueData.cascadeTuanID ?? null,
				drawerOnboarding: false,
				tourActive: false,
				tourStep: 0,
				tourTargetRect: null,
				tourStepKeys: [
					{ ref: 'tourCascade', titleKey: 'TourStep1Title', bodyKey: 'TourStep1Body' },
					{ ref: 'tourStatGrid', titleKey: 'TourStep2Title', bodyKey: 'TourStep2Body' },
					{ ref: 'tourClassTable', titleKey: 'TourStep3Title', bodyKey: 'TourStep3Body' },
					{ ref: 'tourRightSidebar', titleKey: 'TourStep4Title', bodyKey: 'TourStep4Body' },
					{ ref: 'tourBtnThuVien', titleKey: 'TourStep5Title', bodyKey: 'TourStep5Body' },
					{ ref: 'tourBtnThongKe', titleKey: 'TourStep6Title', bodyKey: 'TourStep6Body' },
				],
				khoiDotColors: ['#378ADD', '#1D9E75', '#BA7517', '#7F77DD', '#D85A30', '#888780'],
				monDotColors: {
					'Toán': '#378ADD', 'Tiếng Việt': '#1D9E75', 'Ngoại ngữ': '#7F77DD',
					'Khoa học': '#D85A30', 'Lịch sử': '#BA7517', 'Địa lý': '#D4537E',
					'Mỹ thuật': '#888780', 'Thể dục': '#888780', 'Tin học': '#378ADD',
					'GDCD': '#D4537E', 'Vật lý': '#BA7517', 'Hóa học': '#1D9E75',
					'Sinh học': '#3B6D11', 'Âm nhạc': '#D4537E',
				},
			}
		},
		computed: {
			focusTaskCount() {
				// Badge chỉ phản ánh bài đang chờ chấm ở đúng khối giáo viên đang xem,
				// không lấy tổng các bài chưa hoàn tất của mọi khối.
				const tasks = Array.isArray(this.focusTasks) ? this.focusTasks : []
				return tasks.filter(task => {
					const isCurrentGrade = !this.cascadeKhoiID || String(task.KhoiID) === String(this.cascadeKhoiID)
					return isCurrentGrade && Number(task.PendingGradingCount || 0) > 0
				}).length
			},
			focusTaskCountLabel() {
				return this.focusTaskCount > 99 ? '99+' : String(this.focusTaskCount)
			},
			focusDrawerLabel() {
				return this.toggle ? 'Assignments to grade' : 'Bài cần chấm'
			},
			tourSteps() {
				return this.tourStepKeys.map(s => ({
					ref: s.ref,
					title: this.$t('message.' + s.titleKey),
					body: this.$t('message.' + s.bodyKey),
				}))
			},
			DSKhoiCascade() {
				const seen = {}, result = []
				this.teachingGroups.forEach(g => {
					if (!seen[g.KhoiID]) {
						seen[g.KhoiID] = true
						// Sidebar Khối dùng cùng quy ước với thư viện: direct teacher là xanh,
						// assignment của giáo viên khác được phân quyền là cam.
							result.push({
								KhoiID: g.KhoiID,
								label: this.$t('message.Grade') + ' ' + g.KhoiID,
								hasTeaching: this.teachingGroups.some(x => String(x.KhoiID) === String(g.KhoiID) && Number(x.IsDirectTeacher) === 1),
								hasDelegated: this.teachingGroups.some(x => String(x.KhoiID) === String(g.KhoiID) && this.groupHasDelegated(x)),
								dot: this.khoiDotColors[result.length % this.khoiDotColors.length]
							})
					}
				})
				return result.sort((a, b) => a.KhoiID - b.KhoiID)
			},
			DSMonCascade() {
				if (!this.cascadeKhoiID) return []
				const seen = {}, result = []
				this.teachingGroups.filter(g => g.KhoiID === this.cascadeKhoiID).forEach(g => {
					if (!seen[g.MonHocName]) {
						seen[g.MonHocName] = true
							result.push({ MonHocName: g.MonHocName, hasDelegated: this.groupHasDelegated(g), dot: this.monDotColors[g.MonHocName] || '#888780' })
					}
				})
				return result
			},
			currentTuanFallback() {
				if (!this.cascadeMonHocName || this.DSTuanCascade.length > 0) return null
				const active = vueData.DSTuanHoc?.find(t => t.Is_Active)
				if (!active) return null
				return { TuanHocID: active.TuanHocID, Tuan_HienThi: active.Tuan_HienThi || ('Tu\u1ea7n ' + active.TuanHocID) }
			},
			planningWeeks() {
				const weeks = Array.isArray(vueData.DSTuanHoc) ? vueData.DSTuanHoc : []
				const active = weeks.find(w => w.Is_Active === 1 || w.Is_Active === true || String(w.Is_Active) === '1')
				if (!active) return []
				const currentID = Number(active.TuanHocID)
				const next = weeks
					.filter(w => Number(w.TuanHocID) > currentID)
					.sort((a, b) => Number(a.TuanHocID) - Number(b.TuanHocID))[0]
				return [
					...weeks.filter(w => Number(w.TuanHocID) <= currentID),
					next,
				].filter(Boolean)
			},
			DSTuanCascade() {
				if (!this.cascadeKhoiID || !this.cascadeMonHocName) return []
				const group = this.teachingGroups.find(g => g.KhoiID === this.cascadeKhoiID && g.MonHocName === this.cascadeMonHocName)
				if (!group || !group.weeks) return []
				const weeksByID = new Map(group.weeks.map(w => [String(w.TuanHocID), w]))
				this.planningWeeks.forEach(w => {
					if (!weeksByID.has(String(w.TuanHocID))) weeksByID.set(String(w.TuanHocID), { ...w, classes: [] })
				})
				return [...weeksByID.values()].sort((a, b) => b.TuanHocID - a.TuanHocID).map(w => {
					const classes = w.sortedClasses || w.classes || []
					const real = classes.filter(c => c.LopID !== -1)
					const delegatedCount = this.weekDelegatedCount(w)
					const hasAsm = classes.some(c => c.assignments?.length > 0)
					return {
						TuanHocID: w.TuanHocID,
						Tuan_HienThi: w.Tuan_HienThi,
						sortedClasses: classes,
						isPlanningOnly: !hasAsm,
						ok: classes.filter(c => c.assignments?.length > 0 && this.getPendingCount(c) === 0).length,
						warn: classes.filter(c => this.getPendingCount(c) > 0).length,
						danger: real.filter(c => !c.assignments || c.assignments.length === 0).length,
						delegatedCount,
					}
				})
			},
			centerClasses() {
				if (!this.cascadeTuanID) return []
				const week = this.DSTuanCascade.find(w => w.TuanHocID === this.cascadeTuanID)
				return week ? week.sortedClasses : []
			},
			centerStats() {
				const real = this.centerClasses.filter(c => c.LopID !== -1)
				return {
					ok: real.filter(c => c.assignments?.length > 0 && this.getPendingCount(c) === 0).length,
					warn: real.filter(c => this.getPendingCount(c) > 0).length,
					danger: real.filter(c => !c.assignments || c.assignments.length === 0).length,
				}
			},
			hasMyClasses() {
				if (!this.cascadeKhoiID || !this.cascadeMonHocName) return false
				const group = this.teachingGroups.find(g => g.KhoiID === this.cascadeKhoiID && g.MonHocName === this.cascadeMonHocName)
				if (!group) return false
				if (group.IsDirectTeacher === 1 || group.IsDirectTeacher === true) return true
				if (!group.weeks) return false
				return group.weeks.some(w => (w.classes || []).some(c => c.LopID !== -1 && (c.assignments || []).some(a => String(a.IsMyContent) === '1' || a.IsMyContent === true)))
			},
			cascadeKhoiItem() {
				if (!this.cascadeKhoiID || !this.cascadeMonHocName) return null
				return this.teachingGroups.find(g => g.KhoiID === this.cascadeKhoiID && g.MonHocName === this.cascadeMonHocName) || null
			},
			cascadeTuanHienThi() {
				if (!this.cascadeTuanID) return null
				const week = this.DSTuanCascade.find(w => w.TuanHocID === this.cascadeTuanID)
				return week ? week.Tuan_HienThi : null
			},
			cascadeBreadcrumb() {
				const monLabel = this.cascadeMonHocName
					? (this.cascadeMonHocName === 'Ngoại ngữ' ? 'English' : this.cascadeMonHocName)
					: this.$t('message.Subject')
				return [
					{ label: this.cascadeKhoiID ? this.$t('message.Grade') + ' ' + this.cascadeKhoiID : this.$t('message.Grade'), done: !!this.cascadeKhoiID, active: !this.cascadeKhoiID, step: 0 },
					{ label: monLabel, done: !!this.cascadeMonHocName, active: !!this.cascadeKhoiID && !this.cascadeMonHocName, step: 1 },
					{ label: this.formatTuanHienThi(this.cascadeTuanHienThi) || this.$t('message.WeekStudy'), done: !!this.cascadeTuanID, active: !!this.cascadeMonHocName && !this.cascadeTuanID, step: 2 },
				]
			},
		},
		watch: {
			teachingGroups: {
				handler(newVal) {
					if (!newVal || newVal.length === 0) return
					console.log('[lms-teacher-dashboard][cascade] teachingGroups reloaded', {
						count: newVal.length,
						selected: { khoi: this.cascadeKhoiID, mon: this.cascadeMonHocName, tuan: this.cascadeTuanID },
						vueData: { khoi: vueData.cascadeKhoiID, mon: vueData.cascadeMonHocName, tuan: vueData.cascadeTuanID },
					})
					const previousKhoiID = this.cascadeKhoiID
					const previousMonHocName = this.cascadeMonHocName
					const previousTuanID = this.cascadeTuanID
					this.DSMonHocActive = [...new Set(newVal.map(item => item.MonHocName))].map(mh => {
						const groups = newVal.filter(item => item.MonHocName == mh)
						groups.forEach(g => {
							g.allIndices = g.weeks?.map((_, i) => i) ?? []
							g.weeks?.forEach(w => {
								w.sortedClasses = [...w.classes].sort((a, b) => b.LopID - a.LopID)
								w.allClassIndices = w.classes.map((_, i) => i)
							})
						})
						return { MonHocName: mh, activeTab: groups[0].KhoiID, groups, groupsWithWeeks: groups.filter(g => g.weeks?.length > 0) }
					})

					const selectedKhoi = newVal.some(g => String(g.KhoiID) === String(previousKhoiID))
					const selectedGroup = selectedKhoi && newVal.find(g =>
						String(g.KhoiID) === String(previousKhoiID) && g.MonHocName === previousMonHocName)
					const selectedTuan = selectedGroup?.weeks?.some(w =>
						String(w.TuanHocID) === String(previousTuanID))
					this.cascadeKhoiID = selectedKhoi ? previousKhoiID : null
					this.cascadeMonHocName = selectedGroup ? previousMonHocName : null
					this.cascadeTuanID = selectedTuan ? previousTuanID : null
					this.$nextTick(() => this.autoSelectCascade())
				},
				immediate: false,
			},
			toggle(val) {
				localStorage.setItem('IsLanguage', val)
				this.$i18n.locale = val ? 'en' : 'vi'
			},
			cascadeKhoiID(val) {
				vueData.cascadeKhoiID = val ?? null
				console.log('[lms-teacher-dashboard][cascade] khối changed', val)
				this.$nextTick(() => this.autoSelectCascade())
			},
			cascadeMonHocName(val) {
				vueData.cascadeMonHocName = val ?? null
				console.log('[lms-teacher-dashboard][cascade] môn changed', val)
				this.$nextTick(() => this.autoSelectCascade())
			},
			cascadeTuanID(val) {
				vueData.cascadeTuanID = val ?? null
				vueData.cascadeTuanHienThi = this.cascadeTuanHienThi ?? null
				console.log('[lms-teacher-dashboard][cascade] tuần changed', val)
			},
			cascadeTuanHienThi(val) {
				vueData.cascadeTuanHienThi = val ?? null
			},
		},
		created() {
			this.DSMonHocActive = [...new Set(this.teachingGroups.map(item => item.MonHocName))].map(mh => {
				const groups = this.teachingGroups.filter(item => item.MonHocName == mh)
				groups.forEach(g => {
					g.allIndices = g.weeks?.map((_, i) => i) ?? []
					g.weeks?.forEach(w => {
						w.sortedClasses = [...w.classes].sort((a, b) => b.LopID - a.LopID)
						w.allClassIndices = w.classes.map((_, i) => i)
					})
				})
				return { MonHocName: mh, activeTab: groups[0].KhoiID, groups, groupsWithWeeks: groups.filter(g => g.weeks?.length > 0) }
			})
			this.$nextTick(() => this.autoSelectCascade())
		},
		mounted() {
			console.log('[lms-teacher-dashboard][cascade] mounted', {
				local: { khoi: this.cascadeKhoiID, mon: this.cascadeMonHocName, tuan: this.cascadeTuanID },
				vueData: { khoi: vueData.cascadeKhoiID, mon: vueData.cascadeMonHocName, tuan: vueData.cascadeTuanID },
			})
			if (!localStorage.getItem('lms-tc-tour-done')) {
				this.drawerOnboarding = true
			}
		},
		methods: {
			groupHasDelegated(group) {
				return (group?.weeks || []).some(w => this.weekDelegatedCount(w) > 0)
			},
			weekDelegatedCount(week) {
				return (week?.classes || week?.sortedClasses || []).reduce((sum, c) =>
					sum + (c.assignments || []).filter(a => String(a.IsMyContent) === '0').length, 0)
			},
			autoSelectCascade() {
				// Chỉ tự chọn khi cấp hiện tại có đúng một phương án, không thay thế lựa chọn thủ công.
				if (!this.cascadeKhoiID && this.DSKhoiCascade.length === 1) {
					this.pickKhoi(this.DSKhoiCascade[0].KhoiID)
					return
				}
				if (!this.cascadeMonHocName && this.DSMonCascade.length === 1) {
					this.pickMon(this.DSMonCascade[0].MonHocName)
					return
				}
				if (!this.cascadeTuanID) {
					const active = this.DSTuanCascade.find(w => this.planningWeeks.some(p =>
						String(p.TuanHocID) === String(w.TuanHocID) &&
						(p.Is_Active === 1 || p.Is_Active === true || String(p.Is_Active) === '1')))
					if (active) this.pickTuan(active.TuanHocID)
					else if (this.DSTuanCascade.length === 1) this.pickTuan(this.DSTuanCascade[0].TuanHocID)
				}
			},
			getPendingCount(classItem) {
				if (!classItem.assignments) return 0
				return classItem.assignments.reduce((sum, a) => sum + (a.PendingGradingCount || 0), 0)
			},
			mergeStudentAssignments(assignments) {
				if (!assignments || !assignments.length) return []
				const map = {}
				assignments.forEach(a => {
					const id = a.AssignmentID || a.AssignToStudentID
					if (!map[id]) {
						map[id] = {
							...a,
							TotalStudents: a.TotalStudents || a.TotalStudentsInClass || 1,
							SubmittedCount: a.SubmittedCount || 0,
							GradedCount: a.GradedCount || 0,
							PendingGradingCount: a.PendingGradingCount || 0,
						}
					} else {
						map[id].SubmittedCount = (map[id].SubmittedCount || 0) + (a.SubmittedCount || 0)
						map[id].TotalStudents = (map[id].TotalStudents || 0) + (a.TotalStudents || a.TotalStudentsInClass || 1)
						map[id].GradedCount = (map[id].GradedCount || 0) + (a.GradedCount || 0)
						map[id].PendingGradingCount = (map[id].PendingGradingCount || 0) + (a.PendingGradingCount || 0)
					}
				})
				return Object.values(map)
			},
			xemTinhTrang(assignment) {
				this.iframeRef.value.openWindow({
					title: this.$t('message.ClassGradebook'),
					url: `/lms-teacher-gradebook?LopID=${assignment.LopID}&MonHocID=${assignment.MonHocID}&HocKi=${vueData.NienKhoaItem?.HocKi}&AssignType=CLASS`,
					onclose: () => vueData.initPage()
				})
			},
			OpenModalAddNoiDung(KhoiItem, type = 0) {
				this.KhoiItem = { ...KhoiItem }
				this.defaultType = type
				this.isShowModalAddNoiDung = true
			},
			OpenMyLiberies() {
				this.isShowMyLiberies = true
			},
			OpenDashboard() {
				this.iframeRef.value.openWindow({
					title: this.$t('message.LearningTracking'),
					url: `/lms-teacher-theo-doi-hoc-tap?HocKi=${vueData.NienKhoaItem.HocKi}`,
				})
			},
			onHandleOpenChangeGV() {
				this.isShowModalChangeUser = true
			},
			onOnboardingDone() {
				localStorage.setItem('lms-tc-tour-done', '1')
				this.drawerOnboarding = false
			},
			startTour() {
				this.tourActive = true
				this.tourStep = 0
				this.$nextTick(() => this.updateTourRect())
			},
			updateTourRect() {
				const stepDef = this.tourSteps[this.tourStep]
				if (!stepDef) { this.tourActive = false; return }
				const el = this.$refs[stepDef.ref]
				const domEl = el ? (el.$el ?? el) : null
				if (!domEl) { this.tourTargetRect = null; return }
				const r = domEl.getBoundingClientRect()
				this.tourTargetRect = { top: r.top, left: r.left, width: r.width, height: r.height }
			},
				tourNext() {
				if (this.tourStep < this.tourSteps.length - 1) {
					this.tourStep++
					if (this.tourSteps[this.tourStep]?.ref === 'tourRightSidebar') {
						this.showFocusDrawer = true
					}
					this.$nextTick(() => this.updateTourRect())
				} else {
					this.closeTour()
				}
			},
				tourPrev() {
				if (this.tourStep > 0) {
					if (this.tourSteps[this.tourStep]?.ref === 'tourRightSidebar') {
						this.showFocusDrawer = false
					}
					this.tourStep--
					this.$nextTick(() => this.updateTourRect())
				}
			},
				closeTour() {
				this.tourActive = false
				this.tourTargetRect = null
				this.showFocusDrawer = false
			},
			pickKhoi(khoiID) {
				if (this.cascadeKhoiID === khoiID) return
				this.cascadeKhoiID = khoiID
				this.cascadeMonHocName = null
				this.cascadeTuanID = null
			},
			pickMon(monHocName) {
				if (this.cascadeMonHocName === monHocName) return
				this.cascadeMonHocName = monHocName
				this.cascadeTuanID = null
			},
			pickTuan(tuanID) {
				this.cascadeTuanID = tuanID
			},
			formatTuanHienThi(text) {
				if (!text) return ''
				if (this.$i18n.locale === 'en') {
					return text.replace(/^Tuần\s+/i, 'Week ')
						.replace(/-\s*Tháng\s+/gi, '- Month ')
				}
				return text
			},
			// Thanh đầu trang chỉ cần ngữ cảnh ngắn; ngày đầy đủ vẫn giữ trong title
			// để người dùng xem khi rê chuột, tránh làm breadcrumb chiếm hết chiều ngang.
			formatTopbarBreadcrumb(label, step) {
				if (!label || step !== 2) return label
				return label.replace(/\s*-\s*\([^)]*\)\s*$/, '').replace(/\s*-\s*/g, ' · ')
			},
			resetCascadeFrom(step) {
				if (step === 0) { this.cascadeKhoiID = null; this.cascadeMonHocName = null; this.cascadeTuanID = null }
				else if (step === 1) { this.cascadeMonHocName = null; this.cascadeTuanID = null }
				else if (step === 2) { this.cascadeTuanID = null }
			},
		},
	}
</script>

<style scoped>
/* Breadcrumb trên topbar là ngữ cảnh điều hướng, nên ưu tiên chiều cao thấp và không tràn ngang. */
.lms-dashboard-root .lms-topbar {
	min-height: 44px !important;
	height: 44px;
}

.lms-dashboard-root .lms-topbar-title {
	flex: 1 1 auto;
	overflow: hidden;
}

.lms-dashboard-root .lms-topbar-dashboard-label {
	font-size: 14px !important;
}

.lms-dashboard-root .lms-topbar-action,
.lms-dashboard-root .lms-focus-trigger,
.lms-dashboard-root .lms-focus-trigger-badge {
	flex: 0 0 auto;
}

.lms-dashboard-root .lms-topbar-help {
	margin-left: 4px;
}

/* Hai nút cờ là nhóm cuối của toolbar; kích thước cố định giúp chúng không tràn khỏi viewport. */
.lms-dashboard-root .lms-language-toggle {
	flex: 0 0 auto;
	min-width: 0;
	height: 36px;
}

.lms-dashboard-root .lms-language-toggle .lms-language-btn {
	min-width: 36px;
	width: 36px;
	height: 36px;
	padding: 0;
}

.lms-dashboard-root .lms-topbar-teacher-btn {
	flex: 0 0 auto;
	min-width: auto;
	white-space: nowrap;
}

.lms-dashboard-root .lms-topbar-breadcrumb {
	display: flex;
	align-items: center;
	gap: 3px;
	min-width: 0;
	max-width: 100%;
	overflow: hidden;
	white-space: nowrap;
}

.lms-dashboard-root .lms-topbar-breadcrumb .bc-chip {
	display: inline-flex;
	align-items: center;
	min-width: 0;
	max-width: 125px;
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
	padding: 4px 8px;
	font-size: 12px;
	line-height: 1.2;
}

.lms-dashboard-root .lms-topbar-breadcrumb .bc-chip--week {
	max-width: 205px;
}

.lms-dashboard-root .lms-topbar-breadcrumb .bc-sep {
	flex: 0 0 auto;
	margin: 0 1px;
}

/* Khi màn hình hẹp, rút ngắn chip tuần trước khi để toolbar tự cuộn/tràn. */
@media (max-width: 760px) {
	.lms-dashboard-root .lms-topbar-dashboard-label {
		font-size: 13px !important;
	}

	.lms-dashboard-root .lms-topbar-breadcrumb .bc-chip {
		max-width: 88px;
		padding-left: 6px;
		padding-right: 6px;
		font-size: 11px;
	}

	.lms-dashboard-root .lms-topbar-breadcrumb .bc-chip--week {
		max-width: 145px;
	}
}

@media (max-width: 560px) {
	.lms-dashboard-root .lms-topbar-dashboard-label {
		display: none;
	}

	.lms-dashboard-root .lms-topbar-breadcrumb .bc-chip--week {
		max-width: 115px;
	}
}
</style>