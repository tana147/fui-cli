<template>
	<div class="pa-4" style="max-height: calc(100dvh - 212px); overflow: auto; padding-bottom: 48px !important">
		<!-- Tổng quan - Cards nhỏ gọn -->
		<v-row dense class="mb-2">
			<v-col cols="6" sm="3">
				<v-card class="pa-3 text-center" color="blue lighten-5" elevation="1">
					<v-icon color="white" size="28">mdi-book-open-variant</v-icon>
					<div class="text-h6 font-weight-bold mt-1">{{ tongSoMon }}</div>
					<div class="text-caption">{{ IsLanguage ? 'Subjects' : 'Môn học' }}</div>
				</v-card>
			</v-col>
			<v-col cols="6" sm="3">
				<v-card class="pa-3 text-center" color="green lighten-5" elevation="1">
					<v-icon color="white" size="28">mdi-check-circle</v-icon>
					<div class="text-h6 font-weight-bold mt-1">{{ hoanhThanh }}</div>
					<div class="text-caption">{{ IsLanguage ? 'Completed' : 'Hoàn thành' }}</div>
				</v-card>
			</v-col>
			<v-col cols="6" sm="3">
				<v-card class="pa-3 text-center" color="orange lighten-5" elevation="1">
					<v-icon color="white" size="28">mdi-clock-outline</v-icon>
					<div class="text-white text-h6 font-weight-bold mt-1">{{ dangLam }}</div>
					<div class="text-white text-caption">{{ IsLanguage ? 'In Progress' : 'Đang làm' }}</div>
				</v-card>
			</v-col>
			<v-col cols="6" sm="3">
				<v-card class="pa-3 text-center" color="purple lighten-5" elevation="1">
					<v-icon color="white" size="28">mdi-file-document</v-icon>
					<div class="text-h6 font-weight-bold mt-1">{{ tongBaiTap }}</div>
					<div class="text-caption">{{ IsLanguage ? 'Total Assignments' : 'Tổng bài tập' }}</div>
				</v-card>
			</v-col>
		</v-row>

		<!-- Danh sách môn học - Compact -->
		<v-card elevation="2">
			<v-card-title class="py-2 bg-blue darken-2 text-white">
				<v-icon color="white" size="20" class="mr-2">mdi-format-list-bulleted</v-icon>
				<span class="text-subtitle-1">{{ IsLanguage ? 'Progress by Subject' : 'Tiến độ theo môn' }}</span>
			</v-card-title>

			<v-expansion-panels accordion flat>
				<v-expansion-panel v-for="(mon, index) in danhSachMonHoc" :key="index">
					<v-expansion-panel-title class="py-2">
						<div class="d-flex align-center justify-space-between" style="width: 100%;">
							<div class="d-flex align-center">
								<v-icon :color="mon.color" size="20" class="mr-2">
									{{ mon.icon }}
								</v-icon>
								<div>
									<div class="text-subtitle-2 font-weight-medium">{{ mon.ten }}</div>
										<div class="text-caption text--secondary">{{ mon.baiTap.length }} {{ IsLanguage ? 'tasks' : 'bài' }}</div>
								</div>
							</div>
							<v-chip x-small :color="getTienDoColor(mon.tiLe)" dark class="mr-2">
								{{ mon.tiLe }}%
							</v-chip>
						</div>
					</v-expansion-panel-title>

					<v-expansion-panel-text>
						<v-progress-linear :value="mon.tiLe" :color="getTienDoColor(mon.tiLe)" height="6" class="mb-3"
							rounded></v-progress-linear>

						<v-list class="mt-0 pt-0">
							<template v-for="(baiTap, idx) in mon.baiTap" :key="baiTap.AssignmentID">
								<v-list-item class="py-2" two-line>
									<v-list-item-title class="text-body-2 font-weight-medium mb-1">
										{{ baiTap.Title }}
									</v-list-item-title>
									<v-list-item-subtitle class="text-caption">
										<v-icon x-small class="mr-1">mdi-calendar</v-icon>
										{{ getTuanShort(baiTap.TuanHienThi) }}
										<span class="mx-1">•</span>
										<v-icon x-small class="mr-1">mdi-clock</v-icon>
										{{ formatDateShort(baiTap.SubmissionTime) }}
										<span v-if="baiTap.SoLanNop > 1" class="ml-2">
											<v-chip x-small outlined color="primary">
												<v-icon x-small left>mdi-history</v-icon>
												{{ IsLanguage ? 'Submitted' : 'Đã nộp' }} {{ baiTap.SoLanNop }} {{ IsLanguage ? 'times' : 'lần' }}
											</v-chip>
										</span>
									</v-list-item-subtitle>
									<div v-if="baiTap.lichSu && baiTap.lichSu.length > 1" class="d-flex flex-wrap align-center text-caption text--secondary mt-1">
										<span class="mr-2">{{ IsLanguage ? 'Scores per submission:' : 'Điểm các lần nộp:' }}</span>
										<span v-for="lan in baiTap.lichSu" :key="lan.SubmissionID" class="mr-3 mb-1">
											{{ IsLanguage ? 'Attempt' : 'Lần' }} {{ lan.LanNop || '?' }}: {{ formatScore(lan) }}
										</span>
									</div>
									<template #append>
										<div class="text-right">
											<v-chip x-small :color="getStatusColor(baiTap.SubmissionStatus)" dark>
												{{ getStatusText(baiTap.SubmissionStatus) }}
											</v-chip>
											<div v-if="baiTap.Score !== null && baiTap.Score !== undefined" class="text-body-2 font-weight-bold mt-1">
												{{ IsLanguage ? 'Attempt' : 'Lần' }} {{ baiTap.LanNop || '?' }}: {{ formatScore(baiTap) }}
											</div>
											<div v-else class="text-caption text--secondary mt-1">
												{{ IsLanguage ? 'Attempt' : 'Lần' }} {{ baiTap.LanNop || '?' }}: {{ IsLanguage ? 'Not graded' : 'Chưa chấm' }}
											</div>
										</div>
									</template>
								</v-list-item>
								<v-divider v-if="idx < mon.baiTap.length - 1"></v-divider>
							</template>
						</v-list>
					</v-expansion-panel-text>
				</v-expansion-panel>
			</v-expansion-panels>
		</v-card>
	</div>
