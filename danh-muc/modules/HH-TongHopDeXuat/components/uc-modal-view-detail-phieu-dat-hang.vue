<template>
	<v-dialog v-model="isShow" width="800">
		<v-card>
			<v-toolbar density="compact" elevation="0">
				<v-toolbar-title>
					Xem chi tiết
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text class="py-1">
				<div class="pa-4 border-bottom bg-grey-lighten-5 pb-0">
					<div class="mt-3">
						<div class="d-flex align-center justify-space-between mb-1">
							<span class="text-grey text-caption">NHÀ CUNG CẤP</span>
							<span class="font-weight-bold">{{ selectedItem.TenNhaCungCap }}</span>
						</div>
						<div class="d-flex align-center justify-space-between mb-1 ">
							<span class="text-grey text-caption">NGÀY ĐẶT HÀNG</span>
							<span class="font-weight-bold">{{ formatDate(selectedItem.NgayDatHang) }}</span>
						</div>
						<div class="d-flex align-center justify-space-between mb-1">
							<span class="text-grey text-caption">ĐỊA ĐIỂM</span>
							<span class="font-weight-bold">{{ selectedItem.TenDiaDiem }}</span>
						</div>
					</div>
				</div>
				<div class="pa-4 d-flex flex-column pt-0">
					<div class="d-flex justify-space-between align-center mb-3">
						<div class="text-subtitle-2 font-weight-bold">DANH SÁCH HÀNG HOÁ </div>
					</div>

					<v-list v-if="selectedItem?.arrayHangHoa?.length > 0" lines="two"
						class="pa-0 flex-grow-1 overflow-y-auto">
						<v-list-item v-for="(HangHoa, index) in selectedItem.arrayHangHoa" :key="index"
							class="border rounded-lg mb-2 pa-2">
							<template v-slot:prepend>
								<v-avatar
									:color="HangHoa.Is_CaBiet ? 'purple-lighten-5' : HangHoa.LoaiHangHoa === 'CCDC' ? 'orange-lighten-5' : 'blue-lighten-5'"
									rounded size="40">
									<v-icon size="20"
										:color="HangHoa.Is_CaBiet ? 'purple' : HangHoa.LoaiHangHoa === 'CCDC' ? 'orange-darken-2' : 'blue'">
										{{ HangHoa.Is_CaBiet ? 'mdi-devices' : HangHoa.LoaiHangHoa === 'CCDC' ?
										'mdi-tools'
										: 'mdi-package-variant' }}
									</v-icon>
								</v-avatar>
							</template>

							<v-list-item-title class="font-weight-bold text-body-2">
								{{ HangHoa.TenHangHoa }}
							</v-list-item-title>

							<v-list-item-subtitle class="text-caption mt-1 d-flex justify-space-between">
								<span>SL: <b>{{ HangHoa.SoLuongDat }}</b> {{ HangHoa.TenDonVi }}</span>
							</v-list-item-subtitle>
						</v-list-item>
					</v-list>

					<div v-else>
						<uc-empty text="Chưa có hàng hoá để hiển thị"></uc-empty>
					</div>
				</div>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
    props: {
        isShow: Boolean,
        selectedItem: Object,
    },
    data() {
        return {
        }
    },
    mounted() {
    },
    computed: {

    },
    watch: {},
    methods: {
        formatDate: window.formatDate,
        closeDialog() {
            this.$emit('update:isShow', false)
        },
    },
}
</script>