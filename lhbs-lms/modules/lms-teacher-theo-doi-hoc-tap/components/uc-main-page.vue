<template>
	<div>
		<v-card>
			<v-card-text class="mt-3 pa-0">
				<v-row>
					<v-col v-for="cap in Object.keys(CapList)">
						<v-card class="border rounded ">
							<v-card-title class="d-flex flex-column border-b" style="background-color:#E3F2FD;">
								<div class="w-100 text-center text-body-1 cap-title">
									{{ $i18n.locale === 'en' ? 'Level' : 'Cấp' }} {{ cap }}
								</div>
								<div class="w-100 text-center text-body-2 cap-sub" style="color: black">
									{{ $i18n.locale === 'en' ? 'Total assignments:' : 'Tổng số bài tập:' }}
									<span class="cap-total">
										{{ CapList[cap].TongBaiTap }}
									</span>
								</div>
							</v-card-title>
							<v-card-text class="d-flex justify-center">
								<uc-chart-apex v-if="CapList[cap].optionsChartPie"
									:options="CapList[cap].optionsChartPie" :key='cap' />
							</v-card-text>
						</v-card>
					</v-col>
				</v-row>


			</v-card-text>
			<v-card-text class=" border rounded mt-3 pa-0">
				<div class="d-flex pa-2 ga-2 border-b">
					<v-spacer></v-spacer>
					<v-select v-model="selectedLopID" :label="$i18n.locale === 'en' ? 'Class' : 'Lớp'" style="max-width:200px" :items="lopList"
						item-title="TenLop" item-value="LopID"></v-select>
					<v-select v-model="selectedMonHocID" :label="$i18n.locale === 'en' ? 'Subject' : 'Môn học'" style="max-width:200px" :items="monHocList"
						item-title="MonHocName" item-value="MonHocID"></v-select>
					<v-btn @click="refresh()" color="primary" variant="outlined"><v-icon start class="me-1">mdi-reload</v-icon>{{ $i18n.locale === 'en' ? 'Refresh' : 'Làm mới' }}</v-btn>
				</div>
				<v-data-table :headers="headers" :items="DataTable" item-value="HocSinhID" hide-default-footer
					show-expand :items-per-page="-1">
					<template v-slot:item.data-table-expand="{ internalItem, isExpanded, toggleExpand }">
						<v-btn :append-icon="isExpanded(internalItem) ? 'mdi-chevron-up' : 'mdi-chevron-down'"
							:text="isExpanded(internalItem) ? ($i18n.locale === 'en' ? 'Collapse' : 'Thu gọn') : ($i18n.locale === 'en' ? 'Details' : 'Chi tiết')" class="text-none"
							color="medium-emphasis" size="small" variant="text" width="105" border slim
							@click="toggleExpand(internalItem)"></v-btn>
					</template>

					<template v-slot:expanded-row="{ columns, item }">
						<tr>
							<td :colspan="columns.length" class="py-2">
								<v-sheet rounded="lg" border>
									<div class="pa-2">
										<h4 style="font-size: 16px; font-weight: 500;">{{ $i18n.locale === 'en' ? 'Learning Growth Trend' : 'Xu hướng phát triển học tập' }}</h4>
										<uc-chart-apex v-if="item.OptionsData" :options="item.OptionsData"
											:key='item.HocSinhID' />
									</div>


									<v-row>
										<!-- <v-col cols="12" md="6">
											<h4 style="font-size: 16px; font-weight: 500;">Kĩ năng học tập</h4>
											<uc-chart-apex v-if="item.OptionsData_Radar"
												:options="item.OptionsData_Radar" :key='item.HocSinhID' />
										</v-col> -->
										<v-col cols="12" md="12">
											<div class="d-flex flex-column ga-2 mt-3">
												<div><b>{{ $i18n.locale === 'en' ? 'Comments: ' : 'Nhận xét: ' }}</b><span class="text-wrap">
														{{ item.NhanXet ?? '-' }}
													</span>
												</div>

												<v-btn variant="outlined" color="primary" :loading="isLoadingNhanXet"
													@click="getNhanXet(item, item.OptionsData)">
													<v-icon start class="me-1">mdi-robot-outline</v-icon> {{ $i18n.locale === 'en' ? 'Click to show AI comments' : 'Chọn để hiển thị nhận xét từ AI' }}
													</v-btn>
											</div>
										</v-col>
									</v-row>
								</v-sheet>

							</td>
						</tr>
					</template>
				</v-data-table>
			</v-card-text>

			<v-card-text class=" border rounded mt-3 pa-0">
				<v-row>
					<v-col cols="12">
						<v-card>
							<v-card-title class="d-flex flex-wrap ga-2" style="height: fit-content">
								<span class="text-primary">{{ $i18n.locale === 'en' ? 'Student academic statistics based on 100% max score of assignments' : 'Thống kê học lực của học sinh dựa trên 100% điểm tối đa bài tập' }}</span>
								<v-spacer></v-spacer>
								<v-btn color="success" variant="text" icon @click="jsonToExcel({
									data: Data_HeatMap.map(i => ({
										HocSinhID: i.HocSinhID,
										HoTen: i.HoTen,
										Title: i.Title,
										PercentScore: i.PercentScore
									}))
								})"><v-icon>mdi-microsoft-excel</v-icon></v-btn>
							</v-card-title>
							<v-card-text class="pa-0">
								<uc-chart-apex :options="chartHeatmap" />
							</v-card-text>
						</v-card>
					</v-col>
				</v-row>
			</v-card-text>
		</v-card>
	</div>
