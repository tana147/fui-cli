<template>
	<z-layout>
		<v-container fluid class="h-100" :class="isMobile ? 'pa-0' : 'pa-4'">
			<v-row class="h-100 ma-0">
				<v-card width="100%" height="100%" class="d-flex flex-column">
					<v-toolbar density="comfortable" color="white" class="border-b flex-grow-0">
						<v-toolbar-title class="text-primary font-weight-bold text-subtitle-1 pl-2">
							<v-icon icon="mdi-calendar-clock" start size="small"></v-icon>
							{{ isMobile ? 'Lịch bảo trì' : 'Quản lý lịch bảo trì tài sản' }}
						</v-toolbar-title>

						<v-spacer></v-spacer>

						<div v-if="!isMobile" class="d-flex align-center">
							<v-text-field v-model="filter.search" density="compact" variant="outlined"
								label="Tìm tên lịch..." hide-details single-line prepend-inner-icon="mdi-magnify"
								class="mr-3" style="width: 250px" bg-color="grey-lighten-5"></v-text-field>

							<v-btn class="mr-2" rounded size="small" color="primary" variant="tonal"
								prepend-icon="mdi-clipboard-list" @click="$refs.confirmList.open()">
								Duyệt lịch
							</v-btn>

							<v-btn class="mr-2" rounded size="small" color="primary" variant="tonal"
								prepend-icon="mdi-plus" @click="$refs.createSchedule.open()">
								Tạo lịch mới
							</v-btn>
						</div>

						<div v-else>
							<v-btn icon="mdi-magnify" @click="showMobileSearch = !showMobileSearch"></v-btn>

							<v-menu location="bottom end">
								<template v-slot:activator="{ props }">
									<v-btn v-bind="props" icon="mdi-dots-vertical" color="grey-darken-1"></v-btn>
								</template>
								<v-list density="compact">
									<v-list-item @click="$refs.createSchedule.open()">
										<template v-slot:prepend>
											<v-icon color="">mdi-plus</v-icon>
										</template>
										<v-list-item-title class="">Tạo lịch mới
										</v-list-item-title>
									</v-list-item>

									<v-divider class="my-1"></v-divider>

									<v-list-item @click="$refs.confirmList.open()">
										<template v-slot:prepend>
											<v-icon>mdi-clipboard-list</v-icon>
										</template>
										<v-list-item-title>Duyệt danh sách</v-list-item-title>
									</v-list-item>
								</v-list>
							</v-menu>
						</div>

						<v-btn size="small" icon="mdi-close" variant="text" @click="closeMainPage" />
					</v-toolbar>

					<v-toolbar density="compact" flat color="grey-lighten-4" class="border-b flex-grow-0"
						style="min-height: 48px;">
						<v-row no-gutters align="center" class="w-100 px-2">

							<v-col cols="12" v-if="isMobile && showMobileSearch" class="py-1">
								<v-text-field v-model="filter.search" density="compact" variant="solo"
									placeholder="Nhập tên lịch..." hide-details prepend-inner-icon="mdi-magnify"
									bg-color="white" autofocus></v-text-field>
							</v-col>

							<v-col :cols="isMobile ? 12 : 'auto'"
								class="d-flex align-center justify-center justify-md-start py-1" v-else>
								<v-btn-toggle v-model="filter.timeRange" density="compact" color="primary"
									variant="outlined" divided mandatory>
									<v-btn value="all" size="small">Tất cả</v-btn>
									<v-btn value="month" size="small">Tháng này</v-btn>
									<v-btn value="week" size="small">Tuần này</v-btn>
								</v-btn-toggle>

								<span v-if="!isMobile && filter.timeRange !== 'all'"
									class="ml-3 text-caption text-grey">
									{{ timeRangeLabel }}
								</span>
							</v-col>
						</v-row>
					</v-toolbar>

					<v-card-text class="pa-0 flex-grow-1" style="position: relative; overflow-y: auto;">

						<v-sheet v-if="!isMobile" height="100%">
							<v-calendar ref="calendar" type="month" :events="filteredEvents">
								<template v-slot:event="{ event }">
									<v-tooltip location="top" open-delay="200">
										<template v-slot:activator="{ props }">
											<v-card v-bind="props"
												class="ma-1 pa-1 text-white cursor-pointer rounded-lg elevation-1"
												:color="event.color" flat @click.stop="$refs.eventDetail.open(event)"
												style="font-size: 12px; line-height: 1.2;">
												<div class="d-flex align-center justify-space-between mb-1">
													<span class="font-weight-bold text-truncate mr-1">{{ event.title
													}}</span>
													<v-chip size="x-small" color="white" variant="outlined" class="px-1"
														style="height: 16px;">
														{{ event.TinhTrangTrachNhiem == 1 ? 'NV' : 'ĐT' }}
													</v-chip>
												</div>
												<div style="font-size: 10px; opacity: 0.9;">
													SL Tài sản: <b>{{ event.SoLuongTaiSan }}</b>
												</div>
											</v-card>
										</template>
										<span>{{ event.title }}</span>
									</v-tooltip>
								</template>
							</v-calendar>
						</v-sheet>

						<div v-else class="bg-grey-lighten-5 min-h-100 pb-4">
							<div
								class="px-3 py-2 bg-white mb-2 elevation-1 d-flex justify-space-between align-center sticky-header">
								<span class="text-caption text-grey font-weight-bold text-uppercase">
									{{ filter.timeRange === 'all' ? 'Tất cả sự kiện' : timeRangeLabel }}
								</span>
								<span class="text-caption text-primary">{{ filteredEvents.length }} sự kiện</span>
							</div>

							<div v-if="filteredEvents.length === 0" class="text-center mt-10 text-grey">
								<v-icon size="48" icon="mdi-calendar-search" class="mb-2"></v-icon>
								<div>Không tìm thấy lịch nào</div>
							</div>

							<v-container class="pa-2" v-else>
								<v-card v-for="(event, index) in sortedEvents" :key="index"
									class="mb-3 rounded-lg elevation-2" @click="$refs.eventDetail.open(event)"
									:style="{ borderLeft: '5px solid ' + event.color }">

									<div class="pa-3">
										<div class="d-flex justify-space-between align-start mb-2">
											<div class="font-weight-bold text-subtitle-1 text-primary line-clamp-2"
												style="line-height: 1.3;">
												{{ event.title }}
											</div>
											<v-chip size="x-small" :color="event.color" label variant="flat"
												class="ml-2 flex-shrink-0">
												{{ event.TrangThai === 1 ? 'Đã xong' : 'Chưa xong' }}
											</v-chip>
										</div>

										<div class="d-flex align-center text-caption text-grey-darken-2 mb-2">
											<v-icon size="x-small" start color="grey">mdi-calendar-range</v-icon>
											<span class="mr-3 font-weight-medium">{{ formatDate(event.start) }}</span>

											<v-icon size="x-small" start color="grey">mdi-account-wrench</v-icon>
											<span>{{ event.TinhTrangTrachNhiem == 1 ? 'Nhân viên' : 'Đối tác' }}</span>
										</div>

										<div class="d-flex justify-space-between align-center pt-2  mt-1">
											<span class="text-caption text-grey">Số lượng thiết bị: {{
												event.SoLuongTaiSan }}</span>
										</div>
									</div>
								</v-card>
							</v-container>
						</div>
					</v-card-text>
				</v-card>

				<uc-tao-lich ref="createSchedule" @refresh="getLichSuKien"></uc-tao-lich>
				<uc-chi-tiet-bao-tri ref="eventDetail" @refresh="getLichSuKien"></uc-chi-tiet-bao-tri>
				<uc-lich-bao-tri ref="confirmList" @refresh="getLichSuKien"></uc-lich-bao-tri>

			</v-row>
		</v-container>
	</z-layout>
