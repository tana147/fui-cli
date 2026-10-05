<template>
	<div class="mb-3 mt-3">
		<!-- {{itemDes.Text_Content}} -->
		<c-table v-if="DataArray.length > 0" :label="label" :headers="tableHeader" :items="DataArray" :isNew="isNew"
			:isEdit="isEdit" dense>
			<!-- hide-default-footer -->
			<template v-slot:item.HoTenHocHamHocVi="{ item }">
				<span>
					<span>{{ item.HocViHocHam }}. {{ item.HoTenGiangVien }}</span>
				</span>
			</template>

			<template v-slot:item.DiemThanhPhanList="{ item }">
				<div class="diemThanhPhanWrapper">
					<span class="diemThanhPhan" v-for="(diem, diemIndex) in item.DiemThanhPhanList" :key="diemIndex">
						{{ diem.HinhThuc }}: <b>{{ diem.Diem?.toFixed(1) }}</b>
					</span>
				</div>
			</template>
		</c-table>

		<div class="d-flex justify-center align-center">
			<h4 v-if="DataArray.length === 0" class="primary--text">
				<v-icon class="mb-1" color="primary">mdi-inbox</v-icon> Chưa có nội dung
			</h4>
		</div>
	</div>
</template>

<script>
	export default {
    props: {
        itemdes: {
            type: Object,
            default: () => ({}),
        },
        tableHeader: {
            type: Array,
            default: () => [],
        },
        DataArray: {
            type: Array,
            default: () => [],
        },
        label: {
            type: String,
            default: () => '',
        },
        isNew: {
            type: Boolean,
            default: () => false,
        },
        isEdit: {
            type: Boolean,
            default: () => false,
        },
    },
    data() {
        return {}
    },
    mounted() {},
    computed: {
        itemDes: function () {
            return this.itemdes
        },
    },
    watch: {},
    methods: {},
}
</script>