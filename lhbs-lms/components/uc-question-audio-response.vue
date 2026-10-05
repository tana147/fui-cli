<template>
	<div class="uc-audiores-root">
		<!-- 1) Ghi âm / Nộp (chỉ khi chưa nộp & không phải GV chấm) -->
		<div v-if="submissionstatus < 2 && !isGrade">
			<uc-audio-record v-model:file="fileRecordAudio" :readonly="readonly" :src="lastAudioSrc"
				v-model:isSaveFile="isSaveFile" @handleSave="uploadFile" />
			<div class="text-caption text-medium-emphasis mt-1">
				Ghi âm và lưu để nộp. Bạn có thể nghe lại trước khi nộp.
			</div>
		</div>

		<!-- 2) Câu trả lời của học sinh (nghe trực tiếp) -->
		<div class="student-answer-panel rounded bg-indigo-lighten-5 pa-2" v-if="submissionstatus >= 2">
			<div class="panel-title d-flex align-center ga-2">
				<v-icon size="18">mdi-account-outline</v-icon>
				<b>Câu trả lời của {{ isGrade ? 'học sinh' : 'bạn' }}:</b>
			</div>

			<div v-if="normalizedAudios.length > 0" class="mt-2 d-flex flex-column ga-2">
				<div v-for="(item, idx) in normalizedAudios" :key="idx" class="audio-row" style="position: relative">
					<v-btn v-if="!isGrade && submissionstatus < 2" icon="mdi-close" color="red" variant="tonal"
						@click="answer.splice(idx, 1)" size="small"
						style="position: absolute; right: 8px; top:8px; z-index: 2" />
					<uc-audio-record :key="idx" v-model:file="item.file" v-model:src="item.playUrl" :readonly="true"
						:isSaveFile="false" :isShowBtn="false" />
				</div>
			</div>

			<div v-else class="mt-2 text-red">
				<i>{{ isGrade ? 'Học sinh' : 'Bạn' }} không nộp/ghi âm nội dung nào.</i>
			</div>
		</div>

		<!-- 3) Ý kiến học sinh -->
		<!-- <div v-if="isGrade && submissionstatus >= 2 && studentCommentToShow.length > 0" class="student-comment mt-2">
			<div class="d-flex align-center ga-2">
				<v-icon size="18">mdi-comment-text-outline</v-icon>
				<b>Ý kiến của học sinh</b>
			</div>
			<div class="mt-1">
				{{ studentCommentToShow }}
			</div>
		</div> -->

		<!-- Học sinh -->
		<div class="mt-2">
			<div class="text-end" v-if="!isGrade && submissionstatus < 2 && isShowBtnComment">
				<v-menu v-model="menu" :close-on-content-click="false" scroll-strategy="close" location="start">
					<template #activator="{ props: menuProps }">
						<v-tooltip location="top">
							<template #activator="{ props: tooltipProps }">
								<v-btn v-bind="{ ...menuProps, ...tooltipProps }" icon="mdi-notebook-edit-outline" size="small"
									variant="text" color="primary" />
							</template>
							<span>Ý kiến của bạn</span>
						</v-tooltip>
					</template>
					<v-card :min-width="widthScreen < 650 ? null : 600" variant="outlined" class="elevation-0">
						<v-card-title class="px-4 py-3" style="background-color:#E3F2FD; color:#1565C0; font-weight:600;">
							Ý kiến của bạn
						</v-card-title>
						<v-list>
							<v-list-item>
								<v-textarea :model-value="grading?.comment || ''" @update:model-value="onStudentCommentInput" rows="2"
									hide-details variant="outlined" placeholder="Nhập ý kiến của bạn" />
							</v-list-item>
						</v-list>
						<v-card-actions class="border-t py-0">
							<v-spacer />
							<v-btn variant="text" color="primary" @click="menu = false">
								Đóng
							</v-btn>
						</v-card-actions>
					</v-card>
				</v-menu>
			</div>
			<div v-else-if="grading?.comment" class="pa-2 rounded bg-blue-lighten-1">
				<b>
					<v-icon class="mr-1" size="18">mdi-message-text-outline</v-icon>
					Ý kiến của {{ isGrade ? 'học sinh' : 'bạn' }}:
				</b>
				<div class="mt-1">{{ grading.comment }}</div>
			</div>
		</div>

		<!-- 4) Banner “ĐANG CHỜ CHẤM” (đã nộp nhưng chưa trả bài) -->
		<v-alert v-if="!isGrade && submissionstatus >= 2 && submissionstatus !== 4" variant="tonal" type="warning"
			density="comfortable" class="my-3">
			ĐANG CHỜ CHẤM
		</v-alert>

		<!-- 5) Điểm (v-chip) khi đã trả bài -->
		<div v-if="submissionstatus == 4" class="mt-2">
			<strong>{{ $i18n.locale == 'en' ? 'Score' : 'Điểm' }}</strong>
			<v-chip size="small" :color="scoreChipColor" variant="tonal">
				<v-icon start size="16">mdi-star</v-icon>
				{{ displayScore }} / {{ question.points }}
			</v-chip>
		</div>

		<!-- 6) Nhận xét của GV (ở giao diện học sinh) -->
		<v-alert v-if="submissionstatus == 4 && !isGrade && (grading?.teacherComment || '').trim().length > 0"
			border="start" color="info" elevation="2" class="mt-2" icon="mdi-comment-quote-outline">
			<strong>Nhận xét GV:</strong> {{ grading.teacherComment }}
		</v-alert>

		<!-- 7) Khu vực chấm điểm cho GV -->
		<div class="mt-2 teacher-grading-area" v-if="isGrade">
			<div class="d-flex align-center mb-2">
				<v-number-input :model-value="grading?.manualScore" @update:model-value="onUpdateScoreInput"
					:label="$t('message.points')" :max="question.points" :min="0" variant="outlined" density="compact"
					hide-details style="max-width: 120px;" control-variant="hidden" inset />
				<span class="text-h6 ml-2 text-primary">/ {{ question.points }}</span>
				<span class="ml-1 text-caption">{{ $t('message.points') }}</span>
			</div>
			<v-textarea :model-value="grading?.teacherComment || ''" @update:model-value="updateTeacherComment"
				:label="$t('message.TeacherCommentOptional')" rows="2" outlined dense hide-details />
		</div>

		<uc-loading-page v-model="loadingPage.isLoading" v-model:text="loadingPage.text" />
	</div>
