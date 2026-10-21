<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" max-width="1380px" persistent>
		<v-card class="rounded-xs">
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<p class="title mb-0 primary--text">Chi tiết đổi/điều chỉnh đề tài</p>
					<v-chip v-if="detailData && detailData.SoLanDoiDieuChinh != null" class="ml-2" color="info" dark small>
						{{ detailData.SoLanDoiDieuChinh }} lần đổi/điều chỉnh
					</v-chip>
				</template>
			</c-toolbar>

			<v-card-text class="pa-4">
				<v-card outlined class="rounded-xs">
					<v-card-title class="pa-2 px-3 d-flex align-center">
						<span class="subtitle-1 font-weight-bold primary--text">Danh sách lịch sử thay đổi</span>
						<v-spacer />
						<v-btn icon color="success" class="mr-2" @click="exportExcel" title="Xuất file Excel">
							<v-icon>mdi-microsoft-excel</v-icon>
						</v-btn>
						<v-text-field v-model="search" class="c-underline-search"
							prepend-inner-icon="mdi-magnify" label="Tìm kiếm nhanh..." single-line hide-details dense clearable />
					</v-card-title>

					<v-simple-table fixed-header height="500px">
						<thead>
							<tr>
								<th class="table-col-w-150">Họ tên NCS</th>
								<th class="table-col-w-150">Niên khóa</th>
								<th>Ngành</th>
								<th>Đề tài đã đổi</th>
								<th>GVHD 1</th>
								<th>GVHD 2</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="(item, index) in filteredMergedItems" :key="index">
								<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
									<span class="primary--text font-weight-bold">
										{{ item.HoSV }} {{ item.TenSV }}
									</span>
									<br />
									<b>{{ item.StudentID }}</b>
									<span v-if="item.LopID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.LopID }}]</span>
								</td>

								<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
									{{ item.NienKhoa }}
								</td>

								<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
									{{ item.TenNganh }}
								</td>

								<td>
									{{ item.TenDeTai }}
								</td>

								<td>
									{{ item.GVHD1 }}
								</td>

								<td>
									{{ item.GVHD2 }}
								</td>
							</tr>
							<tr v-if="filteredMergedItems.length === 0">
								<td colspan="6" class="text-center py-4 grey--text">
									Chưa có dữ liệu lịch sử đổi đề tài
								</td>
							</tr>
						</tbody>
					</v-simple-table>
				</v-card>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-detail-doi-dieu-chinh",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			detailData: {
				type: Object,
				default: () => ({}),
			},
		},
		emits: ["input", "on-close"],
		data() {
			return {
				dsChiTietDoiDieuChinh: [],
				search: "",
			};
		},
		computed: {
			dialog: {
				get() {
					return this.value;
				},
				set(val) {
					this.$emit("input", val);
				},
			},
			mergedItems() {
				if (!this.dsChiTietDoiDieuChinh || this.dsChiTietDoiDieuChinh.length === 0) return [];

				const countByStudent = {};
				this.dsChiTietDoiDieuChinh.forEach((item) => {
					const key = item.StudentID || item.Student_ID || "default";
					countByStudent[key] = (countByStudent[key] || 0) + 1;
				});

				const seenStudent = {};
				return this.dsChiTietDoiDieuChinh.map((item, index) => {
					const key = item.StudentID || item.Student_ID || "default";
					const isFirst = !seenStudent[key];
					seenStudent[key] = true;
					return {
						...item,
						rowspan: isFirst ? countByStudent[key] : 0,
						STT: index + 1,
					};
				});
			},
			filteredMergedItems() {
				if (!this.search || !this.search.trim()) {
					return this.mergedItems;
				}
				const s = this.search.trim().toLowerCase();
				const matched = this.dsChiTietDoiDieuChinh.filter((item) =>
					`${item.HoSV || ""} ${item.TenSV || ""} ${item.StudentID || ""} ${item.LopID || ""} ${item.TenDeTai || ""} ${item.TenNganh || ""} ${item.GVHD1 || ""} ${item.GVHD2 || ""}`
						.toLowerCase()
						.includes(s)
				);
				return matched.map((item, index) => ({
					...item,
					rowspan: 1,
					STT: index + 1,
				}));
			},
		},
		watch: {
			value(val) {
				if (val) {
					this.onLoadChiTiet();
				} else {
					this.dsChiTietDoiDieuChinh = [];
					this.search = "";
				}
			},
		},
		methods: {
			async onLoadChiTiet() {
				if (!this.detailData || (!this.detailData.Student_ID && !this.detailData.StudentID)) return;
				const studentId = this.detailData.Student_ID || this.detailData.StudentID;
				const data = await ajaxCALLPromise("/Student_Doi_DieuChinhChiTiet", {
					Student_ID: studentId,
					Process_ID: this.detailData.Process_ID || 7,
				});
				if (data) {
					this.dsChiTietDoiDieuChinh = data.map((item, index) => ({
						...item,
						STT: index + 1,
					}));
				}
			},
			exportExcel() {
				if (!this.dsChiTietDoiDieuChinh || this.dsChiTietDoiDieuChinh.length === 0) {
					Vue.$toast.warning("Không có dữ liệu để xuất Excel", { position: "top" });
					return;
				}
				const exportData = this.dsChiTietDoiDieuChinh.map((item, index) => ({
					STT: index + 1,
					MSHV: item.StudentID,
					HoTen: `${item.HoSV || ""} ${item.TenSV || ""}`.trim(),
					Lop: item.LopID,
					NiênKhoá: item.NienKhoa,
					Ngành: item.TenNganh,
					ĐềTàiĐổi: item.TenDeTai,
					GVHD1: item.GVHD1,
					GVHD2: item.GVHD2,
				}));
				jsonToExcel({
					data: exportData,
					filename: `ChiTietDoiDeTai_${this.detailData.Student_ID || "NCS"}.xlsx`,
					worksheet: "ChiTiet",
				});
			},
			closeDialog() {
				this.dialog = false;
				this.$emit("on-close");
			},
		},
	}
</script>