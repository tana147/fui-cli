<template>
	<div style="background-color: #bdb7b712;">
		<div class="d-flex align-center pa-2">
			<span style="font-size: 17px; " class="font-weight-medium">{{ IsLanguage ? 'Notifications' : 'Trang thông báo' }}</span>
			<v-spacer />
		</div>
		<div class="d-flex ">
			<v-spacer />
			<v-chip-group v-model="Type" selected-class="text-primary" mandatory>
				<v-chip v-for="tag in tags" :key="tag.value">
					{{ tag.title }}
				</v-chip>
			</v-chip-group>
		</div>
		<div style="background-color: #f0f8ff00;height: calc(100vh - 298px); overflow: auto; padding-bottom: 42px;">
			<v-list lines="two" class="d-flex flex-column ga-2 mx-2 pt-0">
				<v-list-item class="rounded " v-for="tb in DSThongBao" :key="tb.ThongBaoID"
					@click="handleClickThongBao(tb)"
					:style="{ 'background-color': tb.Is_DaXem ? '#ffffff' : '#57d1573b !important' }">
					<template #prepend>
						<v-icon :color="tb.Color">{{ tb.Icon }}</v-icon>
					</template>
					<template #title>
						<span class="font-weight-medium">{{ getTypeTitle(tb.TypeTitle) }}</span>
					</template>
					<template #subtitle>
						<div class="d-flex flex-column ga-1">
							<span class="clamp-2">{{ formatContent(tb.TemplateContent) }}</span>
							<span>
								{{ IsLanguage ? 'Time:' : 'Thời gian:' }} {{ tb.ThoiGianNhan ? dayjs(tb.ThoiGianNhan).format('DD/MM/YYYY') : '-' }}
							</span>
						</div>
					</template>
				</v-list-item>
				<uc-empty v-if="DSThongBao.length === 0" />
			</v-list>
		</div>
	</div>
</template>

<script>
	export default {
		data() {
			return {
				vueData,
				Type: 0,
				DSThongBao: [],
				IsShowDialogCalen: false,
				IsLanguage: localStorage.getItem('IsLanguage') ? JSON.parse(localStorage.getItem('IsLanguage')) : false
			}
		},
		mounted() {
			this.GET_EL_PhuHuynh_ThongBao_Get()
		},
		computed: {
			tags() {
				if (this.IsLanguage) {
					return [
						{ title: "Daily", value: 0 },
						{ title: "Weekly", value: 1 },
						{ title: "Monthly", value: 2 },
						{ title: "All", value: 3 }
					]
				}
				return [
					{ title: "Theo ngày", value: 0 },
					{ title: "Theo tuần", value: 1 },
					{ title: "Theo tháng", value: 2 },
					{ title: "Tất cả", value: 3 }
				]
			}
		},
		watch: {
			Type: function () {
				this.GET_EL_PhuHuynh_ThongBao_Get()
			},
			'$i18n.locale': function (locale) {
				this.IsLanguage = locale === 'en'
			}
		},
		methods: {
			getTypeTitle(typeTitle) {
				if (!typeTitle) return '';
				if (this.IsLanguage) {
					if (typeTitle === 'Giáo viên giao bài') return 'Teacher assigned homework';
					if (typeTitle === 'Học sinh nộp bài') return 'Student submitted assignment';
					if (typeTitle === 'Giáo viên chấm bài') return 'Teacher graded assignment';
				}
				return typeTitle;
			},
			formatContent(content) {
				if (!content) return '';
				if (this.IsLanguage) {
					let str = content;
					str = str.replace(/vừa giao bài/g, 'assigned homework');
					str = str.replace(/đã nộp bài/g, 'submitted homework');
					str = str.replace(/cho môn/g, 'for subject');
					str = str.replace(/môn /g, 'subject ');
					str = str.replace(/Hạn nộp:/g, 'Due date:');
					return str;
				}
				return content;
			},
			GET_EL_PhuHuynh_ThongBao_Get() {
				ajaxCALL('/lms/EL_PhuHuynh_ThongBao_Get_ByHocSinhID', {
					HocSinhID: vueData.HocSinhSelected.HocSinhID,
					NienKhoa: vueData.NienKhoa,
					Type: this.Type
					// HocSinhID: 17100132
				}, res => {
					this.DSThongBao = res.data
				})
			},
			handleClickThongBao(tb) {
				this.updateStatus(tb).then(() => {
					tb.Is_DaXem = 1
					CALL("getCountThongBao")
					if (tb.ThongBao_TypeID !== 3) return  //Chấm
				})
			},
			async updateStatus(tb) {
				if (!tb.Is_DaXem) {
					return await ajaxCALLPromise('/lms/EL_PhuHuynh_ThongBao_Udp_Xem_ByThongBaoID', {
						ThongBaoID: tb.ThongBaoID
					})
				}
			},
			dayjs
		}
	}
</script>