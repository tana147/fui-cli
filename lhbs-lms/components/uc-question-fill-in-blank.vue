<template>
	<div class="uc-fib-root">
		<!-- 1) Nội dung câu hỏi (chuỗi text + chỗ trống) -->
		<div class="d-flex flex-wrap align-center ga-2 question-body">
			<span v-for="(part, idx) in (question.config?.parts || [])" :key="idx">
				<span v-if="part.type === 'text'">{{ part.value }}</span>

				<span v-else-if="part.type === 'blank'">
					<!-- Ô nhập cho từng chỗ trống -->
					<v-text-field v-model="userAnswers[part.id]"
						:readonly="readonly || isGrade || submissionstatus >= 2" hide-details="auto" dense
						variant="filled" @blur="onBlurBlank(part.id)" :clearable="false"
						:style="{ width: blankWidths[part.id], minWidth: '0' }" @copy="handleCopyPaste"
						@cut="handleCopyPaste" @paste="handleCopyPaste" @contextmenu="handleContextMenu">
						<!-- icon đúng/sai khi đã chấm -->
						<template v-slot:append-inner v-if="isGradedView">
							<v-icon v-if="isBlankCorrect(part.id)" color="success">mdi-check</v-icon>
							<v-icon v-else color="error">mdi-close</v-icon>
						</template>
					</v-text-field>
				</span>
			</span>
		</div>

		<!-- 2) Hướng dẫn nộp bài (nếu có) -->
		<v-alert v-if="question.config?.submitGuide?.trim()" variant="tonal" type="info" border="start" class="mt-2">
			<strong>Hướng dẫn nộp:</strong> {{ question.config.submitGuide }}
		</v-alert>

		<!-- 3) Câu trả lời của học sinh -->
			<!-- Nếu đã nộp: cố định hiển thị, không cho sửa -->
			<template v-if="isGrade && submissionstatus >= 2">
				<div v-if="hasAnyAnswer" class="d-flex flex-wrap align-center ga-2 mt-2">
					<!-- Render lại chuỗi với các blank (readonly) -->
					<!-- <span v-for="(part, idx) in (question.config?.parts || [])" :key="'view-' + idx">
						<span v-if="part.type === 'text'">{{ part.value }}</span>
						<span v-else-if="part.type === 'blank'">
							<v-chip size="small" color="primary" variant="tonal" class="mx-1">
								{{ userAnswers[part.id] || '…' }}
							</v-chip>
						</span>
					</span> -->
				</div>
				<div v-else class="mt-2 text-red">
					<div class="student-answer-panel rounded bg-indigo-lighten-5 pa-2">
						<div class="panel-title d-flex align-center ga-2">
							<v-icon size="18">mdi-account-outline</v-icon>
							<b>Câu trả lời của {{ isGrade ? 'học sinh' : 'bạn' }}:</b>
						</div>
						<i class="text-red">{{ isGrade ? 'Học sinh' : 'Bạn' }} không điền đáp án.</i>
					</div>
				</div>
			</template>

			<!-- Nếu chưa nộp: học sinh nhập trực tiếp vào các ô trống phía trên. -->

		<!-- 4) Ý kiến học sinh -->
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
		<div v-if="(grading?.comment || '').trim().length > 0 && submissionstatus >= 2"
			class="mt-2 rounded bg-blue-lighten-1">
			<div class="pa-2">
				<b>
					<v-icon class="mr-1" size="18">mdi-message-text-outline</v-icon> <span
						v-if="$i18n.locale =='en'&& isGrade">
						Student's Feedback
					</span>
					<span v-else-if="$i18n.locale !='en'&& isGrade">Ý kiến {{ isGrade ? 'học sinh' : 'bạn' }}:</span>
				</b>
				<div class="mt-1">{{ grading.comment }}</div>
			</div>
		</div>

		<!-- 5) Banner “ĐANG CHỜ CHẤM” (đã nộp nhưng chưa chấm) -->
		<v-alert v-if="!isGrade && submissionstatus >= 2 && submissionstatus !== 4" variant="tonal" type="warning"
			density="comfortable" class="my-2">
			ĐANG CHỜ CHẤM
		</v-alert>

		<!-- 6) Đáp án đúng (chỉ hiện khi chấm hoặc đã trả bài) -->
		<div v-if="isGradedView" class="mt-2">
			<strong>{{$i18n.locale == 'en' ? 'Correct answers':'Đáp án đúng' }}:</strong>
			<template v-if="correctAnswersGrouped.length === 1">
				<v-chip color="green" size="small" v-for="(ans, ansIndex) in correctAnswersGrouped[0].answers" :key="'correct-' + ansIndex" class="ml-1">
					{{ ans }}
				</v-chip>
			</template>
			<template v-else>
				<div v-for="group in correctAnswersGrouped" :key="'group-' + group.blankIndex" class="d-flex align-center flex-wrap ga-1 mt-1">
					<span class="text-caption text-medium-emphasis mr-1">{{ $i18n.locale == 'en' ? 'Blank' : 'Chỗ trống' }} {{ group.blankIndex }}:</span>
					<v-chip color="green" size="small" v-for="(ans, ansIndex) in group.answers" :key="'ans-' + group.blankIndex + '-' + ansIndex">
						{{ ans }}
					</v-chip>
				</div>
			</template>
		</div>

		<!--
			Câu điền đáp án có thể đúng về mặt ý nghĩa nhưng khác định dạng nhập
			(ví dụ 16.5 và 16,5). Giáo viên chỉ được chỉnh riêng câu này; điểm
			và lý do được emit lên component chấm để lưu cùng SubmissionContent.
		-->
		<div v-if="canRegrade" class="mt-3">
			<v-alert :type="hasManualRegrade ? 'success' : 'warning'" variant="tonal" density="comfortable" class="mb-0">
				<div class="d-flex flex-wrap align-center justify-space-between ga-2">
					<div class="text-body-2">
						<strong>{{ hasManualRegrade ? 'Đã chấm lại câu này' : 'Gợi ý chấm lại câu này' }}</strong>
						<div>{{ hasManualRegrade ? 'Điểm hiện tại do giáo viên xác nhận thủ công.' : 'Đáp án học sinh có thể tương đương với đáp án mẫu nhưng khác cách nhập.' }}</div>
						<!-- Hiển thị điểm mới ngay trong banner để giáo viên đối chiếu nhanh với điểm tối đa của câu. -->
						<div v-if="hasManualRegrade" class="text-body-2 mt-1">
							Điểm chấm lại: <strong>{{ displayScore }} / {{ effectiveMaxPoints }}</strong>
						</div>
						<div v-if="hasManualRegrade && lastRegradeReason" class="text-caption mt-1">
							Lý do: {{ lastRegradeReason }}
						</div>
					</div>
					<v-btn color="warning" variant="elevated" size="small" @click="openRegradeDialog">
						<v-icon start size="16">mdi-pencil-check-outline</v-icon>
						{{ hasManualRegrade ? 'Điều chỉnh điểm' : 'Chấm lại câu này' }}
					</v-btn>
				</div>
			</v-alert>
		</div>

		<v-dialog v-if="isGrade" v-model="regradeDialog" max-width="600">
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold">
					Chấm lại câu này
					<v-spacer></v-spacer>
					<v-btn icon variant="text" @click="regradeDialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-1">
					<v-alert density="compact" variant="tonal" type="info" class="mb-3">
						Điểm tự động hiện tại: {{ autoScoreRounded }} / {{ effectiveMaxPoints }}
					</v-alert>
					<v-number-input v-model="regradeForm.score" label="Điểm giáo viên chấm lại"
						:max="effectiveMaxPoints" :min="0" :step="0.01" :precision="2"
						variant="outlined" density="compact" hide-details="auto" control-variant="hidden" inset />
					<div class="text-caption text-medium-emphasis mt-1 mb-3">
						Cho phép nhập điểm từ 0 đến {{ effectiveMaxPoints }}.
					</div>
					<v-textarea v-model="regradeForm.reason" label="Lý do chấm lại *"
						placeholder="Nhập lý do chấm lại câu hỏi này..." :maxlength="2000" counter
						:error-messages="regradeReasonError ? ['Vui lòng nhập lý do chấm lại.'] : []"
						rows="3" variant="outlined" hide-details="auto" />
				</v-card-text>
				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn variant="text" @click="regradeDialog = false">Hủy</v-btn>
					<v-btn color="primary" elevation="0" :disabled="!isRegradeFormValid" @click="saveRegrade">
						Lưu chấm lại
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- 7) Điểm từng câu (v-chip, chỉ hiện khi đã trả bài) -->
		<div v-if="submissionstatus == 4" class="mt-2">
			<strong>{{$i18n.locale == 'en' ? 'Score':'Điểm' }}:</strong>
			<v-chip size="small" :color="scoreChipColor" variant="tonal">
				<v-icon start size="16">mdi-star</v-icon>
				{{ displayScore }} / {{ effectiveMaxPoints }}
			</v-chip>
		</div>

		<!-- 8) Nhận xét của giáo viên -->
		<v-alert v-if="submissionstatus == 4 && !isGrade && (grading?.teacherComment || '').trim().length > 0"
			border="start" color="info" elevation="2" class="mt-2" icon="mdi-comment-quote-outline">
			<strong>Nhận xét GV:</strong> {{ grading.teacherComment }}
		</v-alert>

		<!-- 9) Khu vực chấm điểm cho GV -->
		<div class="mt-4 teacher-grading-area" v-if="isGrade">
			<!-- <div class="d-flex align-center mb-3">
				<v-number-input :model-value="grading?.manualScore ?? 0"
					@update:model-value="val => onUpdateScoreInput(val)" label="Điểm" :max="question.points" :min="0"
					variant="outlined" density="compact" hide-details style="max-width: 120px;"
					control-variant="stacked" inset />
				<span class="text-h6 ml-2 text-primary">/ {{ question.points }}</span>
				<span class="ml-1 text-caption">điểm</span>
				<v-chip class="ml-3" size="small" :color="scoreChipColor" variant="tonal">
					<v-icon start size="16">mdi-star</v-icon>
					Gợi ý: {{ autoScoreRounded }} / {{ question.points }}
				</v-chip>
			</div> -->

			<v-textarea :model-value="grading?.teacherComment || ''" @update:model-value="updateTeacherComment"
				:label="$t('message.TeacherCommentOptional')" rows="2" outlined dense hide-details />
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-question-fill-in-blank',
		props: {
			question: { type: Object, required: true },
			// answer: { blankId: "text", ... }
			answer: { type: Object, default: () => ({}) },
			readonly: { type: Boolean, default: false },
			grading: { type: Object, default: null },
			isGrade: { type: Boolean, default: false },
			submissionstatus: { type: [Number, String], default: -1 },
			isShowBtnComment: { type: Boolean, default: true },
			isBlockCopyPaste: {
				type: Boolean,
				default: false
			}
		},
		emits: ['answer-change', 'grading-change'],
		data() {
			this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
			return {
				userAnswers: this.buildInitialAnswers(this.answer, this.question?.config?.parts || []),
				menu: false,
				widthScreen: null,
				regradeDialog: false,
				regradeForm: { score: null, reason: '' },
				regradeReasonError: false,
				vueData
			}
		},
		computed: {
			blankWidths() {
				const widths = {}
				Object.keys(this.userAnswers).forEach(id => {
					const val = this.userAnswers[id] || ''
					const len = val.length + 7
					widths[id] = `${len}ch`
				})
				return widths
			},
			// Hiển thị icon đúng/sai và đáp án đúng khi đang ở trang chấm (isGrade) hoặc đã trả bài (status==4)
			isGradedView() {
				return this.isGrade || this.submissionstatus === 4
			},
	
			// Có bất kỳ blank nào có câu trả lời?
			hasAnyAnswer() {
				const vals = Object.values(this.userAnswers || {})
				return vals.some(v => (v ?? '').toString().trim().length > 0)
			},
	
			// Danh sách đáp án đúng nhóm theo từng blank
			correctAnswersGrouped() {
				const parts = this.question?.config?.parts || []
				let blankIndex = 0
				return parts
					.filter(p => p.type === 'blank')
					.map(p => {
						blankIndex++
						const accepted = Array.isArray(p.acceptedAnswers) ? p.acceptedAnswers : [p.acceptedAnswers]
						return {
							blankIndex,
							answers: accepted.map(a => (a == null ? '' : String(a).trim())).filter(Boolean)
						}
					})
			},
	
			// Tự chấm: điểm = (số blank đúng / tổng blank) * points (làm tròn 2 chữ số khi hiển thị gợi ý)
			autoScore() {
				const parts = this.question?.config?.parts || []
				const blanks = parts.filter(p => p.type === 'blank')
				if (blanks.length === 0) return 0
	
				let correct = 0
				blanks.forEach(b => {
					if (this.isBlankCorrect(b.id)) correct += 1
				})
				const pts = Number(this.question?.points ?? 0)
				return (correct / blanks.length) * pts
			},
			autoScoreRounded() {
				return Math.round((this.autoScore + Number.EPSILON) * 100) / 100
			},
	
			// Chip điểm chuẩn hoá
			displayScore() {
				// Chỉ manualScore có nguồn teacher_regrade mới ghi đè điểm tự động.
				if (this.hasManualRegrade) return Number(this.grading.manualScore)
				return this.autoScoreRounded
			},
			hasManualRegrade() {
				return this.grading?.manualScoreSource === 'teacher_regrade'
					&& this.grading?.manualScore !== null
					&& this.grading?.manualScore !== undefined
			},
			canRegrade() {
				// Chỉ bài đã chấm và trả bài (status 4) mới được chấm lại;
				// status 2/3 vẫn đi theo luồng nộp/chấm nháp bình thường.
				const status = Number(this.submissionstatus)
				return this.isGrade && status === 4
			},
			lastRegradeReason() {
				const history = Array.isArray(this.grading?.regradeHistory) ? this.grading.regradeHistory : []
				const last = history[history.length - 1]
				return last?.reason || this.grading?.manualScoreReason || ''
			},
			isRegradeFormValid() {
				const score = Number(this.regradeForm.score)
				return Number.isFinite(score) && score >= 0 && score <= this.effectiveMaxPoints
					&& String(this.regradeForm.reason || '').trim().length > 0
			},
			effectiveMaxPoints() {
				return Number(this.question?.points ?? 0)
			},
			scoreChipColor() {
				const s = this.displayScore
				const max = this.effectiveMaxPoints
				if (s <= 0) return 'error'
				if (max && s >= max) return 'success'
				return 'primary'
			}
		},
		watch: {
			// Đồng bộ khi prop "answer" đổi từ bên ngoài
			answer: {
				deep: true,
				handler(ans) {
					const newAnswers = this.buildInitialAnswers(ans, this.question?.config?.parts || [])
					const isChanged = JSON.stringify(newAnswers) !== JSON.stringify(this.userAnswers)
					if (isChanged) {
						this.userAnswers = newAnswers
					}
				}
			},
			// Khi học sinh nhập (hoặc GV reorder sửa – nếu có), phát ra answer-change
			userAnswers: {
				deep: true,
				handler(val) {
					// Không ghi đè khi đã nộp; student không được sửa nữa
					if (this.submissionstatus < 2) {
						this.$emit('answer-change', { ...val })
					}
	
					// Trang chấm chỉ cập nhật autoScore; điểm giáo viên đã chấm lại phải được giữ nguyên.
					if (this.isGrade) {
						const score = this.autoScoreRounded
						const keepManual = this.hasManualRegrade
						this.$emit('grading-change', {
							...(this.grading || {}),
							autoScore: score,
							manualScore: keepManual ? this.grading.manualScore : null,
							manualScoreSource: keepManual ? 'teacher_regrade' : null
						})
					}
				}
			}
		},
		mounted() {
			this.widthScreen = window.innerWidth
			// Lần đầu vào trang chấm: giữ manualScore chỉ khi nó có nguồn chấm lại rõ ràng;
			// manualScore cũ bằng điểm tự động không được xem là điểm giáo viên chốt.
			if (this.isGrade) {
				const hasManual = this.grading?.manualScoreSource === 'teacher_regrade'
				const score = this.autoScoreRounded
				this.$emit('grading-change', {
					...(this.grading || {}),
					autoScore: score,
					manualScore: hasManual ? this.grading.manualScore : null,
					manualScoreSource: hasManual ? 'teacher_regrade' : null
				})
			}
			window.addEventListener('resize', () => { this.handleResize() })
		},
		methods: {
			handleResize() {
				this.widthScreen = window.innerWidth;
			},
			// Khởi tạo map answer cho các blank
			buildInitialAnswers(ansObj, parts) {
				const map = {}
					; (parts || []).forEach(p => {
						if (p.type === 'blank') {
							const raw = ansObj && typeof ansObj === 'object' ? ansObj[p.id] : ''
							map[p.id] = raw != null ? String(raw) : ''
						}
					})
				return map
			},
			onBlurBlank(blankId) {
				// có thể thêm chuẩn hoá theo nhu cầu (ví dụ trim)
				if (this.userAnswers[blankId] != null) {
					this.userAnswers[blankId] = String(this.userAnswers[blankId]).trim()
				}
			},
			normalizeAnswer(value) {
				// Chuẩn hóa Unicode để dấu trừ nhập từ đề/PDF khớp với dấu trừ ASCII trong đáp án.
				// Chuẩn hóa các dạng dấu nháy đơn/kép (Word smart quotes, typographic quotes) về dạng ASCII chuẩn.
				return String(value ?? '')
					.normalize('NFKC')
					.replace(/[’‘ʼ`´ʻʽʹ]/g, "'")
					.replace(/[“”„‟]/g, '"')
					.replace(/[−–—﹣－]/g, '-')
					.replace(/\s+/g, '')
					.trim()
					.toLowerCase()
			},
			answersEquivalent(left, right) {
				const normalizedLeft = this.normalizeAnswer(left)
				const normalizedRight = this.normalizeAnswer(right)
				if (!normalizedLeft || !normalizedRight) return normalizedLeft === normalizedRight

				// Dấu phẩy và dấu chấm đều được chấp nhận làm dấu thập phân.
				// Chỉ chuyển đổi khi toàn chuỗi là một số để không làm thay đổi đáp án chữ.
				const numericPattern = /^[+-]?(?:(?:\d+(?:[.,]\d+)?)|(?:[.,]\d+))$/
				const leftNumber = numericPattern.test(normalizedLeft)
					? Number(normalizedLeft.replace(',', '.'))
					: null
				const rightNumber = numericPattern.test(normalizedRight)
					? Number(normalizedRight.replace(',', '.'))
					: null
				if (Number.isFinite(leftNumber) && Number.isFinite(rightNumber)) {
					return Math.abs(leftNumber - rightNumber) < 1e-9
				}
				return normalizedLeft === normalizedRight
			},
			isBlankCorrect(blankId) {
				const parts = this.question?.config?.parts || []
				const blank = parts.find(p => p.type === 'blank' && p.id === blankId)
				if (!blank) return false
	
				const student = this.userAnswers?.[blankId]
				const accepted = Array.isArray(blank.acceptedAnswers) ? blank.acceptedAnswers : [blank.acceptedAnswers]
				return accepted
					.filter(a => a != null)
					.some(a => this.answersEquivalent(a, student))
			},
			getWidth(value) {
				const len = (value?.length || 1) + 1
				return `${len + 6}ch`
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
			openRegradeDialog() {
				this.regradeForm = {
					score: this.displayScore,
					reason: this.lastRegradeReason || ''
				}
				this.regradeReasonError = false
				this.regradeDialog = true
			},
			saveRegrade() {
				const reason = String(this.regradeForm.reason || '').trim()
				const score = Number(this.regradeForm.score)
				if (!reason) {
					this.regradeReasonError = true
					Vue.$toast?.warning('Vui lòng nhập lý do chấm lại.', { position: 'top' })
					return
				}
				if (!Number.isFinite(score) || score < 0 || score > this.effectiveMaxPoints) return

				const currentScore = this.displayScore
				// Lưu snapshot trước/sau trong SubmissionContent để đối chứng được
				// cả đáp án, đáp án chuẩn và nguồn điểm, không chỉ riêng con số mới.
				const answerSnapshot = JSON.parse(JSON.stringify(this.userAnswers || {}))
				const acceptedAnswersSnapshot = (this.question?.config?.parts || [])
					.filter(part => part.type === 'blank')
					.map(part => ({
						id: part.id,
						acceptedAnswers: Array.isArray(part.acceptedAnswers)
							? [...part.acceptedAnswers]
							: [part.acceptedAnswers]
					}))
				const history = Array.isArray(this.grading?.regradeHistory)
					? [...this.grading.regradeHistory]
					: []
				const user = this.vueData?.user || {}
				// Lịch sử nằm trong SubmissionContent; server đã snapshot toàn bộ payload vào tblEL_Log_ChamBai.
				history.push({
					action: 'REGRADE_QUESTION',
					questionId: this.question?.id || null,
					previousScore: currentScore,
					newScore: score,
					previousAnswer: answerSnapshot,
					newAnswer: answerSnapshot,
					acceptedAnswers: acceptedAnswersSnapshot,
					previousGrading: {
						autoScore: this.grading?.autoScore ?? this.autoScoreRounded,
						manualScore: this.grading?.manualScore ?? null,
						manualScoreSource: this.grading?.manualScoreSource || null
					},
					newGrading: {
						autoScore: this.autoScoreRounded,
						manualScore: score,
						manualScoreSource: 'teacher_regrade'
					},
					reason: reason,
					teacherId: user.UserID || null,
					teacherName: user.HoTen || [user.LastName, user.FirstName].filter(Boolean).join(' ') || null,
					createdAt: new Date().toISOString()
				})

				this.$emit('grading-change', {
					...(this.grading || {}),
					autoScore: this.autoScoreRounded,
					manualScore: score,
					manualScoreSource: 'teacher_regrade',
					manualScoreReason: reason,
					regradeHistory: history
				})
				this.regradeDialog = false
				this.regradeReasonError = false
				Vue.$toast?.success('Đã cập nhật điểm và ghi nhận lý do chấm lại.', { position: 'top' })
			},
			onStudentCommentInput(val) {
				this.grading.comment = val
				this.$emit('grading-change', { ...this.grading, comment: val })
			},
			handleCopyPaste(event) {
				if (this.isBlockCopyPaste && !this.readonly) {
					event.preventDefault();
					// Có thể thêm thông báo cho user
					Vue.$toast?.warning('Không được phép sao chép/dán nội dung trong bài này', { position: "top" });
				}
			},
			handleContextMenu(event) {
				if (this.isBlockCopyPaste && !this.readonly) {
					event.preventDefault();
				}
			}
		}
	}
</script>