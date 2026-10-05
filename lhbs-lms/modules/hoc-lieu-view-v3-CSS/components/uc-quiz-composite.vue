<template>
	<div class="uc-quiz-composite">
		<!-- 🚀 Màn hình Bắt đầu -->
		<div v-if="quizState === 'start'" class="lh-quiz-start">
			<div class="lh-start-hero">
				<h1 class="lh-start-title" v-html="stripP(slideData.content.title)"></h1>
				<p class="lh-start-subtitle">Cùng trả lời các câu hỏi tương tác nhé!</p>
			</div>

			<div class="lh-start-info">
				<div v-if="!slideData?.content?.isInteractiveMode" class="lh-info-card">
					<div class="lh-info-icon">⏰</div>
					<div class="lh-info-content">
						<div class="lh-info-label">Thời gian</div>
						<div class="lh-info-value">{{ Math.floor((slideData.content.timeLimit || 0) / 60) }} phút</div>
					</div>
				</div>
				<div class="lh-info-card">
					<div class="lh-info-icon">📝</div>
					<div class="lh-info-content">
						<div class="lh-info-label">Số câu hỏi</div>
						<div class="lh-info-value">{{ totalQuestions }} câu</div>
					</div>
				</div>
				<div v-if="!slideData?.content?.isInteractiveMode" class="lh-info-card">
					<div class="lh-info-icon">🎯</div>
					<div class="lh-info-content">
						<div class="lh-info-label">Để qua bài</div>
						<div class="lh-info-value">{{ slideData.content.passingScore || Math.ceil(totalPoints * 0.7) }}/{{ totalPoints }}</div>
					</div>
				</div>
			</div>

			<!-- Groups Preview -->
			<div v-if="slideData.content.hasGroups" class="lh-groups-preview">
				<h3 class="lh-preview-title">Cấu trúc bài kiểm tra:</h3>
				<div class="lh-preview-groups">
					<div v-for="(group, index) in slideData.content.groups" :key="group.id" class="lh-preview-group">
						<div class="lh-preview-group-header">
							<span class="lh-preview-group-number">Phần {{ index + 1 }}</span>
							<span class="lh-preview-group-title">{{ group.title }}</span>
						</div>
						<div class="lh-preview-group-info">
							<span>{{ group.questions.length }} câu</span>
							<span>{{ group.points }} điểm</span>
							<span v-if="group.timeLimit">{{ Math.floor(group.timeLimit / 60) }} phút</span>
						</div>
						<div v-if="group.description" class="lh-preview-group-desc">{{ group.description }}</div>
					</div>
				</div>
			</div>

			<div class="lh-start-actions">
				<button class="lh-btn lh-btn-primary lh-btn-large" @click="startTest">
					<span class="lh-btn-icon">🚀</span>
					<span>Bắt đầu làm bài</span>
				</button>
			</div>
		</div>

		<!-- 📝 Màn hình Làm bài -->
		<div v-else-if="quizState === 'doing'" class="lh-quiz-layout">

			<!-- Content Area -->
			<div class="lh-quiz-content">

				<!-- Fullscreen Button -->
				<button class="lh-fullscreen-btn" @click="toggleQuizFullscreen"
					:title="isQuizFullscreen ? 'Thoát toàn màn hình' : 'Xem toàn màn hình'">
					<span class="lh-fullscreen-icon">{{ isQuizFullscreen ? '⛔' : '⛶' }}</span>
				</button>

				<div v-if="currentQuestion && userAnswers && userAnswers.composite && userAnswers.composite[currentQuestion.id]" class="lh-question-container">

					<!-- Question Header -->
					<div class="lh-question-header">
						<div class="lh-question-number">
							<span class="lh-question-badge">Câu {{ currentQuestionGlobalIndex + 1 }}</span>
							<span class="lh-question-type">{{ getQuestionTypeLabel(currentQuestion.type) }}</span>
						</div>
						<div v-if="currentGroup" class="lh-question-group-info">
							<span class="lh-group-badge">{{ currentGroup.title }}</span>
							<span class="lh-group-points">{{ currentQuestion.points || 1 }} điểm</span>
						</div>
					</div>

					<!-- Group Instruction -->
					<div v-if="currentGroup && currentGroup.instruction" class="lh-group-current-instruction">
						<div class="lh-instruction-header">
							<span class="lh-instruction-icon">💡</span>
							<span class="lh-instruction-title">Hướng dẫn {{ currentGroup.title }}:</span>
						</div>
						<div class="lh-instruction-content">{{ currentGroup.instruction }}</div>
					</div>

					<!-- Question Content -->
					<div class="lh-question-block"
						:class="'lh-quiz-' + currentQuestion.type.toLowerCase().replace('quiz_', '')">

						<!-- SingleChoice trong composite -->
						<div v-if="currentQuestion.type === 'QUIZ_SINGLE_CHOICE'" class="lh-single-choice">
							<!-- Prompt -->
							<uc-latex-view class="lh-question-prompt" :key="'prompt-' + currentQuestion.id"
								:content="currentQuestion.content.prompt" />

							<div class="lh-options-grid">
								<label v-for="option in currentQuestion.content.options" :key="option.id"
									class="lh-option-card"
									:class="{ 'lh-selected': userAnswers.composite[currentQuestion.id].singleChoice === option.id }">
									<input type="radio" :value="option.id"
										v-model="userAnswers.composite[currentQuestion.id].singleChoice"
										class="lh-option-input">
									<div class="lh-option-content">
										<div class="lh-option-indicator"></div>
										<!-- Option text -->
										<uc-latex-view class="lh-option-text"
											:key="'option-' + currentQuestion.id + '-' + option.id"
											:content="option.text" />
									</div>
								</label>
							</div>
						</div>

						<!-- MultipleChoice trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_MULTIPLE_CHOICE'" class="lh-multiple-choice">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion?.id" />
							<div class="lh-options-grid">
								<label v-for="option in currentQuestion.content.options" :key="option.id"
									class="lh-option-card lh-checkbox-card"
									:class="{ 'lh-selected': userAnswers.composite[currentQuestion.id].multipleChoice.includes(option.id) }">
									<input type="checkbox" :value="option.id"
										v-model="userAnswers.composite[currentQuestion.id].multipleChoice"
										class="lh-option-input">
									<div class="lh-option-content">
										<div class="lh-checkbox-indicator">
											<div class="lh-checkmark">✓</div>
										</div>
										<uc-latex-view class="lh-option-text" :content="option.text"
											:key="'option-' + currentQuestion.id + '-' + option.id" />
									</div>
								</label>
							</div>
						</div>

						<!-- Ordering trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_ORDERING'" class="lh-ordering">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion.id" />
							<div class="lh-ordering-hint">
								<span class="lh-hint-icon">💡</span>
								<span>Kéo thả để sắp xếp theo thứ tự đúng</span>
							</div>
							<div class="lh-ordering-container" :ref="'orderingContainer_' + currentQuestion.id">
								<div v-for="(item, index) in userAnswers.composite[currentQuestion.id].ordering"
									:key="item.id" class="lh-ordering-item" :data-id="item.id">
									<div class="lh-ordering-handle">
										<span class="lh-ordering-number">{{ index + 1 }}</span>
										<span class="lh-drag-icon">⋮⋮</span>
									</div>
									<uc-latex-view class="lh-ordering-text" :content="item.text"
										:key="'option-' + currentQuestion.id + '-' + item.id" />
								</div>
							</div>
						</div>

						<!-- Fill in blank trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_FILL_IN_BLANK'" class="lh-fill-blank">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion.id" />
							<div class="lh-fill-container">
								<template v-for="(part, index) in currentQuestion.content.parts" :key="index">
									<!-- SỬA: dùng v-html cho text có MathML -->
									<uc-latex-view v-if="part.type === 'text'" class="lh-fill-text"
										:content="part.value" />
									<div v-if="part.type === 'blank'" class="lh-fill-input-wrapper">
										<input type="text"
											v-model="userAnswers.composite[currentQuestion.id].fillInTheBlank[part.id]"
											class="lh-fill-input"
											:style="{ width: Math.max((part.size || 10) * 12, 80) + 'px' }"
											:placeholder="'___'">
									</div>
								</template>
							</div>
						</div>

						<!-- Matching trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_MATCHING'" class="lh-matching">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt || 'Nối các mục ở cột A với cột B cho phù hợp:'"
								:key="'prompt-' + currentQuestion.id" />
							<div class="lh-matching-container">
								<div class="lh-matching-column lh-column-a">
									<div class="lh-column-title">Cột A</div>
									<div
										v-for="itemA in currentQuestion.content.columnA"
										:key="itemA.id"
										class="lh-matching-pair-row"
										@click="handleCompositeMatchingRowClick(itemA.id)"
									>
										<div class="lh-matching-item-a">
											<uc-latex-view :content="itemA.text" />
										</div>
										<div class="lh-matching-dropzone" :data-item-a-id="itemA.id" :ref="'compositeMatchingDropzones_' + currentQuestion.id">
											<div v-if="getMatchedItemB(currentQuestion.id, itemA.id)"
												class="lh-matching-item-b lh-matched-item"
												:data-id="getMatchedItemB(currentQuestion.id, itemA.id).id"
												@click.stop="handleRemoveMatchedItemB(currentQuestion.id, itemA.id)"
												@pointerdown="startCompositeMatchingPointerDrag($event, getMatchedItemB(currentQuestion.id, itemA.id), currentQuestion.id)"
											>
												<span class="lh-drag-icon">⋮⋮</span>
												<uc-latex-view class="lh-matching-text" :content="getMatchedItemB(currentQuestion.id, itemA.id).text" />
												<span class="lh-remove-icon" title="Gỡ đáp án" @click.stop="handleRemoveMatchedItemB(currentQuestion.id, itemA.id)">✕</span>
											</div>
											<div v-else class="lh-dropzone-placeholder">Thả Cột B vào đây</div>
										</div>
									</div>
								</div>
								<div class="lh-matching-column lh-column-b">
									<div class="lh-column-title">Cột B</div>
									<div class="lh-matching-list" :ref="'compositeMatchingBContainer_' + currentQuestion.id">
										<div
											v-for="itemB in getUnmatchedItemsB(currentQuestion.id)"
											:key="itemB.id"
											class="lh-matching-item-b"
											:data-id="itemB.id"
											@click="selectCompositeItemB(itemB.id)"
											@pointerdown="startCompositeMatchingPointerDrag($event, itemB, currentQuestion.id)"
										>
											<span class="lh-drag-icon">⋮⋮</span>
											<uc-latex-view class="lh-matching-text" :content="itemB.text" />
										</div>
									</div>
									<div v-if="getCompositeRemainingBCount(currentQuestion.id) === 0" class="lh-column-b-empty">
										🎉 Đã ghép hết
									</div>
								</div>
							</div>
						</div>

						<!-- Categorize trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_DRAG_DROP_CATEGORIZE'" class="lh-categorize">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion.id" />

							<div class="lh-source-pool">
								<div class="lh-pool-title">
									<span class="lh-pool-icon">📦</span>
									<span>Kéo từ đây:</span>
								</div>
								<div class="lh-items-container" :ref="'sourceContainer_' + currentQuestion.id">
									<div v-for="item in userAnswers.composite[currentQuestion.id].unclassifiedItems"
										:key="item.id" class="lh-draggable-item" :data-id="item.id">
										<span class="lh-item-text">{{ item.text }}</span>
									</div>
								</div>
							</div>

							<div class="lh-categories-grid">
								<div v-for="category in currentQuestion.content.categories" :key="category.id"
									class="lh-category-box">
									<div class="lh-category-header">
										<img v-if="isImage(category.name)" :src="category.name" alt="Category"
											class="lh-category-image">
										<span v-else class="lh-category-name">{{ category.name }}</span>
									</div>
									<div class="lh-category-dropzone" :data-category-id="category.id"
										:ref="'categoryContainer_' + currentQuestion.id + '_' + category.id"
										:data-ref="'categoryContainer_' + currentQuestion.id + '_' + category.id">
										<div class="lh-dropzone-hint">Thả vào đây</div>
									</div>
								</div>
							</div>
						</div>

						<!-- TRUE_FALSE trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_TRUE_FALSE'" class="lh-single-choice">
							<!-- Prompt -->
							<uc-latex-view class="lh-question-prompt" :key="'prompt-' + currentQuestion.id"
								:content="currentQuestion.content.prompt" />
							<div class="lh-options-grid"
								style="grid-template-columns: repeat(auto-fit, minmax(700px, 1fr));">
								<label v-for="option in currentQuestion.content.options" :key="option.id"
									class="lh-option-card"
									:class="[getOptionClass(option.id), { 'lh-selected': getTrueFalseValue(option.id) !== undefined }]">

									<v-select placeholder="Đúng/Sai..."
										:items="[{title: '✅ Đúng', value: true}, {title: '❌ Sai', value: false}]"
										item-title='title' item-value='value'
										:model-value="getTrueFalseValue(option.id)"
										@update:modelValue="updateTrueFalseComposite(option, $event)"
										:bg-color="getTrueFalseBackgroundColor(option.id)" style="min-width:150px" />

									<div class="lh-option-content">
										<!-- Option text -->
										<uc-latex-view class="lh-option-text"
											:key="'option-' + currentQuestion.id + '-' + option.id"
											:content="option.text" />
									</div>
								</label>
							</div>
						</div>

						<!-- Connection (Nối đường thẳng) trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_CONNECTION'" class="lh-connection">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion.id" />

							<div class="lh-connection-instructions">
								<span class="lh-hint-icon">💡</span>
								<span>Bước 1: Chọn nhóm bên trái → Bước 2: Chọn mục bên phải để nối</span>
							</div>

							<div class="lh-connection-parent-container" :ref="'connectionParent_' + currentQuestion.id">
								<svg class="lh-connection-lines-svg" :ref="'svgContainer_' + currentQuestion.id"
									style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none;">
									<line v-for="(line, index) in getConnectionLines(currentQuestion.id)"
										:key="'line-' + index" :x1="line.x1" :y1="line.y1" :x2="line.x2" :y2="line.y2"
										:stroke="line.color" stroke-width="4" stroke-linecap="round"
										class="lh-connection-line" />
								</svg>

								<div class="lh-connection-container" :ref="'connectionContainer_' + currentQuestion.id">
									<div class="lh-connection-column lh-groups-column">
										<div class="lh-connection-header">
											<span class="lh-connection-icon">🏷️</span>
											<span>Nhóm</span>
										</div>
										<div class="lh-connection-items">
											<div v-for="group in currentQuestion.content.groups"
												:key="'group-' + group.id"
												:id="'connect-' + currentQuestion.id + '-group-' + group.id"
												class="lh-connection-item lh-connection-group"
												:class="getCompositeGroupClass(currentQuestion.id, group.id)"
												:style="{ backgroundColor: getCompositeGroupColor(currentQuestion.id, group.id) }"
												@click="selectCompositeGroup(currentQuestion.id, group.id)">
												<div class="lh-group-content">
													<span class="lh-group-text">{{ group.text }}</span>
													<span
														v-if="getCompositeActiveGroup(currentQuestion.id) === group.id"
														class="lh-active-indicator">👆</span>
												</div>
											</div>
										</div>
									</div>

									<div class="lh-connection-column lh-items-column">
										<div class="lh-connection-header">
											<span class="lh-connection-icon">📝</span>
											<span>Mục</span>
										</div>
										<div class="lh-connection-items">
											<div v-for="item in currentQuestion.content.items" :key="'item-' + item.id"
												:id="'connect-' + currentQuestion.id + '-item-' + item.id"
												class="lh-connection-item lh-connection-item-target"
												:class="getCompositeItemClass(currentQuestion.id, item.id)"
												@click="selectCompositeItem(currentQuestion.id, item.id)">
												<div class="lh-item-content">
													<span class="lh-item-text">{{ item.text }}</span>
													<span
														v-if="getCompositeConnectionForItem(currentQuestion.id, item.id)"
														class="lh-connected-indicator">🔗</span>
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>

							<div v-if="getCompositeActiveGroup(currentQuestion.id)" class="lh-connection-status">
								<span class="lh-status-icon">👉</span>
								<span>Đã chọn nhóm: <strong>{{ getCompositeGroupText(currentQuestion.id,
										getCompositeActiveGroup(currentQuestion.id)) }}</strong>
									- Giờ hãy chọn mục để nối!</span>
							</div>
						</div>

						<!-- Bottom Navigation Controls (Bấm chuyển câu tiện lợi ngay dưới đáp án) -->
						<div class="lh-bottom-nav-controls d-flex ga-2 mt-4 pt-3 border-t">
							<button class="lh-btn lh-btn-secondary flex-grow-1 py-2" :disabled="currentQuestionGlobalIndex === 0"
								@click="previousQuestion">
								<span class="lh-btn-icon">⬅️</span>
								<span>Câu trước</span>
							</button>
							<button class="lh-btn lh-btn-primary flex-grow-1 py-2"
								:disabled="currentQuestionGlobalIndex === allQuestions.length - 1" @click="nextQuestion">
								<span>Câu tiếp</span>
								<span class="lh-btn-icon">➡️</span>
							</button>
						</div>

					</div>
				</div>
			</div>

			<!-- Navigation Panel -->
			<div class="lh-quiz-sidebar">
				<div class="lh-sidebar-content">

					<!-- Timer -->
					<div v-if="!slideData?.content?.isInteractiveMode" class="lh-timer-card">
						<div class="lh-timer-icon">⏰</div>
						<div class="lh-timer-time">{{ formatTime(timeLeft) }}</div>
						<div class="lh-timer-label">Thời gian còn lại</div>
					</div>

					<!-- Progress -->
					<div class="lh-progress-card">
						<div class="lh-progress-header">
							<span class="lh-progress-icon">📊</span>
							<span class="lh-progress-title">Tiến độ</span>
						</div>
						<div class="lh-progress-stats">
							<span class="lh-progress-number">{{ getCompletedCount() }}/{{ totalQuestions }}</span>
							<span class="lh-progress-text">đã làm</span>
						</div>
						<div class="lh-progress-bar">
							<div class="lh-progress-fill" :style="{ width: getProgressPercentage() + '%' }"></div>
						</div>
						<div v-if="!slideData?.content?.isInteractiveMode" class="lh-progress-stars">
							<span v-for="n in 5" :key="n" class="lh-star"
								:class="{ 'lh-star-filled': n <= Math.ceil(getProgressPercentage() / 20) }">⭐</span>
						</div>
					</div>

					<!-- Question Grid với Groups -->
					<div class="lh-questions-grid">
						<div class="lh-grid-title">
							<span class="lh-grid-icon">📝</span>
							<span>Danh sách câu hỏi</span>
						</div>

						<!-- Hiển thị có groups -->
						<div v-if="slideData.content.hasGroups" class="lh-groups-container">
							<div v-for="(group, groupIndex) in slideData.content.groups" :key="group.id"
								class="lh-group-section">
								<div class="lh-group-header">
									<span class="lh-group-title">{{ group.title }}</span>
									<span class="lh-group-info">{{ group.questions.length }} câu - {{ group.points }}
										điểm</span>
									<div v-if="group.timeLimit" class="lh-group-timer">
										⏱️ {{ Math.floor(group.timeLimit / 60) }}p
									</div>
									<div class="lh-group-progress" :style="{ width: getGroupProgress(group) + '%' }">
									</div>
								</div>
								<div class="lh-group-questions">
									<button v-for="(q, qIndex) in group.questions" :key="q.id" class="lh-question-btn"
										:class="getQuestionButtonClass(getGlobalIndex(groupIndex, qIndex), q.id)"
										@click="navigateToQuestion(getGlobalIndex(groupIndex, qIndex))">
										<span class="lh-question-btn-number">{{ getGlobalIndex(groupIndex, qIndex) + 1
											}}</span>
										<span v-if="isQuestionCompleted(q.id)" class="lh-question-btn-check">✓</span>
									</button>
								</div>
							</div>
						</div>

						<!-- Hiển thị danh sách câu hỏi -->
						<div v-else class="lh-grid-container">
							<button v-for="(q, index) in allQuestions" :key="q.id"
								class="lh-question-btn" :class="getQuestionButtonClass(index, q.id)"
								@click="navigateToQuestion(index)">
								<span class="lh-question-btn-number">{{ index + 1 }}</span>
								<span v-if="isQuestionCompleted(q.id)" class="lh-question-btn-check">✓</span>
							</button>
						</div>
					</div>

					<!-- Submit Button (Unique single button) -->
					<div class="lh-submit-section mt-3">
						<button class="lh-btn lh-btn-success lh-btn-large w-100" @click="submitTest">
							<span class="lh-btn-icon">🏁</span>
							<span>NỘP BÀI</span>
						</button>
					</div>

				</div>
			</div>
		</div>

		<!-- 🏆 Màn hình Kết quả -->
		<div v-else-if="quizState === 'result'" class="lh-quiz-result"
			:class="{ 'lh-result-passed': testResult.passed, 'lh-result-failed': !testResult.passed }">
			<div class="lh-result-hero">
				<div class="lh-result-icon">{{ testResult.passed ? '🎉' : '💪' }}</div>
				<h1 class="lh-result-title">{{ testResult.passed ? 'Xuất sắc!' : 'Cố gắng lên!' }}</h1>
				<p class="lh-result-subtitle">{{ testResult.passed ? 'Em đã hoàn thành bài kiểm tra!' : 'Hãy ôn tập và
					thử lại nhé!' }}</p>
			</div>

			<div class="lh-result-score">
				<div class="lh-score-circle">
					<div class="lh-score-number">{{ testResult.score }}</div>
					<div class="lh-score-total">/{{ testResult.totalPoints }}</div>
				</div>
				<div class="lh-score-percentage">{{ testResult.percentage }}%</div>
				<div class="lh-score-stars">
					<span v-for="n in 5" :key="n" class="lh-star"
						:class="{ 'lh-star-filled': n <= Math.ceil(testResult.percentage / 20) }">⭐</span>
				</div>
			</div>

			<!-- Groups Result Detail (nếu có) -->
			<div v-if="slideData.content.hasGroups" class="lh-groups-result">
				<h3 class="lh-result-groups-title">Kết quả chi tiết theo phần:</h3>
				<div class="lh-result-groups-grid">
					<div v-for="(group, index) in slideData.content.groups" :key="group.id"
						class="lh-result-group-card">
						<div class="lh-result-group-header">
							<span class="lh-result-group-name">{{ group.title }}</span>
							<span class="lh-result-group-score">{{ getGroupScore(group) }}/{{ group.points }}</span>
						</div>
						<div class="lh-result-group-progress">
							<div class="lh-result-progress-bar">
								<div class="lh-result-progress-fill"
									:style="{ width: (getGroupScore(group) / group.points * 100) + '%' }"></div>
							</div>
							<span class="lh-result-group-percentage">{{ Math.round(getGroupScore(group) / group.points *
								100) }}%</span>
						</div>
						<div class="lh-result-group-stats">
							<span>{{ getGroupCompletedCount(group) }}/{{ group.questions.length }} câu đúng</span>
						</div>
					</div>
				</div>
			</div>

			<div class="lh-result-actions">
				<button class="lh-btn lh-btn-primary lh-btn-large" @click="reviewTest">
					<span class="lh-btn-icon">🔍</span>
					<span>Xem lại bài làm</span>
				</button>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-quiz-composite',
		props: {
			slideData: { type: Object, required: true }
		},
		emits: ['quiz-completed'],
	
		data() {
			return {
				// Quiz states
				selectedCompositeBId: null,
				activeDragItemB: null,
				quizState: 'start', // 'start', 'doing', 'result'
				currentQuestionIndex: 0,
				timer: null,
				timeLeft: 0,
				testResult: { score: 0, passed: false },
	
				// User answers for composite quiz
				userAnswers: {
					composite: {}
				},
	
				// Sortable instances management
				sortableInstances: [],
	
				// Fullscreen states
				isQuizFullscreen: false,
				fullscreenContainer: null,
				originalParent: null,
				originalNextSibling: null,
	
				// Connection quiz specific data
				compositeGroupColors: {},
				compositeLines: {},
	
				// Question type labels for display
				questionTypeLabels: {
					'QUIZ_SINGLE_CHOICE': '🎯 Chọn một đáp án',
					'QUIZ_MULTIPLE_CHOICE': '☑️ Chọn nhiều đáp án',
					'QUIZ_FILL_IN_BLANK': '✏️ Điền vào chỗ trống',
					'QUIZ_ORDERING': '📝 Sắp xếp thứ tự',
					'QUIZ_MATCHING': '🔗 Ghép nối',
					'QUIZ_DRAG_DROP_CATEGORIZE': '📦 Phân loại',
					'QUIZ_CONNECTION': '🔗 Nối đường thẳng',
					'QUIZ_COMPOSITE': '📝 Nhiều câu hỏi',
					'QUIZ_TRUE_FALSE': '🎯 Chọn đáp án đúng sai',
				}
			}
		},
	
		computed: {
			// Tính tổng điểm của composite quiz
			totalPoints() {
				if (this.slideData.content.hasGroups) {
					return this.slideData.content.groups.reduce((total, group) => total + group.points, 0);
				} else {
					return this.slideData.content.questions.reduce((total, q) => total + (q.points || 1), 0);
				}
			},
	
			// Tính tổng số câu hỏi
			totalQuestions() {
				if (this.slideData.content.hasGroups) {
					return this.slideData.content.groups.reduce((total, group) => total + group.questions.length, 0);
				} else {
					return this.slideData.content.questions.length;
				}
			},
	
			// Lấy tất cả questions từ groups hoặc direct questions với ID duy nhất
			allQuestions() {
				let list = [];
				if (this.slideData?.content?.hasGroups) {
					(this.slideData.content.groups || []).forEach(group => {
						list = list.concat(group.questions || []);
					});
				} else {
					list = this.slideData?.content?.questions || [];
				}
				return list.map((q, idx) => {
					const uniqueId = q.id ? String(q.id) : ('q_' + idx);
					return Object.assign({}, q, { id: uniqueId });
				});
			},
	
			// Lấy question hiện tại
			currentQuestion() {
				if (this.quizState === 'doing') {
					const questions = this.allQuestions;
					return questions[this.currentQuestionIndex];
				}
				return null;
			},
	
			// Lấy group hiện tại của question đang làm
			currentGroup() {
				if (this.slideData.content.hasGroups && this.currentQuestion) {
					return this.slideData.content.groups.find(group =>
						group.questions.some(q => q.id === this.currentQuestion.id)
					);
				}
				return null;
			},
	
			// Lấy index của question trong tất cả questions
			currentQuestionGlobalIndex() {
				return this.currentQuestionIndex || 0;
			}
		},
	
		watch: {
	
			slideData: {
				handler(newSlide) {
					if (newSlide) {
						this.initializeQuiz();
					}
				},
				immediate: true,
				deep: false
			},
	
			userAnswers: {
				handler(newAnswers) {
					// Redraw connection lines for current question if it's connection type
					if (this.currentQuestion?.type === 'QUIZ_CONNECTION') {
						Vue.nextTick(() => {
							setTimeout(() => {
								this.drawCompositeConnectionLines(this.currentQuestion.id);
							}, 100);
						});
					}
				},
				deep: true
			}
		},
	
		methods: {
			stripP(text) {
				if (!text) return '';
				return String(text).replace(/<\/?p>/gi, '').trim();
			},

			getMatchedItemB(questionId, itemAId) {
				if (!questionId || !this.userAnswers?.composite[questionId]) return null;
				const slots = this.userAnswers.composite[questionId].matchingSlots;
				if (!slots) return null;
				const itemBId = slots[String(itemAId)];
				if (!itemBId) return null;

				const question = this.allQuestions.find(q => String(q.id) === String(questionId));
				const columnB = question?.content?.columnB || [];
				return columnB.find(b => String(b.id) === String(itemBId)) || null;
			},

			getUnmatchedItemsB(questionId) {
				if (!questionId || !this.userAnswers?.composite[questionId]) return [];
				const question = this.allQuestions.find(q => String(q.id) === String(questionId));
				const columnB = question?.content?.columnB || [];
				const slots = this.userAnswers.composite[questionId].matchingSlots || {};
				const matchedBIds = new Set(Object.values(slots).map(String));

				const initialBList = this.userAnswers.composite[questionId].matching || columnB;
				return initialBList.filter(b => !matchedBIds.has(String(b.id)));
			},

			getCompositeRemainingBCount(questionId) {
				return this.getUnmatchedItemsB(questionId).length;
			},

			selectCompositeItemB(itemBId) {
				if (this.selectedCompositeBId === itemBId) {
					this.selectedCompositeBId = null;
				} else {
					this.selectedCompositeBId = itemBId;
				}
			},

			setProp(obj, key, val) {
				if (!obj) return;
				if (typeof this.$set === 'function') {
					this.$set(obj, key, val);
				} else {
					obj[key] = val;
				}
			},

			deleteProp(obj, key) {
				if (!obj) return;
				if (typeof this.$delete === 'function') {
					this.$delete(obj, key);
				} else {
					delete obj[key];
				}
			},

			handleRemoveMatchedItemB(questionId, itemAId) {
				if (!questionId || !itemAId) return;
				const slots = this.userAnswers?.composite[questionId]?.matchingSlots;
				if (slots && slots[String(itemAId)]) {
					this.deleteProp(slots, String(itemAId));
					this.selectedCompositeBId = null;
					this.playSound('navigate');
					this.$forceUpdate();
				}
			},

			handleCompositeMatchingRowClick(itemAId) {
				const questionId = this.currentQuestion?.id;
				if (!questionId) return;

				if (this.selectedCompositeBId) {
					this.assignCompositeMatchingPair(questionId, itemAId, this.selectedCompositeBId);
					this.selectedCompositeBId = null;
					return;
				}

				this.handleRemoveMatchedItemB(questionId, itemAId);
			},

			assignCompositeMatchingPair(questionId, itemAId, itemBId) {
				if (!this.userAnswers?.composite[questionId]) return;
				if (!this.userAnswers.composite[questionId].matchingSlots) {
					this.setProp(this.userAnswers.composite[questionId], 'matchingSlots', {});
				}

				const slots = this.userAnswers.composite[questionId].matchingSlots;
				const existingAId = Object.keys(slots).find(aId => String(slots[aId]) === String(itemBId));
				const targetOldBId = slots[String(itemAId)];

				if (existingAId && targetOldBId && String(existingAId) !== String(itemAId)) {
					// SWAP: Move itemBId to itemAId, move targetOldBId to existingAId
					this.setProp(slots, String(existingAId), String(targetOldBId));
					this.setProp(slots, String(itemAId), String(itemBId));
				} else if (existingAId && String(existingAId) !== String(itemAId)) {
					// Move itemBId from existingAId to target itemAId
					this.deleteProp(slots, String(existingAId));
					this.setProp(slots, String(itemAId), String(itemBId));
				} else {
					this.setProp(slots, String(itemAId), String(itemBId));
				}

				this.playSound('drop');
				this.$forceUpdate();
			},

			restoreCompositeMatchingDOM(questionId) {
				// Purely reactive rendering handles matching DOM state
				this.$forceUpdate();
			},

			isMatchingPair(itemA, itemB, correctPairs, columnA, columnB) {
				if (!itemA || !itemB) return false;
				const itemA_Id = String(itemA.id || '');
				const itemB_Id = String(itemB.id || '');

				// 1. Check correctPairs array
				if (correctPairs && Array.isArray(correctPairs) && correctPairs.length > 0) {
					const pair = correctPairs.find(p => {
						const pLeft = String(p.from !== undefined ? p.from : (p.id !== undefined ? p.id : (p.itemAId !== undefined ? p.itemAId : (p.leftId !== undefined ? p.leftId : ''))));
						return pLeft === itemA_Id;
					});
					if (pair) {
						const expectedB = String(pair.to !== undefined ? pair.to : (pair.itemBId !== undefined ? pair.itemBId : (pair.correctBId !== undefined ? pair.correctBId : (pair.rightId !== undefined ? pair.rightId : ''))));
						if (expectedB === itemB_Id) return true;
					}
				}

				// 2. Check itemA properties: correctBId, to, targetId
				if (itemA.correctBId !== undefined && itemA.correctBId !== null) {
					if (String(itemA.correctBId) === itemB_Id) return true;
				}
				if (itemA.to !== undefined && itemA.to !== null) {
					if (String(itemA.to) === itemB_Id) return true;
				}
				if (itemA.targetId !== undefined && itemA.targetId !== null) {
					if (String(itemA.targetId) === itemB_Id) return true;
				}

				// 3. Check pairId matching
				if (itemA.pairId !== undefined && itemA.pairId !== null) {
					if (String(itemA.pairId) === String(itemB.pairId || itemB.id)) return true;
				}
				if (itemB.pairId !== undefined && itemB.pairId !== null) {
					if (String(itemB.pairId) === itemA_Id) return true;
				}

				// 4. Fallback: ID matching
				if (itemA_Id && itemB_Id && itemA_Id === itemB_Id) return true;

				// 5. Fallback: Trailing number matching in text (e.g. "Mục A1" <-> "Mục B1")
				const textA = (itemA.text || itemA.title || '').toString();
				const textB = (itemB.text || itemB.title || '').toString();
				const numA = textA.match(/\d+/);
				const numB = textB.match(/\d+/);
				if (numA && numB && numA[0] === numB[0]) return true;

				return false;
			},

			startCompositeMatchingPointerDrag(event, itemB, questionId) {
				if (!itemB) return;
				if (event.cancelable) event.preventDefault();

				// Destroy any stale avatar elements left in body
				const staleAvatars = document.querySelectorAll('#composite-matching-drag-avatar, #matching-drag-avatar');
				staleAvatars.forEach(a => a.remove());

				const pointer = event.touches ? event.touches[0] : event;
				const itemEl = event.currentTarget || event.target.closest('.lh-matching-item-b');
				if (!itemEl) return;

				this.activeDragItemB = itemB;
				this.activeDragEl = itemEl;

				const rect = itemEl.getBoundingClientRect();
				const avatar = itemEl.cloneNode(true);
				avatar.id = 'composite-matching-drag-avatar';
				avatar.className = 'lh-drag-avatar-clone';
				avatar.style.position = 'fixed';
				avatar.style.left = (pointer.clientX - rect.width / 2) + 'px';
				avatar.style.top = (pointer.clientY - rect.height / 2) + 'px';
				avatar.style.width = Math.min(rect.width, 240) + 'px';
				avatar.style.maxWidth = '240px';
				avatar.style.height = rect.height + 'px';
				avatar.style.zIndex = '9999999';
				avatar.style.pointerEvents = 'none';
				avatar.style.boxShadow = '0 12px 28px rgba(0,0,0,0.3)';
				avatar.style.transform = 'scale(1.05) rotate(2deg)';
				avatar.style.opacity = '0.92';
				avatar.style.transition = 'none';
				avatar.style.border = '2px solid #10b981';
				avatar.style.background = '#ffffff';
				avatar.style.borderRadius = '10px';
				avatar.style.touchAction = 'none';

				document.body.appendChild(avatar);
				this.dragAvatarEl = avatar;

				// Hide source element during drag
				itemEl.style.visibility = 'hidden';

				const bContainerRef = 'compositeMatchingBContainer_' + questionId;

				const onPointerMove = (e) => {
					if (e.cancelable) e.preventDefault();
					const p = e.touches ? e.touches[0] : e;
					if (this.dragAvatarEl) {
						this.dragAvatarEl.style.left = (p.clientX - rect.width / 2) + 'px';
						this.dragAvatarEl.style.top = (p.clientY - rect.height / 2) + 'px';
					}

					const elemBelow = document.elementFromPoint(p.clientX, p.clientY);
					const dropzones = Array.from(document.querySelectorAll('.lh-matching-dropzone'));
					dropzones.forEach(d => d.classList.remove('lh-dropzone-hover'));

					if (elemBelow) {
						const dz = elemBelow.closest('.lh-matching-dropzone') || elemBelow.closest('.lh-matching-pair-row');
						if (dz) {
							const targetDz = dz.classList.contains('lh-matching-dropzone') ? dz : dz.querySelector('.lh-matching-dropzone');
							if (targetDz) targetDz.classList.add('lh-dropzone-hover');
						}
					}
				};

				const onPointerUp = (e) => {
					window.removeEventListener('mousemove', onPointerMove);
					window.removeEventListener('mouseup', onPointerUp);
					window.removeEventListener('pointermove', onPointerMove);
					window.removeEventListener('pointerup', onPointerUp);
					window.removeEventListener('touchmove', onPointerMove);
					window.removeEventListener('touchend', onPointerUp);
					window.removeEventListener('touchcancel', onPointerUp);

					// Remove avatar BEFORE detecting element below to prevent raycast collision
					const allAvatars = document.querySelectorAll('#composite-matching-drag-avatar, #matching-drag-avatar');
					allAvatars.forEach(a => a.remove());
					this.dragAvatarEl = null;

					const p = e.changedTouches ? e.changedTouches[0] : (e.touches ? e.touches[0] : e);
					const elemBelow = document.elementFromPoint(p.clientX, p.clientY);

					if (this.activeDragEl) {
						this.activeDragEl.style.visibility = 'visible';
						this.activeDragEl.style.display = '';
						this.activeDragEl.style.opacity = '1';
					}

					const dropzones = Array.from(document.querySelectorAll('.lh-matching-dropzone'));
					dropzones.forEach(d => d.classList.remove('lh-dropzone-hover'));

					if (elemBelow) {
						const dz = elemBelow.closest('.lh-matching-dropzone') || elemBelow.closest('.lh-matching-pair-row');
						if (dz) {
							const targetDz = dz.classList.contains('lh-matching-dropzone') ? dz : dz.querySelector('.lh-matching-dropzone');
							if (targetDz) {
								const itemA_Id = targetDz.dataset.itemAId;
								this.assignCompositeMatchingPair(questionId, itemA_Id, itemB.id);
								this.playSound('drop');
								this.activeDragItemB = null;
								this.activeDragEl = null;
								this.$forceUpdate();
								return;
							}
						}
					}

					// Dropped outside any dropzone -> If itemB was previously placed, remove it back to Column B!
					const slots = this.userAnswers?.composite[questionId]?.matchingSlots;
					if (slots) {
						const placedAId = Object.keys(slots).find(aId => String(slots[aId]) === String(itemB.id));
						if (placedAId) {
							this.deleteProp(slots, String(placedAId));
							this.playSound('navigate');
						}
					}

					this.activeDragItemB = null;
					this.activeDragEl = null;
					this.$forceUpdate();
				};

				window.addEventListener('mousemove', onPointerMove, { passive: false });
				window.addEventListener('mouseup', onPointerUp, { passive: false });
				window.addEventListener('pointermove', onPointerMove, { passive: false });
				window.addEventListener('pointerup', onPointerUp, { passive: false });
				window.addEventListener('touchmove', onPointerMove, { passive: false });
				window.addEventListener('touchend', onPointerUp, { passive: false });
				window.addEventListener('touchcancel', onPointerUp, { passive: false });
			},
			// ==================== QUIZ LIFECYCLE METHODS ====================
			initializeQuiz() {
				// Initialize quiz state
				const isInteractive = !this.slideData?.content?.timeLimit || !!this.slideData?.content?.isInteractiveMode;
				this.quizState = isInteractive ? 'doing' : 'start';
				this.currentQuestionIndex = 0;
				this.timeLeft = this.slideData.content.timeLimit || 3600;
				this.userAnswers = { composite: {} };
				this.compositeGroupColors = {};
				this.compositeLines = {};

				// Pre-initialize answers for all questions
				this.initializeCompositeAnswers();
	
				// Clear any existing timer
				if (this.timer) {
					clearInterval(this.timer);
					this.timer = null;
				}
			},
	
			startTest() {
				this.quizState = 'doing';
				this.timeLeft = this.slideData.content.timeLimit || 3600; // Default 1 hour
				this.currentQuestionIndex = 0;
	
				// Initialize answers for all questions
				this.initializeCompositeAnswers();
	
				// Initialize sortables for current question
				Vue.nextTick(() => {
					this.initCompositeSortables();
				});
	
				this.startTimer();
				this.playSound('start');
			},
	
			initializeCompositeAnswers() {
				const initialAnswers = {};
				const questions = this.allQuestions;
	
				questions.forEach(q => {
					if (q.type === 'QUIZ_SINGLE_CHOICE') {
						initialAnswers[q.id] = { singleChoice: null };
					} else if (q.type === 'QUIZ_MULTIPLE_CHOICE') {
						initialAnswers[q.id] = { multipleChoice: [] };
					} else if (q.type === 'QUIZ_ORDERING') {
						initialAnswers[q.id] = { ordering: this.shuffleArray([...q.content.items]) };
					} else if (q.type === 'QUIZ_FILL_IN_BLANK') {
						const fillInBlank = {};
						q.content.parts.forEach(part => {
							if (part.type === 'blank') {
								fillInBlank[part.id] = '';
							}
						});
						initialAnswers[q.id] = { fillInTheBlank: fillInBlank };
					} else if (q.type === 'QUIZ_MATCHING') {
						initialAnswers[q.id] = { matching: this.shuffleArray([...(q.content.columnB || [])]), matchingSlots: {} };
					} else if (q.type === 'QUIZ_DRAG_DROP_CATEGORIZE') {
						initialAnswers[q.id] = { unclassifiedItems: this.shuffleArray([...q.content.items]) };
					} else if (q.type === 'QUIZ_TRUE_FALSE') {
						initialAnswers[q.id] = { trueFalse: {} };
					} else if (q.type === 'QUIZ_CONNECTION') {
						initialAnswers[q.id] = {
							connection: {
								activeGroup: null,
								selections: []
							}
						};
						// Generate colors for this question's groups
						this.generateCompositeGroupColors(q.id, q.content.groups);
					}
				});
				this.userAnswers.composite = initialAnswers;
			},
	
			startTimer() {
				if (this.timer) clearInterval(this.timer);
				this.timer = setInterval(() => {
					if (this.timeLeft > 0) {
						this.timeLeft--;
					} else {
						clearInterval(this.timer);
						this.submitTest();
					}
				}, 1000);
			},
	
			formatTime(seconds) {
				const m = Math.floor(seconds / 60).toString().padStart(2, '0');
				const s = (seconds % 60).toString().padStart(2, '0');
				return `${m}:${s}`;
			},
	
			// ==================== CONNECTION QUIZ METHODS FOR COMPOSITE ====================
			generateCompositeGroupColors(questionId, groups) {
				const presetColors = [
					'#FF6B6B', '#4DD0E1', '#FFD93D',
					'#6BCB77', '#FF9F1C', '#C084FC',
					'#38BDF8', '#F472B6', '#FBBF24', '#34D399'
				];
	
				if (!this.compositeGroupColors[questionId]) {
					this.compositeGroupColors[questionId] = {};
				}
	
				let i = 0;
				groups.forEach(group => {
					this.compositeGroupColors[questionId][group.id] = presetColors[i % presetColors.length];
					i++;
				});
			},
	
			selectCompositeGroup(questionId, groupId) {
				if (!this.userAnswers.composite[questionId]) {
					this.userAnswers.composite[questionId] = {
						connection: { activeGroup: null, selections: [] }
					};
				}
				if (!this.userAnswers.composite[questionId].connection) {
					this.userAnswers.composite[questionId].connection = { activeGroup: null, selections: [] };
				}

				const connState = this.userAnswers.composite[questionId].connection;
				if (connState.activeGroup === groupId) {
					// Bấm lại nhóm đang chọn -> Bỏ chọn
					connState.activeGroup = null;
				} else {
					connState.activeGroup = groupId;
				}
				this.playSound('navigate');
			},

			selectCompositeItem(questionId, itemId) {
				if (!this.userAnswers.composite[questionId]) {
					this.userAnswers.composite[questionId] = {
						connection: { activeGroup: null, selections: [] }
					};
				}
				if (!this.userAnswers.composite[questionId].connection) {
					this.userAnswers.composite[questionId].connection = { activeGroup: null, selections: [] };
				}

				const connState = this.userAnswers.composite[questionId].connection;
				const activeGroup = connState.activeGroup;
				const existingSelIndex = connState.selections.findIndex(sel => sel.to === itemId);

				if (!activeGroup) {
					if (existingSelIndex !== -1) {
						// Khi chưa chọn Nhóm mà bấm vào Mục đã nối -> chọn lại Nhóm tương ứng
						connState.activeGroup = connState.selections[existingSelIndex].from;
						this.playSound('navigate');
					} else {
						this.showToast("Vui lòng chọn một Nhóm ở cột trái trước.", 'warning');
					}
					return;
				}

				if (existingSelIndex !== -1 && connState.selections[existingSelIndex].from === activeGroup) {
					// Bấm lại đúng cặp đã nối -> Hủy nối
					connState.selections.splice(existingSelIndex, 1);
					connState.activeGroup = null;
					this.playSound('navigate');
				} else {
					// Nối Nhóm đang chọn với Mục
					if (existingSelIndex !== -1) {
						connState.selections.splice(existingSelIndex, 1);
					}
					connState.selections.push({
						from: activeGroup,
						to: itemId
					});
					// Reset activeGroup về null sau khi nối xong để tránh bấm liên tục bị nối nhầm nhóm khác!
					connState.activeGroup = null;
					this.playSound('drop');
				}

				// Vẽ lại đường nối bằng requestAnimationFrame chống đơ/treo trang khi bấm nhanh
				this.drawCompositeConnectionLines(questionId);
			},

			drawCompositeConnectionLines(questionId) {
				if (!this.userAnswers.composite[questionId]?.connection?.selections?.length) {
					if (!this.compositeLines) this.compositeLines = {};
					this.compositeLines[questionId] = [];
					return;
				}

				this.$nextTick(() => {
					const parentEl = this.$refs['connectionParent_' + questionId];
					if (!parentEl) return;

					const parentRect = parentEl.getBoundingClientRect();
					if (!parentRect || parentRect.width === 0) return;

					const newLines = [];
					const selections = this.userAnswers.composite[questionId].connection.selections;

					selections.forEach(selection => {
						const fromEl = document.getElementById('connect-' + questionId + '-group-' + selection.from);
						const toEl = document.getElementById('connect-' + questionId + '-item-' + selection.to);

						if (fromEl && toEl) {
							const fromRect = fromEl.getBoundingClientRect();
							const toRect = toEl.getBoundingClientRect();

							const x1 = fromRect.right - parentRect.left;
							const y1 = fromRect.top + (fromRect.height / 2) - parentRect.top;
							const x2 = toRect.left - parentRect.left;
							const y2 = toRect.top + (toRect.height / 2) - parentRect.top;

							newLines.push({
								x1: Math.max(0, x1),
								y1: Math.max(0, y1),
								x2: Math.max(0, x2),
								y2: Math.max(0, y2),
								color: this.getCompositeGroupColor(questionId, selection.from)
							});
						}
					});

					if (!this.compositeLines) this.compositeLines = {};
					this.compositeLines[questionId] = newLines;
				});
			},
	
			getConnectionLines(questionId) {
				if (!this.compositeLines) this.compositeLines = {};
				return this.compositeLines[questionId] || [];
			},
	
			getCompositeActiveGroup(questionId) {
				return this.userAnswers.composite[questionId]?.connection?.activeGroup || null;
			},
	
			getCompositeGroupClass(questionId, groupId) {
				const isActive = this.getCompositeActiveGroup(questionId) === groupId;
				const hasConnection = this.userAnswers.composite[questionId]?.connection?.selections?.find(s => s.from === groupId);
				return {
					'lh-active': isActive,
					'lh-connected': hasConnection
				};
			},
	
			getCompositeItemClass(questionId, itemId) {
				const matches = this.userAnswers.composite[questionId]?.connection?.selections?.filter(s => s.to === itemId) || [];
				return matches.length > 0 ? 'lh-connected' : '';
			},

			getCompositeGroupColor(questionId, groupId) {
				return this.compositeGroupColors[questionId]?.[groupId] || '#4CAF50';
			},

			getCompositeConnectionForItem(questionId, itemId) {
				return this.userAnswers.composite[questionId]?.connection?.selections?.find(s => s.to === itemId);
			},

			getCompositeGroupText(questionId, groupId) {
				const question = this.allQuestions.find(q => q.id === questionId);
				const group = question?.content?.groups?.find(g => g.id === groupId);
				return group ? group.text : '';
			},

			navigateToQuestion(globalIndex) {
				// Save current sortable state before switching
				this.saveCurrentSortableState();
	
				// Clean up current sortables
				this.destroySortableInstances();
	
				this.currentQuestionIndex = globalIndex;
	
				// Initialize sortables for new question
				Vue.nextTick(() => {
					// Draw connection lines if it's connection type
					if (this.currentQuestion?.type === 'QUIZ_CONNECTION') {
						setTimeout(() => {
							this.drawCompositeConnectionLines(this.currentQuestion.id);
						}, 200);
					}
					if (this.currentQuestion?.type === 'QUIZ_MATCHING') {
						this.restoreCompositeMatchingDOM(this.currentQuestion.id);
					}
					this.initCompositeSortables();
				});
	
				this.playSound('navigate');
			},

			nextQuestion() {
				if (this.currentQuestionGlobalIndex < this.allQuestions.length - 1) {
					this.navigateToQuestion(this.currentQuestionGlobalIndex + 1);
				}
			},
	
			previousQuestion() {
				if (this.currentQuestionGlobalIndex > 0) {
					this.navigateToQuestion(this.currentQuestionGlobalIndex - 1);
				}
			},
	
			// ==================== PROGRESS TRACKING METHODS ====================
			getCompletedCount() {
				const questions = this.allQuestions;
				return questions.filter(question => {
					return this.isQuestionCompleted(question.id);
				}).length;
			},
	
			getProgressPercentage() {
				const totalQuestions = this.allQuestions.length;
				if (totalQuestions === 0) return 0;
				return Math.round((this.getCompletedCount() / totalQuestions) * 100);
			},
	
			isQuestionCompleted(questionId) {
				const answer = this.userAnswers.composite[questionId];
				if (!answer) return false;
	
				// Check specific answer types
				if (answer.singleChoice !== null && answer.singleChoice !== undefined) {
					return true;
				}
	
				if (answer.multipleChoice && Array.isArray(answer.multipleChoice) && answer.multipleChoice.length > 0) {
					return true;
				}
	
				if (answer.fillInTheBlank && typeof answer.fillInTheBlank === 'object') {
					const hasFilledBlanks = Object.values(answer.fillInTheBlank).some(val => val && val.toString().trim() !== '');
					return hasFilledBlanks;
				}
	
				if (answer.trueFalse && typeof answer.trueFalse === 'object') {
					const hasAnswered = Object.keys(answer.trueFalse).length > 0;
					return hasAnswered;
				}
	
				if (answer.connection && typeof answer.connection === 'object') {
					const hasConnections = answer.connection.selections && answer.connection.selections.length > 0;
					return hasConnections;
				}
	
				const allQuestions = this.allQuestions;
				const question = allQuestions.find(q => String(q.id) === String(questionId));
				if (question && question.type === 'QUIZ_MATCHING') {
					const totalA = question.content?.columnA?.length || 0;

					// 1. Check DOM dropzones
					const dropzoneRef = 'compositeMatchingDropzones_' + questionId;
					const dropzonesRef = this.$refs[dropzoneRef];
					const dropzones = dropzonesRef ? (Array.isArray(dropzonesRef) ? dropzonesRef : [dropzonesRef]) : Array.from(document.querySelectorAll('.lh-matching-dropzone'));
					const filledCount = dropzones.filter(dz => dz.querySelector('.lh-matching-item-b')).length;
					if (totalA > 0 && filledCount >= totalA) return true;

					// 2. Check matchingSlots state
					const slots = answer.matchingSlots || {};
					const count = Object.keys(slots).length;
					if (totalA > 0 && count >= totalA) return true;

					return false;
				}

				if (answer.unclassifiedItems !== undefined) {
					if (question && question.content.items) {
						const completed = answer.unclassifiedItems.length < question.content.items.length;
						return completed;
					}
				}
	
				return false;
			},

			getQuestionButtonClass(globalIndex, questionId) {
				const classes = ['lh-question-btn'];
				if (this.isQuestionCompleted(questionId)) {
					classes.push('lh-completed');
				} else {
					classes.push('lh-pending');
				}
				if (this.currentQuestionGlobalIndex === globalIndex) {
					classes.push('lh-current');
				}
				return classes;
			},

			getGlobalIndex(groupIndex, questionIndex) {
				let globalIndex = 0;
				for (let i = 0; i < groupIndex; i++) {
					globalIndex += this.slideData.content.groups[i].questions.length;
				}
				return globalIndex + questionIndex;
			},

			getGroupProgress(group) {
				const completedInGroup = group.questions.filter(q =>
					this.isQuestionCompleted(q.id)).length;
				return Math.round((completedInGroup / group.questions.length) * 100);
			},

			getGroupScore(group) {
				let score = 0;
				group.questions.forEach(question => {
					if (this.checkQuestionAnswer(question)) {
						score += question.points || 1;
					}
				});
				return score;
			},

			getGroupCompletedCount(group) {
				return group.questions.filter(question => this.checkQuestionAnswer(question)).length;
			},

			// ==================== SORTABLE METHODS ====================
			initCompositeSortables() {
				if (!this.currentQuestion) return;

				// Destroy existing instances first
				this.destroySortableInstances();

				if (this.currentQuestion.type === 'QUIZ_ORDERING') {
					this.initOrderingSortable(this.currentQuestion.id);
				} else if (this.currentQuestion.type === 'QUIZ_MATCHING') {
					this.restoreCompositeMatchingDOM(this.currentQuestion.id);
					this.initMatchingSortable(this.currentQuestion.id);
				} else if (this.currentQuestion.type === 'QUIZ_DRAG_DROP_CATEGORIZE') {
					this.initCategorizeSortable(this.currentQuestion.id);
				}
			},

			initOrderingSortable(questionId) {
				const refName = 'orderingContainer_' + questionId;
				const container = this.$refs[refName];
				if (container) {
					const instance = new Sortable(container, {
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						chosenClass: 'lh-sortable-chosen',
						dragClass: 'lh-sortable-drag',
						onEnd: () => this.playSound('drop')
					});
					this.sortableInstances.push(instance);
				}
			},
	
			initMatchingSortable(questionId) {
				// Purely reactive rendering and PointerDrag handle matching drag-and-drop without SortableJS conflicts
			},
	
			initCategorizeSortable(questionId) {
				// Source container
				const sourceRefName = 'sourceContainer_' + questionId;
				const sourceContainer = this.$refs[sourceRefName];
				if (sourceContainer) {
					const sourceInstance = new Sortable(sourceContainer, {
						group: 'categorize-group-' + questionId,
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						chosenClass: 'lh-sortable-chosen',
						dragClass: 'lh-sortable-drag',
						onEnd: () => this.playSound('drop')
					});
					this.sortableInstances.push(sourceInstance);
				}
	
				// Category containers
				if (this.currentQuestion.content.categories) {
					this.currentQuestion.content.categories.forEach(category => {
						const categoryRefName = 'categoryContainer_' + questionId + '_' + category.id;
						const categoryContainer = this.$refs[categoryRefName];
						if (categoryContainer) {
							const categoryInstance = new Sortable(categoryContainer, {
								group: 'categorize-group-' + questionId,
								animation: 200,
								ghostClass: 'lh-sortable-ghost',
								chosenClass: 'lh-sortable-chosen',
								dragClass: 'lh-sortable-drag',
								onEnd: () => this.playSound('drop')
							});
							this.sortableInstances.push(categoryInstance);
						}
					});
				}
			},
	
			destroySortableInstances() {
				this.sortableInstances.forEach(instance => {
					try {
						instance.destroy();
					} catch (e) {
						console.warn('Error destroying sortable instance:', e);
					}
				});
				this.sortableInstances = [];
			},
	
			saveCurrentSortableState() {
				if (!this.currentQuestion) return;
	
				const questionId = this.currentQuestion.id;
	
				if (this.currentQuestion.type === 'QUIZ_ORDERING') {
					const refName = 'orderingContainer_' + questionId;
					const container = this.$refs[refName];
					if (container) {
						const orderedItems = Array.from(container.children).map(el => {
							const itemId = el.dataset.id;
							return this.userAnswers.composite[questionId].ordering.find(item => item.id === itemId);
						}).filter(Boolean);
						this.userAnswers.composite[questionId].ordering = orderedItems;
					}
				} else if (this.currentQuestion.type === 'QUIZ_MATCHING') {
					if (!this.userAnswers.composite[questionId]) return;
					if (!this.userAnswers.composite[questionId].matchingSlots) {
						this.setProp(this.userAnswers.composite[questionId], 'matchingSlots', {});
					}
					const dropzones = Array.from(document.querySelectorAll('.lh-matching-dropzone'));
					dropzones.forEach(dz => {
						const itemAId = dz.dataset.itemAId;
						const itemBEl = dz.querySelector('.lh-matching-item-b');
						if (itemAId && itemBEl && itemBEl.dataset.id) {
							this.setProp(this.userAnswers.composite[questionId].matchingSlots, String(itemAId), String(itemBEl.dataset.id));
						}
					});
				}
			},
	
			// ==================== SUBMISSION & SCORING METHODS ====================
			submitTest() {
				if (this.timer) clearInterval(this.timer);

				// Save current state
				this.saveCurrentSortableState();

				// Calculate score
				let score = 0;
				const questions = this.allQuestions;

				questions.forEach(question => {
					if (this.checkQuestionAnswer(question)) {
						score += question.points || 1;
					}
				});

				const totalPoints = this.totalPoints || questions.length || 1;
				const isAllCorrect = (score >= questions.length);

				this.testResult = {
					score: score,
					totalPoints: totalPoints,
					passed: isAllCorrect,
					isCorrect: isAllCorrect,
					result: isAllCorrect,
					percentage: Math.round((score / totalPoints) * 100)
				};

				if (isAllCorrect) {
					this.showToast("🎉 Tuyệt vời! Em đã hoàn thành đúng tất cả các câu hỏi!", "success");
				} else {
					this.showToast("😅 Chưa đúng hết các câu hỏi. Em hãy kiểm tra lại nhé!", "warning");
				}

				this.playSound(isAllCorrect ? 'success' : 'try-again');

				// Emit result to parent
				this.$emit('quiz-result', {
					isCorrect: isAllCorrect,
					result: isAllCorrect,
					passed: isAllCorrect,
					slideId: this.slideData?.id
				});
				this.$emit('quiz-completed', this.testResult);
			},
	
			reviewTest() {
				this.quizState = 'doing';
				this.currentQuestionIndex = 0;
			},
	
			checkQuestionAnswer(question) {
				const userAnswer = this.userAnswers.composite[question.id];
				if (!userAnswer) return false;

				switch (question.type) {
					case 'QUIZ_SINGLE_CHOICE':
						const userChoice = String(userAnswer.singleChoice);
						const correctChoice = String(question.content.correctAnswer);
						return userChoice === correctChoice;
	
					case 'QUIZ_MULTIPLE_CHOICE':
						const correctAnswers = (question.content.correctAnswers || []).map(String).sort();
						const userAnswers = (userAnswer.multipleChoice || []).map(String).sort();
						return JSON.stringify(userAnswers) === JSON.stringify(correctAnswers);

					case 'QUIZ_MATCHING':
						const columnA_Items = question.content?.columnA || [];
						const columnB_Items = question.content?.columnB || [];
						const correctPairs = question.content?.pairs || question.content?.correctPairs || [];

						if (columnA_Items.length === 0) return false;

						const slots = userAnswer.matchingSlots || {};
						const dropzoneRef = 'compositeMatchingDropzones_' + question.id;
						const dropzonesRef = this.$refs[dropzoneRef];
						let matchCorrect = true;

						for (let i = 0; i < columnA_Items.length; i++) {
							const itemA = columnA_Items[i];
							let assignedBId = slots[String(itemA.id)];

							if (!assignedBId && dropzonesRef) {
								const dropzones = Array.isArray(dropzonesRef) ? dropzonesRef : [dropzonesRef];
								const dz = dropzones.find(d => String(d.dataset.itemAId) === String(itemA.id));
								if (dz) {
									const itemBEl = Array.from(dz.children).find(c => c.classList.contains('lh-matching-item-b'));
									if (itemBEl) assignedBId = itemBEl.dataset.id;
								}
							}

							if (!assignedBId) {
								matchCorrect = false;
								break;
							}

							const itemB = columnB_Items.find(b => String(b.id) === String(assignedBId));
							if (!itemB || !this.isMatchingPair(itemA, itemB, correctPairs, columnA_Items, columnB_Items)) {
								matchCorrect = false;
								break;
							}
						}
						return matchCorrect;
	
					case 'QUIZ_FILL_IN_BLANK':
						let allCorrect = true;
						question.content.parts.forEach(part => {
							if (part.type === 'blank') {
								const userAns = (userAnswer.fillInTheBlank[part.id] || '').toLowerCase().trim();
								const correctAns = (part.correctAnswer || '').toLowerCase().trim();
								if (userAns !== correctAns) {
									allCorrect = false;
								}
							}
						});
						return allCorrect;
	
					case 'QUIZ_CONNECTION':
						let correctCount = 0;
						const userSelectionsMap = new Map(
							(userAnswer.connection?.selections || []).map(s => [String(s.to), String(s.from)])
						);
	
						question.content.items.forEach(item => {
							const userGroup = userSelectionsMap.get(String(item.id));
							const correctGroup = String(item.groupId);
							console.log(`Connection item ${item.id} - User group: ${userGroup}, Correct group: ${correctGroup}`);
							if (userGroup === correctGroup) {
								correctCount++;
							}
						});
						const isCorrect = correctCount === question.content.items.length;
						console.log('Connection - Correct count:', correctCount, 'Total items:', question.content.items.length, 'Result:', isCorrect);
						return isCorrect;
	
					case 'QUIZ_TRUE_FALSE':
					case 'QUIZ_TRUE_FALSE_LIST':
					case 'TRUE_FALSE':
					case 'MATCHING_TF': {
						const userTFMap = userAnswer.trueFalse || {};
						const options = question.content?.options || question.content?.items || [];
						if (!options || options.length === 0) return false;

						let allTFCorrect = true;
						for (const option of options) {
							const userChoice = userTFMap[option.id];
							if (userChoice === undefined || userChoice === null) {
								allTFCorrect = false;
								break;
							}

							let expectedValue = null;
							if (typeof option.isCorrect === 'boolean') {
								expectedValue = option.isCorrect;
							} else if (typeof option.correctAnswer === 'boolean') {
								expectedValue = option.correctAnswer;
							} else if (typeof option.isTrue === 'boolean') {
								expectedValue = option.isTrue;
							} else if (option.correctAnswer !== undefined && option.correctAnswer !== null) {
								const strAns = String(option.correctAnswer).trim().toLowerCase();
								expectedValue = (strAns === 'true' || strAns === '1' || strAns === 'đúng' || strAns === 'dung');
							} else if (option.isCorrect !== undefined && option.isCorrect !== null) {
								const strAns = String(option.isCorrect).trim().toLowerCase();
								expectedValue = (strAns === 'true' || strAns === '1' || strAns === 'đúng' || strAns === 'dung');
							} else if (option.answer !== undefined && option.answer !== null) {
								const strAns = String(option.answer).trim().toLowerCase();
								expectedValue = (strAns === 'true' || strAns === '1' || strAns === 'đúng' || strAns === 'dung');
							} else if (option.value !== undefined && option.value !== null) {
								const strAns = String(option.value).trim().toLowerCase();
								expectedValue = (strAns === 'true' || strAns === '1' || strAns === 'đúng' || strAns === 'dung');
							}

							if (expectedValue !== null && Boolean(userChoice) !== Boolean(expectedValue)) {
								allTFCorrect = false;
								break;
							}
						}
						return allTFCorrect;
					}

					// Add other question types here...
					default:
						return false;
				}
			},
	
			// ==================== TRUE/FALSE METHODS ====================
			updateTrueFalseComposite(option, val) {
				if (val !== null && val !== undefined) {
					if (this.currentQuestion) {
						if (!this.userAnswers.composite[this.currentQuestion.id]) {
							this.userAnswers.composite[this.currentQuestion.id] = { trueFalse: {} };
						}
						if (!this.userAnswers.composite[this.currentQuestion.id].trueFalse) {
							this.userAnswers.composite[this.currentQuestion.id].trueFalse = {};
						}
	
						this.userAnswers.composite[this.currentQuestion.id].trueFalse[option.id] = val;
					}
				}
			},
	
			getTrueFalseValue(optionId) {
				if (this.currentQuestion && this.userAnswers.composite[this.currentQuestion.id]?.trueFalse) {
					return this.userAnswers.composite[this.currentQuestion.id].trueFalse[optionId];
				}
				return undefined;
			},
	
			getTrueFalseBackgroundColor(optionId) {
				const value = this.getTrueFalseValue(optionId);
				if (value === true) return 'success';
				if (value === false) return 'error';
				return 'white';
			},
	
			// ==================== UTILITY METHODS ====================
			shuffleArray(array) {
				const newArray = [...array];
				for (let i = newArray.length - 1; i > 0; i--) {
					const j = Math.floor(Math.random() * (i + 1));
					[newArray[i], newArray[j]] = [newArray[j], newArray[i]];
				}
				return newArray;
			},
	
			getQuestionTypeLabel(type) {
				return this.questionTypeLabels[type] || type;
			},
	
			getOptionClass(optionId) {
				// Return empty for now in composite quiz
				return '';
			},
	
			isImage(value) {
				if (!value) return false;
				const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
				return /^https?:\/\//.test(value) && imageExtensions.some(ext => value.toLowerCase().endsWith(ext));
			},
	
			playSound(type) {
				const sounds = {
					start: '/_cdn/lhbs-lms/sounds/start.mp3',
					correct: '/_cdn/lhbs-lms/sounds/correct.mp3',
					wrong: '/_cdn/lhbs-lms/sounds/wrong.mp3',
					success: '/_cdn/lhbs-lms/sounds/success.mp3',
					'try-again': '/_cdn/lhbs-lms/sounds/try-again.mp3',
					navigate: '/_cdn/lhbs-lms/sounds/click.mp3',
					drop: '/_cdn/lhbs-lms/sounds/drop.mp3',
					'fullscreen-enter': '/_cdn/lhbs-lms/sounds/fullscreen-enter.mp3',
					'fullscreen-exit': '/_cdn/lhbs-lms/sounds/fullscreen-exit.mp3'
				};
	
				if (sounds[type]) {
					const audio = new Audio(sounds[type]);
					audio.volume = 0.3;
					audio.play().catch(() => { }); // Ignore audio errors
				}
			},
	
			showToast(message, type = 'info') {
				// Use Vue toast if available, otherwise fallback to console
				if (this.$toast) {
					this.$toast[type](message);
				} else if (Vue.$toast) {
					Vue.$toast[type](message);
				} else {
					// console.log(`[${type.toUpperCase()}] ${message}`);
				}
			},
	
			// ==================== FULLSCREEN METHODS ====================
			toggleQuizFullscreen() {
				if (this.isQuizFullscreen) {
					this.exitQuizFullscreen();
				} else {
					this.enterQuizFullscreen();
				}
			},
	
			enterQuizFullscreen() {
				const container = this.$el.querySelector('.lh-quiz-layout');
				if (!container) return;
	
				container.requestFullscreen().then(() => {
					this.isQuizFullscreen = true;
					document.addEventListener('keydown', this.handleFullscreenKeydown);
					this.playSound('fullscreen-enter');
				}).catch((err) => {
					console.error('Fullscreen failed:', err);
				});
			},
	
			exitQuizFullscreen() {
				if (document.fullscreenElement) {
					document.exitFullscreen();
					this.isQuizFullscreen = false;
					document.removeEventListener('keydown', this.handleFullscreenKeydown);
					this.playSound('fullscreen-exit');
				}
			},
	
			handleFullscreenKeydown(event) {
				if (event.key === 'Escape') {
					event.preventDefault();
					this.exitQuizFullscreen();
				}
			},
	
			addFullscreenOverlay() {
				const overlay = document.createElement('div');
				overlay.className = 'lh-fullscreen-overlay';
				overlay.id = 'lh-fullscreen-overlay';
				overlay.addEventListener('click', this.exitQuizFullscreen);
				document.body.appendChild(overlay);
			},
	
			removeFullscreenOverlay() {
				const overlay = document.getElementById('lh-fullscreen-overlay');
				if (overlay) {
					overlay.remove();
				}
			},
	
			announceFullscreen(message) {
				const announcer = document.createElement('div');
				announcer.setAttribute('aria-live', 'polite');
				announcer.setAttribute('aria-atomic', 'true');
				announcer.style.position = 'absolute';
				announcer.style.left = '-10000px';
				announcer.textContent = message;
	
				document.body.appendChild(announcer);
	
				setTimeout(() => {
					announcer.remove();
				}, 1000);
			},
	
			resetStates() {
				// Clear timer
				if (this.timer) {
					clearInterval(this.timer);
					this.timer = null;
				}
	
				// Destroy sortable instances
				this.destroySortableInstances();
	
				// Exit fullscreen if active
				if (this.isQuizFullscreen) {
					this.exitQuizFullscreen();
				}
	
				// Reset to initial state
				this.quizState = 'start';
				this.currentQuestionIndex = 0;
				this.timeLeft = 0;
				this.userAnswers = { composite: {} };
				this.testResult = { score: 0, passed: false };
				this.compositeGroupColors = {};
				this.compositeLines = {};
			}
		},
	
		mounted() {
			// Component mounted logic
			if (this.slideData) {
				this.initializeQuiz();
			}
	
			// Add window resize listener for connection quiz
			this.resizeHandler = () => {
				if (this.currentQuestion?.type === 'QUIZ_CONNECTION') {
					setTimeout(() => {
						this.drawCompositeConnectionLines(this.currentQuestion.id);
					}, 100);
				}
			};
			window.addEventListener('resize', this.resizeHandler);
		},
	
		beforeDestroy() {
			this.resetStates();
	
			// Clean up resize listener
			if (this.resizeHandler) {
				window.removeEventListener('resize', this.resizeHandler);
			}
		}
	}
</script>

<style scoped>
.lh-question-header {
  position: sticky !important;
  top: 0 !important;
  z-index: 99 !important;
  background: rgba(255, 255, 255, 0.95) !important;
  backdrop-filter: blur(8px) !important;
  -webkit-backdrop-filter: blur(8px) !important;
  padding: 10px 16px !important;
  margin-bottom: 16px !important;
  border-bottom: 1px solid rgba(0, 0, 0, 0.08) !important;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05) !important;
  border-radius: 8px 8px 0 0 !important;
}

