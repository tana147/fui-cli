<template>

	<!-- <v-timeline>
				<v-timeline-item size="x-small">
					<template v-slot:icon>
						<v-avatar size="small" :image="avatar(item.CreateUser)"></v-avatar>
					</template>

<v-alert :value="true">
	{{ item.GhiChu}}
</v-alert>
</v-timeline-item>
</v-timeline> -->
	<div style="max-height: 120px" class="overflow-y-auto">
		<v-timeline side="end">
			<v-timeline-item v-for="(item, index) in items" :key="index" size="small">
				<template v-slot:icon>
					<v-avatar :image="avatar(item.CreateUser)" size="small"></v-avatar>
				</template>
				<template v-slot:opposite>
					<v-chip :color="statusToColor(item.MaTinhTrang)">
						<v-icon icon="mdi-circle" size="x-small" start></v-icon>{{ item.TenTinhTrang }}
					</v-chip>
				</template>

				<v-card>
					<v-card-text class="text-subtitle-2 text-grey-darken-1 pb-0  align-center">
						<v-row>
							<v-col>
								<div class=" text-grey-darken-1" style="font-size: 14px;">
									<span class="text-caption">{{ item.TenNhanVien }}</span>
								</div>
								<div class=" text-grey-darken-1" style="font-size: 14px;">
									<span style="margin-top: -3px; font-size: 11px;">{{
										formatTime(item.CreateTime)}}</span>
								</div>

							</v-col>
						</v-row>
					</v-card-text>

					<v-card-text>{{ item.GhiChu }}</v-card-text>
				</v-card>
			</v-timeline-item>
		</v-timeline>
	</div>

</template>

<script>
export default {
	props: {
		items: {
			type: Array,
		}
	},
	data() {
		return {

		}
	},
	mounted() { },
	computed: {

	},
	watch: {},
	methods: {
		formatTime: window.formatTime,

		avatar(id) {
			return `https://file.lhbs.vn/me/avatar/${!!id ? id : ''}.jpg`;
		},
		statusToColor(id) {
			switch (id) {
				case 0:
					return 'error';
					break;
				case 1:
					return 'light-green';
					break;
				case 2:
					return 'orange';
					break;
				case 3:
					return 'green';
					break;
				case 4:
					return 'light-blue-accent-3';
					break;

				default:
					return 'green';
					break;
			}
		},
	},
}
</script>