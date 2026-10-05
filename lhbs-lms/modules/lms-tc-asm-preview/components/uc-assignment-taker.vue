<template>
	<div v-if="!assignment" class="text-center pa-10">
		<v-progress-circular indeterminate size="64"></v-progress-circular>
		<p class="mt-4">Đang tải đề bài...</p>
	</div>

	<div v-else>
		<!-- COMPACT HEADER -->
		<v-card class="mb-3" flat border>
			<v-card-text class="py-2">
				<div class="d-flex align-center flex-wrap ga-2">
					<div class="d-flex align-center ga-2">
						<v-icon color="primary">mdi-book-open-variant</v-icon>
						<span class="font-weight-medium text-truncate" style="max-width: 38ch;">
							{{ assignment.Title }}
						</span>
					</div>

					<v-divider vertical class="mx-2 d-none d-md-block"></v-divider>
					<v-chip :color="displayStatusColor(submissionstatus)">{{ displayStatus(submissionstatus) }}</v-chip>
					<v-spacer />
					<div v-if="submissionstatus != 4" class="d-flex ga-2">
						<v-btn size="small" class="text-white" @click="handleClickAction()"
							:color="submissionstatus < 2 ? 'success' : 'orange'">
							<v-icon start v-if="submissionstatus == 4">mdi-send-check</v-icon>
							{{ submissionstatus < 2 ? 'Nộp bài' : 'Hoàn tất & Trả bài' }} </v-btn>
					</div>
					<!-- Hạn nộp + trạng thái -->
					<v-chip size="x-small" :color="dueDateStatus.color" :variant="dueDateStatus.variant" class="mr-1">
						<v-icon start size="14" :icon="dueDateStatus.icon"></v-icon>
						{{ dueDateStatus.text }}
					</v-chip>
					<span class="text-caption text-medium-emphasis">{{ formatDate(assignment.DueDate) }}</span>

					<!-- Hướng dẫn gọn -->
					<v-tooltip text="Hướng dẫn">
						<template #activator="{ props }">
							<v-btn v-bind="props" icon="mdi-information-outline" variant="text" density="comfortable"
								@click="showInstructions = !showInstructions" />
						</template>
					</v-tooltip>
				</div>

				<v-expand-transition>
					<v-alert v-if="showInstructions && assignment.Instructions && assignment.Instructions !== assignment.ExternalLink" class="mt-2" density="comfortable"
						variant="tonal" type="info">
						{{ assignment.Instructions }}
					</v-alert>
				</v-expand-transition>
			</v-card-text>
		</v-card>

		<v-row dense>
			<v-col cols="12" v-if="isIntegrated">
				<v-card flat border height="calc(100vh - 120px)">
					<iframe :src="assignment.ExternalLink || assignment.Instructions" width="100%" height="100%"
						frameborder="0"></iframe>
				</v-card>
			</v-col>
			<!-- NAV -->
			<v-col cols="12" sm="12" md="4" v-if="!isMobile && !isIntegrated"
				style="border-inline-end: 0.5px dashed #a7a2a2;">
				<v-card class="question-nav" sticky top="80px" flat>
					<div class="d-flex justify-end mb-2 " v-if="isTablet">
						<v-btn-toggle v-model="viewMode" color="primary" variant="outlined" density="compact" divided
							mandatory size="x-small">
							<v-btn value="single" size="x-small">
								<v-icon size="16">mdi-numeric-1-box</v-icon>
								<span class="ml-1 d-none d-sm-inline">Từng câu</span>
							</v-btn>
							<v-btn value="all" size="x-small">
								<v-icon size="16">mdi-view-list</v-icon>
								<span class="ml-1 d-none d-sm-inline">Tất cả</span>
							</v-btn>
						</v-btn-toggle>
					</div>

					<v-card-title class="d-flex justify-space-between align-center header-respondsive-fs py-2">
						Cấu trúc bài tập
						<div class="d-flex ga-2 align-center">
							<div class="d-flex justify-end" v-if="!isTablet">
								<v-btn-toggle v-model="viewMode" color="primary" variant="outlined" density="compact"
									divided mandatory size="x-small">
									<v-btn value="single" size="x-small">
										<v-icon size="16">mdi-numeric-1-box</v-icon>
										<span class="ml-1 d-none d-sm-inline">Từng câu</span>
									</v-btn>
									<v-btn value="all" size="x-small">
										<v-icon size="16">mdi-view-list</v-icon>
										<span class="ml-1 d-none d-sm-inline">Tất cả</span>
									</v-btn>
								</v-btn-toggle>
							</div>
							<v-btn icon size="small" @click="navCollapsed = !navCollapsed">
								<v-icon>{{ navCollapsed ? 'mdi-chevron-down' : 'mdi-chevron-up' }}</v-icon>
							</v-btn>
						</div>
					</v-card-title>

					<v-divider></v-divider>

					<v-expand-transition>
						<div v-show="!navCollapsed" class="pa-2 pb-0"
							style="max-height: calc(100vh - 127px);overflow: auto;">
							<div v-for="(group, groupIndex) in assignment.groups" :key="group.id" class="mb-2">
								<v-list-item @click="toggleGroupCollapse(groupIndex)"
									class="group-header-item px-2 py-1" density="compact">
									<template #prepend>
										<v-icon size="20" class="group-toggle-icon">
											{{ groupCollapsed[groupIndex] ? 'mdi-chevron-right' : 'mdi-chevron-down' }}
										</v-icon>
									</template>
									<v-list-item-title class="group-title body-respondsive-fs">{{ group.title }}
									</v-list-item-title>
									<template #append>
										<v-chip size="x-small" color="primary" variant="outlined">
											{{ group.questions.length }} câu
										</v-chip>
									</template>
								</v-list-item>

								<v-expand-transition>
									<div v-show="!groupCollapsed[groupIndex]" class="ml-2 mt-2">
										<div class="question-grid d-flex flex-wrap ga-2">
											<v-btn v-for="(q, questionIndexInGroup) in group.questions" :key="q.id"
												@click="navigateToQuestion(groupIndex, questionIndexInGroup, q.id)"
												:color="getIconColor(q.id)"
												:variant="isActiveQuestion(groupIndex, questionIndexInGroup) ? 'elevated' : 'tonal'"
												class="question-btn" :size="isMobile ? 'x-small' : 'small'">
												<v-icon size="16">{{ getQuestionStatusIcon(q.id) }}</v-icon>
												{{ getGlobalQuestionNumber(groupIndex, questionIndexInGroup) }}
											</v-btn>
										</div>
									</div>
								</v-expand-transition>
							</div>
						</div>
					</v-expand-transition>
				</v-card>
			</v-col>

			<!-- CONTENT -->
			<v-col cols="12" md="8" class="pe-0" v-if="!isIntegrated">
				<div v-if="viewMode === 'single'">
					<!-- COMPACT PROGRESS (sticky nhỏ gọn cho chế độ single cũng được, nhưng giữ nguyên logic lưu) -->
					<v-card v-if="currentQuestion?.config" class="question-content-card ">
						<v-card class="group-header-card w-100" flat border>
							<v-card-text>
								<div class="d-flex justify-space-between align-center">
									<div class="d-flex align-center ga-3">
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
													Tối đa {{
														lodash.round(
															currentGroup.questions.reduce((sum, q) => sum + q.points, 0)
														, 2)
													}} điểm
												</span>
											</div>
										</div>
									</div>

								</div>
								<p v-if="currentGroup.description" class="group-description mb-2"
									style="text-wrap: auto;">
									{{ currentGroup.description }}
								</p>
								<!-- Nội dung do uc-rich-text-editor tạo ra; uc-latex-view giữ định dạng và lọc HTML nguy hiểm khi học sinh làm bài. -->
								<uc-latex-view v-if="currentGroup.content" class="group-content mb-2" :content="currentGroup.content" />
								<!-- Media -->
								<div v-if="currentGroup.media" class="media-container mb-2">
									<!-- Player Video tương tác: Dừng video tại các mốc câu hỏi để học sinh trả lời -->
									<!-- Player Video tương tác: Dừng video tại các mốc câu hỏi để học sinh trả lời -->
									<div v-if="isGroupInteractiveVideo(currentGroup)" class="interactive-video-player-container mb-3">
										<div class="interactive-player-wrapper" style="position: relative; width: 100%; aspect-ratio: 16/9; background: #000; border-radius: 8px; overflow: hidden;">
											<div :id="interactivePlayerId" style="width: 100%; height: 100%;"></div>
											<!-- Lớp overlay trong suốt chỉ xuất hiện khi video đang phát: ngăn hiện controls/thanh time YouTube, click vào để tạm dừng -->
											<div v-if="interactiveVideoPlaying" class="player-overlay" @click="toggleInteractiveVideoPlay"></div>
										</div>

										<!-- Thanh tua Timeline ngoài chuẩn hoc-lieu-view với các chấm mốc câu hỏi -->
										<div class="position-relative w-100 d-flex align-center mt-2 px-1" style="height: 24px;">
											<v-slider v-model="interactiveVideoCurrentTime" :max="interactiveVideoDuration || 100" min="0" step="1"
												hide-details density="compact" color="deep-purple-accent-4" track-color="grey-lighten-2"
												:track-size="4" :thumb-size="12"
												@update:model-value="seekInteractiveVideo"
												class="w-100">
											</v-slider>

											<!-- Các chấm marker câu hỏi tương tác đặt trên thanh timeline slider -->
											<div v-for="q in getGroupInteractiveQuestions(currentGroup)" :key="q.id"
												class="interaction-marker-dot"
												:class="{ 'is-completed': isAnswered(q.id) }"
												:style="{ left: `calc(10px + (100% - 20px) * ${q.timeMarker / (interactiveVideoDuration || 1)})` }"
												@click.stop="seekToInteractiveQuestion(q)"
												:title="`Câu ${getGlobalQuestionNumberByQuestionId(q.id)} (${formatTimeMarker(q.timeMarker)})`">
											</div>
										</div>

										<!-- Điều khiển Play/Pause, hiển thị thời gian và danh sách mốc câu hỏi -->
										<div class="d-flex align-center ga-2 mt-1 px-1 flex-wrap">
											<v-btn icon size="small" variant="tonal" color="deep-purple-accent-4" @click="toggleInteractiveVideoPlay">
												<v-icon>{{ interactiveVideoPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon>
											</v-btn>
											<span class="text-caption font-weight-medium">
												{{ formatTimeMarker(interactiveVideoCurrentTime) }} / {{ formatTimeMarker(interactiveVideoDuration) }}
											</span>
											<!-- Hiển thị danh sách badge các mốc câu hỏi trong nhóm -->
											<div class="d-flex align-center ga-1 ml-auto flex-wrap">
												<span class="text-caption text-medium-emphasis mr-1">Mốc câu hỏi:</span>
												<v-chip v-for="q in getGroupInteractiveQuestions(currentGroup)" :key="q.id"
													size="x-small" :color="isAnswered(q.id) ? 'success' : 'deep-purple'"
													variant="tonal" class="cursor-pointer"
													@click="seekToInteractiveQuestion(q)">
													<v-icon start size="11">mdi-clock-outline</v-icon>
													Câu {{ getGlobalQuestionNumberByQuestionId(q.id) }} ({{ formatTimeMarker(q.timeMarker) }})
												</v-chip>
											</div>
										</div>
									</div>
									<div v-else-if="currentGroup.media.sourceYT?.source?.length > 0"
										class="youtube-container">
										<iframe :src="renderUrlYoutube(currentGroup.media.sourceYT?.source)"
											style="width: 100%; height: 400px" frameborder="0"
											allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
											allowfullscreen></iframe>
									</div>
								<uc-wave-audio-player v-if="getAudioSource(currentGroup.media)?.length > 0"
										:audio-url="getAudioSource(currentGroup.media)" />
									<v-row v-if="currentGroup.media.sourceFiles.image?.length > 0"
										style="min-height: 350px">
										<v-col cols="6" sm="6" md="4" lg="4"
											v-for="file in currentGroup.media.sourceFiles.image" :key="file.source">
											<v-img
												:src="getImageSource(file)"
												:lazy-src="getImageSource(file, 'w200')"
												class="rounded-lg" max-height="350">
												<template #placeholder>
													<v-row align="center" class="fill-height ma-0" justify="center">
														<v-progress-circular color="grey-lighten-5" indeterminate />
													</v-row>
												</template>
											</v-img>
										</v-col>
									</v-row>
									<div v-if="currentGroup.media.sourceFiles.file?.length > 0" class="assignment-media-files">
										<iframe v-for="file in currentGroup.media.sourceFiles.file" :key="file.externalSource || file.source"
											:src="getMediaSource(file)" class="assignment-media-file-frame"
											:title="file.name || 'Tệp đính kèm'" loading="lazy"></iframe>
									</div>
								</div>
							</v-card-text>
						</v-card>

						<v-divider></v-divider>
						<v-card-text class="px-3 pt-3 pb-0" v-if="currentGroup.isCheckShowAllQuestion">
							<div v-for="question in currentGroup.questions">
								<div class="d-flex align-center justify-end ga-2">
									<v-chip v-if="questionsTypesLabel(question.type)"
										:color="questionsTypesLabel(question.type).color" size="small">
										{{ questionsTypesLabel(question.type).label }}
									</v-chip>

									<v-chip color="primary" variant="outlined" size="small">
										{{ question.points }}đ
									</v-chip>
								</div>
								<!-- Question text -->
								<div class="d-flex ga-2">
									<b class="responsive-fs-title" style="flex-shrink: 0;display: inline-block;">
										Câu {{ getGlobalQuestionNumberByQuestionId(question.id) }}:
									</b>
								<uc-latex-view class="question-text body-respondsive-fs flex-column ga-2"
									v-model:content="question.config.questionText"
									:escape-html="isTinHoc" :literal-html-tags="isTinHoc"
									:preserve-html-structure="isTinHoc"
									style="align-items: unset !important" />
								</div>
								<!-- Media -->
								<div v-if="question.config.media" class="media-container">
									<div v-if="question.config.media.sourceYT?.source.length > 0"
										class="youtube-container">
										<iframe :src="renderUrlYoutube(question.config.media.sourceYT?.source)"
											frameborder="0" style="width: 100%; height: 400px"
											allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
											allowfullscreen></iframe>
									</div>
								<uc-wave-audio-player v-if="getAudioSource(question.config.media)?.length > 0"
										:audio-url="getAudioSource(question.config.media)" />
									<v-row v-if="question.config.media.sourceFiles.image?.length > 0"
										style="min-height: 400px">
										<v-col cols="6" sm="6" md="4" lg="4"
											v-for="file in question.config.media.sourceFiles.image" :key="file.source">
											<v-img
												:src="getImageSource(file)"
												:lazy-src="getImageSource(file, 'w200')"
												class="rounded-lg" max-height="400">
												<template #placeholder>
													<v-row align="center" class="fill-height ma-0" justify="center">
														<v-progress-circular color="grey-lighten-5" indeterminate />
													</v-row>
												</template>
											</v-img>
										</v-col>
									</v-row>
									<div v-if="question.config.media.sourceFiles?.file?.length > 0" class="assignment-media-files">
										<iframe v-for="file in question.config.media.sourceFiles.file" :key="file.externalSource || file.source"
											:src="getMediaSource(file)" class="assignment-media-file-frame"
											:title="file.name || 'Tệp đính kèm'" loading="lazy"></iframe>
									</div>
								</div>

								<!-- Answer area -->
				<div class="answer-area">
									<component :is="getQuestionComponent(question.type)" :question="question"
										:answer="getAnswerForChild(question)"
										:grading="userAnswers[question.id]?.grading" :isGrade="isGrade"
										:submissionstatus="submissionstatus" :max-points="question.points"
										:student-comment="userAnswers[question.id]?.grading?.comment || ''"
										@grading-change="updateGrading(question.id, $event)"
										@answer-change="updateAnswer(question.id, $event)" :isShowBtnComment="false"
										:literal-html-tags="isTinHoc" />
								</div>
							</div>
						</v-card-text>
						<v-card-text class="px-3 pt-3 pb-0" v-else>
							<div class="d-flex align-center justify-end ga-2">
								<v-chip v-if="questionsTypesLabel(currentQuestion.type)"
									:color="questionsTypesLabel(currentQuestion.type).color" size="small">
									{{ questionsTypesLabel(currentQuestion.type).label }}
								</v-chip>

								<v-chip color="primary" variant="outlined" size="small">
									{{ currentQuestion.points }}đ
								</v-chip>
							</div>
							<!-- Question text -->
							<div class="d-flex ga-2 align-center flex-wrap">
								<b class="responsive-fs-title" style="flex-shrink: 0;display: inline-block;">
									Câu {{ getGlobalQuestionNumberByQuestionId(currentQuestion.id) }}:
								</b>
								<v-chip v-if="currentQuestion.timeMarker !== undefined && currentQuestion.timeMarker !== null"
									size="x-small" color="deep-purple" variant="flat" class="mr-1">
									<v-icon start size="12">mdi-clock-outline</v-icon>{{ formatTimeMarker(currentQuestion.timeMarker) }}
								</v-chip>
								<uc-latex-view class="question-text body-respondsive-fs flex-column ga-2"
									v-model:content="currentQuestion.config.questionText"
									:escape-html="isTinHoc" :literal-html-tags="isTinHoc"
									:preserve-html-structure="isTinHoc"
									style="align-items: unset !important" />
							</div>
							<!-- Media -->
							<div v-if="currentQuestion.config.media" class="media-container">
								<div v-if="currentQuestion.config.media.sourceYT?.source?.length > 0"
									class="youtube-container">
									<iframe :src="renderUrlYoutube(currentQuestion.config.media.sourceYT?.source)"
										frameborder="0" style="width: 100%; height: 400px"
										allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
										allowfullscreen></iframe>
								</div>
								<uc-wave-audio-player
									v-if="getAudioSource(currentQuestion.config.media)?.length > 0"
									:audio-url="getAudioSource(currentQuestion.config.media)" />
								<v-row v-if="currentQuestion.config.media.sourceFiles.image?.length > 0"
									style="min-height: 400px">
									<v-col cols="6" sm="6" md="4" lg="4"
										v-for="file in currentQuestion.config.media.sourceFiles.image"
										:key="file.source">
										<v-img
											:src="getImageSource(file)"
											:lazy-src="getImageSource(file, 'w200')"
											class="rounded-lg" max-height="400">
											<template #placeholder>
												<v-row align="center" class="fill-height ma-0" justify="center">
													<v-progress-circular color="grey-lighten-5" indeterminate />
												</v-row>
											</template>
										</v-img>
									</v-col>
								</v-row>
								<div v-if="currentQuestion.config.media?.sourceFiles?.file?.length > 0" class="assignment-media-files">
									<iframe v-for="file in currentQuestion.config.media.sourceFiles.file" :key="file.externalSource || file.source"
										:src="getMediaSource(file)" class="assignment-media-file-frame"
										:title="file.name || 'Tệp đính kèm'" loading="lazy"></iframe>
								</div>
							</div>

							<!-- Answer area -->
							<div class="answer-area">
								<component :is="getQuestionComponent(currentQuestion.type)" :question="currentQuestion"
									:answer="getAnswerForChild(currentQuestion)"
									@answer-change="updateAnswer(currentQuestion.id, $event)"
									@grading-change="updateGrading(currentQuestion.id, $event)"
									:grading="userAnswers[currentQuestion.id]?.grading" :isGrade="isGrade"
									:submissionstatus="submissionstatus" :max-points="currentQuestion.points"
									:student-comment="userAnswers[currentQuestion.id]?.grading?.comment || ''"
									:isShowBtnComment="false" :literal-html-tags="isTinHoc" />
							</div>
						</v-card-text>
						<!-- Action Bar -->
						<v-divider class="mt-3"></v-divider>
						<v-card-actions class="pa-3 d-flex justify-space-between">
							<v-btn @click="prevQuestion" :disabled="globalQuestionNumber === 1" variant="text">
								<v-icon start>mdi-chevron-left</v-icon>Câu trước
							</v-btn>

							<v-btn @click="nextQuestion" :disabled="globalQuestionNumber === totalQuestions"
								variant="text">
								Câu sau<v-icon end>mdi-chevron-right</v-icon>
							</v-btn>
						</v-card-actions>
					</v-card>
				</div>

				<div v-else class="all-questions-mode">
					<!-- All Questions List -->
					<div class="questions-container">
						<div v-for="(group, groupIndex) in assignment.groups" :key="group.id"
							class="group-section mb-6">
							<v-card class="group-header-card mb-3" flat border>
								<v-card-text class="py-3">
									<div class="d-flex justify-space-between align-center">
										<div class="d-flex align-center ga-3">
											<div class="group-icon-wrapper">
												<v-icon color="primary" size="20">mdi-folder-text-outline</v-icon>
											</div>
											<div class="group-info">
												<h3 class="group-title-main">{{ group.title }}</h3>
												<div class="group-meta">
													<span class="text-caption text-medium-emphasis">{{
														group.questions.length }} câu hỏi</span>
													<span class="mx-2">•</span>
													<span class="text-caption text-medium-emphasis">
														Tối đa {{group.questions.reduce((sum, q) => sum + q.points, 0)
														}} điểm
													</span>
												</div>
											</div>
										</div>
									</div>
									<p v-if="group.description" class="group-description">
										{{ group.description }}
									</p>
									<!-- Nội dung rich text hiển thị trước Media trong chế độ xem toàn bộ câu hỏi. -->
									<uc-latex-view v-if="group.content" class="group-content mb-2" :content="group.content" />
								</v-card-text>
							</v-card>
							<!-- Media -->
							<div v-if="group.media" class="media-container mb-2">
								<!-- Player Video tương tác: Chế độ tất cả câu hỏi -->
								<div v-if="isGroupInteractiveVideo(group)" class="interactive-video-player-container mb-3">
									<div class="interactive-player-wrapper" style="position: relative; width: 100%; aspect-ratio: 16/9; background: #000; border-radius: 8px; overflow: hidden;">
										<div :id="interactivePlayerId + '_' + groupIndex" style="width: 100%; height: 100%;"></div>
										<!-- Lớp overlay trong suốt chỉ xuất hiện khi video đang phát: ngăn hiện controls/thanh time YouTube, click vào để tạm dừng -->
										<div v-if="interactiveVideoPlaying" class="player-overlay" @click="toggleInteractiveVideoPlay"></div>
									</div>

									<!-- Thanh tua Timeline ngoài chuẩn hoc-lieu-view với các chấm mốc câu hỏi -->
									<div class="position-relative w-100 d-flex align-center mt-2 px-1" style="height: 24px;">
										<v-slider v-model="interactiveVideoCurrentTime" :max="interactiveVideoDuration || 100" min="0" step="1"
											hide-details density="compact" color="deep-purple-accent-4" track-color="grey-lighten-2"
											:track-size="4" :thumb-size="12"
											@update:model-value="seekInteractiveVideo"
											class="w-100">
										</v-slider>

										<!-- Các chấm marker câu hỏi tương tác đặt trên thanh timeline slider -->
										<div v-for="q in getGroupInteractiveQuestions(group)" :key="q.id"
											class="interaction-marker-dot"
											:class="{ 'is-completed': isAnswered(q.id) }"
											:style="{ left: `calc(10px + (100% - 20px) * ${q.timeMarker / (interactiveVideoDuration || 1)})` }"
											@click.stop="seekToInteractiveQuestion(q)"
											:title="`Câu ${getGlobalQuestionNumberByQuestionId(q.id)} (${formatTimeMarker(q.timeMarker)})`">
										</div>
									</div>

									<!-- Điều khiển Play/Pause, hiển thị thời gian và danh sách mốc câu hỏi -->
									<div class="d-flex align-center ga-2 mt-1 px-1 flex-wrap">
										<v-btn icon size="small" variant="tonal" color="deep-purple-accent-4" @click="toggleInteractiveVideoPlay">
											<v-icon>{{ interactiveVideoPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon>
										</v-btn>
										<span class="text-caption font-weight-medium">
											{{ formatTimeMarker(interactiveVideoCurrentTime) }} / {{ formatTimeMarker(interactiveVideoDuration) }}
										</span>
										<div class="d-flex align-center ga-1 ml-auto flex-wrap">
											<span class="text-caption text-medium-emphasis mr-1">Mốc câu hỏi:</span>
											<v-chip v-for="q in getGroupInteractiveQuestions(group)" :key="q.id"
												size="x-small" :color="isAnswered(q.id) ? 'success' : 'deep-purple'"
												variant="tonal" class="cursor-pointer"
												@click="seekToInteractiveQuestion(q)">
												<v-icon start size="11">mdi-clock-outline</v-icon>
												Câu {{ getGlobalQuestionNumberByQuestionId(q.id) }} ({{ formatTimeMarker(q.timeMarker) }})
											</v-chip>
										</div>
									</div>
								</div>
								<div v-else-if="group.media.sourceYT?.source?.length > 0" class="youtube-container">
									<iframe :src="renderUrlYoutube(group.media.sourceYT?.source)"
										style="width: 100%; height: 400px" frameborder="0"
										allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
										allowfullscreen></iframe>
								</div>
								<uc-wave-audio-player v-if="getAudioSource(group.media)?.length > 0"
									:audio-url="getAudioSource(group.media)" />
								<v-row v-if="group.media.sourceFiles.image?.length > 0" style="min-height: fit-content">
									<v-col cols="6" sm="6" md="4" lg="4" v-for="file in group.media.sourceFiles.image"
										:key="file.source">
										<v-img
											:src="getImageSource(file)"
											:lazy-src="getImageSource(file, 'w200')"
											class="rounded-lg" max-height="400">
											<template #placeholder>
												<v-row align="center" class="fill-height ma-0" justify="center">
													<v-progress-circular color="grey-lighten-5" indeterminate />
												</v-row>
											</template>
										</v-img>
									</v-col>
								</v-row>
								<div v-if="group.media.sourceFiles.file?.length > 0" class="assignment-media-files">
									<iframe v-for="file in group.media.sourceFiles.file" :key="file.externalSource || file.source"
										:src="getMediaSource(file)" class="assignment-media-file-frame"
										:title="file.name || 'Tệp đính kèm'" loading="lazy"></iframe>
								</div>
							</div>
							<div class="questions-in-group">
								<v-card v-for="(question, questionIndexInGroup) in group.questions" :key="question.id"
									:id="question.id" class="question-card-all mb-3 border-b"
									:class="{ 'question-answered': isAnswered(question.id) }" flat
									border="!group.isCheckShowAllQuestion">
									<!-- Compact header -->
									<div class="question-header-all-compact pa-2">
										<div v-if="!isMobile">
											<div class="mb-2 d-flex align-center ga-2">
												<v-chip v-if="questionsTypesLabel(question.type)"
													:color="questionsTypesLabel(question.type).color" size="x-small">
													{{ questionsTypesLabel(question.type).label }}
												</v-chip>
												<v-spacer></v-spacer>
												<v-chip text-color="primary" variant="outlined" size="x-small"
													class="points-chip-mobile" style="min-width: 30px">
													{{ question.points }}đ
												</v-chip>
											</div>
											<div class="d-flex ga-2 align-center flex-wrap">
												<v-icon :color="getIconColor(question.id)" size="18">
													{{ getQuestionStatusIcon(question.id) }}
												</v-icon>
												<b style="flex-shrink: 0;display: inline-block;">
													Câu {{ getGlobalQuestionNumber(groupIndex, questionIndexInGroup)
													}}:
												</b>
												<v-chip v-if="question.timeMarker !== undefined && question.timeMarker !== null"
													size="x-small" color="deep-purple" variant="flat" class="mr-1">
													<v-icon start size="12">mdi-clock-outline</v-icon>{{ formatTimeMarker(question.timeMarker) }}
												</v-chip>
													<uc-latex-view class="question-text-compact flex-grow-1 flex-column"
														v-model:content="question.config.questionText"
														:escape-html="isTinHoc" :literal-html-tags="isTinHoc"
														:preserve-html-structure="isTinHoc"
														style="align-items: unset !important;" />
											</div>
										</div>

										<div v-else class="d-flex flex-column ga-1">
											<div class="d-flex align-center ga-2">
												<v-chip v-if="questionsTypesLabel(question.type)"
													:color="questionsTypesLabel(question.type).color" size="x-small">
													{{ questionsTypesLabel(question.type).label }}
												</v-chip>
												<v-spacer></v-spacer>
												<v-chip text-color="primary" variant="outlined" size="x-small"
													class="points-chip-mobile" style="min-width: 30px">
													{{ question.points }}đ
												</v-chip>
											</div>

											<v-divider />

											<!-- Media -->
											<div v-if="group.media" class="media-container">
												<div v-if="group.media.sourceYT?.source?.length > 0"
													class="youtube-container">
													<iframe :src="renderUrlYoutube(group.media.sourceYT?.source)"
														style="width: 100%; height: 400px" frameborder="0"
														allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
														allowfullscreen></iframe>
												</div>
													<uc-wave-audio-player v-if="getAudioSource(group.media)?.length > 0"
													:audio-url="getAudioSource(group.media)" />
												<v-row v-if="group.media.sourceFiles.image.length > 0"
													style="min-height: fit-content">
													<v-col cols="6" sm="6" md="4" lg="4"
														v-for="file in group.media.sourceFiles.image"
														:key="file.source">
														<v-img
													:src="getImageSource(file)"
													:lazy-src="getImageSource(file, 'w200')"
															class="rounded-lg" max-height="400">
															<template #placeholder>
																<v-row align="center" class="fill-height ma-0"
																	justify="center">
																	<v-progress-circular color="grey-lighten-5"
																		indeterminate />
																</v-row>
															</template>
														</v-img>
													</v-col>
												</v-row>
												<div v-if="group.media.sourceFiles.file?.length > 0" class="assignment-media-files">
													<iframe v-for="file in group.media.sourceFiles.file" :key="file.externalSource || file.source"
														:src="getMediaSource(file)" class="assignment-media-file-frame"
														:title="file.name || 'Tệp đính kèm'" loading="lazy"></iframe>
												</div>
											</div>

											<div class="d-flex ga-2">
												<v-icon class="mt-1" :color="getIconColor(question.id)" size="18">
													{{ getQuestionStatusIcon(question.id) }}
												</v-icon>
												<b
													style="flex-shrink: 0;display: inline-block;padding-top:2px;font-size: 0.85rem;">
													Câu {{ getGlobalQuestionNumber(groupIndex, questionIndexInGroup)
													}}:
												</b>
												<uc-latex-view
														class="question-text-compact flex-column flex-grow-1 justify-center"
														v-model:content="question.config.questionText"
														:escape-html="isTinHoc" :literal-html-tags="isTinHoc"
														:preserve-html-structure="isTinHoc"
														style="align-items: unset !important;font-size: 0.85rem;" />
											</div>

										</div>
									</div>

									<v-card-text class="question-content-compact pt-3 pb-4">
										<!-- Media -->
										<div v-if="question.config.media" class="media-container">
											<div v-if="question.config.media.sourceYT?.source.length > 0"
												class="youtube-container">
												<iframe :src="renderUrlYoutube(question.config.media.sourceYT?.source)"
													style="width: 100%; height: 400px" frameborder="0"
													allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
													allowfullscreen></iframe>
											</div>
											<uc-wave-audio-player
														v-if="getAudioSource(question.config.media)?.length > 0"
													:audio-url="getAudioSource(question.config.media)" />
											<v-row v-if="question.config.media.sourceFiles.image.length > 0"
												style="min-height: 400px">
												<v-col :cols="6" sm="6" md="4" lg="4"
													v-for="file in question.config.media.sourceFiles.image"
													:key="file.source">
													<v-img
											:src="getImageSource(file)"
											:lazy-src="getImageSource(file, 'w200')"
														class="rounded-lg" max-height="400">
														<template #placeholder>
															<v-row align="center" class="fill-height ma-0"
																justify="center">
																<v-progress-circular color="grey-lighten-5"
																	indeterminate />
															</v-row>
														</template>
													</v-img>
												</v-col>
											</v-row>
											<div v-if="question.config.media.sourceFiles?.file?.length > 0" class="assignment-media-files">
												<iframe v-for="file in question.config.media.sourceFiles.file" :key="file.externalSource || file.source"
													:src="getMediaSource(file)" class="assignment-media-file-frame"
													:title="file.name || 'Tệp đính kèm'" loading="lazy"></iframe>
											</div>
										</div>

										<!-- Answer -->
										<div class="answer-section-compact">
											<component :is="getQuestionComponent(question.type)" :question="question"
												:answer="getAnswerForChild(question)"
												@answer-change="updateAnswer(question?.id, $event)"
												@grading-change="updateGrading(question?.id, $event)"
												:grading="userAnswers[question.id]?.grading" :isGrade="isGrade"
												:submissionstatus="submissionstatus" :max-points="question.points"
												:student-comment="userAnswers[question.id]?.grading?.comment || ''"
												:isShowBtnComment="false" :literal-html-tags="isTinHoc" />
										</div>
									</v-card-text>
								</v-card>
							</div>
						</div>
					</div>
				</div>
			</v-col>
		</v-row>
	</div>
</template>

<script>
	export default {
		name: 'uc-assignment-taker',
	props: {
		puseranswers: Object,
		assignmentData: Object,
		monHocName: String,
		onSaveDraft: { type: Function, default: () => { } },
		onOpenSubmitDialog: { type: Function, default: () => { } }
	},
	emits: ['update:puseranswers'],
	data() {
		return {
			viewMode: 'single',
			navCollapsed: false,
			groupCollapsed: {},
			currentGroupIndex: 0,
			currentQuestionIndexInGroup: 0,
			saveStatus: 'Đã lưu',
			saveStatusColor: 'grey',
			saveStatusIcon: 'mdi-cloud-check-outline',
			isSaving: false,
			autoSaveTimer: null,
			vueData,
			isMobile: false,
			isTablet: false,
			showInstructions: false,
			toggleTC: false,
			submissionstatus: 1,
			answeredQuestions: null,
			isGrade: false,
			isUpdate: false,
			lodash: _,
			// Preview là một lượt xem mới nên giữ snapshot riêng, không mutate AssignmentConfig gốc.
			previewGroups: null,
			// Trạng thái cho player video tương tác
			interactivePlayerId: 'interactive_yt_player_' + Math.random().toString(36).substring(2, 9),
			interactiveVideoPlaying: false,
			interactiveVideoCurrentTime: 0,
			interactiveVideoDuration: 0,
			interactiveVideoTimer: null,
			lastTriggeredMarkerTime: -1,
			_interactivePlayerInstance: null
		}
	},
	computed: {
		userAnswers() {
			return this.puseranswers || {};
		},
		/**
		 * Bài Tin học cần hiển thị các thẻ HTML trong câu hỏi/đáp án như mã nguồn.
		 * ATC nhận tên môn từ API để dùng cùng quy tắc với màn hình submission.
		 */
		isTinHoc() {
			const subject = String(this.monHocName || '')
				.normalize('NFD')
				.replace(/[\u0300-\u036f]/g, '')
				.replace(/đ/gi, 'd')
				.toLowerCase()
				.trim();
			return /\btin hoc\b/.test(subject);
		},
		isIntegrated() {
			return this.assignment?.Type === 'INTEGRATED' || (!!this.assignment?.IntegrationSource && this.assignment?.IntegrationSource !== 'LMS');
		},
		assignment() {
			if (!this.assignmentData) return null
			let rawData = this.assignmentData;
			if (Array.isArray(rawData)) {
				rawData = rawData[0];
				if (Array.isArray(rawData)) {
					rawData = rawData[0];
				}
			}
			if (!rawData) return null;

			const config = { ...rawData };
			if (config && typeof config.AssignmentConfig === 'string') {
				try {
					const parsed = JSON.parse(config.AssignmentConfig);
					config.groups = this.previewGroups !== null ? this.previewGroups : (parsed.groups || []);
					// Hỗ trợ bài tập tích hợp (Integration) - Chỉ xử lý khi source không phải là 'LMS'
					if (parsed.type === 'INTEGRATED' || (config.IntegrationSource && config.IntegrationSource !== 'LMS')) {
						config.Type = 'INTEGRATED';
						config.ExternalLink = parsed.link || config.Instructions || '';
					}
				} catch (e) {
					config.groups = [];
				}
			}
			return config;
		},
		draft() {
			return this.assignmentData ?? null
		},
		totalQuestions() {
			if (!this.assignment?.groups) return 0;
			return this.assignment.groups.reduce((total, group) => total + group.questions.length, 0);
		},
		currentGroup() { return this.assignment?.groups?.[this.currentGroupIndex]; },
		currentQuestion() { return this.currentGroup?.questions?.[this.currentQuestionIndexInGroup]; },
		globalQuestionNumber() {
			if (!this.assignment?.groups) return 1;
			return this.getGlobalQuestionNumber(this.currentGroupIndex, this.currentQuestionIndexInGroup);
		},
		// isSubmitted() { return this.draft?.SubmissionStatus >= 2; },
		// isGraded() { return this.isSubmitted && this.draft?.SubmissionStatus === 4; },
		allQuestions() { return this.assignment?.groups?.flatMap(group => group.questions) || []; },
		dueDateStatus() {
			if (!this.assignment?.DueDate) {
				return { color: 'grey', variant: 'outlined', icon: 'mdi-calendar-blank', text: 'Không giới hạn' };
			}
			const now = new Date();
			const dueDate = new Date(this.assignment.DueDate);
			const timeDiff = dueDate.getTime() - now.getTime();
			const daysDiff = Math.ceil(timeDiff / (1000 * 3600 * 24));
			const hoursDiff = Math.ceil(timeDiff / (1000 * 3600));

			if (timeDiff < 0) return { color: 'error', variant: 'elevated', icon: 'mdi-clock-alert-outline', text: 'Quá hạn' };
			if (hoursDiff <= 24) return { color: 'warning', variant: 'elevated', icon: 'mdi-clock-fast', text: hoursDiff <= 1 ? 'Gấp!' : `Còn ${hoursDiff}h` };
			if (daysDiff <= 3) return { color: 'orange', variant: 'elevated', icon: 'mdi-clock-outline', text: `Còn ${daysDiff} ngày` };
			return { color: 'success', variant: 'tonal', icon: 'mdi-clock-check-outline', text: daysDiff <= 7 ? `Còn ${daysDiff} ngày` : 'Trong hạn' };
		},
		answeredCount() { return this.allQuestions.filter(q => this.isAnswered(q.id)).length; },
		progressPercent() {
			if (!this.totalQuestions) return 0;
			return (this.answeredCount / this.totalQuestions) * 100;
		}
	},
	mounted() {
		window.addEventListener('resize', () => { this.ResizeWindow() })
		this.ResizeWindow()
	},
	methods: {
		ResizeWindow() {
			this.isMobile = window.innerWidth < 960
			this.isTablet = window.innerWidth <= 1240
		},
		getPreviewAssignmentRecord(value) {
			let record = value
			if (Array.isArray(record)) {
				record = record[0]
				if (Array.isArray(record)) record = record[0]
			}
			return record || null
		},
		// Preview phải mô phỏng đúng một lượt làm bài: group RANDOM được bốc lại
		// từ toàn bộ câu trong group, sau đó mới áp dụng trộn câu/trộn đáp án.
		preparePreviewAttempt(value) {
			this.previewGroups = null
			const record = this.getPreviewAssignmentRecord(value)
			if (!record?.AssignmentConfig) return

			let parsed
			try {
				parsed = typeof record.AssignmentConfig === 'string'
					? JSON.parse(record.AssignmentConfig)
					: record.AssignmentConfig
			} catch (error) {
				return
			}
			if (!parsed || parsed.type === 'INTEGRATED') {
				this.previewGroups = []
				return
			}

			const groups = this.lodash.cloneDeep(Array.isArray(parsed.groups) ? parsed.groups : [])
			groups.forEach(group => {
				const selection = group.questionSelection || {}
				const allQuestions = Array.isArray(group.questions) ? group.questions : []
				const isMatrixGroup = group?.questionSource?.sourceKind === 'QUESTION_BANK_SKILL_MATRIX'
					|| group?.questionSource?.matrixMode === true
					|| selection.matrixMode === true

				if (selection.mode === 'RANDOM' && !isMatrixGroup) {
					const requested = Math.floor(Number(selection.questionsPerAttempt))
					const count = Math.min(
						Math.max(Number.isFinite(requested) ? requested : allQuestions.length, 0),
						allQuestions.length
					)
					group.questions = this.lodash.shuffle(allQuestions).slice(0, count)
				} else if (selection.mode === 'RANDOM' && isMatrixGroup) {
					// Ma trận vẫn tôn trọng pool theo từng nguồn đã cấu hình.
					const selectedIds = new Set()
					const matrixConfigs = Array.isArray(group?.questionSource?.matrixConfigs)
						? group.questionSource.matrixConfigs
						: []
					matrixConfigs.forEach(matrixConfig => {
						const sources = Array.isArray(matrixConfig?.sources) && matrixConfig.sources.length
							? matrixConfig.sources
							: [matrixConfig]
						sources.forEach(source => {
							const sourceIds = new Set((source?.questionIds || []).map(id => String(id)))
							const sourceQuestions = allQuestions.filter(question => sourceIds.has(String(
								question?.sourceTracking?.questionId
									?? question?.sourceTracking?.sourceQuestionId
									?? question?.id
							)))
							const requested = Math.min(
								Math.max(Math.floor(Number(source?.randomCount) || 0), 0),
								sourceQuestions.length
							)
							this.lodash.shuffle(sourceQuestions).slice(0, requested).forEach(question => {
								selectedIds.add(String(question?.id))
							})
						})
					})
					group.questions = selectedIds.size
						? allQuestions.filter(question => selectedIds.has(String(question?.id)))
						: allQuestions
				}

				if (group.advancedFeatures?.isShuffleQuestions) {
					group.questions = this.lodash.shuffle(group.questions)
				}
				if (group.advancedFeatures?.isShuffleAnswers) {
					this.shufflePreviewAnswers(group.questions)
				}
			})

			this.previewGroups = groups
			this.currentGroupIndex = 0
			this.currentQuestionIndexInGroup = 0
		},
		shufflePreviewAnswers(questions) {
			(questions || []).forEach(question => {
				if (!question?.config) return
				if (['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_MULTIPLE_TRUE_FALSE'].includes(question.type)) {
					question.config.options = this.lodash.shuffle(question.config.options || [])
				}
				if (['QUIZ_MATCHING', 'QUIZ_MATCHING_V2'].includes(question.type)) {
					question.config.columnA = this.lodash.shuffle(question.config.columnA || [])
					question.config.columnB = this.lodash.shuffle(question.config.columnB || [])
				}
			})
		},
		isActiveQuestion(groupIndex, questionIndexInGroup) {
			return this.currentGroupIndex === groupIndex && this.currentQuestionIndexInGroup === questionIndexInGroup;
		},
		getAnswerForChild(question) {

			console.log('question', question)
			let answerObject = this.userAnswers[question.id];
			if (!this.isUpdate) {
				switch (question.type) {
					case 'QUIZ_SINGLE_CHOICE': answerObject = ""; break;
					case 'QUIZ_MULTIPLE_CHOICE': answerObject = []; break;
					case 'QUIZ_TRUE_FALSE': answerObject = null; break;
					case 'QUIZ_MULTIPLE_TRUE_FALSE':
						let obj = {}
						for (var option of question.config.options) {
							let answer
							if (option.correctAnswer) answer = true
							if (option.inCorrectAnswer) answer = false
							obj[option.id] = null
						}
						answerObject = obj;
						break;
					case 'QUIZ_FILL_IN_BLANK': {
						const blanks = question.config.parts?.filter(item => item.type === 'blank');
						const obj = {};
						if (blanks) {
							for (var item of blanks) {
								obj[item.id] = "";
							}
						}
						answerObject = obj;
						break;
					}
					case 'QUIZ_MATCHING': answerObject = []; break;
					case 'QUIZ_MATCHING_V2': answerObject = []; break;
				}

				return answerObject
			}
			console.log('answerObject', answerObject)
			console.log('isGrade', this.isGrade)
			return answerObject?.answerData


		},
		// Điểm thực tế của câu
		getQuestionScore(questionId) {
			const g = vueData.userAnswersSubmitted?.[questionId]?.grading
			if (!g) return null
			let s = 0
			let has = false
			if (typeof g.autoScore === 'number') { s += g.autoScore; has = true }
			if (typeof g.manualScore === 'number') { s += g.manualScore; has = true }
			return has ? s : null
		},

		// Chip trạng thái câu
		questionStatus(questionId, maxPoint) {
			const answered = this.isAnswered(questionId)
			// if (!answered) return { label: 'Chưa TL', color: 'grey', variant: 'tonal' }
			const s = this.getQuestionScore(questionId)
			// if (s === null) return { label: 'Chờ chấm', color: 'grey', variant: 'tonal' }
			if (s <= 0) return { label: 'Sai', color: 'error', variant: 'tonal' }
			if (s >= (maxPoint ?? 0)) return { label: 'Đúng', color: 'success', variant: 'tonal' }
			return { label: 'Một phần', color: 'warning', variant: 'tonal' }
		},

		initializeAnswers() {
			if (this.draft) {
				try {
					const asmConfigString = this.assignment?.AssignmentConfig
					if (!asmConfigString) return;
					const asmData = JSON.parse(asmConfigString)
					if (asmData.type === 'INTEGRATED') return;
					const submissionContent = JSON.parse(this.draft.SubmissionContent || '{}') || { answers: {} }
					const answers = submissionContent.answers || {}

					if (asmData.groups) {
						asmData.groups.forEach(group => {
							for (var question of group.questions) {
								const sourceGrading = answers[question.id]?.grading || {};
								answers[question.id] = {
									answerData: answers[question.id]?.answerData ?? null,
									grading: {
										...sourceGrading,
										comment: sourceGrading.comment || null,
										teacherComment: sourceGrading.teacherComment || null,
										manualScore: sourceGrading.manualScore ?? null,
										autoScore: sourceGrading.autoScore ?? null,
									}
								}
							}
						})
					}
					console.log('answers', answers)
					this.$emit('update:puseranswers', answers || {});
				} catch (e) {
					this.$emit('update:puseranswers', {});
				}
			} else {
				// console.log('else')
				//Nếu chưa có draft phải save trước để biết bấm đã bấm vô làm bài
				// this.saveDraft()
				this.$emit('update:puseranswers', {});
			}

			if (this.assignment?.groups) {
				const initialCollapsed = {};
				this.assignment.groups.forEach((group, index) => { initialCollapsed[index] = false });
				this.groupCollapsed = initialCollapsed;
			}
		},
		getQuestionStatusIcon(questionId) {
			if (this.isAnswered(questionId)) { return 'mdi-pencil-circle'; }
			const num = this.getGlobalQuestionNumberByQuestionId(questionId);
			return `mdi-help-box-outline`;
		},
		getIconColor(questionId) {
			return this.isAnswered(questionId) ? 'blue' : 'grey';
		},
		getGlobalQuestionNumber(groupIndex, questionIndexInGroup) {
			if (!this.assignment?.groups) return 1;
			let number = 1;
			for (let i = 0; i < groupIndex; i++) { number += this.assignment.groups[i].questions.length; }
			return number + questionIndexInGroup;
		},
		getGlobalQuestionNumberByQuestionId(questionId) {
			if (!this.allQuestions) return 0;
			const index = this.allQuestions.findIndex(q => q.id === questionId);
			return index + 1;
		},
		getGroupAnsweredCount(group) {
			return group.questions.filter(q => this.isAnswered(q.id)).length;
		},
		toggleGroupCollapse(groupIndex) {
			this.groupCollapsed = { ...this.groupCollapsed, [groupIndex]: !this.groupCollapsed[groupIndex] };
		},
		navigateToQuestion(groupIndex, questionIndexInGroup, id) {
			if (this.viewMode == 'all') {

				var element = document.getElementById(id);
				if (element) {
					element.scrollIntoView({
						behavior: "smooth", // cuộn mượt
						block: "start" // vị trí hiển thị: start | center | end | nearest
					});
				}

			}
			this.currentGroupIndex = groupIndex;
			this.currentQuestionIndexInGroup = questionIndexInGroup;
			if (this.groupCollapsed[groupIndex]) { this.toggleGroupCollapse(groupIndex); }
		},
		prevQuestion() {
			if (this.currentQuestionIndexInGroup > 0) { this.currentQuestionIndexInGroup--; }
			else if (this.currentGroupIndex > 0) {
				this.currentGroupIndex--;
				this.currentQuestionIndexInGroup = this.assignment.groups[this.currentGroupIndex].questions.length - 1;
			}
		},
		nextQuestion() {
			if (!this.assignment || !this.assignment.groups) return;
			const currentGroup = this.assignment.groups[this.currentGroupIndex];
			if (this.currentQuestionIndexInGroup < currentGroup.questions.length - 1) { this.currentQuestionIndexInGroup++; }
			else if (this.currentGroupIndex < this.assignment.groups.length - 1) {
				this.currentGroupIndex++;
				this.currentQuestionIndexInGroup = 0;
			}
		},
		getQuestionComponent(type) {
			const map = {
				'QUIZ_SINGLE_CHOICE': 'uc-question-single-choice',
				'QUIZ_MULTIPLE_CHOICE': 'uc-question-multiple-choice',
				'QUIZ_TRUE_FALSE': 'uc-question-true-false',
				'QUIZ_MULTIPLE_TRUE_FALSE': 'uc-question-multiple-true-false',
				'QUIZ_FILL_IN_BLANK': 'uc-question-fill-in-blank',
				'QUIZ_MATCHING': 'uc-question-matching',
				'QUIZ_MATCHING_V2': 'uc-question-matching',
				'SHORT_ANSWER': 'uc-question-short-answer',
				'ESSAY': 'uc-question-essay',
				'FILE_UPLOAD': 'uc-question-file-upload',
				'AUDIO_RESPONSE': 'uc-question-audio-response'
			};
			return map[type] || 'div';
		},
		isAnswered(questionId) {
			const answer = this.userAnswers[questionId]?.answerData;
			if (answer === null || answer === undefined) return false;
			if (typeof answer === 'string' && answer.trim() === '') return false;
			if (Array.isArray(answer) && answer.length === 0) return false;
			if (typeof answer === 'object' && !Array.isArray(answer) && Object.keys(answer).length === 0) return false;
			return true;
		},
		formatDate(dateString) {
			if (!dateString) return 'Chưa có thông tin';
			const date = new Date(dateString);
			return date.toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
		},
		getYoutubeEmbedUrl(url) {
			if (!url) return '';
			let videoId = '';
			const standardMatch = url.match(/[?&]v=([^&]+)/);
			if (standardMatch) videoId = standardMatch[1];
			const shortMatch = url.match(/youtu\.be\/([^?]+)/);
			if (shortMatch) videoId = shortMatch[1];
			const embedMatch = url.match(/embed\/([^?]+)/);
			if (embedMatch) videoId = embedMatch[1];
			if (videoId) return `https://www.youtube.com/embed/${videoId}`;
			return url;
		},
		getDriveFileId(url) {
			const match = url?.match(/\/d\/([^/]+)\//);
			return match ? match[1] : null;
		},
		normalizeDrivePreviewUrl(url) {
			const match = url?.match(/^https?:\/\/drive\.google\.com\/file\/d\/([^/]+)\/(?:view|preview)(?:[/?#]|$)/i);
			return match ? `https://drive.google.com/file/d/${match[1]}/preview` : url;
		},
		getMediaSource(file) {
			const dbSource = file?.source || '';
			// PDF đã được lưu thêm vào FileData khi giáo viên tải media. Ưu tiên
			// bản nội bộ cho PDF để không phụ thuộc vào bộ chuyển đổi preview
			// của Google Drive (có thể tải được trang 1 nhưng lỗi ở trang sau).
			const hasLmsCopy = file?.mediaSource === 'db'
				&& dbSource
				&& !/drive\.google\.com|docs\.google\.com/i.test(dbSource);
			const source = hasLmsCopy && this.isPreviewableFile(file)
				? dbSource
				: (file?.externalSource || dbSource || '');
			const normalizedSource = this.normalizeDrivePreviewUrl(source);
			if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(normalizedSource)) {
				return normalizedSource.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/');
			}
			if (/^https?:\/\//i.test(normalizedSource) || file?.mediaSource !== 'db') return normalizedSource;
			const base = vueData?.v_Set?.urlReadFile || '';
			return base ? `${base.replace(/\/+$/, '')}/${normalizedSource.replace(/^\/+/, '')}` : normalizedSource;
		},
		getImageSource(file, size = 'w1000') {
			const source = this.getMediaSource(file);
			const fileId = this.getDriveFileId(source);
			return fileId && /drive\.google\.com/i.test(source)
				? 'https://drive.google.com/thumbnail?id=' + (file.externalId || fileId) + '&sz=' + size
				: source;
		},
		getAudioSource(media) {
			const record = media?.sourceRecord;
			return record ? this.getMediaSource(record) : '';
		},
		isPreviewableFile(file) {
			return /\.pdf($|\?)/i.test(file?.name || '') || file?.mimeType === 'application/pdf';
		},
		renderUrlYoutube,
		test() { window.open("/lms-student-dashboard", '_parent'); },
		questionsTypesLabel,
		updateAnswer(questionId, newAnswer) {

			this.isUpdate = true
			console.log('update....', this.isUpdate)
			const newAnswers = { ...this.userAnswers };
			console.log('Received answer update for question ID:', questionId, 'New Answer:', newAnswer);
			const currentAnswerObject = newAnswers[questionId] || {};
			let answerData;

			const question = this.allQuestions.find(q => q.id === questionId);
			if (!question) { console.error(`Không tìm thấy cấu hình cho câu hỏi ID: ${questionId}`); return; }

			const questionType = question.type;
			const fileBasedTypes = ['FILE_UPLOAD', 'AUDIO_RESPONSE'];
			if (fileBasedTypes.includes(questionType)) { answerData = Array.isArray(newAnswer) ? newAnswer : [newAnswer]; }
			else { answerData = newAnswer; }

			console.log('Updating answer for question ID:', questionId, 'New Answer:', newAnswers[questionId]);

			newAnswers[questionId] = {
				...currentAnswerObject,
				answerData,
				grading: {
					teacherComment: newAnswers[questionId]?.grading?.teacherComment ?? '',
					comment: newAnswers[questionId]?.grading?.comment ?? '',
				}
			};

			const manualComp = ['SHORT_ANSWER', 'ESSAY', 'FILE_UPLOAD', 'AUDIO_RESPONSE'];
			if (manualComp.includes(questionType)) {
				newAnswers[questionId].grading = { ...newAnswers[questionId]?.grading, manualScore: null }
			}
			this.$emit('update:puseranswers', newAnswers);
			console.log('newAnswers', newAnswers)
			this.saveStatus = 'Đang soạn...';
			this.saveStatusColor = 'orange';
			this.saveStatusIcon = 'mdi-pencil-outline';
			if (this.autoSaveTimer) clearTimeout(this.autoSaveTimer);
			this.autoSaveTimer = setTimeout(this.saveDraft, 2500);
		},
		handleClickAction() {
			if (this.submissionstatus != 2) {
				this.submissionstatus = 2
			} else if (this.submissionstatus != 4 && this.submissionstatus == 2) {
				this.submissionstatus = 4
				this.isGrade = true
			}

		},
		updateGrading(questionId, newGradingData) {
			const newGrading = { ...this.userAnswers };
			const currentAnswer = newGrading[questionId] || {};
			newGrading[questionId] = { ...currentAnswer, grading: newGradingData };
			this.$emit('update:puseranswers', newGrading);
		},
		displayStatus(status) {
			switch (status) {
				case 1: return 'Chưa nộp';
				case 2: return 'Đã nộp';
				case 4: return 'Đã chấm điểm';
				default: return 'Không xác định';
			}
		},
		displayStatusColor(status) {
			switch (status) {
				case 1: return 'grey';
				case 2: return 'blue';
				case 4: return 'green';
				default: return 'grey';
			}
		},
		// Phương thức hỗ trợ Video tương tác: chỉ chạy chế độ tương tác khi nhóm được tích chọn cho phép
		isGroupInteractiveVideo(group) {
			if (!group) return false;
			return Boolean(group.isInteractiveVideo || group.media?.type === 'INTERACTIVE_VIDEO' || group.media?.interactiveVideo);
		},
		getGroupInteractiveQuestions(group) {
			if (!group?.questions) return [];
			return group.questions.filter(q => q.timeMarker !== undefined && q.timeMarker !== null);
		},
		formatTimeMarker(seconds) {
			if (seconds === undefined || seconds === null || isNaN(Number(seconds))) return '00:00';
			const total = Math.max(0, Math.floor(Number(seconds)));
			const hours = Math.floor(total / 3600);
			const minutes = Math.floor((total % 3600) / 60);
			const secs = total % 60;
			const result = (minutes < 10 ? '0' : '') + minutes + ':' + (secs < 10 ? '0' : '') + secs;
			return hours ? (hours < 10 ? '0' : '') + hours + ':' + result : result;
		},
		ensureYoutubeApiLoaded() {
			if (window.YT && window.YT.Player) return Promise.resolve(window.YT);
			if (window.__contentHubYoutubeApiPromise) return window.__contentHubYoutubeApiPromise;
			window.__contentHubYoutubeApiPromise = new Promise(resolve => {
				let checkCount = 0;
				const interval = setInterval(() => {
					checkCount++;
					if (window.YT && window.YT.Player) {
						clearInterval(interval);
						resolve(window.YT);
					} else if (checkCount > 100) {
						clearInterval(interval);
						resolve(window.YT || null);
					}
				}, 100);

				const prevReady = window.onYouTubeIframeAPIReady;
				window.onYouTubeIframeAPIReady = () => {
					if (typeof prevReady === 'function') prevReady();
					clearInterval(interval);
					resolve(window.YT);
				};
				if (!document.querySelector('script[src*="youtube.com/iframe_api"]')) {
					const script = document.createElement('script');
					script.src = 'https://www.youtube.com/iframe_api';
					document.head.appendChild(script);
				}
			});
			return window.__contentHubYoutubeApiPromise;
		},
		initInteractivePlayer() {
			const group = this.currentGroup;
			if (!this.isGroupInteractiveVideo(group)) return;
			const videoSource = group.media?.interactiveVideo?.source || group.media?.sourceYT?.source || '';
			const match = videoSource.match(/[?&]v=([^&]+)|youtu\.be\/([^?]+)|embed\/([^?]+)/);
			const videoId = match ? (match[1] || match[2] || match[3]) : '';
			if (!videoId) return;

			this.ensureYoutubeApiLoaded().then(() => {
				this.destroyInteractivePlayer();
				this.$nextTick(() => {
					const elemId = this.viewMode === 'all'
						? `${this.interactivePlayerId}_${this.currentGroupIndex}`
						: this.interactivePlayerId;
					let elem = document.getElementById(elemId);
					if (!elem) {
						const wrapper = this.$el?.querySelector?.('.interactive-player-wrapper');
						if (wrapper) {
							elem = document.createElement('div');
							elem.id = elemId;
							elem.style.width = '100%';
							elem.style.height = '100%';
							wrapper.insertBefore(elem, wrapper.firstChild);
						}
					}
					if (!elem || !window.YT?.Player) return;
					// Khởi tạo YouTube Player với controls: 0 để ẩn thanh tua mặc định của YouTube,
					// toàn bộ điều khiển thời gian và mốc câu hỏi được quản lý qua thanh timeline ngoài giống hoc-lieu-view-v2
					this._interactivePlayerInstance = new window.YT.Player(elemId, {
						height: '100%',
						width: '100%',
						videoId,
						playerVars: { controls: 0, disablekb: 0, modestbranding: 1, rel: 0, cc_load_policy: 0, iv_load_policy: 3 },
						events: {
							onReady: event => {
								this._interactivePlayerInstance = event.target;
								const dur = Math.floor(event.target.getDuration?.() || 0);
								if (dur > 0) this.interactiveVideoDuration = dur;
								this.startInteractivePlayerTimer();
							},
							onStateChange: event => {
								this._interactivePlayerInstance = event.target;
								const dur = Math.floor(event.target.getDuration?.() || 0);
								if (dur > 0) this.interactiveVideoDuration = dur;

								const isPlay = event.data === window.YT?.PlayerState?.PLAYING || event.data === 1;
								this.interactiveVideoPlaying = isPlay;
								if (isPlay) {
									this.startInteractivePlayerTimer();
								} else {
									if (this.interactiveVideoTimer) {
										clearInterval(this.interactiveVideoTimer);
										this.interactiveVideoTimer = null;
									}
								}
							}
						}
					});
				});
			});
		},
		destroyInteractivePlayer() {
			if (this.interactiveVideoTimer) {
				clearInterval(this.interactiveVideoTimer);
				this.interactiveVideoTimer = null;
			}
			if (this._interactivePlayerInstance) {
				try { this._interactivePlayerInstance.destroy(); } catch (e) {}
				this._interactivePlayerInstance = null;
			}
			this.interactiveVideoPlaying = false;
		},
		startInteractivePlayerTimer() {
			if (this.interactiveVideoTimer) clearInterval(this.interactiveVideoTimer);
			this.interactiveVideoTimer = setInterval(() => {
				const player = this._interactivePlayerInstance;
				if (player && typeof player.getCurrentTime === 'function') {
					try {
						const currentTime = Math.floor(player.getCurrentTime() || 0);
						this.interactiveVideoCurrentTime = currentTime;
						this.interactiveVideoDuration = Math.floor(player.getDuration() || 0);
						this.checkInteractiveMarkers(currentTime);
					} catch (e) {}
				}
			}, 300);
		},
		toggleInteractiveVideoPlay() {
			const player = this._interactivePlayerInstance;
			if (!player) return;
			try {
				if (this.interactiveVideoPlaying) {
					player.pauseVideo();
				} else {
					player.playVideo();
				}
			} catch (e) {}
		},
		// Tua video đến thời điểm chỉ định từ thanh timeline slider bên ngoài
		seekInteractiveVideo(seconds) {
			const player = this._interactivePlayerInstance;
			if (player && typeof player.seekTo === 'function') {
				try { player.seekTo(Number(seconds || 0), true); } catch (e) {}
			}
		},
		seekToInteractiveQuestion(q) {
			const player = this._interactivePlayerInstance;
			if (player && typeof player.seekTo === 'function') {
				try { player.seekTo(Number(q.timeMarker || 0), true); } catch (e) {}
			}
			// Di chuyển tiêu điểm tới câu hỏi đó
			const qIndexInGroup = (this.currentGroup?.questions || []).findIndex(item => item.id === q.id);
			if (qIndexInGroup !== -1) {
				this.navigateToQuestion(this.currentGroupIndex, qIndexInGroup, q.id);
			}
		},
		checkInteractiveMarkers(currentTime) {
			if (!this.interactiveVideoPlaying) return;
			const questions = this.getGroupInteractiveQuestions(this.currentGroup);
			// Tìm câu hỏi trùng mốc thời gian và chưa từng trigger ở giây này
			const targetQuestion = questions.find(q => {
				const markerTime = Number(q.timeMarker || 0);
				return Math.abs(currentTime - markerTime) <= 1 && this.lastTriggeredMarkerTime !== markerTime;
			});

			if (targetQuestion) {
				this.lastTriggeredMarkerTime = Number(targetQuestion.timeMarker || 0);
				// Tự động tạm dừng video để học sinh trả lời câu hỏi
				const player = this._interactivePlayerInstance;
				if (player && typeof player.pauseVideo === 'function') {
					try { player.pauseVideo(); } catch (e) {}
				}
				// Điều hướng tới câu hỏi đó để học sinh làm
				const qIndex = (this.currentGroup?.questions || []).findIndex(item => item.id === targetQuestion.id);
				if (qIndex !== -1) {
					this.navigateToQuestion(this.currentGroupIndex, qIndex, targetQuestion.id);
				}
			}
		}
	},
	watch: {
		assignmentData: {
			handler(value) {
				this.preparePreviewAttempt(value)
				this.initializeAnswers()
			},
			deep: true,
			immediate: true
		},
		isMobile(val) { if (val) { this.viewMode = 'all'; } },
		currentGroupIndex() {
			this.$nextTick(() => { this.initInteractivePlayer(); });
		},
		viewMode() {
			this.$nextTick(() => { this.initInteractivePlayer(); });
		}
	},
	mounted() {
		window.addEventListener('resize', () => { this.ResizeWindow(); });
		this.ResizeWindow();
		this.$nextTick(() => { this.initInteractivePlayer(); });
	},
	beforeUnmount() {
		if (this.autoSaveTimer) clearTimeout(this.autoSaveTimer);
		this.destroyInteractivePlayer();
	}
	}
</script>