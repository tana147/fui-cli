<template>
	<div v-if="!assignment" class="text-center pa-10">
		<v-progress-circular indeterminate size="64" />
		<p class="mt-4">{{ IsEngLish ? "Loading data submission..." : "Đang tải dữ liệu bài nộp..." }}</p>
	</div>

	<div v-else class="container-scroll" style="display: flex; flex-direction: column; height: calc(100dvh - 48px); overflow: hidden;">
		<!-- Assignment Header -->
		<v-card class="rounded-0 flex-shrink-0" variant="tonal" color="primary">
			<v-alert class="rounded-0 pa-2" color="primary" variant="tonal">
				<v-list-item class="pa-0">
					<template #prepend>
						<div class="d-flex align-center ga-2">
							<!-- Nút điều hướng nằm trong luồng header để không bị tách khỏi drawer hoặc đè lên avatar. -->
							<v-btn v-if="!mobile" icon size="small" variant="text"
								:title="navDrawerOpen ? 'Thu gọn danh sách câu hỏi' : 'Mở danh sách câu hỏi'"
								:aria-label="navDrawerOpen ? 'Thu gọn danh sách câu hỏi' : 'Mở danh sách câu hỏi'"
								@click="navDrawerOpen = !navDrawerOpen">
								<v-icon>{{ navDrawerOpen ? 'mdi-chevron-left' : 'mdi-menu' }}</v-icon>
							</v-btn>
							<v-avatar :size="mobile ? 40 : 60"
								@click="() => { window.postMessage('REFRESH_GRADE_LIST', '*') }" class="elevation-1">
								<!-- Timestamp buộc tải lại avatar sau khi ảnh học sinh được cập nhật. -->
								<v-img :src="vueData.v_Set.urlAvatarHocSinh + submission.HocSinhID + '/' + Date.now()" />
							</v-avatar>
						</div>
					</template>
					<template #append>
						<div class="d-flex flex-column align-center">
							<p class="text-caption " v-if="submission?.SubmissionTime">{{ $t('message.Submitted') }}: {{
								formatDate(submission.SubmissionTime) }}</p>
							<v-chip :color="getSubmissionStatusColor()" variant="elevated" size="small"
								class="progress-chip">
								{{ getSubmissionStatusText() }}
							</v-chip>
						</div>
					</template>
					<v-list-item-title>
						<p class="font-weight-medium text-h6 text-wrap">{{ assignment?.Title }}</p>
						<p class="d-flex flex-wrap text-subtitle-2">
							{{ submission?.HocSinhID }} • {{ submission?.HoTenHocSinh }} • {{ assignment?.TenLop }}
						</p>
					</v-list-item-title>
				</v-list-item>
			</v-alert>
		</v-card>
		<v-row no-gutters class="ma-0 flex-grow-1" style="min-height: 0; overflow: hidden; height: 100%;">
			<!-- INTEGRATED MODE -->
			<template v-if="assignment.AssignmentType === 'INTEGRATED'">
				<v-col cols="3" v-if="!mobile" class="pa-2" style="height: 100%; overflow-y: auto;">
					<div class="TongKet pt-2">
						<div class="text-subtitle-1 font-weight-medium py-1">
							<v-icon left color="primary">mdi-clipboard-check-outline</v-icon>
							{{ $t('message.SummaryAndGeneralComments') }}
						</div>
						<v-card class="mb-2">
							<v-card-text class="pa-0">
								<v-row dense>
									<v-col cols="12">
										<label class="font-weight-medium mb-2 d-block">{{ $t('message.FinalScore') }}</label>
										<div class="d-flex align-center">
											<v-number-input v-model="gradingSummary.totalScore" label="Điểm"
												:max="attemptMaxScore" :min="0" variant="outlined" density="compact"
												hide-details style="max-width: 100px;" control-variant="stacked" inset>
											</v-number-input>
											<span class="text-h6 ml-2 text-primary"> / {{ attemptMaxScore }}</span>
											<span class="ml-1 text-caption">{{ $t('message.points') }}</span>
										</div>
									</v-col>
									<v-col cols="12">
										<label class="font-weight-medium mb-2 d-block">{{ $t('message.OverallComment') }}</label>
										<v-textarea v-model="gradingSummary.teacherComment" hide-details
											:placeholder="$t('message.EnterGeneralFeedback')" auto-grow :rows="2" />
									</v-col>
								</v-row>
							</v-card-text>
						</v-card>
					</div>
				</v-col>
				<v-divider vertical />
				<v-col :cols="mobile ? 12 : 9" style="height: 100%; overflow-y: auto; scroll-padding-bottom: 12px;" class="pa-2">
					<v-card flat border class="mb-2">
						<v-card-text>
							<div class="text-h6 mb-2">{{ assignment.Title }}</div>
							<div v-if="assignment.Instructions" class="text-body-1 mb-3" v-html="assignment.Instructions"></div>
							<v-alert density="compact" type="info" variant="tonal" class="text-caption">
								{{ IsEngLish ? 'This is an integrated assignment. Student work is handled on an external platform.' : 'Đây là bài tập tích hợp. Học sinh thực hiện bài làm trên nền tảng bên ngoài.' }}
							</v-alert>
						</v-card-text>
					</v-card>

					<!-- Mobile grading panel -->
					<v-card v-if="mobile" flat border class="mb-2">
						<v-card-text>
							<div class="mb-3">
								<label class="font-weight-medium mb-2 d-block">{{ $t('message.FinalScore') }}</label>
								<div class="d-flex align-center">
									<v-number-input v-model="gradingSummary.totalScore" label="Điểm"
										:max="attemptMaxScore" :min="0" variant="outlined" density="compact"
										hide-details style="max-width: 100px;" control-variant="stacked" inset>
									</v-number-input>
										<span class="text-h6 ml-2 text-primary"> / {{ attemptMaxScore }}</span>
								</div>
							</div>
							<label class="font-weight-medium mb-2 d-block">{{ $t('message.OverallComment') }}</label>
							<v-textarea v-model="gradingSummary.teacherComment" hide-details variant="outlined"
								:placeholder="$t('message.EnterGeneralFeedback')" auto-grow :rows="2" />
						</v-card-text>
					</v-card>

					<!-- Action bar -->
					<v-card class="mb-2 progress-summary border" flat border>
						<v-card-text class="py-2">
							<div class="d-flex justify-space-between align-center flex-wrap ga-2">
								<v-chip :color="getSubmissionStatusColor()" variant="tonal" size="small">
									{{ getSubmissionStatusText() }}
								</v-chip>
								<div class="d-flex flex-wrap align-center ga-2"
									v-if="![0, 4].includes(submission?.SubmissionStatus)">
									<v-chip v-if="autoSaveStatus" size="x-small" :color="autoSaveStatus === 'saving' ? 'grey' : 'success'" variant="tonal">
										<v-icon v-if="autoSaveStatus === 'saving'" start size="12" class="mdi-spin">mdi-loading</v-icon>
										<v-icon v-else start size="12">mdi-check-circle-outline</v-icon>
										<span v-if="autoSaveStatus === 'saving'">{{ IsEngLish ? 'Saving...' : 'Đang lưu...' }}</span>
										<span v-else>{{ IsEngLish ? 'Auto-saved' : 'Đã lưu tự động' }}<span v-if="lastSavedRelative"> — {{ lastSavedRelative }}</span></span>
									</v-chip>
									<v-btn @click="saveGrading(false)" color="grey-darken-1" variant="outlined"
										size="small" :loading="isSaving">
										<v-icon start size="16">mdi-content-save-outline</v-icon>
										{{ IsEngLish ? "Draft Grading" : "Chấm nháp" }}
									</v-btn>
									<v-btn @click="handleOpenModalRequireResend" color="warning" size="small"
										variant="elevated" :loading="isSaving">
										<v-icon start>mdi-reload-alert</v-icon>
										{{ IsEngLish ? "Request Resubmission" : "Yêu cầu nộp lại bài" }}
									</v-btn>
									<v-btn @click="saveGrading(true)" color="success" size="small" variant="elevated"
										:loading="isSaving">
										<v-icon start size="16">mdi-send-check</v-icon>
										{{ IsEngLish ? "Complete grade and public" : "Hoàn tất & Trả bài" }}
									</v-btn>
								</div>
							</div>
						</v-card-text>
					</v-card>
				</v-col>
			</template>

			<!-- DEFAULT LMS MODE -->
			<template v-else>
				<!--
					Đây là sidebar nội bộ của trang chấm, không dùng v-navigation-drawer cấp app.
					Drawer của Vuetify đăng ký vào layout v-main và đẩy cả header sang phải 280px.
					Khi đóng, v-if tháo hẳn sidebar khỏi flex layout để vùng câu hỏi nhận lại chiều rộng.
				-->
				<aside v-if="!mobile && navDrawerOpen" class="question-drawer">
					<div class="pa-2 d-flex flex-column h-100 overflow-y-auto">
						<v-card class="question-nav mb-2" flat border>
							<div class="d-flex justify-space-between align-center text-subtitle-1 font-weight-medium cursor-pointer pa-2"
								@click="navCollapsed = !navCollapsed">
								{{ $t('message.AssignmentStructure') }}
								<v-btn icon size="small" variant="text" @click.stop="navCollapsed = !navCollapsed">
									<v-icon>{{ navCollapsed ? 'mdi-chevron-down' : 'mdi-chevron-up' }}</v-icon>
								</v-btn>
							</div>
							<v-divider />
							<v-expand-transition>
								<div v-show="!navCollapsed" class="pa-1">
									<div v-for="(group, groupIndex) in assignment.groups" :key="group.id">
										<v-list-item @click="toggleGroupCollapse(groupIndex)"
											class="group-header-item pa-2 py-0" density="compact">
											<template v-slot:prepend>
												<v-icon size="20" class="group-toggle-icon">
													{{ groupCollapsed[groupIndex] ? 'mdi-chevron-right' : 'mdi-chevron-down' }}
												</v-icon>
											</template>
											<v-list-item-title class="group-title">{{ group.title }}</v-list-item-title>
											<template v-slot:append>
												<v-chip size="small" color="primary" variant="outlined">
													{{ group.questions.length }} {{ $t('message.Question') }}
												</v-chip>
											</template>
										</v-list-item>
										<v-expand-transition>
											<div v-show="!groupCollapsed[groupIndex]" class="ml-2 mt-2">
												<div class="question-grid">
													<v-btn v-for="(q, questionIndexInGroup) in group.questions" :key="q.id"
														@click="navigateToQuestion(groupIndex, questionIndexInGroup, q.id)"
														:color="getGradingIconColor(q.id)"
														:variant="isActiveQuestion(groupIndex, questionIndexInGroup) ? 'elevated' : 'tonal'"
														class="question-btn" size="x-small">
														<v-icon size="16">{{ getGradingStatusIcon(q.id) }}</v-icon>
														{{ getGlobalQuestionNumber(groupIndex, questionIndexInGroup) }}
													</v-btn>
												</div>
											</div>
										</v-expand-transition>
									</div>
								</div>
							</v-expand-transition>
						</v-card>

						<div class="TongKet">
							<!-- View Mode Toggle -->
							<div class="d-flex flex-wrap align-center mb-1">
								<div class="text-subtitle-1 font-weight-medium py-1">
									<v-icon left color="primary">mdi-clipboard-check-outline</v-icon>
									{{ $t('message.SummaryAndGeneralComments') }}
								</div>
								<v-spacer></v-spacer>
								<v-btn-toggle v-model="viewMode" color="primary" variant="outlined" density="compact" divided mandatory>
									<v-btn value="single" size="x-small">
										<v-icon size="16">mdi-numeric-1-box</v-icon>
										<span class="ml-1 d-none d-sm-inline">{{ IsEngLish ? 'Single' : 'Từng câu' }}</span>
									</v-btn>
									<v-btn value="all" size="x-small">
										<v-icon size="16">mdi-view-list</v-icon>
										<span class="ml-1 d-none d-sm-inline">{{ IsEngLish ? 'All' : 'Tất cả' }}</span>
									</v-btn>
								</v-btn-toggle>
							</div>
							<!-- Overall Grading Summary -->
							<v-card class="mb-2">
								<v-card-text class="pa-0">
									<v-row dense>
										<v-col cols="12">
											<label class="font-weight-medium mb-2 d-block">{{ $t('message.FinalScore') }}</label>
											<div class="d-flex align-center">
												<v-number-input v-model="gradingSummary.totalScore" label="Điểm"
													:max="attemptMaxScore" :min="0" variant="outlined" density="compact"
													hide-details style="max-width: 100px;" control-variant="stacked" inset>
												</v-number-input>
													<span class="text-h6 ml-2 text-primary"> / {{ attemptMaxScore }}</span>
												<span class="ml-1 text-caption">{{ $t('message.points') }}</span>
											</div>
										</v-col>
										<v-col cols="12">
											<label class="font-weight-medium mb-2 d-block">{{ $t('message.OverallComment') }}</label>
											<v-textarea v-model="gradingSummary.teacherComment" hide-details
												:placeholder="$t('message.EnterGeneralFeedback')" auto-grow :rows="2" />
										</v-col>
									</v-row>
								</v-card-text>
							</v-card>
						</div>
					</div>
				</aside>
				<!--
					The question sidebar is a fixed-width flex sibling, so the question area
					must stay flexible instead of using cols="12". A full-width grid column
					would wrap below the sidebar and leave the visible grading area blank.
				-->
				<v-col style="height: 100%; min-width: 0; overflow-y: auto; scroll-padding-bottom: 12px;" class="pa-2 flex-grow-1">
				<!-- Single Question Mode -->
				<div v-if="viewMode === 'single'" class="position-relative d-flex flex-column">
					<v-card v-if="currentQuestion?.config" class="question-content-card w-100 px-2">
						<div class="d-flex justify-space-between align-center px-0">
							<v-card class="group-header-card mb-2 w-100" flat border>
								<v-card-text class="py-2">
									<div class="d-flex justify-space-between align-center">
										<div class="d-flex align-center ga-2">
											<div class="group-icon-wrapper">
												<v-icon color="primary" size="20">mdi-folder-text-outline</v-icon>
											</div>
											<div class="group-info">
												<h3 class="group-title-main">{{ currentGroup.title }}</h3>
												<div class="group-meta">
													<span class="text-caption text-medium-emphasis">{{
														currentGroup.questions.length }} câu hỏi</span>
													<span class="mx-2">•</span>
													<span class="text-caption text-medium-emphasis">
														Tối đa {{currentGroup.questions.reduce((sum, q) => sum +
														q.points, 0)
														}} điểm
													</span>
												</div>
											</div>
										</div>
									</div>
									<p v-if="currentGroup.description" class="group-description mb-0"
										style="text-wrap: auto;">
										{{ currentGroup.description }}
									</p>
									<!-- Nội dung rich text của Phần hiển thị khi chấm; uc-latex-view lọc HTML nguy hiểm trước khi đưa ra màn hình. -->
									<uc-latex-view v-if="currentGroup.content" class="group-content mb-2" :content="currentGroup.content" />
									<!-- Media -->
									<div v-if="currentGroup.media" class="media-container mb-2 d-flex flex-column ga-2">
										<div v-if="currentGroup.media.sourceYT.source?.length > 0"
											class="youtube-container">
											<iframe :src="renderUrlYoutube(currentGroup.media.sourceYT.source)"
												frameborder="0"
												allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
												allowfullscreen></iframe>
										</div>
						<uc-wave-audio-player v-if="getAudioSource(currentGroup.media)?.length > 0"
							:audio-url="getAudioSource(currentGroup.media)" />
										<div v-if="currentGroup.media.sourceFiles.image.length > 0"
											style="max-height: 350px">
											<v-img v-for="file in currentGroup.media.sourceFiles.image"
												:key="file.source"
														:src="getImageUrl(file)"
														:lazy-src="getImageUrl(file, 'w200')"
												class="rounded-lg" max-height="350">
												<template #placeholder>
													<v-row align="center" class="fill-height ma-0" justify="center">
														<v-progress-circular color="grey-lighten-5" indeterminate />
													</v-row>
												</template>
											</v-img>
										</div>
										<div v-if="currentGroup.media.sourceFiles.file.length > 0">
											<iframe v-for="file in currentGroup.media.sourceFiles.file"
														:key="file.externalSource || file.source" :src="getMediaSource(file)"
								class="assignment-media-file-frame"></iframe>
										</div>
									</div>
								</v-card-text>
							</v-card>
						</div>
						<v-divider />
						<div class="d-flex flex-column ga-2 mt-2">
							<div class="d-flex align-center ga-2 justify-end">
								<v-chip variant="text" class="font-weight-medium"
									v-if="questionsTypesLabel(currentQuestion.type)" size="small"
									:color="questionsTypesLabel(currentQuestion.type).color">
									{{ IsEngLish ? questionsTypesLabel(currentQuestion.type).label_EN :
									questionsTypesLabel(currentQuestion.type)?.label }}
								</v-chip>
								<v-chip color="white" text-color="primary" variant="elevated" size="small"
									class="progress-chip status-badge points-chip-mobile">
									{{ currentQuestion.points }} {{ $t('message.points') }}
								</v-chip>
							</div>
							<div class="d-flex ga-2">
								<!-- Question text for desktop -->
								<b class="font-weight-bold" style="flex: none;">{{ $t('message.Question') }} {{
									globalQuestionNumber
									}}:</b>
								<!-- Question text -->
								<uc-latex-view class="flex-column ms-2" style="align-items: flex-start !important;"
									:content="currentQuestion.config.questionText" :escape-html="false" />
							</div>
						</div>
						<!-- YOUTUBE, RECORD_AUDIO, IMAGE, FILE -->
						<!-- Media Container -->
						<div v-if="currentQuestion.config.media" class="media-container mb-2">
							<div v-if="currentQuestion.config.media.sourceYT.source.length > 0"
								class="youtube-container">
								<iframe :src="renderUrlYoutube(currentQuestion.config.media.sourceYT.source)"
									frameborder="0"
									allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
									allowfullscreen></iframe>
							</div>
						<uc-wave-audio-player v-else-if="getAudioSource(currentQuestion.config.media)?.length > 0"
							:audio-url="getAudioSource(currentQuestion.config.media)" />
							<div v-else-if="currentQuestion.config.media.sourceFiles.image.length > 0">
								<v-img v-for="file in currentQuestion.config.media.sourceFiles.image"
															:src="getImageUrl(file)"
															:lazy-src="getImageUrl(file, 'w200')"
									class="rounded-lg" height="400">
									<template v-slot:placeholder>
										<v-row align="center" class="fill-height ma-0" justify="center">
											<v-progress-circular color="grey-lighten-5" indeterminate />
										</v-row>
									</template>
								</v-img>
							</div>
							<div v-else-if="currentQuestion.config.media.sourceFiles.file.length > 0">
														<iframe v-for="file in currentQuestion.config.media.sourceFiles.file" :src="getMediaSource(file)"
					class="assignment-media-file-frame"></iframe>
							</div>
						</div>


						<!-- Grading Component -->
						<div class="answer-area" v-if="!isLoading">
							<component :is="getQuestionComponent(currentQuestion.type)" :question="currentQuestion"
								:answer="studentAnswers[currentQuestion.id] ? studentAnswers[currentQuestion.id].answerData : null"
								@answer-change="updateAnswer(currentQuestion.id, $event)"
								:grading="gradingData[currentQuestion.id] ? gradingData[currentQuestion.id]?.grading : null"
								:is-grade="true" @grading-change="updateGrading(currentQuestion.id, $event)"
								:submissionstatus="submission.SubmissionStatus" />
						</div>

						<!-- Single Mode Action Bar -->
						<v-divider></v-divider>

					</v-card>
					<v-spacer></v-spacer>
					<div
						class="position-sticky bottom-0 d-flex justify-space-between bg-white pa-3 border rounded-lg mb-2">
						<v-btn @click="prevQuestion" :disabled="globalQuestionNumber === 1" variant="text">
							<v-icon start>mdi-chevron-left</v-icon>{{ $t('message.back') }}
						</v-btn>

						<div class="d-flex align-center ga-2" v-if="![0, 1, 4].includes(submission?.SubmissionStatus)">
							<v-chip v-if="autoSaveStatus" size="x-small" :color="autoSaveStatus === 'saving' ? 'grey' : 'success'" variant="tonal">
								<v-icon v-if="autoSaveStatus === 'saving'" start size="12" class="mdi-spin">mdi-loading</v-icon>
								<v-icon v-else start size="12">mdi-check-circle-outline</v-icon>
								<span v-if="autoSaveStatus === 'saving'">{{ IsEngLish ? 'Saving...' : 'Đang lưu...' }}</span>
								<span v-else>{{ IsEngLish ? 'Auto-saved' : 'Đã lưu tự động' }}<span v-if="lastSavedRelative"> — {{ lastSavedRelative }}</span></span>
							</v-chip>
							<v-btn @click="saveGrading(false)" color="grey-darken-1" variant="outlined"
								:loading="isSaving" size="small">
								<v-icon start>mdi-content-save-outline</v-icon>
								{{ IsEngLish ? "Draft Grading" : "Chấm nháp" }}
							</v-btn>
							<v-menu location="top" scroll-strategy="close" open-on-click :close-on-content-click="false"
								offset="4">
								<template v-slot:activator="{ props }">
									<v-btn v-bind="props" color="warning" size="small" variant="elevated"
										:loading="isSaving">
										<v-icon start>mdi-reload-alert</v-icon>
										{{ IsEngLish ? "Request Resubmission" : "Yêu cầu nộp lại bài" }}
									</v-btn>
								</template>
								<v-card>
									<v-card-title class="border-b bg-warning text-body-2">
										{{ IsEngLish ? "Reason for Requesting Resubmission" : "Lý do yêu cầu nộp lại bài" }}</v-card-title>
									<v-card-text class="pa-1">
										<v-textarea label="Lý do" v-model="Reason" :rows="2" variant="outlined"
											hide-details="auto" dense placeholder="Nhập lý do..." />
									</v-card-text>
									<v-card-actions class="border-t py-0">
										<v-spacer></v-spacer>
										<v-btn variant="text" size="small" @click="YeuCauLamLaiBai()" color="warning">{{
											$t('message.confirm') }}</v-btn>
									</v-card-actions>
								</v-card>
							</v-menu>
							<v-btn @click="saveGrading(true)" color="success" size="small" variant="elevated"
								:loading="isSaving">
								<v-icon start>mdi-send-check</v-icon>
								{{ IsEngLish ? "Complete grade and public" : "Hoàn tất & Trả bài" }}
							</v-btn>
						</div>
						<v-btn @click="nextQuestion" :disabled="globalQuestionNumber === totalQuestions" variant="text">
							{{ $t('message.next') }}
							<v-icon end>mdi-chevron-right</v-icon>
						</v-btn>
					</div>
				</div>

				<!-- All Questions Mode -->
				<div v-else class="all-questions-mode">


					<!-- All Questions List -->
					<div class="questions-container">
						<div v-for="(group, groupIndex) in assignment.groups" :key="group.id"
							class="group-section mb-2">
							<!-- Group Header (same as taker but with grading stats) -->
							<v-card class="group-header-card mb-2" flat border>
								<v-card-text class="py-2">
									<div class="d-flex justify-space-between align-center">
										<div class="d-flex align-center ga-2">
											<div class="">
												<v-icon color="primary" size="20">mdi-folder-text-outline</v-icon>
											</div>
											<div class="group-info">
												<h3 class="group-title-main">{{ group.title }}</h3>
												<div class="group-meta">
													<span class="text-caption text-medium-emphasis">{{
														group.questions.length }}
														{{ $t('message.Question') }}</span>
													<span class="mx-2">•</span>
													<span class="text-caption text-medium-emphasis">{{
														$t('message.MaximumScore') }} {{
														group.questions.reduce((sum, q) => sum + q.points, 0)}}
													</span>
												</div>
											</div>
										</div>
										<div class="group-progress-badge">
											<v-chip color="success" variant="tonal" size="small" class=" status-badge">
												{{ getGroupGradedCount(group) }}/{{ group.questions.length }}
											</v-chip>
										</div>
									</div>
									<p v-if="group.description" class="group-description mb-0">
										{{ group.description }}
									</p>
									<!-- Nội dung rich text của Phần hiển thị trong chế độ chấm toàn bộ câu hỏi. -->
									<uc-latex-view v-if="group.content" class="group-content mb-2" :content="group.content" />
									<!-- Media -->
									<div v-if="group.media" class="media-container mt-2 d-flex flex-column ga-2">
										<div v-if="group.media.sourceYT.source?.length > 0" class="youtube-container">
											<iframe :src="renderUrlYoutube(group.media.sourceYT.source)" frameborder="0"
												allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
												allowfullscreen></iframe>
										</div>
						<uc-wave-audio-player v-if="getAudioSource(group.media)?.length > 0"
							:audio-url="getAudioSource(group.media)" />
										<div v-if="group.media.sourceFiles.image.length > 0" style="max-height: 350px">
											<v-img v-for="file in group.media.sourceFiles.image" :key="file.externalSource || file.source"
												:src="getImageUrl(file)"
												:lazy-src="getImageUrl(file, 'w200')"
												class="rounded-lg" max-height="350">
												<template #placeholder>
													<v-row align="center" class="fill-height ma-0" justify="center">
														<v-progress-circular color="grey-lighten-5" indeterminate />
													</v-row>
												</template>
											</v-img>
										</div>
										<div v-else-if="group.media.sourceFiles.file.length > 0">
											<iframe v-for="file in group.media.sourceFiles.file" :key="file.externalSource || file.source"
								:src="getMediaSource(file)" class="assignment-media-file-frame"></iframe>
										</div>
									</div>
								</v-card-text>
							</v-card>

							<!-- Questions in Group -->
							<div class="questions-in-group">
								<v-card v-for="(question, questionIndexInGroup) in group.questions" :key="question.id"
									class="question-card-all mb-2"
									:class="{ 'question-graded': isQuestionGraded(question.id) }" flat border
									:id="question.id">
									<!-- Question header (responsive) -->
									<div class="question-header-all-compact">
										<div class="d-flex flex-column ga-2 d-lg-flex d-none">
											<!-- Desktop layout -->
											<div class="d-flex justify-space-between">
												<b style="flex-shrink: 0;display: inline-block;">
													<v-icon class="mb-1" :color="getGradingIconColor(question.id)"
														size="18">
														{{ getGradingStatusIcon(question.id) }}
													</v-icon>
													{{ $t('message.Question') }} {{
													getGlobalQuestionNumberByQuestionId(question.id) }}:
												</b>
												<div class="d-flex align-center ga-2 justify-end">
													<v-chip variant="text" class="font-weight-medium"
														v-if="questionsTypesLabel(question.type)" size="small"
														:color="questionsTypesLabel(question.type).color">
														{{ IsEngLish ? questionsTypesLabel(question.type)?.label_EN :
														questionsTypesLabel(question.type)?.label }}
													</v-chip>
													<v-chip color="white" text-color="primary" variant="elevated"
														size="small"
														class="progress-chip status-badge points-chip-mobile">
														{{ question.points }} {{ $t('message.points') }}
													</v-chip>
												</div>
											</div>

											<uc-latex-view class="flex-column px-2"
												style="align-items: start !important;"
												:content="question.config.questionText" :escape-html="false" />
										</div>

										<!-- Mobile layout -->
										<!-- <div class="d-flex d-lg-none">
											<div class="question-meta-mobile">
												<div class="d-flex align-center ga-2">
													<v-icon :color="getGradingIconColor(question.id)" size="18">
														{{ getGradingStatusIcon(question.id, question) }}
													</v-icon>
													<span class="mobile-question-label">
														Câu {{getGlobalQuestionNumber(groupIndex,questionIndexInGroup)}}</span>
												</div>
												<v-chip color="white" text-color="primary" variant="elevated"
													size="x-small" class="points-chip-mobile">
													{{ question.points }}đ
												</v-chip>
											</div>
										</div> -->
									</div>

									<v-card-text class="question-content-compact pt-2 pb-2">
										<!-- Question text for mobile -->
										<!-- <div class="d-block d-lg-none mb-2">
											<uc-latex-view class="flex-column"
												:content="question.config.questionText"></uc-latex-view>
										</div> -->

										<!-- YOUTUBE, RECORD_AUDIO, IMAGE, FILE -->
										<!-- Media Container -->
										<div v-if="question.config.media" class="media-container mb-2">
											<div v-if="question.config.media.sourceYT.source.length > 0">
												<div class="youtube-container"
													v-if="question.config.media.sourceYT.source.length > 0">
													<iframe
														:src="renderUrlYoutube(question.config.media.sourceYT.source)"
														frameborder="0"
														allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
														allowfullscreen></iframe>
												</div>
												<v-container class="fill-height d-flex align-center justify-center py-8"
													v-else>
													<v-card class="pa-2 text-center mx-auto" max-width="720"
														elevation="2" rounded="sm">
														<div class="mb-2 d-flex justify-center">
															<v-avatar size="84" class="elevation-1"
																color="surface-variant">
																<v-icon size="48">mdi-link-off</v-icon>
															</v-avatar>
														</div>
														<h2 class="text-h4 mb-2">
															{{ $t('message.PathNotFound') }}
														</h2>
													</v-card>
												</v-container>
											</div>
							<div v-else-if="getAudioSource(question.config.media)?.length > 0">
								<uc-wave-audio-player
									v-if="getAudioSource(question.config.media)?.length > 0"
									:audio-url="getAudioSource(question.config.media)" />
												<v-container class="fill-height d-flex align-center justify-center py-8"
													v-else>
													<v-card class="pa-2 text-center mx-auto" max-width="720"
														elevation="2" rounded="sm">
														<div class="mb-2 d-flex justify-center">
															<v-avatar size="84" class="elevation-1"
																color="surface-variant">
																<v-icon size="48">mdi-link-off</v-icon>
															</v-avatar>
														</div>
														<h2 class="text-h4 mb-2">
															{{ $t('message.PathNotFound') }}
														</h2>
													</v-card>
												</v-container>
											</div>

											<div v-else-if="question.config.media.sourceFiles.image.length > 0">
												<v-img v-for="file in question.config.media.sourceFiles.image"
															:src="getImageUrl(file)"
															:lazy-src="getImageUrl(file, 'w200')"
													class="rounded-lg" max-height="400">
													<template v-slot:placeholder>
														<v-row align="center" class="fill-height ma-0" justify="center">
															<v-progress-circular color="grey-lighten-5" indeterminate />
														</v-row>
													</template>
												</v-img>
											</div>
											<div v-else-if="question.config.media.sourceFiles.file?.length > 0">
												<iframe v-for="file in question.config.media.sourceFiles.file"
											:src="getMediaSource(file)" class="assignment-media-file-frame"></iframe>
											</div>
										</div>

										<!-- Grading component -->
										<div class="answer-section-compact" v-if="!isLoading">
											<component :is="getQuestionComponent(question.type)" :question="question"
												:answer="studentAnswers[question.id] ? studentAnswers[question.id].answerData : null"
												@answer-change="updateAnswer(question.id, $event)"
												:grading="gradingData[question.id] ? gradingData[question.id].grading : null"
												:is-grade="true" @grading-change="updateGrading(question.id, $event)"
												:submissionstatus="submission.SubmissionStatus" />
										</div>
									</v-card-text>
								</v-card>
							</div>
						</div>
					</div>

					<!-- Progress Summary -->
					<v-card class="mb-2 progress-summary border" flat border>
						<v-card-text class="py-2">
							<div class="d-flex justify-space-between align-center flex-wrap ga-2">
								<div class="d-flex align-center ga-2 flex-wrap">
									<div class="progress-stats">
										<span class="text-subtitle-2 text-medium-emphasis">{{
											$t('message.GradingProgress') }}:</span>
										<span class="text-h6 ml-1">{{ gradedCount }}/{{ totalQuestions }}</span>
									</div>
									<v-progress-linear :model-value="(gradedCount / totalQuestions) * 100"
										color="success" height="6" rounded
										class="progress-bar-inline"></v-progress-linear>
									<span class="text-caption text-medium-emphasis">
										{{ Math.round((gradedCount / totalQuestions) * 100) }}%
									</span>
								</div>

								<div class="d-flex flex-wrap align-center ga-2"
									v-if="![0, 1, 4].includes(submission?.SubmissionStatus)">
									<v-btn @click="saveGrading(false)" color="grey-darken-1" variant="outlined"
										size="small" :loading="isSaving">
										<v-icon start size="16">mdi-content-save-outline</v-icon>
										{{ IsEngLish ? "Draft Grading" : "Chấm nháp" }}
									</v-btn>
									<v-btn @click="handleOpenModalRequireResend" color="warning" size="small"
										variant="elevated" :loading="isSaving">
										<v-icon start>mdi-reload-alert</v-icon>
										{{ IsEngLish ? "Request Resubmission" : "Yêu cầu nộp lại bài" }}
									</v-btn>
									<!-- <v-menu location="bottom" scroll-strategy="close" open-on-click
										:close-on-content-click="false" offset="4">
										<template v-slot:activator="{ props }">
											<v-btn v-bind="props" color="warning" size="small" variant="elevated"
												:loading="isSaving">
												<v-icon start>mdi-reload-alert</v-icon>
												{{ IsEngLish ? "Request Resubmission" : "Yêu cầu nộp lại bài" }}
											</v-btn>
										</template>
										
									</v-menu> -->
									<v-btn @click="saveGrading(true)" color="success" size="small" variant="elevated"
										:loading="isSaving">
										<v-icon start size="16">mdi-send-check</v-icon>
										{{ IsEngLish ? "Complete grade and public" : "Hoàn tất & Trả bài" }}
									</v-btn>

								</div>
							</div>
						</v-card-text>
					</v-card>
				</div>
			</v-col>
			<!-- <v-divider vertical /> -->
			<!-- <v-col cols="3" v-if="!mobile"> -->
			<!-- View Mode Toggle (same as taker) -->
			<!-- <div class="text-subtitle-1 font-weight-medium">
					<v-icon left color="primary">mdi-clipboard-check-outline</v-icon>
					{{ $t('message.SummaryAndGeneralComments') }}
				</div>
				<v-divider class="my-2" /> -->
			<!-- Overall Grading Summary -->
			<!-- <v-card class="mb-2">
					<v-card-text class="pa-0">
						<v-row dense>
							<v-col cols="12">
								<v-btn-toggle v-model="viewMode" color="primary" variant="outlined" density="compact"
									divided mandatory size="small">
									<v-btn value="single" size="small">
										<v-icon size="16">mdi-numeric-1-box</v-icon>
										<span class="ml-1 d-none d-sm-inline">
											{{ IsEngLish ? 'Single' : 'Từng câu' }}
										</span>
									</v-btn>
									<v-btn value="all" size="small">
										<v-icon size="16">mdi-view-list</v-icon>
										<span class="ml-1 d-none d-sm-inline">{{ IsEngLish ? 'All' : 'Tất cả' }}</span>
									</v-btn>
								</v-btn-toggle>
							</v-col>
							<v-col cols="12">
								<label class="font-weight-medium mb-2 d-block">{{ $t('message.FinalScore') }}</label>
								<div class="d-flex align-center">
									<v-number-input v-model="gradingSummary.totalScore" label="Điểm"
										:max="attemptMaxScore" :min="0" variant="outlined" density="compact"
										hide-details style="max-width: 100px;" control-variant="stacked" inset>
									</v-number-input>
										<span class="text-h6 ml-2 text-primary"> / {{ attemptMaxScore }}</span>
									<span class="ml-1 text-caption">{{ $t('message.points') }}</span>
								</div>
							</v-col>
							<v-col cols="12">
								<label class="font-weight-medium mb-2 d-block">{{ $t('message.OverallComment')
								}}</label>
								<v-textarea v-model="gradingSummary.teacherComment" hide-details
									:placeholder="$t('message.EnterGeneralFeedback')" />
							</v-col>
						</v-row>
					</v-card-text>
				</v-card> -->

			<!-- </v-col> -->
			</template>
		</v-row>
		<v-dialog v-model="IsOpenModal_Require_Resend" max-width="600px">
			<v-card>
				<v-card-title class="d-flex  border-b bg-primary text-body-2 py-0">
					<span class="text-white">
						{{
						IsEngLish ? "Reason for Requesting Resubmission" : "Lí do yêu cầu nộp lại bài"
						}}
					</span>
					<v-spacer></v-spacer>
					<v-btn class="text-white" icon="mdi-close" variant="text" size="small"
						@click="handleCloseModalRequireResend"></v-btn>
				</v-card-title>
				<v-card-text class="pa-1 py-2">
					<v-textarea label="Lí do" v-model="Reason" :rows="2" variant="outlined" hide-details="auto" dense
						placeholder="Nhập lí do..." density="compact" />
				</v-card-text>
				<v-card-actions class="border-t py-0">
					<v-spacer></v-spacer>
					<v-btn variant="outlined" size="small" @click="YeuCauLamLaiBai()" color="primary"
						prepend-icon="mdi-content-save-outline">{{
						$t('message.confirm') }}</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-assignment-grader',
		props: {
			submissionData: Array,
			onSaveGradingDraft: { type: Function, default: () => { } },
			onPublishGrades: { type: Function, default: () => { } },
			onOpenPublishDialog: { type: Function, default: () => { } },
			onInitPage: { type: Function, default: () => { } },
			onAutoSaveDraft: { type: Function, default: () => { } },
		},
		data() {
			this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
			const { mobile } = Vuetify.useDisplay()
			return {
				Reason: "",
				viewMode: 'all', // 'single' or 'all'
				// Drawer điều hướng trên desktop được bind bằng v-model nên phải có state reactive ngay từ đầu.
				navDrawerOpen: true,
				navCollapsed: false,
				groupCollapsed: {},
				currentGroupIndex: 0,
				currentQuestionIndexInGroup: 0,
				assignment: null,
				submission: null,
				studentAnswers: {},
				gradingData: {},
				gradingSummary: { totalScore: null, teacherComment: '' },
				isSaving: false,
				isLoading: false,
				vueData,
				mobile,
				IsOpenModal_Require_Resend: false,
				autoSaveStatus: null,
				lastSavedRelative: '',
				_autoSaveTimer: null,

			}
		},
		mounted() {
			if (this.mobile) this.viewMode = 'all'
		},
		beforeUnmount() {},

		computed: {
			attemptMaxScore() {
				return Number(this.assignment?.AttemptMaxScore ?? this.assignment?.MaxScore ?? 0);
			},
			totalQuestions(){
				if (!this.assignment?.groups) return 0;
				return this.assignment.groups.reduce((total, group) => total + group.questions.length, 0);
			},
			currentGroup() { return this.assignment?.groups?.[this.currentGroupIndex]; },
			currentQuestion() { return this.currentGroup?.questions?.[this.currentQuestionIndexInGroup]; },
			globalQuestionNumber() {
				if (!this.assignment?.groups) return 1;
				return this.getGlobalQuestionNumber(this.currentGroupIndex, this.currentQuestionIndexInGroup);
			},
			allQuestions() {
				return this.assignment?.groups?.flatMap(group => group.questions) || [];
			},
			gradedCount() {
				return this.allQuestions.filter(q => this.isQuestionGraded(q.id)).length;
			},
			IsEngLish: function () {
				return this.$i18n.locale == 'en'
			}
		},
		methods: {
			// AssignmentConfig mới dùng groups; một số bài cũ vẫn để questions ở root.
			// Chuẩn hóa cả hai shape để trang chấm không bị rỗng câu khi mở bài cũ.
			getConfigGroups(config) {
				if (!config || typeof config !== 'object') return [];
				const groups = Array.isArray(config.groups) ? [...config.groups] : [];
				if (Array.isArray(config.questions) && config.questions.length) {
					groups.push({ id: '__root_questions__', title: '', questions: config.questions });
				}
				return groups;
			},
			async processData(data) {
				this.isLoading = true
				let promise = await new Promise((resolve, reject) => {
					if (!data || !data[0] || !data[1]) return;
					const assignmentConfig = data[0][0];
					let parsedConfig = {};
					if (assignmentConfig && (typeof assignmentConfig.AssignmentConfig === 'string' || typeof
						assignmentConfig.AssignmentConfig === 'object')) {
						parsedConfig = typeof assignmentConfig.AssignmentConfig === 'string' ? JSON.parse(assignmentConfig.AssignmentConfig) : assignmentConfig.AssignmentConfig;
					assignmentConfig.groups = this.getConfigGroups(parsedConfig);
						assignmentConfig.AssignmentType = parsedConfig?.type || 'LMS';
						assignmentConfig.ExternalLink = parsedConfig?.link || '';
					}
					this.assignment = assignmentConfig;
					const submissionData = data[1][0];
					console.log('submissionData', submissionData)
					console.log('assignmentConfig', assignmentConfig)
					// AssignmentConfig ở bảng 1 chứa đáp án đúng của toàn bộ pool để chấm.
					// SubmissionAssignmentConfig ở bảng 2 là snapshot không đáp án của attempt,
					// nên dùng snapshot để lọc và giữ đúng thứ tự các câu học sinh đã nhận.
					if (submissionData?.SubmissionAssignmentConfig) {
						try {
							const snapshot = typeof submissionData.SubmissionAssignmentConfig === 'string'
								? JSON.parse(submissionData.SubmissionAssignmentConfig)
								: submissionData.SubmissionAssignmentConfig;
							const fullQuestions = new Map(
								this.getConfigGroups(parsedConfig).flatMap(group =>
									(group.questions || [])
										.filter(question => question?.id !== undefined && question?.id !== null)
																	.map(question => [String(question.id), question])
															)
													);
											const snapshotGroups = this.getConfigGroups(snapshot);
											// Chuỗi "null" hoặc snapshot rỗng của dữ liệu cũ không được
											// làm mất config gốc đang dùng để chấm.
											if (snapshotGroups.some(group => Array.isArray(group.questions) && group.questions.length)) {
												assignmentConfig.groups = snapshotGroups.map(snapshotGroup => ({
													...snapshotGroup,
													questions: (snapshotGroup.questions || [])
														.map(question => fullQuestions.get(String(question?.id)) || question)
												}));
											}
						} catch (error) {
							console.error('Không parse được snapshot AssignmentConfig của submission:', error);
						}
					}
					this.submission = submissionData;
					console.log('this.submission', this.submission)
					if (submissionData && submissionData?.SubmissionContent) {
						const content = JSON.parse(submissionData.SubmissionContent);
						const rawAnswers = content.answers || {};
						const allQuestions = this.assignment?.groups?.flatMap(group => group.questions) || [];
	
						// Duyệt qua từng câu trả lời để chuẩn hóa
						for (const questionId in rawAnswers) {
							const questionConfig = allQuestions.find(q => q.id === questionId);
							const answerObject = rawAnswers[questionId];
	
							if (questionConfig && answerObject && answerObject.answerData) {
								const type = questionConfig.type;
								const isArrayType = ['FILE_UPLOAD', 'AUDIO_RESPONSE'];
	
								// Nếu là loại câu hỏi yêu cầu mảng nhưng answerData không phải mảng,
								// hãy bọc nó trong một mảng.
								if (isArrayType.includes(type) && !Array.isArray(answerObject.answerData)) {
									answerObject.answerData = [answerObject.answerData];
								}
							}
						}
	
						this.studentAnswers = JSON.parse(JSON.stringify(content.answers || {}));
						this.gradingData = JSON.parse(JSON.stringify(content.answers || {}));
					}
					this.gradingSummary.totalScore = submissionData?.Score || 0;
					console.log('submissionData?.Score', submissionData?.Score)
					this.gradingSummary.teacherComment = submissionData?.TeacherComment || '';
					if (this.assignment?.groups) {
						const initialCollapsed = {};
						this.assignment.groups.forEach((group, index) => { initialCollapsed[index] = false });
						this.groupCollapsed = initialCollapsed;
					}
					resolve()
				})
				this.isLoading = false
			},
	

		isQuestionGraded(questionId) {
			const grading = this.gradingData[questionId]?.grading;
			if (!grading) return false;
			const question = this.getQuestionById(questionId);
			// Câu điền đáp án có thể được giáo viên chấm lại; khi đó manualScore có
			// source teacher_regrade và phải được tính là điểm hợp lệ của câu.
			if (question?.type === 'QUIZ_FILL_IN_BLANK') {
				return this.getEffectiveQuestionScore(questionId) !== null;
			}
			return (grading.manualScore !== null && grading.manualScore !== undefined)
				|| (grading.autoScore !== null && grading.autoScore !== undefined);
		},
		getEffectiveQuestionScore(questionId) {
			const question = this.getQuestionById(questionId);
			const grading = this.gradingData[questionId]?.grading;
			if (!grading) return null;
			if (question?.type === 'QUIZ_FILL_IN_BLANK') {
				// Chỉ điểm được giáo viên xác nhận bằng nút Chấm lại mới ghi đè autoScore;
				// manualScore cũ từ các phiên bản trước không được xem là override.
				if (grading.manualScoreSource === 'teacher_regrade'
					&& grading.manualScore !== null && grading.manualScore !== undefined) {
					return Number(grading.manualScore);
				}
				if (grading.autoScore !== null && grading.autoScore !== undefined) return Number(grading.autoScore);
				return null;
			}
			if (grading.manualScore !== null && grading.manualScore !== undefined) return Number(grading.manualScore);
			if (grading.autoScore !== null && grading.autoScore !== undefined) return Number(grading.autoScore);
			return null;
		},
	
			getGroupGradedCount(group) {
				return group.questions.filter(q => this.isQuestionGraded(q.id)).length;
			},
			//Hiện tại đang sử dụng cho File Upload
			updateAnswer(questionId, newAnswer) {
				this.gradingData[questionId] = {
					...this.gradingData[questionId],
					answerData: newAnswer
				}
				// Sync studentAnswers so :answer prop (used by chip display) reflects FileAnnotation updates
				if (this.studentAnswers[questionId]) {
					this.studentAnswers[questionId] = {
						...this.studentAnswers[questionId],
						answerData: newAnswer
					}
				}
				this.triggerAutoSave()
			},
			triggerAutoSave() {
				if (!this.submission?.SubmissionID) return
				clearTimeout(this._autoSaveTimer)
				this.autoSaveStatus = 'saving'
				this._autoSaveTimer = setTimeout(async () => {
					const payload = {
						SubmissionID: this.submission.SubmissionID,
						Score: this.gradingSummary.totalScore,
						TeacherComment: this.gradingSummary.teacherComment,
						SubmissionContent: JSON.stringify({ answers: this.gradingData })
					}
					try {
						await this.onAutoSaveDraft(payload)
						this.autoSaveStatus = 'saved'
						this.lastSavedRelative = new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
					} catch (e) {
						this.autoSaveStatus = null
					}
				}, 800)
			},
			async saveGrading(isPublishing) {
				const $this = this
				const isIntegrated = this.assignment?.AssignmentType === 'INTEGRATED'
				let listQuestions = isIntegrated ? [] : _.flatten(this.assignment.groups.map(q => { return [...q.questions] }))
				this.isSaving = true;
				const payload = {
					SubmissionID: this.submission.SubmissionID,
					Score: this.gradingSummary.totalScore,
					TeacherComment: this.gradingSummary.teacherComment,
					SubmissionContent: JSON.stringify({ answers: this.gradingData })
				};
				if (isPublishing) {
					let messageQuestionsNotGrade = isIntegrated ? '' : this.onHandleQuestionNotGrade(listQuestions)
					confirm({
						title: messageQuestionsNotGrade.length > 0 ? (`${this.IsEngLish ? 'There are still ungraded questions. Do you want to confirm and return the assignment?' : "Còn các câu hỏi chưa được chấm. Thầy/Cô xác nhận hoàn tất và trả bài?"}`) : (`${this.IsEngLish ? 'Confirm grading completion and return the assignment to the student?' : "Xác nhận hoàn tất chấm bài và trả bài cho học sinh?"}`),
						message: messageQuestionsNotGrade.length > 0 ? (`${this.IsEngLish ? "List of Ungraded Questions" : "Danh sách câu chưa chấm"}: ` + messageQuestionsNotGrade) : "",
						action: () => {
							this.onPublishGrades(payload);
						}
					})
				} else {
					this.onSaveGradingDraft(payload);
				}
				setTimeout(() => { this.isSaving = false; }, 200);
			},
			async saveGradingTEST(isPublishing) {
				let listQuestions = _.flatten(this.assignment.groups.map(q => { return [...q.questions] }))
				this.isSaving = true;
				await this.calculateTotalScore();
				console.log('saveGradingTEST', this.gradingSummary)
				const payload = {
					SubmissionID: this.submission.SubmissionID,
					Score: this.gradingSummary.totalScore,
					TeacherComment: this.gradingSummary.teacherComment,
					SubmissionContent: JSON.stringify({ answers: this.gradingData })
				};
				setTimeout(() => { this.isSaving = false; }, 200);
			},
			updateGrading(questionId, newGradingData) {
				const isQuestionRegraded = newGradingData?.manualScoreSource === 'teacher_regrade'
					&& Array.isArray(newGradingData?.regradeHistory);
				const newGrading = { ...this.gradingData };
				const currentAnswer = newGrading[questionId] || {};
				newGrading[questionId] = { ...currentAnswer, grading: newGradingData };
				this.gradingData = newGrading;
				// Regrade status 4 cũng phải tính lại tổng điểm trước khi auto-save;
				// nếu chỉ giới hạn <= 3 thì điểm câu đã chấm lại không đi vào Score.
				if (isQuestionRegraded || Number(this.submission?.SubmissionStatus) <= 3) {
					setTimeout(() => {
						this.calculateTotalScore();
					}, 0);
				}
				// Chấm lại phải được lưu ngay để lịch sử và lý do không mất khi giáo viên
				// chuyển câu hoặc đóng trang mà chưa bấm Chấm nháp.
				if (isQuestionRegraded) this.triggerAutoSave();
			},
			async calculateTotalScore() {
				if (this.assignment?.AssignmentType === 'INTEGRATED') return;
				let total = 0;
				await this.allQuestions.forEach(q => {
					const score = this.getEffectiveQuestionScore(q.id);
					if (score !== null) total += parseFloat(score || 0);
				});
				this.gradingSummary.totalScore = parseFloat(Math.round(total * 100) / 100);
			},
			getGradingStatusIcon(questionId, question) {
				const grading = this.gradingData[questionId]?.grading;
				if (!grading) return 'mdi-help-circle-outline';
				const currentQuestion = question || this.getQuestionById(questionId);
				// Câu điền đáp án dùng autoScore, trừ khi giáo viên đã chấm lại thủ công.
				if (currentQuestion?.type === 'QUIZ_FILL_IN_BLANK') {
					const score = this.getEffectiveQuestionScore(questionId);
					if (score === null) return 'mdi-help-circle-outline';
					if (score >= Number(currentQuestion.points ?? 0)) return 'mdi-check-circle';
					if (score <= 0) return 'mdi-close-circle';
					return 'mdi-minus-circle';
				}
				if (this.getEffectiveQuestionScore(questionId) === null) return 'mdi-help-circle-outline';
				if (grading.isCorrect === true || grading.manualScore === currentQuestion?.points) return 'mdi-check-circle';
				if (grading.isCorrect === false || grading.manualScore === 0) return 'mdi-close-circle';
				return 'mdi-minus-circle';
			},
			getGradingIconColor(questionId) {
				const grading = this.gradingData[questionId]?.grading;
				if (!grading) return 'grey';
				const question = this.getQuestionById(questionId);
				// Cùng quy tắc với icon: autoScore là nguồn chính, teacher_regrade được ưu tiên.
				if (question?.type === 'QUIZ_FILL_IN_BLANK') {
					const score = this.getEffectiveQuestionScore(questionId);
					if (score === null) return 'grey';
					if (score >= Number(question.points ?? 0)) return 'success';
					if (score <= 0) return 'error';
					return 'warning';
				}
				if (this.getEffectiveQuestionScore(questionId) === null) return 'grey';
				if (grading.isCorrect === true || grading.manualScore === question?.points) return 'success';
				if (grading.isCorrect === false || grading.manualScore === 0) return 'error';
				return 'warning';
			},
			getQuestionById(questionId) { return this.allQuestions.find(q => q.id === questionId); },
			isActiveQuestion(groupIndex, questionIndexInGroup) { return this.currentGroupIndex === groupIndex && this.currentQuestionIndexInGroup === questionIndexInGroup; },
			getQuestionComponent(type) {
				const map = {
					'QUIZ_SINGLE_CHOICE': 'uc-question-single-choice',
					'QUIZ_MULTIPLE_CHOICE': 'uc-question-multiple-choice',
					'QUIZ_TRUE_FALSE': 'uc-question-true-false',
					'QUIZ_FILL_IN_BLANK': 'uc-question-fill-in-blank',
					'QUIZ_MATCHING': 'uc-question-matching',
					'SHORT_ANSWER': 'uc-question-short-answer',
					'ESSAY': 'uc-question-essay',
					'FILE_UPLOAD': 'uc-question-file-upload',
					'AUDIO_RESPONSE': 'uc-question-audio-response',
					'QUIZ_MULTIPLE_TRUE_FALSE': 'uc-question-multiple-true-false'
				};
				return map[type] || 'div';
			},
			getSubmissionStatusColor() {
				if (this.submission?.SubmissionStatus == 0 && this.submission?.Reason) {
					return 'warning';
				}
				switch (this.submission?.SubmissionStatus) {
					case 4:
						return 'success';
					case 2:
						return 'info';
					case 3:
						return 'purple';
					default: return 'grey';
				}
			},
			getSubmissionStatusText() {
				if (this.submission?.SubmissionStatus == 0 && this.submission?.Reason) return this.IsEngLish ? 'RequestResubmission' : 'Yêu cầu nộp lại bài';
				switch (this.submission?.SubmissionStatus) {
					case 4: return this.IsEngLish ? 'Complete Grade & Public' : 'Đã chấm bài và trả bài'; case 2: return this.IsEngLish ? 'Submitted' : 'Đã nộp'; case 3: return this.IsEngLish ? 'Draft Graded' : 'Đã chấm nháp';
	
					default: return this.IsEngLish ? 'Not submitted' : 'Chưa nộp';
				}
			},
			toggleGroupCollapse(groupIndex) { this.groupCollapsed = { ...this.groupCollapsed, [groupIndex]: !this.groupCollapsed[groupIndex] }; },
			navigateToQuestion(groupIndex, questionIndexInGroup, id) {
				if (this.viewMode == 'all') {
					var element = document.getElementById(id);
					element.scrollIntoView({
						behavior: "smooth", // cuộn mượt 
						block: "start",// vị trí hiển thị: start | center | end | nearest 
					});
				}
				this.currentGroupIndex = groupIndex;
				this.currentQuestionIndexInGroup = questionIndexInGroup;
				if (this.groupCollapsed[groupIndex]) { this.toggleGroupCollapse(groupIndex); }
	
			},
			prevQuestion() { if (this.currentQuestionIndexInGroup > 0) { this.currentQuestionIndexInGroup--; } else if (this.currentGroupIndex > 0) { this.currentGroupIndex--; this.currentQuestionIndexInGroup = this.assignment.groups[this.currentGroupIndex].questions.length - 1; } },
			nextQuestion() {
				if (!this.assignment || !this.assignment.groups) return;
				const currentGroup = this.assignment.groups[this.currentGroupIndex];
				if (this.currentQuestionIndexInGroup < currentGroup.questions.length - 1) { this.currentQuestionIndexInGroup++; } else if (this.currentGroupIndex < this.assignment.groups.length - 1) { this.currentGroupIndex++; this.currentQuestionIndexInGroup = 0; }
			},
			getGlobalQuestionNumber(groupIndex, questionIndexInGroup) {
				if (!this.assignment?.groups) return 1;
				let number = 1;
				for (let i = 0; i < groupIndex; i++) { number += this.assignment.groups[i].questions.length; }
				return number + questionIndexInGroup;
			},
			getDriveFileId(url) {
				const match = url?.match(/\/d\/([^/]+)\//);
				return match ? match[1] : null;
			},
			getMediaSource(file) {
				const source = file?.externalSource || file?.source || '';
				if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(source)) {
					return source.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/');
				}
				if (/^https?:\/\//i.test(source) || file?.mediaSource !== 'db') return source;
				const base = vueData?.v_Set?.urlReadFile || '';
				return base ? `${base.replace(/\/+$/, '')}/${source.replace(/^\/+/, '')}` : source;
			},
			getAudioSource(media) {
				const record = media?.sourceRecord;
				return record ? this.getMediaSource(record) : '';
			},
			getImageUrl(file, size = 'w1000') {
				const source = this.getMediaSource(file);
				const fileId = this.getDriveFileId(source);
				return fileId ? `https://drive.google.com/thumbnail?id=${file.externalId || fileId}&sz=${size}` : source;
			},
			formatDate(dateString) { if (!dateString) return ''; const date = new Date(dateString); return date.toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }); },
			onHandleQuestionNotGrade(listQuestions) {
				// Câu điền đáp án hoàn tất khi đã có autoScore; các dạng khác vẫn nhận manualScore hoặc autoScore.
				let listQuestionsNotGrade = _.keys(_.pickBy(this.gradingData, (value, questionId) => {
					const question = listQuestions.find(q => q.id === questionId);
					const grading = value?.grading || {};
					if (question?.type === 'QUIZ_FILL_IN_BLANK') return grading.autoScore == null;
					return grading.manualScore == null && grading.autoScore == null;
				}))
				//Xử lấy show các câu hỏi chưa chấm
				let getNumberQuestionNotGrade = _.reduce(listQuestions, (result, q, index) => {
					if (listQuestionsNotGrade.includes(q.id)) result.push(`${this.IsEngLish ? 'Question' : 'Câu'}: ` + (index + 1))
					return result
				}, [])
				return getNumberQuestionNotGrade.length > 0 ? getNumberQuestionNotGrade.join(', ') : ''
			},
			getGlobalQuestionNumberByQuestionId(questionId) {
				if (!this.allQuestions) return 0;
				const index = this.allQuestions.findIndex(q => q.id === questionId);
				return index + 1;
			},
			questionsTypesLabel,
			renderUrlYoutube,
			YeuCauLamLaiBai() {
				const $this = this
				if (!$this.Reason) {
					Vue.$toast.warning(`${this.IsEngLish ? 'Please enter the reason' : 'Vui lòng nhập lý do!'} `, { position: "top" })
					return
				}
				confirm({
					title: `${this.IsEngLish ? 'Confirm requesting the student to resubmit the assignment?' : 'Xác nhận yêu cầu học sinh nộp lại bài tập?'} `,
					action: () => {
						ajaxCALL("/lms/EL_Teacher_YeuCauNopBaiLai", {
							SubmissionID: $this.submission?.SubmissionID,
							Reason: $this.Reason
						}, res => {
							Vue.$toast.success(`${this.IsEngLish ? 'Successfully requested the student to resubmit the assignment!' : 'Yêu cầu học sinh nộp lại bài tập thành công!'} `, { position: "top" })
							$this.onInitPage()
						})
					}
				})
	
			},
			handleOpenModalRequireResend() {
				this.IsOpenModal_Require_Resend = true
			},
			handleCloseModalRequireResend() {
				this.IsOpenModal_Require_Resend = false
			}
		},
		watch: {
			submissionData: {
				handler: 'processData',
				immediate: true,
			},
			mobile: function (val) {
				if (val) this.viewMode = 'all'
				else this.viewMode = 'single'
			},
			gradingSummary: {
				handler() {
					if (this.assignment?.AssignmentType === 'INTEGRATED') {
						this.triggerAutoSave()
					}
				},
				deep: true
			}
		}
	}
</script>