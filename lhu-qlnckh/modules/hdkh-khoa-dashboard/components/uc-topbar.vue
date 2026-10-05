<template>
	<v-row align="center" no-gutters class="ga-3">
		<v-col>
			<v-select :model-value="khoaId" @update:model-value="$emit('update:khoaId', $event)" label="Chọn khoa"
				:items="khoaList" item-title="TenKhoa" item-value="KhoaID" hide-details density="compact"></v-select>
		</v-col>
		<v-col cols="auto">
			<v-btn :disabled="!khoaId" @click="$emit('on-export')" icon="mdi-microsoft-excel" color="primary" variant="text">
			</v-btn>
		</v-col>
		<v-col cols='2'>
			<v-text-field :model-value="search" @update:model-value="$emit('update:search', $event)" label="Tìm kiếm"
				hide-details density="compact" variant="underlined" prepend-inner-icon=" mdi-filter-outline"
				:disabled="!khoaId"></v-text-field>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		name: 'uc-topbar',
		props: {
			khoaList: { type: Array, default: () => [] },
			khoaId: [String, Number],
			search: String
		},
		emits: ['update:khoaId', 'update:search', 'on-export']
	}
</script>