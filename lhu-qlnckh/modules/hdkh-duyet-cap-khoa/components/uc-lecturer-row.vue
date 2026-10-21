<template>
	<div class="lecturer-row w-100">
		<div class="lecturer-info">
			<v-row>
				<v-col cols="11">
					<v-row>
						<v-col cols="2">
							<div class="d-flex align-center ga-2">
								<div class="font-weight-medium">
									{{ lecturer.HoTen }}
								</div>

								<v-badge v-if="lecturer.ChoDuyet" :content="lecturer.ChoDuyet" color="warning" inline />
							</div>

							<div class="text-caption text-medium-emphasis">
								ID: {{ lecturer.NhanVienID }}
							</div>
						</v-col>

						<v-col cols="3" class="text-primary pa-0 mt-2 border-e-md">
							<v-list-item density="compact">
								<template v-slot:prepend>
									<v-icon icon="mdi-target-variant" color="grey"></v-icon>
								</template>
								<span style="font-size: 15px">
									Định mức gốc
								</span>
								<template v-slot:append><span class="font-weight-medium">{{ lecturer.DinhMucGoc || 0 }}
										giờ</span></template>
							</v-list-item>
							<v-list-item density="compact">
								<template v-slot:prepend>
									<v-icon icon="mdi-sale" color="grey"></v-icon>
								</template>
								<span style="font-size: 15px">
									Miễn giảm
								</span>
								<template v-slot:append><span class="font-weight-medium">{{ lecturer.TongGioMienGiam ||
										0 }}
										giờ</span></template>
							</v-list-item>
						</v-col>

						<v-col cols="3" class="text-primary pa-0 mt-2 border-e-md">
							<v-list-item density="compact">
								<template v-slot:prepend>
									<v-icon icon="mdi-content-save-move-outline" color="green"></v-icon>
								</template>
								<span style="font-size: 15px">
									Bảo lưu từ năm trước
								</span>
								<template v-slot:append><span class="font-weight-medium text-green">{{
										lecturer.SoGioBaoLuuNamTruoc || 0 }} giờ</span></template>
							</v-list-item>
							<v-list-item density="compact">
								<template v-slot:prepend>
									<v-icon icon="mdi-alert-circle-outline" color="red"></v-icon>
								</template>
								<span style="font-size: 15px">
									Còn thiếu từ năm trước
								</span>
								<template v-slot:append><span class="font-weight-medium text-red">{{
										lecturer.SoGioThieuNamTruoc
										|| 0 }} giờ</span></template>
							</v-list-item>
						</v-col>

						<v-col cols="3" class="text-primary pa-0 mt-2">
							<v-list-item density="compact">
								<template v-slot:prepend>
									<v-icon icon="mdi-target" color="green"></v-icon>
								</template>
								<span style="font-size: 15px">
									Nghĩa vụ trong năm
								</span>
								<template v-slot:append><span class="font-weight-medium text-green">{{
										lecturer.NghiaVuTrongNam || 0 }} giờ</span></template>
							</v-list-item>
							<v-list-item density="compact">
								<template v-slot:prepend>
									<v-icon icon="mdi-alert-outline" color="red"></v-icon>
								</template>
								<span style="font-size: 15px">
									Số giờ phải thực hiện
								</span>
								<template v-slot:append><span class="font-weight-medium text-red">{{
										lecturer.SoGioPhaiThucHien
										|| 0 }} giờ</span></template>
							</v-list-item>
						</v-col>
					</v-row>
				</v-col>

				<v-col cols="1">
					<v-menu>
						<template #activator="{ props }">
							<v-btn color="primary" v-bind="props">
								Kê khai
							</v-btn>
						</template>

						<v-list>
							<v-list-item>
								<v-list-item-title class="cursor-pointer" @click="openDialog">
									Kê khai lý lịch
								</v-list-item-title>
							</v-list-item>

							<v-list-item v-for="(form, index) in dsForms" :key="form.FormID">
								<v-list-item-title class="cursor-pointer" @click="handleItemClick(form.FormID)">{{
									form.FormTitle }}</v-list-item-title>
							</v-list-item>
						</v-list>
					</v-menu>
				</v-col>
			</v-row>
		</div>
		<div class="lecturer-progress">
			<span class="font-weight-bold">{{ lecturer.TongGioDaThucHien }}</span> / {{ lecturer.SoGioPhaiThucHien }}
			giờ
			<v-progress-linear :model-value="progress" :color="progressColor" height="5" rounded class="mt-1"
				style="width: 100px; "></v-progress-linear>
		</div>
		<div class="lecturer-status mt-2">
			<v-chip :color="statusInfo.color" variant="flat" size="small">{{ statusInfo.text }}</v-chip>
		</div>

		<v-dialog v-model="isOpenLyLich" max-width="1200px" persistent @click:outside="closeDialog">
			<v-card>
				<v-card-title class="d-flex">
					<span class="text-h5">{{ dialogTitle }}</span>
					<v-spacer></v-spacer>
					<v-btn @click="closeDialog" variant="text" color="primary" icon='mdi-close'></v-btn>
				</v-card-title>
				<v-card-text>
					<uc-ly-lich-main :user-profile="userProfile" :nhan-vien-id="lecturer.NhanVienID"></uc-ly-lich-main>
				</v-card-text>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-lecturer-row',
		props: {
			lecturer: Object,
			dsForms: Array,
		},
		emits: ['on-show-kekhai'],
		data() {
			return {
				userProfile: null,
				isOpenLyLich: false
			};
		},
		computed: {
			progress() {
				if (!this.lecturer.TongGioDaThucHien || this.lecturer.SoGioPhaiThucHien === 0) return 0;
				return (this.lecturer.TongGioDaThucHien / this.lecturer.SoGioPhaiThucHien) * 100;
			},
			progressColor() {
				if (this.progress >= 100) return 'success';
				if (this.progress >= 50) return 'primary';
				return 'warning';
			},
			statusInfo() {
				if (this.lecturer.KetQua === 'Đạt') {
					return { text: 'Đạt', color: 'success' };
				}
				return { text: 'Chưa đạt', color: 'error' };
			},
			dialogTitle() {
				return `Kê khai lý lịch khoa học - ${this.lecturer.NhanVienID}`
			}
		},
		methods: {
			handleItemClick(formID) {
				this.$emit('on-show-kekhai', formID, this.lecturer)
			},
			closeDialog() {
				this.isOpenLyLich = false
			},
			async openDialog() {
				const userProfile = await ajaxCALLPromise('/HDKH_Profile_GetByNhanVien', { Nhanvienid: this.lecturer.NhanVienID })
				this.userProfile = userProfile
				if (userProfile[0] && userProfile[0].length == 0) {
					const userInfo = await ajaxCALLPromise('/HDKH_Info_CaNhan_Get', { Nhanvienid: this.lecturer.NhanVienID })
					this.userProfile[0][0] = userInfo[0]
				}
				this.isOpenLyLich = true
			}
		}
	}
</script>