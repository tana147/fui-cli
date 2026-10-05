<template>
	<!-- DESKTOP VIEW -->
	<v-row v-if="!isMobile">
		<v-col cols="12" md="3">
			<v-card elevation="2" class="px-2">
				<div class="d-flex mt-3 mb-3 text-primary">
					<v-badge inline class="" :content="DSBaoSuaMoi.length" color="red">
						<h4 style="" class="mr-2">Báo sửa mới</h4>
					</v-badge>
					<v-spacer></v-spacer>
					<v-btn color="grey" variant="text" prepend-icon="mdi-reload" density="compact" size="small"
						@click="onReload">
						Làm mới
					</v-btn>
				</div>
				<v-virtual-scroll :items="DSBaoSuaMoi" height="calc(100vh - 44px)">
					<template v-slot:default="{ item }">
						<uc-bao-sua-card :key="item.BaoSua_Id" :BaoSua_Id="item.BaoSua_Id" :TenHangHoa="item.TenHangHoa"
							:TenDiaDiem="item.TenDiaDiem" :GhiChu="item.GhiChu" :DoUuTien="item.DoUuTien"
							:HoTenNguoiBaoSua="item.HoTenNguoiBaoSua" :ThoiGianBaoSua="item.ThoiGianBaoSua"
							:AnhDaiDien_Url="item.AnhDaiDien_Url" @click="onOpenDialogTiepNhanBaoSua(item)" />
					</template>
				</v-virtual-scroll>
			</v-card>
		</v-col>
		<v-col cols="12" md="9">
			<v-card>
				<v-toolbar density="default">
					<v-item-group v-model="TinhTrangBaoSua">
						<v-item v-for="item in statusItems" :key="item.value" :value="item.value"
							v-slot="{ isSelected, toggle }">
							<v-btn @click="toggle" class="text-none" stacked :color="isSelected ? 'primary' : ''">
								<v-badge v-if="Stats[item.stat]" size="small" :color="item.badgeColor"
									:content="Stats[item.stat]">
									<v-icon size="small">{{ item.icon }}</v-icon>
								</v-badge>
								<v-icon v-else size="small">{{ item.icon }}</v-icon>
								{{ item.text }}
							</v-btn>
						</v-item>
					</v-item-group>
					<v-spacer></v-spacer>
					<v-text-field v-model="search" density="compact" variant="outlined" label="Tìm kiếm" flat
						class="mr-4" style="max-width: 200px;" clearable></v-text-field>
				</v-toolbar>
				<v-data-table-virtual density="compact" :items="DSBaoSuaFilter" :headers="headersBaoSua"
					height="calc(100vh - 64px)" :search="search" item-value="MaBaoSua" fixed-header>
					<template #item.TenTinhTrang="{ item }">
						<uc-time-line :item="item"></uc-time-line>
					</template>
					<template v-slot:item.actions="{ item }">
						<v-btn variant="text" color="primary" icon="mdi-square-edit-outline"
							@click="onOpenDialogUpdateBaoSua(item)">
						</v-btn>
					</template>
					<template #no-data>
						<uc-empty text="Chưa có báo sửa để hiển thị" />
					</template>
				</v-data-table-virtual>
			</v-card>
		</v-col>
	</v-row>
	<!-- MOBILE VIEW -->
	<div v-else style="padding-top: 50px">
		<v-item-group v-model="TinhTrangBaoSua" mandatory>
			<v-row dense class='mx-2'>
				<v-col cols="12">
					<v-item value="BAO_SUA_MOI" v-slot="{ isSelected, toggle }">
						<v-btn @click="toggle" block class="text-none" :color="isSelected ? 'primary' : ''"
							variant="tonal">
							<v-badge v-if="DSBaoSuaMoi.length" :content="DSBaoSuaMoi.length" color="deep-orange"
								size="small">
								<v-icon size="22">mdi-assistant</v-icon>
							</v-badge>
							<v-icon v-else size="22">mdi-assistant</v-icon>
							<span class="ml-2">Báo sửa mới</span>
						</v-btn>
					</v-item>
				</v-col>
				<v-col v-for="(item, index) in statusItems" :key="index" cols="4">
					<v-item :value="item.value" v-slot="{ isSelected, toggle }">
						<v-badge :model-value="!!Stats[item.stat]" :content="Stats[item.stat]" :color="item.badgeColor"
							size="small" class='w-100'>
							<v-chip @click="toggle" class="text-none w-100" :color="isSelected ? 'primary' : ''"
								variant="tonal" label>
								<v-icon size="22">{{ item.icon }}</v-icon>
								<span class="ml-1 text-caption">
									{{ item.text }}
								</span>
							</v-chip>
						</v-badge>
					</v-item>
				</v-col>
			</v-row>
		</v-item-group>
		<v-divider class="mb-2"></v-divider>
		<div style="height: calc(100dvh - 222px); overflow-y: auto;">
			<uc-bao-sua-card v-for="item in DSBaoSuaMobile" :key="item.BaoSua_Id" :BaoSua_Id="item.BaoSua_Id"
				:TenHangHoa="item.TenHangHoa" :TenDiaDiem="item.TenDiaDiem" :GhiChu="item.GhiChu"
				:DoUuTien="item.DoUuTien" :HoTenNguoiBaoSua="item.HoTenNguoiBaoSua"
				:ThoiGianBaoSua="item.ThoiGianBaoSua" :AnhDaiDien_Url="item.AnhDaiDien_Url"
				@click="TinhTrangBaoSua === 'BAO_SUA_MOI' ? onOpenDialogTiepNhanBaoSua(item) : onOpenDialogUpdateBaoSua(item)" />
		</div>
	</div>
