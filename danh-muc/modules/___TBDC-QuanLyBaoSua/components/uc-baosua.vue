<template>
	<v-card class="py-1 mb-1"
		style="border-radius: 12px;border-width: 0.1px; box-shadow: rgba(0, 0, 0, 0.1) 0px 1px 1px; " @click="onClick">

		<v-card-title class="text-caption ">
			<v-row>
				<v-col cols="3" class="text-grey-lighten-1">
					<!-- <v-icon size="small" color="grey" class="">mdi-map-marker-radius-outline</v-icon> -->
					ID: {{ requestId }}
					<!-- <v-chip size="x-small" prepend-icon="mdi-sort-ascending" :color="statusToColor(priority)" tonal>
						{{ priorityname }}
					</v-chip> -->
				</v-col>
				<v-col cols="9" align-self="end" style="display: flex; justify-content: flex-end;">
					<v-chip size="x-small" :color="statusToColor(statusID)" tonal>
						{{ statusText }} #{{priority}}  
					</v-chip>
				</v-col>
			</v-row>
		</v-card-title>


		<v-card-text class="text-subtitle-2 text-grey-darken-1 pb-0  align-center">
			<!-- <v-icon size="18" class="mr-1 text-blue">mdi-office-building</v-icon> -->
			<v-row>
				<v-col cols="2" style="max-width: 30px">
					<v-avatar style="border: 1px solid #e0b44b " size="25" class="mr-2">
						<v-img sizes="25" small :src="'https://file.lhbs.vn/me/avatarOrigin/'+ userid +'.jpg'">
						</v-img>
					</v-avatar>
				</v-col>
				<v-col>
					<div class="d-flex align-center text-grey-darken-1" style="font-size: 14px; margin-top: -5px">
						<!-- <v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon> -->

						<span class="text-caption">{{user}}</span>
					</div>
					<div class="d-flex align-center text-grey-darken-1 mt-0" style="font-size: 14px;">
						<!-- <v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon> -->

						<span style="margin-top: -3px; font-size: 11px;">{{ timeAgo }}</span>
					</div>

				</v-col>
			</v-row>
			<span class="mt-3">
				{{ note }}
			</span>

		</v-card-text>

		<v-card-title class="text-caption">
			<v-row>
				<v-col cols="3" class="text-grey-darken-1" style=" display: flex; align-items: center;">
					<v-icon size="small" color="grey" class="">mdi-map-marker-radius-outline</v-icon>
					<span
						style="white-space: nowrap;overflow: hidden; text-overflow: ellipsis; max-width: 100%; display: inline-block;">{{
						department }}</span>
				</v-col>
				<v-col cols="9" align-self="end" style="display: flex; justify-content: flex-end;">
					<div class=" align-center text-grey-darken-1"
						style="font-size: 14px; white-space: nowrap;overflow: hidden; text-overflow: ellipsis; max-width: 100%; display: inline-block;">
						<!-- <v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon> -->
						<span class="text-caption">{{ title }}</span>
					</div>
				</v-col>
			</v-row>
		</v-card-title>
	</v-card>
</template>

<script>
	export default {
		props: [
			"requestId",
			"title",
			"product",
			"note",
			"department",
			"timeAgo",
			"statusText",
			"statusID",
			"statuscolor",
			"user",
			"userid",
			"priority",
			"priorityname"
		],
		methods: {
			onClick() {
				this.$emit("task-click");
			},
			getPriorityColor(priorityLevel) {
				switch (priorityLevel) {
					case 4:
						return 'red'; // Khẩn cấp
					case 3:
						return 'orange'; // Cao
					case 2:
						return 'primary'; // Trung bình
					case 1:
						return 'green'; // Thấp
					default:
						return 'grey'; // Không xác định
				}
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
			}
	
		}
	}
</script>