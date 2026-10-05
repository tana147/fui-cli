<template>
	<v-card variant="outlined">
		<v-card-title class="d-flex align-center">
			<v-icon class="mr-2" color="purple">mdi-history</v-icon>
			<span class="text-h6 font-weight-regular">{{ $t('message.RecentActivity') || ($i18n.locale === 'en' ? 'Recent Activity' : 'Hoạt động gần đây') }}</span>
		</v-card-title>
		<v-divider></v-divider>
		<v-list lines="two" style="max-height: 400px; overflow-y: auto;">
			<div v-if="!activities || activities.length === 0" class="text-center pa-5 text-grey">
				{{ $i18n.locale === 'en' ? 'No recent activity' : 'Chưa có hoạt động nào' }}
			</div>

			<v-list-item v-for="(activity, index) in activities" :key="index"
				:subtitle="formatTimeAgo(activity.Timestamp)">
				<template v-slot:prepend>
					<v-avatar color="blue-grey-lighten-4" class="mr-3">
						<v-icon color="blue-grey-darken-1">{{ getActivityIcon(activity.ActivityType) }}</v-icon>
					</v-avatar>
				</template>

				<v-list-item-title>
					<strong class="text-primary">{{ activity.StudentName }}</strong> ({{ activity.ClassName }})
					{{ getActivityText(activity.ActivityType) }}
					<strong>"{{ activity.ResourceTitle }}"</strong>
				</v-list-item-title>
			</v-list-item>
		</v-list>
	</v-card>
</template>

<script>
	export default {
		name: 'uc-activity-feed',
    props: {
        activities: { type: Array, default: () => [] }
    },
    methods: {
        getActivityIcon(type) {
            const map = {
                'SUBMITTED_ASSIGNMENT': 'mdi-file-upload-outline',
                'COMPLETED_LESSON': 'mdi-check-decagram-outline',
            };
            return map[type] || 'mdi-bell-outline';
        },
        getActivityText(type) {
            if (this.$i18n.locale === 'en') {
                const map = {
                    'SUBMITTED_ASSIGNMENT': 'submitted assignment',
                    'COMPLETED_LESSON': 'completed lesson',
                };
                return map[type] || 'had a new activity';
            } else {
                const map = {
                    'SUBMITTED_ASSIGNMENT': 'vừa nộp bài tập',
                    'COMPLETED_LESSON': 'vừa hoàn thành bài học',
                };
                return map[type] || 'vừa có hoạt động mới';
            }
        },
        formatTimeAgo(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            const now = new Date();
            const seconds = Math.floor((now - date) / 1000);
            const isEn = this.$i18n.locale === 'en';
            if (seconds < 60) return isEn ? "few seconds ago" : "vài giây trước";
            const minutes = Math.floor(seconds / 60);
            if (minutes < 60) return isEn ? `${minutes} minutes ago` : `${minutes} phút trước`;
            const hours = Math.floor(minutes / 60);
            if (hours < 24) return isEn ? `${hours} hours ago` : `${hours} giờ trước`;
            const days = Math.floor(hours / 24);
            return isEn ? `${days} days ago` : `${days} ngày trước`;
        }
    }
	}
</script>