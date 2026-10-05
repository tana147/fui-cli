<template>
	<div class="dept-list-panel">
		<div class="section-head--responsive d-flex align-start justify-space-between ga-3 mb-4">
			<div>
				<div class="text-h6 font-weight-bold">Danh sách bộ phận</div>
				<div class="text-body-2 text-medium-emphasis mt-1">
					{{ filteredList.length }} / {{ boPhanList.length }} bộ phận đang hiển thị
				</div>
			</div>

			<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="onAddBoPhan">
				Thêm bộ phận
			</v-btn>
		</div>

		<v-text-field v-model="searchKeyword" label="Tìm theo tên hoặc mô tả" prepend-inner-icon="mdi-magnify"
			variant="outlined" density="compact" clearable hide-details class="search-field--sidebar mb-4" />

		<div v-if="filteredList.length" class="dept-list">
			<v-card v-for="boPhan in filteredList" :key="boPhan.BoPhan_Id" :elevation="0" class="dept-card"
				:class="{ 'is-selected': selectedBoPhanId === boPhan.BoPhan_Id }" @click="onSelectBoPhan(boPhan)">
				<v-card-text class="dept-card__body">
					<div class="dept-card__accent"></div>
					<div class="dept-card__top">
						<div class="dept-card__main">
							<div class="dept-card__eyebrow">Bộ phận</div>
							<div class="dept-card__title-row">
								<div class="dept-card__title">{{ boPhan.TenBoPhan }}</div>
								<v-chip size="x-small" :color="boPhan.TinhTrang === 0 ? 'success' : 'warning'"
									variant="tonal">
									{{ boPhan.TinhTrang === 0 ? 'Hoạt động' : 'Tạm khóa' }}
								</v-chip>
							</div>
							<div class="dept-card__desc">
								{{ boPhan.MoTa || 'Chưa cập nhật mô tả.' }}
							</div>
							<div class="dept-card__meta-row">
								<span>{{ boPhan.SoNhanVien }} nhân viên</span>
								<span>{{ boPhan.SoQuyen }} quyền</span>
								<span>Cập nhật {{ getDisplayDate(boPhan) }}</span>
							</div>
						</div>

						<v-menu location="bottom end">
							<template v-slot:activator="{ props }">
								<v-btn size="small" variant="text" icon="mdi-dots-vertical" class="dept-card__menu"
									v-bind="props" @click.stop />
							</template>

							<v-list density="compact">
								<v-list-item prepend-icon="mdi-trash-can-outline" title="Xóa"
									@click="onDeleteBoPhan(boPhan)" />
							</v-list>
						</v-menu>
					</div>

				</v-card-text>
			</v-card>
		</div>

		<div v-else class="empty-wrap">
			<uc-empty :text="searchKeyword ? 'Không tìm thấy bộ phận phù hợp' : 'Chưa có bộ phận nào để hiển thị'" />
		</div>
	</div>
</template>

<script>
	export default {
	    name: 'uc-list-bo-phan',
	    props: {
	        boPhanList: {
	            type: Array,
	            required: true,
	        },
	        selectedBoPhanId: {
	            type: Number,
	            default: null,
	        },
	    },
	    emits: ['add-bo-phan', 'select-bo-phan', 'edit-bo-phan', 'config-quyen', 'delete-bo-phan'],
	    data() {
	        return {
	            searchKeyword: '',
	        }
	    },
	    computed: {
	        filteredList() {
	            const keyword = this.normalizeText(this.searchKeyword)
	
	            if (!keyword) {
	                return this.boPhanList
	            }
	
	            return this.boPhanList.filter(function (boPhan) {
	                return (
	                    this.normalizeText(boPhan.TenBoPhan).includes(keyword) ||
	                    this.normalizeText(boPhan.MoTa).includes(keyword)
	                )
	            }, this)
	        },
	    },
	    methods: {
	        formatDate: window.formatDate,
	        normalizeText(value) {
	            return (value || '').toString().trim().toLowerCase()
	        },
	        getDisplayDate(boPhan) {
	            return boPhan && (boPhan.NgaySua) ? (this.formatDate(boPhan.NgaySua)) : 'Chưa xác định'
	        },
	        onAddBoPhan() {
	            this.$emit('add-bo-phan')
	        },
	        onSelectBoPhan(boPhan) {
	            this.$emit('select-bo-phan', boPhan)
	        },
	        onEditBoPhan(boPhan) {
	            this.$emit('edit-bo-phan', boPhan)
	        },
	        onConfigQuyen(boPhan) {
	            this.$emit('config-quyen', boPhan)
	        },
	        onDeleteBoPhan(boPhan) {
	            this.$emit('delete-bo-phan', boPhan)
	        },
	    },
	}
</script>