</template>

<script>
export default {
	props: {
		DSBaoSuaMoi: Array,
		DSBaoSua: Array,
		Stats: Object,
	},

	data() {
		return {
			headersBaoSua: [
				{ title: "Địa điểm", key: "TenDiaDiem", nowrap: true },
				{ title: "Tài sản", key: "TenHangHoa" },
				{ title: "Ghi chú lỗi ", key: "GhiChu" },
				{ title: 'Tình trạng', key: 'TenTinhTrang', align: "center" },
				{ title: "", key: "actions" }
			],

			statusItems: [
				{
					value: "TIEP_NHAN",
					text: "Tiếp nhận",
					icon: "mdi-format-list-bulleted",
					stat: "DaTiepNhan",
					badgeColor: "deep-orange"
				},
				{
					value: "KIEM_TRA",
					text: "Kiểm tra",
					icon: "mdi-progress-check",
					stat: "DaKiemTra",
					badgeColor: "primary"
				},
				{
					value: "DANG_SUA",
					text: "Đang sửa",
					icon: "mdi-cog-outline",
					stat: "DangSua",
					badgeColor: "warning"
				},
				{
					value: "DA_XONG",
					text: "Sửa xong",
					icon: "mdi-sticker-check-outline",
					stat: "DaSuaXong",
					badgeColor: "success"
				},
				{
					value: "HU",
					text: "Tài sản hư",
					icon: "mdi-close-octagon-outline",
					stat: "Hu",
					badgeColor: "error"
				},
				{
					value: "BAO_SAI",
					text: "Báo sai",
					icon: "mdi-bell-cancel-outline",
					stat: "BaoSai",
					badgeColor: "error"
				}
			],

			TinhTrangBaoSua: this.isMobile === true ? 'BAO_SUA_MOI' : null,
			search: null,
		}
	},

	mounted() {
	},
	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
		DSBaoSuaFilter() {
			if (this.TinhTrangBaoSua === null || this.TinhTrangBaoSua === undefined) return this.DSBaoSua
			return this.DSBaoSua.filter(
				(BaoSua) => BaoSua.TinhTrangHienTai === this.TinhTrangBaoSua
			)
		},
		DSBaoSuaMobile() {
			if (this.TinhTrangBaoSua === 'BAO_SUA_MOI') return this.DSBaoSuaMoi
			else return this.DSBaoSuaFilter
		}
	},

	watch: {
	},

	methods: {
		onOpenDialogTiepNhanBaoSua(item) {
			this.$emit('on-open-dialog-tiep-nhan-bao-sua', item)
		},

		onOpenDialogUpdateBaoSua(item) {
			this.$emit('on-open-dialog-chi-tiet-bao-sua', item)
		},

		onReload() {
			this.$emit('load-bao-sua-moi')
		}
	}
}
</script>