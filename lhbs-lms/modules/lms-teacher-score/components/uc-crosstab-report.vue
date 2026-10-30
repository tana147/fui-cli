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
							@click="openExportColumnsDialog">
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

		<!-- Keep question and identity fields independently selectable; all are checked for each new export. -->
		<v-dialog v-model="exportColumnsDialog.show" max-width="600" scrollable>
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold">
					{{ IsEnglish ? 'Choose Excel columns' : 'Chọn cột xuất Excel' }}
					<v-spacer />
					<v-btn icon @click="exportColumnsDialog.show = false"><v-icon>mdi-close</v-icon></v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-1">
					<div class="text-body-2 text-medium-emphasis mb-2">
						{{ IsEnglish ? 'All columns start selected. Uncheck columns you do not need.' : 'Mặc định đã chọn tất cả cột. Bỏ chọn những cột bạn không cần xuất.' }}
					</div>
					<v-checkbox v-for="column in exportColumnsDialog.columns" :key="column.value"
						v-model="exportColumnsDialog.selectedColumns" :value="column.value" :label="column.label"
						density="compact" hide-details />
				</v-card-text>
				<v-card-actions class="pa-3">
					<v-spacer />
					<v-btn text @click="exportColumnsDialog.show = false">{{ IsEnglish ? 'Cancel' : 'Hủy' }}</v-btn>
					<v-btn color="primary" elevation="0" :disabled="!exportColumnsDialog.selectedColumns.length"
						@click="confirmExportColumns">{{ IsEnglish ? 'Export Excel' : 'Xuất Excel' }}</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
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
			csvContent: [],
			exportColumnsDialog: { show: false, columns: [], selectedColumns: [], pending: null }
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
		openExportColumnsDialog() {
			// Rebuild rows for each export so repeated clicks do not grow the in-memory worksheet.
			const columns = [
				{ key: 'studentId', label: 'Mã HS' },
				{ key: 'studentNumber', label: 'Số danh bộ' },
				{ key: 'studentName', label: 'Họ và tên' },
				{ key: 'attempt', label: 'Lần nộp' },
				...this.questionHeaders.map((header, index) => ({ key: 'question_' + index, label: 'Câu ' + (index + 1), questionId: header.QuestionID_InJSON })),
				{ key: 'totalScore', label: 'Tổng điểm' }
			];
			const rows = this.visibleStudentResults.map(student => {
				const row = {
					studentId: student.HocSinhID,
					studentNumber: student.SoDanhBo ?? student.SoTT,
					studentName: String(student.HoTen ?? ''),
					attempt: this.formatAttemptLabel(student),
					totalScore: student.FinalScore
				};
				columns.filter(column => column.questionId !== undefined).forEach(column => {
					const cellData = student[column.questionId];
					if (!cellData) {
						row[column.key] = '-';
						return;
					}
					try {
						const result = JSON.parse(cellData);
						switch (result.status) {
							case 'CORRECT': row[column.key] = this.IsEnglish ? 'Correct' : 'Đúng'; break;
							case 'INCORRECT': row[column.key] = this.IsEnglish ? 'Wrong' : 'Sai'; break;
							case 'GRADED': row[column.key] = result.score; break;
							case 'PENDING': row[column.key] = this.IsEnglish ? 'Waiting grade' : 'Chờ chấm'; break;
							case 'NOT_ANSWERED': row[column.key] = this.IsEnglish ? 'Not complete' : 'Không làm'; break;
							default: row[column.key] = '-';
						}
					} catch (e) {
						row[column.key] = '-';
					}
				});
				return row;
			});
			const footer = { studentName: this.IsEnglish ? 'Accuracy Rate (%)' : 'Tỉ lệ đúng (%)' };
			columns.filter(column => column.questionId !== undefined).forEach(column => {
				const percentage = this.getCorrectPercentage(column.questionId);
				footer[column.key] = isNaN(percentage) ? '' : percentage + '%';
			});
			this.exportColumnsDialog.columns = columns.map(column => ({ value: column.key, label: column.label }));
			this.exportColumnsDialog.selectedColumns = columns.map(column => column.key);
			this.exportColumnsDialog.pending = {
				columns,
				rows,
				footer,
				fileName: 'BaoCao_' + this.className + '_' + this.assignmentTitle.replace(/ /g, '_') + '.xlsx'
			};
			this.exportColumnsDialog.show = true;
		},
		confirmExportColumns() {
			const pending = this.exportColumnsDialog.pending;
			const selected = new Set(this.exportColumnsDialog.selectedColumns);
			if (!pending || !selected.size) return;
			const columns = pending.columns.filter(column => selected.has(column.key));
			if (!columns.length) return;
			const headers = columns.map(column => column.label);
			const rows = pending.rows.map(row => columns.map(column => row[column.key] ?? ''));
			const footer = columns.map(column => pending.footer[column.key] ?? '');
			const worksheet = XLSX.utils.aoa_to_sheet([headers, ...rows, footer]);
			const workbook = XLSX.utils.book_new();
			XLSX.utils.book_append_sheet(workbook, worksheet, 'BaoCao');
			XLSX.writeFile(workbook, pending.fileName);
			this.exportColumnsDialog.show = false;
		},
		exportToExcel() {
			this.openExportColumnsDialog();
		}
	},
	mounted() {
		this.fetchData();
	}
	}
</script>