<template>
	<uc-dialog v-model="isOpen" :title="formTitle" @update:modelValue="closeDialog" fullscreen persistent
		:retain-focus="false" :is-show-done-btn="false">
			<div v-if="editableItem">
				<!-- BẢNG TẠO NHIỀU CÂU HỎI TRONG CÙNG DIALOG (KIỂU CẤU TRÚC BÀI THI) -->

				<v-container fluid class="pa-0" :key="activeItemIndex">
					<v-row dense class="mb-2">
						<v-col cols="12">
							<div class="text-subtitle-1 font-weight-bold mb-2">Bạn muốn thêm gì vào kho học liệu?</div>
							<v-btn-toggle v-model="contentMode" color="primary" mandatory divided class="d-flex flex-wrap w-100">
								<v-btn value="structure" prepend-icon="mdi-file-tree-outline" class="flex-grow-1 text-none">Tạo mục</v-btn>
								<v-btn value="material" prepend-icon="mdi-file-upload-outline" class="flex-grow-1 text-none">Tạo tài liệu</v-btn>
								<v-btn value="question" prepend-icon="mdi-help-circle-outline" class="flex-grow-1 text-none">Tạo câu hỏi</v-btn>
							</v-btn-toggle>

							<div v-if="isCreatingNew && contentMode === 'question'" class="mt-4">
								<div class="text-subtitle-2 font-weight-bold mb-2">Cách tạo câu hỏi</div>
								<v-btn-toggle v-model="questionBatchMode" color="primary" mandatory divided class="d-flex flex-wrap w-100">
									<v-btn value="single" prepend-icon="mdi-help-circle-outline" class="flex-grow-1 text-none">Một câu hỏi</v-btn>
									<v-btn value="multiple" prepend-icon="mdi-format-list-numbered" class="flex-grow-1 text-none">Nhiều câu hỏi trong một lần soạn</v-btn>
								</v-btn-toggle>
							</div>

			<v-card v-if="isCreatingNew && contentMode === 'question' && questionBatchMode === 'multiple' && !isQuizComposite"
				variant="outlined" class="mt-4">
				<v-card-text class="pa-0">
					<v-tabs v-model="activeItemIndex" color="teal-darken-2" density="compact" show-arrows class="px-2">
						<v-tab v-for="(qItem, idx) in questionList" :key="idx" :value="idx" class="font-weight-bold text-none">
							<v-avatar color="teal-lighten-4" size="20" class="mr-1 text-caption font-weight-bold text-teal-darken-4">
								{{ idx + 1 }}
							</v-avatar>
							{{ qItem.TenNoiDung || `Câu #${idx + 1}` }}
							<v-icon v-if="questionList.length > 1" size="x-small" color="error" class="ml-1" @click.stop="removeQuestionItem(idx)">mdi-close</v-icon>
						</v-tab>
					</v-tabs>
				</v-card-text>
				<v-divider />
				<v-card-actions class="pa-2 justify-end">
					<v-btn color="teal-darken-2" variant="flat" size="small" prepend-icon="mdi-plus"
						class="font-weight-bold text-none" @click="addQuestionItem">
						Thêm câu hỏi
					</v-btn>
					<v-btn color="teal-darken-2" variant="outlined" size="small" prepend-icon="mdi-file-upload-outline"
						class="font-weight-bold text-none" :loading="convertingFile" @click="openQuestionFilePicker">
						Import câu hỏi
					</v-btn>
				</v-card-actions>
				<input ref="questionFileInput" type="file" accept=".doc,.docx,.pdf,.txt,.html,.htm" class="d-none"
					@change="convertQuestionFile" />
			</v-card>
						</v-col>
					</v-row>
					<v-row dense>
						<v-col cols="12">
							<div class="text-subtitle-2 mb-2">{{ contentTypeLabel }}</div>
							<div class="text-caption text-medium-emphasis mb-2">{{ contentTypeDescription }}</div>
							<v-list density="compact" :lines="contentMode === 'question' ? 'two' : 'one'" class="border rounded pa-0">
								<v-row dense class="ma-0">
									<v-col v-for="option in contentTypeOptions" :key="option.value" cols="12" sm="6" lg="4" class="pa-0">
										<v-list-item :active="editableItem.LoaiNoiDung === option.value"
											:prepend-icon="editableItem.LoaiNoiDung === option.value ? 'mdi-check-circle' : 'mdi-circle-outline'"
											color="primary" v-on:click="editableItem.LoaiNoiDung = option.value">
											<v-list-item-title>{{ option.title }}</v-list-item-title>
											<v-list-item-subtitle v-if="option.description">{{ option.description }}</v-list-item-subtitle>
										</v-list-item>
									</v-col>
								</v-row>
							</v-list>
						</v-col>
						<v-col cols="12" sm="3">
							<v-text-field v-model.number="editableItem.ThuTu" label="Thứ tự" type="number"
								variant="outlined" density="compact"
								:readonly="isCreatingNew && contentMode === 'question' && questionBatchMode === 'multiple'"
								:hint="isCreatingNew && contentMode === 'question' && questionBatchMode === 'multiple' ? 'Tự động theo thứ tự câu hỏi' : ''"
								:persistent-hint="isCreatingNew && contentMode === 'question' && questionBatchMode === 'multiple'" />
						</v-col>
						<v-col cols="12" sm="9">
							<v-text-field v-model="editableItem.TenNoiDung" label="Tên mục*" variant="outlined"
								density="compact" autofocus :rules="[requiredNameRule]" />
						</v-col>
						<!-- Tùy chọn chế độ chỉ giáo viên xem -->
						<v-col cols="12" class="pt-0">
							<v-switch
								v-model="editableItem.isTeacherOnly"
								color="warning"
								density="compact"
								:hide-details="true"
								inset
							>
								<template #label>
									<div class="d-flex align-center">
										<v-icon color="warning" class="mr-1" size="small">mdi-account-tie</v-icon>
										<span class="font-weight-medium text-body-2">Chỉ giáo viên xem</span>
										<span class="text-caption text-medium-emphasis ml-2">(Học sinh sẽ không thấy mục này trong mục lục và bài học)</span>
									</div>
								</template>
							</v-switch>
						</v-col>
					</v-row>


					<!-- VÙNG SOẠN THẢO NỘI DUNG ĐỘNG -->
					<div v-if="!isStructureContent" class="mt-4">
						<label class="form-label">Nội dung chi tiết</label>


						<!-- 1. Nếu là QUIZ -->
						<uc-quiz-editor v-if="isQuiz" v-model:loai-noi-dung="editableItem.LoaiNoiDung"
							v-model="editableItem.DataJson" />


						<!-- 2. Nếu là VIDEO hoặc AUDIO -->
						<div v-else-if="isVideo">
							<v-row>
								<v-col cols="12">
									<v-text-field label="Đường dẫn Video (YouTube)" v-model="tempVideoUrl"
										placeholder="Ví dụ: https://www.youtube.com/watch?v=..."
										variant="outlined" density="compact" append-inner-icon="mdi-link"
										@update:modelValue="onVideoUrlChange" />
								</v-col>
								<v-col cols="12">
									<div class="text-subtitle-2 mb-1">Hoặc tải file video lên (tự động phát hành YouTube):</div>
									<v-file-input accept="video/*" label="Tải video từ máy tính"
										@update:modelValue="uploadFileYoutube" variant="outlined" density="compact" />
								</v-col>
								<!-- Video tương tác vẫn lưu dưới loại VIDEO; cờ này bật timeline và lưu các mốc câu hỏi trong DataJson. -->
				<v-col cols="12" class="py-0">
					<v-checkbox v-model="editableItem.DataJson.interactive" label="Video tương tác" color="primary" hide-details />
				</v-col>
				<v-col v-if="getInactiveVideoQuestionCount() > 0" cols="12" class="pt-0">
					<!-- Nhắc tổng quan ngay khi mở node để người soạn biết cần kiểm tra các câu bị vô hiệu hóa. -->
					<v-alert type="warning" variant="tonal" density="compact" class="mb-0">
						<strong>Lưu ý:</strong> Video này có {{ getInactiveVideoQuestionCount() }} câu hỏi không được hỗ trợ bên Soạn học liệu và đã được tắt.
					</v-alert>
				</v-col>

								<!-- Trạng thái upload YouTube -->
								<v-col cols="12" v-if="currentUploadTask && currentUploadTask.status !== 'success' && currentUploadTask.status !== 'error'">
									<v-card variant="tonal" color="primary" class="pa-3">
										<div class="d-flex align-center justify-space-between mb-1">
											<span class="text-caption font-weight-bold d-flex align-center">
												<v-progress-circular indeterminate size="16" width="2" color="primary" class="mr-2" />
												{{ currentUploadTask.statusText || 'Đang tải lên YouTube...' }}
											</span>
											<span class="text-caption font-weight-bold" v-if="currentUploadTask.progress > 0">
												{{ Math.round(currentUploadTask.progress) }}%
											</span>
										</div>
										<v-progress-linear 
											:model-value="currentUploadTask.progress" 
											:indeterminate="currentUploadTask.status === 'processing' || currentUploadTask.progress === 0" 
											color="primary" 
											height="6" 
											rounded 
										/>
									</v-card>
								</v-col>
								<v-col cols="12" v-else-if="currentUploadTask && currentUploadTask.status === 'error'">
									<v-alert type="error" variant="tonal" density="compact">
										{{ currentUploadTask.errorMessage || 'Tải lên YouTube thất bại.' }}
									</v-alert>
								</v-col>

								<!-- Trình phát video xem trước và nút thêm nhanh -->
								<v-col cols="12" v-if="tempVideoUrl" class="d-flex flex-column align-center">
									<div class="video-preview-box w-100 mb-3" style="max-width: 560px; aspect-ratio: 16/9; background: #000; border-radius: 8px; overflow: hidden; position: relative;">
										<div v-if="editorVideoType === 'youtube'" ref="editorYtWrapper" class="w-100 h-100 position-relative">
											<div :id="editorYtPlayerId" class="w-100 h-100"></div>
											<div class="player-overlay" @click="toggleEditorPlay"></div>
										</div>
										<video v-else ref="editorHtmlPlayer" :key="editorEmbedUrl" :src="editorEmbedUrl" controls class="w-100 h-100"
											@play="editorVideoPlaying = true" @pause="editorVideoPlaying = false"
											@timeupdate="onEditorHtmlTimeUpdate" @loadedmetadata="onEditorHtmlMetadata">
											<source :src="editorEmbedUrl" type="video/mp4">
										</video>
									</div>
									
									<!-- Thanh Tua Timeline chuẩn Vuetify (Giao diện xanh lá + chấm cam chuẩn) -->
									<div class="w-100 d-flex flex-column mt-2 mb-4" style="max-width: 560px;">
										<div ref="timelineTrack" class="position-relative w-100 px-1 mb-2 d-flex align-center" style="height: 20px;"
											@mousedown="onTimelineTrackMouseDown"
											@touchstart="onTimelineTrackMouseDown">
											<v-slider v-model="editorVideoCurrentTime" :max="editorVideoDuration || 100" min="0" step="1"
												hide-details density="compact" color="primary" track-color="grey-lighten-2"
												:track-size="4" :thumb-size="12"
												class="w-100">
											</v-slider>
											
											<!-- Hiển thị các chấm câu hỏi trắc nghiệm chuẩn (Kéo mốc KHÔNG làm nhảy thanh timeline) -->
											<div v-for="(item, idx) in videoInteractions" :key="idx" 
												class="interaction-marker-dot"
												:style="{ left: ((getInteractionTime(item) / (editorVideoDuration || 1)) * 96) + 2 + '%' }"
												@mousedown.stop.prevent="startDragMarker(item, $event)"
												@touchstart.stop.prevent="startDragMarker(item, $event)"
												:title="`Kéo để thay đổi thời gian (mốc: ${formatTime(getInteractionTime(item))})`">
											</div>
										</div>

										<div class="d-flex align-center justify-space-between w-100">
											<div class="d-flex align-center ga-2">
												<v-btn icon size="small" variant="tonal" color="primary" @click="toggleEditorPlay">
													<v-icon>{{ editorVideoPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon>
												</v-btn>
												<span class="text-caption font-weight-medium">
													{{ formatTime(editorVideoCurrentTime) }} / {{ formatTime(editorVideoDuration) }}
												</span>
											</div>
											<div class="d-flex align-center ga-2">
												<v-btn color="success" size="small" prepend-icon="mdi-plus" @click="addVideoInteractionAtCurrentTime">
													Thêm câu hỏi tại thời gian hiện tại
												</v-btn>
											</div>
										</div>
									</div>
								</v-col>

								<!-- Bảng cấu hình Video Tương tác -->
								<v-col cols="12" v-if="tempVideoUrl">
									<v-card variant="outlined" class="pa-4 mt-2">
										<v-card-title class="text-subtitle-1 pa-0 d-flex justify-space-between align-center">
											<span>🎯 Danh sách câu hỏi tương tác</span>
											<v-btn size="small" color="primary" prepend-icon="mdi-plus" @click="addVideoInteraction">
												Thêm mốc thủ công
											</v-btn>
										</v-card-title>
										<v-card-text class="pa-0 mt-3">
											<v-table density="compact" v-if="videoInteractions.length > 0">
												<thead>
 													<tr>
														<th style="width: 150px;">Thời gian</th>
														<th>Nội dung câu hỏi trắc nghiệm</th>
														<th style="width: 180px;">Dạng câu hỏi</th>
														<th style="width: 120px; text-align: center;">Thao tác</th>
 													</tr>
												</thead>
												<tbody>
 													<tr v-for="(item, idx) in videoInteractions" :key="idx">
 														<td>
										<v-text-field :model-value="formatTime(getInteractionTime(item))" @change="onInteractionTimeChange(item, $event)" @blur="onInteractionTimeChange(item, $event)"
 																density="compact" variant="outlined" hide-details />
 														</td>
 														<td>
 															<span class="text-truncate d-inline-block" style="max-width: 300px;">
 																{{ getCleanPrompt(item) }}
 															</span>
														</td>
											<td>
								<v-chip size="small" :color="isSupportedInteractionType(getInteractionQuestions(item)[0]?.type) && getInteractionQuestions(item)[0]?.isActive !== false ? 'info' : 'warning'" variant="flat">
									{{ getInteractionQuestions(item)[0]?.type || 'QUIZ_SINGLE_CHOICE' }}
								</v-chip>
								<v-chip v-if="getInteractionQuestions(item).length > 1" size="x-small" color="secondary" variant="tonal" class="ml-1">
									{{ getInteractionQuestions(item).length }} câu
								</v-chip>
								<v-chip v-if="getInactiveInteractionQuestionCount(item)" size="x-small" color="warning" variant="tonal" class="ml-1">
									{{ getInactiveInteractionQuestionCount(item) }} câu không hỗ trợ · đã tắt
								</v-chip>
														</td>
														<td class="text-center">
															<v-btn icon="mdi-cog" color="primary" variant="text" size="small" 
																@click="openInteractionDetail(item)" />
															<v-btn icon="mdi-delete" color="error" variant="text" size="small" 
																@click="removeVideoInteraction(idx)" />
														</td>
 													</tr>
												</tbody>
											</v-table>
											<div v-else class="text-center text-grey py-4">Chưa có mốc tương tác nào.</div>
										</v-card-text>
									</v-card>
								</v-col>
							</v-row>
						</div>
		<div v-else-if="isAudio">
			<v-row>
				<!-- Import Content Hub cần giữ URL file trực tiếp để giáo viên xem và chỉnh lại được node audio. -->
				<v-col cols="12">
					<v-text-field label="Đường dẫn Audio" v-model="tempAudioUrl"
						placeholder="Ví dụ: https://file.lhbs.vn/.../audio.mp3"
						variant="outlined" density="compact" append-inner-icon="mdi-link"
						@update:modelValue="onAudioUrlChange" />
				</v-col>
				<v-col cols="12">
					<v-file-input accept="audio/*" label="Tải audio"
						@update:modelValue="uploadFileGGDrive" />
				</v-col>
				<v-col cols="12">
					<v-alert type="info" variant="tonal">
						Audio được phát hành qua Google Drive và tự động lưu một bản kiểm tra trong LMS. URL hiện tại được giữ lại để lần sau mở dialog vẫn chỉnh sửa được.
					</v-alert>
				</v-col>
			</v-row>
		</div>
		<!-- Hình ảnh từ Content Hub cũng là media trực tiếp, không dùng office viewer. -->
		<div v-else-if="isImage">
			<!-- Ảnh và nội dung được đặt cạnh nhau trên desktop, tự xếp dọc trên màn hình hẹp để giảm cuộn và giữ quan hệ trực quan. -->
			<v-row dense align="start" class="px-3">
				<v-col cols="12" md="5">
					<v-card variant="outlined" class="pa-1">
						<v-card-title class="text-subtitle-2 px-3 py-2">Xem trước hình ảnh</v-card-title>
						<v-divider />
						<v-card-text class="d-flex justify-center align-center pa-2">
							<v-img v-if="tempImageUrl" :src="imageEmbedUrl" alt="Xem trước hình ảnh"
								max-height="360" max-width="100%" contain />
							<span v-else class="text-caption text-medium-emphasis">Chưa có hình ảnh</span>
						</v-card-text>
					</v-card>
				</v-col>
				<v-col cols="12" md="7">
					<v-text-field label="Nguồn ảnh" v-model="tempImageUrl" class="mb-2"
						variant="outlined" density="compact" append-inner-icon="mdi-link"
						@update:modelValue="onImageUrlChange" />
					<!-- Upload trực tiếp dùng cùng flow tài liệu: file cũ được dọn trước, file mới được lưu metadata và cập nhật URL preview. -->
					<v-file-input accept="image/*" label="Tải ảnh từ máy tính"
						placeholder="Chọn một file ảnh để tải lên"
						prepend-icon="mdi-paperclip" variant="outlined" density="compact"
						@update:modelValue="uploadFileGGDrive" />
					<div class="text-caption text-medium-emphasis mb-3">
						Ảnh tải lên mới sẽ thay thế ảnh hiện tại của mục này.
					</div>
					<v-divider class="mb-3" />
					<!-- Nội dung mô tả được lưu riêng trong textContent, không trộn với URL ảnh. -->
					<uc-rich-text-editor :imageapi="vueData.v_Set.apiFile || 'https://file.lhbs.vn/lms/upload/FileData'"
						v-model="textContent" label="Nội dung hình ảnh" variant="outlined" :height="300" />
				</v-col>
			</v-row>
		</div>
						<!-- 3. Nếu là HTML (cần trình soạn thảo Rich Text) -->
						<div v-else-if="isHtml" class="html-editor-wrapper">
							<!-- Tab Navigation -->
							<v-tabs v-model="activeTab" class="editor-tabs" density="compact" color="primary">
								<v-tab value="rich">
									<v-icon start>mdi-format-text-variant</v-icon>
									Văn bản
								</v-tab>
								<v-tab value="html">
									<v-icon start>mdi-code-tags</v-icon>
									Nhúng HTML
								</v-tab>
							</v-tabs>

							<!-- Tab Content -->
							<v-tabs-window v-model="activeTab" class="editor-content">
								<!-- Tab 1: F-Editor (Rich Text) với tích hợp GeoGebra -->
								<v-tabs-window-item value="rich" class="tab-content">
									<uc-rich-text-editor :imageapi="vueData.v_Set.apiFile || 'https://file.lhbs.vn/lms/upload/FileData'"
										v-model="textContent" label="Nội dung văn bản" variant="outlined" :height="400" />
								</v-tabs-window-item>

								<!-- Tab 2: Raw HTML -->
								<v-tabs-window-item value="html" class="tab-content">
									<v-card>
										<v-card-text>
											<v-file-input
												accept=".html"
												label="Tải tệp tin .html để import nội dung"
												variant="outlined"
												density="compact"
												prepend-icon="mdi-code-tags"
												class="mb-3"
												@update:model-value="onHtmlFileSelected"
												@change="onHtmlFileChange"
											/>
											<v-textarea v-model="htmlContent" label="Mã HTML" variant="outlined"
												auto-grow rows="20" placeholder="Nhập mã HTML tại đây..." />
										</v-card-text>
									</v-card>
								</v-tabs-window-item>
							</v-tabs-window>
						</div>
						<div v-else-if="isSlide">
							<v-tabs v-model="slideUploadTab" density="compact" color="primary" class="mb-4">
								<v-tab value="upload">📁 Tải file lên</v-tab>
								<v-tab value="link">🔗 Dán link Google Slides / Canva</v-tab>
							</v-tabs>

							<v-tabs-window v-model="slideUploadTab">
								<v-tabs-window-item value="upload">
					<!-- Vuetify/FUI có thể phát update:modelValue hoặc change tùy bản runtime; handler dùng token để không upload trùng. -->
									<v-file-input accept=".doc,.docx,.ppt,.pptx,.pdf" label="Tải tài liệu"
									@update:modelValue="onDocumentFileSelected"
									@change="onDocumentFileSelected" />
								</v-tabs-window-item>
								<v-tabs-window-item value="link">
									<div class="d-flex ga-2 align-center">
										<v-text-field v-model="inputSlideLink" label="Dán link Google Slides / Canva tại đây"
											placeholder="https://docs.google.com/presentation/... hoặc https://www.canva.com/design/..."
											variant="outlined" density="compact" hide-details append-inner-icon="mdi-link"
											@click:append-inner="saveSlideLink" @keydown.enter="saveSlideLink" />
										<v-btn color="primary" variant="flat" height="40" @click="saveSlideLink">Xác nhận</v-btn>
									</div>
								</v-tabs-window-item>
							</v-tabs-window>

							<!-- Chỉ báo đã có tài liệu khi metadata có reference thật; archiveFileId/fileName là dữ liệu hợp lệ của file cũ. -->
							<v-chip v-if="hasSlideReference" class="mt-4">
								{{ slideReferenceLabel }} <v-icon @click.stop="onCloseFile"> mdi-close</v-icon>
							</v-chip>
						</div>

						<!-- 4. Nếu là ISPRING_CONTENT -->
						<div v-else-if="isISpring" class="ispring-upload-wrapper">
							<div class="ispring-header">
								<v-icon color="purple" class="mr-2">mdi-play-box-multiple</v-icon>
								<span class="text-h6">iSpring Content Upload</span>
							</div>

							<!-- Nếu chưa có content -->
							<div v-if="!editableItem.DataJson.iSpringURL" class="ispring-upload-zone">
								<div class="upload-zone" @click="$refs.iSpringInput.click()" @dragover.prevent
									@drop.prevent="handleiSpringDrop">
									<v-icon size="48" color="purple" class="mb-3">mdi-folder-upload</v-icon>
									<h4>Upload iSpring Content</h4>
									<p>Kéo thả folder iSpring vào đây hoặc click để chọn</p>
									<v-btn color="purple" variant="outlined" class="mt-2">
										📁 Chọn Folder
									</v-btn>
								</div>

								<input ref="iSpringInput" type="file" style="display: none;" webkitdirectory multiple
									@change="handleiSpringUpload">

								<!-- Progress upload -->
								<div v-if="uploadProgress.show" class="upload-progress mt-4">
									<v-progress-linear v-model="uploadProgress.percent" color="purple" height="8"
										rounded></v-progress-linear>
									<p class="text-center mt-2">{{ uploadProgress.text }}</p>
								</div>
							</div>

							<!-- Nếu đã có content -->
							<div v-else class="ispring-existing">
								<v-alert type="success" variant="tonal" class="mb-3">
									<v-icon>mdi-check-circle</v-icon>
									iSpring content đã được upload thành công!
								</v-alert>

								<div class="ispring-info">
									<p><strong>GUID:</strong> {{ editableItem.DataJson.iSpringGUID }}</p>
									<p><strong>URL:</strong>
										<a :href="editableItem.DataJson.iSpringURL" target="_blank" class="text-purple">
											{{ editableItem.DataJson.iSpringURL }}
										</a>
									</p>
								</div>

								<div class="ispring-actions mt-3">
									<v-btn color="purple" variant="outlined" :href="editableItem.DataJson.iSpringURL"
										target="_blank">
										<v-icon start>mdi-eye</v-icon>
										Xem trước
									</v-btn>
									<v-btn color="error" variant="outlined" @click="removeiSpringContent" class="ml-2">
										<v-icon start>mdi-delete</v-icon>
										Xóa & Upload lại
									</v-btn>
								</div>
							</div>
						</div>
					</div>
				</v-container>
			</div>


		<template #actions>
				<v-spacer></v-spacer>
				<v-btn color="grey-darken-1" variant="text" @click="closeDialog">Hủy</v-btn>
				<v-btn color="primary" variant="flat" class="font-weight-bold px-6" @click="save">
					{{ isCreatingNew && questionList.length > 1 ? `Lưu cả ${questionList.length} câu (1 lần)` : 'Lưu' }}
				</v-btn>
		</template>
			<!-- Dialog soạn chi tiết câu hỏi tương tác của Video -->
			<uc-dialog v-model="isInteractionDetailOpen" width="900" :is-show-done-btn="false"
				:title="editingInteraction ? '📝 Thiết kế câu hỏi tương tác (Mốc ' + formatTime(getInteractionTime(editingInteraction)) + ')' : 'Thiết kế câu hỏi tương tác'">
				<div v-if="editingInteraction && editingInteraction.question" class="pa-2">
					<!-- Hiển thị rõ lý do để giáo viên không nhầm câu bị tắt là lỗi mất dữ liệu hoặc lỗi trình soạn thảo. -->
					<v-alert v-if="!isSupportedInteractionType(editingInteraction.question.type) || editingInteraction.question.isActive === false"
						type="warning" variant="tonal" density="compact" class="mb-4">
						Câu hỏi này đang <strong>tắt</strong> vì dạng
						<strong>{{ editingInteraction.question.type }}</strong> chưa được hỗ trợ trong Soạn học liệu.
					</v-alert>
					<v-select v-if="editingInteraction.questions?.length > 1" v-model="editingQuestionIndex"
						:items="editingQuestionOptions" label="Câu hỏi trong mốc thời gian" variant="outlined" density="compact"
						class="mb-4" item-title="title" item-value="value" @update:modelValue="selectEditingQuestion" />
						<v-select v-model="editingInteraction.question.type" :items="quizTypesForVideo" 
							label="Chọn dạng câu hỏi" variant="outlined" density="compact" class="mb-4"
							item-title="title" item-value="value"
							@update:modelValue="onInteractionTypeChange" />
						
						<v-divider class="mb-4"></v-divider>
						
						<!-- Nhúng uc-quiz-editor -->
						<uc-quiz-editor 
							v-model:loai-noi-dung="editingInteraction.question.type"
							v-model="editingInteraction.question.content" />
				</div>
				<template #actions>
					<v-spacer></v-spacer>
					<v-btn color="primary" variant="flat" @click="confirmInteractionDetail">Xác nhận hoàn tất</v-btn>
				</template>
			</uc-dialog>
		<uc-loading-page v-model="loadingPage.isLoading" :text="loadingPage.text" />
	</uc-dialog>
</template>

<script>
	export default {
		name: 'uc-noi-dung-dialog',
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
		props: {
			isOpen: Boolean,
			item: Object,
			resourceContext: {
				type: Object,
				default: () => ({}),
			},
		},
		emits: ['update:isOpen', 'save'],
		data() {
			return {
				questionList: [],
				activeItemIndex: 0,
				questionBatchMode: 'single',
				draftKey: null,
				convertingFile: false,
				questionImportPrompt: `Bạn là bộ phận trích xuất câu hỏi cho module soan-hoc-lieu-v2.
Trước khi xử lý Content, hãy đọc PRIORITY KNOWLEDGE do hệ thống cung cấp và áp dụng đúng nghiệp vụ nhận diện câu hỏi.
Loại câu hỏi cần xử lý lần này là: {{QUESTION_TYPE}}.
Chỉ xử lý đúng loại {{QUESTION_TYPE}}, không trộn loại câu hỏi. Mỗi câu hỏi là một phần tử riêng trong mảng questions.
Giữ nguyên nội dung câu hỏi, lựa chọn, công thức, số liệu và đơn vị. Không tự tạo hoặc tự đoán đáp án nếu Content không có căn cứ.
Không trả về HTML tổng hợp, Markdown, code fence, candidates, RawResponse, thoughtSignature hoặc metadata của Gemini. Không cần gửi id. points mặc định là 1.
Công thức inline dùng $, công thức riêng dòng dùng $$...$$, không dùng MathML, sup hoặc sub. Không nhúng công thức dưới dạng ảnh WMF/EMF (data:image/wmf hoặc data:image/emf); hãy chuyển toàn bộ công thức sang LaTeX.
Chỉ trả về JSON hợp lệ: {"questionType":"{{QUESTION_TYPE}}","questionsCount":0,"questions":[]}. questionsCount phải bằng số phần tử questions.
Mỗi câu phải có type, points, content; mỗi option phải có id và text; đáp án phải tham chiếu đúng option id. Không gộp nhiều câu vào một phần tử.`,
				splitToNodes: true,
				loaiHocLieuOptions: [

					{ value: 'CHUONG', title: 'Chương' },
					{ value: 'BAI', title: 'Bài' },
					{ value: 'NHOM_KY_NANG', title: 'Nhóm kỹ năng' },
					{ value: 'VIDEO', title: 'Video' },
					{ value: 'AUDIO', title: 'Audio' },
					{ value: 'HTML', title: 'HTML' },

				{ value: 'SLIDE', title: 'PPT, DOC & PDF' },

					{ value: 'QUIZ_SINGLE_CHOICE', title: 'Trắc nghiệm đơn' },
					{ value: 'QUIZ_MULTIPLE_CHOICE', title: 'Trắc nghiệm đa lựa chọn' },
					{ value: 'QUIZ_MATCHING', title: 'Ghép cặp' },
					{ value: 'QUIZ_ORDERING', title: 'Sắp xếp thứ tự' },
					{ value: 'QUIZ_DRAG_DROP_CATEGORIZE', title: 'Kéo thả phân loại' },
					{ value: 'QUIZ_FILL_IN_BLANK', title: 'Điền từ' },
					{ value: 'QUIZ_CONNECTION', title: 'Nối nhóm' },
					{ value: 'QUIZ_TRUE_FALSE', title: 'Đúng sai' },
					{ value: 'QUIZ_COMPOSITE', title: 'Bài thi' },
					{ value: 'ISPRING_CONTENT', title: 'ISpring' }

				],
				structureOptions: [
					{ value: 'CHUONG', title: 'Chương' },
					{ value: 'BAI', title: 'Bài' },
					{ value: 'NHOM_KY_NANG', title: 'Nhóm kỹ năng' }
				],
				materialOptions: [
					{ value: 'VIDEO', title: 'Video' },
					{ value: 'AUDIO', title: 'Audio' },
					{ value: 'HTML', title: 'HTML' },
				{ value: 'IMAGE', title: 'Hình ảnh' },
				{ value: 'SLIDE', title: 'PPT, DOC & PDF' },
					{ value: 'ISPRING_CONTENT', title: 'iSpring' }
				],
				questionOptions: [
					{ value: 'QUIZ_SINGLE_CHOICE', title: 'Trắc nghiệm đơn', description: 'Chọn một đáp án đúng.' },
					{ value: 'QUIZ_MULTIPLE_CHOICE', title: 'Trắc nghiệm đa lựa chọn', description: 'Chọn một hoặc nhiều đáp án đúng.' },
					{ value: 'QUIZ_MATCHING', title: 'Ghép cặp', description: 'Ghép các cặp nội dung tương ứng.' },
					{ value: 'QUIZ_ORDERING', title: 'Sắp xếp thứ tự', description: 'Sắp xếp các mục theo thứ tự đúng.' },
					{ value: 'QUIZ_DRAG_DROP_CATEGORIZE', title: 'Kéo thả phân loại', description: 'Kéo thả nội dung vào đúng nhóm.' },
					{ value: 'QUIZ_FILL_IN_BLANK', title: 'Điền từ', description: 'Điền từ hoặc cụm từ còn thiếu.' },
					{ value: 'QUIZ_CONNECTION', title: 'Nối nhóm', description: 'Nối các mục vào đúng nhóm.' },
					{ value: 'QUIZ_TRUE_FALSE', title: 'Đúng sai', description: 'Đánh dấu phát biểu đúng hoặc sai.' },
					{ value: 'QUIZ_COMPOSITE', title: 'Bài thi', description: 'Tạo bài thi gồm nhiều câu hỏi.' }
				],
				vueData,
				filters: {
					max_file_size: '50mb',
					chunk_size: '4mb',
					mime_types: [{ title: "All files", extensions: "*" }]
				},
				activeTab: 'rich', // Tab mặc định là 'rich',

				uploadProgress: {
					show: false,
					percent: 0,
					text: ''
				},
				loadingPage: {
					text: "Đang tải dữ liệu...",
					isLoading: false
				},
				slideUploadTab: 'upload',
				inputSlideLink: '',
				editorYtPlayerId: 'editor-yt-player-' + Math.random().toString(36).substring(2, 9),
				tempVideoUrl: '',
				tempAudioUrl: '',
				tempImageUrl: '',
				localVideoBlobUrl: null,
				currentUploadTaskId: null,
				// Một lần chọn file có thể phát đồng thời hai event; dùng khóa file để tránh tạo hai bản lưu LMS.
				lastDocumentUploadKey: '',
				lastDocumentUploadAt: 0,
				videoInteractions: [],
				isInteractionDetailOpen: false,
				editingInteraction: null,
				editingQuestionIndex: 0,
				targetInteractionItem: null,
				editorManualTime: 0,
				editorVideoPlaying: false,
				editorVideoDuration: 0,
				editorVideoCurrentTime: 0,
				editorUpdateTimerInterval: null,
				isDraggingProgress: false,
				isDraggingMarker: false,
				selectedMarkerId: null,
				quizTypesForVideo: [
					{ value: 'QUIZ_SINGLE_CHOICE', title: 'Trắc nghiệm đơn' },
					{ value: 'QUIZ_MULTIPLE_CHOICE', title: 'Trắc nghiệm nhiều lựa chọn' },
					{ value: 'QUIZ_TRUE_FALSE', title: 'Đúng sai' },
					{ value: 'QUIZ_MATCHING', title: 'Ghép cặp / Nối cột' },
					{ value: 'QUIZ_ORDERING', title: 'Sắp xếp thứ tự' },
					{ value: 'QUIZ_DRAG_DROP_CATEGORIZE', title: 'Kéo thả phân loại' },
					{ value: 'QUIZ_FILL_IN_BLANK', title: 'Điền từ vào chỗ trống' },
						{ value: 'QUIZ_COMPOSITE', title: 'Tổ hợp nhiều câu hỏi' },
						{ value: 'SHORT_ANSWER', title: 'Trả lời ngắn' },
						{ value: 'ESSAY', title: 'Tự luận (Viết câu trả lời)' }
				]
			};
		},
		computed: {
			editableItem: {
				get() {
					if (!this.questionList || this.questionList.length === 0) return null;
					return this.questionList[this.activeItemIndex] || this.questionList[0];
				},
				set(val) {
					if (this.questionList && this.questionList.length > 0) {
						this.questionList[this.activeItemIndex] = val;
					}
				}
			},
			isCreatingNew() { return !this.item || !this.item.NoiDungID; },
			formTitle() { return this.item && this.item.NoiDungID ? 'Cập nhật mục' : 'Thêm mục mới'; },
			contentMode: {
				get() {
					if (this.editableItem?.LoaiNoiDung?.startsWith('QUIZ')) return 'question';
					if (['CHUONG', 'BAI', 'NHOM_KY_NANG'].includes(this.editableItem?.LoaiNoiDung)) return 'structure';
					return 'material';
				},
				set(mode) {
					if (!this.editableItem) return;
					if (mode === 'structure' && !['CHUONG', 'BAI', 'NHOM_KY_NANG'].includes(this.editableItem.LoaiNoiDung)) {
						this.editableItem.LoaiNoiDung = 'CHUONG';
					} else if (mode === 'material' && !this.materialOptions.some(item => item.value === this.editableItem.LoaiNoiDung)) {
						this.editableItem.LoaiNoiDung = 'VIDEO';
					} else if (mode === 'question' && !this.editableItem.LoaiNoiDung?.startsWith('QUIZ')) {
						this.editableItem.LoaiNoiDung = 'QUIZ_SINGLE_CHOICE';
					}
				}
			},
			contentTypeOptions() {
				if (this.contentMode === 'structure') return this.structureOptions;
				if (this.contentMode === 'question') return this.questionOptions;
				return this.materialOptions;
			},
			contentTypeLabel() {
				if (this.contentMode === 'structure') return 'Loại mục*';
				if (this.contentMode === 'question') return 'Dạng câu hỏi*';
				return 'Loại tài liệu*';
			},
			contentTypeDescription() {
				if (this.contentMode === 'structure') return 'Chọn loại mục để xây dựng cấu trúc kho học liệu.';
				if (this.contentMode === 'question') return 'Chọn dạng câu hỏi phù hợp để bắt đầu soạn nội dung.';
				return 'Chọn loại tài liệu bạn muốn thêm vào kho học liệu.';
			},
			isQuiz() { return this.editableItem?.LoaiNoiDung?.startsWith('QUIZ'); },
			isStructureContent() {
				return ['CHUONG', 'BAI', 'NHOM_KY_NANG'].includes(this.editableItem?.LoaiNoiDung);
			},
			isQuizComposite() { return this.editableItem?.LoaiNoiDung === 'QUIZ_COMPOSITE'; },
			// INTERACTIVE dùng cùng player và timeline với VIDEO; TAILIEU vẫn là fallback tài liệu cũ, trừ node iSpring nhận diện theo metadata.
			isVideo() { return !this.isISpring && ['VIDEO', 'INTERACTIVE', 'TAILIEU'].includes(this.editableItem?.LoaiNoiDung); },
			isAudio() { return ['AUDIO'].includes(this.editableItem?.LoaiNoiDung); },
			isImage() { return this.editableItem?.LoaiNoiDung === 'IMAGE'; },
			isHtml() { return ['HTML', 'READING'].includes(this.editableItem?.LoaiNoiDung); },
			isSlide() { return ['SLIDE'].includes(this.editableItem?.LoaiNoiDung) },
			hasSlideReference() {
				const data = this.editableItem?.DataJson;
				if (!data || typeof data !== 'object') return false;
				return Boolean(
					data.fileName || data.archiveFileName || data.title || data.url ||
					data.fileId || data.archiveFileId || data.driveFileId
				);
			},
			slideReferenceLabel() {
				const data = this.editableItem?.DataJson || {};
				return data.fileName || data.archiveFileName || data.title ||
					(data.archiveFileId ? 'Tài liệu lưu trữ' : 'Đã liên kết tài liệu');
			},
			isISpring() {
				const data = this.editableItem?.DataJson;
				const metadata = data && typeof data === 'object' ? data : {};
				const value = `${this.editableItem?.LoaiNoiDung || ''} ${metadata.contentType || ''} ${metadata.url || ''}`.toLowerCase();
				// Tương thích node cũ từng bị lưu TAILIEU nhưng vẫn có iSpringURL/MIME iSpring.
				return this.editableItem?.LoaiNoiDung === 'ISPRING_CONTENT'
					|| Boolean(metadata.iSpringURL)
					|| /ispring|application\/x-ispring/.test(value);
			},
			editingQuestionOptions() {
				return (this.editingInteraction?.questions || []).map((question, index) => ({
					title: `Câu ${index + 1}`,
					value: index,
				}));
			},
			editorVideoType() {
				if (!this.tempVideoUrl) return '';
				if (this.tempVideoUrl.includes('youtube.com') || this.tempVideoUrl.includes('youtu.be')) {
					return 'youtube';
				}
				return 'video';
			},
			editorEmbedUrl() {
				if (!this.tempVideoUrl) return '';
				if (this.editorVideoType === 'youtube') {
					let videoId = '';
					try {
						const urlObj = new URL(this.tempVideoUrl);
						if (urlObj.hostname.includes('youtube.com')) {
							videoId = urlObj.searchParams.get('v') || '';
						} else if (urlObj.hostname.includes('youtu.be')) {
							videoId = urlObj.pathname.slice(1);
						}
					} catch (e) {}
					return videoId;
				}
				return (this.tempVideoUrl.startsWith('http') || this.tempVideoUrl.startsWith('blob:'))
					? this.tempVideoUrl
					: vueData.v_Set.urlReadFile + this.tempVideoUrl;
			},
			imageEmbedUrl() { return this.resolveFileUrl(this.tempImageUrl); },
			currentUploadTask() {
				if (!this.currentUploadTaskId || !window.UploadManager) return null;
				return window.UploadManager.tasks?.find(t => t.id === this.currentUploadTaskId) || null;
			},
			htmlContent: {
				get() {
					console.log('gethtmlContent', this.editableItem.DataJson)
					// KHI HIỂN THỊ: Lấy giá trị từ object và trả về chuỗi
					if (this.editableItem && this.editableItem.DataJson) {
						// Nếu là object, lấy thuộc tính htmlContent, nếu không thì lấy chính nó
						return this.editableItem.DataJson.htmlContent || '';
					}
					return '';
				},
				set(newValue) {
					console.log('set htmlContent', newValue)
					// KHI NHẬP LIỆU: Cập nhật lại object DataJson
					if (this.editableItem) {
						// Luôn đảm bảo DataJson là một object
						if (typeof this.editableItem.DataJson !== 'object' || this.editableItem.DataJson === null) {
							this.editableItem.DataJson = {};
						}
						this.editableItem.DataJson.htmlContent = newValue;
						this.editableItem.DataJson.isType = this.activeTab;
					}
				}
			},
			textContent: {
				get() {
					console.log('get textContent', this.editableItem.DataJson)
					// KHI HIỂN THỊ: Lấy giá trị từ object và trả về chuỗi
					if (this.editableItem && this.editableItem.DataJson) {
						// Nếu là object, lấy thuộc tính htmlContent, nếu không thì lấy chính nó
						return this.editableItem.DataJson.textContent || '';
					}
					return '';
				},
				set(newValue) {
					console.log('set textContent', newValue)
					// KHI NHẬP LIỆU: Cập nhật lại object DataJson
					if (this.editableItem) {
						// Luôn đảm bảo DataJson là một object
						if (typeof this.editableItem.DataJson !== 'object' || this.editableItem.DataJson === null) {
							this.editableItem.DataJson = {};
						}
						this.editableItem.DataJson.textContent = newValue;
						this.editableItem.DataJson.isType = this.activeTab;
					}
				}
			}
		},
		watch: {
			questionBatchMode(newMode) {
				if (newMode === 'single' && this.questionList.length > 1) {
					this.questionList = [this.questionList[this.activeItemIndex] || this.questionList[0]];
					this.activeItemIndex = 0;
				}
			},
			isOpen(newVal) {
				if (newVal) {
					const nextDraftKey = this.getDraftKey(this.item);
					if (this.draftKey === nextDraftKey && this.questionList.length) {
						const currentItem = this.questionList[0];
						if (currentItem && ['VIDEO', 'INTERACTIVE', 'TAILIEU'].includes(currentItem.LoaiNoiDung) && this.tempVideoUrl &&
							(this.tempVideoUrl.includes('youtube.com') || this.tempVideoUrl.includes('youtu.be'))) {
							this.$nextTick(() => {
								setTimeout(() => {
									this.initEditorYtPlayer();
								}, 150);
							});
						}
						return;
					}
					this.draftKey = nextDraftKey;
					this.questionBatchMode = 'single';
					this.extraItems = [];
					// Khi mở, sao chép và parse dữ liệu
					const initialData = JSON.parse(JSON.stringify(this.item || {}));
					// Luôn đảm bảo DataJson là một object
					if (initialData.DataJson && typeof initialData.DataJson === 'string') {
						try {
							initialData.DataJson = JSON.parse(initialData.DataJson);
						}
						catch (e) {
							// Nếu không phải JSON, coi nó là HTML thô
							initialData.DataJson = {
								htmlContent: initialData.DataJson ?? '',
								textContent: '',
								isType: 'html'
							};
						}
					} else if (!initialData.DataJson) {
						initialData.DataJson = {};
					}
					if (initialData.ThuTu === undefined || initialData.ThuTu === null || initialData.ThuTu === '') {
						initialData.ThuTu = 1;
					}
					// Khởi tạo trạng thái quyền xem Chỉ giáo viên
					initialData.isTeacherOnly = Boolean(
						initialData.IsTeacherOnly ||
						initialData.DataJson?.isTeacherOnly ||
						initialData.DataJson?.IsTeacherOnly ||
						initialData.DataJson?.chiGiaoVien ||
						initialData.DataJson?.ChiGiaoVien
					);
					console.log('initialData', initialData)
					this.questionList = [ initialData ];
					this.activeItemIndex = 0;
					if (initialData && ['VIDEO', 'INTERACTIVE', 'TAILIEU'].includes(initialData.LoaiNoiDung)) {
						// Node import có thể giữ link ở source/viewerSource và mốc ở timerMarkers; map fallback
						// tại lúc mở form để cả node cũ lẫn node mới đều hiển thị đúng dữ liệu chỉnh sửa.
						const videoData = initialData.DataJson || {};
						this.tempVideoUrl = videoData.url || videoData.source || videoData.viewerSource || videoData.externalSource || '';
						const markerData = videoData.timerMarkers || videoData.interactions || [];
						this.videoInteractions = Array.isArray(markerData) ? JSON.parse(JSON.stringify(markerData)).map(item => this.normalizeInteractionMarker(item)) : [];
						if (this.tempVideoUrl && (this.tempVideoUrl.includes('youtube.com') || this.tempVideoUrl.includes('youtu.be'))) {
							this.$nextTick(() => {
								setTimeout(() => {
									this.initEditorYtPlayer();
								}, 150);
							});
						}
						this.tempAudioUrl = '';
						this.tempImageUrl = '';
					} else if (initialData && initialData.LoaiNoiDung === 'AUDIO') {
						const mediaData = initialData.DataJson || {};
						// Node cũ có thể đã lưu route viewer; chuẩn hóa lúc mở form để URL audio luôn là file trực tiếp.
						this.tempAudioUrl = this.normalizeDirectMediaUrl(mediaData.audioUrl || mediaData.url || mediaData.source || mediaData.externalSource || '');
						this.tempVideoUrl = '';
						this.tempImageUrl = '';
						this.videoInteractions = [];
					} else if (initialData && initialData.LoaiNoiDung === 'IMAGE') {
						const mediaData = initialData.DataJson || {};
						this.tempImageUrl = mediaData.url || mediaData.source || mediaData.externalSource || '';
						this.tempVideoUrl = '';
						this.tempAudioUrl = '';
						this.videoInteractions = [];
					} else if (initialData && initialData.LoaiNoiDung === 'SLIDE') {
						const slideData = initialData.DataJson || {};
						const savedUrl = String(slideData.url || slideData.source || slideData.externalSource || '');
						// Chỉ nạp lại ô link cho Google Slides/Canva; file archive không phải URL nhập tay.
						this.inputSlideLink = /google\.com|canva\.com/i.test(savedUrl) ? savedUrl : '';
						this.slideUploadTab = this.inputSlideLink ? 'link' : 'upload';
						this.tempVideoUrl = '';
						this.tempAudioUrl = '';
						this.tempImageUrl = '';
						this.videoInteractions = [];
					} else {
						this.tempVideoUrl = '';
						this.tempAudioUrl = '';
						this.tempImageUrl = '';
						this.inputSlideLink = '';
						this.slideUploadTab = 'upload';
						this.videoInteractions = [];
					}
				} else {
					if (this.editorUpdateTimerInterval) {
						clearInterval(this.editorUpdateTimerInterval);
						this.editorUpdateTimerInterval = null;
					}
					if (window.__editorYtPlayer) {
						try {
							window.__editorYtPlayer.destroy();
						} catch (e) {}
						window.__editorYtPlayer = null;
					}
					if (this.localVideoBlobUrl) {
						try { URL.revokeObjectURL(this.localVideoBlobUrl); } catch (e) {}
						this.localVideoBlobUrl = null;
					}
					this.currentUploadTaskId = null;
					this.editorVideoPlaying = false;
					this.editorVideoDuration = 0;
					this.editorVideoCurrentTime = 0;
				}
			},
			tempVideoUrl(newUrl) {
				if (newUrl && (newUrl.includes('youtube.com') || newUrl.includes('youtu.be'))) {
					this.$nextTick(() => {
						this.initEditorYtPlayer();
					});
				}
			}
		},
		mounted() {
			this.ensureYoutubeApiLoaded();
		},
		methods: {
			getDraftKey(item) {
				if (item && item.NoiDungID != null) return 'id:' + item.NoiDungID;
				if (!item) return 'new:none';
				return [
					'new',
					item.HocLieuID ?? '',
					item.ParentID ?? '',
					item.LoaiNoiDung ?? '',
					item.ThuTu ?? ''
				].join(':');
			},
			clearDraft() {
				this.draftKey = null;
				this.questionList = [];
				this.activeItemIndex = 0;
			},
			openQuestionFilePicker() {
				this.$refs.questionFileInput?.click();
			},

			async convertQuestionFile(event) {
				const file = event?.target?.files?.[0];
				if (!file) return;
					const supportedQuestionTypes = ['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_TRUE_FALSE',
						'QUIZ_MATCHING', 'QUIZ_ORDERING', 'QUIZ_DRAG_DROP_CATEGORIZE', 'QUIZ_FILL_IN_BLANK',
						'QUIZ_CONNECTION', 'SHORT_ANSWER', 'ESSAY'];
				const currentType = this.questionList.find(item => supportedQuestionTypes.includes(item.LoaiNoiDung))?.LoaiNoiDung;
				const questionType = currentType || 'QUIZ_SINGLE_CHOICE';
				const prompt = this.questionImportPrompt.replaceAll('{{QUESTION_TYPE}}', questionType);
				const formData = new FormData();
				formData.append('file', file);
				formData.append('prompt', prompt);

				this.convertingFile = true;
				this.loadingPage.isLoading = true;
				this.loadingPage.text = 'Đang trích xuất câu hỏi từ file...';
				try {
					const fileBase64 = await this.fileToBase64(file);
					const response = await fetch('https://tapi.lhbs.vn/lms/auth/AIDocumentProcess', {
						method: 'POST',
						headers: { 'Content-Type': 'application/json' },
						body: JSON.stringify({
							Action: 'CONVERT',
							FileName: file.name,
							FileBase64: fileBase64,
							Prompt: prompt,
							PromptId: 'soan-hoc-lieu-v2-import'
						})
					});

					if (!response.ok) throw new Error(`API lỗi HTTP ${response.status}`);
					const payload = await response.json().catch(() => ({}));
					const responseRow = Array.isArray(payload) ? payload[0] : (payload.data?.[0] || payload);
					if (responseRow && responseRow.Status === 'ERROR') throw new Error(responseRow.ErrorMessage || 'Không thể trích xuất câu hỏi');

					let questions = [];
					if (responseRow && responseRow.Data) {
						let converted = responseRow.Data;
						if (typeof converted === 'string') {
							try { converted = JSON.parse(converted); } catch (e) {}
						}
						if (converted && typeof converted.data === 'string') {
							try { converted.data = JSON.parse(converted.data); } catch (e) {}
						}

						const rawQuestions = converted?.data?.questions
							|| converted?.questions
							|| converted?.result?.questions
							|| converted?.output?.questions
							|| (Array.isArray(converted) ? converted : []);

						if (Array.isArray(rawQuestions)) {
							questions = rawQuestions;
						}
					}

					if (!questions.length) throw new Error('API không trả về câu hỏi nào.');
					const parent = this.questionList[0] || {};
					const baseThuTu = this.getQuestionBaseOrder();
					this.questionList = questions.map((question, index) => ({
						HocLieuID: parent.HocLieuID || this.item?.HocLieuID,
						TenHocLieu: parent.TenHocLieu || this.item?.TenHocLieu,
						ParentID: parent.ParentID ?? this.item?.ParentID ?? 0,
						TenNoiDung: `Câu #${index + 1}`,
						LoaiNoiDung: question.type || questionType || 'QUIZ_SINGLE_CHOICE',
						ThuTu: baseThuTu + index,
						DataJson: this.normalizeImportedQuestionContent(question.content)
					}));
					this.activeItemIndex = 0;
					this.notify(`Đã import ${this.questionList.length} câu hỏi từ file "${file.name}".`);
				} catch (error) {
					this.notify(`Import câu hỏi thất bại: ${error.message}`, 'error');
				} finally {
					this.convertingFile = false;
					this.loadingPage.isLoading = false;
					if (event.target) event.target.value = '';
				}
			},

			questionTitle(question, index) {
				return `Câu #${index + 1}`;
			},

			getQuestionBaseOrder() {
				const value = this.questionList[0]?.ThuTu ?? this.item?.ThuTu ?? 1;
				const numericValue = Number(value);
				return Number.isFinite(numericValue) ? numericValue : 1;
			},

			hasAdvancedAnswer(value) {
				if (Array.isArray(value)) return value.some(item => this.hasAdvancedAnswer(item));
				if (!value || typeof value !== 'object') return false;
				if (value.isAdvanced === true || value.isAdvanced === 'true') return true;
				return Object.values(value).some(item => this.hasAdvancedAnswer(item));
			},

			normalizeImportedQuestionContent(content) {
				let normalized = content;
				if (typeof normalized === 'string') {
					try { normalized = JSON.parse(normalized); } catch (e) { normalized = {}; }
				}
				if (!normalized || typeof normalized !== 'object') normalized = {};
				normalized = JSON.parse(JSON.stringify(normalized));
				if (this.hasAdvancedAnswer(normalized)) normalized.isAdvanced = true;
				return normalized;
			},

			addQuestionItem() {
				const parentItem = this.questionList[0] || {};
				const nextIdx = this.questionList.length + 1;
				const baseThuTu = this.getQuestionBaseOrder();
				const newItem = {
					HocLieuID: parentItem.HocLieuID || this.item?.HocLieuID,
					TenHocLieu: parentItem.TenHocLieu || this.item?.TenHocLieu,
					ParentID: parentItem.ParentID ?? this.item?.ParentID ?? 0,
					TenNoiDung: `Câu #${nextIdx}`,
					LoaiNoiDung: parentItem.LoaiNoiDung?.startsWith('QUIZ') ? parentItem.LoaiNoiDung : 'QUIZ_SINGLE_CHOICE',
					ThuTu: baseThuTu + this.questionList.length,
					DataJson: {}
				};
				this.questionList.push(newItem);
				this.activeItemIndex = this.questionList.length - 1;
			},

			removeQuestionItem(index) {
				if (this.questionList.length > 1) {
					this.questionList.splice(index, 1);
					const baseThuTu = this.getQuestionBaseOrder();
					this.questionList.forEach((question, questionIndex) => {
						question.ThuTu = baseThuTu + questionIndex;
					});
					if (this.activeItemIndex >= this.questionList.length) {
						this.activeItemIndex = this.questionList.length - 1;
					}
				}
			},

			save() {
				for (let i = 0; i < this.questionList.length; i++) {
					const q = this.questionList[i];
					if (!q.TenNoiDung || !q.TenNoiDung.trim()) {
						this.activeItemIndex = i;
						return this.notify(`Vui lòng nhập tên cho câu/mục thứ #${i + 1}!`, "error");
					}
				}

				const baseThuTu = Number(this.item?.ThuTu || 0);
				const payloadList = this.questionList.map((q, idx) => {
					let dataObj = {};
					if (typeof q.DataJson === 'object' && q.DataJson !== null) {
						dataObj = { ...q.DataJson };
					} else {
						try {
							dataObj = JSON.parse(q.DataJson || '{}');
						} catch (e) {
							dataObj = {};
						}
					}
					// Lưu cờ isTeacherOnly vào cấu hình DataJson
					if (q.isTeacherOnly !== undefined) {
						dataObj.isTeacherOnly = Boolean(q.isTeacherOnly);
					}
					const cleanObj = {
						NoiDungID: q.NoiDungID ?? this.item?.NoiDungID,
						HocLieuID: q.HocLieuID || this.item?.HocLieuID,
						TenHocLieu: q.TenHocLieu || this.item?.TenHocLieu,
						ParentID: q.ParentID ?? this.item?.ParentID ?? 0,
						TenNoiDung: (q.TenNoiDung || '').trim(),
						LoaiNoiDung: q.LoaiNoiDung || 'QUIZ_SINGLE_CHOICE',
						ThuTu: baseThuTu + idx,
						DataJson: JSON.stringify(dataObj)
					};
					if (this.isCreatingNew || this.questionList.length > 1) {
						delete cleanObj.NoiDungID;
					}
					return cleanObj;
				});

				if (payloadList.length === 1) {
					this.$emit('save', payloadList[0]);
				} else {
					this.$emit('save', payloadList);
				}
				this.closeDialog();
			},

			notify(message, color = 'success') {
				this.snackbarRef?.value?.showSnackbar?.({ message, color });
			},
			ensureYoutubeApiLoaded() {
				if (window.YT && window.YT.Player) {
					return Promise.resolve(window.YT);
				}
				if (window.__ytApiPromise) {
					return window.__ytApiPromise;
				}
				window.__ytApiPromise = new Promise((resolve) => {
					const prev = window.onYouTubeIframeAPIReady;
					window.onYouTubeIframeAPIReady = () => {
						if (typeof prev === 'function') prev();
						resolve(window.YT);
					};
					if (!document.querySelector('script[src*="youtube.com/iframe_api"]')) {
						const tag = document.createElement('script');
						tag.src = "https://www.youtube.com/iframe_api";
						const firstScriptTag = document.getElementsByTagName('script')[0];
						if (firstScriptTag && firstScriptTag.parentNode) {
							firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
						} else {
							document.head.appendChild(tag);
						}
					}
				});
				return window.__ytApiPromise;
			},
			onHtmlFileSelected(files) {
				let file = files;
				if (Array.isArray(file)) {
					file = file[0];
				}
				if (!file) return;
				const reader = new FileReader();
				reader.onload = (e) => {
					const content = (e.target && e.target.result) || reader.result || '';
					this.htmlContent = content;
					this.notify(`Đã import nội dung từ file "${file.name || 'HTML'}" thành công!`, 'success');
				};
				reader.onerror = () => {
					this.notify('Không thể đọc file .html này.', 'error');
				};
				reader.readAsText(file);
			},
			onHtmlFileChange(event) {
				const files = event?.target?.files || event;
				if (files) {
					this.onHtmlFileSelected(files);
				}
			},
			initEditorYtPlayer() {
				let videoId = this.editorEmbedUrl;
				if (!videoId) return;
				this.ensureYoutubeApiLoaded().then(() => {
					if (window.__editorYtPlayer) {
						try {
							window.__editorYtPlayer.destroy();
						} catch (e) {}
						window.__editorYtPlayer = null;
					}
					const self = this;
					const init = () => {
						const wrapper = self.$refs.editorYtWrapper;
						if (wrapper) {
							let playerEl = document.getElementById(self.editorYtPlayerId);
							if (!playerEl) {
								playerEl = document.createElement('div');
								playerEl.id = self.editorYtPlayerId;
								playerEl.className = 'w-100 h-100';
								wrapper.insertBefore(playerEl, wrapper.firstChild);
							}
						}
						window.__editorYtPlayer = new window.YT.Player(self.editorYtPlayerId, {
							height: '100%',
							width: '100%',
							videoId: videoId,
							playerVars: {
								controls: 0,
								disablekb: 1,
								modestbranding: 1,
								rel: 0,
								cc_load_policy: 0,
								iv_load_policy: 3
							},
							events: {
								'onReady': self.onEditorPlayerReady,
								'onStateChange': self.onEditorPlayerStateChange
							}
						});
					};

					let checkCount = 0;
					const checkYT = setInterval(() => {
						checkCount++;
						let el = document.getElementById(self.editorYtPlayerId);
						const wrapper = self.$refs.editorYtWrapper || (el ? el.parentElement : document.querySelector('.video-preview-box'));
						if (wrapper && !el) {
							el = document.createElement('div');
							el.id = self.editorYtPlayerId;
							el.className = 'w-100 h-100';
							wrapper.insertBefore(el, wrapper.firstChild);
						}
						if (window.YT && window.YT.Player && (el || wrapper)) {
							clearInterval(checkYT);
							init();
						} else if (checkCount > 80) { // Timeout 8s
							clearInterval(checkYT);
						}
					}, 100);
				});
			},
			startEditorTimer() {
				if (this.editorUpdateTimerInterval) {
					clearInterval(this.editorUpdateTimerInterval);
				}
				this.editorUpdateTimerInterval = setInterval(() => {
					if (this.isDraggingSlider) return;
					
					const player = window.__editorYtPlayer;
					if (this.editorVideoType === 'youtube' && player && typeof player.getCurrentTime === 'function') {
						try {
							const cur = player.getCurrentTime();
							const dur = player.getDuration();
							// Một số trình duyệt/YouTube iframe không phát đủ onStateChange; đọc state định kỳ để nút Play/Pause không bị lệch.
							if (typeof player.getPlayerState === 'function') {
								const playerState = Number(player.getPlayerState());
								if (playerState === 1) this.editorVideoPlaying = true;
								else if (playerState === 0 || playerState === 2 || playerState === 5) this.editorVideoPlaying = false;
							}
							if (dur && dur > 0) {
								this.editorVideoDuration = Math.floor(dur);
							}
							if (typeof cur === 'number' && !isNaN(cur) && cur >= 0) {
								this.editorVideoCurrentTime = Math.floor(cur);
							}
						} catch(e) {}
					} else if (this.editorVideoType === 'video' && this.$refs.editorHtmlPlayer) {
						const cur = this.$refs.editorHtmlPlayer.currentTime;
						const dur = this.$refs.editorHtmlPlayer.duration;
						if (dur && dur > 0) {
							this.editorVideoDuration = Math.floor(dur);
						}
						if (typeof cur === 'number' && !isNaN(cur) && cur >= 0) {
							this.editorVideoCurrentTime = Math.floor(cur);
						}
					}
				}, 250);
			},
			onEditorPlayerReady(event) {
				const player = event.target;
				window.__editorYtPlayer = player;
				try {
					this.editorVideoDuration = Math.floor(player.getDuration() || 0);
				} catch(e) {}
				this.disableYtCC(player);
				this.startEditorTimer();
			},
			onEditorPlayerStateChange(event) {
				// Dùng cả hằng số API và mã 1 để tương thích khi PlayerState chưa sẵn sàng lúc callback đầu tiên.
				const playingState = Number(window.YT?.PlayerState?.PLAYING || 1);
				if (Number(event?.data) === playingState) {
					this.editorVideoPlaying = true;
					this.disableYtCC(event.target);
					this.startEditorTimer();
				} else if ([0, 2, 5].includes(Number(event?.data))) {
					this.editorVideoPlaying = false;
				}
			},
			disableYtCC(player) {
				if (!player) return;
				try {
					if (typeof player.unloadModule === 'function') {
						player.unloadModule('captions');
						player.unloadModule('cc');
					}
					if (typeof player.setOption === 'function') {
						player.setOption('captions', 'track', {});
						player.setOption('cc', 'track', {});
					}
				} catch (e) {
					console.warn("Lỗi tắt phụ đề YouTube", e);
				}
			},
			toggleEditorPlay() {
				const player = window.__editorYtPlayer;
				if (this.editorVideoType === 'youtube' && player) {
					if (this.editorVideoPlaying) {
						if (typeof player.pauseVideo === 'function') {
							player.pauseVideo();
						}
					} else {
						if (typeof player.playVideo === 'function') {
							player.playVideo();
						}
					}
				} else if (this.editorVideoType === 'video' && this.$refs.editorHtmlPlayer) {
					if (this.editorVideoPlaying) {
						this.$refs.editorHtmlPlayer.pause();
					} else {
						this.$refs.editorHtmlPlayer.play();
					}
				}
			},
			onTimelineTrackMouseDown(e) {
				if (e.target && e.target.closest && e.target.closest('.interaction-marker-dot')) {
					return;
				}
				const track = this.$refs.timelineTrack;
				if (!track) return;
				
				this.isDraggingSlider = true;
				const updateTimeFromEvent = (event) => {
					const rect = track.getBoundingClientRect();
					const clientX = event.clientX || (event.touches && event.touches[0] ? event.touches[0].clientX : 0);
					let ratio = (clientX - rect.left) / rect.width;
					if (ratio < 0) ratio = 0;
					if (ratio > 1) ratio = 1;
					const dur = this.editorVideoDuration || 1;
					this.editorVideoCurrentTime = Math.floor(ratio * dur);
				};

				updateTimeFromEvent(e);

				const onMouseMove = (event) => {
					if (this.isDraggingSlider) {
						updateTimeFromEvent(event);
					}
				};

				const onMouseUp = () => {
					window.removeEventListener('mousemove', onMouseMove);
					window.removeEventListener('touchmove', onMouseMove);
					window.removeEventListener('mouseup', onMouseUp);
					window.removeEventListener('touchend', onMouseUp);
					if (this.isDraggingSlider) {
						this.isDraggingSlider = false;
						this.seekEditorVideo(this.editorVideoCurrentTime);
					}
				};

				window.addEventListener('mousemove', onMouseMove);
				window.addEventListener('touchmove', onMouseMove);
				window.addEventListener('mouseup', onMouseUp);
				window.addEventListener('touchend', onMouseUp);
			},
			onEditorSliderEnd(val) {
				this.isDraggingSlider = false;
				let sec = val;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.editorVideoCurrentTime;
				}
				this.seekEditorVideo(sec);
			},
			onEditorSliderChange(val) {
				let sec = val;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.editorVideoCurrentTime;
				}
				this.seekEditorVideo(sec);
			},
			seekEditorVideo(seconds) {
				let sec = seconds;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.editorVideoCurrentTime;
				}
				sec = Math.floor(Number(sec) || 0);
				this.editorVideoCurrentTime = sec;
				const player = window.__editorYtPlayer;
				if (this.editorVideoType === 'youtube' && player && typeof player.seekTo === 'function') {
					player.seekTo(sec, true);
				} else if (this.editorVideoType === 'video' && this.$refs.editorHtmlPlayer) {
					this.$refs.editorHtmlPlayer.currentTime = sec;
				}
			},
			onEditorHtmlTimeUpdate(event) {
				if (!this.isDraggingProgress && !this.isDraggingMarker) {
					this.editorVideoCurrentTime = event.target.currentTime || 0;
				}
			},
			onEditorHtmlMetadata(event) {
				this.editorVideoDuration = Math.floor(event.target.duration || 0);
			},
			formatTime(seconds) {
				if (!seconds || isNaN(seconds)) return '00:00';
				const h = Math.floor(seconds / 3600);
				const m = Math.floor((seconds % 3600) / 60);
				const s = Math.floor(seconds % 60);
				
				const mm = m < 10 ? '0' + m : m;
				const ss = s < 10 ? '0' + s : s;
				
				if (h > 0) {
					const hh = h < 10 ? '0' + h : h;
					return `${hh}:${mm}:${ss}`;
				}
				return `${mm}:${ss}`;
			},
			parseTimeToSeconds(timeStr) {
				if (!timeStr) return 0;
				// Hỗ trợ định dạng HH:MM:SS hoặc MM:SS hoặc SS
				const parts = String(timeStr).split(':').map(Number);
				if (parts.some(isNaN)) return 0;
				
				if (parts.length === 3) {
					// HH:MM:SS
					return parts[0] * 3600 + parts[1] * 60 + parts[2];
				} else if (parts.length === 2) {
					// MM:SS
					return parts[0] * 60 + parts[1];
				} else if (parts.length === 1) {
					// SS
					return parts[0];
				}
				return 0;
			},
			onInteractionTimeChange(item, val) {
				let text = val;
				if (val && typeof val === 'object') {
					text = val.target ? val.target.value : '';
				}
				const sec = this.parseTimeToSeconds(text);
				item.time = sec;
				if (item.timeMarker !== undefined) item.timeMarker = sec;
			},
			startDragMarker(item, event) {
				const track = this.$refs.timelineTrack;
				if (!track) return;

				this.isDraggingMarker = true;
				this.selectedMarkerId = item.id;

				const updateMarkerTime = (e) => {
					const clientX = e.touches ? e.touches[0].clientX : e.clientX;
					const rect = track.getBoundingClientRect();
					let relX = clientX - rect.left;
					relX = Math.max(0, Math.min(relX, rect.width));
					const percent = relX / rect.width;
					const newTime = Math.round(percent * (this.editorVideoDuration || 100));
					item.time = newTime;
					if (item.timeMarker !== undefined) item.timeMarker = newTime;
				};

				const moveHandler = (e) => {
					updateMarkerTime(e);
				};

				const upHandler = () => {
					this.isDraggingMarker = false;
					window.removeEventListener('mousemove', moveHandler);
					window.removeEventListener('mouseup', upHandler);
					window.removeEventListener('touchmove', moveHandler);
					window.removeEventListener('touchend', upHandler);
				};

				window.addEventListener('mousemove', moveHandler);
				window.addEventListener('mouseup', upHandler);
				window.addEventListener('touchmove', moveHandler);
				window.addEventListener('touchend', upHandler);
			},
			addVideoInteraction() {
				const time = this.videoInteractions.length > 0 ? this.videoInteractions[this.videoInteractions.length - 1].time + 10 : 10;
				this.videoInteractions.push({
					id: 'int_' + Math.random().toString(36).substr(2, 9),
					time: time,
					prompt: 'Câu hỏi trắc nghiệm...',
					question: {
						type: 'QUIZ_SINGLE_CHOICE',
						content: {
							prompt: 'Nhập câu hỏi...',
							options: [
								{ id: 'opt_1', text: 'Lựa chọn A' },
								{ id: 'opt_2', text: 'Lựa chọn B' }
							],
							correctAnswer: 'opt_1'
						}
					}
				});
			},
			addVideoInteractionAtCurrentTime() {
				let seconds = 0;
				const player = window.__editorYtPlayer;
				if (this.editorVideoType === 'youtube' && player && typeof player.getCurrentTime === 'function') {
					try {
						seconds = Math.floor(player.getCurrentTime() || 0);
					} catch(e) {
						seconds = Math.floor(this.editorVideoCurrentTime || 0);
					}
				} else if (this.editorVideoType === 'video' && this.$refs.editorHtmlPlayer) {
					seconds = Math.floor(this.$refs.editorHtmlPlayer.currentTime || 0);
				} else {
					seconds = Math.floor(this.editorVideoCurrentTime || this.editorManualTime || 0);
				}
				if (!seconds || isNaN(seconds)) {
					seconds = Math.floor(this.editorVideoCurrentTime || 0);
				}

				this.videoInteractions.push({
					id: 'int_' + Math.random().toString(36).substr(2, 9),
					time: seconds,
					prompt: 'Câu hỏi tương tác...',
					question: {
						type: 'QUIZ_SINGLE_CHOICE',
						content: {
							prompt: 'Nhập câu hỏi...',
							options: [
								{ id: 'opt_1', text: 'Lựa chọn A' },
								{ id: 'opt_2', text: 'Lựa chọn B' }
							],
							correctAnswer: 'opt_1'
						}
					}
				});
				this.notify(`Đã thêm mốc tương tác tại thời gian ${this.formatTime(seconds)}!`);
			},
			stripHtml(html) {
				if (!html) return '';
				try {
					let doc = new DOMParser().parseFromString(String(html), 'text/html');
					let text = doc.body.textContent || doc.body.innerText || '';
					return text.replace(/[\r\n\t]+/g, ' ').replace(/\s+/g, ' ').trim();
				} catch(e) {
					return String(html).replace(/<[^>]*>?/gm, '').replace(/&[^;]+;/g, ' ').trim();
				}
			},
			getInteractionTime(item) {
				return Number(item?.timeMarker ?? item?.time ?? 0) || 0;
			},
			getInteractionQuestions(item) {
				if (Array.isArray(item?.questions)) return item.questions;
				return item?.question ? [item.question] : [];
			},
			isSupportedInteractionType(type) {
					return ['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_TRUE_FALSE', 'QUIZ_MATCHING',
						'QUIZ_ORDERING', 'QUIZ_DRAG_DROP_CATEGORIZE', 'QUIZ_FILL_IN_BLANK', 'QUIZ_CONNECTION',
						'SHORT_ANSWER', 'ESSAY'].includes(String(type || '').toUpperCase());
			},
			getInactiveInteractionQuestionCount(item) {
				return this.getInteractionQuestions(item).filter(question => question?.isActive === false || !this.isSupportedInteractionType(question?.type)).length;
			},
			getInactiveVideoQuestionCount() {
				return (this.videoInteractions || []).reduce((total, marker) => total + this.getInactiveInteractionQuestionCount(marker), 0);
			},
			normalizeInteractionMarker(item) {
				const marker = { ...(item || {}) };
				const questions = this.getInteractionQuestions(marker);
				marker.time = this.getInteractionTime(marker);
				marker.questions = questions;
				// Giữ alias question để các dữ liệu cũ và logic chỉnh sửa hiện tại vẫn hoạt động.
				marker.question = questions[0] || null;
				return marker;
			},
			serializeInteractionMarkers(items) {
				return (Array.isArray(items) ? items : []).map(item => {
					const marker = this.normalizeInteractionMarker(item);
					const result = { ...marker, questions: JSON.parse(JSON.stringify(marker.questions || [])) };
					delete result.question;
					// Ghi cả hai tên để tương thích dữ liệu cũ (time) và schema mới của Content Hub (timeMarker).
					result.timeMarker = marker.time;
					return result;
				});
			},
			getCleanPrompt(item) {
				if (!item) return 'Nhập câu hỏi...';
				let raw = null;
				const question = this.getInteractionQuestions(item)[0];
				if (question?.content?.prompt !== undefined && question?.content?.prompt !== null) {
					raw = question.content.prompt;
				} else if (item.prompt !== undefined && item.prompt !== null) {
					raw = item.prompt;
				}
				if (raw === null || raw === undefined) return 'Nhập câu hỏi...';
				let cleanText = this.stripHtml(raw);
				return cleanText ? cleanText : 'Nhập câu hỏi...';
			},
			removeVideoInteraction(index) {
				this.videoInteractions.splice(index, 1);
			},
			openInteractionDetail(item) {
				this.targetInteractionItem = item;
				// Deep clone item so editing in modal doesn't mutate outside table until confirmed
				this.editingInteraction = this.normalizeInteractionMarker(JSON.parse(JSON.stringify(item)));
				this.editingQuestionIndex = 0;
				if (!this.editingInteraction.questions.length) {
					this.editingInteraction.questions = [{
						type: 'QUIZ_SINGLE_CHOICE',
						content: {
							prompt: this.stripHtml(this.editingInteraction.prompt) || 'Nhập câu hỏi...',
							options: [
								{ id: 'opt_1', text: 'Lựa chọn A' },
								{ id: 'opt_2', text: 'Lựa chọn B' }
							],
							correctAnswer: 'opt_1'
						}
					}];
				}
				this.editingInteraction.question = this.editingInteraction.questions[0];
				this.isInteractionDetailOpen = true;
			},
			selectEditingQuestion(index) {
				this.editingQuestionIndex = Number(index) || 0;
				this.editingInteraction.question = this.editingInteraction.questions[this.editingQuestionIndex];
			},
			confirmInteractionDetail() {
				if (this.targetInteractionItem && this.editingInteraction) {
					let promptRaw = '';
					if (this.editingInteraction.question?.content?.prompt !== undefined) {
						promptRaw = this.editingInteraction.question.content.prompt;
					} else if (this.editingInteraction.prompt !== undefined) {
						promptRaw = this.editingInteraction.prompt;
					}
					const cleanText = this.stripHtml(promptRaw);
					
					// Copy question and prompt back to target item ONLY on confirm
					this.targetInteractionItem.questions = JSON.parse(JSON.stringify(this.editingInteraction.questions || [this.editingInteraction.question]));
					this.targetInteractionItem.question = this.targetInteractionItem.questions[0] || null;
					this.targetInteractionItem.prompt = cleanText;
				}
				this.isInteractionDetailOpen = false;
			},
			onInteractionTypeChange(newType) {
				if (!this.editingInteraction || !this.editingInteraction.question) return;
				const content = this.editingInteraction.question.content || {};
				const prompt = content.prompt || this.editingInteraction.prompt || 'Nhập câu hỏi...';
				
				if (newType === 'QUIZ_SINGLE_CHOICE') {
					this.editingInteraction.question.content = {
						prompt: prompt,
						options: [
							{ id: 'opt_1', text: 'Lựa chọn A' },
							{ id: 'opt_2', text: 'Lựa chọn B' }
						],
						correctAnswer: 'opt_1'
					};
				} else if (newType === 'QUIZ_MULTIPLE_CHOICE') {
					this.editingInteraction.question.content = {
						prompt: prompt,
						options: [
							{ id: 'opt_1', text: 'Lựa chọn A' },
							{ id: 'opt_2', text: 'Lựa chọn B' }
						],
						correctAnswers: ['opt_1']
					};
				} else if (newType === 'QUIZ_TRUE_FALSE') {
					this.editingInteraction.question.content = {
						prompt: prompt,
						options: [
							{ id: 'opt_1', text: 'Mệnh đề 1', correctAnswer: true, inCorrectAnswer: false }
						]
					};
				} else if (newType === 'QUIZ_MATCHING') {
					this.editingInteraction.question.content = {
						prompt: prompt,
						leftItems: [{ id: 'l1', text: 'Mục 1' }],
						rightItems: [{ id: 'r1', text: 'Ghép 1' }],
						pairs: [{ leftId: 'l1', rightId: 'r1' }]
					};
				} else if (newType === 'QUIZ_ORDERING') {
					this.editingInteraction.question.content = {
						prompt: prompt,
						items: [{ id: 'ord_1', text: 'Bước 1' }, { id: 'ord_2', text: 'Bước 2' }]
					};
				} else if (newType === 'QUIZ_DRAG_DROP_CATEGORIZE') {
					this.editingInteraction.question.content = {
						prompt: prompt,
						categories: [{ id: 'cat_1', title: 'Nhóm 1' }],
						items: [{ id: 'item_1', text: 'Vật phẩm 1', categoryId: 'cat_1' }]
					};
				} else if (newType === 'QUIZ_FILL_IN_BLANK') {
					this.editingInteraction.question.content = {
						prompt: prompt,
						parts: [
							{ type: 'text', value: 'Câu hỏi có chỗ trống: ' },
							{ type: 'blank', correctAnswer: 'đáp án' }
						]
					};
					} else if (newType === 'SHORT_ANSWER' || newType === 'ESSAY') {
						this.editingInteraction.question.content = {
							prompt: prompt,
							// Đáp án tham khảo chỉ được dùng ở màn giáo viên chấm bài.
							referenceAnswer: ''
						};
				} else if (newType === 'QUIZ_COMPOSITE') {
					this.editingInteraction.question.content = {
						title: prompt || 'Bộ câu hỏi tương tác',
						questions: [
							{
								type: 'QUIZ_SINGLE_CHOICE',
								content: {
									prompt: 'Nhập câu hỏi 1...',
									options: [
										{ id: 'opt_1', text: 'Lựa chọn A' },
										{ id: 'opt_2', text: 'Lựa chọn B' }
									],
									correctAnswer: 'opt_1'
								}
							},
							{
								type: 'QUIZ_TRUE_FALSE',
								content: {
									prompt: 'Nhập câu hỏi 2...',
									options: [
										{ id: 'opt_1', text: 'Mệnh đề 1', correctAnswer: true, inCorrectAnswer: false }
									]
								}
							}
						]
					};
				}
			},
			onVideoUrlChange(val) {
				if (!this.editableItem.DataJson) {
					this.editableItem.DataJson = {};
				}
				this.editableItem.DataJson.url = val;
			},
			resolveFileUrl(value) {
				if (!value || typeof value !== 'string') return '';
				if (/^(https?:|blob:|data:)/i.test(value)) return value;
				const baseUrl = vueData?.v_Set?.urlReadFile || '';
				return baseUrl ? baseUrl.replace(/\/$/, '') + '/' + value.replace(/^\//, '') : value;
			},
			// Audio không dùng route viewer/download vì trình phát cần response file trực tiếp từ FileData.
			normalizeDirectMediaUrl(value) {
				return String(value || '').trim().replace(/\/(?:viewer|download)\/FileData\//i, '/FileData/');
			},
			onAudioUrlChange(val) {
				if (!this.editableItem.DataJson || typeof this.editableItem.DataJson !== 'object') this.editableItem.DataJson = {};
				this.editableItem.DataJson.url = val;
				this.editableItem.DataJson.audioUrl = val;
			},
			onImageUrlChange(val) {
				if (!this.editableItem.DataJson || typeof this.editableItem.DataJson !== 'object') this.editableItem.DataJson = {};
				this.editableItem.DataJson.url = val;
			},
			buildSavePayload(item, fallbackItem = this.editableItem) {
				const payload = { ...(item || {}) };
				const fallback = fallbackItem || {};

				payload.HocLieuID = payload.HocLieuID ?? fallback.HocLieuID ?? this.item?.HocLieuID;
				payload.ParentID = payload.ParentID ?? fallback.ParentID ?? 0;
				payload.LoaiNoiDung = payload.LoaiNoiDung ?? fallback.LoaiNoiDung;
				payload.TenNoiDung = payload.TenNoiDung ?? fallback.TenNoiDung ?? '';
				payload.ThuTu = Number.isFinite(Number(payload.ThuTu))
					? Number(payload.ThuTu)
					: (Number.isFinite(Number(fallback.ThuTu)) ? Number(fallback.ThuTu) : 0);

				return payload;
			},
			ensureDataJsonObject(item) {
				if (!item) return {};
				if (item.DataJson && typeof item.DataJson === 'object') return item.DataJson;

				try {
					item.DataJson = item.DataJson ? JSON.parse(item.DataJson) : {};
				} catch (e) {
					item.DataJson = {};
				}

				return item.DataJson;
			},
			getUploadManager() {
				if (!window.UploadManager) {
					this.notify("UploadManager chưa được khởi tạo.", "error");
					return null;
				}
				return window.UploadManager;
			},
			getSlideContentType(fileType, fileName = '') {
				const value = `${fileType || ''} ${fileName || ''}`.toLowerCase();
				// Chuẩn hóa theo MIME hoặc đuôi file để DOC/PDF không phụ thuộc browser có trả đúng MIME hay không.
				if (/pdf|application\/pdf/.test(value)) return 'PDF';
				if (/pptx?|powerpoint|presentation/.test(value)) return 'PPT';
				if (/xlsx?|excel|spreadsheet/.test(value)) return 'XLSX';
				// MIME Office có chuỗi "officedocument", vì vậy DOC phải kiểm tra sau PPT/XLS.
				if (/docx?|msword|wordprocessingml/.test(value)) return 'DOCX';
				return '';
			},
			async ensureDraftNode(file) {
				const targetItem = this.editableItem;
				if (targetItem.NoiDungID) return true;

				const draftItem = this.buildSavePayload({
					HocLieuID: targetItem.HocLieuID,
					ParentID: targetItem.ParentID || 0,
					LoaiNoiDung: targetItem.LoaiNoiDung,
					TenNoiDung: targetItem.TenNoiDung || file.name,
					ThuTu: targetItem.ThuTu,
					DataJson: JSON.stringify({}),
				}, targetItem);
				const result = await fetchPromise('lms/FP_NoiDung_Save', draftItem, { cache: false });
				const saved = Array.isArray(result) ? result[0] : result;
				if (!saved?.NoiDungID) {
					this.notify('Không thể tạo mục nháp để tải file.', 'error');
					return false;
				}

				Object.assign(targetItem, saved);
				this.ensureDataJsonObject(targetItem);
				this.$emit('update-item', saved);
				this.$emit('refresh-tree');
				return true;
			},
			buildLmsFileMetadata(uploaded, file, targetItem) {
				const contentType = uploaded.FILE_CONTENTTYPE || file.type || '';
				return {
					uploadSource: 'db',
					fileId: uploaded.FILE_ID,
					fileName: file.name || uploaded.FILE_NAME,
					contentType,
					fileSize: Number(uploaded.FILE_SIZE || file.size || 0),
					url: uploaded.FILE_URL || `/FileData/${uploaded.FILE_ID}`,
					title: file.name || uploaded.FILE_NAME,
					slideType: this.getSlideContentType(contentType, file.name),
					mediaType: ['AUDIO', 'IMAGE'].includes(targetItem.LoaiNoiDung) ? targetItem.LoaiNoiDung.toLowerCase() : undefined,
					origin: 'HOC_LIEU',
					sourceHocLieuID: targetItem.HocLieuID,
					sourceNoiDungID: targetItem.NoiDungID,
				};
			},
			async saveUploadedFileToNode(targetItem, metadata) {
				const nodeDataList = await fetchPromise('lms/FP_NoiDung_GetDetail', {
					NoiDungID: targetItem.NoiDungID,
				});
				const nodeData = Array.isArray(nodeDataList) ? nodeDataList[0] : nodeDataList;
				if (!nodeData) throw new Error('Không tìm thấy mục nội dung vừa tạo.');

				// Giữ lại reference của bản archive LMS nếu callback upload nền chạy trước
				// callback phát hành chính; nhờ đó lần lưu URL YouTube/Drive không làm mất ID để dọn sau này.
				const currentMetadata = this.ensureDataJsonObject(nodeData);
				const mergedMetadata = { ...metadata };
				if (currentMetadata.archiveFileId) {
					mergedMetadata.archiveFileId = currentMetadata.archiveFileId;
					mergedMetadata.archiveFileName = currentMetadata.archiveFileName;
					mergedMetadata.archivePurpose = currentMetadata.archivePurpose;
				}
				nodeData.DataJson = JSON.stringify(mergedMetadata);
				await fetchPromise('lms/FP_NoiDung_Save', this.buildSavePayload(nodeData, targetItem), { cache: false });

				// Upload thành công chưa đủ: phải đọc lại node để chắc chắn FILE_ID đã được ghi vào
				// tblNoiDungHocLieu_FP. Nếu bước Save bị lỗi/ngắt, không báo thành công giả cho người dùng.
				const verifyList = await fetchPromise('lms/FP_NoiDung_GetDetail', {
					NoiDungID: targetItem.NoiDungID,
				}, { cache: false });
				const verifyNode = Array.isArray(verifyList) ? verifyList[0] : verifyList;
				const verifyMetadata = this.ensureDataJsonObject(verifyNode);
				const expectedFileId = metadata.fileId || metadata.FILE_ID;
				const savedFileId = verifyMetadata.fileId || verifyMetadata.FILE_ID || verifyMetadata.FileID;
				if (expectedFileId && String(savedFileId || '') !== String(expectedFileId)) {
					throw new Error('File đã upload nhưng chưa gắn được vào nội dung LMS (NoiDungID ' + targetItem.NoiDungID + ').');
				}
				targetItem.DataJson = verifyMetadata;
				return verifyMetadata;
			},
			async saveArchiveReferenceToNode(targetItem, archiveMetadata) {
				const nodeDataList = await fetchPromise('lms/FP_NoiDung_GetDetail', {
					NoiDungID: targetItem.NoiDungID,
				});
				const nodeData = Array.isArray(nodeDataList) ? nodeDataList[0] : nodeDataList;
				if (!nodeData) throw new Error('Không tìm thấy mục nội dung để lưu reference archive.');

				// Chỉ lưu metadata tham chiếu, không lưu thêm binary vào DataJson của node.
				const currentMetadata = this.ensureDataJsonObject(nodeData);
				const mergedMetadata = {
					...currentMetadata,
					archiveFileId: archiveMetadata.fileId,
					archiveFileName: archiveMetadata.fileName,
					archivePurpose: archiveMetadata.archivePurpose,
					resourceNodeId: archiveMetadata.resourceNodeId || currentMetadata.resourceNodeId || null,
					resourceLibraryId: archiveMetadata.resourceLibraryId || currentMetadata.resourceLibraryId || null,
				};
				nodeData.DataJson = JSON.stringify(mergedMetadata);
				await fetchPromise('lms/FP_NoiDung_Save', this.buildSavePayload(nodeData, targetItem), { cache: false });
				targetItem.DataJson = mergedMetadata;
			},
			async registerUploadedFileInResourceLibrary(targetItem, metadata) {
				const response = await fetchPromise('lms/FP_TaiNguyen_File_Register', {
					KhoiID: this.resourceContext?.KhoiID ?? null,
					MonHocID: this.resourceContext?.MonHocID ?? null,
					BoSachID: this.resourceContext?.BoSachID ?? null,
					TenNoiDung: metadata.fileName,
					LoaiNoiDung: targetItem.LoaiNoiDung,
					DataJson: JSON.stringify(metadata),
				}, { cache: false });
				const registered = Array.isArray(response) ? response[0] : response;
				// Ghi lại node tài nguyên để lần thay media sau này xóa được cả bản archive
				// trong Content Hub, không chỉ xóa file Drive/YouTube đang hiển thị.
				metadata.resourceNodeId = registered?.NoiDungID || null;
				metadata.resourceLibraryId = registered?.HocLieuID || null;
				return metadata;
			},
			archiveFileToLmsInBackground(file, targetItem, uploadToken) {
				const uploadManager = this.getUploadManager();
				if (!uploadManager) return;

				uploadManager.uploadLmsFile(file, {
						onComplete: async response => {
							try {
							const uploaded = response?.Files?.[0];
							if (!uploaded?.FILE_ID) throw new Error('API lưu trữ không trả về FILE_ID.');

							const archiveMetadata = {
								...this.buildLmsFileMetadata(uploaded, file, targetItem),
								archivePurpose: 'AUDIT',
								publishSource: targetItem.LoaiNoiDung === 'VIDEO' ? 'youtube' : 'ggdrive',
							};
							await this.registerUploadedFileInResourceLibrary(targetItem, archiveMetadata);
							// Upload archive chạy nền nên có thể hoàn tất sau khi người dùng đã chọn file mới.
							// Nếu token không còn khớp, dọn ngay bản archive cũ để không tạo file mồ côi.
							if (uploadToken && this.ensureDataJsonObject(targetItem).uploadToken !== uploadToken) {
								if (archiveMetadata.resourceNodeId) {
									await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: archiveMetadata.resourceNodeId }, { cache: false });
								}
								await this.deleteDbUploadedFile({ fileId: archiveMetadata.fileId });
								return;
							}
							await this.saveArchiveReferenceToNode(targetItem, archiveMetadata);
							this.notify(`Đã lưu bản kiểm tra “${archiveMetadata.fileName}” vào kho LMS.`);
						} catch (error) {
							console.error('Background LMS archive failed:', error);
							this.notify(
								`Nội dung vẫn được phát hành, nhưng chưa lưu được bản kiểm tra của “${file.name}”.`,
								'warning'
							);
						}
					},
					onError: error => {
						console.error('Background LMS archive upload failed:', error);
						this.notify(
							`Nội dung vẫn tiếp tục phát hành, nhưng lưu nền “${file.name}” vào LMS thất bại.`,
							'warning'
						);
					},
				});
			},
			async savePublishedMetadata(targetItem, metadata) {
				targetItem.DataJson = metadata;
				await this.saveUploadedFileToNode(targetItem, metadata);
				this.$emit('refresh-tree');
			},
			async prepareCurrentResourceForReplacement() {
				const targetItem = this.editableItem;
				const currentMetadata = this.ensureDataJsonObject(targetItem);
				if (!Object.keys(currentMetadata).length) return true;

				try {
					// Xóa vật lý media cũ trước khi upload mới; Content Hub dùng chung chỉ bị gỡ liên kết.
					await this.deleteCurrentFileResource(currentMetadata);
					targetItem.DataJson = {};
					this.tempVideoUrl = '';
					this.tempAudioUrl = '';
					this.tempImageUrl = '';
					return true;
				} catch (error) {
					console.error('Could not remove current resource before replacement:', error);
					this.notify('Không thể xóa nội dung cũ, nên chưa bắt đầu tải nội dung mới.', 'error');
					return false;
				}
			},
			onDocumentFileSelected(value) {
				// Chuẩn hóa cả native change event, File, File[] và FileList để không phụ thuộc phiên bản Vuetify/FUI.
				const selectedFile = value?.target?.files?.[0]
					|| (Array.isArray(value) ? value[0] : value?.[0] || value);
				if (!selectedFile || typeof selectedFile !== 'object') return;

				const uploadKey = [
					selectedFile.name || '',
					selectedFile.size || 0,
					selectedFile.lastModified || 0,
				].join('|');
				const now = Date.now();
				// Cùng một lần chọn file có thể gọi cả update:modelValue và change; chỉ cho phép một request upload.
				if (this.lastDocumentUploadKey === uploadKey && now - this.lastDocumentUploadAt < 1500) return;
				this.lastDocumentUploadKey = uploadKey;
				this.lastDocumentUploadAt = now;
				return this.uploadFileGGDrive(selectedFile);
			},
			async uploadFileGGDrive(file) {
				const selectedFile = Array.isArray(file) ? file[0] : file;
				if (!selectedFile) return;
				const uploadManager = this.getUploadManager();
				if (!uploadManager) return;
				const targetItem = this.editableItem;
				if (!await this.prepareCurrentResourceForReplacement()) return;
				const uploadToken = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
				// Ghi token tạm ngay khi bắt đầu upload để callback archive cũ nhận biết việc thay file.
				targetItem.DataJson = { ...this.ensureDataJsonObject(targetItem), uploadToken };

				const isWordDocument = /\.docx?$/i.test(selectedFile.name || '')
					|| /msword|wordprocessingml/.test(String(selectedFile.type || '').toLowerCase());
				if (isWordDocument) {
					// DOC/DOCX phải lưu trực tiếp vào tblFileData như PDF để viewer dùng FileID LMS;
					// không đưa Word qua Google Drive vì Drive ID không phải FileID của viewer nội bộ.
					this.ensureDraftNode(selectedFile).then(ok => {
						if (!ok) return;
						this.notify('Đang lưu ' + selectedFile.name + ' vào kho file LMS...', 'info');
						uploadManager.uploadLmsFile(selectedFile, {
						onComplete: async response => {
								try {
									const uploaded = response?.Files?.[0];
									if (!uploaded?.FILE_ID) throw new Error('API lưu trữ không trả về FILE_ID.');

									const metadata = this.buildLmsFileMetadata(uploaded, selectedFile, targetItem);
									if (this.ensureDataJsonObject(targetItem).uploadToken !== uploadToken) {
										this.deleteDbUploadedFile({ fileId: uploaded.FILE_ID });
										return;
									}

									await this.savePublishedMetadata(targetItem, metadata);
									this.notify('Đã lưu “' + selectedFile.name + '” vào kho file LMS.');
								} catch (error) {
									this.notify(error.message || 'Không thể lưu file Word vào LMS.', 'error');
								}
							},
							onError: error => this.notify(
									error?.message || ('Lưu ' + selectedFile.name + ' vào LMS thất bại.'),
								'error'
							),
						});
					}).catch(error => this.notify(error.message || 'Không thể tạo mục nội dung để lưu file LMS.', 'error'));
					return;
				}

				// Redefine selectedFile.type so Google Drive API automatically converts PPTX/PPT files to native Google Slides format
				const isPPT = /\.pptx?$/i.test(selectedFile.name || '') || /powerpoint|presentation/.test(String(selectedFile.type || '').toLowerCase());
				if (isPPT) {
					try {
						Object.defineProperty(selectedFile, 'type', {
							value: 'application/vnd.google-apps.presentation',
							writable: true,
							configurable: true
						});
					} catch (e) {
						console.warn("Could not override file type:", e);
					}
				}

				if (!await this.ensureDraftNode(selectedFile)) return;
				this.archiveFileToLmsInBackground(selectedFile, targetItem, uploadToken);
				this.notify(`Đang phát hành ${selectedFile.name} lên Google Drive...`, 'info');
				uploadManager.uploadLmsGoogleDrive(selectedFile, {
					folderPath: `${targetItem.TenHocLieu || this.item?.TenHocLieu || 'HocLieu'}/${vueData.user.UserID}`,
					onComplete: async fileDrive => {
						try {
							const slideType = this.getSlideContentType(selectedFile.type, selectedFile.name);
							// Google Slides preview không phát được audio/ảnh; hai loại media này cần URL tải trực tiếp.
							const isDirectMedia = ['AUDIO', 'IMAGE'].includes(targetItem.LoaiNoiDung);
							const driveUrl = isDirectMedia
								? `https://drive.google.com/uc?export=download&id=${fileDrive.id}`
								: (slideType === 'PDF' || slideType === 'DOCX')
									? `https://drive.google.com/file/d/${fileDrive.id}/preview`
									: `https://docs.google.com/presentation/d/${fileDrive.id}/preview`;

							const metadata = {
								title: selectedFile.name,
								fileName: selectedFile.name,
								contentType: selectedFile.type || '',
								fileSize: Number(selectedFile.size || 0),
								uploadSource: 'ggdrive',
								uploadToken,
								driveFileId: fileDrive.id,
								url: driveUrl,
							slideType: slideType,
								mediaType: ['AUDIO', 'IMAGE'].includes(targetItem.LoaiNoiDung) ? targetItem.LoaiNoiDung.toLowerCase() : undefined,
							};
							// Nếu người dùng đã chọn file khác trong lúc Drive upload này còn chạy, dọn file vừa tạo
							// và không cho callback cũ ghi đè metadata của file mới.
							if (this.ensureDataJsonObject(targetItem).uploadToken !== uploadToken) {
								await this.deleteGoogleDriveFile(metadata);
								return;
							}
							await this.savePublishedMetadata(targetItem, metadata);
							if (targetItem.LoaiNoiDung === 'AUDIO') this.tempAudioUrl = metadata.url;
							if (targetItem.LoaiNoiDung === 'IMAGE') this.tempImageUrl = metadata.url;
							this.notify(`Đã phát hành “${selectedFile.name}” lên Google Drive.`);
						} catch (error) {
							console.error('Google Drive post-upload failed:', error);
							this.notify(error.message || 'Không thể hoàn tất phát hành Google Drive.', 'error');
						}
					},
					onError: error => this.notify(
						error?.message || `Phát hành ${selectedFile.name} lên Google Drive thất bại.`,
						'error'
					),
				});
			},
			async uploadFileYoutube(file) {
				const selectedFile = Array.isArray(file) ? file[0] : file;
				if (!selectedFile) return;
				const uploadManager = this.getUploadManager();
				if (!uploadManager) return;
				const targetItem = this.editableItem;
				if (!await this.prepareCurrentResourceForReplacement()) return;

				// 1. Tạo blob URL xem trước ngay lập tức để người dùng xem video và thiết lập tương tác
				if (this.localVideoBlobUrl) {
					try { URL.revokeObjectURL(this.localVideoBlobUrl); } catch (e) {}
				}
				this.localVideoBlobUrl = URL.createObjectURL(selectedFile);
				this.tempVideoUrl = this.localVideoBlobUrl;

				if (!await this.ensureDraftNode(selectedFile)) return;
				this.notify(`Đang phát hành ${selectedFile.name} lên YouTube...`, 'info');

				const taskId = await uploadManager.uploadLmsYoutube(selectedFile, {
					playlistName: targetItem.TenHocLieu || this.item?.TenHocLieu || 'HocLieu',
					title: selectedFile.name,
					onComplete: async videoResult => {
						try {
							const metadata = {
								title: selectedFile.name,
								fileName: selectedFile.name,
								contentType: selectedFile.type || 'video/*',
								fileSize: Number(selectedFile.size || 0),
								uploadSource: 'youtube',
								videoId: videoResult.id,
								url: videoResult.source,
								interactions: this.videoInteractions || []
							};
							await this.savePublishedMetadata(targetItem, metadata);
							// 2. Chuyển sang link YouTube chính thức
							this.tempVideoUrl = videoResult.source;
							this.notify(`Đã phát hành “${selectedFile.name}” lên YouTube.`);
						} catch (error) {
							console.error('YouTube post-upload failed:', error);
							this.notify(error.message || 'Không thể hoàn tất phát hành YouTube.', 'error');
						}
					},
					onError: error => this.notify(
						error?.message || `Phát hành ${selectedFile.name} lên YouTube thất bại.`,
						'error'
					),
				});
				this.currentUploadTaskId = taskId;
			},


			async onUploadFile(file) {
				const oldFile = typeof this.editableItem.DataJson === 'object' && this.editableItem.DataJson !== null
					? { ...this.editableItem.DataJson }
					: this.editableItem.DataJson;
				const _file = file.Files[0]
				const contentType = this.getSlideContentType(_file.FILE_CONTENTTYPE, _file.FILE_NAME)

				await this.deleteOldFileAfterReplace(oldFile);

				this.editableItem.DataJson.slideType = contentType
				this.editableItem.DataJson.title = _file.FILE_NAME
				this.editableItem.DataJson.fileName = _file.FILE_NAME
				this.editableItem.DataJson.uploadSource = 'db'
				this.editableItem.DataJson.fileId = _file.FILE_ID
				this.editableItem.DataJson.url = _file.FILE_URL
			},
			async saveSlideLink() {
				if (!this.inputSlideLink) return;
				const link = this.inputSlideLink.trim();
				
				let metadata = null;

				// Case 1: Canva Link
				if (link.includes('canva.com')) {
					// Clean up any existing query parameters
					let cleanUrl = link.split('?')[0].trim();
					if (cleanUrl.endsWith('/')) {
						cleanUrl = cleanUrl.slice(0, -1);
					}

					let embedUrl = '';
					if (cleanUrl.includes('/view')) {
						// E.g. https://www.canva.com/design/DAG2e7KcKXw/80_2b2QO75d4MJVYW7OaWg/view -> view?embed
						embedUrl = cleanUrl + '?embed';
					} else if (cleanUrl.includes('/watch')) {
						// E.g. /watch -> watch?embed or view?embed
						embedUrl = cleanUrl.replace('/watch', '/view') + '?embed';
					} else {
						// Fallback: append /view?embed
						embedUrl = cleanUrl + '/view?embed';
					}

					// Extract designId (the part after /design/)
					const designIdMatch = cleanUrl.match(/\/design\/([^\/]+)/);
					const designId = designIdMatch ? designIdMatch[1] : 'canva-design';

					metadata = {
						title: 'Canva Presentation',
						fileName: 'Canva Presentation',
						contentType: 'text/html',
						fileSize: 0,
						uploadSource: 'canva',
						driveFileId: designId,
						url: embedUrl,
						slideType: 'PPT',
					};
				} else {
					// Case 2: Google Drive / Slides Link
					const reg = /\/d\/([^\/]+)/;
					const match = link.match(reg);
					if (!match) {
						this.notify("Đường link Google Slides / Drive không hợp lệ. Vui lòng kiểm tra lại.", "error");
						return;
					}
					
					const fileId = match[1];
					const isPresentation = link.includes('presentation');
					
					metadata = {
						title: isPresentation ? 'Google Slides Presentation' : 'Google Drive File',
						fileName: isPresentation ? 'Google Slides' : 'Google Drive File',
						contentType: isPresentation ? 'application/vnd.google-apps.presentation' : '',
						fileSize: 0,
						uploadSource: 'ggdrive',
						driveFileId: fileId,
						url: isPresentation 
							? `https://docs.google.com/presentation/d/${fileId}/preview`
							: `https://drive.google.com/file/d/${fileId}/preview`,
						slideType: 'PPT',
					};
				}
				
				const targetItem = this.editableItem;
				if (!await this.prepareCurrentResourceForReplacement()) return;
				if (!targetItem.NoiDungID) {
					// Ensure draft node exists if it's a new node
					if (!await this.ensureDraftNode({ name: metadata.title, size: 0, type: metadata.contentType })) return;
				}
				
				// Save metadata to database
				await this.savePublishedMetadata(targetItem, metadata);
				
				// Register in resource library
				try {
					await this.registerUploadedFileInResourceLibrary(targetItem, metadata);
					// Registration trả về ID node; lưu lại vào DataJson để lần upload tiếp theo
					// có đủ thông tin dọn node archive cũ trước khi tạo bản mới.
					await this.saveUploadedFileToNode(targetItem, metadata);
				} catch (e) {
					console.error("Resource library registration failed:", e);
				}
				
				this.inputSlideLink = '';
				this.notify(link.includes('canva.com') ? "Đã liên kết link Canva thành công!" : "Đã liên kết link Google Slides thành công!");
			},
			async onCloseFile(e) {
				const currentFile = typeof this.editableItem.DataJson === 'object' && this.editableItem.DataJson !== null
					? { ...this.editableItem.DataJson }
					: this.editableItem.DataJson;
				if (!currentFile || (typeof currentFile === 'object' && !Object.keys(currentFile).length)) {
					this.editableItem.DataJson = {};
					return;
				}

				// Chỉ gỡ liên kết khỏi node học liệu. FileData và metadata trong kho tài
				// nguyên có thể vẫn đang được tái sử dụng nên không được xóa vật lý tại đây.
				this.editableItem.DataJson = {};
				this.notify("Đã gỡ tập tin khỏi nội dung. File vẫn còn trong kho tài nguyên.");
			},
			async deleteCurrentFileResource(fileInfo) {
				if (this.isSharedLinkedFile(fileInfo)) {
					// File import từ Content Hub chỉ được gỡ khỏi node hiện tại, không xóa file gốc.
					return;
				}
				const resourceNodeDeleted = Boolean(fileInfo?.resourceNodeId);
				if (resourceNodeDeleted) {
					await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: fileInfo.resourceNodeId }, { cache: false });
				}
				if (this.isYouTubeFile(fileInfo)) {
					await this.deleteYouTubeVideo(fileInfo);
				} else if (this.isGoogleDriveFile(fileInfo)) {
					await this.deleteGoogleDriveFile(fileInfo);
				} else if (!resourceNodeDeleted && this.isDbUploadedFile(fileInfo)) {
					// Dữ liệu cũ chưa có resourceNodeId phải được xóa trực tiếp khỏi LMS FileData.
					await this.deleteDbUploadedFile(fileInfo);
				}
				// Archive LMS có thể tồn tại từ các bản cũ chưa lưu resourceNodeId.
				if (!resourceNodeDeleted && fileInfo?.archiveFileId && fileInfo.archiveFileId !== fileInfo.fileId) {
					await this.deleteDbUploadedFile({ fileId: fileInfo.archiveFileId });
				}
			},
			isSharedLinkedFile(fileInfo) {
				const sourceType = String(fileInfo?.sourceTracking?.sourceType || '').toUpperCase();
				return sourceType === 'CONTENT_HUB' || sourceType === 'HOC_LIEU_SO';
			},
			isYouTubeFile(fileInfo) {
				if (typeof fileInfo === 'string') {
					return fileInfo.includes('youtube.com') || fileInfo.includes('youtu.be');
				}
				const url = fileInfo.url || '';
				return fileInfo.uploadSource === 'youtube' || !!fileInfo.videoId || url.includes('youtube.com') || url.includes('youtu.be');
			},
			getYouTubeVideoId(fileInfo) {
				if (typeof fileInfo === 'string') {
					const url = fileInfo;
					if (url.includes('v=')) return url.split('v=')[1].split('&')[0];
					if (url.includes('youtu.be/')) return url.split('youtu.be/')[1].split('?')[0];
					return null;
				}
				if (fileInfo.videoId) return fileInfo.videoId;
				const url = fileInfo.url || '';
				if (url.includes('v=')) {
					return url.split('v=')[1].split('&')[0];
				}
				if (url.includes('youtu.be/')) {
					return url.split('youtu.be/')[1].split('?')[0];
				}
				return null;
			},
			async deleteYouTubeVideo(fileInfo) {
				const videoId = this.getYouTubeVideoId(fileInfo);
				if (!videoId) return;

				const { access_token } = await fetchPromise('lms/FP_Youtube_Token_Get');
				await new Promise((resolve, reject) => window.UploadManager.deleteFromYouTube(videoId, {
					accessToken: access_token,
					onComplete: resolve,
					onError: reject,
				}));
			},
			isGoogleDriveFile(fileInfo) {
				if (typeof fileInfo === 'string') {
					return fileInfo.includes('drive.google.com');
				}
				const url = fileInfo.url || '';
				return fileInfo.uploadSource === 'ggdrive' || !!fileInfo.driveFileId || url.includes('drive.google.com');
			},
			isDbUploadedFile(fileInfo) {
				if (typeof fileInfo === 'string') {
					return fileInfo.includes('file.lhbs.vn') || fileInfo.includes('/FileData/');
				}
				const url = fileInfo.url || fileInfo.FILE_URL || '';
				return fileInfo.uploadSource === 'db'
					|| !!fileInfo.fileId
					|| !!fileInfo.FILE_ID
					|| !!fileInfo.archiveFileId
					|| url.includes('file.lhbs.vn')
					|| url.includes('/FileData/');
			},
			getGoogleDriveFileId(fileInfo) {
				if (typeof fileInfo === 'string') {
					const url = fileInfo;
					if (url.includes('/d/')) {
						const parts = url.split('/d/');
						if (parts[1]) return parts[1].split('/')[0];
					}
					return null;
				}
				if (fileInfo.driveFileId) return fileInfo.driveFileId;
				const url = fileInfo.url || '';
				if (url.includes('/d/')) {
					const parts = url.split('/d/');
					if (parts[1]) {
						return parts[1].split('/')[0];
					}
				}
				return null;
			},
			async deleteGoogleDriveFile(fileInfo) {
				const fileId = this.getGoogleDriveFileId(fileInfo);
				if (!fileId) throw new Error('Không tìm thấy Google Drive file id');

				const { access_token } = await fetchPromise('lms/FP_Youtube_Token_Get');
				await new Promise((resolve, reject) => window.UploadManager.deleteFromGoogleDrive(fileId, {
					accessToken: access_token,
					onComplete: resolve,
					onError: reject,
				}));
			},
			async deleteDbUploadedFile(fileInfo) {
				const fileId = fileInfo.fileId || fileInfo.FILE_ID;
				if (fileId) {
					await window.UploadManager.deleteLmsFile(fileId);
				}
			},
			async deleteOldFileAfterReplace(oldFile) {
				if (!Object.keys(oldFile).length) return;
				try {
					await this.deleteCurrentFileResource(oldFile);
				} catch (error) {
					console.warn('Could not delete replaced file:', error);
					this.notify("Đã upload file mới nhưng chưa xóa được file cũ.", "warning");
				}
			},
			closeDialog() {
				this.$emit('update:isOpen', false);
			},
			requiredNameRule(value) {
				return (typeof value === 'string' && value.trim().length > 0) || 'Tên mục là bắt buộc.';
			},
				save() {
					if (this.isCreatingNew && this.questionList.length > 1) {
						const payloadList = [];
						const baseThuTu = this.getQuestionBaseOrder();
						for (let i = 0; i < this.questionList.length; i++) {
						const question = this.questionList[i];
						if (!question.TenNoiDung || !question.TenNoiDung.trim()) {
							this.activeItemIndex = i;
							return this.notify(`Vui lòng nhập tên cho câu/mục thứ #${i + 1}!`, 'error');
						}

						const questionData = this.buildSavePayload(JSON.parse(JSON.stringify(question)));
						if (questionData.DataJson) {
							questionData.DataJson = JSON.stringify(questionData.DataJson);
						}
						questionData.ParentID = question.ParentID ?? this.item?.ParentID ?? 0;
						questionData.ThuTu = baseThuTu + i;
						delete questionData.NoiDungID;
						payloadList.push(questionData);
					}

					this.$emit('save', payloadList);
					this.clearDraft();
					this.closeDialog();
					return;
				}

				const name = this.editableItem?.TenNoiDung;
				if (typeof name !== 'string' || !name.trim()) {
					return this.notify('Vui lòng nhập tên mục.', 'error');
				}
				this.editableItem.TenNoiDung = name.trim();
				if (this.isISpring && this.editableItem) {
					// Chuẩn hóa type khi lưu lại để viewer không phải suy luận node iSpring ở những lần sau.
					this.editableItem.LoaiNoiDung = 'ISPRING_CONTENT';
				}
				if (this.isVideo && this.editableItem) {
					if (!this.editableItem.DataJson || typeof this.editableItem.DataJson !== 'object') {
						this.editableItem.DataJson = {};
					}
					if (!this.tempVideoUrl?.startsWith('blob:')) {
						this.editableItem.DataJson.url = this.tempVideoUrl;
					}
					// Giữ cấu trúc một timeMarker chứa nhiều câu hỏi khi ghi ngược về Content Hub/học liệu.
					this.editableItem.DataJson.interactions = this.serializeInteractionMarkers(this.videoInteractions);
					if (this.tempVideoUrl && (this.tempVideoUrl.includes('youtube.com') || this.tempVideoUrl.includes('youtu.be'))) {
						this.editableItem.DataJson.uploadSource = 'youtube';
						let videoId = '';
						try {
							const urlObj = new URL(this.tempVideoUrl);
							if (urlObj.hostname.includes('youtube.com')) {
								videoId = urlObj.searchParams.get('v') || '';
							} else if (urlObj.hostname.includes('youtu.be')) {
								videoId = urlObj.pathname.slice(1);
							}
						} catch (e) {}
						if (videoId) {
							this.editableItem.DataJson.videoId = videoId;
						}
					} else if (!this.tempVideoUrl?.startsWith('blob:')) {
						this.editableItem.DataJson.uploadSource = 'video';
					}
				}
				if (this.isAudio && this.editableItem) {
					if (!this.editableItem.DataJson || typeof this.editableItem.DataJson !== 'object') this.editableItem.DataJson = {};
					if (!this.tempAudioUrl?.startsWith('blob:')) {
						this.editableItem.DataJson.url = this.tempAudioUrl;
						this.editableItem.DataJson.audioUrl = this.tempAudioUrl;
					}
				}
				if (this.isImage && this.editableItem) {
					if (!this.editableItem.DataJson || typeof this.editableItem.DataJson !== 'object') this.editableItem.DataJson = {};
					if (!this.tempImageUrl?.startsWith('blob:')) this.editableItem.DataJson.url = this.tempImageUrl;
				}
				// "Đóng gói" lại DataJson thành chuỗi trước khi lưu
				const dataToSave = this.buildSavePayload(JSON.parse(JSON.stringify(this.editableItem)));
				if (dataToSave.DataJson) {
					// Nếu là HTML, nhưng DataJson chỉ có mỗi htmlContent, thì chỉ lưu chuỗi đó thôi
					if (this.isHtml && dataToSave.DataJson.htmlContent && Object.keys(dataToSave.DataJson).length === 1) {
						dataToSave.DataJson = dataToSave.DataJson.htmlContent;
					} else {
						// Các trường hợp khác thì stringify cả object
						dataToSave.DataJson = JSON.stringify(dataToSave.DataJson);
					}
				}
				this.$emit('save', dataToSave);
				this.clearDraft();
				this.closeDialog();
			},

			//API github
			handleiSpringDrop(event) {
				event.preventDefault();
				const files = Array.from(event.dataTransfer.files);
				this.processiSpringFiles(files);
			},

			handleiSpringUpload(event) {
				const files = Array.from(event.target.files);
				this.processiSpringFiles(files);
			},

			async processiSpringFiles(files) {
				// Lấy tên thư mục gốc từ file đầu tiên
				const firstFile = files[0];
				const relativePath = firstFile.webkitRelativePath || firstFile.name;
				const folderName = relativePath.split('/')[0]; // Tên thư mục gốc

				console.log('📁 Detected folder name:', folderName);
				console.log('📁 URL encoded:', encodeURIComponent(folderName));

				// Validate iSpring structure
				const hasIndex = files.some(f => f.name === 'index.html');
				if (!hasIndex) {
					this.notify('Không tìm thấy file index.html trong folder iSpring!', 'error');
					return;
				}

				const iSpringGUID = this.generateGUID();

				this.uploadProgress.show = true;
				this.uploadProgress.percent = 0;
				this.uploadProgress.text = 'Đang chuẩn bị upload...';

				try {
					const result = await this.uploadToGitHub(files, iSpringGUID);

					// Detect where index.html is located in the files list
					const indexFile = files.find(f => f.name === 'index.html');
					const indexRelPath = indexFile.webkitRelativePath || indexFile.name;
					const indexParts = indexRelPath.split('/');
					indexParts.shift(); // Remove the root folder name
					const indexPath = indexParts.join('/'); // e.g. "res/index.html" or "index.html"

					// URL với tên folder encode và đường dẫn tương đối của index.html
					const encodedFolderName = encodeURIComponent(folderName);
					const finalURL = `https://thientamlhu.github.io/lhbs.lms/content/${iSpringGUID}/${encodedFolderName}/${indexPath}`;

					// iSpring chỉ phát hành trên GitHub/GitHub Pages; không tạo fileId/archiveFileId để tránh rơi vào luồng lưu LMS/Google Drive.
					this.editableItem.DataJson = {
						iSpringGUID: iSpringGUID,
						iSpringURL: finalURL,           // URL đã encode
						folderName: folderName,         // Tên gốc
						encodedFolderName: encodedFolderName, // Tên đã encode
						uploadDate: new Date().toISOString(),
						totalFiles: files.length
					};

					console.log('✅ Final URL:', finalURL);

					this.uploadProgress.text = '✅ Upload thành công!';

					// Test URL sau khi upload
					setTimeout(async () => {
						const isAvailable = await this.testURL(finalURL);
						if (isAvailable) {
							this.notify('Upload và deploy thành công!');
						} else {
							this.notify('Upload thành công, đang chờ GitHub Pages deploy.', 'warning');
						}
					}, 3000);

					setTimeout(() => {
						this.uploadProgress.show = false;
					}, 2000);

				} catch (error) {
					console.error('❌ Upload error:', error);
					this.uploadProgress.text = '❌ Upload thất bại: ' + error.message;
					this.notify('Upload thất bại: ' + error.message, 'error');

					setTimeout(() => {
						this.uploadProgress.show = false;
					}, 3000);
				}
			},

			async getGitHubConfig() {
				const config = await fetchPromise('lms/FP_Github_Config_Get');
				return config || {};
			},

			async uploadToGitHub(files, guid, folderName) {
				const { token, owner, repo } = await this.getGitHubConfig();

				const total = files.length;
				let completed = 0;

				for (const file of files) {
					try {
						// Convert to base64
						const base64Content = await this.fileToBase64(file);

						// Determine file path
						const relativePath = file.webkitRelativePath || file.name;
						const filePath = `content/${guid}/${relativePath}`;

						// Upload single file
						await this.uploadSingleFile(token, owner, repo, filePath, base64Content, file.name);

						completed++;
						this.uploadProgress.percent = Math.round((completed / total) * 100);
						this.uploadProgress.text = `Đang upload ${completed}/${total} files...`;

						// Rate limiting
						await new Promise(resolve => setTimeout(resolve, 200));

					} catch (error) {
						// Không tiếp tục lưu metadata khi chỉ upload được một phần folder iSpring.
						throw new Error(`Không thể upload ${file.name}: ${error.message || 'GitHub trả về lỗi.'}`);
					}
				}

				// Return URL
				const url = `https://${owner}.github.io/${repo}/content/${guid}/${folderName}/index.html`;
				return { url, guid };
			},

			fileToBase64(file) {
				return new Promise((resolve, reject) => {
					const reader = new FileReader();
					reader.onload = () => {
						const base64 = reader.result.split(',')[1];
						resolve(base64);
					};
					reader.onerror = reject;
					reader.readAsDataURL(file);
				});
			},

			async uploadSingleFile(token, owner, repo, path, content, fileName) {
				const { branch } = await this.getGitHubConfig();
				const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/contents/${this.encodeGitHubPath(path)}`, {
					method: 'PUT',
					headers: {
						'Authorization': `token ${token}`,
						'Accept': 'application/vnd.github.v3+json',
						'Content-Type': 'application/json'
					},
					body: JSON.stringify({
						message: `Upload ${fileName}`,
						content: content,
						branch
					})
				});

				if (!response.ok) {
					const error = await response.json();
					throw new Error(error.message || 'Upload failed');
				}

				return response.json();
			},

			encodeGitHubPath(path) {
				return path.split('/').map(part => encodeURIComponent(part)).join('/');
			},

			async deleteGitHubPath(path) {
				const { token, owner, repo, branch } = await this.getGitHubConfig();
				const encodedPath = this.encodeGitHubPath(path);
				const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/contents/${encodedPath}?ref=${branch}`, {
					headers: {
						'Authorization': `token ${token}`,
						'Accept': 'application/vnd.github.v3+json'
					}
				});

				if (response.status === 404) return;
				if (!response.ok) {
					const error = await response.json();
					throw new Error(error.message || 'Cannot read GitHub content');
				}

				const content = await response.json();
				const items = Array.isArray(content) ? content : [content];
				for (const item of items) {
					if (item.type === 'dir') {
						await this.deleteGitHubPath(item.path);
					} else {
						await this.deleteGitHubFile(item.path, item.sha);
					}
				}
			},

			async deleteGitHubFile(path, sha) {
				const { token, owner, repo, branch } = await this.getGitHubConfig();
				const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/contents/${this.encodeGitHubPath(path)}`, {
					method: 'DELETE',
					headers: {
						'Authorization': `token ${token}`,
						'Accept': 'application/vnd.github.v3+json',
						'Content-Type': 'application/json'
					},
					body: JSON.stringify({
						message: `Delete ${path}`,
						sha,
						branch
					})
				});

				if (!response.ok && response.status !== 404) {
					const error = await response.json();
					throw new Error(error.message || 'Cannot delete GitHub file');
				}
			},

			generateGUID() {
				if (globalThis.crypto?.randomUUID) {
					return globalThis.crypto.randomUUID();
				}

				const template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
				let guid = '';
				for (const c of template) {
					if (c !== 'x' && c !== 'y') {
						guid += c;
						continue;
					}

					const r = Math.random() * 16 | 0;
					const v = c === 'x' ? r : (r & 0x3 | 0x8);
					guid += v.toString(16);
				}
				return guid;
			},

			async removeiSpringContent() {
				const guid = this.editableItem.DataJson?.iSpringGUID;
				this.loadingPage.isLoading = true;
				this.loadingPage.text = "Đang xóa iSpring content...";
				try {
					if (guid) {
						await this.deleteGitHubPath(`content/${guid}`);
					}
					this.editableItem.DataJson = {};
					if (this.$refs.iSpringInput) this.$refs.iSpringInput.value = '';
					this.notify("Đã xóa iSpring content.");
				} catch (error) {
					console.error('Delete iSpring content failed:', error);
					// Giữ nguyên GUID khi GitHub chưa xóa xong để người dùng retry, tránh metadata trỏ mù vào thư mục rác.
					this.notify(`Chưa xóa iSpring trên GitHub: ${error?.message || 'Lỗi không xác định.'}`, "error");
				} finally {
					this.loadingPage.isLoading = false;
				}
			}
		}
	}
</script>