</template>

<script>
export default {
	data() {
		return {
			rawEvents: [],
			showMobileSearch: false,
			filter: {
				search: '',
				timeRange: 'all'
			}
		};
	},
	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown;
		},
		timeRangeLabel() {
			const now = new Date();
			if (this.filter.timeRange === 'month') {
				return 'Tháng ' + (now.getMonth() + 1);
			} else if (this.filter.timeRange === 'week') {
				return 'Tuần hiện tại';
			}
			return '';
		},
		filteredEvents() {
			const today = new Date();
			today.setHours(0, 0, 0, 0);

			let events = [];
			if (Array.isArray(this.rawEvents)) {
				events = this.rawEvents.map(function (event) {
					const eventDate = new Date(event.NgayDuKien || event.start);
					const isPast = eventDate < today;
					let color = event.TrangThai === 1 ? '#66BB6A' : '#42A5F5';
					if (isPast) {
						color = event.TrangThai === 1 ? '#66BB6A' : '#EF5350';
					}
					return {
						...event,
						title: event.TenLichBaoTri,
						start: eventDate,
						end: eventDate,
						allDay: true,
						color: color
					};
				});
			}

			if (this.filter.search) {
				const s = this.filter.search.toLowerCase();
				events = events.filter(function (e) {
					return e.title.toLowerCase().includes(s);
				});
			}

			if (this.filter.timeRange !== 'all') {
				const now = new Date();
				events = events.filter(function (e) {
					const d = new Date(e.start);
					if (this.filter.timeRange === 'month') {
						return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
					}
					if (this.filter.timeRange === 'week') {
						const day = now.getDay() || 7;
						if (day !== 1) now.setHours(-24 * (day - 1));
						const startWeek = new Date(now);
						const endWeek = new Date(now);
						endWeek.setDate(endWeek.getDate() + 6);
						return d >= startWeek && d <= endWeek;
					}
					return true;
				}.bind(this));
			}
			return events;
		},
		sortedEvents() {
			const events = this.filteredEvents.slice();
			return events.sort(function (a, b) {
				return new Date(b.start) - new Date(a.start);
			});
		}
	},
	mounted() {
		// this.$refs.createSchedule.open()
		// this.$refs.eventDetail.open()
		// this.$refs.confirmList.open()
		// this.getLichSuKien();
	},
	methods: {
		async getLichSuKien() {
			try {
				const res = await axios.post("TS_DotBaoTri_Select");
				this.rawEvents = res.data.data || [];
			} catch (e) { console.error(e); }
		},
		closeMainPage() {
			window.location.href = "https://danhmuc.zentea.vn/TBDC-DashBoard";
		},
		formatDate(date) {
			if (!date) return '';
			return new Date(date).toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
		}
	}
}
</script>
