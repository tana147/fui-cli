<template>
	<div class="page-section">
		<v-card elevation="0">
			<v-card-title>Thiết lập số lượng nhóm sản phẩm tích lá trà</v-card-title>
			<v-card-text>
				<f-table class=" mb-5" label="Danh sách nhóm sản phẩm" :headers="headers"
					:items="vueData.DSCauHinhLaTra" :excel="true" dense :update-form="updateForm"
					:update-api="updateApi" :items-per-page='-1' hide-default-footer="true" />
			</v-card-text>
		</v-card>
	</div>
</template>

<script>
	export default {
	    data() {
	        return {
	            headers: [
	                {
	                    text: "Nhóm sản phẩm",
	                    value: "TenNhomSanPham",
	                },
	                {
	                    text: "Số lượng",
	                    align: "right",
	                    value: "SoLuong",
	                },
	                {
	                    text: "Tạm khóa",
	                    align: "center",
	                    value: "TinhTrang",
	                    el: "v-icon",
	                    attr: {
	                        color: "red"
	                    },
	                    innerHTML: "{{item.TinhTrang == 0 ? '': 'mdi-lock'}}"
	                },
	                {
	                    text: "",
	                    value: "ctrl-update",
	                    align: "center",
	                    width: 100,
	                    sortable: false,
	                },
	            ],
	            updateForm: [
	                {
	                    el: "v-select",
	                    attr: {
	                        ":disabled": "vueData.IsEdit",
	                        ":items": "vueData.DSNhomSanPham",
	                        "item-value": "id",
	                        "item-text": "name",
	                        "v-model": "NhomSanPhamID",
	                        "label": "Nhóm sản phẩm"
	                    },
	                    w: 7,
	                },
	                {
	                    el: "v-text-field",
	                    attr: {
	                        "v-model": "SoLuong",
	                        label: "Số lượng",
	                    },
	                    w: 2,
	                },
	                {
	                    el: "v-select",
	                    attr: {
	                        "v-model": "TinhTrang",
	                        label: "Tình trạng",
	                        ":items": "vueData.DSTinhTrang"
	                    },
	                    w: 3
	                },
	            ],
	            updateApi: {
	                "default-item": {
	                    "TinhTrang": 0,
	                    "SoLuong": 1
	                },
	                "new-action": {
	                    "IsEdit": false
	                },
	                "edit-action": {
	                    "IsEdit": true
	                },
	                new: {
	                    API: "/eorder/CauHinhLaTra_Insert",
	                    IN: {
	                        NhomSanPhamID: "item.NhomSanPhamID",
	                        SoLuong: "item.SoLuong",
	                        TinhTrang: "item.TinhTrang"
	                    },
	                    MESS: "Thêm nhóm sản phẩm thành công",
	                    CALLBACK: [
	                        {
	                            CALL: "getDSCauHinhLaTra",
	                        },
	                    ],
	                },
	                edit: {
	                    API: "/eorder/CauHinhLaTra_Update",
	                    IN: {
	                        CauHinhLaTraID: "item.CauHinhLaTraID",
	                        SoLuong: "item.SoLuong",
	                        TinhTrang: "item.TinhTrang"
	                    },
	                    MESS: "Cập nhật cấu hình thành công",
	                    CALLBACK: [
	                        {
	                            CALL: "getDSCauHinhLaTra",
	                        },
	                    ],
	                },
	                delete: {
	                    CONFIRM: "Bạn có muốn xóa nhóm sản phẩm <br /><b>{{item.TenNhomSanPham}}</b>",
	                    API: "/eorder/CauHinhLaTra_Delete",
	                    IN: {
	                        CauHinhLaTraID: "item.CauHinhLaTraID",
	                    },
	                    MESS: "Xóa thành công",
	                    CALLBACK: [
	                        {
                                CALL: "getDSCauHinhLaTra",
	                        },
	                    ],
	                },
	            },
	        }
	    },
	    watch: {},
	    methods: {
	    },
	}
</script>