<template>
	<v-container class="page-container" fluid>
		<div v-if="loading" class="text-center pa-10">
			<v-progress-circular indeterminate size="64" color="primary"></v-progress-circular>
			<p class="mt-4 text-muted">{{ IsEnglish ? 'Loading report data...' : 'Đang tải dữ liệu báo cáo...' }}</p>
		</div>
		<v-card v-else-if="!hasData" class="ma-4 pa-10 text-center" flat>
			<v-icon size="64" color="grey-lighten-1">mdi-alert-circle-outline</v-icon>
			<h2 class="mt-4 text-h6">{{ IsEnglish ? 'Unable to load data' : 'Không thể tải dữ liệu' }}</h2>
			<p class="text-muted">
				{{ IsEnglish ? 'NoDataOrError' : 'Không tìm thấy dữ liệu cho bài tập này hoặc đã có ỗi xảy ra.' }}
			</p>
		</v-card>

		<div v-else>
			<div class="page-header pa-3 mb-0">
				<div class="d-flex align-center">
					<div class="d-flex align-center">
						<div>
							<div class="ms-4 text-h6 font-weight-bold">
								{{ IsEnglish ? 'DetailedSubmissionReport' : 'Báo cáo chi tiết bài làm' }}</div>
							<div class="ms-4 text-body-2 text-medium-emphasis">
								{{ IsEnglish ? 'Class' : 'Lớp' }}: {{ className }} - {{ $t('message.Assignment') }}: {{
									assignmentTitle }}
							</div>
							<div class="ms-4 text-caption text-medium-emphasis">
								{{ attemptViewHint }}
							</div>
						</div>
					</div>
					<v-spacer></v-spacer>
					<!-- <div>
						<v-btn color="primary" variant="flat" prepend-icon="mdi-file-excel-outline"
							@click="exportToCSV">
							{{ IsEnglish ? 'Export' : 'Xuất' }} CSV
						</v-btn>
					</div> -->
					<div class="d-flex align-center ga-2">
						<v-select
							v-model="selectedAttempt"
							:items="attemptOptions"
							item-title="title"
							item-value="value"
							:label="IsEnglish ? 'Submission attempt' : 'Lượt nộp'"
							class="attempt-filter"
							style="width: 190px; min-width: 170px"
							density="compact"
							hide-details
							variant="outlined"
						></v-select>
						<v-btn color="primary" variant="outlined" prepend-icon="mdi-microsoft-excel"
							@click="exportToExcel">
							{{ IsEnglish ? 'Export' : 'Xuất' }} Excel
						</v-btn>
					</div>
				</div>
			</div>

			<!-- Bảng Crosstab -->
			<v-card class="table-card pa-2">
				<v-table fixed-header height="80vh" density="compact">
					<thead>
						<tr>
							<th class="fixed-col student-id-col">{{ IsEnglish ? 'Student Code' : 'Mã HS' }}</th>
							<th class="fixed-col text-center student-name-col">{{ IsEnglish ? 'Registration Number' : 'Số danh bộ'}}</th>
							<th class="fixed-col student-name-col">{{ IsEnglish ? 'Student' : 'Học sinh' }}</th>
							<th class="text-center attempt-col">{{ IsEnglish ? 'Attempt' : 'Lần nộp' }}</th>
							<th v-for="(header, index) in questionHeaders" :key="header.QuestionID_InJSON"
								class="text-center question-col">
								<v-tooltip location="top">
									<template v-slot:activator="{ props }">
										<span v-bind="props">{{ $t('message.Question') + ` ` + (index + 1) }}</span>
									</template>
									<div v-html="header.QuestionTitle"></div>
								</v-tooltip>
							</th>
							<th class="fixed-col-right score-col text-center">{{ $t('message.TotalScore') }}</th>
						</tr>
					</thead>
					<tbody>
						<!-- Each attempt has its own SubmissionID; an attempt filter collapses rows to one per student. -->
						<tr v-for="student in visibleStudentResults"
							:key="selectedAttempt === 'all' ? (student.SubmissionID || ('student-' + student.HocSinhID)) : ('student-' + student.HocSinhID + '-attempt-' + selectedAttempt)"
							:class="getRowClass(student.FinalScore)">
							<td class="fixed-col student-id-col text-medium-emphasis"
								@click="viewStudentSubmission(student)">
								{{ student.HocSinhID }}
							</td>
                            <td class="fixed-col text-center  text-medium-emphasis">
                                {{ student.SoDanhBo ?? student.SoTT  }}
                            </td>
							<td class="fixed-col student-name-col  "
								@click="viewStudentSubmission(student)">
								{{ student.HoTen }}
							</td>
							<td class="text-center text-medium-emphasis">
								{{ formatAttemptLabel(student) }}
							</td>
							<td v-for="header in questionHeaders" :key="header.QuestionID_InJSON" class="text-center">
								<uc-cell-display :cell-data="student[header.QuestionID_InJSON]" />
							</td>
							<td class="fixed-col-right score-col text-center font-weight-bold">{{ student.FinalScore }}
							</td>
						</tr>
					</tbody>
					<tfoot>
						<tr>
							<th class="fixed-col student-id-col"></th>
							<th></th>
							<th class="fixed-col student-name-col">{{ IsEnglish ? 'Accuracy Rate (%)' : 'Tỉ lệ đúng (%)'
							}}
							</th>
							<th></th>

							<th v-for="header in questionHeaders" :key="header.QuestionID_InJSON" class="text-center">
								{{ isNaN(getCorrectPercentage(header.QuestionID_InJSON)) ? '' :
									getCorrectPercentage(header.QuestionID_InJSON) + '%' }}

							</th>
							<th class="fixed-col-right score-col"></th>
						</tr>
					</tfoot>
				</v-table>
			</v-card>
		</div>
	</v-container>