.lh-options-grid {
  display: grid !important;
  grid-template-columns: repeat(auto-fit, minmax(360px, 1fr)) !important;
  gap: 14px !important;
  margin-top: 14px !important;
  margin-bottom: 24px !important;
  width: 100% !important;
}

.lh-option-card {
  overflow: visible !important;
  box-sizing: border-box !important;
  min-height: 52px !important;
  height: auto !important;
  display: flex !important;
  align-items: center !important;
}

.lh-option-content {
  display: flex !important;
  align-items: center !important;
  gap: 12px !important;
  width: 100% !important;
  min-width: 0 !important;
  overflow: visible !important;
}

.lh-option-text,
.lh-option-text :deep(.uc-latex-view),
.lh-option-card :deep(.uc-latex-view),
.lh-question-prompt :deep(.uc-latex-view) {
  min-width: 0 !important;
  overflow: visible !important;
  overflow-x: visible !important;
  overflow-y: visible !important;
  word-break: break-word !important;
}

.lh-option-card :deep(mjx-container),
.lh-option-text :deep(mjx-container),
.lh-question-prompt :deep(mjx-container),
.lh-question-block :deep(mjx-container) {
  margin: 0 !important;
  max-width: 100% !important;
  overflow-x: auto !important;
  overflow-y: hidden !important;
  scrollbar-width: none !important;
  -ms-overflow-style: none !important;
}

.lh-option-card :deep(mjx-container::-webkit-scrollbar),
.lh-option-text :deep(mjx-container::-webkit-scrollbar),
.lh-question-prompt :deep(mjx-container::-webkit-scrollbar),
.lh-question-block :deep(mjx-container::-webkit-scrollbar),
.lh-option-card :deep(.uc-latex-view::-webkit-scrollbar),
.lh-option-text :deep(.uc-latex-view::-webkit-scrollbar) {
  display: none !important;
  width: 0 !important;
  height: 0 !important;
}
</style>