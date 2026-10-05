<template>
	<v-row class="mb-2" dense>
		<!-- Card 1: Tổng số giảng viên -->
		<v-col cols="12" sm="4" class="py-1">
			<v-card class="mx-auto rounded-sm elevation-1 pa-2 px-3" outlined>
				<div class="d-flex align-center justify-space-between">
					<div>
						<div class="text-caption grey--text text--darken-1 font-weight-medium text-uppercase"
							style="letter-spacing: 0.05em; font-size: 0.72rem;">
							Tổng số giảng viên
						</div>
						<div class="text-h5 font-weight-bold primary--text mt-0">
							{{ stats.tongGV || 0 }}
						</div>
					</div>
					<v-spacer></v-spacer>
					<v-avatar size="36" color="blue-lighten-5" class="ml-3">
						<v-icon size="18" color="primary">mdi-account-group-outline</v-icon>
					</v-avatar>
				</div>
			</v-card>
		</v-col>

		<!-- Card 2: Đạt nghĩa vụ -->
		<v-col cols="12" sm="4" class="py-1">
			<v-card class="mx-auto rounded-sm elevation-1 pa-2 px-3" outlined>
				<div class="d-flex align-center justify-space-between">
					<div>
						<div class="text-caption grey--text text--darken-1 font-weight-medium text-uppercase"
							style="letter-spacing: 0.05em; font-size: 0.72rem;">
							Đạt nghĩa vụ NCKH
						</div>
						<div class="text-h5 font-weight-bold success--text mt-0">
							{{ stats.dat || 0 }}
							<span class="text-caption grey--text font-weight-regular ml-1">({{ stats.tyLeDat || 0
								}}%)</span>
						</div>
					</div>
					<v-spacer></v-spacer>
					<v-avatar size="36" color="green-lighten-5" class="ml-3">
						<v-icon size="18" color="success">mdi-account-check-outline</v-icon>
					</v-avatar>
				</div>
			</v-card>
		</v-col>

		<!-- Card 3: Chưa đạt nghĩa vụ -->
		<v-col cols="12" sm="4" class="py-1">
			<v-card class="mx-auto rounded-sm elevation-1 pa-2 px-3" outlined>
				<div class="d-flex align-center justify-space-between">
					<div>
						<div class="text-caption grey--text text--darken-1 font-weight-medium text-uppercase"
							style="letter-spacing: 0.05em; font-size: 0.72rem;">
							Chưa đạt nghĩa vụ
						</div>
						<div class="text-h5 font-weight-bold error--text mt-0">
							{{ stats.khongDat || 0 }}
							<span class="text-caption grey--text font-weight-regular ml-1">({{ stats.tyLeKhongDat || 0
								}}%)</span>
						</div>
					</div>
					<v-spacer></v-spacer>
					<v-avatar size="36" color="red-lighten-5" class="ml-3">
						<v-icon size="18" color="error">mdi-account-alert-outline</v-icon>
					</v-avatar>
				</div>
			</v-card>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		name: "uc-stats",
	props: {
		stats: {
			type: Object,
			default: () => ({
				tongGV: 0,
				dat: 0,
				khongDat: 0,
				tyLeDat: 0,
				tyLeKhongDat: 0
			})
		}
	}
	}
</script>