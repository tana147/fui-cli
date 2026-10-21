<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" max-width="1380px" persistent>
		<v-card>
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<p class="title mb-0 primary--text">Chi tiết đổi/điều chỉnh đề tài</p>
					<v-chip v-if="detailData && detailData.SoLanDoiDieuChinh != null" class="ml-2" color="info" dark>
						{{ detailData.SoLanDoiDieuChinh }} lần đổi/điều chỉnh
					</v-chip>
				</template>
			</c-toolbar>

			<v-card-text>
				<div class="mt-3">
					<v-card>
						<v-card-title class="primary--text">
							<v-spacer />
							<v-text-field v-model="search" class="c-underline-search max-w-360"
								prepend-inner-icon="mdi-magnify" label="Tìm kiếm..." single-line hide-details />
						</v-card-title>

						<v-simple-table fixed-header height="550px">
							<thead>
								<tr>
									<th class="table-col-w-150">Họ tên</th>
									<th class="table-col-w-150">Niên khóa</th>
									<th>Ngành</th>
									<th class="gvhd-wrap">Đề tài đã đổi</th>
									<th class="gvhd-wrap">GVHD 1</th>
									<th class="gvhd-wrap">GVHD 2</th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="(item, index) in filteredMergedItems" :key="index">
									<!-- Họ và tên học viên -->
									<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
										<span class="green--text">
											<b>{{ item.HoSV }} {{ item.TenSV }}</b>
										</span>
										<br />
										<b>{{ item.StudentID }}</b>
										<span class="amber--text"> [{{ item.LopID }}]</span>
									</td>

									<!-- Niên khóa -->
									<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
										{{ item.NienKhoa }}
									</td>

									<!-- Ngành -->
									<td v-if="item.rowspan > 0" :rowspan="item.rowspan">
										{{ item.TenNganh }}
									</td>

									<!-- Tên đề tài -->
									<td>
										{{ item.TenDeTai }}
									</td>

									<!-- Giảng viên 1 -->
									<td>
										{{ item.GVHD1 }}
									</td>

									<!-- Giảng viên 2 -->
									<td>
										{{ item.GVHD2 }}
									</td>
								</tr>
							</tbody>
						</v-simple-table>
					</v-card>
				</div>
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
					Process_ID: this.detailData.Process_ID,
				});
				if (data) {
					this.dsChiTietDoiDieuChinh = data.map((item, index) => ({
						...item,
						STT: index + 1,
					}));
				}
			},
			closeDialog() {
				this.dialog = false;
				this.$emit("on-close");
			},
		},
	}
</script>