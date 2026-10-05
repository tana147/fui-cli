<template>
	<v-expansion-panels v-model="panel" accordion class="student-info-panels mb-2">
		<v-expansion-panel>
			<v-expansion-panel-header class="student-info-collapse-header pa-2 min-h-40" disable-icon-rotate>
				<div class="d-flex align-center w-100 pr-4">
					<v-icon color="#17445e" class="mr-2" size="18">mdi-account-circle-outline</v-icon>
					<div>
						<h3 class="student-info-card__title text-subtitle-2 font-weight-bold line-height-1-2">
							Thông tin Nghiên cứu sinh (NCS)</h3>
						<div v-if="studentDisplayName" class="text-caption text-grey text--darken-2 mt-0">
							<span class="font-weight-bold primary--text">{{ studentDisplayName }}</span>
							<span v-if="studentDisplayId" class="ml-1 grey--text">({{ studentDisplayId }})</span>
						</div>
					</div>
				</div>
				<template v-slot:actions>
					<v-icon color="#1d5b7a" size="20">{{ panel === 0 ? 'mdi-chevron-up-circle' :
						'mdi-chevron-down-circle' }}
					</v-icon>
				</template>
			</v-expansion-panel-header>

			<v-expansion-panel-content>
				<v-card class="student-info-card rounded-xs" outlined>
					<v-row dense class="px-2 pb-1 pt-0">
						<v-col v-for="field in detailInfoSchema" :key="field.key" cols="12" sm="6" md="4">
							<div
								class="text-caption font-weight-bold text-uppercase grey--text text--darken-1 mb-1 d-block letter-spacing-0-4">
								{{ field.label }}</div>

							<div v-if="field.type === 'yesNo'" class="d-flex align-center mt-1 min-h-40">
								<v-chip small label :class="getYesNoChipClass(detailInfo[field.key])">
									{{ getDetailInfoValue(field) }}
								</v-chip>
							</div>

							<div v-else
								class="text-body-2 font-weight-bold mt-1 pa-2 border rounded-xs bg-white d-flex align-center w-100 student-info-text">
								{{ getDetailInfoValue(field) }}
							</div>
						</v-col>
					</v-row>
				</v-card>
			</v-expansion-panel-content>
		</v-expansion-panel>
	</v-expansion-panels>
</template>

<script>
	export default {
		name: "uc-student-info",
		props: {
			detailInfo: {
				type: Object,
				default: () => ({})
			}
		},
		data() {
			return {
				panel: null,
				detailInfoSchema: [
					{ key: 'Email', label: 'Email' },
					{ key: 'SoDienThoai', label: 'Số điện thoại' },
					{ key: 'NoiSinh', label: 'Nơi sinh' },
					{ key: 'DanToc', label: 'Dân tộc' },
					{ key: 'CCCD', label: 'CCCD' },
					{ key: 'NgayCap_CCCD', label: 'Ngày cấp CCCD', type: 'date' },
					{ key: 'Truong_DaiHoc', label: 'Trường đại học' },
					{ key: 'Nganh_DaiHoc', label: 'Ngành đại học' },
					{ key: 'Truong_ThacSi', label: 'Trường đào tạo Thạc sĩ' },
					{ key: 'Nganh_ThacSi', label: 'Ngành học Thạc sĩ' },
					{ key: 'Diem_ThacSi', label: 'Điểm tốt nghiệp Thạc sĩ' },
					{ key: 'DeTai_ThacSi', label: 'Tên đề tài luận văn Thạc sĩ' },
					{ key: 'NgoaiNgu_DauVao', label: 'Ngoại ngữ đầu vào' },
					{ key: 'BoSungKienThuc', label: 'Bổ sung kiến thức', type: 'yesNo' },
					{ key: 'CongBoKhoaHoc', label: 'Có công bố khoa học', type: 'yesNo' },
					{ key: 'SoBaiBaoDaCongBo', label: 'Số lượng bài báo đã công bố' }
				]
			}
		},
		computed: {
			studentDisplayName() {
				if (!this.detailInfo) return '';
				return (this.detailInfo.HoTen || '').trim();
			},
			studentDisplayId() {
				if (!this.detailInfo) return '';
				return String(this.detailInfo.Student_ID || '').trim();
			}
		},
		methods: {
			getDetailInfoValue(field) {
				const rawValue = this.detailInfo ? this.detailInfo[field.key] : null;

				if (field.type === 'date') {
					return this.formatDisplayDate(rawValue);
				}

				if (field.type === 'yesNo') {
					return this.formatYesNoValue(rawValue);
				}

				if (rawValue === null || rawValue === undefined || rawValue === '') {
					return '-';
				}

				return rawValue;
			},

			formatDisplayDate(value) {
				if (!value) return '-';
				if (typeof moment !== 'undefined') {
					const m = moment(value);
					return m.isValid() ? m.format('DD/MM/YYYY') : value;
				}
				return value;
			},

			formatYesNoValue(value) {
				if (value === null || value === undefined || value === '') {
					return 'Chưa cập nhật';
				}
				const normalizedValue = String(value).trim().toLowerCase();
				if (normalizedValue === 'có' || normalizedValue === 'co' || normalizedValue === 'yes' || normalizedValue === 'true') return 'Có';
				if (normalizedValue === 'không' || normalizedValue === 'khong' || normalizedValue === 'no' || normalizedValue === 'false') return 'Không';
				return String(value);
			},

			getYesNoChipClass(value) {
				const normalizedValue = this.formatYesNoValue(value);
				if (normalizedValue === 'Có') return 'font-weight-bold rounded-pill success--text green lighten-5';
				if (normalizedValue === 'Không') return 'font-weight-bold rounded-pill error--text red lighten-5';
				return 'font-weight-bold rounded-pill grey--text grey lighten-4';
			}
		}
	}
</script>