</template>

<script>
	export default {
		name: 'uc-question-audio-response',
		props: {
			question: Object,
			// Parent chuẩn hoá: answer là Array các file (hoặc null)
			answer: { type: [Array, String, Object, null], default: null },
			readonly: { type: Boolean, default: false },
			grading: Object, // { manualScore, teacherComment, comment? }
			isGrade: { type: Boolean, default: false },
			submissionstatus: { type: Number, default: -1 },
	
			// (mới) nếu parent có truyền ý kiến HS riêng
			studentComment: { type: String, default: '' },
			// (mới) nếu parent có truyền max points riêng; fallback question.points
			maxPoints: { type: Number, default: null },
			isShowBtnComment: { type: Boolean, default: true }
		},
		emits: ['answer-change', 'grading-change'],
		data() {
			return {
				apiFile: "https://file.lhbs.vn/lms/upload/FileData",
				urlReturnFile: "https://file.lhbs.vn/lms",
				isUploading: false,
				fileRecordAudio: null,
				loadingPage: { isLoading: false, text: 'Đang tải dữ liệu...' },
				isSaveFile: false,
				menu: false, widthScreen: null
			}
		},
		computed: {
			// Danh sách audio đã nộp, chuẩn hoá playUrl để <audio> phát trực tiếp
			normalizedAudios() {
				const arr = Array.isArray(this.answer) ? this.answer : (this.answer ? [this.answer] : [])
				return arr
					.map(raw => this.normalizeAudioItem(raw))
					.filter(x => !!x && !!x.playUrl)
			},
			lastAudioSrc() {
				// để truyền cho uc-audio-record (nếu nó hiển thị preview gần nhất)
				return this.normalizedAudios.length ? this.normalizedAudios[this.normalizedAudios.length - 1].playUrl : ''
			},
			studentCommentToShow() {
				const fromProp = (this.studentComment || '').trim()
				const fromGrading = (this.grading?.comment || '').trim()
	
				console.log('fromProp', fromProp)
				console.log('fromGrading', fromGrading)
				return fromProp.length ? fromProp : fromGrading
			},
			displayScore() {
				const s = this.grading?.manualScore
				return typeof s === 'number' ? s : 0
			},
			effectiveMaxPoints() {
				const m = this.maxPoints != null ? this.maxPoints : this.question?.points
				return Number(m || 0)
			},
			scoreChipColor() {
				const s = this.displayScore
				const max = this.effectiveMaxPoints
				if (s <= 0) return 'error'
				if (max && s >= max) return 'success'
				return 'primary'
			}
		},
		mounted() {
			this.widthScreen = window.innerWidth
			window.addEventListener('resize', () => { this.handleResize() })
		},
		methods: {
			handleResize() {
				this.widthScreen = window.innerWidth;
			},
			// --- Upload flow (giữ nguyên ý tưởng của bạn) ---
			ajaxCALLPromise(url, params = null) {
				return new Promise(resolve => {
					ajaxCALL(url, params, res => {
						if (res?.data) resolve(res.data)
						else resolve(res)
					})
				})
			},
			async ensureFolderPathExists(path, access_token) {
				const parts = path.split('/')
				let parentId = 'root'
				for (const part of parts) {
					parentId = await this.getOrCreateFolderId(part, parentId, access_token)
				}
				return parentId
			},
			async getOrCreateFolderId(folderName, parentId = 'root', access_token) {
				const safeFolderName = String(folderName).replace(/\\/g, '\\\\').replace(/'/g, "\\'")
				const query = `name = '${safeFolderName}' and mimeType = 'application/vnd.google-apps.folder' and '${parentId}' in parents and trashed = false`
				const res = await fetch(`https://www.googleapis.com/drive/v3/files?q=${encodeURIComponent(query)}&fields=files(id)`, {
					headers: { Authorization: `Bearer ${access_token}` }
				})
				const data = await res.json()
				if (data && data.files && data.files.length > 0) return data.files[0].id
	
				const createRes = await fetch('https://www.googleapis.com/drive/v3/files', {
					method: 'POST',
					headers: {
						Authorization: `Bearer ${access_token}`,
						'Content-Type': 'application/json'
					},
					body: JSON.stringify({
						name: folderName,
						mimeType: 'application/vnd.google-apps.folder',
						parents: [parentId]
					})
				})
				const created = await createRes.json()
				return created ? created.id : parentId
			},
			async uploadToGoogleDrive(file) {
				try {
					this.loadingPage.isLoading = true
					this.loadingPage.text = "Đang tải dữ liệu..."

					const tokenRes = await this.ajaxCALLPromise('lms/FP_Youtube_Token_Get')
					const access_token = tokenRes?.access_token || tokenRes?.[0]?.access_token
					if (!access_token) {
						throw new Error("Không lấy được token truy cập Google Drive.")
					}

					this.loadingPage.text = "Đang tìm kiếm folder..."
					const asm = (vueData.assignmentData && vueData.assignmentData[0] && vueData.assignmentData[0][0]) || {}
					const monHoc = (asm.MonHocName || 'LMS').replace(/[/\\?%*:|"<>]/g, '_')
					const khoi = asm.KhoiID || ''
					const title = (asm.Title || 'BaiTap').replace(/[/\\?%*:|"<>]/g, '_')
					const userId = (vueData.user && vueData.user.UserID) || 'User'

					const pathPrefix = `LMS/${monHoc} ${khoi}/${title}/${userId}`
					const folderId = await this.ensureFolderPathExists(pathPrefix, access_token)

					const metadata = {
						name: file.name || 'recording.webm',
						mimeType: file.type || 'audio/webm',
						parents: [folderId]
					}

					const form = new FormData()
					form.append('metadata', new Blob([JSON.stringify(metadata)], { type: 'application/json' }))
					form.append('file', file)

					this.loadingPage.text = "Đang upload..."
					const res = await fetch('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart', {
						method: 'POST',
						headers: new Headers({ Authorization: 'Bearer ' + access_token }),
						body: form
					})

					const fileDrive = await res.json()
					if (!fileDrive || !fileDrive.id) {
						throw new Error(fileDrive?.error?.message || "Tải tệp lên Google Drive không thành công.")
					}

					this.loadingPage.text = "Đang cấp quyền file..."
					await fetch(`https://www.googleapis.com/drive/v3/files/${fileDrive.id}/permissions`, {
						method: 'POST',
						headers: { Authorization: 'Bearer ' + access_token, 'Content-Type': 'application/json' },
						body: JSON.stringify({ role: 'reader', type: 'anyone' })
					}).catch(() => {})

					this.loadingPage.isLoading = false
					this.isSaveFile = true
					const previewUrl = `https://drive.google.com/file/d/${fileDrive.id}/preview`
					return { id: fileDrive.id, name: file.name || 'recording.webm', source: previewUrl }
				} catch(err) {
					console.error("uploadToGoogleDrive Error:", err)
					this.loadingPage.isLoading = false
					alert("Lỗi tải lên bài ghi âm: " + (err.message || err))
					return null
				}
			},
			async uploadFile() {
				if (!this.fileRecordAudio) return
				const sourceFile = this.fileRecordAudio
				const uploadedDb = await new Promise((resolve, reject) => {
					if (!window.UploadManager?.uploadLmsSharedFile) return reject(new Error('UploadManager chưa hỗ trợ upload audio LMS'))
					window.UploadManager.uploadLmsSharedFile(sourceFile, { onComplete: resolve, onError: reject })
				})
				const uploadedFile = uploadedDb?.Files?.[0]
				if (!uploadedFile?.FILE_ID) throw new Error('API lưu trữ audio không trả về FILE_ID')
				const external = await this.uploadToGoogleDrive(sourceFile)
				const file = {
					id: uploadedFile.FILE_ID,
					name: uploadedFile.FILE_NAME || sourceFile.name || 'recording.webm',
					source: uploadedFile.FILE_URL || `/FileData/${uploadedFile.FILE_ID}`,
					mediaSource: 'db',
					fileSize: Number(uploadedFile.FILE_SIZE || sourceFile.size || 0),
					externalId: external?.id || '',
					externalSource: external?.source || '',
					externalMediaSource: external ? 'upload' : '',
				}
				const arr = Array.isArray(this.answer) ? [...this.answer] : (this.answer ? [this.answer] : [])
				arr.push(file)
				this.$emit('answer-change', arr)
			},
	
			// --- Helpers hiển thị & chấm ---
			toDrivePlayable(urlOrId) {
				// Nhận vào 1: preview link; 2: google drive file id
				if (!urlOrId) return ''
				// Nếu là preview link -> tách id
				const m = String(urlOrId).match(/\/d\/([^/]+)\//)
				const id = m ? m[1] : null
				const realId = id || urlOrId
				return `https://drive.google.com/uc?export=download&id=${realId}`
			},
			normalizeAudioItem(raw) {
				if (!raw) return null
	
				// Các shape có thể gặp:
				// 1) { id, name, source }  (source = preview link)
				// 2) { fileId, fileName, fileType: 'audio' } (server cũ)
				// 3) string URL
				// 4) đối tượng { url, name }
				// Ưu tiên tạo playUrl hợp lệ cho <audio>.
				if (typeof raw === 'string') {
					// Nếu là link preview drive
					if (raw.includes('/file/d/') && raw.includes('/preview')) {
						return { name: 'Audio', playUrl: this.toDrivePlayable(raw) }
					}
					return { name: 'Audio', playUrl: raw }
				}
	
				const rawSource = raw.externalSource || raw.source
				if (rawSource) {
					if (rawSource.includes('/file/d/') && rawSource.includes('/preview')) {
						return { name: raw.name || 'Audio', playUrl: this.toDrivePlayable(rawSource) }
					}
					return { name: raw.name || 'Audio', playUrl: rawSource }
				}
	
				if (raw.id && !raw.source) {
					// Có id drive
					return { name: raw.name || 'Audio', playUrl: this.toDrivePlayable(raw.id) }
				}
	
				if (raw.fileId && raw.fileType === 'audio') {
					// Trường hợp server cũ: nếu bạn có base URL phát trực tiếp, thay ở đây
					// Fallback: thử dùng trực tiếp fileId như drive id
					return { name: raw.fileName || 'Audio', playUrl: this.toDrivePlayable(raw.fileId) }
				}
	
				if (raw.url) {
					return { name: raw.name || 'Audio', playUrl: raw.url }
				}
	
				return null
			},
			updateTeacherComment(newComment) {
				this.$emit('grading-change', {
					...(this.grading || {}),
					teacherComment: newComment
				})
			},
			onUpdateScoreInput(val) {
				const parsed = (val === undefined || val === null) ? 0 : Number(val)
				this.$emit('grading-change', {
					...(this.grading || {}),
					manualScore: isNaN(parsed) ? 0 : parsed
				})
			},
			onStudentCommentInput(val) {
				this.grading.comment = val
				this.$emit('grading-change', { ...this.grading, comment: val })
			},
		}
	}
</script>

<style scoped>
.uc-audiores-root {}

	.student-answer-panel {
		background: rgba(33, 150, 243, 0.06);
		/* blue lighten bg */
		border: 1px dashed rgba(33, 150, 243, 0.35);
		border-radius: 8px;
		padding: 10px 12px;
	}

	.panel-title {
		font-weight: 600;
	}

	.audio-row {
		padding: 8px 0;
	}

	.audio-player {
		width: 100%;
	}

	.student-comment {
		background: rgba(76, 175, 80, 0.06);
		border: 1px dashed rgba(76, 175, 80, 0.35);
		border-radius: 8px;
		padding: 10px 12px;
	}
</style>