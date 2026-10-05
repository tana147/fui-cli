<template>
    <v-card class="d-flex flex-column pa-2">
        <!-- <v-toolbar density="compact" flat color="grey-lighten-4" class="border-b flex-grow-0" style="min-height:48px">
			<v-row no-gutters align="center" class="w-100 px-2">
				<v-col :cols="isMobile ? 12 : 'auto'" class="d-flex align-center justify-center justify-md-start py-1">

					<v-btn-toggle v-model="filter.timeRange" density="compact" color="primary" variant="outlined"
						divided mandatory>
						<v-btn value="all" size="small">Tất cả</v-btn>
						<v-btn value="month" size="small">Tháng này</v-btn>
						<v-btn value="week" size="small">Tuần này</v-btn>
					</v-btn-toggle>
					<span v-if="!isMobile && filter.timeRange !== 'all'" class="ml-3 text-caption text-grey">
						{{ timeRangeLabel }}
					</span>
				</v-col>
			</v-row>
		</v-toolbar> -->

        <v-card-text class="pa-0 flex-grow-1" style="overflow-y:auto">
            <v-sheet v-if="!isMobile">
                <v-calendar ref="calendar" type="month" :events="filteredEvents">
                    <template #event="{ event }">
                        <v-tooltip location="top" open-delay="200">
                            <template #activator="{ props }">
                                <v-card v-bind="props"
                                    class="ma-1 pa-1 text-white cursor-pointer rounded-lg elevation-1"
                                    :color="event.color" flat @click.stop="onOpenDetail(event)"
                                    style="font-size:12px; line-height:1.2">

                                    <div class="d-flex align-center justify-space-between mb-1">

                                        <span class="font-weight-bold text-truncate mr-1">
                                            {{ event.title }}
                                        </span>

                                        <v-chip size="x-small" color="white" variant="outlined" class="px-1"
                                            style="height:16px">
                                            {{ event.TinhTrangTrachNhiem == 1 ? 'NV' : 'ĐT' }}
                                        </v-chip>

                                    </div>

                                    <div style="font-size:10px; opacity:.9">
                                        SL Tài sản:
                                        <b>{{ event.SoLuongTaiSan }}</b>
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
                    <span class="text-caption text-primary">
                        {{ filteredEvents.length }} sự kiện
                    </span>
                </div>

                <div v-if="filteredEvents.length === 0" class="text-center mt-10 text-grey">
                    <v-icon size="48" icon="mdi-calendar-search" class="mb-2" />
                    <div>Không tìm thấy lịch nào</div>
                </div>

                <v-container v-else class="pa-2">
                    <v-card v-for="(event, index) in sortedEvents" :key="index" class="mb-3 rounded-lg elevation-2"
                        @click="onOpenDetail(event)" :style="{ borderLeft: '5px solid ' + event.color }">
                        <div class="pa-3">
                            <div class="d-flex justify-space-between align-start mb-2">
                                <div class="font-weight-bold text-subtitle-1 text-primary line-clamp-2"
                                    style="line-height:1.3">
                                    {{ event.title }}
                                </div>
                                <v-chip size="x-small" :color="event.color" label variant="flat"
                                    class="ml-2 flex-shrink-0">
                                    {{ event.TrangThai === 1 ? 'Đã xong' : 'Chưa xong' }}
                                </v-chip>
                            </div>
                            <div class="d-flex align-center text-caption text-grey-darken-2 mb-2">
                                <v-icon size="x-small" start color="grey">
                                    mdi-calendar-range
                                </v-icon>
                                <span class="mr-3 font-weight-medium">
                                    {{ formatDate(event.start) }}
                                </span>
                                <v-icon size="x-small" start color="grey">
                                    mdi-account-wrench
                                </v-icon>
                                <span>
                                    {{ event.TinhTrangTrachNhiem == 1 ? 'Nhân viên' : 'Đối tác' }}
                                </span>

                            </div>
                            <div class="d-flex justify-space-between align-center pt-2 mt-1">
                                <span class="text-caption text-grey">
                                    Số lượng thiết bị: {{ event.SoLuongTaiSan }}
                                </span>
                            </div>
                        </div>
                    </v-card>
                </v-container>
            </div>
        </v-card-text>
    </v-card>
    <v-data-table>


    </v-data-table>
</template>

<script>
export default {
    props: {
        DSDotBaoTri: Array
    },

    data() {
        return {
            filter: {
                search: '',
                timeRange: 'all',
                showMobileSearch: false,

            }
        }
    },

    computed: {

        isMobile() {
            return this.$vuetify.display.smAndDown
        },

        timeRangeLabel() {
            const now = new Date()

            if (this.filter.timeRange === 'month') {
                return 'Tháng ' + (now.getMonth() + 1)
            }

            if (this.filter.timeRange === 'week') {
                return 'Tuần hiện tại'
            }

            return ''
        },

        filteredEvents() {
            const today = new Date()
            today.setHours(0, 0, 0, 0)
            let events = (this.DSDotBaoTri || []).map(e => {
                const eventDate = new Date(e.NgayThucHien || e.start)
                const isPast = eventDate < today
                let color = '#42A5F5'
                if (e.TrangThai === 1)
                    color = '#66BB6A'
                else if (isPast)
                    color = '#EF5350'
                return {
                    ...e,
                    title: e.TenDotBaoTri,
                    start: eventDate,
                    end: eventDate,
                    allDay: true,
                    color
                }
            })

            // SEARCH
            if (this.filter.search) {

                const s = this.filter.search.toLowerCase()

                events = events.filter(e =>
                    e.title.toLowerCase().includes(s)
                )
            }

            // TIMERANGE
            if (this.filter.timeRange !== 'all') {

                const now = new Date()

                if (this.filter.timeRange === 'month') {

                    events = events.filter(e => {
                        const d = new Date(e.start)

                        return d.getMonth() === now.getMonth()
                            && d.getFullYear() === now.getFullYear()
                    })
                }

                if (this.filter.timeRange === 'week') {

                    const startWeek = new Date(now)

                    const day = startWeek.getDay() || 7

                    startWeek.setDate(startWeek.getDate() - day + 1)
                    startWeek.setHours(0, 0, 0, 0)

                    const endWeek = new Date(startWeek)

                    endWeek.setDate(endWeek.getDate() + 6)

                    events = events.filter(e => {

                        const d = new Date(e.start)

                        return d >= startWeek && d <= endWeek
                    })
                }
            }

            return events
        },

        sortedEvents() {

            return [...this.filteredEvents].sort(
                (a, b) => new Date(a.start) - new Date(b.start)
            )
        }

    },

    methods: {
        formatDate: window.formatDate,
        onOpenDetail(event) {
            this.$emit('on-view-detail', event)
        }
    }

}
</script>