</template>

<script>
	export default {
		name: 'HomeworkTracker',
		data() {
			return {
				vueData,
				homeworkData: [],
				IsLanguage: localStorage.getItem('IsLanguage') ? JSON.parse(localStorage.getItem('IsLanguage')) : false
			}
		},
		async mounted() {
			this.homeworkData = await ajaxCALLPromise("lms/EL_PhuHuynh_TienDoBaiTap_ByHocSinhID", {
				HocSinhID: vueData.HocSinhSelected.HocSinhID,
				NienKhoa: vueData.NienKhoa
			})
		},
		watch: {
			'$i18n.locale': function (locale) {
				this.IsLanguage = locale === 'en'
			}
		},
		computed: {
			baiTapTheoBai() {
				const baiTapMap = {};

				this.homeworkData.forEach(item => {
					const assignmentKey = item.AssignmentID;
					if (!baiTapMap[assignmentKey]) {
						baiTapMap[assignmentKey] = {
							latest: item,
							lichSu: []
						};
					}
					baiTapMap[assignmentKey].lichSu.push(item);
					if (this.isLaterSubmission(item, baiTapMap[assignmentKey].latest)) {
						baiTapMap[assignmentKey].latest = item;
					}
				});

				return Object.values(baiTapMap).map(group => {
					const lichSu = group.lichSu.slice().sort((a, b) => {
						const lanNopDiff = (Number(a.LanNop) || 0) - (Number(b.LanNop) || 0);
						if (lanNopDiff !== 0) return lanNopDiff;
						return (Number(a.SubmissionID) || 0) - (Number(b.SubmissionID) || 0);
					});

					return Object.assign({}, group.latest, { lichSu });
				});
			},

			danhSachMonHoc() {
			const monHocMap = {};
	
				this.baiTapTheoBai.forEach(item => {
					if (!monHocMap[item.TenMonHoc_HienThi]) {
						monHocMap[item.TenMonHoc_HienThi] = {
							icon: item.Icon || 'mdi-book',
							color: item.Color || '#757575',
							items: []
						};
					}
					monHocMap[item.TenMonHoc_HienThi].items.push(item);
				});
	
				return Object.keys(monHocMap).map(tenMon => {
					const baiTap = monHocMap[tenMon].items;
					const hoanhThanh = baiTap.filter(bt => bt.SubmissionStatus === 4).length;
					const tiLe = Math.round((hoanhThanh / baiTap.length) * 100);
	
					return {
						ten: tenMon,
						icon: monHocMap[tenMon].icon,
						color: monHocMap[tenMon].color,
						baiTap: baiTap,
						hoanhThanh: hoanhThanh,
						tong: baiTap.length,
						tiLe: tiLe
					};
				});
			},
	
			tongSoMon() {
				return this.danhSachMonHoc.length;
			},
	
			hoanhThanh() {
				return this.baiTapTheoBai.filter(item => item.SubmissionStatus === 4).length;
			},
	
			dangLam() {
				return this.baiTapTheoBai.filter(item => item.SubmissionStatus === 2).length;
			},

			tongBaiTap() {
				return this.baiTapTheoBai.length;
			}
		},
	
		methods: {
			isLaterSubmission(candidate, current) {
				if (!current) return true;
				const candidateLanNop = Number(candidate.LanNop) || 0;
				const currentLanNop = Number(current.LanNop) || 0;
				if (candidateLanNop !== currentLanNop) return candidateLanNop > currentLanNop;
				const candidateTime = new Date(candidate.SubmissionTime).getTime() || 0;
				const currentTime = new Date(current.SubmissionTime).getTime() || 0;
				if (candidateTime !== currentTime) return candidateTime > currentTime;
				return (Number(candidate.SubmissionID) || 0) > (Number(current.SubmissionID) || 0);
			},

			formatScore(baiTap) {
				if (baiTap.Score === null || baiTap.Score === undefined) return this.IsLanguage ? 'Not graded' : 'Chưa chấm';
				return `${baiTap.Score}/${baiTap.MaxScore}`;
			},

			getStatusText(status) {
				if (this.IsLanguage) {
					switch (status) {
						case 0: return 'Not Started';
						case 1: return 'In Progress';
						case 2: return 'Submitted';
						case 3: return 'Grading';
						case 4: return 'Completed';
						default: return 'Unknown';
					}
				} else {
					switch (status) {
						case 0: return 'Chưa làm';
						case 1: return 'Đang làm';
						case 2: return 'Đã nộp';
						case 3: return 'Đang chấm';
						case 4: return 'Hoàn thành';
						default: return 'Không xác định';
					}
				}
			},
		
				getStatusColor(status) {
				return status === 4 ? 'success' : 'warning';
			},
	
			getTienDoColor(tiLe) {
				if (tiLe >= 80) return 'success';
				if (tiLe >= 50) return 'info';
				if (tiLe >= 30) return 'warning';
				return 'error';
			},
	
			getTuanShort(tuanStr) {
				if (!tuanStr) return '';
				const match = tuanStr.match(/Tuần (\d+) - Tháng (\d+)/);
				if (match) {
					return this.IsLanguage ? `Week ${match[1]} - M${match[2]}` : `Tuần ${match[1]} - T${match[2]}`;
				}
				return tuanStr;
			},
	
			formatDateShort(dateStr) {
				const date = new Date(dateStr);
				const day = String(date.getDate()).padStart(2, '0');
				const month = String(date.getMonth() + 1).padStart(2, '0');
				const hours = String(date.getHours()).padStart(2, '0');
				const minutes = String(date.getMinutes()).padStart(2, '0');
				return `${day}/${month} ${hours}:${minutes}`;
			}
		}
	}
</script>

<style scoped>
.v-expansion-panel-text {
		padding-top: 8px !important;
	}
</style>