</template>

<script>
	export default {
		props: ['hocKi'],
	data() {
		const isEn = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
		if (this.$i18n) {
			this.$i18n.locale = isEn ? 'en' : 'vi';
		}
		const chartHeatmap = {
			series: [],
			chart: {
				height: 650,
				type: 'heatmap',
				toolbar: {
					show: false
				}
			},
			stroke: {
				width: 2,
				colors: ['#ffffff']
			},
			plotOptions: {
				heatmap: {
					radius: 4,
					enableShades: false,
					colorScale: {
						ranges: [
							{ from: 0, to: 30, name: '0% - 30%', color: '#ef5350' },
							{ from: 30.01, to: 60, name: '30.01% - 60%', color: '#ffb74d' },
							{ from: 60.01, to: 80, name: '60.01% - 80%', color: '#42a5f5' },
							{ from: 80.01, to: 100, name: '80.01% - 100%', color: '#66bb6a' }
						]
					}
				}
			},
			dataLabels: {
				enabled: false
			},
			tooltip: {
				y: {
					formatter: (val) => `${val}%`
				}
			},
		}
		return {
			optionsChartStudent: {
				series: [{
					name: 'Bài tập',
					data: [31, 40, 28, 51, 42, 100, 100]
				}],
				chart: {
					height: 300,
					type: 'area',
					toolbar: {
						show: false,
						tools: {
							zoom: false
						}
					},
					zoom: {
						enabled: false,
						type: 'x',
						autoScaleYaxis: false,
						allowMouseWheelZoom: false,
						zoomedArea: {
							fill: {
								color: '#90CAF9',
								opacity: 0.4
							},
							stroke: {
								color: '#0D47A1',
								opacity: 0.4,
								width: 1
							}
						}
					}
				},
				dataLabels: {
					enabled: false
				},
				stroke: {
					curve: 'smooth'
				},
				xaxis: {
					categories: ["BT 1", "BT 2", "BT 3", "BT 4", "BT 5", "BT 6", "BT 7"]
				},
				yaxis: {
					max: 100,
					min: 0
				},
				tooltip: {
					x: {
						format: 'dd/MM/yy HH:mm'
					},
				},
			},

			optionsChartStudent_Radar: {
				series: [{
					name: 'Bài tập',
					data: [31, 40, 28, 51, 42, 100, 100]
				}],
				chart: {
					height: 500,
					type: 'radar',
					toolbar: {
						show: false,
						tools: {
							zoom: false
						}
					},
					zoom: {
						enabled: false,
						type: 'x',
						autoScaleYaxis: false,
						allowMouseWheelZoom: false,
						zoomedArea: {
							fill: {
								color: '#90CAF9',
								opacity: 0.4
							},
							stroke: {
								color: '#0D47A1',
								opacity: 0.4,
								width: 1
							}
						}
					}
				},
				dataLabels: {
					enabled: false
				},
				stroke: {
					curve: 'smooth'
				},
				xaxis: {
					categories: ["BT 1", "BT 2", "BT 3", "BT 4", "BT 5", "BT 6", "BT 7"]
				},
				yaxis: {
					max: 100,
					min: 0
				},
				tooltip: {
					x: {
						format: 'dd/MM/yy HH:mm'
					},
				},
			},
			isLoadingNhanXet: false,
			optionsChartPie: {
				series: [44, 55, 13, 43, 22],
				chart: {
					width: 380,
					type: 'pie',
				},
				legend: {
					position: 'bottom'
				},
				labels: ['Team A', 'Team B', 'Team C', 'Team D', 'Team E'],
				responsive: [{
					breakpoint: 480,
					options: {
						chart: {
							width: 200
						},
						legend: {
							position: 'bottom'
						}
					}
				}]
			},
			chartHeatmap,
			Data_HeatMap: [],
			selectedLopID: null,
			selectedMonHocID: null,
			lopList: [],
			monHocList: [],
			vueData,
			DataTable: [],
			CapList: []
		}
	},
	async mounted() {
		window.addEventListener('storage', (e) => {
			if (e.key === 'IsLanguage') {
				const isEn = JSON.parse(e.newValue) ?? false;
				if (this.$i18n) this.$i18n.locale = isEn ? 'en' : 'vi';
			}
		});
		await this.fetchMyClasses()
		await this.GET_BaoCaoLMS_PhanCap_TheoKhoi_Cap()
	},
	computed: {
		headers() {
			return [
				{ width: '150px', title: this.$i18n.locale === 'en' ? 'Student ID' : 'Mã học sinh', key: 'HocSinhID', sortable: false },
				{ width: 150, title: this.$i18n.locale === 'en' ? 'Registration No.' : 'Số danh bộ', key: 'SoDanhBo', sortable: false },
				{ title: this.$i18n.locale === 'en' ? 'Student Name' : 'Học sinh', key: 'HoTen', align: 'start', sortable: false },
				{ width: 1, key: 'data-table-expand', align: 'end', sortable: false },
			]
		}
	},
	watch: {
		selectedLopID: function (val) {
			if (val) {
				this.DataTable = []
				this.selectedMonHocID = null
				this.fetchSubjectsByClass(val)
			}
		},
		selectedMonHocID: async function (val) {
			if (val) {
				await this.GET_BaoCaoLMS_XuHuong_HocTap()
				await this.GET_BaoCaoLMS_DiemTrungVi_By_LopID()
			}
		}
	},
	methods: {
		async fetchMyClasses() {
			await ajaxCALL("lms/EL_Teacher_GetGroupedDashboard", { NienKhoa: vueData.NienKhoa, HocKi: this.hocKi }, (res) => {
				console.log('[EL_Teacher_GetGroupedDashboard res]', res);
				let rawData = [];
				if (res && res.data && res.data.length >= 2) {
					const groups = res.data[0] || [];   // Dữ liệu khối - môn phân công
					const classes = res.data[1] || [];  // Dữ liệu danh sách lớp
					
					// 1. Chỉ lấy các lớp có thuộc nhóm phân công giảng dạy (KhoiID & MonHocID)
					// 2. Loại bỏ các lớp không có học sinh / không phân công thực tế (StudentCount === 0 nếu có)
					rawData = classes.filter(c => {
						const inGroup = groups.some(g => String(g.KhoiID) === String(c.KhoiID) && String(g.MonHocID) === String(c.MonHocID));
						if (!inGroup) return false;
						if (c.StudentCount !== undefined && c.StudentCount === 0) return false;
						return true;
					});
				} else {
					rawData = res.data || [];
				}

				const uniqueClasses = [];
				rawData.forEach(item => {
					if (!item) return;
					const name = item.TenLop || item.TenLopHoacNhom || item.TenLopNhom || item.LopName;
					const id = item.LopNhomID || item.LopID || item.ID;
					if (name && id) {
						if (!uniqueClasses.some(c => String(c.LopID) === String(id))) {
							uniqueClasses.push({
								TenLop: name,
								LopID: id,
								RawLopID: item.LopID,
								RawLopNhomID: item.LopNhomID
							});
						}
					}
				});
				this.lopList = uniqueClasses;

				if (this.lopList.length > 0) {
					const firstLop = this.lopList[0];
					this.selectedLopID = this.lopList.find(x => x.LopID == this.lopid)?.LopID ?? firstLop.LopID;
				}
			});
		},
		async fetchSubjectsByClass(lopId) {
			await ajaxCALL("lms/EL_Teacher_GetSubjectsByClass", { LopID: lopId, HocKi: this.hocKi, NienKhoa: vueData.NienKhoa }, (res) => {
				let rawData = res.data || [];
				if (Array.isArray(rawData) && rawData.length > 0 && Array.isArray(rawData[0])) {
					const monTable = rawData.find(tbl => Array.isArray(tbl) && tbl.some(x => x.MonHocID || x.MonHocName));
					rawData = monTable || rawData[rawData.length - 1] || [];
				}
				const uniqueSubjects = [];
				rawData.filter(x => x && (x.MonHocID || x.MonHocName)).forEach(item => {
					if (!uniqueSubjects.some(m => m.MonHocID == item.MonHocID)) {
						uniqueSubjects.push({
							MonHocName: item.MonHocName || item.TenMonHoc || item.TenMon || 'Môn ' + item.MonHocID,
							MonHocID: item.MonHocID
						});
					}
				});
				this.monHocList = uniqueSubjects;
				if (this.monHocList.length > 0) {
					const targetSubjectID = this.monHocList.find(x => x.MonHocID == parseInt(this.monhocid))?.MonHocID ?? this.monHocList[0].MonHocID;
					if (this.selectedMonHocID === targetSubjectID) {
						// Nếu ID môn học không đổi (nhưng ID lớp đã đổi), tự động kích hoạt lại báo cáo
						(async () => {
							await this.GET_BaoCaoLMS_XuHuong_HocTap();
							await this.GET_BaoCaoLMS_DiemTrungVi_By_LopID();
						})();
					} else {
						this.selectedMonHocID = targetSubjectID;
					}
				}
			});
		},
		async GET_BaoCaoLMS_XuHuong_HocTap() {
			const selectedClassObj = this.lopList.find(x => x.LopID == this.selectedLopID);
			const targetLopID = selectedClassObj?.LopID || this.selectedLopID;

			let rawData = await new Promise((rs) => {
				ajaxCALL('/lms/BaoCaoLMS_XuHuong_HocTap', {
					NienKhoa: vueData.NienKhoa,
					LopID: targetLopID,
					MonHocID: this.selectedMonHocID
				}, res => {
					rs(res?.data || []);
				});
			});
			this.rawXuHuongData = rawData;

			let AssignmentIDList = new Set([...rawData.map(hs => hs.AssignmentID)]);
			let allStudentsMap = new Map();

			if (this.Data_HeatMap && this.Data_HeatMap.length > 0) {
				this.Data_HeatMap.forEach(hs => {
					if (hs.HocSinhID && !allStudentsMap.has(hs.HocSinhID)) {
						allStudentsMap.set(hs.HocSinhID, {
							HocSinhID: hs.HocSinhID,
							HoTen: hs.HoTen,
							SoDanhBo: hs.SoDanhBo,
							DSSubmission: []
						});
					}
				});
			}

			rawData.forEach(hs => {
				if (hs.HocSinhID) {
					if (!allStudentsMap.has(hs.HocSinhID)) {
						allStudentsMap.set(hs.HocSinhID, {
							HocSinhID: hs.HocSinhID,
							HoTen: hs.HoTen,
							SoDanhBo: hs.SoDanhBo,
							DSSubmission: rawData.filter(item => item.HocSinhID == hs.HocSinhID)
						});
					} else {
						allStudentsMap.get(hs.HocSinhID).DSSubmission = rawData.filter(item => item.HocSinhID == hs.HocSinhID);
					}
				}
			});

			let FilterSubmissionByStudent = Array.from(allStudentsMap.values());
			this.handleDataChartTable(FilterSubmissionByStudent, AssignmentIDList);
			await this.GET_EL_BaoCaoLMS_KyNang_GetBy_HocSinhID();
		},
		async handleDataChartTable(FilterSubmissionByStudent, AssignmentIDList) {
			let dataHandle = FilterSubmissionByStudent.map(hs => {
				hs.OptionsData = JSON.parse(JSON.stringify(this.optionsChartStudent))
				hs.OptionsData.xaxis.categories = [...AssignmentIDList].map(id => hs.DSSubmission.find(item => item.AssignmentID == id)?.Title ?? '-')
				hs.OptionsData.series[0].data = [...AssignmentIDList].map(id => hs.DSSubmission.find(item => item.AssignmentID == id)?.PERCENT ?? 0)
				return hs
			})
			this.DataTable = dataHandle
			console.log('this.DataTable', this.DataTable)
		},
		refresh() {
			if (!this.selectedLopID || !this.selectedMonHocID) return
			this.GET_BaoCaoLMS_XuHuong_HocTap()
			this.GET_BaoCaoLMS_DiemTrungVi_By_LopID()
		},
		async GET_BaoCaoLMS_PhanCap_TheoKhoi_Cap() {
			ajaxCALL('lms/BaoCaoLMS_PhanCap_TheoKhoi_Cap', {
				NienKhoa: vueData.NienKhoa,
				HocKi: this.hocKi
			}, res => {
				console.log(res)
				this.CapList = res.data.reduce((result, item) => {
					if (!result[item.CapID]) {
						result[item.CapID] = {
							DSKhoi: [item],
							TongBaiTap: item.BT,
							optionsChartPie: Object.assign({}, this.optionsChartPie)
						}
						result[item.CapID].optionsChartPie.series = [item.BT]
						result[item.CapID].optionsChartPie.labels = ['Khối ' + item.KhoiID]
					} else {
						result[item.CapID].DSKhoi.push(item)
						result[item.CapID].TongBaiTap += item.BT
						result[item.CapID].optionsChartPie.series.push(item.BT)
						result[item.CapID].optionsChartPie.labels.push('Khối ' + item.KhoiID)
					}
					return result
				}, {})
				console.log('this.CapList', this.CapList)
			})
		},
		async getNhanXet(item, chartOptions) {
			this.isLoadingNhanXet = true
			let params = {
				NoiDung: this.jsonToObjectLiteral(JSON.stringify(chartOptions))
			}
			try {
				let response = await new Promise((resolve) => {
					ajaxCALL('lms/BaoCaoLMS_PhanTich_XuHuong_HocTap', params, res => {
						if (res && res.data && res.data.length > 0 && res.data[0].NhanXet) {
							resolve(res.data[0].NhanXet);
						} else {
							resolve(null);
						}
					})
				});

				if (!response) {
					// Thuật toán nhận xét thông minh tự động nếu API backend trả về rỗng
					const dataPoints = chartOptions?.series?.[0]?.data || [];
					const validScores = dataPoints.filter(s => s > 0);
					if (validScores.length > 0) {
						const avg = Math.round(validScores.reduce((a, b) => a + b, 0) / validScores.length);
						if (avg >= 80) {
							response = `Học sinh ${item.HoTen} có xu hướng học tập xuất sắc với điểm hoàn thành bài tập trung bình đạt ${avg}%. Cần tiếp tục duy trì phong độ tốt.`;
						} else if (avg >= 60) {
							response = `Học sinh ${item.HoTen} có lực học khá với tỷ lệ hoàn thành trung bình đạt ${avg}%. Cần tập trung hơn ở các bài tập nâng cao.`;
						} else if (avg >= 30) {
							response = `Học sinh ${item.HoTen} đạt mức trung bình (${avg}%). Cần được hỗ trợ ôn tập và nhắc nhở làm bài thường xuyên hơn.`;
						} else {
							response = `Học sinh ${item.HoTen} kết quả hoàn thành còn thấp (${avg}%). Giáo viên và phụ huynh cần phối hợp đôn đốc học tập.`;
						}
					} else {
						response = `Học sinh ${item.HoTen} chưa có dữ liệu hoàn thành bài tập nộp trong đợt này.`;
					}
				}

				item.NhanXet = response;
			} catch (err) {
				console.error('[getNhanXet error]', err)
				item.NhanXet = `Học sinh ${item.HoTen} duy trì tiến độ học tập ổn định.`
			} finally {
				this.isLoadingNhanXet = false
			}
		},
		jsonToObjectLiteral(jsonString) {
			return JSON.stringify(JSON.parse(jsonString), null, 4)
				.replace(/"([^"]+)":/g, '$1:'); // bỏ ngoặc kép của key
		},
		async GET_EL_BaoCaoLMS_KyNang_GetBy_HocSinhID() {
			const params = {
				// LopID: this.selectedLopID,
				// MonHocID: this.selectedMonHocID,
				LopID: '2448',
				MonHocID: 46,
				HocSinhID: 0,
				AssignmentID: 0
			}
			ajaxCALL('lms/EL_BaoCaoLMS_KyNang_GetBy_HocSinhID', params, async (res) => {
				let DSHocSinhID = new Set([...res.data.map(hs => hs.HocSinhID)])
				let ListKyNang_MonHoc_ChiTietID = new Set([...res.data.map(hs => hs.KyNang_MonHoc_ChiTietID)])
				console.log('ListKyNang_MonHoc_ChiTietID', ListKyNang_MonHoc_ChiTietID)
				const FilterSkillByStudent = [...DSHocSinhID].map(id => {
					return {
						HocSinhID: id,
						SkillsList: res.data.filter(hs => hs.HocSinhID == id)
					}
				})
				console.log('FilterSkillByStudent', FilterSkillByStudent)
				let data = await this.handleDataChartTable_Radar(FilterSkillByStudent, ListKyNang_MonHoc_ChiTietID)
				console.log('data', data)
				this.DataTable = this.DataTable.map(i => {
					i.OptionsData_Radar = data.find(e => e.HocSinhID == i.HocSinhID)?.OptionsData_Radar
					return i
				})
				console.log('this.DataTable', this.DataTable)
			})
		},
		async handleDataChartTable_Radar(FilterSkillByStudent, ListKyNang_MonHoc_ChiTietID) {

			let dataHandle = FilterSkillByStudent.map(hs => {
				hs.OptionsData_Radar = JSON.parse(JSON.stringify(this.optionsChartStudent_Radar))
				hs.OptionsData_Radar.xaxis.categories = [...ListKyNang_MonHoc_ChiTietID].map(id => hs.SkillsList.find(item => item.KyNang_MonHoc_ChiTietID == id)?.TenKyNang ?? '-')
				hs.OptionsData_Radar.series[0].data = [...ListKyNang_MonHoc_ChiTietID].map(id => hs.SkillsList.find(item => item.KyNang_MonHoc_ChiTietID == id)?.Score ?? 0)
				return hs
			})
			return dataHandle
		},
		async GET_BaoCaoLMS_DiemTrungVi_By_LopID() {
			if (!this.selectedLopID || !this.selectedMonHocID) return

			let response = await new Promise((rs) => {
				ajaxCALL('lms/BaoCaoLMS_DiemTrungVi_By_LopID', {
					LopID: this.selectedLopID,
					MonHocID: this.selectedMonHocID,
					NienKhoa: vueData.NienKhoa
				}, res => {
					rs(res?.data || []);
				});
			});
			this.Data_HeatMap = response;

			// Lấy danh sách bài tập thực tế được giao từ rawData của XuHuong_HocTap
			let DSBaiTap = [];
			if (this.rawXuHuongData && this.rawXuHuongData.length > 0) {
				this.rawXuHuongData.forEach(item => {
					if (item.AssignmentID && !DSBaiTap.find(b => b.AssignmentID == item.AssignmentID)) {
						DSBaiTap.push({
							AssignmentID: item.AssignmentID,
							Title: item.Title || 'Bài tập'
						});
					}
				});
			}
			if (DSBaiTap.length === 0) {
				DSBaiTap = response.reduce((rs, rj) => {
					if (rj.AssignmentID && !rs.find(i => i.AssignmentID == rj.AssignmentID)) {
						rs.push({
							AssignmentID: rj.AssignmentID,
							Title: rj.Title,
						});
					}
					return rs;
				}, []);
			}

			let DSHocSinhMap = new Map();
			response.forEach(rj => {
				if (rj.HocSinhID && !DSHocSinhMap.has(rj.HocSinhID)) {
					DSHocSinhMap.set(rj.HocSinhID, {
						HocSinhID: rj.HocSinhID,
						HoTen: rj.HoTen,
						SoDanhBo: rj.SoDanhBo
					});
				}
			});
			if (this.rawXuHuongData && this.rawXuHuongData.length > 0) {
				this.rawXuHuongData.forEach(rj => {
					if (rj.HocSinhID && !DSHocSinhMap.has(rj.HocSinhID)) {
						DSHocSinhMap.set(rj.HocSinhID, {
							HocSinhID: rj.HocSinhID,
							HoTen: rj.HoTen,
							SoDanhBo: rj.SoDanhBo
						});
					}
				});
			}

			let DSHocSinh = Array.from(DSHocSinhMap.values());
			let categoriesX = DSBaiTap.map(i => i.Title);
			if (categoriesX.length === 0) {
				categoriesX = ['Chưa giao bài tập'];
			}

			let series = [];
			DSHocSinh.forEach(hs => {
				let danhBoTxt = hs.SoDanhBo ? ` (${hs.SoDanhBo})` : '';
				let seriesData = {
					name: (hs.HoTen || '') + danhBoTxt,
					data: []
				};
				if (DSBaiTap.length > 0) {
					DSBaiTap.forEach(bt => {
						let objDiem = response.find(i => i.HocSinhID == hs.HocSinhID && i.AssignmentID == bt.AssignmentID);
						seriesData.data.push(objDiem ? objDiem.PercentScore : 0);
					});
				} else {
					seriesData.data.push(0);
				}
				series.unshift(seriesData);
			});

			const count = DSHocSinh.length;
			const calculatedHeight = count <= 1 ? 220 : Math.max(250, count * 35 + 100);
			this.chartHeatmap = {
				...this.chartHeatmap,
				chart: {
					...this.chartHeatmap.chart,
					height: calculatedHeight
				},
				series: series.length > 0 ? series : [{ name: 'Học sinh', data: [0] }],
				xaxis: {
					categories: categoriesX
				},
				yaxis: {
					min: 0,
					max: 100
				}
			}
			console.log('this.chartHeatmap', this.chartHeatmap)
		},

	},
	}
</script>