</template>

<script>
	export default {
		props: {
		assignToClassId: { type: Number, required: true }
	},
	data() {
		this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
		return {
			loading: true,
			selectedAttempt: 'all',
			questionHeaders: [],
			studentResults: [],
			columnStats: [],
			className: '...',
			assignmentTitle: '...',
			csvContent: []
		};
	},
	computed: {
		hasData() {
			return !this.loading && this.questionHeaders.length > 0 && this.studentResults.length > 0;
		},
		// Cache question statistics by ID so the footer does not scan the full list on every cell render.
		columnStatsByQuestionId() {
			const statsById = Object.create(null);
			this.columnStats.forEach(stat => {
				if (!Object.prototype.hasOwnProperty.call(statsById, stat.QuestionID_InJSON)) statsById[stat.QuestionID_InJSON] = [];
				statsById[stat.QuestionID_InJSON].push(stat);
			});
			return statsById;
		},
		attemptOptions() {
			const attempts = Array.from(new Set(this.studentResults
				.map(student => Number(student.LanNop))
				.filter(attempt => Number.isInteger(attempt) && attempt > 0)))
				.sort((a, b) => a - b);
			return [
				{ title: this.IsEnglish ? 'All attempts' : 'Tất cả lượt', value: 'all' },
				...attempts.map(attempt => ({
					title: this.IsEnglish ? `Attempt ${attempt}` : `Lần ${attempt}`,
					value: attempt
				}))
			];
		},
		// Keep absent attempts visible in a class-wide view so teachers can spot students who did not take that attempt.
		visibleStudentResults() {
			if (this.selectedAttempt === 'all') return this.studentResults;
			const attemptNumber = Number(this.selectedAttempt);
			const studentsById = new Map();
			this.studentResults.forEach(row => {
				const studentKey = String(row.HocSinhID);
				if (!studentsById.has(studentKey)) studentsById.set(studentKey, []);
				studentsById.get(studentKey).push(row);
			});
			return Array.from(studentsById.values()).map(rows => {
				const selectedRow = rows.find(row => Number(row.LanNop) === attemptNumber);
				if (selectedRow) return selectedRow;
				const placeholder = {
					...rows[0],
					SubmissionID: null,
					FinalScore: null,
					LanNop: null,
					MissingSelectedAttempt: true
				};
				this.questionHeaders.forEach(header => { placeholder[header.QuestionID_InJSON] = null; });
				return placeholder;
			});
		},
		attemptViewHint() {
			if (this.selectedAttempt === 'all') {
				return this.IsEnglish
					? 'Each submission attempt is shown on a separate row; accuracy rates include all attempts.'
					: 'Mỗi lượt nộp hiển thị trên một dòng; tỉ lệ đúng tính trên tất cả lượt nộp.';
			}
			return this.IsEnglish
				? `Showing attempt ${this.selectedAttempt}; students without it remain listed.`
				: `Đang xem lần ${this.selectedAttempt}; học sinh chưa nộp lượt này vẫn được hiển thị.`;
		},
		IsEnglish: function () {
			return this.$i18n.locale == 'en'
		}
	},
	methods: {
		async fetchData() {
			if (!this.assignToClassId) {
				this.loading = false;
				return;
			}
			this.loading = true;
			await ajaxCALL("lms/EL_Teacher_GetAssignmentCrosstabReport", { AssignToClassID: this.assignToClassId }, (res) => {
				if (res && res.data && res.data.length >= 4) {
					this.className = res.data[0][0].ClassName;
					this.assignmentTitle = res.data[0][0].AssignmentTitle;
					this.questionHeaders = res.data[1];
					this.columnStats = res.data[2];
					this.studentResults = res.data[3];
				} else {
					this.questionHeaders = [];
					this.studentResults = [];
				}
			});
			this.loading = false;
		},
		getCorrectPercentage(questionId) {
			const stats = this.columnStatsByQuestionId[questionId] || [];
			const visibleStats = this.selectedAttempt === 'all'
				? stats
				: stats.filter(stat => Number(stat.LanNop) === Number(this.selectedAttempt));
			const correctCount = visibleStats.reduce((total, stat) => total + Number(stat.CorrectCount || 0), 0);
			const resultCount = visibleStats.reduce((total, stat) => total + Number(stat.ResultCount || 0), 0);
			return resultCount ? ((correctCount * 100) / resultCount).toFixed(1) : 'N/A';
		},
		formatAttemptLabel(student) {
			if (student.MissingSelectedAttempt || !student.SubmissionID) {
				return this.IsEnglish ? 'Not submitted' : 'Chưa nộp';
			}
			if (!student.LanNop) return this.IsEnglish ? 'Attempt unknown' : 'Không rõ lần nộp';
			return this.IsEnglish ? `Attempt ${student.LanNop}` : `Lần ${student.LanNop}`;
		},
		getRowClass(score) {
			if (score != null && score < 5.0) {
				return 'low-score-row';
			}
			return '';
		},
		viewStudentSubmission(student) {
			if (student.SubmissionID) {
				Toast.info({ text: `Mở bài của ${student.HoTen}...` });
				// Mở trang chấm bài chi tiết
				// openWindow({ url: `/lms_teacher_grading?SubmissionID=${student.SubmissionID}` });
			} else {
				Toast.warn({ text: `Học sinh ${student.HoTen} chưa nộp bài.` });
			}
		},
		exportToCSV() {
			if (!this.hasData) {
				Toast.warn({ text: 'Không có dữ liệu để xuất file.' });
				return;
			}

			// 1. Tạo Header cho file CSV
			const headers = [
				'Mã HS', 'Họ và tên', 'Lần nộp',
				...this.questionHeaders.map((h, i) => `Câu ${i + 1}`),
				'Tổng điểm'
			];
			let csvContent = headers.join(',') + '\r\n';

			// 2. Thêm dữ liệu từng học sinh
			this.visibleStudentResults.forEach(student => {
				const row = [
					student.HocSinhID,
					`"${student.HoTen}"`, // Đặt trong dấu nháy kép để xử lý tên có dấu phẩy
					this.formatAttemptLabel(student),
					...this.questionHeaders.map(h => {
						const cellData = student[h.QuestionID_InJSON];
						if (!cellData) return 'N/A';
						try {
							const data = JSON.parse(cellData);
							switch (data.status) {
								case 'CORRECT': return this.IsEnglish ? 'Correct' : 'Đúng';
								case 'INCORRECT': return this.IsEnglish ? 'Wrong' : 'Sai';
								case 'GRADED': return data.score;
								case 'PENDING': return this.IsEnglish ? 'Waiting grade' : 'Chờ chấm';
								case 'NOT_ANSWERED': return this.IsEnglish ? 'Not complete' : 'Không làm';
								default: return 'N/A';
							}
						} catch (e) {
							return 'N/A';
						}
					}),
					student.FinalScore
				];
				csvContent += row.join(',') + '\r\n';
			});
			// 3. Kích hoạt tải file
			const blob = new Blob([`\uFEFF${csvContent}`], { type: 'text/csv;charset=utf-8;' });
			const link = document.createElement("a");
			if (link.download !== undefined) {
				const url = URL.createObjectURL(blob);
				const fileName = `BaoCao_${this.className}_${this.assignmentTitle.replace(/ /g, '_')}.csv`;
				link.setAttribute("href", url);
				link.setAttribute("download", fileName);
				link.style.visibility = 'hidden';
				document.body.appendChild(link);
				link.click();
				document.body.removeChild(link);
			}
		},
		exportToExcel() {
			// Rebuild rows for each export so repeated clicks do not grow the in-memory worksheet.
			this.csvContent = [];
			const headers = [
				'Mã HS','Số danh bộ', 'Họ và tên', 'Lần nộp',
				...this.questionHeaders.map((h, i) => `Câu ${i + 1}`),
				'Tổng điểm'
			];
			const footer = [
				'', '', 'Tỉ lệ đúng (%)', '',
				...this.questionHeaders.map((h, i) => (isNaN(this.getCorrectPercentage(h.QuestionID_InJSON)) ? '' :
					this.getCorrectPercentage(h.QuestionID_InJSON) + '%')),
				''
			];
			this.visibleStudentResults.forEach(student => {
				const row = [
					student.HocSinhID,
					student.SoDanhBo ?? student.SoTT,
					`${student.HoTen}`,
					this.formatAttemptLabel(student),
					...this.questionHeaders.map(h => {
						const cellData = student[h.QuestionID_InJSON];
						if (!cellData) return '-';
						try {
							const data = JSON.parse(cellData);
							switch (data.status) {
								case 'CORRECT': return this.IsEnglish ? 'Correct' : 'Đúng';
								case 'INCORRECT': return this.IsEnglish ? 'Wrong' : 'Sai';
								case 'GRADED': return data.score;
								case 'PENDING': return this.IsEnglish ? 'Waiting grade' : 'Chờ chấm';
								case 'NOT_ANSWERED': return this.IsEnglish ? 'Not complete' : 'Không làm';
								default: return '-';
							}
						} catch (e) {
							return '-';
						}
					}),
					student.FinalScore
				];
				this.csvContent.push(row)
			});
			const worksheet = XLSX.utils.aoa_to_sheet(
				[headers, ...this.csvContent, footer]
			)

			const workbook = XLSX.utils.book_new()
			XLSX.utils.book_append_sheet(workbook, worksheet, 'BaoCao')

			const fileName = `BaoCao_${this.className}_${this.assignmentTitle.replace(/ /g, '_')}.xlsx`
			XLSX.writeFile(workbook, fileName)
		}
	},
	mounted() {
		this.fetchData();
	}
	}
</script>